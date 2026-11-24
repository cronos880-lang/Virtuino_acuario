#!/usr/bin/env bash
# Pruebas del sketch ESP32 en el PC: cálculos de la fuente + sketch completo con la placa imitada.
# Necesita g++ y la librería VirtuinoCM original (se descarga si no está).
set -euo pipefail
cd "$(dirname "$0")"
TMP="${TMPDIR:-/tmp}/acuario_esp32_pruebas"
mkdir -p "$TMP/vcm"
if [ ! -f "$TMP/vcm/VirtuinoCM.cpp" ]; then
  for f in VirtuinoCM.h VirtuinoCM.cpp; do
    curl -fsSL -o "$TMP/vcm/$f" "https://raw.githubusercontent.com/iliaslamprou/virtuinoCM/master/$f"
  done
fi
g++ -std=c++17 -Wall -Wextra -O1 test_fuente.cpp -o "$TMP/test_fuente" && "$TMP/test_fuente"
python3 construir_sketch.py .. "$TMP/sketch_combinado.cpp"
g++ -std=c++17 -O1 -w -Isimulado -I"$TMP/vcm" -I"$TMP" -I.. test_sketch.cpp "$TMP/vcm/VirtuinoCM.cpp" -o "$TMP/test_sketch"
fallo=0
for e in arranque secuencia sobretension efuse sin_tension sin_dac temporal noche continua ajustes termostato bluetooth; do
  "$TMP/test_sketch" "$e" || fallo=1
done
exit $fallo
