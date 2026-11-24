#!/usr/bin/env bash
# Pruebas del sketch V2 en el PC: lógica pura + sketch completo con librerías imitadas.
# Necesita g++ y la librería VirtuinoCM original (se descarga si no está).
set -euo pipefail
cd "$(dirname "$0")"
TMP="${TMPDIR:-/tmp}/acuario_v2_pruebas"
mkdir -p "$TMP/vcm"
if [ ! -f "$TMP/vcm/VirtuinoCM.cpp" ]; then
  for f in VirtuinoCM.h VirtuinoCM.cpp; do
    curl -fsSL -o "$TMP/vcm/$f" "https://raw.githubusercontent.com/iliaslamprou/virtuinoCM/master/$f"
  done
fi
g++ -std=c++17 -Wall -Wextra -O1 test_logica.cpp -o "$TMP/test_logica" && "$TMP/test_logica"
python3 construir_sketch.py .. "$TMP/sketch_combinado.cpp"
g++ -std=c++17 -O1 -w -Isimulado -I"$TMP/vcm" -I"$TMP" -I.. test_sketch.cpp "$TMP/vcm/VirtuinoCM.cpp" -o "$TMP/test_sketch"
fallo=0
for e in eeprom_vacia migracion termostato sonda salto bluetooth ajustes luces bomba reloj alarmas watchdog temporal resumen sin_efecto; do
  "$TMP/test_sketch" "$e" || fallo=1
done
exit $fallo
