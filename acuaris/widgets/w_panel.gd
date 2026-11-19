class_name WPanel
extends AcWidget
## Tarjeta de agrupación con título y subtítulo.

func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	caja(r, Estilo.color(prop("fondo"), Estilo.TARJETA), Estilo.color(prop("borde"), Estilo.TARJETA_BORDE), float(prop("radio", 16)))
	var titulo := str(prop("titulo", ""))
	if titulo != "":
		texto(titulo, Rect2(px(14), px(8), size.x - px(28), px(22)), 15, Estilo.TEXTO, "izquierda", true)
	var sub := str(prop("subtitulo", ""))
	if sub != "":
		texto(sub, Rect2(px(14), px(28), size.x - px(28), px(16)), 11.5, Estilo.TEXTO_SEC, "izquierda")
