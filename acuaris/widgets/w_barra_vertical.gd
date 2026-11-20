class_name WBarraVertical
extends AcWidget
## Barra vertical con escala (tipo termómetro), con degradado o color fijo.

func _draw() -> void:
	var mn := float(prop("min", 0))
	var mx := float(prop("max", 100))
	var titulo := str(prop("titulo", ""))
	texto(titulo, Rect2(0, 0, size.x, px(16)), 11.5, Estilo.TEXTO_SEC)
	var txt := (formatear(valor(), int(prop("decimales", 1))) + " " + str(prop("unidad", ""))).strip_edges() if tiene_valor() else "--"
	texto(txt, Rect2(0, size.y - px(20), size.x, px(20)), 14, color_alarma(valor(), Estilo.TEXTO) if tiene_valor() else Estilo.TEXTO, "centro", true)
	var ancho := minf(px(22), size.x * 0.35)
	var pista := Rect2(size.x * 0.5 - ancho * 0.5 - px(8), px(20), ancho, size.y - px(46))
	caja(pista, Estilo.APAGADO, Color.TRANSPARENT, 8)
	var f := clampf((valor() - mn) / maxf(mx - mn, 0.0001), 0.0, 1.0) if tiene_valor() else 0.0
	if f > 0.0:
		var alto := maxf(pista.size.x, pista.size.y * f)
		var r := Rect2(pista.position.x, pista.end.y - alto, pista.size.x, alto)
		if bool(prop("degradado", true)):
			var c0 := Estilo.color(prop("color_inicio"), Estilo.AGUA)
			var c1 := Estilo.color(prop("color_fin"), Estilo.ROJO)
			var ct := c0.lerp(c1, f)
			draw_polygon(PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]),
				PackedColorArray([ct, ct, c0, c0]))
		else:
			caja(r, color_alarma(valor(), Estilo.color(prop("color"), Estilo.AGUA)), Color.TRANSPARENT, 8)
	# Escala a la derecha
	var dec := int(prop("decimales_escala", 0))
	for i in 11:
		var y := pista.end.y - pista.size.y * i / 10.0
		var mayor := i % 5 == 0
		draw_line(Vector2(pista.end.x + px(3), y), Vector2(pista.end.x + (px(9) if mayor else px(6)), y), Estilo.TEXTO_TENUE, px(1), true)
		if mayor:
			texto(formatear(lerpf(mn, mx, i / 10.0), dec), Rect2(pista.end.x + px(10), y - px(7), size.x, px(14)), 9.5, Estilo.TEXTO_TENUE, "izquierda")
