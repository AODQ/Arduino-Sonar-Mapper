module svo;
import std.stdio : writeln, writefln, readln;
import std.random, std.algorithm, std.range;
import klaodg.vector;

struct VoxelData {
  float3 origin;
  float size;
  uint shape;
  LinkedListNode!(VoxelData*)* llnode;

  @disable this();
  this ( float3 _origin ) {
    origin = _origin;
    size = 1.0f;
    shape = 0;
  }
}

uint Encode_Axis ( float3 center, float3 ori ) {
   // [X Y Z]
   return (center.x<ori.x)*0b100 +
          (center.y<ori.y)*0b010 +
          (center.z<ori.z)*0b001;
}

float3 Normalize_Axis ( uint t ) {
  return float3(
    (t&0b100?1:-1),
    (t&0b010?1:-1),
    (t&0b001?1:-1),
  );
}


struct LinkedListNode(T) {
  T data;
  LinkedListNode!T* prev, next;
  this ( T _data, LinkedListNode!T* _prev ) {
    data = _data;
    prev = _prev;
  }
}

struct LinkedList(T) {
  LinkedListNode!T* head;
  LinkedListNode!T* tail;

  // this () {
  //   head = tail = null;
  // }

  LinkedListNode!T* insertFront ( T data ) {
    if ( tail is null ) {
      head = tail = new LinkedListNode!T(data, null);
      return head;
    }
    tail.next = new LinkedListNode!T(data, tail);
    tail = tail.next;
    return tail;
  }

  void Remove ( LinkedListNode!T* n ) {
    auto t = n.prev;
    if ( n.prev ) n.prev = n.next;
    else          head   = n.next;
    if ( n.next ) n.next = t;
    else          tail   = t;
    n.destroy();
  }

  void popBack ( ) {
    if ( tail ) tail = tail.prev;
    if ( tail is null ) head = null;
  }
  void popFront ( ) {
    if ( head ) head = head.next;
    if ( head is null ) tail = null;
  }
  T front ( ) { return head.data; }
  T back  ( ) { return tail.data; }
  bool empty ( ) const { return head == tail; }
  LinkedList!T save ( ) @property { return this; }
}

struct OctreeNode {
  float3 center;
  float radius;
  OctreeNode*[8] children;
  OctreeNode* parent;
  VoxelData* data;

  this ( float3 _center, float _radius, OctreeNode* _parent ) {
    center = _center; radius = _radius; parent = _parent;
  }

  OctreeNode* Insert ( float3 ori, int scale, VoxelData* new_data ) {
    if ( scale <= 0 ) { // within desired resolution
      if ( data is null ) data = new_data;
      else                return null; // couldn't insert (data exists already)
      return &this;
    }
    assert(data is null, "Somehow data leaked into a non-leaf");
    // not yet at desired resolution
    uint ch = Encode_Axis(center, ori);
    if ( children[ch] is null ) { // create child
      float3 dir = ch.Normalize_Axis;
      float new_rad = radius*0.5f;
      children[ch] = new OctreeNode(center+new_rad*dir, new_rad, &this);
    }
    // pass onto next child
    return children[ch].Insert(ori, scale-1, new_data);
  }

  VoxelData* RVoxelData ( float3 ori, int scale ) {
    if ( scale <= 0 ) return data;
    assert(data is null, "Somehow data leaked into a non-leaf");
    auto ch = Encode_Axis(center, ori);
    return children[ch] is null ? null : children[ch].RVoxelData(ori, scale-1);
  }

  uint RSize ( ) {
    if ( data !is null ) return 1;
    uint amt = 0;
    foreach ( c; children )
      if ( c !is null ) amt += c.RSize;
    return amt;
  }
}

class Octree {
  OctreeNode* head;
  LinkedList!(VoxelData*) voxel_render_list;

  float3 center;
  float  radius;
  int scale;

  this ( float3 _center, float _radius, int _scale ) {
    center = _center; radius = _radius; scale = _scale;
    head = new OctreeNode(_center, _radius, null);
  }

  void Insert ( float3 ori, VoxelData* data ) {
    // insert data into octree
    auto onode = head.Insert(ori, scale, data);
    if ( onode is null ) return; // probably hit node twice
    // insert node into render list and linked node to corresponding LL node
    // octree => onodes => rendering-list/linked-list => rnode (ref. as llnode
    //   by onodes)
    onode.data.origin = onode.center;
    onode.data.size   = onode.radius;
    auto rlnode = voxel_render_list.insertFront(onode.data);
    rlnode.data.llnode = rlnode;
    if ( onode.parent is null ) return;
    if ( onode.parent.RSize() >= 4 ) {//  // grow?
      // // get configuration
      // // OctreeNode*[8] children;
      // VoxelData* vdata = new VoxelData(onode.parent.center);
      // // find a better model
      // // bump up size
      // vdata.size = onode.data.size+1;
      // // clear children nodes
      // foreach ( ref ch; onode.parent.children ) {
      //   if ( ch is null ) continue;
      //   auto chdata = ch.data;
      //   if ( chdata is null ) continue;
      //   writeln("Removing: ", chdata.llnode);
      //   voxel_render_list.Remove(chdata.llnode);
      //   writeln("Finished removing...");
      //   ch.data = null;
      // }
      // auto vnode = voxel_render_list.insertFront(vdata);
      // vnode.data.llnode = vnode;
    }
  }

  uint RSize ( ) {
    return head.RSize;
  }

  VoxelData* RVoxelData ( float3 ori ) {
    return head.RVoxelData(ori, scale);
  }

  auto Raymarch ( float3 ori, float3 dir ) {
    Plane_Intersect_Attempt(ori, dir, center, radius, 0,  1.0f);
    Plane_Intersect_Attempt(ori, dir, center, radius, 0, -1.0f);
    Plane_Intersect_Attempt(ori, dir, center, radius, 1,  1.0f);
    Plane_Intersect_Attempt(ori, dir, center, radius, 1, -1.0f);
    Plane_Intersect_Attempt(ori, dir, center, radius, 2,  1.0f);
    Plane_Intersect_Attempt(ori, dir, center, radius, 2, -1.0f);

    struct Intersection {
      float3 intersect;
      VoxelData* pt;
    }

    int st = 0;

    while ( ori.In_Bounds(center-float3(radius), center+float3(radius)) ) {
      VoxelData* vdata = RVoxelData(ori);
      if ( vdata !is null ) return Intersection(ori, vdata);

      ori.v[st] += dir.v[st];
      st = (st+1)%3;
    }
    return Intersection(float3(-1.0f), null);
  }
}

void Plane_Intersect_Attempt ( ref float3 ori, float3 dir, float3 center,
                               float radius, int idx, float op ) {
  float p_pt = center.v[idx] + (op*radius);
  float3 p_nor = float3(0.0f);
  p_nor.v[idx] = op;
  if ( op>0.0f ? (ori.v[idx] > p_pt) : (ori.v[idx] < p_pt) ) {
    Plane_Intersect(ori, dir, p_nor, radius);
  }
}
void Plane_Intersect ( ref float3 ori, float3 dir, float3 nor, float dist ) {
  /*
    ray: p = ori + dir
    plane: dot(ori, nor) + dist = 0
    -- substitude plane ori with ray
    dot((ori + dist*dir), nor) + pd = 0
    -- solve for dist
    dist = (dot(-ori, nor) + pd)/dot(dir, nor)
  */
  ori = ori + dir*((dot(-ori, nor) + dist)/dot(dir, nor));
}
