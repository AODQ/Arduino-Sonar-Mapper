module botrender;
static import gfx;
import klaodg;
import gfm.opengl;
import derelict.opengl;
import std.stdio;

private float3 bot_origin;

void Set_Origin ( float3 O ) { bot_origin = O; }
private void Initialize_Bot ( ) {
  string source =
  q{#version 330 core
  #if VERTEX_SHADER
    layout(location = 0) in vec3 origin;
    uniform mat4 projection;
    uniform mat4 view;
    uniform mat4 model;

    void main ( ) {
      gl_Position = projection*view*model*vec4(origin, 1.0f);
    }
  #endif
  #if FRAGMENT_SHADER
    uniform float time;
    out vec4 color;

    void main ( ) {
      color.xyz = mix(vec3(0.8f, 0.2f, 0.2f),
                      vec3(0.4f, 0.4f, 0.4f), time);
      color.w = 1.0f;
    }
  #endif
  };
  bot_program = new gfx.GLProgram(gl_handle, source);
  glGenVertexArrays(1, &bot_vao);
  glBindVertexArray(bot_vao);
  float[] t_verts = gfx.Cube_vertices.dup;
  glGenBuffers(1, &bot_vbo);
  glBindBuffer(GL_ARRAY_BUFFER, bot_vbo);
  glBufferData(GL_ARRAY_BUFFER, t_verts.length*float.sizeof,
               t_verts.ptr, GL_STATIC_DRAW);
}
private void Initialize_Frustrum ( ) {
  string source = q{#version 330 core
  #if VERTEX_SHADER
    layout(location = 0) in vec3 origin;
    layout(location = 1) in vec3 colour;
    uniform mat4 projection;
    uniform mat4 view;
    uniform mat4 model;
    out vec3 frag_col;

    void main ( ) {
      gl_Position = (projection*view*model)*vec4(origin, 1.0f);
      frag_col = colour;
    }
  #endif
  #if FRAGMENT_SHADER
    in vec3 frag_col;
    out vec4 color;

    void main ( ) {
      color = vec4(frag_col, 1.0f);
    }
  #endif
  };
  frustrum_program = new gfx.GLProgram(gl_handle, source);
  glGenVertexArrays(1, &frustrum_vao);
  glBindVertexArray(frustrum_vao);
  glGenBuffers(1, &frustrum_vertex_vbo);
  glBindBuffer(GL_ARRAY_BUFFER, frustrum_vertex_vbo);
  glBufferData(GL_ARRAY_BUFFER, Frustrum_verts.length*float.sizeof,
               Frustrum_verts.ptr, GL_STATIC_DRAW);
  glGenBuffers(1, &frustrum_colour_vbo);
  glBindBuffer(GL_ARRAY_BUFFER, frustrum_colour_vbo);
  glBufferData(GL_ARRAY_BUFFER, Frustrum_colours.length*float.sizeof,
               Frustrum_colours.ptr, GL_STATIC_DRAW);
}
void Initialize ( ) {
  Initialize_Bot();
  Initialize_Frustrum();
}

GLuint bot_vbo, bot_vao;
gfx.GLProgram bot_program;

GLuint frustrum_vertex_vbo, frustrum_colour_vbo, frustrum_vao;
gfx.GLProgram frustrum_program;
immutable private float[] Frustrum_verts = [
  0f, 0f, 0f, -36f,  0f, 100f,
  0f, 0f, 0f, +36f,  0f, 100f,
  0f, 0f, 0f,   0f, -7f, 100f,
  0f, 0f, 0f,   0f, +7f, 100f,
  0f, 0f, 0f,   0f,  0f, 100f
];
immutable private float[] Frustrum_colours = [
  1.0f, 0.3f, 0.2f, 1.0f, 0.3f, 0.2f,
  1.0f, 0.3f, 0.2f, 1.0f, 0.3f, 0.2f,
  1.0f, 0.3f, 0.7f, 1.0f, 0.3f, 0.7f,
  1.0f, 0.3f, 0.7f, 1.0f, 0.3f, 0.7f,
  0.6f, 0.6f, 0.7f, 0.6f, 0.6f, 0.7f,
];

void Render ( float2 polar, bool change ) {
  import camera, derelict.sdl2.sdl;
  static float time = 0.0f;
  if ( change ) time = 0.0f;
  time += 0.0166f;
  float3 eye = camera_origin, target = eye+camera_target;
  float4x4 projection = gfx.RModel_View,
           view       = float4x4.lookAt(eye, target,
                                   float3(0.0f, -1.0f, 0.0f)),
           model      = float4x4.identity();
  float gamma = -polar.y, beta = PI/2.0f - polar.x;
  float4x4 Rx = float4x4(
    1.0f, 0.0f, 0.0f, 1.0f,
    0.0f, cos(gamma), -sin(gamma), 1.0f,
    0.0f, sin(gamma), cos(gamma), 1.0f,
    0.0f, 0.0f, 0.0f, 1.0f,
  );
  float4x4 Ry = float4x4(
    cos(beta), 0.0f, sin(beta), 1.0f,
    0.0f, 1.0f, 0.0f, 1.0f,
    -sin(beta), 0.0f, cos(beta), 1.0f,
    0.0f, 0.0f, 0.0f, 1.0f,
  );
  model = (Ry*Rx)*model;
  model.translate(bot_origin);
  // -- draw base --
  bot_program.uniform("projection").set(projection);
  bot_program.uniform("view").set(view);
  bot_program.uniform("model").set(model);
  bot_program.uniform("time").set(time);
  bot_program.use();

  glBindVertexArray(bot_vao);
  glEnableVertexAttribArray(0);
  glBindBuffer(GL_ARRAY_BUFFER, bot_vbo);
  glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, null);

  glDrawArrays(GL_TRIANGLE_STRIP, 0, 36);

  bot_program.unuse();
  // -- draw lines --
  frustrum_program.uniform("projection").set(projection);
  frustrum_program.uniform("view").set(view);
  frustrum_program.uniform("model").set(model);
  frustrum_program.use();

  glBindVertexArray(frustrum_vao);
  glEnableVertexAttribArray(0);
  glBindBuffer(GL_ARRAY_BUFFER, frustrum_vertex_vbo);
  glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, null);

  glEnableVertexAttribArray(1);
  glBindBuffer(GL_ARRAY_BUFFER, frustrum_colour_vbo);
  glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 0, null);

  glEnable(GL_LINE_SMOOTH);
  glDrawArrays(GL_LINES, 0, cast(uint)(Frustrum_verts.length/3));
  glDisable(GL_LINE_SMOOTH);

  frustrum_program.unuse();
}
