class_name WEtiqueta
extends AcWidget
## Texto fijo (admite varias líneas con \n).

func _draw() -> void:
	texto(str(prop("texto", "")), Rect2(Vector2.ZERO, size), float(prop("tam", 14)),
		Estilo.color(prop("color"), Estilo.TEXTO), str(prop("alineacion", "izquierda")), bool(prop("negrita", false)))
