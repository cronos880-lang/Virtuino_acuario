// Imitación mínima de Arduino.h para ejecutar el sketch en el PC (solo pruebas).
#pragma once
#include <cstdint>
#include <cmath>
#include <cstring>
#include <cctype>
#include <cstdio>
#include <string>
#include <deque>

typedef bool boolean;
typedef uint8_t byte;
#define HIGH 1
#define LOW 0
#define OUTPUT 1
#define INPUT 0
#define _BV(b) (1 << (b))
#define PORF 0
#define EXTRF 1
#define BORF 2
#define WDRF 3

class __FlashStringHelper;
#define F(s) (reinterpret_cast<const __FlashStringHelper*>(s))

class String {
 public:
  std::string s;
  String() {}
  String(const char* c) : s(c ? c : "") {}
  String(const std::string& x) : s(x) {}
  String(char c) : s(1, c) {}
  String(int v) : s(std::to_string(v)) {}
  String(unsigned int v) : s(std::to_string(v)) {}
  String(long v) : s(std::to_string(v)) {}
  String(unsigned long v) : s(std::to_string(v)) {}
  String(double v, int dec = 2) { char b[64]; std::snprintf(b, sizeof b, "%.*f", dec, v); s = b; }
  String(float v, int dec = 2) : String((double)v, dec) {}
  unsigned int length() const { return s.size(); }
  char charAt(unsigned int i) const { return i < s.size() ? s[i] : 0; }
  int indexOf(char c, unsigned int desde = 0) const { if (desde >= s.size()) return -1; auto p = s.find(c, desde); return p == std::string::npos ? -1 : (int)p; }
  String substring(unsigned int a) const { return a >= s.size() ? String("") : String(s.substr(a)); }
  String substring(unsigned int a, unsigned int b) const { if (a > b) std::swap(a, b); if (a >= s.size()) return String(""); return String(s.substr(a, b - a)); }
  long toInt() const { return std::atol(s.c_str()); }
  float toFloat() const { return (float)std::atof(s.c_str()); }
  bool equals(const String& o) const { return s == o.s; }
  bool operator==(const char* c) const { return s == c; }
  bool operator==(const String& o) const { return s == o.s; }
  bool operator!=(const String& o) const { return s != o.s; }
  void reserve(unsigned int n) { s.reserve(n); }
  const char* c_str() const { return s.c_str(); }
  String& operator+=(const String& o) { s += o.s; return *this; }
  String& operator+=(const char* c) { s += c; return *this; }
  String& operator+=(char c) { s += c; return *this; }
  String& operator+=(int v) { s += std::to_string(v); return *this; }
  String& operator+=(unsigned long v) { s += std::to_string(v); return *this; }
  friend String operator+(const String& a, const String& b) { return String(a.s + b.s); }
  friend String operator+(const char* a, const String& b) { return String(std::string(a) + b.s); }
};

// Reloj de pruebas: millis() lo controla la prueba
extern uint32_t g_millis;
inline unsigned long millis() { return g_millis; }
inline void delay(unsigned long ms) { g_millis += ms; }

extern uint8_t g_pin[80];
extern int g_pwm[80];
inline void pinMode(uint8_t, uint8_t) {}
inline void digitalWrite(uint8_t p, uint8_t v) { g_pin[p] = v; }
inline int digitalRead(uint8_t p) { return g_pin[p]; }
inline void analogWrite(uint8_t p, int v) { g_pwm[p] = v; }
inline int analogRead(uint8_t) { return 0; }
inline unsigned long pulseIn(uint8_t, uint8_t) { return 0; }
inline void yield() {}

class SerialPrueba {
 public:
  std::deque<char> entrada;
  std::string salida;
  void begin(unsigned long) {}
  void setTimeout(unsigned long) {}
  int available() { return (int)entrada.size(); }
  int read() { if (entrada.empty()) return -1; char c = entrada.front(); entrada.pop_front(); return c; }
  String readStringUntil(char fin) { std::string r; while (!entrada.empty()) { char c = entrada.front(); entrada.pop_front(); if (c == fin) break; r += c; } return String(r); }
  void print(const String& t) { salida += t.s; }
  void print(const char* t) { salida += t; }
  void print(const __FlashStringHelper* t) { salida += (const char*)t; }
  void println(const String& t) { salida += t.s + "\n"; }
  void println(const char* t) { salida += std::string(t) + "\n"; }
  void println(const __FlashStringHelper* t) { salida += std::string((const char*)t) + "\n"; }
  operator bool() const { return true; }
};
extern SerialPrueba Serial, Serial1;
