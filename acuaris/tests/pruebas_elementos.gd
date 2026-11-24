extends RefCounted
## Pruebas de los elementos nuevos: lógica (reglas, estados, programador, tabla, historial) y
## que todos los tipos del catálogo se crean y dibujan sin errores.

var t


func _init(ejecutor) -> void:
	t = ejecutor


func ejecutar() -> void:
	# Condiciones
	t.comprobar(AcWidget.cumple("> 80", 81) and not AcWidget.cumple("> 80", 80), "elementos: condición >")
	t.comprobar(AcWidget.cumple("==1", 1.0) and AcWidget.cumple("1", 1.0), "elementos: condición ==")
	t.comprobar(AcWidget.cumple("<= 0,5", 0.5) and AcWidget.cumple("!= 0", 2), "elementos: condición <= y !=")
	t.comprobar(not AcWidget.cumple("> abc", 5), "elementos: condición mal escrita no se cumple")
	# Catálogo completo
	var total := 0
	for g in Esquema.GRUPOS:
		total += g[1].size()
	t.comprobar(total == Esquema.ORDEN.size() and total == 72 and Esquema.GRUPOS.size() == 5, "elementos: 72 tipos en 5 grupos")
	for tipo in Esquema.ORDEN:
		var d := Esquema.crear(tipo, "e_" + tipo, 0, 0)
		var w := FabricaWidgets.crear(d, 2.0)
		t.comprobar(w != null, "elementos: se crea %s" % tipo)
		if w:
			for p in Proyecto.pines_de(d):
				w.recibir(AcWidget.normalizar(p), 1.0)
			w.free()
	# Texto de estado
	var est: WEstado = FabricaWidgets.crear(Esquema.crear("estado", "e", 0, 0), 1.0)
	est.recibir("V1", 0.0)
	t.comprobar(est._regla_activa()[0] == "Apagado", "elementos: estado ==0 → Apagado")
	est.recibir("V1", 5.0)
	t.comprobar(est._regla_activa()[0] == "Alarma", "elementos: estado >1 → Alarma")
	est.free()
	# Regla automática: escribe al pasar a cumplirse (no al abrir)
	var d_regla := Esquema.crear("regla", "r", 0, 0)
	d_regla.pin = "V35"
	d_regla.props.condicion = "> 28"
	d_regla.props.pin_destino = "V16"
	d_regla.props.valor = 0
	var regla: WRegla = FabricaWidgets.crear(d_regla, 1.0)
	var escritas: Array = []
	regla.escritura_solicitada.connect(func(p, v): escritas.append([p, v]))
	regla.recibir("V35", 29.0)
	t.comprobar(escritas.is_empty(), "elementos: regla no actúa al abrir")
	regla.recibir("V35", 27.0)
	regla.recibir("V35", 29.5)
	t.comprobar(escritas.size() == 1 and escritas[0] == ["V16", 0.0], "elementos: regla escribe al cumplirse")
	regla.recibir("V35", 30.0)
	t.comprobar(escritas.size() == 1, "elementos: regla no repite mientras sigue cumpliéndose")
	regla.free()
	# Programador horario
	var evs := WProgramador.eventos_de("07:30|LMXJV|1; 22:00|*|0; malo")
	t.comprobar(evs.size() == 2, "elementos: programador lee eventos")
	t.comprobar(WProgramador.toca(evs[0], {"hour": 7, "minute": 30, "weekday": 1}), "elementos: lunes 07:30 toca")
	t.comprobar(not WProgramador.toca(evs[0], {"hour": 7, "minute": 30, "weekday": 0}), "elementos: domingo no toca")
	t.comprobar(WProgramador.toca(evs[1], {"hour": 22, "minute": 0, "weekday": 6}), "elementos: * toca todos los días")
	# Tabla
	var filas := WTabla.filas_de("Temperatura|v35|°C|1; Bomba|V8||0")
	t.comprobar(filas.size() == 2 and filas[0][1] == "V35" and filas[1][3] == 0, "elementos: tabla lee filas")
	var d_tab := Esquema.crear("tabla", "tb", 0, 0)
	t.comprobar(Proyecto.pines_de(d_tab).has("V35"), "elementos: los pines de la tabla se sondean")
	# Opciones
	var d_op := Esquema.crear("grupo_botones", "g", 0, 0)
	var op: WOpciones = FabricaWidgets.crear(d_op, 1.0)
	t.comprobar(op.opciones_prop() == [["Off", 0.0], ["Auto", 1.0], ["Manual", 2.0]], "elementos: opciones texto:valor")
	op.free()
	# Historial
	Historial.borrar_todo()
	Historial.reloj_externo = 1000.0
	Historial.anotar("V35", 25.0)
	Historial.reloj_externo = 1002.0
	Historial.anotar("V35", 26.0)
	t.comprobar(Historial.serie("V35", 3600)[0].size() == 1, "elementos: historial guarda una muestra cada 5 s")
	Historial.reloj_externo = 1010.0
	Historial.anotar("V35", 27.0)
	t.comprobar(Historial.serie("V35", 3600)[1] == PackedFloat32Array([25.0, 27.0]), "elementos: historial ordenado")
	t.comprobar(Historial.serie("V35", 5)[0].size() == 1, "elementos: historial por rango")
	t.comprobar(Historial.csv("V35", 3600).split("\n").size() == 3, "elementos: exportar CSV")
	Historial.reloj_externo = -1.0
	Historial.borrar_todo()
