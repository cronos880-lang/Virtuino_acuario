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
	t.comprobar(sim.V[27] == 25.0 and sim.V[50] == 1600 and sim.V[70] == 210, "sim v2: valores iniciales del sketch V2")
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
	# 2.1.0: intensidad temporal, resumen y calentador sin efecto
	var s2 := SimuladorArduino.new()
	s2.configurar_modelo("acuario_v2")
	s2.fijar_hora(18, 0)
	_correr(s2, 1.0)
	s2.recibir("!V12=40$")
	_correr(s2, 0.3)
	t.comprobar(s2.luz_pwm == 40 and s2.V[28] == 125.0, "sim v2: intensidad temporal sin tocar la referencia")
	s2.recibir("!V13=1$")
	_correr(s2, 0.3)
	t.comprobar(s2.luz_pwm == 125 and s2.V[12] == 125.0, "sim v2: volver a la referencia")
	s2.recibir("!V12=60$")
	_correr(s2, 0.3)
	s2.fijar_hora(23, 0)
	_correr(s2, 1.0)
	s2.fijar_hora(15, 59, 58)
	_correr(s2, 4.0)
	t.comprobar(s2.V[12] == 125.0, "sim v2: al amanecer vuelve a la referencia")
	t.comprobar(s2.V[76] > 0.0 and s2.V[78] >= s2.V[76] and s2.V[77] == 1559, "sim v2: resumen de hoy (empieza de cero al cambiar de día)")
	s2.temperatura_ambiente = 15.0
	s2.temperatura_agua = 24.0
	s2.recibir("!V27=30$")
	for i in 4000:
		s2.temperatura_agua = 24.0
		s2.avanzar(1.0)
	t.comprobar(s2.V[64] == 1.0 and s2.V[63] == 5.0, "sim v2: calentador sin efecto a los 60 min")
	# Respuesta rápida: la página visible se lee en cada ronda y las escrituras no se acumulan
	var pr := Proyecto.desde_archivo("res://proyectos/acuario_v2.acuaris.json")
	var en := EnlaceSimulado.new()
	var co := Comunicador.new()
	t.root.add_child(en)
	t.root.add_child(co)
	en.set_process(false)
	co.set_process(false)
	en.simulador.configurar_modelo("acuario_v2")
	en.simulador.fijar_hora(18, 0)
	co.fijar_enlace(en)
	co.fijar_pines(pr.todos_los_pines())
	var pp := []
	for d in pr.paginas()[0].widgets:
		pp.append_array(Proyecto.pines_de(d))
	co.fijar_prioritarios(pp)
	en.conectar()
	var ms := 0
	for i in 200:
		ms += 50
		en.paso(0.05)
		co.tick(ms)
	for v in [10.0, 20.0, 30.0, 40.0]:
		co.escribir("V12", v)
	t.comprobar(co._cola_escrituras.size() == 1, "comunicador: escrituras del mismo pin no se acumulan")
	for i in 100:
		ms += 50
		en.paso(0.05)
		co.tick(ms)
	t.comprobar(en.simulador.luz_pwm == 40, "comunicador: la luz cambia con el último valor del deslizador")
	co.escribir("V13", 1.0)   # botón «Referencia»
	var ms0 := ms
	var visto := -1
	for i in 200:
		ms += 50
		en.paso(0.05)
		co.tick(ms)
		if visto < 0 and co.valores.get("V12", -1.0) == 125.0:
			visto = ms - ms0
	t.comprobar(visto >= 0 and visto <= 2500, "comunicador: «Referencia» se ve en el deslizador en < 2,5 s (%d ms)" % visto)
	en.free()
	co.free()
	# Formato hora del elemento Valor
	t.comprobar(WValor.leer_hora("16:30") == 1630 and WValor.leer_hora("930") == 930 and WValor.leer_hora("9.05") == 905, "valor hora: lectura de 16:30, 930 y 9.05")
	t.comprobar(WValor.leer_hora("25:00") == null and WValor.leer_hora("12:60") == null and WValor.leer_hora("abc") == null, "valor hora: horas no válidas")
	t.comprobar(WValor.texto_hora(930) == "09:30" and WValor.texto_hora(2200) == "22:00", "valor hora: se muestra HH:MM")
	# Proyecto Acuario V2
	var p := Proyecto.desde_archivo("res://proyectos/acuario_v2.acuaris.json")
	t.comprobar(p.errores.is_empty() and p.paginas().size() == 4 and p.datos.get("simulador") == "acuario_v2", "proyecto Acuario V2 válido con 4 páginas")
	for pin in ["V27", "V28", "V44", "V50", "V51", "V52", "V53", "V54", "V55", "V57", "V58", "V60", "V63", "V12", "V13", "V64", "V76", "V90", "V6"]:
		t.comprobar(p.todos_los_pines().has(pin), "Acuario V2 usa " + pin)
