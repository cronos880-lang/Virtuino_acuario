class_name WIndicador
extends AcWidget
## Indicador circular (270º) con marcas, zona de color según la consigna y marcador de consigna.

const A0 := deg_to_rad(135.0)
const A1 := deg_to_rad(405.0)


func _ang(v: float, mn: float, mx: float) -> float:
	return lerpf(A0, A1, clampf((v - mn) / maxf(mx - mn, 0.0001), 0.0, 1.0))


func _draw() -> void:
	var mn := float(prop("min", 0))
	var mx := float(prop("max", 100))
	var lado := minf(size.x, size.y)
	var c := size * 0.5
	var grosor := lado * 0.075
	var radio := lado * 0.5 - grosor * 0.5 - px(14)
	var puntos := 128
	# Pista
	draw_arc(c, radio, A0, A1, puntos, Estilo.APAGADO, grosor, true)
	# Color del valor
	var col := Estilo.color(prop("color"), Estilo.AGUA)
	var hay_consigna := pin_de("pin_consigna") != "" and tiene_valor("pin_consigna")
	if hay_consigna and tiene_valor():
		var d := valor() - valor("pin_consigna")
		col = Estilo.VERDE if absf(d) <= float(prop("tolerancia", 0.5)) else (Estilo.CALOR if d > 0 else Estilo.AGUA)
	if tiene_valor():
		var a := _ang(valor(), mn, mx)
		if a > A0 + 0.001:
			draw_arc(c, radio, A0, a, puntos, col, grosor, true)
		draw_circle(c + Vector2.from_angle(A0) * radio, grosor * 0.5, col, true, -1, true)
		draw_circle(c + Vector2.from_angle(a) * radio, grosor * 0.5, col, true, -1, true)
		draw_circle(c + Vector2.from_angle(a) * radio, grosor * 0.22, Color.WHITE, true, -1, true)
	# Marcas
	var divisiones := int(prop("divisiones", 14))
	var r_ext := radio - grosor * 0.5 - px(5)
	for i in divisiones + 1:
		var a := lerpf(A0, A1, float(i) / divisiones)
		var mayor := i % 2 == 0
		var largo := px(7) if mayor else px(4)
		var dir := Vector2.from_angle(a)
		draw_line(c + dir * r_ext, c + dir * (r_ext - largo), Estilo.TEXTO_SEC if mayor else Estilo.TEXTO_TENUE, px(1.4) if mayor else px(1.0), true)
	# Etiquetas mínimo/máximo
	var dec := int(prop("decimales", 1))
	var fs := 10.5
	var pmin := c + Vector2.from_angle(A0) * (radio + grosor * 0.2)
	var pmax := c + Vector2.from_angle(A1) * (radio + grosor * 0.2)
	texto(formatear(mn, 0), Rect2(pmin.x - px(20), pmin.y + px(4), px(40), px(16)), fs, Estilo.TEXTO_TENUE)
	texto(formatear(mx, 0), Rect2(pmax.x - px(20), pmax.y + px(4), px(40), px(16)), fs, Estilo.TEXTO_TENUE)
	# Consigna
	if hay_consigna:
		var ac := _ang(valor("pin_consigna"), mn, mx)
		var dir := Vector2.from_angle(ac)
		var p1 := c + dir * (radio + grosor * 0.5 + px(2))
		var perp := dir.orthogonal()
		var tri := PackedVector2Array([p1, p1 + dir * px(9) + perp * px(5), p1 + dir * px(9) - perp * px(5)])
		draw_colored_polygon(tri, Estilo.AMBAR)
	# Texto central
	var txt := formatear(valor(), dec) if tiene_valor() else "--"
	texto(txt, Rect2(0, c.y - px(26), size.x, px(40)), float(prop("tam", 34)), Estilo.TEXTO, "centro", true)
	texto(str(prop("unidad", "")), Rect2(0, c.y + px(12), size.x, px(18)), 14, Estilo.TEXTO_SEC)
	var titulo := str(prop("titulo", ""))
	if titulo != "":
		texto(titulo, Rect2(0, c.y + radio * 0.62, size.x, px(18)), 12, Estilo.TEXTO_SEC)
