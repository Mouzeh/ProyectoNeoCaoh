extends Node

# ============================================================
# scenes/main_menu/screens/LobbyScreen.gd  (versión mejorada)
# ============================================================

const RoomCard        = preload("res://scenes/main_menu/components/RoomCard.gd")
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

# ── Filtros activos ──────────────────────────────────────────
static var _active_mode_filter: String = ""   # "" = todos
static var _active_tier_filter: String = ""   # "" = todos

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
	header.offset_top  = 50; header.offset_bottom = 140
	var hs = StyleBoxFlat.new()
	hs.bg_color    = Color(C.COLOR_PANEL.r, C.COLOR_PANEL.g, C.COLOR_PANEL.b, 0.9)
	hs.border_color = Color(C.COLOR_GOLD_DIM.r, C.COLOR_GOLD_DIM.g, C.COLOR_GOLD_DIM.b, 0.3)
	hs.border_width_bottom = 1
	hs.shadow_color = Color(0,0,0,0.3); hs.shadow_size = 20
	header.add_theme_stylebox_override("panel", hs)
	container.add_child(header)

	var header_vbox = VBoxContainer.new()
	header_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	header_vbox.add_theme_constant_override("separation", 0)
	header.add_child(header_vbox)

	# Fila 1: título + botones
	var title_row = HBoxContainer.new()
	title_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	title_row.add_theme_constant_override("separation", 0)
	header_vbox.add_child(title_row)

	var accent = ColorRect.new()
	accent.color = C.COLOR_GOLD
	accent.custom_minimum_size = Vector2(6, 0)
	title_row.add_child(accent)

	var title_m = MarginContainer.new()
	title_m.add_theme_constant_override("margin_left", 20)
	title_m.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(title_m)

	var title_v = VBoxContainer.new()
	title_v.alignment = BoxContainer.ALIGNMENT_CENTER
	title_v.add_theme_constant_override("separation", 2)
	title_m.add_child(title_v)

	var title_lbl = Label.new()
	title_lbl.text = "◈ POKÉMON TCG · MESAS DE JUEGO"
	title_lbl.add_theme_font_size_override("font_size", 16)
	title_lbl.add_theme_color_override("font_color", C.COLOR_GOLD)
	title_v.add_child(title_lbl)

	var active_deck = PlayerData.get_active_deck()
	var active_name = PlayerData.get_deck_name(PlayerData.active_deck_slot)
	var deck_size   = active_deck.size()
	var deck_lbl = Label.new()
	deck_lbl.text = active_name + "  ·  " + str(deck_size) + "/60"
	deck_lbl.add_theme_font_size_override("font_size", 11)
	deck_lbl.add_theme_color_override("font_color", C.COLOR_GREEN if deck_size == 60 else Color("df673b"))
	title_v.add_child(deck_lbl)

	# Botones derecha
	var btn_m = MarginContainer.new()
	btn_m.add_theme_constant_override("margin_right", 24)
	btn_m.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var btn_row = HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 12)
	btn_m.add_child(btn_row)
	title_row.add_child(btn_m)

	# Jugar local
	var local_btn = _mk_btn("JUGAR LOCAL", Color(0.2, 0.2, 0.25), Color(0.6, 0.6, 0.6), 140)
	local_btn.pressed.connect(func(): container.get_tree().change_scene_to_file("res://scenes/battle/BattleBoard.tscn"))
	btn_row.add_child(local_btn)

	# Crear mesa → abre el diálogo
	var create_btn = _mk_btn("➕ CREAR MESA", C.COLOR_GOLD, C.COLOR_PANEL, 180)
	create_btn.pressed.connect(func():
		if NetworkManager.ws_connected:
			var dlg = CreateRoomDialog.new()
			dlg.open(container, menu)
		else:
			push_warning("[LobbyScreen] No conectado")
	)
	btn_row.add_child(create_btn)

	# Fila 2: filtros de modo y tier
	var filter_row = HBoxContainer.new()
	filter_row.add_theme_constant_override("separation", 8)
	var fm = MarginContainer.new()
	fm.add_theme_constant_override("margin_left",  26)
	fm.add_theme_constant_override("margin_right", 24)
	fm.add_theme_constant_override("margin_bottom", 8)
	fm.add_child(filter_row)
	header_vbox.add_child(fm)

	# Filtro: modos
	var mode_all = _mk_filter_pill(container, menu, "Todos", "", MODE_COLORS, "mode")
	filter_row.add_child(mode_all)
	for mode in ["casual", "ranking", "wager"]:
		var icon = MODE_ICONS[mode]
		var p = _mk_filter_pill(container, menu, icon + " " + mode.capitalize(), mode, MODE_COLORS, "mode")
		filter_row.add_child(p)

	# Separador
	var sep = Label.new(); sep.text = "│"
	sep.add_theme_color_override("font_color", Color("#444"))
	sep.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	filter_row.add_child(sep)

	# Filtro: tiers
	var tier_all = _mk_filter_pill(container, menu, "Todos", "", {}, "tier")
	filter_row.add_child(tier_all)
	for tier in ["C", "B", "A", "S", "SS"]:
		var p = _mk_filter_pill(container, menu, tier, tier, TIER_COLORS, "tier")
		filter_row.add_child(p)

	# ── Contenido principal ──
	var center_m = MarginContainer.new()
	center_m.anchor_left = 0; center_m.anchor_right  = 1
	center_m.anchor_top  = 0; center_m.anchor_bottom = 1
	center_m.offset_top  = 140
	center_m.add_theme_constant_override("margin_left",   40)
	center_m.add_theme_constant_override("margin_right",  40)
	center_m.add_theme_constant_override("margin_top",    20)
	center_m.add_theme_constant_override("margin_bottom", 20)
	container.add_child(center_m)

	var lobby_vbox = VBoxContainer.new()
	lobby_vbox.add_theme_constant_override("separation", 16)
	center_m.add_child(lobby_vbox)

	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	UITheme.apply_scrollbar_theme(scroll)
	lobby_vbox.add_child(scroll)

	var grid = GridContainer.new()
	grid.name    = "RoomsGrid"
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 20)
	grid.add_theme_constant_override("v_separation", 20)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(grid)

	update_room_list(container, menu.current_rooms, menu)

	if NetworkManager.ws_connected:
		NetworkManager.get_room_list()


static func update_room_list(container: Control, rooms: Array, menu) -> void:
	var grid = UITheme.find_node(container, "RoomsGrid")
	if not grid: return
	for c in grid.get_children(): c.queue_free()

	# Aplicar filtros
	var filtered = rooms.filter(func(r):
		if _active_mode_filter != "" and r.get("mode", "") != _active_mode_filter:
			return false
		if _active_tier_filter != "" and r.get("deck_tier", "") != _active_tier_filter:
			return false
		return true
	)

	if filtered.size() == 0:
		var empty_lbl = Label.new()
		empty_lbl.text = "No hay mesas activas con estos filtros." if rooms.size() > 0 \
			else "No hay mesas activas. ¡Sé el primero en crear una!"
		empty_lbl.add_theme_color_override("font_color", menu.COLOR_TEXT_DIM)
		grid.add_child(empty_lbl)
		return

	for room in filtered:
		grid.add_child(RoomCard.make(room, menu))


# ── Helpers de UI ────────────────────────────────────────────
static func _mk_btn(text: String, bg: Color, fg: Color, min_w: int) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(min_w, 40)
	btn.add_theme_font_size_override("font_size", 13)
	btn.add_theme_color_override("font_color", fg)
	var st = StyleBoxFlat.new()
	st.bg_color = bg
	st.corner_radius_top_left    = 6; st.corner_radius_top_right    = 6
	st.corner_radius_bottom_left = 6; st.corner_radius_bottom_right = 6
	btn.add_theme_stylebox_override("normal", st)
	btn.add_theme_stylebox_override("hover",  st)
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
	st_off.bg_color = Color(base_color.r, base_color.g, base_color.b, 0.18)
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
		# Refrescar lista con filtros actuales
		update_room_list(container, menu.current_rooms, menu)
		# Actualizar estilo de los botones de ese grupo
		# (una solución simple: reconstruir el header no es ideal,
		#  así que solo actualizamos la apariencia de este btn)
		btn.add_theme_stylebox_override("normal", st_on)
		btn.add_theme_stylebox_override("hover",  st_on)
	)

	return btn
