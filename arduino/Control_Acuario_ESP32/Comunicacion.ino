// ============================================================================
//  COMUNICACIÓN con la app (Acuaris o Virtuino 6) por el Bluetooth del ESP32 — VirtuinoCM.
//  Igual que en el V2, cambiando el HC-05 (Serial1) por BluetoothSerial.
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
  while (bt.available()) {
    char c = bt.read();
    if (c == CM_START_CHAR) {
      virtuino.readBuffer = CM_START_CHAR;
      virtuino.readBuffer += bt.readStringUntil(CM_END_CHAR);
      virtuino.readBuffer += CM_END_CHAR;
      String* respuesta = virtuino.getResponse();
      bt.print(*respuesta);
      if (DEPURAR) {
        Serial.print("<- ");
        Serial.print(virtuino.readBuffer);
        Serial.print("  -> ");
        Serial.println(*respuesta);
      }
      break;
    }
  }
}
