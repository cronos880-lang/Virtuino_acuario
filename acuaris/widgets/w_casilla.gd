class_name WCasilla
extends AcWidget
## Casilla de verificación: marcada envía "valor_on", desmarcada "valor_off".

func _init() -> void:
	interactivo = true


func _marcada() -> bool:
	return tiene_valor() and is_equal_approx(valor(), float(prop("valor_on", 1)))


func al_tocar() -> void:
	solicitar_seguro(float(prop("valor_off", 0)) if _marcada() else float(prop("valor_on", 1)), "pin", "¿Cambiar «%s»?" % str(prop("texto", "")))


func _draw() -> void:
	var l := minf(px(26), size.y - px(4))
	var r := Rect2(px(4), (size.y - l) * 0.5, l, l)
	var c := Estilo.color(prop("color"), Estilo.AGUA)
	var on := _marcada()
	caja(r, c if on else Color("#0a1c28"), c if on else Estilo.TARJETA_BORDE, 6, 1.5)
	if on:
		draw_polyline(PackedVector2Array([r.position + Vector2(l * 0.22, l * 0.52), r.position + Vector2(l * 0.43, l * 0.72), r.position + Vector2(l * 0.78, l * 0.3)]), Estilo.FONDO_ABAJO, px(3), true)
	texto(str(prop("texto", "")), Rect2(r.end.x + px(10), 0, size.x - r.end.x - px(10), size.y), 14, Estilo.TEXTO, "izquierda")
