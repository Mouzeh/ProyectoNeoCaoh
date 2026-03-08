extends Node

# ============================================================
# GymScreen.gd
# Pantalla principal de GYMs — 9 tipos en grid
# ============================================================

const GYM_DATA = [
	{ "id": "gym_grass",     "name": "Planta",    "icon": "res://assets/imagen/TypesIcons/grass.png",    "color": Color(0.13, 0.35, 0.15) },
	{ "id": "gym_fire",      "name": "Fuego",     "icon": "res://assets/imagen/TypesIcons/fire.png",     "color": Color(0.45, 0.15, 0.05) },
	{ "id": "gym_water",     "name": "Agua",      "icon": "res://assets/imagen/TypesIcons/water.png",    "color": Color(0.08, 0.22, 0.48) },
	{ "id": "gym_lightning", "name": "Rayo",      "icon": "res://assets/imagen/TypesIcons/electric.png", "color": Color(0.40, 0.35, 0.05) },
	{ "id": "gym_psychic",   "name": "Psíquico",  "icon": "res://assets/imagen/TypesIcons/psy.png",      "color": Color(0.35, 0.10, 0.38) },
	{ "id": "gym_fighting",  "name": "Lucha",     "icon": "res://assets/imagen/TypesIcons/figth.png",    "color": Color(0.40, 0.22, 0.08) },
	{ "id": "gym_darkness",  "name": "Oscuridad", "icon": "res://assets/imagen/TypesIcons/dark.png",     "color": Color(0.10, 0.08, 0.18) },
	{ "id": "gym_metal",     "name": "Metal",     "icon": "res://assets/imagen/TypesIcons/metal.png",    "color": Color(0.22, 0.25, 0.30) },
	{ "id": "gym_colorless", "name": "Incoloro",  "icon": "res://assets/imagen/TypesIcons/incolor.png",  "color": Color(0.28, 0.26, 0.22) }
]

# ── Caché estático ────────────────────────────────────────
static var _st_card_normal: StyleBoxFlat = null
static var _st_card_hover:  StyleBoxFlat = null
static var _st_card_medal:  StyleBoxFlat = null
static var _tex_cache: Dictionary = {}

static func clear_cache() -> void:
	_st_card_normal = null
	_st_card_hover  = null
	_st_card_medal  = null
	_tex_cache.clear()

static func _get_tex(path: String) -> Texture2D:
	if path not in _tex_cache:
		_tex_cache[path] = load(path) if ResourceLoader.exists(path) else null
	return _tex_cache[path]

static func _get_st_card_normal(C) -> StyleBoxFlat:
	if not _st_card_normal:
		var st = StyleBoxFlat.new()
		st.bg_color = Color(C.COLOR_PANEL.r, C.COLOR_PANEL.g, C.COLOR_PANEL.b, 0.85)
		st.border_color = Color(C.COLOR_GOLD_DIM.r, C.COLOR_GOLD_DIM.g, C.COLOR_GOLD_DIM.b, 0.3)
		st.border_width_left = 1; st.border_width_right  = 1
		st.border_width_top  = 1; st.border_width_bottom = 3
		st.corner_radius_top_left    = 16; st.corner_radius_top_right    = 16
		st.corner_radius_bottom_left = 16; st.corner_radius_bottom_right = 16
		st.shadow_color = Color(0, 0, 0, 0.3); st.shadow_size = 12
		_st_card_normal = st
	return _st_card_normal

static func _get_st_card_hover(C) -> StyleBoxFlat:
	if not _st_card_hover:
		var st = _get_st_card_normal(C).duplicate()
		st.bg_color = Color(C.COLOR_PANEL.r + 0.08, C.COLOR_PANEL.g + 0.08, C.COLOR_PANEL.b + 0.08, 0.95)
		st.border_color = C.COLOR_GOLD
		st.border_width_bottom = 4
		st.shadow_color = Color(C.COLOR_GOLD.r, C.COLOR_GOLD.g, C.COLOR_GOLD.b, 0.2)
		st.shadow_size = 24
		_st_card_hover = st
	return _st_card_hover

static func _get_st_card_medal(C) -> StyleBoxFlat:
	if not _st_card_medal:
		var st = _get_st_card_normal(C).duplicate()
		st.border_color = C.COLOR_GOLD
		st.border_width_bottom = 4
		st.shadow_color = Color(C.COLOR_GOLD.r, C.COLOR_GOLD.g, C.COLOR_GOLD.b, 0.25)
		st.shadow_size = 16
		_st_card_medal = st
	return _st_card_medal


# ============================================================
# ENTRY POINT
# ============================================================
static func build(container: Control, menu) -> void:
	var C = menu

	# ── Loading overlay mientras refresca datos ──
	var loading_lbl = Label.new()
	loading_lbl.text = "Actualizando gimnasios..."
	loading_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	loading_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	loading_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	loading_lbl.add_theme_font_size_override("font_size", 16)
	loading_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	container.add_child(loading_lbl)

	# ── Refrescar GymManager antes de construir la UI ──
	GymManager.fetch_gyms(func(ok: bool):
		if not is_instance_valid(loading_lbl): return
		loading_lbl.queue_free()
		_build_ui(container, menu, C)
	)


static func _build_ui(container: Control, menu, C) -> void:
	# ── 1. Fondo ──
	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.06, 0.07, 0.10, 1.0)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(bg)

	# ── 2. Header ──
	var header = Panel.new()
	header.anchor_left = 0; header.anchor_right  = 1
	header.anchor_top  = 0; header.anchor_bottom = 0
	header.offset_top  = 40; header.offset_bottom = 120
	var hs = StyleBoxFlat.new()
	hs.bg_color = Color(C.COLOR_PANEL.r, C.COLOR_PANEL.g, C.COLOR_PANEL.b, 0.90)
	hs.border_color = Color(C.COLOR_GOLD.r, C.COLOR_GOLD.g, C.COLOR_GOLD.b, 0.5)
	hs.border_width_bottom = 2
	hs.shadow_color = Color(0, 0, 0, 0.4); hs.shadow_size = 25
	header.add_theme_stylebox_override("panel", hs)
	container.add_child(header)

	var hbox = HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	header.add_child(hbox)

	var accent = ColorRect.new()
	accent.color = C.COLOR_GOLD
	accent.custom_minimum_size = Vector2(8, 0)
	hbox.add_child(accent)

	var title_m = MarginContainer.new()
	title_m.add_theme_constant_override("margin_left", 30)
	title_m.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(title_m)

	var title_v = VBoxContainer.new()
	title_v.alignment = BoxContainer.ALIGNMENT_CENTER
	title_m.add_child(title_v)

	var title_lbl = Label.new()
	title_lbl.text = "◈ POKÉMON TCG · GIMNASIOS"
	title_lbl.add_theme_font_size_override("font_size", 18)
	title_lbl.add_theme_color_override("font_color", C.COLOR_GOLD)
	title_v.add_child(title_lbl)

	var medals_lbl = Label.new()
	medals_lbl.add_theme_font_size_override("font_size", 13)
	medals_lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	title_v.add_child(medals_lbl)

	# ── 3. Scroll ──
	var scroll = ScrollContainer.new()
	scroll.anchor_left = 0; scroll.anchor_right  = 1
	scroll.anchor_top  = 0; scroll.anchor_bottom = 1
	scroll.offset_top  = 120
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	UITheme.apply_scrollbar_theme(scroll)
	container.add_child(scroll)

	var center_wrap = CenterContainer.new()
	center_wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center_wrap.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	scroll.add_child(center_wrap)

	var inner_v = VBoxContainer.new()
	inner_v.custom_minimum_size = Vector2(1050, 0)
	inner_v.add_theme_constant_override("separation", 30)
	center_wrap.add_child(inner_v)

	var spacer_top = Control.new()
	spacer_top.custom_minimum_size = Vector2(0, 20)
	inner_v.add_child(spacer_top)

	var subtitle = Label.new()
	subtitle.text = "Reta a los Líderes de Gimnasio y gana sus medallas"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 15)
	subtitle.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	inner_v.add_child(subtitle)

	var sep = ColorRect.new()
	sep.custom_minimum_size = Vector2(200, 2)
	sep.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	sep.color = Color(C.COLOR_GOLD_DIM.r, C.COLOR_GOLD_DIM.g, C.COLOR_GOLD_DIM.b, 0.3)
	inner_v.add_child(sep)

	# ── 4. Grid ──
	var grid_wrap = CenterContainer.new()
	grid_wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inner_v.add_child(grid_wrap)

	var grid = GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 25)
	grid.add_theme_constant_override("v_separation", 25)
	grid_wrap.add_child(grid)

	var st_normal = _get_st_card_normal(C)
	var st_hover  = _get_st_card_hover(C)
	var st_medal  = _get_st_card_medal(C)

	var medal_count = 0

	for gym in GYM_DATA:
		var gym_id: String = gym["id"]

		var gym_server_data: Dictionary = GymManager.get_gym_data(gym_id)
		var has_medal: bool             = GymManager.has_medal(gym_id)

		# ── FIX: usar leader_username en lugar de leader_user_id ──
		var leader_name: String = gym_server_data.get("leader_username", "")
		if leader_name == "":
			# fallback: si el backend aún no devuelve username, mostrar "Vacante"
			leader_name = ""

		if has_medal:
			medal_count += 1

		var card = _make_gym_card(gym, leader_name, has_medal, C, st_normal, st_hover, st_medal, menu)
		grid.add_child(card)

	medals_lbl.text = "Medallas: %d / 9  ·  %d 🪙" % [medal_count, PlayerData.coins]

	var spacer_bot = Control.new()
	spacer_bot.custom_minimum_size = Vector2(0, 40)
	inner_v.add_child(spacer_bot)


# ============================================================
# TARJETA DE GYM
# ============================================================
static func _make_gym_card(gym: Dictionary, leader_name: String, has_medal: bool, C, st_normal: StyleBoxFlat, st_hover: StyleBoxFlat, st_medal: StyleBoxFlat, menu) -> Button:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(320, 180)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	var st_base = st_medal if has_medal else st_normal
	btn.add_theme_stylebox_override("normal",  st_base)
	btn.add_theme_stylebox_override("hover",   st_hover)
	btn.add_theme_stylebox_override("pressed", st_base)
	btn.add_theme_stylebox_override("focus",   StyleBoxEmpty.new())

	var color_bar = ColorRect.new()
	color_bar.color = Color(gym["color"].r, gym["color"].g, gym["color"].b, 0.6)
	color_bar.anchor_left  = 0; color_bar.anchor_right  = 1
	color_bar.anchor_top   = 0; color_bar.anchor_bottom = 0
	color_bar.offset_bottom = 6
	color_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(color_bar)

	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left",   25)
	margin.add_theme_constant_override("margin_right",  25)
	margin.add_theme_constant_override("margin_top",    20)
	margin.add_theme_constant_override("margin_bottom", 20)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 8)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(vbox)

	var icon_tex = TextureRect.new()
	icon_tex.texture = _get_tex(gym["icon"])
	icon_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_tex.custom_minimum_size = Vector2(48, 48)
	icon_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(icon_tex)

	var name_lbl = Label.new()
	name_lbl.text = "GIM " + gym["name"].to_upper()
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 16)
	name_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.95))
	name_lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	name_lbl.add_theme_constant_override("shadow_offset_x", 1)
	name_lbl.add_theme_constant_override("shadow_offset_y", 1)
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(name_lbl)

	# ── Líder: muestra username o "Vacante" ──
	var leader_lbl = Label.new()
	leader_lbl.text = "Líder: " + (leader_name if leader_name != "" else "Vacante")
	leader_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	leader_lbl.add_theme_font_size_override("font_size", 12)
	leader_lbl.add_theme_color_override("font_color",
		Color(0.9, 0.75, 0.3) if leader_name != "" else Color(0.5, 0.5, 0.5))
	leader_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(leader_lbl)

	if has_medal:
		var medal_badge = Label.new()
		medal_badge.text = "🏅 MEDALLA OBTENIDA"
		medal_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		medal_badge.add_theme_font_size_override("font_size", 11)
		medal_badge.add_theme_color_override("font_color", C.COLOR_GOLD)
		medal_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(medal_badge)

	var gym_id = gym["id"]
	btn.pressed.connect(func(): menu.navigate_to("GymTypeScreen", { "gym_id": gym_id }))

	return btn
