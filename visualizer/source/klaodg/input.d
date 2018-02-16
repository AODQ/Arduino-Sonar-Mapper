module klaodg.input;
import derelict.glfw3.glfw3;
import klaodg : window_height, window_width;
import klaodg.vector : float3, float2;

private struct MouseKeystate {
  bool left, right, middle;
}
private struct Mouse {
  float3 ori;
  float2 vel;
  MouseKeystate enter, exit, frame;
  bool any, gui_active;
}

Mouse mouse;

void Input_Update ( GLFWwindow* window ) {
  double mx, my;
  glfwGetCursorPos(window, &mx, &my);
  mouse.ori.x = mx;
  mouse.ori.y = window_height - my;
  mouse.vel = mouse.ori.xy - mouse.vel;

  static bool prev_left, prev_middle, prev_right;

  mouse.frame.left   = cast(bool)glfwGetMouseButton(window, GLFW_MOUSE_BUTTON_LEFT);
  mouse.frame.right  = cast(bool)glfwGetMouseButton(window, GLFW_MOUSE_BUTTON_RIGHT);
  mouse.frame.middle = cast(bool)glfwGetMouseButton(window, GLFW_MOUSE_BUTTON_MIDDLE);

  prev_left   = mouse.frame.left;
  prev_middle = mouse.frame.middle;
  prev_right  = mouse.frame.right;

  mouse.enter.left   = mouse.frame.left   && !prev_left;
  mouse.enter.right  = mouse.frame.right  && !prev_right;
  mouse.enter.middle = mouse.frame.middle && !prev_middle;

  mouse.exit.left   = !mouse.frame.left   && prev_left;
  mouse.exit.right  = !mouse.frame.right  && prev_right;
  mouse.exit.middle = !mouse.frame.middle && prev_middle;

  mouse.any = mouse.frame.left || mouse.frame.middle || mouse.frame.right;
}
