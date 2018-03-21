module arduino;
import serial.device;
import klaodg;
import std.stdio;
import std.math;

SerialPort port_com;

string Serial_Read ( ) {
  try {
    ubyte[100] buff;
    auto amt = port_com.read(buff);
    string t = cast(string)(buff[0 .. amt]~'\0');
    return t;
  } catch ( Exception e ) { return ""; }
}

void Initialize_Serial_Port ( ) {
  port_com = new SerialPort("/dev/ttyUSB0");
}

// int[] RDistances ( ) {
//   import std.random;
//   return cast(int[])([uniform(0f, 100f), uniform(0f, 100f)]);
// }

int[] RDistances ( ) {
  import std.string, std.algorithm, std.conv, std.array;
  string data = Serial_Read();
  if ( data == "" ) return [];
  string[] d = data.split(" ");
  writeln(d);
  try {
  if ( d.length >= 1 )
    return [ d[0].to!int ];
  } catch ( Exception e ) {
    writeln("exception getting distance: ", e);
    return []; }
  return [];
}
