class_name ElementoPaleta
extends Control
## Casilla de la paleta: muestra el elemento real en miniatura. Clic = añadir; arrastrar = colocar.

signal elegido(tipo: String)

## Ajustes de muestra para que la miniatura se entienda (props y valor de ejemplo).
const MUESTRAS := {
	"indicador": {"props": {"min": 0, "max": 100, "decimales": 0, "titulo": "", "unidad": ""}, "v": 64.0},
	"manometro": {"props": {"titulo": "", "unidad": ""}, "v": 6.5},
	"valor": {"props": {"titulo": "", "tam": 18}, "v": 24.5},
	"valor_editable": {"props": {"titulo": "", "tam": 18}, "v": 25.0},
	"led": {"props": {"texto": "", "texto_on": "", "texto_off": ""}, "v": 1.0},
	"estado": {"props": {"titulo": "", "tam": 14}, "v": 1.0},
	"interruptor": {"props": {"texto": ""}, "v": 1.0},
	"interruptor_seguro": {"props": {"texto": ""}, "v": 1.0},
	"pulsador": {"props": {"texto": "OK"}, "v": 0.0},
	"pulsador_seguro": {"props": {"texto": "PIN"}, "v": 0.0},
	"casilla": {"props": {"texto": "Sí"}, "v": 1.0},
	"barra": {"props": {"titulo": "", "mostrar": "porcentaje"}, "v": 63.0},
	"barra_escala": {"props": {"titulo": "", "mostrar": "porcentaje"}, "v": 40.0},
	"barra_vertical": {"props": {"titulo": ""}, "v": 26.0},
	"giratorio": {"props": {"titulo": ""}, "v": 1.0},
	"segmentos": {"props": {"titulo": ""}, "v": 70.0},
	"deslizador": {"props": {"titulo": ""}, "v": 40.0},
	"deslizador_v": {"props": {"titulo": ""}, "v": 60.0},
	"potenciometro": {"props": {"titulo": ""}, "v": 160.0},
	"selector": {"props": {"titulo": ""}, "v": 2.0},
	"opciones": {"props": {}, "v": 1.0},
	"grupo_botones": {"props": {}, "v": 1.0},
	"reloj": {"props": {"tam": 20, "con_fondo": false, "titulo": "", "pin_s": ""}, "v": 0.0},
	"etiqueta": {"props": {"texto": "Aa", "tam": 24, "alineacion": "centro", "negrita": true}, "v": 0.0},
	"panel": {"props": {"titulo": ""}, "v": 0.0},
	"deposito": {"props": {}, "v": 65.0},
	"valvula_2v": {"props": {}, "v": 1.0},
	"valvula_3v": {"props": {}, "v": 1.0},
	"bomba_h": {"props": {}, "v": 1.0},
	"tuberia_h": {"props": {}, "v": 1.0},
	"tuberia_v": {"props": {}, "v": 1.0},
	"codo": {"props": {}, "v": 1.0},
	"te": {"props": {}, "v": 1.0},
	"cruz": {"props": {}, "v": 1.0},
	"caudalimetro": {"props": {}, "v": 0.6},
	"manometro_peq": {"props": {}, "v": 4.0},
	"chorro": {"props": {}, "v": 1.0},
	"agitador": {"props": {}, "v": 1.0},
	"motor": {"props": {}, "v": 1.0},
	"solenoide": {"props": {}, "v": 1.0},
	"volante": {"props": {}, "v": 1.0},
	"maneta": {"props": {}, "v": 1.0},
}

const ANCHO := 132.0
const ALTO := 104.0

var tipo := ""
var u := 1.0
var _sobre := false


func preparar(t: String, escala: float) -> ElementoPaleta:
	tipo = t
	u = escala
	custom_minimum_size = Vector2(ANCHO, ALTO) * u
	tooltip_text = "%s · clic para añadir o arrastra al dispositivo" % Esquema.info(tipo).nombre
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	mouse_entered.connect(func(): _sobre = true; queue_redraw())
	mouse_exited.connect(func(): _sobre = false; queue_redraw())
	var d := Esquema.crear(tipo, "paleta_" + tipo, 0, 0)
	var m: Dictionary = MUESTRAS.get(tipo, {})
	for k in m.get("props", {}):
		d.props[k] = m.props[k]
	# Escala para que quepa en la casilla (máx. 116 x 70 dp de muestra)
	var w := float(d.w)
	var h := float(d.h)
	var k := minf(1.0, minf(116.0 / w, 70.0 / h))
	var esc := u * k
	var wd := FabricaWidgets.crear(d, esc)
	if wd == null:
		return self
	wd.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wd.set_process(wd.is_processing())
	wd.position = Vector2((ANCHO * u - w * esc) * 0.5, 6 * u + (74 * u - h * esc) * 0.5)
	add_child(wd)
	var v := float(m.get("v", 1.0))
	for p in Proyecto.pines_de(d):
		var pn := AcWidget.normalizar(p)
		var valor := v
		if pn == "V2":
			valor = 16.0
		elif pn == "V3":
			valor = 20.0
		wd.recibir(pn, valor)
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
	draw_string(Estilo.fuente(false), Vector2(4 * u, size.y - 9 * u), Esquema.info(tipo).nombre, HORIZONTAL_ALIGNMENT_CENTER, size.x - 8 * u, roundi(12 * u), Estilo.TEXTO_SEC)
