// ============================================================================
//  FUENTE DE LUZ: buck LM76005 (consigna por DAC MCP4725), eFuse TPS26632 y PWM.
//
//  Encendido (ningún paso se salta):
//   1. DAC a la tensión de arranque (6 V) y PWM a 0.
//   2. BUCK_EN = 1. Con el eFuse apagado no debe haber sobretensión en la salida.
//   3. LED_EN = 1 (rearma el eFuse). Se comprueba que la salida llega a ~6 V y que
//      LED_FAULT_N no avisa. Si no llega en 1,5 s → fallo.
//   4. Rampa de tensión hasta la configurada (4 V/s): arranque suave de los drivers.
//   5. PWM según el nivel de luz (modo PWM) o al 100 % (modo continua, ya desde la rampa).
//  Apagado: PWM 0 → LED_EN 0 → BUCK_EN 0 → DAC al mínimo (4095). Se apaga 30 s después de
//  que el nivel de luz llegue a 0.
//  Vigilancia continua: eFuse (LED_FAULT_N en bajo 5 ms), sobretensión (100 ms), tensión baja
//  (2 s) y corriente > 4,7 A (2 s). Cualquier fallo apaga todo al instante y queda bloqueado
//  hasta que la app escriba V86 = 1 (o se reinicie la placa).
//
//  Nota: según el esquema, LED_V_ADC mide la SALIDA del eFuse (LED_POS). Por eso la tensión
//  se comprueba justo después de LED_EN, a 6 V (inofensiva), antes de subir a la configurada.
// ============================================================================

Fuente::Estado estado_fuente = Fuente::APAGADA;
uint8_t fallo_fuente = Fuente::SIN_FALLO;
bool dac_presente = false;
float tension_ordenada = 0;        // V que se pide ahora al buck
float referencia_sobre = 0;        // para detectar sobretensión (ver Fuente.h)
float tension_medida = 0, corriente_medida = 0;
unsigned long t_estado = 0, t_tick_fuente = 0, t_medida = 0, t_nivel_cero = 0;
unsigned long t_sobre = 0, t_baja = 0, t_corriente = 0, t_fallo_n = 0, t_correcta = 0;
bool hay_sobre = false, hay_baja = false, hay_corriente = false, hay_fallo_n = false, hay_correcta = false;
const uint8_t BITS_PWM = 8;

// ----------------------------------------------------------------------------- MCP4725
bool dacEscribir(uint16_t codigo) {
  Wire.beginTransmission(DIRECCION_DAC);
  Wire.write((uint8_t)((codigo >> 8) & 0x0F));   // escritura rápida, sin apagado
  Wire.write((uint8_t)(codigo & 0xFF));
  return Wire.endTransmission() == 0;
}

// Lee el valor guardado en la EEPROM del DAC (el que carga al recibir alimentación)
bool dacLeerEeprom(uint16_t& codigo, uint8_t& apagado) {
  if (Wire.requestFrom((int)DIRECCION_DAC, 5) != 5) return false;
  uint8_t b[5];
  for (int i = 0; i < 5; i++) b[i] = Wire.read();
  apagado = (b[3] >> 5) & 0x03;
  codigo = ((uint16_t)(b[3] & 0x0F) << 8) | b[4];
  return true;
}

// Graba un valor en la EEPROM del DAC y espera a que termine (máx. 50 ms según el fabricante)
bool dacGrabarEeprom(uint16_t codigo) {
  Wire.beginTransmission(DIRECCION_DAC);
  Wire.write(0x60);                               // escribir DAC y EEPROM
  Wire.write((uint8_t)(codigo >> 4));
  Wire.write((uint8_t)((codigo & 0x0F) << 4));
  if (Wire.endTransmission() != 0) return false;
  unsigned long t = millis();
  while (millis() - t < 100) {
    delay(5);
    if (Wire.requestFrom((int)DIRECCION_DAC, 1) == 1 && (Wire.read() & 0x80)) return true;   // RDY
  }
  return false;
}

// ----------------------------------------------------------------------------- salidas
void ponerPwm(uint32_t ciclo) {
  ledcWrite(PIN_LUZ_PWM, ciclo);
}

void apagarSalidas() {
  ponerPwm(0);
  digitalWrite(PIN_LED_EN, LOW);
  digitalWrite(PIN_BUCK_EN, LOW);
  if (dac_presente) dacEscribir(Fuente::CODIGO_MIN_TENSION);
  tension_ordenada = 0;
}

bool ordenarTension(float v) {
  tension_ordenada = v;
  if (dacEscribir(Fuente::codigo_dac(v))) return true;
  fuenteFallo(Fuente::FALLO_DAC);
  return false;
}

void cambiarEstado(Fuente::Estado e) {
  estado_fuente = e;
  t_estado = millis();
  hay_correcta = false;
}

void fuenteFallo(uint8_t codigo) {
  apagarSalidas();
  fallo_fuente = codigo;
  cambiarEstado(Fuente::FALLO);
  if (DEPURAR) { Serial.print("FALLO DE LA FUENTE DE LUZ: "); Serial.println(codigo); }
}

void fuenteCambiarFrecuencia() {
  ledcChangeFrequency(PIN_LUZ_PWM, frecuencia_pwm, BITS_PWM);
}

// ----------------------------------------------------------------------------- inicio
void fuenteIniciar() {
  ledcAttach(PIN_LUZ_PWM, frecuencia_pwm, BITS_PWM);
  ponerPwm(0);
  t_tick_fuente = millis();
  dacIniciar();
}

void dacIniciar() {
  // El DAC debe arrancar SIEMPRE a la tensión mínima: se comprueba su EEPROM y se graba 4095
  // solo si hace falta (la EEPROM del MCP4725 admite un número limitado de escrituras).
  uint16_t codigo = 0;
  uint8_t apagado = 0;
  dac_presente = dacLeerEeprom(codigo, apagado);
  if (dac_presente && (codigo != Fuente::CODIGO_MIN_TENSION || apagado != 0)) {
    dac_presente = dacGrabarEeprom(Fuente::CODIGO_MIN_TENSION);
    depurar("DAC: grabado 4095 en su EEPROM");
  }
  apagarSalidas();
  if (!dac_presente) {
    fallo_fuente = Fuente::FALLO_DAC;   // sin DAC no se enciende nunca la luz
    cambiarEstado(Fuente::FALLO);
    depurar("No responde el DAC MCP4725 (0x62): luz bloqueada");
  } else {
    cambiarEstado(Fuente::APAGADA);
  }
}

// ----------------------------------------------------------------------------- medidas
void medir() {
  // Media de 4 lecturas y filtro suave (el PWM hace que la corriente sea pulsante)
  uint32_t mv_v = 0, mv_i = 0;
  for (int i = 0; i < 4; i++) {
    mv_v += analogReadMilliVolts(PIN_ADC_TENSION);
    mv_i += analogReadMilliVolts(PIN_ADC_CORRIENTE);
  }
  float v = Fuente::tension_de_adc(mv_v / 4.0f);
  float a = Fuente::corriente_de_adc(mv_i / 4.0f);
  tension_medida = tension_medida * 0.5f + v * 0.5f;
  corriente_medida = corriente_medida * 0.8f + a * 0.2f;
}

// Condición que debe mantenerse "ms" milisegundos seguidos
bool sostenido(bool cond, bool& activo, unsigned long& desde, unsigned long ms) {
  if (!cond) { activo = false; return false; }
  if (!activo) { activo = true; desde = millis(); }
  return millis() - desde >= ms;
}

// ----------------------------------------------------------------------------- ciclo
void fuenteActualizar() {
  unsigned long ahora = millis();
  uint32_t dt = ahora - t_tick_fuente;
  t_tick_fuente = ahora;
  if (ahora - t_medida >= 20) { t_medida = ahora; medir(); }

  // Rearme pedido por la app
  if (V[V_REARME] == 1) {
    V[V_REARME] = 0;
    if (estado_fuente == Fuente::FALLO) {
      if (!dac_presente) dacIniciar();          // vuelve a buscar el DAC
      if (dac_presente) { fallo_fuente = Fuente::SIN_FALLO; cambiarEstado(Fuente::APAGADA); }
    }
  }

  bool buck_activo = digitalRead(PIN_BUCK_EN) == HIGH;
  bool quiere_luz = nivel_luz > 0;
  if (quiere_luz) t_nivel_cero = ahora;

  // ---- vigilancia (siempre que el buck esté activo)
  if (buck_activo) {
    referencia_sobre = Fuente::bajar_referencia(referencia_sobre, tension_ordenada, dt);
    if (sostenido(Fuente::sobretension(tension_medida, referencia_sobre), hay_sobre, t_sobre, 100)) {
      fuenteFallo(Fuente::FALLO_SOBRETENSION); return;
    }
  } else {
    hay_sobre = false;
  }
  if (digitalRead(PIN_LED_EN) == HIGH) {
    // GPIO39 puede dar pulsos de ~80 ns falsos (errata del ESP32): se exigen 5 ms seguidos
    if (sostenido(digitalRead(PIN_LED_FALLO) == LOW, hay_fallo_n, t_fallo_n, 5)) {
      fuenteFallo(Fuente::FALLO_EFUSE); return;
    }
    if (sostenido(corriente_medida > Fuente::CORRIENTE_MAX_A, hay_corriente, t_corriente, 2000)) {
      fuenteFallo(Fuente::FALLO_CORRIENTE); return;
    }
  } else {
    hay_fallo_n = false;
    hay_corriente = false;
  }

  // ---- secuencia
  float arranque = min(Fuente::TENSION_ARRANQUE, tension_luz);
  switch (estado_fuente) {
    case Fuente::APAGADA:
      if (quiere_luz) {
        ponerPwm(0);
        if (!ordenarTension(arranque)) return;     // 1. DAC
        referencia_sobre = arranque;
        digitalWrite(PIN_BUCK_EN, HIGH);           // 2. buck
        cambiarEstado(Fuente::COMPROBANDO);
      }
      break;

    case Fuente::COMPROBANDO: {
      unsigned long en_estado = ahora - t_estado;
      if (en_estado >= 100 && digitalRead(PIN_LED_EN) == LOW) {
        digitalWrite(PIN_LED_EN, HIGH);            // 3. eFuse (tras 100 ms de buck estable)
      }
      if (digitalRead(PIN_LED_EN) == HIGH &&
          sostenido(Fuente::tension_correcta(tension_medida, arranque), hay_correcta, t_correcta, 200)) {
        if (modo_luz == 1) ponerPwm(Fuente::ciclo_pwm(nivel_luz, true));   // continua: carga desde la rampa
        cambiarEstado(Fuente::SUBIENDO);
      } else if (en_estado > 1600) {
        fuenteFallo(Fuente::FALLO_TENSION); return;
      }
      break;
    }

    case Fuente::SUBIENDO:
      if (!ordenarTension(Fuente::avanzar_rampa(tension_ordenada, tension_luz, dt))) return;   // 4. rampa
      if (tension_ordenada >= tension_luz) cambiarEstado(Fuente::ENCENDIDA);
      break;

    case Fuente::ENCENDIDA:
      // La tensión configurada puede cambiar desde la app: sube en rampa, baja al momento
      if (fabsf(tension_ordenada - tension_luz) > 0.001f &&
          !ordenarTension(Fuente::avanzar_rampa(tension_ordenada, tension_luz, dt))) return;
      ponerPwm(Fuente::ciclo_pwm(nivel_luz, modo_luz == 1));                      // 5. PWM
      if (sostenido(tension_medida < tension_ordenada - Fuente::margen(tension_ordenada),
                    hay_baja, t_baja, 2000)) {
        fuenteFallo(Fuente::FALLO_TENSION); return;
      }
      if (!quiere_luz && ahora - t_nivel_cero >= 30000UL) {
        apagarSalidas();
        cambiarEstado(Fuente::APAGADA);
      }
      break;

    case Fuente::FALLO:
      break;   // todo apagado hasta el rearme
  }
  if (estado_fuente != Fuente::ENCENDIDA) hay_baja = false;

  // ---- publicar
  V[V_TENSION_MEDIDA] = roundf(tension_medida * 10.0f) / 10.0f;
  V[V_CORRIENTE] = roundf(corriente_medida * 100.0f) / 100.0f;
  V[V_POTENCIA] = roundf(tension_medida * corriente_medida * 10.0f) / 10.0f;
  V[V_ESTADO_FUENTE] = estado_fuente;
  V[V_FALLO_FUENTE] = fallo_fuente;
  V[V_ALARMA_LUZ] = fallo_fuente != Fuente::SIN_FALLO ? 1 : 0;
  V[V_TENSION_ORDENADA] = roundf(tension_ordenada * 10.0f) / 10.0f;
  bool aplicando = estado_fuente == Fuente::ENCENDIDA || (estado_fuente == Fuente::SUBIENDO && modo_luz == 1);
  V[V_LUZ_ACTUAL] = aplicando ? Fuente::ciclo_pwm(nivel_luz, modo_luz == 1) : 0;
}
