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
	bg_image.modulate = Color(0.22, 0.22, 0.28, 1)
	container.add_child(bg_image)

	var overlay = ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.04, 0.04, 0.07, 0.72)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(overlay)

	var header = Panel.new()
	header.anchor_left = 0; header.anchor_right  = 1
	header.anchor_top  = 0; header.anchor_bottom = 0
	header.offset_top  = 0; header.offset_bottom = 72
	var hs = StyleBoxFlat.new()
	hs.bg_color = Color(0.05, 0.05, 0.08, 0.96)
	hs.border_color = Color(C.COLOR_GOLD_DIM.r, C.COLOR_GOLD_DIM.g, C.COLOR_GOLD_DIM.b, 0.25)
	hs.border_width_bottom = 1
	hs.shadow_color = Color(0,0,0,0.5); hs.shadow_size = 20
	header.add_theme_stylebox_override("panel", hs)
	container.add_child(header)

	var hbox = HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	header.add_child(hbox)

	var accent = ColorRect.new()
	accent.color = C.COLOR_GOLD
	accent.custom_minimum_size = Vector2(4, 0)
	hbox.add_child(accent)

	var title_m = MarginContainer.new()
	title_m.add_theme_constant_override("margin_left", 20)
	title_m.add_theme_constant_override("margin_top", 4)
	title_m.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(title_m)

	var title_v = VBoxContainer.new()
	title_m.add_child(title_v)

	var eyebrow = Label.new()
	eyebrow.text = "POKÉMON TCG ONLINE"
	eyebrow.add_theme_font_size_override("font_size", 9)
	eyebrow.add_theme_color_override("font_color", Color(C.COLOR_GOLD_DIM.r, C.COLOR_GOLD_DIM.g, C.COLOR_GOLD_DIM.b, 0.8))
	title_v.add_child(eyebrow)

	var title_lbl = Label.new()
	title_lbl.text = "◈  CONFIGURACIÓN"
	title_lbl.add_theme_font_size_override("font_size", 17)
	title_lbl.add_theme_color_override("font_color", C.COLOR_GOLD)
	title_v.add_child(title_lbl)

	var badge_m = MarginContainer.new()
	badge_m.add_theme_constant_override("margin_right", 24)
	hbox.add_child(badge_m)
	var badge = Label.new()
	badge.text = "v0.1 α"
	badge.add_theme_font_size_override("font_size", 10)
	badge.add_theme_color_override("font_color", Color(C.COLOR_TEXT_DIM.r, C.COLOR_TEXT_DIM.g, C.COLOR_TEXT_DIM.b, 0.5))
	badge_m.add_child(badge)

	var scroll = ScrollContainer.new()
	scroll.anchor_left = 0; scroll.anchor_right  = 1
	scroll.anchor_top  = 0; scroll.anchor_bottom = 1
	scroll.offset_top  = 72
	UITheme.apply_scrollbar_theme(scroll)
	container.add_child(scroll)

	var center = MarginContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.add_theme_constant_override("margin_left",   48)
	center.add_theme_constant_override("margin_right",  48)
	center.add_theme_constant_override("margin_top",    28)
	center.add_theme_constant_override("margin_bottom", 40)
	scroll.add_child(center)

	var main_v = VBoxContainer.new()
	main_v.add_theme_constant_override("separation", 6)
	center.add_child(main_v)

	# ── Sección: Audio ──
	_add_section_title(main_v, "🔊   AUDIO", C)
	var audio_card = _make_card(C)
	main_v.add_child(audio_card)
	var audio_v = VBoxContainer.new()
	audio_v.add_theme_constant_override("separation", 0)
	audio_card.add_child(audio_v)
	_add_slider_row(audio_v, "Volumen Música",  "🎵", "Bus: Music", "Music",
		AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music"))  if AudioServer.get_bus_index("Music")  >= 0 else 0.0, C)
	_add_divider(audio_v, C)
	_add_slider_row(audio_v, "Volumen Efectos", "🔉", "Bus: SFX",   "SFX",
		AudioServer.get_bus_volume_db(AudioServer.get_bus_index("SFX"))    if AudioServer.get_bus_index("SFX")    >= 0 else 0.0, C)

	main_v.add_child(UITheme.vspace(18))

	# ── Sección: Pantalla ──
	_add_section_title(main_v, "🖥   PANTALLA", C)
	var screen_card = _make_card(C)
	main_v.add_child(screen_card)
	var screen_v = VBoxContainer.new()
	screen_v.add_theme_constant_override("separation", 0)
	screen_card.add_child(screen_v)
	_add_toggle_row(screen_v, "Pantalla Completa", "⛶", "Cambia el modo de ventana",
		DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN,
		func(val: bool):
			if val: DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			else:   DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	, C)
	_add_divider(screen_v, C)
	_add_toggle_row(screen_v, "VSync", "⟳", "Sincronización vertical",
		DisplayServer.window_get_vsync_mode() != DisplayServer.VSYNC_DISABLED,
		func(val: bool):
			DisplayServer.window_set_vsync_mode(
				DisplayServer.VSYNC_ENABLED if val else DisplayServer.VSYNC_DISABLED)
	, C)

	main_v.add_child(UITheme.vspace(18))

	# ── Sección: Idioma ──
	_add_section_title(main_v, "🌍   IDIOMA", C)
	var lang_card = _make_card(C)
	main_v.add_child(lang_card)
	var lang_v = VBoxContainer.new()
	lang_card.add_child(lang_v)

	var lang_row_m = MarginContainer.new()
	lang_row_m.add_theme_constant_override("margin_left",   16)
	lang_row_m.add_theme_constant_override("margin_right",  16)
	lang_row_m.add_theme_constant_override("margin_top",    14)
	lang_row_m.add_theme_constant_override("margin_bottom", 14)
	lang_v.add_child(lang_row_m)
	var lang_row = HBoxContainer.new()
	lang_row.add_theme_constant_override("separation", 12)
	lang_row_m.add_child(lang_row)

	var icon_lbl = Label.new()
	icon_lbl.text = "🃏"
	lang_row.add_child(icon_lbl)

	var lang_info = VBoxContainer.new()
	lang_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lang_row.add_child(lang_info)
	var lang_main = Label.new()
	lang_main.text = "Idioma de las cartas"
	lang_main.add_theme_font_size_override("font_size", 13)
	lang_main.add_theme_color_override("font_color", C.COLOR_TEXT)
	lang_info.add_child(lang_main)
	var lang_sub = Label.new()
	lang_sub.text = "Cambia las imágenes de las cartas"
	lang_sub.add_theme_font_size_override("font_size", 10)
	lang_sub.add_theme_color_override("font_color", Color(C.COLOR_TEXT_DIM.r, C.COLOR_TEXT_DIM.g, C.COLOR_TEXT_DIM.b, 0.6))
	lang_info.add_child(lang_sub)

	var lang_btns = HBoxContainer.new()
	lang_btns.add_theme_constant_override("separation", 6)
	lang_row.add_child(lang_btns)

	var LM = menu.get_node_or_null("/root/LanguageManager")
	if LM == null:
		push_error("LanguageManager no encontrado en /root/")
		return

	var btn_es = _make_lang_button("ES", C)
	var btn_en = _make_lang_button("EN", C)
	lang_btns.add_child(btn_es)
	lang_btns.add_child(btn_en)

	var st_active = func() -> StyleBoxFlat:
		var s = StyleBoxFlat.new()
		s.bg_color = Color(C.COLOR_GOLD.r, C.COLOR_GOLD.g, C.COLOR_GOLD.b, 0.18)
		s.border_color = C.COLOR_GOLD
		s.border_width_left = 2; s.border_width_right  = 2
		s.border_width_top  = 2; s.border_width_bottom = 2
		s.corner_radius_top_left    = 5; s.corner_radius_top_right    = 5
		s.corner_radius_bottom_left = 5; s.corner_radius_bottom_right = 5
		return s
	var st_inactive = func() -> StyleBoxFlat:
		var s = StyleBoxFlat.new()
		s.bg_color = Color(0, 0, 0, 0)
		s.border_color = Color(C.COLOR_GOLD_DIM.r, C.COLOR_GOLD_DIM.g, C.COLOR_GOLD_DIM.b, 0.25)
		s.border_width_left = 1; s.border_width_right  = 1
		s.border_width_top  = 1; s.border_width_bottom = 1
		s.corner_radius_top_left    = 5; s.corner_radius_top_right    = 5
		s.corner_radius_bottom_left = 5; s.corner_radius_bottom_right = 5
		return s

	var refresh_buttons = func():
		var es = LM.is_spanish()
		btn_es.add_theme_stylebox_override("normal", st_active.call() if es  else st_inactive.call())
		btn_en.add_theme_stylebox_override("normal", st_active.call() if !es else st_inactive.call())
		btn_es.add_theme_color_override("font_color", C.COLOR_GOLD    if es  else C.COLOR_TEXT_DIM)
		btn_en.add_theme_color_override("font_color", C.COLOR_GOLD    if !es else C.COLOR_TEXT_DIM)
	refresh_buttons.call()

	btn_es.pressed.connect(func(): LM.set_language(LM.Language.ES); refresh_buttons.call())
	btn_en.pressed.connect(func(): LM.set_language(LM.Language.EN); refresh_buttons.call())

	main_v.add_child(UITheme.vspace(18))

	# ── Sección: Red ──
	_add_section_title(main_v, "🌐   RED", C)
	var net_card = _make_card(C)
	main_v.add_child(net_card)
	var net_v = VBoxContainer.new()
	net_v.add_theme_constant_override("separation", 0)
	net_card.add_child(net_v)

	var srv_row_m = MarginContainer.new()
	srv_row_m.add_theme_constant_override("margin_left",   16)
	srv_row_m.add_theme_constant_override("margin_right",  16)
	srv_row_m.add_theme_constant_override("margin_top",    14)
	srv_row_m.add_theme_constant_override("margin_bottom", 14)
	net_v.add_child(srv_row_m)
	var srv_hb = HBoxContainer.new()
	srv_hb.add_theme_constant_override("separation", 12)
	srv_row_m.add_child(srv_hb)
	var srv_icon = Label.new()
	srv_icon.text = "📡"
	srv_hb.add_child(srv_icon)
	var srv_info = VBoxContainer.new()
	srv_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	srv_hb.add_child(srv_info)
	var srv_main = Label.new()
	srv_main.text = "Estado del servidor"
	srv_main.add_theme_font_size_override("font_size", 13)
	srv_main.add_theme_color_override("font_color", C.COLOR_TEXT)
	srv_info.add_child(srv_main)
	var srv_sub = Label.new()
	srv_sub.text = "WebSocket"
	srv_sub.add_theme_font_size_override("font_size", 10)
	srv_sub.add_theme_color_override("font_color", Color(C.COLOR_TEXT_DIM.r, C.COLOR_TEXT_DIM.g, C.COLOR_TEXT_DIM.b, 0.6))
	srv_info.add_child(srv_sub)

	var status_hb = HBoxContainer.new()
	status_hb.add_theme_constant_override("separation", 6)
	srv_hb.add_child(status_hb)
	var dot = ColorRect.new()
	dot.custom_minimum_size = Vector2(8, 8)
	dot.color = C.COLOR_GREEN if NetworkManager.ws_connected else Color(0.8, 0.3, 0.3)
	status_hb.add_child(dot)
	var srv_val = Label.new()
	srv_val.text = "Conectado" if NetworkManager.ws_connected else "Desconectado"
	srv_val.add_theme_font_size_override("font_size", 13)
	srv_val.add_theme_color_override("font_color", C.COLOR_GREEN if NetworkManager.ws_connected else Color(0.8, 0.3, 0.3))
	status_hb.add_child(srv_val)

	_add_divider(net_v, C)

	var reconn_row_m = MarginContainer.new()
	reconn_row_m.add_theme_constant_override("margin_left",   16)
	reconn_row_m.add_theme_constant_override("margin_right",  16)
	reconn_row_m.add_theme_constant_override("margin_top",    12)
	reconn_row_m.add_theme_constant_override("margin_bottom", 12)
	net_v.add_child(reconn_row_m)
	var reconn_hb = HBoxContainer.new()
	reconn_hb.add_theme_constant_override("separation", 12)
	reconn_row_m.add_child(reconn_hb)
	var reconn_icon = Label.new()
	reconn_icon.text = "🔁"
	reconn_hb.add_child(reconn_icon)
	var reconn_lbl = Label.new()
	reconn_lbl.text = "Conexión"
	reconn_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reconn_lbl.add_theme_font_size_override("font_size", 13)
	reconn_lbl.add_theme_color_override("font_color", C.COLOR_TEXT)
	reconn_hb.add_child(reconn_lbl)
	var reconn_btn = _make_outline_button("Reconectar", C.COLOR_GOLD, C)
	reconn_btn.pressed.connect(func():
		NetworkManager.connect_to_server()
		srv_val.text = "Conectando..."
		srv_val.add_theme_color_override("font_color", C.COLOR_TEXT_DIM)
		dot.color = C.COLOR_TEXT_DIM
	)
	reconn_hb.add_child(reconn_btn)

	main_v.add_child(UITheme.vspace(18))

	# ── Sección: Cuenta ──
	_add_section_title(main_v, "👤   CUENTA", C)
	var account_card = _make_card(C)
	main_v.add_child(account_card)
	var account_v = VBoxContainer.new()
	account_v.add_theme_constant_override("separation", 0)
	account_card.add_child(account_v)

	if PlayerData.is_logged_in:
		_add_info_row(account_v, "🏷", "Jugador",  PlayerData.username,    C.COLOR_TEXT, C)
		_add_divider(account_v, C)
		_add_info_row(account_v, "📊", "ELO",      str(PlayerData.elo),    C.COLOR_TEXT, C)
		_add_divider(account_v, C)
		_add_info_row(account_v, "🏅", "Rango",    PlayerData.rank,        C.COLOR_GOLD, C)
		_add_divider(account_v, C)
		_add_info_row(account_v, "🪙", "Monedas",  str(PlayerData.coins),  C.COLOR_GOLD, C)
		_add_divider(account_v, C)

		var logout_row_m = MarginContainer.new()
		logout_row_m.add_theme_constant_override("margin_left",   16)
		logout_row_m.add_theme_constant_override("margin_right",  16)
		logout_row_m.add_theme_constant_override("margin_top",    12)
		logout_row_m.add_theme_constant_override("margin_bottom", 12)
		account_v.add_child(logout_row_m)
		var logout_hb = HBoxContainer.new()
		logout_hb.add_theme_constant_override("separation", 12)
		logout_row_m.add_child(logout_hb)
		var logout_icon = Label.new()
		logout_icon.text = "🚪"
		logout_hb.add_child(logout_icon)
		var logout_info = VBoxContainer.new()
		logout_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		logout_hb.add_child(logout_info)
		var logout_main = Label.new()
		logout_main.text = "Sesión"
		logout_main.add_theme_font_size_override("font_size", 13)
		logout_main.add_theme_color_override("font_color", C.COLOR_TEXT)
		logout_info.add_child(logout_main)
		var logout_sub = Label.new()
		logout_sub.text = "Cerrar y volver al login"
		logout_sub.add_theme_font_size_override("font_size", 10)
		logout_sub.add_theme_color_override("font_color", Color(C.COLOR_TEXT_DIM.r, C.COLOR_TEXT_DIM.g, C.COLOR_TEXT_DIM.b, 0.6))
		logout_info.add_child(logout_sub)

		# ── LOGOUT: borra sesión guardada + desconecta + va al login ──
		var logout_btn = _make_outline_button("Cerrar Sesión", Color(0.9, 0.4, 0.4), C)
		logout_btn.pressed.connect(func():
			var cfg_dir = DirAccess.open("user://")
			if cfg_dir and cfg_dir.file_exists("session.cfg"):
				cfg_dir.remove("session.cfg")
			PlayerData.logout()
			NetworkManager.disconnect_from_server()
			menu._show_screen(menu.Screen.LOGIN)
		)
		logout_hb.add_child(logout_btn)
	else:
		var guest_m = MarginContainer.new()
		guest_m.add_theme_constant_override("margin_left",   16)
		guest_m.add_theme_constant_override("margin_top",    14)
		guest_m.add_theme_constant_override("margin_bottom", 14)
		account_v.add_child(guest_m)
		var guest_lbl = Label.new()
		guest_lbl.text = "Jugando como invitado"
		guest_lbl.add_theme_font_size_override("font_size", 13)
		guest_lbl.add_theme_color_override("font_color", C.COLOR_TEXT_DIM)
		guest_m.add_child(guest_lbl)

	main_v.add_child(UITheme.vspace(18))

	# ── Sección: Acerca de ──
	_add_section_title(main_v, "ℹ   ACERCA DE", C)
	var about_card = _make_card(C)
	main_v.add_child(about_card)
	var about_v = VBoxContainer.new()
	about_v.add_theme_constant_override("separation", 0)
	about_card.add_child(about_v)
	_add_info_row(about_v, "📦", "Versión",   "v0.1 Alpha",               C.COLOR_TEXT, C)
	_add_divider(about_v, C)
	_add_info_row(about_v, "🃏", "Expansión", "Neo Genesis (111 cartas)",  C.COLOR_TEXT, C)
	_add_divider(about_v, C)
	_add_info_row(about_v, "⚙", "Motor",     "Godot 4",                   C.COLOR_TEXT, C)
	_add_divider(about_v, C)
	_add_info_row(about_v, "🖧", "Servidor",  "Node.js + SQLite",          C.COLOR_TEXT, C)


# ══════════════════════════════════════════════════════════════
# HELPERS
# ══════════════════════════════════════════════════════════════

static func _make_card(C) -> MarginContainer:
	var mc = MarginContainer.new()
	var st = StyleBoxFlat.new()
	st.bg_color = Color(0.07, 0.07, 0.11, 0.92)
	st.border_color = Color(C.COLOR_GOLD_DIM.r, C.COLOR_GOLD_DIM.g, C.COLOR_GOLD_DIM.b, 0.18)
	st.border_width_left = 1; st.border_width_right  = 1
	st.border_width_top  = 1; st.border_width_bottom = 1
	st.corner_radius_top_left    = 8; st.corner_radius_top_right    = 8
	st.corner_radius_bottom_left = 8; st.corner_radius_bottom_right = 8
	st.shadow_color = Color(0,0,0,0.35); st.shadow_size = 12
	mc.add_theme_stylebox_override("panel", st)
	return mc

static func _add_section_title(parent: VBoxContainer, text: String, C) -> void:
	var m = MarginContainer.new()
	m.add_theme_constant_override("margin_bottom", 6)
	parent.add_child(m)
	var hb = HBoxContainer.new()
	hb.add_theme_constant_override("separation", 8)
	m.add_child(hb)
	var lbl = Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.add_theme_color_override("font_color", Color(C.COLOR_GOLD_DIM.r, C.COLOR_GOLD_DIM.g, C.COLOR_GOLD_DIM.b, 0.9))
	hb.add_child(lbl)
	var line = ColorRect.new()
	line.custom_minimum_size = Vector2(0, 1)
	line.color = Color(C.COLOR_GOLD_DIM.r, C.COLOR_GOLD_DIM.g, C.COLOR_GOLD_DIM.b, 0.15)
	line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(line)

static func _add_divider(parent: Control, C) -> void:
	var div = ColorRect.new()
	div.custom_minimum_size = Vector2(0, 1)
	div.color = Color(C.COLOR_GOLD_DIM.r, C.COLOR_GOLD_DIM.g, C.COLOR_GOLD_DIM.b, 0.07)
	div.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(div)

static func _add_info_row(parent: VBoxContainer, icon: String, label: String, value: String, val_color: Color, C) -> void:
	var row_m = MarginContainer.new()
	row_m.add_theme_constant_override("margin_left",   16)
	row_m.add_theme_constant_override("margin_right",  16)
	row_m.add_theme_constant_override("margin_top",    12)
	row_m.add_theme_constant_override("margin_bottom", 12)
	parent.add_child(row_m)
	var hb = HBoxContainer.new()
	hb.add_theme_constant_override("separation", 12)
	row_m.add_child(hb)
	var icon_lbl = Label.new()
	icon_lbl.text = icon
	hb.add_child(icon_lbl)
	var lbl = Label.new()
	lbl.text = label
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", C.COLOR_TEXT)
	hb.add_child(lbl)
	var val = Label.new()
	val.text = value
	val.add_theme_font_size_override("font_size", 13)
	val.add_theme_color_override("font_color", val_color)
	hb.add_child(val)

static func _add_toggle_row(parent: VBoxContainer, label: String, icon: String, subtitle: String, initial: bool, on_toggle: Callable, C) -> void:
	var row_m = MarginContainer.new()
	row_m.add_theme_constant_override("margin_left",   16)
	row_m.add_theme_constant_override("margin_right",  16)
	row_m.add_theme_constant_override("margin_top",    13)
	row_m.add_theme_constant_override("margin_bottom", 13)
	parent.add_child(row_m)
	var hb = HBoxContainer.new()
	hb.add_theme_constant_override("separation", 12)
	row_m.add_child(hb)
	var icon_lbl = Label.new()
	icon_lbl.text = icon
	hb.add_child(icon_lbl)
	var info_v = VBoxContainer.new()
	info_v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(info_v)
	var main_lbl = Label.new()
	main_lbl.text = label
	main_lbl.add_theme_font_size_override("font_size", 13)
	main_lbl.add_theme_color_override("font_color", C.COLOR_TEXT)
	info_v.add_child(main_lbl)
	if subtitle != "":
		var sub_lbl = Label.new()
		sub_lbl.text = subtitle
		sub_lbl.add_theme_font_size_override("font_size", 10)
		sub_lbl.add_theme_color_override("font_color", Color(C.COLOR_TEXT_DIM.r, C.COLOR_TEXT_DIM.g, C.COLOR_TEXT_DIM.b, 0.6))
		info_v.add_child(sub_lbl)
	var chk = CheckButton.new()
	chk.button_pressed = initial
	chk.toggled.connect(on_toggle)
	hb.add_child(chk)

static func _add_slider_row(parent: VBoxContainer, label: String, icon: String, subtitle: String, _key: String, initial_db: float, C) -> void:
	var row_m = MarginContainer.new()
	row_m.add_theme_constant_override("margin_left",   16)
	row_m.add_theme_constant_override("margin_right",  16)
	row_m.add_theme_constant_override("margin_top",    13)
	row_m.add_theme_constant_override("margin_bottom", 13)
	parent.add_child(row_m)
	var hb = HBoxContainer.new()
	hb.add_theme_constant_override("separation", 12)
	row_m.add_child(hb)
	var icon_lbl = Label.new()
	icon_lbl.text = icon
	hb.add_child(icon_lbl)
	var info_v = VBoxContainer.new()
	info_v.custom_minimum_size = Vector2(130, 0)
	hb.add_child(info_v)
	var main_lbl = Label.new()
	main_lbl.text = label
	main_lbl.add_theme_font_size_override("font_size", 13)
	main_lbl.add_theme_color_override("font_color", C.COLOR_TEXT)
	info_v.add_child(main_lbl)
	var sub_lbl = Label.new()
	sub_lbl.text = subtitle
	sub_lbl.add_theme_font_size_override("font_size", 10)
	sub_lbl.add_theme_color_override("font_color", Color(C.COLOR_TEXT_DIM.r, C.COLOR_TEXT_DIM.g, C.COLOR_TEXT_DIM.b, 0.6))
	info_v.add_child(sub_lbl)
	var slider = HSlider.new()
	slider.min_value = -40.0
	slider.max_value =   6.0
	slider.step      =   1.0
	slider.value     = initial_db
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(slider)
	var val_lbl = Label.new()
	val_lbl.text = str(int(initial_db)) + " dB"
	val_lbl.custom_minimum_size = Vector2(50, 0)
	val_lbl.add_theme_font_size_override("font_size", 12)
	val_lbl.add_theme_color_override("font_color", C.COLOR_GOLD)
	val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hb.add_child(val_lbl)
	slider.value_changed.connect(func(v: float):
		val_lbl.text = str(int(v)) + " dB"
		var bus = AudioServer.get_bus_index(_key)
		if bus >= 0:
			AudioServer.set_bus_volume_db(bus, v)
			SoundManager.save_volume(_key, v)
	)

static func _make_lang_button(text: String, _C) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(52, 34)
	btn.add_theme_font_size_override("font_size", 12)
	return btn

static func _make_outline_button(text: String, col: Color, _C) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(0, 36)
	btn.add_theme_font_size_override("font_size", 11)
	btn.add_theme_color_override("font_color", col)
	var st = StyleBoxFlat.new()
	st.bg_color = Color(0, 0, 0, 0)
	st.border_color = Color(col.r, col.g, col.b, 0.4)
	st.border_width_left = 1; st.border_width_right  = 1
	st.border_width_top  = 1; st.border_width_bottom = 1
	st.corner_radius_top_left    = 5; st.corner_radius_top_right    = 5
	st.corner_radius_bottom_left = 5; st.corner_radius_bottom_right = 5
	var st_hov = st.duplicate()
	st_hov.bg_color = Color(col.r, col.g, col.b, 0.1)
	st_hov.border_color = col
	btn.add_theme_stylebox_override("normal", st)
	btn.add_theme_stylebox_override("hover",  st_hov)
	return btn
