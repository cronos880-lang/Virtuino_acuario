"""Une las pestañas del sketch como hace el IDE de Arduino (principal primero y el resto por
orden alfabético) y añade los prototipos de las funciones. Solo para las pruebas en el PC."""
import re
import sys
from pathlib import Path

carpeta = Path(sys.argv[1]).resolve()
salida = Path(sys.argv[2])
principal = carpeta / (carpeta.name + ".ino")
otras = sorted(p for p in carpeta.glob("*.ino") if p != principal)
textos = [principal.read_text(encoding="utf-8")] + [p.read_text(encoding="utf-8") for p in otras]

firma = re.compile(r"^(?!\s)(?!(?:if|for|while|switch|return|else)\b)([A-Za-z_][\w:<>]*[\s\*&]+)(\w+)\s*\(([^;{}]*)\)\s*(?:__attribute__\S*\s*)?\{", re.M)
prototipos = []
for t in textos:
    for m in firma.finditer(t):
        tipo, nombre, args = m.group(1).strip(), m.group(2), m.group(3).strip()
        if nombre in ("setup", "loop"):
            continue
        prototipos.append(f"{tipo} {nombre}({args});")

includes = [l for l in textos[0].splitlines() if l.startswith("#include")]
cuerpo = "\n".join(f'#line 1 "{n}"\n{t}' for n, t in zip([principal.name] + [p.name for p in otras], textos))
salida.write_text("#include <Arduino.h>\n" + "\n".join(includes) + "\n" + "\n".join(prototipos) + "\n" + cuerpo, encoding="utf-8")
print(f"{len(textos)} pestañas, {len(prototipos)} prototipos")
