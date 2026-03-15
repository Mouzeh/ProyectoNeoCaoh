extends Node

# ============================================================
# CollectionScreen.gd
# rarity_color / rarity_weight definidas localmente
# (sin depender de ShopScreen como estáticas)
# ============================================================

const ShopScreen = preload("res://scenes/main_menu/screens/ShopScreen.gd")
const MiniCard   = preload("res://scenes/main_menu/components/MiniCard.gd")

enum Tab { CARDS, PACKS, DECKS, STATS, COINS }

const EXPANSIONS = [
	{"id":"Legendary Collection","label":"Legendary Collection","logo":"res://assets/imagen/ExpNeoGenesis/TextLogo/Legendary Collection.png","total":110, "active":true},
	{"id":"Neo Genesis",   "label":"Neo Genesis",   "logo":"res://assets/imagen/ExpNeoGenesis/TextLogo/Neo Genesis.png",   "total":111, "active":true},
	{"id":"Neo Discovery", "label":"Neo Discovery", "logo":"res://assets/imagen/ExpNeoGenesis/Neo Discovery.png", "total":75,  "active":false},
	{"id":"Neo Revelation","label":"Neo Revelation","logo":"res://assets/imagen/ExpNeoGenesis/Neo Revelation.png","total":66,  "active":false},
	{"id":"Neo Destiny",   "label":"Neo Destiny",   "logo":"res://assets/imagen/ExpNeoGenesis/Neo Destiny.png",   "total":113, "active":false},
]

# ── Cache estático ───────────────────────────────────────────
static var _exp_cache:       Dictionary = {}
static var _tex_cache:       Dictionary = {}
static var _tex_cache_order: Array      = []
const TEX_CACHE_MAX = 500
static var _pending_load: Array = []
static var _load_timer:   float = 0.0

const BATCH_SIZE   = 20
const SCROLL_AHEAD = 3


# ============================================================
# UTILIDADES DE RAREZA — locales para no depender de ShopScreen
# ============================================================
static func rarity_color(rarity: String) -> Color:
	match rarity:
		"UNCOMMON":   return Color(0.40, 0.85, 0.40)
		"RARE":       return Color(0.95, 0.85, 0.10)
		"RARE_HOLO":  return Color(0.20, 0.85, 1.00)
		"ULTRA_RARE": return Color(1.00, 0.45, 0.05)
		_:            return Color(0.65, 0.65, 0.70)


static func rarity_weight(rarity: String) -> int:
	match rarity:
		"UNCOMMON":   return 1
		"RARE":       return 2
		"RARE_HOLO":  return 3
		"ULTRA_RARE": return 4
		_:            return 0


# ============================================================
# CACHE DE EXPANSIONES Y TEXTURAS
# ============================================================
static func _get_expansion(card: Dictionary) -> String:
	var img = card.get("image","")
	for exp in EXPANSIONS:
		if exp["id"] in img:
			return exp["id"]
	return "Unknown"


static func _ensure_exp_cache() -> void:
	if not _exp_cache.is_empty(): return
	for exp in EXPANSIONS:
		_exp_cache[exp["id"]] = []
	for id in CardDatabase.get_all_ids():
		var card   = CardDatabase.get_card(id)
		var exp_id = _get_expansion(card)
		if exp_id in _exp_cache:
			_exp_cache[exp_id].append(id)
	for exp_id in _exp_cache:
		_exp_cache[exp_id].sort_custom(func(a, b):
			var na = CardDatabase.get_card(a).get("number","999/999").split("/")[0].to_int()
			var nb = CardDatabase.get_card(b).get("number","999/999").split("/")[0].to_int()
			return na < nb
		)


static func _get_ids_for_expansion(exp_id: String) -> Array:
	_ensure_exp_cache()
	return _exp_cache.get(exp_id, [])


static func _cache_texture(path: String, tex: Texture2D) -> void:
	if path in _tex_cache:
		_tex_cache_order.erase(path)
		_tex_cache_order.append(path)
		return
	while _tex_cache_order.size() >= TEX_CACHE_MAX:
		var oldest = _tex_cache_order.pop_front()
		_tex_cache.erase(oldest)
	_tex_cache[path] = tex
	_tex_cache_order.append(path)


static func _get_texture(path: String) -> Texture2D:
	if path == "": return null
	if path in _tex_cache: return _tex_cache[path]
	var status = ResourceLoader.load_threaded_get_status(path)
	if status == ResourceLoader.THREAD_LOAD_LOADED:
		var tex = ResourceLoader.load_threaded_get(path)
		_cache_texture(path, tex)
		return tex
	return null


static func _request_texture(path: String) -> void:
	if path == "" or path in _tex_cache: return
	var status = ResourceLoader.load_threaded_get_status(path)
	if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS: return
	if status == ResourceLoader.THREAD_LOAD_LOADED: return
	if not path in _pending_load:
		_pending_load.append(path)
		ResourceLoader.load_threaded_request(path)


# ============================================================
# ENTRY POINT
# ============================================================
static func build(container: Control, menu) -> void:
	var C = menu
	_ensure_exp_cache()

	var root = Control.new()
	root.name = "CollRoot"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	container.add_child(root)

	var bg = TextureRect.new()
	var bg_tex = load("res://assets/imagen/fondomenu.png")
	if bg_tex: bg.texture = bg_tex
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.modulate = Color(0.15, 0.15, 0.15, 1)
	root.add_child(bg)

	# ── HEADER ──────────────────────────────
	var header = Panel.new()
	header.anchor_left   = 0; header.anchor_right  = 1
	header.anchor_top    = 0; header.anchor_bottom = 0
	header.offset_top    = 0; header.offset_bottom = 88
	var hs = StyleBoxFlat.new()
	hs.bg_color     = Color(C.COLOR_PANEL.r * 1.1, C.COLOR_PANEL.g * 1.1, C.COLOR_PANEL.b * 1.2, 0.97)
	hs.border_color = Color(C.COLOR_GOLD_DIM.r, C.COLOR_GOLD_DIM.g, C.COLOR_GOLD_DIM.b, 0.35)
	hs.border_width_bottom = 2
	header.add_theme_stylebox_override("panel", hs)
	root.add_child(header)

	var gold_strip = ColorRect.new()
	gold_strip.anchor_left = 0; gold_strip.anchor_right  = 1
	gold_strip.anchor_top  = 0; gold_strip.anchor_bottom = 0
	gold_strip.offset_bottom = 3
	gold_strip.color = C.COLOR_GOLD
	header.add_child(gold_strip)

	var hdr_m = MarginContainer.new()
	hdr_m.set_anchors_preset(Control.PRESET_FULL_RECT)
	hdr_m.add_theme_constant_override("margin_left",   20)
	hdr_m.add_theme_constant_override("margin_right",  20)
	hdr_m.add_theme_constant_override("margin_top",    8)
	hdr_m.add_theme_constant_override("margin_bottom", 6)
	header.add_child(hdr_m)

	var hdr_row = HBoxContainer.new()
	hdr_row.add_theme_constant_override("separation", 20)
	hdr_m.add_child(hdr_row)

	var accent_bar = ColorRect.new()
	accent_bar.color = C.COLOR_ACCENT
	accent_bar.custom_minimum_size = Vector2(4, 0)
	accent_bar.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hdr_row.add_child(accent_bar)

	var title_col = VBoxContainer.new()
	title_col.add_theme_constant_override("separation", 2)
	title_col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hdr_row.add_child(title_col)

	var title_lbl = Label.new()
	title_lbl.text = "📚  MI COLECCIÓN"
	title_lbl.add_theme_font_size_override("font_size", 20)
	title_lbl.add_theme_color_override("font_color", C.COLOR_GOLD)
	title_col.add_child(title_lbl)

	var total_unique = CardDatabase.get_all_ids().size()
	var owned_unique = PlayerData.inventory.size()
	var pct = int(float(owned_unique) / max(total_unique, 1) * 100)

	var sub_lbl = Label.new()
	sub_lbl.text = "%d / %d cartas  ·  %d%% completado" % [owned_unique, total_unique, pct]
	sub_lbl.add_theme_font_size_override("font_size", 11)
	sub_lbl.add_theme_color_override("font_color", C.COLOR_TEXT_DIM)
	title_col.add_child(sub_lbl)

	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hdr_row.add_child(spacer)

	var prog_col = VBoxContainer.new()
	prog_col.add_theme_constant_override("separation", 4)
	prog_col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	prog_col.custom_minimum_size = Vector2(220, 0)
	hdr_row.add_child(prog_col)

	var prog_lbl_row = HBoxContainer.new()
	prog_lbl_row.add_theme_constant_override("separation", 0)
	prog_col.add_child(prog_lbl_row)

	var prog_txt = Label.new()
	prog_txt.text = "Progreso total"
	prog_txt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	prog_txt.add_theme_font_size_override("font_size", 10)
	prog_txt.add_theme_color_override("font_color", C.COLOR_TEXT_DIM)
	prog_lbl_row.add_child(prog_txt)

	var pct_lbl = Label.new()
	pct_lbl.text = str(pct) + "%"
	pct_lbl.add_theme_font_size_override("font_size", 10)
	pct_lbl.add_theme_color_override("font_color", C.COLOR_GREEN if pct == 100 else C.COLOR_GOLD)
	prog_lbl_row.add_child(pct_lbl)

	var prog_bar = ProgressBar.new()
	prog_bar.min_value = 0; prog_bar.max_value = total_unique; prog_bar.value = owned_unique
	prog_bar.custom_minimum_size = Vector2(220, 12)
	prog_bar.show_percentage = false
	prog_col.add_child(prog_bar)

	var tabs_sep = Control.new()
	tabs_sep.custom_minimum_size = Vector2(10, 0)
	hdr_row.add_child(tabs_sep)

	var tabs_hbox = HBoxContainer.new()
	tabs_hbox.add_theme_constant_override("separation", 4)
	tabs_hbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hdr_row.add_child(tabs_hbox)

	var tab_labels = ["🃏 Cartas", "📦 Sobres", "📋 Mazos", "📊 Stats", "🪙 Monedas"]
	var tab_btns: Array = []
	for i in range(tab_labels.size()):
		var tb = Button.new()
		tb.text = tab_labels[i]
		tb.custom_minimum_size = Vector2(100, 34)
		tb.add_theme_font_size_override("font_size", 12)
		tabs_hbox.add_child(tb)
		tab_btns.append(tb)

	var content = Control.new()
	content.name = "ContentArea"
	content.anchor_left = 0; content.anchor_right  = 1
	content.anchor_top  = 0; content.anchor_bottom = 1
	content.offset_top  = 92; content.offset_bottom = -6
	root.add_child(content)

	for i in range(tab_btns.size()):
		var idx = i
		tab_btns[i].pressed.connect(func():
			_style_tabs(tab_btns, idx, menu)
			_build_tab(content, idx, root, menu)
		)

	_style_tabs(tab_btns, Tab.CARDS, menu)
	_build_tab(content, Tab.CARDS, root, menu)


static func _style_tabs(btns: Array, active: int, menu) -> void:
	var C = menu
	for i in range(btns.size()):
		var st = StyleBoxFlat.new()
		if i == active:
			st.bg_color     = C.COLOR_ACCENT
			st.border_color = C.COLOR_ACCENT.lightened(0.3)
			btns[i].add_theme_color_override("font_color", Color.WHITE)
		else:
			st.bg_color     = Color(0.12, 0.14, 0.20, 0.7)
			st.border_color = Color(C.COLOR_GOLD_DIM.r, C.COLOR_GOLD_DIM.g, C.COLOR_GOLD_DIM.b, 0.25)
			btns[i].add_theme_color_override("font_color", C.COLOR_TEXT_DIM)
		st.border_width_left = 1; st.border_width_right  = 1
		st.border_width_top  = 1; st.border_width_bottom = 1
		st.corner_radius_top_left    = 6; st.corner_radius_top_right    = 6
		st.corner_radius_bottom_left = 6; st.corner_radius_bottom_right = 6
		btns[i].add_theme_stylebox_override("normal", st)
		btns[i].add_theme_stylebox_override("hover",  st)


static func _build_tab(content: Control, tab: int, root: Control, menu) -> void:
	for c in content.get_children(): c.queue_free()
	match tab:
		Tab.CARDS: _build_cards_tab(content, root, menu)
		Tab.PACKS: _build_packs_tab(content, root, menu)
		Tab.DECKS: _build_decks_tab(content, menu)
		Tab.STATS: _build_stats_tab(content, menu)
		Tab.COINS: _build_coins_tab(content, menu)


# ════════════════════════════════════════════════════════════
# TAB: CARTAS
# ════════════════════════════════════════════════════════════
static func _build_cards_tab(content: Control, root: Control, menu) -> void:
	var C = menu

	var main_v = VBoxContainer.new()
	main_v.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_v.add_theme_constant_override("separation", 0)
	content.add_child(main_v)

	var exp_bar = Panel.new()
	exp_bar.custom_minimum_size   = Vector2(0, 120)
	exp_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var st_bar = StyleBoxFlat.new()
	st_bar.bg_color = Color(0.05, 0.06, 0.10, 0.98)
	st_bar.border_color = Color(C.COLOR_GOLD_DIM.r, C.COLOR_GOLD_DIM.g, C.COLOR_GOLD_DIM.b, 0.2)
	st_bar.border_width_bottom = 1
	exp_bar.add_theme_stylebox_override("panel", st_bar)
	main_v.add_child(exp_bar)

	var exp_m = MarginContainer.new()
	exp_m.add_theme_constant_override("margin_left",  16)
	exp_m.add_theme_constant_override("margin_right", 16)
	exp_m.add_theme_constant_override("margin_top",    8)
	exp_m.add_theme_constant_override("margin_bottom", 8)
	exp_m.set_anchors_preset(Control.PRESET_FULL_RECT)
	exp_bar.add_child(exp_m)

	var exp_hbox = HBoxContainer.new()
	exp_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	exp_hbox.add_theme_constant_override("separation", 20)
	exp_m.add_child(exp_hbox)

	var grid_area = Control.new()
	grid_area.name = "GridArea"
	grid_area.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	grid_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_v.add_child(grid_area)

	var exp_btns: Array = []
	for exp_data in EXPANSIONS:
		var btn = _make_expansion_btn(exp_data, C)
		exp_hbox.add_child(btn)
		exp_btns.append({"btn": btn, "data": exp_data})

	for i in range(exp_btns.size()):
		var idx      = i
		var exp_data = exp_btns[i]["data"]
		exp_btns[i]["btn"].pressed.connect(func():
			if not exp_data["active"]: return
			_style_exp_btns(exp_btns, idx, C)
			_build_expansion_grid(grid_area, exp_data["id"], content, menu)
		)

	_style_exp_btns(exp_btns, 0, C)
	_build_expansion_grid(grid_area, EXPANSIONS[0]["id"], content, menu)


static func _make_expansion_btn(exp_data: Dictionary, C) -> Button:
	var active = exp_data["active"]
	var btn    = Button.new()
	btn.custom_minimum_size        = Vector2(190, 100)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if active else Control.CURSOR_ARROW

	var st = StyleBoxFlat.new()
	st.bg_color     = Color(0.1, 0.12, 0.18, 0.9) if active else Color(0.05, 0.06, 0.08, 0.7)
	st.border_color = C.COLOR_GOLD_DIM if active else Color(0.2, 0.2, 0.25, 0.4)
	st.border_width_left = 1; st.border_width_right  = 1
	st.border_width_top  = 1; st.border_width_bottom = 1
	st.corner_radius_top_left    = 10; st.corner_radius_top_right    = 10
	st.corner_radius_bottom_left = 10; st.corner_radius_bottom_right = 10
	btn.add_theme_stylebox_override("normal",  st)
	btn.add_theme_stylebox_override("pressed", st)
	var st_hov = st.duplicate()
	st_hov.bg_color     = Color(0.18, 0.22, 0.32, 0.9) if active else st.bg_color
	st_hov.border_color = C.COLOR_GOLD if active else st.border_color
	btn.add_theme_stylebox_override("hover", st_hov)

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 4)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(vbox)

	var logo_path   = exp_data.get("logo","")
	var logo_loaded = false
	if active and logo_path != "":
		var tex: Texture2D = null
		if ResourceLoader.exists(logo_path):
			tex = load(logo_path) as Texture2D
		if tex:
			var img = TextureRect.new()
			img.texture             = tex
			img.expand_mode         = TextureRect.EXPAND_IGNORE_SIZE
			img.stretch_mode        = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			img.custom_minimum_size = Vector2(170, 62)
			img.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			img.mouse_filter        = Control.MOUSE_FILTER_IGNORE
			vbox.add_child(img)
			logo_loaded = true

	if not logo_loaded:
		var lbl = Label.new()
		lbl.text = exp_data["label"]
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 13)
		lbl.add_theme_color_override("font_color", C.COLOR_GOLD if active else Color(0.35, 0.35, 0.4, 0.8))
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(lbl)

	if not active:
		var soon = Label.new()
		soon.text = "PRÓXIMAMENTE"
		soon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		soon.add_theme_font_size_override("font_size", 9)
		soon.add_theme_color_override("font_color", Color(0.4, 0.4, 0.5, 0.8))
		soon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(soon)
	else:
		var ids   = _get_ids_for_expansion(exp_data["id"])
		var owned = 0
		for id in ids:
			if PlayerData.inventory.has(id): owned += 1
		var pl = Label.new()
		pl.text = str(owned) + " / " + str(ids.size())
		pl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		pl.add_theme_font_size_override("font_size", 10)
		pl.add_theme_color_override("font_color", C.COLOR_GREEN if owned == ids.size() else C.COLOR_TEXT_DIM)
		pl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(pl)
	return btn


static func _style_exp_btns(btns: Array, active_idx: int, C) -> void:
	for i in range(btns.size()):
		var b = btns[i]["btn"]; var data = btns[i]["data"]
		var st = StyleBoxFlat.new()
		if i == active_idx and data["active"]:
			st.bg_color            = Color(0.15, 0.20, 0.30, 0.97)
			st.border_color        = C.COLOR_GOLD
			st.border_width_bottom = 3
			st.shadow_color        = Color(C.COLOR_GOLD.r, C.COLOR_GOLD.g, C.COLOR_GOLD.b, 0.3)
			st.shadow_size         = 8
		else:
			st.bg_color     = Color(0.1, 0.12, 0.18, 0.9) if data["active"] else Color(0.05, 0.06, 0.08, 0.7)
			st.border_color = C.COLOR_GOLD_DIM if data["active"] else Color(0.2, 0.2, 0.25, 0.4)
			st.border_width_bottom = 1
		st.border_width_left = 1; st.border_width_right = 1; st.border_width_top = 1
		st.corner_radius_top_left    = 10; st.corner_radius_top_right    = 10
		st.corner_radius_bottom_left = 10; st.corner_radius_bottom_right = 10
		b.add_theme_stylebox_override("normal",  st)
		b.add_theme_stylebox_override("pressed", st)


static func _build_expansion_grid(grid_area: Control, exp_id: String, content: Control, menu) -> void:
	var C = menu
	for c in grid_area.get_children(): c.queue_free()
	_pending_load.clear()

	var all_ids = _get_ids_for_expansion(exp_id)
	for id in all_ids:
		var img_path = LanguageManager.get_card_image(CardDatabase.get_card(id))
		_request_texture(img_path)

	var main_h = HBoxContainer.new()
	main_h.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_h.add_theme_constant_override("separation", 12)
	var mm = MarginContainer.new()
	mm.set_anchors_preset(Control.PRESET_FULL_RECT)
	mm.add_theme_constant_override("margin_left",   16)
	mm.add_theme_constant_override("margin_right",  16)
	mm.add_theme_constant_override("margin_top",    12)
	mm.add_theme_constant_override("margin_bottom", 12)
	mm.add_child(main_h)
	grid_area.add_child(mm)

	var st_panel = StyleBoxFlat.new()
	st_panel.bg_color = Color(C.COLOR_PANEL.r, C.COLOR_PANEL.g, C.COLOR_PANEL.b, 0.88)
	st_panel.border_color = Color(C.COLOR_GOLD_DIM.r, C.COLOR_GOLD_DIM.g, C.COLOR_GOLD_DIM.b, 0.2)
	st_panel.border_width_left = 1; st_panel.border_width_right  = 1
	st_panel.border_width_top  = 1; st_panel.border_width_bottom = 1
	st_panel.corner_radius_top_left    = 12; st_panel.corner_radius_top_right    = 12
	st_panel.corner_radius_bottom_left = 12; st_panel.corner_radius_bottom_right = 12

	var coll_p = PanelContainer.new()
	coll_p.size_flags_horizontal    = Control.SIZE_EXPAND_FILL
	coll_p.size_flags_stretch_ratio = 0.72
	coll_p.add_theme_stylebox_override("panel", st_panel)
	main_h.add_child(coll_p)

	var cv = VBoxContainer.new()
	cv.add_theme_constant_override("separation", 10)
	var cv_m = MarginContainer.new()
	cv_m.add_theme_constant_override("margin_left",   14)
	cv_m.add_theme_constant_override("margin_right",  14)
	cv_m.add_theme_constant_override("margin_top",    10)
	cv_m.add_theme_constant_override("margin_bottom", 10)
	cv_m.add_child(cv)
	coll_p.add_child(cv_m)

	var fhb = HBoxContainer.new()
	fhb.add_theme_constant_override("separation", 8)
	cv.add_child(fhb)

	var search = LineEdit.new()
	search.name = "SearchInput"
	search.placeholder_text = "🔎 Buscar en " + exp_id + "..."
	search.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	search.add_theme_stylebox_override("normal", UITheme.input_style(Color(0.2, 0.2, 0.3)))
	search.add_theme_stylebox_override("focus",  UITheme.input_style(C.COLOR_GOLD))
	fhb.add_child(search)

	var show_opt = OptionButton.new()
	show_opt.name = "ShowFilter"
	show_opt.add_item("Todas"); show_opt.add_item("Solo mis cartas"); show_opt.add_item("Faltantes")
	show_opt.custom_minimum_size = Vector2(140, 0)
	fhb.add_child(show_opt)

	var sort_opt = OptionButton.new()
	sort_opt.name = "SortFilter"
	sort_opt.add_item("Nº de carta"); sort_opt.add_item("Nombre"); sort_opt.add_item("Rareza")
	sort_opt.custom_minimum_size = Vector2(120, 0)
	fhb.add_child(sort_opt)

	var scroll = ScrollContainer.new()
	scroll.name = "CardScroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	UITheme.apply_scrollbar_theme(scroll)
	cv.add_child(scroll)

	var grid = GridContainer.new()
	grid.name    = "SetGrid"
	grid.columns = 7
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	scroll.add_child(grid)

	var prev_p = PanelContainer.new()
	prev_p.size_flags_horizontal    = Control.SIZE_EXPAND_FILL
	prev_p.size_flags_stretch_ratio = 0.28
	var st_prev = st_panel.duplicate()
	st_prev.bg_color = Color(0.04, 0.05, 0.08, 0.98)
	prev_p.add_theme_stylebox_override("panel", st_prev)
	main_h.add_child(prev_p)

	var pv = VBoxContainer.new()
	pv.alignment = BoxContainer.ALIGNMENT_CENTER
	pv.add_theme_constant_override("separation", 8)
	var pv_m = MarginContainer.new()
	pv_m.add_theme_constant_override("margin_left",  14); pv_m.add_theme_constant_override("margin_right", 14)
	pv_m.add_theme_constant_override("margin_top",   14); pv_m.add_theme_constant_override("margin_bottom",14)
	pv_m.add_child(pv); prev_p.add_child(pv_m)

	var prev_img = TextureRect.new(); prev_img.name = "PreviewImage"
	prev_img.size_flags_vertical = Control.SIZE_EXPAND_FILL
	prev_img.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	prev_img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pv.add_child(prev_img)

	pv.add_child(UITheme.vspace(6))

	var prev_name = Label.new(); prev_name.name = "PreviewName"
	prev_name.text = "Pasa el mouse\nsobre una carta"
	prev_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prev_name.autowrap_mode = TextServer.AUTOWRAP_WORD
	prev_name.add_theme_font_size_override("font_size", 25)
	prev_name.add_theme_color_override("font_color", C.COLOR_GOLD)
	pv.add_child(prev_name)

	var prev_detail_panel = PanelContainer.new()
	prev_detail_panel.name = "PreviewDetailPanel"
	var pd_st = StyleBoxFlat.new()
	pd_st.bg_color     = Color(0.06, 0.08, 0.06, 0.95)
	pd_st.border_color = Color(0.85, 0.72, 0.30, 0.55)
	pd_st.set_border_width_all(1)
	pd_st.set_corner_radius_all(8)
	pd_st.content_margin_left  = 12
	pd_st.content_margin_right  = 12
	pd_st.content_margin_top    = 8
	pd_st.content_margin_bottom = 8
	prev_detail_panel.add_theme_stylebox_override("panel", pd_st)
	pv.add_child(prev_detail_panel)

	var prev_detail = Label.new()
	prev_detail.name = "PreviewDetail"
	prev_detail.text = ""
	prev_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prev_detail.autowrap_mode = TextServer.AUTOWRAP_WORD
	prev_detail.add_theme_font_size_override("font_size", 20)
	prev_detail.add_theme_color_override("font_color", C.COLOR_TEXT_DIM)
	prev_detail_panel.add_child(prev_detail)

	search.text_changed.connect(func(_t):    _refresh_set_grid(grid_area, grid, all_ids, menu))
	show_opt.item_selected.connect(func(_i): _refresh_set_grid(grid_area, grid, all_ids, menu))
	sort_opt.item_selected.connect(func(_i): _refresh_set_grid(grid_area, grid, all_ids, menu))

	_fill_grid_batched(grid, all_ids, 0, grid_area, menu)


static func _fill_grid_batched(grid: GridContainer, ids: Array, start: int, grid_area: Control, menu) -> void:
	if not is_instance_valid(grid): return
	var end = min(start + BATCH_SIZE, ids.size())
	for i in range(start, end):
		var id    = ids[i]
		var card  = CardDatabase.get_card(id)
		var owned = PlayerData.inventory.has(id)
		var qty   = PlayerData.get_card_count(id)
		grid.add_child(_make_set_card_slot(id, card, owned, qty, grid_area, menu))

	if end < ids.size():
		grid.get_tree().process_frame.connect(
			func(): _fill_grid_batched(grid, ids, end, grid_area, menu),
			CONNECT_ONE_SHOT
		)


static func _refresh_set_grid(grid_area: Control, grid: GridContainer, all_ids: Array, menu) -> void:
	var search_box = UITheme.find_node(grid_area, "SearchInput") as LineEdit
	var show_box   = UITheme.find_node(grid_area, "ShowFilter")  as OptionButton
	var sort_box   = UITheme.find_node(grid_area, "SortFilter")  as OptionButton

	var search_text = search_box.text.to_lower() if search_box else ""
	var show_mode   = show_box.selected if show_box else 0
	var sort_mode   = sort_box.selected if sort_box else 0

	var filtered = all_ids.duplicate()
	if search_text != "":
		filtered = filtered.filter(func(id): return search_text in CardDatabase.get_card(id).get("name","").to_lower())
	match show_mode:
		1: filtered = filtered.filter(func(id): return PlayerData.inventory.has(id))
		2: filtered = filtered.filter(func(id): return not PlayerData.inventory.has(id))

	filtered.sort_custom(func(a, b):
		var ca = CardDatabase.get_card(a); var cb = CardDatabase.get_card(b)
		match sort_mode:
			0:
				var na = ca.get("number","999/999").split("/")[0].to_int()
				var nb = cb.get("number","999/999").split("/")[0].to_int()
				return na < nb
			1: return ca.get("name","") < cb.get("name","")
			# ✅ USA FUNCIONES LOCALES — sin ShopScreen.rarity_weight
			2: return rarity_weight(ca.get("rarity","COMMON")) > rarity_weight(cb.get("rarity","COMMON"))
		return false
	)

	for c in grid.get_children(): c.queue_free()
	_fill_grid_batched(grid, filtered, 0, grid_area, menu)


static func _make_set_card_slot(card_id: String, card: Dictionary, owned: bool, qty: int, grid_area: Control, menu) -> Control:
	var C    = menu
	var slot = Control.new()
	slot.custom_minimum_size = Vector2(100, 140)

	var panel = Panel.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	var st = StyleBoxFlat.new()
	if owned:
		match card.get("rarity","COMMON"):
			"ULTRA_RARE": st.border_color = Color(1.0, 0.45, 0.05)
			"RARE_HOLO":  st.border_color = Color(0.2,  0.85, 1.0)
			"RARE":       st.border_color = Color(0.95, 0.85, 0.1)
			_:            st.border_color = Color(0.3,  0.35, 0.45)
		st.bg_color = Color(0.08, 0.10, 0.15)
	else:
		st.border_color = Color(0.18, 0.18, 0.22)
		st.bg_color     = Color(0.04, 0.04, 0.06)
	st.border_width_left = 1; st.border_width_right  = 1
	st.border_width_top  = 1; st.border_width_bottom = 1
	st.corner_radius_top_left    = 6; st.corner_radius_top_right    = 6
	st.corner_radius_bottom_left = 6; st.corner_radius_bottom_right = 6
	panel.add_theme_stylebox_override("panel", st)
	slot.add_child(panel)

	var img_path = LanguageManager.get_card_image(card)
	var tr = TextureRect.new()
	tr.set_anchors_preset(Control.PRESET_FULL_RECT)
	tr.offset_left = 4; tr.offset_top    = 4
	tr.offset_right= -4; tr.offset_bottom = -20
	tr.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.modulate = Color.WHITE if owned else Color(0.0, 0.0, 0.0, 0.85)
	slot.add_child(tr)

	var cached_tex = _get_texture(img_path)
	if cached_tex:
		tr.texture = cached_tex
	elif img_path != "":
		var timer = Timer.new()
		timer.wait_time = 0.05
		timer.autostart = true
		var path_ref = img_path
		timer.timeout.connect(func():
			if not is_instance_valid(tr):
				timer.queue_free(); return
			var status = ResourceLoader.load_threaded_get_status(path_ref)
			if status == ResourceLoader.THREAD_LOAD_LOADED:
				var tex = ResourceLoader.load_threaded_get(path_ref)
				_cache_texture(path_ref, tex)
				tr.texture = tex
				timer.queue_free()
			elif status == ResourceLoader.THREAD_LOAD_FAILED:
				timer.queue_free()
		)
		slot.add_child(timer)

	var num_lbl = Label.new()
	num_lbl.text = card.get("number","?")
	num_lbl.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	num_lbl.offset_top = -20; num_lbl.offset_bottom = -2
	num_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	num_lbl.add_theme_font_size_override("font_size", 9)
	num_lbl.add_theme_color_override("font_color",
		C.COLOR_GOLD_DIM if owned else Color(0.3, 0.3, 0.35))
	slot.add_child(num_lbl)

	if owned and qty > 1:
		var badge = Label.new()
		badge.text = "×" + str(qty)
		badge.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		badge.offset_left = -22; badge.offset_right  = -2
		badge.offset_top  = 2;   badge.offset_bottom = 16
		badge.add_theme_font_size_override("font_size", 9)
		badge.add_theme_color_override("font_color", C.COLOR_GREEN)
		slot.add_child(badge)

	slot.mouse_filter = Control.MOUSE_FILTER_STOP
	slot.mouse_entered.connect(func():
		if is_instance_valid(panel):
			var s = panel.get_theme_stylebox("panel").duplicate()
			if owned: s.bg_color = Color(0.16, 0.20, 0.30)
			panel.add_theme_stylebox_override("panel", s)
		_show_set_card_preview(grid_area, card_id, card, owned, qty, menu)
	)
	slot.mouse_exited.connect(func():
		if is_instance_valid(panel):
			var s = panel.get_theme_stylebox("panel").duplicate()
			s.bg_color = Color(0.08, 0.10, 0.15) if owned else Color(0.04, 0.04, 0.06)
			panel.add_theme_stylebox_override("panel", s)
	)
	return slot


static func _show_set_card_preview(grid_area, card_id, card, owned, qty, menu) -> void:
	var C        = menu
	var prev_img = UITheme.find_node(grid_area, "PreviewImage")  as TextureRect
	var prev_lbl = UITheme.find_node(grid_area, "PreviewName")   as Label
	var prev_det = UITheme.find_node(grid_area, "PreviewDetail") as Label

	var img_path = LanguageManager.get_card_image(card)
	if prev_img:
		var tex = _get_texture(img_path)
		if tex == null and img_path != "":
			tex = load(img_path)
			_cache_texture(img_path, tex)
		prev_img.texture  = tex
		prev_img.modulate = Color.WHITE if owned else Color(0.15, 0.15, 0.15)

	if prev_lbl:
		prev_lbl.text = card.get("name", card_id)
		# ✅ USA FUNCIÓN LOCAL — sin ShopScreen.rarity_color
		prev_lbl.add_theme_color_override("font_color",
			rarity_color(card.get("rarity","COMMON")) if owned else Color(0.4, 0.4, 0.5))

	if prev_det:
		var rarity = card.get("rarity","COMMON").replace("_"," ")
		var number = card.get("number","?")
		prev_det.text = "Nº " + number + "  ·  " + rarity + "\n" + ("Tienes: ×" + str(qty) if owned else "🔒 No tienes esta carta")


# ════════════════════════════════════════════════════════════
# TAB: SOBRES
# ════════════════════════════════════════════════════════════
static func _build_packs_tab(content: Control, root: Control, menu) -> void:
	var C = menu

	var scroll = ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	UITheme.apply_scrollbar_theme(scroll)
	content.add_child(scroll)

	var mm = MarginContainer.new()
	mm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mm.add_theme_constant_override("margin_left",  50)
	mm.add_theme_constant_override("margin_right", 50)
	mm.add_theme_constant_override("margin_top",   30)
	mm.add_theme_constant_override("margin_bottom",30)
	scroll.add_child(mm)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 28)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mm.add_child(vbox)

	var hdr_h = HBoxContainer.new()
	hdr_h.add_theme_constant_override("separation", 12)
	vbox.add_child(hdr_h)

	var acc = ColorRect.new()
	acc.color = C.COLOR_ACCENT
	acc.custom_minimum_size = Vector2(4, 0)
	hdr_h.add_child(acc)

	var hdr_v2 = VBoxContainer.new()
	hdr_v2.add_theme_constant_override("separation", 2)
	hdr_v2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hdr_h.add_child(hdr_v2)

	var title = Label.new()
	title.text = "📦 SOBRES SIN ABRIR"
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", C.COLOR_GOLD)
	hdr_v2.add_child(title)

	var sub = Label.new()
	sub.text = "Haz clic en la imagen del sobre para ampliarlo · Pulsa Abrir para revelar las cartas"
	sub.add_theme_font_size_override("font_size", 12)
	sub.add_theme_color_override("font_color", C.COLOR_TEXT_DIM)
	hdr_v2.add_child(sub)

	var open_all_btn = Button.new()
	open_all_btn.name = "OpenAllBtn"
	open_all_btn.text = "⚡ Abrir Todos"
	open_all_btn.custom_minimum_size = Vector2(150, 44)
	open_all_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	open_all_btn.add_theme_font_size_override("font_size", 14)
	var oa_st = StyleBoxFlat.new()
	oa_st.bg_color = Color(0.55, 0.35, 0.05, 0.9)
	oa_st.border_color = Color(0.95, 0.72, 0.15, 0.8)
	oa_st.border_width_left = 1; oa_st.border_width_right  = 1
	oa_st.border_width_top  = 1; oa_st.border_width_bottom = 1
	oa_st.corner_radius_top_left    = 10; oa_st.corner_radius_top_right    = 10
	oa_st.corner_radius_bottom_left = 10; oa_st.corner_radius_bottom_right = 10
	var oa_hov = oa_st.duplicate(); oa_hov.bg_color = Color(0.70, 0.48, 0.08, 0.95)
	open_all_btn.add_theme_stylebox_override("normal", oa_st)
	open_all_btn.add_theme_stylebox_override("hover",  oa_hov)
	open_all_btn.add_theme_color_override("font_color", Color(1.0, 0.92, 0.6))
	hdr_h.add_child(open_all_btn)

	var packs_container = HBoxContainer.new()
	packs_container.name = "PacksContainer"
	packs_container.add_theme_constant_override("separation", 32)
	packs_container.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(packs_container)

	_load_pending_packs(content, root, packs_container, open_all_btn, menu)


static func _load_pending_packs(content, root, packs_container, open_all_btn, menu) -> void:
	var C = menu
	var http = HTTPRequest.new()
	content.add_child(http)
	http.request_completed.connect(func(result, code, _h, body):
		http.queue_free()
		if result != HTTPRequest.RESULT_SUCCESS or code != 200: return
		var data = JSON.parse_string(body.get_string_from_utf8())
		if not data: return
		for c in packs_container.get_children(): c.queue_free()
		var packs = data.get("packs", [])
		if packs.size() == 0:
			var e = Label.new()
			e.text = "No tienes sobres sin abrir.\nVisita la Tienda para comprar."
			e.add_theme_color_override("font_color", C.COLOR_TEXT_DIM)
			e.add_theme_font_size_override("font_size", 14)
			e.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			packs_container.add_child(e)
			if is_instance_valid(open_all_btn): open_all_btn.disabled = true
			return

		var all_pack_types: Array = []
		for pi in packs:
			var qty = pi.get("quantity", 0)
			for _i in range(qty):
				all_pack_types.append(pi.get("pack_type", ""))

		for pi in packs:
			_create_pending_pack_card(content, root, packs_container, pi, menu)

		if is_instance_valid(open_all_btn):
			open_all_btn.pressed.connect(func():
				_open_all_packs(root, content, packs_container, open_all_btn, all_pack_types, menu)
			)
	)
	http.request(NetworkManager.BASE_URL + "/api/shop/my-packs",
		["Authorization: Bearer " + NetworkManager.token],
		HTTPClient.METHOD_GET, "")


static func _open_all_packs(root: Control, content: Control, packs_container: Control, btn: Button, pack_types: Array, menu) -> void:
	if pack_types.is_empty(): return
	btn.disabled = true
	btn.text = "Abriendo 0/%d..." % pack_types.size()

	var all_cards: Array = []
	var completed = [0]
	var failed    = [false]
	var batch_size = 10

	var send_batch = func(self_ref: Callable, offset: int) -> void:
		if failed[0]: return
		var batch_end   = min(offset + batch_size, pack_types.size())
		var batch_done  = [0]
		var batch_count = batch_end - offset

		for i in range(offset, batch_end):
			var pack_type = pack_types[i]
			var http = HTTPRequest.new()
			root.add_child(http)
			http.request_completed.connect(func(result, code, _h, body):
				http.queue_free()
				if failed[0]: return
				if result != HTTPRequest.RESULT_SUCCESS or code != 200:
					failed[0] = true
					btn.disabled = false; btn.text = "⚡ Abrir Todos"
					return
				var data = JSON.parse_string(body.get_string_from_utf8())
				if data and data.get("success"):
					var cards = data.get("cards_received", [])
					for card in cards:
						PlayerData.add_card(card)
						all_cards.append(card)
				completed[0] += 1
				batch_done[0] += 1
				btn.text = "Abriendo %d/%d..." % [completed[0], pack_types.size()]

				if batch_done[0] >= batch_count:
					if completed[0] >= pack_types.size():
						_show_open_all_summary(root, menu, all_cards, pack_types.size())
						for c in packs_container.get_children(): c.queue_free()
						var done_lbl = Label.new()
						done_lbl.text = "✅ Todos los sobres abiertos"
						done_lbl.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
						done_lbl.add_theme_font_size_override("font_size", 14)
						done_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
						packs_container.add_child(done_lbl)
						btn.text = "⚡ Abrir Todos"
					else:
						self_ref.call(self_ref, completed[0])
			)
			http.request(NetworkManager.BASE_URL + "/api/shop/open-pack",
				["Content-Type: application/json", "Authorization: Bearer " + NetworkManager.token],
				HTTPClient.METHOD_POST, JSON.stringify({"pack_type": pack_type}))

	send_batch.call(send_batch, 0)


static func _show_open_all_summary(root: Control, menu, all_cards: Array, total_packs: int) -> void:
	var C = menu
	if root.get_node_or_null("OpenAllSummary"): return

	var by_rarity: Dictionary = {}
	var notables: Array = []
	for card_id in all_cards:
		var r = CardDatabase.get_card(card_id).get("rarity", "COMMON")
		by_rarity[r] = by_rarity.get(r, 0) + 1
		if r in ["RARE", "RARE_HOLO", "ULTRA_RARE"]:
			notables.append(card_id)

	var overlay = ColorRect.new()
	overlay.name  = "OpenAllSummary"
	overlay.color = Color(0.02, 0.03, 0.07, 0.96)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 200
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(overlay)

	var scroll = ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	UITheme.apply_scrollbar_theme(scroll)
	overlay.add_child(scroll)

	var center = CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(center)

	var master = VBoxContainer.new()
	master.alignment = BoxContainer.ALIGNMENT_CENTER
	master.add_theme_constant_override("separation", 20)
	center.add_child(master)

	var title = Label.new()
	title.text = "⚡ %d Sobres Abiertos — %d Cartas" % [total_packs, all_cards.size()]
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", C.COLOR_GOLD)
	master.add_child(title)

	var rarity_hbox = HBoxContainer.new()
	rarity_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	rarity_hbox.add_theme_constant_override("separation", 10)
	master.add_child(rarity_hbox)

	for r in ["COMMON", "UNCOMMON", "RARE", "RARE_HOLO", "ULTRA_RARE"]:
		var cnt = by_rarity.get(r, 0)
		if cnt == 0: continue
		# ✅ USA FUNCIÓN LOCAL
		var rc = rarity_color(r)
		var pill = PanelContainer.new()
		var pst = StyleBoxFlat.new()
		pst.bg_color     = Color(rc.r * 0.18, rc.g * 0.18, rc.b * 0.18, 0.9)
		pst.border_color = rc
		pst.border_width_left = 1; pst.border_width_right  = 1
		pst.border_width_top  = 1; pst.border_width_bottom = 1
		pst.corner_radius_top_left    = 8; pst.corner_radius_top_right    = 8
		pst.corner_radius_bottom_left = 8; pst.corner_radius_bottom_right = 8
		pst.content_margin_left = 12; pst.content_margin_right  = 12
		pst.content_margin_top  = 6;  pst.content_margin_bottom = 6
		pill.add_theme_stylebox_override("panel", pst)
		rarity_hbox.add_child(pill)
		var pill_v = VBoxContainer.new()
		pill_v.alignment = BoxContainer.ALIGNMENT_CENTER
		pill_v.add_theme_constant_override("separation", 2)
		pill.add_child(pill_v)
		var rl = Label.new(); rl.text = r.replace("_"," ")
		rl.add_theme_font_size_override("font_size", 10)
		rl.add_theme_color_override("font_color", rc)
		rl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		pill_v.add_child(rl)
		var cl = Label.new(); cl.text = "×" + str(cnt)
		cl.add_theme_font_size_override("font_size", 18)
		cl.add_theme_color_override("font_color", Color.WHITE)
		cl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		pill_v.add_child(cl)

	if notables.size() > 0:
		var notable_title = Label.new()
		notable_title.text = "⭐ Cartas Destacadas"
		notable_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		notable_title.add_theme_font_size_override("font_size", 16)
		notable_title.add_theme_color_override("font_color", C.COLOR_TEXT_DIM)
		master.add_child(notable_title)

		var notable_grid = GridContainer.new()
		notable_grid.columns = mini(notables.size(), 8)
		notable_grid.add_theme_constant_override("h_separation", 10)
		notable_grid.add_theme_constant_override("v_separation", 10)
		master.add_child(notable_grid)

		for card_id in notables:
			var card     = CardDatabase.get_card(card_id)
			var rarr     = card.get("rarity", "COMMON")
			var img_path = LanguageManager.get_card_image(card)
			# ✅ USA FUNCIÓN LOCAL
			var rc       = rarity_color(rarr)

			var slot = PanelContainer.new()
			slot.custom_minimum_size = Vector2(110, 154)
			var sst = StyleBoxFlat.new()
			sst.bg_color     = Color(0.06, 0.07, 0.12, 0.97)
			sst.border_color = rc
			sst.border_width_left = 2; sst.border_width_right  = 2
			sst.border_width_top  = 2; sst.border_width_bottom = 2
			sst.corner_radius_top_left    = 8; sst.corner_radius_top_right    = 8
			sst.corner_radius_bottom_left = 8; sst.corner_radius_bottom_right = 8
			sst.shadow_color = rc; sst.shadow_size = 10
			slot.add_theme_stylebox_override("panel", sst)
			notable_grid.add_child(slot)

			var img = TextureRect.new()
			img.set_anchors_preset(Control.PRESET_FULL_RECT)
			img.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
			img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			var tex = _get_texture(img_path)
			if tex == null and img_path != "": tex = load(img_path)
			img.texture = tex
			slot.add_child(img)

	var close_btn = Button.new()
	close_btn.text = "✅  Añadir a mi Colección"
	close_btn.custom_minimum_size = Vector2(260, 52)
	close_btn.add_theme_font_size_override("font_size", 17)
	var st_c = StyleBoxFlat.new()
	st_c.bg_color = Color(0.08, 0.55, 0.22)
	st_c.corner_radius_top_left    = 10; st_c.corner_radius_top_right    = 10
	st_c.corner_radius_bottom_left = 10; st_c.corner_radius_bottom_right = 10
	var st_c_hov = st_c.duplicate(); st_c_hov.bg_color = Color(0.10, 0.68, 0.28)
	close_btn.add_theme_stylebox_override("normal", st_c)
	close_btn.add_theme_stylebox_override("hover",  st_c_hov)
	close_btn.add_theme_color_override("font_color", Color.WHITE)
	close_btn.pressed.connect(func(): overlay.queue_free())
	master.add_child(close_btn)

	master.modulate.a = 0.0
	master.create_tween().tween_property(master, "modulate:a", 1.0, 0.35).set_trans(Tween.TRANS_CUBIC)


static func _create_pending_pack_card(content, root, parent, pack_info, menu) -> void:
	var C         = menu
	var pack_type = pack_info.get("pack_type", "")
	var qty       = pack_info.get("quantity", 0)
	var name_str  = pack_info.get("name", pack_type)

	var img_map = {
		"typhlosion_pack":           "res://assets/Sobres/SobreFuego.png",
		"feraligatr_pack":           "res://assets/Sobres/SobreAgua.png",
		"meganium_pack":             "res://assets/Sobres/SobreHierba.png",
		"legendary_collection_pack": "res://assets/Sobres/legendary.png",
	}
	var color_map = {
		"typhlosion_pack":           Color(0.85, 0.25, 0.15),
		"feraligatr_pack":           Color(0.20, 0.45, 0.90),
		"meganium_pack":             Color(0.20, 0.75, 0.30),
		"legendary_collection_pack": Color(0.85, 0.70, 0.15),
	}

	var glow     = color_map.get(pack_type, C.COLOR_GOLD)
	var img_path = img_map.get(pack_type, "")

	var box = PanelContainer.new()
	box.custom_minimum_size = Vector2(240, 400)
	var st = StyleBoxFlat.new()
	st.bg_color = Color(0.08, 0.10, 0.16, 0.97)
	st.border_width_left = 2; st.border_width_right  = 2
	st.border_width_top  = 2; st.border_width_bottom = 2
	st.border_color = glow.darkened(0.25)
	st.corner_radius_top_left    = 16; st.corner_radius_top_right    = 16
	st.corner_radius_bottom_left = 16; st.corner_radius_bottom_right = 16
	st.shadow_color = glow; st.shadow_size = 12
	box.add_theme_stylebox_override("panel", st)
	parent.add_child(box)

	box.mouse_entered.connect(func():
		var s = box.get_theme_stylebox("panel").duplicate()
		s.shadow_size = 22; s.border_color = glow
		box.add_theme_stylebox_override("panel", s)
		box.create_tween().tween_property(box, "modulate", Color(1.04, 1.04, 1.04), 0.12)
	)
	box.mouse_exited.connect(func():
		var s = box.get_theme_stylebox("panel").duplicate()
		s.shadow_size = 12; s.border_color = glow.darkened(0.25)
		box.add_theme_stylebox_override("panel", s)
		box.create_tween().tween_property(box, "modulate", Color.WHITE, 0.12)
	)

	var vb = VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 10)
	box.add_child(vb)

	var top_bar = ColorRect.new()
	top_bar.color = glow
	top_bar.custom_minimum_size  = Vector2(0, 3)
	top_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_child(top_bar)

	var img_m = MarginContainer.new()
	img_m.add_theme_constant_override("margin_left",  16)
	img_m.add_theme_constant_override("margin_right", 16)
	img_m.add_theme_constant_override("margin_top",   10)
	vb.add_child(img_m)

	var img = TextureRect.new()
	img.custom_minimum_size = Vector2(170, 220)
	img.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	img.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	img.mouse_filter = Control.MOUSE_FILTER_STOP
	if img_path != "" and ResourceLoader.exists(img_path):
		img.texture = load(img_path)
	img_m.add_child(img)

	img.gui_input.connect(func(ev):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			_show_pack_image_zoom(root, img_path, name_str, glow)
	)

	var zoom_hint = Label.new()
	zoom_hint.text = "🔍 Clic para ampliar"
	zoom_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	zoom_hint.add_theme_font_size_override("font_size", 10)
	zoom_hint.add_theme_color_override("font_color", Color(glow.r, glow.g, glow.b, 0.6))
	vb.add_child(zoom_hint)

	var nl = Label.new()
	nl.text = name_str
	nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nl.add_theme_font_size_override("font_size", 14)
	nl.add_theme_color_override("font_color", C.COLOR_TEXT)
	vb.add_child(nl)

	var qty_pill = PanelContainer.new()
	var qp_st = StyleBoxFlat.new()
	qp_st.bg_color     = Color(glow.r, glow.g, glow.b, 0.18)
	qp_st.border_color = Color(glow.r, glow.g, glow.b, 0.5)
	qp_st.border_width_left = 1; qp_st.border_width_right  = 1
	qp_st.border_width_top  = 1; qp_st.border_width_bottom = 1
	qp_st.corner_radius_top_left    = 20; qp_st.corner_radius_top_right    = 20
	qp_st.corner_radius_bottom_left = 20; qp_st.corner_radius_bottom_right = 20
	qty_pill.add_theme_stylebox_override("panel", qp_st)
	qty_pill.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vb.add_child(qty_pill)

	var ql = Label.new()
	ql.name = "QtyLbl"
	ql.text = "×" + str(qty) + " disponibles"
	ql.add_theme_font_size_override("font_size", 13)
	ql.add_theme_color_override("font_color", glow)
	var ql_m = MarginContainer.new()
	ql_m.add_theme_constant_override("margin_left",  12)
	ql_m.add_theme_constant_override("margin_right", 12)
	ql_m.add_theme_constant_override("margin_top",    4)
	ql_m.add_theme_constant_override("margin_bottom", 4)
	ql_m.add_child(ql)
	qty_pill.add_child(ql_m)

	var btns_m = MarginContainer.new()
	btns_m.add_theme_constant_override("margin_left",  16)
	btns_m.add_theme_constant_override("margin_right", 16)
	btns_m.add_theme_constant_override("margin_bottom",12)
	vb.add_child(btns_m)

	var btns_v = VBoxContainer.new()
	btns_v.add_theme_constant_override("separation", 8)
	btns_m.add_child(btns_v)

	var open_btn = Button.new()
	open_btn.text = "✨  Abrir Sobre"
	open_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	open_btn.custom_minimum_size   = Vector2(0, 44)
	open_btn.add_theme_font_size_override("font_size", 14)
	var st_btn = StyleBoxFlat.new()
	st_btn.bg_color = glow.darkened(0.1)
	st_btn.corner_radius_top_left    = 8; st_btn.corner_radius_top_right    = 8
	st_btn.corner_radius_bottom_left = 8; st_btn.corner_radius_bottom_right = 8
	var st_btn_hov = st_btn.duplicate(); st_btn_hov.bg_color = glow.lightened(0.1)
	open_btn.add_theme_stylebox_override("normal", st_btn)
	open_btn.add_theme_stylebox_override("hover",  st_btn_hov)
	open_btn.add_theme_color_override("font_color", Color.WHITE)
	btns_v.add_child(open_btn)

	var reveal_btn = Button.new()
	reveal_btn.text = "⚡  Revelar Todas (%d)" % qty
	reveal_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reveal_btn.custom_minimum_size   = Vector2(0, 36)
	reveal_btn.add_theme_font_size_override("font_size", 12)
	var st_r = StyleBoxFlat.new()
	st_r.bg_color     = Color(glow.r * 0.3, glow.g * 0.3, glow.b * 0.3, 0.85)
	st_r.border_color = Color(glow.r, glow.g, glow.b, 0.5)
	st_r.border_width_left = 1; st_r.border_width_right  = 1
	st_r.border_width_top  = 1; st_r.border_width_bottom = 1
	st_r.corner_radius_top_left    = 8; st_r.corner_radius_top_right    = 8
	st_r.corner_radius_bottom_left = 8; st_r.corner_radius_bottom_right = 8
	var st_r_hov = st_r.duplicate(); st_r_hov.bg_color = Color(glow.r * 0.45, glow.g * 0.45, glow.b * 0.45, 0.95)
	reveal_btn.add_theme_stylebox_override("normal", st_r)
	reveal_btn.add_theme_stylebox_override("hover",  st_r_hov)
	reveal_btn.add_theme_color_override("font_color", Color(glow.r + 0.3, glow.g + 0.3, glow.b + 0.3, 1.0).clamp())
	btns_v.add_child(reveal_btn)

	var cq = [qty]

	open_btn.pressed.connect(func():
		open_btn.disabled = true
		open_btn.text     = "⏳  Abriendo..."
		ShopScreen.open_pack_from_collection(root, menu, pack_type, func(cards):
			_show_pack_opening(root, menu, cards)
			cq[0] -= 1
			if cq[0] <= 0:
				box.queue_free()
			else:
				ql.text           = "×" + str(cq[0]) + " disponibles"
				reveal_btn.text   = "⚡  Revelar Todas (%d)" % cq[0]
				open_btn.disabled = false
				open_btn.text     = "✨  Abrir Sobre"
		)
	)

	reveal_btn.pressed.connect(func():
		if cq[0] <= 0: return
		open_btn.disabled   = true
		reveal_btn.disabled = true
		reveal_btn.text     = "Abriendo 0/%d..." % cq[0]
		_open_pack_type_silent(root, menu, pack_type, cq[0], cq, ql, open_btn, reveal_btn, box)
	)


static func _open_pack_type_silent(root, menu, pack_type: String, total: int, cq: Array,
		ql: Label, open_btn: Button, reveal_btn: Button, box: Control) -> void:
	var all_cards: Array = []
	var completed = [0]
	var failed    = [false]
	var batch_size = 10

	var send_batch = func(self_ref: Callable, offset: int) -> void:
		if failed[0]: return
		var batch_end   = min(offset + batch_size, total)
		var batch_count = batch_end - offset
		var batch_done  = [0]

		for _i in range(batch_count):
			var http = HTTPRequest.new()
			root.add_child(http)
			http.request_completed.connect(func(result, code, _h, body):
				http.queue_free()
				if failed[0]: return
				if result != HTTPRequest.RESULT_SUCCESS or code != 200:
					failed[0]           = true
					open_btn.disabled   = false
					reveal_btn.disabled = false
					reveal_btn.text     = "⚡  Revelar Todas (%d)" % cq[0]
					return
				var data = JSON.parse_string(body.get_string_from_utf8())
				if data and data.get("success"):
					var cards = data.get("cards_received", [])
					for card in cards:
						PlayerData.add_card(card)
						all_cards.append(card)
				completed[0] += 1
				batch_done[0] += 1
				reveal_btn.text = "Abriendo %d/%d..." % [completed[0], total]

				if batch_done[0] >= batch_count:
					if completed[0] >= total:
						_show_open_all_summary(root, menu, all_cards, total)
						box.queue_free()
					else:
						self_ref.call(self_ref, completed[0])
			)
			http.request(NetworkManager.BASE_URL + "/api/shop/open-pack",
				["Content-Type: application/json", "Authorization: Bearer " + NetworkManager.token],
				HTTPClient.METHOD_POST, JSON.stringify({"pack_type": pack_type}))

	send_batch.call(send_batch, 0)


static func _show_pack_image_zoom(root: Control, img_path: String, label: String, glow: Color) -> void:
	if not img_path or not ResourceLoader.exists(img_path): return
	if root.get_node_or_null("PackImgZoom"): return

	var overlay = ColorRect.new()
	overlay.name = "PackImgZoom"
	overlay.color = Color(0, 0, 0, 0)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 300
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(overlay)
	overlay.create_tween().tween_property(overlay, "color:a", 0.88, 0.18)

	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(center)

	var wrap = VBoxContainer.new()
	wrap.alignment = BoxContainer.ALIGNMENT_CENTER
	wrap.add_theme_constant_override("separation", 16)
	center.add_child(wrap)

	var card_panel = PanelContainer.new()
	var cp_st = StyleBoxFlat.new()
	cp_st.bg_color = Color(0.05, 0.06, 0.09, 0.98)
	cp_st.border_color = glow
	cp_st.border_width_left = 3; cp_st.border_width_right  = 3
	cp_st.border_width_top  = 3; cp_st.border_width_bottom = 3
	cp_st.corner_radius_top_left    = 18; cp_st.corner_radius_top_right    = 18
	cp_st.corner_radius_bottom_left = 18; cp_st.corner_radius_bottom_right = 18
	cp_st.shadow_color = glow; cp_st.shadow_size = 30
	card_panel.add_theme_stylebox_override("panel", cp_st)
	wrap.add_child(card_panel)

	var cp_m = MarginContainer.new()
	cp_m.add_theme_constant_override("margin_left",  20)
	cp_m.add_theme_constant_override("margin_right", 20)
	cp_m.add_theme_constant_override("margin_top",   20)
	cp_m.add_theme_constant_override("margin_bottom",20)
	card_panel.add_child(cp_m)

	var zoom_img = TextureRect.new()
	zoom_img.texture = load(img_path)
	zoom_img.custom_minimum_size = Vector2(320, 420)
	zoom_img.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	zoom_img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	zoom_img.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cp_m.add_child(zoom_img)

	var name_lbl = Label.new()
	name_lbl.text = label
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 16)
	name_lbl.add_theme_color_override("font_color", glow)
	wrap.add_child(name_lbl)

	var hint = Label.new()
	hint.text = "Clic en cualquier lugar para cerrar"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 11)
	hint.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6, 0.8))
	wrap.add_child(hint)

	card_panel.scale        = Vector2(0.5, 0.5)
	card_panel.pivot_offset = Vector2(card_panel.size.x * 0.5, card_panel.size.y * 0.5)
	card_panel.create_tween().tween_property(card_panel, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	overlay.gui_input.connect(func(ev):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			var tc = overlay.create_tween().set_parallel(true)
			tc.tween_property(overlay,    "color:a",    0.0,                 0.15)
			tc.tween_property(card_panel, "scale",      Vector2(0.85, 0.85), 0.15)
			tc.tween_property(card_panel, "modulate:a", 0.0,                 0.15)
			overlay.get_tree().create_timer(0.16).timeout.connect(overlay.queue_free)
	)


# ════════════════════════════════════════════════════════════
# APERTURA DE SOBRE
# ════════════════════════════════════════════════════════════
static func _show_pack_opening(root, menu, cards) -> void:
	var common_cards: Array = []; var rare_card_id = ""; var rare_rarity = "COMMON"
	for card_id in cards:
		var r = CardDatabase.get_card(card_id).get("rarity", "COMMON")
		if r in ["RARE", "RARE_HOLO", "ULTRA_RARE"]:
			# ✅ USA ShopScreen.rarity_weight — esto SÍ pertenece a ShopScreen
			if rare_card_id == "" or ShopScreen.rarity_weight(r) > ShopScreen.rarity_weight(rare_rarity):
				if rare_card_id != "": common_cards.append(rare_card_id)
				rare_card_id = card_id; rare_rarity = r
			else: common_cards.append(card_id)
		else: common_cards.append(card_id)
	if rare_card_id == "":
		rare_card_id = common_cards.pop_back()
		rare_rarity  = CardDatabase.get_card(rare_card_id).get("rarity", "COMMON")

	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0.05, 0.97)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 200
	root.add_child(overlay)

	var scroll = ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	UITheme.apply_scrollbar_theme(scroll)
	overlay.add_child(scroll)

	var center = CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(center)

	var master = VBoxContainer.new()
	master.alignment = BoxContainer.ALIGNMENT_CENTER
	master.add_theme_constant_override("separation", 24)
	center.add_child(master)

	var title_lbl = Label.new()
	title_lbl.name = "PackOpenTitle"
	title_lbl.text = "✨  ¡Toca las cartas para revelarlas!"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 26)
	title_lbl.add_theme_color_override("font_color", Color(0.95, 0.85, 0.5))
	master.add_child(title_lbl)

	var hint_lbl = Label.new()
	hint_lbl.name = "ZoomHint"
	hint_lbl.text = "🔍 Haz clic en una carta revelada para ampliarla"
	hint_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_lbl.add_theme_font_size_override("font_size", 12)
	hint_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7, 0.7))
	hint_lbl.hide()
	master.add_child(hint_lbl)

	var reveal_all_btn = Button.new()
	reveal_all_btn.text = "⚡ Revelar Todas"
	reveal_all_btn.custom_minimum_size   = Vector2(200, 38)
	reveal_all_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	reveal_all_btn.add_theme_font_size_override("font_size", 13)
	var ra_st = StyleBoxFlat.new()
	ra_st.bg_color     = Color(0.45, 0.30, 0.05, 0.9)
	ra_st.border_color = Color(0.9, 0.7, 0.15, 0.7)
	ra_st.border_width_left = 1; ra_st.border_width_right  = 1
	ra_st.border_width_top  = 1; ra_st.border_width_bottom = 1
	ra_st.corner_radius_top_left    = 8; ra_st.corner_radius_top_right    = 8
	ra_st.corner_radius_bottom_left = 8; ra_st.corner_radius_bottom_right = 8
	var ra_hov = ra_st.duplicate(); ra_hov.bg_color = Color(0.60, 0.42, 0.08, 0.95)
	reveal_all_btn.add_theme_stylebox_override("normal", ra_st)
	reveal_all_btn.add_theme_stylebox_override("hover",  ra_hov)
	reveal_all_btn.add_theme_color_override("font_color", Color(1.0, 0.90, 0.55))
	master.add_child(reveal_all_btn)

	var grid = GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 18)
	master.add_child(grid)

	var sep = Label.new()
	sep.text = "▼  CARTA ESPECIAL  ▼"
	sep.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sep.add_theme_font_size_override("font_size", 13)
	sep.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 0.5))
	master.add_child(sep)

	var rare_center = CenterContainer.new()
	master.add_child(rare_center)

	var close_btn = Button.new()
	close_btn.text = "✨  Añadir a mi Colección"
	close_btn.custom_minimum_size = Vector2(260, 52)
	close_btn.hide()
	var st_c = StyleBoxFlat.new()
	st_c.bg_color = Color(0.08, 0.55, 0.22)
	st_c.corner_radius_top_left    = 10; st_c.corner_radius_top_right    = 10
	st_c.corner_radius_bottom_left = 10; st_c.corner_radius_bottom_right = 10
	var st_c_hov = st_c.duplicate(); st_c_hov.bg_color = Color(0.10, 0.68, 0.28)
	close_btn.add_theme_stylebox_override("normal", st_c)
	close_btn.add_theme_stylebox_override("hover",  st_c_hov)
	close_btn.add_theme_font_size_override("font_size", 17)
	close_btn.pressed.connect(func(): overlay.queue_free())
	master.add_child(close_btn)

	var state = {"flipped_common": 0, "total_common": common_cards.size(), "rare_flipped": false}
	var all_slots: Array = []

	for card_id in common_cards:
		var s = _make_card_slot(card_id, overlay, menu, false, state, title_lbl, hint_lbl, close_btn, rare_center, rare_card_id, rare_rarity)
		s.custom_minimum_size = Vector2(128, 178)
		grid.add_child(s)
		all_slots.append({"slot": s, "is_rare": false})

	var rs = _make_card_slot(rare_card_id, overlay, menu, true, state, title_lbl, hint_lbl, close_btn, rare_center, rare_card_id, rare_rarity)
	rs.custom_minimum_size = Vector2(175, 245)
	rs.name         = "RareSlot"
	rs.modulate     = Color(1, 1, 1, 0.35)
	rs.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rare_center.add_child(rs)
	all_slots.append({"slot": rs, "is_rare": true})

	reveal_all_btn.pressed.connect(func():
		reveal_all_btn.disabled = true
		_reveal_all_cards_instant(all_slots, common_cards, rare_card_id, rare_rarity,
			state, rare_center, title_lbl, hint_lbl, close_btn, overlay, menu)
	)

	master.modulate.a = 0.0
	master.create_tween().tween_property(master, "modulate:a", 1.0, 0.4).set_trans(Tween.TRANS_CUBIC)


static func _reveal_all_cards_instant(all_slots: Array, common_cards: Array, rare_card_id: String,
		rare_rarity: String, state: Dictionary, rare_center, title_lbl, hint_lbl, close_btn, overlay, menu) -> void:
	for entry in all_slots:
		if entry["is_rare"]: continue
		var slot     = entry["slot"]
		var children = slot.get_children()
		if children.size() < 3: continue
		children[2].hide()
		children[1].show()
		children[1].modulate = Color.WHITE
		children[1].scale    = Vector2.ONE
		state.flipped_common += 1

	_unlock_rare_slot(rare_center, title_lbl, rare_rarity)

	var tree = overlay.get_tree()
	if tree:
		tree.create_timer(0.35).timeout.connect(func():
			var rs = rare_center.get_node_or_null("RareSlot")
			if not rs: return
			var rc2 = rs.get_children()
			if rc2.size() >= 3:
				rc2[2].hide()
				rc2[1].show()
				rc2[1].modulate = Color.WHITE
				rc2[1].scale    = Vector2.ONE
			rs.mouse_filter  = Control.MOUSE_FILTER_STOP
			state.rare_flipped = true
			ShopScreen.spawn_particles(overlay, rs.position + rs.custom_minimum_size * 0.5, rare_rarity)
			if rare_rarity == "ULTRA_RARE":
				title_lbl.text = "✨  ¡ULTRA RARA!  ✨"
				# ✅ USA FUNCIÓN LOCAL
				title_lbl.add_theme_color_override("font_color", rarity_color("ULTRA_RARE"))
			hint_lbl.show()
			close_btn.show()
		)


static func _make_card_slot(card_id, overlay, menu, is_rare, state, title_lbl, hint_lbl, close_btn, rare_center, rare_card_id, rare_rarity) -> Control:
	var rarity = CardDatabase.get_card(card_id).get("rarity", "COMMON")
	var cn     = ShopScreen.clicks_needed(rarity) if is_rare else 1

	var slot = Control.new()
	slot.pivot_offset = Vector2(64, 89)

	var gr = Panel.new()
	gr.set_anchors_preset(Control.PRESET_FULL_RECT)
	var stg = StyleBoxFlat.new()
	stg.bg_color = Color(0, 0, 0, 0)
	stg.corner_radius_top_left    = 10; stg.corner_radius_top_right    = 10
	stg.corner_radius_bottom_left = 10; stg.corner_radius_bottom_right = 10
	gr.add_theme_stylebox_override("panel", stg)
	gr.hide()
	slot.add_child(gr)

	var front = MiniCard.make(card_id, overlay, menu, -1, -1)
	front.set_anchors_preset(Control.PRESET_FULL_RECT)
	front.pivot_offset = Vector2(64, 89)
	front.scale.x = 0.0
	front.hide()
	slot.add_child(front)

	var back = TextureRect.new()
	back.texture     = load("res://assets/imagen/back.jpg")
	back.set_anchors_preset(Control.PRESET_FULL_RECT)
	back.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	back.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	back.pivot_offset = Vector2(64, 89)
	back.mouse_filter = Control.MOUSE_FILTER_STOP
	back.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	slot.add_child(back)

	var cl = Label.new()
	cl.text = ""; cl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cl.set_anchors_preset(Control.PRESET_FULL_RECT)
	cl.add_theme_font_size_override("font_size", 22)
	cl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cl.hide()
	slot.add_child(cl)

	var ss = {"clicks": 0, "flipped": false}

	back.gui_input.connect(func(ev):
		if not (ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT): return
		if ss.flipped: return
		ss.clicks += 1

		if rarity == "ULTRA_RARE" and ss.clicks < cn:
			var cc = ShopScreen.ULTRA_RARE_CHARGE_COLORS[min(ss.clicks - 1, 5)]
			var tp = back.create_tween()
			tp.tween_property(back, "modulate", Color(cc.r * 2, cc.g * 2, cc.b * 2, 1), 0.08)
			tp.tween_property(back, "modulate", Color.WHITE, 0.15)
			var orig = slot.position
			var ts = slot.create_tween()
			for _x in range(3):
				ts.tween_property(slot, "position", orig + Vector2(randf_range(-6, 6), randf_range(-5, 5)), 0.04)
			ts.tween_property(slot, "position", orig, 0.04)
			cl.show()
			cl.text = "●".repeat(ss.clicks) + "○".repeat(cn - ss.clicks - 1)
			cl.add_theme_color_override("font_color", cc)
			gr.show(); stg.shadow_color = cc; stg.shadow_size = 12 + ss.clicks * 10
			return

		ss.flipped = true
		cl.hide()
		back.mouse_default_cursor_shape = Control.CURSOR_ARROW

		var tw = slot.create_tween()
		tw.tween_property(back, "scale:x", 0.0, 0.10).set_trans(Tween.TRANS_SINE)
		tw.tween_callback(func():
			back.hide(); front.show(); cl.hide()

			if rarity in ["RARE", "RARE_HOLO", "ULTRA_RARE"]:
				# ✅ USA FUNCIÓN LOCAL
				var rc = rarity_color(rarity)
				gr.show()
				stg.shadow_color = rc
				stg.shadow_size  = 22 if rarity == "RARE" else (40 if rarity == "RARE_HOLO" else 65)
				var tg = gr.create_tween().set_loops()
				tg.tween_property(stg, "shadow_size", int(stg.shadow_size * 1.5), 0.7)
				tg.tween_property(stg, "shadow_size", stg.shadow_size, 0.7)

				var pop = Vector2(1.14, 1.14)
				if rarity == "RARE_HOLO":  pop = Vector2(1.22, 1.22)
				if rarity == "ULTRA_RARE": pop = Vector2(1.38, 1.38)
				front.scale = pop
				front.create_tween().tween_property(front, "scale", Vector2.ONE, 0.55).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
				ShopScreen.spawn_particles(overlay, slot.position + slot.custom_minimum_size * 0.5, rarity)

				if rarity == "ULTRA_RARE":
					var fl = ColorRect.new()
					fl.color = Color(1, 1, 1, 0)
					fl.set_anchors_preset(Control.PRESET_FULL_RECT)
					fl.z_index = 300; fl.mouse_filter = Control.MOUSE_FILTER_IGNORE
					overlay.add_child(fl)
					var tf = fl.create_tween()
					tf.tween_property(fl, "color:a", 0.80, 0.08)
					tf.tween_property(fl, "color:a", 0.0,  0.38)
					tf.tween_callback(fl.queue_free)
					title_lbl.text = "✨  ¡ULTRA RARA!  ✨"
					# ✅ USA FUNCIÓN LOCAL
					title_lbl.add_theme_color_override("font_color", rarity_color("ULTRA_RARE"))

			front.mouse_filter = Control.MOUSE_FILTER_STOP
			front.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			front.gui_input.connect(func(fev):
				if fev is InputEventMouseButton and fev.pressed and fev.button_index == MOUSE_BUTTON_LEFT:
					_show_revealed_card_zoom(overlay, card_id, rarity, menu)
			)
			if is_instance_valid(hint_lbl) and hint_lbl.is_inside_tree():
				hint_lbl.show()
		)
		tw.tween_property(front, "scale:x", 1.0, 0.12).set_trans(Tween.TRANS_SINE)

		if not is_rare:
			state.flipped_common += 1
			if state.flipped_common == state.total_common:
				_unlock_rare_slot(rare_center, title_lbl, rare_rarity)
		else:
			state.rare_flipped = true
			close_btn.show()
			close_btn.create_tween().tween_property(close_btn, "modulate:a", 1.0, 0.4)
	)
	return slot


static func _show_revealed_card_zoom(overlay: Control, card_id: String, rarity: String, menu) -> void:
	if overlay.get_node_or_null("RevealedZoom"): return

	var card     = CardDatabase.get_card(card_id)
	var img_path = LanguageManager.get_card_image(card)
	# ✅ USA FUNCIÓN LOCAL
	var rc       = rarity_color(rarity)

	var zoom_overlay = ColorRect.new()
	zoom_overlay.name  = "RevealedZoom"
	zoom_overlay.color = Color(0, 0, 0, 0)
	zoom_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	zoom_overlay.z_index      = 400
	zoom_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(zoom_overlay)
	zoom_overlay.create_tween().tween_property(zoom_overlay, "color:a", 0.82, 0.15)

	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	zoom_overlay.add_child(center)

	var wrap = VBoxContainer.new()
	wrap.alignment = BoxContainer.ALIGNMENT_CENTER
	wrap.add_theme_constant_override("separation", 18)
	center.add_child(wrap)

	var cpanel = PanelContainer.new()
	var cp_st = StyleBoxFlat.new()
	cp_st.bg_color     = Color(0.04, 0.05, 0.08, 0.99)
	cp_st.border_color = rc
	cp_st.border_width_left = 3; cp_st.border_width_right  = 3
	cp_st.border_width_top  = 3; cp_st.border_width_bottom = 3
	cp_st.corner_radius_top_left    = 20; cp_st.corner_radius_top_right    = 20
	cp_st.corner_radius_bottom_left = 20; cp_st.corner_radius_bottom_right = 20
	cp_st.shadow_color = rc; cp_st.shadow_size = 40
	cpanel.add_theme_stylebox_override("panel", cp_st)
	wrap.add_child(cpanel)

	var cp_m = MarginContainer.new()
	cp_m.add_theme_constant_override("margin_left",  18)
	cp_m.add_theme_constant_override("margin_right", 18)
	cp_m.add_theme_constant_override("margin_top",   18)
	cp_m.add_theme_constant_override("margin_bottom",18)
	cpanel.add_child(cp_m)

	var zoom_img = TextureRect.new()
	var tex = _get_texture(img_path)
	if tex == null and img_path != "": tex = load(img_path)
	zoom_img.texture = tex
	zoom_img.custom_minimum_size = Vector2(300, 420)
	zoom_img.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	zoom_img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	zoom_img.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cp_m.add_child(zoom_img)

	var info_v = VBoxContainer.new()
	info_v.alignment = BoxContainer.ALIGNMENT_CENTER
	info_v.add_theme_constant_override("separation", 4)
	wrap.add_child(info_v)

	var name_lbl = Label.new()
	name_lbl.text = card.get("name", card_id)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 18)
	name_lbl.add_theme_color_override("font_color", rc)
	info_v.add_child(name_lbl)

	var detail_lbl = Label.new()
	detail_lbl.text = rarity.replace("_", " ") + "  ·  " + card.get("number", "?")
	detail_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail_lbl.add_theme_font_size_override("font_size", 12)
	detail_lbl.add_theme_color_override("font_color", Color(0.55, 0.55, 0.65))
	info_v.add_child(detail_lbl)

	var close_hint = Label.new()
	close_hint.text = "Clic para cerrar"
	close_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	close_hint.add_theme_font_size_override("font_size", 11)
	close_hint.add_theme_color_override("font_color", Color(0.4, 0.4, 0.5, 0.7))
	wrap.add_child(close_hint)

	cpanel.scale        = Vector2(0.45, 0.45)
	cpanel.pivot_offset = cpanel.size * 0.5
	cpanel.create_tween().tween_property(cpanel, "scale", Vector2.ONE, 0.30).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	zoom_overlay.gui_input.connect(func(ev):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			var tc = zoom_overlay.create_tween().set_parallel(true)
			tc.tween_property(zoom_overlay, "color:a",    0.0,                 0.14)
			tc.tween_property(cpanel,       "scale",      Vector2(0.85, 0.85), 0.14)
			tc.tween_property(cpanel,       "modulate:a", 0.0,                 0.14)
			zoom_overlay.get_tree().create_timer(0.15).timeout.connect(zoom_overlay.queue_free)
	)


static func _unlock_rare_slot(rare_center, title_lbl, rare_rarity) -> void:
	var rs = rare_center.get_node_or_null("RareSlot")
	if not rs: return
	var tx = {"RARE": "⭐ ¡Carta Rara!", "RARE_HOLO": "💫 ¡Holográfica!", "ULTRA_RARE": "🔥 ¡ULTRA RARA!"}
	title_lbl.text = tx.get(rare_rarity, "¡Revela!")
	# ✅ USA FUNCIÓN LOCAL
	title_lbl.add_theme_color_override("font_color", rarity_color(rare_rarity))
	rs.mouse_filter = Control.MOUSE_FILTER_STOP
	var tw = rs.create_tween().set_parallel(true)
	tw.tween_property(rs, "modulate:a", 1.0,              0.5).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(rs, "scale",      Vector2(1.10, 1.10), 0.25).set_trans(Tween.TRANS_BACK)
	tw.tween_property(rs, "scale",      Vector2.ONE,         0.25).set_trans(Tween.TRANS_BACK).set_delay(0.25)


# ════════════════════════════════════════════════════════════
# TAB: MAZOS
# ════════════════════════════════════════════════════════════
static func _build_decks_tab(content: Control, menu) -> void:
	var C = menu
	var mm = MarginContainer.new(); mm.set_anchors_preset(Control.PRESET_FULL_RECT)
	mm.add_theme_constant_override("margin_left",  40)
	mm.add_theme_constant_override("margin_right", 40)
	mm.add_theme_constant_override("margin_top",   20)
	content.add_child(mm)
	var vbox = VBoxContainer.new(); vbox.add_theme_constant_override("separation", 16); mm.add_child(vbox)
	var t = Label.new(); t.text = "📋 MIS MAZOS"
	t.add_theme_font_size_override("font_size", 16); t.add_theme_color_override("font_color", C.COLOR_GOLD); vbox.add_child(t)
	if PlayerData.decks.is_empty():
		var e = Label.new(); e.text = "No tienes mazos.\nCrea uno en el Constructor de Mazo."
		e.add_theme_color_override("font_color", C.COLOR_TEXT_DIM); e.add_theme_font_size_override("font_size", 14); vbox.add_child(e); return
	var grid = GridContainer.new(); grid.columns = 3
	grid.add_theme_constant_override("h_separation", 16); grid.add_theme_constant_override("v_separation", 16); vbox.add_child(grid)
	for slot in PlayerData.decks.keys():
		var dd = PlayerData.decks[slot]; var dn = dd.get("name", "Mazo " + str(slot)); var dc = dd.get("cards", [])
		var box = PanelContainer.new(); box.custom_minimum_size = Vector2(240, 120)
		var st = StyleBoxFlat.new()
		st.bg_color     = Color(C.COLOR_PANEL.r, C.COLOR_PANEL.g, C.COLOR_PANEL.b, 0.9)
		st.border_color = C.COLOR_GOLD_DIM
		st.border_width_left = 1; st.border_width_right  = 1
		st.border_width_top  = 1; st.border_width_bottom = 1
		st.corner_radius_top_left    = 10; st.corner_radius_top_right    = 10
		st.corner_radius_bottom_left = 10; st.corner_radius_bottom_right = 10
		box.add_theme_stylebox_override("panel", st); grid.add_child(box)
		var bv = VBoxContainer.new(); bv.alignment = BoxContainer.ALIGNMENT_CENTER; bv.add_theme_constant_override("separation", 6); box.add_child(bv)
		var nl = Label.new(); nl.text = "🃏 " + dn; nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nl.add_theme_font_size_override("font_size", 14); nl.add_theme_color_override("font_color", C.COLOR_GOLD); bv.add_child(nl)
		var cl2 = Label.new(); cl2.text = str(dc.size()) + " / 60 cartas"; cl2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cl2.add_theme_font_size_override("font_size", 12)
		cl2.add_theme_color_override("font_color", C.COLOR_GREEN if dc.size() == 60 else C.COLOR_TEXT_DIM); bv.add_child(cl2)


# ════════════════════════════════════════════════════════════
# TAB: ESTADÍSTICAS
# ════════════════════════════════════════════════════════════
static func _build_stats_tab(content: Control, menu) -> void:
	var C = menu; var inv = PlayerData.inventory
	var mm = MarginContainer.new(); mm.set_anchors_preset(Control.PRESET_FULL_RECT)
	mm.add_theme_constant_override("margin_left",  40)
	mm.add_theme_constant_override("margin_right", 40)
	mm.add_theme_constant_override("margin_top",   20)
	content.add_child(mm)
	var scroll = ScrollContainer.new(); scroll.set_anchors_preset(Control.PRESET_FULL_RECT); mm.add_child(scroll)
	var vbox = VBoxContainer.new(); vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL; vbox.add_theme_constant_override("separation", 24); scroll.add_child(vbox)
	var t = Label.new(); t.text = "📊 ESTADÍSTICAS"; t.add_theme_font_size_override("font_size", 16); t.add_theme_color_override("font_color", C.COLOR_GOLD); vbox.add_child(t)
	var total_unique = CardDatabase.get_all_ids().size(); var owned_unique = inv.size(); var total_cards = 0; var by_rarity: Dictionary = {}
	for id in inv.keys():
		var q = inv[id]; total_cards += q; var r = CardDatabase.get_card(id).get("rarity", "COMMON"); by_rarity[r] = by_rarity.get(r, 0) + q
	var shb = HBoxContainer.new(); shb.add_theme_constant_override("separation", 16); vbox.add_child(shb)
	for pair in [["📚 Únicas", str(owned_unique) + " / " + str(total_unique), C.COLOR_ACCENT], ["🃏 Total", str(total_cards), C.COLOR_GOLD], ["🪙 Monedas", str(PlayerData.coins), C.COLOR_GREEN], ["⚔️ ELO", str(PlayerData.elo), C.COLOR_TEXT]]:
		var box = PanelContainer.new(); box.custom_minimum_size = Vector2(150, 80)
		var st = StyleBoxFlat.new(); st.bg_color = Color(C.COLOR_PANEL.r, C.COLOR_PANEL.g, C.COLOR_PANEL.b, 0.9); st.border_color = pair[2]; st.border_width_bottom = 3
		st.corner_radius_top_left = 8; st.corner_radius_top_right = 8; st.corner_radius_bottom_left = 8; st.corner_radius_bottom_right = 8
		box.add_theme_stylebox_override("panel", st); shb.add_child(box)
		var bv = VBoxContainer.new(); bv.alignment = BoxContainer.ALIGNMENT_CENTER; box.add_child(bv)
		var l1 = Label.new(); l1.text = pair[0]; l1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; l1.add_theme_font_size_override("font_size", 11); l1.add_theme_color_override("font_color", C.COLOR_TEXT_DIM); bv.add_child(l1)
		var l2 = Label.new(); l2.text = pair[1]; l2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; l2.add_theme_font_size_override("font_size", 20); l2.add_theme_color_override("font_color", pair[2]); bv.add_child(l2)
	var et = Label.new(); et.text = "Por Expansión"; et.add_theme_font_size_override("font_size", 14); et.add_theme_color_override("font_color", C.COLOR_TEXT_DIM); vbox.add_child(et)
	var ehb = HBoxContainer.new(); ehb.add_theme_constant_override("separation", 16); vbox.add_child(ehb)
	for exp_data in EXPANSIONS:
		if not exp_data["active"]: continue
		var eids = _get_ids_for_expansion(exp_data["id"]); var eown = 0
		for id in eids:
			if inv.has(id): eown += 1
		var pct = int(float(eown) / max(eids.size(), 1) * 100)
		var ebox = PanelContainer.new(); ebox.custom_minimum_size = Vector2(180, 90)
		var est = StyleBoxFlat.new(); est.bg_color = Color(0.08, 0.10, 0.15, 0.9); est.border_color = C.COLOR_GOLD_DIM
		est.border_width_left = 1; est.border_width_right = 1; est.border_width_top = 1; est.border_width_bottom = 1
		est.corner_radius_top_left = 8; est.corner_radius_top_right = 8; est.corner_radius_bottom_left = 8; est.corner_radius_bottom_right = 8
		ebox.add_theme_stylebox_override("panel", est); ehb.add_child(ebox)
		var ev = VBoxContainer.new(); ev.alignment = BoxContainer.ALIGNMENT_CENTER; ebox.add_child(ev)
		var en = Label.new(); en.text = exp_data["label"]; en.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; en.add_theme_font_size_override("font_size", 11); en.add_theme_color_override("font_color", C.COLOR_GOLD); ev.add_child(en)
		var ep = Label.new(); ep.text = str(eown) + " / " + str(eids.size()) + " (" + str(pct) + "%)"; ep.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; ep.add_theme_font_size_override("font_size", 14)
		ep.add_theme_color_override("font_color", C.COLOR_GREEN if pct == 100 else C.COLOR_TEXT); ev.add_child(ep)
		var pb = ProgressBar.new(); pb.min_value = 0; pb.max_value = eids.size(); pb.value = eown; pb.custom_minimum_size = Vector2(150, 10); pb.size_flags_horizontal = Control.SIZE_SHRINK_CENTER; ev.add_child(pb)
	var rt = Label.new(); rt.text = "Por Rareza"; rt.add_theme_font_size_override("font_size", 14); rt.add_theme_color_override("font_color", C.COLOR_TEXT_DIM); vbox.add_child(rt)
	var rhb = HBoxContainer.new(); rhb.add_theme_constant_override("separation", 12); vbox.add_child(rhb)
	for r in ["COMMON", "UNCOMMON", "RARE", "RARE_HOLO", "ULTRA_RARE"]:
		var cnt = by_rarity.get(r, 0)
		# ✅ USA FUNCIÓN LOCAL
		var rc = rarity_color(r)
		var rb = PanelContainer.new(); rb.custom_minimum_size = Vector2(120, 60)
		var rst = StyleBoxFlat.new(); rst.bg_color = Color(rc.r * 0.15, rc.g * 0.15, rc.b * 0.15, 0.9); rst.border_color = rc; rst.border_width_left = 2
		rst.corner_radius_top_left = 6; rst.corner_radius_top_right = 6; rst.corner_radius_bottom_left = 6; rst.corner_radius_bottom_right = 6
		rb.add_theme_stylebox_override("panel", rst); rhb.add_child(rb)
		var rv = VBoxContainer.new(); rv.alignment = BoxContainer.ALIGNMENT_CENTER; rb.add_child(rv)
		var rl1 = Label.new(); rl1.text = r.replace("_", " "); rl1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; rl1.add_theme_font_size_override("font_size", 10); rl1.add_theme_color_override("font_color", rc); rv.add_child(rl1)
		var rl2 = Label.new(); rl2.text = str(cnt); rl2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; rl2.add_theme_font_size_override("font_size", 18); rl2.add_theme_color_override("font_color", rc); rv.add_child(rl2)
		
		# ════════════════════════════════════════════════════════════
# TAB: MONEDAS
# ════════════════════════════════════════════════════════════
static func _build_coins_tab(content: Control, menu) -> void:
	var C = menu
	var mm = MarginContainer.new()
	mm.set_anchors_preset(Control.PRESET_FULL_RECT)
	mm.add_theme_constant_override("margin_left",  40)
	mm.add_theme_constant_override("margin_right", 40)
	mm.add_theme_constant_override("margin_top",   20)
	content.add_child(mm)

	var scroll = ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	UITheme.apply_scrollbar_theme(scroll)
	mm.add_child(scroll)

	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 24)
	scroll.add_child(vbox)

	var t = Label.new()
	t.text = "🪙 MIS MONEDAS"
	t.add_theme_font_size_override("font_size", 16)
	t.add_theme_color_override("font_color", C.COLOR_GOLD)
	vbox.add_child(t)

	var grid = GridContainer.new()
	grid.name = "MyCoinsGrid"
	grid.columns = 5
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 20)
	grid.add_theme_constant_override("v_separation", 20)
	vbox.add_child(grid)

	_fetch_my_coins(content, menu, grid)


static func _fetch_my_coins(collection_root: Control, menu, grid: Control) -> void:
	var loading = Label.new()
	loading.text = "Cargando mis monedas..."
	loading.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	grid.add_child(loading)

	var http = HTTPRequest.new()
	collection_root.add_child(http)

	http.request_completed.connect(func(result, code, _h, body):
		http.queue_free()
		loading.queue_free()
		if result != HTTPRequest.RESULT_SUCCESS or code != 200:
			var err = Label.new()
			err.text = "⚠ Error al cargar monedas"
			err.add_theme_color_override("font_color", Color(0.8, 0.3, 0.3))
			grid.add_child(err)
			return

		var data = JSON.parse_string(body.get_string_from_utf8())
		if not data: return

		var has_coins = false
		for coin in data.get("coins", []):
			if coin.get("owned", false) or coin.get("equipped", false):
				has_coins = true
				_create_collection_coin_card(collection_root, menu, grid, coin)

		if not has_coins:
			var empty_msg = Label.new()
			empty_msg.text = "Aún no tienes monedas personalizadas."
			empty_msg.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
			grid.add_child(empty_msg)
	)

	http.request(
		NetworkManager.BASE_URL + "/api/shop/coins",
		["Authorization: Bearer " + NetworkManager.token],
		HTTPClient.METHOD_GET, ""
	)


static func _create_collection_coin_card(collection_root: Control, menu, parent: Control, coin: Dictionary) -> void:
	var equipped = coin.get("equipped", false)
	var coin_id  = coin.get("id", "")
	var coin_name = coin.get("name", "Moneda")
	var glow     = Color(0.95, 0.78, 0.2)

	var box = PanelContainer.new()
	box.custom_minimum_size = Vector2(170, 180)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var st = StyleBoxFlat.new()
	st.bg_color = Color(0.08, 0.09, 0.15, 0.97)
	st.border_width_left = 1; st.border_width_right = 1
	st.border_width_top  = 1; st.border_width_bottom = 1
	st.corner_radius_top_left = 16; st.corner_radius_top_right = 16
	st.corner_radius_bottom_left = 16; st.corner_radius_bottom_right = 16

	if equipped:
		st.border_color = glow
		st.shadow_color = Color(glow.r, glow.g, glow.b, 0.40)
		st.shadow_size  = 14
	else:
		st.border_color = Color(0.18, 0.42, 0.18, 0.55)

	box.add_theme_stylebox_override("panel", st)
	parent.add_child(box)

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 10)
	box.add_child(vbox)

	var top_strip = ColorRect.new()
	top_strip.custom_minimum_size = Vector2(0, 5)
	top_strip.color = glow if equipped else Color(0.28, 0.58, 0.28)
	vbox.add_child(top_strip)

	# --- Carga de Imagen ---
	var file_front = coin.get("file_front", "ENERGY-SMALL-SILVER-NON.png")
	var img_path = "res://assets/imagen/tokens/TCG Flip Coins/CoinFont/" + file_front
	var icon_rect = TextureRect.new()
	icon_rect.custom_minimum_size = Vector2(70, 70)
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(icon_rect)

	if file_front != "":
		ShopScreen._load_texture_into(icon_rect, img_path)

	var name_lbl = Label.new()
	name_lbl.text = coin_name
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 13)
	name_lbl.add_theme_color_override("font_color", glow if equipped else Color(0.8, 0.8, 0.8))
	vbox.add_child(name_lbl)

	var m = MarginContainer.new()
	m.add_theme_constant_override("margin_left", 16)
	m.add_theme_constant_override("margin_right", 16)
	m.add_theme_constant_override("margin_bottom", 16)
	vbox.add_child(m)

	var btn: Button
	if equipped:
		btn = ShopScreen._make_buy_button("Desequipar", Color(0.8, 0.3, 0.3))
		# Enviar 'default' en lugar de string vacío para evitar bugs en el backend
		btn.pressed.connect(func(): _equip_or_unequip(collection_root, menu, "default", box, st, btn, parent))
	else:
		btn = ShopScreen._make_buy_button("Equipar", Color(0.4, 0.75, 0.4))
		btn.pressed.connect(func(): _equip_or_unequip(collection_root, menu, coin_id, box, st, btn, parent))

	m.add_child(btn)


static func _equip_or_unequip(collection_root: Control, menu, coin_id: String, box: PanelContainer, st: StyleBoxFlat, btn: Button, grid: Control) -> void:
	var http = HTTPRequest.new()
	collection_root.add_child(http)

	http.request_completed.connect(func(result, code, _h, body):
		http.queue_free()
		if result == HTTPRequest.RESULT_SUCCESS and code == 200:
			var msg = "✨ Moneda equipada" if coin_id != "default" else "Moneda desequipada"
			ShopScreen._show_toast(collection_root, msg, Color(0.95, 0.78, 0.2))
			
			# Guardado local
			PlayerData.set("equipped_coin", coin_id)
			
			# Refrescar vista
			for child in grid.get_children():
				child.queue_free()
			_fetch_my_coins(collection_root, menu, grid)
		else:
			ShopScreen._show_toast(collection_root, "⚠ Error de red", Color(0.8, 0.2, 0.2))
	)

	http.request(
		NetworkManager.BASE_URL + "/api/shop/equip-coin",
		["Content-Type: application/json", "Authorization: Bearer " + NetworkManager.token],
		HTTPClient.METHOD_POST,
		JSON.stringify({"coin_id": coin_id})
	)
