class_name ModeloEditor
extends RefCounted
## Proyecto en edición: operaciones sobre elementos y páginas, deshacer/rehacer, abrir y guardar.
## Todas las medidas en dp. Las coordenadas de los elementos son relativas al área de la página
## (debajo de la cabecera de la app, de ALTO_CABECERA_DP).

signal cambiado
signal seleccion_cambiada

const ALTO_CABECERA_DP := 60.0
const MAX_HISTORIAL := 200

var datos: Dictionary = {}
var ruta := ""
var modificado := false
var solo_lectura := false   # el ejemplo original no se sobrescribe: se usa "Guardar como"
var pagina_actual := 0
var seleccion := ""
var rejilla := 4.0

var _historial: Array[String] = []
var _indice := -1


# ------------------------------------------------------------------ proyectos
func nuevo(nombre: String, perfil_id: String, orientacion := "vertical") -> void:
	var perfil := Perfiles.buscar(perfil_id)
	var tam := Perfiles.tamano_dp(perfil) if not perfil.is_empty() else Vector2(384, 832)
	if (orientacion == "horizontal") != (tam.x > tam.y):
		tam = Vector2(tam.y, tam.x)
	datos = {
		"formato": Proyecto.FORMATO, "version": Proyecto.VERSION_FORMATO,
		"nombre": nombre, "perfil": perfil_id, "orientacion": orientacion,
		"lienzo_dp": [roundi(tam.x), roundi(tam.y)],
		"conexion": {"tipo": "bluetooth_spp", "nombre_dispositivo": "", "intervalo_ms": 400},
		"paginas": [{"id": "pagina_1", "nombre": "Principal", "widgets": []}],
	}
	ruta = ""
	solo_lectura = false
	_reiniciar()


func abrir(ruta_archivo: String) -> Array[String]:
	var p := Proyecto.desde_archivo(ruta_archivo)
	if not p.errores.is_empty():
		return p.errores
	cargar_datos(p.datos)
	ruta = ruta_archivo
	solo_lectura = ruta_archivo.begins_with("res://")
	return []


func cargar_datos(d: Dictionary) -> void:
	datos = d.duplicate(true)
	if not datos.has("orientacion"):
		var l: Array = datos.get("lienzo_dp", [384, 832])
		datos["orientacion"] = "horizontal" if l[0] > l[1] else "vertical"
	_reiniciar()


func guardar(ruta_archivo := "") -> String:
	var destino := ruta_archivo if ruta_archivo != "" else ruta
	if destino == "" or destino.begins_with("res://"):
		return "Elige dónde guardar (Guardar como)"
	var f := FileAccess.open(destino, FileAccess.WRITE)
	if f == null:
		return "No se puede escribir en %s (error %d)" % [destino, FileAccess.get_open_error()]
	f.store_string(JSON.stringify(datos, "  ", false) + "\n")
	f.close()
	ruta = destino
	solo_lectura = false
	modificado = false
	cambiado.emit()
	return ""


func _reiniciar() -> void:
	pagina_actual = 0
	seleccion = ""
	modificado = false
	_historial.clear()
	_indice = -1
	_instantanea()
	cambiado.emit()
	seleccion_cambiada.emit()


# ------------------------------------------------------------------ lienzo y perfil
func lienzo() -> Vector2:
	var l: Array = datos.get("lienzo_dp", [384, 832])
	return Vector2(l[0], l[1])


func area_pagina() -> Vector2:
	var l := lienzo()
	return Vector2(l.x, l.y - ALTO_CABECERA_DP)


func perfil() -> Dictionary:
	return Perfiles.buscar(str(datos.get("perfil", "")))


## Cambia de dispositivo u orientación. Los elementos se conservan; si quedan fuera, se recolocan dentro.
func cambiar_dispositivo(perfil_id: String, orientacion: String) -> void:
	var p := Perfiles.buscar(perfil_id)
	if p.is_empty():
		return
	var tam := Perfiles.tamano_dp(p)
	if (orientacion == "horizontal") != (tam.x > tam.y):
		tam = Vector2(tam.y, tam.x)
	datos["perfil"] = perfil_id
	datos["orientacion"] = orientacion
	datos["lienzo_dp"] = [roundi(tam.x), roundi(tam.y)]
	var area := area_pagina()
	for pag in datos.paginas:
		for w in pag.widgets:
			w.w = minf(float(w.w), area.x)
			w.x = clampf(float(w.x), 0.0, area.x - float(w.w))
	_registrar()


# ------------------------------------------------------------------ páginas
func paginas() -> Array:
	var p = datos.get("paginas", [])
	return p if p is Array else []


func pagina() -> Dictionary:
	if paginas().is_empty():
		return {"widgets": []}
	return paginas()[clampi(pagina_actual, 0, paginas().size() - 1)]


func widgets() -> Array:
	return pagina().get("widgets", [])


func ir_a_pagina(i: int) -> void:
	pagina_actual = clampi(i, 0, paginas().size() - 1)
	seleccionar("")
	cambiado.emit()


func anadir_pagina(nombre := "") -> void:
	var n := paginas().size() + 1
	var id := "pagina_%d" % n
	var ids := paginas().map(func(p): return p.get("id"))
	while ids.has(id):
		n += 1
		id = "pagina_%d" % n
	datos.paginas.append({"id": id, "nombre": nombre if nombre != "" else "Página %d" % n, "widgets": []})
	pagina_actual = paginas().size() - 1
	seleccion = ""
	_registrar()


func renombrar_pagina(nombre: String) -> void:
	if nombre.strip_edges() == "":
		return
	pagina()["nombre"] = nombre.strip_edges()
	_registrar()


func borrar_pagina() -> bool:
	if paginas().size() <= 1:
		return false
	datos.paginas.remove_at(pagina_actual)
	pagina_actual = clampi(pagina_actual, 0, paginas().size() - 1)
	seleccion = ""
	_registrar()
	return true


# ------------------------------------------------------------------ elementos
func buscar(id: String) -> Dictionary:
	for w in widgets():
		if w.get("id") == id:
			return w
	return {}


func _todos_los_ids() -> Array:
	var r := []
	for pag in paginas():
		for w in pag.get("widgets", []):
			r.append(w.get("id"))
	return r


func id_nuevo(tipo: String) -> String:
	var ids := _todos_los_ids()
	var n := 1
	while ids.has("%s_%d" % [tipo, n]):
		n += 1
	return "%s_%d" % [tipo, n]


func ajustar(v: float) -> float:
	return roundf(v / rejilla) * rejilla if rejilla > 0 else v


func anadir(tipo: String, x := -1.0, y := -1.0) -> String:
	if Esquema.info(tipo).is_empty():
		return ""
	var area := area_pagina()
	var d := Esquema.crear(tipo, id_nuevo(tipo), 0, 0)
	d.w = minf(float(d.w), area.x - 32.0)
	if x < 0 or y < 0:
		# Debajo del último elemento, con margen de 16 dp.
		var fondo := 8.0
		for w in widgets():
			fondo = maxf(fondo, float(w.y) + float(w.h))
		x = 16.0
		y = fondo + 12.0
	d.x = clampf(ajustar(x), 0.0, maxf(0.0, area.x - float(d.w)))
	d.y = maxf(0.0, ajustar(y))
	widgets().append(d)
	seleccion = d.id
	_registrar()
	seleccion_cambiada.emit()
	return d.id


func seleccionar(id: String) -> void:
	if id != seleccion:
		seleccion = id
		seleccion_cambiada.emit()


## Mueve/redimensiona. Con registrar=false (durante un arrastre) no se guarda en el historial.
func fijar_rect(id: String, r: Rect2, registrar := true) -> void:
	var w := buscar(id)
	if w.is_empty():
		return
	var area := area_pagina()
	var tam := Vector2(maxf(ajustar(r.size.x), 16.0), maxf(ajustar(r.size.y), 16.0))
	tam.x = minf(tam.x, area.x)
	var pos := Vector2(clampf(ajustar(r.position.x), 0.0, area.x - tam.x), maxf(0.0, ajustar(r.position.y)))
	w.x = pos.x
	w.y = pos.y
	w.w = tam.x
	w.h = tam.y
	if registrar:
		_registrar()
	else:
		cambiado.emit()


func rect_de(id: String) -> Rect2:
	var w := buscar(id)
	if w.is_empty():
		return Rect2()
	return Rect2(float(w.x), float(w.y), float(w.w), float(w.h))


func fijar_prop(id: String, clave: String, valor) -> void:
	var w := buscar(id)
	if w.is_empty():
		return
	if not w.has("props"):
		w["props"] = {}
	if (valor is String and valor == "" and clave.begins_with("pin_")):
		w.props.erase(clave)
	else:
		w.props[clave] = valor
	_registrar()


func fijar_pin(id: String, pin: String) -> bool:
	var w := buscar(id)
	if w.is_empty() or ProtocoloVCM.separar_pin(pin).is_empty():
		return false
	w["pin"] = pin.strip_edges().to_upper()
	_registrar()
	return true


func renombrar(id: String, nuevo_id: String) -> bool:
	nuevo_id = nuevo_id.strip_edges()
	var w := buscar(id)
	if w.is_empty() or nuevo_id == "" or _todos_los_ids().has(nuevo_id):
		return false
	w["id"] = nuevo_id
	seleccion = nuevo_id
	_registrar()
	return true


func borrar(id: String) -> void:
	var lista := widgets()
	for i in lista.size():
		if lista[i].get("id") == id:
			lista.remove_at(i)
			if seleccion == id:
				seleccion = ""
				seleccion_cambiada.emit()
			_registrar()
			return


func duplicar(id: String) -> String:
	var w := buscar(id)
	if w.is_empty():
		return ""
	var copia: Dictionary = w.duplicate(true)
	copia.id = id_nuevo(str(w.tipo))
	copia.x = clampf(float(w.x) + 12.0, 0.0, area_pagina().x - float(w.w))
	copia.y = float(w.y) + 12.0
	widgets().append(copia)
	seleccion = copia.id
	_registrar()
	seleccion_cambiada.emit()
	return copia.id


## Orden de dibujo: los últimos de la lista quedan encima.
func traer_delante(id: String) -> void:
	_mover_en_lista(id, true)


func enviar_atras(id: String) -> void:
	_mover_en_lista(id, false)


func _mover_en_lista(id: String, al_final: bool) -> void:
	var lista := widgets()
	for i in lista.size():
		if lista[i].get("id") == id:
			var w = lista[i]
			lista.remove_at(i)
			if al_final:
				lista.append(w)
			else:
				lista.insert(0, w)
			_registrar()
			return


## Elemento visible en un punto (dp, coordenadas de página), empezando por el de encima.
func elemento_en(p: Vector2) -> String:
	var lista := widgets()
	for i in range(lista.size() - 1, -1, -1):
		var w = lista[i]
		if Rect2(float(w.x), float(w.y), float(w.w), float(w.h)).has_point(p):
			return str(w.id)
	return ""


# ------------------------------------------------------------------ deshacer / rehacer
func _instantanea() -> void:
	var s := JSON.stringify({"d": datos, "p": pagina_actual})
	if _indice >= 0 and _indice < _historial.size() and _historial[_indice] == s:
		return
	_historial.resize(_indice + 1)
	_historial.append(s)
	if _historial.size() > MAX_HISTORIAL:
		_historial.pop_front()
	_indice = _historial.size() - 1


## Cierra un cambio (por ejemplo, al soltar tras un arrastre).
func registrar() -> void:
	_registrar()


func _registrar() -> void:
	modificado = true
	_instantanea()
	cambiado.emit()


func puede_deshacer() -> bool:
	return _indice > 0


func puede_rehacer() -> bool:
	return _indice < _historial.size() - 1


func deshacer() -> void:
	if puede_deshacer():
		_indice -= 1
		_restaurar()


func rehacer() -> void:
	if puede_rehacer():
		_indice += 1
		_restaurar()


func _restaurar() -> void:
	var e = JSON.parse_string(_historial[_indice])
	datos = e.d
	pagina_actual = int(e.p)
	if buscar(seleccion).is_empty():
		seleccion = ""
	modificado = true
	cambiado.emit()
	seleccion_cambiada.emit()
