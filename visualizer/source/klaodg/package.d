module klaodg;

public import klaodg.vector;
import derelict.util.loader;
import gfm.logger, gfm.sdl2, gfm.opengl, gfm.math;

ConsoleLogger console;
SDL2 sdl2;
SDLTTF sdl2ttf;
SDLImage sdl2image;
SDL2Window window;
OpenGL gl_handle;
private int width, height;
private float ms_per_frame;
float2 Window_Dim ( ) { return float2(width, height); }
float MS_Per_Frame ( ) { return ms_per_frame; }

void Initialize_Klaodg ( int _width, int _height, float _ms_per_frame,
                        string _name ) {
  ms_per_frame = _ms_per_frame;
  width = _width; height = _height;
  console = new ConsoleLogger();
  sdl2 = new SDL2(console, SharedLibVersion(2, 0, 0));
  gl_handle = new OpenGL(console);

  sdl2.subSystemInit(SDL_INIT_VIDEO);
  sdl2.subSystemInit(SDL_INIT_EVENTS);
  sdl2image = new SDLImage(sdl2, IMG_INIT_PNG);
  sdl2ttf   = new SDLTTF(sdl2);

  SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 3);
  SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 3);
  SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK,
                      SDL_GL_CONTEXT_PROFILE_CORE);
  window = new SDL2Window(sdl2, SDL_WINDOWPOS_UNDEFINED,
                          SDL_WINDOWPOS_UNDEFINED,
                          width, height, SDL_WINDOW_OPENGL);
  gl_handle.reload();
  gl_handle.redirectDebugOutput();
  glViewport(0, 0, width, height);
  glEnable(GL_BLEND);
  glEnable(GL_DEPTH_TEST);
  glDepthFunc(GL_LESS);
  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
  window.setTitle(_name);

  //----
}

private bool is_rendering = false;
bool Render_State ( ) { return is_rendering; }
void Start_Frame_Render ( ) {
  sdl2.processEvents();
  glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
  is_rendering = true;
}
void End_Frame_Render ( ) {
  window.swapBuffers();
  is_rendering = false;
}


void Clean ( ) {
  console.destroy;
  sdl2.destroy;
  sdl2image.destroy;
  window.destroy;
  gl_handle.destroy;
}
