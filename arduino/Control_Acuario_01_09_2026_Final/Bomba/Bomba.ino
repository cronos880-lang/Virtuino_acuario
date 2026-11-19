
void Bomba() {

  DateTime now = rtc.now();

  // Verificar si ha pasado una hora completa
  if (now.minute() == 0 && now.second() == 0) {
    // Cambiar el estado de la salida cada hora
    digitalWrite(outputPin, !digitalRead(outputPin)); // Alternar el estado (encendido/apagado)
    Serial.println("Se cambió el estado de la salida.");
  }

  delay(1000); // Esperar 1 segundo antes de la próxima verificación
}