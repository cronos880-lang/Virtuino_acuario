class_name WTabla
extends AcWidget
## Tabla compacta de varios valores. props.filas = "Temperatura|V35|°C|1; Bomba|V8||0"
## Con la unidad "hora" el valor HHMM se muestra como HH:MM.

static func filas_de(texto: String) -> Array:
	var r := []
	for f in texto.split(";", false):
		var c := f.split("|")
		if c.size() >= 2:
			r.append([c[0].strip_edges(), c[1].strip_edges().to_upper(), c[2].strip_edges() if c.size() > 2 else "", int(c[3]) if c.size() > 3 and c[3].strip_edges().is_valid_int() else 1])
	return r


func recibir(pin: String, v: float) -> void:
	for f in filas_de(str(prop("filas", ""))):
		if AcWidget.normalizar(f[1]) == pin:
			valores[pin] = v
			queue_redraw()
			return
	super(pin, v)


func _draw() -> void:
	caja(Rect2(Vector2.ZERO, size), Estilo.TARJETA, Estilo.TARJETA_BORDE, 14)
	var titulo := str(prop("titulo", ""))
	var y := px(8)
	if titulo != "":
		texto(titulo, Rect2(px(12), y, size.x - px(24), px(18)), 13, Estilo.TEXTO, "izquierda", true)
		y += px(24)
	var filas := filas_de(str(prop("filas", "")))
	if filas.is_empty():
		texto("Define las filas en propiedades", Rect2(0, y, size.x, size.y - y), 11, Estilo.TEXTO_TENUE)
		return
	var alto := (size.y - y - px(6)) / filas.size()
	for i in filas.size():
		var f: Array = filas[i]
		var r := Rect2(px(12), y + i * alto, size.x - px(24), alto)
		if i > 0:
			draw_line(Vector2(r.position.x, r.position.y), Vector2(r.end.x, r.position.y), Color(1, 1, 1, 0.06), px(1))
		texto(f[0], r, 13, Estilo.TEXTO_SEC, "izquierda")
		var p := AcWidget.normalizar(f[1])
		var txt := "--"
		if valores.has(p):
			# Unidad "hora": el valor es HHMM (por ejemplo 710) y se muestra 07:10
			txt = WValor.texto_hora(valores[p]) if f[2] == "hora" else (formatear(valores[p], f[3]) + " " + f[2]).strip_edges()
		texto(txt, r, 14, Estilo.TEXTO, "derecha", true)
