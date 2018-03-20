module klaodg.vector;

public import gfm.math;
public import std.math : PI, sin, cos, tan, asin, acos, atan, atan2, sinh, cosh,
                         tanh, asinh, acosh, atanh, pow, exp, log, exp2, log2,
                         sqrt, abs, floor, trunc, round, ceil, modf, modf;
public import std.algorithm : min, max;

immutable float TAU = PI*2.0f;

alias Is_Vector = isVector;

alias int2 = Vector!(int, 2);
alias int3 = Vector!(int, 3);
alias int4 = Vector!(int, 4);

alias uint2 = Vector!(uint, 2);
alias uint3 = Vector!(uint, 3);
alias uint4 = Vector!(uint, 4);

alias float2 = Vector!(float, 2);
alias float3 = Vector!(float, 3);
alias float4 = Vector!(float, 4);

alias float3x3 = mat3x3!float;
alias float4x4 = mat4x4!float;

float3x3 Float3x3(float3 u, float3 v, float3 w) {
  return float3x3([u.x, u.y, u.z,
                   v.x, v.y, v.z,
                   w.x, w.y, w.z]);
}

T Sqr(T)(T t) { return t*t; }

struct Ray { float3 ori, dir; }

struct RGBA32 {
  private uint _data;

  private uint Pack ( float t, int idx ) inout {
    import std.algorithm : clamp;
    // 0.0f .. 255.0f shifted to the left to form R255+G255+B255+A255
    return cast(uint)(t.clamp(0.0f, 1.0f)*255.0f) << (idx*8);
  }
  private float Unpack ( int idx ) inout {
    // Clear irrelevant bytes and shift to right to grab 0.0f .. 1.0f
    return cast(float)((_data&(0xFF<<(idx*8))) >> (idx*8))/255.0f;
  }

  this ( float4 data ) { // Pack
    import std.algorithm, std.range;
    _data = iota(0, 4).map!(i => Pack(data.v[i], i))
                      .reduce!((x, y) => x+y);
  }
  float4 Unpack ( ) inout {
    import std.algorithm, std.range;
    return float4(iota(0, 4).map!(i => Unpack(i)).array);
  }
}

float3 Normalize ( float3 t ) pure nothrow { return t.normalized; }

bool In_Bounds(T)(T t, T l, T h) if(Is_Vector!T){
  import std.stdio;
  if ( Clamp(t, l, h-T(1)) == t ) return true;
  return false;
}

auto Clamp ( float v, float min, float max ) pure nothrow {
  return (v < min ? min : (v > max ? max : v));
}
auto Clamp(T)(T vec, T min, T max) pure nothrow
           if (Is_Vector!T) {
  T ret;
  static foreach ( i; 0 .. T.Dim )
    ret.v[i] = (vec.v[i] < min.v[i] ? min.v[i] :
               (vec.v[i] > max.v[i] ? max.v[i] :
                vec.v[i]));
  return ret;
}

auto Step(float3 o, float3 d) {

}


float3 Clamp ( float3 torig, float3 dir ) {
  return float3(Clamp(torig.x, dir.x),
                Clamp(torig.x, dir.x),
                Clamp(torig.x, dir.x));
}

float Clamp ( float torig, float dir ) {
  return dir <= 0.0f ? floor(torig) : ceil(torig);
}

T Mix (T)(T x, T y, float a) { return cast(T)(y*a + x*(1.0f - a)); }

float Distance ( float3 u, float3 v ) pure nothrow {
  return sqrt(Sqr(u.x-v.x) + Sqr(u.y-v.y) + Sqr(u.z-v.z));
}

float3 To_Cartesian ( float theta, float phi ) {
  return float3(cos(phi)*sin(theta), sin(phi)*sin(theta), cos(theta));
}
