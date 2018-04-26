module sonar;
static import gfx;
import klaodg;
import gfm.opengl;
import derelict.opengl;
import svo;
import std.stdio;
static import svorender;
static import botrender;

class SonarMap {
  Octree otree;
  int y_iter = 70, x_iter = 0;
  this ( ) {
    otree = new Octree(float3(0.0f), 100.0f, 6);//SCALE
    string source =
    q{#version 330 core
    #if VERTEX_SHADER
      layout(location = 0) in vec3 origin;
      layout(location = 1) in vec3 normal;
      uniform mat4 projection;
      uniform mat4 view;
      uniform vec3 camera_origin; // light source
      uniform vec3 model_offset;
      uniform float model_size;
    out vec3 frag_wi, frag_Lo, frag_ori, frag_nor, frag_col;

      void main ( ) {
        vec4 O = vec4(model_offset+origin*model_size, 1.0f);
        gl_Position = (projection*view) * O;
        frag_col = vec3(exp(-distance(model_offset.xyz, camera_origin)*0.15f));
        frag_col += vec3(0.2f, 0.6f, 0.4f);
        frag_ori = gl_Position.xyz;
        frag_Lo = vec3(0.0f, 10.0f, 5.0f);
        frag_wi = -normalize(frag_ori);
        frag_nor = normal;
      }
    #endif
    #if FRAGMENT_SHADER
      out vec4 color;
      in vec3 frag_wi, frag_Lo, frag_ori, frag_nor, frag_col;

      void main ( ) {
        // awful "who-cares" shading implementation since there are only
        // non-interesting primitives present anyways
        vec3 L = reflect(-frag_wi, frag_nor);
        color.xyz = vec3(
          dot(frag_nor, normalize(-frag_Lo)) + 0.5f
        )*(L+vec3(0.8f));
        // color.xyz = vec3(1.0f);
        color.w = 1.0f;
      }
    #endif
    };
    program = new gfx.GLProgram(gl_handle, source);

    glGenVertexArrays(1, &voxel_vertex_vao);
    glBindVertexArray(voxel_vertex_vao);
    float[] temp_vertices = gfx.Cube_vertices.dup;
    glGenBuffers(1, &voxel_vertex_vbo);
    glBindBuffer(GL_ARRAY_BUFFER, voxel_vertex_vbo);
    glBufferData(GL_ARRAY_BUFFER, temp_vertices.length*float.sizeof,
                 temp_vertices.ptr, GL_STATIC_DRAW);

    temp_vertices = gfx.Cube_normals.dup;
    glGenBuffers(1, &normal_vbo);
    glBindBuffer(GL_ARRAY_BUFFER, normal_vbo);
    glBufferData(GL_ARRAY_BUFFER, temp_vertices.length*float.sizeof,
                 temp_vertices.ptr, GL_STATIC_DRAW);

    glBindVertexArray(voxel_vertex_vao);
    glEnableVertexAttribArray(0);
    glBindBuffer(GL_ARRAY_BUFFER, voxel_vertex_vbo);
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, null);
    glEnableVertexAttribArray(1);
    glBindBuffer(GL_ARRAY_BUFFER, normal_vbo);
    glVertexAttribPointer(1, 3, GL_FLOAT, GL_TRUE, 0, null);
    svorender.Initialize();
    botrender.Initialize();
    botrender.Set_Origin(float3(0.0f));
  }

  void Build_Geometry ( float3 origin ) {
    if ( ++ voxel_count >= 5012 ) return; // hit limit
    // insert node into tree
    otree.Insert(origin, new VoxelData(origin));
    svorender.Update_Lines(otree);
  }

  float2 RPolar ( int y_iter, int x_iter ) {
    float theta = Mix(0.2f, 0.8f, x_iter/40.0f);
    theta *= PI;
    float phi = -PI*((y_iter-90.0f)/180.0f);
    return float2(theta, phi);
  }

  float3 RNor ( int y_iter, int x_iter, bool left ) {
    float2 P = RPolar(y_iter, x_iter);
    return Normalize(float3(cos(P.x), P.y, sin(P.x)));
  }

  bool finished = false;
  void Update() {
    import arduino;
    auto tbl = RDistances();
    Render(otree.voxel_render_list);
    bool change = tbl.length != 0;
    svorender.Render(otree);
    botrender.Render(RPolar(y_iter, x_iter), change);
    if ( tbl.length == 0 ) return;
    if ( finished ) return;
    float left_dist  = cast(float)tbl[0];
          // right_dist = cast(float)tbl[1];
    float3 left_origin = float3(0.0f,  1.0f, 0.0f);
    // polar coordinates => cartesian coordinates
    if ( left_dist > 1.0f && left_dist < 100.0f ) {
      float3 N = RNor(y_iter, x_iter, true);
      float3 O = left_origin + left_dist*N;
      Build_Geometry(O);
    }
    if ( ++ x_iter == 40 ) {
      x_iter = 0;
      y_iter += 2;
      if ( y_iter >= 110 ) {
        y_iter = 70;
        finished = true;
      }
    }
  }
}

GLuint voxel_vertex_vbo, normal_vbo;
GLuint voxel_vertex_vao;
int voxel_count;
gfx.GLProgram program;

void Render(Range)( Range render_list ) {
  import gfm.sdl2;
  import camera;
  Update_Camera();
  float3 eye = camera_origin, target = eye+camera_target;
  float4x4 projection = gfx.RModel_View,
           view       = float4x4.lookAt(eye, target,
                                   float3(0.0f, -1.0f, 0.0f));
  // model.translate(float3(2.0f));
  program.uniform("projection").set(projection);
  program.uniform("view").set(view);
  program.uniform("camera_origin").set(camera_origin);
  program.use();

  glBindVertexArray(voxel_vertex_vao);

  foreach ( r; render_list ) {
    program.uniform("model_offset").set(r.origin);
    program.uniform("model_size").set(r.size);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 36);
  }
  program.unuse;
}
