extends Control

# ============================================================
# MainMenu.gd  —  RESPONSIVE & DESIGN PREMIUM
# ============================================================

enum Screen { LOGIN, LOBBY, DECK_BUILDER, QUEUE }

var current_screen: Screen = Screen.LOGIN
var player_id: String = ""
var current_deck: Array = []
var deck_name: String = "Fuego Inicial"

const COLOR_BG       = Color(0.04, 0.05, 0.08)
const COLOR_PANEL    = Color(0.07, 0.09, 0.14, 0.97)
const COLOR_GOLD     = Color(0.95, 0.82, 0.40)
const COLOR_GOLD_DIM = Color(0.55, 0.44, 0.18)
const COLOR_TEXT     = Color(0.93, 0.90, 0.80)
const COLOR_TEXT_DIM = Color(0.55, 0.54, 0.48)
const COLOR_ACCENT   = Color(0.22, 0.58, 0.92)
const COLOR_ACCENT2  = Color(0.15, 0.75, 0.80)
const COLOR_RED      = Color(0.80, 0.22, 0.22)
const COLOR_GREEN    = Color(0.22, 0.72, 0.38)
const COLOR_PURPLE   = Color(0.45, 0.22, 0.72)

var screen_container: Control = null
var _particles: Array = []
var _particle_timer: float = 0.0

# ─── READY ──────────────────────────────────────────────────
func _ready() -> void:
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
	_show_screen(current_screen)

func _process(delta: float) -> void:
	_particle_timer += delta
	if _particle_timer > 0.45:
		_particle_timer = 0.0
		_spawn_particle()
	_update_particles(delta)

# ─── FONDO ──────────────────────────────────────────────────
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
	c.anchor_left   = px; c.anchor_right  = px; c.anchor_top = py; c.anchor_bottom = py
	c.offset_left = -radius; c.offset_right = radius; c.offset_top = -radius; c.offset_bottom = radius
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var panel = Panel.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	var st = StyleBoxFlat.new()
	st.bg_color     = Color.from_hsv(0.60 + hue * 0.1, 0.4, 0.15, 0.06)
	st.border_color = Color.from_hsv(0.55 + hue * 0.1, 0.6, 0.5, 0.07)
	st.border_width_left = 1; st.border_width_right = 1; st.border_width_top = 1; st.border_width_bottom = 1
	for corner in ["corner_radius_top_left", "corner_radius_top_right", "corner_radius_bottom_left", "corner_radius_bottom_right"]:
		st.set(corner, int(radius))
	panel.add_theme_stylebox_override("panel", st)
	c.add_child(panel)
	add_child(c)

# ─── PARTÍCULAS ─────────────────────────────────────────────
func _spawn_particle() -> void:
	var layer = get_node_or_null("ParticleLayer")
	if not layer: return
	var vp = get_viewport().get_visible_rect().size
	var rng = RandomNumberGenerator.new()
	rng.randomize()

	var dot = ColorRect.new()
	dot.color = COLOR_GOLD if rng.randf() > 0.5 else COLOR_ACCENT2
	dot.color.a = 0.0
	var sz = rng.randf_range(6, 12) 
	dot.size = Vector2(sz, sz)
	dot.position = Vector2(rng.randf_range(0, vp.x), vp.y + 10)
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(dot)

	_particles.append({
		"node": dot,
		"speed": rng.randf_range(30, 80),
		"drift": rng.randf_range(-20, 20),
		"life": rng.randf_range(4.0, 9.0),
		"age": 0.0
	})

func _update_particles(delta: float) -> void:
	var to_remove = []
	for p in _particles:
		if not is_instance_valid(p.node):
			to_remove.append(p)
			continue
		p.age += delta
		var t = p.age / p.life
		p.node.position.y -= p.speed * delta
		p.node.position.x += p.drift * delta * 0.1
		p.node.color.a = min(t * 6.0, 1.0) * (1.0 - t) * 0.7
		if p.age >= p.life:
			p.node.queue_free()
			to_remove.append(p)
	for p in to_remove:
		_particles.erase(p)

# ============================================================
# NAVEGACIÓN
# ============================================================
func _show_screen(screen: Screen) -> void:
	current_screen = screen
	for child in screen_container.get_children():
		child.queue_free()
	match screen:
		Screen.LOGIN: _build_login_screen()
		Screen.LOBBY: _build_lobby_screen()
		Screen.DECK_BUILDER: _build_deck_builder()
		Screen.QUEUE: _build_queue_screen()

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
	st_card.border_width_left = 1; st_card.border_width_right = 1; st_card.border_width_top = 1; st_card.border_width_bottom = 1
	st_card.corner_radius_top_left = 20; st_card.corner_radius_top_right = 20; st_card.corner_radius_bottom_left = 20; st_card.corner_radius_bottom_right = 20
	st_card.shadow_color = Color(0, 0, 0, 0.4); st_card.shadow_size = 40; st_card.shadow_offset = Vector2(0, 15)
	card.add_theme_stylebox_override("panel", st_card)
	center.add_child(card)

	var card_hbox = HBoxContainer.new()
	card_hbox.add_theme_constant_override("separation", 0)
	card.add_child(card_hbox)

	var left_panel = PanelContainer.new()
	left_panel.custom_minimum_size = Vector2(360, 0)
	var grad = Gradient.new()
	grad.set_color(0, COLOR_BG.darkened(0.2)); grad.set_color(1, Color(COLOR_GOLD_DIM.r, COLOR_GOLD_DIM.g, COLOR_GOLD_DIM.b, 0.6)) 
	var grad_tex = GradientTexture2D.new()
	grad_tex.gradient = grad; grad_tex.fill_from = Vector2(0, 0); grad_tex.fill_to = Vector2(1, 1)
	var st_left = StyleBoxTexture.new(); st_left.texture = grad_tex
	left_panel.add_theme_stylebox_override("panel", st_left)
	card_hbox.add_child(left_panel)

	var left_m = MarginContainer.new()
	left_m.add_theme_constant_override("margin_left", 32); left_m.add_theme_constant_override("margin_right", 32); left_m.add_theme_constant_override("margin_top", 32); left_m.add_theme_constant_override("margin_bottom", 32)
	left_panel.add_child(left_m)

	var left_v = VBoxContainer.new()
	left_m.add_child(left_v)

	var brand_lbl = Label.new(); brand_lbl.text = "◈ Pokémon TCG"; brand_lbl.add_theme_font_size_override("font_size", 16); brand_lbl.add_theme_color_override("font_color", COLOR_GOLD)
	left_v.add_child(brand_lbl)
	var spacer = Control.new(); spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL; left_v.add_child(spacer)
	var sub_msg = Label.new(); sub_msg.text = "you can easily"; sub_msg.add_theme_font_size_override("font_size", 14); sub_msg.add_theme_color_override("font_color", COLOR_TEXT_DIM)
	left_v.add_child(sub_msg)
	var main_msg = Label.new(); main_msg.text = "Simplify your game experience\nAnd organize your collection\nwith clarity."; main_msg.autowrap_mode = TextServer.AUTOWRAP_WORD; main_msg.add_theme_font_size_override("font_size", 24); main_msg.add_theme_color_override("font_color", COLOR_TEXT)
	left_v.add_child(main_msg); left_v.add_child(_vspace(8))
	var ver_msg = Label.new(); ver_msg.text = "v0.1 Alpha · 111 cartas Neo Genesis"; ver_msg.add_theme_font_size_override("font_size", 11); ver_msg.add_theme_color_override("font_color", COLOR_TEXT_DIM.darkened(0.2))
	left_v.add_child(ver_msg)

	var right_m = MarginContainer.new(); right_m.size_flags_horizontal = Control.SIZE_EXPAND_FILL; right_m.add_theme_constant_override("margin_left", 60); right_m.add_theme_constant_override("margin_right", 60); right_m.add_theme_constant_override("margin_top", 50); right_m.add_theme_constant_override("margin_bottom", 50)
	card_hbox.add_child(right_m)
	var right_v = VBoxContainer.new(); right_v.alignment = BoxContainer.ALIGNMENT_CENTER; right_v.add_theme_constant_override("separation", 14); right_m.add_child(right_v)

	var star = Label.new(); star.text = "✱"; star.add_theme_font_size_override("font_size", 34); star.add_theme_color_override("font_color", COLOR_GOLD)
	right_v.add_child(star)
	var title = Label.new(); title.text = "Create your Account"; title.add_theme_font_size_override("font_size", 28); title.add_theme_color_override("font_color", COLOR_TEXT)
	right_v.add_child(title)
	var subtitle = Label.new(); subtitle.text = "Access your collection, decks, and matches anytime, anywhere."; subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD; subtitle.add_theme_font_size_override("font_size", 12); subtitle.add_theme_color_override("font_color", COLOR_TEXT_DIM)
	right_v.add_child(subtitle); right_v.add_child(_vspace(12))

	var lbl_input = Label.new(); lbl_input.text = "Trainer Name"; lbl_input.add_theme_font_size_override("font_size", 11); lbl_input.add_theme_color_override("font_color", COLOR_TEXT)
	right_v.add_child(lbl_input)
	var name_input = LineEdit.new(); name_input.name = "NameInput"; name_input.placeholder_text = "ej: AshKetchum"; name_input.custom_minimum_size = Vector2(0, 46); name_input.add_theme_font_size_override("font_size", 14); name_input.add_theme_color_override("font_color", COLOR_TEXT); name_input.add_theme_color_override("caret_color", COLOR_GOLD)
	var st_in = StyleBoxFlat.new(); st_in.bg_color = COLOR_BG; st_in.border_color = Color(COLOR_GOLD_DIM.r, COLOR_GOLD_DIM.g, COLOR_GOLD_DIM.b, 0.3); st_in.border_width_left = 1; st_in.border_width_right = 1; st_in.border_width_top = 1; st_in.border_width_bottom = 1; st_in.corner_radius_top_left = 6; st_in.corner_radius_top_right = 6; st_in.corner_radius_bottom_left = 6; st_in.corner_radius_bottom_right = 6; st_in.content_margin_left = 14
	var st_in_focus = st_in.duplicate(); st_in_focus.border_color = COLOR_GOLD; name_input.add_theme_stylebox_override("normal", st_in); name_input.add_theme_stylebox_override("focus", st_in_focus)
	right_v.add_child(name_input); right_v.add_child(_vspace(10))

	var btn_connect = Button.new(); btn_connect.text = "Connect & Play"; btn_connect.custom_minimum_size = Vector2(0, 48); btn_connect.add_theme_font_size_override("font_size", 15); btn_connect.add_theme_color_override("font_color", COLOR_PANEL) 
	var st_btn = StyleBoxFlat.new(); st_btn.bg_color = COLOR_GOLD; st_btn.corner_radius_top_left = 8; st_btn.corner_radius_top_right = 8; st_btn.corner_radius_bottom_left = 8; st_btn.corner_radius_bottom_right = 8; st_btn.shadow_color = Color(COLOR_GOLD.r, COLOR_GOLD.g, COLOR_GOLD.b, 0.2); st_btn.shadow_size = 15; st_btn.shadow_offset = Vector2(0, 4)
	var st_btn_hov = st_btn.duplicate(); st_btn_hov.bg_color = COLOR_GOLD.lightened(0.1); var st_btn_press = st_btn.duplicate(); st_btn_press.bg_color = COLOR_GOLD.darkened(0.1); st_btn_press.shadow_size = 5; st_btn_press.shadow_offset = Vector2(0, 1)
	btn_connect.add_theme_stylebox_override("normal", st_btn); btn_connect.add_theme_stylebox_override("hover", st_btn_hov); btn_connect.add_theme_stylebox_override("pressed", st_btn_press); btn_connect.pressed.connect(func(): _on_connect_pressed(name_input)); right_v.add_child(btn_connect)

	var div_hb = HBoxContainer.new(); var line_color = Color(COLOR_GOLD_DIM.r, COLOR_GOLD_DIM.g, COLOR_GOLD_DIM.b, 0.2)
	var l_line = ColorRect.new(); l_line.color = line_color; l_line.size_flags_horizontal = Control.SIZE_EXPAND_FILL; l_line.custom_minimum_size = Vector2(0, 1); l_line.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var div_lbl = Label.new(); div_lbl.text = "  or continue with  "; div_lbl.add_theme_font_size_override("font_size", 11); div_lbl.add_theme_color_override("font_color", COLOR_TEXT_DIM)
	var r_line = ColorRect.new(); r_line.color = line_color; r_line.size_flags_horizontal = Control.SIZE_EXPAND_FILL; r_line.custom_minimum_size = Vector2(0, 1); r_line.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	div_hb.add_child(l_line); div_hb.add_child(div_lbl); div_hb.add_child(r_line); right_v.add_child(div_hb)

	var btn_local = Button.new(); btn_local.text = "Local Play (No Server)"; btn_local.custom_minimum_size = Vector2(0, 44); btn_local.add_theme_font_size_override("font_size", 14); btn_local.add_theme_color_override("font_color", COLOR_GOLD_DIM)
	var st_local = StyleBoxFlat.new(); st_local.bg_color = Color(0,0,0,0); st_local.border_color = Color(COLOR_GOLD_DIM.r, COLOR_GOLD_DIM.g, COLOR_GOLD_DIM.b, 0.4); st_local.border_width_left = 1; st_local.border_width_right = 1; st_local.border_width_top = 1; st_local.border_width_bottom = 1; st_local.corner_radius_top_left = 8; st_local.corner_radius_top_right = 8; st_local.corner_radius_bottom_left = 8; st_local.corner_radius_bottom_right = 8
	var st_local_hov = st_local.duplicate(); st_local_hov.bg_color = Color(1, 1, 1, 0.03); st_local_hov.border_color = COLOR_GOLD_DIM; var st_local_press = st_local.duplicate(); st_local_press.bg_color = Color(0, 0, 0, 0.1)
	btn_local.add_theme_stylebox_override("normal", st_local); btn_local.add_theme_stylebox_override("hover", st_local_hov); btn_local.add_theme_stylebox_override("pressed", st_local_press); btn_local.pressed.connect(func(): _on_local_pressed(name_input)); right_v.add_child(btn_local)

	var conn_text = "Status: Server Connected" if NetworkManager.ws_connected else "Status: Offline"
	var conn_color = COLOR_GOLD if NetworkManager.ws_connected else COLOR_TEXT_DIM
	var status_lbl = Label.new(); status_lbl.text = conn_text; status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; status_lbl.add_theme_font_size_override("font_size", 11); status_lbl.add_theme_color_override("font_color", conn_color)
	right_v.add_child(_vspace(10)); right_v.add_child(status_lbl)

	var logo_hbox = HBoxContainer.new(); logo_hbox.anchor_left = 1.0; logo_hbox.anchor_right = 1.0; logo_hbox.anchor_top = 1.0; logo_hbox.anchor_bottom = 1.0; logo_hbox.offset_left = -550; logo_hbox.offset_top = -100; logo_hbox.offset_right = -24; logo_hbox.offset_bottom = -20; logo_hbox.alignment = BoxContainer.ALIGNMENT_END; logo_hbox.add_theme_constant_override("separation", 16)
	screen_container.add_child(logo_hbox)

	for path in ["res://assets/imagen/logo_dev.png", "res://assets/imagen/logo_pokemon.png"]:
		var tex = load(path)
		if tex:
			var tr = TextureRect.new(); tr.texture = tex; tr.custom_minimum_size = Vector2(200, 80); tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED; tr.modulate = Color(1, 1, 1, 0.6)
			tr.mouse_filter = Control.MOUSE_FILTER_STOP; tr.mouse_entered.connect(func(): tr.modulate = Color(1, 1, 1, 1.0)); tr.mouse_exited.connect(func(): tr.modulate = Color(1, 1, 1, 0.6))
			logo_hbox.add_child(tr)
		else:
			var debug_lbl = Label.new(); debug_lbl.text = "ERROR: " + path.get_file(); debug_lbl.add_theme_font_size_override("font_size", 18); debug_lbl.add_theme_color_override("font_color", Color(1.0, 0.0, 0.0)); logo_hbox.add_child(debug_lbl)

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

	var hbox = HBoxContainer.new(); hbox.set_anchors_preset(Control.PRESET_FULL_RECT); header.add_child(hbox)
	var accent = ColorRect.new(); accent.color = COLOR_GOLD; accent.custom_minimum_size = Vector2(6, 0); hbox.add_child(accent)

	var title_m = MarginContainer.new(); title_m.add_theme_constant_override("margin_left", 20); title_m.size_flags_horizontal = Control.SIZE_EXPAND_FILL; hbox.add_child(title_m)
	var title_v = VBoxContainer.new(); title_v.alignment = BoxContainer.ALIGNMENT_CENTER; title_v.add_theme_constant_override("separation", 2); title_m.add_child(title_v)

	var title_lbl = Label.new(); title_lbl.text = "◈ POKÉMON TCG · NEO GENESIS"; title_lbl.add_theme_font_size_override("font_size", 16); title_lbl.add_theme_color_override("font_color", COLOR_GOLD); title_v.add_child(title_lbl)
	var subtitle_lbl = Label.new(); subtitle_lbl.text = "MAIN HUB"; subtitle_lbl.add_theme_font_size_override("font_size", 11); subtitle_lbl.add_theme_color_override("font_color", COLOR_TEXT_DIM); title_v.add_child(subtitle_lbl)

	var pill_m = MarginContainer.new(); pill_m.add_theme_constant_override("margin_right", 24); pill_m.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var pp = _pill("👤  Trainer: " + player_id, Color(0, 0, 0, 0.5), COLOR_GOLD, 36); pp.custom_minimum_size = Vector2(180, 36); pill_m.add_child(pp); hbox.add_child(pill_m)

	var center = CenterContainer.new(); center.anchor_left = 0; center.anchor_right = 1; center.anchor_top = 0; center.anchor_bottom = 1; center.offset_top = 70
	screen_container.add_child(center)
	var col = VBoxContainer.new(); col.custom_minimum_size = Vector2(500, 0); col.add_theme_constant_override("separation", 24); center.add_child(col)

	var play_card = PanelContainer.new()
	var st_play = StyleBoxFlat.new()
	st_play.bg_color = COLOR_PANEL; st_play.border_color = Color(COLOR_GOLD_DIM.r, COLOR_GOLD_DIM.g, COLOR_GOLD_DIM.b, 0.5)
	st_play.border_width_left = 1; st_play.border_width_right = 1; st_play.border_width_top = 1; st_play.border_width_bottom = 1
	st_play.corner_radius_top_left = 16; st_play.corner_radius_top_right = 16; st_play.corner_radius_bottom_left = 16; st_play.corner_radius_bottom_right = 16
	st_play.shadow_color = Color(0, 0, 0, 0.4); st_play.shadow_size = 25; st_play.shadow_offset = Vector2(0, 10)
	play_card.add_theme_stylebox_override("panel", st_play); col.add_child(play_card)

	var play_m = MarginContainer.new(); play_m.add_theme_constant_override("margin_left", 40); play_m.add_theme_constant_override("margin_right", 40); play_m.add_theme_constant_override("margin_top", 35); play_m.add_theme_constant_override("margin_bottom", 35); play_card.add_child(play_m)
	var play_v = VBoxContainer.new(); play_v.add_theme_constant_override("separation", 12); play_m.add_child(play_v)

	var play_title = Label.new(); play_title.text = "⚔ BATTLE ARENA"; play_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; play_title.add_theme_font_size_override("font_size", 22); play_title.add_theme_color_override("font_color", COLOR_GOLD); play_v.add_child(play_title)
	var play_desc = Label.new(); play_desc.text = "Enfrenta a otro entrenador en línea o juega de manera local."; play_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; play_desc.add_theme_font_size_override("font_size", 13); play_desc.add_theme_color_override("font_color", COLOR_TEXT_DIM); play_v.add_child(play_desc)

	var deck_status = Label.new(); deck_status.text = _get_deck_status_text(); deck_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; deck_status.add_theme_font_size_override("font_size", 12)
	var v = _validate_deck_local(current_deck); deck_status.add_theme_color_override("font_color", COLOR_GREEN if v.valid else Color("df673b")); play_v.add_child(deck_status)

	play_v.add_child(_vspace(15))

	var play_btn = Button.new(); play_btn.text = "BUSCAR PARTIDA" if NetworkManager.ws_connected else "JUGAR LOCAL"; play_btn.custom_minimum_size = Vector2(0, 50); play_btn.add_theme_font_size_override("font_size", 16); play_btn.add_theme_color_override("font_color", COLOR_PANEL)
	var st_btn_play = StyleBoxFlat.new(); st_btn_play.bg_color = COLOR_GOLD; st_btn_play.corner_radius_top_left = 10; st_btn_play.corner_radius_top_right = 10; st_btn_play.corner_radius_bottom_left = 10; st_btn_play.corner_radius_bottom_right = 10; st_btn_play.shadow_color = Color(COLOR_GOLD.r, COLOR_GOLD.g, COLOR_GOLD.b, 0.2); st_btn_play.shadow_size = 15; st_btn_play.shadow_offset = Vector2(0, 4)
	var st_btn_play_hov = st_btn_play.duplicate(); st_btn_play_hov.bg_color = COLOR_GOLD.lightened(0.1); var st_btn_play_press = st_btn_play.duplicate(); st_btn_play_press.bg_color = COLOR_GOLD.darkened(0.1); st_btn_play_press.shadow_size = 5; st_btn_play_press.shadow_offset = Vector2(0, 1)
	play_btn.add_theme_stylebox_override("normal", st_btn_play); play_btn.add_theme_stylebox_override("hover", st_btn_play_hov); play_btn.add_theme_stylebox_override("pressed", st_btn_play_press); play_btn.pressed.connect(func(): _on_play_pressed()); play_v.add_child(play_btn)

	var deck_card = PanelContainer.new(); var st_deck = StyleBoxFlat.new(); st_deck.bg_color = COLOR_BG.lightened(0.02); st_deck.border_color = Color(COLOR_GOLD_DIM.r, COLOR_GOLD_DIM.g, COLOR_GOLD_DIM.b, 0.2); st_deck.border_width_left = 1; st_deck.border_width_right = 1; st_deck.border_width_top = 1; st_deck.border_width_bottom = 1; st_deck.corner_radius_top_left = 16; st_deck.corner_radius_top_right = 16; st_deck.corner_radius_bottom_left = 16; st_deck.corner_radius_bottom_right = 16; deck_card.add_theme_stylebox_override("panel", st_deck); col.add_child(deck_card)
	var deck_m = MarginContainer.new(); deck_m.add_theme_constant_override("margin_left", 30); deck_m.add_theme_constant_override("margin_right", 30); deck_m.add_theme_constant_override("margin_top", 25); deck_m.add_theme_constant_override("margin_bottom", 25); deck_card.add_child(deck_m)
	var deck_v = VBoxContainer.new(); deck_v.add_theme_constant_override("separation", 8); deck_m.add_child(deck_v)

	var deck_title = Label.new(); deck_title.text = "🃏 DECK BUILDER"; deck_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; deck_title.add_theme_font_size_override("font_size", 16); deck_title.add_theme_color_override("font_color", COLOR_TEXT); deck_v.add_child(deck_title)
	var deck_desc = Label.new(); deck_desc.text = "Personaliza tu mazo · 111 cartas Neo Genesis"; deck_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; deck_desc.add_theme_font_size_override("font_size", 12); deck_desc.add_theme_color_override("font_color", COLOR_TEXT_DIM); deck_v.add_child(deck_desc); deck_v.add_child(_vspace(10))

	var deck_btn = Button.new(); deck_btn.text = "ABRIR CONSTRUCTOR"; deck_btn.custom_minimum_size = Vector2(0, 44); deck_btn.add_theme_font_size_override("font_size", 14); deck_btn.add_theme_color_override("font_color", COLOR_GOLD_DIM)
	var st_btn_deck = StyleBoxFlat.new(); st_btn_deck.bg_color = Color(0,0,0,0); st_btn_deck.border_color = Color(COLOR_GOLD_DIM.r, COLOR_GOLD_DIM.g, COLOR_GOLD_DIM.b, 0.4); st_btn_deck.border_width_left = 1; st_btn_deck.border_width_right = 1; st_btn_deck.border_width_top = 1; st_btn_deck.border_width_bottom = 1; st_btn_deck.corner_radius_top_left = 8; st_btn_deck.corner_radius_top_right = 8; st_btn_deck.corner_radius_bottom_left = 8; st_btn_deck.corner_radius_bottom_right = 8
	var st_btn_deck_hov = st_btn_deck.duplicate(); st_btn_deck_hov.bg_color = Color(1, 1, 1, 0.05); var st_btn_deck_press = st_btn_deck.duplicate(); st_btn_deck_press.bg_color = Color(0, 0, 0, 0.2); deck_btn.add_theme_stylebox_override("normal", st_btn_deck); deck_btn.add_theme_stylebox_override("hover", st_btn_deck_hov); deck_btn.add_theme_stylebox_override("pressed", st_btn_deck_press); deck_btn.pressed.connect(func(): _show_screen(Screen.DECK_BUILDER)); deck_v.add_child(deck_btn)

	var back_btn = Button.new(); back_btn.text = "← Cerrar sesión"; back_btn.custom_minimum_size = Vector2(150, 36); back_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER; back_btn.add_theme_font_size_override("font_size", 12); back_btn.add_theme_color_override("font_color", Color(0.6, 0.4, 0.4)) 
	var st_back = StyleBoxFlat.new(); st_back.bg_color = Color(0,0,0,0); var st_back_hov = st_back.duplicate(); st_back_hov.bg_color = Color(1, 0, 0, 0.1); st_back_hov.corner_radius_top_left = 6; st_back_hov.corner_radius_top_right = 6; st_back_hov.corner_radius_bottom_left = 6; st_back_hov.corner_radius_bottom_right = 6; back_btn.add_theme_stylebox_override("normal", st_back); back_btn.add_theme_stylebox_override("hover", st_back_hov); back_btn.add_theme_stylebox_override("pressed", st_back_hov); back_btn.pressed.connect(func(): NetworkManager.disconnect_from_server(); _show_screen(Screen.LOGIN)); col.add_child(back_btn)

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
# QUEUE
# ============================================================
func _build_queue_screen() -> void:
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	screen_container.add_child(center)

	var vp = get_viewport().get_visible_rect().size
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(clamp(vp.x * 0.40, 400, 540), 0)
	var ps = StyleBoxFlat.new()
	ps.bg_color              = COLOR_PANEL
	ps.border_color          = Color(COLOR_GOLD_DIM.r, COLOR_GOLD_DIM.g, COLOR_GOLD_DIM.b, 0.55)
	ps.border_width_left     = 1; ps.border_width_right    = 1; ps.border_width_top      = 1; ps.border_width_bottom   = 1
	ps.corner_radius_top_left     = 10; ps.corner_radius_top_right    = 10; ps.corner_radius_bottom_left  = 10; ps.corner_radius_bottom_right = 10
	ps.shadow_color = Color(0, 0, 0, 0.5); ps.shadow_size  = 12
	panel.add_theme_stylebox_override("panel", ps)
	center.add_child(panel)

	var vbox = VBoxContainer.new(); vbox.add_theme_constant_override("separation", 0); panel.add_child(vbox)
	vbox.add_child(_color_strip(COLOR_ACCENT, 6, true))

	var body = MarginContainer.new(); body.add_theme_constant_override("margin_left",   40); body.add_theme_constant_override("margin_right",  40); body.add_theme_constant_override("margin_top",    20); body.add_theme_constant_override("margin_bottom", 20); vbox.add_child(body)
	var inner = VBoxContainer.new(); inner.add_theme_constant_override("separation", 12); body.add_child(inner)

	inner.add_child(_clbl("BUSCANDO PARTIDA", 20, COLOR_GOLD)); inner.add_child(_clbl("Esperando a otro entrenador...", 11, COLOR_TEXT_DIM)); inner.add_child(_pill("🃏  " + deck_name, Color(0.10, 0.14, 0.10), COLOR_GREEN, 30))

	var dots = _clbl("◆  ◇  ◇", 26, COLOR_GOLD); dots.name = "Dots"; inner.add_child(dots); inner.add_child(_divider())

	var cancel_btn = _btn("CANCELAR BÚSQUEDA", COLOR_RED, 48, 13); cancel_btn.pressed.connect(func(): NetworkManager.leave_queue(); _show_screen(Screen.LOBBY)); inner.add_child(cancel_btn)

	NetworkManager.game_started.connect(func(_s): get_tree().change_scene_to_file("res://scenes/BattleBoard.tscn"), CONNECT_ONE_SHOT)
	_animate_dots(dots)

var _dot_frames: Array = ["◆  ◇  ◇", "◆  ◆  ◇", "◆  ◆  ◆", "◇  ◆  ◆", "◇  ◇  ◆", "◇  ◇  ◇"]
var _dot_idx: int = 0
var _dot_label: Label = null

func _animate_dots(lbl: Label) -> void:
	_dot_label = lbl; _dot_idx   = 0; _tick_dots()

func _tick_dots() -> void:
	if not is_instance_valid(_dot_label): return
	_dot_label.text = _dot_frames[_dot_idx % _dot_frames.size()]
	_dot_idx += 1
	get_tree().create_timer(0.35).timeout.connect(_tick_dots, CONNECT_ONE_SHOT)


# ============================================================
# DECK BUILDER (CON FILTROS AVANZADOS Y VISTA PREVIA)
# ============================================================
func _build_deck_builder() -> void:
	# --- FONDO ---
	var bg_image: TextureRect = TextureRect.new() 
	var bg_tex = load("res://assets/imagen/fondomenu.png") 
	if bg_tex: bg_image.texture = bg_tex
	bg_image.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg_image.modulate = Color(0.15, 0.15, 0.15, 1) 
	screen_container.add_child(bg_image)

	# --- HEADER GLASSMORPHISM ---
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
	st_back.bg_color = Color(0,0,0,0)
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
	main_area.offset_top = 90 
	main_area.offset_bottom = -20 
	main_area.offset_left = 24
	main_area.offset_right = -24
	main_area.add_theme_constant_override("separation", 16)
	screen_container.add_child(main_area)

	# ==========================================
	# 1. MITAD IZQUIERDA: COLECCIÓN (50% del espacio)
	# ==========================================
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

	# --- NUEVA BARRA DE FILTROS AVANZADA ---
	var filter_hbox = HBoxContainer.new()
	filter_hbox.add_theme_constant_override("separation", 8)
	cv.add_child(filter_hbox)

	var search_in = LineEdit.new()
	search_in.name = "SearchInput"
	search_in.placeholder_text = "🔎 Buscar..."
	search_in.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	search_in.add_theme_stylebox_override("normal", _input_style(Color(0.2, 0.2, 0.3)))
	search_in.add_theme_stylebox_override("focus", _input_style(COLOR_GOLD))
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
	cv.add_child(scroll)

	var grid = GridContainer.new()
	grid.name = "CollectionGrid"
	grid.columns = 5 
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 16)
	scroll.add_child(grid)

	# Conectamos las señales para actualizar la grilla
	search_in.text_changed.connect(func(_t): _refresh_collection_grid(header))
	cat_opt.item_selected.connect(func(_i): _refresh_collection_grid(header))
	elem_opt.item_selected.connect(func(_i): _refresh_collection_grid(header))
	rarity_opt.item_selected.connect(func(_i): _refresh_collection_grid(header))

	# ==========================================
	# 2. CENTRO: PREVIEW DE CARTA (25% del espacio)
	# ==========================================
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

	prev_v.add_child(_vspace(10))

	var prev_name = Label.new()
	prev_name.name = "PreviewName"
	prev_name.text = "Pasa el mouse o haz Click Derecho en una carta"
	prev_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prev_name.autowrap_mode = TextServer.AUTOWRAP_WORD
	prev_name.add_theme_font_size_override("font_size", 14)
	prev_name.add_theme_color_override("font_color", COLOR_GOLD)
	prev_v.add_child(prev_name)

	# ==========================================
	# 3. MITAD DERECHA: MAZO ACTUAL (25% del espacio)
	# ==========================================
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

	var btns_hb = HBoxContainer.new()
	btns_hb.add_theme_constant_override("separation", 12)
	dv.add_child(btns_hb)

	var demo_btn = Button.new()
	demo_btn.text = "Cargar Inicial"
	demo_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	demo_btn.custom_minimum_size = Vector2(0, 36)
	demo_btn.add_theme_font_size_override("font_size", 12)
	var st_demo = StyleBoxFlat.new()
	st_demo.bg_color = Color(0.16, 0.28, 0.18, 0.4)
	st_demo.border_color = Color(0.3, 0.6, 0.3)
	st_demo.border_width_left = 1; st_demo.border_width_top = 1; st_demo.border_width_right = 1; st_demo.border_width_bottom = 1
	st_demo.corner_radius_top_left = 6; st_demo.corner_radius_bottom_right = 6; st_demo.corner_radius_bottom_left = 6; st_demo.corner_radius_top_right = 6
	demo_btn.add_theme_stylebox_override("normal", st_demo)
	demo_btn.pressed.connect(func():
		current_deck = _get_starter_deck_fire()
		deck_name = "Fuego Inicial"
		_refresh_deck_list(dp_panel, header)
	)
	btns_hb.add_child(demo_btn)

	var clear_btn = Button.new()
	clear_btn.text = "Limpiar"
	clear_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	clear_btn.custom_minimum_size = Vector2(0, 36)
	clear_btn.add_theme_font_size_override("font_size", 12)
	var st_clear = StyleBoxFlat.new()
	st_clear.bg_color = Color(0.28, 0.10, 0.10, 0.3)
	st_clear.border_color = Color(0.6, 0.2, 0.2)
	st_clear.border_width_left = 1; st_clear.border_width_top = 1; st_clear.border_width_right = 1; st_clear.border_width_bottom = 1
	st_clear.corner_radius_top_left = 6; st_clear.corner_radius_bottom_right = 6; st_clear.corner_radius_bottom_left = 6; st_clear.corner_radius_top_right = 6
	clear_btn.add_theme_stylebox_override("normal", st_clear)
	clear_btn.pressed.connect(func():
		current_deck = []
		_refresh_deck_list(dp_panel, header)
	)
	btns_hb.add_child(clear_btn)

	_refresh_deck_list(dp_panel, header)
	_refresh_collection_grid(header) # Cargamos por primera vez

# ============================================================
# LÓGICA DE FILTROS AVANZADOS
# ============================================================
func _refresh_collection_grid(header: Control) -> void:
	var grid = _find_node(screen_container, "CollectionGrid")
	var search_box = _find_node(screen_container, "SearchInput") as LineEdit
	var cat_box = _find_node(screen_container, "CatFilter") as OptionButton
	var elem_box = _find_node(screen_container, "ElemFilter") as OptionButton
	var rarity_box = _find_node(screen_container, "RarityFilter") as OptionButton

	if not grid: return

	# 1. Limpiamos la grilla
	for c in grid.get_children():
		c.queue_free()

	# 2. Leemos qué dice cada botón
	var search_text = search_box.text.to_lower() if search_box else ""
	var sel_cat = cat_box.get_item_text(cat_box.selected) if cat_box else "Categoría: Todas"
	var sel_elem = elem_box.get_item_text(elem_box.selected) if elem_box else "Elemento: Todos"
	var sel_rarity = rarity_box.get_item_text(rarity_box.selected) if rarity_box else "Rareza: Todas"

	var all_ids = CardDatabase.get_all_ids()
	var filtered_ids = []

	# Lista de soporte por si no usas una variable "is_baby" en tu JSON
	var baby_names = ["pichu", "cleffa", "igglybuff", "smoochum", "tyrogue", "elekid", "magby"]

	# 3. Revisamos carta por carta
	for id in all_ids:
		var card = CardDatabase.get_card(id)
		var c_name = card.get("name", "").to_lower()
		var c_type = card.get("type", "").to_upper() # POKEMON, TRAINER, ENERGY
		var c_elem = card.get("pokemon_type", card.get("type", "")).to_upper() # FIRE, WATER...
		var c_rarity = card.get("rarity", "COMMON").to_upper()
		var c_stage = card.get("stage", 0)
		var is_baby = card.get("is_baby", false) or card.get("subtype", "") == "BABY" or c_name in baby_names

		# Filtro de Búsqueda por Nombre
		if search_text != "" and not search_text in c_name:
			continue

		# Filtro de Categoría (Etapa/Trainer)
		if sel_cat != "Categoría: Todas":
			if sel_cat == "Básico" and (c_type != "POKEMON" or c_stage != 0 or is_baby): continue
			if sel_cat == "Bebé" and (c_type != "POKEMON" or not is_baby): continue
			if sel_cat == "Fase 1" and (c_type != "POKEMON" or c_stage != 1): continue
			if sel_cat == "Fase 2" and (c_type != "POKEMON" or c_stage != 2): continue
			if sel_cat == "Entrenador" and c_type != "TRAINER": continue
			if sel_cat == "Energía" and c_type != "ENERGY": continue

		# Filtro de Elemento (Fuego, Agua...)
		if sel_elem != "Elemento: Todos":
			var target_elem = ""
			match sel_elem:
				"Fuego": target_elem = "FIRE"
				"Agua": target_elem = "WATER"
				"Planta": target_elem = "GRASS"
				"Rayo": target_elem = "LIGHTNING"
				"Psíquico": target_elem = "PSYCHIC"
				"Lucha": target_elem = "FIGHTING"
				"Incoloro": target_elem = "COLORLESS"
			
			if c_elem != target_elem:
				continue

		# Filtro de Rareza
		if sel_rarity != "Rareza: Todas":
			if sel_rarity == "Común / Infrecuente" and c_rarity not in ["COMMON", "UNCOMMON"]: continue
			if sel_rarity == "Rara / Holo" and c_rarity not in ["RARE", "RARE_HOLO"]: continue
			if sel_rarity == "Ultra Rara" and c_rarity != "ULTRA_RARE": continue

		# Si pasa todos los filtros, ¡la mostramos!
		filtered_ids.append(id)

	# 4. Agregamos las cartas filtradas
	for id in filtered_ids:
		grid.add_child(_mini_card(id, header))


func _mini_card(card_id: String, header: Control) -> Control:
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
				_add_to_deck(card_id, header)
			elif ev.button_index == MOUSE_BUTTON_RIGHT:
				_show_card_preview(card_id)
	)
	return c

func _show_card_preview(card_id: String) -> void:
	var data = CardDatabase.get_card(card_id)
	var img_path = data.get("image", "")
	var preview_img = _find_node(screen_container, "PreviewImage") as TextureRect
	var preview_lbl = _find_node(screen_container, "PreviewName") as Label
	if preview_img and img_path != "":
		preview_img.texture = load(img_path)
	if preview_lbl:
		preview_lbl.text = data.get("name", card_id) + "\n(" + data.get("type", "Desconocido") + ")"

# ── FIX: límite de 4 por nombre de especie ──────────────────
func _get_species_count(card_id: String) -> int:
	var data = CardDatabase.get_card(card_id)
	var species_name = data.get("name", card_id).to_lower()
	var count = 0
	for id in current_deck:
		var d = CardDatabase.get_card(id)
		if d.get("name", id).to_lower() == species_name:
			count += 1
	return count

func _add_to_deck(card_id: String, header: Control) -> void:
	var data = CardDatabase.get_card(card_id)
	var is_energy = data.get("type") == "ENERGY"
	var max_copies = 20 if is_energy else 4
	var count = current_deck.count(card_id) if is_energy else _get_species_count(card_id)
	if count >= max_copies or current_deck.size() >= 60:
		return
	current_deck.append(card_id)
	_update_count_label(header)
	var dp = _find_node(screen_container, "DeckPanel")
	if dp:
		_refresh_deck_list(dp, header)

func _update_count_label(header: Control) -> void:
	var lbl = _find_node(header, "CountLbl") as Label
	if lbl:
		lbl.text = str(current_deck.size()) + " / 60 Cartas"
		lbl.add_theme_color_override("font_color",
			COLOR_GREEN if current_deck.size() == 60 else COLOR_TEXT_DIM)

func _refresh_deck_list(deck_panel: Control, header: Control = null) -> void:
	var vbox = _find_node(deck_panel, "DeckVBox")
	if not vbox: return
	for c in vbox.get_children(): c.queue_free()
	if header: _update_count_label(header)

	var counts: Dictionary = {}
	for id in current_deck:
		counts[id] = counts.get(id, 0) + 1

	for id in counts:
		var data = CardDatabase.get_card(id)
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 4)
		row.custom_minimum_size = Vector2(0, 22)

		var dot = ColorRect.new()
		dot.color               = _type_color(data.get("pokemon_type", data.get("type", "")))
		dot.custom_minimum_size = Vector2(4, 18)
		dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(dot)

		var n = Label.new()
		n.text                  = data.get("name", id).left(17)
		n.custom_minimum_size   = Vector2(100, 20)
		n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		n.add_theme_font_size_override("font_size", 10)
		n.add_theme_color_override("font_color", COLOR_TEXT)
		row.add_child(n)

		var cnt = Label.new()
		cnt.text                 = "×" + str(counts[id])
		cnt.custom_minimum_size  = Vector2(24, 20)
		cnt.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		cnt.add_theme_font_size_override("font_size", 10)
		cnt.add_theme_color_override("font_color", COLOR_GOLD)
		row.add_child(cnt)

		var rm = Button.new()
		rm.text                = "−"
		rm.custom_minimum_size = Vector2(22, 20)
		rm.add_theme_font_size_override("font_size", 14)
		rm.add_theme_color_override("font_color", Color.WHITE)
		var rms = StyleBoxFlat.new()
		rms.bg_color                   = Color(0.22, 0.10, 0.10)
		rms.corner_radius_top_left     = 4; rms.corner_radius_top_right    = 4
		rms.corner_radius_bottom_left  = 4; rms.corner_radius_bottom_right = 4
		rm.add_theme_stylebox_override("normal", rms)
		rm.pressed.connect(func():
			current_deck.erase(id)
			_refresh_deck_list(deck_panel, header)
		)
		row.add_child(rm)
		vbox.add_child(row)

		var sep = ColorRect.new()
		sep.color               = Color(0.15, 0.18, 0.25)
		sep.custom_minimum_size = Vector2(0, 1)
		vbox.add_child(sep)

func _type_color(t: String) -> Color:
	match t.to_upper():
		"FIRE":       return Color(0.90, 0.35, 0.15)
		"WATER":      return Color(0.20, 0.55, 0.90)
		"GRASS":      return Color(0.25, 0.75, 0.30)
		"LIGHTNING":  return Color(0.95, 0.85, 0.10)
		"PSYCHIC":    return Color(0.75, 0.25, 0.80)
		"FIGHTING":   return Color(0.80, 0.45, 0.20)
		"COLORLESS":  return Color(0.65, 0.65, 0.65)
		"TRAINER":    return Color(0.30, 0.50, 0.80)
		"ENERGY":     return Color(0.50, 0.50, 0.50)
		_:            return Color(0.35, 0.35, 0.45)

func _find_node(root: Node, target: String) -> Node:
	if root.name == target: return root
	for c in root.get_children():
		var f = _find_node(c, target)
		if f: return f
	return null

# ============================================================
# DECK INICIAL
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
	return d

# ============================================================
# VALIDACIÓN — límite de 4 por nombre de especie
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
		if c.get("type") == "POKEMON" and c.get("stage", 0) == 0:
			return { "valid": true }
	return { "valid": false, "error": "Necesitas al menos 1 Pokémon básico" }

# ============================================================
# NETWORK
# ============================================================
func _connect_network() -> void:
	if not NetworkManager: return
	NetworkManager.connected_to_server.connect(func(): _show_screen(current_screen))
	NetworkManager.disconnected_from_server.connect(func(): _show_screen(current_screen))

# ============================================================
# HELPERS UI
# ============================================================
func _clbl(text: String, fs: int, color: Color) -> Label:
	var l = Label.new()
	l.text = text; l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.add_theme_font_size_override("font_size", fs)
	l.add_theme_color_override("font_color", color)
	return l

func _llbl(text: String, fs: int, color: Color) -> Label:
	var l = Label.new()
	l.text = text; l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.add_theme_font_size_override("font_size", fs)
	l.add_theme_color_override("font_color", color)
	return l

func _vspace(px: int) -> Control:
	var c = Control.new()
	c.custom_minimum_size = Vector2(0, px)
	return c

func _divider() -> Control:
	var hb = HBoxContainer.new()
	hb.add_theme_constant_override("separation", 0)
	hb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var ll = ColorRect.new()
	ll.color = Color(COLOR_GOLD_DIM.r, COLOR_GOLD_DIM.g, COLOR_GOLD_DIM.b, 0.35)
	ll.custom_minimum_size = Vector2(0, 1)
	ll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ll.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hb.add_child(ll)
	var dot = Label.new()
	dot.text = " ◆ "
	dot.add_theme_font_size_override("font_size", 9)
	dot.add_theme_color_override("font_color", COLOR_GOLD_DIM)
	hb.add_child(dot)
	var rl = ColorRect.new()
	rl.color = Color(COLOR_GOLD_DIM.r, COLOR_GOLD_DIM.g, COLOR_GOLD_DIM.b, 0.35)
	rl.custom_minimum_size = Vector2(0, 1)
	rl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hb.add_child(rl)
	var m = MarginContainer.new()
	m.add_theme_constant_override("margin_top", 4)
	m.add_theme_constant_override("margin_bottom", 4)
	m.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	m.add_child(hb)
	return m

func _pill(text: String, bg: Color, fg: Color, min_h: int) -> Control:
	var pc = PanelContainer.new()
	pc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pc.custom_minimum_size   = Vector2(0, min_h)
	var st = StyleBoxFlat.new()
	st.bg_color = bg
	st.border_color = Color(fg.r, fg.g, fg.b, 0.40)
	st.border_width_left = 1; st.border_width_right  = 1
	st.border_width_top  = 1; st.border_width_bottom = 1
	st.corner_radius_top_left = 5; st.corner_radius_top_right    = 5
	st.corner_radius_bottom_left = 5; st.corner_radius_bottom_right = 5
	pc.add_theme_stylebox_override("panel", st)
	var l = Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	l.add_theme_font_size_override("font_size", 10)
	l.add_theme_color_override("font_color", fg)
	pc.add_child(l)
	return pc

func _btn(text: String, color: Color, min_h: int, fs: int) -> Button:
	var b = Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, min_h)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.add_theme_font_size_override("font_size", fs)
	b.add_theme_color_override("font_color", Color.WHITE)
	for st_name in ["normal", "hover", "pressed", "focus", "disabled"]:
		var st = StyleBoxFlat.new()
		match st_name:
			"disabled": st.bg_color = Color(0.10, 0.10, 0.12)
			"hover":    st.bg_color = color.lightened(0.18)
			"pressed":  st.bg_color = color.darkened(0.12)
			_:          st.bg_color = color
		st.corner_radius_top_left = 6; st.corner_radius_top_right = 6
		st.corner_radius_bottom_left = 6; st.corner_radius_bottom_right = 6
		b.add_theme_stylebox_override(st_name, st)
	return b

func _color_strip(color: Color, height: int, rounded_top: bool = false) -> Control:
	var p = Panel.new()
	p.custom_minimum_size = Vector2(0, height)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var st = StyleBoxFlat.new()
	st.bg_color = color
	if rounded_top:
		st.corner_radius_top_left = 10; st.corner_radius_top_right = 10
	p.add_theme_stylebox_override("panel", st)
	return p

func _circle_icon(symbol: String, radius: int, color: Color) -> Control:
	var pc = PanelContainer.new()
	pc.custom_minimum_size = Vector2(radius * 2, radius * 2)
	var st = StyleBoxFlat.new()
	st.bg_color = Color(0.10, 0.12, 0.20)
	st.border_color = color
	st.border_width_left = 2; st.border_width_right  = 2
	st.border_width_top  = 2; st.border_width_bottom = 2
	st.corner_radius_top_left = radius; st.corner_radius_top_right    = radius
	st.corner_radius_bottom_left = radius; st.corner_radius_bottom_right = radius
	pc.add_theme_stylebox_override("panel", st)
	var l = Label.new()
	l.text = symbol
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	l.add_theme_font_size_override("font_size", radius - 4)
	l.add_theme_color_override("font_color", color)
	pc.add_child(l)
	return pc

func _input_style(border_color: Color) -> StyleBoxFlat:
	var st = StyleBoxFlat.new()
	st.bg_color = Color(0.05, 0.07, 0.12)
	st.border_color = border_color
	st.border_width_bottom = 2; st.border_width_left  = 1
	st.border_width_right  = 1; st.border_width_top   = 1
	st.corner_radius_top_left = 6; st.corner_radius_top_right = 6
	st.corner_radius_bottom_left = 6; st.corner_radius_bottom_right = 6
	st.content_margin_left = 14; st.content_margin_top    = 10
	st.content_margin_right = 14; st.content_margin_bottom = 10
	return st

func _styled_panel() -> Panel:
	var p = Panel.new()
	var st = StyleBoxFlat.new()
	st.bg_color = Color(0.07, 0.09, 0.14, 0.95)
	st.border_color = Color(COLOR_GOLD_DIM.r, COLOR_GOLD_DIM.g, COLOR_GOLD_DIM.b, 0.40)
	st.border_width_left = 1; st.border_width_right  = 1
	st.border_width_top  = 1; st.border_width_bottom = 1
	st.corner_radius_top_left = 8; st.corner_radius_top_right = 8
	st.corner_radius_bottom_left = 8; st.corner_radius_bottom_right = 8
	p.add_theme_stylebox_override("panel", st)
	return p

func _card(accent: Color, children: Array) -> Control:
	var pc = PanelContainer.new()
	pc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var ps = StyleBoxFlat.new()
	ps.bg_color = COLOR_PANEL
	ps.border_color = Color(COLOR_GOLD_DIM.r, COLOR_GOLD_DIM.g, COLOR_GOLD_DIM.b, 0.50)
	ps.border_width_left = 1; ps.border_width_right  = 1
	ps.border_width_top  = 1; ps.border_width_bottom = 1
	ps.corner_radius_top_left = 10; ps.corner_radius_top_right = 10
	ps.corner_radius_bottom_left = 10; ps.corner_radius_bottom_right = 10
	pc.add_theme_stylebox_override("panel", ps)
	var vb = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 0)
	pc.add_child(vb)
	vb.add_child(_color_strip(accent, 4, true))
	var m = MarginContainer.new()
	m.add_theme_constant_override("margin_left", 16); m.add_theme_constant_override("margin_right", 16)
	m.add_theme_constant_override("margin_top", 14);  m.add_theme_constant_override("margin_bottom", 14)
	vb.add_child(m)
	var inner = VBoxContainer.new()
	inner.name = "CardInner"
	inner.add_theme_constant_override("separation", 8)
	m.add_child(inner)
	for child in children:
		inner.add_child(child)
	return pc
