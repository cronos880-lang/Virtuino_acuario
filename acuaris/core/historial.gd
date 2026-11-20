class_name Historial
extends RefCounted
## Historial de valores recibidos (para gráficas y tablas). Común a toda la app.
## Guarda como máximo una muestra cada INTERVALO_S por pin y MAX_MUESTRAS por pin.

const INTERVALO_S := 5.0
const MAX_MUESTRAS := 20000
const ARCHIVO := "user://historial.json"

static var _datos: Dictionary = {}   # pin -> {"t": PackedFloat64Array, "v": PackedFloat32Array}
static var reloj_externo := -1.0     # para pruebas


static func ahora() -> float:
	return reloj_externo if reloj_externo >= 0.0 else Time.get_unix_time_from_system()


static func anotar(pin: String, valor: float) -> void:
	var d: Dictionary = _datos.get(pin, {})
	if d.is_empty():
		d = {"t": PackedFloat64Array(), "v": PackedFloat32Array()}
		_datos[pin] = d
	var t := ahora()
	var ts: PackedFloat64Array = d.t
	if not ts.is_empty() and t - ts[ts.size() - 1] < INTERVALO_S:
		return
	ts.append(t)
	var vs: PackedFloat32Array = d.v
	vs.append(valor)
	if ts.size() > MAX_MUESTRAS:
		ts = ts.slice(ts.size() - MAX_MUESTRAS)
		vs = vs.slice(vs.size() - MAX_MUESTRAS)
	d.t = ts
	d.v = vs


## Muestras de los últimos `segundos`: [tiempos, valores]
static func serie(pin: String, segundos: float) -> Array:
	var d: Dictionary = _datos.get(pin, {})
	if d.is_empty():
		return [PackedFloat64Array(), PackedFloat32Array()]
	var desde := ahora() - segundos
	var ts: PackedFloat64Array = d.t
	var i := ts.bsearch(desde)
	return [ts.slice(i), (d.v as PackedFloat32Array).slice(i)]


static func borrar_todo() -> void:
	_datos.clear()


static func guardar() -> void:
	var salida := {}
	for p in _datos:
		salida[p] = {"t": Array(_datos[p].t), "v": Array(_datos[p].v)}
	var f := FileAccess.open(ARCHIVO, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(salida))


static func cargar() -> void:
	var f := FileAccess.open(ARCHIVO, FileAccess.READ)
	if f == null:
		return
	var d = JSON.parse_string(f.get_as_text())
	if not d is Dictionary:
		return
	for p in d:
		_datos[p] = {"t": PackedFloat64Array(d[p].get("t", [])), "v": PackedFloat32Array(d[p].get("v", []))}


## Texto CSV (fecha;valor) para exportar.
static func csv(pin: String, segundos: float) -> String:
	var s := serie(pin, segundos)
	var lineas := PackedStringArray(["fecha;%s" % pin])
	for i in s[0].size():
		lineas.append("%s;%s" % [Time.get_datetime_string_from_unix_time(int(s[0][i]), true), str(s[1][i]).replace(".", ",")])
	return "\n".join(lineas)
