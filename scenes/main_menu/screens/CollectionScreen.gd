extends Node

# ============================================================
# CollectionScreen.gd — con cache + threaded loading
# ============================================================

const ShopScreen = preload("res://scenes/main_menu/screens/ShopScreen.gd")
const MiniCard   = preload("res://scenes/main_menu/components/MiniCard.gd")

enum Tab { CARDS, PACKS, DECKS, STATS }

const EXPANSIONS = [
	{"id":"Neo Genesis",   "label":"Neo Genesis",   "logo":"res://assets/imagen/ExpNeoGenesis/Neo Genesis.png",   "total":111, "active":true},
	{"id":"Neo Discovery", "label":"Neo Discovery", "logo":"res://assets/imagen/ExpNeoGenesis/Neo Discovery.png", "total":75,  "active":false},
	{"id":"Neo Revelation","label":"Neo Revelation","logo":"res://assets/imagen/ExpNeoGenesis/Neo Revelation.png","total":66,  "active":false},
	{"id":"Neo Destiny",   "label":"Neo Destiny",   "logo":"res://assets/imagen/ExpNeoGenesis/Neo Destiny.png",   "total":113, "active":false},
]

# ── Cache estático — se llena una sola vez por sesión ────────
static var _exp_cache:    Dictionary = {}   # { "Neo Genesis": [id, id, ...] }
static var _tex_cache:    Dictionary = {}   # { "res://path": Texture2D }
static var _tex_cache_order: Array = []        # orden de inserción para LRU
const TEX_CACHE_MAX = 500
static var _pending_load: Array      = []   # paths pendientes de carga threaded
static var _load_timer:   float      = 0.0

const BATCH_SIZE     = 20     # slots que se crean por frame
const SCROLL_AHEAD   = 3      # filas extra a precargar fuera de vista


# ─── Detecta expansión por image path ───────────────────────
static func _get_expansion(card: Dictionary) -> String:
	var img = card.get("image","")
	for exp in EXPANSIONS:
		if exp["id"] in img:
			return exp["id"]
	return "Unknown"


# ─── Llena el caché de expansiones (solo una vez) ────────────
static func _ensure_exp_cache() -> void:
	if not _exp_cache.is_empty(): return
	for exp in EXPANSIONS:
		_exp_cache[exp["id"]] = []
	for id in CardDatabase.get_all_ids():
		var card   = CardDatabase.get_card(id)
		var exp_id = _get_expansion(card)
		if exp_id in _exp_cache:
			_exp_cache[exp_id].append(id)
	# Ordenar cada lista por número de carta
	for exp_id in _exp_cache:
		_exp_cache[exp_id].sort_custom(func(a, b):
			var na = CardDatabase.get_card(a).get("number","999/999").split("/")[0].to_int()
			var nb = CardDatabase.get_card(b).get("number","999/999").split("/")[0].to_int()
			return na < nb
		)


static func _get_ids_for_expansion(exp_id: String) -> Array:
	_ensure_exp_cache()
	return _exp_cache.get(exp_id, [])


# ─── Cache LRU: máximo TEX_CACHE_MAX texturas ───────────────
static func _cache_texture(path: String, tex: Texture2D) -> void:
	if path in _tex_cache:
		# Mover al final (más reciente)
		_tex_cache_order.erase(path)
		_tex_cache_order.append(path)
		return
	# Evictar el más antiguo si se supera el límite
	while _tex_cache_order.size() >= TEX_CACHE_MAX:
		var oldest = _tex_cache_order.pop_front()
		_tex_cache.erase(oldest)
	_tex_cache[path] = tex
	_tex_cache_order.append(path)


# ─── Carga de textura: cache primero, luego threaded ─────────
static func _get_texture(path: String) -> Texture2D:
	if path == "": return null
	if path in _tex_cache: return _tex_cache[path]
	# Intentar desde el caché de ResourceLoader
	var status = ResourceLoader.load_threaded_get_status(path)
	if status == ResourceLoader.THREAD_LOAD_LOADED:
		var tex = ResourceLoader.load_threaded_get(path)
		_cache_texture(path, tex)
		return tex
	# No está listo aún — devolver null (se rellenará después)
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
	_ensure_exp_cache()  # precalentar caché al entrar

	var root = Control.new()
	root.name = "CollRoot"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	container.add_child(root)

	# ── Fondo ────────────────────────────────────────────────
	var bg = TextureRect.new()
	var bg_tex = load("res://assets/imagen/fondomenu.png")
	if bg_tex: bg.texture = bg_tex
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.modulate = Color(0.15, 0.15, 0.15, 1)
	root.add_child(bg)

	# ── Header ───────────────────────────────────────────────
	var header = Panel.new()
	header.anchor_left = 0; header.anchor_right  = 1
	header.anchor_top  = 0; header.anchor_bottom = 0
	header.offset_top  = 50; header.offset_bottom = 130
	var hs = StyleBoxFlat.new()
	hs.bg_color    = Color(C.COLOR_PANEL.r, C.COLOR_PANEL.g, C.COLOR_PANEL.b, 0.85)
	hs.border_color = Color(C.COLOR_GOLD_DIM.r, C.COLOR_GOLD_DIM.g, C.COLOR_GOLD_DIM.b, 0.3)
	hs.border_width_bottom = 1
	header.add_theme_stylebox_override("panel", hs)
	root.add_child(header)

	var hdr_v = VBoxContainer.new()
	hdr_v.set_anchors_preset(Control.PRESET_FULL_RECT)
	hdr_v.add_theme_constant_override("separation", 4)
	header.add_child(hdr_v)

	var row1 = HBoxContainer.new()
	row1.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hdr_v.add_child(row1)

	var accent = ColorRect.new()
	accent.color = C.COLOR_ACCENT
	accent.custom_minimum_size = Vector2(6, 0)
	row1.add_child(accent)

	var title_m = MarginContainer.new()
	title_m.add_theme_constant_override("margin_left", 16)
	title_m.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row1.add_child(title_m)

	var title_lbl = Label.new()
	title_lbl.text = "📚 MI COLECCIÓN"
	title_lbl.add_theme_font_size_override("font_size", 18)
	title_lbl.add_theme_color_override("font_color", C.COLOR_GOLD)
	title_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_m.add_child(title_lbl)

	var total_unique = CardDatabase.get_all_ids().size()
	var owned_unique = PlayerData.inventory.size()

	var progress_lbl = Label.new()
	progress_lbl.name = "ProgressLbl"
	progress_lbl.text = str(owned_unique) + " / " + str(total_unique) + " cartas"
	progress_lbl.add_theme_font_size_override("font_size", 13)
	progress_lbl.add_theme_color_override("font_color", C.COLOR_TEXT_DIM)
	progress_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row1.add_child(progress_lbl)

	var prog_m = MarginContainer.new()
	prog_m.add_theme_constant_override("margin_right", 24)
	prog_m.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row1.add_child(prog_m)

	var prog_bar = ProgressBar.new()
	prog_bar.min_value = 0; prog_bar.max_value = total_unique; prog_bar.value = owned_unique
	prog_bar.custom_minimum_size = Vector2(180, 14)
	prog_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	prog_m.add_child(prog_bar)

	var tabs_m = MarginContainer.new()
	tabs_m.add_theme_constant_override("margin_left", 26)
	tabs_m.add_theme_constant_override("margin_bottom", 6)
	hdr_v.add_child(tabs_m)

	var tabs_hbox = HBoxContainer.new()
	tabs_hbox.add_theme_constant_override("separation", 4)
	tabs_m.add_child(tabs_hbox)

	var tab_labels = ["🃏  Cartas", "📦  Sobres", "📋  Mazos", "📊  Estadísticas"]
	var tab_btns: Array = []
	for i in range(tab_labels.size()):
		var tb = Button.new()
		tb.text = tab_labels[i]
		tb.custom_minimum_size = Vector2(130, 30)
		tb.add_theme_font_size_override("font_size", 12)
		tabs_hbox.add_child(tb)
		tab_btns.append(tb)

	var content = Control.new()
	content.name = "ContentArea"
	content.anchor_left = 0; content.anchor_right  = 1
	content.anchor_top  = 0; content.anchor_bottom = 1
	content.offset_top  = 140; content.offset_bottom = -10
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
			btns[i].add_theme_color_override("font_color", C.COLOR_PANEL)
		else:
			st.bg_color     = Color(0,0,0,0)
			st.border_color = Color(C.COLOR_GOLD_DIM.r, C.COLOR_GOLD_DIM.g, C.COLOR_GOLD_DIM.b, 0.3)
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


# ════════════════════════════════════════════════════════════
# TAB: CARTAS
# ════════════════════════════════════════════════════════════
static func _build_cards_tab(content: Control, root: Control, menu) -> void:
	var C = menu

	var main_v = VBoxContainer.new()
	main_v.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_v.add_theme_constant_override("separation", 0)
	content.add_child(main_v)

	# Barra de expansiones
	var exp_bar = Panel.new()
	exp_bar.custom_minimum_size = Vector2(0, 110)
	exp_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var st_bar = StyleBoxFlat.new()
	st_bar.bg_color = Color(0.04, 0.05, 0.08, 0.97)
	st_bar.border_color = Color(C.COLOR_GOLD_DIM.r, C.COLOR_GOLD_DIM.g, C.COLOR_GOLD_DIM.b, 0.2)
	st_bar.border_width_bottom = 1
	exp_bar.add_theme_stylebox_override("panel", st_bar)
	main_v.add_child(exp_bar)

	var exp_m = MarginContainer.new()
	exp_m.add_theme_constant_override("margin_left",  20)
	exp_m.add_theme_constant_override("margin_right", 20)
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
	btn.custom_minimum_size = Vector2(200, 90)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if active else Control.CURSOR_ARROW

	var st = StyleBoxFlat.new()
	st.bg_color     = Color(0.1, 0.12, 0.18, 0.9) if active else Color(0.05, 0.06, 0.08, 0.7)
	st.border_color = C.COLOR_GOLD_DIM if active else Color(0.2, 0.2, 0.25, 0.4)
	st.border_width_left = 1; st.border_width_right  = 1
	st.border_width_top  = 1; st.border_width_bottom = 1
	st.corner_radius_top_left    = 10; st.corner_radius_top_right    = 10
	st.corner_radius_bottom_left = 10; st.corner_radius_bottom_right = 10
	btn.add_theme_stylebox_override("normal", st)
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

	var logo_path = exp_data.get("logo","")
	if active and logo_path != "" and ResourceLoader.exists(logo_path):
		var img = TextureRect.new()
		img.texture = load(logo_path)
		img.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
		img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		img.custom_minimum_size = Vector2(160, 55)
		img.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(img)
	else:
		var lbl = Label.new()
		lbl.text = exp_data["label"]
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 13)
		lbl.add_theme_color_override("font_color",
			C.COLOR_GOLD if active else Color(0.35, 0.35, 0.4, 0.8))
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(lbl)

	if not active:
		var soon = Label.new()
		soon.text = "PRÓXIMAMENTE"
		soon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		soon.add_theme_font_size_override("font_size", 10)
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
		pl.add_theme_color_override("font_color", C.COLOR_TEXT_DIM)
		pl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(pl)
	return btn


static func _style_exp_btns(btns: Array, active_idx: int, C) -> void:
	for i in range(btns.size()):
		var b = btns[i]["btn"]; var data = btns[i]["data"]
		var st = StyleBoxFlat.new()
		if i == active_idx and data["active"]:
			st.bg_color = Color(0.15, 0.20, 0.30, 0.97)
			st.border_color = C.COLOR_GOLD; st.border_width_bottom = 3
		else:
			st.bg_color     = Color(0.1, 0.12, 0.18, 0.9) if data["active"] else Color(0.05, 0.06, 0.08, 0.7)
			st.border_color = C.COLOR_GOLD_DIM if data["active"] else Color(0.2, 0.2, 0.25, 0.4)
			st.border_width_bottom = 1
		st.border_width_left = 1; st.border_width_right = 1; st.border_width_top = 1
		st.corner_radius_top_left    = 10; st.corner_radius_top_right    = 10
		st.corner_radius_bottom_left = 10; st.corner_radius_bottom_right = 10
		b.add_theme_stylebox_override("normal", st)


# ── GRID DE EXPANSIÓN con carga por lotes + threaded ─────────
static func _build_expansion_grid(grid_area: Control, exp_id: String, content: Control, menu) -> void:
	var C = menu
	for c in grid_area.get_children(): c.queue_free()
	_pending_load.clear()

	var all_ids = _get_ids_for_expansion(exp_id)

	# Lanzar precarga threaded de TODAS las imágenes del set de una
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

	# Filtros
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

	# Scroll + Grid
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

	# Preview panel
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
	prev_name.add_theme_font_size_override("font_size", 12)
	prev_name.add_theme_color_override("font_color", C.COLOR_GOLD)
	pv.add_child(prev_name)

	var prev_detail = Label.new(); prev_detail.name = "PreviewDetail"; prev_detail.text = ""
	prev_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prev_detail.autowrap_mode = TextServer.AUTOWRAP_WORD
	prev_detail.add_theme_font_size_override("font_size", 10)
	prev_detail.add_theme_color_override("font_color", C.COLOR_TEXT_DIM)
	pv.add_child(prev_detail)

	# Conectar filtros
	search.text_changed.connect(func(_t):    _refresh_set_grid(grid_area, grid, all_ids, menu))
	show_opt.item_selected.connect(func(_i): _refresh_set_grid(grid_area, grid, all_ids, menu))
	sort_opt.item_selected.connect(func(_i): _refresh_set_grid(grid_area, grid, all_ids, menu))

	# Poblar en lotes usando call_deferred
	_fill_grid_batched(grid, all_ids, 0, grid_area, menu)


# ── Inserción en lotes: BATCH_SIZE slots por frame ───────────
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
		# Próximo lote en el siguiente frame
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
			2: return ShopScreen.rarity_weight(ca.get("rarity","COMMON")) > ShopScreen.rarity_weight(cb.get("rarity","COMMON"))
		return false
	)

	for c in grid.get_children(): c.queue_free()
	_fill_grid_batched(grid, filtered, 0, grid_area, menu)


# ── Slot de carta — usa caché de textura ─────────────────────
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

	# Intentar textura desde caché inmediatamente
	var cached_tex = _get_texture(img_path)
	if cached_tex:
		tr.texture = cached_tex
	elif img_path != "":
		# Polling via Timer hasta que el threaded load termine
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
			tex = load(img_path)  # fallback síncrono solo para preview
			_cache_texture(img_path, tex)
		prev_img.texture  = tex
		prev_img.modulate = Color.WHITE if owned else Color(0.15, 0.15, 0.15)

	if prev_lbl:
		prev_lbl.text = card.get("name", card_id)
		prev_lbl.add_theme_color_override("font_color",
			ShopScreen.rarity_color(card.get("rarity","COMMON")) if owned else Color(0.4, 0.4, 0.5))

	if prev_det:
		var rarity = card.get("rarity","COMMON").replace("_"," ")
		var number = card.get("number","?")
		prev_det.text = "Nº " + number + "  ·  " + rarity + "\n" + ("Tienes: ×" + str(qty) if owned else "🔒 No tienes esta carta")


# (polling manejado via Timer en _make_set_card_slot)


# ════════════════════════════════════════════════════════════
# TAB: SOBRES
# ════════════════════════════════════════════════════════════
static func _build_packs_tab(content: Control, root: Control, menu) -> void:
	var C = menu
	var mm = MarginContainer.new(); mm.set_anchors_preset(Control.PRESET_FULL_RECT)
	mm.add_theme_constant_override("margin_left",40); mm.add_theme_constant_override("margin_right",40)
	mm.add_theme_constant_override("margin_top",20); mm.add_theme_constant_override("margin_bottom",20)
	content.add_child(mm)
	var vbox = VBoxContainer.new(); vbox.add_theme_constant_override("separation",20); mm.add_child(vbox)
	var title = Label.new(); title.text = "📦 SOBRES SIN ABRIR"
	title.add_theme_font_size_override("font_size",16); title.add_theme_color_override("font_color",C.COLOR_GOLD); vbox.add_child(title)
	var sub = Label.new(); sub.text = "Haz clic en 'Abrir' para revelar tus cartas"
	sub.add_theme_font_size_override("font_size",12); sub.add_theme_color_override("font_color",C.COLOR_TEXT_DIM); vbox.add_child(sub)
	var packs_container = HBoxContainer.new(); packs_container.name = "PacksContainer"
	packs_container.add_theme_constant_override("separation",24); vbox.add_child(packs_container)
	_load_pending_packs(content, root, packs_container, menu)


static func _load_pending_packs(content, root, packs_container, menu) -> void:
	var C = menu; var http = HTTPRequest.new(); content.add_child(http)
	http.request_completed.connect(func(result, code, _h, body):
		http.queue_free()
		if result != HTTPRequest.RESULT_SUCCESS or code != 200: return
		var data = JSON.parse_string(body.get_string_from_utf8()); if not data: return
		for c in packs_container.get_children(): c.queue_free()
		var packs = data.get("packs",[])
		if packs.size() == 0:
			var e = Label.new(); e.text = "No tienes sobres sin abrir.\nVisita la Tienda para comprar."
			e.add_theme_color_override("font_color",C.COLOR_TEXT_DIM); e.add_theme_font_size_override("font_size",14)
			e.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; packs_container.add_child(e); return
		for pi in packs: _create_pending_pack_card(content, root, packs_container, pi, menu)
	)
	http.request("http://localhost:3000/api/shop/my-packs",["Authorization: Bearer "+NetworkManager.token],HTTPClient.METHOD_GET,"")


static func _create_pending_pack_card(content, root, parent, pack_info, menu) -> void:
	var C=menu; var pack_type=pack_info.get("pack_type",""); var qty=pack_info.get("quantity",0); var name_str=pack_info.get("name",pack_type)
	var img_map={"typhlosion_pack":"res://assets/Sobres/SobreFuego.png","feraligatr_pack":"res://assets/Sobres/SobreAgua.png","meganium_pack":"res://assets/Sobres/SobreHierba.png"}
	var color_map={"typhlosion_pack":Color(0.8,0.2,0.2),"feraligatr_pack":Color(0.2,0.4,0.8),"meganium_pack":Color(0.2,0.7,0.3)}
	var glow=color_map.get(pack_type,C.COLOR_GOLD); var img_path=img_map.get(pack_type,"")
	var box=PanelContainer.new(); box.custom_minimum_size=Vector2(200,320)
	var st=StyleBoxFlat.new(); st.bg_color=Color(0.1,0.12,0.18,0.95); st.border_width_left=2;st.border_width_right=2;st.border_width_top=2;st.border_width_bottom=2
	st.border_color=glow.darkened(0.2); st.corner_radius_top_left=12;st.corner_radius_top_right=12;st.corner_radius_bottom_left=12;st.corner_radius_bottom_right=12
	st.shadow_color=glow; st.shadow_size=8; box.add_theme_stylebox_override("panel",st); parent.add_child(box)
	var vb=VBoxContainer.new(); vb.alignment=BoxContainer.ALIGNMENT_CENTER; vb.add_theme_constant_override("separation",8); box.add_child(vb)
	var img=TextureRect.new(); img.custom_minimum_size=Vector2(140,180); img.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; img.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if img_path!="" and ResourceLoader.exists(img_path): img.texture=load(img_path)
	vb.add_child(img)
	var nl=Label.new(); nl.text=name_str; nl.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; nl.add_theme_font_size_override("font_size",13); nl.add_theme_color_override("font_color",C.COLOR_TEXT); vb.add_child(nl)
	var ql=Label.new(); ql.name="QtyLbl"; ql.text="×"+str(qty)+" disponibles"; ql.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; ql.add_theme_font_size_override("font_size",12); ql.add_theme_color_override("font_color",glow); vb.add_child(ql)
	var open_btn=Button.new(); open_btn.text="✨ Abrir Sobre"; open_btn.custom_minimum_size=Vector2(150,38); open_btn.size_flags_horizontal=Control.SIZE_SHRINK_CENTER
	open_btn.add_theme_font_size_override("font_size",13)
	var st_btn=StyleBoxFlat.new(); st_btn.bg_color=glow.darkened(0.15); st_btn.corner_radius_top_left=6;st_btn.corner_radius_top_right=6;st_btn.corner_radius_bottom_left=6;st_btn.corner_radius_bottom_right=6
	open_btn.add_theme_stylebox_override("normal",st_btn); open_btn.add_theme_color_override("font_color",Color.WHITE)
	var cq=[qty]
	open_btn.pressed.connect(func():
		open_btn.disabled=true; open_btn.text="Abriendo..."
		ShopScreen.open_pack_from_collection(root,menu,pack_type,func(cards):
			_show_pack_opening(root,menu,cards)
			cq[0]-=1
			if cq[0]<=0: box.queue_free()
			else: ql.text="×"+str(cq[0])+" disponibles"; open_btn.disabled=false; open_btn.text="✨ Abrir Sobre"
		)
	)
	vb.add_child(open_btn)


# ════════════════════════════════════════════════════════════
# APERTURA DE SOBRE (animación)
# ════════════════════════════════════════════════════════════
static func _show_pack_opening(root, menu, cards) -> void:
	var common_cards:Array=[]; var rare_card_id=""; var rare_rarity="COMMON"
	for card_id in cards:
		var r=CardDatabase.get_card(card_id).get("rarity","COMMON")
		if r in ["RARE","RARE_HOLO","ULTRA_RARE"]:
			if rare_card_id=="" or ShopScreen.rarity_weight(r)>ShopScreen.rarity_weight(rare_rarity):
				if rare_card_id!="": common_cards.append(rare_card_id)
				rare_card_id=card_id; rare_rarity=r
			else: common_cards.append(card_id)
		else: common_cards.append(card_id)
	if rare_card_id=="": rare_card_id=common_cards.pop_back(); rare_rarity=CardDatabase.get_card(rare_card_id).get("rarity","COMMON")
	var overlay=ColorRect.new(); overlay.color=Color(0,0,0.05,0.97); overlay.set_anchors_preset(Control.PRESET_FULL_RECT); overlay.z_index=200; root.add_child(overlay)
	var center=CenterContainer.new(); center.set_anchors_preset(Control.PRESET_FULL_RECT); overlay.add_child(center)
	var master=VBoxContainer.new(); master.alignment=BoxContainer.ALIGNMENT_CENTER; master.add_theme_constant_override("separation",20); center.add_child(master)
	var title_lbl=Label.new(); title_lbl.name="PackOpenTitle"; title_lbl.text="¡Toca las cartas para revelarlas!"; title_lbl.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; title_lbl.add_theme_font_size_override("font_size",24); title_lbl.add_theme_color_override("font_color",Color(0.95,0.85,0.5)); master.add_child(title_lbl)
	var grid=GridContainer.new(); grid.columns=5; grid.add_theme_constant_override("h_separation",14); grid.add_theme_constant_override("v_separation",14); master.add_child(grid)
	var sep=Label.new(); sep.text="▼  CARTA ESPECIAL  ▼"; sep.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; sep.add_theme_font_size_override("font_size",13); sep.add_theme_color_override("font_color",Color(0.6,0.6,0.6,0.5)); master.add_child(sep)
	var rare_center=CenterContainer.new(); master.add_child(rare_center)
	var close_btn=Button.new(); close_btn.text="✨  Añadir a mi Colección"; close_btn.custom_minimum_size=Vector2(240,48); close_btn.hide()
	var st_c=StyleBoxFlat.new(); st_c.bg_color=Color(0.1,0.55,0.25); st_c.corner_radius_top_left=10;st_c.corner_radius_top_right=10;st_c.corner_radius_bottom_left=10;st_c.corner_radius_bottom_right=10
	close_btn.add_theme_stylebox_override("normal",st_c); close_btn.add_theme_font_size_override("font_size",16); close_btn.pressed.connect(func(): overlay.queue_free()); master.add_child(close_btn)
	var state={"flipped_common":0,"total_common":common_cards.size(),"rare_flipped":false}
	for card_id in common_cards:
		var s=_make_card_slot(card_id,overlay,menu,false,state,title_lbl,close_btn,rare_center,rare_card_id,rare_rarity); s.custom_minimum_size=Vector2(106,148); grid.add_child(s)
	var rs=_make_card_slot(rare_card_id,overlay,menu,true,state,title_lbl,close_btn,rare_center,rare_card_id,rare_rarity); rs.custom_minimum_size=Vector2(148,207); rs.name="RareSlot"; rs.modulate=Color(1,1,1,0.35); rs.mouse_filter=Control.MOUSE_FILTER_IGNORE; rare_center.add_child(rs)
	master.modulate.a=0.0; master.create_tween().tween_property(master,"modulate:a",1.0,0.4).set_trans(Tween.TRANS_CUBIC)


static func _make_card_slot(card_id,overlay,menu,is_rare,state,title_lbl,close_btn,rare_center,rare_card_id,rare_rarity)->Control:
	var rarity=CardDatabase.get_card(card_id).get("rarity","COMMON"); var cn=ShopScreen.clicks_needed(rarity) if is_rare else 1
	var slot=Control.new(); slot.pivot_offset=Vector2(53,74)
	var gr=Panel.new(); gr.set_anchors_preset(Control.PRESET_FULL_RECT)
	var stg=StyleBoxFlat.new(); stg.bg_color=Color(0,0,0,0); stg.corner_radius_top_left=8;stg.corner_radius_top_right=8;stg.corner_radius_bottom_left=8;stg.corner_radius_bottom_right=8
	gr.add_theme_stylebox_override("panel",stg); gr.hide(); slot.add_child(gr)
	var front=MiniCard.make(card_id,overlay,menu,-1,-1); front.set_anchors_preset(Control.PRESET_FULL_RECT); front.pivot_offset=Vector2(53,74); front.scale.x=0.0; front.hide(); slot.add_child(front)
	var back=TextureRect.new(); back.texture=load("res://assets/imagen/back.jpg"); back.set_anchors_preset(Control.PRESET_FULL_RECT); back.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; back.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED; back.pivot_offset=Vector2(53,74); back.mouse_filter=Control.MOUSE_FILTER_STOP; slot.add_child(back)
	var cl=Label.new(); cl.text=""; cl.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; cl.vertical_alignment=VERTICAL_ALIGNMENT_CENTER; cl.set_anchors_preset(Control.PRESET_FULL_RECT); cl.add_theme_font_size_override("font_size",20); cl.mouse_filter=Control.MOUSE_FILTER_IGNORE; cl.hide(); slot.add_child(cl)
	var ss={"clicks":0,"flipped":false}
	back.gui_input.connect(func(ev):
		if not(ev is InputEventMouseButton and ev.pressed and ev.button_index==MOUSE_BUTTON_LEFT): return
		if ss.flipped: return
		ss.clicks+=1
		if rarity=="ULTRA_RARE" and ss.clicks<cn:
			var cc=ShopScreen.ULTRA_RARE_CHARGE_COLORS[min(ss.clicks-1,5)]
			var tp=back.create_tween(); tp.tween_property(back,"modulate",Color(cc.r*2,cc.g*2,cc.b*2,1),0.08); tp.tween_property(back,"modulate",Color.WHITE,0.15)
			var orig=slot.position; var ts=slot.create_tween()
			for _x in range(3): ts.tween_property(slot,"position",orig+Vector2(randf_range(-5,5),randf_range(-4,4)),0.04)
			ts.tween_property(slot,"position",orig,0.04)
			cl.show(); cl.text="●".repeat(ss.clicks)+"○".repeat(cn-ss.clicks-1); cl.add_theme_color_override("font_color",cc)
			gr.show(); stg.shadow_color=cc; stg.shadow_size=10+ss.clicks*8; return
		ss.flipped=true; cl.hide()
		var tw=slot.create_tween(); tw.tween_property(back,"scale:x",0.0,0.10).set_trans(Tween.TRANS_SINE)
		tw.tween_callback(func():
			back.hide(); front.show(); cl.hide()
			if rarity in ["RARE","RARE_HOLO","ULTRA_RARE"]:
				var rc=ShopScreen.rarity_color(rarity); gr.show(); stg.shadow_color=rc; stg.shadow_size=20 if rarity=="RARE" else(35 if rarity=="RARE_HOLO" else 55)
				var tg=gr.create_tween().set_loops(); tg.tween_property(stg,"shadow_size",stg.shadow_size*1.5,0.7); tg.tween_property(stg,"shadow_size",stg.shadow_size,0.7)
				var pop=Vector2(1.12,1.12); if rarity=="RARE_HOLO": pop=Vector2(1.2,1.2); if rarity=="ULTRA_RARE": pop=Vector2(1.35,1.35)
				front.scale=pop; front.create_tween().tween_property(front,"scale",Vector2.ONE,0.55).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
				ShopScreen.spawn_particles(overlay,slot.position+slot.custom_minimum_size*0.5,rarity)
				if rarity=="ULTRA_RARE":
					var fl=ColorRect.new(); fl.color=Color(1,1,1,0); fl.set_anchors_preset(Control.PRESET_FULL_RECT); fl.z_index=300; fl.mouse_filter=Control.MOUSE_FILTER_IGNORE; overlay.add_child(fl)
					var tf=fl.create_tween(); tf.tween_property(fl,"color:a",0.75,0.08); tf.tween_property(fl,"color:a",0.0,0.35); tf.tween_callback(fl.queue_free)
					title_lbl.text="✨  ¡ULTRA RARA!  ✨"; title_lbl.add_theme_color_override("font_color",ShopScreen.rarity_color("ULTRA_RARE"))
		)
		tw.tween_property(front,"scale:x",1.0,0.12).set_trans(Tween.TRANS_SINE)
		if not is_rare:
			state.flipped_common+=1
			if state.flipped_common==state.total_common: _unlock_rare_slot(rare_center,title_lbl,rare_rarity)
		else: state.rare_flipped=true; close_btn.show(); close_btn.create_tween().tween_property(close_btn,"modulate:a",1.0,0.4)
	)
	return slot


static func _unlock_rare_slot(rare_center,title_lbl,rare_rarity)->void:
	var rs=rare_center.get_node_or_null("RareSlot"); if not rs: return
	var tx={"RARE":"⭐ ¡Carta Rara!","RARE_HOLO":"💫 ¡Holográfica!","ULTRA_RARE":"🔥 ¡ULTRA RARA!"}
	title_lbl.text=tx.get(rare_rarity,"¡Revela!"); title_lbl.add_theme_color_override("font_color",ShopScreen.rarity_color(rare_rarity))
	rs.mouse_filter=Control.MOUSE_FILTER_STOP
	var tw=rs.create_tween().set_parallel(true)
	tw.tween_property(rs,"modulate:a",1.0,0.5).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(rs,"scale",Vector2(1.08,1.08),0.25).set_trans(Tween.TRANS_BACK)
	tw.tween_property(rs,"scale",Vector2.ONE,0.25).set_trans(Tween.TRANS_BACK).set_delay(0.25)


# ════════════════════════════════════════════════════════════
# TAB: MAZOS
# ════════════════════════════════════════════════════════════
static func _build_decks_tab(content: Control, menu) -> void:
	var C=menu; var mm=MarginContainer.new(); mm.set_anchors_preset(Control.PRESET_FULL_RECT)
	mm.add_theme_constant_override("margin_left",40);mm.add_theme_constant_override("margin_right",40);mm.add_theme_constant_override("margin_top",20); content.add_child(mm)
	var vbox=VBoxContainer.new(); vbox.add_theme_constant_override("separation",16); mm.add_child(vbox)
	var t=Label.new(); t.text="📋 MIS MAZOS"; t.add_theme_font_size_override("font_size",16); t.add_theme_color_override("font_color",C.COLOR_GOLD); vbox.add_child(t)
	if PlayerData.decks.is_empty():
		var e=Label.new(); e.text="No tienes mazos.\nCrea uno en el Constructor de Mazo."; e.add_theme_color_override("font_color",C.COLOR_TEXT_DIM); e.add_theme_font_size_override("font_size",14); vbox.add_child(e); return
	var grid=GridContainer.new(); grid.columns=3; grid.add_theme_constant_override("h_separation",16); grid.add_theme_constant_override("v_separation",16); vbox.add_child(grid)
	for slot in PlayerData.decks.keys():
		var dd=PlayerData.decks[slot]; var dn=dd.get("name","Mazo "+str(slot)); var dc=dd.get("cards",[])
		var box=PanelContainer.new(); box.custom_minimum_size=Vector2(240,120)
		var st=StyleBoxFlat.new(); st.bg_color=Color(C.COLOR_PANEL.r,C.COLOR_PANEL.g,C.COLOR_PANEL.b,0.9); st.border_color=C.COLOR_GOLD_DIM
		st.border_width_left=1;st.border_width_right=1;st.border_width_top=1;st.border_width_bottom=1
		st.corner_radius_top_left=10;st.corner_radius_top_right=10;st.corner_radius_bottom_left=10;st.corner_radius_bottom_right=10
		box.add_theme_stylebox_override("panel",st); grid.add_child(box)
		var bv=VBoxContainer.new(); bv.alignment=BoxContainer.ALIGNMENT_CENTER; bv.add_theme_constant_override("separation",6); box.add_child(bv)
		var nl=Label.new(); nl.text="🃏 "+dn; nl.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; nl.add_theme_font_size_override("font_size",14); nl.add_theme_color_override("font_color",C.COLOR_GOLD); bv.add_child(nl)
		var cl=Label.new(); cl.text=str(dc.size())+" / 60 cartas"; cl.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; cl.add_theme_font_size_override("font_size",12)
		cl.add_theme_color_override("font_color",C.COLOR_GREEN if dc.size()==60 else C.COLOR_TEXT_DIM); bv.add_child(cl)


# ════════════════════════════════════════════════════════════
# TAB: ESTADÍSTICAS
# ════════════════════════════════════════════════════════════
static func _build_stats_tab(content: Control, menu) -> void:
	var C=menu; var inv=PlayerData.inventory
	var mm=MarginContainer.new(); mm.set_anchors_preset(Control.PRESET_FULL_RECT)
	mm.add_theme_constant_override("margin_left",40);mm.add_theme_constant_override("margin_right",40);mm.add_theme_constant_override("margin_top",20); content.add_child(mm)
	var scroll=ScrollContainer.new(); scroll.set_anchors_preset(Control.PRESET_FULL_RECT); mm.add_child(scroll)
	var vbox=VBoxContainer.new(); vbox.size_flags_horizontal=Control.SIZE_EXPAND_FILL; vbox.add_theme_constant_override("separation",24); scroll.add_child(vbox)
	var t=Label.new(); t.text="📊 ESTADÍSTICAS"; t.add_theme_font_size_override("font_size",16); t.add_theme_color_override("font_color",C.COLOR_GOLD); vbox.add_child(t)
	var total_unique=CardDatabase.get_all_ids().size(); var owned_unique=inv.size(); var total_cards=0; var by_rarity:Dictionary={}
	for id in inv.keys():
		var q=inv[id]; total_cards+=q; var r=CardDatabase.get_card(id).get("rarity","COMMON"); by_rarity[r]=by_rarity.get(r,0)+q
	var shb=HBoxContainer.new(); shb.add_theme_constant_override("separation",16); vbox.add_child(shb)
	for pair in [["📚 Únicas",str(owned_unique)+" / "+str(total_unique),C.COLOR_ACCENT],["🃏 Total",str(total_cards),C.COLOR_GOLD],["🪙 Monedas",str(PlayerData.coins),C.COLOR_GREEN],["⚔️ ELO",str(PlayerData.elo),C.COLOR_TEXT]]:
		var box=PanelContainer.new(); box.custom_minimum_size=Vector2(150,80)
		var st=StyleBoxFlat.new(); st.bg_color=Color(C.COLOR_PANEL.r,C.COLOR_PANEL.g,C.COLOR_PANEL.b,0.9); st.border_color=pair[2]; st.border_width_bottom=3
		st.corner_radius_top_left=8;st.corner_radius_top_right=8;st.corner_radius_bottom_left=8;st.corner_radius_bottom_right=8; box.add_theme_stylebox_override("panel",st); shb.add_child(box)
		var bv=VBoxContainer.new(); bv.alignment=BoxContainer.ALIGNMENT_CENTER; box.add_child(bv)
		var l1=Label.new(); l1.text=pair[0]; l1.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; l1.add_theme_font_size_override("font_size",11); l1.add_theme_color_override("font_color",C.COLOR_TEXT_DIM); bv.add_child(l1)
		var l2=Label.new(); l2.text=pair[1]; l2.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; l2.add_theme_font_size_override("font_size",20); l2.add_theme_color_override("font_color",pair[2]); bv.add_child(l2)
	var et=Label.new(); et.text="Por Expansión"; et.add_theme_font_size_override("font_size",14); et.add_theme_color_override("font_color",C.COLOR_TEXT_DIM); vbox.add_child(et)
	var ehb=HBoxContainer.new(); ehb.add_theme_constant_override("separation",16); vbox.add_child(ehb)
	for exp_data in EXPANSIONS:
		if not exp_data["active"]: continue
		var eids=_get_ids_for_expansion(exp_data["id"]); var eown=0
		for id in eids:
			if inv.has(id): eown+=1
		var pct=int(float(eown)/max(eids.size(),1)*100)
		var ebox=PanelContainer.new(); ebox.custom_minimum_size=Vector2(180,90)
		var est=StyleBoxFlat.new(); est.bg_color=Color(0.08,0.10,0.15,0.9); est.border_color=C.COLOR_GOLD_DIM
		est.border_width_left=1;est.border_width_right=1;est.border_width_top=1;est.border_width_bottom=1
		est.corner_radius_top_left=8;est.corner_radius_top_right=8;est.corner_radius_bottom_left=8;est.corner_radius_bottom_right=8
		ebox.add_theme_stylebox_override("panel",est); ehb.add_child(ebox)
		var ev=VBoxContainer.new(); ev.alignment=BoxContainer.ALIGNMENT_CENTER; ebox.add_child(ev)
		var en=Label.new(); en.text=exp_data["label"]; en.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; en.add_theme_font_size_override("font_size",11); en.add_theme_color_override("font_color",C.COLOR_GOLD); ev.add_child(en)
		var ep=Label.new(); ep.text=str(eown)+" / "+str(eids.size())+" ("+str(pct)+"%)"; ep.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; ep.add_theme_font_size_override("font_size",14)
		ep.add_theme_color_override("font_color",C.COLOR_GREEN if pct==100 else C.COLOR_TEXT); ev.add_child(ep)
		var pb=ProgressBar.new(); pb.min_value=0; pb.max_value=eids.size(); pb.value=eown; pb.custom_minimum_size=Vector2(150,10); pb.size_flags_horizontal=Control.SIZE_SHRINK_CENTER; ev.add_child(pb)
	var rt=Label.new(); rt.text="Por Rareza"; rt.add_theme_font_size_override("font_size",14); rt.add_theme_color_override("font_color",C.COLOR_TEXT_DIM); vbox.add_child(rt)
	var rhb=HBoxContainer.new(); rhb.add_theme_constant_override("separation",12); vbox.add_child(rhb)
	for r in ["COMMON","UNCOMMON","RARE","RARE_HOLO","ULTRA_RARE"]:
		var cnt=by_rarity.get(r,0); var rc=ShopScreen.rarity_color(r)
		var rb=PanelContainer.new(); rb.custom_minimum_size=Vector2(120,60)
		var rst=StyleBoxFlat.new(); rst.bg_color=Color(rc.r*0.15,rc.g*0.15,rc.b*0.15,0.9); rst.border_color=rc; rst.border_width_left=2
		rst.corner_radius_top_left=6;rst.corner_radius_top_right=6;rst.corner_radius_bottom_left=6;rst.corner_radius_bottom_right=6; rb.add_theme_stylebox_override("panel",rst); rhb.add_child(rb)
		var rv=VBoxContainer.new(); rv.alignment=BoxContainer.ALIGNMENT_CENTER; rb.add_child(rv)
		var rl1=Label.new(); rl1.text=r.replace("_"," "); rl1.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; rl1.add_theme_font_size_override("font_size",10); rl1.add_theme_color_override("font_color",rc); rv.add_child(rl1)
		var rl2=Label.new(); rl2.text=str(cnt); rl2.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; rl2.add_theme_font_size_override("font_size",18); rl2.add_theme_color_override("font_color",rc); rv.add_child(rl2)
