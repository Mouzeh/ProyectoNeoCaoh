extends Control

# ============================================================
# MainMenu.gd — Orquestador principal
# Solo maneja: navegación, estado global, partículas, red
# Cada pantalla vive en scenes/main_menu/screens/
# ============================================================

# ─── Pantallas ───────────────────────────────────────────────
const LoginScreen       = preload("res://scenes/main_menu/screens/LoginScreen.gd")
const HomeScreen        = preload("res://scenes/main_menu/screens/HomeScreen.gd")
const LobbyScreen       = preload("res://scenes/main_menu/screens/LobbyScreen.gd")
const DeckBuilderScreen = preload("res://scenes/main_menu/screens/DeckBuilderScreen.gd")
const QueueScreen       = preload("res://scenes/main_menu/screens/QueueScreen.gd")
const ShopScreen        = preload("res://scenes/main_menu/screens/ShopScreen.gd")
const CollectionScreen  = preload("res://scenes/main_menu/screens/CollectionScreen.gd")
const ProfileScreen     = preload("res://scenes/main_menu/screens/ProfileScreen.gd")
const SettingsScreen    = preload("res://scenes/main_menu/screens/SettingsScreen.gd")
const RankingScreen     = preload("res://scenes/main_menu/screens/RankingScreen.gd")

# ─── Componentes ─────────────────────────────────────────────
const RoomCard     = preload("res://scenes/main_menu/components/RoomCard.gd")
const MiniCard     = preload("res://scenes/main_menu/components/MiniCard.gd")


enum Screen {
	LOGIN,
	HOME,
	LOBBY,
	DECK_BUILDER,
	QUEUE,
	PROFILE,
	COLLECTION,
	SHOP,
	SETTINGS,
	HISTORY,
	RANKING,
}

# ─── Estado global compartido con todas las pantallas ────────
var current_screen:   Screen = Screen.LOGIN
var player_id:        String = ""
var current_deck:     Array  = []
var deck_name:        String = "Fuego Inicial"
var current_rooms:    Array  = []
var viewing_username: String = ""  # perfil de otro jugador

# ─── Colores (alias de UITheme) ──────────────────────────────
var COLOR_BG:       Color
var COLOR_PANEL:    Color
var COLOR_GOLD:     Color
var COLOR_GOLD_DIM: Color
var COLOR_TEXT:     Color
var COLOR_TEXT_DIM: Color
var COLOR_ACCENT:   Color
var COLOR_ACCENT2:  Color
var COLOR_RED:      Color
var COLOR_GREEN:    Color
var COLOR_PURPLE:   Color

# ─── Nodos ───────────────────────────────────────────────────
var screen_container: Control = null
var _particles:       Array   = []
var _particle_timer:  float   = 0.0

# ─── Pantallas que muestran navbar ───────────────────────────
const NAVBAR_SCREENS = [
	Screen.HOME,
	Screen.LOBBY,
	Screen.DECK_BUILDER,
	Screen.PROFILE,
	Screen.COLLECTION,
	Screen.SHOP,
	Screen.SETTINGS,
	Screen.HISTORY,
	Screen.RANKING,
]

# ============================================================
# INIT
# ============================================================
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
	offset_left = 0; offset_top = 0; offset_right = 0; offset_bottom = 0

	current_deck = []
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

# ============================================================
# NAVEGACIÓN
# ============================================================
func _show_screen(screen: Screen) -> void:
	current_screen = screen
	for child in screen_container.get_children():
		child.queue_free()

	match screen:
		Screen.LOGIN:        LoginScreen.build(screen_container, self)
		Screen.HOME:         HomeScreen.build(screen_container, self)
		Screen.LOBBY:        LobbyScreen.build(screen_container, self)
		Screen.DECK_BUILDER: DeckBuilderScreen.build(screen_container, self)
		Screen.QUEUE:        QueueScreen.build(screen_container, self)
		Screen.PROFILE:      ProfileScreen.build(screen_container, self)
		Screen.COLLECTION:   CollectionScreen.build(screen_container, self)
		Screen.SHOP:         ShopScreen.build(screen_container, self)
		Screen.SETTINGS:     SettingsScreen.build(screen_container, self)
		Screen.RANKING:      RankingScreen.build(screen_container, self)
		Screen.HISTORY:      _build_placeholder("📜 Historial", "Próximamente")

	if current_screen in NAVBAR_SCREENS:
		_build_top_navbar()


# Navegar al perfil de otro jugador (desde ranking u otras pantallas)
func _show_profile(username: String) -> void:
	viewing_username = username
	_show_screen(Screen.PROFILE)


func _build_placeholder(title: String, msg: String) -> void:
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	screen_container.add_child(center)
	var v = VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(v)
	var t = Label.new()
	t.text = title
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_font_size_override("font_size", 28)
	t.add_theme_color_override("font_color", COLOR_GOLD)
	v.add_child(t)
	var s = Label.new()
	s.text = msg
	s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	s.add_theme_font_size_override("font_size", 14)
	s.add_theme_color_override("font_color", COLOR_TEXT_DIM)
	v.add_child(s)

# ============================================================
# NAVBAR SUPERIOR
# ============================================================
func _build_top_navbar() -> void:
	var navbar = PanelContainer.new()
	navbar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	navbar.custom_minimum_size = Vector2(0, 50)
	navbar.z_index = 100
	var ns = StyleBoxFlat.new()
	ns.bg_color = Color(0.05, 0.07, 0.09, 0.95)
	ns.border_color = Color(COLOR_GOLD_DIM.r, COLOR_GOLD_DIM.g, COLOR_GOLD_DIM.b, 0.5)
	ns.border_width_bottom = 2
	navbar.add_theme_stylebox_override("panel", ns)

	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 20)
	navbar.add_child(hbox)

	var tabs = [
		["🏠 HOME",       Screen.HOME],
		["⚔️ MESAS",      Screen.LOBBY],
		["🃏 DECK",        Screen.DECK_BUILDER],
		["📦 COLECCIÓN",   Screen.COLLECTION],
		["🏪 TIENDA",      Screen.SHOP],
		["🏆 RANKING",     Screen.RANKING],
		["👤 PERFIL",      Screen.PROFILE],
		["⚙️ AJUSTES",     Screen.SETTINGS],
	]

	for tab in tabs:
		var b = Button.new()
		b.text = tab[0]
		b.custom_minimum_size = Vector2(110, 50)
		b.add_theme_font_size_override("font_size", 11)
		var is_active = (current_screen == tab[1])
		b.add_theme_color_override("font_color",       COLOR_GOLD if is_active else COLOR_TEXT_DIM)
		b.add_theme_color_override("font_hover_color", COLOR_GOLD.lightened(0.2))
		var bs = StyleBoxFlat.new()
		bs.bg_color            = Color(1,1,1, 0.05) if is_active else Color(0,0,0,0)
		bs.border_color        = COLOR_GOLD if is_active else Color(0,0,0,0)
		bs.border_width_bottom = 3 if is_active else 0
		b.add_theme_stylebox_override("normal",  bs)
		b.add_theme_stylebox_override("hover",   bs)
		b.add_theme_stylebox_override("pressed", bs)
		if not is_active:
			var target = tab[1]
			b.pressed.connect(func(): _show_screen(target))
		else:
			b.mouse_default_cursor_shape = Control.CURSOR_ARROW
		hbox.add_child(b)

	screen_container.add_child(navbar)

# ============================================================
# FONDO Y PARTÍCULAS
# ============================================================
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
		var px     = rng.randf_range(0.0, 1.0)
		var py     = rng.randf_range(0.0, 1.0)
		_make_deco_circle(px, py, radius, rng.randf_range(0, 1))

	screen_container = Control.new()
	screen_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	screen_container.offset_left   = 0; screen_container.offset_top    = 0
	screen_container.offset_right  = 0; screen_container.offset_bottom = 0
	add_child(screen_container)

	var particle_layer = Control.new()
	particle_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	particle_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	particle_layer.name = "ParticleLayer"
	add_child(particle_layer)


func _make_deco_circle(px: float, py: float, radius: float, hue: float) -> void:
	var c = Control.new()
	c.anchor_left  = px; c.anchor_right  = px
	c.anchor_top   = py; c.anchor_bottom = py
	c.offset_left  = -radius; c.offset_right  = radius
	c.offset_top   = -radius; c.offset_bottom = radius
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var panel = Panel.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	var st = StyleBoxFlat.new()
	st.bg_color     = Color.from_hsv(0.60 + hue * 0.1, 0.4, 0.15, 0.06)
	st.border_color = Color.from_hsv(0.55 + hue * 0.1, 0.6, 0.5,  0.07)
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
	var vp  = get_viewport().get_visible_rect().size
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
		"node":  dot,
		"speed": rng.randf_range(30, 80),
		"drift": rng.randf_range(-20, 20),
		"life":  rng.randf_range(4.0, 9.0),
		"age":   0.0,
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
	for p in to_remove:
		_particles.erase(p)

# ============================================================
# RED
# ============================================================
func _connect_network() -> void:
	if not NetworkManager: return

	NetworkManager.connected_to_server.connect(func():
		if current_screen == Screen.LOGIN:
			_show_screen(Screen.LOGIN)
	)
	NetworkManager.disconnected_from_server.connect(func():
		if current_screen == Screen.LOGIN:
			_show_screen(Screen.LOGIN)
	)
	NetworkManager.room_list_updated.connect(func(rooms):
		current_rooms = rooms
		if current_screen == Screen.LOBBY:
			LobbyScreen.update_room_list(screen_container, rooms, self)
	)
	NetworkManager.room_created.connect(func(_room_id):
		_show_screen(Screen.QUEUE)
	)
