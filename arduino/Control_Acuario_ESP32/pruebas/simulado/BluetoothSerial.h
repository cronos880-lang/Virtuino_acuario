#pragma once
#include "Arduino.h"
class BluetoothSerial : public SerialPrueba { public: std::string nombre; bool begin(const char* n) { nombre = n; return true; } };
