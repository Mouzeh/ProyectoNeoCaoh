extends Node

# ============================================================
# DeckBuilderScreen.gd
# Modo Dual: Construcción Personal y Modo Gym (Líder/Sub/Grunt)
# ============================================================

const MiniCard       = preload("res://scenes/main_menu/components/MiniCard.gd")
const LiderGymScreen = preload("res://scenes/main_menu/screens/LiderGymScreen.gd")

const TIER_COLORS = {
	"SS": Color(1.0,  0.85, 0.1),
	"S":  Color(0.9,  0.5,  0.1),
	"A":  Color(0.4,  0.8,  0.3),
	"B":  Color(0.3,  0.6,  1.0),
}

const TIER_CHALLENGER_LABEL = {
	"SS": "vs Retadores SS",
	"S":  "vs Retadores S",
	"A":  "vs Retadores A",
	"B":  "vs Retadores B y C",
}

# Colores por slot cuando no hay tier calculado
const SLOT_COLORS = [
	Color(0.55, 0.35, 0.85),  # slot 1 — púrpura
	Color(0.25, 0.65, 0.95),  # slot 2 — azul
	Color(0.95, 0.55, 0.15),  # slot 3 — naranja
	Color(0.45, 0.45, 0.45),  # slot 4 — gris (bloqueado)
]

# ─── CACHÉ DE TEXTURAS ────────────────────────────────────────
static var _texture_cache: Dictionary = {}

# ─── CACHÉ DEL GRID DE COLECCIÓN ─────────────────────────────
static var _grid_cache: Dictionary  = {}
static var _grid_cache_key: String  = ""

# ─── PREFERENCIA DE VISTA (persiste durante la sesión) ────────
# "carousel" = vista de 1 deck  |  "grid" = vista de todos
static var _deck_view_mode: String = "carousel"


# ─── ENTRY POINT ──────────────────────────────────────────
static func build(container: Control, menu, params: Dictionary = {}) -> void:
	var builder_root = Control.new()
	builder_root.name = "BuilderRoot"
	builder_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	container.add_child(builder_root)

	if menu.get_meta("deck_mode", "normal") == "gym":
		var gym_role = menu.get_meta("gym_role", "leader")
		if gym_role == "leader":
			build_deck_editor(builder_root, menu, 0)
		else:
			build_gym_tier_selection(builder_root, menu)
	else:
		build_deck_selection(builder_root, menu)


# ============================================================
# VISTA 0: SELECTOR DE TIERS (grunt / sub-líder)
# ============================================================
static func build_gym_tier_selection(container: Control, menu) -> void:
	for c in container.get_children(): c.queue_free()

	var gym_id    : String     = menu.get_meta("gym_editing_id", "")
	var gym_role  : String     = menu.get_meta("gym_role",       "grunt")
	var gym_type  : String     = menu.get_meta("gym_type",       "")
	var gym_decks : Dictionary = menu.get_meta("gym_decks_data", {})

	var bg_image = TextureRect.new()
	var bg_tex = load("res://assets/imagen/fondomenu.png")
	if bg_tex: bg_image.texture = bg_tex
	bg_image.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_image.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	bg_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg_image.modulate     = Color(0.15, 0.15, 0.15, 1)
	container.add_child(bg_image)

	var header = Panel.new()
	header.anchor_left = 0; header.anchor_right  = 1
	header.anchor_top  = 0; header.anchor_bottom = 0
	header.offset_top  = 0; header.offset_bottom = 70
	var hs = StyleBoxFlat.new()
	hs.bg_color     = Color(menu.COLOR_PANEL.r,    menu.COLOR_PANEL.g,    menu.COLOR_PANEL.b,    0.85)
	hs.border_color = Color(menu.COLOR_GOLD_DIM.r, menu.COLOR_GOLD_DIM.g, menu.COLOR_GOLD_DIM.b, 0.3)
	hs.border_width_bottom = 1
	header.add_theme_stylebox_override("panel", hs)
	container.add_child(header)

	var header_hbox = HBoxContainer.new()
	header_hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	header.add_child(header_hbox)

	var back_btn = Button.new()
	back_btn.text = "⬅ Volver al Gimnasio"
	back_btn.custom_minimum_size = Vector2(190, 0)
	var st_back = StyleBoxFlat.new()
	st_back.bg_color = Color(0.2, 0.2, 0.2, 0.8)
	back_btn.add_theme_stylebox_override("normal", st_back)
	back_btn.pressed.connect(func():
		menu.set_meta("deck_mode", "normal")
		menu.navigate_to("GymTypeScreen", {"gym_id": gym_id})
	)
	header_hbox.add_child(back_btn)

	var title_m = MarginContainer.new()
	title_m.add_theme_constant_override("margin_left", 30)
	title_m.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_hbox.add_child(title_m)

	var role_label = "SUB-LÍDER" if gym_role == "sub_leader" else "GRUNT"
	var title_lbl = Label.new()
	title_lbl.text = "🛠️  MIS MAZOS DEL GYM  ·  " + role_label + "  ·  TIPO " + gym_type
	title_lbl.add_theme_font_size_override("font_size", 18)
	title_lbl.add_theme_color_override("font_color", menu.COLOR_GOLD)
	title_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_m.add_child(title_lbl)

	var scroll = ScrollContainer.new()
	scroll.anchor_left   = 0;   scroll.anchor_right  = 1
	scroll.anchor_top    = 0;   scroll.anchor_bottom = 1
	scroll.offset_top    = 80;  scroll.offset_bottom = -20
	scroll.offset_left   = 60;  scroll.offset_right  = -60
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	container.add_child(scroll)

	var center = CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	scroll.add_child(center)

	var grid = GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 30)
	grid.add_theme_constant_override("v_separation", 30)
	center.add_child(grid)

	for tier in ["SS", "S", "A", "B"]:
		var deck_cards : Array = gym_decks.get(tier, [])
		_create_gym_tier_box(container, menu, grid, tier, deck_cards, gym_id, gym_role, gym_type, gym_decks)


static func _create_gym_tier_box(container: Control, menu, parent: Control,
		tier: String, deck_cards: Array,
		gym_id: String, gym_role: String, gym_type: String,
		gym_decks: Dictionary) -> void:

	var tier_color  : Color = TIER_COLORS.get(tier, Color(0.5, 0.5, 0.5))
	var is_complete : bool  = deck_cards.size() == 60

	var box = PanelContainer.new()
	box.custom_minimum_size = Vector2(230, 370)

	var st = StyleBoxFlat.new()
	st.bg_color = Color(0.08, 0.10, 0.16, 0.95)
	st.corner_radius_top_left    = 12; st.corner_radius_top_right    = 12
	st.corner_radius_bottom_left = 12; st.corner_radius_bottom_right = 12
	if is_complete:
		st.border_width_left = 3; st.border_width_right  = 3
		st.border_width_top  = 3; st.border_width_bottom = 3
		st.border_color = tier_color
		st.shadow_color = Color(tier_color.r, tier_color.g, tier_color.b, 0.35)
		st.shadow_size  = 18
	else:
		st.border_width_left = 2; st.border_width_right  = 2
		st.border_width_top  = 2; st.border_width_bottom = 2
		st.border_color = Color(tier_color.r * 0.5, tier_color.g * 0.5, tier_color.b * 0.5, 0.7)
	box.add_theme_stylebox_override("panel", st)
	parent.add_child(box)

	var m = MarginContainer.new()
	m.add_theme_constant_override("margin_left",   20)
	m.add_theme_constant_override("margin_right",  20)
	m.add_theme_constant_override("margin_top",    20)
	m.add_theme_constant_override("margin_bottom", 20)
	box.add_child(m)

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 8)
	m.add_child(vbox)

	var tier_badge = Label.new()
	tier_badge.text = "TIER  " + tier
	tier_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tier_badge.add_theme_font_size_override("font_size", 28)
	tier_badge.add_theme_color_override("font_color", tier_color)
	vbox.add_child(tier_badge)

	var chal_lbl = Label.new()
	chal_lbl.text = TIER_CHALLENGER_LABEL.get(tier, "")
	chal_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chal_lbl.add_theme_font_size_override("font_size", 11)
	chal_lbl.add_theme_color_override("font_color", Color(0.55, 0.55, 0.55))
	vbox.add_child(chal_lbl)

	var funda_tex = load("res://assets/iconos/deckFunda.png") as Texture2D
	var funda_row = HBoxContainer.new()
	funda_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(funda_row)

	if funda_tex:
		var funda_img = TextureRect.new()
		funda_img.texture             = funda_tex
		funda_img.custom_minimum_size = Vector2(60, 84)
		funda_img.expand_mode         = TextureRect.EXPAND_IGNORE_SIZE
		funda_img.stretch_mode        = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		funda_img.modulate            = tier_color if is_complete else Color(tier_color.r, tier_color.g, tier_color.b, 0.3)
		funda_row.add_child(funda_img)
	else:
		var icon_lbl = Label.new()
		icon_lbl.text = "🃏"
		icon_lbl.add_theme_font_size_override("font_size", 48)
		funda_row.add_child(icon_lbl)

	var count_lbl = Label.new()
	count_lbl.text = str(deck_cards.size()) + " / 60 cartas"
	count_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	count_lbl.add_theme_font_size_override("font_size", 13)
	count_lbl.add_theme_color_override("font_color", menu.COLOR_GREEN if is_complete else menu.COLOR_RED)
	vbox.add_child(count_lbl)

	var status_lbl = Label.new()
	status_lbl.text = "✅ Listo" if is_complete else "⚠️ Incompleto"
	status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_lbl.add_theme_font_size_override("font_size", 12)
	status_lbl.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3) if is_complete else Color(0.9, 0.6, 0.1))
	vbox.add_child(status_lbl)

	vbox.add_child(_vspacer(6))

	var edit_btn = Button.new()
	edit_btn.text = "✏️ Editar Mazo" if is_complete else "➕ Crear Mazo"
	edit_btn.custom_minimum_size   = Vector2(180, 40)
	edit_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var st_btn = StyleBoxFlat.new()
	st_btn.bg_color     = Color(tier_color.r * 0.35, tier_color.g * 0.35, tier_color.b * 0.35, 0.9)
	st_btn.border_color = tier_color
	st_btn.border_width_left = 1; st_btn.border_width_right  = 1
	st_btn.border_width_top  = 1; st_btn.border_width_bottom = 1
	st_btn.corner_radius_top_left    = 8; st_btn.corner_radius_top_right    = 8
	st_btn.corner_radius_bottom_left = 8; st_btn.corner_radius_bottom_right = 8
	var st_btn_hov = st_btn.duplicate()
	st_btn_hov.bg_color = Color(tier_color.r * 0.6, tier_color.g * 0.6, tier_color.b * 0.6, 1.0)
	edit_btn.add_theme_stylebox_override("normal", st_btn)
	edit_btn.add_theme_stylebox_override("hover",  st_btn_hov)
	edit_btn.add_theme_color_override("font_color", Color.WHITE)
	edit_btn.pressed.connect(func():
		menu.set_meta("gym_tier_editing", tier)
		menu.current_deck = deck_cards.duplicate()
		menu.deck_name    = "Deck " + tier + " · " + gym_type
		build_deck_editor(container, menu, 0)
	)
	vbox.add_child(edit_btn)


static func _vspacer(h: int) -> Control:
	var s = Control.new(); s.custom_minimum_size = Vector2(0, h); return s


# ============================================================
# VISTA 1: SELECTOR DE MAZOS (Modo Normal)
# Con toggle Carrusel ↔ Grid
# ============================================================
static func build_deck_selection(container: Control, menu) -> void:
	for c in container.get_children(): c.queue_free()
	_grid_cache.clear()
	_grid_cache_key = ""

	# ── Fondo ────────────────────────────────────────────────
	var bg_image = TextureRect.new()
	var bg_tex = load("res://assets/imagen/fondomenu.png")
	if bg_tex: bg_image.texture = bg_tex
	bg_image.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_image.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	bg_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg_image.modulate = Color(0.15, 0.15, 0.15, 1)
	container.add_child(bg_image)

	# ── Header ───────────────────────────────────────────────
	var header = Panel.new()
	header.anchor_left = 0; header.anchor_right  = 1
	header.anchor_top  = 0; header.anchor_bottom = 0
	header.offset_top  = 0; header.offset_bottom = 70
	var hs = StyleBoxFlat.new()
	hs.bg_color     = Color(menu.COLOR_PANEL.r,    menu.COLOR_PANEL.g,    menu.COLOR_PANEL.b,    0.85)
	hs.border_color = Color(menu.COLOR_GOLD_DIM.r, menu.COLOR_GOLD_DIM.g, menu.COLOR_GOLD_DIM.b, 0.3)
	hs.border_width_bottom = 1
	header.add_theme_stylebox_override("panel", hs)
	container.add_child(header)

	var header_hbox = HBoxContainer.new()
	header_hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	header.add_child(header_hbox)

	var exit_btn = Button.new()
	exit_btn.text = "⬅ Volver al Menú"
	exit_btn.custom_minimum_size = Vector2(140, 0)
	var st_exit = StyleBoxFlat.new()
	st_exit.bg_color = Color(0.2, 0.2, 0.2, 0.8)
	exit_btn.add_theme_stylebox_override("normal", st_exit)
	exit_btn.pressed.connect(func():
		if menu.has_method("_show_screen"):
			menu._show_screen(menu.Screen.LOBBY)
		elif menu.has_method("build_main_menu"):
			menu.build_main_menu()
	)
	header_hbox.add_child(exit_btn)

	var title_m = MarginContainer.new()
	title_m.add_theme_constant_override("margin_left", 30)
	title_m.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_hbox.add_child(title_m)

	var title_lbl = Label.new()
	title_lbl.text = "🗃️ MIS MAZOS"
	title_lbl.add_theme_font_size_override("font_size", 24)
	title_lbl.add_theme_color_override("font_color", menu.COLOR_GOLD)
	title_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_m.add_child(title_lbl)

	# ── Toggle de vista ──────────────────────────────────────
	var toggle_m = MarginContainer.new()
	toggle_m.add_theme_constant_override("margin_right", 20)
	toggle_m.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	header_hbox.add_child(toggle_m)

	var toggle_hbox = HBoxContainer.new()
	toggle_hbox.add_theme_constant_override("separation", 0)
	toggle_m.add_child(toggle_hbox)

	var _build_toggle_btn = func(label: String, mode: String) -> Button:
		var btn = Button.new()
		btn.text        = label
		btn.toggle_mode = false
		btn.custom_minimum_size = Vector2(42, 34)
		btn.add_theme_font_size_override("font_size", 18)
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

		var st_active = StyleBoxFlat.new()
		st_active.bg_color     = Color(menu.COLOR_GOLD.r, menu.COLOR_GOLD.g, menu.COLOR_GOLD.b, 0.22)
		st_active.border_color = menu.COLOR_GOLD
		st_active.border_width_left = 1; st_active.border_width_right  = 1
		st_active.border_width_top  = 1; st_active.border_width_bottom = 1
		if mode == "carousel":
			st_active.corner_radius_top_left    = 8; st_active.corner_radius_bottom_left = 8
		else:
			st_active.corner_radius_top_right   = 8; st_active.corner_radius_bottom_right = 8

		var st_idle = st_active.duplicate()
		st_idle.bg_color     = Color(0.12, 0.12, 0.18, 0.7)
		st_idle.border_color = Color(0.28, 0.28, 0.38, 0.6)

		var st_hover = st_idle.duplicate()
		st_hover.bg_color = Color(0.18, 0.18, 0.26, 0.9)

		var is_active = _deck_view_mode == mode
		btn.add_theme_stylebox_override("normal",  st_active if is_active else st_idle)
		btn.add_theme_stylebox_override("hover",   st_active if is_active else st_hover)
		btn.add_theme_stylebox_override("pressed", st_active)
		btn.add_theme_color_override("font_color",
			Color.WHITE if is_active else Color(0.55, 0.55, 0.65))
		return btn

	var btn_carousel = _build_toggle_btn.call("☰", "carousel")
	var btn_grid     = _build_toggle_btn.call("⊞", "grid")
	btn_carousel.tooltip_text = "Vista carrusel (1 mazo)"
	btn_grid.tooltip_text     = "Vista grid (todos los mazos)"
	toggle_hbox.add_child(btn_carousel)
	toggle_hbox.add_child(btn_grid)

	# ── Zona de contenido (se reconstruye al cambiar vista) ──
	var content_root = Control.new()
	content_root.name = "DeckContentRoot"
	content_root.anchor_left   = 0; content_root.anchor_right  = 1
	content_root.anchor_top    = 0; content_root.anchor_bottom = 1
	content_root.offset_top    = 70
	container.add_child(content_root)

	# Función que reconstruye el contenido según el modo actual
	var rebuild_content = func():
		for c in content_root.get_children(): c.queue_free()
		if _deck_view_mode == "carousel":
			_build_carousel_view(content_root, container, menu)
		else:
			_build_grid_view(content_root, container, menu)

	btn_carousel.pressed.connect(func():
		if _deck_view_mode == "carousel": return
		_deck_view_mode = "carousel"
		rebuild_content.call()
		# Redibujar botones
		build_deck_selection(container, menu)
	)
	btn_grid.pressed.connect(func():
		if _deck_view_mode == "grid": return
		_deck_view_mode = "grid"
		rebuild_content.call()
		# Redibujar botones
		build_deck_selection(container, menu)
	)

	rebuild_content.call()


# ============================================================
# VISTA CARRUSEL — idéntica a la original
# ============================================================
static func _build_carousel_view(content_root: Control, container: Control, menu) -> void:
	var max_slots = PlayerData.deck_slots
	
	var slots = []
	for s in range(1, 5):
		slots.append({
			"slot": s,
			"locked": s > max_slots,
		})
		
	# Ordenar: slot activo primero
	var active_slot = PlayerData.active_deck_slot
	slots.sort_custom(func(a, b):
		if a.slot == active_slot: return true
		if b.slot == active_slot: return false
		return a.slot < b.slot
	)

	var current_idx_ref = {"v": 0}

	var carousel_root = Control.new()
	carousel_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	carousel_root.offset_top    = 0
	carousel_root.offset_bottom = -20
	content_root.add_child(carousel_root)

	var btn_left = Button.new()
	btn_left.text = "❮"
	btn_left.add_theme_font_size_override("font_size", 48)
	btn_left.add_theme_color_override("font_color", Color(1, 1, 1, 0.8))
	btn_left.anchor_left = 0; btn_left.anchor_right  = 0
	btn_left.anchor_top  = 0; btn_left.anchor_bottom = 1
	btn_left.offset_left = 0; btn_left.offset_right  = 72
	var st_arr = StyleBoxFlat.new(); st_arr.bg_color = Color(0,0,0,0)
	btn_left.add_theme_stylebox_override("normal",  st_arr)
	btn_left.add_theme_stylebox_override("hover",   st_arr)
	btn_left.add_theme_stylebox_override("pressed", st_arr)
	carousel_root.add_child(btn_left)

	var btn_right = Button.new()
	btn_right.text = "❯"
	btn_right.add_theme_font_size_override("font_size", 48)
	btn_right.add_theme_color_override("font_color", Color(1, 1, 1, 0.8))
	btn_right.anchor_left = 1; btn_right.anchor_right  = 1
	btn_right.anchor_top  = 0; btn_right.anchor_bottom = 1
	btn_right.offset_left = -72; btn_right.offset_right = 0
	btn_right.add_theme_stylebox_override("normal",  st_arr)
	btn_right.add_theme_stylebox_override("hover",   st_arr)
	btn_right.add_theme_stylebox_override("pressed", st_arr)
	carousel_root.add_child(btn_right)

	var card_center = CenterContainer.new()
	card_center.anchor_left = 0; card_center.anchor_right  = 1
	card_center.anchor_top  = 0; card_center.anchor_bottom = 1
	card_center.offset_left = 72; card_center.offset_right = -72
	card_center.clip_contents = false
	carousel_root.add_child(card_center)

	var dots_bar = HBoxContainer.new()
	dots_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	dots_bar.add_theme_constant_override("separation", 10)
	dots_bar.anchor_left = 0; dots_bar.anchor_right  = 1
	dots_bar.anchor_top  = 1; dots_bar.anchor_bottom = 1
	dots_bar.offset_top  = -28; dots_bar.offset_bottom = 0
	carousel_root.add_child(dots_bar)

	var dots: Array = []
	for i in slots.size():
		var dot = Label.new()
		dot.text = "●"
		dot.add_theme_font_size_override("font_size", 14)
		dots_bar.add_child(dot)
		dots.append(dot)

	var refresh_carousel = func():
		for c in card_center.get_children(): c.queue_free()
		var idx  = current_idx_ref.v
		var info = slots[idx]
		for i in dots.size():
			dots[i].add_theme_color_override("font_color",
				menu.COLOR_GOLD if i == idx else Color(0.4, 0.4, 0.4))
		btn_left.modulate.a  = 0.25 if idx == 0             else 1.0
		btn_right.modulate.a = 0.25 if idx == slots.size()-1 else 1.0
		var dummy_grid = HBoxContainer.new()
		dummy_grid.alignment     = BoxContainer.ALIGNMENT_CENTER
		dummy_grid.clip_contents = false
		card_center.add_child(dummy_grid)
		_create_deck_box(container, menu, dummy_grid, info.slot, info.locked)

	refresh_carousel.call()

	btn_left.pressed.connect(func():
		if current_idx_ref.v > 0:
			current_idx_ref.v -= 1
			refresh_carousel.call()
	)
	btn_right.pressed.connect(func():
		if current_idx_ref.v < slots.size() - 1:
			current_idx_ref.v += 1
			refresh_carousel.call()
	)


# ============================================================
# VISTA GRID — todos los mazos a la vez, activo primero
# ============================================================
static func _build_grid_view(content_root: Control, container: Control, menu) -> void:
	# Slots ordenados: activo primero, luego resto, bloqueados al final
	var active_slot = PlayerData.active_deck_slot
	var max_slots = PlayerData.deck_slots

	var all_slots = []
	for s in range(1, 9):
		all_slots.append({
			"slot": s,
			"locked": s > max_slots,
		})
	all_slots.sort_custom(func(a, b):
		# Activo primero
		if a.slot == active_slot and not a.locked: return true
		if b.slot == active_slot and not b.locked: return false
		# Bloqueados al final
		if a.locked and not b.locked: return false
		if b.locked and not a.locked: return true
		return a.slot < b.slot
	)

	# ── Cabecera de la vista grid: selector de columnas ─────
	var top_bar = HBoxContainer.new()
	top_bar.anchor_left   = 0;  top_bar.anchor_right  = 1
	top_bar.anchor_top    = 0;  top_bar.anchor_bottom = 0
	top_bar.offset_top    = 8;  top_bar.offset_bottom = 44
	top_bar.offset_left   = 24; top_bar.offset_right  = -24
	top_bar.add_theme_constant_override("separation", 12)
	content_root.add_child(top_bar)

	# Etiqueta
	var cols_lbl = Label.new()
	cols_lbl.text = "Mazos por fila:"
	cols_lbl.add_theme_font_size_override("font_size", 13)
	cols_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	cols_lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top_bar.add_child(cols_lbl)

	# Botones 1 / 2 / 3
	var cols_ref = [2]  # default: 2 por fila

	var grid_container_ref = [null]  # referencia al GridContainer para rebuild

	var scroll = ScrollContainer.new()
	scroll.anchor_left   = 0;  scroll.anchor_right  = 1
	scroll.anchor_top    = 0;  scroll.anchor_bottom = 1
	scroll.offset_top    = 52; scroll.offset_bottom = -16
	scroll.offset_left   = 16; scroll.offset_right  = -16
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	UITheme.apply_scrollbar_theme(scroll)
	content_root.add_child(scroll)

	var scroll_vbox = VBoxContainer.new()
	scroll_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_vbox.add_theme_constant_override("separation", 20)
	scroll.add_child(scroll_vbox)

	var rebuild_grid = func():
		for c in scroll_vbox.get_children(): c.queue_free()

		var grid = GridContainer.new()
		grid.columns = cols_ref[0]
		grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		# Separación generosa para que las cartas respiren
		grid.add_theme_constant_override("h_separation", 28)
		grid.add_theme_constant_override("v_separation", 28)
		scroll_vbox.add_child(grid)
		grid_container_ref[0] = grid

		for info in all_slots:
			var wrapper = Control.new()
			wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			wrapper.clip_contents = false
			# Altura mínima para que el abanico respire
			wrapper.custom_minimum_size = Vector2(0, 520)
			grid.add_child(wrapper)

			var inner = HBoxContainer.new()
			inner.alignment = BoxContainer.ALIGNMENT_CENTER
			inner.set_anchors_preset(Control.PRESET_FULL_RECT)
			inner.clip_contents = false
			wrapper.add_child(inner)

			_create_deck_box(container, menu, inner, info.slot, info.locked)

			# Badge "ACTIVO" encima del slot activo
			if info.slot == active_slot and not info.locked:
				var active_badge = Label.new()
				active_badge.text = "★ ACTIVO"
				active_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				active_badge.add_theme_font_size_override("font_size", 11)
				active_badge.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3))
				active_badge.anchor_left   = 0;  active_badge.anchor_right  = 1
				active_badge.anchor_top    = 0;  active_badge.anchor_bottom = 0
				active_badge.offset_top    = 4;  active_badge.offset_bottom = 20
				active_badge.mouse_filter  = Control.MOUSE_FILTER_IGNORE
				wrapper.add_child(active_badge)

	# Botones de columnas — se construyen ANTES del rebuild para que existan
	var col_btns: Array = []
	for n_cols in [1, 2, 3]:
		var cb = Button.new()
		cb.text = str(n_cols)
		cb.custom_minimum_size = Vector2(34, 30)
		cb.add_theme_font_size_override("font_size", 13)
		cb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		cb.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

		var st_cb_on = StyleBoxFlat.new()
		st_cb_on.bg_color     = Color(menu.COLOR_GOLD.r, menu.COLOR_GOLD.g, menu.COLOR_GOLD.b, 0.20)
		st_cb_on.border_color = menu.COLOR_GOLD
		st_cb_on.border_width_left = 1; st_cb_on.border_width_right  = 1
		st_cb_on.border_width_top  = 1; st_cb_on.border_width_bottom = 1
		st_cb_on.corner_radius_top_left    = 6; st_cb_on.corner_radius_top_right    = 6
		st_cb_on.corner_radius_bottom_left = 6; st_cb_on.corner_radius_bottom_right = 6
		var st_cb_off = st_cb_on.duplicate()
		st_cb_off.bg_color     = Color(0.12, 0.12, 0.18, 0.7)
		st_cb_off.border_color = Color(0.28, 0.28, 0.38, 0.5)
		var st_cb_hov = st_cb_off.duplicate()
		st_cb_hov.bg_color = Color(0.18, 0.18, 0.26, 0.9)

		var is_on = (n_cols == cols_ref[0])
		cb.add_theme_stylebox_override("normal",  st_cb_on  if is_on else st_cb_off)
		cb.add_theme_stylebox_override("hover",   st_cb_on  if is_on else st_cb_hov)
		cb.add_theme_stylebox_override("pressed", st_cb_on)
		cb.add_theme_color_override("font_color",
			Color.WHITE if is_on else Color(0.55, 0.55, 0.65))

		var nc = n_cols  # captura por valor
		cb.pressed.connect(func():
			cols_ref[0] = nc
			rebuild_grid.call()
			# Actualizar estilos de los botones de columna
			for i in col_btns.size():
				var is_sel = (col_btns[i] == cb)
				col_btns[i].add_theme_stylebox_override("normal",
					st_cb_on if is_sel else st_cb_off)
				col_btns[i].add_theme_color_override("font_color",
					Color.WHITE if is_sel else Color(0.55, 0.55, 0.65))
		)
		top_bar.add_child(cb)
		col_btns.append(cb)

	rebuild_grid.call()


# ============================================================
# _create_deck_box — con abanico ANIMADO (sin cambios)
# ============================================================
static func _create_deck_box(container: Control, menu, parent: Control, slot_id: int, is_locked: bool) -> void:

	var outer = Control.new()
	outer.custom_minimum_size    = Vector2(310, 500)
	outer.size_flags_horizontal  = Control.SIZE_SHRINK_CENTER
	outer.size_flags_vertical    = Control.SIZE_SHRINK_CENTER
	outer.clip_contents = false
	parent.add_child(outer)

	var deck_data    : Dictionary = {} if is_locked else PlayerData.decks.get(str(slot_id), {})
	var deck_cards   : Array      = deck_data.get("cards", [])
	var deck_name    : String     = deck_data.get("name", "Mazo " + str(slot_id))
	var featured_ids : Array      = deck_data.get("featured_cards", [])
	var is_empty     : bool       = deck_cards.size() == 0
	var is_active    : bool       = (PlayerData.active_deck_slot == slot_id)
	var deck_tier    : String     = _calculate_deck_tier(deck_cards) if deck_cards.size() == 60 else ""
	var tier_color   : Color      = TIER_COLORS.get(deck_tier, Color(0.5, 0.5, 0.5))

	var slot_idx    = clamp(slot_id - 1, 0, SLOT_COLORS.size() - 1)
	var funda_color : Color
	if is_locked:
		funda_color = Color(0.3, 0.3, 0.3, 0.5)
	elif deck_tier != "":
		funda_color = tier_color
	elif not is_empty:
		funda_color = SLOT_COLORS[slot_idx]
	else:
		funda_color = Color(SLOT_COLORS[slot_idx].r, SLOT_COLORS[slot_idx].g, SLOT_COLORS[slot_idx].b, 0.30)

	var fan_back = Control.new()
	fan_back.set_anchors_preset(Control.PRESET_FULL_RECT)
	fan_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fan_back.clip_contents = false

	var fan_rects : Array = []

	var PIVOT_X : float = 140.0
	var PIVOT_Y : float = 148.0
	var cw      : float = 100.0
	var ch      : float = 140.0

	var fan_cfgs = [
		{"rot": -20.0, "ox": -48.0, "oy":  0.0,  "alpha": 0.92, "layer": "back"},
		{"rot":   0.0, "ox":   0.0, "oy": -12.0, "alpha": 1.00, "layer": "back"},
		{"rot":  20.0, "ox":  48.0, "oy":  0.0,  "alpha": 0.92, "layer": "back"},
	]

	if featured_ids.size() > 0 and not is_empty and not is_locked:
		var use_cfgs : Array
		match featured_ids.size():
			1: use_cfgs = [1]
			2: use_cfgs = [0, 2]
			_: use_cfgs = [0, 1, 2]

		for fi in use_cfgs.size():
			var card_id  = featured_ids[fi]
			var cfg      = fan_cfgs[use_cfgs[fi]]
			var card_tex = _load_card_texture_cached(card_id)
			if not card_tex: continue

			var fan_rect = TextureRect.new()
			fan_rect.texture             = card_tex
			fan_rect.custom_minimum_size = Vector2(cw, ch)
			fan_rect.expand_mode         = TextureRect.EXPAND_IGNORE_SIZE
			fan_rect.stretch_mode        = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			fan_rect.modulate            = Color(1.0, 1.0, 1.0, 0.0)
			fan_rect.mouse_filter        = Control.MOUSE_FILTER_IGNORE
			fan_rect.pivot_offset = Vector2(cw * 0.5, ch)

			var final_pos = Vector2(
				PIVOT_X - cw * 0.5 + cfg.ox,
				PIVOT_Y - ch       + cfg.oy
			)
			var final_rot = deg_to_rad(cfg.rot)

			fan_rect.position = Vector2(final_pos.x, final_pos.y + 40.0)
			fan_rect.rotation = 0.0
			fan_back.add_child(fan_rect)

			fan_rects.append({
				"rect":        fan_rect,
				"final_pos":   final_pos,
				"final_rot":   final_rot,
				"final_alpha": cfg.alpha,
				"cfg_rot":     cfg.rot,
				"layer":       cfg.layer,
			})

	var box = PanelContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.clip_contents = false

	var st = StyleBoxFlat.new()
	st.bg_color = Color(0.1, 0.12, 0.18, 0.95)
	st.corner_radius_top_left    = 14; st.corner_radius_top_right    = 14
	st.corner_radius_bottom_left = 14; st.corner_radius_bottom_right = 14

	if is_locked:
		st.border_width_left = 2; st.border_width_right  = 2
		st.border_width_top  = 2; st.border_width_bottom = 2
		st.border_color = Color(0.3, 0.3, 0.3)
	elif is_active:
		st.border_width_left = 4; st.border_width_right  = 4
		st.border_width_top  = 4; st.border_width_bottom = 4
		st.border_color = Color(0.3, 0.8, 0.3, 1.0)
		st.shadow_color = Color(0.2, 0.9, 0.2, 0.4)
		st.shadow_size  = 25
	else:
		st.border_width_left = 2; st.border_width_right  = 2
		st.border_width_top  = 2; st.border_width_bottom = 2
		st.border_color = funda_color
		if not is_empty:
			st.shadow_color = Color(funda_color.r, funda_color.g, funda_color.b, 0.25)
			st.shadow_size  = 12

	box.add_theme_stylebox_override("panel", st)
	outer.add_child(box)

	if fan_rects.size() > 0:
		var tween = outer.create_tween().set_parallel(false)
		tween.tween_interval(0.05)

		for i in fan_rects.size():
			var fr    = fan_rects[i]
			var rect  = fr.rect

			tween.tween_callback(func():
				if not is_instance_valid(rect): return
				var sub = rect.create_tween().set_parallel(true)
				sub.set_ease(Tween.EASE_OUT)
				sub.set_trans(Tween.TRANS_BACK)
				sub.tween_property(rect, "position", fr.final_pos,   0.45)
				sub.tween_property(rect, "rotation", fr.final_rot,   0.45)
				sub.tween_property(rect, "modulate", Color(1.0, 1.0, 1.0, fr.final_alpha), 0.30)
			)
			if i < fan_rects.size() - 1:
				tween.tween_interval(0.07)

		tween.tween_interval(0.5)
		tween.tween_callback(func():
			for fi in fan_rects.size():
				var fr   = fan_rects[fi]
				var rect = fr.rect
				if not is_instance_valid(rect): continue
				var base_rot = fr.final_rot
				var loop_tw = rect.create_tween()
				loop_tw.set_loops()
				loop_tw.set_ease(Tween.EASE_IN_OUT)
				loop_tw.set_trans(Tween.TRANS_SINE)
				var amp       = deg_to_rad(2.5)
				var phase_off = fi * 0.18
				loop_tw.tween_property(rect, "rotation", base_rot + amp,       0.9 + phase_off)
				loop_tw.tween_property(rect, "rotation", base_rot - amp * 0.6, 0.9 + phase_off)
				loop_tw.tween_property(rect, "rotation", base_rot,             0.6 + phase_off)
		)

	box.add_child(fan_back)

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 6)
	box.add_child(vbox)

	if is_locked:
		var lbl = Label.new()
		lbl.text = "🔒\nSLOT BLOQUEADO"
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_color_override("font_color", Color.GRAY)
		vbox.add_child(lbl)
		var btn = Button.new()
		btn.text = "Comprar en Tienda"
		btn.custom_minimum_size   = Vector2(160, 40)
		btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		vbox.add_child(UITheme.vspace(20))
		vbox.add_child(btn)
		return

	var funda_tex = load("res://assets/iconos/deckFunda.png") as Texture2D
	var funda_row = HBoxContainer.new()
	funda_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(funda_row)

	if funda_tex:
		var funda_img = TextureRect.new()
		funda_img.texture             = funda_tex
		funda_img.custom_minimum_size = Vector2(210, 294)
		funda_img.expand_mode         = TextureRect.EXPAND_IGNORE_SIZE
		funda_img.stretch_mode        = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		funda_img.modulate            = funda_color
		funda_row.add_child(funda_img)
	else:
		var icon_lbl = Label.new()
		icon_lbl.text = "🃏"
		icon_lbl.add_theme_font_size_override("font_size", 80)
		funda_row.add_child(icon_lbl)

	if deck_tier != "":
		var tier_lbl = Label.new()
		tier_lbl.text = "TIER  " + deck_tier
		tier_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tier_lbl.add_theme_font_size_override("font_size", 14)
		tier_lbl.add_theme_color_override("font_color", tier_color)
		vbox.add_child(tier_lbl)

	var name_lbl = Label.new()
	name_lbl.text = "VACÍO" if is_empty else deck_name
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 17)
	name_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5) if is_empty else Color.WHITE)
	name_lbl.custom_minimum_size       = Vector2(210, 0)
	name_lbl.autowrap_mode             = TextServer.AUTOWRAP_OFF
	name_lbl.text_overrun_behavior     = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_lbl.clip_text                 = true
	vbox.add_child(name_lbl)

	var count_lbl = Label.new()
	count_lbl.text = str(deck_cards.size()) + "/60 Cartas"
	count_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	count_lbl.add_theme_font_size_override("font_size", 13)
	count_lbl.add_theme_color_override("font_color", menu.COLOR_GREEN if deck_cards.size() == 60 else menu.COLOR_RED)
	vbox.add_child(count_lbl)

	vbox.add_child(UITheme.vspace(8))

	var edit_btn = Button.new()
	edit_btn.text = "➕ Crear Mazo" if is_empty else "✏️ Editar Mazo"
	edit_btn.custom_minimum_size   = Vector2(200, 38)
	edit_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var st_btn = StyleBoxFlat.new()
	st_btn.bg_color = menu.COLOR_PURPLE if is_empty else menu.COLOR_ACCENT
	st_btn.corner_radius_top_left    = 6; st_btn.corner_radius_top_right    = 6
	st_btn.corner_radius_bottom_left = 6; st_btn.corner_radius_bottom_right = 6
	edit_btn.add_theme_stylebox_override("normal", st_btn)
	edit_btn.pressed.connect(func():
		menu.current_deck = deck_cards.duplicate()
		menu.deck_name    = deck_name
		menu.set_meta("editing_slot", slot_id)
		var fresh_featured = PlayerData.get_deck_featured(slot_id)
		menu.set_meta("featured_cards_editing", fresh_featured.duplicate())
		_grid_cache.clear()
		_grid_cache_key = ""
		build_deck_editor(container, menu, slot_id)
	)
	vbox.add_child(edit_btn)

	if not is_empty:
		vbox.add_child(UITheme.vspace(4))
		var active_btn = Button.new()
		active_btn.custom_minimum_size   = Vector2(200, 38)
		active_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

		if is_active:
			active_btn.text     = "✅ Mazo Activo"
			active_btn.disabled = true
			var st_act = StyleBoxFlat.new()
			st_act.bg_color = Color(0.2, 0.6, 0.2, 0.8)
			st_act.corner_radius_top_left    = 6; st_act.corner_radius_top_right    = 6
			st_act.corner_radius_bottom_left = 6; st_act.corner_radius_bottom_right = 6
			active_btn.add_theme_stylebox_override("disabled", st_act)
			active_btn.add_theme_color_override("font_disabled_color", Color.WHITE)
		else:
			active_btn.text = "Hacer Activo"
			var st_inact = StyleBoxFlat.new()
			st_inact.bg_color = Color(0.3, 0.3, 0.3, 0.8)
			st_inact.corner_radius_top_left    = 6; st_inact.corner_radius_top_right    = 6
			st_inact.corner_radius_bottom_left = 6; st_inact.corner_radius_bottom_right = 6
			active_btn.add_theme_stylebox_override("normal", st_inact)

			active_btn.pressed.connect(func():
				PlayerData.active_deck_slot = slot_id
				if PlayerData.has_method("save_active_deck_to_server"):
					PlayerData.save_active_deck_to_server(slot_id)
				else:
					var http = HTTPRequest.new()
					container.add_child(http)
					var url     = NetworkManager.BASE_URL + "/api/user/active-deck"
					var headers = ["Authorization: Bearer " + NetworkManager.token, "Content-Type: application/json"]
					var payload = JSON.stringify({"active_deck_slot": slot_id})
					http.request(url, headers, HTTPClient.METHOD_PUT, payload)
					http.request_completed.connect(func(_res, code, _h, _body):
						if is_instance_valid(http): http.queue_free()
					)
				build_deck_selection(container, menu)
			)

		vbox.add_child(active_btn)
		vbox.add_child(UITheme.vspace(4))
		var clear_deck_btn = Button.new()
		clear_deck_btn.text = "🗑  Vaciar Mazo"
		clear_deck_btn.custom_minimum_size   = Vector2(200, 38)
		clear_deck_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		var st_clear = StyleBoxFlat.new()
		st_clear.bg_color = Color(0.28, 0.08, 0.08, 0.85)
		st_clear.border_color = Color(0.70, 0.20, 0.20, 0.60)
		st_clear.border_width_left = 1; st_clear.border_width_right  = 1
		st_clear.border_width_top  = 1; st_clear.border_width_bottom = 1
		st_clear.corner_radius_top_left    = 6; st_clear.corner_radius_top_right    = 6
		st_clear.corner_radius_bottom_left = 6; st_clear.corner_radius_bottom_right = 6
		var st_clear_hov = st_clear.duplicate()
		st_clear_hov.bg_color = Color(0.50, 0.10, 0.10, 0.95)
		clear_deck_btn.add_theme_stylebox_override("normal", st_clear)
		clear_deck_btn.add_theme_stylebox_override("hover",  st_clear_hov)
		clear_deck_btn.add_theme_color_override("font_color", Color(0.95, 0.60, 0.60))
		clear_deck_btn.add_theme_font_size_override("font_size", 12)
		clear_deck_btn.pressed.connect(func():
			var confirm = AcceptDialog.new()
			confirm.title = "¿Vaciar mazo?"
			confirm.dialog_text = "¿Seguro que querés vaciar\n\"%s\"?\n\nEsta acción no se puede deshacer." % deck_name
			confirm.ok_button_text = "Sí, vaciar"
			container.add_child(confirm)
			confirm.popup_centered()
			confirm.confirmed.connect(func():
				var http = HTTPRequest.new()
				container.add_child(http)
				var headers = ["Authorization: Bearer " + NetworkManager.token, "Content-Type: application/json"]
				http.request(
					NetworkManager.BASE_URL + "/api/decks/clear",
					headers,
					HTTPClient.METHOD_POST,
					JSON.stringify({"slot": slot_id})
				)
				http.request_completed.connect(func(_res, _code, _h, _body):
					http.queue_free()
					PlayerData.decks[str(slot_id)] = {"name": deck_name, "cards": [], "featured_cards": []}
					confirm.queue_free()
					build_deck_selection(container, menu)
				)
			)
			confirm.canceled.connect(func(): confirm.queue_free())
		)
		vbox.add_child(clear_deck_btn)
		
		


# ============================================================
# VISTA 2: EL EDITOR DE MAZOS (sin cambios)
# ============================================================
static func build_deck_editor(container: Control, menu, current_slot: int) -> void:
	var C = menu
	for c in container.get_children(): c.queue_free()

	var is_gym_mode : bool   = menu.get_meta("deck_mode", "normal") == "gym"
	var gym_role    : String = menu.get_meta("gym_role",  "leader")

	var bg_image = TextureRect.new()
	var bg_tex = load("res://assets/imagen/fondomenu.png")
	if bg_tex: bg_image.texture = bg_tex
	bg_image.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_image.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	bg_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg_image.modulate     = Color(0.15, 0.15, 0.15, 1)
	container.add_child(bg_image)

	var header = Panel.new()
	header.anchor_left = 0; header.anchor_right  = 1
	header.anchor_top  = 0; header.anchor_bottom = 0
	header.offset_top  = 0; header.offset_bottom = 70
	var hs = StyleBoxFlat.new()
	hs.bg_color     = Color(C.COLOR_PANEL.r,    C.COLOR_PANEL.g,    C.COLOR_PANEL.b,    0.85)
	hs.border_color = Color(C.COLOR_GOLD_DIM.r, C.COLOR_GOLD_DIM.g, C.COLOR_GOLD_DIM.b, 0.3)
	hs.border_width_bottom = 1
	header.add_theme_stylebox_override("panel", hs)
	container.add_child(header)

	var hbox = HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	header.add_child(hbox)

	var back_label : String
	if not is_gym_mode:
		back_label = "⬅ Volver a Mis Mazos"
	elif gym_role == "leader":
		back_label = "⬅ Volver al Panel Líder"
	else:
		back_label = "⬅ Volver a Mis Tiers"

	var back_btn = Button.new()
	back_btn.text                = back_label
	back_btn.custom_minimum_size = Vector2(200, 0)
	var st_back = StyleBoxFlat.new()
	st_back.bg_color = Color(0.2, 0.2, 0.2, 0.8)
	back_btn.add_theme_stylebox_override("normal", st_back)
	back_btn.pressed.connect(func():
		_grid_cache.clear()
		_grid_cache_key = ""
		if is_gym_mode:
			if gym_role == "leader":
				menu.set_meta("deck_mode", "normal")
				menu.navigate_to("LiderGymScreen", {"gym_id": menu.get_meta("gym_editing_id", "")})
			else:
				build_gym_tier_selection(container, menu)
		else:
			build_deck_selection(container, menu)
	)
	hbox.add_child(back_btn)

	var title_m = MarginContainer.new()
	title_m.add_theme_constant_override("margin_left", 20)
	title_m.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(title_m)

	var title_v = VBoxContainer.new()
	title_v.alignment = BoxContainer.ALIGNMENT_CENTER
	title_v.add_theme_constant_override("separation", 2)
	title_m.add_child(title_v)

	var name_input = LineEdit.new()
	name_input.text             = menu.deck_name
	name_input.placeholder_text = "Nombre del Mazo"
	name_input.max_length       = 30
	name_input.add_theme_font_size_override("font_size", 16)
	name_input.add_theme_color_override("font_color", C.COLOR_GOLD)
	name_input.custom_minimum_size = Vector2(250, 30)
	if is_gym_mode: name_input.editable = false
	name_input.text_changed.connect(func(new_text): menu.deck_name = new_text)
	var st_input = StyleBoxFlat.new(); st_input.bg_color = Color(0, 0, 0, 0)
	name_input.add_theme_stylebox_override("normal", st_input)
	title_v.add_child(name_input)

	var count_lbl = Label.new()
	count_lbl.name = "CountLbl"
	count_lbl.text = str(C.current_deck.size()) + " / 60 Cartas"
	count_lbl.add_theme_font_size_override("font_size", 12)
	count_lbl.add_theme_color_override("font_color", C.COLOR_TEXT_DIM)
	title_v.add_child(count_lbl)

	var tier_lbl = Label.new()
	tier_lbl.name = "TierLbl"
	tier_lbl.text = ""
	tier_lbl.add_theme_font_size_override("font_size", 12)
	tier_lbl.add_theme_color_override("font_color", C.COLOR_TEXT_DIM)
	title_v.add_child(tier_lbl)

	var main_area = HBoxContainer.new()
	main_area.anchor_left = 0; main_area.anchor_right  = 1
	main_area.anchor_top  = 0; main_area.anchor_bottom = 1
	main_area.offset_top  = 75; main_area.offset_bottom = -20
	main_area.offset_left = 24; main_area.offset_right  = -24
	main_area.add_theme_constant_override("separation", 16)
	container.add_child(main_area)

	var st_coll = StyleBoxFlat.new()
	st_coll.bg_color     = Color(C.COLOR_PANEL.r,    C.COLOR_PANEL.g,    C.COLOR_PANEL.b,    0.95)
	st_coll.border_color = Color(C.COLOR_GOLD_DIM.r, C.COLOR_GOLD_DIM.g, C.COLOR_GOLD_DIM.b, 0.3)
	st_coll.border_width_left = 1; st_coll.border_width_right  = 1
	st_coll.border_width_top  = 1; st_coll.border_width_bottom = 1
	st_coll.corner_radius_top_left    = 16; st_coll.corner_radius_top_right    = 16
	st_coll.corner_radius_bottom_left = 16; st_coll.corner_radius_bottom_right = 16

	var coll_panel = PanelContainer.new()
	coll_panel.size_flags_horizontal    = Control.SIZE_EXPAND_FILL
	coll_panel.size_flags_stretch_ratio = 0.50
	coll_panel.add_theme_stylebox_override("panel", st_coll)
	main_area.add_child(coll_panel)

	var cv_m = MarginContainer.new()
	cv_m.add_theme_constant_override("margin_left",   20)
	cv_m.add_theme_constant_override("margin_right",  20)
	cv_m.add_theme_constant_override("margin_top",    16)
	cv_m.add_theme_constant_override("margin_bottom", 16)
	coll_panel.add_child(cv_m)

	var cv = VBoxContainer.new()
	cv.add_theme_constant_override("separation", 12)
	cv_m.add_child(cv)

	var coll_title = Label.new()
	if is_gym_mode:
		var tier_editing = menu.get_meta("gym_tier_editing", "")
		coll_title.text = "CARTAS DEL GYM · TIPO " + str(menu.get_meta("gym_type", "")) + " E INCOLORO" \
			+ ("  ·  TIER " + tier_editing if tier_editing != "" else "")
	else:
		coll_title.text = "MI COLECCIÓN  ·  Click Izq: Agregar | Click Der: Ver" if PlayerData.is_logged_in else "TODAS LAS CARTAS"
	coll_title.add_theme_font_size_override("font_size", 12)
	coll_title.add_theme_color_override("font_color", C.COLOR_GOLD_DIM)
	cv.add_child(coll_title)

	var filter_vbox = VBoxContainer.new()
	filter_vbox.add_theme_constant_override("separation", 6)
	cv.add_child(filter_vbox)

	var filter_row1 = HBoxContainer.new()
	filter_row1.add_theme_constant_override("separation", 8)
	filter_vbox.add_child(filter_row1)

	var search_in = LineEdit.new()
	search_in.name             = "SearchInput"
	search_in.placeholder_text = "🔎 Nombre, tipo, rareza…"
	search_in.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	search_in.add_theme_stylebox_override("normal", UITheme.input_style(Color(0.2, 0.2, 0.3)))
	search_in.add_theme_stylebox_override("focus",  UITheme.input_style(C.COLOR_GOLD))
	filter_row1.add_child(search_in)

	var cat_opt = OptionButton.new()
	cat_opt.name = "CatFilter"
	for item in ["Cat: Todas","Pokemon","Básico","Bebé","Fase 1","Fase 2","Entrenador","Energía"]:
		cat_opt.add_item(item)
	cat_opt.custom_minimum_size = Vector2(110, 0)
	filter_row1.add_child(cat_opt)

	var rarity_opt = OptionButton.new()
	rarity_opt.name = "RarityFilter"
	for item in ["Rareza: Todas","Común","Infrecuente","Rara","Holo","Ultra Rara"]:
		rarity_opt.add_item(item)
	rarity_opt.custom_minimum_size = Vector2(120, 0)
	filter_row1.add_child(rarity_opt)

	var filter_row2 = HBoxContainer.new()
	filter_row2.add_theme_constant_override("separation", 8)
	filter_vbox.add_child(filter_row2)

	if not is_gym_mode:
		var elem_opt = OptionButton.new()
		elem_opt.name = "ElemFilter"
		for item in ["Elem: Todos","Fuego","Agua","Planta","Rayo","Psíquico","Lucha","Incoloro","Siniestro","Metálico"]:
			elem_opt.add_item(item)
		elem_opt.custom_minimum_size = Vector2(130, 0)
		filter_row2.add_child(elem_opt)

	var sort_opt = OptionButton.new()
	sort_opt.name = "SortFilter"
	for item in ["Orden: Nombre ↑","Nombre ↓","Poder ↑","Poder ↓","Rareza"]:
		sort_opt.add_item(item)
	sort_opt.custom_minimum_size = Vector2(130, 0)
	filter_row2.add_child(sort_opt)

	var in_deck_btn = Button.new()
	in_deck_btn.name             = "InDeckFilter"
	in_deck_btn.text             = "En mazo"
	in_deck_btn.toggle_mode      = true
	in_deck_btn.custom_minimum_size = Vector2(80, 0)
	var st_tog_off = StyleBoxFlat.new()
	st_tog_off.bg_color     = Color(0.15, 0.15, 0.2, 0.8)
	st_tog_off.border_color = Color(0.3, 0.3, 0.4)
	st_tog_off.border_width_left = 1; st_tog_off.border_width_right  = 1
	st_tog_off.border_width_top  = 1; st_tog_off.border_width_bottom = 1
	st_tog_off.corner_radius_top_left = 5; st_tog_off.corner_radius_bottom_right = 5
	var st_tog_on = st_tog_off.duplicate()
	st_tog_on.bg_color     = Color(0.15, 0.4, 0.15, 0.9)
	st_tog_on.border_color = Color(0.3, 0.8, 0.3)
	in_deck_btn.add_theme_stylebox_override("normal",   st_tog_off)
	in_deck_btn.add_theme_stylebox_override("hover",    st_tog_off)
	in_deck_btn.add_theme_stylebox_override("pressed",  st_tog_on)
	filter_row2.add_child(in_deck_btn)

	var clear_filter_btn = Button.new()
	clear_filter_btn.text = "✕ Limpiar"
	clear_filter_btn.custom_minimum_size = Vector2(70, 0)
	clear_filter_btn.add_theme_font_size_override("font_size", 11)
	var st_clr = StyleBoxFlat.new()
	st_clr.bg_color = Color(0.25, 0.15, 0.15, 0.8)
	clear_filter_btn.add_theme_stylebox_override("normal", st_clr)
	clear_filter_btn.pressed.connect(func():
		search_in.text = ""
		cat_opt.selected = 0
		rarity_opt.selected = 0
		sort_opt.selected = 0
		in_deck_btn.button_pressed = false
		var elem_box2 = UITheme.find_node(container, "ElemFilter") as OptionButton
		if elem_box2: elem_box2.selected = 0
		_refresh_collection_grid(container, menu)
	)
	filter_row2.add_child(clear_filter_btn)

	var result_lbl = Label.new()
	result_lbl.name = "FilterResultLbl"
	result_lbl.text = ""
	result_lbl.add_theme_font_size_override("font_size", 10)
	result_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	result_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	result_lbl.horizontal_alignment  = HORIZONTAL_ALIGNMENT_RIGHT
	filter_row2.add_child(result_lbl)

	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UITheme.apply_scrollbar_theme(scroll)
	cv.add_child(scroll)

	var grid = GridContainer.new()
	grid.name    = "CollectionGrid"
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 16)
	scroll.add_child(grid)

	search_in.text_changed.connect(func(_t): _refresh_collection_grid(container, menu))
	cat_opt.item_selected.connect(func(_i):  _refresh_collection_grid(container, menu))
	rarity_opt.item_selected.connect(func(_i): _refresh_collection_grid(container, menu))
	sort_opt.item_selected.connect(func(_i):   _refresh_collection_grid(container, menu))
	in_deck_btn.toggled.connect(func(_p):      _refresh_collection_grid(container, menu))
	var elem_box_ref = UITheme.find_node(container, "ElemFilter") as OptionButton
	if elem_box_ref:
		elem_box_ref.item_selected.connect(func(_i): _refresh_collection_grid(container, menu))

	var preview_panel = PanelContainer.new()
	preview_panel.size_flags_horizontal    = Control.SIZE_EXPAND_FILL
	preview_panel.size_flags_stretch_ratio = 0.25
	var st_prev = st_coll.duplicate()
	st_prev.bg_color = Color(0.04, 0.05, 0.08, 0.98)
	preview_panel.add_theme_stylebox_override("panel", st_prev)
	main_area.add_child(preview_panel)

	var prev_m = MarginContainer.new()
	prev_m.add_theme_constant_override("margin_left",   16)
	prev_m.add_theme_constant_override("margin_right",  16)
	prev_m.add_theme_constant_override("margin_top",    16)
	prev_m.add_theme_constant_override("margin_bottom", 16)
	preview_panel.add_child(prev_m)

	var prev_v = VBoxContainer.new()
	prev_v.alignment = BoxContainer.ALIGNMENT_CENTER
	prev_m.add_child(prev_v)

	var prev_img = TextureRect.new()
	prev_img.name = "PreviewImage"
	prev_img.size_flags_vertical = Control.SIZE_EXPAND_FILL
	prev_img.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	prev_img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	prev_v.add_child(prev_img)
	prev_v.add_child(UITheme.vspace(6))

	var prev_power = Label.new()
	prev_power.name = "PreviewPower"
	prev_power.text = ""
	prev_power.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prev_power.add_theme_font_size_override("font_size", 42)
	prev_power.add_theme_color_override("font_color", Color(1.0, 0.85, 0.1))
	prev_power.visible = false
	prev_v.add_child(prev_power)

	var prev_power_lbl = Label.new()
	prev_power_lbl.name = "PreviewPowerLbl"
	prev_power_lbl.text = "PODER"
	prev_power_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prev_power_lbl.add_theme_font_size_override("font_size", 9)
	prev_power_lbl.add_theme_color_override("font_color", Color(0.6, 0.55, 0.25))
	prev_power_lbl.visible = false
	prev_v.add_child(prev_power_lbl)

	prev_v.add_child(UITheme.vspace(4))

	var prev_name = Label.new()
	prev_name.name = "PreviewName"
	prev_name.text = "Pasa el mouse o\nClick Derecho en una carta"
	prev_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prev_name.autowrap_mode        = TextServer.AUTOWRAP_WORD
	prev_name.add_theme_font_size_override("font_size", 13)
	prev_name.add_theme_color_override("font_color", C.COLOR_GOLD)
	prev_v.add_child(prev_name)

	var dp_panel = PanelContainer.new()
	dp_panel.name = "DeckPanel"
	dp_panel.size_flags_horizontal    = Control.SIZE_EXPAND_FILL
	dp_panel.size_flags_stretch_ratio = 0.25
	var st_dp = st_coll.duplicate()
	st_dp.bg_color = Color(C.COLOR_BG.r, C.COLOR_BG.g, C.COLOR_BG.b, 0.98)
	dp_panel.add_theme_stylebox_override("panel", st_dp)
	main_area.add_child(dp_panel)

	var dp_m = MarginContainer.new()
	dp_m.add_theme_constant_override("margin_left",   20)
	dp_m.add_theme_constant_override("margin_right",  20)
	dp_m.add_theme_constant_override("margin_top",    16)
	dp_m.add_theme_constant_override("margin_bottom", 16)
	dp_panel.add_child(dp_m)

	var dv = VBoxContainer.new()
	dv.add_theme_constant_override("separation", 12)
	dp_m.add_child(dv)

	var funda_tex_editor = load("res://assets/iconos/deckFunda.png") as Texture2D
	var deck_header_row = HBoxContainer.new()
	deck_header_row.alignment = BoxContainer.ALIGNMENT_CENTER
	deck_header_row.add_theme_constant_override("separation", 10)
	dv.add_child(deck_header_row)

	if funda_tex_editor:
		var funda_small = TextureRect.new()
		funda_small.texture             = funda_tex_editor
		funda_small.custom_minimum_size = Vector2(28, 40)
		funda_small.expand_mode         = TextureRect.EXPAND_IGNORE_SIZE
		funda_small.stretch_mode        = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		funda_small.modulate            = C.COLOR_GOLD
		funda_small.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		deck_header_row.add_child(funda_small)

	var deck_title_lbl = Label.new()
	deck_title_lbl.text = "LISTA DEL MAZO"
	deck_title_lbl.add_theme_font_size_override("font_size", 12)
	deck_title_lbl.add_theme_color_override("font_color", C.COLOR_GOLD_DIM)
	deck_title_lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	deck_header_row.add_child(deck_title_lbl)

	var ds = ScrollContainer.new()
	ds.name = "DeckScroll"
	ds.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dv.add_child(ds)

	var dl = VBoxContainer.new()
	dl.name = "DeckVBox"
	dl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dl.add_theme_constant_override("separation", 4)
	ds.add_child(dl)

	var clear_btn = Button.new()
	clear_btn.text = "Limpiar Todo"
	clear_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	clear_btn.custom_minimum_size   = Vector2(0, 32)
	clear_btn.add_theme_font_size_override("font_size", 11)
	clear_btn.pressed.connect(func():
		menu.current_deck = []
		menu.set_meta("featured_cards_editing", [])
		_grid_cache.clear()
		_grid_cache_key = ""
		_refresh_deck_list(container, dp_panel, header, menu)
		_refresh_collection_grid(container, menu)
	)
	dv.add_child(clear_btn)

	if not is_gym_mode:
		var feat_sep = HSeparator.new()
		feat_sep.modulate = Color(1, 1, 1, 0.15)
		dv.add_child(feat_sep)

		var feat_header = HBoxContainer.new()
		feat_header.add_theme_constant_override("separation", 6)
		dv.add_child(feat_header)

		var feat_icon = Label.new()
		feat_icon.text = "⭐"
		feat_icon.add_theme_font_size_override("font_size", 13)
		feat_header.add_child(feat_icon)

		var feat_title = Label.new()
		feat_title.name = "FeaturedTitle"
		feat_title.text = "CARTAS DESTACADAS  (0/3)"
		feat_title.add_theme_font_size_override("font_size", 11)
		feat_title.add_theme_color_override("font_color", C.COLOR_GOLD_DIM)
		feat_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		feat_header.add_child(feat_title)

		var feat_hint = Label.new()
		feat_hint.text = "⭐ en lista →"
		feat_hint.add_theme_font_size_override("font_size", 10)
		feat_hint.add_theme_color_override("font_color", Color(0.45, 0.45, 0.45))
		feat_header.add_child(feat_hint)

		var feat_row = HBoxContainer.new()
		feat_row.name      = "FeaturedRow"
		feat_row.alignment = BoxContainer.ALIGNMENT_CENTER
		feat_row.add_theme_constant_override("separation", 8)
		dv.add_child(feat_row)

		_refresh_featured_row(container, feat_row, feat_title, menu, current_slot)

	var save_btn = Button.new()
	save_btn.name = "SaveDeckBtn"
	save_btn.text = "Mazo Incompleto (0/60)"
	save_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	save_btn.custom_minimum_size   = Vector2(0, 36)
	save_btn.add_theme_font_size_override("font_size", 12)
	save_btn.add_theme_color_override("font_color", Color.WHITE)

	var st_save = StyleBoxFlat.new()
	st_save.bg_color = Color(0.15, 0.5, 0.2, 0.9)
	st_save.corner_radius_top_left    = 6; st_save.corner_radius_top_right    = 6
	st_save.corner_radius_bottom_left = 6; st_save.corner_radius_bottom_right = 6
	var st_save_hov      = st_save.duplicate(); st_save_hov.bg_color      = Color(0.2, 0.6, 0.25, 1)
	var st_save_disabled = st_save.duplicate(); st_save_disabled.bg_color = Color(0.3, 0.3, 0.3, 0.5)
	save_btn.add_theme_stylebox_override("normal",   st_save)
	save_btn.add_theme_stylebox_override("hover",    st_save_hov)
	save_btn.add_theme_stylebox_override("disabled", st_save_disabled)
	save_btn.disabled = true

	save_btn.pressed.connect(func():
		if menu.current_deck.size() == 60 and _has_basic_pokemon(menu.current_deck):
			if is_gym_mode:
				save_btn.text     = "Guardando en Gimnasio..."
				save_btn.disabled = true
				_save_gym_deck_to_server(container, menu, gym_role)
			else:
				var slot_to_save  = menu.get_meta("editing_slot", current_slot)
				var deck_tier     = _calculate_deck_tier(menu.current_deck)
				var featured_ids  = menu.get_meta("featured_cards_editing", []).duplicate()
				save_btn.text     = "Guardando..."
				save_btn.disabled = true
				PlayerData.save_deck_to_server(slot_to_save, menu.deck_name, menu.current_deck, deck_tier, featured_ids)

				var overlay = ColorRect.new()
				overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
				overlay.color        = Color(0, 0, 0, 0.55)
				overlay.z_index      = 100
				overlay.mouse_filter = Control.MOUSE_FILTER_STOP
				container.add_child(overlay)

				var popup = PanelContainer.new()
				popup.z_index = 101
				popup.custom_minimum_size = Vector2(380, 0)
				var st_pop = StyleBoxFlat.new()
				st_pop.bg_color              = Color(0.06, 0.06, 0.07, 0.98)
				st_pop.border_color          = Color(1.0, 0.78, 0.1, 0.9)
				st_pop.border_width_left     = 2; st_pop.border_width_right  = 2
				st_pop.border_width_top      = 2; st_pop.border_width_bottom = 2
				st_pop.corner_radius_top_left    = 14; st_pop.corner_radius_top_right    = 14
				st_pop.corner_radius_bottom_left = 14; st_pop.corner_radius_bottom_right = 14
				st_pop.shadow_color = Color(1.0, 0.78, 0.1, 0.18)
				st_pop.shadow_size  = 24
				popup.add_theme_stylebox_override("panel", st_pop)

				var center_pop = CenterContainer.new()
				center_pop.set_anchors_preset(Control.PRESET_FULL_RECT)
				overlay.add_child(center_pop)
				center_pop.add_child(popup)

				var pm = MarginContainer.new()
				pm.add_theme_constant_override("margin_left",   32)
				pm.add_theme_constant_override("margin_right",  32)
				pm.add_theme_constant_override("margin_top",    28)
				pm.add_theme_constant_override("margin_bottom", 28)
				popup.add_child(pm)

				var pv = VBoxContainer.new()
				pv.alignment = BoxContainer.ALIGNMENT_CENTER
				pv.add_theme_constant_override("separation", 14)
				pm.add_child(pv)

				var funda_tex_popup = load("res://assets/iconos/deckFunda.png") as Texture2D
				if funda_tex_popup:
					var pop_funda = TextureRect.new()
					pop_funda.texture               = funda_tex_popup
					pop_funda.custom_minimum_size   = Vector2(54, 76)
					pop_funda.expand_mode           = TextureRect.EXPAND_IGNORE_SIZE
					pop_funda.stretch_mode          = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
					pop_funda.modulate              = Color(1.0, 0.78, 0.1)
					pop_funda.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
					pv.add_child(pop_funda)

				var title_pop = Label.new()
				title_pop.text = "Mazo Guardado"
				title_pop.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				title_pop.add_theme_font_size_override("font_size", 20)
				title_pop.add_theme_color_override("font_color", Color.WHITE)
				pv.add_child(title_pop)

				var desc_pop = Label.new()
				desc_pop.text = "\"" + menu.deck_name + "\"\nse guardó correctamente."
				desc_pop.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				desc_pop.autowrap_mode        = TextServer.AUTOWRAP_WORD
				desc_pop.add_theme_font_size_override("font_size", 13)
				desc_pop.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
				pv.add_child(desc_pop)

				var ok_btn = Button.new()
				ok_btn.text                  = "OK"
				ok_btn.custom_minimum_size   = Vector2(140, 40)
				ok_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
				ok_btn.add_theme_font_size_override("font_size", 14)
				ok_btn.add_theme_color_override("font_color", Color(0.06, 0.06, 0.07))
				var st_ok = StyleBoxFlat.new()
				st_ok.bg_color = Color(1.0, 0.78, 0.1)
				st_ok.corner_radius_top_left    = 8; st_ok.corner_radius_top_right    = 8
				st_ok.corner_radius_bottom_left = 8; st_ok.corner_radius_bottom_right = 8
				var st_ok_hov = st_ok.duplicate()
				st_ok_hov.bg_color = Color(1.0, 0.88, 0.3)
				ok_btn.add_theme_stylebox_override("normal",  st_ok)
				ok_btn.add_theme_stylebox_override("hover",   st_ok_hov)
				ok_btn.add_theme_stylebox_override("pressed", st_ok)
				ok_btn.pressed.connect(func(): overlay.queue_free())
				pv.add_child(ok_btn)

				popup.modulate     = Color(1, 1, 1, 0)
				popup.scale        = Vector2(0.85, 0.85)
				popup.pivot_offset = Vector2(190, 80)
				SoundManager.play("save")
				var tween = container.create_tween().set_parallel(true)
				tween.set_ease(Tween.EASE_OUT)
				tween.set_trans(Tween.TRANS_BACK)
				tween.tween_property(popup, "modulate", Color(1, 1, 1, 1), 0.25)
				tween.tween_property(popup, "scale",    Vector2(1, 1),     0.25)
				save_btn.text     = "💾 Guardar Mazo en Servidor"
				save_btn.disabled = false
	)
	dv.add_child(save_btn)

	var err_lbl = Label.new()
	err_lbl.name = "SaveErrorLbl"
	err_lbl.text = ""
	err_lbl.visible = false
	err_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	err_lbl.add_theme_font_size_override("font_size", 12)
	err_lbl.add_theme_color_override("font_color", Color(1.0, 0.35, 0.35))
	dv.add_child(err_lbl)

	_refresh_deck_list(container, dp_panel, header, menu)
	_refresh_collection_grid(container, menu)


# ============================================================
# CARTAS DESTACADAS — helpers (sin cambios)
# ============================================================

static func _load_card_texture_cached(card_id: String) -> Texture2D:
	if _texture_cache.has(card_id):
		return _texture_cache[card_id]
	var card = CardDatabase.get_card(card_id)
	if card.is_empty(): return null
	var img_path = LanguageManager.get_card_image(card) if card.has("image") else card.get("image", "")
	if img_path == "": img_path = card.get("image", "")
	if img_path == "": return null
	var tex = load(img_path) as Texture2D
	if tex: _texture_cache[card_id] = tex
	return tex

static func _load_card_texture(card_id: String) -> Texture2D:
	return _load_card_texture_cached(card_id)


static func _refresh_featured_row(container: Control, feat_row: Control,
		feat_title: Label, menu, slot_id: int) -> void:
	for c in feat_row.get_children(): c.queue_free()

	var featured : Array = menu.get_meta("featured_cards_editing", [])

	if featured.is_empty() and slot_id > 0:
		featured = PlayerData.get_deck_featured(slot_id).duplicate()
		menu.set_meta("featured_cards_editing", featured)

	if feat_title:
		feat_title.text = "CARTAS DESTACADAS  (%d/3)" % featured.size()

	for i in 3:
		var slot_box = PanelContainer.new()
		slot_box.custom_minimum_size = Vector2(68, 96)
		var st_slot = StyleBoxFlat.new()
		st_slot.corner_radius_top_left    = 8; st_slot.corner_radius_top_right    = 8
		st_slot.corner_radius_bottom_left = 8; st_slot.corner_radius_bottom_right = 8

		if i < featured.size():
			var card_tex = _load_card_texture_cached(featured[i])
			st_slot.bg_color     = Color(0.1, 0.12, 0.18, 0.9)
			st_slot.border_color = Color(1.0, 0.78, 0.1, 0.9)
			st_slot.border_width_left = 2; st_slot.border_width_right  = 2
			st_slot.border_width_top  = 2; st_slot.border_width_bottom = 2
			slot_box.add_theme_stylebox_override("panel", st_slot)

			if card_tex:
				var img = TextureRect.new()
				img.texture      = card_tex
				img.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
				img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
				img.set_anchors_preset(Control.PRESET_FULL_RECT)
				slot_box.add_child(img)

			var rm_btn = Button.new()
			rm_btn.text = "×"
			rm_btn.add_theme_font_size_override("font_size", 14)
			rm_btn.add_theme_color_override("font_color", Color.WHITE)
			rm_btn.custom_minimum_size = Vector2(22, 22)
			rm_btn.anchor_left   = 1; rm_btn.anchor_right  = 1
			rm_btn.anchor_top    = 0; rm_btn.anchor_bottom = 0
			rm_btn.offset_left   = -24; rm_btn.offset_right  = 0
			rm_btn.offset_top    = 0;   rm_btn.offset_bottom = 24
			var st_rm = StyleBoxFlat.new()
			st_rm.bg_color = Color(0.7, 0.1, 0.1, 0.9)
			st_rm.corner_radius_top_left = 4; st_rm.corner_radius_bottom_right = 4
			rm_btn.add_theme_stylebox_override("normal", st_rm)
			rm_btn.z_index = 10
			var rm_idx = i
			rm_btn.pressed.connect(func():
				var f = menu.get_meta("featured_cards_editing", [])
				f.remove_at(rm_idx)
				menu.set_meta("featured_cards_editing", f)
				var ft = UITheme.find_node(container, "FeaturedTitle") as Label
				var fr = UITheme.find_node(container, "FeaturedRow")
				if fr: _refresh_featured_row(container, fr, ft, menu, slot_id)
			)
			slot_box.add_child(rm_btn)
		else:
			st_slot.bg_color     = Color(0.08, 0.10, 0.14, 0.6)
			st_slot.border_color = Color(0.3, 0.3, 0.35, 0.6)
			st_slot.border_width_left = 1; st_slot.border_width_right  = 1
			st_slot.border_width_top  = 1; st_slot.border_width_bottom = 1
			slot_box.add_theme_stylebox_override("panel", st_slot)

			var plus_lbl = Label.new()
			plus_lbl.text = "＋"
			plus_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			plus_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
			plus_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
			plus_lbl.add_theme_font_size_override("font_size", 28)
			plus_lbl.add_theme_color_override("font_color", Color(0.35, 0.35, 0.4))
			slot_box.add_child(plus_lbl)

		feat_row.add_child(slot_box)


static func _try_add_featured(container: Control, menu, card_id: String, slot_id: int) -> void:
	var featured : Array = menu.get_meta("featured_cards_editing", [])
	if featured.has(card_id):
		featured.erase(card_id)
	elif featured.size() < 3:
		featured.append(card_id)
	else:
		return
	menu.set_meta("featured_cards_editing", featured)
	var ft = UITheme.find_node(container, "FeaturedTitle") as Label
	var fr = UITheme.find_node(container, "FeaturedRow")
	if fr: _refresh_featured_row(container, fr, ft, menu, slot_id)


# ============================================================
# CACHÉ + GRID DE COLECCIÓN (sin cambios)
# ============================================================

static func _make_cache_key(menu, search_text: String, sel_cat: String,
		sel_elem: String, sel_rarity: String, sel_sort: String,
		in_deck_only: bool) -> String:
	var deck_hash = str(menu.current_deck.hash())
	return "%s|%s|%s|%s|%s|%s|%d" % [
		search_text, sel_cat, sel_elem, sel_rarity, sel_sort,
		deck_hash, int(in_deck_only)
	]


static func _refresh_collection_grid(container: Control, menu) -> void:
	var grid       = UITheme.find_node(container, "CollectionGrid")
	var search_box = UITheme.find_node(container, "SearchInput")   as LineEdit
	var cat_box    = UITheme.find_node(container, "CatFilter")     as OptionButton
	var elem_box   = UITheme.find_node(container, "ElemFilter")    as OptionButton
	var rarity_box = UITheme.find_node(container, "RarityFilter")  as OptionButton
	var sort_box   = UITheme.find_node(container, "SortFilter")    as OptionButton
	var in_deck_b  = UITheme.find_node(container, "InDeckFilter")  as Button
	var result_lbl = UITheme.find_node(container, "FilterResultLbl") as Label
	if not grid: return

	var is_gym_mode = menu.get_meta("deck_mode", "normal") == "gym"
	var gym_type    = menu.get_meta("gym_type", "COLORLESS") if is_gym_mode else ""

	var search_text  = search_box.text.strip_edges().to_lower() if search_box else ""
	var sel_cat      = cat_box.get_item_text(cat_box.selected)         if cat_box    else "Cat: Todas"
	var sel_elem     = elem_box.get_item_text(elem_box.selected)       if elem_box   else "Elem: Todos"
	var sel_rarity   = rarity_box.get_item_text(rarity_box.selected)   if rarity_box else "Rareza: Todas"
	var sel_sort     = sort_box.get_item_text(sort_box.selected)       if sort_box   else "Orden: Nombre ↑"
	var in_deck_only = in_deck_b.button_pressed                        if in_deck_b  else false

	var baby_names = ["pichu","cleffa","igglybuff","smoochum","tyrogue","elekid","magby"]

	var search_tokens : Array = []
	for tok in search_text.split(" ", false):
		if tok.length() > 0:
			search_tokens.append(tok)

	const TYPE_ALIASES = {
		"fuego": "FIRE", "fire": "FIRE",
		"agua": "WATER", "water": "WATER",
		"planta": "GRASS", "grass": "GRASS",
		"rayo": "LIGHTNING", "lightning": "LIGHTNING", "electrico": "LIGHTNING",
		"psiquico": "PSYCHIC", "psychic": "PSYCHIC",
		"lucha": "FIGHTING", "fighting": "FIGHTING",
		"incoloro": "COLORLESS", "colorless": "COLORLESS",
		"siniestro": "DARKNESS", "darkness": "DARKNESS", "oscuro": "DARKNESS",
		"metalico": "METAL", "metal": "METAL",
	}
	const RARITY_ALIASES = {
		"comun": "COMMON", "común": "COMMON", "common": "COMMON",
		"infrecuente": "UNCOMMON", "uncommon": "UNCOMMON",
		"rara": "RARE", "rare": "RARE",
		"holo": "RARE_HOLO",
		"ultra": "ULTRA_RARE", "ultrarara": "ULTRA_RARE",
	}

	var result_ids : Array = []

	for id in CardDatabase.get_all_ids():
		var card = CardDatabase.get_card(id)
		if card.is_empty(): continue

		var c_name   = card.get("name",   "").to_lower()
		var c_type   = card.get("type",   "").to_upper()
		var c_elem   = card.get("pokemon_type", card.get("type","")).to_upper()
		var c_rarity = card.get("rarity", "COMMON").to_upper()
		var c_stage  = card.get("stage",  0)
		var c_power  = int(card.get("power", 0))
		var is_baby  = card.get("is_baby", false) or c_name in baby_names

		if is_gym_mode:
			if c_type == "POKEMON" and c_elem != gym_type and c_elem != "COLORLESS": continue
			if c_type == "ENERGY"  and "SPECIAL" in c_rarity:                        continue

		if in_deck_only and not id in menu.current_deck: continue

		if search_tokens.size() > 0:
			var all_match = true
			for tok in search_tokens:
				var tok_match = false
				if tok in c_name:
					tok_match = true
				if not tok_match and TYPE_ALIASES.has(tok):
					if c_elem == TYPE_ALIASES[tok]:
						tok_match = true
				if not tok_match and RARITY_ALIASES.has(tok):
					if c_rarity == RARITY_ALIASES[tok]:
						tok_match = true
				if not tok_match and (tok == "fase1" or tok == "1") and int(c_stage) == 1 and c_type == "POKEMON":
					tok_match = true
				if not tok_match and (tok == "fase2" or tok == "2") and int(c_stage) == 2 and c_type == "POKEMON":
					tok_match = true
				if not tok_match and tok == "bebe" or tok == "bebé":
					if is_baby: tok_match = true
				if not tok_match:
					all_match = false
					break
			if not all_match: continue

		if sel_cat != "Cat: Todas":
			if sel_cat == "Pokemon"    and c_type != "POKEMON":      							 continue
			if sel_cat == "Básico"     and (c_type != "POKEMON" or int(c_stage) != 0 or is_baby): continue
			if sel_cat == "Bebé"       and (c_type != "POKEMON" or not is_baby):                  continue
			if sel_cat == "Fase 1"     and (c_type != "POKEMON" or int(c_stage) != 1):            continue
			if sel_cat == "Fase 2"     and (c_type != "POKEMON" or int(c_stage) != 2):            continue
			if sel_cat == "Entrenador" and c_type != "TRAINER":                                   continue
			if sel_cat == "Energía"    and c_type != "ENERGY":                                    continue

		if not is_gym_mode and sel_elem != "Elem: Todos":
			var target = {"Fuego":"FIRE","Agua":"WATER","Planta":"GRASS","Rayo":"LIGHTNING",
				"Psíquico":"PSYCHIC","Lucha":"FIGHTING","Incoloro":"COLORLESS",
				"Siniestro":"DARKNESS","Metálico":"METAL"}.get(sel_elem,"")
			if c_elem != target: continue
		
		
		if sel_rarity != "Rareza: Todas":
			if sel_rarity == "Común"       and c_rarity != "COMMON":     continue
			if sel_rarity == "Infrecuente" and c_rarity != "UNCOMMON":   continue
			if sel_rarity == "Rara"        and c_rarity != "RARE":       continue
			if sel_rarity == "Holo"        and c_rarity != "RARE_HOLO":  continue
			if sel_rarity == "Ultra Rara"  and c_rarity != "ULTRA_RARE": continue

		var qty       : int
		var available : int
		var in_deck   = menu.current_deck.count(id)

		if is_gym_mode:
			qty       = 99 if c_type == "ENERGY" else 4
			available = max(0, qty - in_deck)
		else:
			qty       = PlayerData.get_card_count(id) if PlayerData.is_logged_in else -1
			available = (qty - in_deck)               if PlayerData.is_logged_in else -1

		var show_card = (available > 0) if is_gym_mode else (qty > 0 or not PlayerData.is_logged_in)
		if not show_card: continue

		result_ids.append({"id": id, "name": c_name, "power": c_power,
			"rarity": c_rarity, "qty": qty, "available": available})

	const RARITY_ORDER = {"COMMON": 0, "UNCOMMON": 1, "RARE": 2, "RARE_HOLO": 3, "ULTRA_RARE": 4}
	match sel_sort:
		"Nombre ↑":
			result_ids.sort_custom(func(a, b): return a.name < b.name)
		"Nombre ↓":
			result_ids.sort_custom(func(a, b): return a.name > b.name)
		"Poder ↑":
			result_ids.sort_custom(func(a, b): return a.power < b.power)
		"Poder ↓":
			result_ids.sort_custom(func(a, b): return a.power > b.power)
		"Rareza":
			result_ids.sort_custom(func(a, b):
				var ra = RARITY_ORDER.get(a.rarity, 0)
				var rb = RARITY_ORDER.get(b.rarity, 0)
				return ra > rb
			)
		_:
			result_ids.sort_custom(func(a, b): return a.name < b.name)

	if result_lbl:
		result_lbl.text = str(result_ids.size()) + " cartas"

	var new_key = _make_cache_key(menu, search_text, sel_cat, sel_elem,
		sel_rarity, sel_sort, in_deck_only)

	if new_key == _grid_cache_key and _grid_cache.size() > 0:
		for entry in result_ids:
			var cached_node = _grid_cache.get(entry.id)
			if is_instance_valid(cached_node):
				MiniCard.update_availability(cached_node, entry.qty, entry.available)
		return

	_grid_cache_key = new_key
	for c in grid.get_children(): c.queue_free()
	_grid_cache.clear()

	for entry in result_ids:
		_load_card_texture_cached(entry.id)

	for entry in result_ids:
		var tex  = _load_card_texture_cached(entry.id)
		var node = MiniCard.make(entry.id, container, menu, entry.qty, entry.available, tex)
		grid.add_child(node)
		_grid_cache[entry.id] = node


# ============================================================
# _refresh_deck_list (sin cambios)
# ============================================================
static func _refresh_deck_list(container: Control, deck_panel: Control, header: Control, menu) -> void:
	var vbox = UITheme.find_node(deck_panel, "DeckVBox")
	if not vbox: return
	for c in vbox.get_children(): c.queue_free()

	_grid_cache_key = ""

	var is_gym_mode  = menu.get_meta("deck_mode", "normal") == "gym"
	var slot_id      = menu.get_meta("editing_slot", 0)
	var featured_ids : Array = menu.get_meta("featured_cards_editing", [])

	var counts: Dictionary = {}
	for id in menu.current_deck:
		counts[id] = counts.get(id, 0) + 1

	var sorted_ids = counts.keys()
	sorted_ids.sort_custom(func(a, b):
		var da = CardDatabase.get_card(a)
		var db = CardDatabase.get_card(b)
		var ta = da.get("type", "").to_upper()
		var tb = db.get("type", "").to_upper()
		var wa = 1 if ta == "POKEMON" else (2 if ta == "TRAINER" else (3 if ta == "ENERGY" else 4))
		var wb = 1 if tb == "POKEMON" else (2 if tb == "TRAINER" else (3 if tb == "ENERGY" else 4))
		if wa != wb: return wa < wb
		return da.get("name", a) < db.get("name", b)
	)

	for id in sorted_ids:
		var data        = CardDatabase.get_card(id)
		var type_str    = data.get("pokemon_type", data.get("type",""))
		var is_featured = featured_ids.has(id)

		var panel = PanelContainer.new()
		var st_panel = StyleBoxFlat.new()
		st_panel.corner_radius_top_left    = 6; st_panel.corner_radius_top_right    = 6
		st_panel.corner_radius_bottom_left = 6; st_panel.corner_radius_bottom_right = 6

		if is_featured:
			st_panel.bg_color = Color(0.16, 0.14, 0.08, 0.9)
			st_panel.border_width_left   = 2; st_panel.border_width_right  = 2
			st_panel.border_width_top    = 2; st_panel.border_width_bottom = 2
			st_panel.border_color        = Color(1.0, 0.78, 0.1, 0.9)
		else:
			st_panel.bg_color = Color(0.12, 0.14, 0.20, 0.8)
			st_panel.border_width_left = 4
			st_panel.border_color      = UITheme.type_color(type_str)

		panel.add_theme_stylebox_override("panel", st_panel)
		vbox.add_child(panel)

		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		row.custom_minimum_size = Vector2(0, 30)
		panel.add_child(row)
		row.add_child(_spacer(2))

		if is_featured:
			var star_icon = Label.new()
			star_icon.text = "⭐"
			star_icon.add_theme_font_size_override("font_size", 11)
			star_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			row.add_child(star_icon)
		else:
			var icon_tex = UITheme.type_icon(type_str)
			if icon_tex:
				var icon_rect = TextureRect.new()
				icon_rect.texture              = icon_tex
				icon_rect.expand_mode          = TextureRect.EXPAND_IGNORE_SIZE
				icon_rect.stretch_mode         = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				icon_rect.custom_minimum_size  = Vector2(18, 18)
				icon_rect.size_flags_vertical  = Control.SIZE_SHRINK_CENTER
				row.add_child(icon_rect)

		var n = Label.new()
		n.text = data.get("name", id).left(18)
		n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		n.vertical_alignment    = VERTICAL_ALIGNMENT_CENTER
		n.add_theme_font_size_override("font_size", 12)
		n.add_theme_color_override("font_color", menu.COLOR_TEXT)
		row.add_child(n)

		var cnt = Label.new()
		cnt.text = "×" + str(counts[id])
		cnt.custom_minimum_size  = Vector2(30, 0)
		cnt.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		cnt.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		cnt.add_theme_font_size_override("font_size", 12)
		cnt.add_theme_color_override("font_color", menu.COLOR_GOLD)
		row.add_child(cnt)

		if not is_gym_mode:
			var star_btn = Button.new()
			star_btn.text            = "✖" if is_featured else "⭐"
			star_btn.tooltip_text    = "Quitar destacada" if is_featured else "Destacar"
			star_btn.custom_minimum_size = Vector2(26, 26)
			star_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			star_btn.add_theme_font_size_override("font_size", 12)
			var st_star = StyleBoxFlat.new()
			st_star.bg_color = Color(0.35, 0.25, 0.05, 0.7) if is_featured else Color(0.18, 0.16, 0.04, 0.5)
			st_star.corner_radius_top_left    = 5; st_star.corner_radius_bottom_right = 5
			var st_star_hov = st_star.duplicate(); st_star_hov.bg_color = Color(0.55, 0.42, 0.05, 0.95)
			star_btn.add_theme_stylebox_override("normal", st_star)
			star_btn.add_theme_stylebox_override("hover",  st_star_hov)
			star_btn.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
			star_btn.pressed.connect(func():
				_try_add_featured(container, menu, id, slot_id)
				_refresh_deck_list(container, deck_panel, header, menu)
			)
			row.add_child(star_btn)

		var rm = Button.new()
		rm.text = "−"
		rm.custom_minimum_size = Vector2(26, 26)
		rm.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		rm.add_theme_font_size_override("font_size", 14)
		rm.add_theme_color_override("font_color", Color.WHITE)
		var rms = StyleBoxFlat.new()
		rms.bg_color = Color(0.3, 0.1, 0.1, 0.5)
		rms.corner_radius_top_left    = 6; rms.corner_radius_bottom_right = 6
		var rms_hov = rms.duplicate(); rms_hov.bg_color = Color(0.6, 0.2, 0.2, 0.9)
		rm.add_theme_stylebox_override("normal", rms)
		rm.add_theme_stylebox_override("hover",  rms_hov)
		rm.pressed.connect(func():
			var idx_rm = menu.current_deck.rfind(id)
			if idx_rm >= 0: menu.current_deck.remove_at(idx_rm)
			if not menu.current_deck.has(id):
				var f = menu.get_meta("featured_cards_editing", [])
				if f.has(id):
					f.erase(id)
					menu.set_meta("featured_cards_editing", f)
					var ft2  = UITheme.find_node(container, "FeaturedTitle") as Label
					var fr2  = UITheme.find_node(container, "FeaturedRow")
					var sid2 = menu.get_meta("editing_slot", 0)
					if fr2: _refresh_featured_row(container, fr2, ft2, menu, sid2)
			_grid_cache_key = ""
			_refresh_deck_list(container, deck_panel, header, menu)
			_refresh_collection_grid(container, menu)
		)
		row.add_child(rm)

		panel.mouse_filter = Control.MOUSE_FILTER_PASS
		panel.mouse_entered.connect(func():
			var s = st_panel.duplicate()
			s.bg_color = Color(0.18, 0.22, 0.32, 0.9)
			panel.add_theme_stylebox_override("panel", s)
			MiniCard.show_preview(container, id)
		)
		panel.mouse_exited.connect(func():
			panel.add_theme_stylebox_override("panel", st_panel)
		)

	_update_count_label(container, header, menu)


static func _has_basic_pokemon(deck: Array) -> bool:
	var baby_names = ["pichu","cleffa","igglybuff","smoochum","tyrogue","elekid","magby"]
	for id in deck:
		var card = CardDatabase.get_card(id)
		if card.is_empty(): continue
		var c_type  = card.get("type", "").to_upper()
		var c_stage = int(card.get("stage", 0))
		var c_name  = card.get("name", "").to_lower()
		var is_baby = card.get("is_baby", false) or c_name in baby_names
		if c_type == "POKEMON" and (c_stage == 0 or is_baby):
			return true
	return false


static func _calculate_deck_tier(deck: Array) -> String:
	if deck.size() == 0: return ""
	var powers : Array = []
	for id in deck:
		var card = CardDatabase.get_card(id)
		if card.is_empty(): continue
		var c_type = card.get("type", "").to_upper()
		if c_type == "ENERGY": continue
		var p = int(card.get("power", 0))
		if p > 0: powers.append(p)
	if powers.size() == 0: return "C"
	powers.sort()
	powers.reverse()
	var top = powers.slice(0, min(20, powers.size()))
	var avg = 0.0
	for p in top: avg += p
	avg /= top.size()
	if avg >= 71: return "SS"
	if avg >= 51: return "S"
	if avg >= 36: return "A"
	if avg >= 21: return "B"
	return "C"


static func _update_count_label(container: Control, header: Control, menu) -> void:
	var lbl = UITheme.find_node(header, "CountLbl") as Label
	var current_size = menu.current_deck.size()

	if lbl:
		lbl.text = str(current_size) + " / 60 Cartas"
		lbl.add_theme_color_override("font_color", menu.COLOR_GREEN if current_size == 60 else menu.COLOR_TEXT_DIM)

	const TIER_ORDER_ARR = ["C", "B", "A", "S", "SS"]
	var tier_lbl = UITheme.find_node(header, "TierLbl") as Label
	var deck_tier     : String = ""
	var tier_too_high : bool   = false

	if tier_lbl:
		if current_size > 0:
			deck_tier = _calculate_deck_tier(menu.current_deck)
			var tier_color = TIER_COLORS.get(deck_tier, Color(0.6, 0.6, 0.6))

			var is_gym_mode = menu.get_meta("deck_mode", "normal") == "gym"
			var slot_tier   = menu.get_meta("gym_tier_editing", "") as String
			if is_gym_mode and slot_tier != "":
				var deck_idx = TIER_ORDER_ARR.find(deck_tier)
				var slot_idx = TIER_ORDER_ARR.find(slot_tier)
				if deck_idx > slot_idx:
					tier_too_high = true
					tier_lbl.text = "⚠️ TIER " + deck_tier + " — excede slot " + slot_tier
					tier_lbl.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
				else:
					tier_lbl.text = "⬡ TIER  " + deck_tier
					tier_lbl.add_theme_color_override("font_color", tier_color)
			else:
				tier_lbl.text = "⬡ TIER  " + deck_tier
				tier_lbl.add_theme_color_override("font_color", tier_color)
		else:
			tier_lbl.text = ""

	var save_btn = UITheme.find_node(container, "SaveDeckBtn") as Button
	if save_btn:
		if tier_too_high:
			save_btn.text     = "❌ Mazo demasiado poderoso para este slot"
			save_btn.disabled = true
		elif current_size == 60:
			if _has_basic_pokemon(menu.current_deck):
				var dest = "Gimnasio" if menu.get_meta("deck_mode", "normal") == "gym" else "Servidor"
				save_btn.text     = "💾 Guardar Mazo en " + dest
				save_btn.disabled = false
			else:
				save_btn.text     = "❌ Falta al menos 1 Pokémon Básico"
				save_btn.disabled = true
		else:
			save_btn.text     = "Faltan cartas (" + str(current_size) + "/60)"
			save_btn.disabled = true


static func _spacer(w: int) -> Control:
	var s = Control.new(); s.custom_minimum_size = Vector2(w, 0); return s


# ============================================================
# GUARDADO (sin cambios)
# ============================================================
static func _save_gym_deck_to_server(container: Control, menu, gym_role: String) -> void:
	var http    = HTTPRequest.new()
	container.add_child(http)

	var gym_id  = menu.get_meta("gym_editing_id", "")
	var tier    = menu.get_meta("gym_tier_editing", "B")
	var headers = ["Authorization: Bearer " + NetworkManager.token, "Content-Type: application/json"]

	var url     : String
	var payload : String

	if gym_role == "leader":
		url     = NetworkManager.BASE_URL + "/api/gym/" + gym_id + "/leader-deck"
		payload = JSON.stringify({ "tier": tier, "deck_cards": menu.current_deck })
	else:
		url     = NetworkManager.BASE_URL + "/api/gym/" + gym_id + "/member-deck"
		payload = JSON.stringify({ "tier": tier, "deck_cards": menu.current_deck })

	http.request(url, headers, HTTPClient.METHOD_PUT, payload)

	http.request_completed.connect(func(result, code, _h, body):
		http.queue_free()
		if code == 200:
			SoundManager.play("save")

			var gym_decks : Dictionary = menu.get_meta("gym_decks_data", {})
			gym_decks[tier] = menu.current_deck.duplicate()
			menu.set_meta("gym_decks_data", gym_decks)

			if gym_role == "leader":
				LiderGymScreen.invalidate_cache(gym_id)
				menu.set_meta("deck_mode", "normal")
				menu.navigate_to("LiderGymScreen", {"gym_id": gym_id})
			else:
				build_gym_tier_selection(container, menu)
		else:
			var err = JSON.parse_string(body.get_string_from_utf8())
			var msg = err.get("error", "Error al guardar") if err else "Error desconocido"
			NetworkManager.emit_signal("error_received", msg)
			var save_btn = UITheme.find_node(container, "SaveDeckBtn") as Button
			if save_btn:
				save_btn.text     = "💾 Reintentar Guardado"
				save_btn.disabled = false
			var err_lbl = UITheme.find_node(container, "SaveErrorLbl") as Label
			if err_lbl:
				err_lbl.text = "❌ " + msg
				err_lbl.visible = true
	)
