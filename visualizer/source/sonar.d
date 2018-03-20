module sonar;
static import gfx;
import klaodg;
import gfm.opengl;
import derelict.opengl;
import svo : Octree;
import std.stdio;

struct VoxelVertex {
  float3 origin;
  float3 col;
}
alias VoxelSpecification = gfx.VertexSpecification!VoxelVertex;


class SonarMap {
  Octree otree;
  int y_iter = 70, x_iter = 0;
  this ( ) {
    otree = new Octree(float3(0.0f), 100.0f, 64);
    string source =
    q{#version 330 core
    #if VERTEX_SHADER
      layout(location = 0) in vec3 origin;
      layout(location = 1) in vec4 offset;
      out vec3 frag_col;
      uniform mat4 map_matrix;
      uniform vec3 camera_origin;
      void main ( ) {
        gl_Position = map_matrix * vec4(origin+offset.xyz, 1.0f);
        frag_col = vec3(exp(-distance(offset.xyz, camera_origin)*0.15f));
        frag_col += vec3(0.2f, 0.1f, 0.0f);
      }
    #endif
    #if FRAGMENT_SHADER
      in vec3 frag_col;
      out vec4 color;

      void main ( ) {
        color.xyz = frag_col;
        // color.xyz = vec3(1.0f);
        color.w = 1.0f;
      }
    #endif
    };
    program = new gfx.GLProgram(gl_handle, source);
    voxel_specification = new VoxelSpecification(program);

    glGenVertexArrays(1, &voxel_vertex_vao);
    glBindVertexArray(voxel_vertex_vao);
    float[] temp_vertices = gfx.Cube_vertices.dup;
    glGenBuffers(1, &voxel_vertex_vbo);
    glBindBuffer(GL_ARRAY_BUFFER, voxel_vertex_vbo);
    glBufferData(GL_ARRAY_BUFFER, temp_vertices.length*float.sizeof,
                 temp_vertices.ptr, GL_STATIC_DRAW);

    glGenBuffers(1, &voxel_origin_vbo);
    glBindBuffer(GL_ARRAY_BUFFER, voxel_origin_vbo);
    glBufferData(GL_ARRAY_BUFFER, 5012*4*float.sizeof, null, GL_STREAM_DRAW);
    Build_Geometry(float3(0.0f, 1.0f, -15.24f/2.0f));
    Build_Geometry(float3(0.0f, 1.0f,  15.24f/2.0f));
  }

  void Build_Geometry ( float3 origin ) {
    if ( ++ voxel_count >= 5012 ) return; // hit limit
    float4 T = float4(origin, 1.0f);
    writeln(voxel_origin_vbo);
    glBindVertexArray(voxel_vertex_vao);
    glBindBuffer(GL_ARRAY_BUFFER, voxel_origin_vbo);
    glBufferData(GL_ARRAY_BUFFER, 5012*4*float.sizeof, null, GL_STREAM_DRAW);
    glBufferSubData(GL_ARRAY_BUFFER, voxel_count*4*float.sizeof, 4*float.sizeof,
                    T.ptr);
  }

  float3 ROrigin ( float3 O, float dist, int y_iter, int x_iter ) {
    float theta = Mix(0.2f, 0.45f, x_iter/40.0f);
    y_iter -= 90;
    float3 N = Normalize(float3(cos(theta), y_iter/180.0f, sin(theta)));
    N.y.writeln;
    return O+dist*N;
  }

  bool finished = false;
  void Update() {
    import arduino;
    auto tbl = RDistances(x_iter, y_iter);
    if ( tbl.length == 0 ) return;
    Render();
    if ( finished ) return;
    float left_dist  = cast(float)tbl[0],
          right_dist = cast(float)tbl[1];
    float3 left_origin = float3(0.0f,  1.0f, -15.24f/2.0f),
           right_origin = float3(0.0f, 1.0f,  15.24f/2.0f);
    // polar coordinates => cartesian coordinates
    if ( left_dist > 1.0f )
      Build_Geometry(ROrigin(left_origin, left_dist, y_iter, x_iter));
    if ( right_dist > 1.0f )
      Build_Geometry(ROrigin(right_origin, right_dist, y_iter, 40-x_iter));
    // otree.Insert(left_origin+left_nor*left_dist,
    //              new VoxelData(left_origin, left_nor, left_dist));
    // otree.Insert(right_origin+right_nor*right_dist,
    //              new VoxelData(right_origin, right_nor, right_dist));
    if ( ++ x_iter == 40 ) {
      x_iter = 0;
      y_iter += 10;
      if ( y_iter >= 110 ) {
        y_iter = 70;
        finished = true;
      }
    }
  }
}

// TODO : instancing implementation with size
GLuint voxel_vertex_vbo, voxel_origin_vbo;
GLuint voxel_vertex_vao;
VoxelSpecification voxel_specification;
int voxel_count;
gfx.GLProgram program;

void Render ( ) {
  import gfm.sdl2;
  import camera;
  Update_Camera();
  float3 eye = camera_origin, target = eye+camera_target;
  float4x4 projection = gfx.RModel_View,
           view       = float4x4.lookAt(eye, target,
                                   float3(0.0f, -1.0f, 0.0f));
  view.translate(float3(0.0f));
  float4x4 model = float4x4.identity;
  model.translate(float3(2.0f));
  program.uniform("map_matrix").set(projection*view*model);
  program.uniform("camera_origin").set(camera_origin);
  program.use();

  glBindVertexArray(voxel_vertex_vao);
  glEnableVertexAttribArray(0);
  glBindBuffer(GL_ARRAY_BUFFER, voxel_vertex_vbo);
  glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, null);

  glEnableVertexAttribArray(1);
  glBindBuffer(GL_ARRAY_BUFFER, voxel_origin_vbo);
  glVertexAttribPointer(1, 4, GL_FLOAT, GL_FALSE, 0, null);

  glVertexAttribDivisor(0, 0);
  glVertexAttribDivisor(1, 1);

  glDrawArraysInstanced(GL_TRIANGLE_STRIP, 0, 36, voxel_count);
  program.unuse;
}
