extends Control
## MAQUETA del diseñador de PC (fase 1). No es funcional todavía: muestra la distribución prevista
## usando los componentes reales (la página del móvil se dibuja con el mismo código que la app).
##   godot --path acuaris res://ui/disenador_maqueta.tscn -- --captura=salida.png

const PROYECTO := "res://proyectos/acuario.acuaris.json"
const SELECCION := "temp"

var proyecto: Proyecto
var perfil: Dictionary
var s := 1.0
var marco := Rect2()
var pantalla := Rect2()
var paleta: Array[Dictionary] = []


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	proyecto = Proyecto.desde_archivo(PROYECTO)
	perfil = Perfiles.buscar(proyecto.datos.get("perfil", ""))
	_construir()
	var args := OS.get_cmdline_user_args()
	for a in args:
		if a.begins_with("--captura="):
			for i in 4:
				await get_tree().process_frame
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(a.substr(10))
			print("Captura guardada: ", a.substr(10))
			get_tree().quit()


func _construir() -> void:
	var tam := get_viewport_rect().size
	var u := tam.y / 1080.0  # unidad de interfaz del propio diseñador
	# Pantalla del móvil: cabe en el alto disponible
	var alto_disp := tam.y - 150 * u
	s = alto_disp / proyecto.alto_dp()
	var ancho_pant := proyecto.ancho_dp() * s
	pantalla = Rect2((tam.x - ancho_pant) * 0.5, 110 * u, ancho_pant, alto_disp)
	marco = pantalla.grow(14 * u)
	# Contenido real de la app dentro del marco
	var fondo := FondoDegradado.new()
	fondo.position = pantalla.position
	fondo.size = pantalla.size
	add_child(fondo)
	var barra := BarraSuperior.new()
	barra.s = s
	barra.subtitulo = "Proyecto: " + proyecto.nombre()
	barra.estado_txt = "Simulador"
	barra.estado_color = Estilo.VERDE
	barra.position = pantalla.position
	barra.size = Vector2(ancho_pant, 60 * s)
	add_child(barra)
	var vista := VistaPagina.new()
	vista.position = pantalla.position + Vector2(0, 60 * s)
	add_child(vista)
	vista.construir(proyecto.paginas()[0], s, proyecto.ancho_dp(), proyecto.alto_dp())
	var sim := SimuladorArduino.new()
	sim.fijar_hora(16, 20)
	for i in 260:
		sim.avanzar(1.0)
	for p in proyecto.todos_los_pines():
		var sp := ProtocoloVCM.separar_pin(p)
		vista.recibir(ProtocoloVCM.nombre_pin(sp.tipo, sp.pin), sim.V[sp.pin])
	# Selección del elemento activo (encima de la página)
	for w in proyecto.paginas()[0].widgets:
		if w.id == SELECCION:
			var capa := Control.new()
			capa.mouse_filter = Control.MOUSE_FILTER_IGNORE
			capa.position = vista.position + Vector2(w.x, w.y) * s
			capa.size = Vector2(w.w, w.h) * s
			capa.draw.connect(func():
				var r := Rect2(Vector2.ZERO, capa.size)
				capa.draw_rect(r, Color(Estilo.AMBAR, 0.08))
				capa.draw_rect(r, Estilo.AMBAR, false, maxf(1.0, 2.0 * s / 2.8))
				for q in [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]:
					capa.draw_rect(Rect2(q - Vector2(5, 5), Vector2(10, 10)), Color.WHITE)
					capa.draw_rect(Rect2(q - Vector2(5, 5), Vector2(10, 10)), Estilo.AMBAR, false, 2.0))
			add_child(capa)
	# Miniaturas de la paleta: elementos reales a escala reducida
	paleta = [
		{"tipo": "indicador", "nombre": "Indicador", "pin": "V35", "props": {"min": 0, "max": 100, "decimales": 0, "tam": 15}, "v": 64.0},
		{"tipo": "led", "nombre": "LED", "pin": "V8", "props": {"texto": "", "texto_on": "", "color_on": "#3ddc84"}, "v": 1.0},
		{"tipo": "interruptor", "nombre": "Interruptor", "pin": "V15", "props": {"texto": ""}, "v": 1.0},
		{"tipo": "pulsador", "nombre": "Pulsador", "pin": "V20", "props": {"texto": "OK", "modo": "conmutado"}, "v": 0.0},
		{"tipo": "valor", "nombre": "Valor", "pin": "V5", "props": {"decimales": 1, "tam": 18}, "v": 24.5},
		{"tipo": "barra", "nombre": "Barra", "pin": "V10", "props": {"min": 0, "max": 255, "mostrar": "porcentaje"}, "v": 160.0},
		{"tipo": "deslizador", "nombre": "Deslizador", "pin": "V28", "props": {"min": 0, "max": 255}, "v": 90.0},
		{"tipo": "reloj", "nombre": "Reloj", "pin": "", "props": {"pin_h": "V2", "pin_m": "V3", "tam": 18, "con_fondo": false}, "v": 0.0},
		{"tipo": "etiqueta", "nombre": "Texto", "pin": "", "props": {"texto": "Aa", "tam": 22, "alineacion": "centro", "negrita": true}, "v": 0.0},
		{"tipo": "panel", "nombre": "Panel", "pin": "", "props": {"titulo": ""}, "v": 0.0},
	]
	var x0 := 24 * u
	var y := 150 * u
	for i in paleta.size():
		var e := paleta[i]
		var col := i % 2
		var fila := i / 2
		var celda := Rect2(x0 + col * 156 * u, y + fila * 128 * u, 146 * u, 118 * u)
		e["celda"] = celda
		var d := {"id": "pal_%d" % i, "tipo": e.tipo, "x": 0, "y": 0, "w": 120, "h": 70, "props": e.props}
		if e.pin != "":
			d["pin"] = e.pin
		var esc := u
		if e.tipo == "indicador":
			d.w = 76; d.h = 76
		var w := FabricaWidgets.crear(d, esc)
		w.position = celda.position + Vector2((celda.size.x - d.w * esc) * 0.5, 10 * u + (78 * u - d.h * esc) * 0.5)
		add_child(w)
		for p in Proyecto.pines_de(d):
			var sp := ProtocoloVCM.separar_pin(p)
			w.recibir(ProtocoloVCM.nombre_pin(sp.tipo, sp.pin), e.v if p == e.pin else (16.0 if p == "V2" else 20.0))
	queue_redraw()


func _draw() -> void:
	var tam := get_viewport_rect().size
	var u := tam.y / 1080.0
	var fb := Estilo.fuente(true)
	var fn := Estilo.fuente(false)
	draw_rect(Rect2(Vector2.ZERO, tam), Color("#0a1620"))
	# Barra superior del diseñador
	draw_rect(Rect2(0, 0, tam.x, 64 * u), Color("#0f2433"))
	draw_string(fb, Vector2(24 * u, 42 * u), "Acuaris · Diseñador", HORIZONTAL_ALIGNMENT_LEFT, -1, roundi(22 * u), Estilo.TEXTO)
	var px: Array = perfil.get("pantalla_px", [1080, 2340])
	var info := "%s   ·   %d × %d dp   ·   %d × %d px   ·   densidad %.2f (estimada)" % [perfil.get("nombre", "?"), proyecto.ancho_dp(), proyecto.alto_dp(), px[0], px[1], perfil.get("densidad", 0.0)]
	_pastilla(Vector2(330 * u, 16 * u), info, u, Estilo.AGUA)
	_pastilla(Vector2(tam.x - 420 * u, 16 * u), "Zoom: ajustar a ventana", u, Estilo.LUZ)
	_pastilla(Vector2(tam.x - 210 * u, 16 * u), "▶ Probar (simulador)", u, Estilo.VERDE)
	# Paneles laterales
	_tarjeta(Rect2(12 * u, 80 * u, 336 * u, tam.y - 92 * u), u)
	draw_string(fb, Vector2(28 * u, 120 * u), "Elementos", HORIZONTAL_ALIGNMENT_LEFT, -1, roundi(18 * u), Estilo.TEXTO)
	for e in paleta:
		var c: Rect2 = e.celda
		_tarjeta(c, u, Color("#0d2738"))
		draw_string(fn, Vector2(c.position.x, c.end.y - 12 * u), e.nombre, HORIZONTAL_ALIGNMENT_CENTER, c.size.x, roundi(13 * u), Estilo.TEXTO_SEC)
	var der := Rect2(tam.x - 348 * u, 80 * u, 336 * u, tam.y - 92 * u)
	_tarjeta(der, u)
	draw_string(fb, der.position + Vector2(16 * u, 40 * u), "Propiedades", HORIZONTAL_ALIGNMENT_LEFT, -1, roundi(18 * u), Estilo.TEXTO)
	var sel: Dictionary = {}
	for w in proyecto.paginas()[0].widgets:
		if w.id == SELECCION:
			sel = w
	var filas := [["Identificador", sel.id], ["Tipo", sel.tipo], ["Pin", sel.pin], ["Posición (dp)", "%d, %d" % [sel.x, sel.y]], ["Tamaño (dp)", "%d × %d" % [sel.w, sel.h]]]
	for k in sel.props:
		filas.append([str(k), str(sel.props[k])])
	var y := der.position.y + 72 * u
	for f in filas:
		draw_string(fn, Vector2(der.position.x + 16 * u, y), f[0], HORIZONTAL_ALIGNMENT_LEFT, 130 * u, roundi(13 * u), Estilo.TEXTO_SEC)
		var campo := Rect2(der.position.x + 150 * u, y - 20 * u, 170 * u, 28 * u)
		_tarjeta(campo, u, Color("#0a1c28"), 6)
		draw_string(fn, campo.position + Vector2(8 * u, 19 * u), f[1], HORIZONTAL_ALIGNMENT_LEFT, campo.size.x - 12 * u, roundi(13 * u), Estilo.TEXTO)
		y += 38 * u
	draw_string(fn, Vector2(der.position.x + 16 * u, der.end.y - 24 * u), "Maqueta de la fase 1 (no funcional)", HORIZONTAL_ALIGNMENT_LEFT, -1, roundi(12 * u), Estilo.AMBAR)
	# Marco del teléfono
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("#1b1f24")
	sb.border_color = Color("#3a4350")
	sb.set_border_width_all(roundi(3 * u))
	sb.set_corner_radius_all(roundi(42 * u))
	sb.corner_detail = 24
	draw_style_box(sb, marco)
	draw_circle(Vector2(marco.get_center().x, pantalla.position.y - 6 * u), 4 * u, Color("#0b0d10"), true, -1, true)


func _tarjeta(r: Rect2, u: float, fondo := Color("#0f2433"), radio := 12.0) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fondo
	sb.border_color = Color("#1d3b50")
	sb.set_border_width_all(maxi(1, roundi(u)))
	sb.set_corner_radius_all(roundi(radio * u))
	draw_style_box(sb, r)


func _pastilla(pos: Vector2, t: String, u: float, c: Color) -> void:
	var fb := Estilo.fuente(true)
	var fs := roundi(13 * u)
	var w := fb.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + 28 * u
	var r := Rect2(pos, Vector2(w, 32 * u))
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(c, 0.12)
	sb.border_color = Color(c, 0.5)
	sb.set_border_width_all(maxi(1, roundi(u)))
	sb.set_corner_radius_all(roundi(16 * u))
	draw_style_box(sb, r)
	draw_string(fb, pos + Vector2(14 * u, 21 * u), t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Estilo.TEXTO)
