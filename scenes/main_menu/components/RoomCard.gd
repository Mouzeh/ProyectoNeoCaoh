extends Node

# ============================================================
# RoomCard.gd — Componente: tarjeta de mesa en el lobby
# ============================================================

static func make(data: Dictionary, menu) -> Control:
	var C = menu

	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(340, 240)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var st = StyleBoxFlat.new()
	st.bg_color = C.COLOR_PANEL
	st.border_color = Color(C.COLOR_GOLD_DIM.r, C.COLOR_GOLD_DIM.g, C.COLOR_GOLD_DIM.b, 0.3)
	st.border_width_left = 1; st.border_width_right  = 1
	st.border_width_top  = 1; st.border_width_bottom = 1
	st.corner_radius_top_left    = 16; st.corner_radius_top_right    = 16
	st.corner_radius_bottom_left = 16; st.corner_radius_bottom_right = 16
	st.shadow_color = Color(0,0,0,0.4); st.shadow_size = 25; st.shadow_offset = Vector2(0,10)
	card.add_theme_stylebox_override("panel", st)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left",   16)
	margin.add_theme_constant_override("margin_right",  16)
	margin.add_theme_constant_override("margin_top",    16)
	margin.add_theme_constant_override("margin_bottom", 16)
	card.add_child(margin)

	var main_vbox = VBoxContainer.new()
	margin.add_child(main_vbox)

	# Stats apuesta/modo/premios
	var header_hbox = HBoxContainer.new()
	main_vbox.add_child(header_hbox)
	for pair in [["Apuesta","🪙 " + str(data.get("apuesta",10))], ["Modo","🏆"], ["Premios","🎁 x6"]]:
		var lbl = Label.new()
		lbl.text = pair[0] + "\n" + pair[1]
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl.add_theme_font_size_override("font_size", 12)
		lbl.add_theme_color_override("font_color", C.COLOR_TEXT)
		header_hbox.add_child(lbl)

	main_vbox.add_child(UITheme.vspace(5))

	# Campo visual
	var field_panel = PanelContainer.new()
	field_panel.custom_minimum_size = Vector2(0, 80)
	var field_st = StyleBoxFlat.new()
	field_st.bg_color = C.COLOR_BG.lightened(0.05)
	field_st.border_color = Color(C.COLOR_GOLD_DIM.r, C.COLOR_GOLD_DIM.g, C.COLOR_GOLD_DIM.b, 0.3)
	field_st.border_width_left = 1; field_st.border_width_right  = 1
	field_st.border_width_top  = 1; field_st.border_width_bottom = 1
	field_panel.add_theme_stylebox_override("panel", field_st)
	main_vbox.add_child(field_panel)

	main_vbox.add_child(UITheme.vspace(5))

	# Jugadores
	var is_full = data.get("guest", "") != ""
	var stats_hbox = HBoxContainer.new()
	main_vbox.add_child(stats_hbox)

	var host_vbox = VBoxContainer.new()
	var h_name = Label.new()
	h_name.text = data.get("host", "Desconocido")
	h_name.add_theme_font_size_override("font_size", 14)
	h_name.add_theme_color_override("font_color", C.COLOR_GOLD)
	host_vbox.add_child(h_name)
	var h_stats = Label.new()
	h_stats.text = "Vict: " + str(data.get("h_win",0)) + " / Derrot: " + str(data.get("h_loss",0))
	h_stats.add_theme_font_size_override("font_size", 11)
	h_stats.add_theme_color_override("font_color", C.COLOR_TEXT_DIM)
	host_vbox.add_child(h_stats)
	stats_hbox.add_child(host_vbox)

	var stats_spacer = Control.new()
	stats_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats_hbox.add_child(stats_spacer)

	var guest_vbox = VBoxContainer.new()
	guest_vbox.alignment = BoxContainer.ALIGNMENT_END
	var g_name = Label.new()
	g_name.text = data.get("guest","") if is_full else "Esperando"
	g_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	g_name.add_theme_font_size_override("font_size", 14)
	g_name.add_theme_color_override("font_color", C.COLOR_TEXT if is_full else C.COLOR_TEXT_DIM)
	guest_vbox.add_child(g_name)
	var g_stats = Label.new()
	g_stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	g_stats.add_theme_font_size_override("font_size", 11)
	g_stats.add_theme_color_override("font_color", C.COLOR_TEXT_DIM)
	g_stats.text = ("Vict: " + str(data.get("g_win",0)) + " / Derrot: " + str(data.get("g_loss",0))) if is_full else "Vict: - / Derrot: -"
	guest_vbox.add_child(g_stats)
	stats_hbox.add_child(guest_vbox)

	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(spacer)

	# Botones
	var btn_hbox = HBoxContainer.new()
	btn_hbox.add_theme_constant_override("separation", 10)
	main_vbox.add_child(btn_hbox)

	var btn_ver = Button.new()
	btn_ver.text = "VER MESA"
	btn_ver.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_ver.custom_minimum_size = Vector2(0, 36)
	btn_ver.add_theme_font_size_override("font_size", 12)
	btn_ver.add_theme_color_override("font_color", C.COLOR_GOLD_DIM)
	var st_ver = StyleBoxFlat.new()
	st_ver.bg_color = Color(0,0,0,0)
	st_ver.border_color = Color(C.COLOR_GOLD_DIM.r, C.COLOR_GOLD_DIM.g, C.COLOR_GOLD_DIM.b, 0.4)
	st_ver.border_width_left = 1; st_ver.border_width_right  = 1
	st_ver.border_width_top  = 1; st_ver.border_width_bottom = 1
	st_ver.corner_radius_top_left = 8; st_ver.corner_radius_top_right    = 8
	st_ver.corner_radius_bottom_left = 8; st_ver.corner_radius_bottom_right = 8
	var st_ver_hov = st_ver.duplicate(); st_ver_hov.bg_color = Color(1,1,1,0.05)
	btn_ver.add_theme_stylebox_override("normal",  st_ver)
	btn_ver.add_theme_stylebox_override("hover",   st_ver_hov)
	btn_ver.add_theme_stylebox_override("pressed", st_ver_hov)
	btn_hbox.add_child(btn_ver)

	var btn_join = Button.new()
	btn_join.text = "INGRESAR MESA"
	btn_join.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_join.custom_minimum_size = Vector2(0, 36)
	btn_join.add_theme_font_size_override("font_size", 12)
	btn_join.add_theme_color_override("font_color", C.COLOR_PANEL)
	var st_join = StyleBoxFlat.new()
	st_join.bg_color = C.COLOR_GOLD
	st_join.corner_radius_top_left    = 8; st_join.corner_radius_top_right    = 8
	st_join.corner_radius_bottom_left = 8; st_join.corner_radius_bottom_right = 8
	st_join.shadow_color = Color(C.COLOR_GOLD.r, C.COLOR_GOLD.g, C.COLOR_GOLD.b, 0.2)
	st_join.shadow_size = 10; st_join.shadow_offset = Vector2(0,3)
	var st_join_hov = st_join.duplicate(); st_join_hov.bg_color = C.COLOR_GOLD.lightened(0.1)
	if is_full:
		btn_join.disabled = true
		var st_dis = st_join.duplicate(); st_dis.bg_color = Color(0.15,0.17,0.20,0.9)
		btn_join.add_theme_stylebox_override("disabled", st_dis)
		btn_join.add_theme_color_override("font_disabled_color", Color(0.8,0.8,0.8,0.5))
	else:
		btn_join.pressed.connect(func():
			if NetworkManager.ws_connected:
				# ¡AQUÍ ESTÁ EL CAMBIO! Ahora mandamos el mazo activo de PlayerData
				NetworkManager.join_room(data.get("room_id",""), PlayerData.get_active_deck())
		)
	btn_join.add_theme_stylebox_override("normal", st_join)
	btn_join.add_theme_stylebox_override("hover",  st_join_hov)
	btn_hbox.add_child(btn_join)

	return card
