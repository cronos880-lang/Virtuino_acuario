class_name Proyecto
extends RefCounted
## Carga y valida un proyecto Acuaris (*.acuaris.json). Las medidas se expresan en dp.

const FORMATO := "acuaris-proyecto"
const VERSION_FORMATO := 1

var datos: Dictionary = {}
var errores: Array[String] = []


static func desde_archivo(ruta: String) -> Proyecto:
	var p := Proyecto.new()
	var f := FileAccess.open(ruta, FileAccess.READ)
	if f == null:
		p.errores.append("No se puede abrir %s" % ruta)
		return p
	p.cargar_texto(f.get_as_text())
	return p


func cargar_texto(texto: String) -> bool:
	errores.clear()
	var json := JSON.new()
	if json.parse(texto) != OK:
		errores.append("JSON no válido (línea %d): %s" % [json.get_error_line(), json.get_error_message()])
		return false
	if not json.data is Dictionary:
		errores.append("El proyecto debe ser un objeto JSON")
		return false
	datos = json.data
	return validar()


func validar() -> bool:
	if datos.get("formato") != FORMATO:
		errores.append("Formato desconocido: %s" % datos.get("formato"))
	if int(datos.get("version", 0)) > VERSION_FORMATO:
		errores.append("Versión de formato %s más nueva que la soportada (%d)" % [datos.get("version"), VERSION_FORMATO])
	if not datos.get("paginas") is Array or datos.paginas.is_empty():
		errores.append("El proyecto no tiene páginas")
		return false
	var ids := {}
	for pag in datos.paginas:
		for w in pag.get("widgets", []):
			var id := str(w.get("id", ""))
			if id == "" or ids.has(id):
				errores.append("Identificador vacío o repetido: '%s'" % id)
			ids[id] = true
			if Esquema.info(str(w.get("tipo", ""))).is_empty():
				errores.append("Tipo de elemento desconocido '%s' en %s" % [w.get("tipo"), id])
			for k in ["x", "y", "w", "h"]:
				if not (w.get(k) is float or w.get(k) is int):
					errores.append("%s: falta la medida '%s'" % [id, k])
			for pin in pines_de(w):
				if ProtocoloVCM.separar_pin(pin).is_empty():
					errores.append("%s: pin no válido '%s'" % [id, pin])
	return errores.is_empty()


func nombre() -> String:
	return str(datos.get("nombre", "Sin nombre"))


func ancho_dp() -> float:
	return float(datos.get("lienzo_dp", [384, 832])[0])


func alto_dp() -> float:
	return float(datos.get("lienzo_dp", [384, 832])[1])


func paginas() -> Array:
	return datos.get("paginas", [])


func intervalo_ms() -> int:
	return int(datos.get("conexion", {}).get("intervalo_ms", 400))


## Pines que usa un elemento: "pin" y cualquier propiedad "pin_*".
static func pines_de(w: Dictionary) -> Array[String]:
	var r: Array[String] = []
	if w.has("pin") and str(w.pin) != "":
		r.append(str(w.pin))
	for k in w.get("props", {}):
		if str(k).begins_with("pin_") and str(w.props[k]) != "":
			r.append(str(w.props[k]))
	# Tabla de valores: los pines van dentro de "filas" (texto|pin|unidad|decimales; ...)
	if w.get("props", {}).has("filas"):
		for f in str(w.props.filas).split(";", false):
			var c := f.split("|")
			if c.size() >= 2 and c[1].strip_edges() != "":
				r.append(c[1].strip_edges().to_upper())
	return r


func todos_los_pines() -> Array[String]:
	var r: Array[String] = []
	for pag in paginas():
		for w in pag.get("widgets", []):
			for p in pines_de(w):
				if not r.has(p):
					r.append(p)
	return r
