class_name EnvioProtocolo
extends RefCounted
## Envío de interfaces del editor (PC) a la app (móvil/tablet) por la red local.
##
## Descubrimiento (UDP 47801): la app envía "ACUARIS?" por difusión; cada editor responde
##   "ACUARIS!{json}" con {"pc": nombre, "puerto": 47800, "version": 1}.
## Conexión (TCP 47800): mensajes JSON de una línea terminados en "\n".
##   app -> PC : {"tipo":"hola","codigo":"123456","dispositivo":"..."}  (primera vez)
##               {"tipo":"hola","token":"...","dispositivo":"..."}       (ya emparejado)
##               {"tipo":"recibido","nombre":"...","revision":N}
##               {"tipo":"ping"}
##   PC -> app : {"tipo":"bienvenida","token":"...","pc":"..."}
##               {"tipo":"error","motivo":"codigo"|"token"|"version"}
##               {"tipo":"proyecto","revision":N,"datos":{...}}
##               {"tipo":"pong"}

const PUERTO_TCP := 47800
const PUERTO_UDP := 47801
const VERSION := 1
const PREGUNTA := "ACUARIS?"
const RESPUESTA := "ACUARIS!"
const MAX_LINEA := 4 * 1024 * 1024


static func linea(d: Dictionary) -> PackedByteArray:
	return (JSON.stringify(d) + "\n").to_utf8_buffer()


## Extrae los mensajes completos de un buffer de bytes. Devuelve [mensajes, resto].
static func extraer(buffer: PackedByteArray) -> Array:
	var mensajes: Array[Dictionary] = []
	var inicio := 0
	for i in buffer.size():
		if buffer[i] == 10:
			var texto := buffer.slice(inicio, i).get_string_from_utf8()
			inicio = i + 1
			var d = JSON.parse_string(texto)
			if d is Dictionary:
				mensajes.append(d)
	return [mensajes, buffer.slice(inicio)]


static func codigo_aleatorio() -> String:
	return "%06d" % (randi() % 1000000)


static func token_aleatorio() -> String:
	var c := Crypto.new()
	return c.generate_random_bytes(16).hex_encode()


## Direcciones IPv4 de la red local de este equipo (para mostrarlas al usuario).
static func ips_locales() -> PackedStringArray:
	var r := PackedStringArray()
	for ip in IP.get_local_addresses():
		if ip.count(".") != 3 or ip.begins_with("127.") or ip.begins_with("169.254."):
			continue
		r.append(ip)
	return r
