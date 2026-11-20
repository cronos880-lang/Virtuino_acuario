extends RefCounted
## El simulador "acuario_v2" debe comportarse como arduino/Control_Acuario_V2 (mismos escenarios
## que pruebas/test_sketch.cpp del sketch).

var t


func _init(ejecutor) -> void:
	t = ejecutor


func _correr(sim: SimuladorArduino, segundos: float) -> String:
	var salida := ""
	var pasos := int(segundos / 0.05)
	for i in pasos:
		salida += sim.avanzar(0.05)
	return salida


func ejecutar() -> void:
	# Fórmulas (mismos valores que test_logica.cpp)
	t.comprobar(SimuladorArduino.nivel_luz(16 * 3600 + 7 * 60 + 30, 1600, 2200, 15, 125) == 62, "sim v2: mitad del amanecer = 62 (igual que el sketch)")
	t.comprobar(SimuladorArduino.en_horario(3 * 3600, 2200, 600) and not SimuladorArduino.en_horario(12 * 3600, 2200, 600), "sim v2: horario que cruza la medianoche")
	var sim := SimuladorArduino.new()
	sim.configurar_modelo("acuario_v2")
	t.comprobar(sim.V[27] == 25.0 and sim.V[50] == 1600 and sim.V[70] == 200, "sim v2: valores iniciales del sketch V2")
	sim.fijar_hora(15, 30)
	sim.temperatura_agua = 24.5
	sim.temperatura_ambiente = 24.5
	_correr(sim, 2.0)
	t.comprobar(sim.V[6] == 1.0 and sim.V[8] == 1.0, "sim v2: calentador enciende al arrancar y bomba en horario")
	# Ajustes desde la app (protocolo real)
	sim.recibir("!V27=26.5$")
	_correr(sim, 0.3)
	t.comprobar(sim.V[27] == 26.5 and sim.aj.consigna == 26.5, "sim v2: consigna aceptada")
	sim.recibir("!V27=99$")
	_correr(sim, 0.3)
	t.comprobar(sim.V[27] == 26.5, "sim v2: consigna absurda restaurada")
	sim.recibir("!V50=2575$")
	_correr(sim, 0.3)
	t.comprobar(sim.V[50] == 1600, "sim v2: HHMM no válido restaurado")
	sim.recibir("!V44=930$")
	_correr(sim, 0.3)
	t.comprobar(sim.hora() == 9 and sim.minuto() == 30 and sim.V[44] == 0, "sim v2: poner en hora 09:30")
	t.comprobar(_correr(sim, 0.0) == "" and sim.obtener_respuesta("!V27=?$") == "!V27=26.50$", "sim v2: lectura con el formato de VirtuinoCM")
	# Fallo de sonda
	sim.sonda_conectada = false
	_correr(sim, 10.0)
	t.comprobar(sim.V[60] == 0.0, "sim v2: a los 10 s sin sonda aún no hay alarma")
	_correr(sim, 6.0)
	t.comprobar(sim.V[60] == 1.0 and sim.V[63] == 3.0 and sim.V[6] == 0.0, "sim v2: fallo de sonda → calentador apagado y estado 3")
	sim.sonda_conectada = true
	_correr(sim, 2.0)
	t.comprobar(sim.V[60] == 0.0, "sim v2: la alarma se quita al volver la sonda")
	# Formato hora del elemento Valor
	t.comprobar(WValor.leer_hora("16:30") == 1630 and WValor.leer_hora("930") == 930 and WValor.leer_hora("9.05") == 905, "valor hora: lectura de 16:30, 930 y 9.05")
	t.comprobar(WValor.leer_hora("25:00") == null and WValor.leer_hora("12:60") == null and WValor.leer_hora("abc") == null, "valor hora: horas no válidas")
	t.comprobar(WValor.texto_hora(930) == "09:30" and WValor.texto_hora(2200) == "22:00", "valor hora: se muestra HH:MM")
	# Proyecto Acuario V2
	var p := Proyecto.desde_archivo("res://proyectos/acuario_v2.acuaris.json")
	t.comprobar(p.errores.is_empty() and p.paginas().size() == 4 and p.datos.get("simulador") == "acuario_v2", "proyecto Acuario V2 válido con 4 páginas")
	for pin in ["V27", "V28", "V44", "V50", "V51", "V52", "V53", "V54", "V55", "V57", "V58", "V60", "V63", "V70"]:
		t.comprobar(p.todos_los_pines().has(pin), "Acuario V2 usa " + pin)
