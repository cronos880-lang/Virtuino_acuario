class_name WOpciones
extends AcWidget
## Elegir uno entre varios valores. tipo "opciones" = botones de radio en columna;
## tipo "grupo_botones" = fila de botones unidos (modos Apagado / Auto / Manual...).
## props.opciones = "Apagado:0, Auto:1, Manual:2"

var _rects: Array[Rect2] = []


func _init() -> void:
	interactivo = true


func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and not e.pressed:
		var ops := opciones_prop()
		for i in _rects.size():
			if _rects[i].has_point(e.position) and i < ops.size():
				solicitar_seguro(ops[i][1], "pin", "¿Elegir «%s»?" % ops[i][0])
				accept_event()
				return


func _draw() -> void:
	_rects.clear()
	var ops := opciones_prop()
	if ops.is_empty():
		texto("Sin opciones", Rect2(Vector2.ZERO, size), 12, Estilo.TEXTO_TENUE)
		return
	var c := Estilo.color(prop("color"), Estilo.AGUA)
	var activo := -1
	for i in ops.size():
		if tiene_valor() and is_equal_approx(valor(), ops[i][1]):
			activo = i
	if str(def.get("tipo")) == "grupo_botones":
		var ancho := size.x / ops.size()
		caja(Rect2(Vector2.ZERO, size), Color("#0a1c28"), Estilo.TARJETA_BORDE, 12)
		for i in ops.size():
			var r := Rect2(i * ancho, 0, ancho, size.y)
			_rects.append(r)
			if i == activo:
				caja(r.grow(-px(3)), c, Color.TRANSPARENT, 10)
			texto(str(ops[i][0]), r, 13.5, Estilo.FONDO_ABAJO if i == activo else Estilo.TEXTO, "centro", i == activo)
		return
	var alto := size.y / ops.size()
	for i in ops.size():
		var r := Rect2(0, i * alto, size.x, alto)
		_rects.append(r)
		var cc := Vector2(px(14), r.get_center().y)
		draw_circle(cc, px(9), c if i == activo else Estilo.TARJETA_BORDE, false, px(2), true)
		if i == activo:
			draw_circle(cc, px(5), c, true, -1, true)
		texto(str(ops[i][0]), Rect2(px(32), r.position.y, size.x - px(32), alto), 14, Estilo.TEXTO, "izquierda")
