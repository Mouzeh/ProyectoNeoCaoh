extends Control

# ============================================================
# MainMenu.gd  —  RESPONSIVE
# ============================================================

enum Screen { LOGIN, LOBBY, DECK_BUILDER, QUEUE }

var current_screen: Screen = Screen.LOGIN
var player_id: String = ""
var current_deck: Array = []
var deck_name: String = "Fuego Inicial"

# ─── Alias locales → UITheme (se asignan en _ready) ────────
var COLOR_BG       : Color
var COLOR_PANEL    : Color
var COLOR_GOLD     : Color
var COLOR_GOLD_DIM : Color
var COLOR_TEXT     : Color
var COLOR_TEXT_DIM : Color
var COLOR_ACCENT   : Color
var COLOR_ACCENT2  : Color
var COLOR_RED      : Color
var COLOR_GREEN    : Color
var COLOR_PURPLE   : Color

var screen_container: Control = null
var _particles: Array = []
var _particle_timer: float = 0.0

func _ready() -> void:
	COLOR_BG       = UITheme.COLOR_BG
	COLOR_PANEL    = UITheme.COLOR_PANEL
	COLOR_GOLD     = UITheme.COLOR_GOLD
	COLOR_GOLD_DIM = UITheme.COLOR_GOLD_DIM
	COLOR_TEXT     = UITheme.COLOR_TEXT
	COLOR_TEXT_DIM = UITheme.COLOR_TEXT_DIM
	COLOR_ACCENT   = UITheme.COLOR_ACCENT
	COLOR_ACCENT2  = UITheme.COLOR_ACCENT2
	COLOR_RED      = UITheme.COLOR_RED
	COLOR_GREEN    = UITheme.COLOR_GREEN
	COLOR_PURPLE   = UITheme.COLOR_PURPLE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	offset_left   = 0
	offset_top    = 0
	offset_right  = 0
	offset_bottom = 0
	current_deck = _get_starter_deck_fire()
	_build_background()
	_connect_network()
	_show_screen(Screen.LOGIN)
	get_viewport().size_changed.connect(_on_viewport_resized)

func _on_viewport_resized() -> void:
	pass

func _process(delta: float) -> void:
	_particle_timer += delta
	if _particle_timer > 0.45:
		_particle_timer = 0.0
		_spawn_particle()
	_update_particles(delta)

func _build_background() -> void:
	var bg = ColorRect.new()
	bg.color = COLOR_BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	var rng = RandomNumberGenerator.new()
	rng.seed = 77
	for i in range(9):
		var radius = rng.randf_range(80, 260)
		var px = rng.randf_range(0.0, 1.0)
		var py = rng.randf_range(0.0, 1.0)
		_make_deco_circle(px, py, radius, rng.randf_range(0, 1))
	screen_container = Control.new()
	screen_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	screen_container.offset_left   = 0
	screen_container.offset_top    = 0
	screen_container.offset_right  = 0
	screen_container.offset_bottom = 0
	add_child(screen_container)
	var particle_layer = Control.new()
	particle_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	particle_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	particle_layer.name = "ParticleLayer"
	add_child(particle_layer)

func _make_deco_circle(px: float, py: float, radius: float, hue: float) -> void:
	var c = Control.new()
	c.anchor_left   = px; c.anchor_right  = px
	c.anchor_top    = py; c.anchor_bottom = py
	c.offset_left   = -radius; c.offset_right  = radius
	c.offset_top    = -radius; c.offset_bottom = radius
	c.mouse_filter  = Control.MOUSE_FILTER_IGNORE
	var panel = Panel.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	var st = StyleBoxFlat.new()
	st.bg_color     = Color.from_hsv(0.60 + hue * 0.1, 0.4, 0.15, 0.06)
	st.border_color = Color.from_hsv(0.55 + hue * 0.1, 0.6, 0.5, 0.07)
	st.border_width_left = 1; st.border_width_right  = 1
	st.border_width_top  = 1; st.border_width_bottom = 1
	for corner in ["corner_radius_top_left", "corner_radius_top_right",
				   "corner_radius_bottom_left", "corner_radius_bottom_right"]:
		st.set(corner, int(radius))
	panel.add_theme_stylebox_override("panel", st)
	c.add_child(panel)
	add_child(c)

func _spawn_particle() -> void:
	var layer = get_node_or_null("ParticleLayer")
	if not layer: return
	var vp = get_viewport().get_visible_rect().size
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var dot = ColorRect.new()
	dot.color   = COLOR_GOLD if rng.randf() > 0.5 else COLOR_ACCENT2
	dot.color.a = 0.0
	var sz = rng.randf_range(6, 12)
	dot.size         = Vector2(sz, sz)
	dot.position     = Vector2(rng.randf_range(0, vp.x), vp.y + 10)
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(dot)
	_particles.append({
		"node": dot, "speed": rng.randf_range(30, 80),
		"drift": rng.randf_range(-20, 20), "life": rng.randf_range(4.0, 9.0), "age": 0.0
	})

func _update_particles(delta: float) -> void:
	var to_remove = []
	for p in _particles:
		if not is_instance_valid(p.node):
			to_remove.append(p); continue
		p.age += delta
		var t = p.age / p.life
		p.node.position.y -= p.speed * delta
		p.node.position.x += p.drift * delta * 0.1
		p.node.color.a = min(t * 6.0, 1.0) * (1.0 - t) * 0.7
		if p.age >= p.life:
			p.node.queue_free(); to_remove.append(p)
	for p in to_remove: _particles.erase(p)

# ============================================================
# NAVEGACIÓN
# ============================================================
func _show_screen(screen: Screen) -> void:
	current_screen = screen
	for child in screen_container.get_children():
		child.queue_free()
	match screen:
		Screen.LOGIN:        _build_login_screen()
		Screen.LOBBY:        _build_lobby_screen()
		Screen.DECK_BUILDER: _build_deck_builder()
		Screen.QUEUE:        _build_queue_screen()

# ============================================================
# LOGIN
# ============================================================
func _build_login_screen() -> void:
	var bg_image = TextureRect.new()
	var bg_tex = load("res://assets/imagen/loginbackgraund.png")
	if bg_tex: bg_image.texture = bg_tex
	bg_image.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg_image.modulate = Color(0.1, 0.1, 0.1, 0)
	var vp_size = get_viewport().get_visible_rect().size
	bg_image.pivot_offset = vp_size / 2.0
	bg_image.scale = Vector2(1.02, 1.02)
	screen_container.add_child(bg_image)
	var tween = create_tween().set_parallel(true)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUINT)
	tween.tween_property(bg_image, "modulate", Color(1, 1, 1, 1), 3.0)
	tween.tween_property(bg_image, "scale", Vector2(1.0, 1.0), 6.0)

	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	screen_container.add_child(center)

	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(800, 480)
	card.clip_contents = true
	var st_card = StyleBoxFlat.new()
	st_card.bg_color = COLOR_PANEL
	st_card.border_color = Color(COLOR_GOLD_DIM.r, COLOR_GOLD_DIM.g, COLOR_GOLD_DIM.b, 0.5)
	st_card.border_width_left = 1; st_card.border_width_right = 1
	st_card.border_width_top = 1; st_card.border_width_bottom = 1
	st_card.corner_radius_top_left = 20; st_card.corner_radius_top_right = 20
	st_card.corner_radius_bottom_left = 20; st_card.corner_radius_bottom_right = 20
	st_card.shadow_color = Color(0, 0, 0, 0.4)
	st_card.shadow_size = 40; st_card.shadow_offset = Vector2(0, 15)
	card.add_theme_stylebox_override("panel", st_card)
	center.add_child(card)

	var card_hbox = HBoxContainer.new()
	card_hbox.add_theme_constant_override("separation", 0)
	card.add_child(card_hbox)

	var left_panel = PanelContainer.new()
	left_panel.custom_minimum_size = Vector2(360, 0)
	var grad = Gradient.new()
	grad.set_color(0, COLOR_BG.darkened(0.2))
	grad.set_color(1, Color(COLOR_GOLD_DIM.r, COLOR_GOLD_DIM.g, COLOR_GOLD_DIM.b, 0.6))
	var grad_tex = GradientTexture2D.new()
	grad_tex.gradient = grad
	grad_tex.fill_from = Vector2(0, 0); grad_tex.fill_to = Vector2(1, 1)
	var st_left = StyleBoxTexture.new()
	st_left.texture = grad_tex
	left_panel.add_theme_stylebox_override("panel", st_left)
	card_hbox.add_child(left_panel)

	var left_m = MarginContainer.new()
	left_m.add_theme_constant_override("margin_left", 32)
	left_m.add_theme_constant_override("margin_right", 32)
	left_m.add_theme_constant_override("margin_top", 32)
	left_m.add_theme_constant_override("margin_bottom", 32)
	left_panel.add_child(left_m)

	var left_v = VBoxContainer.new()
	left_m.add_child(left_v)

	var brand_lbl = Label.new()
	brand_lbl.text = "◈ Pokémon TCG"
	brand_lbl.add_theme_font_size_override("font_size", 16)
	brand_lbl.add_theme_color_override("font_color", COLOR_GOLD)
	left_v.add_child(brand_lbl)

	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_v.add_child(spacer)

	var sub_msg = Label.new()
	sub_msg.text = "you can easily"
	sub_msg.add_theme_font_size_override("font_size", 14)
	sub_msg.add_theme_color_override("font_color", COLOR_TEXT_DIM)
	left_v.add_child(sub_msg)

	var main_msg = Label.new()
	main_msg.text = "Simplify your game experience\nAnd organize your collection\nwith clarity."
	main_msg.autowrap_mode = TextServer.AUTOWRAP_WORD
	main_msg.add_theme_font_size_override("font_size", 24)
	main_msg.add_theme_color_override("font_color", COLOR_TEXT)
	left_v.add_child(main_msg)

	left_v.add_child(UITheme.vspace(8))
	var ver_msg = Label.new()
	ver_msg.text = "v0.1 Alpha · 111 cartas Neo Genesis"
	ver_msg.add_theme_font_size_override("font_size", 11)
	ver_msg.add_theme_color_override("font_color", COLOR_TEXT_DIM.darkened(0.2))
	left_v.add_child(ver_msg)

	var right_m = MarginContainer.new()
	right_m.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_m.add_theme_constant_override("margin_left", 60)
	right_m.add_theme_constant_override("margin_right", 60)
	right_m.add_theme_constant_override("margin_top", 50)
	right_m.add_theme_constant_override("margin_bottom", 50)
	card_hbox.add_child(right_m)

	var right_v = VBoxContainer.new()
	right_v.alignment = BoxContainer.ALIGNMENT_CENTER
	right_v.add_theme_constant_override("separation", 14)
	right_m.add_child(right_v)

	var star = Label.new()
	star.text = "✱"
	star.add_theme_font_size_override("font_size", 34)
	star.add_theme_color_override("font_color", COLOR_GOLD)
	right_v.add_child(star)

	var title = Label.new()
	title.text = "Create your Account"
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", COLOR_TEXT)
	right_v.add_child(title)

	var subtitle = Label.new()
	subtitle.text = "Access your collection, decks, and matches anytime, anywhere - and keep all your progress in one place."
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD
	subtitle.add_theme_font_size_override("font_size", 12)
	subtitle.add_theme_color_override("font_color", COLOR_TEXT_DIM)
	right_v.add_child(subtitle)

	right_v.add_child(UITheme.vspace(12))

	var lbl_input = Label.new()
	lbl_input.text = "Trainer Name"
	lbl_input.add_theme_font_size_override("font_size", 11)
	lbl_input.add_theme_color_override("font_color", COLOR_TEXT)
	right_v.add_child(lbl_input)

	var name_input = LineEdit.new()
	name_input.name = "NameInput"
	name_input.placeholder_text = "ej: AshKetchum"
	name_input.custom_minimum_size = Vector2(0, 46)
	name_input.add_theme_font_size_override("font_size", 14)
	name_input.add_theme_color_override("font_color", COLOR_TEXT)
	name_input.add_theme_color_override("caret_color", COLOR_GOLD)
	var st_in = StyleBoxFlat.new()
	st_in.bg_color = COLOR_BG
	st_in.border_color = Color(COLOR_GOLD_DIM.r, COLOR_GOLD_DIM.g, COLOR_GOLD_DIM.b, 0.3)
	st_in.border_width_left = 1; st_in.border_width_right = 1
	st_in.border_width_top = 1; st_in.border_width_bottom = 1
	st_in.corner_radius_top_left = 6; st_in.corner_radius_top_right = 6
	st_in.corner_radius_bottom_left = 6; st_in.corner_radius_bottom_right = 6
	st_in.content_margin_left = 14
	var st_in_focus = st_in.duplicate()
	st_in_focus.border_color = COLOR_GOLD
	name_input.add_theme_stylebox_override("normal", st_in)
	name_input.add_theme_stylebox_override("focus", st_in_focus)
	right_v.add_child(name_input)

	right_v.add_child(UITheme.vspace(10))

	var btn_connect = Button.new()
	btn_connect.text = "Connect & Play"
	btn_connect.custom_minimum_size = Vector2(0, 48)
	btn_connect.add_theme_font_size_override("font_size", 15)
	btn_connect.add_theme_color_override("font_color", COLOR_PANEL)
	var st_btn = StyleBoxFlat.new()
	st_btn.bg_color = COLOR_GOLD
	st_btn.corner_radius_top_left = 8; st_btn.corner_radius_top_right = 8
	st_btn.corner_radius_bottom_left = 8; st_btn.corner_radius_bottom_right = 8
	st_btn.shadow_color = Color(COLOR_GOLD.r, COLOR_GOLD.g, COLOR_GOLD.b, 0.2)
	st_btn.shadow_size = 15; st_btn.shadow_offset = Vector2(0, 4)
	var st_btn_hov = st_btn.duplicate()
	st_btn_hov.bg_color = COLOR_GOLD.lightened(0.1)
	var st_btn_press = st_btn.duplicate()
	st_btn_press.bg_color = COLOR_GOLD.darkened(0.1)
	st_btn_press.shadow_size = 5; st_btn_press.shadow_offset = Vector2(0, 1)
	btn_connect.add_theme_stylebox_override("normal", st_btn)
	btn_connect.add_theme_stylebox_override("hover", st_btn_hov)
	btn_connect.add_theme_stylebox_override("pressed", st_btn_press)
	btn_connect.pressed.connect(func(): _on_connect_pressed(name_input))
	right_v.add_child(btn_connect)

	var div_hb = HBoxContainer.new()
	var line_color = Color(COLOR_GOLD_DIM.r, COLOR_GOLD_DIM.g, COLOR_GOLD_DIM.b, 0.2)
	var l_line = ColorRect.new()
	l_line.color = line_color; l_line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l_line.custom_minimum_size = Vector2(0, 1); l_line.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var div_lbl = Label.new()
	div_lbl.text = "  or continue with  "
	div_lbl.add_theme_font_size_override("font_size", 11)
	div_lbl.add_theme_color_override("font_color", COLOR_TEXT_DIM)
	var r_line = ColorRect.new()
	r_line.color = line_color; r_line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	r_line.custom_minimum_size = Vector2(0, 1); r_line.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	div_hb.add_child(l_line); div_hb.add_child(div_lbl); div_hb.add_child(r_line)
	right_v.add_child(div_hb)

	var btn_local = Button.new()
	btn_local.text = "Local Play (No Server)"
	btn_local.custom_minimum_size = Vector2(0, 44)
	btn_local.add_theme_font_size_override("font_size", 14)
	btn_local.add_theme_color_override("font_color", COLOR_GOLD_DIM)
	var st_local = StyleBoxFlat.new()
	st_local.bg_color = Color(0, 0, 0, 0)
	st_local.border_color = Color(COLOR_GOLD_DIM.r, COLOR_GOLD_DIM.g, COLOR_GOLD_DIM.b, 0.4)
	st_local.border_width_left = 1; st_local.border_width_right = 1
	st_local.border_width_top = 1; st_local.border_width_bottom = 1
	st_local.corner_radius_top_left = 8; st_local.corner_radius_top_right = 8
	st_local.corner_radius_bottom_left = 8; st_local.corner_radius_bottom_right = 8
	var st_local_hov = st_local.duplicate()
	st_local_hov.bg_color = Color(1, 1, 1, 0.03)
	st_local_hov.border_color = COLOR_GOLD_DIM
	var st_local_press = st_local.duplicate()
	st_local_press.bg_color = Color(0, 0, 0, 0.1)
	btn_local.add_theme_stylebox_override("normal", st_local)
	btn_local.add_theme_stylebox_override("hover", st_local_hov)
	btn_local.add_theme_stylebox_override("pressed", st_local_press)
	btn_local.pressed.connect(func(): _on_local_pressed(name_input))
	right_v.add_child(btn_local)

	var conn_text = "Status: Server Connected" if NetworkManager.ws_connected else "Status: Offline"
	var conn_color = COLOR_GOLD if NetworkManager.ws_connected else COLOR_TEXT_DIM
	var status_lbl = Label.new()
	status_lbl.text = conn_text
	status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_lbl.add_theme_font_size_override("font_size", 11)
	status_lbl.add_theme_color_override("font_color", conn_color)
	right_v.add_child(UITheme.vspace(10))
	right_v.add_child(status_lbl)

	var logo_hbox = HBoxContainer.new()
	logo_hbox.anchor_left = 1.0; logo_hbox.anchor_right = 1.0
	logo_hbox.anchor_top = 1.0; logo_hbox.anchor_bottom = 1.0
	logo_hbox.offset_left = -550; logo_hbox.offset_top = -100
	logo_hbox.offset_right = -24; logo_hbox.offset_bottom = -20
	logo_hbox.alignment = BoxContainer.ALIGNMENT_END
	logo_hbox.add_theme_constant_override("separation", 16)
	screen_container.add_child(logo_hbox)

	for path in ["res://assets/imagen/logo_dev.png", "res://assets/imagen/logo_pokemon.png"]:
		var tex = load(path)
		if tex:
			var tr = TextureRect.new()
			tr.texture = tex
			tr.custom_minimum_size = Vector2(200, 80)
			tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tr.modulate = Color(1, 1, 1, 0.6)
			tr.mouse_filter = Control.MOUSE_FILTER_STOP
			tr.mouse_entered.connect(func(): tr.modulate = Color(1, 1, 1, 1.0))
			tr.mouse_exited.connect(func(): tr.modulate = Color(1, 1, 1, 0.6))
			logo_hbox.add_child(tr)
		else:
			var debug_lbl = Label.new()
			debug_lbl.text = "ERROR: " + path.get_file()
			debug_lbl.add_theme_font_size_override("font_size", 18)
			debug_lbl.add_theme_color_override("font_color", Color(1.0, 0.0, 0.0))
			logo_hbox.add_child(debug_lbl)

func _on_connect_pressed(name_input: LineEdit) -> void:
	var name = name_input.text.strip_edges()
	if name == "":
		name_input.placeholder_text = "⚠  Ingresa un nombre primero"
		return
	player_id = name
	NetworkManager.player_id = player_id
	if NetworkManager.ws_connected:
		NetworkManager.authenticate(player_id)
		NetworkManager.auth_ok.connect(func(_p): _show_screen(Screen.LOBBY), CONNECT_ONE_SHOT)
	else:
		NetworkManager.connect_to_server()
		NetworkManager.auth_ok.connect(func(_p): _show_screen(Screen.LOBBY), CONNECT_ONE_SHOT)

func _on_local_pressed(name_input: LineEdit) -> void:
	var name = name_input.text.strip_edges()
	if name == "":
		name_input.placeholder_text = "⚠  Ingresa un nombre primero"
		return
	player_id = name
	NetworkManager.player_id = player_id
	_show_screen(Screen.LOBBY)

# ============================================================
# LOBBY
# ============================================================
func _build_lobby_screen() -> void:
	var bg_image = TextureRect.new()
	var bg_tex = load("res://assets/imagen/fondomenu.png")
	if bg_tex: bg_image.texture = bg_tex
	bg_image.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg_image.modulate = Color(0.3, 0.3, 0.3, 1)
	screen_container.add_child(bg_image)

	var header = Panel.new()
	header.anchor_left = 0; header.anchor_right = 1
	header.anchor_top = 0; header.anchor_bottom = 0
	header.offset_bottom = 70
	var hs = StyleBoxFlat.new()
	hs.bg_color = Color(COLOR_PANEL.r, COLOR_PANEL.g, COLOR_PANEL.b, 0.85)
	hs.border_color = Color(COLOR_GOLD_DIM.r, COLOR_GOLD_DIM.g, COLOR_GOLD_DIM.b, 0.3)
	hs.border_width_bottom = 1
	hs.shadow_color = Color(0, 0, 0, 0.3); hs.shadow_size = 20
	header.add_theme_stylebox_override("panel", hs)
	screen_container.add_child(header)

	var hbox = HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	header.add_child(hbox)

	var accent = ColorRect.new()
	accent.color = COLOR_GOLD
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
	title_lbl.text = "◈ POKÉMON TCG · NEO GENESIS"
	title_lbl.add_theme_font_size_override("font_size", 16)
	title_lbl.add_theme_color_override("font_color", COLOR_GOLD)
	title_v.add_child(title_lbl)

	var subtitle_lbl = Label.new()
	subtitle_lbl.text = "MAIN HUB"
	subtitle_lbl.add_theme_font_size_override("font_size", 11)
	subtitle_lbl.add_theme_color_override("font_color", COLOR_TEXT_DIM)
	title_v.add_child(subtitle_lbl)

	var pill_m = MarginContainer.new()
	pill_m.add_theme_constant_override("margin_right", 24)
	pill_m.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var pp = UITheme.pill("👤  Trainer: " + player_id, Color(0, 0, 0, 0.5), COLOR_GOLD, 36)
	pp.custom_minimum_size = Vector2(180, 36)
	pill_m.add_child(pp)
	hbox.add_child(pill_m)

	var center = CenterContainer.new()
	center.anchor_left = 0; center.anchor_right = 1
	center.anchor_top = 0; center.anchor_bottom = 1
	center.offset_top = 70
	screen_container.add_child(center)

	var col = VBoxContainer.new()
	col.custom_minimum_size = Vector2(500, 0)
	col.add_theme_constant_override("separation", 24)
	center.add_child(col)

	var play_card = PanelContainer.new()
	var st_play = StyleBoxFlat.new()
	st_play.bg_color = COLOR_PANEL
	st_play.border_color = Color(COLOR_GOLD_DIM.r, COLOR_GOLD_DIM.g, COLOR_GOLD_DIM.b, 0.5)
	st_play.border_width_left = 1; st_play.border_width_right = 1
	st_play.border_width_top = 1; st_play.border_width_bottom = 1
	st_play.corner_radius_top_left = 16; st_play.corner_radius_top_right = 16
	st_play.corner_radius_bottom_left = 16; st_play.corner_radius_bottom_right = 16
	st_play.shadow_color = Color(0, 0, 0, 0.4)
	st_play.shadow_size = 25; st_play.shadow_offset = Vector2(0, 10)
	play_card.add_theme_stylebox_override("panel", st_play)
	col.add_child(play_card)

	var play_m = MarginContainer.new()
	play_m.add_theme_constant_override("margin_left", 40)
	play_m.add_theme_constant_override("margin_right", 40)
	play_m.add_theme_constant_override("margin_top", 35)
	play_m.add_theme_constant_override("margin_bottom", 35)
	play_card.add_child(play_m)

	var play_v = VBoxContainer.new()
	play_v.add_theme_constant_override("separation", 12)
	play_m.add_child(play_v)

	var play_title = Label.new()
	play_title.text = "⚔ BATTLE ARENA"
	play_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	play_title.add_theme_font_size_override("font_size", 22)
	play_title.add_theme_color_override("font_color", COLOR_GOLD)
	play_v.add_child(play_title)

	var play_desc = Label.new()
	play_desc.text = "Enfrenta a otro entrenador en línea o juega de manera local."
	play_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	play_desc.add_theme_font_size_override("font_size", 13)
	play_desc.add_theme_color_override("font_color", COLOR_TEXT_DIM)
	play_v.add_child(play_desc)

	var deck_status = Label.new()
	deck_status.text = _get_deck_status_text()
	deck_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	deck_status.add_theme_font_size_override("font_size", 12)
	var v = _validate_deck_local(current_deck)
	deck_status.add_theme_color_override("font_color", COLOR_GREEN if v.valid else Color("df673b"))
	play_v.add_child(deck_status)

	play_v.add_child(UITheme.vspace(15))

	var play_btn = Button.new()
	play_btn.text = "BUSCAR PARTIDA" if NetworkManager.ws_connected else "JUGAR LOCAL"
	play_btn.custom_minimum_size = Vector2(0, 50)
	play_btn.add_theme_font_size_override("font_size", 16)
	play_btn.add_theme_color_override("font_color", COLOR_PANEL)
	var st_btn_play = StyleBoxFlat.new()
	st_btn_play.bg_color = COLOR_GOLD
	st_btn_play.corner_radius_top_left = 10; st_btn_play.corner_radius_top_right = 10
	st_btn_play.corner_radius_bottom_left = 10; st_btn_play.corner_radius_bottom_right = 10
	st_btn_play.shadow_color = Color(COLOR_GOLD.r, COLOR_GOLD.g, COLOR_GOLD.b, 0.2)
	st_btn_play.shadow_size = 15; st_btn_play.shadow_offset = Vector2(0, 4)
	var st_btn_play_hov = st_btn_play.duplicate()
	st_btn_play_hov.bg_color = COLOR_GOLD.lightened(0.1)
	var st_btn_play_press = st_btn_play.duplicate()
	st_btn_play_press.bg_color = COLOR_GOLD.darkened(0.1)
	st_btn_play_press.shadow_size = 5; st_btn_play_press.shadow_offset = Vector2(0, 1)
	play_btn.add_theme_stylebox_override("normal", st_btn_play)
	play_btn.add_theme_stylebox_override("hover", st_btn_play_hov)
	play_btn.add_theme_stylebox_override("pressed", st_btn_play_press)
	play_btn.pressed.connect(func(): _on_play_pressed())
	play_v.add_child(play_btn)

	var deck_card = PanelContainer.new()
	var st_deck = StyleBoxFlat.new()
	st_deck.bg_color = COLOR_BG.lightened(0.02)
	st_deck.border_color = Color(COLOR_GOLD_DIM.r, COLOR_GOLD_DIM.g, COLOR_GOLD_DIM.b, 0.2)
	st_deck.border_width_left = 1; st_deck.border_width_right = 1
	st_deck.border_width_top = 1; st_deck.border_width_bottom = 1
	st_deck.corner_radius_top_left = 16; st_deck.corner_radius_top_right = 16
	st_deck.corner_radius_bottom_left = 16; st_deck.corner_radius_bottom_right = 16
	deck_card.add_theme_stylebox_override("panel", st_deck)
	col.add_child(deck_card)

	var deck_m = MarginContainer.new()
	deck_m.add_theme_constant_override("margin_left", 30)
	deck_m.add_theme_constant_override("margin_right", 30)
	deck_m.add_theme_constant_override("margin_top", 25)
	deck_m.add_theme_constant_override("margin_bottom", 25)
	deck_card.add_child(deck_m)

	var deck_v = VBoxContainer.new()
	deck_v.add_theme_constant_override("separation", 8)
	deck_m.add_child(deck_v)

	var deck_title = Label.new()
	deck_title.text = "🃏 DECK BUILDER"
	deck_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	deck_title.add_theme_font_size_override("font_size", 16)
	deck_title.add_theme_color_override("font_color", COLOR_TEXT)
	deck_v.add_child(deck_title)

	var deck_desc = Label.new()
	deck_desc.text = "Personaliza tu mazo · 111 cartas Neo Genesis"
	deck_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	deck_desc.add_theme_font_size_override("font_size", 12)
	deck_desc.add_theme_color_override("font_color", COLOR_TEXT_DIM)
	deck_v.add_child(deck_desc)
	deck_v.add_child(UITheme.vspace(10))

	var deck_btn = Button.new()
	deck_btn.text = "ABRIR CONSTRUCTOR"
	deck_btn.custom_minimum_size = Vector2(0, 44)
	deck_btn.add_theme_font_size_override("font_size", 14)
	deck_btn.add_theme_color_override("font_color", COLOR_GOLD_DIM)
	var st_btn_deck = StyleBoxFlat.new()
	st_btn_deck.bg_color = Color(0, 0, 0, 0)
	st_btn_deck.border_color = Color(COLOR_GOLD_DIM.r, COLOR_GOLD_DIM.g, COLOR_GOLD_DIM.b, 0.4)
	st_btn_deck.border_width_left = 1; st_btn_deck.border_width_right = 1
	st_btn_deck.border_width_top = 1; st_btn_deck.border_width_bottom = 1
	st_btn_deck.corner_radius_top_left = 8; st_btn_deck.corner_radius_top_right = 8
	st_btn_deck.corner_radius_bottom_left = 8; st_btn_deck.corner_radius_bottom_right = 8
	var st_btn_deck_hov = st_btn_deck.duplicate()
	st_btn_deck_hov.bg_color = Color(1, 1, 1, 0.05)
	var st_btn_deck_press = st_btn_deck.duplicate()
	st_btn_deck_press.bg_color = Color(0, 0, 0, 0.2)
	deck_btn.add_theme_stylebox_override("normal", st_btn_deck)
	deck_btn.add_theme_stylebox_override("hover", st_btn_deck_hov)
	deck_btn.add_theme_stylebox_override("pressed", st_btn_deck_press)
	deck_btn.pressed.connect(func(): _show_screen(Screen.DECK_BUILDER))
	deck_v.add_child(deck_btn)

	var back_btn = Button.new()
	back_btn.text = "← Cerrar sesión"
	back_btn.custom_minimum_size = Vector2(150, 36)
	back_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back_btn.add_theme_font_size_override("font_size", 12)
	back_btn.add_theme_color_override("font_color", Color(0.6, 0.4, 0.4))
	var st_back = StyleBoxFlat.new()
	st_back.bg_color = Color(0, 0, 0, 0)
	var st_back_hov = st_back.duplicate()
	st_back_hov.bg_color = Color(1, 0, 0, 0.1)
	st_back_hov.corner_radius_top_left = 6; st_back_hov.corner_radius_top_right = 6
	st_back_hov.corner_radius_bottom_left = 6; st_back_hov.corner_radius_bottom_right = 6
	back_btn.add_theme_stylebox_override("normal", st_back)
	back_btn.add_theme_stylebox_override("hover", st_back_hov)
	back_btn.add_theme_stylebox_override("pressed", st_back_hov)
	back_btn.pressed.connect(func():
		NetworkManager.disconnect_from_server()
		_show_screen(Screen.LOGIN)
	)
	col.add_child(back_btn)

func _get_deck_status_text() -> String:
	var v = _validate_deck_local(current_deck)
	if v.valid:
		return "✓  Deck: " + deck_name + "  (" + str(current_deck.size()) + " cartas)"
	return "⚠  " + v.error

func _on_play_pressed() -> void:
	if NetworkManager.ws_connected:
		NetworkManager.join_queue(current_deck)
		_show_screen(Screen.QUEUE)
	else:
		get_tree().change_scene_to_file("res://scenes/BattleBoard.tscn")

# ============================================================
# QUEUE — FIX: eliminado el listener duplicado de game_started
# ============================================================
func _build_queue_screen() -> void:
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	screen_container.add_child(center)

	var vp = get_viewport().get_visible_rect().size
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(clamp(vp.x * 0.40, 400, 540), 0)
	var ps = StyleBoxFlat.new()
	ps.bg_color            = COLOR_PANEL
	ps.border_color        = Color(COLOR_GOLD_DIM.r, COLOR_GOLD_DIM.g, COLOR_GOLD_DIM.b, 0.55)
	ps.border_width_left   = 1; ps.border_width_right  = 1
	ps.border_width_top    = 1; ps.border_width_bottom = 1
	ps.corner_radius_top_left     = 10; ps.corner_radius_top_right    = 10
	ps.corner_radius_bottom_left  = 10; ps.corner_radius_bottom_right = 10
	ps.shadow_color = Color(0, 0, 0, 0.5); ps.shadow_size = 12
	panel.add_theme_stylebox_override("panel", ps)
	center.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 0)
	panel.add_child(vbox)

	vbox.add_child(UITheme.color_strip(COLOR_ACCENT, 6, true))

	var body = MarginContainer.new()
	body.add_theme_constant_override("margin_left",   40)
	body.add_theme_constant_override("margin_right",  40)
	body.add_theme_constant_override("margin_top",    20)
	body.add_theme_constant_override("margin_bottom", 20)
	vbox.add_child(body)

	var inner = VBoxContainer.new()
	inner.add_theme_constant_override("separation", 12)
	body.add_child(inner)

	inner.add_child(UITheme.clbl("BUSCANDO PARTIDA", 20, COLOR_GOLD))
	inner.add_child(UITheme.clbl("Esperando a otro entrenador...", 11, COLOR_TEXT_DIM))
	inner.add_child(UITheme.pill("🃏  " + deck_name, Color(0.10, 0.14, 0.10), COLOR_GREEN, 30))

	var dots = UITheme.clbl("◆  ◇  ◇", 26, COLOR_GOLD)
	dots.name = "Dots"
	inner.add_child(dots)
	inner.add_child(UITheme.divider())

	var cancel_btn = UITheme.btn("CANCELAR BÚSQUEDA", COLOR_RED, 48, 13)
	cancel_btn.pressed.connect(func():
		NetworkManager.leave_queue()
		_show_screen(Screen.LOBBY)
	)
	inner.add_child(cancel_btn)

	# FIX: eliminado el NetworkManager.game_started.connect(...) que estaba aquí.
	# GameManager (autoload) es el único responsable de llamar change_scene al recibir GAME_START.

	_animate_dots(dots)

var _dot_frames: Array = ["◆  ◇  ◇", "◆  ◆  ◇", "◆  ◆  ◆", "◇  ◆  ◆", "◇  ◇  ◆", "◇  ◇  ◇"]
var _dot_idx: int = 0
var _dot_label: Label = null

func _animate_dots(lbl: Label) -> void:
	_dot_label = lbl; _dot_idx = 0; _tick_dots()

func _tick_dots() -> void:
	if not is_instance_valid(_dot_label): return
	_dot_label.text = _dot_frames[_dot_idx % _dot_frames.size()]
	_dot_idx += 1
	get_tree().create_timer(0.35).timeout.connect(_tick_dots, CONNECT_ONE_SHOT)

# ============================================================
# DECK BUILDER
# ============================================================
func _build_deck_builder() -> void:
	var bg_image = TextureRect.new()
	var bg_tex = load("res://assets/imagen/fondomenu.png")
	if bg_tex: bg_image.texture = bg_tex
	bg_image.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg_image.modulate = Color(0.15, 0.15, 0.15, 1)
	screen_container.add_child(bg_image)

	var header = Panel.new()
	header.anchor_left = 0; header.anchor_right = 1
	header.anchor_top = 0; header.anchor_bottom = 0
	header.offset_bottom = 70
	var hs = StyleBoxFlat.new()
	hs.bg_color = Color(COLOR_PANEL.r, COLOR_PANEL.g, COLOR_PANEL.b, 0.85)
	hs.border_color = Color(COLOR_GOLD_DIM.r, COLOR_GOLD_DIM.g, COLOR_GOLD_DIM.b, 0.3)
	hs.border_width_bottom = 1
	hs.shadow_color = Color(0, 0, 0, 0.3); hs.shadow_size = 20
	header.add_theme_stylebox_override("panel", hs)
	screen_container.add_child(header)

	var hbox = HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	header.add_child(hbox)

	var accent = ColorRect.new()
	accent.color = COLOR_PURPLE
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
	title_lbl.text = "🃏 CONSTRUCTOR DE MAZO"
	title_lbl.add_theme_font_size_override("font_size", 16)
	title_lbl.add_theme_color_override("font_color", COLOR_GOLD)
	title_v.add_child(title_lbl)

	var count_lbl = Label.new()
	count_lbl.name = "CountLbl"
	count_lbl.text = str(current_deck.size()) + " / 60 Cartas"
	count_lbl.add_theme_font_size_override("font_size", 12)
	count_lbl.add_theme_color_override("font_color", COLOR_TEXT_DIM)
	title_v.add_child(count_lbl)

	var bm = MarginContainer.new()
	bm.add_theme_constant_override("margin_right", 24)
	bm.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox.add_child(bm)

	var back_btn = Button.new()
	back_btn.text = "← Volver al Lobby"
	back_btn.custom_minimum_size = Vector2(150, 38)
	back_btn.add_theme_font_size_override("font_size", 13)
	back_btn.add_theme_color_override("font_color", COLOR_GOLD_DIM)
	var st_back = StyleBoxFlat.new()
	st_back.bg_color = Color(0, 0, 0, 0)
	st_back.border_color = Color(COLOR_GOLD_DIM.r, COLOR_GOLD_DIM.g, COLOR_GOLD_DIM.b, 0.4)
	st_back.border_width_left = 1; st_back.border_width_right = 1
	st_back.border_width_top = 1; st_back.border_width_bottom = 1
	st_back.corner_radius_top_left = 8; st_back.corner_radius_top_right = 8
	st_back.corner_radius_bottom_left = 8; st_back.corner_radius_bottom_right = 8
	var st_back_hov = st_back.duplicate()
	st_back_hov.bg_color = Color(1, 1, 1, 0.05)
	back_btn.add_theme_stylebox_override("normal", st_back)
	back_btn.add_theme_stylebox_override("hover", st_back_hov)
	back_btn.add_theme_stylebox_override("pressed", st_back_hov)
	back_btn.pressed.connect(func(): _show_screen(Screen.LOBBY))
	bm.add_child(back_btn)

	var main_area = HBoxContainer.new()
	main_area.anchor_left = 0; main_area.anchor_right = 1
	main_area.anchor_top = 0; main_area.anchor_bottom = 1
	main_area.offset_top = 90; main_area.offset_bottom = -20
	main_area.offset_left = 24; main_area.offset_right = -24
	main_area.add_theme_constant_override("separation", 16)
	screen_container.add_child(main_area)

	var coll_panel = PanelContainer.new()
	coll_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	coll_panel.size_flags_stretch_ratio = 0.50
	var st_coll = StyleBoxFlat.new()
	st_coll.bg_color = Color(COLOR_PANEL.r, COLOR_PANEL.g, COLOR_PANEL.b, 0.95)
	st_coll.border_color = Color(COLOR_GOLD_DIM.r, COLOR_GOLD_DIM.g, COLOR_GOLD_DIM.b, 0.3)
	st_coll.border_width_left = 1; st_coll.border_width_right = 1
	st_coll.border_width_top = 1; st_coll.border_width_bottom = 1
	st_coll.corner_radius_top_left = 16; st_coll.corner_radius_top_right = 16
	st_coll.corner_radius_bottom_left = 16; st_coll.corner_radius_bottom_right = 16
	st_coll.shadow_color = Color(0, 0, 0, 0.5); st_coll.shadow_size = 30
	coll_panel.add_theme_stylebox_override("panel", st_coll)
	main_area.add_child(coll_panel)

	var cv_m = MarginContainer.new()
	cv_m.add_theme_constant_override("margin_left", 20)
	cv_m.add_theme_constant_override("margin_right", 20)
	cv_m.add_theme_constant_override("margin_top", 16)
	cv_m.add_theme_constant_override("margin_bottom", 16)
	coll_panel.add_child(cv_m)

	var cv = VBoxContainer.new()
	cv.add_theme_constant_override("separation", 12)
	cv_m.add_child(cv)

	var coll_title = Label.new()
	coll_title.text = "COLECCIÓN  ·  Click Izquierdo: Agregar | Click Derecho: Ver"
	coll_title.add_theme_font_size_override("font_size", 12)
	coll_title.add_theme_color_override("font_color", COLOR_GOLD_DIM)
	cv.add_child(coll_title)

	var filter_hbox = HBoxContainer.new()
	filter_hbox.add_theme_constant_override("separation", 8)
	cv.add_child(filter_hbox)

	var search_in = LineEdit.new()
	search_in.name = "SearchInput"
	search_in.placeholder_text = "🔎 Buscar..."
	search_in.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	search_in.add_theme_stylebox_override("normal", UITheme.input_style(Color(0.2, 0.2, 0.3)))
	search_in.add_theme_stylebox_override("focus", UITheme.input_style(COLOR_GOLD))
	filter_hbox.add_child(search_in)

	var cat_opt = OptionButton.new()
	cat_opt.name = "CatFilter"
	cat_opt.add_item("Categoría: Todas")
	cat_opt.add_item("Básico")
	cat_opt.add_item("Bebé")
	cat_opt.add_item("Fase 1")
	cat_opt.add_item("Fase 2")
	cat_opt.add_item("Entrenador")
	cat_opt.add_item("Energía")
	cat_opt.custom_minimum_size = Vector2(130, 0)
	filter_hbox.add_child(cat_opt)

	var elem_opt = OptionButton.new()
	elem_opt.name = "ElemFilter"
	elem_opt.add_item("Elemento: Todos")
	elem_opt.add_item("Fuego")
	elem_opt.add_item("Agua")
	elem_opt.add_item("Planta")
	elem_opt.add_item("Rayo")
	elem_opt.add_item("Psíquico")
	elem_opt.add_item("Lucha")
	elem_opt.add_item("Incoloro")
	elem_opt.add_item("Siniestro")
	elem_opt.add_item("Metálico")
	elem_opt.custom_minimum_size = Vector2(130, 0)
	filter_hbox.add_child(elem_opt)

	var rarity_opt = OptionButton.new()
	rarity_opt.name = "RarityFilter"
	rarity_opt.add_item("Rareza: Todas")
	rarity_opt.add_item("Común / Infrecuente")
	rarity_opt.add_item("Rara / Holo")
	rarity_opt.add_item("Ultra Rara")
	rarity_opt.custom_minimum_size = Vector2(140, 0)
	filter_hbox.add_child(rarity_opt)

	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UITheme.apply_scrollbar_theme(scroll)
	cv.add_child(scroll)

	var grid = GridContainer.new()
	grid.name = "CollectionGrid"
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 16)
	scroll.add_child(grid)

	search_in.text_changed.connect(func(_t): _refresh_collection_grid())
	cat_opt.item_selected.connect(func(_i): _refresh_collection_grid())
	elem_opt.item_selected.connect(func(_i): _refresh_collection_grid())
	rarity_opt.item_selected.connect(func(_i): _refresh_collection_grid())

	var preview_panel = PanelContainer.new()
	preview_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview_panel.size_flags_stretch_ratio = 0.25
	var st_prev = st_coll.duplicate()
	st_prev.bg_color = Color(0.04, 0.05, 0.08, 0.98)
	preview_panel.add_theme_stylebox_override("panel", st_prev)
	main_area.add_child(preview_panel)

	var prev_m = MarginContainer.new()
	prev_m.add_theme_constant_override("margin_left", 16)
	prev_m.add_theme_constant_override("margin_right", 16)
	prev_m.add_theme_constant_override("margin_top", 16)
	prev_m.add_theme_constant_override("margin_bottom", 16)
	preview_panel.add_child(prev_m)

	var prev_v = VBoxContainer.new()
	prev_v.alignment = BoxContainer.ALIGNMENT_CENTER
	prev_m.add_child(prev_v)

	var prev_img = TextureRect.new()
	prev_img.name = "PreviewImage"
	prev_img.size_flags_vertical = Control.SIZE_EXPAND_FILL
	prev_img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	prev_img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	prev_v.add_child(prev_img)
	prev_v.add_child(UITheme.vspace(10))

	var prev_name = Label.new()
	prev_name.name = "PreviewName"
	prev_name.text = "Pasa el mouse o haz Click Derecho en una carta"
	prev_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prev_name.autowrap_mode = TextServer.AUTOWRAP_WORD
	prev_name.add_theme_font_size_override("font_size", 14)
	prev_name.add_theme_color_override("font_color", COLOR_GOLD)
	prev_v.add_child(prev_name)

	var dp_panel = PanelContainer.new()
	dp_panel.name = "DeckPanel"
	dp_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dp_panel.size_flags_stretch_ratio = 0.25
	var st_dp = st_coll.duplicate()
	st_dp.bg_color = Color(COLOR_BG.r, COLOR_BG.g, COLOR_BG.b, 0.98)
	dp_panel.add_theme_stylebox_override("panel", st_dp)
	main_area.add_child(dp_panel)

	var dp_m = MarginContainer.new()
	dp_m.add_theme_constant_override("margin_left", 20)
	dp_m.add_theme_constant_override("margin_right", 20)
	dp_m.add_theme_constant_override("margin_top", 16)
	dp_m.add_theme_constant_override("margin_bottom", 16)
	dp_panel.add_child(dp_m)

	var dv = VBoxContainer.new()
	dv.add_theme_constant_override("separation", 12)
	dp_m.add_child(dv)

	var deck_title_lbl = Label.new()
	deck_title_lbl.text = "LISTA DEL MAZO"
	deck_title_lbl.add_theme_font_size_override("font_size", 12)
	deck_title_lbl.add_theme_color_override("font_color", COLOR_GOLD_DIM)
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

	var btns_grid = GridContainer.new()
	btns_grid.columns = 2
	btns_grid.add_theme_constant_override("h_separation", 8)
	btns_grid.add_theme_constant_override("v_separation", 8)
	dv.add_child(btns_grid)

	var add_deck_btn = func(label: String, color: Color, deck_func: Callable, d_name: String):
		var b = Button.new()
		b.text = label
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, 32)
		b.add_theme_font_size_override("font_size", 10)
		var st = StyleBoxFlat.new()
		st.bg_color = color
		st.bg_color.a = 0.25
		st.border_width_left = 1; st.border_width_top = 1
		st.border_width_right = 1; st.border_width_bottom = 1
		st.border_color = color
		st.corner_radius_top_left = 4; st.corner_radius_top_right = 4
		st.corner_radius_bottom_left = 4; st.corner_radius_bottom_right = 4
		b.add_theme_stylebox_override("normal", st)
		b.pressed.connect(func():
			current_deck = deck_func.call()
			deck_name = d_name
			_refresh_deck_list(dp_panel, header)
		)
		btns_grid.add_child(b)

	add_deck_btn.call("🔥 Fuego", COLOR_RED, _get_starter_deck_fire, "Fuego Inicial")
	add_deck_btn.call("💧 Agua", COLOR_ACCENT, _get_starter_deck_water, "Agua Control")
	add_deck_btn.call("🌿 Planta", COLOR_GREEN, _get_starter_deck_grass, "Planta Veneno")
	add_deck_btn.call("⚡ Rayo", COLOR_GOLD, _get_starter_deck_lightning, "Rayo Veloz")

	var clear_btn = Button.new()
	clear_btn.text = "Limpiar Todo"
	clear_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	clear_btn.custom_minimum_size = Vector2(0, 32)
	clear_btn.add_theme_font_size_override("font_size", 11)
	clear_btn.pressed.connect(func():
		current_deck = []
		_refresh_deck_list(dp_panel, header)
	)
	dv.add_child(clear_btn)

	_refresh_deck_list(dp_panel, header)
	_refresh_collection_grid()

func _mini_card(card_id: String) -> Control:
	var data = CardDatabase.get_card(card_id)
	var c = Control.new()
	c.custom_minimum_size = Vector2(120, 170)
	c.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	c.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	var panel = Panel.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	var st = StyleBoxFlat.new()
	st.bg_color = Color(0.08, 0.10, 0.15)
	match data.get("rarity", "COMMON"):
		"ULTRA_RARE": st.border_color = COLOR_GOLD
		"RARE_HOLO":  st.border_color = Color(0.55, 0.78, 1.0)
		"RARE":       st.border_color = Color(0.78, 0.78, 0.78)
		_:            st.border_color = Color(0.25, 0.28, 0.36)
	st.border_width_left = 1; st.border_width_right = 1
	st.border_width_top = 1; st.border_width_bottom = 1
	st.corner_radius_top_left = 6; st.corner_radius_top_right = 6
	st.corner_radius_bottom_left = 6; st.corner_radius_bottom_right = 6
	panel.add_theme_stylebox_override("panel", st)
	c.add_child(panel)

	var img_path = data.get("image", "")
	if img_path != "":
		var tex = load(img_path)
		if tex:
			var tr = TextureRect.new()
			tr.texture = tex
			tr.set_anchors_preset(Control.PRESET_FULL_RECT)
			tr.offset_left = 6; tr.offset_top = 6
			tr.offset_right = -6; tr.offset_bottom = -26
			tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tr.clip_contents = true
			c.add_child(tr)

	var nl = Label.new()
	nl.text = data.get("name", card_id).left(14)
	nl.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	nl.offset_top = -24; nl.offset_bottom = -4
	nl.add_theme_font_size_override("font_size", 11)
	nl.add_theme_color_override("font_color", COLOR_TEXT)
	nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	c.add_child(nl)

	c.tooltip_text = data.get("name", card_id) + " (Click Derecho para ver)"
	c.mouse_filter = Control.MOUSE_FILTER_STOP

	c.mouse_entered.connect(func():
		if is_instance_valid(panel):
			var s = panel.get_theme_stylebox("panel").duplicate()
			s.bg_color = Color(0.18, 0.22, 0.32)
			panel.add_theme_stylebox_override("panel", s)
			_show_card_preview(card_id)
	)
	c.mouse_exited.connect(func():
		if is_instance_valid(panel):
			var s = panel.get_theme_stylebox("panel").duplicate()
			s.bg_color = Color(0.08, 0.10, 0.15)
			panel.add_theme_stylebox_override("panel", s)
	)
	c.gui_input.connect(func(ev):
		if ev is InputEventMouseButton and ev.pressed:
			if ev.button_index == MOUSE_BUTTON_LEFT:
				_add_to_deck(card_id)
			elif ev.button_index == MOUSE_BUTTON_RIGHT:
				_show_card_preview(card_id)
	)
	return c

func _show_card_preview(card_id: String) -> void:
	var data = CardDatabase.get_card(card_id)
	var img_path = data.get("image", "")
	var preview_img = UITheme.find_node(screen_container, "PreviewImage") as TextureRect
	var preview_lbl = UITheme.find_node(screen_container, "PreviewName") as Label
	if preview_img and img_path != "":
		preview_img.texture = load(img_path)
	if preview_lbl:
		preview_lbl.text = data.get("name", card_id) + "\n(" + data.get("type", "Desconocido") + ")"

func _get_species_count(card_id: String) -> int:
	var data = CardDatabase.get_card(card_id)
	var species_name = data.get("name", card_id).to_lower()
	var count = 0
	for id in current_deck:
		var d = CardDatabase.get_card(id)
		if d.get("name", id).to_lower() == species_name:
			count += 1
	return count

func _add_to_deck(card_id: String) -> void:
	var data = CardDatabase.get_card(card_id)
	var is_energy = data.get("type") == "ENERGY"
	var max_copies = 20 if is_energy else 4
	var count = current_deck.count(card_id) if is_energy else _get_species_count(card_id)
	if count >= max_copies or current_deck.size() >= 60:
		return
	current_deck.append(card_id)
	var header = UITheme.find_node(screen_container, "CountLbl")
	if header: header = header.get_parent().get_parent()
	_update_count_label(header)
	var dp = UITheme.find_node(screen_container, "DeckPanel")
	if dp:
		_refresh_deck_list(dp, header)

func _update_count_label(header: Control) -> void:
	var lbl = UITheme.find_node(header, "CountLbl") as Label
	if lbl:
		lbl.text = str(current_deck.size()) + " / 60 Cartas"
		lbl.add_theme_color_override("font_color",
			COLOR_GREEN if current_deck.size() == 60 else COLOR_TEXT_DIM)

func _refresh_deck_list(deck_panel: Control, header: Control = null) -> void:
	var vbox = UITheme.find_node(deck_panel, "DeckVBox")
	if not vbox: return
	for c in vbox.get_children(): c.queue_free()
	if header: _update_count_label(header)

	var counts: Dictionary = {}
	var types_count: Dictionary = {}
	for id in current_deck:
		counts[id] = counts.get(id, 0) + 1
		var d = CardDatabase.get_card(id)
		var type = d.get("pokemon_type", d.get("type", "")).to_upper()
		types_count[type] = types_count.get(type, 0) + 1

	for id in counts:
		var data = CardDatabase.get_card(id)
		var type_str = data.get("pokemon_type", data.get("type", ""))

		var panel = PanelContainer.new()
		var st_panel = StyleBoxFlat.new()
		st_panel.bg_color = Color(0.12, 0.14, 0.20, 0.8)
		st_panel.corner_radius_top_left = 6; st_panel.corner_radius_top_right = 6
		st_panel.corner_radius_bottom_left = 6; st_panel.corner_radius_bottom_right = 6
		st_panel.border_width_left = 4
		st_panel.border_color = UITheme.type_color(type_str)
		panel.add_theme_stylebox_override("panel", st_panel)
		vbox.add_child(panel)

		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		row.custom_minimum_size = Vector2(0, 30)
		panel.add_child(row)

		var spacer = Control.new()
		spacer.custom_minimum_size = Vector2(2, 0)
		row.add_child(spacer)

		var icon_tex = UITheme.type_icon(type_str)
		if icon_tex:
			var icon_rect = TextureRect.new()
			icon_rect.texture = icon_tex
			icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon_rect.custom_minimum_size = Vector2(18, 18)
			icon_rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			row.add_child(icon_rect)

		var n = Label.new()
		n.text = data.get("name", id).left(18)
		n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		n.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		n.add_theme_font_size_override("font_size", 12)
		n.add_theme_color_override("font_color", COLOR_TEXT)
		row.add_child(n)

		var cnt = Label.new()
		cnt.text = "×" + str(counts[id])
		cnt.custom_minimum_size = Vector2(30, 0)
		cnt.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		cnt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		cnt.add_theme_font_size_override("font_size", 12)
		cnt.add_theme_color_override("font_color", COLOR_GOLD)
		row.add_child(cnt)

		var rm = Button.new()
		rm.text = "−"
		rm.custom_minimum_size = Vector2(26, 26)
		rm.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		rm.add_theme_font_size_override("font_size", 14)
		rm.add_theme_color_override("font_color", Color.WHITE)
		var rms = StyleBoxFlat.new()
		rms.bg_color = Color(0.3, 0.1, 0.1, 0.5)
		rms.corner_radius_top_left = 6; rms.corner_radius_top_right = 6
		rms.corner_radius_bottom_left = 6; rms.corner_radius_bottom_right = 6
		var rms_hov = rms.duplicate()
		rms_hov.bg_color = Color(0.6, 0.2, 0.2, 0.9)
		rm.add_theme_stylebox_override("normal", rms)
		rm.add_theme_stylebox_override("hover", rms_hov)
		rm.pressed.connect(func():
			current_deck.erase(id)
			_refresh_deck_list(deck_panel, header)
		)
		row.add_child(rm)

		panel.mouse_filter = Control.MOUSE_FILTER_PASS
		panel.mouse_entered.connect(func():
			var s = st_panel.duplicate()
			s.bg_color = Color(0.18, 0.22, 0.32, 0.9)
			panel.add_theme_stylebox_override("panel", s)
			_show_card_preview(id)
		)
		panel.mouse_exited.connect(func():
			panel.add_theme_stylebox_override("panel", st_panel)
		)

	_update_stats_bar(types_count, current_deck.size())

func _update_stats_bar(types_count: Dictionary, total: int) -> void:
	var stats_hb = UITheme.find_node(screen_container, "StatsBar") as HBoxContainer
	if not stats_hb: return
	for c in stats_hb.get_children(): c.queue_free()
	if total == 0: return

	var type_order = ["GRASS","FIRE","WATER","LIGHTNING","PSYCHIC","FIGHTING","DARKNESS","METAL","COLORLESS","TRAINER","ENERGY"]
	var type_names = {"GRASS":"Planta","FIRE":"Fuego","WATER":"Agua","LIGHTNING":"Rayo","PSYCHIC":"Psíquico","FIGHTING":"Lucha","COLORLESS":"Incoloro","DARKNESS":"Siniestro","METAL":"Metálico","TRAINER":"Entrenador","ENERGY":"Energía"}

	for type in type_order:
		if not types_count.has(type): continue
		var count = types_count[type]
		if count == 0: continue
		var rect = ColorRect.new()
		rect.color = UITheme.type_color(type)
		rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		rect.size_flags_stretch_ratio = max(float(count) / total, 0.01)
		rect.mouse_filter = Control.MOUSE_FILTER_STOP
		rect.tooltip_text = str(count) + " " + type_names.get(type, type)
		stats_hb.add_child(rect)

func _refresh_collection_grid() -> void:
	var grid = UITheme.find_node(screen_container, "CollectionGrid")
	var search_box = UITheme.find_node(screen_container, "SearchInput") as LineEdit
	var cat_box = UITheme.find_node(screen_container, "CatFilter") as OptionButton
	var elem_box = UITheme.find_node(screen_container, "ElemFilter") as OptionButton
	var rarity_box = UITheme.find_node(screen_container, "RarityFilter") as OptionButton
	if not grid: return

	for c in grid.get_children(): c.queue_free()

	var search_text = search_box.text.to_lower() if search_box else ""
	var sel_cat    = cat_box.get_item_text(cat_box.selected) if cat_box else "Categoría: Todas"
	var sel_elem   = elem_box.get_item_text(elem_box.selected) if elem_box else "Elemento: Todos"
	var sel_rarity = rarity_box.get_item_text(rarity_box.selected) if rarity_box else "Rareza: Todas"

	var baby_names = ["pichu","cleffa","igglybuff","smoochum","tyrogue","elekid","magby"]

	for id in CardDatabase.get_all_ids():
		var card = CardDatabase.get_card(id)
		var c_name   = card.get("name", "").to_lower()
		var c_type   = card.get("type", "").to_upper()
		var c_elem   = card.get("pokemon_type", card.get("type", "")).to_upper()
		var c_rarity = card.get("rarity", "COMMON").to_upper()
		var c_stage  = card.get("stage", 0)
		var is_baby  = card.get("is_baby", false) or c_name in baby_names

		if search_text != "" and not search_text in c_name: continue

		if sel_cat != "Categoría: Todas":
			if sel_cat == "Básico"     and (c_type != "POKEMON" or int(c_stage) != 0 or is_baby): continue
			if sel_cat == "Bebé"       and (c_type != "POKEMON" or not is_baby): continue
			if sel_cat == "Fase 1"     and (c_type != "POKEMON" or int(c_stage) != 1): continue
			if sel_cat == "Fase 2"     and (c_type != "POKEMON" or int(c_stage) != 2): continue
			if sel_cat == "Entrenador" and c_type != "TRAINER": continue
			if sel_cat == "Energía"    and c_type != "ENERGY": continue

		if sel_elem != "Elemento: Todos":
			var target = {"Fuego":"FIRE","Agua":"WATER","Planta":"GRASS","Rayo":"LIGHTNING","Psíquico":"PSYCHIC","Lucha":"FIGHTING","Incoloro":"COLORLESS","Siniestro":"DARKNESS","Metálico":"METAL"}.get(sel_elem, "")
			if c_elem != target: continue

		if sel_rarity != "Rareza: Todas":
			if sel_rarity == "Común / Infrecuente" and c_rarity not in ["COMMON","UNCOMMON"]: continue
			if sel_rarity == "Rara / Holo"         and c_rarity not in ["RARE","RARE_HOLO"]: continue
			if sel_rarity == "Ultra Rara"           and c_rarity != "ULTRA_RARE": continue

		grid.add_child(_mini_card(id))

# ============================================================
# MAZOS PREDEFINIDOS
# ============================================================
func _get_starter_deck_fire() -> Array:
	var d = []
	for i in 4:  d.append("cyndaquil_1")
	for i in 3:  d.append("cyndaquil_2")
	for i in 3:  d.append("quilava_1")
	for i in 2:  d.append("quilava_2")
	for i in 2:  d.append("typhlosion_1")
	for i in 2:  d.append("typhlosion_2")
	for i in 2:  d.append("pichu")
	for i in 2:  d.append("pikachu")
	for i in 2:  d.append("magmar")
	for i in 2:  d.append("magby")
	for i in 4:  d.append("professor_elm")
	for i in 3:  d.append("bills_teleporter")
	for i in 3:  d.append("moo_moo_milk")
	for i in 2:  d.append("super_rod")
	for i in 2:  d.append("double_gust")
	for i in 2:  d.append("focus_band")
	for i in 2:  d.append("gold_berry")
	for i in 14: d.append("fire_energy")
	for i in 4:  d.append("lightning_energy")
	return d  # 60 cartas

func _get_starter_deck_water() -> Array:
	var d = []
	for i in 4: d.append("totodile_1")
	for i in 3: d.append("croconaw_1")
	for i in 2: d.append("feraligatr_1")
	for i in 3: d.append("slowpoke")
	for i in 2: d.append("slowking")
	for i in 4: d.append("horsea")
	for i in 4: d.append("seadra")
	for i in 4: d.append("mary")
	for i in 4: d.append("professor_elm")
	for i in 4: d.append("super_scoop_up")
	for i in 3: d.append("moo_moo_milk")
	for i in 3: d.append("time_capsule")
	for i in 20: d.append("water_energy")
	return d  # 60 cartas

func _get_starter_deck_grass() -> Array:
	# FIX: corregido de 56 a 60 cartas (añadidos 4 grass_energy)
	var d = []
	for i in 4: d.append("chikorita_1")
	for i in 3: d.append("bayleef_1")
	for i in 2: d.append("meganium_1")
	for i in 3: d.append("hoppip")
	for i in 2: d.append("skiploom")
	for i in 2: d.append("jumpluff")
	for i in 4: d.append("spinarak")
	for i in 4: d.append("professor_elm")
	for i in 4: d.append("sprout_tower")
	for i in 4: d.append("berry")
	for i in 4: d.append("pokemon_march")
	for i in 4: d.append("bills_teleporter")
	for i in 20: d.append("grass_energy")
	return d  # 60 cartas

func _get_starter_deck_lightning() -> Array:
	# FIX: corregido de 57 a 60 cartas (añadidos 3 lightning_energy)
	var d = []
	for i in 4: d.append("mareep")
	for i in 3: d.append("flaaffy")
	for i in 2: d.append("ampharos")
	for i in 3: d.append("chinchou")
	for i in 2: d.append("lanturn")
	for i in 4: d.append("elekid")
	for i in 4: d.append("pikachu")
	for i in 4: d.append("professor_elm")
	for i in 4: d.append("pokegear")
	for i in 4: d.append("energy_charge")
	for i in 3: d.append("double_gust")
	for i in 3: d.append("super_rod")
	for i in 20: d.append("lightning_energy")
	return d  # 60 cartas

# ============================================================
# VALIDACIÓN
# ============================================================
func _validate_deck_local(deck: Array) -> Dictionary:
	if deck.size() != 60:
		return { "valid": false, "error": str(deck.size()) + "/60 cartas" }
	var species_counts: Dictionary = {}
	for id in deck:
		var data = CardDatabase.get_card(id)
		if data.is_empty():
			return { "valid": false, "error": "Carta desconocida: " + id }
		if data.get("type") != "ENERGY":
			var species = data.get("name", id).to_lower()
			species_counts[species] = species_counts.get(species, 0) + 1
			if species_counts[species] > 4:
				return { "valid": false, "error": "Máx 4 copias de " + data.get("name", id) }
	for id in deck:
		var c = CardDatabase.get_card(id)
		if c.get("type") == "POKEMON" and int(c.get("stage", 0)) == 0:
			return { "valid": true }
	return { "valid": false, "error": "Necesitas al menos 1 Pokémon básico" }

# ============================================================
# NETWORK
# ============================================================
func _connect_network() -> void:
	if not NetworkManager: return
	NetworkManager.connected_to_server.connect(func(): _show_screen(current_screen))
	NetworkManager.disconnected_from_server.connect(func(): _show_screen(current_screen))
