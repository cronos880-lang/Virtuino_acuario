class_name WManometro
extends AcWidget
## Instrumento analógico con aguja, escala numerada y zonas verde / ámbar / roja.

const A0 := deg_to_rad(135.0)
const A1 := deg_to_rad(405.0)


func _ang(v: float, mn: float, mx: float) -> float:
	return lerpf(A0, A1, clampf((v - mn) / maxf(mx - mn, 0.0001), 0.0, 1.0))


func _draw() -> void:
	var mn := float(prop("min", 0))
	var mx := float(prop("max", 100))
	var lado := minf(size.x, size.y)
	var c := size * 0.5
	var radio := lado * 0.5 - px(6)
	var k := lado / px(200.0)
	draw_circle(c, radio, Color("#0b2233"), true, -1, true)
	draw_circle(c, radio, Estilo.TARJETA_BORDE, false, px(2), true)
	# Zonas
	var r_z := radio - px(12) * k
	var z1 := float(prop("zona_verde", mn + (mx - mn) * 0.6))
	var z2 := float(prop("zona_ambar", mn + (mx - mn) * 0.8))
	if not bool(prop("sin_zonas", false)):
		draw_arc(c, r_z, A0, _ang(z1, mn, mx), 64, Color(Estilo.VERDE, 0.85), px(7) * k, true)
		draw_arc(c, r_z, _ang(z1, mn, mx), _ang(z2, mn, mx), 32, Color(Estilo.AMBAR, 0.9), px(7) * k, true)
		draw_arc(c, r_z, _ang(z2, mn, mx), A1, 32, Color(Estilo.ROJO, 0.9), px(7) * k, true)
	# Escala
	var div := int(prop("divisiones", 10))
	var dec := int(prop("decimales_escala", 0))
	for i in div * 5 + 1:
		var a := lerpf(A0, A1, float(i) / (div * 5))
		var d := Vector2.from_angle(a)
		var mayor := i % 5 == 0
		var r1 := radio - px(20) * k
		draw_line(c + d * r1, c + d * (r1 - (px(10) if mayor else px(5)) * k), Estilo.TEXTO if mayor else Estilo.TEXTO_TENUE, px(1.6 if mayor else 1.0), true)
		if mayor and lado > px(110):
			var v := lerpf(mn, mx, float(i) / (div * 5))
			var pt := c + d * (r1 - px(22) * k)
			texto(formatear(v, dec), Rect2(pt - Vector2(px(20), px(8)), Vector2(px(40), px(16))), 10.0 * k, Estilo.TEXTO_SEC)
	# Texto
	var unidad := str(prop("unidad", ""))
	texto(unidad, Rect2(0, c.y + radio * 0.28, size.x, px(16) * k), 12.0 * k, Estilo.TEXTO_SEC)
	var txt := formatear(valor(), int(prop("decimales", 1))) if tiene_valor() else "--"
	texto(txt, Rect2(0, c.y + radio * 0.45, size.x, px(22) * k), 17.0 * k, color_alarma(valor(), Estilo.TEXTO) if tiene_valor() else Estilo.TEXTO, "centro", true)
	var titulo := str(prop("titulo", ""))
	if titulo != "":
		texto(titulo, Rect2(0, c.y - radio * 0.3, size.x, px(14) * k), 10.0 * k, Estilo.TEXTO_SEC)
	# Aguja
	var ang := _ang(valor(), mn, mx) if tiene_valor() else A0
	var dir := Vector2.from_angle(ang)
	var perp := dir.orthogonal()
	var punta := c + dir * (radio - px(24) * k)
	draw_colored_polygon(PackedVector2Array([c + perp * px(4) * k, punta, c - perp * px(4) * k, c - dir * px(14) * k]), Estilo.color(prop("color_aguja"), Estilo.ROJO))
	draw_circle(c, px(8) * k, Color("#dfe9ef"), true, -1, true)
	draw_circle(c, px(3) * k, Color("#0b2233"), true, -1, true)
