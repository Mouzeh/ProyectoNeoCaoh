extends Node

# ============================================================
# QueueScreen.gd
# ============================================================

static func build(container: Control, menu) -> void:
	var C = menu

	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	container.add_child(center)

	var vp = container.get_viewport().get_visible_rect().size
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(clamp(vp.x * 0.40, 400, 540), 0)
	var ps = StyleBoxFlat.new()
	ps.bg_color   = C.COLOR_PANEL
	ps.border_color = Color(C.COLOR_GOLD_DIM.r, C.COLOR_GOLD_DIM.g, C.COLOR_GOLD_DIM.b, 0.55)
	ps.border_width_left = 1; ps.border_width_right  = 1
	ps.border_width_top  = 1; ps.border_width_bottom = 1
	ps.corner_radius_top_left     = 10; ps.corner_radius_top_right    = 10
	ps.corner_radius_bottom_left  = 10; ps.corner_radius_bottom_right = 10
	ps.shadow_color = Color(0,0,0,0.5); ps.shadow_size = 12
	panel.add_theme_stylebox_override("panel", ps)
	center.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 0)
	panel.add_child(vbox)

	vbox.add_child(UITheme.color_strip(C.COLOR_ACCENT, 6, true))

	var body = MarginContainer.new()
	body.add_theme_constant_override("margin_left",   40)
	body.add_theme_constant_override("margin_right",  40)
	body.add_theme_constant_override("margin_top",    20)
	body.add_theme_constant_override("margin_bottom", 20)
	vbox.add_child(body)

	var inner = VBoxContainer.new()
	inner.add_theme_constant_override("separation", 12)
	body.add_child(inner)

	var active_name = PlayerData.get_deck_name(PlayerData.active_deck_slot)

	inner.add_child(UITheme.clbl("ESPERANDO RIVAL...", 20, C.COLOR_GOLD))
	inner.add_child(UITheme.clbl("Tu mesa está lista. Esperando a que alguien se una.", 11, C.COLOR_TEXT_DIM))
	inner.add_child(UITheme.pill("🃏  " + active_name, Color(0.10, 0.14, 0.10), C.COLOR_GREEN, 30))

	var dots = UITheme.clbl("◆  ◇  ◇", 26, C.COLOR_GOLD)
	dots.name = "Dots"
	inner.add_child(dots)
	inner.add_child(UITheme.divider())

	var cancel_btn = UITheme.btn("CANCELAR MESA", C.COLOR_RED, 48, 13)
	cancel_btn.pressed.connect(func():
		NetworkManager.leave_room()
		menu._show_screen(menu.Screen.LOBBY)
	)
	inner.add_child(cancel_btn)

	_animate_dots(dots, container)


static var _dot_frames: Array = ["◆  ◇  ◇","◆  ◆  ◇","◆  ◆  ◆","◇  ◆  ◆","◇  ◇  ◆","◇  ◇  ◇"]
static var _dot_idx:    int   = 0

static func _animate_dots(lbl: Label, _container: Control) -> void:
	_dot_idx = 0
	lbl.text = _dot_frames[0]
	
	# Creamos un Timer real y lo hacemos hijo del Label
	var timer = Timer.new()
	timer.wait_time = 0.35
	timer.autostart = true
	lbl.add_child(timer)
	
	# Al ser hijo, si la pantalla desaparece al iniciar la partida, el Timer se destruye solo.
	timer.timeout.connect(func():
		_dot_idx += 1
		lbl.text = _dot_frames[_dot_idx % _dot_frames.size()]
	)
