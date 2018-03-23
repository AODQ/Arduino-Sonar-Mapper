#ifndef AOUTIL_H_
#define AOUTIL_H_

#include <Arduino.h>

// No c++14 support.. no constexpr/ctfe :-(
template <uint32_t a, uint32_t b> struct CTMin {
  static const uint32_t val = (a<b?a:b); };
template <uint32_t a, uint32_t b> struct CTMax {
  static const uint32_t val = (a>b?a:b); };

template <typename T, typename U> T Min(T a, T b) { return U(a<b?a:b); }
template <typename T, typename U> T Max(T a, U b) { return T(a>b?a:b); }

// Template can't go into new line for function (??? bug?)
template <typename T> T Clamp ( T idx, T low, T hi ) {
  if ( idx < low ) return low;
  if ( idx > hi  ) return hi;
  return idx;
}

template <typename T> T Mix ( T x, T y, float a ) {
  return static_cast<T>(y*a + x*(1.0f-a));
}

template <typename T> T Sign(T t) { return (t < T(0)) ? T(-1) : T(+1); }

// Emulate d write(ln)
void write() {}
template <typename F, typename... Arg> void write(const F& f, const Arg&... a) {
  Serial.print(f);
  write(a...);
}

template<typename... Args> void writeln(const Args&... a) {
  write(a..., "\n");
}

#endif
