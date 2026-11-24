# Control Acuario V2 (2.1.0 de prueba)

Versión mejorada del sketch del acuario. **No sustituye a `Control_Acuario_01_09_2026_Final`**, que
sigue siendo la versión que funciona y la de vuelta atrás. Esta versión no es oficial hasta que la
apruebes tras probarla.

## Qué cambia respecto al sketch anterior

| Antes | Ahora |
|---|---|
| Si la sonda falla, el calentador se queda como estaba | A los **15 s sin lectura válida el calentador se apaga** y salta la alarma V60 |
| La lectura de la sonda paraba el programa unos 0,75 s cada segundo | Lectura **sin bloqueo**: el Bluetooth responde siempre (comprobado: en menos de 20 ms) |
| Menú de configuración que bloqueaba el control y podía quedarse atrapado | **Sin menú**: cada ajuste se escribe en su variable V, se valida y se guarda sin parar nada |
| Consigna sin límites; EEPROM vacía = calentador que no enciende | Límites (consigna 18–32 °C, intensidad 0–255...) y **valores por defecto seguros** |
| Horarios fijos en el código | **Horarios de luces y bomba configurables** desde la app (también los que cruzan la medianoche) |
| Amanecer en 15 saltos | **Amanecer y atardecer suaves** (se calculan por segundos) |
| El watchdog podía dejar la placa reiniciándose tras un cuelgue | Watchdog desactivado al arrancar (método de avr-libc) y **causa del reinicio** visible |
| Ajuste de hora con minutos y segundos antiguos | **Poner en hora** escribiendo HHMM (por ejemplo 1630) |
| Sin avisos | **Alarmas**: sonda, temperatura alta o baja y hora perdida. **Diagnóstico**: reinicios, memoria y tiempo de calentador |

La intensidad y la consigna que tenías guardadas con el sketch anterior **se recuperan** la primera vez
que arranca la V2.

## Novedades de la 2.1.0
- **Intensidad temporal (V12), para jugar:**
  - Cambia la luz al momento y **no escribe nunca en la EEPROM**.
  - Vuelve a la referencia (V28) al empezar el siguiente amanecer, al escribir V13 = 1 o al reiniciar.
  - La referencia solo se cambia desde la página Consignas y es lo único que se guarda (2 s después del último cambio).
- **Resumen de hoy**, que se pone a cero a medianoche:
  - V76 / V77: temperatura mínima y su hora (HHMM).
  - V78 / V79: temperatura máxima y su hora.
  - V90: veces que ha arrancado el calentador.
  - V91 / V92: minutos de luz y de bomba (los minutos de calentador siguen en V73).
- **Aviso de calentador sin efecto (V64):**
  - Salta si el calentador lleva **60 min encendido** y el agua **no ha subido 0,2 °C**: calentador roto, desenchufado o cortado por su propio termostato.
  - **Solo avisa; no apaga nada.**
  - Estado general V63 = 5.

## Variables V (protocolo VirtuinoCM)

**Lecturas** (las mismas del panel actual, que sigue funcionando sin cambios)

| V | Qué es |
|---|---|
| V2, V3, V4 | Hora, minutos, segundos |
| V5, V35 | Temperatura del agua (°C) |
| V6 / V7 | Calentador encendido / apagado |
| V8 | Bomba en marcha (1/0) |
| V10 | Intensidad configurada (0–255) |
| V11 | **Nuevo:** luz que se aplica ahora mismo (0–255) |

**Mandos manuales** (igual que antes): V29 = bomba en manual · V15 = bomba ON en manual · V16 = luces al máximo

**Ajustes** (la app los **escribe**; si el valor no es válido, el Arduino restaura el anterior)

| V | Ajuste | Límites | Por defecto |
|---|---|---|---|
| V27 | Consigna de temperatura (°C) | 18–32 | 25,0 |
| V28 | Intensidad de las luces | 0–255 | 125 |
| V44 | Poner en hora (escribir HHMM, por ejemplo 930 = 09:30) | 0000–2359 | — |
| V50 / V51 | Luces: encendido / apagado (HHMM) | 0000–2359 | 1600 / 2200 |
| V52 | Minutos de amanecer y de atardecer | 0–60 | 15 |
| V53 / V54 | Bomba: encendido / apagado (HHMM) | 0000–2359 | 1500 / 2200 |
| V55 | Histéresis (°C) | 0,1–2,0 | 0,2 |
| V57 / V58 | Alarma de temperatura alta / baja (°C) | 5–40, baja < alta | 29 / 21 |

**Alarmas** (1 = activa): V60 fallo de sonda · V61 temperatura alta · V65 temperatura baja · V62 hora perdida
· V64 calentador sin efecto
· V63 estado general (0 OK, 1 alta, 2 baja, 3 sonda, 4 hora perdida, 5 calentador sin efecto)

**Diagnóstico:** V70 versión (210 = 2.1.0) · V71 número de arranques · V72 causa del último reinicio
(0 desconocida, 1 encendido, 2 botón de reset, 3 caída de tensión, 4 watchdog) · V73 minutos de
calentador hoy · V74 memoria libre (bytes) · V75 minutos desde el arranque

> **Virtuino 6:** las lecturas y los mandos manuales siguen funcionando. Su **página de configuración
> antigua (V9, V20–V26) ya no se usa**: los ajustes se hacen con el proyecto de Acuaris «Acuario V2».

## Cargar en el Arduino

1. Arduino IDE → abrir `Control_Acuario_V2/Control_Acuario_V2.ino`. Se abren todas las pestañas.
2. Librerías (las que ya usabas): **VirtuinoCM**, **OneWire**, **DallasTemperature** y **RTClib** (Adafruit).
3. Placa: **Arduino Mega o Mega 2560** → Verificar → Subir.
4. Para ver mensajes de depuración: `DEPURAR = true` en la pestaña principal y Monitor Serie a 115200.
5. Si tus relés de estado sólido se activaran con nivel BAJO, cambia `RELE_ON = HIGH` por `LOW`.
   El sketch anterior usa HIGH y te funciona, por eso se deja así.

## Prueba en banco (antes de conectarlo al acuario)

1. Pon una **bombilla o un piloto** en lugar del calentador y la bomba.
2. **Sonda en agua fría:** el calentador debe encenderse en 1–2 s. En agua templada (por encima de consigna + 0,2 °C) se apaga, pero **no antes de 3 min** desde el último cambio.
3. **Desconecta la sonda:** en unos 15 s el calentador se APAGA y V60 = 1. Al reconectarla, la alarma se quita.
4. Desde Acuaris:
   - Escribe la consigna 99: debe volver al valor anterior.
   - Escribe 26,5: se acepta y se mantiene tras reiniciar la placa.
5. **Poner en hora:** escribe 930 en V44; el reloj marca 09:30.
6. **Corta el Bluetooth en cualquier momento:** el control sigue funcionando.
7. **Luces:** pon el amanecer dentro de 2 minutos y comprueba que suben sin saltos.

## Cómo se ha comprobado (y qué falta)

- `pruebas/test_logica.cpp`: 33 pruebas de la lógica (horarios, rampas, termostato, validaciones, desbordamiento de `millis`).
- `pruebas/test_sketch.cpp`: **el sketch completo se ejecuta en el PC** con imitaciones de las librerías (sonda, reloj, EEPROM, puerto serie) y la librería VirtuinoCM original. Son 57 comprobaciones en 15 escenarios: EEPROM vacía, recuperación de los ajustes anteriores, termostato, fallo de sonda, saltos de lectura, tiempos de respuesta del Bluetooth, ajustes, luces, bomba, reloj, alarmas, watchdog, intensidad temporal, resumen del día y calentador sin efecto.
- Para ejecutarlas: `pruebas/ejecutar_pruebas.sh` (necesita g++ e Internet para descargar VirtuinoCM).
- **Falta:**
  - **Compilar con el compilador de AVR** (Arduino IDE o arduino-cli): en esta sesión no se ha podido instalar.
  - **Probarlo en tu placa real.** Los tiempos reales de la sonda, los relés y el Bluetooth no son exactos; el programa usa márgenes (800 ms de conversión, 15 s de fallo y 3 min de relé) pensados para eso.

## Volver atrás

Carga de nuevo `Control_Acuario_01_09_2026_Final`. La V2 guarda sus ajustes a partir de la dirección
32 de la EEPROM y no borra las direcciones 0–5 que usaba el sketch anterior, así que este sigue
encontrando su intensidad y su consigna.
