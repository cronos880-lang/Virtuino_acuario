// I²C con un MCP4725 imitado (dirección 0x62): escritura rápida, EEPROM y lectura de 5 bytes.
#pragma once
#include <cstdint>
#include <vector>
#include <string>
extern bool g_dac_presente;
extern uint16_t g_dac, g_dac_eeprom;
extern int g_dac_grabaciones;
extern std::vector<std::string> g_eventos;
struct TwoWire {
  uint8_t dir = 0; std::vector<uint8_t> tx, rx; size_t pos = 0;
  void begin(int = 0, int = 0) {}
  void beginTransmission(uint8_t d) { dir = d; tx.clear(); }
  size_t write(uint8_t b) { tx.push_back(b); return 1; }
  uint8_t endTransmission() {
    if (dir != 0x62 || !g_dac_presente) return 2;
    if (tx.size() == 2 && (tx[0] & 0xF0) == 0) { g_dac = ((tx[0] & 0x0F) << 8) | tx[1]; g_eventos.push_back("DAC=" + std::to_string(g_dac)); }
    else if (tx.size() == 3 && tx[0] == 0x60) { g_dac = (tx[1] << 4) | (tx[2] >> 4); g_dac_eeprom = g_dac; g_dac_grabaciones++; }
    return 0;
  }
  int requestFrom(int d, int n) {
    rx.clear(); pos = 0;
    if (d != 0x62 || !g_dac_presente) return 0;
    uint8_t b[5] = {0xC0, (uint8_t)(g_dac >> 4), (uint8_t)((g_dac & 0x0F) << 4), (uint8_t)(g_dac_eeprom >> 8), (uint8_t)(g_dac_eeprom & 0xFF)};
    for (int i = 0; i < n && i < 5; i++) rx.push_back(b[i]);
    return (int)rx.size();
  }
  int read() { return pos < rx.size() ? rx[pos++] : -1; }
};
extern TwoWire Wire;
