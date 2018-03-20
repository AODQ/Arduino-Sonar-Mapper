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
  // port_com = new SerialPort("/dev/ttyUSB0");
}

int[] RDistances ( int x_iter, int y_iter ) {
  import std.random;
  return cast(int[])[uniform(20.0f, 100.0f), uniform(20.0f, 100.0f)];
}
