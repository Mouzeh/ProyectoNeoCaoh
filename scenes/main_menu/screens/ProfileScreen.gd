extends Node

# ============================================================
# ProfileScreen.gd
# Muestra perfil propio o de otro jugador (menu.viewing_username)
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
	title_lbl.text = "◈ POKÉMON TCG · PERFIL"
	title_lbl.add_theme_font_size_override("font_size", 16)
	title_lbl.add_theme_color_override("font_color", C.COLOR_GOLD)
	title_m.add_child(title_lbl)

	# ── Contenido principal (se llena tras fetch) ──
	var scroll = ScrollContainer.new()
	scroll.anchor_left = 0; scroll.anchor_right  = 1
	scroll.anchor_top  = 0; scroll.anchor_bottom = 1
	scroll.offset_top  = 120
	UITheme.apply_scrollbar_theme(scroll)
	container.add_child(scroll)

	var outer = MarginContainer.new()
	outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.add_theme_constant_override("margin_left",   40)
	outer.add_theme_constant_override("margin_right",  40)
	outer.add_theme_constant_override("margin_top",    24)
	outer.add_theme_constant_override("margin_bottom", 24)
	scroll.add_child(outer)

	var content_v = VBoxContainer.new()
	content_v.name = "ContentV"
	content_v.add_theme_constant_override("separation", 20)
	outer.add_child(content_v)

	var loading_lbl = Label.new()
	loading_lbl.text = "Cargando perfil..."
	loading_lbl.add_theme_color_override("font_color", C.COLOR_TEXT_DIM)
	loading_lbl.add_theme_font_size_override("font_size", 14)
	content_v.add_child(loading_lbl)

	# Determinar qué perfil cargar
	var target_username = menu.viewing_username if menu.viewing_username != "" else PlayerData.username
	menu.viewing_username = ""  # reset para próxima vez

	_fetch_profile(container, content_v, target_username, C, menu)


static func _fetch_profile(container: Control, content_v: VBoxContainer, username: String, C, menu) -> void:
	var url = NetworkManager.BASE_URL + "/api/social/profile"
	var http = HTTPRequest.new()
	container.add_child(http)

	var headers = []
	if NetworkManager.token != "":
		headers.append("Authorization: Bearer " + NetworkManager.token)

	http.request_completed.connect(func(result, code, _h, response_bytes):
		http.queue_free()
		for child in content_v.get_children(): child.queue_free()

		if result != HTTPRequest.RESULT_SUCCESS or code != 200:
			var err = Label.new()
			err.text = "⚠ No se pudo cargar el perfil de " + username
			err.add_theme_color_override("font_color", C.COLOR_RED)
			content_v.add_child(err)
			return

		var json = JSON.new()
		if json.parse(response_bytes.get_string_from_utf8()) != OK: return
		var data    = json.get_data()
		var player  = data.get("player", {})
		var stats   = data.get("stats",  {})
		var matches = data.get("matches", [])

		_build_profile(content_v, player, stats, matches, C, menu)
	)

	http.request(url + "/" + username, headers, HTTPClient.METHOD_GET)


static func _build_profile(content_v: VBoxContainer, player: Dictionary, stats: Dictionary, matches: Array, C, menu) -> void:
	var is_own = player.get("username", "") == PlayerData.username

	# ── Fila superior: avatar + stats + mazos ──
	var top_hbox = HBoxContainer.new()
	top_hbox.add_theme_constant_override("separation", 20)
	content_v.add_child(top_hbox)

	# ── Columna izquierda ──
	var left_col = VBoxContainer.new()
	left_col.custom_minimum_size = Vector2(260, 0)
	left_col.add_theme_constant_override("separation", 14)
	top_hbox.add_child(left_col)

	# Avatar card
	var avatar_card = _make_panel(C)
	avatar_card.custom_minimum_size = Vector2(0, 180)
	left_col.add_child(avatar_card)

	var avatar_v = VBoxContainer.new()
	avatar_v.alignment = BoxContainer.ALIGNMENT_CENTER
	avatar_v.add_theme_constant_override("separation", 8)
	avatar_card.add_child(avatar_v)

	var avatar_lbl = Label.new()
	avatar_lbl.text = "🎴"
	avatar_lbl.add_theme_font_size_override("font_size", 56)
	avatar_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	avatar_v.add_child(avatar_lbl)

	var name_lbl = Label.new()
	name_lbl.text = player.get("username", "")
	name_lbl.add_theme_font_size_override("font_size", 20)
	name_lbl.add_theme_color_override("font_color", C.COLOR_GOLD)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	avatar_v.add_child(name_lbl)

	var rank = player.get("rank", "BRONZE")
	var rank_lbl = Label.new()
	rank_lbl.text = _rank_icon(rank) + "  " + rank
	rank_lbl.add_theme_font_size_override("font_size", 12)
	rank_lbl.add_theme_color_override("font_color", _rank_color(rank, C))
	rank_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	avatar_v.add_child(rank_lbl)

	# Stats card
	var stats_card = _make_panel(C)
	left_col.add_child(stats_card)

	var stats_v = VBoxContainer.new()
	stats_v.add_theme_constant_override("separation", 10)
	stats_card.add_child(stats_v)

	_add_stat_row(stats_v, "⚔  ELO",        str(player.get("elo", 1000)),        C.COLOR_GOLD, C)
	_add_stat_row(stats_v, "🏆  Partidas",   str(stats.get("total", 0)),          C.COLOR_TEXT, C)
	_add_stat_row(stats_v, "✅  Victorias",  str(stats.get("wins", 0)),           C.COLOR_GREEN, C)
	_add_stat_row(stats_v, "❌  Derrotas",   str(stats.get("losses", 0)),         C.COLOR_RED, C)
	_add_stat_row(stats_v, "📊  Winrate",    str(stats.get("winrate", 0)) + "%",  _wr_color(stats.get("winrate", 0), C), C)
	_add_stat_row(stats_v, "🎯  Turnos avg", str(stats.get("avg_turns", 0)),      C.COLOR_TEXT_DIM, C)

	# Racha
	var streak = stats.get("streak", 0)
	if streak != 0:
		var streak_text  = ("🔥 Racha " + str(streak) + "V") if streak > 0 else ("💀 Racha " + str(abs(streak)) + "D")
		var streak_color = C.COLOR_GREEN if streak > 0 else C.COLOR_RED
		_add_stat_row(stats_v, "⚡  Racha", streak_text, streak_color, C)

	# Battle Pass
	var bp_card = _make_panel(C)
	left_col.add_child(bp_card)

	var bp_v = VBoxContainer.new()
	bp_v.add_theme_constant_override("separation", 6)
	bp_card.add_child(bp_v)

	var bp_lbl = Label.new()
	bp_lbl.text = "✦ Battle Pass — Nivel " + str(player.get("battle_pass_level", 1))
	bp_lbl.add_theme_font_size_override("font_size", 11)
	bp_lbl.add_theme_color_override("font_color", C.COLOR_GOLD)
	bp_v.add_child(bp_lbl)

	# Logout solo si es perfil propio
	if is_own:
		var spacer = Control.new(); spacer.custom_minimum_size = Vector2(0, 4)
		left_col.add_child(spacer)

		var logout_btn = Button.new()
		logout_btn.text = "Cerrar Sesión"
		logout_btn.custom_minimum_size = Vector2(0, 40)
		logout_btn.add_theme_font_size_override("font_size", 12)
		logout_btn.add_theme_color_override("font_color", Color(0.9, 0.4, 0.4))
		var st_l = StyleBoxFlat.new()
		st_l.bg_color = Color(0,0,0,0)
		st_l.border_color = Color(0.9, 0.4, 0.4, 0.5)
		st_l.border_width_left = 1; st_l.border_width_right  = 1
		st_l.border_width_top  = 1; st_l.border_width_bottom = 1
		st_l.corner_radius_top_left    = 6; st_l.corner_radius_top_right    = 6
		st_l.corner_radius_bottom_left = 6; st_l.corner_radius_bottom_right = 6
		logout_btn.add_theme_stylebox_override("normal", st_l)
		logout_btn.pressed.connect(func():
			PlayerData.logout()
			NetworkManager.disconnect_from_server()
			menu._show_screen(menu.Screen.LOGIN)
		)
		left_col.add_child(logout_btn)

	# ── Columna derecha: historial ──
	var right_col = VBoxContainer.new()
	right_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_col.add_theme_constant_override("separation", 12)
	top_hbox.add_child(right_col)

	var hist_title = Label.new()
	hist_title.text = "ÚLTIMAS PARTIDAS"
	hist_title.add_theme_font_size_override("font_size", 12)
	hist_title.add_theme_color_override("font_color", C.COLOR_GOLD_DIM)
	right_col.add_child(hist_title)

	if matches.size() == 0:
		var no_matches = Label.new()
		no_matches.text = "Sin partidas registradas aún"
		no_matches.add_theme_font_size_override("font_size", 13)
		no_matches.add_theme_color_override("font_color", C.COLOR_TEXT_DIM)
		right_col.add_child(no_matches)
	else:
		for match_data in matches:
			right_col.add_child(_make_match_row(match_data, player.get("username",""), C, menu))

	# Mazos (solo perfil propio)
	if is_own:
		content_v.add_child(_make_decks_section(C))


static func _make_match_row(match_data: Dictionary, username: String, C, menu) -> PanelContainer:
	var result = match_data.get("result", "LOSS")
	var p1     = match_data.get("player1", "")
	var p2     = match_data.get("player2", "")
	var opp    = p2 if p1 == username else p1

	var row = PanelContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var st = StyleBoxFlat.new()
	match result:
		"WIN":  st.bg_color = Color(0.1, 0.25, 0.1, 0.8)
		"LOSS": st.bg_color = Color(0.25, 0.1, 0.1, 0.8)
		_:      st.bg_color = Color(C.COLOR_PANEL.r, C.COLOR_PANEL.g, C.COLOR_PANEL.b, 0.6)
	st.border_color = Color(C.COLOR_GOLD_DIM.r, C.COLOR_GOLD_DIM.g, C.COLOR_GOLD_DIM.b, 0.15)
	st.border_width_left = 1; st.border_width_right  = 1
	st.border_width_top  = 1; st.border_width_bottom = 1
	st.corner_radius_top_left    = 6; st.corner_radius_top_right    = 6
	st.corner_radius_bottom_left = 6; st.corner_radius_bottom_right = 6
	row.add_theme_stylebox_override("panel", st)

	var m = MarginContainer.new()
	m.add_theme_constant_override("margin_left",  14)
	m.add_theme_constant_override("margin_right", 14)
	m.add_theme_constant_override("margin_top",    8)
	m.add_theme_constant_override("margin_bottom", 8)
	row.add_child(m)

	var hb = HBoxContainer.new()
	hb.add_theme_constant_override("separation", 12)
	m.add_child(hb)

	# Resultado badge
	var result_lbl = Label.new()
	result_lbl.text = "✅ WIN" if result == "WIN" else ("❌ LOSS" if result == "LOSS" else "➖ DRAW")
	result_lbl.custom_minimum_size = Vector2(70, 0)
	result_lbl.add_theme_font_size_override("font_size", 12)
	result_lbl.add_theme_color_override("font_color",
		C.COLOR_GREEN if result == "WIN" else (C.COLOR_RED if result == "LOSS" else C.COLOR_TEXT_DIM))
	hb.add_child(result_lbl)

	# vs
	var vs_lbl = Label.new()
	vs_lbl.text = "vs  " + opp
	vs_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vs_lbl.add_theme_font_size_override("font_size", 13)
	vs_lbl.add_theme_color_override("font_color", C.COLOR_TEXT)
	hb.add_child(vs_lbl)

	# Turnos
	var turns_lbl = Label.new()
	turns_lbl.text = str(match_data.get("turns", 0)) + " turnos"
	turns_lbl.custom_minimum_size = Vector2(70, 0)
	turns_lbl.add_theme_font_size_override("font_size", 11)
	turns_lbl.add_theme_color_override("font_color", C.COLOR_TEXT_DIM)
	turns_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hb.add_child(turns_lbl)

	# Click en opp para ver su perfil
	vs_lbl.mouse_filter = Control.MOUSE_FILTER_STOP
	vs_lbl.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	vs_lbl.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed:
			menu._show_profile(opp)
	)

	return row


static func _make_decks_section(C) -> VBoxContainer:
	var section = VBoxContainer.new()
	section.add_theme_constant_override("separation", 12)

	var title = Label.new()
	title.text = "MIS MAZOS"
	title.add_theme_font_size_override("font_size", 12)
	title.add_theme_color_override("font_color", C.COLOR_GOLD_DIM)
	section.add_child(title)

	var grid = GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	section.add_child(grid)

	for slot in range(1, 7):
		var card = _make_panel(C)
		card.custom_minimum_size = Vector2(0, 80)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(card)

		var dv = VBoxContainer.new()
		dv.alignment = BoxContainer.ALIGNMENT_CENTER
		dv.add_theme_constant_override("separation", 4)
		card.add_child(dv)

		var deck_name  = PlayerData.get_deck_name(slot)
		var deck_cards = PlayerData.get_deck(slot)
		var has_deck   = deck_name != ""

		var slot_lbl = Label.new()
		slot_lbl.text = "Slot " + str(slot)
		slot_lbl.add_theme_font_size_override("font_size", 10)
		slot_lbl.add_theme_color_override("font_color", C.COLOR_TEXT_DIM)
		slot_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		dv.add_child(slot_lbl)

		var name_lbl = Label.new()
		name_lbl.text = deck_name if has_deck else "— Vacío —"
		name_lbl.add_theme_font_size_override("font_size", 13)
		name_lbl.add_theme_color_override("font_color", C.COLOR_TEXT if has_deck else C.COLOR_TEXT_DIM)
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		dv.add_child(name_lbl)

		if has_deck:
			var count_lbl = Label.new()
			count_lbl.text = str(deck_cards.size()) + " cartas"
			count_lbl.add_theme_font_size_override("font_size", 10)
			count_lbl.add_theme_color_override("font_color", C.COLOR_TEXT_DIM)
			count_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			dv.add_child(count_lbl)

	return section


# ── Helpers ─────────────────────────────────────────────────

static func _make_panel(C) -> MarginContainer:
	var mc = MarginContainer.new()
	mc.add_theme_constant_override("margin_left",   18)
	mc.add_theme_constant_override("margin_right",  18)
	mc.add_theme_constant_override("margin_top",    14)
	mc.add_theme_constant_override("margin_bottom", 14)
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

static func _add_stat_row(parent: VBoxContainer, label: String, value: String, value_color: Color, C) -> void:
	var hb = HBoxContainer.new()
	parent.add_child(hb)
	var lbl = Label.new()
	lbl.text = label
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.add_theme_color_override("font_color", C.COLOR_TEXT_DIM)
	hb.add_child(lbl)
	var val = Label.new()
	val.text = value
	val.add_theme_font_size_override("font_size", 12)
	val.add_theme_color_override("font_color", value_color)
	hb.add_child(val)

static func _rank_icon(rank: String) -> String:
	match rank:
		"BRONZE":   return "🥉"
		"SILVER":   return "🥈"
		"GOLD":     return "🥇"
		"PLATINUM": return "💎"
		"DIAMOND":  return "💠"
		_:          return "🎖"

static func _rank_color(rank: String, C) -> Color:
	match rank:
		"BRONZE":   return Color(0.8, 0.5, 0.3)
		"SILVER":   return Color(0.7, 0.7, 0.75)
		"GOLD":     return C.COLOR_GOLD
		"PLATINUM": return Color(0.4, 0.8, 0.9)
		"DIAMOND":  return Color(0.5, 0.7, 1.0)
		_:          return C.COLOR_TEXT_DIM

static func _wr_color(wr: int, C) -> Color:
	if wr >= 60: return C.COLOR_GREEN
	if wr >= 45: return C.COLOR_TEXT
	return C.COLOR_RED
