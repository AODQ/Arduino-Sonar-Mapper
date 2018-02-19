#include <AOUtil.h>
#include <ParallelSonar.h>
#include <Arduino.h>
#include <avr/io.h>
#include <avr/interrupt.h>

#include <Servo.h>

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
    // LINE BELOW BREAKS SONAR ???
    servo.write(int( i*180.0f ));
  }
};

template <int Sonar_amt, int Sonar_dist, int Servo_x, int Iters>
struct Camera {
  static_assert(Sonar_amt%2 == 0, "Must have even number of sensors");
  using SonarPool = ParallelSonar<Sonar_amt, Sonar_dist>;
  CameraServo* servo_left, * servo_right; // No unique ptr.. but not really necessary anyways
  SonarPool* sonar_pool;
  int y_iter = 0;

  void Init ( ) {
    Serial.begin(9600);
    servo_left  = new CameraServo(Servo_x);
    servo_right = new CameraServo(Servo_x+1);
    sonar_pool = new SonarPool();
    Clean_Reset();
  }

  void Clean_Reset ( ) {
    int l = int(servo_left->RTheta()*180.0f),
        r = int(servo_right->RTheta()*180.0f);
    while ( l != 0 && r != 180 ) {
      if ( l != 0   ) servo_left ->Apply((--l)/180.0f);
      if ( r != 180 ) servo_right->Apply((++r)/180.0f);
    }
  }

  void Sweep () {
    const float it_fl = static_cast<float>(Iters);
    float d = 0.0f;
    for ( int i = 0; i != Iters; ++ i ) {
      servo_left->Apply(Mix(0.2f, 0.8f, i/it_fl));
      servo_right->Apply(1.0f - Mix(0.2f, 0.8f, i/it_fl));
      delay(250); // delay to avoid screwing up parallel sonar pin readings
      unsigned long data[Sonar_amt];
      sonar_pool->Ping(data);
      for ( auto&& d : data )
        write(d, " ");
    }
    Clean_Reset();
  }
};

// template <int Sonar_amt, int Sonar_dist, int Servo_x, int Iters>
Camera<6, 100, 11, 140> camera;

void setup(){
  camera.Init();
}

#include <Chrono.h>
Chrono chrono;
void loop() {
  chrono.restart(0);
  chrono.resume();

  camera.Sweep();

  chrono.stop();
}
