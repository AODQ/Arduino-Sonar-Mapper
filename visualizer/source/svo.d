module svo;
import std.stdio : writeln, writefln, readln;
import klaodg.vector;

struct VoxelData {
  float3 original_pos, original_nor;
  float original_dist;
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

struct OctreeNode {
  float3 center;
  float radius;
  OctreeNode*[8] children;
  VoxelData* data;

  this ( float3 _center, float _radius ) {
    center = _center; radius = _radius;
  }

  void Insert ( float3 ori, int scale, VoxelData* new_data ) {
    if ( scale <= 0 ) { // within desired resolution
      if ( data is null ) data = new_data;
      return;
    }
    assert(data is null, "Somehow data leaked into a non-leaf");
    // not yet at desired resolution
    uint ch = Encode_Axis(center, ori);
    if ( children[ch] is null ) { // create child
      float3 dir = ch.Normalize_Axis;
      float new_rad = radius*0.5f;
      children[ch] = new OctreeNode(center+new_rad*dir, new_rad);
    }
    // pass onto next child
    children[ch].Insert(ori, scale-1, new_data);
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
  VoxelData* voxels;

  float3 center;
  float  radius;
  int scale;

  this ( float3 _center, float _radius, int _scale ) {
    center = _center; radius = _radius; scale = _scale;
    head = new OctreeNode(_center, _radius);
  }

  void Insert ( float3 ori, VoxelData* data ) {
    head.Insert(ori, scale, data);
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
