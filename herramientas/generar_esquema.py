"""Genera acuaris/widgets/esquema.gd (catálogo de elementos) a partir de esta definición."""
import json
import sys

def P(clave, nombre, tipo, defecto, opciones=None):
    d = {"clave": clave, "nombre": nombre, "tipo": tipo, "defecto": defecto}
    if opciones:
        d["opciones"] = opciones
    return d

ALINEACION = ["izquierda", "centro", "derecha"]
ALARMA = [P("limite_alto", "Límite alto", "texto", ""), P("limite_bajo", "Límite bajo", "texto", ""),
          P("color_alto", "Color si alto", "color", "#ff5a5f"), P("color_bajo", "Color si bajo", "color", "#2ec4d6")]
SEGURO = [P("confirmar", "Pedir confirmación", "bool", False), P("clave", "PIN (vacío = sin PIN)", "texto", "")]
RANGOS = ["15 min", "1 h", "6 h", "24 h", "7 d"]
# Listas: se editan en el inspector con casillas por línea, pero se guardan como texto (compatible).
PICTOS = ["bombilla", "ventilador", "bomba", "calentador", "valvula", "motor", "deposito", "termometro", "gota", "campana",
          "enchufe", "candado", "compresor", "power", "play", "stop", "reset", "flecha_arriba", "flecha_abajo"]
L_OPCIONES = {"filas": ",", "campos": ":", "columnas": [["Texto", "texto"], ["Valor", "numero"]]}
L_REGLAS = {"filas": ";", "campos": "|", "columnas": [["Condición", "texto"], ["Texto", "texto"], ["Color", "color"]]}
L_FILAS = {"filas": ";", "campos": "|", "columnas": [["Texto", "texto"], ["Pin", "pin"], ["Unidad", "texto"], ["Dec.", "numero"]]}
L_EVENTOS = {"filas": ";", "campos": "|", "columnas": [["Hora", "texto"], ["Días", "texto"], ["Valor", "numero"]]}

T = {}
def tipo(id_, nombre, w, h, pin, props, script):
    T[id_] = {"nombre": nombre, "w": w, "h": h, "pin": pin, "props": props, "script": script}

# ---------------------------------------------------------------- Visualización
tipo("valor", "Valor", 128, 60, "V1", [
    P("titulo", "Título", "texto", "Valor"), P("unidad", "Unidad", "texto", ""),
    P("decimales", "Decimales", "entero", 1), P("factor", "Factor", "numero", 1),
    P("tam", "Tamaño texto", "numero", 22), P("color", "Color", "color", "#e8f3fa"),
    P("alineacion", "Alineación", "opcion", "centro", ALINEACION), P("con_fondo", "Con fondo", "bool", True),
    P("editable", "Editable al tocar", "bool", False), P("formato", "Formato", "opcion", "numero", ["numero", "hora"])] + ALARMA + SEGURO, "w_valor")
tipo("valor_editable", "Valor editable", 128, 60, "V1", [
    P("titulo", "Título", "texto", "Consigna"), P("unidad", "Unidad", "texto", ""),
    P("decimales", "Decimales", "entero", 1), P("tam", "Tamaño texto", "numero", 22),
    P("color", "Color", "color", "#ffc145"), P("alineacion", "Alineación", "opcion", "centro", ALINEACION),
    P("con_fondo", "Con fondo", "bool", True), P("editable", "Editable al tocar", "bool", True),
    P("formato", "Formato", "opcion", "numero", ["numero", "hora"]),
    P("texto_cero", "Texto si vale 0 (vacío = mostrar 0)", "texto", "")] + SEGURO, "w_valor")
tipo("led", "LED", 200, 40, "V1", [
    P("texto", "Texto", "texto", "Piloto"), P("texto_on", "Texto encendido", "texto", "ON"),
    P("texto_off", "Texto apagado", "texto", "OFF"), P("color_on", "Color encendido", "color", "#3ddc84"),
    P("color_off", "Color apagado", "color", "#26465c"), P("umbral", "Umbral", "numero", 0.5),
    P("radio", "Radio (dp)", "numero", 11), P("vertical", "Texto en dos líneas", "bool", False),
    P("con_fondo", "Con fondo", "bool", False)], "w_led")
tipo("indicador_dibujo", "Indicador con dibujo", 96, 120, "V1", [
    P("dibujo", "Dibujo", "opcion", "bombilla", PICTOS), P("texto", "Texto", "texto", "Luz"),
    P("texto_on", "Texto activo", "texto", "ON"), P("texto_off", "Texto inactivo", "texto", "OFF"),
    P("condicion", "Activo si", "texto", ">= 0.5"), P("color_on", "Color activo", "color", "#ffc145"),
    P("color_off", "Color inactivo", "color", "#4a6a80"), P("min", "Mínimo (depósito/termómetro)", "numero", 0),
    P("max", "Máximo (depósito/termómetro)", "numero", 100), P("velocidad", "Velocidad de giro", "numero", 1),
    P("con_fondo", "Con fondo", "bool", False)], "w_dibujo")
tipo("estado", "Texto de estado", 200, 56, "V1", [
    P("titulo", "Título", "texto", "Estado"),
    P("reglas", "Reglas", "lista", "==0|Apagado|#5d8299; ==1|En marcha|#3ddc84; >1|Alarma|#ff5a5f", L_REGLAS),
    P("defecto", "Texto si no se cumple", "texto", "?"), P("tam", "Tamaño texto", "numero", 18),
    P("alineacion", "Alineación", "opcion", "centro", ALINEACION), P("con_fondo", "Con fondo", "bool", True)], "w_estado")
tipo("indicador", "Indicador", 200, 200, "V1", [
    P("titulo", "Título", "texto", ""), P("unidad", "Unidad", "texto", ""),
    P("min", "Mínimo", "numero", 0), P("max", "Máximo", "numero", 100),
    P("decimales", "Decimales", "entero", 1), P("pin_consigna", "Pin consigna", "pin", ""),
    P("tolerancia", "Tolerancia", "numero", 0.5), P("color", "Color", "color", "#2ec4d6"),
    P("tam", "Tamaño texto", "numero", 34)] + ALARMA, "w_indicador")
tipo("manometro", "Manómetro (aguja)", 200, 200, "V1", [
    P("titulo", "Título", "texto", ""), P("unidad", "Unidad", "texto", "bar"),
    P("min", "Mínimo", "numero", 0), P("max", "Máximo", "numero", 10),
    P("decimales", "Decimales", "entero", 1), P("decimales_escala", "Decimales escala", "entero", 0),
    P("divisiones", "Divisiones", "entero", 10), P("zona_verde", "Verde hasta", "numero", 6),
    P("zona_ambar", "Ámbar hasta", "numero", 8), P("sin_zonas", "Sin zonas de color", "bool", False),
    P("color_aguja", "Color aguja", "color", "#ff5a5f")] + ALARMA, "w_manometro")
tipo("barra", "Barra", 240, 48, "V1", [
    P("titulo", "Título", "texto", "Nivel"), P("min", "Mínimo", "numero", 0), P("max", "Máximo", "numero", 100),
    P("mostrar", "Mostrar", "opcion", "valor", ["valor", "porcentaje"]), P("unidad", "Unidad", "texto", ""),
    P("decimales", "Decimales", "entero", 0), P("color", "Color", "color", "#ffd166"),
    P("escala", "Con escala", "bool", False)] + ALARMA, "w_barra")
tipo("barra_escala", "Barra con escala", 240, 64, "V1", [
    P("titulo", "Título", "texto", "Nivel"), P("min", "Mínimo", "numero", 0), P("max", "Máximo", "numero", 100),
    P("mostrar", "Mostrar", "opcion", "valor", ["valor", "porcentaje"]), P("unidad", "Unidad", "texto", ""),
    P("decimales", "Decimales", "entero", 0), P("color", "Color", "color", "#2ec4d6"),
    P("escala", "Con escala", "bool", True)] + ALARMA, "w_barra")
tipo("barra_vertical", "Barra vertical", 80, 220, "V1", [
    P("titulo", "Título", "texto", "Temp."), P("unidad", "Unidad", "texto", "°C"),
    P("min", "Mínimo", "numero", 0), P("max", "Máximo", "numero", 40), P("decimales", "Decimales", "entero", 1),
    P("decimales_escala", "Decimales escala", "entero", 0), P("degradado", "Degradado", "bool", True),
    P("color_inicio", "Color abajo", "color", "#2ec4d6"), P("color_fin", "Color arriba", "color", "#ff5a5f"),
    P("color", "Color fijo", "color", "#2ec4d6")] + ALARMA, "w_barra_vertical")
tipo("giratorio", "Icono giratorio", 100, 116, "V1", [
    P("titulo", "Título", "texto", "Bomba"), P("icono", "Icono", "opcion", "bomba", ["bomba", "ventilador", "rueda"]),
    P("min", "Parado en", "numero", 0), P("max", "Máxima velocidad en", "numero", 1),
    P("color", "Color", "color", "#2ec4d6")] + ALARMA, "w_giratorio")
tipo("segmentos", "Segmentos", 160, 64, "V1", [
    P("titulo", "Título", "texto", "Señal"), P("min", "Mínimo", "numero", 0), P("max", "Máximo", "numero", 100),
    P("segmentos", "Segmentos", "entero", 5), P("umbral_malo", "Umbral malo", "numero", 25),
    P("umbral_regular", "Umbral regular", "numero", 50), P("escalera", "Forma de escalera", "bool", True),
    P("unidad", "Unidad", "texto", "%"), P("decimales", "Decimales", "entero", 0)], "w_segmentos")
tipo("imagen", "Imagen", 160, 120, "V1", [
    P("imagen", "Imagen", "imagen", ""), P("imagen_activa", "Imagen si se cumple", "imagen", ""),
    P("condicion", "Condición", "texto", ">= 0.5"), P("ajuste", "Ajuste", "opcion", "contener", ["contener", "cubrir"])], "w_imagen")
tipo("reloj", "Reloj", 280, 60, "", [
    P("titulo", "Título", "texto", "Hora"), P("pin_h", "Pin horas", "pin", "V2"), P("pin_m", "Pin minutos", "pin", "V3"),
    P("pin_s", "Pin segundos", "pin", "V4"), P("tam", "Tamaño texto", "numero", 28), P("con_fondo", "Con fondo", "bool", True)], "w_reloj")
tipo("etiqueta", "Texto", 200, 28, "", [
    P("texto", "Texto", "texto", "Texto"), P("tam", "Tamaño", "numero", 14), P("color", "Color", "color", "#e8f3fa"),
    P("alineacion", "Alineación", "opcion", "izquierda", ALINEACION), P("negrita", "Negrita", "bool", False)], "w_etiqueta")
tipo("panel", "Panel", 352, 160, "", [
    P("titulo", "Título", "texto", "Panel"), P("subtitulo", "Subtítulo", "texto", ""),
    P("fondo", "Color fondo", "color", "#10314a"), P("borde", "Color borde", "color", "#1d4a68"),
    P("radio", "Radio esquinas", "numero", 16)], "w_panel")

# ---------------------------------------------------------------- Control
tipo("interruptor", "Interruptor", 240, 36, "V1", [
    P("texto", "Texto", "texto", "Interruptor"), P("texto_on", "Detalle activado", "texto", ""),
    P("texto_off", "Detalle desactivado", "texto", ""), P("color_on", "Color activado", "color", "#2ec4d6")] + SEGURO, "w_interruptor")
tipo("interruptor_luz", "Interruptor con luz", 260, 44, "V1", [
    P("texto", "Texto", "texto", "Bomba"), P("texto_on", "Detalle activado", "texto", ""),
    P("texto_off", "Detalle desactivado", "texto", ""), P("color_on", "Color activado", "color", "#2ec4d6"),
    P("pin_luz", "Pin de la luz (estado real; vacío = el propio)", "pin", ""), P("color_luz", "Color de la luz", "color", "#3ddc84")] + SEGURO, "w_interruptor")
tipo("interruptor_seguro", "Interruptor seguro", 240, 36, "V1", [
    P("texto", "Texto", "texto", "Calentador"), P("texto_on", "Detalle activado", "texto", ""),
    P("texto_off", "Detalle desactivado", "texto", ""), P("color_on", "Color activado", "color", "#ff8a3d"),
    P("confirmar", "Pedir confirmación", "bool", True), P("clave", "PIN (vacío = sin PIN)", "texto", "")], "w_interruptor")
tipo("pulsador", "Pulsador", 120, 48, "V1", [
    P("texto", "Texto", "texto", "Pulsar"), P("modo", "Modo", "opcion", "conmutado", ["conmutado", "momentaneo", "valor"]),
    P("valor", "Valor a enviar", "numero", 1), P("color", "Color", "color", "#2ec4d6"),
    P("tam", "Tamaño texto", "numero", 15), P("radio", "Radio esquinas", "numero", 14)] + SEGURO, "w_pulsador")
tipo("pulsador_seguro", "Pulsador seguro", 120, 48, "V1", [
    P("texto", "Texto", "texto", "Reset"), P("modo", "Modo", "opcion", "valor", ["conmutado", "momentaneo", "valor"]),
    P("valor", "Valor a enviar", "numero", 1), P("color", "Color", "color", "#ff5a5f"),
    P("tam", "Tamaño texto", "numero", 15), P("radio", "Radio esquinas", "numero", 14),
    P("confirmar", "Pedir confirmación", "bool", True), P("clave", "PIN (vacío = sin PIN)", "texto", "1234")], "w_pulsador")
tipo("boton", "Botón personalizable", 140, 52, "V1", [
    P("texto", "Texto", "texto", "Marcha"), P("modo", "Modo", "opcion", "conmutado", ["conmutado", "momentaneo", "valor"]),
    P("valor", "Valor a enviar", "numero", 1), P("forma", "Forma", "opcion", "redondeado", ["rectangulo", "redondeado", "pildora", "circulo"]),
    P("radio", "Radio esquinas (redondeado)", "numero", 14), P("color_fondo", "Color de fondo", "color", "#10314a"),
    P("color_texto", "Color de la letra", "color", "#e8f4fa"), P("color_borde", "Color del borde", "color", "#2ec4d6"),
    P("ancho_borde", "Grosor del borde (0 = sin)", "numero", 1.5), P("color_activo", "Fondo activo / pulsado", "color", "#2ec4d6"),
    P("color_texto_activo", "Letra activa / pulsada", "color", "#06131d"), P("tam", "Tamaño texto", "numero", 15),
    P("negrita", "Negrita", "bool", True), P("icono", "Icono", "opcion", "ninguno", ["ninguno"] + PICTOS),
    P("imagen", "Imagen de fondo (opcional)", "imagen", "")] + SEGURO, "w_pulsador")
tipo("casilla", "Casilla", 200, 36, "V1", [
    P("texto", "Texto", "texto", "Activar"), P("valor_on", "Valor marcada", "numero", 1),
    P("valor_off", "Valor desmarcada", "numero", 0), P("color", "Color", "color", "#2ec4d6")] + SEGURO, "w_casilla")
tipo("opciones", "Opciones", 180, 108, "V1", [
    P("opciones", "Opciones", "lista", "Apagado:0, Auto:1, Manual:2", L_OPCIONES),
    P("color", "Color", "color", "#2ec4d6")] + SEGURO, "w_opciones")
tipo("grupo_botones", "Grupo de botones", 300, 44, "V1", [
    P("opciones", "Opciones", "lista", "Off:0, Auto:1, Manual:2", L_OPCIONES),
    P("color", "Color", "color", "#2ec4d6")] + SEGURO, "w_opciones")
tipo("selector", "Selector giratorio", 150, 160, "V1", [
    P("titulo", "Título", "texto", "Velocidad"), P("opciones", "Posiciones", "lista", "Off:0, 1:1, 2:2, 3:3", L_OPCIONES),
    P("color", "Color", "color", "#2ec4d6")] + SEGURO, "w_selector")
tipo("potenciometro", "Potenciómetro", 150, 166, "V1", [
    P("titulo", "Título", "texto", "Intensidad"), P("min", "Mínimo", "numero", 0), P("max", "Máximo", "numero", 255),
    P("paso", "Paso", "numero", 1), P("unidad", "Unidad", "texto", ""), P("decimales", "Decimales", "entero", 0),
    P("color", "Color", "color", "#ffd166")] + SEGURO, "w_potenciometro")
tipo("deslizador", "Deslizador", 240, 56, "V1", [
    P("titulo", "Título", "texto", "Ajuste"), P("min", "Mínimo", "numero", 0), P("max", "Máximo", "numero", 100),
    P("paso", "Paso", "numero", 1), P("unidad", "Unidad", "texto", ""), P("decimales", "Decimales", "entero", 0),
    P("color", "Color", "color", "#2ec4d6"), P("vertical", "Vertical", "bool", False),
    P("en_vivo", "Enviar mientras se arrastra", "bool", False)] + SEGURO, "w_deslizador")
tipo("deslizador_v", "Deslizador vertical", 72, 220, "V1", [
    P("titulo", "Título", "texto", "Nivel"), P("min", "Mínimo", "numero", 0), P("max", "Máximo", "numero", 100),
    P("paso", "Paso", "numero", 1), P("unidad", "Unidad", "texto", ""), P("decimales", "Decimales", "entero", 0),
    P("color", "Color", "color", "#2ec4d6"), P("vertical", "Vertical", "bool", True),
    P("en_vivo", "Enviar mientras se arrastra", "bool", False)] + SEGURO, "w_deslizador")

# ---------------------------------------------------------------- Gráficas y especiales
tipo("grafica", "Gráfica", 352, 200, "V1", [
    P("titulo", "Título", "texto", "Temperatura"), P("rango", "Rango inicial", "opcion", "1 h", RANGOS),
    P("min", "Mínimo (vacío = auto)", "texto", ""), P("max", "Máximo (vacío = auto)", "texto", ""),
    P("decimales", "Decimales", "entero", 1), P("color", "Color", "color", "#2ec4d6")], "w_grafica")
tipo("grafica_avanzada", "Gráfica avanzada", 352, 220, "V1", [
    P("titulo", "Título", "texto", "Comparativa"), P("pin_2", "Pin 2", "pin", ""), P("pin_3", "Pin 3", "pin", ""),
    P("rango", "Rango inicial", "opcion", "6 h", RANGOS), P("min", "Mínimo (vacío = auto)", "texto", ""),
    P("max", "Máximo (vacío = auto)", "texto", ""), P("decimales", "Decimales", "entero", 1),
    P("color", "Color 1", "color", "#2ec4d6"), P("color_2", "Color 2", "color", "#ffc145"), P("color_3", "Color 3", "color", "#3ddc84"),
    P("nombre", "Nombre 1 (leyenda)", "texto", ""), P("nombre_2", "Nombre 2", "texto", ""), P("nombre_3", "Nombre 3", "texto", ""),
    P("unidad", "Unidad", "texto", ""), P("viva", "Curva suave, relleno y punto vivo", "bool", False),
    P("pin_franja", "Franja: centro (p. ej. consigna)", "pin", ""), P("pin_franja_ancho", "Franja: ± ancho (p. ej. histéresis)", "pin", ""),
    P("pin_actividad", "Zonas de actividad (p. ej. calentador)", "pin", ""), P("color_actividad", "Color de actividad", "color", "#ff8a3d"),
    P("pin_limite_alto", "Línea de alarma alta", "pin", ""), P("pin_limite_bajo", "Línea de alarma baja", "pin", "")], "w_grafica")
tipo("grafica_emergente", "Gráfica emergente", 220, 56, "V1", [
    P("titulo", "Título", "texto", "Historial"), P("pin_2", "Pin 2", "pin", ""), P("pin_3", "Pin 3", "pin", ""),
    P("unidad", "Unidad", "texto", ""), P("decimales", "Decimales", "entero", 1), P("rango", "Rango inicial", "opcion", "6 h", RANGOS),
    P("color", "Color", "color", "#2ec4d6")], "w_grafica_emergente")
tipo("historial_tabla", "Historial (tabla)", 220, 56, "V1", [
    P("titulo", "Título", "texto", "Datos guardados"), P("dias", "Días a mostrar", "numero", 1),
    P("unidad", "Unidad", "texto", ""), P("decimales", "Decimales", "entero", 1), P("color", "Color", "color", "#2ec4d6")], "w_historial_tabla")
tipo("tabla", "Tabla de valores", 300, 140, "", [
    P("titulo", "Título", "texto", "Resumen"),
    P("filas", "Filas", "lista", "Temperatura|V35|°C|1; Consigna|V27|°C|1; Bomba|V8||0", L_FILAS)], "w_tabla")
tipo("estado_dispositivo", "Estado del controlador", 240, 52, "", [
    P("titulo", "Título", "texto", "Controlador"), P("segundos", "Sin respuesta tras (s)", "numero", 10)], "w_estado_dispositivo")
tipo("regla", "Regla automática", 300, 52, "V1", [
    P("titulo", "Título", "texto", "Regla"), P("condicion", "Condición", "texto", "> 28"),
    P("pin_destino", "Pin destino", "pin", "V16"), P("valor", "Valor si se cumple", "numero", 0),
    P("valor_si_no", "Valor si deja de cumplirse (vacío = nada)", "texto", ""), P("al_iniciar", "Actuar también al abrir", "bool", False)], "w_regla")
tipo("programador", "Programador horario", 300, 110, "V16", [
    P("titulo", "Título", "texto", "Horario"), P("eventos", "Eventos", "lista", "08:00|LMXJV|1; 22:00|*|0", L_EVENTOS)], "w_programador")
tipo("mapa", "Mapa (posición)", 300, 200, "", [
    P("pin_lat", "Pin latitud", "pin", "V50"), P("pin_lon", "Pin longitud", "pin", "V51"), P("radio_m", "Radio visible (m)", "numero", 200)], "w_mapa")

# ---------------------------------------------------------------- Hidráulica
TUBO = [P("tubo", "Grosor tubo (dp)", "numero", 18), P("color_tubo", "Color tubo", "color", "#5f7c8e"),
        P("color_liquido", "Color líquido", "color", "#2ec4d6")]
CAUDAL = [P("min", "Parado en", "numero", 0), P("max", "Máximo en", "numero", 1), P("invertir", "Invertir sentido", "bool", False)]
COND = [P("condicion", "Activo si", "texto", ">= 0.5")]
ORIENT = [P("orientacion", "Orientación (0-3)", "entero", 0)]
ETQ = [P("etiqueta", "Etiqueta", "texto", "")]
tipo("deposito", "Depósito", 140, 180, "V1", [
    P("forma", "Forma", "opcion", "redondeado", ["redondeado", "caja", "cilindro", "barril", "conico"]),
    P("min", "Vacío en", "numero", 0), P("max", "Lleno en", "numero", 100),
    P("mostrar", "Mostrar", "opcion", "porcentaje", ["porcentaje", "valor"]), P("unidad", "Unidad", "texto", "L"),
    P("decimales", "Decimales", "entero", 0)] + TUBO + ETQ, "w_hidraulica")
tipo("tuberia_h", "Tubería horizontal", 120, 40, "V1", TUBO + CAUDAL, "w_hidraulica")
tipo("tuberia_v", "Tubería vertical", 40, 120, "V1", TUBO + CAUDAL, "w_hidraulica")
tipo("acoplamiento", "Acoplamiento", 60, 40, "V1", TUBO + CAUDAL, "w_hidraulica")
tipo("codo", "Codo", 40, 40, "V1", TUBO + CAUDAL + ORIENT, "w_hidraulica")
tipo("te", "Te", 60, 40, "V1", TUBO + CAUDAL + ORIENT, "w_hidraulica")
tipo("cruz", "Cruz", 40, 40, "V1", TUBO + CAUDAL, "w_hidraulica")
tipo("reduccion", "Reducción", 60, 40, "V1", TUBO + [P("tubo_2", "Grosor salida (dp)", "numero", 10)] + CAUDAL, "w_hidraulica")
tipo("valvula_2v", "Válvula 2 vías", 80, 60, "V1", TUBO + COND + ETQ, "w_hidraulica")
tipo("valvula_3v", "Válvula 3 vías", 80, 60, "V1", TUBO + ORIENT + ETQ, "w_hidraulica")
tipo("acoplamiento_eje", "Acoplamiento con eje", 60, 60, "V1", TUBO + CAUDAL, "w_hidraulica")
tipo("bomba_h", "Bomba", 100, 60, "V1", TUBO + CAUDAL + ETQ, "w_hidraulica")
tipo("antirretorno", "Válvula antirretorno", 80, 40, "V1", TUBO + COND + [P("invertir", "Invertir sentido", "bool", False)], "w_hidraulica")
tipo("caudalimetro", "Caudalímetro", 80, 60, "V1", TUBO + CAUDAL + ETQ, "w_hidraulica")
tipo("volante", "Volante", 40, 40, "V1", TUBO + COND, "w_hidraulica")
tipo("maneta", "Maneta", 40, 40, "V1", TUBO + COND, "w_hidraulica")
tipo("motor", "Motor", 40, 48, "V1", TUBO + COND, "w_hidraulica")
tipo("solenoide", "Solenoide", 32, 44, "V1", TUBO + COND, "w_hidraulica")
tipo("manometro_peq", "Manómetro de línea", 44, 52, "V1", TUBO + [P("min", "Mínimo", "numero", 0), P("max", "Máximo", "numero", 10), P("decimales", "Decimales", "entero", 1)], "w_hidraulica")
tipo("sensor", "Sensor", 40, 48, "V1", TUBO + [P("etiqueta", "Etiqueta", "texto", "TT")], "w_hidraulica")
tipo("agitador", "Agitador", 60, 100, "V1", TUBO + COND, "w_hidraulica")
tipo("chorro", "Chorro de salida", 30, 80, "V1", TUBO + COND, "w_hidraulica")

# ---------------------------------------------------------------- Neumática
NC = [P("condicion", "Activo si", "texto", ">= 0.5"), P("color", "Color con aire", "color", "#4da3ff")]
CIL = [P("etiqueta", "Etiqueta", "texto", "1A"), P("min", "Valor recogido", "numero", 0), P("max", "Valor extendido", "numero", 1),
       P("tiempo", "Tiempo de carrera (s)", "numero", 0.6), P("color", "Color con aire", "color", "#4da3ff"),
       P("pin_fin_a", "Detector recogido", "pin", ""), P("pin_fin_b", "Detector extendido", "pin", "")]
tipo("cilindro_de", "Cilindro doble efecto", 200, 80, "V1", CIL, "w_neumatica")
tipo("cilindro_se", "Cilindro simple efecto", 200, 80, "V1", CIL, "w_neumatica")
tipo("valvula_52", "Electroválvula 5/2", 150, 90, "V1", NC + [P("etiqueta", "Etiqueta", "texto", "1V1")], "w_neumatica")
tipo("valvula_32", "Electroválvula 3/2", 150, 90, "V1", NC + [P("etiqueta", "Etiqueta", "texto", "1V2")], "w_neumatica")
tipo("compresor_n", "Compresor", 70, 70, "V1", NC, "w_neumatica")
tipo("frl", "Unidad FRL", 180, 70, "V1", NC, "w_neumatica")
tipo("silenciador", "Silenciador", 30, 44, "V1", NC, "w_neumatica")
tipo("ventosa", "Ventosa de vacío", 70, 80, "V1", NC, "w_neumatica")
tipo("pinza", "Pinza neumática", 80, 90, "V1", NC, "w_neumatica")
tipo("detector", "Detector magnético", 70, 44, "V1", NC + [P("etiqueta", "Etiqueta", "texto", "1S1")], "w_neumatica")
tipo("linea_h", "Línea neumática horizontal", 120, 20, "V1", NC + [P("grosor", "Grosor (dp)", "numero", 3), P("pilotaje", "Línea de pilotaje (discontinua)", "bool", False)], "w_neumatica")
tipo("linea_v", "Línea neumática vertical", 20, 120, "V1", NC + [P("grosor", "Grosor (dp)", "numero", 3), P("pilotaje", "Línea de pilotaje (discontinua)", "bool", False)], "w_neumatica")

GRUPOS = [
    ["Visualización", ["valor", "valor_editable", "led", "indicador_dibujo", "estado", "indicador", "manometro", "barra", "barra_escala",
                       "barra_vertical", "giratorio", "segmentos", "imagen", "reloj", "etiqueta", "panel"]],
    ["Control", ["interruptor", "interruptor_luz", "interruptor_seguro", "pulsador", "pulsador_seguro", "boton", "casilla", "opciones",
                 "grupo_botones", "selector", "potenciometro", "deslizador", "deslizador_v"]],
    ["Gráficas y especiales", ["grafica", "grafica_avanzada", "grafica_emergente", "historial_tabla", "tabla",
                               "estado_dispositivo", "regla", "programador", "mapa"]],
    ["Hidráulica", ["deposito", "tuberia_h", "tuberia_v", "acoplamiento", "codo", "te", "cruz", "reduccion",
                    "valvula_2v", "valvula_3v", "acoplamiento_eje", "bomba_h", "antirretorno", "caudalimetro",
                    "volante", "maneta", "motor", "solenoide", "manometro_peq", "sensor", "agitador", "chorro"]],
    ["Neumática", ["cilindro_de", "cilindro_se", "valvula_52", "valvula_32", "compresor_n", "frl", "silenciador",
                   "ventosa", "pinza", "detector", "linea_h", "linea_v"]],
]
todos = [t for g in GRUPOS for t in g[1]]
assert sorted(todos) == sorted(T.keys()), set(T.keys()) ^ set(todos)
assert len(set(todos)) == len(todos)

def gd(v, ind=0):
    return json.dumps(v, ensure_ascii=False, indent="\t").replace("\n", "\n" + "\t" * ind)

out = '''class_name Esquema
extends RefCounted
## Catálogo de elementos: nombre visible, tamaño inicial (dp), script y propiedades editables.
## Lo usan la paleta, el inspector, la fábrica y la creación de elementos nuevos.
## ARCHIVO GENERADO: se edita herramientas/generar_esquema.py y se ejecuta
##   python3 herramientas/generar_esquema.py acuaris/widgets/esquema.gd
##
## Tipos de propiedad: "texto", "numero", "entero", "color", "bool", "opcion", "pin", "imagen" y "lista"
## (varias líneas con casillas; se guarda como texto con los separadores de "opciones").

const GRUPOS := %s

const ORDEN := %s

const TIPOS := %s


static func info(tipo: String) -> Dictionary:
	return TIPOS.get(tipo, {})


static func usa_pin(tipo: String) -> bool:
	return info(tipo).get("pin", "") != ""


## Definición nueva de un elemento con sus valores por defecto.
static func crear(tipo: String, id: String, x: float, y: float) -> Dictionary:
	var i := info(tipo)
	var props := {}
	for p in i.get("props", []):
		if str(p.defecto) != "" or p.tipo == "texto":
			props[p.clave] = p.defecto
	var d := {"id": id, "tipo": tipo, "x": x, "y": y, "w": i.get("w", 100), "h": i.get("h", 40), "props": props}
	if usa_pin(tipo):
		d["pin"] = i.pin
	return d
''' % (gd(GRUPOS), gd(todos), gd(T))
open(sys.argv[1], "w", encoding="utf-8").write(out)
print(len(T), "tipos")
