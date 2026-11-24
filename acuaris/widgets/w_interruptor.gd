class_name WInterruptor
extends AcWidget
## Interruptor deslizante: escribe 1/0 en el pin y muestra el estado que devuelve el controlador.
## "interruptor_luz": además lleva una luz a la izquierda que muestra el estado REAL leído de
## pin_luz (por ejemplo, el interruptor manda V15 y la luz lee V8 = bomba en marcha). Sin pin_luz,
## la luz sigue al propio interruptor.

func _init() -> void:
	interactivo = true


func al_tocar() -> void:
	solicitar_seguro(0.0 if valor() >= 0.5 else 1.0, "pin", "¿%s «%s»?" % ["Desactivar" if valor() >= 0.5 else "Activar", str(prop("texto", pin_de()))])


func _draw() -> void:
	var on := tiene_valor() and valor() >= 0.5
	var c_on := Estilo.color(prop("color_on"), Estilo.AGUA)
	var w := px(50)
	var h := px(28)
	var pista := Rect2(size.x - w - px(4), (size.y - h) * 0.5, w, h)
	caja(pista, c_on if on else Estilo.APAGADO, Color.TRANSPARENT, 14)
	var radio := h * 0.5 - px(3)
	var cx := pista.end.x - h * 0.5 if on else pista.position.x + h * 0.5
	var col_bola := Color.WHITE if tiene_valor() else Estilo.TEXTO_TENUE
	if _pulsado:
		draw_circle(Vector2(cx, pista.get_center().y), radio * 1.6, Color(1, 1, 1, 0.12), true, -1, true)
	draw_circle(Vector2(cx, pista.get_center().y) + Vector2(0, px(1)), radio, Color(0, 0, 0, 0.25), true, -1, true)
	draw_circle(Vector2(cx, pista.get_center().y), radio, col_bola, true, -1, true)
	var x0 := px(4)
	if str(def.get("tipo")) == "interruptor_luz":
		var p_luz := pin_de("pin_luz")
		var hay := tiene_valor("pin_luz") if p_luz != "" else tiene_valor()
		var luz_on: bool = hay and (valores[p_luz] >= 0.5 if p_luz != "" else on)
		var c_luz := Estilo.color(prop("color_luz"), Estilo.VERDE)
		var rl := minf(size.y * 0.5 - px(4), px(11))
		var cl := Vector2(px(6) + rl, size.y * 0.5)
		if luz_on:
			draw_circle(cl, rl * 1.9, Color(c_luz, 0.10), true, -1, true)
			draw_circle(cl, rl * 1.45, Color(c_luz, 0.22), true, -1, true)
		draw_circle(cl, rl, c_luz if luz_on else Estilo.APAGADO, true, -1, true)
		draw_circle(cl, rl, Color(1, 1, 1, 0.25 if luz_on else 0.08), false, px(1.2), true)
		draw_circle(cl + Vector2(-rl * 0.32, -rl * 0.32), rl * 0.32, Color(1, 1, 1, 0.45 if luz_on else 0.10), true, -1, true)
		x0 = cl.x + rl + px(10)
	var etiqueta := str(prop("texto", ""))
	var detalle := ""
	if prop("texto_on") != null and tiene_valor():
		detalle = str(prop("texto_on")) if on else str(prop("texto_off", ""))
	if detalle != "":
		texto(etiqueta, Rect2(x0, 0, pista.position.x - px(8) - x0, size.y * 0.58), 14, Estilo.TEXTO, "izquierda")
		texto(detalle, Rect2(x0, size.y * 0.5, pista.position.x - px(8) - x0, size.y * 0.45), 11.5, c_on if on else Estilo.TEXTO_SEC, "izquierda")
	else:
		texto(etiqueta, Rect2(x0, 0, pista.position.x - px(8) - x0, size.y), 14, Estilo.TEXTO, "izquierda")
