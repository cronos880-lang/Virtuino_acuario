class_name Enlace
extends Node
## Canal de comunicación con el controlador (simulador, Bluetooth, ...).

signal datos_recibidos(texto: String)
signal estado_cambiado(estado: int, detalle: String)

enum Estado { DESCONECTADO, CONECTANDO, CONECTADO, ERROR }

var estado: int = Estado.DESCONECTADO
var descripcion := ""


func conectar(_destino: String = "") -> void:
	pass


func desconectar() -> void:
	_cambiar_estado(Estado.DESCONECTADO, "")


func enviar(_texto: String) -> void:
	pass


func esta_conectado() -> bool:
	return estado == Estado.CONECTADO


func _cambiar_estado(nuevo: int, detalle: String) -> void:
	estado = nuevo
	estado_cambiado.emit(nuevo, detalle)
