class_name ElementoPaleta
extends Control
## Casilla de la paleta: muestra el elemento real en miniatura. Clic = añadir; arrastrar = colocar.

signal elegido(tipo: String)

const MUESTRAS := {
	"indicador": {"pin": "V1", "props": {"min": 0, "max": 100, "decimales": 0}, "v": 64.0, "w": 84, "h": 84},
	"valor": {"pin": "V1", "props": {"decimales": 1, "tam": 18, "titulo": ""}, "v": 24.5, "w": 110, "h": 44},
	"led": {"pin": "V1", "props": {"texto": "", "texto_on": "", "color_on": "#3ddc84"}, "v": 1.0, "w": 60, "h": 40},
	"interruptor": {"pin": "V1", "props": {"texto": ""}, "v": 1.0, "w": 70, "h": 36},
	"pulsador": {"pin": "V1", "props": {"texto": "OK"}, "v": 0.0, "w": 100, "h": 40},
	"barra": {"pin": "V1", "props": {"min": 0, "max": 100, "mostrar": "porcentaje", "titulo": ""}, "v": 63.0, "w": 110, "h": 46},
	"deslizador": {"pin": "V1", "props": {"min": 0, "max": 100, "titulo": ""}, "v": 40.0, "w": 110, "h": 50},
	"reloj": {"pin": "", "props": {"pin_h": "V2", "pin_m": "V3", "tam": 20, "con_fondo": false, "titulo": ""}, "v": 0.0, "w": 110, "h": 40},
	"etiqueta": {"pin": "", "props": {"texto": "Aa", "tam": 24, "alineacion": "centro", "negrita": true}, "v": 0.0, "w": 110, "h": 40},
	"panel": {"pin": "", "props": {"titulo": ""}, "v": 0.0, "w": 100, "h": 56},
}

var tipo := ""
var u := 1.0
var _sobre := false


func preparar(t: String, escala: float) -> ElementoPaleta:
	tipo = t
	u = escala
	custom_minimum_size = Vector2(132, 108) * u
	tooltip_text = "%s · clic para añadir o arrastra al dispositivo" % Esquema.info(tipo).nombre
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	mouse_entered.connect(func(): _sobre = true; queue_redraw())
	mouse_exited.connect(func(): _sobre = false; queue_redraw())
	var m: Dictionary = MUESTRAS[tipo]
	var d := {"id": "paleta_" + tipo, "tipo": tipo, "x": 0, "y": 0, "w": m.w, "h": m.h, "props": m.props}
	if m.pin != "":
		d["pin"] = m.pin
	var w := FabricaWidgets.crear(d, u)
	w.mouse_filter = Control.MOUSE_FILTER_IGNORE
	w.position = Vector2((132 - m.w) * 0.5, 8 + (74 - m.h) * 0.5) * u
	add_child(w)
	for p in Proyecto.pines_de(d):
		w.recibir(AcWidget.normalizar(p), m.v if p == m.pin else (16.0 if p == "V2" else 20.0))
	return self


func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and not e.pressed:
		if Rect2(Vector2.ZERO, size).has_point(e.position):
			elegido.emit(tipo)


func _get_drag_data(_pos: Vector2) -> Variant:
	var vista := Label.new()
	vista.text = "  + " + Esquema.info(tipo).nombre
	vista.add_theme_font_size_override("font_size", roundi(15 * u))
	vista.add_theme_color_override("font_color", Estilo.AMBAR)
	set_drag_preview(vista)
	return {"acuaris_tipo": tipo}


func _draw() -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("#123247") if _sobre else Color("#0d2738")
	sb.border_color = Estilo.AGUA if _sobre else Color("#1d3b50")
	sb.set_border_width_all(maxi(1, roundi(u)))
	sb.set_corner_radius_all(roundi(10 * u))
	draw_style_box(sb, Rect2(Vector2.ZERO, size))
	draw_string(Estilo.fuente(false), Vector2(0, size.y - 12 * u), Esquema.info(tipo).nombre, HORIZONTAL_ALIGNMENT_CENTER, size.x, roundi(13 * u), Estilo.TEXTO_SEC)
