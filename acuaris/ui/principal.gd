extends Control
## Aplicación Acuaris (ejecución): carga el proyecto, conecta (simulador o Bluetooth) y muestra la interfaz.
##
## Argumentos de línea de órdenes (después de "--"), útiles en PC para pruebas y capturas:
##   --proyecto=<ruta.json>  --pantalla=panel|conexion|medir  --hora=HH:MM
##   --segundos=<N> (simula N segundos antes de capturar)  --captura=<archivo.png>

const PROYECTO_DEFECTO := "res://proyectos/acuario.acuaris.json"
const CONFIG := "user://acuaris.cfg"
const ALTO_BARRA_DP := 60.0
const PROYECTO_RECIBIDO := "user://proyecto_recibido.acuaris.json"

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
var _pagina := 0
var receptor := ReceptorEnvio.new()
var _pantalla := ""
var _ip_escrita := ""
var _codigo_escrito := ""


func _ready() -> void:
	args = _leer_args()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	get_tree().set_quit_on_go_back(false)
	add_child(comunicador)
	comunicador.valor_actualizado.connect(_al_valor)
	config.load(CONFIG)
	Historial.cargar()
	var t_hist := Timer.new()
	t_hist.wait_time = 60.0
	t_hist.autostart = true
	t_hist.timeout.connect(Historial.guardar)
	add_child(t_hist)
	add_child(receptor)
	receptor.proyecto_recibido.connect(_al_recibir_proyecto)
	receptor.estado_cambiado.connect(func(_e, _d): _al_cambiar_recepcion())
	receptor.pcs_encontrados.connect(func(_l): _al_cambiar_recepcion())
	_aplicar_proyecto(_proyecto_inicial())
	_construir()
	get_viewport().size_changed.connect(_construir)
	if not proyecto.errores.is_empty():
		_mostrar_errores()
		return
	if args.has("captura"):
		_modo_captura()
		return
	if OS.has_feature("mobile"):
		# Si ya estaba emparejado con un editor, se vuelve a enlazar solo para recibir cambios.
		var pc := receptor.ultimo_pc()
		if not pc.is_empty() and not receptor.bloqueado and receptor.tiene_token(pc):
			receptor.conectar(pc)
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
		if h != comunicador and h != enlace and h != receptor and not (h is Enlace) and not (h is Timer):
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
	barra.subtitulo = _subtitulo()
	barra.position = Vector2(0, margen_sup)
	barra.size = Vector2(tam.x, ALTO_BARRA_DP * s)
	barra.pulsado_estado.connect(mostrar_conexion)
	add_child(barra)
	var y_contenido := barra.position.y + barra.size.y
	if proyecto.paginas().size() > 1:
		var pest := PestanasApp.new()
		pest.s = s
		pest.actual = _pagina
		for p in proyecto.paginas():
			pest.nombres.append(str(p.get("nombre", "Página")))
		pest.position = Vector2(0, y_contenido)
		pest.size = Vector2(tam.x, 46 * s)
		pest.elegida.connect(func(i): _pagina = i; _construir())
		add_child(pest)
		y_contenido += pest.size.y
	scroll = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	scroll.position = Vector2(0, y_contenido)
	scroll.size = Vector2(tam.x, tam.y - scroll.position.y)
	add_child(scroll)
	vista = VistaPagina.new()
	scroll.add_child(vista)
	vista.escritura_solicitada.connect(comunicador.escribir)
	if not proyecto.paginas().is_empty():
		_pagina = clampi(_pagina, 0, proyecto.paginas().size() - 1)
		vista.construir(proyecto.paginas()[_pagina], s, proyecto.ancho_dp(), proyecto.alto_dp())
	for p in comunicador.valores:
		vista.recibir(p, comunicador.valores[p])
	_actualizar_estado()


func _subtitulo() -> String:
	var t := "Proyecto: " + proyecto.nombre()
	if receptor.conectado():
		t += "  ·  enlazado con el PC"
	return t


# ------------------------------------------------------------------ proyecto (incluido o recibido del editor)
func _proyecto_inicial() -> Proyecto:
	if args.has("proyecto"):
		return Proyecto.desde_archivo(str(args.proyecto))
	if FileAccess.file_exists(PROYECTO_RECIBIDO):
		var p := Proyecto.desde_archivo(PROYECTO_RECIBIDO)
		if p.errores.is_empty():
			return p
	return Proyecto.desde_archivo(PROYECTO_DEFECTO)


func _aplicar_proyecto(p: Proyecto) -> void:
	proyecto = p
	comunicador.intervalo_ronda_ms = proyecto.intervalo_ms()
	comunicador.fijar_pines(proyecto.todos_los_pines())
	if OS.has_feature("mobile") and proyecto.errores.is_empty():
		DisplayServer.screen_set_orientation(DisplayServer.SCREEN_LANDSCAPE if proyecto.ancho_dp() > proyecto.alto_dp() else DisplayServer.SCREEN_PORTRAIT)


func _al_recibir_proyecto(datos: Dictionary, revision: int) -> void:
	var p := Proyecto.new()
	if not p.cargar_texto(JSON.stringify(datos)):
		_aviso_breve("Interfaz recibida con errores: no se aplica", Estilo.ROJO)
		return
	var f := FileAccess.open(PROYECTO_RECIBIDO, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(datos))
		f.close()
	var estaba := _pantalla
	_aplicar_proyecto(p)
	_construir()
	if estaba == "recepcion":
		mostrar_recepcion()
	_aviso_breve("Interfaz actualizada desde el PC (versión %d)" % revision, Estilo.VERDE)


func volver_a_original() -> void:
	receptor.desconectar()
	if FileAccess.file_exists(PROYECTO_RECIBIDO):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PROYECTO_RECIBIDO))
	_aplicar_proyecto(Proyecto.desde_archivo(PROYECTO_DEFECTO))
	_construir()
	_aviso_breve("Vuelta a la interfaz original del acuario", Estilo.AGUA)


func _al_cambiar_recepcion() -> void:
	if barra:
		barra.subtitulo = _subtitulo()
		barra.queue_redraw()
	if _pantalla == "recepcion":
		mostrar_recepcion()


func _aviso_breve(texto: String, color: Color) -> void:
	var l := Label.new()
	l.text = texto
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", Estilo.fuente(true))
	l.add_theme_font_size_override("font_size", roundi(14 * s))
	l.add_theme_color_override("font_color", Estilo.FONDO_ABAJO)
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(roundi(14 * s))
	sb.content_margin_left = 16 * s
	sb.content_margin_right = 16 * s
	sb.content_margin_top = 10 * s
	sb.content_margin_bottom = 10 * s
	l.add_theme_stylebox_override("normal", sb)
	var tam := get_viewport_rect().size
	l.size = Vector2(tam.x - 32 * s, 0)
	l.position = Vector2(16 * s, tam.y - 110 * s)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(l)
	get_tree().create_timer(3.5).timeout.connect(func(): if is_instance_valid(l): l.queue_free())


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
	_pantalla = ""
	if capa:
		capa.queue_free()
		capa = null


func mostrar_conexion() -> void:
	var caja := _nueva_capa("Conexión")
	_pantalla = "conexion"
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
	caja.add_child(_etiqueta("INTERFAZ · EDITOR DEL PC", 12, Estilo.TEXTO_TENUE, true))
	var det := "Enlazado con %s: los cambios llegan solos" % receptor.pc_actual.get("pc", "el PC") if receptor.conectado() else "Recibe por WiFi lo que diseñas en el PC"
	var b_rec := BotonUi.new().preparar(s, "Recibir del editor del PC", det, Estilo.VERDE if receptor.conectado() else Estilo.AGUA)
	b_rec.pulsado.connect(mostrar_recepcion)
	caja.add_child(b_rec)
	var b_blq := BotonUi.new().preparar(s, "Cambios del PC: " + ("BLOQUEADOS" if receptor.bloqueado else "permitidos"), "Pulsa para " + ("permitirlos" if receptor.bloqueado else "bloquearlos (interfaz terminada)"), Estilo.AMBAR if receptor.bloqueado else Estilo.TEXTO_TENUE)
	b_blq.pulsado.connect(func(): receptor.fijar_bloqueado(not receptor.bloqueado); mostrar_conexion())
	caja.add_child(b_blq)
	if FileAccess.file_exists(PROYECTO_RECIBIDO):
		var b_orig := BotonUi.new().preparar(s, "Volver a la interfaz original", "La del acuario incluida en la app", Estilo.TEXTO_TENUE)
		b_orig.pulsado.connect(func(): volver_a_original(); mostrar_conexion())
		caja.add_child(b_orig)
	caja.add_child(_etiqueta("HERRAMIENTAS", 12, Estilo.TEXTO_TENUE, true))
	var b_medir := BotonUi.new().preparar(s, "Medir este móvil", "Tamaño, densidad y márgenes reales", Estilo.LUZ)
	b_medir.pulsado.connect(mostrar_medicion)
	caja.add_child(b_medir)
	if enlace:
		var b_volver := BotonUi.new().preparar(s, "Volver al panel")
		b_volver.destacado = true
		b_volver.pulsado.connect(cerrar_capa)
		caja.add_child(b_volver)


func _campo(texto: String, marcador: String, teclado: int, al_cambiar: Callable) -> LineEdit:
	var le := LineEdit.new()
	le.text = texto
	le.placeholder_text = marcador
	le.add_theme_font_size_override("font_size", roundi(17 * s))
	le.add_theme_color_override("font_color", Estilo.TEXTO)
	le.add_theme_color_override("font_placeholder_color", Estilo.TEXTO_TENUE)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("#0a1c28")
	sb.border_color = Estilo.TARJETA_BORDE
	sb.set_border_width_all(maxi(1, roundi(s)))
	sb.set_corner_radius_all(roundi(10 * s))
	sb.content_margin_left = 14 * s
	sb.content_margin_right = 14 * s
	sb.content_margin_top = 10 * s
	sb.content_margin_bottom = 10 * s
	le.add_theme_stylebox_override("normal", sb)
	var sbf: StyleBoxFlat = sb.duplicate()
	sbf.border_color = Estilo.AGUA
	le.add_theme_stylebox_override("focus", sbf)
	# Ojo: el teclado "decimal" de Android solo admite UN punto; para direcciones se usa el de URL.
	le.virtual_keyboard_type = teclado
	le.text_changed.connect(al_cambiar)
	return le


func mostrar_recepcion() -> void:
	var caja := _nueva_capa("Recibir del editor del PC")
	_pantalla = "recepcion"
	var e := receptor.estado
	var textos := {
		"parado": "Abre el editor en el PC y pulsa «Enviar al móvil». Después elige el PC aquí.",
		"buscando": "Buscando editores en la red WiFi…",
		"conectando": "Conectando con %s…" % receptor.detalle,
		"esperando": "Esperando respuesta del PC…",
		"necesita_codigo": "Escribe el código de 6 cifras que muestra el editor. %s" % receptor.detalle,
		"conectado": "Enlazado con %s. Cada cambio que hagas en el editor aparecerá aquí solo." % receptor.detalle,
		"desconectado": "Se perdió la conexión con el PC. %s" % receptor.detalle,
		"error": receptor.detalle,
	}
	var col := Estilo.VERDE if e == "conectado" else (Estilo.ROJO if e == "error" else Estilo.TEXTO_SEC)
	caja.add_child(_etiqueta(str(textos.get(e, "")), 14, col))
	if receptor.bloqueado:
		caja.add_child(_etiqueta("Los cambios del PC están BLOQUEADOS en esta app (Conexión → Cambios del PC).", 13, Estilo.AMBAR))
	if e == "necesita_codigo":
		caja.add_child(_campo(_codigo_escrito, "Código (6 cifras)", LineEdit.KEYBOARD_TYPE_NUMBER, func(t): _codigo_escrito = t))
		var b_ok := BotonUi.new().preparar(s, "Aceptar código")
		b_ok.destacado = true
		b_ok.pulsado.connect(func(): receptor.conectar(receptor.pc_actual, _codigo_escrito.replace(" ", "")); _codigo_escrito = "")
		caja.add_child(b_ok)
	if e == "conectado" or e == "desconectado":
		var b_des := BotonUi.new().preparar(s, "Desconectar del PC", "La interfaz recibida se queda en la app", Estilo.TEXTO_TENUE)
		b_des.pulsado.connect(func(): receptor.desconectar())
		caja.add_child(b_des)
	else:
		caja.add_child(_etiqueta("EDITORES ENCONTRADOS", 12, Estilo.TEXTO_TENUE, true))
		if receptor.pcs.is_empty():
			caja.add_child(_etiqueta("…" if e == "buscando" else "Ninguno de momento.", 13, Estilo.TEXTO_SEC))
		for pc in receptor.pcs:
			var emp := receptor.tiene_token(pc)
			var b := BotonUi.new().preparar(s, str(pc.pc), "%s · %s" % [pc.ip, "emparejado" if emp else "pedirá el código"], Estilo.VERDE if emp else Estilo.AGUA)
			b.pulsado.connect(func(): receptor.conectar(pc))
			caja.add_child(b)
		var b_bus := BotonUi.new().preparar(s, "Buscar de nuevo", "En la misma red WiFi que el PC", Estilo.AGUA)
		b_bus.pulsado.connect(func(): receptor.buscar())
		caja.add_child(b_bus)
		caja.add_child(_etiqueta("O ESCRIBE LA DIRECCIÓN QUE MUESTRA EL EDITOR", 12, Estilo.TEXTO_TENUE, true))
		caja.add_child(_campo(_ip_escrita, "Ejemplo: 192.168.1.20", LineEdit.KEYBOARD_TYPE_URL, func(t): _ip_escrita = t))
		var b_ip := BotonUi.new().preparar(s, "Conectar a esta dirección")
		b_ip.pulsado.connect(func():
			var ip := _ip_escrita.strip_edges().replace(",", ".").replace(" ", "")
			if ip.is_valid_ip_address():
				receptor.conectar({"pc": ip, "ip": ip, "puerto": EnvioProtocolo.PUERTO_TCP})
			else:
				_aviso_breve("Dirección no válida", Estilo.ROJO))
		caja.add_child(b_ip)
	var b_volver := BotonUi.new().preparar(s, "Volver")
	b_volver.destacado = true
	b_volver.pulsado.connect(mostrar_conexion)
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
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		Historial.guardar()
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
		"recepcion":
			# Solo para la captura de ejemplo: un PC "encontrado".
			receptor.pcs.append({"pc": "PC-OFICINA", "ip": "192.168.1.20", "puerto": EnvioProtocolo.PUERTO_TCP})
			mostrar_recepcion()
	_actualizar_estado()
	for i in 4:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(str(args.captura))
	print("Captura guardada: %s (%dx%d)" % [args.captura, img.get_width(), img.get_height()])
	get_tree().quit()
