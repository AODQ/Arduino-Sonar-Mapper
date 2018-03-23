#ifndef PARALLEL_SONAR_H_
#define PARALLEL_SONAR_H_
#include <Arduino.h> // uint8_t

template <int Length, int Distance>
struct ParallelSonar {
private:
  static_assert(Length <= 6, "Maximum of 6 sonars");
  static const uint8_t Port      = 4,
                       Sonar_pin = 4;
  uint8_t bits[Length];
  void Trigger_Sonar ( ) {
    /* pinMode(Sonar_pin, OUTPUT); */
    delay(10);
    digitalWrite(Sonar_pin, LOW);
    delayMicroseconds(2);
    digitalWrite(Sonar_pin, HIGH);
    delayMicroseconds(10);
    digitalWrite(Sonar_pin, LOW);
    /* pinMode(Sonar_pin, INPUT); */
  }
public:
  ParallelSonar ( ) {
    pinMode(Sonar_pin  , OUTPUT);
    digitalWrite(Sonar_pin, LOW);
    for ( int i = 0; i != Length; ++ i ) {
      bits[i] = digitalPinToBitMask(i+2);
      pinMode(i+2, INPUT);
    }
  }
  void Ping ( unsigned long* timers ) {
    // trigger sonar -> capture all information ASAP -> play back captured
    //   information to apply information to all sonars -> organize collected
    //   data and retrieve the distance

    // -- initialize stamp holding information
    uint8_t bit_stamps[Length*5];
    unsigned long bit_timer[Length*5];
    int bit_stamps_length = 0;
    uint8_t bit_mask = 0, prev_val = -1; // capture first state
    for ( const auto& bit : bits ) bit_mask |= bit;

    // trigger sonars
    Trigger_Sonar();

    // speed of light = 0.0343cm/μs
    // sonar travels 1 cm in 29.155 μs, thus a round trip is 1cm per 58μs, and some extra
    // for sonar delay
    auto max_time = micros() + (unsigned long)(Distance)*58 + 2800;
    // -- this loop has to be as fast as possible to reduce the possibility
    //    of missing the rising/falling edge of all 6 sonars.
    //    This is why the limitation of 6 exists, so per each iteration
    //    I only have to poll the port (2..6) once.
    while ( true ) {
      if ( micros() > max_time ) break;
      uint8_t value = (*portInputRegister(Port)) & bit_mask;
      if ( value != prev_val ) { // change made
        bit_timer [bit_stamps_length] = micros();
        bit_stamps[bit_stamps_length] = value;
        ++ bit_stamps_length;
        prev_val = value;
        if ( bit_stamps_length >= Length*5 ) break;
      }
    }

    // initialize state holding information
    unsigned long it_time[Length*5];
    uint8_t it_prev[Length];
    int it_length[Length];
    for ( int i = 0; i != Length; ++ i ) {
      it_prev[i] = -1; // capture first state
      it_length[i] = 0;
    }
    // -- play back our previous results
    uint8_t port_val, bit_val;
    for ( int stamp_iter = 0; stamp_iter != bit_stamps_length; ++ stamp_iter ) {
      auto stamp_val = bit_stamps[stamp_iter];
      auto stamp_time_val = bit_timer[stamp_iter];
      for ( int i = 0; i != Length; ++ i ) { // collect data for each sonar
        auto bit_val = stamp_val&bits[i];
        if ( it_prev[i] != bit_val ) {
          it_time[i*5 + it_length[i]] = stamp_time_val;
          ++it_length[i];
          it_prev[i] = bit_val;
        }
      }
    }

    // -- organize previous data
    for ( int i = 0; i != Length; ++ i ) {
      if ( it_length[i] != 3 ) {
        timers[i] = 0;
        continue;
      }
      auto length = (it_time[i*5 + 2] - it_time[i*5 + 1]);
      // cm per sec => 34,300 => per us => 0.0343
      timers[i] = (length/2.0f)*0.0343f;
    }
  }
};

#endif
