// ============================================================================
//  COMUNICACIÓN con la app (Acuaris o Virtuino 6) por el HC-05 — protocolo VirtuinoCM.
// ============================================================================

// La app cambia un valor
void alRecibir(char tipo, uint8_t indice, String valor) {
  if (tipo == 'V' && indice < V_MEMORIA) V[indice] = valor.toFloat();
}

// La app pide un valor
String alPedir(char tipo, uint8_t indice) {
  if (tipo == 'V' && indice < V_MEMORIA) return String(V[indice]);
  return "";
}

// Atiende un comando completo si ha llegado (no espera si no hay nada)
void virtuinoRun() {
  while (Serial1.available()) {
    char c = Serial1.read();
    if (c == CM_START_CHAR) {
      virtuino.readBuffer = CM_START_CHAR;
      virtuino.readBuffer += Serial1.readStringUntil(CM_END_CHAR);
      virtuino.readBuffer += CM_END_CHAR;
      String* respuesta = virtuino.getResponse();
      Serial1.print(*respuesta);
      if (DEPURAR) {
        Serial.print(F("<- "));
        Serial.print(virtuino.readBuffer);
        Serial.print(F("  -> "));
        Serial.println(*respuesta);
      }
      break;
    }
  }
}
