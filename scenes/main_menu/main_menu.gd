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
const ChatScreen        = preload("res://scenes/main_menu/screens/ChatScreen.gd")
const ModPanelScreen    = preload("res://scenes/main_menu/screens/ModPanelScreen.gd")
const BattlePassScreen  = preload("res://scenes/main_menu/screens/BattlePassScreen.gd")

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
	CHAT,
	MOD_PANEL,
	BATTLE_PASS,
}

# ─── Estado global compartido con todas las pantallas ────────
var current_screen:   Screen = Screen.LOGIN
var player_id:        String = ""
var current_deck:     Array  = []
var deck_name:        String = "Fuego Inicial"
var current_rooms:    Array  = []
var viewing_username: String = ""

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

# ─── Referencia al ChatScreen activo (para redirigir WS) ─────
var _chat_screen_node: Node = null

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
	Screen.CHAT,
	Screen.MOD_PANEL,
	Screen.BATTLE_PASS,
]

# ============================================================
# INIT
# ============================================================
func _ready() -> void:
	add_to_group("main_menu")
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
	
	# ─── CORRECCIÓN: Evitar volver al login si ya hay sesión activa ───
	if NetworkManager.player_id != "":
		_show_screen(Screen.HOME)
	else:
		_show_screen(Screen.LOGIN)
	# ──────────────────────────────────────────────────────────────────
	
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
	_chat_screen_node = null

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
		Screen.BATTLE_PASS:  BattlePassScreen.build(screen_container, self)
		Screen.CHAT:         ChatScreen.build(screen_container, self)
		Screen.MOD_PANEL:    ModPanelScreen.build(screen_container, self)

	if screen == Screen.CHAT:
		await get_tree().process_frame
		_chat_screen_node = screen_container.get_node_or_null("ChatScreenNode")

	if current_screen in NAVBAR_SCREENS:
		_build_top_navbar()


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
		["🎟️ PASE",      Screen.BATTLE_PASS],
		["🏆 RANKING",     Screen.RANKING],
		["💬 CHAT",        Screen.CHAT],
		["👤 PERFIL",      Screen.PROFILE],
		["⚙️ AJUSTES",     Screen.SETTINGS],
	]

	var role = PlayerData.role if "role" in PlayerData else 1
	if role >= 3:
		tabs.append(["⚙️ MOD", Screen.MOD_PANEL])

	for tab in tabs:
		var b = Button.new()
		b.text = tab[0]
		b.custom_minimum_size = Vector2(100, 50)
		b.add_theme_font_size_override("font_size", 11)
		var is_active = (current_screen == tab[1])

		b.add_theme_color_override("font_color",       COLOR_GOLD if is_active else COLOR_TEXT_DIM)
		b.add_theme_color_override("font_hover_color", COLOR_GOLD.lightened(0.2))

		var bs = StyleBoxFlat.new()
		bs.bg_color            = Color(1, 1, 1, 0.05) if is_active else Color(0, 0, 0, 0)
		bs.border_color        = COLOR_GOLD if is_active else Color(0, 0, 0, 0)
		bs.border_width_bottom = 3 if is_active else 0
		b.add_theme_stylebox_override("normal",  bs)
		b.add_theme_stylebox_override("hover",   bs)
		b.add_theme_stylebox_override("pressed", bs)

		if tab[1] == Screen.MOD_PANEL and role >= 3:
			b.add_theme_color_override("font_color", Color(1.0, 0.65, 0.0) if not is_active else COLOR_GOLD)

		if not is_active:
			var target = tab[1]
			b.pressed.connect(func(): _show_screen(target))
		else:
			b.mouse_default_cursor_shape = Control.CURSOR_ARROW

		hbox.add_child(b)

	screen_container.add_child(navbar)

# ============================================================
# REDIRIGIR MENSAJES WEBSOCKET AL CHAT Y ACTUALIZACIONES
# ============================================================
func handle_ws_message(data: Dictionary) -> void:
	var msg_type = data.get("type", "")

	# ── ACTUALIZACIÓN EN TIEMPO REAL ──────────────────────────
	if msg_type == "PLAYER_DATA_UPDATE":
		var p = data.get("payload", {})

		# 1. Actualizar PlayerData global
		if p.has("coins"):             PlayerData.coins             = p["coins"]
		if p.has("gems"):              PlayerData.gems              = p["gems"]
		if p.has("battle_pass_level"): PlayerData.battle_pass_level = p["battle_pass_level"]
		if p.has("battle_pass_xp"):    PlayerData.battle_pass_xp   = p["battle_pass_xp"]
		if p.has("has_premium_pass"):  PlayerData.has_premium_pass  = (p["has_premium_pass"] == 1 or p["has_premium_pass"] == true)

		# 2. Refrescar label de HomeScreen si está visible
		var home_sub = screen_container.get_node_or_null("HomeSubLabel")
		if home_sub:
			home_sub.text = "Bienvenido, " + PlayerData.username + "  ·  " + str(PlayerData.coins) + " 🪙  ·  ELO " + str(PlayerData.elo)

		# 3. Refrescar CoinsLabel de ShopScreen si está visible
		var shop_root = screen_container.get_node_or_null("ShopRoot")
		if shop_root:
			var coins_lbl = UITheme.find_node(shop_root, "CoinsLabel") as Label
			if coins_lbl:
				coins_lbl.text = "🪙 " + str(PlayerData.coins)

		# 4. Refrescar BattlePass si está abierto
		if current_screen == Screen.BATTLE_PASS:
			var bp_node = screen_container.get_node_or_null("BattlePassScreenNode")
			if bp_node and bp_node.has_method("_update_premium_ui"):
				bp_node._update_premium_ui()

		# 5. Toast con el mensaje del mod/servidor
		var msg = data.get("message", "Tus datos han sido actualizados.")
		_show_global_toast("🔔 " + msg)
		return

	# ── Anuncio global ────────────────────────────────────────
	if msg_type == "CHAT_ANNOUNCEMENT":
		var content = data.get("message", {}).get("content", "")
		if content != "":
			_show_global_toast(content)
		if is_instance_valid(_chat_screen_node) and _chat_screen_node.has_method("handle_ws_message"):
			_chat_screen_node.handle_ws_message(data)
		return

	if msg_type.begins_with("CHAT_") or msg_type == "BANNED":
		if is_instance_valid(_chat_screen_node) and _chat_screen_node.has_method("handle_ws_message"):
			_chat_screen_node.handle_ws_message(data)
		return

	match msg_type:
		"ROOM_LIST_UPDATE":
			current_rooms = data.get("rooms", [])
			if current_screen == Screen.LOBBY:
				LobbyScreen.update_room_list(screen_container, current_rooms, self)
		"ROOM_CREATED":
			_show_screen(Screen.QUEUE)

# ============================================================
# TOAST GLOBAL DE ANUNCIOS — desliza desde la derecha
# ============================================================

func _markdown_to_bbcode(text: String) -> String:
	var result  = ""
	var remaining = text
	var re = RegEx.new()
	re.compile("\\[([^\\]]+)\\]\\(([^)]+)\\)")
	while remaining.length() > 0:
		var m = re.search(remaining)
		if m == null:
			result += remaining
			break
		result += remaining.substr(0, m.get_start())
		var link_text = m.get_string(1)
		var link_url  = m.get_string(2)
		result += "[url=" + link_url + "]" + link_text + "[/url]"
		remaining = remaining.substr(m.get_end())
	return result

func _dismiss_toast(toast_ref: WeakRef) -> void:
	var toast = toast_ref.get_ref()
	if toast == null or not is_instance_valid(toast): return
	var vp_w = get_viewport().get_visible_rect().size.x
	var tween_out = create_tween()
	tween_out.set_parallel(true)
	tween_out.tween_property(toast, "modulate:a", 0.0,         0.35).set_trans(Tween.TRANS_SINE)
	tween_out.tween_property(toast, "position:x", vp_w + 10.0, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	await tween_out.finished
	var t2 = toast_ref.get_ref()
	if t2 != null and is_instance_valid(t2):
		t2.queue_free()

func _show_global_toast(message: String) -> void:
	var old = get_node_or_null("GlobalToast")
	if old and is_instance_valid(old):
		_dismiss_toast(weakref(old))

	var vp   = get_viewport().get_visible_rect().size
	var vp_w = vp.x

	const TOAST_W  : float = 380.0
	const TOAST_H  : float = 72.0
	const MARGIN_R : float = 16.0
	const TOP_Y    : float = 64.0

	var toast = PanelContainer.new()
	toast.name          = "GlobalToast"
	toast.z_index       = 200
	toast.mouse_filter  = Control.MOUSE_FILTER_STOP
	toast.anchor_left   = 0.0
	toast.anchor_right  = 0.0
	toast.anchor_top    = 0.0
	toast.anchor_bottom = 0.0
	toast.size          = Vector2(TOAST_W, TOAST_H)
	toast.position      = Vector2(vp_w + 10.0, TOP_Y)
	toast.modulate.a    = 0.0

	var style = StyleBoxFlat.new()
	style.bg_color               = Color(0.08, 0.06, 0.01, 0.97)
	style.border_color           = COLOR_GOLD
	style.border_width_left      = 4
	style.border_width_right     = 2
	style.border_width_top       = 2
	style.border_width_bottom    = 2
	style.corner_radius_top_left     = 8
	style.corner_radius_top_right    = 8
	style.corner_radius_bottom_left  = 8
	style.corner_radius_bottom_right = 8
	style.shadow_color           = Color(0, 0, 0, 0.6)
	style.shadow_size            = 10
	style.content_margin_left    = 12
	style.content_margin_right   = 8
	style.content_margin_top     = 8
	style.content_margin_bottom  = 8
	toast.add_theme_stylebox_override("panel", style)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	toast.add_child(hbox)

	var icon_lbl = Label.new()
	icon_lbl.text = "🔔"
	icon_lbl.add_theme_font_size_override("font_size", 22)
	icon_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(icon_lbl)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical   = Control.SIZE_SHRINK_CENTER
	hbox.add_child(vbox)

	var title_lbl = Label.new()
	title_lbl.text = "🔔 ANUNCIO"
	title_lbl.add_theme_font_size_override("font_size", 9)
	title_lbl.add_theme_color_override("font_color", COLOR_GOLD_DIM)
	vbox.add_child(title_lbl)

	var msg_lbl = RichTextLabel.new()
	msg_lbl.bbcode_enabled        = true
	msg_lbl.scroll_active         = false
	msg_lbl.fit_content           = true
	msg_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	msg_lbl.add_theme_font_size_override("normal_font_size", 13)
	msg_lbl.add_theme_color_override("default_color",        COLOR_TEXT)
	msg_lbl.add_theme_color_override("font_color",           COLOR_TEXT)
	msg_lbl.add_theme_color_override("font_link_color",      COLOR_GOLD)
	msg_lbl.text = _markdown_to_bbcode(message)
	msg_lbl.meta_clicked.connect(func(meta): OS.shell_open(str(meta)))
	vbox.add_child(msg_lbl)

	var close_btn = Button.new()
	close_btn.text = "✕"
	close_btn.flat = true
	close_btn.add_theme_font_size_override("font_size", 11)
	close_btn.add_theme_color_override("font_color",       COLOR_TEXT_DIM)
	close_btn.add_theme_color_override("font_hover_color", COLOR_GOLD)
	close_btn.custom_minimum_size = Vector2(26, 26)
	var toast_ref2 = weakref(toast)
	close_btn.pressed.connect(func(): _dismiss_toast(toast_ref2))
	hbox.add_child(close_btn)

	add_child(toast)

	var dest_x = vp_w - TOAST_W - MARGIN_R
	var tween_in = create_tween()
	tween_in.set_parallel(true)
	tween_in.tween_property(toast, "modulate:a", 1.0,    0.4).set_trans(Tween.TRANS_SINE)
	tween_in.tween_property(toast, "position:x", dest_x, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	var toast_ref = weakref(toast)
	await get_tree().create_timer(6.5).timeout
	_dismiss_toast(toast_ref)

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
