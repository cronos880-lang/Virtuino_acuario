class_name AcWidget
extends Control
## Base de todos los elementos de interfaz. La definición viene del proyecto (medidas en dp).
## Todo se dibuja con primitivas vectoriales a la resolución real de la pantalla:
##   px = dp * s   (s = píxeles por dp del dispositivo o zoom del diseñador)
## Las fuentes se rasterizan al tamaño final en píxeles, sin escalar imágenes: máxima nitidez.

signal escritura_solicitada(pin: String, valor: float)

var def: Dictionary = {}
var s := 1.0
var valores: Dictionary = {}
var interactivo := false

var _pulsado := false
var _pos_pulsacion := Vector2.ZERO


func configurar(definicion: Dictionary, escala: float) -> void:
	def = definicion
	s = escala
	position = Vector2(float(def.get("x", 0)), float(def.get("y", 0))) * s
	size = Vector2(float(def.get("w", 10)), float(def.get("h", 10))) * s
	mouse_filter = Control.MOUSE_FILTER_PASS if interactivo else Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func prop(clave: String, defecto = null):
	return def.get("props", {}).get(clave, defecto)


static func normalizar(pin: String) -> String:
	var sp := ProtocoloVCM.separar_pin(pin)
	return "" if sp.is_empty() else ProtocoloVCM.nombre_pin(sp.tipo, sp.pin)


func pin_de(clave := "pin") -> String:
	var p = def.get("pin", "") if clave == "pin" else prop(clave, "")
	return normalizar(str(p))


func tiene_valor(clave := "pin") -> bool:
	return valores.has(pin_de(clave))


func valor(clave := "pin", defecto := 0.0) -> float:
	return valores.get(pin_de(clave), defecto)


func recibir(pin: String, v: float) -> void:
	for p in Proyecto.pines_de(def):
		if normalizar(p) == pin:
			valores[pin] = v
			queue_redraw()
			return


func solicitar(v: float, clave := "pin") -> void:
	var p := pin_de(clave)
	if p != "":
		escritura_solicitada.emit(p, v)


# ------------------------------------------------------------------ ayudas de dibujo
func px(dp: float) -> float:
	return dp * s


func tam_fuente(dp: float) -> int:
	return maxi(1, roundi(dp * s))


func caja(r: Rect2, fondo: Color, borde: Color = Color.TRANSPARENT, radio_dp := 14.0, ancho_borde_dp := 1.0) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fondo
	sb.set_corner_radius_all(roundi(px(radio_dp)))
	sb.corner_detail = 16
	sb.anti_aliasing = true
	if borde.a > 0.0:
		sb.border_color = borde
		sb.set_border_width_all(maxi(1, roundi(px(ancho_borde_dp))))
	draw_style_box(sb, r)


## Texto dentro de un rectángulo. alineacion: "izquierda" | "centro" | "derecha".
func texto(t: String, r: Rect2, tam_dp: float, color: Color, alineacion := "centro", negrita := false) -> void:
	var f := Estilo.fuente(negrita)
	var fs := tam_fuente(tam_dp)
	var lineas := t.split("\n")
	var alto_linea := f.get_height(fs)
	var total := alto_linea * lineas.size()
	var y := r.position.y + (r.size.y - total) * 0.5 + f.get_ascent(fs)
	var alin := HORIZONTAL_ALIGNMENT_CENTER
	if alineacion == "izquierda":
		alin = HORIZONTAL_ALIGNMENT_LEFT
	elif alineacion == "derecha":
		alin = HORIZONTAL_ALIGNMENT_RIGHT
	for linea in lineas:
		draw_string(f, Vector2(r.position.x, roundf(y)), linea, alin, r.size.x, fs, color)
		y += alto_linea


func ancho_texto(t: String, tam_dp: float, negrita := false) -> float:
	return Estilo.fuente(negrita).get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, tam_fuente(tam_dp)).x


func formatear(v: float, decimales: int) -> String:
	if decimales <= 0:
		return str(roundi(v))
	return ("%." + str(decimales) + "f") % v


# ------------------------------------------------------------------ pulsaciones
## Toque corto (no arrastre) sobre el elemento. Los elementos interactivos lo redefinen.
func al_tocar() -> void:
	pass


func al_presionar(_presionado: bool) -> void:
	pass


func _gui_input(evento: InputEvent) -> void:
	if not interactivo:
		return
	if evento is InputEventMouseButton and evento.button_index == MOUSE_BUTTON_LEFT:
		if evento.pressed:
			_pulsado = true
			_pos_pulsacion = evento.position
			al_presionar(true)
			queue_redraw()
		elif _pulsado:
			_pulsado = false
			al_presionar(false)
			if evento.position.distance_to(_pos_pulsacion) < px(12) and Rect2(Vector2.ZERO, size).has_point(evento.position):
				al_tocar()
			queue_redraw()
	elif evento is InputEventMouseMotion and _pulsado:
		if evento.position.distance_to(_pos_pulsacion) > px(12):
			_pulsado = false
			al_presionar(false)
			queue_redraw()
