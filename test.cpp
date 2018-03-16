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

template <int Pin>
struct Rotatal {
  CameraServo* servo_x, * servo_y;
  void Init ( ) {
    servo_y = new CameraServo(Pin+0);
    servo_x = new CameraServo(Pin+1);
  }

  void Set ( float x, float y ) {
    servo_y->Apply(y);
    servo_x->Apply(x);
  }
};

template <int Sonar_amt, int Sonar_dist, int Servo_x, int Iters>
struct Camera {
  static_assert(Sonar_amt%2 == 0, "Must have even number of sensors");
  using SonarPool = ParallelSonar<Sonar_amt, Sonar_dist>;
  Rotatal<Servo_x>  left;
  Rotatal<Servo_x+2>right;
  SonarPool* sonar_pool;
  int y_iter = 90;

  void Init ( ) {
    Serial.begin(9600);
    left.Init();
    right.Init();
    sonar_pool = new SonarPool();
    Clean_Reset();
  }


  void Clean_Reset ( ) {
    left .Set(1.0f, y_iter/180.0f);
    right.Set(0.0f, y_iter/180.0f);
  }

  void Sweep () {
    const float it_fl = static_cast<float>(Iters);
    float d = 0.0f;
    delay(100);
    for ( int i = 0; i != Iters; ++ i ) {
      right.Set(Mix(0.2f, 0.4f, i/it_fl), (y_iter+10)/180.0f);
      left .Set(1.0f - Mix(0.2f, 0.4f, i/it_fl), y_iter/180.0f);
      delay(50); // delay to avoid screwing up parallel sonar pin readings
      unsigned long data[Sonar_amt];
      unsigned long rdata[Sonar_amt];
      for ( int avg = 0; avg != 20; ++ avg ) {
        sonar_pool->Ping(data);
        for ( int it = 0; it != Sonar_amt; ++ it )
          rdata[it] += data[it];
        delay(10);
      }
      for ( auto& rd : rdata )
        rd /= 20;
      for ( auto&& d : rdata )
        write(d, " ");
    }
    y_iter += 10;
    if ( y_iter >= 110 ) y_iter = 70;
    Clean_Reset();
  }
};

// template <int Sonar_amt, int Sonar_dist, int Servo_x, int Iters>
Camera<2, 100, 9, 20> camera;

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
