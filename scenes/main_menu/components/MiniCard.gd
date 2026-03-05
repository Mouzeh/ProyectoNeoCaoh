extends Node

# ============================================================
# MiniCard.gd — Componente: miniatura de carta en colección
# ============================================================

static func make(card_id: String, container: Control, menu, qty: int = -1, available: int = -1) -> Control:
	var data = CardDatabase.get_card(card_id)
	var C    = menu

	var show_qty     = qty >= 0
	var is_exhausted = show_qty and available <= 0

	var c = Control.new()
	c.custom_minimum_size  = Vector2(120, 170)
	c.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	c.size_flags_vertical   = Control.SIZE_SHRINK_CENTER

	# ── Panel base ──
	var panel = Panel.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	var st = StyleBoxFlat.new()
	st.bg_color = Color(0.05, 0.05, 0.07) if is_exhausted else Color(0.08, 0.10, 0.15)
	match data.get("rarity","COMMON"):
		"ULTRA_RARE": st.border_color = C.COLOR_GOLD
		"RARE_HOLO":  st.border_color = Color(0.55, 0.78, 1.0)
		"RARE":       st.border_color = Color(0.78, 0.78, 0.78)
		_:            st.border_color = Color(0.25, 0.28, 0.36)
	if is_exhausted:
		st.border_color = st.border_color.darkened(0.5)
	st.border_width_left = 1; st.border_width_right  = 1
	st.border_width_top  = 1; st.border_width_bottom = 1
	st.corner_radius_top_left    = 6; st.corner_radius_top_right    = 6
	st.corner_radius_bottom_left = 6; st.corner_radius_bottom_right = 6
	panel.add_theme_stylebox_override("panel", st)
	c.add_child(panel)

	# ── Imagen ──
	var img_path = data.get("image","")
	if img_path != "":
		var tex = load(img_path)
		if tex:
			var tr = TextureRect.new()
			tr.texture = tex
			tr.set_anchors_preset(Control.PRESET_FULL_RECT)
			tr.offset_left = 6; tr.offset_top    = 6
			tr.offset_right= -6; tr.offset_bottom = -26
			tr.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
			tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tr.clip_contents = true
			if is_exhausted: tr.modulate = Color(0.35, 0.35, 0.35)
			c.add_child(tr)

	# ── Nombre abajo ──
	var nl = Label.new()
	nl.text = data.get("name", card_id).left(14)
	nl.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	nl.offset_top = -24; nl.offset_bottom = -4
	nl.add_theme_font_size_override("font_size", 11)
	nl.add_theme_color_override("font_color",
		C.COLOR_TEXT_DIM if is_exhausted else C.COLOR_TEXT)
	nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	c.add_child(nl)

	# ── Badge de copias en el centro ──
	if show_qty:
		var badge_bg = Panel.new()
		badge_bg.set_anchors_preset(Control.PRESET_CENTER)
		badge_bg.offset_left  = -22; badge_bg.offset_right  = 22
		badge_bg.offset_top   = -14; badge_bg.offset_bottom = 14
		var bst = StyleBoxFlat.new()
		if is_exhausted:
			bst.bg_color     = Color(0.15, 0.05, 0.05, 0.92)
			bst.border_color = Color(0.6, 0.2, 0.2, 0.9)
		else:
			bst.bg_color     = Color(0.05, 0.08, 0.05, 0.92)
			bst.border_color = Color(0.2, 0.6, 0.2, 0.9)
		bst.border_width_left = 1; bst.border_width_right  = 1
		bst.border_width_top  = 1; bst.border_width_bottom = 1
		bst.corner_radius_top_left    = 6; bst.corner_radius_top_right    = 6
		bst.corner_radius_bottom_left = 6; bst.corner_radius_bottom_right = 6
		badge_bg.add_theme_stylebox_override("panel", bst)
		c.add_child(badge_bg)

		var badge_lbl = Label.new()
		badge_lbl.text = str(available) + "/" + str(qty)
		badge_lbl.set_anchors_preset(Control.PRESET_CENTER)
		badge_lbl.offset_left  = -22; badge_lbl.offset_right  = 22
		badge_lbl.offset_top   = -14; badge_lbl.offset_bottom = 14
		badge_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		badge_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		badge_lbl.add_theme_font_size_override("font_size", 13)
		badge_lbl.add_theme_color_override("font_color",
			Color(0.9, 0.3, 0.3) if is_exhausted else Color(0.3, 0.9, 0.3))
		c.add_child(badge_lbl)

		var sub_lbl = Label.new()
		sub_lbl.text = "AGOTADO" if is_exhausted else "disponibles"
		sub_lbl.set_anchors_preset(Control.PRESET_CENTER)
		sub_lbl.offset_left  = -30; sub_lbl.offset_right  = 30
		sub_lbl.offset_top   = 12;  sub_lbl.offset_bottom = 26
		sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sub_lbl.add_theme_font_size_override("font_size", 8)
		sub_lbl.add_theme_color_override("font_color",
			Color(0.7, 0.3, 0.3, 0.9) if is_exhausted else Color(0.4, 0.7, 0.4, 0.8))
		c.add_child(sub_lbl)

	c.tooltip_text = data.get("name", card_id) + " (Click Derecho para ver)"
	c.mouse_filter = Control.MOUSE_FILTER_STOP

	c.mouse_entered.connect(func():
		if is_instance_valid(panel) and not is_exhausted:
			var s = panel.get_theme_stylebox("panel").duplicate()
			s.bg_color = Color(0.18, 0.22, 0.32)
			panel.add_theme_stylebox_override("panel", s)
		show_preview(container, card_id)
	)
	c.mouse_exited.connect(func():
		if is_instance_valid(panel):
			var s = panel.get_theme_stylebox("panel").duplicate()
			s.bg_color = Color(0.05, 0.05, 0.07) if is_exhausted else Color(0.08, 0.10, 0.15)
			panel.add_theme_stylebox_override("panel", s)
	)
	c.gui_input.connect(func(ev):
		if ev is InputEventMouseButton and ev.pressed:
			if ev.button_index == MOUSE_BUTTON_LEFT:
				if not is_exhausted:
					_add_to_deck(card_id, container, menu)
			elif ev.button_index == MOUSE_BUTTON_RIGHT:
				show_preview(container, card_id)
	)
	return c

static func show_preview(container: Control, card_id: String) -> void:
	var data        = CardDatabase.get_card(card_id)
	var preview_img = UITheme.find_node(container, "PreviewImage") as TextureRect
	var preview_lbl = UITheme.find_node(container, "PreviewName")  as Label
	if preview_img and data.get("image","") != "":
		preview_img.texture = load(data.get("image",""))
	if preview_lbl:
		var qty_text = ""
		if PlayerData.is_logged_in:
			qty_text = "\nInventario: " + str(PlayerData.get_card_count(card_id))
		preview_lbl.text = data.get("name", card_id) + "\n(" + data.get("type","Desconocido") + ")" + qty_text

# ── LOGICA PARA AGREGAR CON REGLAS DE ENERGIA ──
static func _add_to_deck(card_id: String, container: Control, menu) -> void:
	var data       = CardDatabase.get_card(card_id)
	
	var basic_energies = [
		"grass_energy", "fire_energy", "water_energy", 
		"lightning_energy", "psychic_energy", "fighting_energy"
	]
	
	var is_basic_energy = card_id in basic_energies
	var max_copies = 60 if is_basic_energy else 4

	# Límite por REGLAS
	var species_in_deck = menu.current_deck.count(card_id) if is_basic_energy \
		else _get_species_count(card_id, menu)
		
	if species_in_deck >= max_copies or menu.current_deck.size() >= 60:
		return

	# Límite de INVENTARIO
	if PlayerData.is_logged_in and not is_basic_energy:
		var owned      = PlayerData.get_card_count(card_id)
		var id_in_deck = menu.current_deck.count(card_id)
		if id_in_deck >= owned:
			return

	menu.current_deck.append(card_id)
	var dp  = UITheme.find_node(container, "DeckPanel")
	var hdr = UITheme.find_node(container, "CountLbl")
	if hdr: hdr = hdr.get_parent().get_parent()
	if dp:  _refresh_deck_list(container, dp, hdr, menu)
	_refresh_collection_grid_badges(container, menu)

static func _refresh_collection_grid_badges(container: Control, menu) -> void:
	var grid = UITheme.find_node(container, "CollectionGrid")
	if not grid: return
	for ch in grid.get_children(): ch.queue_free()
	var ids = PlayerData.inventory.keys() if PlayerData.is_logged_in else CardDatabase.get_all_ids()
	for id in ids:
		var qty       = PlayerData.get_card_count(id) if PlayerData.is_logged_in else -1
		var id_in_deck = menu.current_deck.count(id)
		var available = (qty - id_in_deck) if PlayerData.is_logged_in else -1
		grid.add_child(make(id, container, menu, qty, available))

static func _get_species_count(card_id: String, menu) -> int:
	var data         = CardDatabase.get_card(card_id)
	var species_name = data.get("name", card_id).to_lower()
	var count        = 0
	for id in menu.current_deck:
		var d = CardDatabase.get_card(id)
		if d.get("name", id).to_lower() == species_name:
			count += 1
	return count

# ── LOGICA SINCRONIZADA PARA ACTUALIZAR LA LISTA VISUAL ──
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
		
		if wa != wb:
			return wa < wb
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
		rms.corner_radius_top_left    = 6; rms.corner_radius_top_right    = 6
		rms.corner_radius_bottom_left = 6; rms.corner_radius_bottom_right = 6
		var rms_hov = rms.duplicate(); rms_hov.bg_color = Color(0.6,0.2,0.2,0.9)
		rm.add_theme_stylebox_override("normal", rms)
		rm.add_theme_stylebox_override("hover",  rms_hov)
		rm.pressed.connect(func():
			menu.current_deck.erase(id)
			_refresh_deck_list(container, deck_panel, header, menu)
			_refresh_collection_grid_badges(container, menu)
		)
		row.add_child(rm)

		panel.mouse_filter = Control.MOUSE_FILTER_PASS
		panel.mouse_entered.connect(func():
			var s = st_panel.duplicate(); s.bg_color = Color(0.18,0.22,0.32,0.9)
			panel.add_theme_stylebox_override("panel", s)
			show_preview(container, id)
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
		lbl.add_theme_color_override("font_color",
			menu.COLOR_GREEN if current_size == 60 else menu.COLOR_TEXT_DIM)

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
