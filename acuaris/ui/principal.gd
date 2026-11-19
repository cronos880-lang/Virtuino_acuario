extends Control
## Aplicación Acuaris (ejecución): carga el proyecto, conecta (simulador o Bluetooth) y muestra la interfaz.
##
## Argumentos de línea de órdenes (después de "--"), útiles en PC para pruebas y capturas:
##   --proyecto=<ruta.json>  --pantalla=panel|conexion|medir  --hora=HH:MM
##   --segundos=<N> (simula N segundos antes de capturar)  --captura=<archivo.png>

const PROYECTO_DEFECTO := "res://proyectos/acuario.acuaris.json"
const CONFIG := "user://acuaris.cfg"
const ALTO_BARRA_DP := 60.0

var proyecto: Proyecto
var s := 1.0
var comunicador := Comunicador.new()
var enlace: Enlace = null
var barra: BarraSuperior
var scroll: ScrollContainer
var vista: VistaPagina
var capa: Control = null
var args := {}
var config := ConfigFile.new()
var _reintentos := 0
var _desconexion_voluntaria := false
var _t_estado := 0.0


func _ready() -> void:
	args = _leer_args()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	get_tree().set_quit_on_go_back(false)
	add_child(comunicador)
	comunicador.valor_actualizado.connect(_al_valor)
	config.load(CONFIG)
	proyecto = Proyecto.desde_archivo(str(args.get("proyecto", PROYECTO_DEFECTO)))
	comunicador.intervalo_ronda_ms = proyecto.intervalo_ms()
	comunicador.fijar_pines(proyecto.todos_los_pines())
	_construir()
	get_viewport().size_changed.connect(_construir)
	if not proyecto.errores.is_empty():
		_mostrar_errores()
		return
	if args.has("captura"):
		_modo_captura()
		return
	if OS.has_feature("mobile"):
		var ultimo := str(config.get_value("conexion", "direccion", ""))
		if ultimo == "simulador":
			conectar_simulador()
		elif ultimo != "" and EnlaceBluetooth.disponible():
			conectar_bluetooth(ultimo, str(config.get_value("conexion", "nombre", "")))
		else:
			mostrar_conexion()
	else:
		conectar_simulador()


func _leer_args() -> Dictionary:
	var r := {}
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--"):
			var partes := a.substr(2).split("=", true, 1)
			r[partes[0]] = partes[1] if partes.size() > 1 else true
	return r


# ------------------------------------------------------------------ construcción
func _construir() -> void:
	var tam := get_viewport_rect().size
	s = tam.x / proyecto.ancho_dp()
	# Se redibuja solo la interfaz: el comunicador y la conexión activa se conservan.
	for h in get_children():
		if h != comunicador and h != enlace and not (h is Enlace):
			h.queue_free()
	capa = null
	var fondo := FondoDegradado.new()
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fondo)
	var margen_sup := 0.0
	if OS.has_feature("mobile"):
		margen_sup = maxf(0.0, DisplayServer.get_display_safe_area().position.y - (DisplayServer.screen_get_size().y - tam.y))
	barra = BarraSuperior.new()
	barra.s = s
	barra.subtitulo = "Proyecto: " + proyecto.nombre()
	barra.position = Vector2(0, margen_sup)
	barra.size = Vector2(tam.x, ALTO_BARRA_DP * s)
	barra.pulsado_estado.connect(mostrar_conexion)
	add_child(barra)
	scroll = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	scroll.position = Vector2(0, barra.position.y + barra.size.y)
	scroll.size = Vector2(tam.x, tam.y - scroll.position.y)
	add_child(scroll)
	vista = VistaPagina.new()
	scroll.add_child(vista)
	vista.escritura_solicitada.connect(comunicador.escribir)
	if not proyecto.paginas().is_empty():
		vista.construir(proyecto.paginas()[0], s, proyecto.ancho_dp(), proyecto.alto_dp())
	for p in comunicador.valores:
		vista.recibir(p, comunicador.valores[p])
	_actualizar_estado()


func _al_valor(pin: String, v: float) -> void:
	if vista:
		vista.recibir(pin, v)


# ------------------------------------------------------------------ conexiones
func _cambiar_enlace(nuevo: Enlace) -> void:
	if enlace:
		_desconexion_voluntaria = true
		enlace.desconectar()
		enlace.queue_free()
	_desconexion_voluntaria = false
	enlace = nuevo
	add_child(enlace)
	enlace.estado_cambiado.connect(_al_estado_enlace)
	comunicador.valores.clear()
	comunicador.fijar_enlace(enlace)
	_construir()


func conectar_simulador() -> void:
	var e := EnlaceSimulado.new()
	if args.has("hora"):
		var hm := str(args.hora).split(":")
		e.simulador.fijar_hora(hm[0].to_int(), hm[1].to_int() if hm.size() > 1 else 0)
	_cambiar_enlace(e)
	e.conectar()
	_guardar_conexion("simulador", "Simulador")


func conectar_bluetooth(direccion: String, nombre: String) -> void:
	var e := EnlaceBluetooth.new()
	e.descripcion = nombre
	_cambiar_enlace(e)
	_reintentos = 0
	e.conectar(direccion)
	_guardar_conexion(direccion, nombre)


func _guardar_conexion(direccion: String, nombre: String) -> void:
	config.set_value("conexion", "direccion", direccion)
	config.set_value("conexion", "nombre", nombre)
	config.save(CONFIG)


func _al_estado_enlace(estado: int, _detalle: String) -> void:
	_actualizar_estado()
	# Reconexión automática del Bluetooth si se corta (hasta 5 intentos).
	if enlace is EnlaceBluetooth and not _desconexion_voluntaria:
		if estado == Enlace.Estado.CONECTADO:
			_reintentos = 0
		elif (estado == Enlace.Estado.DESCONECTADO or estado == Enlace.Estado.ERROR) and _reintentos < 5:
			_reintentos += 1
			var e: EnlaceBluetooth = enlace
			get_tree().create_timer(3.0).timeout.connect(func():
				if is_instance_valid(e) and e == enlace and not e.esta_conectado():
					e.conectar(e.direccion))


func _process(delta: float) -> void:
	_t_estado += delta
	if _t_estado > 0.5:
		_t_estado = 0.0
		_actualizar_estado()


func _actualizar_estado() -> void:
	if barra == null:
		return
	var txt := "Sin conexión"
	var col := Estilo.ROJO
	if enlace:
		match enlace.estado:
			Enlace.Estado.CONECTADO:
				txt = enlace.descripcion if enlace.descripcion != "" else "Conectado"
				col = Estilo.VERDE
				var silencio := Time.get_ticks_msec() - comunicador.ultima_respuesta_ms
				if comunicador.ultima_respuesta_ms >= 0 and silencio > 5000:
					txt = "Sin respuesta"
					col = Estilo.AMBAR
			Enlace.Estado.CONECTANDO:
				txt = "Conectando…"
				col = Estilo.AMBAR
			Enlace.Estado.ERROR:
				txt = "Error de conexión"
	if txt != barra.estado_txt or col != barra.estado_color:
		barra.estado_txt = txt
		barra.estado_color = col
		barra.queue_redraw()


# ------------------------------------------------------------------ pantallas superpuestas
func _nueva_capa(titulo: String) -> VBoxContainer:
	cerrar_capa()
	capa = FondoDegradado.new()
	capa.set_anchors_preset(Control.PRESET_FULL_RECT)
	capa.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(capa)
	var sc := ScrollContainer.new()
	sc.set_anchors_preset(Control.PRESET_FULL_RECT)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	capa.add_child(sc)
	var margen := MarginContainer.new()
	margen.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for lado in ["left", "right"]:
		margen.add_theme_constant_override("margin_" + lado, roundi(16 * s))
	margen.add_theme_constant_override("margin_top", roundi(20 * s))
	margen.add_theme_constant_override("margin_bottom", roundi(24 * s))
	sc.add_child(margen)
	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", roundi(10 * s))
	margen.add_child(caja)
	caja.add_child(_etiqueta(titulo, 24, Estilo.TEXTO, true))
	return caja


func _etiqueta(t: String, tam_dp: float, color: Color, negrita := false) -> Label:
	var l := Label.new()
	l.text = t
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_override("font", Estilo.fuente(negrita))
	l.add_theme_font_size_override("font_size", roundi(tam_dp * s))
	l.add_theme_color_override("font_color", color)
	return l


func cerrar_capa() -> void:
	if capa:
		capa.queue_free()
		capa = null


func mostrar_conexion() -> void:
	var caja := _nueva_capa("Conexión")
	caja.add_child(_etiqueta("Elige con qué controlador quieres trabajar.", 13, Estilo.TEXTO_SEC))
	caja.add_child(_etiqueta("SIN HARDWARE", 12, Estilo.TEXTO_TENUE, true))
	var b_sim := BotonUi.new().preparar(s, "Simulador del acuario", "Arduino virtual que reproduce tu sketch", Estilo.AGUA)
	b_sim.pulsado.connect(func(): cerrar_capa(); conectar_simulador())
	caja.add_child(b_sim)
	caja.add_child(_etiqueta("BLUETOOTH · DISPOSITIVOS EMPAREJADOS", 12, Estilo.TEXTO_TENUE, true))
	if not EnlaceBluetooth.disponible():
		caja.add_child(_etiqueta("El Bluetooth se usa desde la app de Android. En el PC trabaja con el simulador.", 13, Estilo.TEXTO_SEC))
	else:
		var bt := EnlaceBluetooth.new()
		add_child(bt)
		if not bt.tiene_permisos():
			var b_perm := BotonUi.new().preparar(s, "Dar permiso de Bluetooth", "Necesario para ver los dispositivos emparejados", Estilo.AMBAR)
			b_perm.pulsado.connect(func(): bt.solicitar_permisos())
			bt.permisos_resueltos.connect(func(_ok): bt.queue_free(); mostrar_conexion())
			caja.add_child(b_perm)
		elif not bt.bluetooth_activo():
			caja.add_child(_etiqueta("El Bluetooth del teléfono está apagado. Actívalo y vuelve a esta pantalla.", 13, Estilo.AMBAR))
			bt.queue_free()
		else:
			var lista := bt.dispositivos_emparejados()
			bt.queue_free()
			if lista.is_empty():
				caja.add_child(_etiqueta("No hay dispositivos emparejados. Empareja el HC-06 en los ajustes de Bluetooth de Android (PIN habitual 1234).", 13, Estilo.TEXTO_SEC))
			for d in lista:
				var nombre := str(d.get("nombre", "?"))
				var dir := str(d.get("direccion", ""))
				var b := BotonUi.new().preparar(s, nombre, dir, Estilo.VERDE if nombre.to_upper().begins_with("HC-") else Estilo.TEXTO_TENUE)
				b.pulsado.connect(func(): cerrar_capa(); conectar_bluetooth(dir, nombre))
				caja.add_child(b)
	caja.add_child(_etiqueta("HERRAMIENTAS", 12, Estilo.TEXTO_TENUE, true))
	var b_medir := BotonUi.new().preparar(s, "Medir este móvil", "Tamaño, densidad y márgenes reales", Estilo.LUZ)
	b_medir.pulsado.connect(mostrar_medicion)
	caja.add_child(b_medir)
	if enlace:
		var b_volver := BotonUi.new().preparar(s, "Volver al panel")
		b_volver.destacado = true
		b_volver.pulsado.connect(cerrar_capa)
		caja.add_child(b_volver)


func mostrar_medicion() -> void:
	var caja := _nueva_capa("Medir este móvil")
	var perfil := Perfiles.medir_este_dispositivo()
	var px: Array = perfil.pantalla_px
	var d: float = perfil.densidad
	var lineas := [
		"Modelo: %s" % OS.get_model_name(),
		"Sistema: %s" % perfil.sistema,
		"Pantalla: %d x %d px" % [px[0], px[1]],
		"DPI del sistema: %d  ·  densidad: %.4f px/dp" % [perfil.dpi_sistema, d],
		"Tamaño útil: %d x %d dp" % [roundi(px[0] / d), roundi(px[1] / d)] if d > 0 else "",
		"Márgenes del sistema: %d dp arriba, %d dp abajo" % [perfil.margen_superior_dp, perfil.margen_inferior_dp],
		"Ventana de la app: %d x %d px" % [perfil.ventana_px[0], perfil.ventana_px[1]],
	]
	for l in lineas:
		if l != "":
			caja.add_child(_etiqueta(l, 14, Estilo.TEXTO))
	if not OS.has_feature("mobile"):
		caja.add_child(_etiqueta("Estás en un PC: esta medición describe el monitor, no el móvil.", 13, Estilo.AMBAR))
	var b_copiar := BotonUi.new().preparar(s, "Copiar perfil", "Para pegarlo en el diseñador", Estilo.AGUA)
	b_copiar.pulsado.connect(func():
		DisplayServer.clipboard_set(JSON.stringify(perfil, "  "))
		b_copiar.detalle = "Copiado al portapapeles"
		b_copiar.queue_redraw())
	caja.add_child(b_copiar)
	var b_volver := BotonUi.new().preparar(s, "Volver")
	b_volver.destacado = true
	b_volver.pulsado.connect(mostrar_conexion)
	caja.add_child(b_volver)


func _mostrar_errores() -> void:
	var caja := _nueva_capa("Proyecto con errores")
	for e in proyecto.errores:
		caja.add_child(_etiqueta("• " + e, 13, Estilo.ROJO))


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if capa and enlace:
			cerrar_capa()
		else:
			get_tree().quit()


# ------------------------------------------------------------------ capturas (PC)
func _modo_captura() -> void:
	conectar_simulador()
	var e: EnlaceSimulado = enlace
	var segundos := float(args.get("segundos", 20))
	var t := 0
	var pasos := int(segundos * 10.0)
	for i in pasos:
		t += 100
		e.paso(0.1)
		comunicador.tick(t)
	match str(args.get("pantalla", "panel")):
		"conexion":
			mostrar_conexion()
		"medir":
			mostrar_medicion()
	_actualizar_estado()
	for i in 4:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(str(args.captura))
	print("Captura guardada: %s (%dx%d)" % [args.captura, img.get_width(), img.get_height()])
	get_tree().quit()
