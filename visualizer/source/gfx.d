module gfx;
public import gfm.opengl;
import klaodg;

float4x4 RModel_View ( ) {
  return float4x4.perspective(1.5f, Window_Dim.x/cast(float)Window_Dim.y,
                              0.1f, 400.0f);
}

float4x4 Translate ( float4x4 mat, float2 vec ) pure {
  mat.translate(float3(vec, 1.0f));
  return mat;
}
float4x4 Scale ( float4x4 mat, float2 vec ) pure {
  mat.scale(float3(vec, 1.0f));
  return mat;
}
float4x4 Rotate ( float4x4 mat, float theta ) pure {
  return float4x4.rotateZ(theta);
}

immutable float[] Cube_vertices = [
  -1.0f, -1.0f, -1.0f, -1.0f, -1.0f, 1.0f,
  -1.0f, 1.0f,  1.0f,  1.0f,  1.0f,  -1.0f,
  -1.0f, -1.0f, -1.0f, -1.0f, 1.0f,  -1.0f,
  1.0f,  -1.0f, 1.0f,  -1.0f, -1.0f, -1.0f,
  1.0f,  -1.0f, -1.0f, 1.0f,  1.0f,  -1.0f,
  1.0f,  -1.0f, -1.0f, -1.0f, -1.0f, -1.0f,
  -1.0f, -1.0f, -1.0f, -1.0f, 1.0f,  1.0f,
  -1.0f, 1.0f,  -1.0f, 1.0f,  -1.0f, 1.0f,
  -1.0f, -1.0f, 1.0f,  -1.0f, -1.0f, -1.0f,
  -1.0f, 1.0f,  1.0f,  -1.0f, -1.0f, 1.0f,
  1.0f,  -1.0f, 1.0f,  1.0f,  1.0f,  1.0f,
  1.0f,  -1.0f, -1.0f, 1.0f,  1.0f,  -1.0f,
  1.0f,  -1.0f, -1.0f, 1.0f,  1.0f,  1.0f,
  1.0f,  -1.0f, 1.0f,  1.0f,  1.0f,  1.0f,
  1.0f,  1.0f,  -1.0f, -1.0f, 1.0f,  -1.0f,
  1.0f,  1.0f,  1.0f,  -1.0f, 1.0f,  -1.0f,
  -1.0f, 1.0f,  1.0f,  1.0f,  1.0f,  1.0f,
  -1.0f, 1.0f,  1.0f,  1.0f,  -1.0f, 1.0f,
];


immutable static float e = 0.57735f;
immutable float[] Cube_normals = [
  -e, -e, -e, -e, -e, e,
  -e, e,  e,  e,  e,  -e,
  -e, -e, -e, -e, e,  -e,
  e,  -e, e,  -e, -e, -e,
  e,  -e, -e, e,  e,  -e,
  e,  -e, -e, -e, -e, -e,
  -e, -e, -e, -e, e,  e,
  -e, e,  -e, e,  -e, e,
  -e, -e, e,  -e, -e, -e,
  -e, e,  e,  -e, -e, e,
  e,  -e, e,  e,  e,  e,
  e,  -e, -e, e,  e,  -e,
  e,  -e, -e, e,  e,  e,
  e,  -e, e,  e,  e,  e,
  e,  e,  -e, -e, e,  -e,
  e,  e,  e,  -e, e,  -e,
  -e, e,  e,  e,  e,  e,
  -e, e,  e,  e,  -e, e,
];
