class_name EnlaceSimulado
extends Enlace
## Enlace con el Arduino virtual. Simula la latencia del Bluetooth (9600 baudios).

var simulador := SimuladorArduino.new()
## Multiplica la velocidad del reloj simulado (1 = tiempo real).
var aceleracion := 1.0
## Pasadas del loop() del Arduino por segundo (con vDelay(50) x4 ronda las 5-6).
var pasadas_por_segundo := 6.0
var _acumulado := 0.0


func _init() -> void:
	descripcion = "Simulador"


func conectar(_destino: String = "") -> void:
	_cambiar_estado(Estado.CONECTADO, "Simulador")


func enviar(texto: String) -> void:
	if estado == Estado.CONECTADO:
		simulador.recibir(texto)


func _process(delta: float) -> void:
	paso(delta)


## Avanza el simulador (se usa también desde las pruebas automáticas).
func paso(delta: float) -> void:
	if estado != Estado.CONECTADO:
		return
	_acumulado += delta
	var periodo := 1.0 / pasadas_por_segundo
	while _acumulado >= periodo:
		_acumulado -= periodo
		var salida := simulador.avanzar(periodo * aceleracion)
		if salida != "":
			datos_recibidos.emit(salida)
