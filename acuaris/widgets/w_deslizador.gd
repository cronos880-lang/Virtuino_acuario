class_name WDeslizador
extends AcWidget
## Deslizador horizontal o vertical ("vertical"): arrastrar para elegir y soltar para enviar.
## Con "en_vivo" también envía mientras se arrastra (unas 6 veces por segundo), para ver el efecto al momento.

var _arrastrando := false
var _valor_local := 0.0
var _t_envio := 0
var _ultimo_enviado := NAN


func _init() -> void:
	interactivo = true


func _vertical() -> bool:
	return bool(prop("vertical", false))


func _pista() -> Rect2:
	if _vertical():
		return Rect2(size.x * 0.5 - px(4), px(30), px(8), size.y - px(52))
	return Rect2(px(14), size.y - px(22), size.x - px(28), px(8))


func _valor_en(p: Vector2) -> float:
	var r := _pista()
	var f: float
	if _vertical():
		f = clampf(1.0 - (p.y - r.position.y) / r.size.y, 0.0, 1.0)
	else:
		f = clampf((p.x - r.position.x) / r.size.x, 0.0, 1.0)
	var v := lerpf(float(prop("min", 0)), float(prop("max", 100)), f)
	var paso := float(prop("paso", 1))
	return snappedf(v, paso) if paso > 0 else v


func _gui_input(evento: InputEvent) -> void:
	if evento is InputEventMouseButton and evento.button_index == MOUSE_BUTTON_LEFT:
		_arrastrando = evento.pressed
		_valor_local = _valor_en(evento.position)
		if not evento.pressed:
			solicitar_seguro(_valor_local)
		queue_redraw()
		accept_event()
	elif evento is InputEventMouseMotion and _arrastrando:
		_valor_local = _valor_en(evento.position)
		var ahora := Time.get_ticks_msec()
		var pide := bool(prop("confirmar", false)) or str(prop("clave", "")) != ""
		if bool(prop("en_vivo", false)) and not pide and ahora - _t_envio >= 150 and _valor_local != _ultimo_enviado:
			_t_envio = ahora
			_ultimo_enviado = _valor_local
			solicitar(_valor_local)
		queue_redraw()
		accept_event()


func _draw() -> void:
	var mn := float(prop("min", 0))
	var mx := float(prop("max", 100))
	var v := _valor_local if _arrastrando else valor("pin", mn)
	var c := Estilo.color(prop("color"), Estilo.AGUA)
	var txt := formatear(v, int(prop("decimales", 0))) + " " + str(prop("unidad", "")) if (tiene_valor() or _arrastrando) else "--"
	var p := _pista()
	var f := clampf((v - mn) / maxf(mx - mn, 0.0001), 0.0, 1.0)
	var centro: Vector2
	if _vertical():
		texto(str(prop("titulo", "")), Rect2(0, 0, size.x, px(14)), 11.5, Estilo.TEXTO_SEC)
		texto(txt.strip_edges(), Rect2(0, px(12), size.x, px(16)), 13, Estilo.TEXTO, "centro", true)
		caja(p, Estilo.APAGADO, Color.TRANSPARENT, 4)
		caja(Rect2(p.position.x, p.end.y - p.size.y * f, p.size.x, p.size.y * f), c, Color.TRANSPARENT, 4)
		centro = Vector2(p.get_center().x, p.end.y - p.size.y * f)
	else:
		texto(str(prop("titulo", "")), Rect2(px(14), 0, size.x * 0.6, px(24)), 13, Estilo.TEXTO_SEC, "izquierda")
		texto(txt.strip_edges(), Rect2(size.x * 0.4, 0, size.x * 0.6 - px(14), px(24)), 14, Estilo.TEXTO, "derecha", true)
		caja(p, Estilo.APAGADO, Color.TRANSPARENT, 4)
		caja(Rect2(p.position, Vector2(p.size.x * f, p.size.y)), c, Color.TRANSPARENT, 4)
		centro = Vector2(p.position.x + p.size.x * f, p.get_center().y)
	draw_circle(centro, px(11), Color(0, 0, 0, 0.25), true, -1, true)
	draw_circle(centro, px(10), Color.WHITE, true, -1, true)
