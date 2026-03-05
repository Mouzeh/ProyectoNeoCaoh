extends Node

# ============================================================
# SettingsScreen.gd
# ============================================================

static func build(container: Control, menu) -> void:
	var C = menu

	# ── Fondo ──
	var bg_image = TextureRect.new()
	var bg_tex = load("res://assets/imagen/fondomenu.png")
	if bg_tex: bg_image.texture = bg_tex
	bg_image.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_image.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	bg_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg_image.modulate = Color(0.3, 0.3, 0.3, 1)
	container.add_child(bg_image)

	# ── Header ──
	var header = Panel.new()
	header.anchor_left = 0; header.anchor_right  = 1
	header.anchor_top  = 0; header.anchor_bottom = 0
	header.offset_top  = 50; header.offset_bottom = 120
	var hs = StyleBoxFlat.new()
	hs.bg_color = Color(C.COLOR_PANEL.r, C.COLOR_PANEL.g, C.COLOR_PANEL.b, 0.85)
	hs.border_color = Color(C.COLOR_GOLD_DIM.r, C.COLOR_GOLD_DIM.g, C.COLOR_GOLD_DIM.b, 0.3)
	hs.border_width_bottom = 1
	hs.shadow_color = Color(0,0,0,0.3); hs.shadow_size = 20
	header.add_theme_stylebox_override("panel", hs)
	container.add_child(header)

	var hbox = HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	header.add_child(hbox)

	var accent = ColorRect.new()
	accent.color = C.COLOR_GOLD
	accent.custom_minimum_size = Vector2(6, 0)
	hbox.add_child(accent)

	var title_m = MarginContainer.new()
	title_m.add_theme_constant_override("margin_left", 20)
	title_m.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(title_m)

	var title_lbl = Label.new()
	title_lbl.text = "◈ POKÉMON TCG · CONFIGURACIÓN"
	title_lbl.add_theme_font_size_override("font_size", 16)
	title_lbl.add_theme_color_override("font_color", C.COLOR_GOLD)
	title_m.add_child(title_lbl)

	# ── Contenido ──
	var scroll = ScrollContainer.new()
	scroll.anchor_left = 0; scroll.anchor_right  = 1
	scroll.anchor_top  = 0; scroll.anchor_bottom = 1
	scroll.offset_top  = 120
	UITheme.apply_scrollbar_theme(scroll)
	container.add_child(scroll)

	var center = MarginContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.add_theme_constant_override("margin_left",   40)
	center.add_theme_constant_override("margin_right",  40)
	center.add_theme_constant_override("margin_top",    30)
	center.add_theme_constant_override("margin_bottom", 30)
	scroll.add_child(center)

	var main_v = VBoxContainer.new()
	main_v.add_theme_constant_override("separation", 24)
	center.add_child(main_v)

	# ── Sección: Audio ──
	_add_section_title(main_v, "🔊  AUDIO", C)

	var audio_card = _make_panel(C)
	main_v.add_child(audio_card)

	var audio_v = VBoxContainer.new()
	audio_v.add_theme_constant_override("separation", 16)
	audio_card.add_child(audio_v)

	_add_slider_row(audio_v, "Volumen Música",  "music_volume",  AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music"))  if AudioServer.get_bus_index("Music")  >= 0 else 0.0, C)
	_add_slider_row(audio_v, "Volumen Efectos", "sfx_volume",    AudioServer.get_bus_volume_db(AudioServer.get_bus_index("SFX"))    if AudioServer.get_bus_index("SFX")    >= 0 else 0.0, C)

	# ── Sección: Pantalla ──
	_add_section_title(main_v, "🖥  PANTALLA", C)

	var screen_card = _make_panel(C)
	main_v.add_child(screen_card)

	var screen_v = VBoxContainer.new()
	screen_v.add_theme_constant_override("separation", 16)
	screen_card.add_child(screen_v)

	_add_toggle_row(screen_v, "Pantalla Completa", DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN, func(val: bool):
		if val:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	, C)

	_add_toggle_row(screen_v, "VSync", DisplayServer.window_get_vsync_mode() != DisplayServer.VSYNC_DISABLED, func(val: bool):
		DisplayServer.window_set_vsync_mode(
			DisplayServer.VSYNC_ENABLED if val else DisplayServer.VSYNC_DISABLED
		)
	, C)

	# ── Sección: Red ──
	_add_section_title(main_v, "🌐  RED", C)

	var net_card = _make_panel(C)
	main_v.add_child(net_card)

	var net_v = VBoxContainer.new()
	net_v.add_theme_constant_override("separation", 12)
	net_card.add_child(net_v)

	# Estado del servidor
	var srv_hb = HBoxContainer.new()
	net_v.add_child(srv_hb)

	var srv_lbl = Label.new()
	srv_lbl.text = "Estado del servidor"
	srv_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	srv_lbl.add_theme_font_size_override("font_size", 13)
	srv_lbl.add_theme_color_override("font_color", C.COLOR_TEXT_DIM)
	srv_hb.add_child(srv_lbl)

	var srv_val = Label.new()
	srv_val.text = "● Conectado" if NetworkManager.ws_connected else "○ Desconectado"
	srv_val.add_theme_font_size_override("font_size", 13)
	srv_val.add_theme_color_override("font_color", C.COLOR_GREEN if NetworkManager.ws_connected else Color(0.8, 0.3, 0.3))
	srv_hb.add_child(srv_val)

	# Botón reconectar
	var reconn_btn = Button.new()
	reconn_btn.text = "Reconectar al Servidor"
	reconn_btn.custom_minimum_size = Vector2(0, 40)
	reconn_btn.add_theme_font_size_override("font_size", 13)
	reconn_btn.add_theme_color_override("font_color", C.COLOR_GOLD)
	var st_reconn = StyleBoxFlat.new()
	st_reconn.bg_color = Color(0,0,0,0)
	st_reconn.border_color = Color(C.COLOR_GOLD_DIM.r, C.COLOR_GOLD_DIM.g, C.COLOR_GOLD_DIM.b, 0.4)
	st_reconn.border_width_left = 1; st_reconn.border_width_right  = 1
	st_reconn.border_width_top  = 1; st_reconn.border_width_bottom = 1
	st_reconn.corner_radius_top_left    = 6; st_reconn.corner_radius_top_right    = 6
	st_reconn.corner_radius_bottom_left = 6; st_reconn.corner_radius_bottom_right = 6
	reconn_btn.add_theme_stylebox_override("normal", st_reconn)
	reconn_btn.pressed.connect(func():
		NetworkManager.connect_to_server()
		srv_val.text = "Conectando..."
		srv_val.add_theme_color_override("font_color", C.COLOR_TEXT_DIM)
	)
	net_v.add_child(reconn_btn)

	# ── Sección: Cuenta ──
	_add_section_title(main_v, "👤  CUENTA", C)

	var account_card = _make_panel(C)
	main_v.add_child(account_card)

	var account_v = VBoxContainer.new()
	account_v.add_theme_constant_override("separation", 12)
	account_card.add_child(account_v)

	if PlayerData.is_logged_in:
		_add_info_row(account_v, "Jugador",  PlayerData.username, C)
		_add_info_row(account_v, "ELO",      str(PlayerData.elo), C)
		_add_info_row(account_v, "Rango",    PlayerData.rank,     C)
		_add_info_row(account_v, "Monedas",  str(PlayerData.coins), C)

		account_v.add_child(UITheme.vspace(8))

		var logout_btn = Button.new()
		logout_btn.text = "Cerrar Sesión"
		logout_btn.custom_minimum_size = Vector2(160, 42)
		logout_btn.add_theme_font_size_override("font_size", 13)
		logout_btn.add_theme_color_override("font_color", Color(0.9, 0.4, 0.4))
		var st_logout = StyleBoxFlat.new()
		st_logout.bg_color = Color(0,0,0,0)
		st_logout.border_color = Color(0.9, 0.4, 0.4, 0.5)
		st_logout.border_width_left = 1; st_logout.border_width_right  = 1
		st_logout.border_width_top  = 1; st_logout.border_width_bottom = 1
		st_logout.corner_radius_top_left    = 6; st_logout.corner_radius_top_right    = 6
		st_logout.corner_radius_bottom_left = 6; st_logout.corner_radius_bottom_right = 6
		var st_logout_hov = st_logout.duplicate()
		st_logout_hov.bg_color = Color(0.9, 0.4, 0.4, 0.1)
		logout_btn.add_theme_stylebox_override("normal", st_logout)
		logout_btn.add_theme_stylebox_override("hover",  st_logout_hov)
		logout_btn.pressed.connect(func():
			PlayerData.logout()
			NetworkManager.disconnect_from_server()
			menu._show_screen(menu.Screen.LOGIN)
		)
		account_v.add_child(logout_btn)
	else:
		var guest_lbl = Label.new()
		guest_lbl.text = "Jugando como invitado"
		guest_lbl.add_theme_font_size_override("font_size", 13)
		guest_lbl.add_theme_color_override("font_color", C.COLOR_TEXT_DIM)
		account_v.add_child(guest_lbl)

	# ── Sección: Acerca de ──
	_add_section_title(main_v, "ℹ  ACERCA DE", C)

	var about_card = _make_panel(C)
	main_v.add_child(about_card)

	var about_v = VBoxContainer.new()
	about_v.add_theme_constant_override("separation", 8)
	about_card.add_child(about_v)

	_add_info_row(about_v, "Versión",    "v0.1 Alpha",          C)
	_add_info_row(about_v, "Expansión",  "Neo Genesis (111 cartas)", C)
	_add_info_row(about_v, "Motor",      "Godot 4",             C)
	_add_info_row(about_v, "Servidor",   "Node.js + SQLite",    C)


# ── Helpers ─────────────────────────────────────────────────

static func _make_panel(C) -> MarginContainer:
	var mc = MarginContainer.new()
	mc.add_theme_constant_override("margin_left",   20)
	mc.add_theme_constant_override("margin_right",  20)
	mc.add_theme_constant_override("margin_top",    16)
	mc.add_theme_constant_override("margin_bottom", 16)
	var st = StyleBoxFlat.new()
	st.bg_color = Color(C.COLOR_PANEL.r, C.COLOR_PANEL.g, C.COLOR_PANEL.b, 0.85)
	st.border_color = Color(C.COLOR_GOLD_DIM.r, C.COLOR_GOLD_DIM.g, C.COLOR_GOLD_DIM.b, 0.2)
	st.border_width_left = 1; st.border_width_right  = 1
	st.border_width_top  = 1; st.border_width_bottom = 1
	st.corner_radius_top_left    = 10; st.corner_radius_top_right    = 10
	st.corner_radius_bottom_left = 10; st.corner_radius_bottom_right = 10
	st.shadow_color = Color(0,0,0,0.2); st.shadow_size = 10
	mc.add_theme_stylebox_override("panel", st)
	return mc

static func _add_section_title(parent: VBoxContainer, text: String, C) -> void:
	var lbl = Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.add_theme_color_override("font_color", C.COLOR_GOLD_DIM)
	parent.add_child(lbl)

static func _add_info_row(parent: VBoxContainer, label: String, value: String, C) -> void:
	var hb = HBoxContainer.new()
	parent.add_child(hb)
	var lbl = Label.new()
	lbl.text = label
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", C.COLOR_TEXT_DIM)
	hb.add_child(lbl)
	var val = Label.new()
	val.text = value
	val.add_theme_font_size_override("font_size", 13)
	val.add_theme_color_override("font_color", C.COLOR_TEXT)
	hb.add_child(val)

static func _add_toggle_row(parent: VBoxContainer, label: String, initial: bool, on_toggle: Callable, C) -> void:
	var hb = HBoxContainer.new()
	parent.add_child(hb)
	var lbl = Label.new()
	lbl.text = label
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", C.COLOR_TEXT_DIM)
	hb.add_child(lbl)
	var chk = CheckButton.new()
	chk.button_pressed = initial
	chk.toggled.connect(on_toggle)
	hb.add_child(chk)

static func _add_slider_row(parent: VBoxContainer, label: String, _key: String, initial_db: float, C) -> void:
	var hb = HBoxContainer.new()
	hb.add_theme_constant_override("separation", 12)
	parent.add_child(hb)
	var lbl = Label.new()
	lbl.text = label
	lbl.custom_minimum_size = Vector2(160, 0)
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", C.COLOR_TEXT_DIM)
	hb.add_child(lbl)
	var slider = HSlider.new()
	slider.min_value = -40.0
	slider.max_value =   6.0
	slider.step      =   1.0
	slider.value     = initial_db
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(slider)
	var val_lbl = Label.new()
	val_lbl.text = str(int(initial_db)) + " dB"
	val_lbl.custom_minimum_size = Vector2(52, 0)
	val_lbl.add_theme_font_size_override("font_size", 12)
	val_lbl.add_theme_color_override("font_color", C.COLOR_TEXT)
	hb.add_child(val_lbl)
	slider.value_changed.connect(func(v: float):
		val_lbl.text = str(int(v)) + " dB"
	)
