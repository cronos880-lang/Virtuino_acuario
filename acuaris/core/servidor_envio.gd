class_name ServidorEnvio
extends Node
## Lado PC (editor): atiende a las apps que piden la interfaz y les envía cada versión.
## Emparejamiento: la primera vez la app debe dar el código de 6 cifras que muestra el editor;
## después se identifica con un token guardado en los dos lados.

signal clientes_cambiados
signal aviso(texto: String)

const ARCHIVO_EMPAREJADOS := "user://emparejados.cfg"
const SIN_ACTIVIDAD_MS := 20000

var codigo := ""
var nombre_pc := ""
var activo := false
var revision := 0
var puerto_tcp := EnvioProtocolo.PUERTO_TCP
var puerto_udp := EnvioProtocolo.PUERTO_UDP

var _tcp := TCPServer.new()
var _udp := PacketPeerUDP.new()
var _clientes: Array[Dictionary] = []
var _tokens: Dictionary = {}
var _datos: Dictionary = {}
var _reloj_externo := -1
var archivo := ARCHIVO_EMPAREJADOS


func _init() -> void:
	nombre_pc = OS.get_environment("COMPUTERNAME")
	if nombre_pc == "":
		nombre_pc = OS.get_environment("HOSTNAME")
	if nombre_pc == "":
		nombre_pc = "PC"


func iniciar(tcp := EnvioProtocolo.PUERTO_TCP, udp := EnvioProtocolo.PUERTO_UDP) -> String:
	if activo:
		return ""
	puerto_tcp = tcp
	puerto_udp = udp
	var e := _tcp.listen(puerto_tcp, "*")
	if e != OK:
		return "No se pudo abrir el puerto %d (¿otro editor abierto?). Error %d" % [puerto_tcp, e]
	e = _udp.bind(puerto_udp, "*")
	if e != OK:
		aviso.emit("La búsqueda automática no está disponible (puerto %d ocupado). Usa la IP." % puerto_udp)
	codigo = EnvioProtocolo.codigo_aleatorio()
	_cargar_tokens()
	activo = true
	return ""


func detener() -> void:
	for c in _clientes:
		c.peer.disconnect_from_host()
	_clientes.clear()
	_tcp.stop()
	_udp.close()
	activo = false
	clientes_cambiados.emit()


func nuevo_codigo() -> void:
	codigo = EnvioProtocolo.codigo_aleatorio()


func olvidar_emparejados() -> void:
	_tokens.clear()
	_guardar_tokens()
	for c in _clientes:
		c.peer.disconnect_from_host()
	_clientes.clear()
	clientes_cambiados.emit()


func num_emparejados() -> int:
	return _tokens.size()


## Publica una versión de la interfaz y la envía a todas las apps conectadas.
func publicar(datos: Dictionary) -> int:
	_datos = datos.duplicate(true)
	revision += 1
	var n := 0
	for c in _clientes:
		if c.autenticado:
			_enviar_proyecto(c)
			n += 1
	return n


func clientes() -> Array[Dictionary]:
	var r: Array[Dictionary] = []
	for c in _clientes:
		if c.autenticado:
			r.append({"dispositivo": c.dispositivo, "ip": c.ip, "revision": c.revision_recibida, "rechazado": c.rechazado})
	return r


func _process(_d: float) -> void:
	sondear()


func _ahora() -> int:
	return _reloj_externo if _reloj_externo >= 0 else Time.get_ticks_msec()


func sondear(ahora_ms := -1) -> void:
	if ahora_ms >= 0:
		_reloj_externo = ahora_ms
	if not activo:
		return
	# Descubrimiento
	while _udp.is_bound() and _udp.get_available_packet_count() > 0:
		var pkt := _udp.get_packet().get_string_from_utf8()
		var ip := _udp.get_packet_ip()
		var puerto := _udp.get_packet_port()
		if pkt.strip_edges() == EnvioProtocolo.PREGUNTA and ip != "":
			_udp.set_dest_address(ip, puerto)
			_udp.put_packet((EnvioProtocolo.RESPUESTA + JSON.stringify({"pc": nombre_pc, "puerto": puerto_tcp, "version": EnvioProtocolo.VERSION})).to_utf8_buffer())
	# Conexiones nuevas
	while _tcp.is_connection_available():
		var peer := _tcp.take_connection()
		peer.set_no_delay(true)
		_clientes.append({"peer": peer, "ip": peer.get_connected_host(), "buffer": PackedByteArray(), "autenticado": false,
			"dispositivo": "?", "revision_recibida": 0, "rechazado": false, "t": _ahora()})
	# Mensajes
	var cambios := false
	for c in _clientes.duplicate():
		var peer: StreamPeerTCP = c.peer
		peer.poll()
		if peer.get_status() != StreamPeerTCP.STATUS_CONNECTED or _ahora() - int(c.t) > SIN_ACTIVIDAD_MS:
			peer.disconnect_from_host()
			_clientes.erase(c)
			cambios = cambios or c.autenticado
			continue
		var n := peer.get_available_bytes()
		if n <= 0:
			continue
		var r := peer.get_partial_data(n)
		if r[0] != OK:
			continue
		c.t = _ahora()
		var buf: PackedByteArray = c.buffer
		buf.append_array(r[1])
		if buf.size() > EnvioProtocolo.MAX_LINEA:
			buf = PackedByteArray()
		var ex := EnvioProtocolo.extraer(buf)
		c.buffer = ex[1]
		for m in ex[0]:
			cambios = _atender(c, m) or cambios
	if cambios:
		clientes_cambiados.emit()


func _atender(c: Dictionary, m: Dictionary) -> bool:
	var peer: StreamPeerTCP = c.peer
	match str(m.get("tipo", "")):
		"hola":
			c.dispositivo = str(m.get("dispositivo", "Dispositivo"))
			if int(m.get("version", EnvioProtocolo.VERSION)) > EnvioProtocolo.VERSION:
				peer.put_data(EnvioProtocolo.linea({"tipo": "error", "motivo": "version"}))
				return false
			var token := str(m.get("token", ""))
			if token != "" and _tokens.has(token):
				c.autenticado = true
			elif token == "" and str(m.get("codigo", "")) == codigo and codigo != "":
				token = EnvioProtocolo.token_aleatorio()
				_tokens[token] = c.dispositivo
				_guardar_tokens()
				c.autenticado = true
			else:
				peer.put_data(EnvioProtocolo.linea({"tipo": "error", "motivo": "token" if token != "" else "codigo"}))
				aviso.emit("Intento de conexión rechazado desde %s (%s)" % [c.ip, c.dispositivo])
				return false
			peer.put_data(EnvioProtocolo.linea({"tipo": "bienvenida", "token": token, "pc": nombre_pc}))
			aviso.emit("Conectado: %s" % c.dispositivo)
			if not _datos.is_empty():
				_enviar_proyecto(c)
			return true
		"recibido":
			c.revision_recibida = int(m.get("revision", 0))
			c.rechazado = false
			return true
		"rechazado":
			c.rechazado = true
			return true
		"ping":
			peer.put_data(EnvioProtocolo.linea({"tipo": "pong"}))
	return false


func _enviar_proyecto(c: Dictionary) -> void:
	var peer: StreamPeerTCP = c.peer
	peer.put_data(EnvioProtocolo.linea({"tipo": "proyecto", "revision": revision, "datos": _datos}))


func _cargar_tokens() -> void:
	var cfg := ConfigFile.new()
	_tokens.clear()
	if cfg.load(archivo) == OK:
		for t in cfg.get_section_keys("tokens") if cfg.has_section("tokens") else PackedStringArray():
			_tokens[t] = cfg.get_value("tokens", t, "")


func _guardar_tokens() -> void:
	var cfg := ConfigFile.new()
	for t in _tokens:
		cfg.set_value("tokens", t, _tokens[t])
	cfg.save(archivo)
