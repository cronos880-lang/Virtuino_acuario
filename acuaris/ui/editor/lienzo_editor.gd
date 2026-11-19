class_name LienzoEditor
extends Control
## Lienzo del editor: dibuja el dispositivo (móvil, tablet o PC) con la página real dentro y
## permite seleccionar, mover y redimensionar elementos con ajuste a la rejilla (dp).

signal mensaje(texto: String)
signal escritura_solicitada(pin: String, valor: float)

const MARGEN := 40.0
const TIRADOR := 9.0

var modelo: ModeloEditor
var zoom := 1.0           # px por dp
var u := 1.0              # escala de la interfaz del propio editor
var modo_prueba := false
var valores: Dictionary = {}

var pantalla := Rect2()   # zona de pantalla del dispositivo (px, en este control)
var _fondo: FondoDegradado
var _barra: BarraSuperior
var _vista: VistaPagina
var _capa: Control
var _accion := ""         # "", "mover", "tirador_<n>"
var _inicio_raton := Vector2.ZERO
var _rect_inicial := Rect2()
var _cambio_en_arrastre := false
var _sobre := ""


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	_fondo = FondoDegradado.new()
	_fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fondo)
	_barra = BarraSuperior.new()
	_barra.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_barra)
	_vista = VistaPagina.new()
	_vista.modo_editor = true
	_vista.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vista.escritura_solicitada.connect(func(p, v): escritura_solicitada.emit(p, v))
	add_child(_vista)
	_capa = Control.new()
	_capa.focus_mode = Control.FOCUS_CLICK
	_capa.gui_input.connect(_entrada)
	_capa.draw.connect(_dibujar_capa)
	_capa.set_drag_forwarding(Callable(), _puede_soltar, _soltar)
	_capa.mouse_exited.connect(func(): _sobre = ""; _capa.queue_redraw())
	add_child(_capa)


func fijar_modelo(m: ModeloEditor) -> void:
	modelo = m
	modelo.cambiado.connect(_al_cambiar)
	modelo.seleccion_cambiada.connect(func(): _capa.queue_redraw())
	reconstruir()


func _al_cambiar() -> void:
	if _accion != "":
		var d := modelo.buscar(modelo.seleccion)
		if not d.is_empty():
			_vista.actualizar(d)
		_capa.queue_redraw()
		return
	reconstruir()


func zoom_ajustado(area: Vector2) -> float:
	if modelo == null:
		return 1.0
	var l := modelo.lienzo()
	var marco := _grosor_marco()
	var disp := area - Vector2.ONE * ((MARGEN * 2.0 + 16.0) * u) - Vector2(marco.x * 2.0, marco.y + marco.z)
	return maxf(0.1, minf(disp.x / l.x, disp.y / l.y))


## Escala para ver el dispositivo a su tamaño físico real (aproximado: depende del DPI que
## informe el monitor).
func zoom_real() -> float:
	var p := modelo.perfil()
	var dpi_pc := float(DisplayServer.screen_get_dpi())
	var ppi := float(p.get("ppi_fisico", 0))
	if ppi <= 0.0:
		return u
	return float(p.get("densidad", 1.0)) * dpi_pc / ppi


func tipo_dispositivo() -> String:
	return str(modelo.perfil().get("tipo", "movil"))


## Grosor del marco en px: (lateral, superior, inferior)
func _grosor_marco() -> Vector3:
	match tipo_dispositivo():
		"tablet":
			return Vector3(22, 22, 22) * u
		"pc":
			return Vector3(2, 34, 2) * u
		_:
			return Vector3(12, 18, 14) * u


func reconstruir() -> void:
	if modelo == null:
		return
	var l := modelo.lienzo()
	var marco := _grosor_marco()
	var tam_pantalla := l * zoom
	var total := tam_pantalla + Vector2(marco.x * 2.0, marco.y + marco.z) + Vector2.ONE * MARGEN * 2.0 * u
	custom_minimum_size = total
	var area_padre: Vector2 = get_parent().size if get_parent() is Control else total
	var origen := (Vector2(maxf(total.x, area_padre.x), maxf(total.y, area_padre.y)) - tam_pantalla) * 0.5
	origen.y += (marco.y - marco.z) * 0.5
	pantalla = Rect2(origen.round(), tam_pantalla.round())
	_fondo.position = pantalla.position
	_fondo.size = pantalla.size
	_barra.s = zoom
	_barra.subtitulo = "Proyecto: " + str(modelo.datos.get("nombre", ""))
	_barra.estado_txt = "Simulador"
	_barra.estado_color = Estilo.VERDE
	_barra.position = pantalla.position
	_barra.size = Vector2(pantalla.size.x, ModeloEditor.ALTO_CABECERA_DP * zoom)
	_barra.queue_redraw()
	_vista.position = pantalla.position + Vector2(0, ModeloEditor.ALTO_CABECERA_DP * zoom)
	_vista.modo_editor = not modo_prueba
	_vista.rejilla_dp = 0.0 if modo_prueba else modelo.rejilla * 2.0
	var area := modelo.area_pagina()
	_vista.construir(modelo.pagina(), zoom, area.x, area.y)
	_vista.clip_contents = true
	_vista.size = area * zoom
	for p in valores:
		_vista.recibir(p, valores[p])
	_capa.position = _vista.position
	_capa.size = _vista.size
	_capa.mouse_filter = Control.MOUSE_FILTER_IGNORE if modo_prueba else Control.MOUSE_FILTER_STOP
	_capa.queue_redraw()
	queue_redraw()


func recibir(pin: String, v: float) -> void:
	valores[pin] = v
	if _vista:
		_vista.recibir(pin, v)


# ------------------------------------------------------------------ dibujo del dispositivo
func _draw() -> void:
	if modelo == null:
		return
	var m := _grosor_marco()
	var exterior := Rect2(pantalla.position - Vector2(m.x, m.y), pantalla.size + Vector2(m.x * 2.0, m.y + m.z))
	var sb := StyleBoxFlat.new()
	sb.anti_aliasing = true
	sb.corner_detail = 24
	match tipo_dispositivo():
		"pc":
			sb.bg_color = Color("#2a3440")
			sb.set_corner_radius_all(roundi(8 * u))
			draw_style_box(sb, exterior)
			for i in 3:
				draw_circle(exterior.position + Vector2((18 + i * 18) * u, m.y * 0.5), 5 * u, [Color("#ff5f57"), Color("#febc2e"), Color("#28c840")][i], true, -1, true)
			draw_string(Estilo.fuente(true), exterior.position + Vector2(84 * u, m.y * 0.5 + 5 * u), "Acuaris", HORIZONTAL_ALIGNMENT_LEFT, -1, roundi(13 * u), Estilo.TEXTO_SEC)
		"tablet":
			sb.bg_color = Color("#1b1f24")
			sb.border_color = Color("#3a4350")
			sb.set_border_width_all(roundi(2 * u))
			sb.set_corner_radius_all(roundi(30 * u))
			draw_style_box(sb, exterior)
			draw_circle(Vector2(exterior.get_center().x, exterior.position.y + m.y * 0.5), 3.5 * u, Color("#0b0d10"), true, -1, true)
		_:
			sb.bg_color = Color("#1b1f24")
			sb.border_color = Color("#3a4350")
			sb.set_border_width_all(roundi(3 * u))
			sb.set_corner_radius_all(roundi(40 * u))
			draw_style_box(sb, exterior)
			draw_circle(Vector2(exterior.get_center().x, exterior.position.y + m.y * 0.55), 4 * u, Color("#0b0d10"), true, -1, true)


# ------------------------------------------------------------------ selección y edición
func _a_dp(p: Vector2) -> Vector2:
	return p / zoom


func _tiradores(r: Rect2) -> Array[Vector2]:
	var c := r.get_center()
	return [r.position, Vector2(c.x, r.position.y), Vector2(r.end.x, r.position.y), Vector2(r.end.x, c.y),
		r.end, Vector2(c.x, r.end.y), Vector2(r.position.x, r.end.y), Vector2(r.position.x, c.y)]


func _tirador_en(p: Vector2) -> int:
	if modelo.seleccion == "":
		return -1
	var r := Rect2(modelo.rect_de(modelo.seleccion).position * zoom, modelo.rect_de(modelo.seleccion).size * zoom)
	var t := _tiradores(r)
	for i in t.size():
		if p.distance_to(t[i]) <= TIRADOR * u:
			return i
	return -1


func _entrada(e: InputEvent) -> void:
	if modelo == null or modo_prueba:
		return
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		if e.pressed:
			_capa.grab_focus()
			var t := _tirador_en(e.position)
			if t >= 0:
				_accion = "tirador_%d" % t
			else:
				var id := modelo.elemento_en(_a_dp(e.position))
				modelo.seleccionar(id)
				_accion = "mover" if id != "" else ""
			_inicio_raton = e.position
			_rect_inicial = modelo.rect_de(modelo.seleccion)
			_cambio_en_arrastre = false
		else:
			var habia := _accion != ""
			_accion = ""
			if habia and _cambio_en_arrastre:
				modelo.registrar()
			elif habia:
				reconstruir()
	elif e is InputEventMouseMotion:
		if _accion == "":
			var antes := _sobre
			_sobre = modelo.elemento_en(_a_dp(e.position))
			var t := _tirador_en(e.position)
			_capa.mouse_default_cursor_shape = _cursor_tirador(t) if t >= 0 else (Control.CURSOR_MOVE if _sobre != "" else Control.CURSOR_ARROW)
			if antes != _sobre:
				_capa.queue_redraw()
			return
		var d: Vector2 = (e.position - _inicio_raton) / zoom
		var r := _rect_inicial
		if _accion == "mover":
			r.position += d
		else:
			var n := _accion.substr(8).to_int()
			var izq := r.position.x
			var arr := r.position.y
			var der := r.end.x
			var aba := r.end.y
			if n in [0, 6, 7]:
				izq = minf(izq + d.x, der - 16.0)
			if n in [2, 3, 4]:
				der = maxf(der + d.x, izq + 16.0)
			if n in [0, 1, 2]:
				arr = minf(arr + d.y, aba - 16.0)
			if n in [4, 5, 6]:
				aba = maxf(aba + d.y, arr + 16.0)
			r = Rect2(izq, arr, der - izq, aba - arr)
		modelo.fijar_rect(modelo.seleccion, r, false)
		_cambio_en_arrastre = true
		var f := modelo.rect_de(modelo.seleccion)
		mensaje.emit("%s · x %d  y %d · %d × %d dp" % [modelo.seleccion, f.position.x, f.position.y, f.size.x, f.size.y])


func _cursor_tirador(n: int) -> int:
	match n:
		0, 4:
			return Control.CURSOR_FDIAGSIZE
		2, 6:
			return Control.CURSOR_BDIAGSIZE
		1, 5:
			return Control.CURSOR_VSIZE
		_:
			return Control.CURSOR_HSIZE


func _dibujar_capa() -> void:
	if modelo == null or modo_prueba:
		return
	if _sobre != "" and _sobre != modelo.seleccion:
		var rs := modelo.rect_de(_sobre)
		_capa.draw_rect(Rect2(rs.position * zoom, rs.size * zoom), Color(Estilo.AGUA, 0.55), false, maxf(1.0, u))
	if modelo.seleccion == "":
		return
	var rd := modelo.rect_de(modelo.seleccion)
	var r := Rect2(rd.position * zoom, rd.size * zoom)
	_capa.draw_rect(r, Color(Estilo.AMBAR, 0.07))
	_capa.draw_rect(r, Estilo.AMBAR, false, maxf(1.5, 2.0 * u))
	var lado := 8.0 * u
	for q in _tiradores(r):
		var c := Rect2(q - Vector2.ONE * lado * 0.5, Vector2.ONE * lado)
		_capa.draw_rect(c, Color.WHITE)
		_capa.draw_rect(c, Estilo.AMBAR, false, maxf(1.0, 1.5 * u))
	var txt := "%d × %d" % [rd.size.x, rd.size.y]
	var f := Estilo.fuente(true)
	var fs := roundi(11 * u)
	var ancho := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + 10 * u
	var y_et := r.position.y - 20 * u if r.position.y > 24 * u else r.end.y + 4 * u
	var et := Rect2(r.position.x, y_et, ancho, 16 * u)
	_capa.draw_rect(et, Estilo.AMBAR)
	_capa.draw_string(f, et.position + Vector2(5 * u, 12 * u), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Estilo.FONDO_ABAJO)


# ------------------------------------------------------------------ soltar desde la paleta
func _puede_soltar(_pos: Vector2, datos) -> bool:
	return not modo_prueba and datos is Dictionary and datos.get("acuaris_tipo", "") != ""


func _soltar(pos: Vector2, datos) -> void:
	var tipo: String = datos.acuaris_tipo
	var i := Esquema.info(tipo)
	var p := _a_dp(pos) - Vector2(float(i.w), float(i.h)) * 0.5
	modelo.anadir(tipo, maxf(0.0, p.x), maxf(0.0, p.y))
	mensaje.emit("Añadido: %s" % Esquema.info(tipo).nombre)
