// ============================================================================
//  AJUSTES: EEPROM y escritura de ajustes desde la app (sin menú bloqueante)
//
//  La app escribe el ajuste en su variable V (por ejemplo V27 = 26.5). Aquí se detecta que
//  el valor es distinto del publicado, se valida y:
//   - si es válido: se aplica, se publica y se guarda en la EEPROM (2 s después del último
//     cambio, para no gastarla si se mueve un deslizador);
//   - si no lo es: se restaura el valor anterior (la app lo verá en la siguiente lectura).
// ============================================================================

const int DIR_AJUSTES = 32;          // el sketch anterior usaba las direcciones 0..5
const int DIR_LUMEN_ANTIGUO = 0;     // int (2 bytes)
const int DIR_CONSIGNA_ANTIGUA = 2;  // float (4 bytes)
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
  V[V_REINICIOS] = ajustes.reinicios;
}

void ajustesIniciar() {
  EEPROM.get(DIR_AJUSTES, ajustes);
  bool bloque_valido = ajustes.magia == Logica::MAGIA_AJUSTES && ajustes.suma == Logica::calcular_suma(ajustes);
  if (!bloque_valido) {
    // Primera vez con V2: valores por defecto, recuperando los del sketch anterior si son válidos
    Logica::por_defecto(ajustes);
    int lumen_antiguo = 0;
    float consigna_antigua = NAN;
    EEPROM.get(DIR_LUMEN_ANTIGUO, lumen_antiguo);
    EEPROM.get(DIR_CONSIGNA_ANTIGUA, consigna_antigua);
    if (lumen_antiguo >= 0 && lumen_antiguo <= 255) ajustes.intensidad = (uint8_t)lumen_antiguo;
    if (Logica::en_rango(consigna_antigua, Logica::CONSIGNA_MIN, Logica::CONSIGNA_MAX)) ajustes.consigna = consigna_antigua;
    depurar(F("Ajustes: bloque nuevo (valores por defecto / anteriores)"));
  }
  Logica::sanear(ajustes);
  ajustes.reinicios++;
  ajustes.suma = Logica::calcular_suma(ajustes);
  EEPROM.put(DIR_AJUSTES, ajustes);   // put = solo escribe los bytes que cambian
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
  if (cambio) {
    guardado_pendiente = true;
    t_ultimo_cambio_ajuste = millis();
    depurar(F("Ajuste cambiado desde la app"));
  }
  if (guardado_pendiente && millis() - t_ultimo_cambio_ajuste >= ESPERA_GUARDAR_MS) {
    Logica::sanear(ajustes);
    EEPROM.put(DIR_AJUSTES, ajustes);
    guardado_pendiente = false;
    depurar(F("Ajustes guardados en la EEPROM"));
  }
}
