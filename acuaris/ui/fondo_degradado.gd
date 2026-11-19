class_name FondoDegradado
extends Control
## Fondo con degradado vertical (vectorial, sin imágenes).

func _ready() -> void:
	resized.connect(queue_redraw)


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	draw_polygon(
		PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]),
		PackedColorArray([Estilo.FONDO_ARRIBA, Estilo.FONDO_ARRIBA, Estilo.FONDO_ABAJO, Estilo.FONDO_ABAJO]))
