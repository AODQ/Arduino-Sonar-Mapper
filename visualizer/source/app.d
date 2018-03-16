import std.string : format;
import std.conv : to;
import std.parallelism, std.range;
import klaodg;
import std.stdio;
import serial.device : SerialPort, TimeoutException;
import std.algorithm, std.range;

immutable int2 dim      = int2(640, 480);
immutable float2 dim_fl = cast(float2)(dim);
SerialPort port_com;

string Serial_Read ( ) {
  try {
    ubyte[100] buff;
    auto amt = port_com.read(buff);
    string t = cast(string)(buff[0 .. amt]~'\0');
    return t;
  } catch ( Exception e ) {
    return "";
  }
}

int[] RDistances ( ) {
  string data = Serial_Read();
  if ( data == "" ) return [];
  string[] d = data.split(" ");
  try {
  if ( d.length >= 1 )
    return d[0..2].map!(to!int).array;
  } catch ( Exception e ) { return []; }
  return [];
}

// TODO make To_Vec again
auto To_Vec(T, U, int N)(Vector!(U, N) vec) {
  Vector!(T, N) nvec;
  static foreach ( i; 0 .. N )
    nvec.v[i] = cast(T)vec.v[i];
  return nvec;
}

/*
  sudo usermod -a -G dialout aodq
  sudo chmod a+rw /dev/tty/USB0
*/

int t = 0;

float3 To_Cartesian ( float theta, float phi ) {
  return float3(cos(phi)*sin(theta), sin(phi)*sin(theta), cos(theta));
}

Ray Look_At ( float2 uv, float3 eye, float3 center,
              float3 up = float3(0.0f, 1.0f, 0.0f)) pure nothrow {
  float3 ww = Normalize(center - eye),
         uu = Normalize(cross(up, ww)),
         vv = Normalize(cross(ww, uu));
  return Ray(eye, Normalize(uv.x*uu + uv.y*vv + 2.5*ww));
}


void main ( ) {
  import core.time : dur;
  auto timeout = dur!"msecs"(100);
  port_com = new SerialPort("/dev/ttyUSB0");

  GLBuffer left, right;

  import svo : Octree;
  auto otree = new Octree(float3(0.0f), 100.0f, 64);

  int y_iter = 70, x_iter = 0;

  bool finished = false;
  Initialize(dim.x, dim.y, "klaodg arduino",
  () {}, (GLBuffer img, float unused_time) { //update
    if ( finished ) {
      // draw image
      immutable float3 eye = float3(0.0f);
      foreach ( i; 0 .. dim.x )
      foreach ( j; 0 .. dim.y ) {
        int2 frag_coord = To_Vec!float(int2(i, j));
        float2 uv = -1.0f + 2.0f*(To_Vec!float(frag_coord)/dim_fl);
        uv.x *= dim_fl.x/dim_fl.y;
        auto ray = Look_At(uv, eye, float3(0.0f));
        auto t = otree.Raymarch(ray.ori, ray.dir);
        if ( t.pt == null ) {
          img.Apply(frag_coord, float4(0.4f, 0.0f, 0.4f, 1.0f));
          continue;
        }
        float dist = distance(eye, t.intersect);
        img.Apply(frag_coord, float4(float3(dist)/100.0f, 1.0f));
      }
      return;
    }
    // --init left/right sonar data
    auto tbl = RDistances();
    if ( tbl.length == 0 ) return;
    float left_dist  = cast(float)tbl[0],
          right_dist = cast(float)tbl[1];
    float3 left_origin = float3(0.0f, -1.0f, 0.0f),
           right_origin = float3(0.0f, 1.0f, 0.0f);
    // polar coordinates => cartesian coordinates
    float phi = y_iter/180.0f,
          theta = Mix(0.2f, 0.4f, x_iter/40.0f); // 180.0f degrees, !cos
    float3 left_nor  = Normalize(To_Cartesian(theta*PI, phi)),
           right_nor = Normalize(To_Cartesian((1.0-theta)*PI, phi));
    // TODO : reorient hemisphere for normals ?
    // like raymarching ... ro = ro + rd*dist
    otree.Insert(left_origin+left_nor*left_dist,
                 VoxelData(left_origin, left_nor, left_dist));
    otree.Insert(right_origin+right_nor*right_dist,
                 VoxelData(right_origin, right_nor, right_dist));

    writeln(x_iter, " :: ", y_iter);
    writeln(left_origin+left_nor*left_dist);
    writeln(right_origin+right_nor*right_dist);



    //--end
    if ( ++ x_iter == 40 ) {
      x_iter = 0;
      y_iter += 2;
      if ( y_iter >= 110 ) {
        y_iter = 70;
        finished = true;
      }
    }
  });
  port_com.close();
}
