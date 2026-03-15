extends Node

# ============================================================
# HomeScreen.gd
# Banner rotativo + Comunidad + Cortina de Noticias
# Sin header — botón Novedades flotante con dot pulsante
# ============================================================

const API_URL = "NetworkManager.BASE_URL/api/social"

const NEWS = [
	{
		"tag":   "🆕 NOVEDAD",
		"title": "Pokémon TCG Neo Genesis Alpha",
		"body":  "Ya puedes jugar online con los 111 pokémon de Neo Genesis. Crea una mesa, invita a un amigo y a jugar.",
		"color": Color(0.12, 0.28, 0.45),
		"image": "res://assets/imagen/banner/banner1.png",
		"url":   "",
	},
	{
		"tag":   "🃏 DECK BUILDER",
		"title": "Construye tu mazo ideal",
		"body":  "Usa el Deck Builder para crear mazos personalizados con tus cartas. Valida la legalidad antes de jugar.",
		"color": Color(0.28, 0.15, 0.40),
		"image": "res://assets/imagen/banner/banner2.png",
		"url":   "",
	},
	{
		"tag":   "📦 SOBRES",
		"title": "Abre sobres de Neo Genesis",
		"body":  "Visita la tienda para abrir sobres y expandir tu colección. ¡Cada sobre trae 9 cartas!",
		"color": Color(0.45, 0.25, 0.10),
		"image": "res://assets/imagen/banner/banner3.png",
		"url":   "",
	},
	{
		"tag":   "🏆 RANKING",
		"title": "Sube en el ranking",
		"body":  "Gana partidas para subir tu ELO y alcanzar el rango Diamante. Top 20 visible en la pestaña Ranking.",
		"color": Color(0.12, 0.35, 0.25),
		"image": "res://assets/imagen/banner/banner4.png",
		"url":   "",
	},
]

const SERVER_NOTICES = [
	{"date": "Hoy", "text": "¡Mantenimiento programado completado! Los servidores son un 20% más rápidos."},
	{"date": "Ayer", "text": "Se corrigió el bug del PokePower de Elekid (Playful Punch). ¡A golpear se ha dicho!"},
	{"date": "02/03", "text": "¡Nueva temporada de Ranked! Reinicio de ELO en 3 días. Prepárate."},
]

# Iconos reales con rutas de textura
const LINKS = [
	{ "icon_path": "res://assets/iconos/discord.png",   "label": "Discord Oficial",   "url": "https://discord.gg/hkUVgjT6" },
	{ "icon_path": "res://assets/iconos/fb.png",        "label": "Facebook",          "url": "https://www.facebook.com/profile.php?id=61586292251689" },
	{ "icon_path": "res://assets/iconos/instagram.png", "label": "Instagram",         "url": "https://www.instagram.com" },
	{ "icon_path": "res://assets/iconos/web.png",       "label": "neocaoh.cl",        "url": "https://www.neocaoh.cl" },
]

# ============================================================
# CACHÉ ESTÁTICO
# ============================================================
static var _tex_cache:      Dictionary   = {}
static var _custom_font:    Font         = null
static var _font_checked:   bool         = false
static var _st_link_normal: StyleBoxFlat = null
static var _st_link_hover:  StyleBoxFlat = null
static var _st_curtain:     StyleBoxFlat = null
static var _st_notice:      StyleBoxFlat = null

static func clear_cache() -> void:
	_tex_cache.clear()
	_custom_font    = null
	_font_checked   = false
	_st_link_normal = null
	_st_link_hover  = null
	_st_curtain     = null
	_st_notice      = null

static func _get_tex(path: String) -> Texture2D:
	if path not in _tex_cache:
		_tex_cache[path] = load(path) if ResourceLoader.exists(path) else null
	return _tex_cache[path]

static func _get_font() -> Font:
	if not _font_checked:
		_font_checked = true
		if ResourceLoader.exists("res://assets/fonts/title_font.ttf"):
			_custom_font = load("res://assets/fonts/title_font.ttf")
	return _custom_font

static func _get_st_link_normal(C) -> StyleBoxFlat:
	if not _st_link_normal:
		var st = StyleBoxFlat.new()
		st.bg_color = Color(C.COLOR_PANEL.r, C.COLOR_PANEL.g, C.COLOR_PANEL.b, 0.8)
		st.border_color = Color(C.COLOR_GOLD_DIM.r, C.COLOR_GOLD_DIM.g, C.COLOR_GOLD_DIM.b, 0.4)
		st.border_width_left = 1; st.border_width_right  = 1
		st.border_width_top  = 1; st.border_width_bottom = 3
		st.corner_radius_top_left    = 14; st.corner_radius_top_right    = 14
		st.corner_radius_bottom_left = 14; st.corner_radius_bottom_right = 14
		st.shadow_color = Color(0, 0, 0, 0.2); st.shadow_size = 10
		_st_link_normal = st
	return _st_link_normal

static func _get_st_link_hover(C) -> StyleBoxFlat:
	if not _st_link_hover:
		var st = _get_st_link_normal(C).duplicate()
		st.bg_color = Color(C.COLOR_PANEL.r + 0.08, C.COLOR_PANEL.g + 0.08, C.COLOR_PANEL.b + 0.08, 0.95)
		st.border_color = C.COLOR_GOLD
		st.shadow_color = Color(C.COLOR_GOLD.r, C.COLOR_GOLD.g, C.COLOR_GOLD.b, 0.15)
		st.shadow_size = 20
		_st_link_hover = st
	return _st_link_hover

static func _get_st_curtain(C) -> StyleBoxFlat:
	if not _st_curtain:
		var st = StyleBoxFlat.new()
		st.bg_color = Color(0.05, 0.08, 0.1, 0.98)
		st.border_color = C.COLOR_GOLD_DIM
		st.border_width_left = 2
		st.shadow_color = Color(0, 0, 0, 0.8); st.shadow_size = 50
		_st_curtain = st
	return _st_curtain

static func _get_st_notice() -> StyleBoxFlat:
	if not _st_notice:
		var st = StyleBoxFlat.new()
		st.bg_color = Color(1, 1, 1, 0.05)
		st.corner_radius_top_left    = 8; st.corner_radius_top_right    = 8
		st.corner_radius_bottom_left = 8; st.corner_radius_bottom_right = 8
		st.content_margin_left = 15; st.content_margin_right  = 15
		st.content_margin_top  = 15; st.content_margin_bottom = 15
		_st_notice = st
	return _st_notice


# ============================================================
# ENTRY POINT
# ============================================================
static func build(container: Control, menu) -> void:
	var C = menu

	# ── 1. Fondo ──
	var bg_image = TextureRect.new()
	var bg_tex = _get_tex("res://assets/imagen/fondomenu.png")
	if bg_tex: bg_image.texture = bg_tex
	bg_image.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_image.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	bg_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg_image.modulate     = Color(0.2, 0.2, 0.22, 1)
	container.add_child(bg_image)

	# ── 2. Scroll — empieza justo bajo la navbar (92px) ──
	var scroll = ScrollContainer.new()
	scroll.anchor_left  = 0; scroll.anchor_right  = 1
	scroll.anchor_top   = 0; scroll.anchor_bottom = 1
	scroll.offset_top   = 92
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	UITheme.apply_scrollbar_theme(scroll)
	container.add_child(scroll)

	var center_wrap = CenterContainer.new()
	center_wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center_wrap.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	scroll.add_child(center_wrap)

	var inner_v = VBoxContainer.new()
	inner_v.custom_minimum_size = Vector2(1050, 0)
	inner_v.add_theme_constant_override("separation", 35)
	center_wrap.add_child(inner_v)

	var spacer_top = Control.new()
	spacer_top.custom_minimum_size = Vector2(0, 18)
	inner_v.add_child(spacer_top)

	# ── 3. Banner Rotativo ──
	var banner_container = Control.new()
	banner_container.custom_minimum_size = Vector2(1050, 340)
	banner_container.clip_contents = true
	inner_v.add_child(banner_container)

	var current_slide = [0]
	var slides: Array = []

	for i in range(NEWS.size()):
		var slide = _make_slide(NEWS[i], C)
		slide.anchor_left  = 0; slide.anchor_right  = 1
		slide.anchor_top   = 0; slide.anchor_bottom = 1
		slide.modulate.a   = 1.0 if i == 0 else 0.0
		banner_container.add_child(slide)
		slides.append(slide)

	var dots_hb = HBoxContainer.new()
	dots_hb.alignment = BoxContainer.ALIGNMENT_CENTER
	dots_hb.add_theme_constant_override("separation", 10)
	inner_v.add_child(dots_hb)

	var dots: Array = []
	for i in range(NEWS.size()):
		var dot = ColorRect.new()
		dot.custom_minimum_size = Vector2(30, 6) if i == 0 else Vector2(10, 6)
		dot.color = C.COLOR_GOLD if i == 0 else Color(C.COLOR_GOLD_DIM.r, C.COLOR_GOLD_DIM.g, C.COLOR_GOLD_DIM.b, 0.4)
		dots_hb.add_child(dot)
		dots.append(dot)

	var timer = Timer.new()
	timer.wait_time = 5.0
	timer.autostart = true
	container.add_child(timer)
	timer.timeout.connect(func():
		var prev = current_slide[0]
		current_slide[0] = (current_slide[0] + 1) % NEWS.size()
		var next = current_slide[0]
		var tw = container.create_tween().set_parallel(true)
		tw.tween_property(slides[prev], "modulate:a", 0.0, 0.5)
		tw.tween_property(slides[next], "modulate:a", 1.0, 0.5)
		for i in range(dots.size()):
			dots[i].color = C.COLOR_GOLD if i == next else Color(C.COLOR_GOLD_DIM.r, C.COLOR_GOLD_DIM.g, C.COLOR_GOLD_DIM.b, 0.4)
			tw.tween_property(dots[i], "custom_minimum_size:x", 30.0 if i == next else 10.0, 0.3)
	)

	var separator = ColorRect.new()
	separator.custom_minimum_size   = Vector2(200, 2)
	separator.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	separator.color = Color(C.COLOR_GOLD_DIM.r, C.COLOR_GOLD_DIM.g, C.COLOR_GOLD_DIM.b, 0.3)
	inner_v.add_child(separator)

	# ── 4. Comunidad ──
	var links_title = Label.new()
	links_title.text = "ÚNETE A LA COMUNIDAD"
	links_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	links_title.add_theme_font_size_override("font_size", 16)
	links_title.add_theme_color_override("font_color", C.COLOR_GOLD)
	links_title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	inner_v.add_child(links_title)

	var links_hb = HBoxContainer.new()
	links_hb.alignment = BoxContainer.ALIGNMENT_CENTER
	links_hb.add_theme_constant_override("separation", 25)
	inner_v.add_child(links_hb)

	var st_normal = _get_st_link_normal(C)
	var st_hover  = _get_st_link_hover(C)

	for link in LINKS:
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(210, 130)
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		btn.add_theme_stylebox_override("normal",  st_normal)
		btn.add_theme_stylebox_override("hover",   st_hover)
		btn.add_theme_stylebox_override("pressed", st_normal)

		var card_v = VBoxContainer.new()
		card_v.set_anchors_preset(Control.PRESET_FULL_RECT)
		card_v.alignment    = BoxContainer.ALIGNMENT_CENTER
		card_v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card_v.add_theme_constant_override("separation", 10)
		btn.add_child(card_v)

		# Icono desde textura
		var icon_tex = _get_tex(link["icon_path"])
		if icon_tex:
			var tex_rect = TextureRect.new()
			tex_rect.texture              = icon_tex
			tex_rect.custom_minimum_size  = Vector2(48, 48)
			tex_rect.size                 = Vector2(48, 48)
			tex_rect.stretch_mode         = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tex_rect.expand_mode          = TextureRect.EXPAND_IGNORE_SIZE
			tex_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			tex_rect.mouse_filter         = Control.MOUSE_FILTER_IGNORE
			card_v.add_child(tex_rect)
		else:
			# Fallback emoji si no carga la textura
			var icon_lbl = Label.new()
			icon_lbl.text = "🔗"
			icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			icon_lbl.add_theme_font_size_override("font_size", 48)
			card_v.add_child(icon_lbl)

		var txt_lbl = Label.new()
		txt_lbl.text = link["label"]
		txt_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		txt_lbl.add_theme_font_size_override("font_size", 14)
		txt_lbl.add_theme_color_override("font_color", C.COLOR_TEXT)
		card_v.add_child(txt_lbl)

		var url = link["url"]
		btn.pressed.connect(func(): OS.shell_open(url))
		links_hb.add_child(btn)

	var spacer_bot = Control.new()
	spacer_bot.custom_minimum_size = Vector2(0, 40)
	inner_v.add_child(spacer_bot)

	# ── 5. Botón Novedades flotante + Cortina ──
	# IMPORTANTE: se construye al final para que su z_index quede
	# por encima del scroll pero la cortina use z_index >= 200
	# para superar la navbar (z_index 100 de MainMenu)
	_build_news_fab(container, C)


# ============================================================
# BOTÓN FLOTANTE "NOVEDADES" — esquina superior derecha
# ============================================================
static func _build_news_fab(container: Control, C) -> void:
	var fab = PanelContainer.new()
	fab.anchor_left   = 1.0
	fab.anchor_right  = 1.0
	fab.anchor_top    = 0.0
	fab.anchor_bottom = 0.0
	fab.offset_left   = -224
	fab.offset_right  = -16
	fab.offset_top    = 100
	fab.offset_bottom = 142
	fab.z_index       = 50
	fab.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	var st_normal = StyleBoxFlat.new()
	st_normal.bg_color             = Color(0.07, 0.055, 0.02, 0.90)
	st_normal.border_color         = C.COLOR_GOLD
	st_normal.border_width_left    = 1
	st_normal.border_width_right   = 1
	st_normal.border_width_top     = 1
	st_normal.border_width_bottom  = 2
	st_normal.corner_radius_top_left     = 21
	st_normal.corner_radius_top_right    = 21
	st_normal.corner_radius_bottom_left  = 21
	st_normal.corner_radius_bottom_right = 21
	st_normal.shadow_color = Color(C.COLOR_GOLD.r, C.COLOR_GOLD.g, C.COLOR_GOLD.b, 0.15)
	st_normal.shadow_size  = 12
	st_normal.content_margin_left   = 16
	st_normal.content_margin_right  = 16
	st_normal.content_margin_top    = 0
	st_normal.content_margin_bottom = 0
	fab.add_theme_stylebox_override("panel", st_normal)

	var st_hover = st_normal.duplicate()
	st_hover.bg_color     = Color(0.12, 0.09, 0.03, 0.97)
	st_hover.shadow_size  = 22
	st_hover.shadow_color = Color(C.COLOR_GOLD.r, C.COLOR_GOLD.g, C.COLOR_GOLD.b, 0.30)

	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 10)
	fab.add_child(hbox)

	var dot_panel = Panel.new()
	dot_panel.custom_minimum_size = Vector2(9, 9)
	dot_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var dot_st = StyleBoxFlat.new()
	dot_st.bg_color = C.COLOR_GOLD
	dot_st.corner_radius_top_left     = 5
	dot_st.corner_radius_top_right    = 5
	dot_st.corner_radius_bottom_left  = 5
	dot_st.corner_radius_bottom_right = 5
	dot_panel.add_theme_stylebox_override("panel", dot_st)
	hbox.add_child(dot_panel)

	var lbl = Label.new()
	lbl.text = "Novedades del servidor"
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", C.COLOR_GOLD)
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(lbl)

	var arrow = Label.new()
	arrow.text = "›"
	arrow.add_theme_font_size_override("font_size", 18)
	arrow.add_theme_color_override("font_color", Color(C.COLOR_GOLD.r, C.COLOR_GOLD.g, C.COLOR_GOLD.b, 0.6))
	arrow.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(arrow)

	container.add_child(fab)

	var pulse = container.create_tween().set_loops()
	pulse.tween_property(dot_panel, "modulate:a", 0.25, 1.0).set_trans(Tween.TRANS_SINE)
	pulse.tween_property(dot_panel, "modulate:a", 1.0,  1.0).set_trans(Tween.TRANS_SINE)

	fab.mouse_entered.connect(func():
		fab.add_theme_stylebox_override("panel", st_hover)
		lbl.add_theme_color_override("font_color", Color(1.0, 0.95, 0.75))
		arrow.add_theme_color_override("font_color", C.COLOR_GOLD)
	)
	fab.mouse_exited.connect(func():
		fab.add_theme_stylebox_override("panel", st_normal)
		lbl.add_theme_color_override("font_color", C.COLOR_GOLD)
		arrow.add_theme_color_override("font_color", Color(C.COLOR_GOLD.r, C.COLOR_GOLD.g, C.COLOR_GOLD.b, 0.6))
	)

	_build_curtain(container, C, fab)


# ============================================================
# CORTINA (DRAWER)
# z_index 200/201 para superar la navbar de MainMenu (z 100)
# ============================================================
static func _build_curtain(container: Control, C, trigger: Control) -> void:
	# Dimmer cubre TODO incluyendo la navbar
	var dimmer = ColorRect.new()
	dimmer.set_anchors_preset(Control.PRESET_FULL_RECT)
	dimmer.color        = Color(0, 0, 0, 0.0)
	dimmer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dimmer.z_index      = 200   # ← por encima de la navbar (100)
	container.add_child(dimmer)

	var curtain   = Panel.new()
	var curtain_w = 400.0
	curtain.anchor_left  = 1.0; curtain.anchor_right  = 1.0
	curtain.anchor_top   = 0.0; curtain.anchor_bottom = 1.0
	curtain.offset_left  = 0
	curtain.offset_right = curtain_w
	curtain.z_index      = 201  # ← por encima del dimmer
	curtain.add_theme_stylebox_override("panel", _get_st_curtain(C))
	container.add_child(curtain)

	var c_margin = MarginContainer.new()
	c_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	c_margin.add_theme_constant_override("margin_left",   25)
	c_margin.add_theme_constant_override("margin_right",  25)
	c_margin.add_theme_constant_override("margin_top",    40)
	c_margin.add_theme_constant_override("margin_bottom", 40)
	curtain.add_child(c_margin)

	var c_vbox = VBoxContainer.new()
	c_vbox.add_theme_constant_override("separation", 20)
	c_margin.add_child(c_vbox)

	var top_hbox = HBoxContainer.new()
	c_vbox.add_child(top_hbox)

	var c_title = Label.new()
	c_title.text = "NOTICIAS DEL SERVIDOR"
	c_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	c_title.add_theme_font_size_override("font_size", 16)
	c_title.add_theme_color_override("font_color", C.COLOR_GOLD)
	top_hbox.add_child(c_title)

	var close_btn = Button.new()
	close_btn.text = "✖"
	close_btn.flat = true
	close_btn.add_theme_font_size_override("font_size", 20)
	close_btn.add_theme_color_override("font_color",       Color(0.6, 0.6, 0.6))
	close_btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0))
	close_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	top_hbox.add_child(close_btn)

	var c_sep = ColorRect.new()
	c_sep.custom_minimum_size = Vector2(0, 1)
	c_sep.color = Color(C.COLOR_GOLD_DIM.r, C.COLOR_GOLD_DIM.g, C.COLOR_GOLD_DIM.b, 0.5)
	c_vbox.add_child(c_sep)

	var st_notice = _get_st_notice()
	for notice in SERVER_NOTICES:
		var n_panel = PanelContainer.new()
		n_panel.add_theme_stylebox_override("panel", st_notice)
		c_vbox.add_child(n_panel)

		var n_v = VBoxContainer.new()
		n_v.add_theme_constant_override("separation", 8)
		n_panel.add_child(n_v)

		var date_lbl = Label.new()
		date_lbl.text = "🕒 " + notice["date"]
		date_lbl.add_theme_font_size_override("font_size", 11)
		date_lbl.add_theme_color_override("font_color", Color(0.5, 0.8, 0.5))
		n_v.add_child(date_lbl)

		var text_lbl = Label.new()
		text_lbl.text = notice["text"]
		text_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		text_lbl.add_theme_font_size_override("font_size", 13)
		text_lbl.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
		n_v.add_child(text_lbl)

	var is_open = [false]
	var toggle_curtain = func():
		is_open[0] = !is_open[0]
		var tw = container.create_tween().set_parallel(true).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
		if is_open[0]:
			dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
			tw.tween_property(dimmer,  "color:a",      0.5,        0.3)
			tw.tween_property(curtain, "offset_left",  -curtain_w, 0.4)
			tw.tween_property(curtain, "offset_right", 0.0,        0.4)
		else:
			dimmer.mouse_filter = Control.MOUSE_FILTER_IGNORE
			tw.tween_property(dimmer,  "color:a",      0.0,       0.3)
			tw.tween_property(curtain, "offset_left",  0.0,       0.4)
			tw.tween_property(curtain, "offset_right", curtain_w, 0.4)

	trigger.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			toggle_curtain.call()
	)
	close_btn.pressed.connect(toggle_curtain)
	dimmer.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			if is_open[0]: toggle_curtain.call()
	)


# ============================================================
# SLIDE DEL BANNER
# ============================================================
static func _make_slide(news: Dictionary, C) -> Panel:
	var panel = Panel.new()
	panel.clip_contents = true

	var st = StyleBoxFlat.new()
	st.bg_color = news["color"]
	st.corner_radius_top_left    = 16; st.corner_radius_top_right    = 16
	st.corner_radius_bottom_left = 16; st.corner_radius_bottom_right = 16
	st.shadow_color = Color(0, 0, 0, 0.4); st.shadow_size = 30
	panel.add_theme_stylebox_override("panel", st)

	if news.has("image") and news["image"] != "":
		var tex = _get_tex(news["image"])
		if tex:
			var bg_img = TextureRect.new()
			bg_img.texture     = tex
			bg_img.set_anchors_preset(Control.PRESET_FULL_RECT)
			bg_img.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
			bg_img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			panel.add_child(bg_img)

			var dim = TextureRect.new()
			var grad = Gradient.new()
			grad.add_point(0.0, Color(0, 0, 0, 0.85))
			grad.add_point(0.6, Color(0, 0, 0, 0.4))
			grad.add_point(1.0, Color(0, 0, 0, 0.0))
			var grad_tex = GradientTexture1D.new()
			grad_tex.gradient = grad
			dim.texture = grad_tex
			dim.set_anchors_preset(Control.PRESET_FULL_RECT)
			panel.add_child(dim)

	var m = MarginContainer.new()
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	m.add_theme_constant_override("margin_left",   60)
	m.add_theme_constant_override("margin_right",  60)
	m.add_theme_constant_override("margin_top",    40)
	m.add_theme_constant_override("margin_bottom", 40)
	panel.add_child(m)

	var v = VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 15)
	m.add_child(v)

	var custom_font = _get_font()

	var tag_lbl = Label.new()
	tag_lbl.text = news["tag"]
	tag_lbl.add_theme_font_size_override("font_size", 14)
	if custom_font: tag_lbl.add_theme_font_override("font", custom_font)
	tag_lbl.add_theme_color_override("font_color",        Color(1, 0.85, 0.4, 1))
	tag_lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	tag_lbl.add_theme_constant_override("shadow_offset_x", 1)
	tag_lbl.add_theme_constant_override("shadow_offset_y", 1)
	v.add_child(tag_lbl)

	var title_lbl = Label.new()
	title_lbl.text = news["title"]
	title_lbl.add_theme_font_size_override("font_size", 38)
	if custom_font: title_lbl.add_theme_font_override("font", custom_font)
	title_lbl.add_theme_color_override("font_color",        Color(1, 1, 1, 1))
	title_lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	title_lbl.add_theme_constant_override("shadow_offset_x",     2)
	title_lbl.add_theme_constant_override("shadow_offset_y",     2)
	title_lbl.add_theme_constant_override("shadow_outline_size", 4)
	v.add_child(title_lbl)

	var body_lbl = Label.new()
	body_lbl.text = news["body"]
	body_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	body_lbl.add_theme_font_size_override("font_size", 16)
	body_lbl.add_theme_color_override("font_color",        Color(0.9, 0.9, 0.9, 1))
	body_lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	body_lbl.add_theme_constant_override("shadow_offset_x", 1)
	body_lbl.add_theme_constant_override("shadow_offset_y", 1)
	body_lbl.custom_minimum_size = Vector2(700, 0)
	v.add_child(body_lbl)

	if news.has("url") and news["url"] != "":
		var btn = Button.new()
		btn.text = "Saber más"
		btn.custom_minimum_size   = Vector2(140, 42)
		btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		btn.add_theme_font_size_override("font_size", 14)
		if custom_font: btn.add_theme_font_override("font", custom_font)

		var st_btn = StyleBoxFlat.new()
		st_btn.bg_color     = Color(1, 1, 1, 0.2)
		st_btn.border_color = Color(1, 1, 1, 0.5)
		st_btn.border_width_left = 1; st_btn.border_width_right  = 1
		st_btn.border_width_top  = 1; st_btn.border_width_bottom = 1
		st_btn.corner_radius_top_left    = 20; st_btn.corner_radius_top_right    = 20
		st_btn.corner_radius_bottom_left = 20; st_btn.corner_radius_bottom_right = 20
		var st_btn_hover = st_btn.duplicate()
		st_btn_hover.bg_color = Color(1, 1, 1, 0.35)
		btn.add_theme_stylebox_override("normal", st_btn)
		btn.add_theme_stylebox_override("hover",  st_btn_hover)
		var url = news["url"]
		btn.pressed.connect(func(): OS.shell_open(url))
		v.add_child(btn)

	return panel
