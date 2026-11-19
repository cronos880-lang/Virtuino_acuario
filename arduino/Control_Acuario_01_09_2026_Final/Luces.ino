void Luces(int *lumen, int *luz, int *luz1, DateTime now) {

    int hora = now.hour();
    int minuto = now.minute();
    int nivel = 0;

    // Modo manual
    if (V[16] == 1) {
        nivel = *lumen;
    }

    // Modo automático
    else {

        // Amanecer 16:00 - 16:14 (15 minutos)
        if (hora == 16 && minuto < 15) {
            nivel = map(minuto, 0, 14, 0, *lumen);
        }

        // Luz estable 16:15 - 21:44
        else if ((hora > 16 && hora < 21) ||
                 (hora == 16 && minuto >= 15) ||
                 (hora == 21 && minuto < 45)) {

            nivel = *lumen;
        }

        // Atardecer 21:45 - 21:59 (15 minutos)
        else if (hora == 21 && minuto >= 45) {
            nivel = map(minuto, 45, 59, *lumen, 0);
        }

        // Apagado
        else {
            nivel = 0;
        }
    }

    *luz  = nivel;
    *luz1 = nivel;

    // Luz nocturna desactivada
    digitalWrite(12, LOW);
}
