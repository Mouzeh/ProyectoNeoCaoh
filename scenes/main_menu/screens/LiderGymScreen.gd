extends Node

# ============================================================
# LiderGymScreen.gd
# Panel de gestión exclusivo para el Líder del GYM
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

const TIER_ORDER  = ["SS", "S", "A", "B"]
const TIER_COLORS = {
	"SS": Color(1.0,  0.85, 0.1),
	"S":  Color(0.9,  0.5,  0.1),
	"A":  Color(0.4,  0.8,  0.3),
	"B":  Color(0.3,  0.6,  1.0),
}

# Muestra qué retadores enfrentarán cada deck del Líder
# SS → retadores SS y S  |  S → retadores A  |  A → retadores B  |  B → retadores C
const TIER_CHALLENGER_LABEL = {
	"SS": "Retadores tier SS y S",
	"S":  "Retadores tier A",
	"A":  "Retadores tier B",
	"B":  "Retadores tier B y C",
}

static var _tex_cache: Dictionary = {}
static var _lider_cache: Dictionary = {}  # { gym_id: { data: {...}, timestamp: float } }
const LIDER_CACHE_TTL = 60.0
const GymTypeScreen = preload("res://scenes/main_menu/screens/GymTypeScreen.gd")

static func _get_tex(path: String) -> Texture2D:
	if path not in _tex_cache:
		_tex_cache[path] = load(path) if ResourceLoader.exists(path) else null
	return _tex_cache[path]

static func invalidate_cache(gym_id: String) -> void:
	_lider_cache.erase(gym_id)

# ============================================================
# ENTRY POINT
# ============================================================
static func build(container: Control, menu, params: Dictionary = {}) -> void:
	var C        = menu
	var gym_id   : String = params.get("gym_id", "")
	var tc       : Color  = TYPE_COLORS.get(gym_id, Color(0.2, 0.2, 0.25))
	var gym_name : String = GYM_NAMES.get(gym_id, "Gimnasio")

	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(tc.r * 0.18, tc.g * 0.18, tc.b * 0.18, 1.0)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(bg)

	var overlay = ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.03, 0.04, 0.07, 0.72)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(overlay)

	var header = Panel.new()
	header.anchor_left = 0; header.anchor_right  = 1
	header.anchor_top  = 0; header.anchor_bottom = 0
	header.offset_top  = 40; header.offset_bottom = 130
	var hs = StyleBoxFlat.new()
	hs.bg_color     = Color(C.COLOR_PANEL.r, C.COLOR_PANEL.g, C.COLOR_PANEL.b, 0.93)
	hs.border_color = tc
	hs.border_width_bottom = 3
	hs.shadow_color = Color(tc.r, tc.g, tc.b, 0.3); hs.shadow_size = 18
	header.add_theme_stylebox_override("panel", hs)
	container.add_child(header)

	var hbox = HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	header.add_child(hbox)

	var accent = ColorRect.new()
	accent.color = tc
	accent.custom_minimum_size = Vector2(8, 0)
	hbox.add_child(accent)

	var icon_m = MarginContainer.new()
	icon_m.add_theme_constant_override("margin_left",   20)
	icon_m.add_theme_constant_override("margin_right",  10)
	icon_m.add_theme_constant_override("margin_top",    10)
	icon_m.add_theme_constant_override("margin_bottom", 10)
	hbox.add_child(icon_m)
	var icon_tr = TextureRect.new()
	icon_tr.custom_minimum_size = Vector2(55, 55)
	icon_tr.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	icon_tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var tex = _get_tex(TYPE_ICONS.get(gym_id, ""))
	if tex: icon_tr.texture = tex
	icon_m.add_child(icon_tr)

	var title_m = MarginContainer.new()
	title_m.add_theme_constant_override("margin_left", 10)
	title_m.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(title_m)
	var title_v = VBoxContainer.new()
	title_v.alignment = BoxContainer.ALIGNMENT_CENTER
	title_m.add_child(title_v)

	var title_lbl = Label.new()
	title_lbl.text = "👑 " + gym_name.to_upper() + " · PANEL DEL LÍDER"
	title_lbl.add_theme_font_size_override("font_size", 18)
	title_lbl.add_theme_color_override("font_color", Color(lerpf(tc.r, 1.0, 0.55), lerpf(tc.g, 1.0, 0.55), lerpf(tc.b, 1.0, 0.55)))
	title_v.add_child(title_lbl)

	var sub_lbl = Label.new()
	sub_lbl.text = "Líder: " + PlayerData.username
	sub_lbl.add_theme_font_size_override("font_size", 13)
	sub_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	title_v.add_child(sub_lbl)

	var back_m = MarginContainer.new()
	back_m.add_theme_constant_override("margin_right",  30)
	back_m.add_theme_constant_override("margin_top",    20)
	back_m.add_theme_constant_override("margin_bottom", 20)
	hbox.add_child(back_m)
	var back_btn = Button.new()
	back_btn.text = "← Volver"
	back_btn.custom_minimum_size = Vector2(110, 40)
	back_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var bb = StyleBoxFlat.new()
	bb.bg_color = Color(1,1,1,0.07); bb.border_color = Color(0.6,0.6,0.6,0.5)
	bb.border_width_left=1; bb.border_width_right=1; bb.border_width_top=1; bb.border_width_bottom=1
	bb.corner_radius_top_left=20; bb.corner_radius_top_right=20
	bb.corner_radius_bottom_left=20; bb.corner_radius_bottom_right=20
	var bb_h = bb.duplicate(); bb_h.bg_color = Color(1,1,1,0.15)
	back_btn.add_theme_stylebox_override("normal", bb)
	back_btn.add_theme_stylebox_override("hover",  bb_h)
	back_btn.add_theme_stylebox_override("focus",  StyleBoxEmpty.new())
	back_btn.add_theme_color_override("font_color", Color(0.85,0.85,0.85))
	back_btn.pressed.connect(func(): menu.navigate_to("GymTypeScreen", {"gym_id": gym_id}))
	back_m.add_child(back_btn)

	var scroll = ScrollContainer.new()
	scroll.anchor_left=0; scroll.anchor_right=1; scroll.anchor_top=0; scroll.anchor_bottom=1
	scroll.offset_top = 130
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	UITheme.apply_scrollbar_theme(scroll)
	container.add_child(scroll)

	var center_wrap = CenterContainer.new()
	center_wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center_wrap.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	scroll.add_child(center_wrap)

	var inner_v = VBoxContainer.new()
	inner_v.custom_minimum_size = Vector2(1000, 0)
	inner_v.add_theme_constant_override("separation", 30)
	center_wrap.add_child(inner_v)

	var spacer_top = Control.new()
	spacer_top.custom_minimum_size = Vector2(0, 15)
	inner_v.add_child(spacer_top)

	# ── Decks por Tier ──
	inner_v.add_child(_section_title("🃏 DECKS DEL ALTO MANDO POR TIER", tc))

	var decks_sub = Label.new()
	decks_sub.text = "Crea un mazo para cada tier usando colección ilimitada de cartas tipo " + gym_name.split(" ")[1] + " e incoloras."
	decks_sub.autowrap_mode = TextServer.AUTOWRAP_WORD
	decks_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	decks_sub.add_theme_font_size_override("font_size", 13)
	decks_sub.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	inner_v.add_child(decks_sub)

	var tier_grid = GridContainer.new()
	tier_grid.columns = 2
	tier_grid.add_theme_constant_override("h_separation", 20)
	tier_grid.add_theme_constant_override("v_separation", 20)
	inner_v.add_child(tier_grid)

	var deck_slot_labels: Dictionary = {}
	for tier in TIER_ORDER:
		var slot_panel = _make_tier_slot(tier, tc, C, deck_slot_labels, gym_id, container, menu, gym_name)
		tier_grid.add_child(slot_panel)

	var sep = ColorRect.new()
	sep.custom_minimum_size = Vector2(200, 2)
	sep.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	sep.color = Color(tc.r, tc.g, tc.b, 0.3)
	inner_v.add_child(sep)

	# ── Gestión de Miembros ──
	inner_v.add_child(_section_title("⚔️ GESTIÓN DE MIEMBROS", tc))

	var add_panel = _make_add_member_panel(C, tc, gym_id, container, inner_v, menu)
	inner_v.add_child(add_panel)

	var members_lbl = Label.new()
	members_lbl.text = "MIEMBROS ACTUALES"
	members_lbl.add_theme_font_size_override("font_size", 12)
	members_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	inner_v.add_child(members_lbl)

	var members_vbox = VBoxContainer.new()
	members_vbox.add_theme_constant_override("separation", 8)
	members_vbox.name = "MembersVBox"
	inner_v.add_child(members_vbox)

	var loading_lbl = Label.new()
	loading_lbl.text = "Cargando miembros..."
	loading_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	loading_lbl.add_theme_font_size_override("font_size", 13)
	loading_lbl.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
	members_vbox.add_child(loading_lbl)

	var spacer_bot = Control.new()
	spacer_bot.custom_minimum_size = Vector2(0, 40)
	inner_v.add_child(spacer_bot)

	_fetch_data(container, C, gym_id, tc, deck_slot_labels, members_vbox, menu)


# ============================================================
# SLOT DE TIER
# ============================================================
static func _make_tier_slot(tier: String, tc: Color, C, deck_slot_labels: Dictionary, gym_id: String, container: Control, menu, gym_name: String) -> Panel:
	var tier_color = TIER_COLORS.get(tier, Color(0.7, 0.7, 0.7))

	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(460, 130)
	var st = StyleBoxFlat.new()
	st.bg_color = Color(C.COLOR_PANEL.r, C.COLOR_PANEL.g, C.COLOR_PANEL.b, 0.8)
	st.border_color = Color(tier_color.r, tier_color.g, tier_color.b, 0.5)
	st.border_width_left=1; st.border_width_right=1; st.border_width_top=1
	st.border_width_bottom = 3
	st.corner_radius_top_left=12; st.corner_radius_top_right=12
	st.corner_radius_bottom_left=12; st.corner_radius_bottom_right=12
	st.content_margin_left=20; st.content_margin_right=20
	st.content_margin_top=16; st.content_margin_bottom=16
	panel.add_theme_stylebox_override("panel", st)

	var hbox = HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.add_theme_constant_override("separation", 15)
	panel.add_child(hbox)

	var tier_badge = Label.new()
	tier_badge.text = tier
	tier_badge.custom_minimum_size = Vector2(52, 52)
	tier_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tier_badge.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	tier_badge.add_theme_font_size_override("font_size", 22)
	tier_badge.add_theme_color_override("font_color", tier_color)
	var badge_st = StyleBoxFlat.new()
	badge_st.bg_color = Color(tier_color.r, tier_color.g, tier_color.b, 0.12)
	badge_st.border_color = tier_color
	badge_st.border_width_left=2; badge_st.border_width_right=2
	badge_st.border_width_top=2; badge_st.border_width_bottom=2
	badge_st.corner_radius_top_left=10; badge_st.corner_radius_top_right=10
	badge_st.corner_radius_bottom_left=10; badge_st.corner_radius_bottom_right=10
	tier_badge.add_theme_stylebox_override("normal", badge_st)
	hbox.add_child(tier_badge)

	var info_v = VBoxContainer.new()
	info_v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_v.alignment = BoxContainer.ALIGNMENT_CENTER
	info_v.add_theme_constant_override("separation", 6)
	hbox.add_child(info_v)

	# ── Caption: muestra qué retadores enfrentarán este deck ──
	var cap_lbl = Label.new()
	cap_lbl.text = TIER_CHALLENGER_LABEL.get(tier, "Retadores tier " + tier) + " enfrentarán este deck"
	cap_lbl.add_theme_font_size_override("font_size", 11)
	cap_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	info_v.add_child(cap_lbl)

	var assigned_lbl = Label.new()
	assigned_lbl.text = "Buscando datos..."
	assigned_lbl.add_theme_font_size_override("font_size", 15)
	assigned_lbl.add_theme_color_override("font_color", Color(0.55, 0.55, 0.55))
	assigned_lbl.name = "AssignedLbl_" + tier
	info_v.add_child(assigned_lbl)
	deck_slot_labels[tier] = assigned_lbl

	var assign_btn = Button.new()
	assign_btn.text = "🛠️ Crear/Editar"
	assign_btn.custom_minimum_size = Vector2(120, 36)
	assign_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var ab_st = StyleBoxFlat.new()
	ab_st.bg_color = Color(tier_color.r, tier_color.g, tier_color.b, 0.18)
	ab_st.border_color = tier_color
	ab_st.border_width_left=1; ab_st.border_width_right=1
	ab_st.border_width_top=1; ab_st.border_width_bottom=2
	ab_st.corner_radius_top_left=18; ab_st.corner_radius_top_right=18
	ab_st.corner_radius_bottom_left=18; ab_st.corner_radius_bottom_right=18
	var ab_hov = ab_st.duplicate()
	ab_hov.bg_color = Color(tier_color.r, tier_color.g, tier_color.b, 0.35)
	assign_btn.add_theme_stylebox_override("normal", ab_st)
	assign_btn.add_theme_stylebox_override("hover",  ab_hov)
	assign_btn.add_theme_stylebox_override("focus",  StyleBoxEmpty.new())
	assign_btn.add_theme_color_override("font_color", Color(1,1,1,0.9))
	assign_btn.add_theme_font_size_override("font_size", 12)

	assign_btn.pressed.connect(func():
		var t_type = "COLORLESS"
		if "fire"        in gym_id: t_type = "FIRE"
		elif "water"     in gym_id: t_type = "WATER"
		elif "grass"     in gym_id: t_type = "GRASS"
		elif "lightning" in gym_id: t_type = "LIGHTNING"
		elif "psychic"   in gym_id: t_type = "PSYCHIC"
		elif "fighting"  in gym_id: t_type = "FIGHTING"
		elif "darkness"  in gym_id: t_type = "DARKNESS"
		elif "metal"     in gym_id: t_type = "METAL"

		menu.set_meta("deck_mode",        "gym")
		menu.set_meta("gym_role",         "leader")
		menu.set_meta("gym_type",         t_type)
		menu.set_meta("gym_tier_editing", tier)
		menu.set_meta("gym_editing_id",   gym_id)

		var existing_deck = []
		var decks_data = menu.get_meta("gym_decks_data", {})
		if decks_data.has(tier):
			existing_deck = decks_data[tier].duplicate()

		menu.current_deck = existing_deck
		menu.deck_name = "Mazo " + tier + " (" + gym_name.split(" ")[1] + ")"

		menu.navigate_to("DeckBuilderScreen")
	)
	hbox.add_child(assign_btn)

	return panel


# ============================================================
# PANEL AGREGAR MIEMBRO
# ============================================================
static func _make_add_member_panel(C, tc: Color, gym_id: String, container: Control, inner_v: VBoxContainer, menu) -> Panel:
	var panel = Panel.new()
	var st = StyleBoxFlat.new()
	st.bg_color = Color(C.COLOR_PANEL.r, C.COLOR_PANEL.g, C.COLOR_PANEL.b, 0.75)
	st.border_color = Color(tc.r, tc.g, tc.b, 0.35)
	st.border_width_left=1; st.border_width_right=1
	st.border_width_top=1; st.border_width_bottom=1
	st.corner_radius_top_left=12; st.corner_radius_top_right=12
	st.corner_radius_bottom_left=12; st.corner_radius_bottom_right=12
	st.content_margin_left=20; st.content_margin_right=20
	st.content_margin_top=16; st.content_margin_bottom=16
	panel.add_theme_stylebox_override("panel", st)

	var outer_v = VBoxContainer.new()
	outer_v.set_anchors_preset(Control.PRESET_FULL_RECT)
	outer_v.add_theme_constant_override("separation", 10)
	panel.add_child(outer_v)

	var search_hbox = HBoxContainer.new()
	search_hbox.add_theme_constant_override("separation", 12)
	outer_v.add_child(search_hbox)

	var input = LineEdit.new()
	input.placeholder_text = "Buscar jugador por username..."
	input.custom_minimum_size = Vector2(280, 42)
	input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	input.add_theme_font_size_override("font_size", 14)
	var input_st = StyleBoxFlat.new()
	input_st.bg_color = Color(0, 0, 0, 0.35)
	input_st.border_color = Color(tc.r, tc.g, tc.b, 0.4)
	input_st.border_width_left=1; input_st.border_width_right=1
	input_st.border_width_top=1; input_st.border_width_bottom=2
	input_st.corner_radius_top_left=8; input_st.corner_radius_top_right=8
	input_st.corner_radius_bottom_left=8; input_st.corner_radius_bottom_right=8
	input_st.content_margin_left=12; input_st.content_margin_right=12
	input_st.content_margin_top=8; input_st.content_margin_bottom=8
	input.add_theme_stylebox_override("normal", input_st)
	input.add_theme_stylebox_override("focus",  input_st)
	search_hbox.add_child(input)

	var role_opt = OptionButton.new()
	role_opt.custom_minimum_size = Vector2(130, 42)
	role_opt.add_item("⭐ Sub-Líder", 0)
	role_opt.add_item("⚔️ Grunt",    1)
	role_opt.add_theme_font_size_override("font_size", 13)
	search_hbox.add_child(role_opt)

	var search_btn = Button.new()
	search_btn.text = "🔍 Buscar"
	search_btn.custom_minimum_size = Vector2(110, 42)
	search_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(tc.r, tc.g, tc.b, 0.22)
	sb.border_color = tc
	sb.border_width_left=1; sb.border_width_right=1
	sb.border_width_top=1; sb.border_width_bottom=2
	sb.corner_radius_top_left=20; sb.corner_radius_top_right=20
	sb.corner_radius_bottom_left=20; sb.corner_radius_bottom_right=20
	var sb_h = sb.duplicate(); sb_h.bg_color = Color(tc.r, tc.g, tc.b, 0.4)
	search_btn.add_theme_stylebox_override("normal", sb)
	search_btn.add_theme_stylebox_override("hover",  sb_h)
	search_btn.add_theme_stylebox_override("focus",  StyleBoxEmpty.new())
	search_btn.add_theme_color_override("font_color", Color(1,1,1,0.9))
	search_btn.add_theme_font_size_override("font_size", 13)
	search_hbox.add_child(search_btn)

	var feedback = Label.new()
	feedback.text = ""
	feedback.add_theme_font_size_override("font_size", 12)
	feedback.name = "AddFeedback"
	outer_v.add_child(feedback)

	var results_vbox = VBoxContainer.new()
	results_vbox.add_theme_constant_override("separation", 6)
	results_vbox.name = "SearchResults"
	outer_v.add_child(results_vbox)

	search_btn.pressed.connect(func():
		var q = input.text.strip_edges()
		if q.length() < 2:
			feedback.text = "⚠️ Escribe al menos 2 caracteres"
			feedback.add_theme_color_override("font_color", Color(0.9, 0.75, 0.2))
			return
		feedback.text = "Buscando..."
		feedback.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		_search_users(container, gym_id, q, role_opt, results_vbox, feedback, inner_v, C, tc, menu)
	)

	input.text_submitted.connect(func(_t): search_btn.emit_signal("pressed"))
	return panel

static func _search_users(container: Control, gym_id: String, query: String,
		role_opt: OptionButton, results_vbox: VBoxContainer,
		feedback: Label, inner_v: VBoxContainer, C, tc: Color, menu) -> void:

	for child in results_vbox.get_children(): child.queue_free()
	var http = HTTPRequest.new()
	container.add_child(http)
	var headers = ["Authorization: Bearer " + NetworkManager.token, "Content-Type: application/json"]
	var url = NetworkManager.BASE_URL + "/api/gym/" + gym_id + "/members/search?q=" + query.uri_encode()
	http.request(url, headers, HTTPClient.METHOD_GET)

	http.request_completed.connect(func(result, code, _h, body):
		http.queue_free()
		if result != HTTPRequest.RESULT_SUCCESS or code != 200:
			feedback.text = "❌ Error al buscar jugadores"
			feedback.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))
			return
		var json = JSON.parse_string(body.get_string_from_utf8())
		var results: Array = json.get("results", []) if json else []

		if results.is_empty():
			feedback.text = "Sin resultados para «" + query + "»"
			feedback.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
			return
		feedback.text = str(results.size()) + " resultado(s) — selecciona un jugador:"
		feedback.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))

		for user in results:
			var raw_uid2   = user.get("player_id", "")
			var raw_uname2 = user.get("username", "???")
			var uid   : String = str(raw_uid2)   if raw_uid2   != null else ""
			var uname : String = str(raw_uname2) if raw_uname2 != null else "???"
			var elo   : int    = int(user.get("elo", 0))

			var row_btn = Button.new()
			row_btn.text = uname + "  (ELO " + str(elo) + ")"
			row_btn.custom_minimum_size = Vector2(0, 38)
			row_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			row_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT

			var rb_st = StyleBoxFlat.new()
			rb_st.bg_color = Color(tc.r, tc.g, tc.b, 0.08)
			rb_st.border_color = Color(tc.r, tc.g, tc.b, 0.3)
			rb_st.border_width_bottom = 1
			rb_st.corner_radius_top_left=8; rb_st.corner_radius_top_right=8
			rb_st.corner_radius_bottom_left=8; rb_st.corner_radius_bottom_right=8
			rb_st.content_margin_left = 12
			var rb_hov = rb_st.duplicate()
			rb_hov.bg_color = Color(tc.r, tc.g, tc.b, 0.22)
			rb_hov.border_color = tc
			row_btn.add_theme_stylebox_override("normal", rb_st)
			row_btn.add_theme_stylebox_override("hover",  rb_hov)
			row_btn.add_theme_stylebox_override("focus",  StyleBoxEmpty.new())
			row_btn.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
			row_btn.add_theme_font_size_override("font_size", 13)

			var roles_map = ["sub_leader", "grunt"]
			row_btn.pressed.connect(func():
				var role_str = roles_map[role_opt.get_selected_id()]
				for child in results_vbox.get_children(): child.queue_free()
				_add_member_by_id(container, gym_id, uid, uname, role_str, feedback, inner_v, C, tc, menu)
			)
			results_vbox.add_child(row_btn)
	)

static func _add_member_by_id(container: Control, gym_id: String,
		target_user_id: String, username: String, role: String,
		feedback: Label, inner_v: VBoxContainer, C, tc: Color, menu) -> void:

	var http = HTTPRequest.new()
	container.add_child(http)
	var headers = ["Authorization: Bearer " + NetworkManager.token, "Content-Type: application/json"]
	var payload = JSON.stringify({"target_user_id": target_user_id, "role": role})
	http.request(NetworkManager.BASE_URL + "/api/gym/" + gym_id + "/member", headers, HTTPClient.METHOD_POST, payload)

	http.request_completed.connect(func(result, code, _h, body):
		http.queue_free()
		if code == 200:
			feedback.text = "✅ " + username + " agregado como " + role
			feedback.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
			invalidate_cache(gym_id)
			GymTypeScreen.clear_cache()
			var members_vbox = inner_v.find_child("MembersVBox", true, false)
			if members_vbox:
				for child in members_vbox.get_children(): child.queue_free()
				_fetch_data(container, C, gym_id, tc, {}, members_vbox, menu)
		else:
			var err = JSON.parse_string(body.get_string_from_utf8())
			feedback.text = "❌ " + (err.get("error", "Error") if err else "Error")
			feedback.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))
	)


static func _make_member_row_leader(member: Dictionary, C, tc: Color, gym_id: String, members_vbox: VBoxContainer, container: Control, menu) -> Panel:
	var role     = str(member.get("role",     "grunt"))
	var username = str(member.get("username", "???"))
	var user_id  = str(member.get("user_id",  ""))

	var panel = Panel.new()
	var st = StyleBoxFlat.new()
	st.bg_color = Color(C.COLOR_PANEL.r, C.COLOR_PANEL.g, C.COLOR_PANEL.b, 0.7)
	st.border_color = Color(1,1,1,0.08)
	st.border_width_bottom=1
	st.corner_radius_top_left=8; st.corner_radius_top_right=8
	st.corner_radius_bottom_left=8; st.corner_radius_bottom_right=8
	st.content_margin_left=16; st.content_margin_right=16
	st.content_margin_top=12; st.content_margin_bottom=12
	panel.add_theme_stylebox_override("panel", st)

	var hbox = HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.add_theme_constant_override("separation", 12)
	panel.add_child(hbox)

	var role_lbl = Label.new()
	role_lbl.text = "👑 LÍDER" if role == "leader" else ("⭐ SUB" if role == "sub_leader" else "⚔️ GRUNT")
	role_lbl.custom_minimum_size = Vector2(90, 0)
	role_lbl.add_theme_font_size_override("font_size", 12)
	role_lbl.add_theme_color_override("font_color", tc if role == "leader" else (Color(lerpf(tc.r,1,.4),lerpf(tc.g,1,.4),lerpf(tc.b,1,.4)) if role == "sub_leader" else Color(0.6,0.6,0.6)))
	hbox.add_child(role_lbl)

	var name_lbl = Label.new()
	name_lbl.text = username
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.add_theme_font_size_override("font_size", 14)
	name_lbl.add_theme_color_override("font_color", Color(0.9,0.9,0.9))
	hbox.add_child(name_lbl)

	if role != "leader":
		var kick_btn = Button.new()
		kick_btn.text = "Expulsar"
		kick_btn.custom_minimum_size = Vector2(90, 32)
		kick_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var kb = StyleBoxFlat.new()
		kb.bg_color = Color(0.5,0.1,0.1,0.3); kb.border_color = Color(0.8,0.3,0.3,0.6)
		kb.border_width_left=1; kb.border_width_right=1
		kb.border_width_top=1; kb.border_width_bottom=1
		kb.corner_radius_top_left=16; kb.corner_radius_top_right=16
		kb.corner_radius_bottom_left=16; kb.corner_radius_bottom_right=16
		var kb_h = kb.duplicate(); kb_h.bg_color = Color(0.7,0.15,0.15,0.5)
		kick_btn.add_theme_stylebox_override("normal", kb)
		kick_btn.add_theme_stylebox_override("hover",  kb_h)
		kick_btn.add_theme_stylebox_override("focus",  StyleBoxEmpty.new())
		kick_btn.add_theme_color_override("font_color", Color(1,0.5,0.5))
		kick_btn.add_theme_font_size_override("font_size", 12)
		kick_btn.pressed.connect(func(): _remove_member(container, gym_id, user_id, panel, members_vbox))
		hbox.add_child(kick_btn)

	return panel

static func _section_title(text: String, tc: Color) -> Label:
	var lbl = Label.new()
	lbl.text = text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 15)
	lbl.add_theme_color_override("font_color", Color(lerpf(tc.r, 1.0, 0.45), lerpf(tc.g, 1.0, 0.45), lerpf(tc.b, 1.0, 0.45)))
	return lbl

# ============================================================
# FETCH
# ============================================================
static func _fetch_data(container: Control, C, gym_id: String, tc: Color,
		deck_slot_labels: Dictionary, members_vbox: VBoxContainer, menu) -> void:

	var now    = Time.get_unix_time_from_system()
	var cached = _lider_cache.get(gym_id, null)
	var use_cache = cached != null and (now - cached.get("timestamp", 0.0)) < LIDER_CACHE_TTL \
		and not deck_slot_labels.is_empty()  # solo usar caché si hay labels que poblar

	if use_cache:
		_apply_lider_data(cached.get("data", {}), C, gym_id, tc, deck_slot_labels, members_vbox, menu, container)
		return

	var http = HTTPRequest.new()
	container.add_child(http)
	var headers = ["Authorization: Bearer " + NetworkManager.token, "Content-Type: application/json"]
	http.request(NetworkManager.BASE_URL + "/api/gym/" + gym_id, headers, HTTPClient.METHOD_GET)

	http.request_completed.connect(func(result, code, _h, body):
		http.queue_free()
		if result != HTTPRequest.RESULT_SUCCESS or code != 200: return
		var json = JSON.parse_string(body.get_string_from_utf8())
		if not json: return
		_lider_cache[gym_id] = { "data": json, "timestamp": Time.get_unix_time_from_system() }
		_apply_lider_data(json, C, gym_id, tc, deck_slot_labels, members_vbox, menu, container)
	)

static func _apply_lider_data(json: Dictionary, C, gym_id: String, tc: Color,
		deck_slot_labels: Dictionary, members_vbox: VBoxContainer, menu, container: Control) -> void:

	var gym_data     = json.get("gym", {})
	var members      = json.get("members", [])
	var leader_decks = gym_data.get("leader_decks", {})

	if not menu.has_meta("gym_decks_data"):
		menu.set_meta("gym_decks_data", {})

	var decks_data = menu.get_meta("gym_decks_data")

	for tier in deck_slot_labels:
		var deck_array = leader_decks.get(tier, [])
		var lbl = deck_slot_labels[tier]
		if deck_array is Array and deck_array.size() > 0:
			lbl.text = "✅ Mazo de " + str(deck_array.size()) + " cartas"
			lbl.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
			decks_data[tier] = deck_array
		else:
			lbl.text = "Sin asignar"
			lbl.add_theme_color_override("font_color", Color(0.55, 0.55, 0.55))

	menu.set_meta("gym_decks_data", decks_data)

	for child in members_vbox.get_children(): child.queue_free()
	for member in members:
		var row = _make_member_row_leader(member, C, tc, gym_id, members_vbox, container, menu)
		members_vbox.add_child(row)

static func _remove_member(container: Control, gym_id: String, user_id: String,
		row: Panel, members_vbox: VBoxContainer) -> void:

	var http = HTTPRequest.new()
	container.add_child(http)
	var headers = ["Authorization: Bearer " + NetworkManager.token, "Content-Type: application/json"]
	http.request(NetworkManager.BASE_URL + "/api/gym/" + gym_id + "/member/" + user_id, headers, HTTPClient.METHOD_DELETE)

	http.request_completed.connect(func(result, code, _h, _b):
		http.queue_free()
		if code == 200:
			invalidate_cache(gym_id)
			GymTypeScreen.clear_cache()
			row.queue_free()
	)
