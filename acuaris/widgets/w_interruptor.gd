class_name WInterruptor
extends AcWidget
## Interruptor deslizante: escribe 1/0 en el pin y muestra el estado que devuelve el controlador.

func _init() -> void:
	interactivo = true


func al_tocar() -> void:
	solicitar(0.0 if valor() >= 0.5 else 1.0)


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
	var etiqueta := str(prop("texto", ""))
	var detalle := ""
	if prop("texto_on") != null and tiene_valor():
		detalle = str(prop("texto_on")) if on else str(prop("texto_off", ""))
	if detalle != "":
		texto(etiqueta, Rect2(px(4), 0, pista.position.x - px(12), size.y * 0.58), 14, Estilo.TEXTO, "izquierda")
		texto(detalle, Rect2(px(4), size.y * 0.5, pista.position.x - px(12), size.y * 0.45), 11.5, c_on if on else Estilo.TEXTO_SEC, "izquierda")
	else:
		texto(etiqueta, Rect2(px(4), 0, pista.position.x - px(12), size.y), 14, Estilo.TEXTO, "izquierda")
