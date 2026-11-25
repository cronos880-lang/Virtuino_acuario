class_name Comunicador
extends Node
## Motor de sondeo: pregunta uno a uno los pines usados por la interfaz y envía las escrituras.
##
## Igual que Virtuino: una sola petición de lectura en vuelo cada vez (el Arduino atiende un
## comando por pasada del loop y su buffer serie es de 64 bytes). Las escrituras no tienen
## respuesta en VirtuinoCM, así que se envían y se continúa.

signal valor_actualizado(pin: String, valor: float)
signal estadisticas_cambiadas()

var enlace: Enlace = null
var pines_lectura: Array[String] = []
var valores: Dictionary = {}

## Pausa entre el final de una ronda de lecturas y la siguiente.
var intervalo_ronda_ms := 400
## Tiempo máximo de espera de una respuesta (el DS18B20 a 12 bits bloquea ~750 ms el Arduino).
var tiempo_espera_ms := 2000

# Estadísticas
var respuestas := 0
var sin_respuesta := 0
var latencia_ms := 0
var ultima_respuesta_ms := -1
## Hora (unix) de la última respuesta del controlador, para el elemento "Estado del controlador".
static var ultima_respuesta_unix := 0.0

var _buffer := ""
var _pendiente := ""
var _t_envio := 0
var _indice := 0
var _t_fin_ronda := -100000
var _cola_escrituras: Array[Dictionary] = []
## Pines de la página que se está viendo: se leen en cada ronda; el resto, una de cada RONDAS_COMPLETA.
var pines_prioritarios: Array[String] = []
const RONDAS_COMPLETA := 4
var _ronda: Array[String] = []
var _n_ronda := 0
var _ronda_ya := false   # tras escribir, empezar otra ronda en cuanto se pueda (respuesta rápida)
var _t_ultima_escritura: Dictionary = {}
var _reloj_externo := -1


func fijar_enlace(nuevo: Enlace) -> void:
	if enlace and enlace.datos_recibidos.is_connected(_al_recibir):
		enlace.datos_recibidos.disconnect(_al_recibir)
	enlace = nuevo
	_buffer = ""
	_pendiente = ""
	_indice = 0
	_ronda = pines_lectura.duplicate()
	if enlace:
		enlace.datos_recibidos.connect(_al_recibir)


func fijar_pines(pines: Array) -> void:
	pines_lectura.clear()
	for p in pines:
		var sp := ProtocoloVCM.separar_pin(str(p))
		if sp.is_empty():
			continue
		var nombre := ProtocoloVCM.nombre_pin(sp.tipo, sp.pin)
		if not pines_lectura.has(nombre):
			pines_lectura.append(nombre)
	_ronda = pines_lectura.duplicate()
	_indice = 0


## Escribe un valor en el controlador. Actualiza al instante el valor local (respuesta inmediata
## en pantalla) y descarta lecturas pedidas antes de la escritura.
func escribir(pin: String, valor: float) -> void:
	var sp := ProtocoloVCM.separar_pin(pin)
	if sp.is_empty():
		push_warning("Pin no válido: %s" % pin)
		return
	var nombre := ProtocoloVCM.nombre_pin(sp.tipo, sp.pin)
	var texto := ProtocoloVCM.peticion_escritura(sp.tipo, sp.pin, valor)
	# Si ya había una escritura pendiente del mismo pin (deslizador en vivo), se sustituye: sin cola
	var sustituida := false
	for e in _cola_escrituras:
		if e.pin == nombre:
			e.texto = texto
			sustituida = true
	if not sustituida:
		_cola_escrituras.append({"texto": texto, "pin": nombre})
	# Se corta la ronda en curso y se vuelve a leer ya la página visible, para ver el efecto
	_ronda_ya = true
	_indice = _ronda.size()
	valores[nombre] = valor
	valor_actualizado.emit(nombre, valor)


func _ahora() -> int:
	return _reloj_externo if _reloj_externo >= 0 else Time.get_ticks_msec()


func _process(_delta: float) -> void:
	tick()


## Un paso del motor. Las pruebas pueden pasar un tiempo concreto en milisegundos.
func tick(ahora_ms: int = -1) -> void:
	if ahora_ms >= 0:
		_reloj_externo = ahora_ms
	var ahora := _ahora()
	if enlace == null or not enlace.esta_conectado():
		return
	if _pendiente != "":
		if ahora - _t_envio < tiempo_espera_ms:
			return
		sin_respuesta += 1
		_pendiente = ""
		estadisticas_cambiadas.emit()
	if not _cola_escrituras.is_empty():
		var e: Dictionary = _cola_escrituras.pop_front()
		_t_ultima_escritura[e.pin] = ahora
		enlace.enviar(e.texto)
		return
	if pines_lectura.is_empty():
		return
	if _indice >= _ronda.size():
		if ahora - _t_fin_ronda < intervalo_ronda_ms and not _ronda_ya:
			return
		_nueva_ronda()
	var nombre := _ronda[_indice]
	_indice += 1
	if _indice >= _ronda.size():
		_t_fin_ronda = ahora
	var sp := ProtocoloVCM.separar_pin(nombre)
	_pendiente = nombre
	_t_envio = ahora
	enlace.enviar(ProtocoloVCM.peticion_lectura(sp.tipo, sp.pin))


## Pines de la página visible (se leen en todas las rondas).
func fijar_prioritarios(pines: Array) -> void:
	pines_prioritarios.clear()
	for p in pines:
		var sp := ProtocoloVCM.separar_pin(str(p))
		if not sp.is_empty():
			var nombre := ProtocoloVCM.nombre_pin(sp.tipo, sp.pin)
			if not pines_prioritarios.has(nombre):
				pines_prioritarios.append(nombre)
	_ronda_ya = true


func _nueva_ronda() -> void:
	_indice = 0
	_ronda_ya = false
	_n_ronda += 1
	if pines_prioritarios.is_empty() or _n_ronda % RONDAS_COMPLETA == 0:
		_ronda = pines_lectura.duplicate()
	else:
		_ronda = pines_prioritarios.duplicate()


func _al_recibir(texto: String) -> void:
	_buffer += texto
	var r := ProtocoloVCM.analizar(_buffer)
	_buffer = r.resto
	if _buffer.length() > 1024:
		_buffer = ""
	var ahora := _ahora()
	for m in r.mensajes:
		var nombre := ProtocoloVCM.nombre_pin(m.tipo, m.pin)
		var es_pendiente := nombre == _pendiente
		if es_pendiente:
			_pendiente = ""
			respuestas += 1
			latencia_ms = ahora - _t_envio
			ultima_respuesta_ms = ahora
			Comunicador.ultima_respuesta_unix = Time.get_unix_time_from_system()
		# Lectura pedida antes de una escritura posterior: valor obsoleto, se ignora.
		if _t_ultima_escritura.has(nombre) and es_pendiente and _t_envio <= _t_ultima_escritura[nombre]:
			continue
		if not m.numerico:
			continue
		valores[nombre] = m.valor
		Historial.anotar(nombre, m.valor)
		valor_actualizado.emit(nombre, m.valor)
	if not r.mensajes.is_empty():
		estadisticas_cambiadas.emit()
