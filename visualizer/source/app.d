import klaodg;
import sonar;
import std.stdio;

immutable int2 dim      = int2(640, 480);
Ray Look_At ( float2 uv, float3 eye, float3 center,
              float3 up = float3(0.0f, 1.0f, 0.0f)) {
  float3 ww = Normalize(center - eye),
         uu = Normalize(cross(up, ww)),
         vv = Normalize(cross(ww, uu));
  return Ray(eye, Normalize(uv.x*uu + uv.y*vv + 2.5*ww));
}

SonarMap sonar_map;


void main ( ) {
  import arduino : Initialize_Serial_Port;
  import gfm.sdl2;
  Initialize_Klaodg(dim.x, dim.y, 16, "thingie");
  Initialize_Serial_Port();
  sonar_map = new SonarMap();

  SDL_Event sdl_event;
  SDL_PushEvent(&sdl_event);
  float last_time, framerate;
  while ( true ) {
    if ( sdl2.wasQuitRequested ||
         sdl2.keyboard.isPressed(SDLK_BACKQUOTE) ) break;
    last_time = SDL_GetTicks();

    Start_Frame_Render();

    sonar_map.Update();

    End_Frame_Render();
    SDL_PumpEvents();
    SDL_Delay(1);

    framerate = SDL_GetTicks()-last_time;
    if ( framerate < 15.0f )
      writeln(framerate, " ms");
  }
}
