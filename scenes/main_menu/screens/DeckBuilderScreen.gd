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

# ─── ENTRY POINT ──────────────────────────────────────────
static func build(container: Control, menu, params: Dictionary = {}) -> void:
	var builder_root = Control.new()
	builder_root.name = "BuilderRoot"
	builder_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	container.add_child(builder_root)

	if menu.get_meta("deck_mode", "normal") == "gym":
		var gym_role = menu.get_meta("gym_role", "leader")
		if gym_role == "leader":
			# Líder entra directo al editor con el tier ya seteado
			build_deck_editor(builder_root, menu, 0)
		else:
			# Grunt / sub-líder: primero elige el tier
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
	# gym_decks_data: { "SS": [...], "S": [...], "A": [...], "B": [...] }
	var gym_decks : Dictionary = menu.get_meta("gym_decks_data", {})

	var bg_image = TextureRect.new()
	var bg_tex = load("res://assets/imagen/fondomenu.png")
	if bg_tex: bg_image.texture = bg_tex
	bg_image.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_image.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	bg_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg_image.modulate     = Color(0.15, 0.15, 0.15, 1)
	container.add_child(bg_image)

	# Header
	var header = Panel.new()
	header.anchor_left = 0; header.anchor_right  = 1
	header.anchor_top  = 0; header.anchor_bottom = 0
	header.offset_top  = 50; header.offset_bottom = 120
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

	# Grid 4 tiers
	var scroll = ScrollContainer.new()
	scroll.anchor_left   = 0;   scroll.anchor_right  = 1
	scroll.anchor_top    = 0;   scroll.anchor_bottom = 1
	scroll.offset_top    = 130; scroll.offset_bottom = -20
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
	box.custom_minimum_size = Vector2(230, 330)

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
	m.add_theme_constant_override("margin_top",    24)
	m.add_theme_constant_override("margin_bottom", 24)
	box.add_child(m)

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 10)
	m.add_child(vbox)

	# Badge tier
	var tier_badge = Label.new()
	tier_badge.text = "TIER  " + tier
	tier_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tier_badge.add_theme_font_size_override("font_size", 28)
	tier_badge.add_theme_color_override("font_color", tier_color)
	vbox.add_child(tier_badge)

	# Quiénes usan este deck
	var chal_lbl = Label.new()
	chal_lbl.text = TIER_CHALLENGER_LABEL.get(tier, "")
	chal_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chal_lbl.add_theme_font_size_override("font_size", 11)
	chal_lbl.add_theme_color_override("font_color", Color(0.55, 0.55, 0.55))
	vbox.add_child(chal_lbl)

	vbox.add_child(_vspacer(6))

	# Contador cartas
	var count_lbl = Label.new()
	count_lbl.text = str(deck_cards.size()) + " / 60 cartas"
	count_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	count_lbl.add_theme_font_size_override("font_size", 13)
	count_lbl.add_theme_color_override("font_color", menu.COLOR_GREEN if is_complete else menu.COLOR_RED)
	vbox.add_child(count_lbl)

	# Estado
	var status_lbl = Label.new()
	status_lbl.text = "✅ Listo" if is_complete else "⚠️ Incompleto"
	status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_lbl.add_theme_font_size_override("font_size", 12)
	status_lbl.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3) if is_complete else Color(0.9, 0.6, 0.1))
	vbox.add_child(status_lbl)

	vbox.add_child(_vspacer(10))

	# Botón editar
	var edit_btn = Button.new()
	edit_btn.text = "✏️ Editar Mazo" if is_complete else "➕ Crear Mazo"
	edit_btn.custom_minimum_size    = Vector2(180, 40)
	edit_btn.size_flags_horizontal  = Control.SIZE_SHRINK_CENTER
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
# VISTA 1: SELECTOR DE MAZOS (Solo para Modo Normal)
# ============================================================
static func build_deck_selection(container: Control, menu) -> void:
	for c in container.get_children(): c.queue_free()

	var bg_image = TextureRect.new()
	var bg_tex = load("res://assets/imagen/fondomenu.png")
	if bg_tex: bg_image.texture = bg_tex
	bg_image.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_image.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	bg_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg_image.modulate = Color(0.15, 0.15, 0.15, 1)
	container.add_child(bg_image)

	var header = Panel.new()
	header.anchor_left = 0; header.anchor_right  = 1
	header.anchor_top  = 0; header.anchor_bottom = 0
	header.offset_top  = 50; header.offset_bottom = 120
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

	var scroll = ScrollContainer.new()
	scroll.anchor_left = 0; scroll.anchor_right  = 1
	scroll.anchor_top  = 0; scroll.anchor_bottom = 1
	scroll.offset_top  = 160; scroll.offset_bottom = -40
	scroll.offset_left = 40;  scroll.offset_right  = -40
	container.add_child(scroll)

	var grid = GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 40)
	grid.add_theme_constant_override("v_separation", 40)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(grid)

	_create_deck_box(container, menu, grid, 1, false)
	_create_deck_box(container, menu, grid, 2, false)
	_create_deck_box(container, menu, grid, 3, false)
	_create_deck_box(container, menu, grid, 4, true)


static func _create_deck_box(container: Control, menu, parent: Control, slot_id: int, is_locked: bool) -> void:
	var box = PanelContainer.new()
	box.custom_minimum_size = Vector2(240, 360)

	var is_active = (PlayerData.active_deck_slot == slot_id)
	var st = StyleBoxFlat.new()
	st.bg_color = Color(0.1, 0.12, 0.18, 0.95)
	st.corner_radius_top_left    = 12; st.corner_radius_top_right    = 12
	st.corner_radius_bottom_left = 12; st.corner_radius_bottom_right = 12

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
		st.border_color = menu.COLOR_GOLD_DIM

	box.add_theme_stylebox_override("panel", st)
	parent.add_child(box)

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
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

	var img_panel = PanelContainer.new()
	img_panel.custom_minimum_size  = Vector2(160, 110)
	img_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var st_img = StyleBoxFlat.new()
	st_img.bg_color = Color(0.08, 0.1, 0.15)
	st_img.corner_radius_top_left    = 8; st_img.corner_radius_top_right    = 8
	st_img.corner_radius_bottom_left = 8; st_img.corner_radius_bottom_right = 8
	img_panel.add_theme_stylebox_override("panel", st_img)

	var img_rect = TextureRect.new()
	img_rect.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	img_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var tex_path = "res://assets/imagen/Deck1.png"
	if ResourceLoader.exists(tex_path): img_rect.texture = load(tex_path)
	img_panel.add_child(img_rect)
	vbox.add_child(img_panel)
	vbox.add_child(UITheme.vspace(10))

	var deck_data  = PlayerData.decks.get(str(slot_id), {})
	var deck_cards = deck_data.get("cards", [])
	var deck_name  = deck_data.get("name", "Mazo " + str(slot_id))
	var is_empty   = deck_cards.size() == 0

	var name_lbl = Label.new()
	name_lbl.text = "VACÍO" if is_empty else deck_name
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 16)
	name_lbl.add_theme_color_override("font_color", Color.GRAY if is_empty else Color.WHITE)
	name_lbl.custom_minimum_size       = Vector2(180, 0)
	name_lbl.autowrap_mode             = TextServer.AUTOWRAP_OFF
	name_lbl.text_overrun_behavior     = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_lbl.clip_text                 = true
	vbox.add_child(name_lbl)

	var count_lbl = Label.new()
	count_lbl.text = str(deck_cards.size()) + "/60 Cartas"
	count_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	count_lbl.add_theme_font_size_override("font_size", 12)
	count_lbl.add_theme_color_override("font_color", menu.COLOR_GREEN if deck_cards.size() == 60 else menu.COLOR_RED)
	vbox.add_child(count_lbl)
	vbox.add_child(UITheme.vspace(16))

	var edit_btn = Button.new()
	edit_btn.text = "➕ Crear Mazo" if is_empty else "✏️ Editar Mazo"
	edit_btn.custom_minimum_size   = Vector2(180, 36)
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
		build_deck_editor(container, menu, slot_id)
	)
	vbox.add_child(edit_btn)

	if not is_empty:
		vbox.add_child(UITheme.vspace(8))
		var active_btn = Button.new()
		active_btn.custom_minimum_size   = Vector2(180, 36)
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
				build_deck_selection(container, menu)
			)
		vbox.add_child(active_btn)


# ============================================================
# VISTA 2: EL EDITOR DE MAZOS
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
	header.offset_top  = 50; header.offset_bottom = 120
	var hs = StyleBoxFlat.new()
	hs.bg_color     = Color(C.COLOR_PANEL.r,    C.COLOR_PANEL.g,    C.COLOR_PANEL.b,    0.85)
	hs.border_color = Color(C.COLOR_GOLD_DIM.r, C.COLOR_GOLD_DIM.g, C.COLOR_GOLD_DIM.b, 0.3)
	hs.border_width_bottom = 1
	header.add_theme_stylebox_override("panel", hs)
	container.add_child(header)

	var hbox = HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	header.add_child(hbox)

	# Botón volver — destino depende del rol
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
		if is_gym_mode:
			if gym_role == "leader":
				menu.set_meta("deck_mode", "normal")
				menu.navigate_to("LiderGymScreen", {"gym_id": menu.get_meta("gym_editing_id", "")})
			else:
				# Volver al selector de tiers (sin recargar del servidor)
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

	var bm = MarginContainer.new()
	bm.add_theme_constant_override("margin_right", 24)
	bm.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox.add_child(bm)

	# ── Área principal ──
	var main_area = HBoxContainer.new()
	main_area.anchor_left = 0; main_area.anchor_right  = 1
	main_area.anchor_top  = 0; main_area.anchor_bottom = 1
	main_area.offset_top  = 140; main_area.offset_bottom = -20
	main_area.offset_left = 24;  main_area.offset_right  = -24
	main_area.add_theme_constant_override("separation", 16)
	container.add_child(main_area)

	var st_coll = StyleBoxFlat.new()
	st_coll.bg_color     = Color(C.COLOR_PANEL.r,    C.COLOR_PANEL.g,    C.COLOR_PANEL.b,    0.95)
	st_coll.border_color = Color(C.COLOR_GOLD_DIM.r, C.COLOR_GOLD_DIM.g, C.COLOR_GOLD_DIM.b, 0.3)
	st_coll.border_width_left = 1; st_coll.border_width_right  = 1
	st_coll.border_width_top  = 1; st_coll.border_width_bottom = 1
	st_coll.corner_radius_top_left    = 16; st_coll.corner_radius_top_right    = 16
	st_coll.corner_radius_bottom_left = 16; st_coll.corner_radius_bottom_right = 16

	# Panel colección
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

	var filter_hbox = HBoxContainer.new()
	filter_hbox.add_theme_constant_override("separation", 8)
	cv.add_child(filter_hbox)

	var search_in = LineEdit.new()
	search_in.name             = "SearchInput"
	search_in.placeholder_text = "🔎 Buscar..."
	search_in.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	search_in.add_theme_stylebox_override("normal", UITheme.input_style(Color(0.2, 0.2, 0.3)))
	search_in.add_theme_stylebox_override("focus",  UITheme.input_style(C.COLOR_GOLD))
	filter_hbox.add_child(search_in)

	var cat_opt = OptionButton.new()
	cat_opt.name = "CatFilter"
	for item in ["Categoría: Todas","Básico","Bebé","Fase 1","Fase 2","Entrenador","Energía"]:
		cat_opt.add_item(item)
	cat_opt.custom_minimum_size = Vector2(130, 0)
	filter_hbox.add_child(cat_opt)

	# Filtro elemento: solo en modo normal (en gym está fijo al tipo del gym)
	if not is_gym_mode:
		var elem_opt = OptionButton.new()
		elem_opt.name = "ElemFilter"
		for item in ["Elemento: Todos","Fuego","Agua","Planta","Rayo","Psíquico","Lucha","Incoloro","Siniestro","Metálico"]:
			elem_opt.add_item(item)
		elem_opt.custom_minimum_size = Vector2(130, 0)
		filter_hbox.add_child(elem_opt)

	var rarity_opt = OptionButton.new()
	rarity_opt.name = "RarityFilter"
	for item in ["Rareza: Todas","Común / Infrecuente","Rara / Holo","Ultra Rara"]:
		rarity_opt.add_item(item)
	rarity_opt.custom_minimum_size = Vector2(140, 0)
	filter_hbox.add_child(rarity_opt)

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

	# Panel preview
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
	prev_v.add_child(UITheme.vspace(10))

	var prev_name = Label.new()
	prev_name.name = "PreviewName"
	prev_name.text = "Pasa el mouse o Click Derecho en una carta"
	prev_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prev_name.autowrap_mode        = TextServer.AUTOWRAP_WORD
	prev_name.add_theme_font_size_override("font_size", 14)
	prev_name.add_theme_color_override("font_color", C.COLOR_GOLD)
	prev_v.add_child(prev_name)

	# Panel deck
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

	var deck_title_lbl = Label.new()
	deck_title_lbl.text = "LISTA DEL MAZO"
	deck_title_lbl.add_theme_font_size_override("font_size", 12)
	deck_title_lbl.add_theme_color_override("font_color", C.COLOR_GOLD_DIM)
	dv.add_child(deck_title_lbl)

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
		_refresh_deck_list(container, dp_panel, header, menu)
		_refresh_collection_grid(container, menu)
	)
	dv.add_child(clear_btn)

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
				var slot_to_save = menu.get_meta("editing_slot", current_slot)
				var deck_tier    = _calculate_deck_tier(menu.current_deck)
				save_btn.text     = "Guardando..."
				save_btn.disabled = true
				PlayerData.save_deck_to_server(slot_to_save, menu.deck_name, menu.current_deck, deck_tier)
				# Popup confirmación custom
				var overlay = ColorRect.new()
				overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
				overlay.color       = Color(0, 0, 0, 0.55)
				overlay.z_index     = 100
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

				var icon_lbl = Label.new()
				icon_lbl.text = "✦"
				icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				icon_lbl.add_theme_font_size_override("font_size", 32)
				icon_lbl.add_theme_color_override("font_color", Color(1.0, 0.78, 0.1))
				pv.add_child(icon_lbl)

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
				ok_btn.text                = "OK"
				ok_btn.custom_minimum_size = Vector2(140, 40)
				ok_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
				ok_btn.add_theme_font_size_override("font_size", 14)
				ok_btn.add_theme_color_override("font_color", Color(0.06, 0.06, 0.07))
				var st_ok = StyleBoxFlat.new()
				st_ok.bg_color              = Color(1.0, 0.78, 0.1)
				st_ok.corner_radius_top_left    = 8; st_ok.corner_radius_top_right    = 8
				st_ok.corner_radius_bottom_left = 8; st_ok.corner_radius_bottom_right = 8
				var st_ok_hov = st_ok.duplicate()
				st_ok_hov.bg_color = Color(1.0, 0.88, 0.3)
				ok_btn.add_theme_stylebox_override("normal",  st_ok)
				ok_btn.add_theme_stylebox_override("hover",   st_ok_hov)
				ok_btn.add_theme_stylebox_override("pressed", st_ok)
				ok_btn.pressed.connect(func(): overlay.queue_free())
				pv.add_child(ok_btn)

				# Animación entrada
				popup.modulate = Color(1, 1, 1, 0)
				popup.scale    = Vector2(0.85, 0.85)
				popup.pivot_offset = Vector2(190, 80)
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
# FUNCIONES AUXILIARES DE RENDERIZADO
# ============================================================
static func _refresh_collection_grid(container: Control, menu) -> void:
	var grid       = UITheme.find_node(container, "CollectionGrid")
	var search_box = UITheme.find_node(container, "SearchInput")  as LineEdit
	var cat_box    = UITheme.find_node(container, "CatFilter")    as OptionButton
	var elem_box   = UITheme.find_node(container, "ElemFilter")   as OptionButton  # null en modo gym
	var rarity_box = UITheme.find_node(container, "RarityFilter") as OptionButton
	if not grid: return
	for c in grid.get_children(): c.queue_free()

	var is_gym_mode = menu.get_meta("deck_mode", "normal") == "gym"
	var gym_type    = menu.get_meta("gym_type", "COLORLESS") if is_gym_mode else ""

	var search_text = search_box.text.to_lower() if search_box else ""
	var sel_cat     = cat_box.get_item_text(cat_box.selected)       if cat_box    else "Categoría: Todas"
	var sel_elem    = elem_box.get_item_text(elem_box.selected)     if elem_box   else "Elemento: Todos"
	var sel_rarity  = rarity_box.get_item_text(rarity_box.selected) if rarity_box else "Rareza: Todas"
	var baby_names  = ["pichu","cleffa","igglybuff","smoochum","tyrogue","elekid","magby"]

	for id in CardDatabase.get_all_ids():
		var card = CardDatabase.get_card(id)
		if card.is_empty(): continue

		var c_name   = card.get("name",   "").to_lower()
		var c_type   = card.get("type",   "").to_upper()
		var c_elem   = card.get("pokemon_type", card.get("type","")).to_upper()
		var c_rarity = card.get("rarity", "COMMON").to_upper()
		var c_stage  = card.get("stage",  0)
		var is_baby  = card.get("is_baby", false) or c_name in baby_names

		# Filtro de tipo gym
		if is_gym_mode:
			if c_type == "POKEMON" and c_elem != gym_type and c_elem != "COLORLESS": continue
			if c_type == "ENERGY"  and "SPECIAL" in c_rarity:                        continue

		if search_text != "" and not search_text in c_name: continue

		if sel_cat != "Categoría: Todas":
			if sel_cat == "Básico"     and (c_type != "POKEMON" or int(c_stage) != 0 or is_baby): continue
			if sel_cat == "Bebé"       and (c_type != "POKEMON" or not is_baby):                  continue
			if sel_cat == "Fase 1"     and (c_type != "POKEMON" or int(c_stage) != 1):            continue
			if sel_cat == "Fase 2"     and (c_type != "POKEMON" or int(c_stage) != 2):            continue
			if sel_cat == "Entrenador" and c_type != "TRAINER":                                   continue
			if sel_cat == "Energía"    and c_type != "ENERGY":                                    continue

		if not is_gym_mode and sel_elem != "Elemento: Todos":
			var target = {"Fuego":"FIRE","Agua":"WATER","Planta":"GRASS","Rayo":"LIGHTNING",
				"Psíquico":"PSYCHIC","Lucha":"FIGHTING","Incoloro":"COLORLESS",
				"Siniestro":"DARKNESS","Metálico":"METAL"}.get(sel_elem,"")
			if c_elem != target: continue

		if sel_rarity != "Rareza: Todas":
			if sel_rarity == "Común / Infrecuente" and c_rarity not in ["COMMON","UNCOMMON"]: continue
			if sel_rarity == "Rara / Holo"         and c_rarity not in ["RARE","RARE_HOLO"]:  continue
			if sel_rarity == "Ultra Rara"          and c_rarity != "ULTRA_RARE":              continue

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
		if show_card:
			grid.add_child(MiniCard.make(id, container, menu, qty, available))


static func _refresh_deck_list(container: Control, deck_panel: Control, header: Control, menu) -> void:
	var vbox = UITheme.find_node(deck_panel, "DeckVBox")
	if not vbox: return
	for c in vbox.get_children(): c.queue_free()

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
		var data     = CardDatabase.get_card(id)
		var type_str = data.get("pokemon_type", data.get("type",""))

		var panel = PanelContainer.new()
		var st_panel = StyleBoxFlat.new()
		st_panel.bg_color = Color(0.12, 0.14, 0.20, 0.8)
		st_panel.corner_radius_top_left    = 6; st_panel.corner_radius_top_right    = 6
		st_panel.corner_radius_bottom_left = 6; st_panel.corner_radius_bottom_right = 6
		st_panel.border_width_left = 4
		st_panel.border_color      = UITheme.type_color(type_str)
		panel.add_theme_stylebox_override("panel", st_panel)
		vbox.add_child(panel)

		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		row.custom_minimum_size = Vector2(0, 30)
		panel.add_child(row)
		row.add_child(_spacer(2))

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
			menu.current_deck.erase(id)
			_refresh_deck_list(container, deck_panel, header, menu)
			_refresh_collection_grid(container, menu)
		)
		row.add_child(rm)

		panel.mouse_filter = Control.MOUSE_FILTER_PASS
		panel.mouse_entered.connect(func():
			var s = st_panel.duplicate(); s.bg_color = Color(0.18, 0.22, 0.32, 0.9)
			panel.add_theme_stylebox_override("panel", s)
			MiniCard.show_preview(container, id)
		)
		panel.mouse_exited.connect(func():
			panel.add_theme_stylebox_override("panel", st_panel)
		)

	# Actualizar badge y botón guardar DESPUÉS de poblar el deck
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

	# ── Tier badge ──────────────────────────────────────────────
	const TIER_ORDER_ARR = ["C", "B", "A", "S", "SS"]
	var tier_lbl = UITheme.find_node(header, "TierLbl") as Label
	print("[DeckBuilder] tier_lbl encontrado: ", tier_lbl != null, " | deck_size: ", current_size, " | slot: ", menu.get_meta("gym_tier_editing", "none"))
	var deck_tier : String = ""
	var tier_too_high : bool = false

	if tier_lbl:
		if current_size > 0:
			deck_tier = _calculate_deck_tier(menu.current_deck)
			var tier_color = TIER_COLORS.get(deck_tier, Color(0.6, 0.6, 0.6))

			# En modo gym: verificar si el tier del deck supera el slot editado
			var is_gym_mode = menu.get_meta("deck_mode", "normal") == "gym"
			var slot_tier   = menu.get_meta("gym_tier_editing", "") as String
			print("[DeckBuilder] deck_tier=%s slot_tier=%s is_gym=%s" % [deck_tier, slot_tier, str(is_gym_mode)])
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
# GUARDADO — tier va siempre en el payload (líder y miembros)
# ============================================================
static func _save_gym_deck_to_server(container: Control, menu, gym_role: String) -> void:
	var http    = HTTPRequest.new()
	container.add_child(http)

	var gym_id  = menu.get_meta("gym_editing_id", "")
	var tier    = menu.get_meta("gym_tier_editing", "B")
	var headers = ["Authorization: Bearer " + NetworkManager.token, "Content-Type: application/json"]

	# ── DEBUG ──────────────────────────────────────────────────
	print("[DeckBuilder] === GUARDANDO DECK ===")
	print("[DeckBuilder] gym_id      = '%s'" % gym_id)
	print("[DeckBuilder] tier        = '%s'" % tier)
	print("[DeckBuilder] gym_role    = '%s'" % gym_role)
	print("[DeckBuilder] deck_size   = %d"   % menu.current_deck.size())
	print("[DeckBuilder] token ok    = %s"   % str(NetworkManager.token.length() > 10))
	print("[DeckBuilder] BASE_URL    = '%s'" % NetworkManager.BASE_URL)
	# ──────────────────────────────────────────────────────────

	var url     : String
	var payload : String

	if gym_role == "leader":
		url     = NetworkManager.BASE_URL + "/api/gym/" + gym_id + "/leader-deck"
		payload = JSON.stringify({ "tier": tier, "deck_cards": menu.current_deck })
	else:
		url     = NetworkManager.BASE_URL + "/api/gym/" + gym_id + "/member-deck"
		payload = JSON.stringify({ "tier": tier, "deck_cards": menu.current_deck })

	print("[DeckBuilder] url = '%s'" % url)

	http.request(url, headers, HTTPClient.METHOD_PUT, payload)

	http.request_completed.connect(func(result, code, _h, body):
		http.queue_free()
		print("[DeckBuilder] response code = %d" % code)
		print("[DeckBuilder] body = %s" % body.get_string_from_utf8())
		if code == 200:
			print("[DeckBuilder] Deck tier %s guardado (rol: %s)" % [tier, gym_role])
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
