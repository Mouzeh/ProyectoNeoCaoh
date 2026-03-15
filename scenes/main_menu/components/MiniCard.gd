extends Node

# ============================================================
# MiniCard.gd — Componente: miniatura de carta en colección
# ============================================================

static func make(card_id: String, container: Control, menu, qty: int = -1, available: int = -1, cached_tex: Texture2D = null) -> Control:
	var data = CardDatabase.get_card(card_id)
	var C    = menu

	var show_qty     = qty >= 0
	var is_exhausted = show_qty and available <= 0

	var c = Control.new()
	c.name                  = "MiniCard_" + card_id   # nombre único para debug
	c.set_meta("card_id", card_id)                    # guardamos el id en meta para update_availability
	c.custom_minimum_size   = Vector2(120, 170)
	c.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	c.size_flags_vertical   = Control.SIZE_SHRINK_CENTER

	# ── Panel base ──
	var panel = Panel.new()
	panel.name = "CardPanel"
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

	# ── Imagen: usa caché si se pasa, si no load síncrono ──
	var img_path = LanguageManager.get_card_image(data)
	var _tex_to_use : Texture2D = cached_tex
	if not _tex_to_use and img_path != "":
		_tex_to_use = load(img_path) as Texture2D
	if _tex_to_use:
		var tex = _tex_to_use
		if true:
			var tr = TextureRect.new()
			tr.name    = "CardImage"
			tr.texture = tex
			tr.set_anchors_preset(Control.PRESET_FULL_RECT)
			tr.offset_left   = 6;  tr.offset_top    = 6
			tr.offset_right  = -6; tr.offset_bottom = -26
			tr.expand_mode   = TextureRect.EXPAND_IGNORE_SIZE
			tr.stretch_mode  = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tr.clip_contents = true
			if is_exhausted: tr.modulate = Color(0.35, 0.35, 0.35)
			c.add_child(tr)

	# ── Nombre abajo ──
	var nl = Label.new()
	nl.name = "CardName"
	nl.text = data.get("name", card_id).left(14)
	nl.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	nl.offset_top = -24; nl.offset_bottom = -4
	nl.add_theme_font_size_override("font_size", 11)
	nl.add_theme_color_override("font_color",
		C.COLOR_TEXT_DIM if is_exhausted else C.COLOR_TEXT)
	nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	c.add_child(nl)

	# ── Badge de copias ──
	if show_qty:
		var badge_bg = Panel.new()
		badge_bg.name = "BadgeBg"
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
		badge_lbl.name = "BadgeLbl"
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
		sub_lbl.name = "SubLbl"
		sub_lbl.text = "AGOTADO" if is_exhausted else "disponibles"
		sub_lbl.set_anchors_preset(Control.PRESET_CENTER)
		sub_lbl.offset_left  = -30; sub_lbl.offset_right  = 30
		sub_lbl.offset_top   = 12;  sub_lbl.offset_bottom = 26
		sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sub_lbl.add_theme_font_size_override("font_size", 8)
		sub_lbl.add_theme_color_override("font_color",
			Color(0.7, 0.3, 0.3, 0.9) if is_exhausted else Color(0.4, 0.7, 0.4, 0.8))
		c.add_child(sub_lbl)

	c.tooltip_text = data.get("name", card_id) + " (Click Der: ver)"
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


# ============================================================
# update_availability — actualiza los badges sin recrear el nodo
# Llamado por el sistema de caché del grid para reflejar
# cuántas copias quedan disponibles tras agregar al deck.
# ============================================================
static func update_availability(card_node: Control, qty: int, available: int) -> void:
	if not is_instance_valid(card_node): return

	var is_exhausted = qty >= 0 and available <= 0

	var panel     = card_node.find_child("CardPanel",  false, false) as Panel
	var card_img  = card_node.find_child("CardImage",  false, false) as TextureRect
	var badge_lbl = card_node.find_child("BadgeLbl",   false, false) as Label
	var badge_bg  = card_node.find_child("BadgeBg",    false, false) as Panel
	var sub_lbl   = card_node.find_child("SubLbl",     false, false) as Label
	var name_lbl  = card_node.find_child("CardName",   false, false) as Label

	if badge_lbl:
		badge_lbl.text = str(available) + "/" + str(qty)
		badge_lbl.add_theme_color_override("font_color",
			Color(0.9, 0.3, 0.3) if is_exhausted else Color(0.3, 0.9, 0.3))

	if sub_lbl:
		sub_lbl.text = "AGOTADO" if is_exhausted else "disponibles"
		sub_lbl.add_theme_color_override("font_color",
			Color(0.7, 0.3, 0.3, 0.9) if is_exhausted else Color(0.4, 0.7, 0.4, 0.8))

	if badge_bg:
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

	if panel:
		var s = panel.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
		if s:
			s.bg_color = Color(0.05, 0.05, 0.07) if is_exhausted else Color(0.08, 0.10, 0.15)
			panel.add_theme_stylebox_override("panel", s)

	if card_img:
		card_img.modulate = Color(0.35, 0.35, 0.35) if is_exhausted else Color.WHITE

	if name_lbl:
		# COLOR_TEXT_DIM / COLOR_TEXT no están accesibles aquí sin menu ref,
		# usamos colores hardcoded equivalentes
		name_lbl.add_theme_color_override("font_color",
			Color(0.45, 0.45, 0.5) if is_exhausted else Color(0.88, 0.88, 0.92))


static func show_preview(container: Control, card_id: String) -> void:
	var data        = CardDatabase.get_card(card_id)
	var preview_img  = UITheme.find_node(container, "PreviewImage")    as TextureRect
	var preview_lbl  = UITheme.find_node(container, "PreviewName")     as Label
	var power_lbl    = UITheme.find_node(container, "PreviewPower")    as Label
	var power_sub    = UITheme.find_node(container, "PreviewPowerLbl") as Label

	# Imagen
	var img_path = LanguageManager.get_card_image(data)
	if preview_img and img_path != "":
		preview_img.texture = load(img_path)

	# ── Poder en grande ──────────────────────────────────────
	var power = int(data.get("power", 0))
	var is_pokemon = data.get("type","").to_upper() == "POKEMON"
	if power_lbl:
		if power > 0 and is_pokemon:
			power_lbl.text    = str(power)
			power_lbl.visible = true
			# Color según tier del poder
			if power >= 71:
				power_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.1))   # SS dorado
			elif power >= 51:
				power_lbl.add_theme_color_override("font_color", Color(0.9, 0.5, 0.1))    # S naranja
			elif power >= 36:
				power_lbl.add_theme_color_override("font_color", Color(0.4, 0.8, 0.3))    # A verde
			else:
				power_lbl.add_theme_color_override("font_color", Color(0.3, 0.6, 1.0))    # B azul
		else:
			power_lbl.text    = ""
			power_lbl.visible = false
	if power_sub:
		power_sub.visible = power > 0 and is_pokemon

	# ── Info de texto ─────────────────────────────────────────
	if preview_lbl:
		var c_type       = data.get("type","").to_upper()
		var type_display = data.get("pokemon_type", c_type)
		var rarity       = data.get("rarity", "COMMON")
		var rarity_map   = {
			"COMMON": "Común", "UNCOMMON": "Infrecuente",
			"RARE": "Rara", "RARE_HOLO": "Rara Holo", "ULTRA_RARE": "Ultra Rara"
		}
		var lines : PackedStringArray = []
		lines.append(data.get("name", card_id))
		lines.append("(%s)" % type_display)
		lines.append("✦ " + rarity_map.get(rarity, rarity))
		if PlayerData.is_logged_in:
			var owned = PlayerData.get_card_count(card_id)
			lines.append("Inventario: %d" % owned)
		preview_lbl.text = "\n".join(lines)


# ── LÓGICA PARA AGREGAR CON REGLAS ──
static func _add_to_deck(card_id: String, container: Control, menu) -> void:
	var data = CardDatabase.get_card(card_id)

	var basic_energies = [
		"grass_energy", "fire_energy", "water_energy",
		"lightning_energy", "psychic_energy", "fighting_energy"
	]

	var is_basic_energy = card_id in basic_energies
	var is_gym_mode     = menu.get_meta("deck_mode", "normal") == "gym"
	var max_copies      = 60 if is_basic_energy else 4

	if menu.current_deck.size() >= 60:
		return

	var species_in_deck = menu.current_deck.count(card_id) if is_basic_energy \
		else _get_species_count(card_id, menu)
	if species_in_deck >= max_copies:
		return

	if not is_gym_mode and PlayerData.is_logged_in and not is_basic_energy:
		var owned      = PlayerData.get_card_count(card_id)
		var id_in_deck = menu.current_deck.count(card_id)
		if id_in_deck >= owned:
			return

	menu.current_deck.append(card_id)

	var dp  = UITheme.find_node(container, "DeckPanel")
	var hdr = UITheme.find_node(container, "CountLbl")
	if hdr: hdr = hdr.get_parent().get_parent()
	if dp:  _refresh_deck_list(container, dp, hdr, menu)

	_refresh_collection_grid(container, menu)


# ============================================================
# _refresh_collection_grid — respeta modo gym Y filtros activos
# (duplica la lógica de DeckBuilderScreen para mantener
#  compatibilidad cuando se llama desde MiniCard._add_to_deck)
# ============================================================
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
	for ch in grid.get_children(): ch.queue_free()

	var is_gym_mode = menu.get_meta("deck_mode", "normal") == "gym"
	var gym_type    = menu.get_meta("gym_type", "COLORLESS") if is_gym_mode else ""

	var search_text  = search_box.text.strip_edges().to_lower() if search_box else ""
	var sel_cat      = cat_box.get_item_text(cat_box.selected)         if cat_box    else "Cat: Todas"
	var sel_elem     = elem_box.get_item_text(elem_box.selected)       if elem_box   else "Elem: Todos"
	var sel_rarity   = rarity_box.get_item_text(rarity_box.selected)   if rarity_box else "Rareza: Todas"
	var sel_sort     = sort_box.get_item_text(sort_box.selected)       if sort_box   else "Orden: Nombre ↑"
	var in_deck_only = in_deck_b.button_pressed                        if in_deck_b  else false
	var baby_names   = ["pichu","cleffa","igglybuff","smoochum","tyrogue","elekid","magby"]

	var search_tokens : Array = []
	for tok in search_text.split(" ", false):
		if tok.length() > 0: search_tokens.append(tok)

	const TYPE_ALIASES = {
		"fuego": "FIRE", "fire": "FIRE",
		"agua": "WATER", "water": "WATER",
		"planta": "GRASS", "grass": "GRASS",
		"rayo": "LIGHTNING", "lightning": "LIGHTNING",
		"psiquico": "PSYCHIC", "psychic": "PSYCHIC",
		"lucha": "FIGHTING", "fighting": "FIGHTING",
		"incoloro": "COLORLESS", "colorless": "COLORLESS",
		"siniestro": "DARKNESS", "darkness": "DARKNESS",
		"metalico": "METAL", "metal": "METAL",
	}
	const RARITY_ALIASES = {
		"comun": "COMMON", "común": "COMMON", "common": "COMMON",
		"infrecuente": "UNCOMMON", "uncommon": "UNCOMMON",
		"rara": "RARE", "rare": "RARE",
		"holo": "RARE_HOLO",
		"ultra": "ULTRA_RARE", "ultrarara": "ULTRA_RARE",
	}
	const RARITY_ORDER = {"COMMON": 0, "UNCOMMON": 1, "RARE": 2, "RARE_HOLO": 3, "ULTRA_RARE": 4}

	var result_ids : Array = []

	for id in CardDatabase.get_all_ids():
		var card = CardDatabase.get_card(id)
		if card.is_empty(): continue

		var c_name   = card.get("name","").to_lower()
		var c_type   = card.get("type","").to_upper()
		var c_elem   = card.get("pokemon_type", card.get("type","")).to_upper()
		var c_rarity = card.get("rarity","COMMON").to_upper()
		var c_stage  = card.get("stage", 0)
		var c_power  = int(card.get("power", 0))
		var is_baby  = card.get("is_baby", false) or c_name in baby_names

		if is_gym_mode:
			if c_type == "POKEMON" and c_elem != gym_type and c_elem != "COLORLESS": continue
			if c_type == "ENERGY" and "SPECIAL" in c_rarity:                         continue

		if in_deck_only and not id in menu.current_deck: continue

		if search_tokens.size() > 0:
			var all_match = true
			for tok in search_tokens:
				var tok_match = false
				if tok in c_name: tok_match = true
				if not tok_match and TYPE_ALIASES.has(tok) and c_elem == TYPE_ALIASES[tok]: tok_match = true
				if not tok_match and RARITY_ALIASES.has(tok) and c_rarity == RARITY_ALIASES[tok]: tok_match = true
				if not tok_match and (tok == "fase1" or tok == "1") and int(c_stage) == 1 and c_type == "POKEMON": tok_match = true
				if not tok_match and (tok == "fase2" or tok == "2") and int(c_stage) == 2 and c_type == "POKEMON": tok_match = true
				if not tok_match and (tok == "bebe" or tok == "bebé") and is_baby: tok_match = true
				if not tok_match: all_match = false; break
			if not all_match: continue

		if sel_cat != "Cat: Todas":
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

	match sel_sort:
		"Nombre ↓":   result_ids.sort_custom(func(a, b): return a.name > b.name)
		"Poder ↑":    result_ids.sort_custom(func(a, b): return a.power < b.power)
		"Poder ↓":    result_ids.sort_custom(func(a, b): return a.power > b.power)
		"Rareza":     result_ids.sort_custom(func(a, b): return RARITY_ORDER.get(a.rarity,0) > RARITY_ORDER.get(b.rarity,0))
		_:            result_ids.sort_custom(func(a, b): return a.name < b.name)

	if result_lbl:
		result_lbl.text = str(result_ids.size()) + " cartas"

	for entry in result_ids:
		grid.add_child(make(entry.id, container, menu, entry.qty, entry.available))


static func _get_species_count(card_id: String, menu) -> int:
	var data         = CardDatabase.get_card(card_id)
	var species_name = data.get("name", card_id).to_lower()
	var count        = 0
	for id in menu.current_deck:
		var d = CardDatabase.get_card(id)
		if d.get("name", id).to_lower() == species_name:
			count += 1
	return count


# ── LÓGICA SINCRONIZADA PARA ACTUALIZAR LA LISTA VISUAL ──
static func _refresh_deck_list(container: Control, deck_panel: Control, header: Control, menu) -> void:
	var vbox = UITheme.find_node(deck_panel, "DeckVBox")
	if not vbox: return
	for c in vbox.get_children(): c.queue_free()

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
		rms.corner_radius_top_left    = 6; rms.corner_radius_top_right    = 6
		rms.corner_radius_bottom_left = 6; rms.corner_radius_bottom_right = 6
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
			show_preview(container, id)
		)
		panel.mouse_exited.connect(func():
			panel.add_theme_stylebox_override("panel", st_panel)
		)

	_update_count_label(container, header, menu)


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

	const TIER_ORDER_ARR = ["C", "B", "A", "S", "SS"]
	const TIER_COLORS_LOCAL = {
		"SS": Color(1.0,  0.85, 0.1),
		"S":  Color(0.9,  0.5,  0.1),
		"A":  Color(0.4,  0.8,  0.3),
		"B":  Color(0.3,  0.6,  1.0),
		"C":  Color(0.6,  0.6,  0.6),
	}
	var tier_lbl     = UITheme.find_node(header, "TierLbl") as Label
	var tier_too_high : bool = false

	if tier_lbl:
		if current_size > 0:
			var deck_tier  : String = _calculate_deck_tier(menu.current_deck)
			var tier_color : Color  = TIER_COLORS_LOCAL.get(deck_tier, Color(0.6, 0.6, 0.6))
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

	var err_lbl = UITheme.find_node(container, "SaveErrorLbl") as Label
	if err_lbl: err_lbl.visible = false


static func _calculate_deck_tier(deck: Array) -> String:
	if deck.size() == 0: return "C"
	var powers : Array = []
	for id in deck:
		var card = CardDatabase.get_card(id)
		if card.is_empty(): continue
		if card.get("type", "").to_upper() == "ENERGY": continue
		var p = int(card.get("power", 0))
		if p > 0: powers.append(p)
	if powers.size() == 0: return "C"
	powers.sort(); powers.reverse()
	var top = powers.slice(0, min(20, powers.size()))
	var avg = 0.0
	for p in top: avg += p
	avg /= top.size()
	if avg >= 71: return "SS"
	if avg >= 51: return "S"
	if avg >= 36: return "A"
	if avg >= 21: return "B"
	return "C"


static func _spacer(w: int) -> Control:
	var s = Control.new()
	s.custom_minimum_size = Vector2(w, 0)
	return s
