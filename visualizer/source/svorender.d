module svorender;
static import gfx;
import klaodg;
import derelict.opengl;
import gfm.opengl;
import svo;

// debug octree rendering!

GLuint otree_vtx_vbo, otree_vtx_vao, otree_vtx_ebo;
gfx.GLProgram program;

private float[] otree_lines = [
  300, 200, 0,
  200, 300, 0,
];
private uint[] otree_indices = [
  0, 1
];

void Initialize ( ) {
  string source =
  q{#version 330 core
  #if VERTEX_SHADER
    layout(location = 0) in vec3 origin;
    uniform mat4 projection;
    uniform mat4 view;
    out vec3 frag_wi, frag_Lo, frag_ori, frag_nor;

    void main ( ) {
      vec4 O = vec4(origin, 1.0f);
      gl_Position = (projection*view)*O;
      frag_ori = gl_Position.xyz;
      frag_Lo = vec3(0.0f, 10.0f, 5.0f);
      frag_wi = -normalize(frag_ori);
      frag_nor = vec3(0.0f, 1.0f, 0.0f);
    }
  #endif
  #if FRAGMENT_SHADER
    in vec3 frag_wi, frag_Lo, frag_ori, frag_nor;
    out vec4 color;

    void main ( ) {
      color = vec4((0.8f+clamp(frag_wi, 0.0f, 0.2f)), 1.0f);
    }
  #endif
  };
  writeln("Initializing octree renderer");
  program = new gfx.GLProgram(gl_handle, source);
  glGenVertexArrays(1, &otree_vtx_vao);
  glBindVertexArray(otree_vtx_vao);
  glGenBuffers(1, &otree_vtx_vbo);
  // glGenBuffers(1, &otree_vtx_ebo);
  Update_Buffers();

  glEnableVertexAttribArray(0);
  glBindBuffer(GL_ARRAY_BUFFER, otree_vtx_vbo);
  glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, null);
}

private void Update_Buffers ( ) {
  glBindBuffer(GL_ARRAY_BUFFER, otree_vtx_vbo);
  glBufferData(GL_ARRAY_BUFFER, 150_000*3*float.sizeof, otree_lines.ptr,
               GL_STREAM_DRAW);
  // glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, otree_vtx_ebo);
  // glBufferData(GL_ELEMENT_ARRAY_BUFFER, 150_000*uint.sizeof, otree_indices.ptr,
  //              GL_STREAM_DRAW);
}

private void Construct_Lines ( ref OctreeNode* N ) {
  // if ( head.data !is null ) return;
  // add to list
  float3 L = N.center - float3(N.radius),
         H = N.center + float3(N.radius);
  float x = H.x, y = H.y, z = H.z,
        X = L.x, Y = L.y, Z = L.z;
  // LL -> UL
  uint I = cast(uint)otree_lines.length;
  otree_lines ~= [
    x, y, z, x, y, Z, x, y, z, x, Y, z, x, y, z, X, y, z,
    X, y, z, X, Y, z, X, y, z, X, y, Z, x, Y, z, x, Y, Z,
    x, Y, z, X, Y, z, x, y, Z, X, y, Z, x, y, Z, x, Y, Z,
    X, Y, Z, X, y, Z, X, Y, Z, x, Y, Z, X, Y, Z, X, Y, z
  ];
  // otree_lines = [
  //   x, y, z, x, y, Z, x, Y, Z, x, Y, z,
  //   X, y, Z, X, Y, Z, X, Y, z, X, y, z,
  // ];
  // otree_indices ~= [
  //   I+0, I+1, I+0, I+3, I+0, I+7,
  //   I+7, I+6, I+7, I+4, I+3, I+2,
  //   I+3, I+6, I+1, I+4, I+1, I+2,
  //   I+5, I+4, I+5, I+2, I+5, I+6,
  // ];
  foreach ( ch; N.children )
    if ( ch !is null ) ch.Construct_Lines;
}
void Update_Lines ( ref Octree octree ) {
  // rebuild lines
  otree_lines = [];
  otree_indices = [];
  Construct_Lines(octree.head);
  // pass back to gl
  Update_Buffers();
}

void Render ( ref Octree octree ) {
  import camera, derelict.sdl2.sdl;
  static bool render = true;
  if ( sdl2.keyboard.testAndRelease(SDLK_1) ) {
    render ^= 1;
  }
  if ( !render ) return;
  float3 eye = camera_origin, target = eye+camera_target;
  float4x4 projection = gfx.RModel_View,
           view       = float4x4.lookAt(eye, target,
                                   float3(0.0f, -1.0f, 0.0f));

  program.uniform("projection").set(projection);
  program.uniform("view").set(view);
  program.use();
  glBindVertexArray(otree_vtx_vao);

  glEnable(GL_LINE_SMOOTH);
  glDrawArrays(GL_LINES, 0, cast(uint)(otree_lines.length/3));
  glDisable(GL_LINE_SMOOTH);
  // glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, otree_vtx_ebo);

  // glDrawElements(GL_LINES, cast(uint)(otree_indices.length), GL_UNSIGNED_INT,
                 // null);
  program.unuse();
}
