class_name TemaEditor
extends RefCounted
## Tema oscuro del editor, coherente con la paleta de la app, escalado a la pantalla del PC.


static func caja(fondo: Color, radio: float, u: float, margen := Vector4(10, 6, 10, 6), borde := Color.TRANSPARENT) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fondo
	sb.set_corner_radius_all(roundi(radio * u))
	sb.corner_detail = 12
	sb.content_margin_left = margen.x * u
	sb.content_margin_top = margen.y * u
	sb.content_margin_right = margen.z * u
	sb.content_margin_bottom = margen.w * u
	if borde.a > 0:
		sb.border_color = borde
		sb.set_border_width_all(maxi(1, roundi(u)))
	return sb


static func crear(u: float) -> Theme:
	var t := Theme.new()
	t.default_font = Estilo.fuente(false)
	t.default_font_size = roundi(14 * u)
	var borde := Color("#1d3b50")
	var b_normal := caja(Color("#143247"), 8, u, Vector4(9, 6, 9, 6), borde)
	var b_hover := caja(Color("#1a4360"), 8, u, Vector4(9, 6, 9, 6), Estilo.AGUA)
	var b_pulsado := caja(Estilo.AGUA, 8, u, Vector4(9, 6, 9, 6))
	var b_desact := caja(Color("#0f2433"), 8, u, Vector4(9, 6, 9, 6), Color("#163044"))
	for clase in ["Button", "OptionButton", "ColorPickerButton", "MenuButton"]:
		t.set_stylebox("normal", clase, b_normal)
		t.set_stylebox("hover", clase, b_hover)
		t.set_stylebox("pressed", clase, b_pulsado)
		t.set_stylebox("hover_pressed", clase, b_pulsado)
		t.set_stylebox("disabled", clase, b_desact)
		t.set_stylebox("focus", clase, StyleBoxEmpty.new())
		t.set_color("font_color", clase, Estilo.TEXTO)
		t.set_color("font_hover_color", clase, Color.WHITE)
		t.set_color("font_pressed_color", clase, Estilo.FONDO_ABAJO)
		t.set_color("font_hover_pressed_color", clase, Estilo.FONDO_ABAJO)
		t.set_color("font_disabled_color", clase, Estilo.TEXTO_TENUE)
	var campo := caja(Color("#0a1c28"), 6, u, Vector4(8, 5, 8, 5), borde)
	var campo_foco := caja(Color("#0a1c28"), 6, u, Vector4(8, 5, 8, 5), Estilo.AGUA)
	t.set_stylebox("normal", "LineEdit", campo)
	t.set_stylebox("focus", "LineEdit", campo_foco)
	t.set_stylebox("read_only", "LineEdit", campo)
	t.set_color("font_color", "LineEdit", Estilo.TEXTO)
	t.set_color("caret_color", "LineEdit", Estilo.AGUA)
	t.set_color("selection_color", "LineEdit", Color(Estilo.AGUA, 0.35))
	t.set_stylebox("panel", "PanelContainer", caja(Color("#0f2433"), 12, u, Vector4(14, 14, 14, 14), borde))
	t.set_stylebox("panel", "PopupMenu", caja(Color("#10283a"), 8, u, Vector4(6, 6, 6, 6), borde))
	t.set_stylebox("hover", "PopupMenu", caja(Color("#1a4360"), 6, u))
	t.set_color("font_color", "PopupMenu", Estilo.TEXTO)
	t.set_color("font_hover_color", "PopupMenu", Color.WHITE)
	t.set_stylebox("panel", "TooltipPanel", caja(Color("#10283a"), 6, u, Vector4(8, 5, 8, 5), borde))
	t.set_color("font_color", "TooltipLabel", Estilo.TEXTO)
	t.set_color("font_color", "Label", Estilo.TEXTO)
	t.set_color("font_color", "CheckBox", Estilo.TEXTO)
	t.set_color("font_pressed_color", "CheckBox", Estilo.TEXTO)
	t.set_color("font_hover_color", "CheckBox", Color.WHITE)
	t.set_color("font_hover_pressed_color", "CheckBox", Color.WHITE)
	for e in ["normal", "hover", "pressed", "hover_pressed", "focus"]:
		t.set_stylebox(e, "CheckBox", StyleBoxEmpty.new())
	t.set_stylebox("tab_selected", "TabBar", caja(Color("#143247"), 8, u, Vector4(14, 6, 14, 6), Estilo.AGUA))
	t.set_stylebox("tab_unselected", "TabBar", caja(Color("#0d2333"), 8, u, Vector4(14, 6, 14, 6), borde))
	t.set_stylebox("tab_hovered", "TabBar", caja(Color("#123247"), 8, u, Vector4(14, 6, 14, 6), borde))
	t.set_color("font_selected_color", "TabBar", Color.WHITE)
	t.set_color("font_unselected_color", "TabBar", Estilo.TEXTO_SEC)
	t.set_color("font_hovered_color", "TabBar", Estilo.TEXTO)
	t.set_stylebox("panel", "AcceptDialog", caja(Color("#0f2433"), 0, u, Vector4(16, 16, 16, 16)))
	t.set_stylebox("embedded_border", "Window", caja(Color("#0f2433"), 10, u, Vector4(8, 32, 8, 8), borde))
	t.set_color("title_color", "Window", Estilo.TEXTO)
	t.set_constant("separation", "VSeparator", roundi(10 * u))
	return t
