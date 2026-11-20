class_name WBarra
extends AcWidget
## Barra horizontal de nivel.

func _draw() -> void:
	var mn := float(prop("min", 0))
	var mx := float(prop("max", 100))
	var c := Estilo.color(prop("color"), Estilo.LUZ)
	var titulo := str(prop("titulo", ""))
	var txt := "--"
	var frac := 0.0
	if tiene_valor():
		frac = clampf((valor() - mn) / maxf(mx - mn, 0.0001), 0.0, 1.0)
		if str(prop("mostrar", "valor")) == "porcentaje":
			txt = "%d %%" % roundi(frac * 100.0)
		else:
			txt = formatear(valor(), int(prop("decimales", 0))) + " " + str(prop("unidad", ""))
	texto(titulo, Rect2(px(4), 0, size.x * 0.65, px(22)), 13, Estilo.TEXTO_SEC, "izquierda")
	texto(txt.strip_edges(), Rect2(size.x * 0.35, 0, size.x * 0.65 - px(4), px(22)), 14, Estilo.TEXTO, "derecha", true)
	if tiene_valor():
		c = color_alarma(valor(), c)
	var con_escala := bool(prop("escala", false))
	var alto_escala := px(16) if con_escala else 0.0
	var pista := Rect2(px(4), px(28), size.x - px(8), maxf(px(8), size.y - px(32) - alto_escala))
	if con_escala:
		var y := pista.end.y + px(3)
		for i in 11:
			var x := pista.position.x + pista.size.x * i / 10.0
			draw_line(Vector2(x, y), Vector2(x, y + (px(5) if i % 5 == 0 else px(3))), Estilo.TEXTO_TENUE, px(1), true)
		var dec := int(prop("decimales", 0))
		texto(formatear(mn, dec), Rect2(pista.position.x, y + px(4), px(50), px(12)), 9.5, Estilo.TEXTO_TENUE, "izquierda")
		texto(formatear(mx, dec), Rect2(pista.end.x - px(50), y + px(4), px(50), px(12)), 9.5, Estilo.TEXTO_TENUE, "derecha")
	caja(pista, Estilo.APAGADO, Color.TRANSPARENT, 6)
	if frac > 0.0:
		var relleno := Rect2(pista.position, Vector2(maxf(pista.size.y, pista.size.x * frac), pista.size.y))
		caja(relleno, c, Color.TRANSPARENT, 6)
		caja(Rect2(relleno.position, Vector2(relleno.size.x, relleno.size.y * 0.45)), Color(1, 1, 1, 0.18), Color.TRANSPARENT, 6)
