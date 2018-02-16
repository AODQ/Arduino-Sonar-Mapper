module klaodg.glrender;

// /***
//   A simple live GL3 renderer
// ***/
import derelict.opengl;
import std.stdio : writeln;

private GLuint shader_id;
private int def_attr_tex;
private GLuint VBO, VAO, EBO, VBO_UV;
private GLfloat[] vertices = [
    -1.0f, -1.0f,
    -1.0f,  1.0f,
     1.0f,  1.0f,
     1.0f, -1.0f
];

private GLubyte[] elements = [
  0, 1, 2,
  0, 2, 3
];

private const GLchar* vertex_shader = `
  #version 330
  const vec2 distr = vec2(0.5, 0.5);
  layout (location = 0) in vec2 vertices;
  out vec2 Texcoord;
  void main ( ) {
    Texcoord = vertices*distr + distr;
    gl_Position = vec4(vertices, 0.0, 1.0);
  }
`;

private const GLchar* fragment_shader =  `
  #version 330
  in vec2 Texcoord;
  uniform sampler2D Tex;
  void main() {
    gl_FragColor.rgba = vec4(texture(Tex, Texcoord).rgba);
  }
`;

private void Check_Shader_Error ( int handle, string type ) @trusted {
  GLint compile_status;
  glGetShaderiv(handle, GL_COMPILE_STATUS, &compile_status);
  if ( compile_status == GL_FALSE ) {
    writeln(type ~ " shader compilation failed");
    writeln("--------------------------------------");

  GLchar[256] error_message;
    glGetShaderInfoLog(handle, 256, null, error_message.ptr);
    writeln(error_message);
    writeln("--------------------------------------");
    assert(0);
  }
}

/// Initialize OpenGL buffers/objects, texture and shader
void Renderer_Initialize() {
  // --- create shader ---
  shader_id      = glCreateProgram();
  auto def_vert_handle = glCreateShader(GL_VERTEX_SHADER),
       def_frag_handle = glCreateShader(GL_FRAGMENT_SHADER);
  glShaderSource     (def_vert_handle, 1, &vertex_shader, null);
  glShaderSource     (def_frag_handle, 1, &fragment_shader, null);
  glCompileShader    (def_frag_handle);
  Check_Shader_Error (def_frag_handle, "fragment");
  glCompileShader    (def_vert_handle);
  Check_Shader_Error (def_vert_handle, "vertex");
  glAttachShader     (shader_id, def_vert_handle);
  glAttachShader     (shader_id, def_frag_handle);
  glLinkProgram      (shader_id);
  glUseProgram       (shader_id);

  GLint compile_status;
  glGetProgramiv(shader_id, GL_LINK_STATUS, &compile_status);
  if ( compile_status == GL_FALSE ) {
    writeln("link shader compilation failed");
    writeln("--------------------------------------");
    GLchar[256] error_message;
    glGetProgramInfoLog(shader_id, 256, null, error_message.ptr);
    writeln(error_message);
    writeln("--------------------------------------");
    assert(0);
  }
  def_attr_tex  = glGetAttribLocation (shader_id, "Tex"   );

  // --- create defaults ---
  glGenVertexArrays(1, &VAO);
  glGenBuffers(1, &VBO);
  glGenBuffers(1, &EBO);
  glBindVertexArray(VAO);

  glBindBuffer(GL_ARRAY_BUFFER, VBO);
  glBufferData(GL_ARRAY_BUFFER, vertices.length*float.sizeof, vertices.ptr,
               GL_STATIC_DRAW);
  glEnableVertexAttribArray(0);
  glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, 0, null);

  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, EBO);
  glBufferData(GL_ELEMENT_ARRAY_BUFFER, elements.length*elements.sizeof,
                                        elements.ptr, GL_STATIC_DRAW);
}

/// Render a texture
void Render ( uint gl_texture ) {
  // -- render texture --
  glUseProgram(shader_id);
  glBindVertexArray(VAO);

  glActiveTexture(GL_TEXTURE0);
  glBindTexture(GL_TEXTURE_2D, gl_texture);
  glUniform1i(def_attr_tex, 0);
  Error_Check("uniform");

  glBindBuffer(GL_ARRAY_BUFFER, VBO);
  Error_Check("buffer data/bind 2");
  glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_BYTE, null);
  Error_Check("render");
}


private void Error_Check ( string desc ) {
  auto res = glGetError();
  assert(res == 0, "Found error: " ~ glErrorString(res) ~ " at " ~ desc);
}
private string glErrorString(GLenum err) {
  switch(err) {
    case GL_INVALID_ENUM:      return "Invalid Enum";
    case GL_INVALID_VALUE:     return "Invalid Value";
    case GL_INVALID_OPERATION: return "Invalid Operation";
    case GL_OUT_OF_MEMORY:     return "Out of Memory";
    default: return "Unknown Error";
  }
}
