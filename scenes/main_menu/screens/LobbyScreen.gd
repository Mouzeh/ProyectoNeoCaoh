extends Node

# ============================================================
# scenes/main_menu/screens/LobbyScreen.gd
# ============================================================

const RoomCard         = preload("res://scenes/main_menu/components/RoomCard.gd")
const CreateRoomDialog = preload("res://scenes/main_menu/components/CreateRoomDialog.gd")

const TIER_COLORS = {
	"C":  Color("#8ecae6"),
	"B":  Color("#52b788"),
	"A":  Color("#f4a261"),
	"S":  Color("#e63946"),
	"SS": Color("#c77dff"),
}
const MODE_COLORS = {
	"casual":  Color("#4a90d9"),
	"ranking": Color("#52b788"),
	"wager":   Color("#e8a838"),
}
const MODE_ICONS = {
	"casual":  "🎮",
	"ranking": "🏆",
	"wager":   "💰",
}

static var _active_mode_filter: String = ""
static var _active_tier_filter: String = ""

# ─────────────────────────────────────────────────────────────
static func build(container: Control, menu) -> void:
	var C = menu

	# Fondo
	var bg = TextureRect.new()
	var bg_tex = load("res://assets/imagen/fondomenu.png")
	if bg_tex: bg.texture = bg_tex
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.modulate = Color(0.3, 0.3, 0.3, 1)
	container.add_child(bg)

	# ── Header ──
	var header = Panel.new()
	header.anchor_left = 0; header.anchor_right  = 1
	header.anchor_top  = 0; header.anchor_bottom = 0
	header.offset_top  = 0; header.offset_bottom = 175
	var hs = StyleBoxFlat.new()
	hs.bg_color     = Color(C.COLOR_PANEL.r, C.COLOR_PANEL.g, C.COLOR_PANEL.b, 0.9)
	hs.border_color = Color(C.COLOR_GOLD_DIM.r, C.COLOR_GOLD_DIM.g, C.COLOR_GOLD_DIM.b, 0.3)
	hs.border_width_bottom = 1
	hs.shadow_color = Color(0, 0, 0, 0.3); hs.shadow_size = 20
	header.add_theme_stylebox_override("panel", hs)
	container.add_child(header)

	var header_vbox = VBoxContainer.new()
	header_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	header_vbox.add_theme_constant_override("separation", 0)
	header.add_child(header_vbox)

	# Fila 1: título centrado
	var title_row = HBoxContainer.new()
	title_row.alignment = BoxContainer.ALIGNMENT_CENTER
	title_row.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	title_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_theme_constant_override("separation", 0)
	header_vbox.add_child(title_row)

	var title_lbl = Label.new()
	title_lbl.text = "MESAS ACTIVAS"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_lbl.add_theme_font_size_override("font_size", 26)
	title_lbl.add_theme_color_override("font_color", C.COLOR_GOLD)
	title_row.add_child(title_lbl)

	var create_btn = _mk_create_btn(C, 200, 46, 14)
	create_btn.pressed.connect(func(): _open_create_dialog(container, menu))
	var btn_margin = MarginContainer.new()
	btn_margin.add_theme_constant_override("margin_right", 26)
	btn_margin.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	btn_margin.add_child(create_btn)
	title_row.add_child(btn_margin)

	# Fila 2: filtros
	var filter_row = HBoxContainer.new()
	filter_row.alignment = BoxContainer.ALIGNMENT_CENTER
	filter_row.add_theme_constant_override("separation", 8)
	var fm = MarginContainer.new()
	fm.add_theme_constant_override("margin_left",  26)
	fm.add_theme_constant_override("margin_right", 26)
	fm.add_theme_constant_override("margin_bottom", 10)
	fm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fm.add_child(filter_row)
	header_vbox.add_child(fm)

	var mode_all = _mk_filter_pill(container, menu, "Todos", "", MODE_COLORS, "mode")
	filter_row.add_child(mode_all)
	for mode in ["casual", "ranking", "wager"]:
		filter_row.add_child(_mk_filter_pill(container, menu,
			MODE_ICONS[mode] + " " + mode.capitalize(), mode, MODE_COLORS, "mode"))

	var sep = Label.new(); sep.text = "│"
	sep.add_theme_color_override("font_color", Color("#444"))
	sep.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	filter_row.add_child(sep)

	var tier_all = _mk_filter_pill(container, menu, "Todos", "", {}, "tier")
	filter_row.add_child(tier_all)
	for tier in ["C", "B", "A", "S", "SS"]:
		filter_row.add_child(_mk_filter_pill(container, menu, tier, tier, TIER_COLORS, "tier"))

	# ── Scroll + Grid ──
	var scroll = ScrollContainer.new()
	scroll.name          = "RoomsScroll"
	scroll.anchor_left   = 0; scroll.anchor_right  = 1
	scroll.anchor_top    = 0; scroll.anchor_bottom = 1
	scroll.offset_top    = 185
	scroll.offset_left   = 40
	scroll.offset_right  = -40
	scroll.offset_bottom = -20
	UITheme.apply_scrollbar_theme(scroll)
	container.add_child(scroll)

	var grid = GridContainer.new()
	grid.name    = "RoomsGrid"
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 20)
	grid.add_theme_constant_override("v_separation", 20)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(grid)

	# ── Empty state ──
	var empty = Control.new()
	empty.name          = "EmptyState"
	empty.anchor_left   = 0.0; empty.anchor_right  = 1.0
	empty.anchor_top    = 0.0; empty.anchor_bottom = 1.0
	empty.offset_left   = 0;   empty.offset_right  = 0
	empty.offset_top    = 0;   empty.offset_bottom = 0
	empty.mouse_filter  = Control.MOUSE_FILTER_IGNORE
	empty.visible       = false
	container.add_child(empty)

	var content_area = Control.new()
	content_area.anchor_left   = 0.0; content_area.anchor_right  = 1.0
	content_area.anchor_top    = 0.0; content_area.anchor_bottom = 1.0
	content_area.offset_top    = 175
	content_area.offset_left   = 0;   content_area.offset_right  = 0
	content_area.offset_bottom = 0
	content_area.mouse_filter  = Control.MOUSE_FILTER_IGNORE
	empty.add_child(content_area)

	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content_area.add_child(center)

	var vbox = VBoxContainer.new()
	vbox.name      = "EmptyVBox"
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 22)
	center.add_child(vbox)

	update_room_list(container, menu.current_rooms, menu)

	if NetworkManager.ws_connected:
		NetworkManager.get_room_list()


# ============================================================
# UPDATE ROOM LIST
# ============================================================
static func update_room_list(container: Control, rooms: Array, menu) -> void:
	var grid   = UITheme.find_node(container, "RoomsGrid")
	var empty  = container.get_node_or_null("EmptyState")
	var scroll = container.get_node_or_null("RoomsScroll")
	if not grid: return

	for c in grid.get_children(): c.queue_free()

	var filtered = rooms.filter(func(r):
		if _active_mode_filter != "" and r.get("mode", "") != _active_mode_filter:
			return false
		if _active_tier_filter != "" and r.get("deck_tier", "") != _active_tier_filter:
			return false
		return true
	)

	if filtered.size() == 0:
		if scroll: scroll.visible = false
		if empty:
			var vbox = _find_vbox(empty)
			if vbox:
				for c in vbox.get_children(): c.queue_free()
				_fill_empty_vbox(vbox, container, rooms.size() > 0, menu)
			empty.visible = true
		return

	if scroll: scroll.visible = true
	if empty:  empty.visible  = false

	for room in filtered:
		grid.add_child(RoomCard.make(room, menu))


static func _find_vbox(empty: Control) -> VBoxContainer:
	if empty.get_child_count() == 0: return null
	var ca = empty.get_child(0)
	if ca.get_child_count() == 0: return null
	var cc = ca.get_child(0)
	if cc.get_child_count() == 0: return null
	return cc.get_child(0) as VBoxContainer


# ============================================================
# RELLENAR EMPTY STATE
# ============================================================
static func _fill_empty_vbox(
		vbox: VBoxContainer,
		container: Control,
		has_rooms_but_filtered: bool,
		menu) -> void:
	var C = menu

	# Icono
	var icon_tex = load("res://assets/iconos/politd.png") as Texture2D
	if icon_tex:
		var icon_rect = TextureRect.new()
		icon_rect.texture               = icon_tex
		icon_rect.custom_minimum_size   = Vector2(100, 100)
		icon_rect.stretch_mode          = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.expand_mode           = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		icon_rect.mouse_filter          = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(icon_rect)
	else:
		var icon_lbl = Label.new()
		icon_lbl.text = "🎴"
		icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon_lbl.add_theme_font_size_override("font_size", 80)
		vbox.add_child(icon_lbl)

	# Título
	var title = Label.new()
	title.text = "No hay mesas activas" if not has_rooms_but_filtered \
		else "Sin resultados para estos filtros"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", C.COLOR_TEXT)
	vbox.add_child(title)

	# Subtítulo — más grande para que se lea bien
	var sub = Label.new()
	sub.text = "¡Sé el primero en crear una mesa y desafía a otros entrenadores!" \
		if not has_rooms_but_filtered else \
		"Prueba cambiando o quitando los filtros activos."
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 20)
	sub.add_theme_color_override("font_color", C.COLOR_TEXT_DIM)
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD
	sub.custom_minimum_size = Vector2(560, 0)
	vbox.add_child(sub)

	# Botón crear mesa
	if not has_rooms_but_filtered:
		var spacer = Control.new()
		spacer.custom_minimum_size = Vector2(0, 12)
		vbox.add_child(spacer)

		var btn = _mk_create_btn(C, 280, 62, 18)
		btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		btn.pressed.connect(func(): _open_create_dialog(container, menu))
		vbox.add_child(btn)


# ============================================================
# HELPERS
# ============================================================
static func _open_create_dialog(container: Control, menu) -> void:
	if NetworkManager.ws_connected:
		SoundManager.play("room_created")
		var dlg = CreateRoomDialog.new()
		dlg.open(container, menu)
	else:
		push_warning("[LobbyScreen] No conectado")


static func _mk_create_btn(C, min_w: int, min_h: int, font_size: int) -> Button:
	var btn = Button.new()
	btn.text = "➕  CREAR MESA"
	btn.custom_minimum_size = Vector2(min_w, min_h)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.add_theme_font_size_override("font_size", font_size)
	btn.add_theme_color_override("font_color", C.COLOR_PANEL)

	var st = StyleBoxFlat.new()
	st.bg_color = C.COLOR_GOLD
	st.corner_radius_top_left     = int(min_h * 0.35)
	st.corner_radius_top_right    = int(min_h * 0.35)
	st.corner_radius_bottom_left  = int(min_h * 0.35)
	st.corner_radius_bottom_right = int(min_h * 0.35)
	st.shadow_color = Color(C.COLOR_GOLD.r, C.COLOR_GOLD.g, C.COLOR_GOLD.b, 0.35)
	st.shadow_size  = 14

	var st_hov = st.duplicate()
	st_hov.bg_color = Color(
		min(C.COLOR_GOLD.r * 1.15, 1.0),
		min(C.COLOR_GOLD.g * 1.15, 1.0),
		min(C.COLOR_GOLD.b * 1.15, 1.0)
	)
	st_hov.shadow_size = 22

	btn.add_theme_stylebox_override("normal",  st)
	btn.add_theme_stylebox_override("hover",   st_hov)
	btn.add_theme_stylebox_override("pressed", st)
	return btn


static func _mk_filter_pill(container: Control, menu, label: String, value: String,
							color_map: Dictionary, filter_type: String) -> Button:
	var btn = Button.new()
	btn.text = label
	btn.flat = true
	btn.add_theme_font_size_override("font_size", 11)
	btn.custom_minimum_size = Vector2(0, 26)

	var base_color = color_map.get(value, Color("#555")) if value != "" else Color("#555")
	var st_off = StyleBoxFlat.new()
	st_off.bg_color     = Color(base_color.r, base_color.g, base_color.b, 0.18)
	st_off.border_color = Color(base_color.r, base_color.g, base_color.b, 0.4)
	st_off.border_width_left = 1; st_off.border_width_right  = 1
	st_off.border_width_top  = 1; st_off.border_width_bottom = 1
	st_off.corner_radius_top_left    = 12; st_off.corner_radius_top_right    = 12
	st_off.corner_radius_bottom_left = 12; st_off.corner_radius_bottom_right = 12

	var st_on = StyleBoxFlat.new()
	st_on.bg_color = base_color
	st_on.corner_radius_top_left    = 12; st_on.corner_radius_top_right    = 12
	st_on.corner_radius_bottom_left = 12; st_on.corner_radius_bottom_right = 12

	btn.add_theme_stylebox_override("normal", st_off)
	btn.add_theme_stylebox_override("hover",  st_off)
	btn.add_theme_color_override("font_color", Color("#ccc"))

	btn.pressed.connect(func():
		if filter_type == "mode":
			_active_mode_filter = value
		else:
			_active_tier_filter = value
		update_room_list(container, menu.current_rooms, menu)
		btn.add_theme_stylebox_override("normal", st_on)
		btn.add_theme_stylebox_override("hover",  st_on)
	)

	return btn
