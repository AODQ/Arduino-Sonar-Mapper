import std.string : format;
import std.conv : to;
import std.parallelism, std.range;
import klaodg;
import std.stdio;
import serial.device : SerialPort, TimeoutException;

immutable int2 dim = int2(256, 144);
immutable float2 dim_fl = cast(float2)(dim);
immutable int2 cam_dim = int2(20);
SerialPort port_com;

string Serial_Read ( ) {
  try {
    ubyte[100] buff;
    auto amt = port_com.read(buff);
    string t = cast(string)(buff[0 .. amt]~'\0');
    return t;
  } catch ( Exception e ) {
    return "";
  }
}

auto RDistance ( ) {
  struct DistInfo {
    int coord_x;
    float dist;
  }
  string data = Serial_Read();
  if ( data == "" ) return DistInfo(0, -1.0f);
  string[] d = data.split(" ");
  return DistInfo(d[0].to!int, d[1][0..$-1].to!float);
}

// TODO make To_Vec again
auto To_Int2 ( float x , float y ) {
  return int2(cast(int)x, cast(int)y);
}

/*
  sudo usermod -a -G dialout aodq
  sudo chmod a+rw /dev/tty/USB0
*/

int XCast ( int t ) {
  return cast(int)(cast(float)(t)*(dim_fl.x/cast(float)(cam_dim.x)));
}
int t = 0;
void main ( ) {
  import core.time : dur;
  auto timeout = dur!"msecs"(100);
  port_com = new SerialPort("/dev/ttyUSB0");
  Initialize(256, 144, "klaodg arduino", (GLBuffer img, float time) {
    auto info = RDistance();
    if ( t > 19 ) t = 0;
    writeln("T: ", t);
    if ( info.coord_x == 19 ) t += 1;
    bool draw = info.dist > 0.0f;
    if ( info.dist <= 0.0f ) {
    }
    foreach ( i; XCast(info.coord_x) .. XCast(info.coord_x+1) )
    foreach ( j; 0 .. 7.0f ) {
      if ( !draw ) {
        img.Apply(To_Int2(i, (t*8)+j), float4(0.0f, 0.0f, 0.0f, 1.0f));
        continue;
      }
      img.Apply(To_Int2(i, (t*8)+j), float4(1.0f-info.dist, 0.0f, 0.0f, 1.0f));
    }
  });
  port_com.close();
}
