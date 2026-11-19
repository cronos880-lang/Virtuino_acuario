class_name WValor
extends AcWidget
## Valor numérico de un pin con título y unidad.

func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	if bool(prop("con_fondo", true)):
		caja(r, Color(Estilo.APAGADO, 0.35), Color.TRANSPARENT, 12)
	var alin := str(prop("alineacion", "centro"))
	var titulo := str(prop("titulo", ""))
	var y0 := 0.0
	if titulo != "":
		texto(titulo, Rect2(px(10), px(4), size.x - px(20), px(18)), 11.5, Estilo.TEXTO_SEC, alin)
		y0 = px(16)
	var txt := "--"
	if tiene_valor():
		txt = formatear(valor() * float(prop("factor", 1.0)), int(prop("decimales", 1)))
	var unidad := str(prop("unidad", ""))
	if unidad != "":
		txt += " " + unidad
	texto(txt, Rect2(px(6), y0, size.x - px(12), size.y - y0), float(prop("tam", 22)),
		Estilo.color(prop("color"), Estilo.TEXTO), alin, true)
