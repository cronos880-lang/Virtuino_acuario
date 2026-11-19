class_name WLed
extends AcWidget
## Piloto luminoso: encendido si el valor del pin >= umbral.

func _draw() -> void:
	var on := tiene_valor() and valor() >= float(prop("umbral", 0.5))
	var c_on := Estilo.color(prop("color_on"), Estilo.VERDE)
	var c_off := Estilo.color(prop("color_off"), Estilo.APAGADO)
	var r := Rect2(Vector2.ZERO, size)
	if bool(prop("con_fondo", false)):
		caja(r, Color(Estilo.APAGADO, 0.35), Color.TRANSPARENT, 12)
	var radio := minf(size.y * 0.5 - px(4), px(float(prop("radio", 11))))
	var centro := Vector2(px(8) + radio + px(4), size.y * 0.5)
	if on:
		draw_circle(centro, radio * 2.0, Color(c_on, 0.08), true, -1, true)
		draw_circle(centro, radio * 1.55, Color(c_on, 0.18), true, -1, true)
	draw_circle(centro, radio, c_on if on else c_off, true, -1, true)
	draw_circle(centro, radio, Color(1, 1, 1, 0.25 if on else 0.08), false, px(1.2), true)
	draw_circle(centro + Vector2(-radio * 0.32, -radio * 0.32), radio * 0.32, Color(1, 1, 1, 0.45 if on else 0.10), true, -1, true)
	var x_txt := centro.x + radio + px(12)
	var etiqueta := str(prop("texto", ""))
	var estado := ""
	if not tiene_valor():
		estado = "--"
	else:
		estado = str(prop("texto_on", "ON")) if on else str(prop("texto_off", "OFF"))
	var ancho_estado := ancho_texto(estado, 13, true) + px(8)
	if bool(prop("vertical", false)):
		texto(etiqueta, Rect2(x_txt, 0, size.x - x_txt - px(6), size.y * 0.55), 13.5, Estilo.TEXTO, "izquierda", true)
		texto(estado, Rect2(x_txt, size.y * 0.45, size.x - x_txt - px(6), size.y * 0.5), 12.5, c_on if on else Estilo.TEXTO_TENUE, "izquierda", true)
	else:
		texto(etiqueta, Rect2(x_txt, 0, size.x - x_txt - ancho_estado - px(6), size.y), 14, Estilo.TEXTO, "izquierda")
		texto(estado, Rect2(size.x - ancho_estado - px(6), 0, ancho_estado, size.y), 13, c_on if on else Estilo.TEXTO_TENUE, "derecha", true)
