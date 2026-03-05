extends Node

# ============================================================
# LobbyScreen.gd
# ============================================================

const RoomCard     = preload("res://scenes/main_menu/components/RoomCard.gd")

static func build(container: Control, menu) -> void:
	var C = menu

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

	var title_v = VBoxContainer.new()
	title_v.alignment = BoxContainer.ALIGNMENT_CENTER
	title_v.add_theme_constant_override("separation", 2)
	title_m.add_child(title_v)

	var title_lbl = Label.new()
	title_lbl.text = "◈ POKÉMON TCG · MESAS DE JUEGO"
	title_lbl.add_theme_font_size_override("font_size", 16)
	title_lbl.add_theme_color_override("font_color", C.COLOR_GOLD)
	title_v.add_child(title_lbl)

	var deck_status = Label.new()
	var active_deck = PlayerData.get_active_deck()
	var active_name = PlayerData.get_deck_name(PlayerData.active_deck_slot)
	var deck_size = active_deck.size()
	deck_status.text = active_name + "  ·  " + str(deck_size) + "/60 cartas"
	deck_status.add_theme_font_size_override("font_size", 11)
	deck_status.add_theme_color_override("font_color", C.COLOR_GREEN if deck_size == 60 else Color("df673b"))
	title_v.add_child(deck_status)

	var pill_m = MarginContainer.new()
	pill_m.add_theme_constant_override("margin_right", 24)
	pill_m.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var pp = UITheme.pill("👤  [" + PlayerData.rank + "] " + PlayerData.username, Color(0,0,0,0.5), C.COLOR_GOLD, 36)
	pp.custom_minimum_size = Vector2(180, 36)
	pill_m.add_child(pp)
	hbox.add_child(pill_m)

	# ── Contenido principal ──
	var center = MarginContainer.new()
	center.anchor_left = 0; center.anchor_right  = 1
	center.anchor_top  = 0; center.anchor_bottom = 1
	center.offset_top  = 120
	center.add_theme_constant_override("margin_left",   40)
	center.add_theme_constant_override("margin_right",  40)
	center.add_theme_constant_override("margin_top",    20)
	center.add_theme_constant_override("margin_bottom", 20)
	container.add_child(center)

	var lobby_vbox = VBoxContainer.new()
	lobby_vbox.add_theme_constant_override("separation", 16)
	center.add_child(lobby_vbox)

	# Botones de acción
	var actions_hbox = HBoxContainer.new()
	actions_hbox.alignment = BoxContainer.ALIGNMENT_END
	actions_hbox.add_theme_constant_override("separation", 20)
	lobby_vbox.add_child(actions_hbox)

	var local_btn = Button.new()
	local_btn.text = "JUGAR LOCAL"
	local_btn.custom_minimum_size = Vector2(160, 45)
	local_btn.add_theme_font_size_override("font_size", 14)
	var st_local = StyleBoxFlat.new()
	st_local.bg_color = Color(0.2, 0.2, 0.25)
	st_local.border_color = Color(0.4, 0.4, 0.45)
	st_local.border_width_left = 1; st_local.border_width_right  = 1
	st_local.border_width_top  = 1; st_local.border_width_bottom = 1
	st_local.corner_radius_top_left    = 6; st_local.corner_radius_top_right    = 6
	st_local.corner_radius_bottom_left = 6; st_local.corner_radius_bottom_right = 6
	local_btn.add_theme_stylebox_override("normal", st_local)
	local_btn.add_theme_stylebox_override("hover",  st_local)
	local_btn.pressed.connect(func(): container.get_tree().change_scene_to_file("res://scenes/battle/BattleBoard.tscn"))
	actions_hbox.add_child(local_btn)

	var create_btn = Button.new()
	create_btn.text = "➕ CREAR NUEVA MESA"
	create_btn.custom_minimum_size = Vector2(200, 45)
	create_btn.add_theme_font_size_override("font_size", 14)
	create_btn.add_theme_color_override("font_color", C.COLOR_PANEL)
	var st_create = StyleBoxFlat.new()
	st_create.bg_color = C.COLOR_GOLD
	st_create.corner_radius_top_left    = 6; st_create.corner_radius_top_right    = 6
	st_create.corner_radius_bottom_left = 6; st_create.corner_radius_bottom_right = 6
	create_btn.add_theme_stylebox_override("normal", st_create)
	create_btn.add_theme_stylebox_override("hover",  st_create)
	create_btn.pressed.connect(func():
		if NetworkManager.ws_connected:
			NetworkManager.create_room(PlayerData.get_active_deck())
		else:
			print("No conectado al servidor")
	)
	actions_hbox.add_child(create_btn)

	# Grid de mesas
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

	update_room_list(container, C.current_rooms, menu)

	if NetworkManager.ws_connected:
		NetworkManager.get_room_list()


static func update_room_list(container: Control, rooms: Array, menu) -> void:
	var grid = UITheme.find_node(container, "RoomsGrid")
	if not grid: return
	for c in grid.get_children(): c.queue_free()

	if rooms.size() == 0:
		var empty_lbl = Label.new()
		empty_lbl.text = "No hay mesas activas. ¡Sé el primero en crear una!"
		empty_lbl.add_theme_color_override("font_color", menu.COLOR_TEXT_DIM)
		grid.add_child(empty_lbl)
		return

	for room in rooms:
		grid.add_child(RoomCard.make(room, menu))
