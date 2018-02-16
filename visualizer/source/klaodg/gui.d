module klaodg.gui;

import derelict.glfw3.glfw3, derelict.opengl;
import std.string : format;
import imgui;
import klaodg : window_width, window_height;
import klaodg.input : mouse;

struct GUI {
  this ( int nothing ) {
    int width, height;
  }

  void Start_Update ( float ms ) {
    imguiBeginFrame(cast(int)mouse.ori.x, cast(int)mouse.ori.y,
                    mouse.frame.left, cast(int)mouse.ori.z);
    mouse.gui_active = false;

    immutable scroll_area_width  = (window_width/4) - 10,
              scroll_area_height = (window_height - 350);

    if ( mouse.any ) {
      if ( mouse.ori.x < scroll_area_width ) mouse.gui_active = true;
    }

    if ( mouse.gui_active && !mouse.any ) mouse.gui_active = false;
    // -- gui --
    int trash;
    imguiBeginScrollArea("Settings", 10, 10, scroll_area_width,
                                             scroll_area_height, &trash);
    imguiLabel("Time: %s ms".format(cast(int)(ms*1000.0f)));
  }
  void End_Update ( ) {
    imguiEndScrollArea();
    imguiEndFrame();
    imguiRender(window_width, window_height);
  }
}
