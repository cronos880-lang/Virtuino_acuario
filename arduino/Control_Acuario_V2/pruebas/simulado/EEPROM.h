#pragma once
#include <cstring>
#include <cstdint>
struct EEPROMPrueba {
  uint8_t mem[4096];
  int escrituras = 0;
  template <typename T> T& get(int dir, T& v) { std::memcpy(&v, mem + dir, sizeof(T)); return v; }
  template <typename T> const T& put(int dir, const T& v) {
    const uint8_t* p = (const uint8_t*)&v;
    for (size_t i = 0; i < sizeof(T); i++) if (mem[dir + i] != p[i]) { mem[dir + i] = p[i]; escrituras++; }
    return v;
  }
};
extern EEPROMPrueba EEPROM;
