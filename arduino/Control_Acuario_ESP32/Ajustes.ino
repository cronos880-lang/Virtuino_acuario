// ============================================================================
//  AJUSTES: memoria NVS del ESP32 (Preferences) y escritura de ajustes desde la app.
//
//  Igual que en el V2: la app escribe el ajuste en su variable V, aquí se detecta que el valor es
//  distinto del publicado y se valida:
//   - si es válido: se aplica, se publica y se guarda 2 s después del último cambio
//     (un movimiento de deslizador = una escritura);
//   - si no lo es: se restaura el valor anterior (la app lo verá en la siguiente lectura).
//  La NVS reparte el desgaste por la flash. La intensidad temporal (V12) no se guarda nunca.
// ============================================================================

const unsigned long ESPERA_GUARDAR_MS = 2000UL;

bool guardado_pendiente = false;
unsigned long t_ultimo_cambio_ajuste = 0;

// Valores publicados, para detectar escrituras de la app
float publicado[V_MEMORIA];

void publicar(uint8_t v, float valor) {
  V[v] = valor;
  publicado[v] = valor;
}

bool escrito_por_app(uint8_t v) {
  return fabs(V[v] - publicado[v]) > 0.001;
}

void publicarAjustes() {
  publicar(V_CONSIGNA, ajustes.consigna);
  publicar(V_INTENSIDAD, ajustes.intensidad);
  V[V_INTENSIDAD_VER] = ajustes.intensidad;
  publicar(V_LUZ_ON, ajustes.luz_on);
  publicar(V_LUZ_OFF, ajustes.luz_off);
  publicar(V_RAMPA, ajustes.rampa_min);
  publicar(V_BOMBA_ON, ajustes.bomba_on);
  publicar(V_BOMBA_OFF, ajustes.bomba_off);
  publicar(V_HISTERESIS, ajustes.histeresis);
  publicar(V_ALARMA_ALTA, ajustes.alarma_alta);
  publicar(V_ALARMA_BAJA, ajustes.alarma_baja);
  publicar(V_TENSION_LUZ, tension_luz);
  publicar(V_MODO_LUZ, modo_luz);
  publicar(V_FRECUENCIA, frecuencia_pwm);
  V[V_REINICIOS] = ajustes.reinicios;
}

void guardarAjustes() {
  Logica::sanear(ajustes);
  memoria.putBytes("ajustes", &ajustes, sizeof(ajustes));
  memoria.putFloat("tension", tension_luz);
  memoria.putUChar("modo", modo_luz);
  memoria.putUShort("frec", frecuencia_pwm);
}

void ajustesIniciar() {
  memoria.begin("acuario", false);
  bool bloque_valido = memoria.getBytesLength("ajustes") == sizeof(ajustes) &&
                       memoria.getBytes("ajustes", &ajustes, sizeof(ajustes)) == sizeof(ajustes) &&
                       ajustes.magia == Logica::MAGIA_AJUSTES && ajustes.suma == Logica::calcular_suma(ajustes);
  if (!bloque_valido) {
    Logica::por_defecto(ajustes);   // primera vez: valores por defecto (los mismos del V2)
    depurar("Ajustes: valores por defecto");
  }
  Logica::sanear(ajustes);
  // Fuente de luz: un valor no válido se sustituye por el de defecto (10 V, PWM, 490 Hz)
  float t = memoria.getFloat("tension", Fuente::TENSION_DEFECTO);
  tension_luz = Fuente::tension_valida(t) ? t : Fuente::TENSION_DEFECTO;
  uint8_t m = memoria.getUChar("modo", 0);
  modo_luz = (m <= 1) ? m : 0;
  uint16_t f = memoria.getUShort("frec", Fuente::FRECUENCIA_DEFECTO);
  frecuencia_pwm = Fuente::frecuencia_valida(f) ? f : Fuente::FRECUENCIA_DEFECTO;

  ajustes.reinicios++;
  ajustes.suma = Logica::calcular_suma(ajustes);
  guardarAjustes();
  publicarAjustes();
  publicar(V_PONER_HORA, 0);
  intensidad_actual = ajustes.intensidad;   // al arrancar, siempre la referencia
  publicar(V_INTENSIDAD_TEMP, intensidad_actual);
}

// Comprueba un ajuste HHMM escrito por la app
bool tomarHHMM(uint8_t v, uint16_t& destino) {
  if (!escrito_por_app(v)) return false;
  long nuevo = lround(V[v]);
  if (Logica::hhmm_valido(nuevo)) {
    destino = (uint16_t)nuevo;
    publicar(v, nuevo);
    return true;
  }
  publicar(v, destino);   // no válido: se restaura
  return false;
}

bool tomarReal(uint8_t v, float& destino, float mn, float mx) {
  if (!escrito_por_app(v)) return false;
  float nuevo = V[v];
  if (Logica::en_rango(nuevo, mn, mx)) {
    destino = nuevo;
    publicar(v, nuevo);
    return true;
  }
  publicar(v, destino);
  return false;
}

void ajustesRevisar() {
  bool cambio = false;
  cambio |= tomarReal(V_CONSIGNA, ajustes.consigna, Logica::CONSIGNA_MIN, Logica::CONSIGNA_MAX);
  cambio |= tomarReal(V_HISTERESIS, ajustes.histeresis, Logica::HIST_MIN, Logica::HIST_MAX);
  float alta = ajustes.alarma_alta, baja = ajustes.alarma_baja;
  bool c_alta = tomarReal(V_ALARMA_ALTA, alta, Logica::ALARMA_MIN, Logica::ALARMA_MAX);
  bool c_baja = tomarReal(V_ALARMA_BAJA, baja, Logica::ALARMA_MIN, Logica::ALARMA_MAX);
  if (c_alta || c_baja) {
    if (baja < alta) { ajustes.alarma_alta = alta; ajustes.alarma_baja = baja; cambio = true; }
    publicar(V_ALARMA_ALTA, ajustes.alarma_alta);
    publicar(V_ALARMA_BAJA, ajustes.alarma_baja);
  }
  if (escrito_por_app(V_INTENSIDAD)) {
    long n = lround(V[V_INTENSIDAD]);
    if (n >= 0 && n <= 255) {
      ajustes.intensidad = (uint8_t)n;
      cambio = true;
      volverAReferencia();          // cambiar la referencia también cambia la luz actual
    }
    publicar(V_INTENSIDAD, ajustes.intensidad);
    V[V_INTENSIDAD_VER] = ajustes.intensidad;
  }
  if (escrito_por_app(V_RAMPA)) {
    long n = lround(V[V_RAMPA]);
    if (n >= 0 && n <= Logica::RAMPA_MAX) { ajustes.rampa_min = (uint8_t)n; cambio = true; }
    publicar(V_RAMPA, ajustes.rampa_min);
  }
  cambio |= tomarHHMM(V_LUZ_ON, ajustes.luz_on);
  cambio |= tomarHHMM(V_LUZ_OFF, ajustes.luz_off);
  cambio |= tomarHHMM(V_BOMBA_ON, ajustes.bomba_on);
  cambio |= tomarHHMM(V_BOMBA_OFF, ajustes.bomba_off);
  // Fuente de luz
  cambio |= tomarReal(V_TENSION_LUZ, tension_luz, Fuente::TENSION_MIN, Fuente::TENSION_MAX);
  if (escrito_por_app(V_MODO_LUZ)) {
    long n = lround(V[V_MODO_LUZ]);
    if (n == 0 || n == 1) { modo_luz = (uint8_t)n; cambio = true; }
    publicar(V_MODO_LUZ, modo_luz);
  }
  if (escrito_por_app(V_FRECUENCIA)) {
    long n = lround(V[V_FRECUENCIA]);
    if (Fuente::frecuencia_valida(n) && n != frecuencia_pwm) {
      frecuencia_pwm = (uint16_t)n;
      cambio = true;
      fuenteCambiarFrecuencia();
    }
    publicar(V_FRECUENCIA, frecuencia_pwm);
  }
  if (cambio) {
    guardado_pendiente = true;
    t_ultimo_cambio_ajuste = millis();
    depurar("Ajuste cambiado desde la app");
  }
  if (guardado_pendiente && millis() - t_ultimo_cambio_ajuste >= ESPERA_GUARDAR_MS) {
    guardarAjustes();
    guardado_pendiente = false;
    depurar("Ajustes guardados en la NVS");
  }
}
