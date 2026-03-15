extends Node

# ============================================================
# ProfileScreen.gd  — v3
# Muestra perfil propio o de otro jugador (menu.viewing_username)
# Colección, monedas y medallas visibles para todos
# ============================================================

static func build(container: Control, menu) -> void:
	var C = menu

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
	hs.shadow_color = Color(0, 0, 0, 0.5); hs.shadow_size = 20
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
	title_lbl.text = "◈  PERFIL DE JUGADOR"
	title_lbl.add_theme_font_size_override("font_size", 17)
	title_lbl.add_theme_color_override("font_color", C.COLOR_GOLD)
	title_v.add_child(title_lbl)

	var scroll = ScrollContainer.new()
	scroll.anchor_left = 0; scroll.anchor_right  = 1
	scroll.anchor_top  = 0; scroll.anchor_bottom = 1
	scroll.offset_top  = 72
	UITheme.apply_scrollbar_theme(scroll)
	container.add_child(scroll)

	var outer = MarginContainer.new()
	outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.add_theme_constant_override("margin_left",   48)
	outer.add_theme_constant_override("margin_right",  48)
	outer.add_theme_constant_override("margin_top",    28)
	outer.add_theme_constant_override("margin_bottom", 40)
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

	var target_username = menu.viewing_username if menu.viewing_username != "" else PlayerData.username
	menu.viewing_username = ""

	_fetch_profile(container, content_v, target_username, C, menu)


# ──────────────────────────────────────────────────────────────
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

		_build_profile(content_v, player, stats, matches, data, C, menu)
	)

	http.request(url + "/" + username.uri_encode(), headers, HTTPClient.METHOD_GET)


# ──────────────────────────────────────────────────────────────
static func _build_profile(content_v: VBoxContainer, player: Dictionary, stats: Dictionary, matches: Array, data: Dictionary, C, menu) -> void:
	var is_own = player.get("username", "") == PlayerData.username

	# ══════════════════════════════════════════════════
	# HERO BANNER
	# ══════════════════════════════════════════════════
	var hero = _make_card(C)
	hero.custom_minimum_size = Vector2(0, 140)
	content_v.add_child(hero)

	var rank     = player.get("rank", "BRONZE")
	var rank_col = _rank_color(rank, C)

	var hero_glow = ColorRect.new()
	hero_glow.set_anchors_preset(Control.PRESET_FULL_RECT)
	hero_glow.color = Color(rank_col.r, rank_col.g, rank_col.b, 0.07)
	hero_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hero.add_child(hero_glow)

	var hero_hb = HBoxContainer.new()
	hero_hb.add_theme_constant_override("separation", 24)
	hero.add_child(hero_hb)

	var avatar_wrap = MarginContainer.new()
	avatar_wrap.add_theme_constant_override("margin_left",  4)
	avatar_wrap.add_theme_constant_override("margin_right", 0)
	hero_hb.add_child(avatar_wrap)

	var avatar_panel = PanelContainer.new()
	avatar_panel.custom_minimum_size = Vector2(88, 88)
	var av_st = StyleBoxFlat.new()
	av_st.bg_color = Color(rank_col.r, rank_col.g, rank_col.b, 0.18)
	av_st.border_color = rank_col
	av_st.border_width_left = 2; av_st.border_width_right  = 2
	av_st.border_width_top  = 2; av_st.border_width_bottom = 2
	av_st.corner_radius_top_left    = 44; av_st.corner_radius_top_right    = 44
	av_st.corner_radius_bottom_left = 44; av_st.corner_radius_bottom_right = 44
	avatar_panel.add_theme_stylebox_override("panel", av_st)
	avatar_wrap.add_child(avatar_panel)

	var avatar_lbl = Label.new()
	avatar_lbl.text = "🎴"
	avatar_lbl.add_theme_font_size_override("font_size", 44)
	avatar_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	avatar_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	avatar_panel.add_child(avatar_lbl)

	var hero_info = VBoxContainer.new()
	hero_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hero_info.add_theme_constant_override("separation", 6)
	hero_hb.add_child(hero_info)

	var name_lbl = Label.new()
	name_lbl.text = player.get("username", "")
	name_lbl.add_theme_font_size_override("font_size", 26)
	name_lbl.add_theme_color_override("font_color", C.COLOR_GOLD)
	hero_info.add_child(name_lbl)

	var rank_badge_hb = HBoxContainer.new()
	rank_badge_hb.add_theme_constant_override("separation", 8)
	hero_info.add_child(rank_badge_hb)

	var rank_badge = PanelContainer.new()
	var rb_st = StyleBoxFlat.new()
	rb_st.bg_color = Color(rank_col.r, rank_col.g, rank_col.b, 0.18)
	rb_st.border_color = Color(rank_col.r, rank_col.g, rank_col.b, 0.5)
	rb_st.border_width_left = 1; rb_st.border_width_right  = 1
	rb_st.border_width_top  = 1; rb_st.border_width_bottom = 1
	rb_st.corner_radius_top_left    = 4; rb_st.corner_radius_top_right    = 4
	rb_st.corner_radius_bottom_left = 4; rb_st.corner_radius_bottom_right = 4
	rb_st.content_margin_left  = 8; rb_st.content_margin_right  = 8
	rb_st.content_margin_top   = 3; rb_st.content_margin_bottom = 3
	rank_badge.add_theme_stylebox_override("panel", rb_st)
	rank_badge_hb.add_child(rank_badge)

	var rank_lbl = Label.new()
	rank_lbl.text = _rank_icon(rank) + "  " + rank
	rank_lbl.add_theme_font_size_override("font_size", 11)
	rank_lbl.add_theme_color_override("font_color", rank_col)
	rank_badge.add_child(rank_lbl)

	var bp_badge = PanelContainer.new()
	var bp_st = StyleBoxFlat.new()
	bp_st.bg_color = Color(C.COLOR_GOLD.r, C.COLOR_GOLD.g, C.COLOR_GOLD.b, 0.10)
	bp_st.border_color = Color(C.COLOR_GOLD.r, C.COLOR_GOLD.g, C.COLOR_GOLD.b, 0.35)
	bp_st.border_width_left = 1; bp_st.border_width_right  = 1
	bp_st.border_width_top  = 1; bp_st.border_width_bottom = 1
	bp_st.corner_radius_top_left    = 4; bp_st.corner_radius_top_right    = 4
	bp_st.corner_radius_bottom_left = 4; bp_st.corner_radius_bottom_right = 4
	bp_st.content_margin_left  = 8; bp_st.content_margin_right  = 8
	bp_st.content_margin_top   = 3; bp_st.content_margin_bottom = 3
	rank_badge_hb.add_child(bp_badge)

	var bp_lbl = Label.new()
	bp_lbl.text = "✦ BP Nivel " + str(player.get("battle_pass_level", 1))
	bp_lbl.add_theme_font_size_override("font_size", 11)
	bp_lbl.add_theme_color_override("font_color", C.COLOR_GOLD)
	bp_badge.add_child(bp_lbl)

	var elo_lbl = Label.new()
	elo_lbl.text = "⚔  " + str(player.get("elo", 1000)) + " ELO"
	elo_lbl.add_theme_font_size_override("font_size", 16)
	elo_lbl.add_theme_color_override("font_color", C.COLOR_GOLD)
	hero_info.add_child(elo_lbl)

	if is_own:
		var logout_btn = _make_outline_button("🚪  Cerrar Sesión", Color(0.9, 0.4, 0.4), C)
		logout_btn.custom_minimum_size = Vector2(150, 36)
		var logout_col = VBoxContainer.new()
		var sp = Control.new()
		sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
		logout_col.add_child(sp)
		logout_col.add_child(logout_btn)
		hero_hb.add_child(logout_col)

		logout_btn.pressed.connect(func():
			var cfg_dir = DirAccess.open("user://")
			if cfg_dir and cfg_dir.file_exists("session.cfg"):
				cfg_dir.remove("session.cfg")
			PlayerData.logout()
			NetworkManager.disconnect_from_server()
			menu._show_screen(menu.Screen.LOGIN)
		)

	# ══════════════════════════════════════════════════
	# STATS RANKED
	# ══════════════════════════════════════════════════
	var wins    = stats.get("wins",    0)
	var losses  = stats.get("losses",  0)
	var total   = stats.get("total",   0)
	var winrate = stats.get("winrate", 0)
	var streak  = stats.get("streak",  0)
	var avg_t   = stats.get("avg_turns", 0)

	_add_section_title_standalone(content_v, "🏆  ESTADÍSTICAS RANKED", C)

	var stats_hb = HBoxContainer.new()
	stats_hb.add_theme_constant_override("separation", 12)
	content_v.add_child(stats_hb)

	_add_stat_card(stats_hb, "🏆", "Partidas",   str(total),           C.COLOR_TEXT,     C)
	_add_stat_card(stats_hb, "✅", "Victorias",  str(wins),            C.COLOR_GREEN,    C)
	_add_stat_card(stats_hb, "❌", "Derrotas",   str(losses),          C.COLOR_RED,      C)
	_add_stat_card(stats_hb, "📊", "Winrate",    str(winrate) + "%",   _wr_color(winrate, C), C)
	_add_stat_card(stats_hb, "🎯", "Avg Turnos", str(avg_t),           C.COLOR_TEXT_DIM, C)

	var streak_text  = ("🔥 +" + str(streak) + "V") if streak > 0 else (("💀 " + str(abs(streak)) + "D") if streak < 0 else "➖ 0")
	var streak_color = C.COLOR_GREEN if streak > 0 else (C.COLOR_RED if streak < 0 else C.COLOR_TEXT_DIM)
	_add_stat_card(stats_hb, "⚡", "Racha", streak_text, streak_color, C)

	# ══════════════════════════════════════════════════
	# STATS CASUAL
	# ══════════════════════════════════════════════════
	var casual_total   = stats.get("casual_total",   0)
	var casual_wins    = stats.get("casual_wins",    0)
	var casual_losses  = stats.get("casual_losses",  0)
	var casual_winrate = stats.get("casual_winrate", 0)

	_add_section_title_standalone(content_v, "🎮  ESTADÍSTICAS CASUAL", C)

	var casual_hb = HBoxContainer.new()
	casual_hb.add_theme_constant_override("separation", 12)
	content_v.add_child(casual_hb)

	_add_stat_card(casual_hb, "🎮", "Partidas",  str(casual_total),         C.COLOR_TEXT,  C)
	_add_stat_card(casual_hb, "✅", "Victorias", str(casual_wins),          C.COLOR_GREEN, C)
	_add_stat_card(casual_hb, "❌", "Derrotas",  str(casual_losses),        C.COLOR_RED,   C)
	_add_stat_card(casual_hb, "📊", "Winrate",   str(casual_winrate) + "%", _wr_color(casual_winrate, C), C)

	# ══════════════════════════════════════════════════
	# COLECCIÓN — visible para todos
	# ══════════════════════════════════════════════════
	_add_section_title_standalone(content_v, "📚  COLECCIÓN", C)

	var coll_card = _make_card(C)
	content_v.add_child(coll_card)

	var coll_hb = HBoxContainer.new()
	coll_hb.add_theme_constant_override("separation", 12)
	coll_card.add_child(coll_hb)

	var total_unique = CardDatabase.get_all_ids().size()
	var owned_unique = PlayerData.inventory.size()
	var total_cards  = 0
	for id in PlayerData.inventory.keys():
		total_cards += PlayerData.inventory[id]
	var pct = int(float(owned_unique) / max(total_unique, 1) * 100)

	_add_stat_card(coll_hb, "📚", "Únicas",       str(owned_unique) + "/" + str(total_unique), C.COLOR_ACCENT, C)
	_add_stat_card(coll_hb, "🃏", "Total cartas", str(total_cards),                            C.COLOR_GOLD,   C)
	_add_stat_card(coll_hb, "📈", "Completado",   str(pct) + "%",                              C.COLOR_GREEN if pct == 100 else C.COLOR_TEXT, C)

	var prog_v = VBoxContainer.new()
	prog_v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	prog_v.add_theme_constant_override("separation", 6)
	coll_hb.add_child(prog_v)

	var prog_lbl = Label.new()
	prog_lbl.text = "Progreso de colección"
	prog_lbl.add_theme_font_size_override("font_size", 11)
	prog_lbl.add_theme_color_override("font_color", C.COLOR_TEXT_DIM)
	prog_v.add_child(prog_lbl)

	var prog_bar = ProgressBar.new()
	prog_bar.min_value = 0
	prog_bar.max_value = total_unique
	prog_bar.value     = owned_unique
	prog_bar.custom_minimum_size = Vector2(0, 14)
	prog_bar.show_percentage = false
	prog_v.add_child(prog_bar)

	var prog_sub = Label.new()
	prog_sub.text = str(owned_unique) + " de " + str(total_unique) + " cartas únicas"
	prog_sub.add_theme_font_size_override("font_size", 10)
	prog_sub.add_theme_color_override("font_color", C.COLOR_TEXT_DIM)
	prog_v.add_child(prog_sub)

	# ══════════════════════════════════════════════════
	# MEDALLAS DE GYM (Próximamente) — visible para todos
	# ══════════════════════════════════════════════════
	_add_section_title_standalone(content_v, "🏅  MEDALLAS DE GIMNASIO", C)

	var medals_card = _make_card(C)
	content_v.add_child(medals_card)

	var medals_v = VBoxContainer.new()
	medals_v.add_theme_constant_override("separation", 10)
	medals_card.add_child(medals_v)

	var coming_soon_lbl = Label.new()
	coming_soon_lbl.text = "🚧  Próximamente — Las medallas de Gimnasio aparecerán aquí"
	coming_soon_lbl.add_theme_font_size_override("font_size", 13)
	coming_soon_lbl.add_theme_color_override("font_color", Color(C.COLOR_GOLD_DIM.r, C.COLOR_GOLD_DIM.g, C.COLOR_GOLD_DIM.b, 0.6))
	coming_soon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	medals_v.add_child(coming_soon_lbl)

	var gym_icons = ["🌿", "🔥", "💧", "⚡", "🔮", "👊", "🌑", "⚙️", "⭕"]
	var medals_hb = HBoxContainer.new()
	medals_hb.alignment = BoxContainer.ALIGNMENT_CENTER
	medals_hb.add_theme_constant_override("separation", 10)
	medals_v.add_child(medals_hb)

	for gym_icon in gym_icons:
		var badge_panel = PanelContainer.new()
		badge_panel.custom_minimum_size = Vector2(56, 56)
		var b_st = StyleBoxFlat.new()
		b_st.bg_color = Color(0.10, 0.10, 0.15, 0.7)
		b_st.border_color = Color(0.25, 0.25, 0.30, 0.5)
		b_st.border_width_left = 1; b_st.border_width_right  = 1
		b_st.border_width_top  = 1; b_st.border_width_bottom = 1
		b_st.corner_radius_top_left    = 28; b_st.corner_radius_top_right    = 28
		b_st.corner_radius_bottom_left = 28; b_st.corner_radius_bottom_right = 28
		badge_panel.add_theme_stylebox_override("panel", b_st)
		medals_hb.add_child(badge_panel)

		var b_lbl = Label.new()
		b_lbl.text = gym_icon
		b_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
		b_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		b_lbl.add_theme_font_size_override("font_size", 20)
		b_lbl.modulate = Color(1, 1, 1, 0.30)
		badge_panel.add_child(b_lbl)

	# ══════════════════════════════════════════════════
	# MONEDAS — visible para todos, datos del perfil visitado
	# ══════════════════════════════════════════════════
	_add_section_title_standalone(content_v, "🪙  MONEDAS", C)

	var coins_card = _make_card(C)
	content_v.add_child(coins_card)

	var coins_inner = VBoxContainer.new()
	coins_inner.add_theme_constant_override("separation", 10)
	coins_card.add_child(coins_inner)

	_fill_coins_from_data(coins_inner, data.get("coins", []), C)

	# ══════════════════════════════════════════════════
	# FILA INFERIOR: historial + mazos
	# ══════════════════════════════════════════════════
	var bottom_hb = HBoxContainer.new()
	bottom_hb.add_theme_constant_override("separation", 20)
	content_v.add_child(bottom_hb)

	var hist_col = VBoxContainer.new()
	hist_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hist_col.add_theme_constant_override("separation", 10)
	bottom_hb.add_child(hist_col)

	_add_section_title(hist_col, "📋  ÚLTIMAS PARTIDAS", C)

	if matches.size() == 0:
		var no_m = Label.new()
		no_m.text = "Sin partidas registradas aún"
		no_m.add_theme_font_size_override("font_size", 13)
		no_m.add_theme_color_override("font_color", C.COLOR_TEXT_DIM)
		hist_col.add_child(no_m)
	else:
		for match_data in matches:
			hist_col.add_child(_make_match_row(match_data, player.get("username", ""), C, menu))

	if is_own:
		var decks_col = VBoxContainer.new()
		decks_col.custom_minimum_size = Vector2(280, 0)
		decks_col.add_theme_constant_override("separation", 10)
		bottom_hb.add_child(decks_col)

		_add_section_title(decks_col, "🃏  MIS MAZOS", C)
		decks_col.add_child(_make_decks_grid(C))


# ──────────────────────────────────────────────────────────────
static func _fill_coins_from_data(parent: VBoxContainer, owned_coins: Array, C) -> void:
	for c in parent.get_children(): c.queue_free()

	if owned_coins.size() == 0:
		var empty = Label.new()
		empty.text = "Aún no tiene monedas personalizadas."
		empty.add_theme_font_size_override("font_size", 12)
		empty.add_theme_color_override("font_color", C.COLOR_TEXT_DIM)
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		parent.add_child(empty)
		return

	var coins_hb = HBoxContainer.new()
	coins_hb.add_theme_constant_override("separation", 14)
	parent.add_child(coins_hb)

	for coin in owned_coins:
		var equipped   = coin.get("equipped", false)
		var coin_name  = coin.get("name", "Moneda")
		var file_front = coin.get("file_front", "")
		var img_path   = "res://assets/imagen/tokens/TCG Flip Coins/CoinFont/" + file_front
		var glow       = Color(0.95, 0.78, 0.2)

		var box = PanelContainer.new()
		box.custom_minimum_size = Vector2(90, 110)
		var b_st = StyleBoxFlat.new()
		b_st.bg_color = Color(0.08, 0.09, 0.14, 0.95)
		b_st.border_width_left = 1; b_st.border_width_right  = 1
		b_st.border_width_top  = 1; b_st.border_width_bottom = 1
		b_st.corner_radius_top_left    = 10; b_st.corner_radius_top_right    = 10
		b_st.corner_radius_bottom_left = 10; b_st.corner_radius_bottom_right = 10
		if equipped:
			b_st.border_color = glow
			b_st.shadow_color = Color(glow.r, glow.g, glow.b, 0.4)
			b_st.shadow_size  = 10
		else:
			b_st.border_color = Color(0.25, 0.25, 0.35, 0.5)
		box.add_theme_stylebox_override("panel", b_st)
		coins_hb.add_child(box)

		var bv = VBoxContainer.new()
		bv.alignment = BoxContainer.ALIGNMENT_CENTER
		bv.add_theme_constant_override("separation", 6)
		box.add_child(bv)

		var icon = TextureRect.new()
		icon.custom_minimum_size = Vector2(52, 52)
		icon.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		if file_front != "" and ResourceLoader.exists(img_path):
			icon.texture = load(img_path)
		bv.add_child(icon)

		var n_lbl = Label.new()
		n_lbl.text = coin_name
		n_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		n_lbl.add_theme_font_size_override("font_size", 10)
		n_lbl.add_theme_color_override("font_color", glow if equipped else C.COLOR_TEXT_DIM)
		n_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		bv.add_child(n_lbl)

		if equipped:
			var eq_lbl = Label.new()
			eq_lbl.text = "✦ Equipada"
			eq_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			eq_lbl.add_theme_font_size_override("font_size", 9)
			eq_lbl.add_theme_color_override("font_color", glow)
			bv.add_child(eq_lbl)


# ──────────────────────────────────────────────────────────────
static func _add_section_title_standalone(parent: VBoxContainer, text: String, C) -> void:
	var m = MarginContainer.new()
	m.add_theme_constant_override("margin_top",    8)
	m.add_theme_constant_override("margin_bottom", 2)
	parent.add_child(m)
	var hb = HBoxContainer.new()
	hb.add_theme_constant_override("separation", 8)
	m.add_child(hb)
	var lbl = Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.add_theme_color_override("font_color", Color(C.COLOR_GOLD_DIM.r, C.COLOR_GOLD_DIM.g, C.COLOR_GOLD_DIM.b, 0.9))
	hb.add_child(lbl)
	var line = ColorRect.new()
	line.custom_minimum_size = Vector2(0, 1)
	line.color = Color(C.COLOR_GOLD_DIM.r, C.COLOR_GOLD_DIM.g, C.COLOR_GOLD_DIM.b, 0.15)
	line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(line)


# ──────────────────────────────────────────────────────────────
static func _add_stat_card(parent: HBoxContainer, icon: String, label: String, value: String, value_color: Color, C) -> void:
	var card = _make_card(C)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.custom_minimum_size   = Vector2(0, 80)
	parent.add_child(card)

	var v = VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 4)
	card.add_child(v)

	var icon_lbl = Label.new()
	icon_lbl.text = icon + "  " + label
	icon_lbl.add_theme_font_size_override("font_size", 10)
	icon_lbl.add_theme_color_override("font_color", C.COLOR_TEXT_DIM)
	icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(icon_lbl)

	var val_lbl = Label.new()
	val_lbl.text = value
	val_lbl.add_theme_font_size_override("font_size", 20)
	val_lbl.add_theme_color_override("font_color", value_color)
	val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(val_lbl)


# ──────────────────────────────────────────────────────────────
static func _make_match_row(match_data: Dictionary, username: String, C, menu) -> PanelContainer:
	var result = match_data.get("result", "LOSS")
	var p1     = match_data.get("player1", "")
	var p2     = match_data.get("player2", "")
	var opp    = p2 if p1 == username else p1
	var mode   = match_data.get("mode", "casual")

	var row = PanelContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var st = StyleBoxFlat.new()
	match result:
		"WIN":  st.bg_color = Color(0.06, 0.18, 0.08, 0.9)
		"LOSS": st.bg_color = Color(0.18, 0.06, 0.06, 0.9)
		_:      st.bg_color = Color(C.COLOR_PANEL.r, C.COLOR_PANEL.g, C.COLOR_PANEL.b, 0.6)

	var left_border_col = C.COLOR_GREEN if result == "WIN" else (C.COLOR_RED if result == "LOSS" else C.COLOR_TEXT_DIM)
	st.border_color = left_border_col
	st.border_width_left = 3
	st.border_width_right = 0; st.border_width_top = 0; st.border_width_bottom = 0
	st.corner_radius_top_left    = 6; st.corner_radius_top_right    = 6
	st.corner_radius_bottom_left = 6; st.corner_radius_bottom_right = 6
	row.add_theme_stylebox_override("panel", st)

	var m = MarginContainer.new()
	m.add_theme_constant_override("margin_left",  14)
	m.add_theme_constant_override("margin_right", 14)
	m.add_theme_constant_override("margin_top",    9)
	m.add_theme_constant_override("margin_bottom", 9)
	row.add_child(m)

	var hb = HBoxContainer.new()
	hb.add_theme_constant_override("separation", 12)
	m.add_child(hb)

	var result_lbl = Label.new()
	result_lbl.text = "✅ WIN" if result == "WIN" else ("❌ LOSS" if result == "LOSS" else "➖ DRAW")
	result_lbl.custom_minimum_size = Vector2(72, 0)
	result_lbl.add_theme_font_size_override("font_size", 12)
	result_lbl.add_theme_color_override("font_color",
		C.COLOR_GREEN if result == "WIN" else (C.COLOR_RED if result == "LOSS" else C.COLOR_TEXT_DIM))
	hb.add_child(result_lbl)

	var mode_lbl = Label.new()
	mode_lbl.text = "🏆" if mode == "ranking" else "🎮"
	mode_lbl.tooltip_text = "Ranked" if mode == "ranking" else "Casual"
	mode_lbl.add_theme_font_size_override("font_size", 12)
	hb.add_child(mode_lbl)

	var vs_lbl = Label.new()
	vs_lbl.text = "vs  " + opp
	vs_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vs_lbl.add_theme_font_size_override("font_size", 13)
	vs_lbl.add_theme_color_override("font_color", C.COLOR_TEXT)
	vs_lbl.mouse_filter = Control.MOUSE_FILTER_STOP
	vs_lbl.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	vs_lbl.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed:
			menu._show_profile(opp)
	)
	hb.add_child(vs_lbl)

	var turns_lbl = Label.new()
	turns_lbl.text = str(match_data.get("turns", 0)) + " turnos"
	turns_lbl.custom_minimum_size = Vector2(70, 0)
	turns_lbl.add_theme_font_size_override("font_size", 11)
	turns_lbl.add_theme_color_override("font_color", C.COLOR_TEXT_DIM)
	turns_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hb.add_child(turns_lbl)

	return row


# ──────────────────────────────────────────────────────────────
static func _make_decks_grid(C) -> GridContainer:
	var grid = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)

	for slot in range(1, 7):
		var deck_name  = PlayerData.get_deck_name(slot)
		var deck_cards = PlayerData.get_deck(slot)
		var has_deck   = deck_name != ""

		var card = _make_card(C)
		card.custom_minimum_size   = Vector2(0, 72)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(card)

		if has_deck:
			var tint = ColorRect.new()
			tint.set_anchors_preset(Control.PRESET_FULL_RECT)
			tint.color = Color(0.06, 0.25, 0.1, 0.15)
			tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
			card.add_child(tint)

		var dv = VBoxContainer.new()
		dv.alignment = BoxContainer.ALIGNMENT_CENTER
		dv.add_theme_constant_override("separation", 3)
		card.add_child(dv)

		var slot_lbl = Label.new()
		slot_lbl.text = "Slot " + str(slot)
		slot_lbl.add_theme_font_size_override("font_size", 9)
		slot_lbl.add_theme_color_override("font_color", C.COLOR_TEXT_DIM)
		slot_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		dv.add_child(slot_lbl)

		var name_lbl = Label.new()
		name_lbl.text = deck_name if has_deck else "— Vacío —"
		name_lbl.add_theme_font_size_override("font_size", 13)
		name_lbl.add_theme_color_override("font_color", C.COLOR_GREEN if has_deck else C.COLOR_TEXT_DIM)
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		dv.add_child(name_lbl)

		if has_deck:
			var count_lbl = Label.new()
			count_lbl.text = str(deck_cards.size()) + " cartas"
			count_lbl.add_theme_font_size_override("font_size", 10)
			count_lbl.add_theme_color_override("font_color", C.COLOR_TEXT_DIM)
			count_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			dv.add_child(count_lbl)

	return grid


# ══════════════════════════════════════════════════════════════
# HELPERS
# ══════════════════════════════════════════════════════════════

static func _make_card(C) -> MarginContainer:
	var mc = MarginContainer.new()
	mc.add_theme_constant_override("margin_left",   18)
	mc.add_theme_constant_override("margin_right",  18)
	mc.add_theme_constant_override("margin_top",    14)
	mc.add_theme_constant_override("margin_bottom", 14)
	var st = StyleBoxFlat.new()
	st.bg_color     = Color(0.07, 0.07, 0.11, 0.92)
	st.border_color = Color(C.COLOR_GOLD_DIM.r, C.COLOR_GOLD_DIM.g, C.COLOR_GOLD_DIM.b, 0.18)
	st.border_width_left = 1; st.border_width_right  = 1
	st.border_width_top  = 1; st.border_width_bottom = 1
	st.corner_radius_top_left    = 10; st.corner_radius_top_right    = 10
	st.corner_radius_bottom_left = 10; st.corner_radius_bottom_right = 10
	st.shadow_color = Color(0, 0, 0, 0.3); st.shadow_size = 12
	mc.add_theme_stylebox_override("panel", st)
	return mc

static func _add_section_title(parent: VBoxContainer, text: String, C) -> void:
	var m = MarginContainer.new()
	m.add_theme_constant_override("margin_bottom", 2)
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
	st.corner_radius_top_left    = 6; st.corner_radius_top_right    = 6
	st.corner_radius_bottom_left = 6; st.corner_radius_bottom_right = 6
	var st_hov = st.duplicate()
	st_hov.bg_color = Color(col.r, col.g, col.b, 0.12)
	st_hov.border_color = col
	btn.add_theme_stylebox_override("normal",  st)
	btn.add_theme_stylebox_override("hover",   st_hov)
	return btn

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
