class_name EnlaceBluetooth
extends Enlace
## Bluetooth clásico (perfil puerto serie, SPP) mediante el complemento Android "AcuarisBluetooth".
## En el PC el complemento no existe y disponible() devuelve false.

const SINGLETON := "AcuarisBluetooth"

signal permisos_resueltos(concedidos: bool)

var _bt: Object = null
var direccion := ""


func _ready() -> void:
	if Engine.has_singleton(SINGLETON):
		_bt = Engine.get_singleton(SINGLETON)
		_bt.connect("bt_datos", _al_recibir)
		_bt.connect("bt_estado", _al_estado)
		_bt.connect("bt_permisos", func(ok: bool): permisos_resueltos.emit(ok))


static func disponible() -> bool:
	return Engine.has_singleton(SINGLETON)


func tiene_permisos() -> bool:
	return _bt != null and _bt.tiene_permisos()


func solicitar_permisos() -> void:
	if _bt:
		_bt.solicitar_permisos()


func bluetooth_activo() -> bool:
	return _bt != null and _bt.bluetooth_activo()


## Lista de dispositivos emparejados: [{"nombre": .., "direccion": ..}]
func dispositivos_emparejados() -> Array:
	if _bt == null:
		return []
	var datos = JSON.parse_string(_bt.dispositivos_emparejados())
	return datos if datos is Array else []


func conectar(destino: String = "") -> void:
	if _bt == null:
		_cambiar_estado(Estado.ERROR, "Bluetooth no disponible en este equipo")
		return
	direccion = destino
	_cambiar_estado(Estado.CONECTANDO, destino)
	_bt.conectar(destino)


func desconectar() -> void:
	if _bt:
		_bt.desconectar()
	_cambiar_estado(Estado.DESCONECTADO, "")


func enviar(texto: String) -> void:
	if _bt and estado == Estado.CONECTADO:
		_bt.enviar(texto)


func _al_recibir(texto: String) -> void:
	datos_recibidos.emit(texto)


func _al_estado(e: String, detalle: String) -> void:
	match e:
		"conectando":
			_cambiar_estado(Estado.CONECTANDO, detalle)
		"conectado":
			descripcion = detalle
			_cambiar_estado(Estado.CONECTADO, detalle)
		"error":
			_cambiar_estado(Estado.ERROR, detalle)
		_:
			_cambiar_estado(Estado.DESCONECTADO, detalle)
