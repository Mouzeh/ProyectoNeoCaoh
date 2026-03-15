extends Node

# ============================================================
# RankingScreen.gd
# Top 20 global por ELO + posición del jugador actual
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
	header.offset_top  = 0; header.offset_bottom = 120
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
	title_lbl.text = "◈ POKÉMON TCG · RANKING GLOBAL"
	title_lbl.add_theme_font_size_override("font_size", 16)
	title_lbl.add_theme_color_override("font_color", C.COLOR_GOLD)
	title_m.add_child(title_lbl)

	# ── Contenido ──
	var center = MarginContainer.new()
	center.anchor_left = 0; center.anchor_right  = 1
	center.anchor_top  = 0; center.anchor_bottom = 1
	center.offset_top  = 120
	center.add_theme_constant_override("margin_left",   40)
	center.add_theme_constant_override("margin_right",  40)
	center.add_theme_constant_override("margin_top",    24)
	center.add_theme_constant_override("margin_bottom", 24)
	container.add_child(center)

	var main_v = VBoxContainer.new()
	main_v.add_theme_constant_override("separation", 16)
	center.add_child(main_v)

	# ── Mi posición (placeholder hasta cargar) ──
	var my_card = _make_panel(C)
	my_card.name = "MyCard"
	my_card.custom_minimum_size = Vector2(0, 70)
	main_v.add_child(my_card)

	var my_lbl = Label.new()
	my_lbl.name = "MyLabel"
	my_lbl.text = "Cargando tu posición..."
	my_lbl.add_theme_font_size_override("font_size", 13)
	my_lbl.add_theme_color_override("font_color", C.COLOR_TEXT_DIM)
	my_card.add_child(my_lbl)

	# ── Cabecera tabla ──
	var header_row = _make_row_header(C)
	main_v.add_child(header_row)

	# ── Scroll con tabla ──
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	UITheme.apply_scrollbar_theme(scroll)
	main_v.add_child(scroll)

	var table_v = VBoxContainer.new()
	table_v.name = "TableV"
	table_v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	table_v.add_theme_constant_override("separation", 4)
	scroll.add_child(table_v)

	var loading_lbl = Label.new()
	loading_lbl.text = "Cargando ranking..."
	loading_lbl.add_theme_font_size_override("font_size", 13)
	loading_lbl.add_theme_color_override("font_color", C.COLOR_TEXT_DIM)
	loading_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	table_v.add_child(loading_lbl)

	# ── Fetch ──
	_fetch_ranking(container, table_v, my_card, my_lbl, C, menu)


static func _fetch_ranking(container: Control, table_v: VBoxContainer, my_card, my_lbl: Label, C, menu) -> void:
	var url = NetworkManager.BASE_URL + "/api/social/ranking"
	var http = HTTPRequest.new()
	container.add_child(http)

	var headers = []
	if NetworkManager.token != "":
		headers.append("Authorization: Bearer " + NetworkManager.token)

	http.request_completed.connect(func(result, code, _headers, response_bytes):
		http.queue_free()

		if result != HTTPRequest.RESULT_SUCCESS or code != 200:
			for child in table_v.get_children(): child.queue_free()
			var err_lbl = Label.new()
			err_lbl.text = "⚠ No se pudo cargar el ranking"
			err_lbl.add_theme_color_override("font_color", C.COLOR_RED)
			table_v.add_child(err_lbl)
			return

		var json = JSON.new()
		if json.parse(response_bytes.get_string_from_utf8()) != OK: return
		var data = json.get_data()

		# Limpiar loading
		for child in table_v.get_children(): child.queue_free()

		# Filas del ranking
		var ranking = data.get("ranking", [])
		for entry in ranking:
			var is_me = entry.get("username", "") == PlayerData.username
			var row = _make_row(entry, is_me, C, menu)
			table_v.add_child(row)

		# Mi posición
		var my_pos = data.get("my_position", null)
		_update_my_card(my_card, my_lbl, my_pos, C)
	)

	http.request(url, headers, HTTPClient.METHOD_GET)


static func _update_my_card(my_card, my_lbl: Label, my_pos, C) -> void:
	for child in my_card.get_children(): child.queue_free()

	if my_pos == null:
		var lbl = Label.new()
		lbl.text = "Juega partidas para aparecer en el ranking"
		lbl.add_theme_font_size_override("font_size", 12)
		lbl.add_theme_color_override("font_color", C.COLOR_TEXT_DIM)
		my_card.add_child(lbl)
		return

	var hb = HBoxContainer.new()
	hb.add_theme_constant_override("separation", 20)
	my_card.add_child(hb)

	var pos_lbl = Label.new()
	pos_lbl.text = "#" + str(my_pos.get("position", "?"))
	pos_lbl.custom_minimum_size = Vector2(60, 0)
	pos_lbl.add_theme_font_size_override("font_size", 28)
	pos_lbl.add_theme_color_override("font_color", C.COLOR_GOLD)
	hb.add_child(pos_lbl)

	var info_v = VBoxContainer.new()
	info_v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_v.add_theme_constant_override("separation", 4)
	hb.add_child(info_v)

	var name_lbl = Label.new()
	name_lbl.text = "👤 " + my_pos.get("username", "") + "  —  Tu posición"
	name_lbl.add_theme_font_size_override("font_size", 14)
	name_lbl.add_theme_color_override("font_color", C.COLOR_TEXT)
	info_v.add_child(name_lbl)

	var stats_lbl = Label.new()
	stats_lbl.text = "ELO %d  ·  %s  ·  %d/%d partidas  ·  %d%% winrate" % [
		my_pos.get("elo", 0),
		my_pos.get("rank", ""),
		my_pos.get("wins", 0),
		my_pos.get("total", 0),
		my_pos.get("winrate", 0),
	]
	stats_lbl.add_theme_font_size_override("font_size", 11)
	stats_lbl.add_theme_color_override("font_color", C.COLOR_TEXT_DIM)
	info_v.add_child(stats_lbl)


static func _make_row(entry: Dictionary, is_me: bool, C, menu) -> PanelContainer:
	var row = PanelContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var st = StyleBoxFlat.new()
	if is_me:
		st.bg_color = Color(C.COLOR_GOLD.r, C.COLOR_GOLD.g, C.COLOR_GOLD.b, 0.1)
		st.border_color = Color(C.COLOR_GOLD.r, C.COLOR_GOLD.g, C.COLOR_GOLD.b, 0.5)
		st.border_width_left = 2
	else:
		st.bg_color = Color(C.COLOR_PANEL.r, C.COLOR_PANEL.g, C.COLOR_PANEL.b, 0.5)
		st.border_color = Color(C.COLOR_GOLD_DIM.r, C.COLOR_GOLD_DIM.g, C.COLOR_GOLD_DIM.b, 0.1)
		st.border_width_left = 1; st.border_width_right  = 1
		st.border_width_top  = 1; st.border_width_bottom = 1
	st.corner_radius_top_left    = 6; st.corner_radius_top_right    = 6
	st.corner_radius_bottom_left = 6; st.corner_radius_bottom_right = 6
	row.add_theme_stylebox_override("panel", st)

	var m = MarginContainer.new()
	m.add_theme_constant_override("margin_left",  16)
	m.add_theme_constant_override("margin_right", 16)
	m.add_theme_constant_override("margin_top",    8)
	m.add_theme_constant_override("margin_bottom", 8)
	row.add_child(m)

	var hb = HBoxContainer.new()
	hb.add_theme_constant_override("separation", 16)
	m.add_child(hb)

	# Posición
	var pos = entry.get("position", 0)
	var pos_lbl = Label.new()
	pos_lbl.text = _medal(pos)
	pos_lbl.custom_minimum_size = Vector2(40, 0)
	pos_lbl.add_theme_font_size_override("font_size", 18)
	pos_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hb.add_child(pos_lbl)

	# Nombre (clickeable para ver perfil)
	var name_btn = Button.new()
	name_btn.text = entry.get("username", "")
	name_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_btn.add_theme_font_size_override("font_size", 14)
	name_btn.add_theme_color_override("font_color", C.COLOR_GOLD if is_me else C.COLOR_TEXT)
	var st_name = StyleBoxFlat.new()
	st_name.bg_color = Color(0,0,0,0)
	name_btn.add_theme_stylebox_override("normal",  st_name)
	name_btn.add_theme_stylebox_override("hover",   st_name)
	name_btn.add_theme_stylebox_override("pressed", st_name)
	name_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var uname = entry.get("username", "")
	name_btn.pressed.connect(func(): menu._show_profile(uname))
	hb.add_child(name_btn)

	# Rango
	var rank_lbl = Label.new()
	rank_lbl.text = _rank_icon(entry.get("rank", "")) + " " + entry.get("rank", "")
	rank_lbl.custom_minimum_size = Vector2(100, 0)
	rank_lbl.add_theme_font_size_override("font_size", 12)
	rank_lbl.add_theme_color_override("font_color", _rank_color(entry.get("rank",""), C))
	hb.add_child(rank_lbl)

	# ELO
	var elo_lbl = Label.new()
	elo_lbl.text = str(entry.get("elo", 0))
	elo_lbl.custom_minimum_size = Vector2(70, 0)
	elo_lbl.add_theme_font_size_override("font_size", 14)
	elo_lbl.add_theme_color_override("font_color", C.COLOR_GOLD)
	elo_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hb.add_child(elo_lbl)

	# Winrate
	var wr_lbl = Label.new()
	wr_lbl.text = str(entry.get("winrate", 0)) + "%"
	wr_lbl.custom_minimum_size = Vector2(55, 0)
	wr_lbl.add_theme_font_size_override("font_size", 13)
	wr_lbl.add_theme_color_override("font_color", _wr_color(entry.get("winrate", 0), C))
	wr_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hb.add_child(wr_lbl)

	# Partidas
	var games_lbl = Label.new()
	games_lbl.text = str(entry.get("wins",0)) + "W / " + str(entry.get("total",0) - entry.get("wins",0)) + "L"
	games_lbl.custom_minimum_size = Vector2(90, 0)
	games_lbl.add_theme_font_size_override("font_size", 11)
	games_lbl.add_theme_color_override("font_color", C.COLOR_TEXT_DIM)
	games_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hb.add_child(games_lbl)

	return row


static func _make_row_header(C) -> PanelContainer:
	var row = PanelContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var st = StyleBoxFlat.new()
	st.bg_color = Color(0,0,0,0)
	row.add_theme_stylebox_override("panel", st)

	var m = MarginContainer.new()
	m.add_theme_constant_override("margin_left",  16)
	m.add_theme_constant_override("margin_right", 16)
	row.add_child(m)

	var hb = HBoxContainer.new()
	hb.add_theme_constant_override("separation", 16)
	m.add_child(hb)

	for col in [["#", 40], ["Jugador", 0], ["Rango", 100], ["ELO", 70], ["Winrate", 55], ["Partidas", 90]]:
		var lbl = Label.new()
		lbl.text = col[0]
		if col[1] > 0:
			lbl.custom_minimum_size = Vector2(col[1], 0)
		else:
			lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl.add_theme_font_size_override("font_size", 11)
		lbl.add_theme_color_override("font_color", C.COLOR_GOLD_DIM)
		if col[0] in ["ELO", "Winrate", "Partidas"]:
			lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		hb.add_child(lbl)

	return row


static func _make_panel(C) -> MarginContainer:
	var mc = MarginContainer.new()
	mc.add_theme_constant_override("margin_left",   20)
	mc.add_theme_constant_override("margin_right",  20)
	mc.add_theme_constant_override("margin_top",    14)
	mc.add_theme_constant_override("margin_bottom", 14)
	var st = StyleBoxFlat.new()
	st.bg_color = Color(C.COLOR_PANEL.r, C.COLOR_PANEL.g, C.COLOR_PANEL.b, 0.85)
	st.border_color = Color(C.COLOR_GOLD_DIM.r, C.COLOR_GOLD_DIM.g, C.COLOR_GOLD_DIM.b, 0.3)
	st.border_width_left = 1; st.border_width_right  = 1
	st.border_width_top  = 1; st.border_width_bottom = 1
	st.corner_radius_top_left    = 10; st.corner_radius_top_right    = 10
	st.corner_radius_bottom_left = 10; st.corner_radius_bottom_right = 10
	st.shadow_color = Color(0,0,0,0.2); st.shadow_size = 10
	mc.add_theme_stylebox_override("panel", st)
	return mc


static func _medal(pos: int) -> String:
	match pos:
		1: return "🥇"
		2: return "🥈"
		3: return "🥉"
		_: return "#" + str(pos)

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
