extends Node

# ============================================================
# ShopScreen.gd  —  REDISEÑADO v2 (Full-width, tarjetas grandes)
# Layout: 100% ancho para productos, grid adaptativo
# ============================================================

const MiniCard = preload("res://scenes/main_menu/components/MiniCard.gd")

# ── Cache de texturas ────────────────────────────────────────
static var _tex_cache:       Dictionary = {}
static var _tex_cache_order: Array      = []
const TEX_CACHE_MAX = 100

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
	if status in [ResourceLoader.THREAD_LOAD_IN_PROGRESS, ResourceLoader.THREAD_LOAD_LOADED]: return
	ResourceLoader.load_threaded_request(path)

static func _load_texture_into(rect: TextureRect, path: String) -> void:
	if path == "": return
	var cached = _get_texture(path)
	if cached:
		rect.texture = cached
		return
	# Assets locales: carga síncrona, simple y sin fallos de timing
	var tex = load(path)
	if tex:
		_cache_texture(path, tex)
		rect.texture = tex


# ============================================================
# BUILD PRINCIPAL
# ============================================================
static func build(container: Control, menu) -> void:
	var C = menu

	var shop_root = Control.new()
	shop_root.name = "ShopRoot"
	shop_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	container.add_child(shop_root)

	# Fondo
	var bg_image = TextureRect.new()
	var bg_tex = load("res://assets/imagen/fondomenu.png")
	if bg_tex: bg_image.texture = bg_tex
	bg_image.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_image.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	bg_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg_image.modulate = Color(0.10, 0.10, 0.12, 1)
	shop_root.add_child(bg_image)

	# Overlay degradado
	var overlay = ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.03, 0.04, 0.08, 0.60)
	shop_root.add_child(overlay)

	# ── Header ──────────────────────────────────────────────
	var header = Panel.new()
	header.anchor_left   = 0; header.anchor_right  = 1
	header.anchor_top    = 0; header.anchor_bottom = 0
	header.offset_top    = 0; header.offset_bottom = 100
	var hs = StyleBoxFlat.new()
	hs.bg_color = Color(0.05, 0.06, 0.10, 0.95)
	hs.border_color = Color(C.COLOR_GOLD_DIM.r, C.COLOR_GOLD_DIM.g, C.COLOR_GOLD_DIM.b, 0.30)
	hs.border_width_bottom = 2
	header.add_theme_stylebox_override("panel", hs)
	shop_root.add_child(header)

	# Layout: [monedas+gemas izq EXPAND] | [título centro SHRINK] | [spacer der EXPAND]
	var header_hbox = HBoxContainer.new()
	header_hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	header_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	header_hbox.add_theme_constant_override("separation", 0)
	header.add_child(header_hbox)

	# Lado izquierdo: monedas y gemas
	var left_currency_m = MarginContainer.new()
	left_currency_m.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_currency_m.add_theme_constant_override("margin_left", 28)
	header_hbox.add_child(left_currency_m)

	var left_currency_hbox = HBoxContainer.new()
	left_currency_hbox.add_theme_constant_override("separation", 12)
	left_currency_hbox.size_flags_vertical   = Control.SIZE_SHRINK_CENTER
	left_currency_hbox.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	left_currency_m.add_child(left_currency_hbox)

	var coins_pill = _make_currency_pill("🪙", str(PlayerData.coins), C.COLOR_GOLD, "CoinsLabel")
	left_currency_hbox.add_child(coins_pill)
	var gems_pill = _make_currency_pill("💎", str(PlayerData.gems), Color(0.4, 0.75, 1.0), "GemsLabel")
	left_currency_hbox.add_child(gems_pill)

	# Centro: título + subtítulo
	var title_vbox = VBoxContainer.new()
	title_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	title_vbox.add_theme_constant_override("separation", 5)
	title_vbox.size_flags_vertical   = Control.SIZE_SHRINK_CENTER
	title_vbox.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	header_hbox.add_child(title_vbox)

	var title_lbl = Label.new()
	title_lbl.text = "TIENDA"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 34)
	title_lbl.add_theme_color_override("font_color", C.COLOR_GOLD)
	title_vbox.add_child(title_lbl)

	var subtitle_lbl = Label.new()
	subtitle_lbl.text = "Consigue sobres, decks y cartas exclusivas"
	subtitle_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_lbl.add_theme_font_size_override("font_size", 17)
	subtitle_lbl.add_theme_color_override("font_color", Color(0.68, 0.68, 0.80))
	title_vbox.add_child(subtitle_lbl)

	# Espaciador derecho simétrico al izquierdo para centrado perfecto
	var right_spacer = Control.new()
	right_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_hbox.add_child(right_spacer)

	# ── Cuerpo principal: scroll full-width ──────────────────
	var scroll = ScrollContainer.new()
	scroll.anchor_left   = 0; scroll.anchor_right  = 1
	scroll.anchor_top    = 0; scroll.anchor_bottom = 1
	scroll.offset_top    = 100; scroll.offset_bottom = 0
	scroll.offset_left   = 0;   scroll.offset_right  = 0
	UITheme.apply_scrollbar_theme(scroll)
	shop_root.add_child(scroll)

	var main_vbox = VBoxContainer.new()
	main_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_vbox.add_theme_constant_override("separation", 0)
	scroll.add_child(main_vbox)

	# Precargar imágenes
	_request_texture("res://assets/imagen/fondomenu.png")
	_request_texture("res://assets/Sobres/SobreFuego.png")
	_request_texture("res://assets/Sobres/SobreAgua.png")
	_request_texture("res://assets/Sobres/SobreHierba.png")
	_request_texture("res://assets/Sobres/legendary.png")
	_request_texture("res://assets/Sobres/Lava.jpg")
	_request_texture("res://assets/Sobres/Turmoil.jpg")
	_request_texture("res://assets/cards/Neo Genesis/sneasel-alt.png")

	# ── Hero Banner full-width ───────────────────────────────
	_build_hero_banner(main_vbox, menu)

	main_vbox.add_child(UITheme.vspace(28))

	# ── Sección: Sobres Neo Genesis ──────────────────────────
	_section_header(main_vbox, "SOBRES DE EXPANSIÓN", "Neo Genesis",
		Color(0.3, 0.7, 1.0), "res://assets/imagen/ExpNeoGenesis/IconLogo/Neo Genesis.png")

	main_vbox.add_child(UITheme.vspace(16))

	var neo_grid = _make_grid(4, 20)
	var neo_m = _wrap_in_margin(neo_grid, 36, 36, 0, 0)
	main_vbox.add_child(neo_m)

	_create_pack_card(shop_root, menu, neo_grid, "typhlosion_pack",  "Typhlosion",
		"res://assets/Sobres/SobreFuego.png",  100, Color(0.95, 0.38, 0.18), "coins")
	_create_pack_card(shop_root, menu, neo_grid, "feraligatr_pack", "Feraligatr",
		"res://assets/Sobres/SobreAgua.png",   100, Color(0.22, 0.52, 0.95), "coins")
	_create_pack_card(shop_root, menu, neo_grid, "meganium_pack",   "Meganium",
		"res://assets/Sobres/SobreHierba.png", 100, Color(0.25, 0.80, 0.38), "coins")

	main_vbox.add_child(UITheme.vspace(40))
	_section_divider(main_vbox)

	# ── Sección: Legendary Collection ────────────────────────
	_section_header(main_vbox, "SOBRES DE EXPANSIÓN", "Legendary Collection",
		Color(0.95, 0.78, 0.2), "res://assets/imagen/ExpNeoGenesis/IconLogo/Neo Genesis.png")

	main_vbox.add_child(UITheme.vspace(16))

	var lc_grid = _make_grid(4, 20)
	var lc_m = _wrap_in_margin(lc_grid, 36, 36, 0, 0)
	main_vbox.add_child(lc_m)

	_create_pack_card(shop_root, menu, lc_grid, "legendary_collection_pack", "Legendary Collection",
		"res://assets/Sobres/legendary.png", 150, Color(0.88, 0.68, 0.12), "coins")

	main_vbox.add_child(UITheme.vspace(40))
	_section_divider(main_vbox)

	# ── Sección: Starter Decks ────────────────────────────────
	_section_header(main_vbox, "STARTER DECKS", "Legendary Collection",
		Color(0.55, 0.90, 0.45), "")

	main_vbox.add_child(UITheme.vspace(16))

	var decks_grid = _make_grid(3, 20)
	decks_grid.name = "DecksHBox"
	var decks_m = _wrap_in_margin(decks_grid, 36, 36, 0, 0)
	main_vbox.add_child(decks_m)

	_fetch_bought_decks(shop_root, menu, decks_grid)

	main_vbox.add_child(UITheme.vspace(40))
	_section_divider(main_vbox)

	# ── Sección: Cartas Promo ─────────────────────────────────
	_section_header(main_vbox, "CARTAS PROMO", "Edición Especial",
		Color(0.5, 0.8, 1.0), "")

	main_vbox.add_child(UITheme.vspace(16))

	var promo_grid = _make_grid(4, 20)
	var promo_m = _wrap_in_margin(promo_grid, 36, 36, 0, 0)
	main_vbox.add_child(promo_m)

	_create_promo_card(shop_root, menu, promo_grid,
		"sneasel_alt", "Sneasel Full Art",
		"res://assets/cards/Neo Genesis/sneasel-alt.png",
		100, Color(0.3, 0.0, 0.5)
	)

	main_vbox.add_child(UITheme.vspace(40))
	_section_divider(main_vbox)

	# ── Sección: Mejoras ──────────────────────────────────────
	_section_header(main_vbox, "MEJORAS", "Cuenta",
		C.COLOR_PURPLE, "")

	main_vbox.add_child(UITheme.vspace(16))

	var upgrades_grid = _make_grid(4, 20)
	var upgrades_m = _wrap_in_margin(upgrades_grid, 36, 36, 0, 0)
	main_vbox.add_child(upgrades_m)

	_create_slot_upgrade_card(shop_root, menu, upgrades_grid, 500)

	main_vbox.add_child(UITheme.vspace(40))
	_section_divider(main_vbox)

	# ── Sección: Monedas Personalizables ──────────────────────
	_section_header(main_vbox, "COSMÉTICOS", "Monedas de Lanzamiento",
		Color(0.95, 0.78, 0.2), "")

	main_vbox.add_child(UITheme.vspace(16))

	var coins_grid = _make_grid(4, 20)
	coins_grid.name = "CoinsGrid"
	var coins_m = _wrap_in_margin(coins_grid, 36, 36, 0, 0)
	main_vbox.add_child(coins_m)

	_fetch_shop_coins(shop_root, menu, coins_grid)

	main_vbox.add_child(UITheme.vspace(60))


# ============================================================
# HERO BANNER FULL-WIDTH ANIMADO
# ============================================================
static func _build_hero_banner(parent: Control, menu) -> void:
	var C = menu

	# Contenedor principal del hero — alto fijo de 220px
	var hero_root = Control.new()
	hero_root.custom_minimum_size = Vector2(0, 220)
	hero_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hero_root.clip_contents = true
	parent.add_child(hero_root)

	var slides_data = [
		{
			"tag":       "DISPONIBLE AHORA",
			"tag_color": Color(0.25, 0.85, 0.42),
			"title":     "Neo Genesis",
			"subtitle":  "La expansión clásica de Johto. ¡Consigue a Typhlosion, Feraligatr y Meganium!",
			"accent":    Color(0.28, 0.62, 1.0),
			"bg":        "res://assets/imagen/fondomenu.png",
			"bg_tint":   Color(0.10, 0.18, 0.35, 1.0),
			"items":     [
				"res://assets/Sobres/SobreFuego.png",
				"res://assets/Sobres/SobreAgua.png",
				"res://assets/Sobres/SobreHierba.png",
			],
		},
		{
			"tag":       "EDICIÓN LIMITADA",
			"tag_color": Color(0.95, 0.78, 0.20),
			"title":     "Legendary Collection",
			"subtitle":  "Revive los clásicos. Cartas icónicas reimaginadas con arte renovado.",
			"accent":    Color(0.95, 0.78, 0.20),
			"bg":        "res://assets/imagen/fondomenu.png",
			"bg_tint":   Color(0.30, 0.22, 0.05, 1.0),
			"items":     [
				"res://assets/Sobres/legendary.png",
				"res://assets/Sobres/Turmoil.jpg",
				"res://assets/Sobres/Lava.jpg",
			],
		},
		{
			"tag":       "✨ PROMO ESPECIAL",
			"tag_color": Color(0.65, 0.42, 1.0),
			"title":     "Sneasel Full Art",
			"subtitle":  "Carta promo exclusiva con arte alternativo. Solo por tiempo limitado.",
			"accent":    Color(0.50, 0.30, 0.95),
			"bg":        "res://assets/imagen/fondomenu.png",
			"bg_tint":   Color(0.12, 0.05, 0.28, 1.0),
			"items":     [
				"res://assets/cards/Neo Genesis/sneasel-alt.png",
			],
		},
	]

	# Construir cada slide
	var slide_nodes: Array = []
	for i in range(slides_data.size()):
		var s    = slides_data[i]
		var slide = _build_hero_slide(hero_root, s)
		slide.modulate.a = 1.0 if i == 0 else 0.0
		hero_root.add_child(slide)
		slide_nodes.append(slide)

	# ── Dots de navegación ───────────────────────────────────
	var dots_anchor = Control.new()
	dots_anchor.set_anchors_preset(Control.PRESET_FULL_RECT)
	dots_anchor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hero_root.add_child(dots_anchor)

	var dots_hbox = HBoxContainer.new()
	dots_hbox.add_theme_constant_override("separation", 10)
	dots_hbox.anchor_left   = 0.5; dots_hbox.anchor_right  = 0.5
	dots_hbox.anchor_top    = 1.0; dots_hbox.anchor_bottom = 1.0
	dots_hbox.offset_left   = -40; dots_hbox.offset_right  = 40
	dots_hbox.offset_top    = -26; dots_hbox.offset_bottom = -8
	dots_hbox.mouse_filter  = Control.MOUSE_FILTER_IGNORE
	dots_anchor.add_child(dots_hbox)

	var dot_nodes: Array = []
	for i in range(slides_data.size()):
		var dot = PanelContainer.new()
		var dot_st = StyleBoxFlat.new()
		dot_st.bg_color = slides_data[0]["accent"] if i == 0 else Color(0.25, 0.25, 0.32)
		dot_st.corner_radius_top_left    = 6
		dot_st.corner_radius_top_right   = 6
		dot_st.corner_radius_bottom_left = 6
		dot_st.corner_radius_bottom_right = 6
		dot.add_theme_stylebox_override("panel", dot_st)
		dot.custom_minimum_size = Vector2(28 if i == 0 else 8, 8)
		dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		dots_hbox.add_child(dot)
		dot_nodes.append({"panel": dot, "style": dot_st})

	# ── Botones prev / next ──────────────────────────────────
	var btn_prev = _make_hero_nav_btn("‹")
	btn_prev.anchor_left   = 0; btn_prev.anchor_right  = 0
	btn_prev.anchor_top    = 0.5; btn_prev.anchor_bottom = 0.5
	btn_prev.offset_left   = 16; btn_prev.offset_right  = 60
	btn_prev.offset_top    = -22; btn_prev.offset_bottom = 22
	dots_anchor.add_child(btn_prev)

	var btn_next = _make_hero_nav_btn("›")
	btn_next.anchor_left   = 1; btn_next.anchor_right  = 1
	btn_next.anchor_top    = 0.5; btn_next.anchor_bottom = 0.5
	btn_next.offset_left   = -60; btn_next.offset_right  = -16
	btn_next.offset_top    = -22; btn_next.offset_bottom = 22
	dots_anchor.add_child(btn_next)

	# ── Auto-rotación + lógica de cambio ────────────────────
	var current_idx = [0]

	var go_to = func(self_ref: Callable, next: int) -> void:
		var prev = current_idx[0]
		if prev == next: return
		current_idx[0] = next

		var tw_out = slide_nodes[prev].create_tween()
		tw_out.tween_property(slide_nodes[prev], "modulate:a", 0.0, 0.35)

		var tw_in = slide_nodes[next].create_tween()
		tw_in.tween_interval(0.15)
		tw_in.tween_property(slide_nodes[next], "modulate:a", 1.0, 0.45)

		for i in range(dot_nodes.size()):
			var d = dot_nodes[i]
			d["style"].bg_color = slides_data[next]["accent"] if i == next else Color(0.25, 0.25, 0.32)
			d["panel"].add_theme_stylebox_override("panel", d["style"])
			d["panel"].custom_minimum_size = Vector2(28 if i == next else 8, 8)

	var timer = Timer.new()
	timer.wait_time = 5.5
	timer.autostart = true
	hero_root.add_child(timer)
	timer.timeout.connect(func():
		var next = (current_idx[0] + 1) % slides_data.size()
		go_to.call(go_to, next)
	)

	btn_next.pressed.connect(func():
		timer.stop(); timer.start()
		go_to.call(go_to, (current_idx[0] + 1) % slides_data.size())
	)
	btn_prev.pressed.connect(func():
		timer.stop(); timer.start()
		go_to.call(go_to, (current_idx[0] - 1 + slides_data.size()) % slides_data.size())
	)


static func _build_hero_slide(parent: Control, data: Dictionary) -> Control:
	var slide = Control.new()
	slide.set_anchors_preset(Control.PRESET_FULL_RECT)

	# Fondo oscuro base
	var bg_base = ColorRect.new()
	bg_base.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_base.color = Color(0.04, 0.05, 0.09, 1.0)
	slide.add_child(bg_base)

	# Imagen de fondo del menú (compartida, teñida distinto por slide)
	var bg_tex = TextureRect.new()
	bg_tex.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_tex.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	bg_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg_tex.modulate     = data["bg_tint"]
	_load_texture_into(bg_tex, data["bg"])
	slide.add_child(bg_tex)

	# Degradado izquierdo para legibilidad del texto
	var grad_left = ColorRect.new()
	grad_left.anchor_left   = 0;    grad_left.anchor_right  = 0.55
	grad_left.anchor_top    = 0;    grad_left.anchor_bottom = 1
	grad_left.color = Color(0.02, 0.03, 0.07, 0.92)
	slide.add_child(grad_left)

	# Degradado suave de transición centro → derecha
	var grad_mid = ColorRect.new()
	grad_mid.anchor_left   = 0.50; grad_mid.anchor_right  = 0.65
	grad_mid.anchor_top    = 0;    grad_mid.anchor_bottom = 1
	grad_mid.color = Color(0.02, 0.03, 0.07, 0.55)
	slide.add_child(grad_mid)

	# Línea de color superior (accent)
	var top_line = ColorRect.new()
	top_line.anchor_left   = 0; top_line.anchor_right  = 1
	top_line.anchor_top    = 0; top_line.anchor_bottom = 0
	top_line.offset_bottom = 4
	top_line.color = data["accent"]
	slide.add_child(top_line)

	# ── Contenido izquierdo: tag + título + subtítulo ────────
	var content_m = MarginContainer.new()
	content_m.anchor_left   = 0;    content_m.anchor_right  = 0.52
	content_m.anchor_top    = 0;    content_m.anchor_bottom = 1
	content_m.add_theme_constant_override("margin_left",   52)
	content_m.add_theme_constant_override("margin_right",  16)
	content_m.add_theme_constant_override("margin_top",    20)
	content_m.add_theme_constant_override("margin_bottom", 36)
	slide.add_child(content_m)

	var content_vbox = VBoxContainer.new()
	content_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	content_vbox.add_theme_constant_override("separation", 10)
	content_m.add_child(content_vbox)

	# Tag pill
	var tag_pc = PanelContainer.new()
	tag_pc.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var tag_st = StyleBoxFlat.new()
	tag_st.bg_color    = Color(data["tag_color"].r, data["tag_color"].g, data["tag_color"].b, 0.18)
	tag_st.border_color = Color(data["tag_color"].r, data["tag_color"].g, data["tag_color"].b, 0.65)
	tag_st.border_width_left = 1; tag_st.border_width_right  = 1
	tag_st.border_width_top  = 1; tag_st.border_width_bottom = 1
	tag_st.corner_radius_top_left    = 6; tag_st.corner_radius_top_right    = 6
	tag_st.corner_radius_bottom_left = 6; tag_st.corner_radius_bottom_right = 6
	tag_st.content_margin_left = 12; tag_st.content_margin_right  = 12
	tag_st.content_margin_top  = 4;  tag_st.content_margin_bottom = 4
	tag_pc.add_theme_stylebox_override("panel", tag_st)
	content_vbox.add_child(tag_pc)

	var tag_lbl = Label.new()
	tag_lbl.text = data["tag"]
	tag_lbl.add_theme_font_size_override("font_size", 13)
	tag_lbl.add_theme_color_override("font_color", data["tag_color"])
	tag_pc.add_child(tag_lbl)

	# Título grande
	var title_lbl = Label.new()
	title_lbl.text = data["title"]
	title_lbl.add_theme_font_size_override("font_size", 38)
	title_lbl.add_theme_color_override("font_color", Color.WHITE)
	title_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content_vbox.add_child(title_lbl)

	# Subtítulo
	var sub_lbl = Label.new()
	sub_lbl.text = data["subtitle"]
	sub_lbl.add_theme_font_size_override("font_size", 16)
	sub_lbl.add_theme_color_override("font_color", Color(0.68, 0.68, 0.78))
	sub_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content_vbox.add_child(sub_lbl)

	# ── Imágenes de items: ocupan todo el lado derecho ───────
	var items_container = Control.new()
	items_container.anchor_left   = 0.50; items_container.anchor_right  = 1.0
	items_container.anchor_top    = 0;    items_container.anchor_bottom = 1
	items_container.clip_contents = false
	slide.add_child(items_container)

	var items_hbox = HBoxContainer.new()
	items_hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	items_hbox.offset_left   = 10; items_hbox.offset_right  = -10
	items_hbox.offset_top    = 0;  items_hbox.offset_bottom = 0
	items_hbox.alignment     = BoxContainer.ALIGNMENT_CENTER
	items_hbox.add_theme_constant_override("separation", 10)
	items_container.add_child(items_hbox)

	for item_path in data["items"]:
		var item_rect = TextureRect.new()
		item_rect.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
		item_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		item_rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		item_rect.size_flags_vertical   = Control.SIZE_EXPAND_FILL
		_load_texture_into(item_rect, item_path)

		# Animación de flotación suave con fase distinta por item
		var float_tw = item_rect.create_tween().set_loops()
		var phase = randf_range(0.0, 1.2)
		float_tw.tween_interval(phase)
		float_tw.tween_property(item_rect, "position:y",  9.0, 1.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		float_tw.tween_property(item_rect, "position:y", -9.0, 1.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

		items_hbox.add_child(item_rect)

	return slide


static func _make_hero_nav_btn(arrow: String) -> Button:
	var btn = Button.new()
	btn.text = arrow
	btn.flat = false
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.add_theme_font_size_override("font_size", 28)

	for st_name in ["normal", "hover", "pressed"]:
		var st = StyleBoxFlat.new()
		match st_name:
			"normal":  st.bg_color = Color(0.08, 0.09, 0.14, 0.70)
			"hover":   st.bg_color = Color(0.18, 0.20, 0.30, 0.90)
			"pressed": st.bg_color = Color(0.25, 0.28, 0.40, 1.00)
		st.border_color = Color(0.35, 0.35, 0.45, 0.60)
		st.border_width_left = 1; st.border_width_right  = 1
		st.border_width_top  = 1; st.border_width_bottom = 1
		st.corner_radius_top_left    = 8; st.corner_radius_top_right    = 8
		st.corner_radius_bottom_left = 8; st.corner_radius_bottom_right = 8
		btn.add_theme_stylebox_override(st_name, st)

	btn.add_theme_color_override("font_color", Color(0.80, 0.80, 0.90))
	return btn


# ============================================================
# HELPERS DE LAYOUT
# ============================================================

static func _make_grid(columns: int, separation: int) -> GridContainer:
	var grid = GridContainer.new()
	grid.columns = columns
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", separation)
	grid.add_theme_constant_override("v_separation", separation)
	return grid

static func _wrap_in_margin(child: Control, left: int, right: int, top: int, bottom: int) -> MarginContainer:
	var m = MarginContainer.new()
	m.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	m.add_theme_constant_override("margin_left",   left)
	m.add_theme_constant_override("margin_right",  right)
	m.add_theme_constant_override("margin_top",    top)
	m.add_theme_constant_override("margin_bottom", bottom)
	m.add_child(child)
	return m

static func _section_divider(parent: Control) -> void:
	var div_m = MarginContainer.new()
	div_m.add_theme_constant_override("margin_left",  36)
	div_m.add_theme_constant_override("margin_right", 36)
	parent.add_child(div_m)
	var line = ColorRect.new()
	line.custom_minimum_size = Vector2(0, 1)
	line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.color = Color(0.18, 0.18, 0.24, 1.0)
	div_m.add_child(line)
	parent.add_child(UITheme.vspace(28))


# ============================================================
# HELPERS DE UI
# ============================================================

static func _make_currency_pill(icon: String, value: String, color: Color, node_name: String) -> Control:
	var pc = PanelContainer.new()
	var st = StyleBoxFlat.new()
	st.bg_color = Color(color.r, color.g, color.b, 0.12)
	st.border_color = Color(color.r, color.g, color.b, 0.40)
	st.border_width_left = 1; st.border_width_right  = 1
	st.border_width_top  = 1; st.border_width_bottom = 1
	st.corner_radius_top_left    = 30; st.corner_radius_top_right    = 30
	st.corner_radius_bottom_left = 30; st.corner_radius_bottom_right = 30
	st.content_margin_left = 18; st.content_margin_right  = 18
	st.content_margin_top  = 8;  st.content_margin_bottom = 8
	pc.add_theme_stylebox_override("panel", st)

	var hb = HBoxContainer.new()
	hb.add_theme_constant_override("separation", 8)
	pc.add_child(hb)

	var icon_lbl = Label.new()
	icon_lbl.text = icon
	icon_lbl.add_theme_font_size_override("font_size", 20)
	hb.add_child(icon_lbl)

	var val_lbl = Label.new()
	val_lbl.name = node_name
	val_lbl.text = value
	val_lbl.add_theme_font_size_override("font_size", 20)
	val_lbl.add_theme_color_override("font_color", color)
	hb.add_child(val_lbl)

	return pc


static func _section_header(parent: Control, label: String, sublabel: String, accent: Color, icon_path: String) -> void:
	var outer_m = MarginContainer.new()
	outer_m.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer_m.add_theme_constant_override("margin_left",  36)
	outer_m.add_theme_constant_override("margin_right", 36)
	outer_m.add_theme_constant_override("margin_top",   28)
	parent.add_child(outer_m)

	var hb = HBoxContainer.new()
	hb.add_theme_constant_override("separation", 16)
	hb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer_m.add_child(hb)

	# Barra vertical de color
	var bar = ColorRect.new()
	bar.color = accent
	bar.custom_minimum_size = Vector2(5, 0)
	bar.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hb.add_child(bar)

	var vb = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 3)
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(vb)

	var top_lbl = Label.new()
	top_lbl.text = label
	top_lbl.add_theme_font_size_override("font_size", 13)
	top_lbl.add_theme_color_override("font_color", Color(accent.r, accent.g, accent.b, 0.85))
	vb.add_child(top_lbl)

	var sub_lbl = Label.new()
	sub_lbl.text = sublabel
	sub_lbl.add_theme_font_size_override("font_size", 26)
	sub_lbl.add_theme_color_override("font_color", Color(0.95, 0.92, 0.88))
	vb.add_child(sub_lbl)

	# Spacer + línea decorativa a la derecha del título
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.size_flags_vertical   = Control.SIZE_SHRINK_CENTER
	spacer.custom_minimum_size   = Vector2(0, 1)
	hb.add_child(spacer)

	var h_line = ColorRect.new()
	h_line.custom_minimum_size = Vector2(0, 1)
	h_line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h_line.size_flags_vertical   = Control.SIZE_SHRINK_CENTER
	h_line.color = Color(accent.r, accent.g, accent.b, 0.18)
	hb.add_child(h_line)


# ── CARD DE SOBRE ─────────────────────────────────────────────
static func _create_pack_card(shop_root, menu, parent, pack_id, pack_name, img_path, price, glow_color, currency := "coins") -> void:
	var C   = menu
	var box = PanelContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.custom_minimum_size   = Vector2(0, 400)

	var st = StyleBoxFlat.new()
	st.bg_color = Color(0.08, 0.09, 0.15, 0.97)
	st.border_width_left = 1; st.border_width_right  = 1
	st.border_width_top  = 1; st.border_width_bottom = 1
	st.border_color = Color(glow_color.r, glow_color.g, glow_color.b, 0.30)
	st.corner_radius_top_left    = 16; st.corner_radius_top_right    = 16
	st.corner_radius_bottom_left = 16; st.corner_radius_bottom_right = 16
	box.add_theme_stylebox_override("panel", st)
	parent.add_child(box)

	# Hover: glow + scale
	box.mouse_entered.connect(func():
		var st_h = st.duplicate()
		st_h.border_color = glow_color
		st_h.shadow_color = Color(glow_color.r, glow_color.g, glow_color.b, 0.50)
		st_h.shadow_size  = 18
		box.add_theme_stylebox_override("panel", st_h)
		var tw = box.create_tween()
		tw.tween_property(box, "scale", Vector2(1.035, 1.035), 0.14).set_trans(Tween.TRANS_CUBIC)
	)
	box.mouse_exited.connect(func():
		box.add_theme_stylebox_override("panel", st)
		var tw = box.create_tween()
		tw.tween_property(box, "scale", Vector2(1.0, 1.0), 0.16).set_trans(Tween.TRANS_CUBIC)
	)

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 10)
	box.add_child(vbox)

	# Franja superior de color
	var top_strip = ColorRect.new()
	top_strip.custom_minimum_size = Vector2(0, 5)
	top_strip.color = glow_color
	top_strip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(top_strip)
	vbox.add_child(UITheme.vspace(8))

	# Imagen del sobre
	var img_rect = TextureRect.new()
	img_rect.custom_minimum_size = Vector2(160, 220)
	img_rect.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	img_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	img_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(img_rect)
	_load_texture_into(img_rect, img_path)

	# Botón zoom invisible sobre la imagen
	var zoom_btn = Button.new()
	zoom_btn.set_anchors_preset(Control.PRESET_FULL_RECT)
	zoom_btn.flat = true
	zoom_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var zh = StyleBoxFlat.new()
	zh.bg_color = Color(1, 1, 1, 0.08)
	zh.set_corner_radius_all(8)
	zoom_btn.add_theme_stylebox_override("hover", zh)
	var _zp = img_path; var _zn = pack_name
	zoom_btn.pressed.connect(func(): _show_image_zoom(shop_root, _zp, _zn))
	img_rect.add_child(zoom_btn)

	vbox.add_child(UITheme.vspace(4))

	# Nombre
	var name_lbl = Label.new()
	name_lbl.text = pack_name
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 18)
	name_lbl.add_theme_color_override("font_color", C.COLOR_TEXT)
	vbox.add_child(name_lbl)

	# Precio
	var price_hb = HBoxContainer.new()
	price_hb.alignment = BoxContainer.ALIGNMENT_CENTER
	price_hb.add_theme_constant_override("separation", 6)
	vbox.add_child(price_hb)

	var price_icon = Label.new()
	price_icon.text = "💎" if currency == "gems" else "🪙"
	price_icon.add_theme_font_size_override("font_size", 18)
	price_hb.add_child(price_icon)

	var price_lbl = Label.new()
	price_lbl.text = str(price)
	price_lbl.add_theme_font_size_override("font_size", 22)
	price_lbl.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0) if currency == "gems" else C.COLOR_GOLD)
	price_hb.add_child(price_lbl)

	# ── Selector de cantidad ─────────────────────────────────
	var qty_ref = [1]

	var qty_container = MarginContainer.new()
	qty_container.add_theme_constant_override("margin_left",  16)
	qty_container.add_theme_constant_override("margin_right", 16)
	vbox.add_child(qty_container)

	var qty_hbox = HBoxContainer.new()
	qty_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	qty_hbox.add_theme_constant_override("separation", 8)
	qty_container.add_child(qty_hbox)

	var btn_minus = _make_qty_button("-", glow_color)
	qty_hbox.add_child(btn_minus)

	# ── LineEdit editable en lugar de Label ──────────────────
	var qty_lbl = LineEdit.new()
	qty_lbl.text = "1"
	qty_lbl.custom_minimum_size   = Vector2(52, 0)
	qty_lbl.expand_to_text_length = false
	qty_lbl.alignment             = HORIZONTAL_ALIGNMENT_CENTER
	qty_lbl.add_theme_font_size_override("font_size", 20)
	qty_lbl.add_theme_color_override("font_color", Color.WHITE)
	var le_st = StyleBoxFlat.new()
	le_st.bg_color     = Color(0.10, 0.10, 0.18, 0.90)
	le_st.border_color = Color(glow_color.r, glow_color.g, glow_color.b, 0.45)
	le_st.border_width_left = 1; le_st.border_width_right  = 1
	le_st.border_width_top  = 1; le_st.border_width_bottom = 1
	le_st.corner_radius_top_left    = 8; le_st.corner_radius_top_right    = 8
	le_st.corner_radius_bottom_left = 8; le_st.corner_radius_bottom_right = 8
	le_st.content_margin_left = 6; le_st.content_margin_right = 6
	qty_lbl.add_theme_stylebox_override("normal", le_st)
	qty_lbl.add_theme_stylebox_override("focus",  le_st)
	qty_hbox.add_child(qty_lbl)

	var btn_plus = _make_qty_button("+", glow_color)
	qty_hbox.add_child(btn_plus)

	# ── Botón MAX ────────────────────────────────────────────
	var btn_max = _make_qty_button("MAX", glow_color)
	btn_max.custom_minimum_size = Vector2(52, 38)
	btn_max.add_theme_font_size_override("font_size", 13)
	qty_hbox.add_child(btn_max)

	# Total label (debajo del selector)
	var total_lbl = Label.new()
	total_lbl.text = _format_total(price, 1, currency)
	total_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	total_lbl.add_theme_font_size_override("font_size", 14)
	total_lbl.add_theme_color_override("font_color", Color(0.50, 0.50, 0.62))
	vbox.add_child(total_lbl)

	# ── Lógica compartida de actualización de cantidad ───────
	var _apply_qty = func(v: int) -> void:
		v = clampi(v, 1, 99)
		qty_ref[0]     = v
		qty_lbl.text   = str(v)
		total_lbl.text = _format_total(price, v, currency)
		btn_minus.disabled = v <= 1
		btn_plus.disabled  = v >= 99

	# Botón −
	btn_minus.pressed.connect(func():
		_apply_qty.call(qty_ref[0] - 1)
	)

	# Botón +
	btn_plus.pressed.connect(func():
		_apply_qty.call(qty_ref[0] + 1)
	)

	# Botón MAX: calcula cuántos sobres alcanza con el saldo actual
	btn_max.pressed.connect(func():
		var balance = PlayerData.gems if currency == "gems" else PlayerData.coins
		var max_qty = clampi(balance / price, 1, 99) if price > 0 else 99
		_apply_qty.call(max_qty)
	)

	# Validar entrada manual al confirmar con Enter o al perder el foco
	var _on_qty_entered = func(new_text: String) -> void:
		var v = new_text.to_int()
		_apply_qty.call(v)

	qty_lbl.text_submitted.connect(_on_qty_entered)
	qty_lbl.focus_exited.connect(func(): _on_qty_entered.call(qty_lbl.text))

	# Estado inicial: − deshabilitado (cantidad = 1)
	btn_minus.disabled = true

	var m = MarginContainer.new()
	m.add_theme_constant_override("margin_left",   16)
	m.add_theme_constant_override("margin_right",  16)
	m.add_theme_constant_override("margin_bottom", 16)
	vbox.add_child(m)

	var buy_btn = _make_buy_button("Comprar", glow_color)
	buy_btn.pressed.connect(func(): _buy_pack_multi(shop_root, menu, pack_id, price, qty_ref, buy_btn, currency))
	m.add_child(buy_btn)


# ── Botón pequeño de cantidad ─────────────────────────────────
static func _make_qty_button(label: String, color: Color) -> Button:
	var btn = Button.new()
	btn.text = label
	btn.custom_minimum_size = Vector2(38, 38)
	btn.add_theme_font_size_override("font_size", 22)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	for st_name in ["normal", "hover", "pressed", "disabled"]:
		var st = StyleBoxFlat.new()
		match st_name:
			"normal":   st.bg_color = Color(color.r, color.g, color.b, 0.15)
			"hover":    st.bg_color = Color(color.r, color.g, color.b, 0.35)
			"pressed":  st.bg_color = Color(color.r, color.g, color.b, 0.55)
			"disabled": st.bg_color = Color(0.12, 0.12, 0.18, 0.60)
		st.border_color = Color(color.r, color.g, color.b, 0.60) if st_name != "disabled" else Color(0.25, 0.25, 0.30, 0.4)
		st.border_width_left = 1; st.border_width_right  = 1
		st.border_width_top  = 1; st.border_width_bottom = 1
		st.corner_radius_top_left    = 10; st.corner_radius_top_right    = 10
		st.corner_radius_bottom_left = 10; st.corner_radius_bottom_right = 10
		btn.add_theme_stylebox_override(st_name, st)

	btn.add_theme_color_override("font_color",          Color.WHITE)
	btn.add_theme_color_override("font_disabled_color", Color(0.30, 0.30, 0.38))
	return btn


static func _format_total(price: int, qty: int, currency: String) -> String:
	if qty <= 1: return ""
	var icon = "💎" if currency == "gems" else "🪙"
	return "Total: " + icon + " " + str(price * qty)


static func _make_buy_button(text: String, color: Color, disabled: bool = false, disabled_text: String = "") -> Button:
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size   = Vector2(0, 48)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.add_theme_font_size_override("font_size", 17)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	if disabled:
		btn.text     = disabled_text
		btn.disabled = true
		var st_d = StyleBoxFlat.new()
		st_d.bg_color = Color(0.10, 0.20, 0.10, 0.90)
		st_d.border_color = Color(0.28, 0.52, 0.28, 0.55)
		st_d.border_width_left = 1; st_d.border_width_right  = 1
		st_d.border_width_top  = 1; st_d.border_width_bottom = 1
		st_d.corner_radius_top_left    = 12; st_d.corner_radius_top_right    = 12
		st_d.corner_radius_bottom_left = 12; st_d.corner_radius_bottom_right = 12
		btn.add_theme_stylebox_override("disabled", st_d)
		btn.add_theme_color_override("font_disabled_color", Color(0.38, 0.70, 0.38))
	else:
		for st_name in ["normal", "hover", "pressed"]:
			var st = StyleBoxFlat.new()
			match st_name:
				"normal":  st.bg_color = Color(color.r, color.g, color.b, 0.18)
				"hover":
					st.bg_color   = Color(color.r, color.g, color.b, 0.40)
					st.shadow_color = Color(color.r, color.g, color.b, 0.35)
					st.shadow_size  = 10
				"pressed": st.bg_color = Color(color.r, color.g, color.b, 0.55)
			st.border_color = Color(color.r, color.g, color.b, 0.75)
			st.border_width_left = 1; st.border_width_right  = 1
			st.border_width_top  = 1; st.border_width_bottom = 1
			st.corner_radius_top_left    = 12; st.corner_radius_top_right    = 12
			st.corner_radius_bottom_left = 12; st.corner_radius_bottom_right = 12
			btn.add_theme_stylebox_override(st_name, st)
		btn.add_theme_color_override("font_color", color.lightened(0.35))

	return btn


# ── CARD DE STARTER DECK ──────────────────────────────────────
static func _create_deck_card(shop_root, menu, parent,
		deck_id, deck_name, img_path, back_path,
		description, price, glow_color, already_bought) -> void:
	var C   = menu
	var box = PanelContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.custom_minimum_size   = Vector2(0, 380)

	var st = StyleBoxFlat.new()
	st.bg_color = Color(0.07, 0.09, 0.14, 0.97)
	st.border_width_left = 1; st.border_width_right  = 1
	st.border_width_top  = 1; st.border_width_bottom = 1
	st.border_color = Color(glow_color.r, glow_color.g, glow_color.b, 0.28) if not already_bought else Color(0.18, 0.42, 0.18, 0.55)
	st.corner_radius_top_left    = 16; st.corner_radius_top_right    = 16
	st.corner_radius_bottom_left = 16; st.corner_radius_bottom_right = 16
	if not already_bought:
		st.shadow_color = Color(glow_color.r, glow_color.g, glow_color.b, 0.20)
		st.shadow_size  = 10
	box.add_theme_stylebox_override("panel", st)
	parent.add_child(box)

	if not already_bought:
		box.mouse_entered.connect(func():
			var st_h = st.duplicate()
			st_h.border_color = glow_color
			st_h.shadow_size  = 20
			st_h.shadow_color = Color(glow_color.r, glow_color.g, glow_color.b, 0.45)
			box.add_theme_stylebox_override("panel", st_h)
			var tw = box.create_tween()
			tw.tween_property(box, "scale", Vector2(1.03, 1.03), 0.14).set_trans(Tween.TRANS_CUBIC)
		)
		box.mouse_exited.connect(func():
			box.add_theme_stylebox_override("panel", st)
			var tw = box.create_tween()
			tw.tween_property(box, "scale", Vector2(1.0, 1.0), 0.16).set_trans(Tween.TRANS_CUBIC)
		)

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 10)
	box.add_child(vbox)

	var top_strip = ColorRect.new()
	top_strip.custom_minimum_size = Vector2(0, 5)
	top_strip.color = glow_color if not already_bought else Color(0.28, 0.58, 0.28)
	top_strip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(top_strip)
	vbox.add_child(UITheme.vspace(8))

	var img_rect_deck = TextureRect.new()
	img_rect_deck.custom_minimum_size = Vector2(200, 160)
	img_rect_deck.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	img_rect_deck.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	img_rect_deck.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(img_rect_deck)
	_load_texture_into(img_rect_deck, img_path)

	var zoom_btn_deck = Button.new()
	zoom_btn_deck.set_anchors_preset(Control.PRESET_FULL_RECT)
	zoom_btn_deck.flat = true
	zoom_btn_deck.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var zh_deck = StyleBoxFlat.new()
	zh_deck.bg_color = Color(1, 1, 1, 0.08)
	zh_deck.set_corner_radius_all(8)
	zoom_btn_deck.add_theme_stylebox_override("hover", zh_deck)
	var _zp_deck = img_path; var _zb_deck = back_path; var _zn_deck = deck_name
	zoom_btn_deck.pressed.connect(func(): _show_deck_zoom(shop_root, _zp_deck, _zb_deck, _zn_deck))
	img_rect_deck.add_child(zoom_btn_deck)

	var name_lbl = Label.new()
	name_lbl.text = deck_name
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 20)
	name_lbl.add_theme_color_override("font_color", C.COLOR_GOLD if not already_bought else Color(0.48, 0.72, 0.48))
	vbox.add_child(name_lbl)

	var desc_lbl = Label.new()
	desc_lbl.text = description
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.add_theme_font_size_override("font_size", 15)
	desc_lbl.add_theme_color_override("font_color", C.COLOR_TEXT_DIM)
	vbox.add_child(desc_lbl)

	var info_lbl = Label.new()
	info_lbl.text = "60 cartas · 1 por jugador"
	info_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_lbl.add_theme_font_size_override("font_size", 13)
	info_lbl.add_theme_color_override("font_color", Color(0.36, 0.36, 0.46))
	vbox.add_child(info_lbl)

	var m = MarginContainer.new()
	m.add_theme_constant_override("margin_left",   16)
	m.add_theme_constant_override("margin_right",  16)
	m.add_theme_constant_override("margin_bottom", 16)
	vbox.add_child(m)

	var buy_btn: Button
	if already_bought:
		buy_btn = _make_buy_button("", glow_color, true, "✅ Ya obtenido")
	else:
		buy_btn = _make_buy_button("🪙 " + str(price) + " monedas", glow_color)
		buy_btn.pressed.connect(func(): _buy_deck(shop_root, menu, deck_id, price, buy_btn))
	m.add_child(buy_btn)


# ── CARD DE PROMO ─────────────────────────────────────────────
static func _create_promo_card(shop_root, menu, parent, card_id, card_name, img_path, price_gems, glow_color) -> void:
	var C   = menu
	var box = PanelContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.custom_minimum_size   = Vector2(0, 420)

	var st = StyleBoxFlat.new()
	st.bg_color = Color(0.06, 0.04, 0.12, 0.97)
	st.border_width_left = 1; st.border_width_right  = 1
	st.border_width_top  = 1; st.border_width_bottom = 1
	st.border_color = Color(glow_color.r, glow_color.g, glow_color.b, 0.50)
	st.corner_radius_top_left    = 16; st.corner_radius_top_right    = 16
	st.corner_radius_bottom_left = 16; st.corner_radius_bottom_right = 16
	st.shadow_color = Color(glow_color.r, glow_color.g, glow_color.b, 0.35)
	st.shadow_size  = 16
	box.add_theme_stylebox_override("panel", st)
	parent.add_child(box)

	box.mouse_entered.connect(func():
		var st_h = st.duplicate()
		st_h.border_color = glow_color.lightened(0.25)
		st_h.shadow_size  = 28
		st_h.shadow_color = Color(glow_color.r, glow_color.g, glow_color.b, 0.55)
		box.add_theme_stylebox_override("panel", st_h)
		var tw = box.create_tween()
		tw.tween_property(box, "scale", Vector2(1.035, 1.035), 0.14).set_trans(Tween.TRANS_CUBIC)
	)
	box.mouse_exited.connect(func():
		box.add_theme_stylebox_override("panel", st)
		var tw = box.create_tween()
		tw.tween_property(box, "scale", Vector2(1.0, 1.0), 0.16).set_trans(Tween.TRANS_CUBIC)
	)

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 10)
	box.add_child(vbox)

	var top_strip = ColorRect.new()
	top_strip.custom_minimum_size = Vector2(0, 5)
	top_strip.color = glow_color.lightened(0.25)
	top_strip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(top_strip)

	var badge_m = MarginContainer.new()
	badge_m.add_theme_constant_override("margin_top", 10)
	vbox.add_child(badge_m)

	var badge = Label.new()
	badge.text = "✨ PROMO EXCLUSIVA"
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.add_theme_font_size_override("font_size", 13)
	badge.add_theme_color_override("font_color", Color(0.72, 0.62, 1.0))
	badge_m.add_child(badge)

	var img_rect_promo = TextureRect.new()
	img_rect_promo.custom_minimum_size = Vector2(165, 230)
	img_rect_promo.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	img_rect_promo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	img_rect_promo.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(img_rect_promo)
	_load_texture_into(img_rect_promo, img_path)

	var zoom_btn_promo = Button.new()
	zoom_btn_promo.set_anchors_preset(Control.PRESET_FULL_RECT)
	zoom_btn_promo.flat = true
	zoom_btn_promo.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var zh_promo = StyleBoxFlat.new()
	zh_promo.bg_color = Color(1, 1, 1, 0.08)
	zh_promo.set_corner_radius_all(8)
	zoom_btn_promo.add_theme_stylebox_override("hover", zh_promo)
	var _zp_promo = img_path; var _zn_promo = card_name
	zoom_btn_promo.pressed.connect(func(): _show_image_zoom(shop_root, _zp_promo, _zn_promo))
	img_rect_promo.add_child(zoom_btn_promo)

	var name_lbl = Label.new()
	name_lbl.text = card_name
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 18)
	name_lbl.add_theme_color_override("font_color", C.COLOR_TEXT)
	vbox.add_child(name_lbl)

	var price_hb = HBoxContainer.new()
	price_hb.alignment = BoxContainer.ALIGNMENT_CENTER
	price_hb.add_theme_constant_override("separation", 6)
	vbox.add_child(price_hb)

	var pi = Label.new()
	pi.text = "💎"
	pi.add_theme_font_size_override("font_size", 18)
	price_hb.add_child(pi)

	var pl = Label.new()
	pl.text = str(price_gems)
	pl.add_theme_font_size_override("font_size", 22)
	pl.add_theme_color_override("font_color", Color(0.55, 0.82, 1.0))
	price_hb.add_child(pl)

	var m = MarginContainer.new()
	m.add_theme_constant_override("margin_left",   16)
	m.add_theme_constant_override("margin_right",  16)
	m.add_theme_constant_override("margin_bottom", 16)
	vbox.add_child(m)

	var buy_btn = _make_buy_button("💎 Comprar", glow_color)
	buy_btn.pressed.connect(func(): _buy_promo_card(shop_root, menu, card_id, price_gems, buy_btn))
	m.add_child(buy_btn)


# ── CARD DE SLOT ──────────────────────────────────────────────
static func _create_slot_upgrade_card(shop_root, menu, parent, price) -> void:
	var C   = menu
	var box = PanelContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.custom_minimum_size   = Vector2(0, 260)

	var st = StyleBoxFlat.new()
	st.bg_color = Color(0.10, 0.08, 0.16, 0.97)
	st.border_width_left = 1; st.border_width_right  = 1
	st.border_width_top  = 1; st.border_width_bottom = 1
	st.border_color = Color(C.COLOR_PURPLE.r, C.COLOR_PURPLE.g, C.COLOR_PURPLE.b, 0.45)
	st.corner_radius_top_left    = 16; st.corner_radius_top_right    = 16
	st.corner_radius_bottom_left = 16; st.corner_radius_bottom_right = 16
	box.add_theme_stylebox_override("panel", st)
	parent.add_child(box)

	box.mouse_entered.connect(func():
		var st_h = st.duplicate()
		st_h.border_color = C.COLOR_PURPLE
		st_h.shadow_color = Color(C.COLOR_PURPLE.r, C.COLOR_PURPLE.g, C.COLOR_PURPLE.b, 0.40)
		st_h.shadow_size  = 16
		box.add_theme_stylebox_override("panel", st_h)
		var tw = box.create_tween()
		tw.tween_property(box, "scale", Vector2(1.025, 1.025), 0.14)
	)
	box.mouse_exited.connect(func():
		box.add_theme_stylebox_override("panel", st)
		var tw = box.create_tween()
		tw.tween_property(box, "scale", Vector2(1.0, 1.0), 0.16)
	)

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 16)
	box.add_child(vbox)

	var top_strip = ColorRect.new()
	top_strip.custom_minimum_size = Vector2(0, 5)
	top_strip.color = C.COLOR_PURPLE
	top_strip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(top_strip)
	vbox.add_child(UITheme.vspace(10))

	var icon = Label.new()
	icon.text = "🗃️"
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.add_theme_font_size_override("font_size", 54)
	vbox.add_child(icon)

	var n = Label.new()
	n.text = "Nuevo Slot de Mazo"
	n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	n.add_theme_font_size_override("font_size", 18)
	n.add_theme_color_override("font_color", C.COLOR_TEXT)
	vbox.add_child(n)

	var desc = Label.new()
	desc.text = "Desbloquea un espacio adicional para guardar mazos"
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.add_theme_font_size_override("font_size", 13)
	desc.add_theme_color_override("font_color", Color(0.45, 0.45, 0.55))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc)

	var m = MarginContainer.new()
	m.add_theme_constant_override("margin_left",   16)
	m.add_theme_constant_override("margin_right",  16)
	m.add_theme_constant_override("margin_bottom", 16)
	vbox.add_child(m)

	var btn = _make_buy_button("🪙 " + str(price) + " monedas", C.COLOR_PURPLE)
	btn.pressed.connect(func(): _buy_slot(shop_root, menu, price, btn))
	m.add_child(btn)


# ============================================================
# HTTP
# ============================================================

static func _fetch_bought_decks(shop_root: Control, menu, decks_grid: Control) -> void:
	var loading_lbl = Label.new()
	loading_lbl.name = "DecksLoading"
	loading_lbl.text = "Cargando..."
	loading_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	decks_grid.add_child(loading_lbl)

	var http = HTTPRequest.new()
	shop_root.add_child(http)

	http.request_completed.connect(func(result, code, _h, body):
		http.queue_free()
		loading_lbl.queue_free()

		var bought: Array = []
		if result == HTTPRequest.RESULT_SUCCESS and code == 200:
			var data = JSON.parse_string(body.get_string_from_utf8())
			if data: bought = data.get("bought_decks", [])
		else:
			var err_lbl = Label.new()
			err_lbl.text = "⚠ Error al cargar decks"
			err_lbl.add_theme_color_override("font_color", Color(0.8, 0.3, 0.3))
			decks_grid.add_child(err_lbl)
			return

		_create_deck_card(shop_root, menu, decks_grid,
			"lc_starter_turmoil", "Deck Turmoil",
			"res://assets/Sobres/Turmoil.jpg",
			"res://assets/Sobres/TurmoilBack.png",
			"⚡🌊 Dark Pokémon + Lightning",
			300, Color(0.2, 0.5, 0.9),
			"lc_starter_turmoil" in bought
		)
		_create_deck_card(shop_root, menu, decks_grid,
			"lc_starter_lava", "Deck Lava",
			"res://assets/Sobres/Lava.jpg",
			"res://assets/Sobres/LavaBack.png",
			"🔥🥊 Fire + Fighting",
			300, Color(0.9, 0.3, 0.1),
			"lc_starter_lava" in bought
		)
	)

	http.request(
		NetworkManager.BASE_URL + "/api/shop/my-decks",
		["Authorization: Bearer " + NetworkManager.token],
		HTTPClient.METHOD_GET, ""
	)


static func _buy_deck(shop_root: Control, menu, deck_id: String, price: int, btn: Button) -> void:
	if PlayerData.coins < price:
		_show_toast(shop_root, "🪙 Monedas insuficientes", Color(0.8, 0.2, 0.2))
		return
	btn.disabled = true; btn.text = "Comprando..."
	var http = HTTPRequest.new()
	shop_root.add_child(http)
	http.request_completed.connect(func(result, code, _h, body):
		http.queue_free()
		if result != HTTPRequest.RESULT_SUCCESS or code != 200:
			var err_data = JSON.parse_string(body.get_string_from_utf8())
			var msg = err_data.get("error", "Error al comprar") if err_data else "Error de red"
			_show_toast(shop_root, "⚠ " + msg, Color(0.8, 0.2, 0.2))
			btn.disabled = false; btn.text = "🪙 " + str(price) + " monedas"
			return
		var data = JSON.parse_string(body.get_string_from_utf8())
		if not data or not data.get("success", false):
			_show_toast(shop_root, "⚠ " + data.get("error", "Error"), Color(0.8, 0.2, 0.2))
			btn.disabled = false; btn.text = "🪙 " + str(price) + " monedas"
			return
		if data.has("coins_left"): PlayerData.coins = data["coins_left"]
		_update_currency_ui(shop_root)
		var cards_list = data.get("cards_list", [])
		for card_id in cards_list: PlayerData.add_card(card_id)
		btn.text = "✅ Ya obtenido"; btn.disabled = true
		var st_d = StyleBoxFlat.new()
		st_d.bg_color = Color(0.10, 0.20, 0.10, 0.90)
		st_d.corner_radius_top_left = 10; st_d.corner_radius_top_right = 10
		st_d.corner_radius_bottom_left = 10; st_d.corner_radius_bottom_right = 10
		btn.add_theme_stylebox_override("disabled", st_d)
		btn.add_theme_color_override("font_disabled_color", Color(0.38, 0.70, 0.38))
		SoundManager.play("purchase")
		_show_toast(shop_root, "✓ Deck obtenido · " + str(data.get("cards_added", 0)) + " cartas añadidas", Color(0.2, 0.7, 0.3))
	)
	http.request(NetworkManager.BASE_URL + "/api/shop/buy-deck",
		["Content-Type: application/json", "Authorization: Bearer " + NetworkManager.token],
		HTTPClient.METHOD_POST, JSON.stringify({"deck_id": deck_id, "currency": "coins"}))


static func _buy_pack_multi(shop_root: Control, menu, pack_id: String, price: int, qty_ref: Array, buy_btn: Button, currency := "coins") -> void:
	const BATCH_SIZE = 10
	var qty     = qty_ref[0]
	var balance = PlayerData.gems if currency == "gems" else PlayerData.coins
	var icon    = "💎" if currency == "gems" else "🪙"

	if balance < price * qty:
		_show_toast(shop_root, icon + " Saldo insuficiente (%d sobres × %d)" % [qty, price], Color(0.8, 0.2, 0.2))
		return

	buy_btn.disabled = true
	buy_btn.text = "Comprando 0/%d..." % qty

	var completed  = [0]
	var failed     = [false]
	var remaining  = [qty]

	var send_batch = func(self_ref: Callable) -> void:
		if failed[0]: return
		var batch = min(remaining[0], BATCH_SIZE)
		remaining[0] -= batch
		var batch_done = [0]

		for i in range(batch):
			var http = HTTPRequest.new()
			shop_root.add_child(http)
			http.request_completed.connect(func(result, code, _h, body):
				http.queue_free()
				if failed[0]: return

				if result != HTTPRequest.RESULT_SUCCESS or code != 200:
					failed[0] = true
					var err_data = JSON.parse_string(body.get_string_from_utf8())
					_show_toast(shop_root, "⚠ " + (err_data.get("error", "Error") if err_data else "Error de red"), Color(0.8, 0.2, 0.2))
					buy_btn.disabled = false; buy_btn.text = "Comprar"
					return

				var data = JSON.parse_string(body.get_string_from_utf8())
				if not data or not data.get("success", false):
					failed[0] = true
					_show_toast(shop_root, "⚠ " + data.get("error", "Error"), Color(0.8, 0.2, 0.2))
					buy_btn.disabled = false; buy_btn.text = "Comprar"
					return

				if data.has("coins_left"): PlayerData.coins = data["coins_left"]
				if data.has("gems_left"):  PlayerData.gems  = data["gems_left"]
				completed[0] += 1
				batch_done[0] += 1
				buy_btn.text = "Comprando %d/%d..." % [completed[0], qty]

				if batch_done[0] >= batch:
					_update_currency_ui(shop_root)
					if completed[0] >= qty:
						buy_btn.disabled = false
						buy_btn.text = "Comprar"
						SoundManager.play("purchase")
						_show_toast(shop_root, "✓ %d sobre%s guardado%s" % [qty, "s" if qty > 1 else "", "s" if qty > 1 else ""], Color(0.2, 0.7, 0.3))
					else:
						self_ref.call(self_ref)
			)
			http.request(NetworkManager.BASE_URL + "/api/shop/buy",
				["Content-Type: application/json", "Authorization: Bearer " + NetworkManager.token],
				HTTPClient.METHOD_POST, JSON.stringify({"pack_type": pack_id, "currency": currency}))

	send_batch.call(send_batch)


static func _buy_pack(shop_root: Control, menu, pack_id: String, price: int, btn: Button, currency := "coins") -> void:
	var balance = PlayerData.gems if currency == "gems" else PlayerData.coins
	if balance < price:
		_show_toast(shop_root, ("💎" if currency == "gems" else "🪙") + " Saldo insuficiente", Color(0.8, 0.2, 0.2))
		return
	btn.disabled = true; btn.text = "Comprando..."
	var http = HTTPRequest.new()
	shop_root.add_child(http)
	http.request_completed.connect(func(result, code, _h, body):
		http.queue_free()
		btn.disabled = false; btn.text = "Comprar"
		if result != HTTPRequest.RESULT_SUCCESS or code != 200:
			var err_data = JSON.parse_string(body.get_string_from_utf8())
			_show_toast(shop_root, "⚠ " + (err_data.get("error", "Error") if err_data else "Error de red"), Color(0.8, 0.2, 0.2))
			return
		var data = JSON.parse_string(body.get_string_from_utf8())
		if not data or not data.get("success", false):
			_show_toast(shop_root, "⚠ " + data.get("error", "Error"), Color(0.8, 0.2, 0.2))
			return
		if data.has("coins_left"): PlayerData.coins = data["coins_left"]
		if data.has("gems_left"):  PlayerData.gems  = data["gems_left"]
		_update_currency_ui(shop_root)
		SoundManager.play("purchase")
		_show_toast(shop_root, "✓ Sobre guardado · " + str(data.get("pending_packs", 0)) + " sin abrir", Color(0.2, 0.7, 0.3))
	)
	http.request(NetworkManager.BASE_URL + "/api/shop/buy",
		["Content-Type: application/json", "Authorization: Bearer " + NetworkManager.token],
		HTTPClient.METHOD_POST, JSON.stringify({"pack_type": pack_id, "currency": currency}))


static func _buy_promo_card(shop_root: Control, menu, card_id: String, price_gems: int, btn: Button) -> void:
	if PlayerData.gems < price_gems:
		_show_toast(shop_root, "💎 Gemas insuficientes", Color(0.8, 0.2, 0.2))
		return
	btn.disabled = true; btn.text = "Comprando..."
	var http = HTTPRequest.new()
	shop_root.add_child(http)
	http.request_completed.connect(func(result, code, _h, body):
		http.queue_free()
		btn.disabled = false; btn.text = "💎 Comprar"
		if result != HTTPRequest.RESULT_SUCCESS or code != 200:
			var err_data = JSON.parse_string(body.get_string_from_utf8())
			_show_toast(shop_root, "⚠ " + (err_data.get("error", "Error") if err_data else "Error de red"), Color(0.8, 0.2, 0.2))
			return
		var data = JSON.parse_string(body.get_string_from_utf8())
		if not data or not data.get("success", false):
			_show_toast(shop_root, "⚠ " + data.get("error", "Error"), Color(0.8, 0.2, 0.2))
			return
		if data.has("coins_left"): PlayerData.coins = data["coins_left"]
		if data.has("gems_left"):  PlayerData.gems  = data["gems_left"]
		_update_currency_ui(shop_root)
		PlayerData.add_card(data.get("card_id", card_id))
		btn.text = "✅ Obtenida"; btn.disabled = true
		_show_toast(shop_root, "✨ ¡Carta promo obtenida!", Color(0.4, 0.2, 0.9))
	)
	http.request(NetworkManager.BASE_URL + "/api/shop/buy-card",
		["Content-Type: application/json", "Authorization: Bearer " + NetworkManager.token],
		HTTPClient.METHOD_POST, JSON.stringify({"card_id": card_id, "currency": "gems"}))


static func open_pack_from_collection(shop_root: Control, menu, pack_type: String, on_done: Callable) -> void:
	var http = HTTPRequest.new()
	shop_root.add_child(http)
	http.request_completed.connect(func(result, code, _h, body):
		http.queue_free()
		if result != HTTPRequest.RESULT_SUCCESS or code != 200:
			_show_toast(shop_root, "⚠ Error al abrir sobre", Color(0.8, 0.2, 0.2))
			return
		var data = JSON.parse_string(body.get_string_from_utf8())
		if data and data.get("success"):
			var cards = data.get("cards_received", [])
			for card in cards: PlayerData.add_card(card)
			on_done.call(cards)
	)
	http.request(NetworkManager.BASE_URL + "/api/shop/open-pack",
		["Content-Type: application/json", "Authorization: Bearer " + NetworkManager.token],
		HTTPClient.METHOD_POST, JSON.stringify({"pack_type": pack_type}))


static func _buy_slot(shop_root: Control, menu, price: int, btn: Button) -> void:
	if PlayerData.coins < price:
		_show_toast(shop_root, "🪙 Monedas insuficientes", Color(0.8, 0.2, 0.2))
		return
	if PlayerData.deck_slots >= 8:
		_show_toast(shop_root, "Ya tienes el máximo de slots desbloqueados", Color(0.8, 0.5, 0.1))
		return
	btn.disabled = true
	var http = HTTPRequest.new()
	shop_root.add_child(http)
	http.request_completed.connect(func(result, code, _h, body):
		http.queue_free()
		btn.disabled = false
		if result != HTTPRequest.RESULT_SUCCESS or code != 200:
			var err_data = JSON.parse_string(body.get_string_from_utf8())
			var msg = err_data.get("error", "Error al comprar") if err_data else "Error de red"
			_show_toast(shop_root, "⚠ " + msg, Color(0.8, 0.2, 0.2))
			return
		var data = JSON.parse_string(body.get_string_from_utf8())
		if not data or not data.get("success", false):
			_show_toast(shop_root, "⚠ " + data.get("error", "Error"), Color(0.8, 0.2, 0.2))
			return
		PlayerData.coins = data.get("coins_left", PlayerData.coins)
		# El servidor devuelve deck_slots con el nuevo total
		if data.has("deck_slots"):
			PlayerData.deck_slots = int(data["deck_slots"])
		else:
			# Fallback por si la versión del servidor es antigua
			PlayerData.deck_slots = clampi(PlayerData.deck_slots + 1, 3, 6)
		_update_currency_ui(shop_root)
		SoundManager.play("purchase")
		_show_toast(shop_root, "✓ Slot %d desbloqueado" % PlayerData.deck_slots, Color(0.2, 0.7, 0.3))
	)
	http.request(NetworkManager.BASE_URL + "/api/shop/buy-slot",
		["Content-Type: application/json", "Authorization: Bearer " + NetworkManager.token],
		HTTPClient.METHOD_POST, "{}")
		
# ── MÉTODOS HTTP PARA MONEDAS ────────────────────────────────
static func _fetch_shop_coins(shop_root: Control, menu, grid: Control) -> void:
	var loading = Label.new()
	loading.text = "Cargando monedas..."
	loading.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	grid.add_child(loading)
	var http = HTTPRequest.new()
	shop_root.add_child(http)
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
		for coin in data.get("coins", []):
			_create_coin_card(shop_root, menu, grid, coin)
	)
	http.request(
		NetworkManager.BASE_URL + "/api/shop/coins",
		["Authorization: Bearer " + NetworkManager.token],
		HTTPClient.METHOD_GET, ""
	)

static func _create_coin_card(shop_root: Control, menu, parent: Control, coin: Dictionary) -> void:
	var C         = menu
	var owned     = coin.get("owned", false)
	var equipped  = coin.get("equipped", false)
	var price_coins = coin.get("price_coins", 0)
	var price_gems  = coin.get("price_gems", 0)
	var use_gems    = price_coins == 0 and price_gems > 0
	var price       = price_gems if use_gems else price_coins
	var coin_id     = coin.get("id", "")
	var coin_name   = coin.get("name", "Moneda")
	var glow        = Color(0.95, 0.78, 0.2)  # dorado por defecto
	var box = PanelContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.custom_minimum_size   = Vector2(0, 240)
	var st = StyleBoxFlat.new()
	st.bg_color = Color(0.08, 0.09, 0.15, 0.97)
	st.border_width_left = 1; st.border_width_right  = 1
	st.border_width_top  = 1; st.border_width_bottom = 1
	if equipped:
		st.border_color = Color(0.95, 0.78, 0.2)
		st.shadow_color = Color(0.95, 0.78, 0.2, 0.40)
		st.shadow_size  = 14
	elif owned:
		st.border_color = Color(0.18, 0.42, 0.18, 0.55)
	else:
		st.border_color = Color(glow.r, glow.g, glow.b, 0.30)
	st.corner_radius_top_left    = 16; st.corner_radius_top_right    = 16
	st.corner_radius_bottom_left = 16; st.corner_radius_bottom_right = 16
	box.add_theme_stylebox_override("panel", st)
	parent.add_child(box)
	# Hover solo si no está comprada/equipada
	if not owned and not equipped:
		box.mouse_entered.connect(func():
			var st_h = st.duplicate()
			st_h.border_color = glow
			st_h.shadow_color = Color(glow.r, glow.g, glow.b, 0.45)
			st_h.shadow_size  = 16
			box.add_theme_stylebox_override("panel", st_h)
			var tw = box.create_tween()
			tw.tween_property(box, "scale", Vector2(1.03, 1.03), 0.14)
		)
		box.mouse_exited.connect(func():
			box.add_theme_stylebox_override("panel", st)
			var tw = box.create_tween()
			tw.tween_property(box, "scale", Vector2(1.0, 1.0), 0.16)
		)
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 10)
	box.add_child(vbox)
	# Franja superior
	var top_strip = ColorRect.new()
	top_strip.custom_minimum_size   = Vector2(0, 5)
	top_strip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_strip.color = Color(0.28, 0.58, 0.28) if owned else glow
	vbox.add_child(top_strip)
	vbox.add_child(UITheme.vspace(10))
	# Badge "EQUIPADA"
	if equipped:
		var badge = Label.new()
		badge.text = "✓ EQUIPADA"
		badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		badge.add_theme_font_size_override("font_size", 12)
		badge.add_theme_color_override("font_color", Color(0.95, 0.78, 0.2))
		vbox.add_child(badge)
# Preview de la moneda (Imagen desde base de datos)
	var file_front = coin.get("file_front", "ENERGY-SMALL-SILVER-NON.png") # Por defecto la clásica
	var base_path = "res://assets/imagen/tokens/TCG Flip Coins/CoinFont/"
	var img_path = base_path + file_front
	
	var icon_rect = TextureRect.new()
	icon_rect.custom_minimum_size = Vector2(90, 90) # Ajusta el tamaño aquí
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(icon_rect)
	
	if file_front != "":
		_load_texture_into(icon_rect, img_path)
		
	# Nombre
	var name_lbl = Label.new()
	name_lbl.text = coin_name
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 17)
	name_lbl.add_theme_color_override("font_color",
		Color(0.95, 0.78, 0.2) if equipped else
		Color(0.48, 0.72, 0.48) if owned else
		C.COLOR_TEXT
	)
	vbox.add_child(name_lbl)
	# Descripción opcional
	var desc = coin.get("description", "")
	if desc != "":
		var desc_lbl = Label.new()
		desc_lbl.text = desc
		desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		desc_lbl.add_theme_font_size_override("font_size", 13)
		desc_lbl.add_theme_color_override("font_color", Color(0.45, 0.45, 0.55))
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox.add_child(desc_lbl)
	var m = MarginContainer.new()
	m.add_theme_constant_override("margin_left",   16)
	m.add_theme_constant_override("margin_right",  16)
	m.add_theme_constant_override("margin_bottom", 16)
	vbox.add_child(m)
	# Botón según estado
# Botón según estado
	var btn: Button
	if equipped or owned:
		btn = _make_buy_button("✅ Obtenida", Color(0.4, 0.75, 0.4), true, "✅ Obtenida")
	else:
		var label = ("💎 %d" % price) if use_gems else ("🪙 %d" % price)
		btn = _make_buy_button(label, glow)
		btn.pressed.connect(func(): _buy_coin(shop_root, menu, coin_id, price, use_gems, btn, box, st))
	m.add_child(btn)

static func _buy_coin(shop_root: Control, menu, coin_id: String,
		price: int, use_gems: bool, btn: Button,
		box: PanelContainer, st: StyleBoxFlat) -> void:
	var balance = PlayerData.gems if use_gems else PlayerData.coins
	if balance < price:
		_show_toast(shop_root, ("💎" if use_gems else "🪙") + " Saldo insuficiente", Color(0.8, 0.2, 0.2))
		return
	btn.disabled = true; btn.text = "Comprando..."
	var http = HTTPRequest.new()
	shop_root.add_child(http)
	http.request_completed.connect(func(result, code, _h, body):
		http.queue_free()
		if result != HTTPRequest.RESULT_SUCCESS or code != 200:
			var err = JSON.parse_string(body.get_string_from_utf8())
			_show_toast(shop_root, "⚠ " + (err.get("error", "Error") if err else "Error de red"), Color(0.8, 0.2, 0.2))
			btn.disabled = false; btn.text = ("💎" if use_gems else "🪙") + " " + str(price)
			return
		var data = JSON.parse_string(body.get_string_from_utf8())
		if not data or not data.get("success", false):
			_show_toast(shop_root, "⚠ " + data.get("error", "Error"), Color(0.8, 0.2, 0.2))
			btn.disabled = false; btn.text = ("💎" if use_gems else "🪙") + " " + str(price)
			return
		if data.has("coins_left"): PlayerData.coins = data["coins_left"]
		if data.has("gems_left"):  PlayerData.gems  = data["gems_left"]
		_update_currency_ui(shop_root)
		SoundManager.play("purchase")
# Cambiar a estado "Obtenida"
		btn.text = "✅ Obtenida"
		btn.disabled = true
		var st_owned = st.duplicate()
		st_owned.border_color = Color(0.18, 0.42, 0.18, 0.55)
		box.add_theme_stylebox_override("panel", st_owned)
		_show_toast(shop_root, "🪙 ¡Moneda desbloqueada! Equípala desde tu Colección.", Color(0.2, 0.7, 0.3))
	)
	http.request(
		NetworkManager.BASE_URL + "/api/shop/buy-coin",
		["Content-Type: application/json", "Authorization: Bearer " + NetworkManager.token],
		HTTPClient.METHOD_POST,
		JSON.stringify({"coin_id": coin_id, "currency": "gems" if use_gems else "coins"})
	)

static func _equip_coin(shop_root: Control, menu, coin_id: String,
		box: PanelContainer, st: StyleBoxFlat, btn: Button) -> void:
	var http = HTTPRequest.new()
	shop_root.add_child(http)
	http.request_completed.connect(func(result, code, _h, body):
		http.queue_free()
		if result != HTTPRequest.RESULT_SUCCESS or code != 200:
			_show_toast(shop_root, "⚠ Error al equipar", Color(0.8, 0.2, 0.2))
			return
		var data = JSON.parse_string(body.get_string_from_utf8())
		if not data or not data.get("success", false):
			_show_toast(shop_root, "⚠ " + data.get("error", "Error"), Color(0.8, 0.2, 0.2))
			return
		btn.text = "✅ Equipada"; btn.disabled = true
		var st_eq = st.duplicate()
		st_eq.border_color = Color(0.95, 0.78, 0.2)
		st_eq.shadow_color = Color(0.95, 0.78, 0.2, 0.40)
		st_eq.shadow_size  = 14
		box.add_theme_stylebox_override("panel", st_eq)
		_show_toast(shop_root, "✨ Moneda equipada", Color(0.95, 0.78, 0.2))
		
		# NOTA: Para que las demás cartas vuelvan a su estado normal (desequipada), 
		# la forma más sencilla en Godot es reconstruir la lista de monedas llamando 
		# de nuevo a la API para refrescar la UI (o podrías almacenar referencias globales).
		# Por ahora refrescamos toda la tienda para mayor facilidad:
		if menu.has_method("refresh_shop"):
			menu.refresh_shop() 
	)
	http.request(
		NetworkManager.BASE_URL + "/api/shop/equip-coin",
		["Content-Type: application/json", "Authorization: Bearer " + NetworkManager.token],
		HTTPClient.METHOD_POST,
		JSON.stringify({"coin_id": coin_id})
	)

# ============================================================
# ZOOM DE IMAGEN
# ============================================================
static func _show_deck_zoom(zoom_anchor: Control, front_path: String, back_path: String, label: String) -> void:
	if zoom_anchor.get_node_or_null("ShopZoomOverlay"): return

	var vp_size = zoom_anchor.get_viewport().get_visible_rect().size

	var overlay = Control.new()
	overlay.name = "ShopZoomOverlay"
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 400
	zoom_anchor.add_child(overlay)

	var dim = ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.0, 0.02, 0.06, 0.92)
	overlay.add_child(dim)

	var IMG_W = round(vp_size.x * 0.38)
	var IMG_H = round(vp_size.y * 0.72)
	var gap   = 24.0
	var total_w = IMG_W * 2 + gap
	var start_x = round((vp_size.x - total_w) / 2.0)
	var img_y   = round(vp_size.y / 2.0 - IMG_H / 2.0) - 20.0

	for i in 2:
		var img_path = front_path if i == 0 else back_path
		var img_rect = TextureRect.new()
		img_rect.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
		img_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		img_rect.custom_minimum_size = Vector2(IMG_W, IMG_H)
		img_rect.size     = Vector2(IMG_W, IMG_H)
		img_rect.position = Vector2(start_x + i * (IMG_W + gap), img_y)
		img_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		overlay.add_child(img_rect)

		var tex = _get_texture(img_path)
		if not tex:
			tex = load(img_path)
			if tex: _cache_texture(img_path, tex)
		if tex: img_rect.texture = tex

		img_rect.scale = Vector2(0.72, 0.72)
		img_rect.pivot_offset = Vector2(IMG_W / 2.0, IMG_H / 2.0)

	var name_lbl = Label.new()
	name_lbl.text = label
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.position = Vector2(0, img_y + IMG_H + 10.0)
	name_lbl.size     = Vector2(vp_size.x, 30)
	name_lbl.add_theme_font_size_override("font_size", 24)
	name_lbl.add_theme_color_override("font_color", Color(0.93, 0.82, 0.45))
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(name_lbl)

	var hint = Label.new()
	hint.text = "Clic o Esc para cerrar"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.position = Vector2(0, vp_size.y - 38)
	hint.size     = Vector2(vp_size.x, 22)
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55, 0.75))
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(hint)

	var close_btn = Button.new()
	close_btn.set_anchors_preset(Control.PRESET_FULL_RECT)
	close_btn.flat = true
	var empty_st = StyleBoxEmpty.new()
	for sn in ["normal", "hover", "pressed", "focus"]:
		close_btn.add_theme_stylebox_override(sn, empty_st)
	close_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	close_btn.pressed.connect(func(): _close_image_zoom(overlay))
	overlay.add_child(close_btn)

	overlay.modulate.a = 0.0
	var tw = overlay.create_tween()
	tw.set_parallel(true)
	tw.tween_property(overlay, "modulate:a", 1.0, 0.18)
	for child in overlay.get_children():
		if child is TextureRect:
			tw.tween_property(child, "scale", Vector2(1.0, 1.0), 0.22) \
				.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


static func _show_image_zoom(zoom_anchor: Control, img_path: String, label: String) -> void:
	if zoom_anchor.get_node_or_null("ShopZoomOverlay"): return

	var vp_size = zoom_anchor.get_viewport().get_visible_rect().size

	var overlay = Control.new()
	overlay.name = "ShopZoomOverlay"
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 400
	zoom_anchor.add_child(overlay)

	var dim = ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.0, 0.02, 0.06, 0.92)
	overlay.add_child(dim)

	var MAX_W = vp_size.x * 0.58
	var MAX_H = vp_size.y * 0.78

	var img_rect = TextureRect.new()
	img_rect.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	img_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	img_rect.custom_minimum_size = Vector2(MAX_W, MAX_H)
	img_rect.size = Vector2(MAX_W, MAX_H)
	img_rect.position = Vector2(
		round(vp_size.x / 2.0 - MAX_W / 2.0),
		round(vp_size.y / 2.0 - MAX_H / 2.0) - 24.0
	)
	img_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(img_rect)

	var cached = _get_texture(img_path)
	if cached:
		img_rect.texture = cached
	else:
		var tex = load(img_path)
		if tex:
			_cache_texture(img_path, tex)
			img_rect.texture = tex

	var name_lbl = Label.new()
	name_lbl.text = label
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.position = Vector2(0, img_rect.position.y + MAX_H + 10.0)
	name_lbl.size     = Vector2(vp_size.x, 30)
	name_lbl.add_theme_font_size_override("font_size", 24)
	name_lbl.add_theme_color_override("font_color", Color(0.93, 0.82, 0.45))
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(name_lbl)

	var hint = Label.new()
	hint.text = "Clic o Esc para cerrar"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.position = Vector2(0, vp_size.y - 38)
	hint.size     = Vector2(vp_size.x, 22)
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55, 0.75))
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(hint)

	var close_btn = Button.new()
	close_btn.set_anchors_preset(Control.PRESET_FULL_RECT)
	close_btn.flat = true
	var empty_st = StyleBoxEmpty.new()
	for sn in ["normal", "hover", "pressed", "focus"]:
		close_btn.add_theme_stylebox_override(sn, empty_st)
	close_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	close_btn.pressed.connect(func(): _close_image_zoom(overlay))
	overlay.add_child(close_btn)

	overlay.modulate.a  = 0.0
	img_rect.scale      = Vector2(0.72, 0.72)
	img_rect.pivot_offset = Vector2(MAX_W / 2.0, MAX_H / 2.0)

	var tw = overlay.create_tween()
	tw.set_parallel(true)
	tw.tween_property(overlay,  "modulate:a", 1.0,               0.18)
	tw.tween_property(img_rect, "scale",      Vector2(1.0, 1.0), 0.22) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


static func _close_image_zoom(overlay: Control) -> void:
	if not is_instance_valid(overlay): return
	var tw = overlay.create_tween()
	tw.set_parallel(true)
	tw.tween_property(overlay, "modulate:a", 0.0, 0.14)
	tw.tween_property(overlay, "scale",      Vector2(0.92, 0.92), 0.14)
	tw.tween_callback(overlay.queue_free).set_delay(0.14)


# ── HELPERS ───────────────────────────────────────────────────
static func _update_currency_ui(shop_root: Control) -> void:
	var coins_lbl = UITheme.find_node(shop_root, "CoinsLabel") as Label
	if coins_lbl: coins_lbl.text = str(PlayerData.coins)
	var gems_lbl = UITheme.find_node(shop_root, "GemsLabel") as Label
	if gems_lbl: gems_lbl.text = str(PlayerData.gems)


static func _show_toast(parent: Control, msg: String, color: Color) -> void:
	var toast = Label.new()
	toast.text = msg
	toast.add_theme_font_size_override("font_size", 17)
	toast.add_theme_color_override("font_color", Color.WHITE)
	var st = StyleBoxFlat.new()
	st.bg_color    = Color(color.r * 0.25, color.g * 0.25, color.b * 0.25, 0.96)
	st.border_color = color
	st.border_width_left = 1; st.border_width_right  = 1
	st.border_width_top  = 1; st.border_width_bottom = 1
	st.corner_radius_top_left    = 10; st.corner_radius_top_right    = 10
	st.corner_radius_bottom_left = 10; st.corner_radius_bottom_right = 10
	st.content_margin_left = 24; st.content_margin_right  = 24
	st.content_margin_top  = 14; st.content_margin_bottom = 14
	toast.add_theme_stylebox_override("normal", st)
	toast.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	toast.offset_bottom = -60; toast.offset_top  = -120
	toast.offset_left   = -300; toast.offset_right = 300
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast.z_index = 100
	parent.add_child(toast)
	var tw = toast.create_tween()
	tw.tween_property(toast, "position:y", toast.position.y - 12, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_interval(2.2)
	tw.tween_property(toast, "modulate:a", 0.0, 0.5)
	tw.tween_callback(toast.queue_free)


# ── RAREZA ────────────────────────────────────────────────────
static func rarity_color(rarity: String) -> Color:
	match rarity:
		"RARE":       return Color(0.95, 0.85, 0.1,  1.0)
		"RARE_HOLO":  return Color(0.2,  0.85, 1.0,  1.0)
		"ULTRA_RARE": return Color(1.0,  0.45, 0.05, 1.0)
		_:            return Color(0.6,  0.6,  0.6,  1.0)

static func rarity_weight(rarity: String) -> int:
	match rarity:
		"COMMON":     return 0
		"UNCOMMON":   return 1
		"RARE":       return 2
		"RARE_HOLO":  return 3
		"ULTRA_RARE": return 4
	return 0

static func clicks_needed(rarity: String) -> int:
	match rarity:
		"RARE":       return 2
		"RARE_HOLO":  return 3
		"ULTRA_RARE": return 6
		_:            return 1

const ULTRA_RARE_CHARGE_COLORS = [
	Color(0.3,  0.0,  0.6,  0.8),
	Color(0.0,  0.2,  0.9,  0.8),
	Color(0.0,  0.8,  0.4,  0.8),
	Color(0.95, 0.8,  0.0,  0.8),
	Color(1.0,  0.3,  0.0,  0.8),
	Color(1.0,  0.05, 0.05, 0.9),
]

static func spawn_particles(parent: Control, origin: Vector2, rarity: String) -> void:
	var base_color = rarity_color(rarity)
	var count = 12 if rarity == "RARE" else (20 if rarity == "RARE_HOLO" else 35)
	for i in range(count):
		var p = ColorRect.new()
		var size = randf_range(3.0, 8.0)
		p.custom_minimum_size = Vector2(size, size)
		p.color = base_color.lightened(randf_range(0.0, 0.4))
		p.position = origin
		parent.add_child(p)
		var angle  = randf_range(0.0, TAU)
		var speed  = randf_range(60.0, 220.0)
		var target = origin + Vector2(cos(angle), sin(angle)) * speed
		var tw = p.create_tween().set_parallel(true)
		tw.tween_property(p, "position", target, randf_range(0.5, 1.0)).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.tween_property(p, "modulate:a", 0.0, randf_range(0.4, 0.9)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_callback(p.queue_free).set_delay(1.0)
