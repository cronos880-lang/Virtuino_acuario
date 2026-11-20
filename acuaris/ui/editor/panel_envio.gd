class_name PanelEnvio
extends AcceptDialog
## Ventana "Enviar al móvil o tablet" del editor.

signal enviar_ahora

var servidor: ServidorEnvio
var u := 1.0
var auto := true
var _lista: VBoxContainer
var _codigo: Label
var _ips: Label
var _caja_auto: CheckBox


func preparar(srv: ServidorEnvio, escala: float) -> PanelEnvio:
	servidor = srv
	u = escala
	title = "Enviar al móvil o tablet"
	ok_button_text = "Cerrar"
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", roundi(10 * u))
	v.custom_minimum_size = Vector2(520, 0) * u
	add_child(v)
	var pasos := Label.new()
	pasos.text = "1. En el móvil o la tablet abre Acuaris → Conexión → «Recibir del editor del PC».\n2. Elige este PC en la lista (o escribe su dirección).\n3. La primera vez escribe el código. Después ya no hace falta.\n\nEl PC y el dispositivo deben estar en la misma red WiFi."
	pasos.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pasos.custom_minimum_size.x = 520 * u
	pasos.add_theme_color_override("font_color", Estilo.TEXTO_SEC)
	v.add_child(pasos)
	_ips = Label.new()
	_ips.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_ips.custom_minimum_size.x = 520 * u
	v.add_child(_ips)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", roundi(12 * u))
	_codigo = Label.new()
	_codigo.add_theme_font_override("font", Estilo.fuente(true))
	_codigo.add_theme_font_size_override("font_size", roundi(30 * u))
	_codigo.add_theme_color_override("font_color", Estilo.AMBAR)
	h.add_child(_codigo)
	var b_cod := Button.new()
	b_cod.text = "Nuevo código"
	b_cod.tooltip_text = "Cambia el código para nuevos emparejamientos (los ya emparejados siguen funcionando)"
	b_cod.pressed.connect(func(): servidor.nuevo_codigo(); actualizar())
	h.add_child(b_cod)
	v.add_child(h)
	_caja_auto = CheckBox.new()
	_caja_auto.text = "Enviar automáticamente cada cambio"
	_caja_auto.button_pressed = auto
	_caja_auto.toggled.connect(func(x): auto = x)
	v.add_child(_caja_auto)
	var t := Label.new()
	t.text = "DISPOSITIVOS CONECTADOS"
	t.add_theme_font_size_override("font_size", roundi(11 * u))
	t.add_theme_color_override("font_color", Estilo.TEXTO_TENUE)
	v.add_child(t)
	_lista = VBoxContainer.new()
	v.add_child(_lista)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", roundi(8 * u))
	var b_env := Button.new()
	b_env.text = "Enviar ahora"
	b_env.pressed.connect(func(): enviar_ahora.emit())
	hb.add_child(b_env)
	var b_olv := Button.new()
	b_olv.text = "Olvidar dispositivos emparejados"
	b_olv.pressed.connect(func(): servidor.olvidar_emparejados(); actualizar())
	hb.add_child(b_olv)
	v.add_child(hb)
	var nota := Label.new()
	nota.text = "Si Windows pregunta por el cortafuegos, permite el acceso en «redes privadas»."
	nota.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nota.custom_minimum_size.x = 520 * u
	nota.add_theme_font_size_override("font_size", roundi(12 * u))
	nota.add_theme_color_override("font_color", Estilo.TEXTO_TENUE)
	v.add_child(nota)
	servidor.clientes_cambiados.connect(actualizar)
	return self


func actualizar() -> void:
	if servidor == null or _lista == null:
		return
	var ips := EnvioProtocolo.ips_locales()
	_ips.text = "Este PC: %s   ·   dirección: %s" % [servidor.nombre_pc, ", ".join(ips) if not ips.is_empty() else "sin red"]
	var c := servidor.codigo
	_codigo.text = "Código: %s %s" % [c.substr(0, 3), c.substr(3)]
	for h in _lista.get_children():
		h.queue_free()
	var cl := servidor.clientes()
	if cl.is_empty():
		var l := Label.new()
		l.text = "Ninguno todavía. Emparejados guardados: %d" % servidor.num_emparejados()
		l.add_theme_color_override("font_color", Estilo.TEXTO_SEC)
		_lista.add_child(l)
	for d in cl:
		var l := Label.new()
		var est := "BLOQUEADO (no acepta cambios)" if d.rechazado else ("al día (versión %d)" % d.revision if d.revision == servidor.revision else "recibiendo…")
		l.text = "●  %s  ·  %s  ·  %s" % [d.dispositivo, d.ip, est]
		l.add_theme_color_override("font_color", Estilo.AMBAR if d.rechazado else Estilo.VERDE)
		_lista.add_child(l)
