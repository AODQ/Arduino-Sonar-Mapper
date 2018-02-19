#include <AOUtil.h>
#include <ParallelSonar.h>
#include <Arduino.h>
#include <avr/io.h>
#include <avr/interrupt.h>

using ParallelSonarT = ParallelSonar<6>;
ParallelSonarT* pool;
void setup ( ) {
  Serial.begin(9600);
  pool = new ParallelSonarT();
}

void loop ( ) {
  unsigned long widths[6];
  pool->Ping(widths);

  for ( const auto& w : widths )
    writeln(w);
  writeln("---");
}