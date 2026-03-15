extends Node
class_name ForfeitManager


# ============================================================
# ForfeitManager.gd
# Construye el botón "Abandonar" y su popup de confirmación.
# Emite forfeit_confirmed cuando el jugador confirma.
# ============================================================

signal forfeit_confirmed

const COLOR_GOLD     = Color(0.85, 0.72, 0.30)
const COLOR_GOLD_DIM = Color(0.55, 0.45, 0.18)
const COLOR_TEXT     = Color(0.92, 0.88, 0.75)

var _parent:          Node2D  = null
var _forfeit_btn:     Button  = null
var _forfeit_confirm: Control = null


# ============================================================
# SETUP
# ============================================================
func setup(parent: Node2D, viewport_size: Vector2) -> void:
	_parent = parent
	var W := viewport_size.x
	var H := viewport_size.y
	_build_forfeit_button(W, H)


# ============================================================
# BOTÓN PRINCIPAL
# ============================================================
func _build_forfeit_button(W: float, H: float) -> void:
	_forfeit_btn          = Button.new()
	_forfeit_btn.text     = "✕  Abandonar"
	_forfeit_btn.position = Vector2(14.0, 34.0)
	_forfeit_btn.size     = Vector2(260.0, 28.0)
	_forfeit_btn.z_index  = 10
	_forfeit_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	var s_n = StyleBoxFlat.new()
	s_n.bg_color     = Color(0.75, 0.08, 0.08, 1.0)
	s_n.border_color = Color(1.0, 0.20, 0.20, 1.0)
	s_n.border_width_left = 1; s_n.border_width_right  = 1
	s_n.border_width_top  = 1; s_n.border_width_bottom = 1
	s_n.corner_radius_top_left    = 5; s_n.corner_radius_top_right    = 5
	s_n.corner_radius_bottom_left = 5; s_n.corner_radius_bottom_right = 5
	_forfeit_btn.add_theme_stylebox_override("normal", s_n)

	var s_h = StyleBoxFlat.new()
	s_h.bg_color     = Color(0.95, 0.12, 0.12, 1.0)
	s_h.border_color = Color(1.0, 0.40, 0.40, 1.0)
	s_h.border_width_left = 1; s_h.border_width_right  = 1
	s_h.border_width_top  = 1; s_h.border_width_bottom = 1
	s_h.corner_radius_top_left    = 5; s_h.corner_radius_top_right    = 5
	s_h.corner_radius_bottom_left = 5; s_h.corner_radius_bottom_right = 5
	_forfeit_btn.add_theme_stylebox_override("hover", s_h)

	_forfeit_btn.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	_forfeit_btn.add_theme_font_size_override("font_size", 11)
	_forfeit_btn.pressed.connect(_on_forfeit_pressed)
	_parent.add_child(_forfeit_btn)


func _on_forfeit_pressed() -> void:
	if _forfeit_confirm and is_instance_valid(_forfeit_confirm): return
	_forfeit_confirm = _build_forfeit_confirm_popup()
	_parent.add_child(_forfeit_confirm)


func close_confirm() -> void:
	if _forfeit_confirm and is_instance_valid(_forfeit_confirm):
		_forfeit_confirm.queue_free()
		_forfeit_confirm = null


func has_confirm_open() -> bool:
	return _forfeit_confirm != null and is_instance_valid(_forfeit_confirm)


# ============================================================
# POPUP DE CONFIRMACIÓN
# ============================================================
func _build_forfeit_confirm_popup() -> Control:
	var vp    := _parent.get_viewport().get_visible_rect().size
	var popup := Control.new()
	popup.name    = "ForfeitConfirm"
	popup.set_anchors_preset(Control.PRESET_FULL_RECT)
	popup.z_index = 300

	var dim = ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.72)
	popup.add_child(dim)

	const PW := 360.0
	const PH := 168.0
	var panel = Panel.new()
	panel.position = Vector2((vp.x - PW) / 2.0, (vp.y - PH) / 2.0)
	panel.size     = Vector2(PW, PH)
	var ps = StyleBoxFlat.new()
	ps.bg_color     = Color(0.08, 0.05, 0.05, 0.98)
	ps.border_color = Color(0.80, 0.25, 0.25)
	ps.border_width_left = 2; ps.border_width_right  = 2
	ps.border_width_top  = 2; ps.border_width_bottom = 2
	ps.corner_radius_top_left    = 12; ps.corner_radius_top_right    = 12
	ps.corner_radius_bottom_left = 12; ps.corner_radius_bottom_right = 12
	ps.shadow_color = Color(0, 0, 0, 0.6); ps.shadow_size = 16
	panel.add_theme_stylebox_override("panel", ps)
	popup.add_child(panel)

	var title = Label.new()
	title.text     = "¿Abandonar la partida?"
	title.position = Vector2(0, 20)
	title.size     = Vector2(PW, 28)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(0.90, 0.35, 0.35))
	panel.add_child(title)

	var desc = Label.new()
	desc.text          = "Perderás la partida y recibirás\nla pantalla de derrota."
	desc.position      = Vector2(0, 58)
	desc.size          = Vector2(PW, 44)
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc.add_theme_font_size_override("font_size", 12)
	desc.add_theme_color_override("font_color", COLOR_TEXT)
	panel.add_child(desc)

	var confirm_btn = Button.new()
	confirm_btn.text     = "Sí, abandonar"
	confirm_btn.position = Vector2(PW / 2.0 - 158, PH - 50)
	confirm_btn.size     = Vector2(140, 34)
	confirm_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var cs = StyleBoxFlat.new()
	cs.bg_color     = Color(0.50, 0.07, 0.07, 0.90)
	cs.border_color = Color(0.90, 0.28, 0.28)
	cs.border_width_left = 1; cs.border_width_right  = 1
	cs.border_width_top  = 1; cs.border_width_bottom = 1
	cs.corner_radius_top_left    = 7; cs.corner_radius_top_right    = 7
	cs.corner_radius_bottom_left = 7; cs.corner_radius_bottom_right = 7
	var cs_h = cs.duplicate()
	cs_h.bg_color = Color(0.65, 0.10, 0.10, 0.95)
	confirm_btn.add_theme_stylebox_override("normal", cs)
	confirm_btn.add_theme_stylebox_override("hover",  cs_h)
	confirm_btn.add_theme_color_override("font_color", Color(1, 0.75, 0.75))
	confirm_btn.add_theme_font_size_override("font_size", 12)
	confirm_btn.pressed.connect(func():
		popup.queue_free()
		_forfeit_confirm = null
		emit_signal("forfeit_confirmed")
	)
	panel.add_child(confirm_btn)

	var cancel_btn = Button.new()
	cancel_btn.text     = "Cancelar"
	cancel_btn.position = Vector2(PW / 2.0 + 18, PH - 50)
	cancel_btn.size     = Vector2(140, 34)
	cancel_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var ns = StyleBoxFlat.new()
	ns.bg_color     = Color(0, 0, 0, 0)
	ns.border_color = COLOR_GOLD_DIM
	ns.border_width_left = 1; ns.border_width_right  = 1
	ns.border_width_top  = 1; ns.border_width_bottom = 1
	ns.corner_radius_top_left    = 7; ns.corner_radius_top_right    = 7
	ns.corner_radius_bottom_left = 7; ns.corner_radius_bottom_right = 7
	var ns_h = ns.duplicate()
	ns_h.bg_color     = Color(COLOR_GOLD_DIM.r, COLOR_GOLD_DIM.g, COLOR_GOLD_DIM.b, 0.12)
	ns_h.border_color = COLOR_GOLD
	cancel_btn.add_theme_stylebox_override("normal", ns)
	cancel_btn.add_theme_stylebox_override("hover",  ns_h)
	cancel_btn.add_theme_color_override("font_color", COLOR_TEXT)
	cancel_btn.add_theme_font_size_override("font_size", 12)
	cancel_btn.pressed.connect(func():
		popup.queue_free()
		_forfeit_confirm = null
	)
	panel.add_child(cancel_btn)

	panel.modulate.a = 0.0
	panel.scale      = Vector2(0.88, 0.88)
	var tw = panel.create_tween()
	tw.set_parallel(true)
	tw.tween_property(panel, "modulate:a", 1.0,         0.18)
	tw.tween_property(panel, "scale",      Vector2.ONE, 0.20) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	return popup
