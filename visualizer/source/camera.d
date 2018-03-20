import klaodg;
import gfm.sdl2;
import std.stdio;

float3 camera_origin = float3(0.0f, 0.0f, -5.0f),
       camera_target = Normalize(float3(0.0f, 0.0f, 1.0f));

void Update_Camera ( ) {
  { // position
    float A = PI - (sdl2.mouse.x/Window_Dim.x)*2.0f*PI;
    float horiz = cast(float)(cast(int)(sdl2.keyboard.isPressed(SDLK_a)) -
                              cast(int)(sdl2.keyboard.isPressed(SDLK_d))),
          verti = cast(float)(cast(int)(sdl2.keyboard.isPressed(SDLK_w)) -
                              cast(int)(sdl2.keyboard.isPressed(SDLK_s)));
    float2 P = float2(verti, horiz);
    P = (cos(A)*P + sin(A)*float2(-P.y, P.x));
    camera_origin.x += P.x*0.5f;
    camera_origin.z += P.y*0.5f;
    float B = PI/2.0f - sdl2.mouse.y/Window_Dim.y*PI;
    camera_target = float3(cos(A), -B, sin(A));
  }
  if ( sdl2.keyboard.isPressed(SDLK_q) ) {
    camera_origin.y -= 0.5f;
  }
  if ( sdl2.keyboard.isPressed(SDLK_e) ) {
    camera_origin.y += 0.5f;
  }
}
