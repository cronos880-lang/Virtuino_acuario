// NVS imitada (memoria del ESP32): persiste entre "reinicios" de la prueba.
#pragma once
#include <map>
#include <string>
#include <vector>
#include <cstring>
extern std::map<std::string, std::vector<uint8_t>> g_nvs;
extern int g_nvs_escrituras;
class Preferences {
  template <class T> T leer(const char* k, T def) { auto i = g_nvs.find(k); if (i == g_nvs.end() || i->second.size() != sizeof(T)) return def; T v; memcpy(&v, i->second.data(), sizeof v); return v; }
  template <class T> size_t poner(const char* k, T v) { std::vector<uint8_t> b(sizeof v); memcpy(b.data(), &v, sizeof v); if (g_nvs[k] != b) { g_nvs[k] = b; g_nvs_escrituras++; } return sizeof v; }
 public:
  bool begin(const char*, bool) { return true; }
  size_t getBytesLength(const char* k) { auto i = g_nvs.find(k); return i == g_nvs.end() ? 0 : i->second.size(); }
  size_t getBytes(const char* k, void* d, size_t n) { auto i = g_nvs.find(k); if (i == g_nvs.end() || i->second.size() > n) return 0; memcpy(d, i->second.data(), i->second.size()); return i->second.size(); }
  size_t putBytes(const char* k, const void* d, size_t n) { std::vector<uint8_t> b((const uint8_t*)d, (const uint8_t*)d + n); if (g_nvs[k] != b) { g_nvs[k] = b; g_nvs_escrituras++; } return n; }
  float getFloat(const char* k, float d) { return leer(k, d); }
  uint8_t getUChar(const char* k, uint8_t d) { return leer(k, d); }
  uint16_t getUShort(const char* k, uint16_t d) { return leer(k, d); }
  size_t putFloat(const char* k, float v) { return poner(k, v); }
  size_t putUChar(const char* k, uint8_t v) { return poner(k, v); }
  size_t putUShort(const char* k, uint16_t v) { return poner(k, v); }
};
