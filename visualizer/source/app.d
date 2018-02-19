import std.string : format;
import std.conv : to;
import std.parallelism, std.range;
import klaodg;
import std.stdio;
import serial.device : SerialPort, TimeoutException;
import std.algorithm, std.range;

immutable int2 dim      = int2(256, 144);
immutable float2 dim_fl = cast(float2)(dim);
immutable int2 cam_dim  = int2(140, 6);
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

int[] RDistance ( ) {
  string data = Serial_Read();
  if ( data == "" ) return [];
  string[] d = data.split(" ");
  if ( d.length >= 6 )
    return d[0..6].map!(to!int).array;
  return [];
}

// TODO make To_Vec again
auto To_Int2 ( float x , float y ) {
  return int2(cast(int)x, cast(int)y);
}

/*
  sudo usermod -a -G dialout aodq
  sudo chmod a+rw /dev/tty/USB0
*/

int XCast (T)( T t ) {
  return cast(int)(cast(float)(t)*(dim_fl.x/cast(float)(cam_dim.x)));
}
int YCast (T)( T t ) {
  return cast(int)(cast(float)(t)*(dim_fl.y/cast(float)(cam_dim.y)));
}
int t = 0;


void Apply_Buffer ( GLBuffer img, int[] arr, int x_iter ) {
  foreach ( y_iter, elem; arr ) {
    bool draw = elem > 0;
    foreach ( i; XCast(x_iter) .. XCast(x_iter+1) )
    foreach ( j; YCast(y_iter) .. YCast(y_iter+1) ) {
      auto pos = To_Int2(i, j);
      img.Apply(pos, float4(float3((100-elem)/100.0f)*draw, 1.0f));
    }
  }
}
void main ( ) {
  import core.time : dur;
  auto timeout = dur!"msecs"(100);
  port_com = new SerialPort("/dev/ttyUSB2");
  int it = 0;

  GLBuffer left, right;
  Initialize(dim.x, dim.y, "klaodg arduino",
  () {// init
    left  = new GLBuffer(dim.x, dim.y);
    right = new GLBuffer(dim.x, dim.y);
  }, (GLBuffer img, float time) { //update
    int[] arr = RDistance();
    if ( arr.length == 0 ) return;
    left .Apply_Buffer(arr[0 .. cam_dim.y], it);
    right.Apply_Buffer( arr[0 .. cam_dim.y], it);
    // "overlay" the two
    foreach ( i; 0 .. dim.x )
    foreach ( j; 0 .. dim.y ) {
      auto pos = To_Int2(i, j);
      img.Apply(pos, float4(
        Mix(left.Read(pos), right.Read(pos), 0.5f).xyz, 1.0f));
    }
    if ( ++ it >= cam_dim.x ) it = 0;
  });
  port_com.close();
}
