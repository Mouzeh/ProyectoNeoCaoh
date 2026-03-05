extends Node

# ============================================================
# DeckBuilderScreen.gd
# ============================================================

const MiniCard     = preload("res://scenes/main_menu/components/MiniCard.gd")

# ─── ENTRY POINT ──────────────────────────────────────────
static func build(container: Control, menu) -> void:
	# Creamos una "capa" exclusiva para el DeckBuilder
	var builder_root = Control.new()
	builder_root.name = "BuilderRoot"
	builder_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	container.add_child(builder_root)
	
	# Le pasamos esta nueva capa a las vistas en lugar de usar el contenedor principal
	build_deck_selection(builder_root, menu)
# ============================================================
# VISTA 1: SELECTOR DE MAZOS (CAJAS)
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
	hs.bg_color = Color(menu.COLOR_PANEL.r, menu.COLOR_PANEL.g, menu.COLOR_PANEL.b, 0.85)
	hs.border_color = Color(menu.COLOR_GOLD_DIM.r, menu.COLOR_GOLD_DIM.g, menu.COLOR_GOLD_DIM.b, 0.3)
	hs.border_width_bottom = 1
	header.add_theme_stylebox_override("panel", hs)
	container.add_child(header)

	# ── BOTÓN PARA VOLVER AL LOBBY ──
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
		# Llamamos a la función de tu MainMenu.gd pasándole el enum Screen.LOBBY
		if menu.has_method("_show_screen"):
			menu._show_screen(menu.Screen.LOBBY)
		elif menu.has_method("build_main_menu"):
			menu.build_main_menu()
		else:
			print("Botón Volver: Configura tu función de retorno aquí")
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
	box.custom_minimum_size = Vector2(240, 360) # Cajas un poco más altas para que quepan 2 botones
	
	var is_active = (PlayerData.active_deck_slot == slot_id)
	
	# ── ESTILO DE LA CAJA (CON BRILLO SI ES ACTIVA) ──
	var st = StyleBoxFlat.new()
	st.bg_color = Color(0.1, 0.12, 0.18, 0.95)
	st.corner_radius_top_left = 12; st.corner_radius_top_right = 12
	st.corner_radius_bottom_left = 12; st.corner_radius_bottom_right = 12
	
	if is_locked:
		st.border_width_left = 2; st.border_width_right = 2
		st.border_width_top = 2; st.border_width_bottom = 2
		st.border_color = Color(0.3, 0.3, 0.3)
	elif is_active:
		# Efecto Brillante para el Mazo Activo
		st.border_width_left = 4; st.border_width_right = 4
		st.border_width_top = 4; st.border_width_bottom = 4
		st.border_color = Color(0.3, 0.8, 0.3, 1.0) # Borde Verde Brillo
		st.shadow_color = Color(0.2, 0.9, 0.2, 0.4)
		st.shadow_size = 25
	else:
		st.border_width_left = 2; st.border_width_right = 2
		st.border_width_top = 2; st.border_width_bottom = 2
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
		btn.custom_minimum_size = Vector2(160, 40)
		btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		vbox.add_child(UITheme.vspace(20))
		vbox.add_child(btn)
		return

	# ── IMAGEN DEL MAZO ──
	var img_panel = PanelContainer.new()
	img_panel.custom_minimum_size = Vector2(160, 110)
	img_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var st_img = StyleBoxFlat.new()
	st_img.bg_color = Color(0.08, 0.1, 0.15)
	st_img.corner_radius_top_left = 8; st_img.corner_radius_top_right = 8
	st_img.corner_radius_bottom_left = 8; st_img.corner_radius_bottom_right = 8
	img_panel.add_theme_stylebox_override("panel", st_img)
	
	var img_rect = TextureRect.new()
	img_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	img_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	var tex_path = "res://assets/imagen/Deck1.png"
	if ResourceLoader.exists(tex_path):
		img_rect.texture = load(tex_path)
	else:
		var ph_lbl = Label.new()
		ph_lbl.text = "🖼️\nFalta Deck1.png"
		ph_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ph_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		ph_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
		ph_lbl.add_theme_font_size_override("font_size", 10)
		ph_lbl.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
		img_rect.add_child(ph_lbl)
		
	img_panel.add_child(img_rect)
	vbox.add_child(img_panel)
	vbox.add_child(UITheme.vspace(10))

	# ── DATOS DEL MAZO ──
	var deck_data = PlayerData.decks.get(str(slot_id), {})
	var deck_cards = deck_data.get("cards", [])
	var deck_name = deck_data.get("name", "Mazo " + str(slot_id))
	var is_empty = deck_cards.size() == 0

	var name_lbl = Label.new()
	name_lbl.text = "VACÍO" if is_empty else deck_name
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 16)
	name_lbl.add_theme_color_override("font_color", Color.GRAY if is_empty else Color.WHITE)
	name_lbl.custom_minimum_size = Vector2(180, 0)
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
	name_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_lbl.clip_text = true
	vbox.add_child(name_lbl)

	var count_lbl = Label.new()
	count_lbl.text = str(deck_cards.size()) + "/60 Cartas"
	count_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	count_lbl.add_theme_font_size_override("font_size", 12)
	count_lbl.add_theme_color_override("font_color", menu.COLOR_GREEN if deck_cards.size() == 60 else menu.COLOR_RED)
	vbox.add_child(count_lbl)
	
	vbox.add_child(UITheme.vspace(16))

	# ── BOTONES (Editar y Activar) ──
	var edit_btn = Button.new()
	edit_btn.text = "➕ Crear Mazo" if is_empty else "✏️ Editar Mazo"
	edit_btn.custom_minimum_size = Vector2(180, 36)
	edit_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	
	var st_btn = StyleBoxFlat.new()
	st_btn.bg_color = menu.COLOR_PURPLE if is_empty else menu.COLOR_ACCENT
	st_btn.corner_radius_top_left = 6; st_btn.corner_radius_bottom_right = 6
	st_btn.corner_radius_top_right = 6; st_btn.corner_radius_bottom_left = 6
	edit_btn.add_theme_stylebox_override("normal", st_btn)
	
	edit_btn.pressed.connect(func():
		menu.current_deck = deck_cards.duplicate()
		menu.deck_name = deck_name
		build_deck_editor(container, menu, slot_id)
	)
	vbox.add_child(edit_btn)

	# Si el mazo NO está vacío, mostramos el botón de Activar
	if not is_empty:
		vbox.add_child(UITheme.vspace(8))
		var active_btn = Button.new()
		active_btn.custom_minimum_size = Vector2(180, 36)
		active_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		
		if is_active:
			active_btn.text = "✅ Mazo Activo"
			active_btn.disabled = true
			var st_act = StyleBoxFlat.new()
			st_act.bg_color = Color(0.2, 0.6, 0.2, 0.8) # Verde
			st_act.corner_radius_top_left = 6; st_act.corner_radius_bottom_right = 6
			st_act.corner_radius_top_right = 6; st_act.corner_radius_bottom_left = 6
			active_btn.add_theme_stylebox_override("disabled", st_act)
			active_btn.add_theme_color_override("font_disabled_color", Color.WHITE)
		else:
			active_btn.text = "Hacer Activo"
			var st_inact = StyleBoxFlat.new()
			st_inact.bg_color = Color(0.3, 0.3, 0.3, 0.8) # Gris
			st_inact.corner_radius_top_left = 6; st_inact.corner_radius_bottom_right = 6
			st_inact.corner_radius_top_right = 6; st_inact.corner_radius_bottom_left = 6
			active_btn.add_theme_stylebox_override("normal", st_inact)
			
			active_btn.pressed.connect(func():
				PlayerData.active_deck_slot = slot_id
				# Recargamos la vista para aplicar el efecto de brillo a la nueva caja
				build_deck_selection(container, menu)
			)
			
		vbox.add_child(active_btn)


# ============================================================
# VISTA 2: EL EDITOR DE MAZOS
# ============================================================
static func build_deck_editor(container: Control, menu, current_slot: int) -> void:
	var C = menu
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
	hs.bg_color = Color(C.COLOR_PANEL.r, C.COLOR_PANEL.g, C.COLOR_PANEL.b, 0.85)
	hs.border_color = Color(C.COLOR_GOLD_DIM.r, C.COLOR_GOLD_DIM.g, C.COLOR_GOLD_DIM.b, 0.3)
	hs.border_width_bottom = 1
	header.add_theme_stylebox_override("panel", hs)
	container.add_child(header)

	var hbox = HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	header.add_child(hbox)

	var back_btn = Button.new()
	back_btn.text = "⬅ Volver a Mis Mazos"
	back_btn.custom_minimum_size = Vector2(160, 0)
	var st_back = StyleBoxFlat.new()
	st_back.bg_color = Color(0.2, 0.2, 0.2, 0.8)
	back_btn.add_theme_stylebox_override("normal", st_back)
	back_btn.pressed.connect(func(): build_deck_selection(container, menu))
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
	name_input.text = menu.deck_name
	name_input.placeholder_text = "Nombre del Mazo"
	name_input.max_length = 16
	name_input.add_theme_font_size_override("font_size", 16)
	name_input.add_theme_color_override("font_color", C.COLOR_GOLD)
	name_input.custom_minimum_size = Vector2(250, 30)
	name_input.text_changed.connect(func(new_text): menu.deck_name = new_text)
	var st_input = StyleBoxFlat.new(); st_input.bg_color = Color(0,0,0,0)
	name_input.add_theme_stylebox_override("normal", st_input)
	title_v.add_child(name_input)

	var count_lbl = Label.new()
	count_lbl.name = "CountLbl"
	count_lbl.text = str(C.current_deck.size()) + " / 60 Cartas"
	count_lbl.add_theme_font_size_override("font_size", 12)
	count_lbl.add_theme_color_override("font_color", C.COLOR_TEXT_DIM)
	title_v.add_child(count_lbl)

	var bm = MarginContainer.new()
	bm.add_theme_constant_override("margin_right", 24)
	bm.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox.add_child(bm)

	var main_area = HBoxContainer.new()
	main_area.anchor_left = 0; main_area.anchor_right  = 1
	main_area.anchor_top  = 0; main_area.anchor_bottom = 1
	main_area.offset_top  = 140; main_area.offset_bottom = -20
	main_area.offset_left = 24; main_area.offset_right  = -24
	main_area.add_theme_constant_override("separation", 16)
	container.add_child(main_area)

	var st_coll = StyleBoxFlat.new()
	st_coll.bg_color = Color(C.COLOR_PANEL.r, C.COLOR_PANEL.g, C.COLOR_PANEL.b, 0.95)
	st_coll.border_color = Color(C.COLOR_GOLD_DIM.r, C.COLOR_GOLD_DIM.g, C.COLOR_GOLD_DIM.b, 0.3)
	st_coll.border_width_left = 1; st_coll.border_width_right  = 1
	st_coll.border_width_top  = 1; st_coll.border_width_bottom = 1
	st_coll.corner_radius_top_left    = 16; st_coll.corner_radius_top_right    = 16
	st_coll.corner_radius_bottom_left = 16; st_coll.corner_radius_bottom_right = 16

	var coll_panel = PanelContainer.new()
	coll_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
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
	coll_title.text = "MI COLECCIÓN  ·  Click Izq: Agregar | Click Der: Ver" if PlayerData.is_logged_in else "TODAS LAS CARTAS  ·  Click Izq: Agregar | Click Der: Ver"
	coll_title.add_theme_font_size_override("font_size", 12)
	coll_title.add_theme_color_override("font_color", C.COLOR_GOLD_DIM)
	cv.add_child(coll_title)

	var filter_hbox = HBoxContainer.new()
	filter_hbox.add_theme_constant_override("separation", 8)
	cv.add_child(filter_hbox)

	var search_in = LineEdit.new()
	search_in.name = "SearchInput"
	search_in.placeholder_text = "🔎 Buscar..."
	search_in.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	search_in.add_theme_stylebox_override("normal", UITheme.input_style(Color(0.2,0.2,0.3)))
	search_in.add_theme_stylebox_override("focus",  UITheme.input_style(C.COLOR_GOLD))
	filter_hbox.add_child(search_in)

	var cat_opt = OptionButton.new()
	cat_opt.name = "CatFilter"
	for item in ["Categoría: Todas","Básico","Bebé","Fase 1","Fase 2","Entrenador","Energía"]: cat_opt.add_item(item)
	cat_opt.custom_minimum_size = Vector2(130, 0)
	filter_hbox.add_child(cat_opt)

	var elem_opt = OptionButton.new()
	elem_opt.name = "ElemFilter"
	for item in ["Elemento: Todos","Fuego","Agua","Planta","Rayo","Psíquico","Lucha","Incoloro","Siniestro","Metálico"]: elem_opt.add_item(item)
	elem_opt.custom_minimum_size = Vector2(130, 0)
	filter_hbox.add_child(elem_opt)

	var rarity_opt = OptionButton.new()
	rarity_opt.name = "RarityFilter"
	for item in ["Rareza: Todas","Común / Infrecuente","Rara / Holo","Ultra Rara"]: rarity_opt.add_item(item)
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
	elem_opt.item_selected.connect(func(_i): _refresh_collection_grid(container, menu))
	rarity_opt.item_selected.connect(func(_i): _refresh_collection_grid(container, menu))

	var preview_panel = PanelContainer.new()
	preview_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
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
	prev_name.autowrap_mode = TextServer.AUTOWRAP_WORD
	prev_name.add_theme_font_size_override("font_size", 14)
	prev_name.add_theme_color_override("font_color", C.COLOR_GOLD)
	prev_v.add_child(prev_name)

	var dp_panel = PanelContainer.new()
	dp_panel.name = "DeckPanel"
	dp_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
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
	clear_btn.custom_minimum_size = Vector2(0, 32)
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
	save_btn.custom_minimum_size = Vector2(0, 36)
	save_btn.add_theme_font_size_override("font_size", 12)
	save_btn.add_theme_color_override("font_color", Color.WHITE)
	
	var st_save = StyleBoxFlat.new()
	st_save.bg_color = Color(0.15, 0.5, 0.2, 0.9)
	st_save.corner_radius_top_left = 6; st_save.corner_radius_top_right = 6
	st_save.corner_radius_bottom_left = 6; st_save.corner_radius_bottom_right = 6
	var st_save_hov = st_save.duplicate(); st_save_hov.bg_color = Color(0.2, 0.6, 0.25, 1)
	var st_save_disabled = st_save.duplicate(); st_save_disabled.bg_color = Color(0.3, 0.3, 0.3, 0.5)
	
	save_btn.add_theme_stylebox_override("normal", st_save)
	save_btn.add_theme_stylebox_override("hover", st_save_hov)
	save_btn.add_theme_stylebox_override("disabled", st_save_disabled)
	save_btn.disabled = true
	
	save_btn.pressed.connect(func():
		var size = menu.current_deck.size()
		if size == 60 and _has_basic_pokemon(menu.current_deck):
			PlayerData.save_deck_to_server(current_slot, menu.deck_name, menu.current_deck)
	)
	dv.add_child(save_btn)
	
	_refresh_deck_list(container, dp_panel, header, menu)
	_refresh_collection_grid(container, menu)


# ============================================================
# FUNCIONES AUXILIARES DE RENDERIZADO
# ============================================================
static func _refresh_collection_grid(container: Control, menu) -> void:
	var grid       = UITheme.find_node(container, "CollectionGrid")
	var search_box = UITheme.find_node(container, "SearchInput")  as LineEdit
	var cat_box    = UITheme.find_node(container, "CatFilter")    as OptionButton
	var elem_box   = UITheme.find_node(container, "ElemFilter")   as OptionButton
	var rarity_box = UITheme.find_node(container, "RarityFilter") as OptionButton
	if not grid: return
	for c in grid.get_children(): c.queue_free()

	var search_text = search_box.text.to_lower() if search_box else ""
	var sel_cat     = cat_box.get_item_text(cat_box.selected)       if cat_box    else "Categoría: Todas"
	var sel_elem    = elem_box.get_item_text(elem_box.selected)     if elem_box   else "Elemento: Todos"
	var sel_rarity  = rarity_box.get_item_text(rarity_box.selected) if rarity_box else "Rareza: Todas"
	var baby_names  = ["pichu","cleffa","igglybuff","smoochum","tyrogue","elekid","magby"]

	var card_ids: Array = []
	if PlayerData.is_logged_in and PlayerData.inventory.size() > 0:
		card_ids = PlayerData.inventory.keys()
	else:
		card_ids = CardDatabase.get_all_ids()

	for id in card_ids:
		var card     = CardDatabase.get_card(id)
		if card.is_empty(): continue

		var c_name   = card.get("name","").to_lower()
		var c_type   = card.get("type","").to_upper()
		var c_elem   = card.get("pokemon_type", card.get("type","")).to_upper()
		var c_rarity = card.get("rarity","COMMON").to_upper()
		var c_stage  = card.get("stage", 0)
		var is_baby  = card.get("is_baby", false) or c_name in baby_names

		if search_text != "" and not search_text in c_name: continue
		if sel_cat != "Categoría: Todas":
			if sel_cat == "Básico"     and (c_type != "POKEMON" or int(c_stage) != 0 or is_baby): continue
			if sel_cat == "Bebé"       and (c_type != "POKEMON" or not is_baby):                  continue
			if sel_cat == "Fase 1"     and (c_type != "POKEMON" or int(c_stage) != 1):            continue
			if sel_cat == "Fase 2"     and (c_type != "POKEMON" or int(c_stage) != 2):            continue
			if sel_cat == "Entrenador" and c_type != "TRAINER":                                   continue
			if sel_cat == "Energía"    and c_type != "ENERGY":                                    continue
		if sel_elem != "Elemento: Todos":
			var target = {"Fuego":"FIRE","Agua":"WATER","Planta":"GRASS","Rayo":"LIGHTNING","Psíquico":"PSYCHIC","Lucha":"FIGHTING","Incoloro":"COLORLESS","Siniestro":"DARKNESS","Metálico":"METAL"}.get(sel_elem,"")
			if c_elem != target: continue
		if sel_rarity != "Rareza: Todas":
			if sel_rarity == "Común / Infrecuente" and c_rarity not in ["COMMON","UNCOMMON"]: continue
			if sel_rarity == "Rara / Holo"         and c_rarity not in ["RARE","RARE_HOLO"]:  continue
			if sel_rarity == "Ultra Rara"          and c_rarity != "ULTRA_RARE":              continue

		var qty       = PlayerData.get_card_count(id) if PlayerData.is_logged_in else -1
		var in_deck   = menu.current_deck.count(id)
		var available = (qty - in_deck) if PlayerData.is_logged_in else -1

		grid.add_child(MiniCard.make(id, container, menu, qty, available))

static func _refresh_deck_list(container: Control, deck_panel: Control, header: Control, menu) -> void:
	var vbox = UITheme.find_node(deck_panel, "DeckVBox")
	if not vbox: return
	for c in vbox.get_children(): c.queue_free()
	
	_update_count_label(container, header, menu)

	var counts:      Dictionary = {}
	var types_count: Dictionary = {}
	for id in menu.current_deck:
		counts[id] = counts.get(id, 0) + 1
		var d    = CardDatabase.get_card(id)
		var type = d.get("pokemon_type", d.get("type","")).to_upper()
		types_count[type] = types_count.get(type, 0) + 1

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
		st_panel.border_color = UITheme.type_color(type_str)
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
			icon_rect.texture = icon_tex
			icon_rect.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
			icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon_rect.custom_minimum_size = Vector2(18, 18)
			icon_rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
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
		cnt.custom_minimum_size   = Vector2(30, 0)
		cnt.horizontal_alignment  = HORIZONTAL_ALIGNMENT_RIGHT
		cnt.vertical_alignment    = VERTICAL_ALIGNMENT_CENTER
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
		rms.bg_color = Color(0.3,0.1,0.1,0.5)
		rms.corner_radius_top_left    = 6; rms.corner_radius_bottom_right = 6
		var rms_hov = rms.duplicate(); rms_hov.bg_color = Color(0.6,0.2,0.2,0.9)
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
			var s = st_panel.duplicate(); s.bg_color = Color(0.18,0.22,0.32,0.9)
			panel.add_theme_stylebox_override("panel", s)
			MiniCard.show_preview(container, id)
		)
		panel.mouse_exited.connect(func():
			panel.add_theme_stylebox_override("panel", st_panel)
		)

static func _has_basic_pokemon(deck: Array) -> bool:
	var baby_names = ["pichu", "cleffa", "igglybuff", "smoochum", "tyrogue", "elekid", "magby"]
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

static func _update_count_label(container: Control, header: Control, menu) -> void:
	var lbl = UITheme.find_node(header, "CountLbl") as Label
	var current_size = menu.current_deck.size()
	
	if lbl:
		lbl.text = str(current_size) + " / 60 Cartas"
		lbl.add_theme_color_override("font_color", menu.COLOR_GREEN if current_size == 60 else menu.COLOR_TEXT_DIM)

	var save_btn = UITheme.find_node(container, "SaveDeckBtn") as Button
	if save_btn:
		if current_size == 60:
			if _has_basic_pokemon(menu.current_deck):
				save_btn.text = "💾 Guardar Mazo al Servidor (60/60)"
				save_btn.disabled = false
			else:
				save_btn.text = "❌ Falta al menos 1 Pokémon Básico"
				save_btn.disabled = true
		else:
			save_btn.text = "Faltan cartas (" + str(current_size) + "/60)"
			save_btn.disabled = true

static func _spacer(w: int) -> Control:
	var s = Control.new()
	s.custom_minimum_size = Vector2(w, 0)
	return s
