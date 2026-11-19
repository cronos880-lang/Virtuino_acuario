#!/usr/bin/env bash
# Instala Godot (editor Linux) y sus plantillas de exportación oficiales, si no están en caché.
set -euo pipefail
V="${GODOT_VERSION:?}"
DIR="${GODOT_DIR:?}"
TPL="$HOME/.local/share/godot/export_templates/${V}.stable"
BASE="https://github.com/godotengine/godot/releases/download/${V}-stable"
mkdir -p "$DIR"
if [ ! -x "$DIR/godot" ]; then
  curl -fsSL -o /tmp/godot.zip "$BASE/Godot_v${V}-stable_linux.x86_64.zip"
  unzip -q -o /tmp/godot.zip -d "$DIR"
  mv "$DIR/Godot_v${V}-stable_linux.x86_64" "$DIR/godot"
  chmod +x "$DIR/godot"
  rm /tmp/godot.zip
fi
if [ ! -f "$TPL/version.txt" ]; then
  curl -fsSL -o /tmp/tpl.tpz "$BASE/Godot_v${V}-stable_export_templates.tpz"
  mkdir -p /tmp/tpl "$(dirname "$TPL")"
  unzip -q -o /tmp/tpl.tpz -d /tmp/tpl
  rm -rf "$TPL"
  mv /tmp/tpl/templates "$TPL"
  rm -rf /tmp/tpl /tmp/tpl.tpz
fi
"$DIR/godot" --version
ls "$TPL" | head -30
