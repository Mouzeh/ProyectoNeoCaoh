extends Node

# ============================================================
# GymTypeScreen.gd
# Vista interna de un GYM — Líder, Sub-Líder, Grunts, Reto PvP
# ============================================================

const TYPE_ICONS = {
	"gym_grass":     "res://assets/imagen/TypesIcons/grass.png",
	"gym_fire":      "res://assets/imagen/TypesIcons/fire.png",
	"gym_water":     "res://assets/imagen/TypesIcons/water.png",
	"gym_lightning": "res://assets/imagen/TypesIcons/electric.png",
	"gym_psychic":   "res://assets/imagen/TypesIcons/psy.png",
	"gym_fighting":  "res://assets/imagen/TypesIcons/figth.png",
	"gym_darkness":  "res://assets/imagen/TypesIcons/dark.png",
	"gym_metal":     "res://assets/imagen/TypesIcons/metal.png",
	"gym_colorless": "res://assets/imagen/TypesIcons/incolor.png",
}

const TYPE_COLORS = {
	"gym_grass":     Color(0.13, 0.45, 0.18),
	"gym_fire":      Color(0.65, 0.20, 0.05),
	"gym_water":     Color(0.08, 0.30, 0.65),
	"gym_lightning": Color(0.55, 0.48, 0.05),
	"gym_psychic":   Color(0.50, 0.12, 0.52),
	"gym_fighting":  Color(0.55, 0.28, 0.08),
	"gym_darkness":  Color(0.15, 0.10, 0.28),
	"gym_metal":     Color(0.30, 0.33, 0.40),
	"gym_colorless": Color(0.38, 0.35, 0.28),
}

const GYM_NAMES = {
	"gym_grass":     "Gimnasio Planta",
	"gym_fire":      "Gimnasio Fuego",
	"gym_water":     "Gimnasio Agua",
	"gym_lightning": "Gimnasio Rayo",
	"gym_psychic":   "Gimnasio Psíquico",
	"gym_fighting":  "Gimnasio Lucha",
	"gym_darkness":  "Gimnasio Oscuridad",
	"gym_metal":     "Gimnasio Metal",
	"gym_colorless": "Gimnasio Incoloro",
}

const GYM_TYPES_MAP = {
	"gym_grass":     "GRASS",
	"gym_fire":      "FIRE",
	"gym_water":     "WATER",
	"gym_lightning": "LIGHTNING",
	"gym_psychic":   "PSYCHIC",
	"gym_fighting":  "FIGHTING",
	"gym_darkness":  "DARKNESS",
	"gym_metal":     "METAL",
	"gym_colorless": "COLORLESS",
}

const ROLE_LABEL = {
	"leader":     "👑 LÍDER",
	"sub_leader": "⭐ SUB-LÍDER",
	"grunt":      "⚔️ GRUNT",
}

const TIER_COLORS = {
	"SS": Color(1.0,  0.85, 0.1),
	"S":  Color(0.9,  0.5,  0.1),
	"A":  Color(0.4,  0.8,  0.3),
	"B":  Color(0.3,  0.6,  1.0),
	"C":  Color(0.6,  0.6,  0.6),
}

static var _tex_cache: Dictionary = {}
static var _gym_data_cache: Dictionary = {}  # { gym_id: { data: {...}, timestamp: float } }
const GYM_CACHE_TTL = 60.0  # segundos

static func clear_cache() -> void:
	_tex_cache.clear()
	_gym_data_cache.clear()

static func _invalidate_gym_cache(gym_id: String) -> void:
	_gym_data_cache.erase(gym_id)

static func _get_tex(path: String) -> Texture2D:
	if path not in _tex_cache:
		_tex_cache[path] = load(path) if ResourceLoader.exists(path) else null
	return _tex_cache[path]


# ============================================================
# ENTRY POINT
# ============================================================
static func build(container: Control, menu, params: Dictionary) -> void:
	var C = menu
	var gym_id     : String = params.get("gym_id", "gym_grass")
	var type_color : Color  = TYPE_COLORS.get(gym_id, Color(0.2, 0.2, 0.2))
	var gym_name   : String = GYM_NAMES.get(gym_id, "Gimnasio")
	var icon_path  : String = TYPE_ICONS.get(gym_id, "")

	# ── Fondo ──
	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color       = Color(type_color.r * 0.2, type_color.g * 0.2, type_color.b * 0.2, 1.0)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(bg)

	var grad_overlay = ColorRect.new()
	grad_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	grad_overlay.color       = Color(0.04, 0.05, 0.08, 0.7)
	grad_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(grad_overlay)

	# ── Header ──
	var header = Panel.new()
	header.anchor_left = 0; header.anchor_right  = 1
	header.anchor_top  = 0; header.anchor_bottom = 0
	header.offset_top  = 40; header.offset_bottom = 130
	var hs = StyleBoxFlat.new()
	hs.bg_color     = Color(C.COLOR_PANEL.r, C.COLOR_PANEL.g, C.COLOR_PANEL.b, 0.92)
	hs.border_color = type_color
	hs.border_width_bottom = 3
	hs.shadow_color = Color(type_color.r, type_color.g, type_color.b, 0.3)
	hs.shadow_size  = 20
	header.add_theme_stylebox_override("panel", hs)
	container.add_child(header)

	var hbox = HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	header.add_child(hbox)

	var accent = ColorRect.new()
	accent.color              = type_color
	accent.custom_minimum_size = Vector2(8, 0)
	hbox.add_child(accent)

	var icon_margin = MarginContainer.new()
	icon_margin.add_theme_constant_override("margin_left",   20)
	icon_margin.add_theme_constant_override("margin_right",  10)
	icon_margin.add_theme_constant_override("margin_top",    10)
	icon_margin.add_theme_constant_override("margin_bottom", 10)
	hbox.add_child(icon_margin)

	var icon_tex = TextureRect.new()
	icon_tex.custom_minimum_size = Vector2(55, 55)
	icon_tex.expand_mode         = TextureRect.EXPAND_IGNORE_SIZE
	icon_tex.stretch_mode        = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var tex = _get_tex(icon_path)
	if tex: icon_tex.texture = tex
	icon_margin.add_child(icon_tex)

	var title_m = MarginContainer.new()
	title_m.add_theme_constant_override("margin_left", 10)
	title_m.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(title_m)

	var title_v = VBoxContainer.new()
	title_v.alignment = BoxContainer.ALIGNMENT_CENTER
	title_m.add_child(title_v)

	var title_lbl = Label.new()
	title_lbl.text = "◈ " + gym_name.to_upper()
	title_lbl.add_theme_font_size_override("font_size", 20)
	title_lbl.add_theme_color_override("font_color", Color(
		lerpf(type_color.r, 1.0, 0.6),
		lerpf(type_color.g, 1.0, 0.6),
		lerpf(type_color.b, 1.0, 0.6)
	))
	title_v.add_child(title_lbl)

	var sub_lbl = Label.new()
	sub_lbl.text = "Cargando información..."
	sub_lbl.add_theme_font_size_override("font_size", 13)
	sub_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	sub_lbl.name = "SubLbl"
	title_v.add_child(sub_lbl)

	# ── Botones del header (derecha) ──
	var btns_m = MarginContainer.new()
	btns_m.add_theme_constant_override("margin_right",  30)
	btns_m.add_theme_constant_override("margin_top",    20)
	btns_m.add_theme_constant_override("margin_bottom", 20)
	hbox.add_child(btns_m)

	var btns_hbox = HBoxContainer.new()
	btns_hbox.add_theme_constant_override("separation", 10)
	btns_hbox.alignment = BoxContainer.ALIGNMENT_END
	btns_m.add_child(btns_hbox)

	# ── Botón Panel del Líder ──
	var leader_btn = Button.new()
	leader_btn.text    = "👑 Panel del Líder"
	leader_btn.name    = "LeaderPanelBtn"
	leader_btn.custom_minimum_size            = Vector2(160, 40)
	leader_btn.mouse_default_cursor_shape     = Control.CURSOR_POINTING_HAND
	leader_btn.visible = false
	var lb_st = _header_btn_style(type_color, 0.25)
	var lb_hov = _header_btn_style(type_color, 0.5)
	leader_btn.add_theme_stylebox_override("normal", lb_st)
	leader_btn.add_theme_stylebox_override("hover",  lb_hov)
	leader_btn.add_theme_stylebox_override("focus",  StyleBoxEmpty.new())
	leader_btn.add_theme_color_override("font_color", Color(
		lerpf(type_color.r, 1.0, 0.6),
		lerpf(type_color.g, 1.0, 0.6),
		lerpf(type_color.b, 1.0, 0.6)
	))
	leader_btn.add_theme_font_size_override("font_size", 13)
	leader_btn.pressed.connect(func():
		menu.navigate_to("LiderGymScreen", {"gym_id": gym_id})
	)
	btns_hbox.add_child(leader_btn)

	# ── Botón "🛠️ Mis Mazos del Gym" (grunt / sub-líder) ──
	var member_deck_btn = Button.new()
	member_deck_btn.text    = "🛠️ Mis Mazos del Gym"
	member_deck_btn.name    = "MemberDeckBtn"
	member_deck_btn.custom_minimum_size        = Vector2(190, 40)
	member_deck_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	member_deck_btn.visible = false
	var mb_st  = _header_btn_style(type_color, 0.25)
	var mb_hov = _header_btn_style(type_color, 0.5)
	member_deck_btn.add_theme_stylebox_override("normal", mb_st)
	member_deck_btn.add_theme_stylebox_override("hover",  mb_hov)
	member_deck_btn.add_theme_stylebox_override("focus",  StyleBoxEmpty.new())
	member_deck_btn.add_theme_color_override("font_color", Color(
		lerpf(type_color.r, 1.0, 0.6),
		lerpf(type_color.g, 1.0, 0.6),
		lerpf(type_color.b, 1.0, 0.6)
	))
	member_deck_btn.add_theme_font_size_override("font_size", 13)
	btns_hbox.add_child(member_deck_btn)

	# ── Botón Volver ──
	var back_btn = Button.new()
	back_btn.text = "← Volver"
	back_btn.custom_minimum_size        = Vector2(110, 40)
	back_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var bb_st = StyleBoxFlat.new()
	bb_st.bg_color     = Color(1, 1, 1, 0.07)
	bb_st.border_color = Color(0.6, 0.6, 0.6, 0.5)
	bb_st.border_width_left = 1; bb_st.border_width_right  = 1
	bb_st.border_width_top  = 1; bb_st.border_width_bottom = 1
	bb_st.corner_radius_top_left    = 20; bb_st.corner_radius_top_right    = 20
	bb_st.corner_radius_bottom_left = 20; bb_st.corner_radius_bottom_right = 20
	var bb_hov = bb_st.duplicate()
	bb_hov.bg_color     = Color(1, 1, 1, 0.15)
	bb_hov.border_color = Color(0.8, 0.8, 0.8, 0.8)
	back_btn.add_theme_stylebox_override("normal", bb_st)
	back_btn.add_theme_stylebox_override("hover",  bb_hov)
	back_btn.add_theme_stylebox_override("focus",  StyleBoxEmpty.new())
	back_btn.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	back_btn.pressed.connect(func(): menu.navigate_to("GymScreen", {}))
	btns_hbox.add_child(back_btn)

	# ── Scroll ──
	var scroll = ScrollContainer.new()
	scroll.anchor_left = 0; scroll.anchor_right  = 1
	scroll.anchor_top  = 0; scroll.anchor_bottom = 1
	scroll.offset_top  = 130
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	UITheme.apply_scrollbar_theme(scroll)
	container.add_child(scroll)

	var center_wrap = CenterContainer.new()
	center_wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center_wrap.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	scroll.add_child(center_wrap)

	var inner_v = VBoxContainer.new()
	inner_v.custom_minimum_size = Vector2(1000, 0)
	inner_v.add_theme_constant_override("separation", 25)
	center_wrap.add_child(inner_v)

	var spacer_top = Control.new()
	spacer_top.custom_minimum_size = Vector2(0, 15)
	inner_v.add_child(spacer_top)

	# Panel de progreso
	var progress_panel = _make_progress_panel(C, type_color)
	progress_panel.name = "ProgressPanel"
	inner_v.add_child(progress_panel)

	# Sección miembros
	var members_title = Label.new()
	members_title.text = "MIEMBROS DEL GIMNASIO (PvP)"
	members_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	members_title.add_theme_font_size_override("font_size", 14)
	members_title.add_theme_color_override("font_color", Color(
		lerpf(type_color.r, 1.0, 0.5),
		lerpf(type_color.g, 1.0, 0.5),
		lerpf(type_color.b, 1.0, 0.5)
	))
	inner_v.add_child(members_title)

	var members_vbox = VBoxContainer.new()
	members_vbox.add_theme_constant_override("separation", 10)
	members_vbox.name = "MembersVBox"
	inner_v.add_child(members_vbox)

	var loading_lbl = Label.new()
	loading_lbl.text = "Cargando miembros..."
	loading_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	loading_lbl.add_theme_font_size_override("font_size", 13)
	loading_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	loading_lbl.name = "LoadingLbl"
	members_vbox.add_child(loading_lbl)

	var spacer_bot = Control.new()
	spacer_bot.custom_minimum_size = Vector2(0, 40)
	inner_v.add_child(spacer_bot)

	# Fetch
	_fetch_gym_type_data(container, C, gym_id, type_color,
		sub_lbl, members_vbox, progress_panel, leader_btn, member_deck_btn, menu)


# ── Helper para estilos de botones del header ──
static func _header_btn_style(type_color: Color, alpha: float) -> StyleBoxFlat:
	var st = StyleBoxFlat.new()
	st.bg_color     = Color(type_color.r, type_color.g, type_color.b, alpha)
	st.border_color = type_color
	st.border_width_left = 1; st.border_width_right  = 1
	st.border_width_top  = 1; st.border_width_bottom = 2
	st.corner_radius_top_left    = 20; st.corner_radius_top_right    = 20
	st.corner_radius_bottom_left = 20; st.corner_radius_bottom_right = 20
	return st


# ============================================================
# PANEL DE PROGRESO
# ============================================================
static func _make_progress_panel(C, type_color: Color) -> Panel:
	var panel = Panel.new()
	var st = StyleBoxFlat.new()
	st.bg_color     = Color(type_color.r * 0.15, type_color.g * 0.15, type_color.b * 0.15, 0.9)
	st.border_color = Color(type_color.r, type_color.g, type_color.b, 0.4)
	st.border_width_left = 1; st.border_width_right  = 1
	st.border_width_top  = 1; st.border_width_bottom = 1
	st.corner_radius_top_left    = 12; st.corner_radius_top_right    = 12
	st.corner_radius_bottom_left = 12; st.corner_radius_bottom_right = 12
	st.content_margin_left   = 30; st.content_margin_right  = 30
	st.content_margin_top    = 20; st.content_margin_bottom = 20
	panel.add_theme_stylebox_override("panel", st)
	panel.custom_minimum_size = Vector2(0, 80)

	var hbox = HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 40)
	panel.add_child(hbox)

	for item in [["TierLbl","TU TIER",22], ["ProgLbl","PROGRESO",16], ["StateLbl","ESTADO",14]]:
		if item[0] != "TierLbl":
			var vsep = ColorRect.new()
			vsep.custom_minimum_size = Vector2(1, 40)
			vsep.color               = Color(1, 1, 1, 0.1)
			hbox.add_child(vsep)

		var v = VBoxContainer.new()
		v.alignment = BoxContainer.ALIGNMENT_CENTER
		hbox.add_child(v)

		var cap = Label.new()
		cap.text = item[1]
		cap.add_theme_font_size_override("font_size", 11)
		cap.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(cap)

		var lbl = Label.new()
		lbl.text = "—"
		lbl.add_theme_font_size_override("font_size", item[2])
		lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.name = item[0]
		v.add_child(lbl)

	return panel


# ============================================================
# FILA DE MIEMBRO
# ============================================================
# my_gym_decks_map: el dict { "SS":[...], "S":[...], ... } del jugador actual
# (solo relevante para mostrar estado de decks en la propia fila del miembro logueado)
static func _make_member_row(member: Dictionary, C, type_color: Color,
		grunts_defeated: Array, sub_leader_defeated: bool,
		gym_id: String, my_gym_decks_map: Dictionary, leader_decks: Dictionary = {}) -> Panel:

	var role     : String = str(member.get("role",     "grunt")) if member.get("role")     != null else "grunt"
	var username : String = str(member.get("username", "???"))   if member.get("username") != null else "???"
	var wins     : int   = int(member.get("wins",   0))
	var losses   : int   = int(member.get("losses", 0))
	var winrate  : int   = int(member.get("winrate",0))
	var raw_uid          = member.get("user_id", "")
	var user_id  : String = str(raw_uid) if raw_uid != null else ""

	var is_leader  = role == "leader"
	var is_sub     = role == "sub_leader"
	var is_grunt   = role == "grunt"
	var is_me      = (user_id != "" and user_id == NetworkManager.player_id)

	# ¿Este miembro ya fue derrotado en el reto activo?
	var is_defeated = false
	if is_grunt:
		is_defeated = user_id in grunts_defeated
	elif is_sub:
		is_defeated = sub_leader_defeated

	# ── Panel exterior ──
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(0, 70)
	var st = StyleBoxFlat.new()
	if is_leader:
		st.bg_color     = Color(type_color.r * 0.3, type_color.g * 0.3, type_color.b * 0.3, 0.9)
		st.border_color = type_color
		st.border_width_left = 6
	elif is_sub:
		st.bg_color     = Color(type_color.r * 0.18, type_color.g * 0.18, type_color.b * 0.18, 0.85)
		st.border_color = Color(type_color.r, type_color.g, type_color.b, 0.6)
		st.border_width_left = 4
	else:
		st.bg_color     = Color(C.COLOR_PANEL.r, C.COLOR_PANEL.g, C.COLOR_PANEL.b, 0.7)
		st.border_color = Color(1, 1, 1, 0.1)
		st.border_width_left = 3

	st.border_width_right = 1; st.border_width_top = 1; st.border_width_bottom = 1
	st.corner_radius_top_left    = 10; st.corner_radius_top_right    = 10
	st.corner_radius_bottom_left = 10; st.corner_radius_bottom_right = 10
	st.content_margin_left   = 20; st.content_margin_right  = 20
	st.content_margin_top    = 12; st.content_margin_bottom = 12

	# Si está derrotado, atenuar
	if is_defeated:
		st.bg_color.a = 0.35
		st.border_color = Color(0.3, 0.6, 0.3, 0.8)
		st.border_width_left = 4

	panel.add_theme_stylebox_override("panel", st)

	var hbox = HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.add_theme_constant_override("separation", 20)
	panel.add_child(hbox)

	# ── Columna izquierda: rol + nombre ──
	var left_v = VBoxContainer.new()
	left_v.alignment             = BoxContainer.ALIGNMENT_CENTER
	left_v.custom_minimum_size   = Vector2(220, 0)
	left_v.add_theme_constant_override("separation", 3)
	hbox.add_child(left_v)

	var role_color = type_color if is_leader else \
		Color(lerpf(type_color.r,1,0.35), lerpf(type_color.g,1,0.35), lerpf(type_color.b,1,0.35)) if is_sub \
		else Color(0.6, 0.6, 0.6)

	var role_lbl = Label.new()
	role_lbl.text = ROLE_LABEL.get(role, "⚔️ GRUNT")
	role_lbl.add_theme_font_size_override("font_size", 11)
	role_lbl.add_theme_color_override("font_color", role_color)
	left_v.add_child(role_lbl)

	var name_row = HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 8)
	left_v.add_child(name_row)

	var name_lbl = Label.new()
	name_lbl.text = username
	name_lbl.add_theme_font_size_override("font_size", 16 if is_leader else 14)
	name_lbl.add_theme_color_override("font_color", Color(1,1,1,0.9) if is_leader else Color(0.85,0.85,0.85))
	name_row.add_child(name_lbl)

	if is_me:
		var me_badge = Label.new()
		me_badge.text = "(Tú)"
		me_badge.add_theme_font_size_override("font_size", 11)
		me_badge.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		me_badge.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		name_row.add_child(me_badge)

	# ── Separador ──
	var sep = ColorRect.new()
	sep.custom_minimum_size = Vector2(1, 40)
	sep.color               = Color(1, 1, 1, 0.07)
	sep.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox.add_child(sep)

	# ── Columna centro: W/L stats ──
	var stats_v = VBoxContainer.new()
	stats_v.alignment           = BoxContainer.ALIGNMENT_CENTER
	stats_v.custom_minimum_size = Vector2(140, 0)
	stats_v.add_theme_constant_override("separation", 2)
	hbox.add_child(stats_v)

	var stats_cap = Label.new()
	stats_cap.text = "ESTADÍSTICAS"
	stats_cap.add_theme_font_size_override("font_size", 10)
	stats_cap.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
	stats_v.add_child(stats_cap)

	var stats_lbl = Label.new()
	stats_lbl.text = "%dW  %dL  (%d%%)" % [wins, losses, winrate]
	stats_lbl.add_theme_font_size_override("font_size", 13)
	stats_lbl.add_theme_color_override("font_color",
		Color(0.4, 0.85, 0.4) if winrate >= 50 else Color(0.75, 0.4, 0.4))
	stats_v.add_child(stats_lbl)

	# ── Separador ──
	var sep2 = ColorRect.new()
	sep2.custom_minimum_size = Vector2(1, 40)
	sep2.color               = Color(1, 1, 1, 0.07)
	sep2.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox.add_child(sep2)

	# ── Columna: estado de decks por tier (solo para el miembro que soy yo) ──
	if is_me and not is_leader and not my_gym_decks_map.is_empty():
		var tiers_v = VBoxContainer.new()
		tiers_v.alignment           = BoxContainer.ALIGNMENT_CENTER
		tiers_v.custom_minimum_size = Vector2(200, 0)
		tiers_v.add_theme_constant_override("separation", 3)
		hbox.add_child(tiers_v)

		var tiers_cap = Label.new()
		tiers_cap.text = "MIS MAZOS"
		tiers_cap.add_theme_font_size_override("font_size", 10)
		tiers_cap.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
		tiers_v.add_child(tiers_cap)

		var tiers_hbox = HBoxContainer.new()
		tiers_hbox.add_theme_constant_override("separation", 8)
		tiers_v.add_child(tiers_hbox)

		for tier in ["SS", "S", "A", "B"]:
			var deck_size = my_gym_decks_map.get(tier, []).size()
			var ready     = deck_size == 60
			var tc        = TIER_COLORS.get(tier, Color(0.5, 0.5, 0.5))

			var tier_badge_panel = PanelContainer.new()
			var tb_st = StyleBoxFlat.new()
			tb_st.bg_color     = Color(tc.r * 0.2, tc.g * 0.2, tc.b * 0.2, 0.9) if ready else Color(0.08, 0.08, 0.08, 0.8)
			tb_st.border_color = tc if ready else Color(0.25, 0.25, 0.25)
			tb_st.border_width_left = 1; tb_st.border_width_right  = 1
			tb_st.border_width_top  = 1; tb_st.border_width_bottom = 1
			tb_st.corner_radius_top_left    = 6; tb_st.corner_radius_top_right    = 6
			tb_st.corner_radius_bottom_left = 6; tb_st.corner_radius_bottom_right = 6
			tb_st.content_margin_left = 8; tb_st.content_margin_right  = 8
			tb_st.content_margin_top  = 3; tb_st.content_margin_bottom = 3
			tier_badge_panel.add_theme_stylebox_override("panel", tb_st)
			tiers_hbox.add_child(tier_badge_panel)

			var tier_lbl = Label.new()
			tier_lbl.text = ("✅ " if ready else "—  ") + tier
			tier_lbl.add_theme_font_size_override("font_size", 11)
			tier_lbl.add_theme_color_override("font_color", tc if ready else Color(0.35, 0.35, 0.35))
			tier_badge_panel.add_child(tier_lbl)

		var sep3 = ColorRect.new()
		sep3.custom_minimum_size = Vector2(1, 40)
		sep3.color               = Color(1, 1, 1, 0.07)
		sep3.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		hbox.add_child(sep3)

	# ── Columna derecha: derrotado / Retar ── (size_flags EXPAND para empujar a la derecha)
	var right_v = VBoxContainer.new()
	right_v.alignment           = BoxContainer.ALIGNMENT_CENTER
	right_v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_v.custom_minimum_size = Vector2(120, 0)
	hbox.add_child(right_v)

	if is_defeated:
		# Badge "Derrotado"
		var defeated_lbl = Label.new()
		defeated_lbl.text = "✅ Derrotado"
		defeated_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		defeated_lbl.add_theme_font_size_override("font_size", 13)
		defeated_lbl.add_theme_color_override("font_color", Color(0.35, 0.85, 0.35))
		right_v.add_child(defeated_lbl)
	elif is_me:
		# No se puede retar a sí mismo — vacío
		pass
	elif user_id != "":
		# Botón retar
		var chal_btn = _make_challenge_button(user_id, gym_id, type_color)
		chal_btn.size_flags_horizontal = Control.SIZE_SHRINK_END

		# Si es el líder, verificar que tenga los 4 decks completos
		if is_leader:
			var missing : Array = []
			for t in ["SS", "S", "A", "B"]:
				if leader_decks.get(t, []).size() != 60:
					missing.append(t)
			if missing.size() > 0:
				chal_btn.disabled = true
				chal_btn.text     = "🔒 No listo"
				chal_btn.mouse_default_cursor_shape = Control.CURSOR_ARROW
				var not_ready_lbl = Label.new()
				not_ready_lbl.text = "Faltan decks: " + ", ".join(missing)
				not_ready_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
				not_ready_lbl.add_theme_font_size_override("font_size", 10)
				not_ready_lbl.add_theme_color_override("font_color", Color(0.9, 0.5, 0.2))
				right_v.add_child(not_ready_lbl)

		right_v.add_child(chal_btn)

	return panel


static func _make_challenge_button(defender_id: String, gym_id: String, type_color: Color) -> Button:
	var btn = Button.new()
	btn.text = "⚔️ Retar"
	btn.custom_minimum_size        = Vector2(100, 36)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	var st = StyleBoxFlat.new()
	st.bg_color = Color(type_color.r * 0.8, type_color.g * 0.8, type_color.b * 0.8, 0.8)
	st.corner_radius_top_left    = 6; st.corner_radius_top_right    = 6
	st.corner_radius_bottom_left = 6; st.corner_radius_bottom_right = 6
	var st_hov = st.duplicate(); st_hov.bg_color = type_color
	var st_dis = st.duplicate(); st_dis.bg_color = Color(0.3, 0.3, 0.3, 0.6)

	btn.add_theme_stylebox_override("normal",   st)
	btn.add_theme_stylebox_override("hover",    st_hov)
	btn.add_theme_stylebox_override("disabled", st_dis)
	btn.add_theme_font_size_override("font_size", 13)

	btn.pressed.connect(func():
		_send_gym_challenge(defender_id, gym_id, btn)
	)
	return btn


static func _send_gym_challenge(defender_id: String, gym_id: String, btn: Button) -> void:
	var active_slot  = str(PlayerData.active_deck_slot)
	var my_deck_data = PlayerData.decks.get(active_slot, {})
	var my_cards     = my_deck_data.get("cards", [])

	if my_cards.size() != 60:
		NetworkManager.emit_signal("error_received", "Tu mazo activo no tiene 60 cartas.")
		return

	var my_tier = CardDatabase.calculate_deck_tier(my_cards)

	var msg = {
		"type": "GYM_CHALLENGE_REQUEST",
		"payload": {
			"target_user_id":  defender_id,
			"gym_id":          gym_id,
			"challenger_tier": my_tier,
			"challenger_deck": my_cards
		}
	}

	NetworkManager.send_ws(msg)

	btn.text     = "Enviando..."
	btn.disabled = true

	var timer = btn.get_tree().create_timer(10.0)
	timer.timeout.connect(func():
		if is_instance_valid(btn) and btn.disabled:
			btn.text     = "⚔️ Retar"
			btn.disabled = false
	)


# ============================================================
# FETCH
# ============================================================
static func _fetch_gym_type_data(
		container: Control, C,
		gym_id: String, type_color: Color,
		sub_lbl: Label, members_vbox: VBoxContainer,
		progress_panel: Panel, leader_btn: Button,
		member_deck_btn: Button, menu) -> void:

	var now = Time.get_unix_time_from_system()

	# ── Verificar caché para datos estáticos ──
	var cached = _gym_data_cache.get(gym_id, null)
	var use_cache = cached != null and (now - cached.get("timestamp", 0.0)) < GYM_CACHE_TTL

	if use_cache:
		_apply_gym_data(cached.get("data", {}), C, gym_id, type_color,
			sub_lbl, members_vbox, progress_panel, leader_btn, member_deck_btn, menu, true)
		return

	var http = HTTPRequest.new()
	container.add_child(http)

	var headers = ["Authorization: Bearer " + NetworkManager.token, "Content-Type: application/json"]
	var url     = NetworkManager.BASE_URL + "/api/gym/" + gym_id
	http.request(url, headers, HTTPClient.METHOD_GET)

	http.request_completed.connect(func(result, code, _headers, body):
		http.queue_free()

		if result != HTTPRequest.RESULT_SUCCESS or code != 200:
			sub_lbl.text = "Error al cargar el gimnasio (código %d)" % code
			return

		var json = JSON.parse_string(body.get_string_from_utf8())
		if not json:
			sub_lbl.text = "Error: respuesta inválida del servidor"
			return

		# Guardar en caché (sin progreso — siempre fresco)
		_gym_data_cache[gym_id] = { "data": json, "timestamp": Time.get_unix_time_from_system() }

		_apply_gym_data(json, C, gym_id, type_color,
			sub_lbl, members_vbox, progress_panel, leader_btn, member_deck_btn, menu, false)
	)


static func _apply_gym_data(
	json: Dictionary, C,
	gym_id: String, type_color: Color,
	sub_lbl: Label, members_vbox: VBoxContainer,
	progress_panel: Panel, leader_btn: Button,
	member_deck_btn: Button, menu, from_cache: bool) -> void:

	var gym_data     = json.get("gym",          {})
	var members      = json.get("members",       [])
	var progress     = json.get("progress",      null)
	var has_medal    = json.get("has_medal",     false)
	var my_role      = json.get("my_role",       null)
	# my_gym_decks: { "SS": [...], "S": [...], "A": [...], "B": [...] } o null
	var my_gym_decks = json.get("my_gym_decks",  null)

	# Nombre del líder
	var leader_name : String = gym_data.get("leader_username", "")
	if leader_name == "":
		var leader_arr = members.filter(func(m): return m.get("role") == "leader")
		if leader_arr.size() > 0:
			leader_name = leader_arr[0].get("username", "")

	var display_leader = leader_name if leader_name != "" else "Vacante"
	sub_lbl.text = "Líder: " + display_leader + \
		("  ·  🏅 Medalla obtenida" if has_medal else "  ·  Sin medalla")

	# Botón Panel del Líder
	if is_instance_valid(leader_btn) and leader_name != "" and leader_name == PlayerData.username:
		leader_btn.visible = true

	# Botón Mis Mazos del Gym (grunt / sub-líder)
	if is_instance_valid(member_deck_btn) and my_role != null and my_role != "leader":
		member_deck_btn.visible = true

		# Contar cuántos de los 4 decks están completos
		var decks_ready = 0
		if my_gym_decks is Dictionary:
			for t in ["SS","S","A","B"]:
				if my_gym_decks.get(t, []).size() == 60:
					decks_ready += 1
		member_deck_btn.text = "🛠️ Mis Mazos  (%d/4 listos)" % decks_ready

		# Al pulsar: ir al selector de tiers en DeckBuilder
		member_deck_btn.pressed.connect(func():
			var gym_type = GYM_TYPES_MAP.get(gym_id, "COLORLESS")
			menu.set_meta("deck_mode",       "gym")
			menu.set_meta("gym_type",        gym_type)
			menu.set_meta("gym_role",        my_role)
			menu.set_meta("gym_editing_id",  gym_id)
			menu.set_meta("gym_tier_editing","")   # se setea al elegir tier en DeckBuilder
			# Pasar todos los decks para que DeckBuilder los muestre sin fetch adicional
			menu.set_meta("gym_decks_data",  my_gym_decks if my_gym_decks is Dictionary else {})
			menu.current_deck = []
			menu.deck_name    = "Mazo de " + GYM_NAMES.get(gym_id, "Gym")
			menu.navigate_to("DeckBuilderScreen")
		)

		# Panel de progreso
		var grunts_defeated : Array = []
		if progress != null:
			var raw = progress.get("grunts_defeated", [])
			if raw is Array:       grunts_defeated = raw
			elif raw is String:
				var parsed = JSON.parse_string(raw)
				if parsed is Array: grunts_defeated = parsed

		var total_grunts        = members.filter(func(m): return m.get("role") == "grunt").size()
		var sub_leader_defeated = false
		var leader_defeated     = false
		var attempt_tier        = "—"

		if progress != null:
			sub_leader_defeated = progress.get("sub_leader_defeated", false)
			leader_defeated     = progress.get("leader_defeated", false)
			attempt_tier        = progress.get("attempt_tier", "—")

		var tier_lbl  = progress_panel.find_child("TierLbl",  true, false)
		var prog_lbl  = progress_panel.find_child("ProgLbl",  true, false)
		var state_lbl = progress_panel.find_child("StateLbl", true, false)

		if tier_lbl:
			tier_lbl.text = attempt_tier if attempt_tier != null else "—"
			tier_lbl.add_theme_color_override("font_color", TIER_COLORS.get(attempt_tier, Color(0.7, 0.7, 0.7)))

		var sub_count = 1 if members.any(func(m): return m.get("role") == "sub_leader") else 0

		if prog_lbl:
			var sub_str = ("  ·  Sub-Líder %s" % ("✅" if sub_leader_defeated else "⬜")) if sub_count > 0 else ""
			prog_lbl.text = str(grunts_defeated.size()) + " / " + str(total_grunts) + " Grunts" + sub_str

		if state_lbl:
			if has_medal:
				state_lbl.text = "🏅 Completado"
				state_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.1))
			elif leader_defeated:
				state_lbl.text = "✅ Líder vencido"
				state_lbl.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
			elif sub_leader_defeated:
				state_lbl.text = "⚔️ Ante el Líder"
				state_lbl.add_theme_color_override("font_color", Color(0.9, 0.6, 0.1))
			elif grunts_defeated.size() > 0:
				state_lbl.text = "⚔️ En progreso"
				state_lbl.add_theme_color_override("font_color", Color(0.9, 0.75, 0.2))
			else:
				state_lbl.text = "🔒 Sin iniciar"
				state_lbl.add_theme_color_override("font_color", Color(0.55, 0.55, 0.55))

		# Poblar miembros
		var loading = members_vbox.find_child("LoadingLbl", true, false)
		if loading: loading.queue_free()

		var has_leader_row = members.any(func(m): return m.get("role") == "leader")
		if not has_leader_row and gym_data.get("leader_user_id", "") != "":
			var raw_lname = gym_data.get("leader_username", "")
			var raw_luid  = gym_data.get("leader_user_id",  "")
			var synthetic_leader = {
				"role":     "leader",
				"username": str(raw_lname) if raw_lname != null else "???",
				"user_id":  str(raw_luid)  if raw_luid  != null else "",
				"wins":     0, "losses": 0, "winrate": 0,
			}
			members = [synthetic_leader] + members

		if members.is_empty():
			var empty_lbl = Label.new()
			empty_lbl.text = "Este gimnasio no tiene miembros aún"
			empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			empty_lbl.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
			members_vbox.add_child(empty_lbl)
		else:
			var decks_map : Dictionary = my_gym_decks if my_gym_decks is Dictionary else {}
			var leader_decks : Dictionary = gym_data.get("leader_decks", {})
			for member in members:
				var row = _make_member_row(member, C, type_color,
					grunts_defeated, sub_leader_defeated,
					gym_id, decks_map, leader_decks)
				members_vbox.add_child(row)
