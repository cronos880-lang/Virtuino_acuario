
void Bomba(DateTime now) {

    bool estadoBomba;

    // Modo manual
    if (V[29] == 1) {
        estadoBomba = (V[15] == 1);
    }
    // Modo automático
    else {
        int hora = now.hour();
        estadoBomba = (hora >= 15 && hora < 22);
    }

    digitalWrite(4, estadoBomba ? HIGH : LOW);
    V[8] = estadoBomba;
}




/*
///////////////////////////////////////////

void Bomba(DateTime now) {

    static bool manual = false;  // Mantiene el estado entre llamadas
    int hora = now.hour();

    // Verifica si estamos en Manual o Automático
    if (V[29] == 1) {
        manual = true;  // Modo manual activado
    } else {
        manual = false; // Modo automático
    }

    // Control de la bomba
    if (manual) {
        // Modo MANUAL: el estado depende de V[15]
        if (V[15] == 1) {
            digitalWrite(4, HIGH);
        } else {
            digitalWrite(4, LOW);
        }
    } else {
        // Modo AUTOMÁTICO: horario de 15:00 a 22:00
 
        if (hora >= 15 && hora < 22) {
            digitalWrite(4, HIGH);
        } else {
            digitalWrite(4, LOW);
        }
    }

    // Actualiza el estado de la salida en el Virtuino
    V[8] = digitalRead(4); 
}

*/

