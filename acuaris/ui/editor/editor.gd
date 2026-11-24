extends Control
## Editor de interfaces Acuaris (PC).
##   godot --path acuaris res://ui/editor/editor.tscn [-- --abrir=<ruta> --captura=<png> --seleccionar=<id>]

const EJEMPLO := "res://proyectos/acuario.acuaris.json"

var modelo := ModeloEditor.new()
var u := 1.0
var lienzo: LienzoEditor
var inspector: Inspector
var scroll_lienzo: ScrollContainer
var pestanas: TabBar
var estado: Label
var titulo: Label
var sel_dispositivo: OptionButton
var sel_orientacion: OptionButton
var etiqueta_zoom: Label
var boton_probar: Button
var b_deshacer: Button
var b_rehacer: Button
var zoom_modo := "ajustar"   # "ajustar" | "manual"
var zoom_manual := 1.0
var perfiles: Array = []
var dialogo_archivo: FileDialog
var dialogo_nuevo: ConfirmationDialog
var dialogo_confirmar: ConfirmationDialog
var _accion_pendiente: Callable

var servidor := ServidorEnvio.new()
var panel_envio: PanelEnvio
var b_enviar: Button
var _temporizador_envio := Timer.new()
var enlace := EnlaceSimulado.new()
var comunicador := Comunicador.new()


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	u = clampf(float(DisplayServer.screen_get_dpi()) / 96.0, 1.0, 3.0)
	var a := _args()
	if a.has("escala-ui"):  # solo para pruebas: simula el escalado de Windows
		u = clampf(str(a["escala-ui"]).to_float(), 1.0, 3.0)
	theme = TemaEditor.crear(u)
	perfiles = Perfiles.cargar_todos()
	get_tree().set_auto_accept_quit(false)
	_construir_interfaz()
	lienzo.fijar_modelo(modelo)
	inspector.fijar_modelo(modelo)
	modelo.cambiado.connect(_al_cambiar)
	modelo.seleccion_cambiada.connect(_actualizar_barra)
	# Simulador siempre en marcha: el diseño se ve con datos vivos.
	add_child(enlace)
	add_child(comunicador)
	enlace.simulador.fijar_hora(16, 20)
	comunicador.fijar_enlace(enlace)
	comunicador.valor_actualizado.connect(lienzo.recibir)
	lienzo.escritura_solicitada.connect(comunicador.escribir)
	enlace.conectar()
	var args := _args()
	var inicial: String = args.get("abrir", EJEMPLO)
	var errores := modelo.abrir(inicial)
	if not errores.is_empty():
		modelo.nuevo("Nuevo proyecto", "samsung_galaxy_a56")
		_aviso("No se pudo abrir %s:\n%s" % [inicial, "\n".join(errores)])
	resized.connect(_actualizar_zoom)
	await get_tree().process_frame
	_actualizar_zoom()
	if args.has("envio"):
		_abrir_envio()
	if args.has("pagina"):
		modelo.ir_a_pagina(int(args.pagina))
	if args.has("seleccionar"):
		modelo.seleccionar(str(args.seleccionar))
	if args.has("captura"):
		# Simula unos minutos para que los valores (y las gráficas) sean realistas.
		var t := 0
		var base := Time.get_unix_time_from_system() - 900.0
		for i in 9000:
			t += 100
			Historial.reloj_externo = base + t / 1000.0
			enlace.paso(0.1)
			comunicador.tick(t)
		for i in 4:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(str(args.captura))
		print("Captura guardada: ", args.captura)
		get_tree().quit()


func _args() -> Dictionary:
	var r := {}
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--"):
			var partes := a.substr(2).split("=", true, 1)
			r[partes[0]] = partes[1] if partes.size() > 1 else true
	return r


# ------------------------------------------------------------------ interfaz
func _construir_interfaz() -> void:
	var fondo := ColorRect.new()
	fondo.color = Color("#0a1620")
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fondo)
	var raiz := VBoxContainer.new()
	raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	raiz.add_theme_constant_override("separation", 0)
	add_child(raiz)
	raiz.add_child(_barra_herramientas())
	var cuerpo := HBoxContainer.new()
	cuerpo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cuerpo.add_theme_constant_override("separation", roundi(8 * u))
	var margen_cuerpo := MarginContainer.new()
	margen_cuerpo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for lado in ["left", "right", "top", "bottom"]:
		margen_cuerpo.add_theme_constant_override("margin_" + lado, roundi(8 * u))
	margen_cuerpo.add_child(cuerpo)
	raiz.add_child(margen_cuerpo)
	cuerpo.add_child(_panel_paleta())
	cuerpo.add_child(_zona_central())
	cuerpo.add_child(_panel_inspector())
	estado = Label.new()
	estado.text = "Listo"
	estado.add_theme_color_override("font_color", Estilo.TEXTO_SEC)
	var me := MarginContainer.new()
	me.add_theme_constant_override("margin_left", roundi(14 * u))
	me.add_theme_constant_override("margin_bottom", roundi(4 * u))
	me.add_child(estado)
	raiz.add_child(me)
	_dialogos()
	# Las ventanas emergentes no heredan el tema del editor: se les asigna expresamente.
	for d in [dialogo_archivo, dialogo_confirmar, dialogo_nuevo, panel_envio]:
		d.theme = theme


func _barra_herramientas() -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", TemaEditor.caja(Color("#0f2433"), 0, u, Vector4(10, 8, 10, 8)))
	# HFlowContainer: si la ventana es estrecha, la barra pasa a dos filas en vez de salirse.
	var h := HFlowContainer.new()
	h.add_theme_constant_override("h_separation", roundi(6 * u))
	h.add_theme_constant_override("v_separation", roundi(6 * u))
	panel.add_child(h)
	var marca := Label.new()
	marca.text = "Acuaris"
	marca.add_theme_font_override("font", Estilo.fuente(true))
	marca.add_theme_font_size_override("font_size", roundi(20 * u))
	h.add_child(marca)
	h.add_child(_separador())
	h.add_child(_boton("Nuevo", _nuevo, "Crear una interfaz nueva"))
	h.add_child(_boton("Abrir", _abrir, "Abrir un proyecto .acuaris.json"))
	h.add_child(_boton("Acuario", func(): _con_confirmacion(func(): modelo.abrir(EJEMPLO); _actualizar_zoom()), "Abrir tu interfaz original del acuario (solo lectura: se guarda con otro nombre)"))
	h.add_child(_boton("Guardar", _guardar, "Ctrl+S"))
	h.add_child(_boton("Guardar como…", _guardar_como))
	h.add_child(_separador())
	b_deshacer = _boton("↶", modelo.deshacer, "Deshacer (Ctrl+Z)")
	b_rehacer = _boton("↷", modelo.rehacer, "Rehacer (Ctrl+Y)")
	h.add_child(b_deshacer)
	h.add_child(b_rehacer)
	h.add_child(_separador())
	sel_dispositivo = OptionButton.new()
	sel_dispositivo.tooltip_text = "Dispositivo de destino"
	var tipos := {"movil": "Móvil", "tablet": "Tablet", "pc": "PC"}
	for p in perfiles:
		sel_dispositivo.add_item("%s · %s" % [tipos.get(p.get("tipo", "movil"), "?"), p.nombre])
		sel_dispositivo.set_item_metadata(sel_dispositivo.item_count - 1, p.id)
	sel_dispositivo.item_selected.connect(func(_i): _cambiar_dispositivo())
	sel_dispositivo.custom_minimum_size.x = 210 * u
	sel_dispositivo.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	sel_dispositivo.fit_to_longest_item = false
	sel_dispositivo.clip_text = true
	h.add_child(sel_dispositivo)
	sel_orientacion = OptionButton.new()
	sel_orientacion.add_item("Vertical")
	sel_orientacion.add_item("Horizontal")
	sel_orientacion.item_selected.connect(func(_i): _cambiar_dispositivo())
	h.add_child(sel_orientacion)
	h.add_child(_separador())
	h.add_child(_boton("−", func(): _zoom_paso(1.0 / 1.2), "Alejar"))
	etiqueta_zoom = Label.new()
	etiqueta_zoom.custom_minimum_size.x = 56 * u
	etiqueta_zoom.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	h.add_child(etiqueta_zoom)
	h.add_child(_boton("+", func(): _zoom_paso(1.2), "Acercar"))
	h.add_child(_boton("Ajustar", func(): zoom_modo = "ajustar"; _actualizar_zoom(), "Ver el dispositivo entero"))
	h.add_child(_boton("1:1", func():
		zoom_modo = "manual"
		zoom_manual = lienzo.zoom_real()
		_actualizar_zoom(), "Tamaño real: el dispositivo a su tamaño físico aproximado (según el DPI del monitor)"))
	boton_probar = _boton("▶ Probar", _alternar_prueba, "Usar la interfaz con el simulador (los interruptores funcionan)")
	boton_probar.toggle_mode = true
	h.add_child(boton_probar)
	b_enviar = _boton("Enviar al móvil", _abrir_envio, "Enviar la interfaz a la app del móvil o la tablet por WiFi")
	h.add_child(b_enviar)
	return panel


func _barra_titulo() -> Control:
	# Nombre del proyecto y archivo, en la línea de las pestañas (no ocupa la barra superior).
	titulo = Label.new()
	titulo.add_theme_color_override("font_color", Estilo.TEXTO_SEC)
	titulo.clip_text = true
	titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	titulo.custom_minimum_size.x = 60 * u
	return titulo


func _separador() -> Control:
	var s := VSeparator.new()
	s.add_theme_constant_override("separation", roundi(10 * u))
	return s


func _boton(t: String, f: Callable, ayuda := "") -> Button:
	var b := Button.new()
	b.text = t
	b.tooltip_text = ayuda
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(f)
	return b


func _panel_paleta() -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = 300 * u
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(sc)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", roundi(10 * u))
	sc.add_child(v)
	var t := Label.new()
	t.text = "Elementos"
	t.add_theme_font_override("font", Estilo.fuente(true))
	t.add_theme_font_size_override("font_size", roundi(17 * u))
	v.add_child(t)
	var buscar := LineEdit.new()
	buscar.placeholder_text = "Buscar elemento…"
	buscar.clear_button_enabled = true
	v.add_child(buscar)
	var grupos: Array = []   # [cabecera, rejilla, [casillas]]
	for g in Esquema.GRUPOS:
		var cab := Button.new()
		cab.flat = true
		cab.alignment = HORIZONTAL_ALIGNMENT_LEFT
		cab.focus_mode = Control.FOCUS_NONE
		cab.add_theme_font_override("font", Estilo.fuente(true))
		cab.add_theme_color_override("font_color", Estilo.AGUA)
		cab.add_theme_color_override("font_hover_color", Color.WHITE)
		v.add_child(cab)
		var rejilla := GridContainer.new()
		rejilla.columns = 2
		rejilla.add_theme_constant_override("h_separation", roundi(8 * u))
		rejilla.add_theme_constant_override("v_separation", roundi(8 * u))
		v.add_child(rejilla)
		var casillas: Array = []
		for tipo in g[1]:
			var e := ElementoPaleta.new().preparar(tipo, u)
			e.elegido.connect(func(tp):
				if boton_probar.button_pressed:
					return
				modelo.anadir(tp)
				_estado("Añadido: %s" % Esquema.info(tp).nombre))
			rejilla.add_child(e)
			casillas.append(e)
		var nombre_grupo: String = g[0]
		var actualizar_cab := func(): cab.text = "%s %s (%d)" % ["▾" if rejilla.visible else "▸", nombre_grupo, casillas.size()]
		cab.pressed.connect(func(): rejilla.visible = not rejilla.visible; actualizar_cab.call())
		actualizar_cab.call()
		grupos.append([cab, rejilla, casillas])
	buscar.text_changed.connect(func(texto):
		var q: String = texto.strip_edges().to_lower()
		for gr in grupos:
			var visibles := 0
			for e in gr[2]:
				var ok: bool = q == "" or str(Esquema.info(e.tipo).nombre).to_lower().contains(q)
				e.visible = ok
				visibles += 1 if ok else 0
			gr[0].visible = visibles > 0
			if q != "":
				gr[1].visible = visibles > 0)
	return panel


func _zona_central() -> Control:
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", roundi(4 * u))
	var h := HBoxContainer.new()
	pestanas = TabBar.new()
	pestanas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pestanas.clip_tabs = false   # fila propia: todas las páginas a la vista (antes se cortaban)
	pestanas.tab_clicked.connect(func(i): modelo.ir_a_pagina(i))
	var t := _barra_titulo()
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(t)
	h.add_child(_boton("+ Página", func(): modelo.anadir_pagina(), "Añadir una página"))
	h.add_child(_boton("Borrar página", func():
		if modelo.paginas().size() <= 1:
			_estado("El proyecto necesita al menos una página")
			return
		_con_confirmacion(func(): modelo.borrar_pagina(), "¿Borrar la página '%s' y sus elementos?" % modelo.pagina().get("nombre", ""))))
	v.add_child(h)
	v.add_child(pestanas)
	scroll_lienzo = ScrollContainer.new()
	scroll_lienzo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll_lienzo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var fondo := TemaEditor.caja(Color("#081219"), 12, u)
	scroll_lienzo.add_theme_stylebox_override("panel", fondo)
	v.add_child(scroll_lienzo)
	lienzo = LienzoEditor.new()
	lienzo.u = u
	lienzo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lienzo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	lienzo.mensaje.connect(_estado)
	scroll_lienzo.add_child(lienzo)
	scroll_lienzo.resized.connect(func(): _actualizar_zoom() if zoom_modo == "ajustar" else lienzo.reconstruir())
	return v


func _panel_inspector() -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = 320 * u
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(sc)
	inspector = Inspector.new()
	inspector.u = u
	inspector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inspector.mensaje.connect(_estado)
	sc.add_child(inspector)
	return panel


func _abrir_envio() -> void:
	if not servidor.activo:
		var e := servidor.iniciar()
		if e != "":
			_aviso(e)
			return
		servidor.publicar(modelo.datos)
	panel_envio.actualizar()
	panel_envio.popup_centered(Vector2i(Vector2(600, 560) * u))


func _publicar() -> void:
	if servidor.activo:
		var n := servidor.publicar(modelo.datos)
		if n > 0:
			_estado("Interfaz enviada a %d dispositivo(s)" % n)


func _actualizar_boton_envio() -> void:
	if b_enviar:
		var n := servidor.clientes().size()
		b_enviar.text = "Enviar al móvil (%d)" % n if servidor.activo else "Enviar al móvil"


func _dialogos() -> void:
	add_child(servidor)
	servidor.aviso.connect(_estado)
	servidor.clientes_cambiados.connect(_actualizar_boton_envio)
	_temporizador_envio.one_shot = true
	_temporizador_envio.wait_time = 0.7
	_temporizador_envio.timeout.connect(_publicar)
	add_child(_temporizador_envio)
	panel_envio = PanelEnvio.new().preparar(servidor, u)
	panel_envio.enviar_ahora.connect(_publicar)
	add_child(panel_envio)
	dialogo_archivo = FileDialog.new()
	dialogo_archivo.access = FileDialog.ACCESS_FILESYSTEM
	dialogo_archivo.use_native_dialog = true
	dialogo_archivo.filters = PackedStringArray(["*.acuaris.json ; Proyectos Acuaris", "*.json ; JSON"])
	var docs := OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)
	if docs != "":
		DirAccess.make_dir_recursive_absolute(docs.path_join("Acuaris"))
		dialogo_archivo.current_dir = docs.path_join("Acuaris")
	add_child(dialogo_archivo)
	dialogo_confirmar = ConfirmationDialog.new()
	dialogo_confirmar.title = "Acuaris"
	dialogo_confirmar.ok_button_text = "Continuar"
	dialogo_confirmar.cancel_button_text = "Cancelar"
	dialogo_confirmar.confirmed.connect(func(): if _accion_pendiente.is_valid(): _accion_pendiente.call())
	add_child(dialogo_confirmar)
	dialogo_nuevo = ConfirmationDialog.new()
	dialogo_nuevo.title = "Nueva interfaz"
	dialogo_nuevo.ok_button_text = "Crear"
	dialogo_nuevo.cancel_button_text = "Cancelar"
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", roundi(8 * u))
	var nombre := LineEdit.new()
	nombre.name = "Nombre"
	nombre.placeholder_text = "Nombre de la interfaz"
	nombre.custom_minimum_size.x = 380 * u
	v.add_child(_con_etiqueta("Nombre", nombre))
	var disp := OptionButton.new()
	disp.name = "Dispositivo"
	for i in sel_dispositivo.item_count:
		disp.add_item(sel_dispositivo.get_item_text(i))
		disp.set_item_metadata(i, sel_dispositivo.get_item_metadata(i))
	v.add_child(_con_etiqueta("Dispositivo", disp))
	var ori := OptionButton.new()
	ori.name = "Orientacion"
	ori.add_item("Vertical")
	ori.add_item("Horizontal")
	v.add_child(_con_etiqueta("Orientación", ori))
	dialogo_nuevo.add_child(v)
	dialogo_nuevo.confirmed.connect(func():
		var n := nombre.text.strip_edges()
		modelo.nuevo(n if n != "" else "Nueva interfaz", str(disp.get_item_metadata(disp.selected)), "horizontal" if ori.selected == 1 else "vertical")
		zoom_modo = "ajustar"
		_actualizar_zoom()
		_estado("Interfaz nueva creada. Añade elementos desde la izquierda."))
	add_child(dialogo_nuevo)


func _con_etiqueta(t: String, c: Control) -> Control:
	var v := VBoxContainer.new()
	var l := Label.new()
	l.text = t
	l.add_theme_color_override("font_color", Estilo.TEXTO_SEC)
	v.add_child(l)
	v.add_child(c)
	return v


# ------------------------------------------------------------------ acciones
func _con_confirmacion(f: Callable, pregunta := "") -> void:
	if pregunta == "" and not modelo.modificado:
		f.call()
		return
	_accion_pendiente = f
	dialogo_confirmar.dialog_text = pregunta if pregunta != "" else "Hay cambios sin guardar. ¿Continuar y perderlos?"
	dialogo_confirmar.popup_centered()


func _nuevo() -> void:
	_con_confirmacion(func():
		var disp: OptionButton = dialogo_nuevo.find_child("Dispositivo", true, false)
		disp.select(sel_dispositivo.selected)
		(dialogo_nuevo.find_child("Nombre", true, false) as LineEdit).text = ""
		dialogo_nuevo.popup_centered())


func _abrir() -> void:
	_con_confirmacion(func():
		dialogo_archivo.file_mode = FileDialog.FILE_MODE_OPEN_FILE
		dialogo_archivo.title = "Abrir proyecto"
		# Empieza en la carpeta del proyecto abierto (al arrancar, los proyectos que trae el programa)
		var carpeta := ProjectSettings.globalize_path(modelo.ruta).get_base_dir() if modelo.ruta != "" else ProjectSettings.globalize_path("res://proyectos")
		if DirAccess.dir_exists_absolute(carpeta):
			dialogo_archivo.current_dir = carpeta
		_conectar_archivo(func(ruta):
			var e := modelo.abrir(ruta)
			if e.is_empty():
				zoom_modo = "ajustar"
				_actualizar_zoom()
				_estado("Abierto: " + ruta)
			else:
				_aviso("No se pudo abrir:\n" + "\n".join(e)))
		dialogo_archivo.popup_centered_ratio(0.6))


func _guardar() -> void:
	if modelo.ruta == "" or modelo.solo_lectura:
		_guardar_como()
		return
	var e := modelo.guardar()
	_estado("Guardado: " + modelo.ruta if e == "" else e)


func _guardar_como() -> void:
	dialogo_archivo.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	dialogo_archivo.title = "Guardar proyecto como"
	dialogo_archivo.current_file = str(modelo.datos.get("nombre", "proyecto")).to_snake_case() + ".acuaris.json"
	_conectar_archivo(func(ruta):
		if not ruta.ends_with(".json"):
			ruta += ".acuaris.json"
		var e := modelo.guardar(ruta)
		_estado("Guardado: " + ruta if e == "" else e))
	dialogo_archivo.popup_centered_ratio(0.6)


func _conectar_archivo(f: Callable) -> void:
	for c in dialogo_archivo.file_selected.get_connections():
		dialogo_archivo.file_selected.disconnect(c.callable)
	dialogo_archivo.file_selected.connect(f, CONNECT_ONE_SHOT)


func _cambiar_dispositivo() -> void:
	var id := str(sel_dispositivo.get_item_metadata(sel_dispositivo.selected))
	var ori := "horizontal" if sel_orientacion.selected == 1 else "vertical"
	if id == str(modelo.datos.get("perfil")) and ori == str(modelo.datos.get("orientacion")):
		return
	modelo.cambiar_dispositivo(id, ori)
	zoom_modo = "ajustar"
	_actualizar_zoom()
	_estado("Dispositivo: %s (%s). Revisa la colocación de los elementos." % [modelo.perfil().get("nombre", id), ori])


func _alternar_prueba() -> void:
	lienzo.modo_prueba = boton_probar.button_pressed
	if lienzo.modo_prueba:
		modelo.seleccionar("")
		# En prueba la rueda del ratón la usan los elementos: se ajusta el zoom para ver la pantalla entera
		zoom_modo = "ajustar"
		_actualizar_zoom()
		_estado("Modo prueba: la interfaz funciona con el simulador del acuario. Pulsa de nuevo para volver a editar.")
	else:
		_estado("Modo edición")
	lienzo.reconstruir()


func _zoom_paso(f: float) -> void:
	if zoom_modo == "ajustar":
		zoom_manual = lienzo.zoom
	zoom_modo = "manual"
	zoom_manual = clampf(zoom_manual * f, 0.2, 6.0)
	_actualizar_zoom()


func _actualizar_zoom() -> void:
	if lienzo == null or scroll_lienzo == null:
		return
	lienzo.zoom = lienzo.zoom_ajustado(scroll_lienzo.size) if zoom_modo == "ajustar" else zoom_manual
	etiqueta_zoom.text = "%d %%" % roundi(lienzo.zoom / u * 100.0)
	lienzo.reconstruir()
	_actualizar_barra()


func _al_cambiar() -> void:
	var sim_modelo := str(modelo.datos.get("simulador", "acuario_v1"))
	if enlace.simulador.modelo != sim_modelo:
		enlace.simulador.configurar_modelo(sim_modelo)
		enlace.simulador.fijar_hora(16, 20)
	if servidor.activo and panel_envio.auto:
		_temporizador_envio.start()
	comunicador.fijar_pines(_pines_proyecto())
	_actualizar_barra()


func _pines_proyecto() -> Array:
	var r := []
	for pag in modelo.paginas():
		for w in pag.get("widgets", []):
			r.append_array(Proyecto.pines_de(w))
	return r


func _actualizar_barra() -> void:
	if titulo == null:
		return
	var nombre_archivo := modelo.ruta.get_file() if modelo.ruta != "" else "sin guardar"
	titulo.text = "%s%s  ·  %s" % [modelo.datos.get("nombre", ""), " *" if modelo.modificado else "", nombre_archivo]
	b_deshacer.disabled = not modelo.puede_deshacer()
	b_rehacer.disabled = not modelo.puede_rehacer()
	for i in sel_dispositivo.item_count:
		if sel_dispositivo.get_item_metadata(i) == modelo.datos.get("perfil"):
			sel_dispositivo.select(i)
	sel_orientacion.select(1 if modelo.datos.get("orientacion") == "horizontal" else 0)
	pestanas.clear_tabs()
	for p in modelo.paginas():
		pestanas.add_tab(str(p.get("nombre", "Página")))
	if pestanas.tab_count > 0:
		pestanas.current_tab = clampi(modelo.pagina_actual, 0, pestanas.tab_count - 1)


func _estado(t: String) -> void:
	if estado:
		estado.text = t


func _aviso(t: String) -> void:
	var a := AcceptDialog.new()
	a.theme = theme
	a.title = "Acuaris"
	a.dialog_text = t
	add_child(a)
	a.popup_centered()


# ------------------------------------------------------------------ teclado y salida
func _shortcut_input(e: InputEvent) -> void:
	if not (e is InputEventKey) or not e.pressed:
		return
	var foco := get_viewport().gui_get_focus_owner()
	var escribiendo := foco is LineEdit or foco is TextEdit or foco is SpinBox or (foco and foco.get_parent() is SpinBox)
	var k: InputEventKey = e
	if k.is_command_or_control_pressed():
		match k.keycode:
			KEY_Z:
				if k.shift_pressed:
					modelo.rehacer()
				else:
					modelo.deshacer()
			KEY_Y:
				modelo.rehacer()
			KEY_S:
				_guardar()
			KEY_D:
				if modelo.seleccion != "" and not escribiendo:
					modelo.duplicar(modelo.seleccion)
			_:
				return
		get_viewport().set_input_as_handled()
		return
	if escribiendo or modelo.seleccion == "" or lienzo.modo_prueba:
		return
	var paso := modelo.rejilla * (4.0 if k.shift_pressed else 1.0)
	var r := modelo.rect_de(modelo.seleccion)
	match k.keycode:
		KEY_DELETE, KEY_BACKSPACE:
			modelo.borrar(modelo.seleccion)
		KEY_LEFT:
			r.position.x -= paso
			modelo.fijar_rect(modelo.seleccion, r)
		KEY_RIGHT:
			r.position.x += paso
			modelo.fijar_rect(modelo.seleccion, r)
		KEY_UP:
			r.position.y -= paso
			modelo.fijar_rect(modelo.seleccion, r)
		KEY_DOWN:
			r.position.y += paso
			modelo.fijar_rect(modelo.seleccion, r)
		KEY_ESCAPE:
			modelo.seleccionar("")
		_:
			return
	get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if modelo.modificado:
			_con_confirmacion(func(): get_tree().quit(), "Hay cambios sin guardar. ¿Salir sin guardar?")
		else:
			get_tree().quit()
