module klaodg;

public import klaodg.buffer, klaodg.vector, klaodg.input;

public import imgui : imguiSeparator, imguiSeparatorLine,
                      imguiLabel, imguiSlider, imguiCheck;

import std.exception, std.file, std.path, std.stdio, std.string;

import derelict.glfw3.glfw3, derelict.opengl;
import klaodg.gui;
import imgui;
// import gui;

private GLFWwindow* window;
GUI* gui;
int window_width, window_height;

alias UpdateDelegate = void delegate(GLBuffer, float time/*, gui*/);

void Initialize ( int width, int height, string title, UpdateDelegate update ) {
  string font_path = thisExePath().dirName().buildPath("DroidSans.ttf");
  window_width  = 640;
  window_height = 480;
  DerelictGL3.load();
  DerelictGLFW3.load();
  glfwInit();

  glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
  glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3);
  glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE );
  glfwWindowHint(GLFW_RESIZABLE,      GL_FALSE                 );
  glfwWindowHint(GLFW_FLOATING,       GL_TRUE                  );
  glfwWindowHint( GLFW_REFRESH_RATE,  0                        );
  glfwSwapInterval(1);

  window = glfwCreateWindow(640, 480, title.ptr, null, null);

  glfwWindowHint(GLFW_FLOATING,       GL_TRUE                  );
  glfwMakeContextCurrent(window);
  DerelictGL3.reload();
  glClampColor(GL_CLAMP_READ_COLOR, GL_FALSE);

  glEnable(GL_DEBUG_OUTPUT_SYNCHRONOUS_ARB);

  enforce(imguiInit("DroidSans.ttf"));

  glClearColor(0.02f, 0.02f, 0.02f, 1.0f);
  glEnable(GL_BLEND);
  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
  glDisable(GL_DEPTH_TEST);

  { // initialize buffer
    import klaodg.glrender : Renderer_Initialize;
    Renderer_Initialize();
  }


  { // gui
    glfwGetWindowSize(window, &window_width, &window_height);

    On_Window_Resize(window, window_width, window_height);
    glfwSetWindowSizeCallback(window, &On_Window_Resize);

    gui = new GUI(0);
  }

  GLBuffer gl_buffer = new GLBuffer(width, height);
  float last_time, framerate;

  while ( !glfwWindowShouldClose(window) ) {
    last_time = glfwGetTime();

    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    Input_Update(window);
    gui.Start_Update(framerate);
    update(gl_buffer, glfwGetTime());
    gl_buffer.Render();
    gui.End_Update();
    glfwSwapBuffers(window);
    glfwPollEvents();

    framerate = glfwGetTime()-last_time;
  }

  imguiDestroy();
}

extern(C) void On_Window_Resize(GLFWwindow* w, int width, int height) nothrow {
  glViewport(0, 0, width, height);

  window_width  = width;
  window_height = height;
}
