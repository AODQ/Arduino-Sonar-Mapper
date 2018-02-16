#include <NewPing.h>
#include <Servo.h>

// --- util -------------------------------------------------------------------
float Clamp ( float idx, float low, float hi ) {
  if ( idx < low ) return low;
  if ( idx > hi  ) return hi;
  return idx;
}

float Mix ( float x, float y, float a ) {
  return y*a + x*(1.0f-a);
}

void writeln() {}
// Template can't go into new line for function (??? bug?). Emulate d writeln
template <typename F, typename... Args> void writeln(
                      const F& f, const Args&... a) {
  Serial.print(f);
  writeln(a...);
}

template <int Sensor_trig, int Sensor_echo, int Sensor_dist>
struct CameraSensor {
  NewPing* sensor;

  CameraSensor ( ) {
    sensor = new NewPing(Sensor_trig, Sensor_echo, Sensor_dist);
  }

  // return distance 0.0f .. 1.0f
  float RDist ( ) {
    // 0 .. Sensor_dist
    float t = sensor->convert_cm(sensor->ping_median(2));
    return t/static_cast<float>(Sensor_dist);
  }
};

struct CameraServo {
private:
  float theta;
public:
  Servo servo;
  CameraServo ( ) {}
  CameraServo ( int idx ) {
    servo.attach(idx);
    theta = servo.read()/180.0f;
  }

  float RTheta ( ) { return theta; }
  // 0.0f .. 1.0f
  void Apply ( float i ) {
    theta = Clamp(i, 0.0f, 1.0f);
    servo.write(int(i*180.0f));
  }
};

template <int Sensor_trig, int Sensor_echo, int Servo_x, int Sensor_dist,
          int Y_iters>
struct Camera {
  using CameraSensorT = CameraSensor<Sensor_trig, Sensor_echo, Sensor_dist>;
  CameraServo* servo_x , * servo_y;
  CameraSensorT* sensor_x;
  int y_iter = 0;

  void Init ( ) {
    servo_x = new CameraServo(Servo_x);
    servo_y = new CameraServo(Servo_x+1);
    sensor_x = new CameraSensorT();
    Clean_Reset(servo_x);
    Clean_Reset(servo_y);
  }

  void Setup ( ) {
    Serial.begin(9600);
  }

  void Clean_Reset ( CameraServo* servo ) {
    int t = int(servo->RTheta()*180.0f);
    while ( t -- != 0 ) {
      servo->Apply(t/180.0f);
      delay(1);
    }
  }

  void Sweep ( int iterations ) {
    const float it_fl = static_cast<float>(iterations);
    for ( int i = 0; i != iterations; ++ i ) {
      servo_x->Apply(Mix(0.2f, 0.8f, i/it_fl));
      writeln(i, " ", sensor_x->RDist());
    }
    Clean_Reset(servo_x);
    if ( ++ y_iter == Y_iters ) {
      y_iter = 0;
      Clean_Reset(servo_y);
    }
    servo_y->Apply(Mix(0.2f, 0.8f, float(y_iter)/Y_iters));
  }
};

Camera<2, 3, 9, 50, 20> camera;

void setup(){
  camera.Init();
  camera.Setup();
}

#include <Chrono.h>
Chrono chrono;
void loop() {
  chrono.restart(0);
  chrono.resume();

  camera.Sweep(20);

  chrono.stop();
  // writeln(" ms: ", chrono.elapsed());
}
