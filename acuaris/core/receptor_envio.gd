class_name ReceptorEnvio
extends Node
## Lado app (móvil/tablet): busca editores en la red local, se empareja con el código y
## recibe cada versión de la interfaz mientras está conectada.

signal pcs_encontrados(lista: Array)
signal estado_cambiado(estado: String, detalle: String)
signal proyecto_recibido(datos: Dictionary, revision: int)

const ARCHIVO := "user://acuaris.cfg"
const PING_MS := 5000
const REINTENTO_MS := 5000

## "parado", "buscando", "conectando", "necesita_codigo", "conectado", "error", "desconectado"
var estado := "parado"
var detalle := ""
var bloqueado := false
var pcs: Array[Dictionary] = []
var pc_actual: Dictionary = {}

var _udp := PacketPeerUDP.new()
var _peer: StreamPeerTCP = null
var _buffer := PackedByteArray()
var _codigo := ""
var _t_ping := 0
var _t_reintento := -1
var _t_busqueda := -1
var _reloj_externo := -1
var _cfg := ConfigFile.new()
var archivo := ARCHIVO


func _ready() -> void:
	_cfg.load(archivo)
	bloqueado = bool(_cfg.get_value("envio", "bloqueado", false))


func _ahora() -> int:
	return _reloj_externo if _reloj_externo >= 0 else Time.get_ticks_msec()


func fijar_bloqueado(v: bool) -> void:
	bloqueado = v
	_cfg.set_value("envio", "bloqueado", v)
	_cfg.save(archivo)


func _clave(pc: Dictionary) -> String:
	return "pc_" + str(pc.get("pc", pc.get("ip", ""))).to_snake_case()


func tiene_token(pc: Dictionary) -> bool:
	return str(_cfg.get_value("tokens", _clave(pc), "")) != "" or str(_cfg.get_value("tokens", "ip_" + str(pc.get("ip", "")).replace(".", "_"), "")) != ""


func _token(pc: Dictionary) -> String:
	var t := str(_cfg.get_value("tokens", _clave(pc), ""))
	if t == "":
		t = str(_cfg.get_value("tokens", "ip_" + str(pc.get("ip", "")).replace(".", "_"), ""))
	return t


func ultimo_pc() -> Dictionary:
	var d = _cfg.get_value("envio", "ultimo_pc", {})
	return d if d is Dictionary else {}


# ------------------------------------------------------------------ búsqueda
## Pregunta por difusión en la red local quién tiene el editor abierto.
func buscar(destinos: Array = [], puerto_udp := EnvioProtocolo.PUERTO_UDP) -> void:
	pcs.clear()
	_udp.close()
	_udp.bind(0, "*")
	_udp.set_broadcast_enabled(true)
	var lista := destinos.duplicate()
	if lista.is_empty():
		lista.append("255.255.255.255")
		for ip in EnvioProtocolo.ips_locales():
			var p := ip.split(".")
			lista.append("%s.%s.%s.255" % [p[0], p[1], p[2]])
	for d in lista:
		_udp.set_dest_address(str(d), puerto_udp)
		_udp.put_packet(EnvioProtocolo.PREGUNTA.to_utf8_buffer())
	_t_busqueda = _ahora()
	if estado != "conectado":
		_cambiar("buscando", "")


# ------------------------------------------------------------------ conexión
func conectar(pc: Dictionary, codigo := "") -> void:
	desconectar(false)
	pc_actual = pc.duplicate()
	_codigo = codigo.strip_edges()
	if _codigo == "" and not tiene_token(pc):
		_cambiar("necesita_codigo", str(pc.get("pc", pc.get("ip", ""))))
		return
	_peer = StreamPeerTCP.new()
	_buffer = PackedByteArray()
	var e := _peer.connect_to_host(str(pc.ip), int(pc.get("puerto", EnvioProtocolo.PUERTO_TCP)))
	if e != OK:
		_cambiar("error", "No se pudo conectar con %s" % pc.ip)
		return
	_cambiar("conectando", str(pc.get("pc", pc.ip)))
	_t_reintento = -1


func desconectar(manual := true) -> void:
	if _peer:
		_peer.disconnect_from_host()
	_peer = null
	if manual:
		_t_reintento = -1
		pc_actual = {}
		_cambiar("parado", "")


func conectado() -> bool:
	return estado == "conectado"


func _process(_d: float) -> void:
	sondear()


func sondear(ahora_ms := -1) -> void:
	if ahora_ms >= 0:
		_reloj_externo = ahora_ms
	var ahora := _ahora()
	# Respuestas de la búsqueda
	if _udp.is_bound():
		var nuevos := false
		while _udp.get_available_packet_count() > 0:
			var txt := _udp.get_packet().get_string_from_utf8()
			var ip := _udp.get_packet_ip()
			if txt.begins_with(EnvioProtocolo.RESPUESTA):
				var d = JSON.parse_string(txt.substr(EnvioProtocolo.RESPUESTA.length()))
				if d is Dictionary and not pcs.any(func(x): return x.ip == ip):
					pcs.append({"pc": str(d.get("pc", "PC")), "ip": ip, "puerto": int(d.get("puerto", EnvioProtocolo.PUERTO_TCP))})
					nuevos = true
		if nuevos:
			pcs_encontrados.emit(pcs)
		if _t_busqueda >= 0 and ahora - _t_busqueda > 2500:
			_t_busqueda = -1
			_udp.close()
			if estado == "buscando":
				_cambiar("parado", "%d encontrado(s)" % pcs.size())
			pcs_encontrados.emit(pcs)
	# Reconexión automática tras un corte
	if _peer == null:
		if _t_reintento >= 0 and ahora >= _t_reintento and not pc_actual.is_empty():
			conectar(pc_actual)
		return
	_peer.poll()
	var st := _peer.get_status()
	if st == StreamPeerTCP.STATUS_CONNECTING:
		return
	if st != StreamPeerTCP.STATUS_CONNECTED:
		var estaba := estado == "conectado"
		_peer = null
		if estaba or tiene_token(pc_actual):
			_t_reintento = ahora + REINTENTO_MS
			_cambiar("desconectado", "Reintentando…")
		else:
			_cambiar("error", "No responde %s. ¿Está abierto el editor y en la misma WiFi?" % pc_actual.get("ip", ""))
		return
	if estado == "conectando":
		var hola := {"tipo": "hola", "version": EnvioProtocolo.VERSION, "dispositivo": OS.get_model_name()}
		var t := _token(pc_actual)
		if t != "" and _codigo == "":
			hola["token"] = t
		else:
			hola["codigo"] = _codigo
		_peer.put_data(EnvioProtocolo.linea(hola))
		_cambiar("esperando", "")
		_t_ping = ahora
	if ahora - _t_ping > PING_MS:
		_t_ping = ahora
		_peer.put_data(EnvioProtocolo.linea({"tipo": "ping"}))
	var n := _peer.get_available_bytes()
	if n <= 0:
		return
	var r := _peer.get_partial_data(n)
	if r[0] != OK:
		return
	_buffer.append_array(r[1])
	if _buffer.size() > EnvioProtocolo.MAX_LINEA:
		_buffer = PackedByteArray()
	var ex := EnvioProtocolo.extraer(_buffer)
	_buffer = ex[1]
	for m in ex[0]:
		_atender(m)


func _atender(m: Dictionary) -> void:
	match str(m.get("tipo", "")):
		"bienvenida":
			pc_actual["pc"] = str(m.get("pc", pc_actual.get("pc", "PC")))
			_cfg.set_value("tokens", _clave(pc_actual), str(m.get("token", "")))
			_cfg.set_value("tokens", "ip_" + str(pc_actual.ip).replace(".", "_"), str(m.get("token", "")))
			_cfg.set_value("envio", "ultimo_pc", pc_actual)
			_cfg.save(archivo)
			_codigo = ""
			_cambiar("conectado", str(pc_actual.pc))
		"error":
			var motivo := str(m.get("motivo", ""))
			desconectar(false)
			_t_reintento = -1
			if motivo == "token":
				if _cfg.has_section_key("tokens", _clave(pc_actual)):
					_cfg.erase_section_key("tokens", _clave(pc_actual))
				var k_ip := "ip_" + str(pc_actual.get("ip", "")).replace(".", "_")
				if _cfg.has_section_key("tokens", k_ip):
					_cfg.erase_section_key("tokens", k_ip)
				_cfg.save(archivo)
				_cambiar("necesita_codigo", "El PC ya no reconoce este dispositivo: escribe el código nuevo")
			elif motivo == "codigo":
				_cambiar("necesita_codigo", "Código incorrecto")
			else:
				_cambiar("error", "Versión del editor no compatible: actualiza la app")
		"proyecto":
			var rev := int(m.get("revision", 0))
			if bloqueado:
				_peer.put_data(EnvioProtocolo.linea({"tipo": "rechazado", "revision": rev}))
				return
			var datos = m.get("datos")
			if datos is Dictionary:
				proyecto_recibido.emit(datos, rev)
				if _peer:
					_peer.put_data(EnvioProtocolo.linea({"tipo": "recibido", "revision": rev, "nombre": str(datos.get("nombre", ""))}))


func _cambiar(e: String, d: String) -> void:
	estado = e
	detalle = d
	estado_cambiado.emit(e, d)
