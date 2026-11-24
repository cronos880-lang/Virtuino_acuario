class_name Pictos
extends RefCounted
## Dibujos vectoriales (nítidos a cualquier tamaño) para indicadores e iconos de botones.
## Se dibujan en un cuadrado de coordenadas 0..1 que se ajusta al rectángulo pedido.
## "on" = encendido/activo; "fase" (0..1) anima los que giran o se mueven.

const LISTA := ["bombilla", "ventilador", "bomba", "calentador", "valvula", "motor", "deposito", "termometro",
	"gota", "campana", "enchufe", "candado", "compresor", "power", "play", "stop", "reset", "flecha_arriba", "flecha_abajo"]
const NOMBRES := {"bombilla": "Bombilla", "ventilador": "Ventilador", "bomba": "Bomba de agua", "calentador": "Calentador",
	"valvula": "Válvula", "motor": "Motor", "deposito": "Depósito con nivel", "termometro": "Termómetro", "gota": "Gota",
	"campana": "Campana de alarma", "enchufe": "Enchufe", "candado": "Candado", "compresor": "Compresor",
	"power": "Encendido", "play": "Marcha", "stop": "Paro", "reset": "Reinicio", "flecha_arriba": "Flecha arriba",
	"flecha_abajo": "Flecha abajo"}

static var _ci: CanvasItem
static var _o := Vector2.ZERO
static var _k := 1.0


static func _p(x: float, y: float) -> Vector2:
	return _o + Vector2(x, y) * _k


static func _w(v: float) -> float:
	return maxf(v * _k, 1.0)


static func _linea(a: Vector2, b: Vector2, c: Color, g := 0.06) -> void:
	_ci.draw_line(_p(a.x, a.y), _p(b.x, b.y), c, _w(g), true)


static func _circ(cx: float, cy: float, r: float, c: Color, relleno := true, g := 0.06) -> void:
	_ci.draw_circle(_p(cx, cy), r * _k, c, relleno, -1.0 if relleno else _w(g), true)


static func _arco(cx: float, cy: float, r: float, a0: float, a1: float, c: Color, g := 0.06) -> void:
	_ci.draw_arc(_p(cx, cy), r * _k, a0, a1, 32, c, _w(g), true)


static func _rect(x: float, y: float, w: float, h: float, c: Color, relleno := true, g := 0.06) -> void:
	_ci.draw_rect(Rect2(_p(x, y), Vector2(w, h) * _k), c, relleno, -1.0 if relleno else _w(g))


static func _poli(pts: Array, c: Color) -> void:
	var v := PackedVector2Array()
	for q in pts:
		v.append(_p(q.x, q.y))
	_ci.draw_colored_polygon(v, c)


static func _brillo(cx: float, cy: float, r: float, c: Color) -> void:
	_circ(cx, cy, r * 1.5, Color(c, 0.10))
	_circ(cx, cy, r * 1.2, Color(c, 0.18))


## Dibuja el pictograma `nombre` dentro de `r`. `c` = color activo; `apagado` = color inactivo.
static func dibujar(ci: CanvasItem, nombre: String, r: Rect2, c: Color, on: bool, fase := 0.0, apagado := Color("#4a6a80")) -> void:
	_ci = ci
	_k = minf(r.size.x, r.size.y)
	_o = r.position + (r.size - Vector2(_k, _k)) * 0.5
	var col := c if on else apagado
	var trazo := Color("#dbe9f2") if on else Color("#7d9bb0")
	match nombre:
		"bombilla":
			if on:
				_brillo(0.5, 0.4, 0.3, c)
			_circ(0.5, 0.4, 0.26, col)
			_poli([Vector2(0.36, 0.58), Vector2(0.64, 0.58), Vector2(0.6, 0.72), Vector2(0.4, 0.72)], col)
			_rect(0.39, 0.74, 0.22, 0.05, trazo)
			_rect(0.41, 0.81, 0.18, 0.05, trazo)
			_arco(0.5, 0.4, 0.13, PI * 1.1, PI * 1.6, Color(1, 1, 1, 0.55 if on else 0.15), 0.04)
		"ventilador":
			_circ(0.5, 0.5, 0.44, Color(col, 0.18))
			_circ(0.5, 0.5, 0.44, col, false, 0.04)
			var giro := fase * TAU if on else 0.3
			for i in 3:
				var a := giro + i * TAU / 3.0
				var d := Vector2(cos(a), sin(a))
				var n := Vector2(-d.y, d.x)
				_poli([Vector2(0.5, 0.5) + n * 0.05, Vector2(0.5, 0.5) + d * 0.38 + n * 0.12, Vector2(0.5, 0.5) + d * 0.4 - n * 0.02], col)
			_circ(0.5, 0.5, 0.07, trazo)
		"bomba":
			_rect(0.06, 0.62, 0.24, 0.12, col)
			_rect(0.5, 0.14, 0.12, 0.22, col)
			_circ(0.5, 0.56, 0.3, Color(col, 0.25))
			_circ(0.5, 0.56, 0.3, col, false, 0.06)
			var g2 := fase * TAU if on else 0.0
			for i in 4:
				var a := g2 + i * TAU / 4.0
				_linea(Vector2(0.5, 0.56), Vector2(0.5, 0.56) + Vector2(cos(a), sin(a)) * 0.22, trazo, 0.05)
			_rect(0.18, 0.86, 0.64, 0.06, trazo)
		"calentador":
			if on:
				_brillo(0.5, 0.5, 0.36, c)
			_rect(0.4, 0.06, 0.2, 0.12, trazo)
			_rect(0.36, 0.18, 0.28, 0.72, Color(col, 0.35))
			_rect(0.36, 0.18, 0.28, 0.72, col, false, 0.05)
			for i in 4:
				var y := 0.28 + i * 0.15
				_arco(0.5, y + 0.04, 0.08, PI * 1.0, PI * 2.0, trazo if on else col, 0.04)
		"valvula":
			_poli([Vector2(0.1, 0.35), Vector2(0.5, 0.6), Vector2(0.1, 0.85)], col)
			_poli([Vector2(0.9, 0.35), Vector2(0.5, 0.6), Vector2(0.9, 0.85)], col)
			_linea(Vector2(0.5, 0.6), Vector2(0.5, 0.25), trazo, 0.06)
			_rect(0.3, 0.12, 0.4, 0.13, col if on else trazo)
		"motor":
			_rect(0.14, 0.26, 0.6, 0.48, Color(col, 0.3))
			_rect(0.14, 0.26, 0.6, 0.48, col, false, 0.05)
			for i in 4:
				_linea(Vector2(0.24 + i * 0.13, 0.3), Vector2(0.24 + i * 0.13, 0.7), Color(col, 0.6), 0.03)
			_rect(0.74, 0.44, 0.16, 0.12, trazo)
			_rect(0.2, 0.74, 0.12, 0.1, trazo)
			_rect(0.56, 0.74, 0.12, 0.1, trazo)
			if on:
				_circ(0.82, 0.3, 0.06, c)
		"deposito":
			var nivel := clampf(fase, 0.0, 1.0)
			_rect(0.2, 0.12 + 0.76 * (1.0 - nivel), 0.6, 0.76 * nivel, Color(c, 0.75))
			_rect(0.2, 0.12, 0.6, 0.76, trazo, false, 0.05)
			for i in 3:
				_linea(Vector2(0.2, 0.31 + i * 0.19), Vector2(0.28, 0.31 + i * 0.19), trazo, 0.03)
		"termometro":
			var t := clampf(fase, 0.0, 1.0)
			_rect(0.42, 0.08, 0.16, 0.66, trazo, false, 0.04)
			_rect(0.45, 0.08 + 0.62 * (1.0 - t), 0.1, 0.62 * t + 0.06, c)
			_circ(0.5, 0.8, 0.13, c)
			_circ(0.5, 0.8, 0.13, trazo, false, 0.04)
			for i in 4:
				_linea(Vector2(0.6, 0.16 + i * 0.14), Vector2(0.68, 0.16 + i * 0.14), trazo, 0.03)
		"gota":
			_poli([Vector2(0.5, 0.08), Vector2(0.74, 0.5), Vector2(0.26, 0.5)], col)
			_circ(0.5, 0.6, 0.25, col)
			_arco(0.5, 0.6, 0.15, PI * 0.55, PI * 0.95, Color(1, 1, 1, 0.5 if on else 0.15), 0.04)
		"campana":
			var mov := sin(fase * TAU * 2.0) * 0.04 if on else 0.0
			if on:
				_brillo(0.5, 0.5, 0.34, c)
			_poli([Vector2(0.5 + mov, 0.14), Vector2(0.74 + mov, 0.36), Vector2(0.8 + mov, 0.72), Vector2(0.2 + mov, 0.72), Vector2(0.26 + mov, 0.36)], col)
			_circ(0.5 + mov, 0.2, 0.09, col)
			_rect(0.14 + mov, 0.72, 0.72, 0.06, col)
			_circ(0.5 - mov, 0.84, 0.07, trazo)
		"enchufe":
			_circ(0.5, 0.5, 0.38, Color(col, 0.25))
			_circ(0.5, 0.5, 0.38, col, false, 0.05)
			_circ(0.37, 0.5, 0.06, trazo)
			_circ(0.63, 0.5, 0.06, trazo)
		"candado":
			if on:   # cerrado
				_arco(0.5, 0.42, 0.18, PI, TAU, col, 0.08)
			else:    # abierto
				_arco(0.5, 0.36, 0.18, PI * 1.25, TAU, col, 0.08)
			_rect(0.26, 0.42, 0.48, 0.42, col)
			_circ(0.5, 0.6, 0.06, Color("#06131d"))
		"compresor":
			_rect(0.1, 0.42, 0.62, 0.36, Color(col, 0.3))
			_rect(0.1, 0.42, 0.62, 0.36, col, false, 0.05)
			_circ(0.72, 0.4, 0.18, col, false, 0.05)
			var g3 := fase * TAU if on else 0.0
			_linea(Vector2(0.72, 0.4), Vector2(0.72, 0.4) + Vector2(cos(g3), sin(g3)) * 0.14, trazo, 0.05)
			_rect(0.16, 0.8, 0.1, 0.08, trazo)
			_rect(0.56, 0.8, 0.1, 0.08, trazo)
			_circ(0.3, 0.32, 0.08, trazo, false, 0.04)
		"power":
			_arco(0.5, 0.54, 0.3, -PI * 0.3, PI * 1.3, col, 0.09)
			_linea(Vector2(0.5, 0.14), Vector2(0.5, 0.5), col, 0.09)
		"play":
			_poli([Vector2(0.3, 0.18), Vector2(0.82, 0.5), Vector2(0.3, 0.82)], col)
		"stop":
			_rect(0.24, 0.24, 0.52, 0.52, col)
		"reset":
			_arco(0.5, 0.52, 0.3, -PI * 0.15, PI * 1.45, col, 0.09)
			_poli([Vector2(0.64, 0.1), Vector2(0.86, 0.36), Vector2(0.56, 0.38)], col)
		"flecha_arriba":
			_poli([Vector2(0.5, 0.14), Vector2(0.86, 0.56), Vector2(0.14, 0.56)], col)
			_rect(0.38, 0.54, 0.24, 0.32, col)
		"flecha_abajo":
			_poli([Vector2(0.5, 0.86), Vector2(0.86, 0.44), Vector2(0.14, 0.44)], col)
			_rect(0.38, 0.14, 0.24, 0.32, col)
