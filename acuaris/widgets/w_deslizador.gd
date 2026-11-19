class_name WDeslizador
extends AcWidget
## Deslizador: arrastrar para elegir y soltar para enviar.

var _arrastrando := false
var _valor_local := 0.0


func _init() -> void:
	interactivo = true


func _pista() -> Rect2:
	return Rect2(px(14), size.y - px(22), size.x - px(28), px(8))


func _valor_en(x: float) -> float:
	var p := _pista()
	var f := clampf((x - p.position.x) / p.size.x, 0.0, 1.0)
	var v := lerpf(float(prop("min", 0)), float(prop("max", 100)), f)
	var paso := float(prop("paso", 1))
	return snappedf(v, paso) if paso > 0 else v


func _gui_input(evento: InputEvent) -> void:
	if evento is InputEventMouseButton and evento.button_index == MOUSE_BUTTON_LEFT:
		_arrastrando = evento.pressed
		_valor_local = _valor_en(evento.position.x)
		if not evento.pressed:
			solicitar(_valor_local)
		queue_redraw()
		accept_event()
	elif evento is InputEventMouseMotion and _arrastrando:
		_valor_local = _valor_en(evento.position.x)
		queue_redraw()
		accept_event()


func _draw() -> void:
	var mn := float(prop("min", 0))
	var mx := float(prop("max", 100))
	var v := _valor_local if _arrastrando else valor("pin", mn)
	var c := Estilo.color(prop("color"), Estilo.AGUA)
	texto(str(prop("titulo", "")), Rect2(px(14), 0, size.x * 0.6, px(24)), 13, Estilo.TEXTO_SEC, "izquierda")
	var txt := formatear(v, int(prop("decimales", 0))) + " " + str(prop("unidad", "")) if (tiene_valor() or _arrastrando) else "--"
	texto(txt.strip_edges(), Rect2(size.x * 0.4, 0, size.x * 0.6 - px(14), px(24)), 14, Estilo.TEXTO, "derecha", true)
	var p := _pista()
	caja(p, Estilo.APAGADO, Color.TRANSPARENT, 4)
	var f := clampf((v - mn) / maxf(mx - mn, 0.0001), 0.0, 1.0)
	caja(Rect2(p.position, Vector2(p.size.x * f, p.size.y)), c, Color.TRANSPARENT, 4)
	var centro := Vector2(p.position.x + p.size.x * f, p.get_center().y)
	draw_circle(centro, px(11), Color(0, 0, 0, 0.25), true, -1, true)
	draw_circle(centro, px(10), Color.WHITE, true, -1, true)
