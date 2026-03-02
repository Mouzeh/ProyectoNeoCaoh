extends Node2D

# ============================================================
# BattleBoard.gd
# Tablero de batalla Pokemon TCG Neo Genesis
# v9: Cartas más grandes + Drag & Drop corregido
# ============================================================

# ─── SEÑALES ────────────────────────────────────────────────
signal action_requested(action_type, params)
signal card_selected(card_node, zone, index)

# ─── TARGET SELECTOR ────────────────────────────────────────
var target_selector: Node = null

# ─── REFERENCIAS A ZONAS ────────────────────────────────────
var my_active_zone:    Control = null
var my_bench_zones:    Array   = []
var my_hand_zone:      Control = null
var my_deck_zone:      Control = null
var my_discard_zone:   Control = null
var my_prizes_zone:    Control = null

var opp_active_zone:   Control = null
var opp_bench_zones:   Array   = []
var opp_hand_zone:     Control = null
var opp_deck_zone:     Control = null
var opp_discard_zone:  Control = null
var opp_prizes_zone:   Control = null

var stadium_zone:      Control = null
var action_panel:      Control = null
var log_panel:         Control = null
var turn_indicator:    Label   = null
var phase_label:       Label   = null

# ─── SETUP UI ────────────────────────────────────────────────
var setup_overlay:     Control = null

# ─── ESTADO LOCAL ───────────────────────────────────────────
var current_state: Dictionary = {}
var my_player_id: String = ""
var selected_hand_index: int = -1
var selected_card_node = null
var my_turn: bool = false
var _processed_logs_count: int = 0

# ─── PROTECTORES ─────────────────────────────────────────────
var my_sleeve_id: String = "default"
var opp_sleeve_id: String = "default"

# ─── TRAINER EN CURSO ────────────────────────────────────────
var _trainer_hand_index: int = -1
var _trainer_card_id: String = ""
var _trainer_targets: Dictionary = {}
var _trainer_awaiting: String = ""

# ─── POPUPS Y ZOOM ───────────────────────────────────────────
var _selection_popup: Control = null
var _zoom_active: bool = false
var _zoom_overlay: Control = null
var _action_zoom_overlay: Control = null

# ─── DRAG EN CURSO ───────────────────────────────────────────
var _active_drag_card = null
var _active_drag_hand_index: int = -1
var _active_drag_card_id: String = ""

# ─── COLORES ────────────────────────────────────────────────
const COLOR_FELT        = Color(0.08, 0.18, 0.12)
const COLOR_FELT_LIGHT  = Color(0.11, 0.24, 0.16)
const COLOR_GOLD        = Color(0.85, 0.72, 0.30)
const COLOR_GOLD_DIM    = Color(0.55, 0.45, 0.18)
const COLOR_MY_ZONE     = Color(0.10, 0.25, 0.40, 0.6)
const COLOR_OPP_ZONE    = Color(0.35, 0.10, 0.10, 0.6)
const COLOR_ACTIVE_GLOW = Color(0.95, 0.85, 0.20, 0.8)
const COLOR_TEXT        = Color(0.92, 0.88, 0.75)

# ─── TAMAÑOS ────────────────────────────────────────────────
const CARD_W    = 130
const CARD_H    = 182
const ZONE_PAD  = 8
const FIELD_W   = 100
const FIELD_H   = 140
const BENCH_GAP = 6

# ─── READY ──────────────────────────────────────────────────
func _ready() -> void:
	_build_board()
	_connect_network()
	_init_target_selector()

# ============================================================
# CONSTRUIR TABLERO VISUAL
# ============================================================
func _build_board() -> void:
	var vp = get_viewport().get_visible_rect().size
	var W = vp.x
	var H = vp.y

	var bg = ColorRect.new()
	bg.color = COLOR_FELT
	bg.size = Vector2(W, H)
	bg.position = Vector2.ZERO
	add_child(bg)

	var divider = ColorRect.new()
	divider.color = COLOR_GOLD_DIM
	divider.size = Vector2(W - 40, 2)
	divider.position = Vector2(20, H / 2.0)
	add_child(divider)

	var my_y_center  = H * 0.73
	var opp_y_center = H * 0.27

	my_prizes_zone = _make_zone(
		Vector2(20, my_y_center - FIELD_H / 2.0),
		Vector2(FIELD_W + 16, FIELD_H + 40), "Premios", COLOR_MY_ZONE, true)
	add_child(my_prizes_zone)

	my_deck_zone = _make_zone(
		Vector2(W - FIELD_W - 36, my_y_center - FIELD_H / 2.0),
		Vector2(FIELD_W + 16, FIELD_H + 40), "Mazo", COLOR_MY_ZONE, true)
	add_child(my_deck_zone)

	my_discard_zone = _make_zone(
		Vector2(W - FIELD_W - 36, my_y_center - FIELD_H / 2.0 - FIELD_H - 20),
		Vector2(FIELD_W + 16, FIELD_H + 40), "Descarte", COLOR_MY_ZONE, true)
	add_child(my_discard_zone)

	my_active_zone = _make_zone(
		Vector2(W / 2.0 - (FIELD_W + 16) / 2.0, my_y_center - FIELD_H / 2.0 - 10),
		Vector2(FIELD_W + 16, FIELD_H + 20), "Activo", COLOR_ACTIVE_GLOW, true)
	add_child(my_active_zone)

	var bench_total_w = 5 * (FIELD_W + BENCH_GAP) - BENCH_GAP
	var bench_start_x = W / 2.0 - bench_total_w / 2.0
	var bench_y = my_y_center + FIELD_H / 2.0 - 10
	for i in range(5):
		var bz = _make_zone(
			Vector2(bench_start_x + i * (FIELD_W + BENCH_GAP), bench_y),
			Vector2(FIELD_W, FIELD_H - 20), "B" + str(i + 1), COLOR_MY_ZONE, false)
		add_child(bz)
		my_bench_zones.append(bz)

	my_hand_zone = Control.new()
	my_hand_zone.name = "MyHand"
	my_hand_zone.position = Vector2(0, H - CARD_H - 28)
	my_hand_zone.size = Vector2(W, CARD_H + 28)
	add_child(my_hand_zone)
	var hand_bg = ColorRect.new()
	hand_bg.color = Color(0.05, 0.10, 0.08, 0.85)
	hand_bg.size = Vector2(W, CARD_H + 28)
	my_hand_zone.add_child(hand_bg)

	opp_hand_zone = Control.new()
	opp_hand_zone.name = "OppHand"
	opp_hand_zone.position = Vector2(0, 0)
	opp_hand_zone.size = Vector2(W, CARD_H + 28)
	add_child(opp_hand_zone)
	var opp_hand_bg = ColorRect.new()
	opp_hand_bg.color = Color(0.10, 0.05, 0.05, 0.85)
	opp_hand_bg.size = Vector2(W, CARD_H + 28)
	opp_hand_zone.add_child(opp_hand_bg)

	opp_prizes_zone = _make_zone(
		Vector2(W - FIELD_W - 36, opp_y_center - FIELD_H / 2.0),
		Vector2(FIELD_W + 16, FIELD_H + 40), "Premios", COLOR_OPP_ZONE, true)
	add_child(opp_prizes_zone)

	opp_deck_zone = _make_zone(
		Vector2(20, opp_y_center - FIELD_H / 2.0),
		Vector2(FIELD_W + 16, FIELD_H + 40), "Mazo", COLOR_OPP_ZONE, true)
	add_child(opp_deck_zone)

	opp_discard_zone = _make_zone(
		Vector2(20, opp_y_center - FIELD_H / 2.0 + FIELD_H + 20),
		Vector2(FIELD_W + 16, FIELD_H + 40), "Descarte", COLOR_OPP_ZONE, true)
	add_child(opp_discard_zone)

	opp_active_zone = _make_zone(
		Vector2(W / 2.0 - (FIELD_W + 16) / 2.0, opp_y_center - FIELD_H / 2.0 - 10),
		Vector2(FIELD_W + 16, FIELD_H + 20), "Activo", COLOR_OPP_ZONE, true)
	add_child(opp_active_zone)

	var opp_bench_y = opp_y_center - FIELD_H / 2.0 - (FIELD_H - 20) - 16
	for i in range(5):
		var bz = _make_zone(
			Vector2(bench_start_x + i * (FIELD_W + BENCH_GAP), opp_bench_y),
			Vector2(FIELD_W, FIELD_H - 20), "B" + str(i + 1), COLOR_OPP_ZONE, false)
		add_child(bz)
		opp_bench_zones.append(bz)

	stadium_zone = _make_zone(
		Vector2(W / 2.0 - 60, H / 2.0 - 40),
		Vector2(120, 80), "Stadium", Color(0.30, 0.25, 0.05, 0.5), true)
	add_child(stadium_zone)

	action_panel = _build_action_panel(W, H)
	add_child(action_panel)

	log_panel = _build_log_panel(W, H)
	add_child(log_panel)

	turn_indicator = Label.new()
	turn_indicator.position = Vector2(W / 2.0 - 120, H / 2.0 - 14)
	turn_indicator.size = Vector2(240, 28)
	turn_indicator.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	turn_indicator.add_theme_font_size_override("font_size", 14)
	turn_indicator.add_theme_color_override("font_color", COLOR_GOLD)
	turn_indicator.text = "Esperando partida..."
	add_child(turn_indicator)

	phase_label = Label.new()
	phase_label.position = Vector2(W / 2.0 - 80, H / 2.0 + 18)
	phase_label.size = Vector2(160, 18)
	phase_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	phase_label.add_theme_font_size_override("font_size", 10)
	phase_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.5))
	add_child(phase_label)

func _make_zone(pos: Vector2, sz: Vector2, label_text: String, color: Color, show_label: bool) -> Control:
	var zone = Control.new()
	zone.position = pos
	zone.size = sz

	var bg = Panel.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = COLOR_GOLD_DIM
	style.border_width_left   = 1
	style.border_width_right  = 1
	style.border_width_top    = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left     = 6
	style.corner_radius_top_right    = 6
	style.corner_radius_bottom_left  = 6
	style.corner_radius_bottom_right = 6
	bg.add_theme_stylebox_override("panel", style)
	zone.add_child(bg)

	if show_label:
		var zone_lbl = Label.new()
		zone_lbl.text = label_text
		zone_lbl.add_theme_font_size_override("font_size", 9)
		zone_lbl.add_theme_color_override("font_color", Color(0.7, 0.65, 0.40))
		zone_lbl.position = Vector2(4, sz.y - 14)
		zone_lbl.size = Vector2(sz.x - 8, 14)
		zone_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		zone.add_child(zone_lbl)

	return zone

func _build_action_panel(W: float, H: float) -> Control:
	var panel = Control.new()
	panel.position = Vector2(W - 170, H / 2.0 - 60)
	panel.size = Vector2(160, 150)

	var bg = Panel.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.08, 0.06, 0.92)
	style.border_color = COLOR_GOLD_DIM
	style.border_width_left   = 1
	style.border_width_right  = 1
	style.border_width_top    = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left     = 8
	style.corner_radius_top_right    = 8
	style.corner_radius_bottom_left  = 8
	style.corner_radius_bottom_right = 8
	bg.add_theme_stylebox_override("panel", style)
	panel.add_child(bg)

	var buttons = [
		["Jugar Básico",  "PLAY_BASIC"],
		["Poner Energía", "ATTACH_ENERGY"],
		["Evolucionar",   "EVOLVE"],
		["Fin de Turno",  "END_TURN"],
	]

	for i in range(buttons.size()):
		var btn = _make_button(buttons[i][0], buttons[i][1])
		btn.position = Vector2(8, 12 + i * 26)
		btn.size = Vector2(144, 22)
		panel.add_child(btn)

	return panel

func _make_button(text: String, action: String) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.name = "Btn_" + action

	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color(0.12, 0.20, 0.14)
	style_normal.border_color = COLOR_GOLD_DIM
	style_normal.border_width_bottom = 1
	style_normal.corner_radius_top_left     = 4
	style_normal.corner_radius_top_right    = 4
	style_normal.corner_radius_bottom_left  = 4
	style_normal.corner_radius_bottom_right = 4
	btn.add_theme_stylebox_override("normal", style_normal)

	var style_hover = StyleBoxFlat.new()
	style_hover.bg_color = Color(0.20, 0.35, 0.22)
	style_hover.border_color = COLOR_GOLD
	style_hover.border_width_bottom = 1
	style_hover.corner_radius_top_left     = 4
	style_hover.corner_radius_top_right    = 4
	style_hover.corner_radius_bottom_left  = 4
	style_hover.corner_radius_bottom_right = 4
	btn.add_theme_stylebox_override("hover", style_hover)

	btn.add_theme_color_override("font_color", COLOR_TEXT)
	btn.add_theme_font_size_override("font_size", 11)
	btn.pressed.connect(func(): _on_action_button(action))
	return btn

func _build_log_panel(_W: float, H: float) -> Control:
	var panel = Control.new()
	panel.name = "BattleLog"
	panel.position = Vector2(10, H / 2.0 - 150)
	panel.size = Vector2(200, 300)

	var bg = Panel.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.05, 0.04, 0.92)
	style.border_color = COLOR_GOLD_DIM
	style.border_width_left   = 1
	style.border_width_right  = 1
	style.border_width_top    = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left     = 8
	style.corner_radius_top_right    = 8
	style.corner_radius_bottom_left  = 8
	style.corner_radius_bottom_right = 8
	bg.add_theme_stylebox_override("panel", style)
	panel.add_child(bg)

	var header = ColorRect.new()
	header.color = Color(0.08, 0.14, 0.10, 1.0)
	header.size = Vector2(200, 22)
	panel.add_child(header)

	var log_title = Label.new()
	log_title.text = "⚔  REGISTRO DE BATALLA"
	log_title.position = Vector2(0, 3)
	log_title.size = Vector2(200, 16)
	log_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	log_title.add_theme_font_size_override("font_size", 9)
	log_title.add_theme_color_override("font_color", COLOR_GOLD)
	panel.add_child(log_title)

	var scroll = ScrollContainer.new()
	scroll.name = "LogScroll"
	scroll.position = Vector2(0, 24)
	scroll.size = Vector2(200, 274)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)

	var vbox = VBoxContainer.new()
	vbox.name = "LogEntries"
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 2)
	scroll.add_child(vbox)

	return panel

# ============================================================
# CARD BACK / PROTECTORES
# ============================================================
func _make_card_back(sleeve_id: String = "default") -> Control:
	var container = Control.new()
	container.custom_minimum_size = Vector2(CARD_W, CARD_H)
	container.size = Vector2(CARD_W, CARD_H)

	var tex_path = "res://assets/sleeves/" + sleeve_id + ".png"
	if ResourceLoader.exists(tex_path):
		var tex_rect = TextureRect.new()
		tex_rect.texture = load(tex_path)
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		tex_rect.size = Vector2(CARD_W, CARD_H)
		container.add_child(tex_rect)
	else:
		var panel = Panel.new()
		panel.size = Vector2(CARD_W, CARD_H)
		var bg_style = StyleBoxFlat.new()
		bg_style.bg_color     = Color(0.10, 0.12, 0.35)
		bg_style.border_color = Color(0.60, 0.50, 0.20)
		bg_style.border_width_left   = 2
		bg_style.border_width_right  = 2
		bg_style.border_width_top    = 2
		bg_style.border_width_bottom = 2
		bg_style.corner_radius_top_left     = 6
		bg_style.corner_radius_top_right    = 6
		bg_style.corner_radius_bottom_left  = 6
		bg_style.corner_radius_bottom_right = 6
		panel.add_theme_stylebox_override("panel", bg_style)
		container.add_child(panel)

		var top_half = ColorRect.new()
		top_half.color = Color(0.80, 0.15, 0.15)
		top_half.size = Vector2(50, 25)
		top_half.position = Vector2((CARD_W - 50) / 2.0, CARD_H / 2.0 - 27)
		container.add_child(top_half)

		var bot_half = ColorRect.new()
		bot_half.color = Color(0.95, 0.95, 0.95)
		bot_half.size = Vector2(50, 25)
		bot_half.position = Vector2((CARD_W - 50) / 2.0, CARD_H / 2.0 - 2)
		container.add_child(bot_half)

		var belt = ColorRect.new()
		belt.color = Color(0.10, 0.10, 0.10)
		belt.size = Vector2(CARD_W - 10, 4)
		belt.position = Vector2(5, CARD_H / 2.0 - 2)
		container.add_child(belt)

		var btn_outer = ColorRect.new()
		btn_outer.color = Color(0.20, 0.20, 0.20)
		btn_outer.size = Vector2(16, 16)
		btn_outer.position = Vector2(CARD_W / 2.0 - 8, CARD_H / 2.0 - 8)
		container.add_child(btn_outer)

		var btn_inner = ColorRect.new()
		btn_inner.color = Color(0.80, 0.80, 0.80)
		btn_inner.size = Vector2(8, 8)
		btn_inner.position = Vector2(CARD_W / 2.0 - 4, CARD_H / 2.0 - 4)
		container.add_child(btn_inner)

	return container

# ============================================================
# CONECTAR CON NETWORKMANAGER
# ============================================================
func _connect_network() -> void:
	if not NetworkManager:
		return
	NetworkManager.game_started.connect(_on_game_started)
	NetworkManager.state_updated.connect(_on_state_updated)
	NetworkManager.game_over.connect(_on_game_over)
	NetworkManager.error_received.connect(_on_error)

	if not NetworkManager.pending_game_state.is_empty():
		print("[Board] Usando pending_game_state")
		_on_game_started(NetworkManager.pending_game_state)

func _on_game_started(state: Dictionary) -> void:
	my_player_id = NetworkManager.player_id
	print("[Board] game_started my_id=", my_player_id)
	var opp_info = state.get("opponent", {})
	if opp_info.has("sleeve_id"):
		opp_sleeve_id = opp_info.get("sleeve_id", "default")

	_processed_logs_count = 0
	_update_board(state)
	_add_log("¡Partida iniciada!")

func _on_state_updated(state: Dictionary, log_arr: Array) -> void:
	_update_board(state)

	if log_arr.size() >= _processed_logs_count:
		for i in range(_processed_logs_count, log_arr.size()):
			_add_log(log_arr[i])
		_processed_logs_count = log_arr.size()
	else:
		for entry in log_arr:
			_add_log(entry)

func _on_game_over(winner: String, you_won: bool) -> void:
	var msg = "¡GANASTE! 🏆" if you_won else "Perdiste..."
	_show_game_over_screen(msg, you_won)

func _on_error(message: String) -> void:
	_add_log("⚠ " + message)

# ============================================================
# ACTUALIZAR TABLERO
# ============================================================
func _update_board(state: Dictionary) -> void:
	current_state = state
	my_turn = state.get("current_player", "") == my_player_id

	var phase = state.get("phase", "")

	if phase == "SETUP_PLACE_ACTIVE":
		_show_setup_overlay(state)
	else:
		_hide_setup_overlay()

	var my_data_pre = state.get("my", {})
	var needs_promote = (phase == "WAITING_PROMOTE" or my_data_pre.get("active") == null) \
					and my_data_pre.get("bench", []).size() > 0 \
					and state.get("current_player", "") == my_player_id
	if needs_promote:
		_show_promote_popup(my_data_pre.get("bench", []))
	else:
		_hide_promote_popup()

	if turn_indicator:
		if phase == "SETUP_PLACE_ACTIVE":
			var setup_ready = state.get("setup_ready", {})
			var yo_listo = setup_ready.get(my_player_id, false)
			turn_indicator.text = "Esperando al rival..." if yo_listo else "Elige tu Pokémon activo y banco"
			turn_indicator.add_theme_color_override("font_color", COLOR_GOLD)
		else:
			turn_indicator.text = "TU TURNO" if my_turn else "TURNO DEL OPONENTE"
			turn_indicator.add_theme_color_override("font_color", COLOR_GOLD if my_turn else Color(0.6, 0.4, 0.4))

	if phase_label:
		phase_label.text = phase

	var my_data  = state.get("my", {})
	var opp_data = state.get("opponent", {})

	_update_zone_pokemon(my_active_zone, my_data.get("active"))
	var my_bench = my_data.get("bench", [])
	for i in range(5):
		_update_zone_pokemon(my_bench_zones[i], my_bench[i] if i < my_bench.size() else null)

	_update_zone_pokemon(opp_active_zone, opp_data.get("active"))
	var opp_bench = opp_data.get("bench", [])
	for i in range(5):
		_update_zone_pokemon(opp_bench_zones[i], opp_bench[i] if i < opp_bench.size() else null)

	_update_hand(my_data.get("hand", []))
	_update_opponent_hand(opp_data.get("hand_count", 0))

	_update_counter_zone(my_deck_zone,    str(my_data.get("deck",   []).size()) + "\nMazo")
	_update_counter_zone(my_prizes_zone,  str(my_data.get("prizes", []).size()) + "\nPremios")
	_update_counter_zone(opp_deck_zone,   str(opp_data.get("deck_count",   0))  + "\nMazo")
	_update_counter_zone(opp_prizes_zone, str(opp_data.get("prizes_count", 0))  + "\nPremios")

	_update_action_buttons()
	_check_glaring_gaze(state)

# ============================================================
# SETUP OVERLAY
# ============================================================
func _show_setup_overlay(state: Dictionary) -> void:
	var setup_ready = state.get("setup_ready", {})
	var yo_listo = setup_ready.get(my_player_id, false)

	if yo_listo:
		if setup_overlay:
			var btn = setup_overlay.get_node_or_null("ConfirmBtn")
			if btn: btn.disabled = true
			var lbl = setup_overlay.get_node_or_null("SetupLabel")
			if lbl: lbl.text = "⏳ Esperando que el rival elija..."
		return

	if setup_overlay: return

	var vp = get_viewport().get_visible_rect().size
	setup_overlay = Control.new()
	setup_overlay.name = "SetupOverlay"
	setup_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	setup_overlay.z_index = 50
	add_child(setup_overlay)

	var panel_w = min(700.0, vp.x - 40)
	var panel_h = 200.0
	var panel = Panel.new()
	panel.name = "SetupPanel"
	panel.position = Vector2((vp.x - panel_w) / 2.0, vp.y - panel_h - 160)
	panel.size = Vector2(panel_w, panel_h)
	var pstyle = StyleBoxFlat.new()
	pstyle.bg_color     = Color(0.05, 0.10, 0.08, 0.95)
	pstyle.border_color = COLOR_GOLD
	pstyle.border_width_left   = 2
	pstyle.border_width_right  = 2
	pstyle.border_width_top    = 2
	pstyle.border_width_bottom = 2
	pstyle.corner_radius_top_left     = 10
	pstyle.corner_radius_top_right    = 10
	pstyle.corner_radius_bottom_left  = 10
	pstyle.corner_radius_bottom_right = 10
	panel.add_theme_stylebox_override("panel", pstyle)
	setup_overlay.add_child(panel)

	var lbl = Label.new()
	lbl.name = "SetupLabel"
	lbl.text = "FASE DE SETUP — Haz clic en una carta básica de tu mano para elegir tu Activo\nLuego puedes agregar más básicos al banco. Confirma cuando estés listo."
	lbl.position = Vector2(12, 10)
	lbl.size = Vector2(panel_w - 24, 50)
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.add_theme_color_override("font_color", COLOR_GOLD)
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(lbl)

	var status_lbl = Label.new()
	status_lbl.name = "StatusLabel"
	status_lbl.text = "Sin activo elegido"
	status_lbl.position = Vector2(12, 64)
	status_lbl.size = Vector2(panel_w - 24, 24)
	status_lbl.add_theme_font_size_override("font_size", 11)
	status_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.5))
	status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(status_lbl)

	var confirm_btn = _make_button("✓ Confirmar selección", "CONFIRM_SETUP")
	confirm_btn.name = "ConfirmBtn"
	confirm_btn.position = Vector2(panel_w / 2.0 - 110, panel_h - 50)
	confirm_btn.size = Vector2(220, 36)
	confirm_btn.disabled = true
	confirm_btn.pressed.connect(_on_confirm_setup)
	panel.add_child(confirm_btn)

	_add_log("SETUP: elige tu Pokémon activo haciendo clic en tu mano")

func _hide_setup_overlay() -> void:
	if setup_overlay:
		setup_overlay.queue_free()
		setup_overlay = null

func _update_setup_status() -> void:
	if not setup_overlay: return
	var my_data = current_state.get("my", {})
	var has_active = my_data.get("active") != null
	var bench_count = my_data.get("bench", []).size()

	var status_lbl = setup_overlay.get_node_or_null("SetupPanel/StatusLabel")
	if status_lbl:
		if has_active:
			status_lbl.text = "✓ Activo elegido | Banco: %d Pokémon | (clic en mano para agregar más al banco)" % bench_count
			status_lbl.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
		else:
			status_lbl.text = "Haz clic en un Pokémon Básico de tu mano para elegir el Activo"
			status_lbl.add_theme_color_override("font_color", Color(0.9, 0.7, 0.3))

	var confirm_btn = setup_overlay.get_node_or_null("SetupPanel/ConfirmBtn")
	if confirm_btn:
		confirm_btn.disabled = not has_active

func _on_confirm_setup() -> void:
	NetworkManager.send_action("CONFIRM_SETUP", {})
	_add_log("Confirmado, esperando al rival...")
	var confirm_btn = setup_overlay.get_node_or_null("SetupPanel/ConfirmBtn") if setup_overlay else null
	if confirm_btn:
		confirm_btn.disabled = true
	var lbl = setup_overlay.get_node_or_null("SetupPanel/SetupLabel") if setup_overlay else null
	if lbl:
		lbl.text = "⏳ Esperando que el rival confirme..."

# ============================================================
# PROMOTE POPUP
# ============================================================
var _promote_popup: Control = null

func _show_promote_popup(bench: Array) -> void:
	if _promote_popup: return

	var vp = get_viewport().get_visible_rect().size
	_promote_popup = Control.new()
	_promote_popup.name = "PromotePopup"
	_promote_popup.set_anchors_preset(Control.PRESET_FULL_RECT)
	_promote_popup.z_index = 150
	add_child(_promote_popup)

	var dim = ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.72)
	_promote_popup.add_child(dim)

	var card_cols  = min(bench.size(), 5)
	var panel_w    = max(300.0, card_cols * (CARD_W + 16) + 40.0)
	var panel_h    = CARD_H + 100.0
	var panel      = Panel.new()
	panel.position = Vector2((vp.x - panel_w) / 2.0, (vp.y - panel_h) / 2.0)
	panel.size     = Vector2(panel_w, panel_h)
	var pstyle = StyleBoxFlat.new()
	pstyle.bg_color     = Color(0.06, 0.12, 0.09, 0.97)
	pstyle.border_color = COLOR_GOLD
	pstyle.border_width_left   = 2
	pstyle.border_width_right  = 2
	pstyle.border_width_top    = 2
	pstyle.border_width_bottom = 2
	pstyle.corner_radius_top_left     = 10
	pstyle.corner_radius_top_right    = 10
	pstyle.corner_radius_bottom_left  = 10
	pstyle.corner_radius_bottom_right = 10
	panel.add_theme_stylebox_override("panel", pstyle)
	_promote_popup.add_child(panel)

	var title = Label.new()
	title.text = "⚠ Tu Pokémon activo fue KO — elige quién pasa al frente"
	title.position = Vector2(10, 10)
	title.size = Vector2(panel_w - 20, 28)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 13)
	title.add_theme_color_override("font_color", COLOR_GOLD)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(title)

	var cards_total_w = card_cols * (CARD_W + 12) - 12
	var cards_start_x = (panel_w - cards_total_w) / 2.0

	for i in range(bench.size()):
		var poke = bench[i]
		if poke == null: continue

		var card_id = poke.get("card_id", "")
		var btn     = Button.new()
		btn.position = Vector2(cards_start_x + i * (CARD_W + 12), 48)
		btn.size     = Vector2(CARD_W, CARD_H + 4)
		btn.flat     = true

		if not card_id.is_empty() and not card_id == "face_down":
			var card_inst = CardDatabase.create_card_instance(card_id)
			card_inst.position = Vector2.ZERO
			card_inst.mouse_filter = Control.MOUSE_FILTER_IGNORE
			btn.add_child(card_inst)
		else:
			var lbl = Label.new()
			lbl.text = card_id
			lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
			lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
			lbl.add_theme_font_size_override("font_size", 10)
			lbl.add_theme_color_override("font_color", COLOR_TEXT)
			btn.add_child(lbl)

		var poke_data = CardDatabase.get_card(card_id)
		var max_hp    = poke_data.get("hp", 0)
		var dmg       = poke.get("damage_counters", 0)
		var cur_hp    = max(0, max_hp - dmg * 10)
		var hp_lbl    = Label.new()
		hp_lbl.text   = "%d/%d HP" % [cur_hp, max_hp]
		hp_lbl.position = Vector2(0, CARD_H + 4)
		hp_lbl.size     = Vector2(CARD_W, 16)
		hp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hp_lbl.add_theme_font_size_override("font_size", 9)
		var hp_color = Color(0.3, 0.9, 0.3) if cur_hp > max_hp * 0.5 else \
					  Color(0.9, 0.7, 0.1) if cur_hp > max_hp * 0.25 else \
					  Color(0.9, 0.2, 0.2)
		hp_lbl.add_theme_color_override("font_color", hp_color)
		btn.add_child(hp_lbl)

		var hover_style = StyleBoxFlat.new()
		hover_style.bg_color = Color(0.25, 0.70, 0.30, 0.30)
		hover_style.border_color = COLOR_GOLD
		hover_style.border_width_left   = 2
		hover_style.border_width_right  = 2
		hover_style.border_width_top    = 2
		hover_style.border_width_bottom = 2
		hover_style.corner_radius_top_left     = 4
		hover_style.corner_radius_top_right    = 4
		hover_style.corner_radius_bottom_left  = 4
		hover_style.corner_radius_bottom_right = 4
		btn.add_theme_stylebox_override("hover", hover_style)
		var normal_style = StyleBoxFlat.new()
		normal_style.bg_color = Color(0, 0, 0, 0)
		btn.add_theme_stylebox_override("normal", normal_style)
		btn.add_theme_stylebox_override("pressed", normal_style)

		var bench_index = i
		btn.pressed.connect(func():
			_on_promote_selected(bench_index)
		)
		panel.add_child(btn)

	_promote_popup.modulate.a = 0.0
	var tw = create_tween()
	tw.tween_property(_promote_popup, "modulate:a", 1.0, 0.18)

func _hide_promote_popup() -> void:
	if _promote_popup:
		_promote_popup.queue_free()
		_promote_popup = null

func _on_promote_selected(bench_index: int) -> void:
	_hide_promote_popup()
	NetworkManager.send_action("PROMOTE", {"benchIndex": bench_index})
	_add_log("Promoviendo Pokémon al frente...")

# ============================================================
# MOSTRAR POKÉMON EN ZONA
# ============================================================
func _update_zone_pokemon(zone: Control, pokemon_data) -> void:
	if not zone: return

	for child in zone.get_children():
		if child.name not in ["Background", "SelectOverlay", "ClickArea", "TrainerClickArea"]:
			child.queue_free()

	if pokemon_data == null: return

	var card_id = pokemon_data.get("card_id", "")
	if card_id == "": return

	if pokemon_data.get("face_down", false) or card_id == "face_down":
		var back = _make_card_back("default")
		back.scale = Vector2((zone.size.x - 8) / float(CARD_W), (zone.size.y - 20) / float(CARD_H))
		back.position = Vector2(4, 4)
		zone.add_child(back)
		return

	var card_data = CardDatabase.get_card(card_id)
	if card_data.is_empty(): return

	var card_instance = CardDatabase.create_card_instance(card_id)
	card_instance.scale = Vector2((zone.size.x - 8) / 130.0, (zone.size.y - 20) / 182.0)
	card_instance.position = Vector2(4, 4)
	card_instance.is_draggable = false
	zone.add_child(card_instance)

	if zone == my_active_zone:
		card_instance.card_clicked.connect(func(_c): _on_active_pokemon_clicked())

	var status = pokemon_data.get("status", "")
	if status != "" and status != null:
		_add_status_token(zone, status)

	if pokemon_data.get("is_poisoned", false):
		_add_status_token(zone, "POISONED")

	if pokemon_data.get("is_burned", false):
		_add_status_token(zone, "BURNED")

	var dmg = pokemon_data.get("damage_counters", 0)
	if dmg > 0:
		_add_damage_tokens(zone, dmg)

	var energies = pokemon_data.get("attached_energy", [])
	if energies.size() > 0:
		_add_energy_indicators(zone, energies)

# ============================================================
# GENERADORES DE TOKENS VISUALES
# ============================================================
func _add_status_token(zone: Control, status: String) -> void:
	var TOKEN_FILES = {
		"POISONED": "poison.png",
		"BURNED": "burn.png",
		"ASLEEP": "asleep.png",
		"PARALYZED": "paralyzed.png",
		"CONFUSED": "confused.png",
	}

	var file_name = TOKEN_FILES.get(status, "")
	if file_name == "": return

	var tex_path = "res://assets/imagen/Tokens/" + file_name
	var existing_tokens = 0
	for child in zone.get_children():
		if child.name.begins_with("StatusToken_"):
			existing_tokens += 1

	if ResourceLoader.exists(tex_path):
		var icon = TextureRect.new()
		icon.name = "StatusToken_" + status
		icon.texture = load(tex_path)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.size = Vector2(24, 24)
		icon.position = Vector2(zone.size.x - 28 - (existing_tokens * 18), 4)
		zone.add_child(icon)
	else:
		var badge = Label.new()
		badge.name = "StatusToken_" + status
		badge.text = {"POISONED":"☠", "BURNED":"🔥", "ASLEEP":"💤", "PARALYZED":"⚡", "CONFUSED":"💫"}.get(status, "?")
		badge.position = Vector2(zone.size.x - 20 - (existing_tokens * 16), 2)
		badge.add_theme_font_size_override("font_size", 14)
		zone.add_child(badge)

func _add_damage_tokens(zone: Control, counters: int) -> void:
	var fifties = counters / 5
	var tens = counters % 5
	var tex_50 = "res://assets/imagen/tokens/damage_50.png"
	var tex_10 = "res://assets/imagen/tokens/damage_10.png"
	var start_x = 8.0
	var start_y = zone.size.y / 2.0 - 12.0
	var offset_x = 0.0
	for i in range(fifties):
		_spawn_token_sprite(zone, tex_50, Vector2(start_x + offset_x, start_y), "50")
		offset_x += 14.0
	for i in range(tens):
		_spawn_token_sprite(zone, tex_10, Vector2(start_x + offset_x, start_y), "10")
		offset_x += 14.0

func _spawn_token_sprite(zone: Control, path: String, pos: Vector2, fallback_text: String) -> void:
	if ResourceLoader.exists(path):
		var icon = TextureRect.new()
		icon.texture = load(path)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.size = Vector2(24, 24)
		icon.position = pos
		zone.add_child(icon)
	else:
		var bg = ColorRect.new()
		bg.color = Color(0.8, 0.1, 0.1, 0.9)
		bg.size = Vector2(20, 20)
		bg.position = pos
		var lbl = Label.new()
		lbl.text = fallback_text
		lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 10)
		bg.add_child(lbl)
		zone.add_child(bg)

func _add_energy_indicators(zone: Control, energies: Array) -> void:
	for i in range(min(energies.size(), 6)):
		var e_type   = CardDatabase.get_energy_type(energies[i])
		var icon_tex = _get_type_icon(e_type)
		if icon_tex:
			var icon_rect = TextureRect.new()
			icon_rect.texture = icon_tex
			icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon_rect.size = Vector2(14, 14)
			icon_rect.position = Vector2(4 + i * 16, zone.size.y - 20)
			zone.add_child(icon_rect)
		else:
			var dot = ColorRect.new()
			dot.size = Vector2(8, 8)
			dot.position = Vector2(4 + i * 10, zone.size.y - 18)
			dot.color = Color(0.5, 0.5, 0.5)
			zone.add_child(dot)

func _update_counter_zone(zone: Control, text: String) -> void:
	if not zone: return
	var count_lbl = zone.get_node_or_null("CountLabel")
	if not count_lbl:
		count_lbl = Label.new()
		count_lbl.name = "CountLabel"
		count_lbl.set_anchors_preset(Control.PRESET_CENTER)
		count_lbl.position = Vector2(8, 10)
		count_lbl.size = Vector2(zone.size.x - 16, 40)
		count_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		count_lbl.add_theme_font_size_override("font_size", 20)
		count_lbl.add_theme_color_override("font_color", COLOR_GOLD)
		zone.add_child(count_lbl)
	count_lbl.text = text

# ============================================================
# ACTUALIZAR MANO
# ============================================================
const HAND_CARD_W    = 130
const HAND_CARD_H    = 182
const HAND_MARGIN    = 220
const HAND_IDEAL_STEP = 44
const HAND_MIN_STEP   = 22

func _calc_hand_step(count: int) -> float:
	if count <= 1: return float(HAND_CARD_W)
	var vp_w  = get_viewport().get_visible_rect().size.x
	var avail = vp_w - HAND_MARGIN * 2.0 - HAND_CARD_W
	var max_step = avail / float(count - 1)
	return clamp(min(HAND_IDEAL_STEP, max_step), HAND_MIN_STEP, HAND_CARD_W)

func _update_hand(hand_cards: Array) -> void:
	if not my_hand_zone: return

	for child in my_hand_zone.get_children():
		if child is ColorRect: continue
		if child.get("is_dragging") == true: continue
		child.queue_free()

	if hand_cards.size() == 0: return

	var count  = hand_cards.size()
	var step   = _calc_hand_step(count)
	var vp_w   = get_viewport().get_visible_rect().size.x
	var total_w = HAND_CARD_W + (count - 1) * step
	var start_x = (vp_w - total_w) / 2.0

	for i in range(count):
		var card_data_item = hand_cards[i]
		var card_id = card_data_item.get("card_id", "")
		if card_id == "": continue

		var card = CardDatabase.create_card_instance(card_id)
		card.scale = Vector2.ONE
		card.is_draggable = true
		var center_offset = abs(i - (count - 1) / 2.0) / max(1.0, (count - 1) / 2.0)
		var arc_y = center_offset * center_offset * 20.0
		card.position = Vector2(start_x + i * step, 6.0 + arc_y)
		card.z_index = i

		var hand_index    = i
		var card_id_local = card_id

		card.card_clicked.connect(func(_c):
			if target_selector:
				target_selector.on_hand_card_clicked(hand_index, card_id_local)
			_on_hand_card_clicked(hand_index)
		)
		card.card_drag_started.connect(func(_c):
			_on_hand_card_drag_started(hand_index, card_id_local, card)
		)
		card.card_dropped.connect(func(_c, drop_pos):
			_on_hand_card_dropped(hand_index, card_id_local, drop_pos, card)
		)

		my_hand_zone.add_child(card)

func _update_opponent_hand(count: int) -> void:
	if not opp_hand_zone: return

	for child in opp_hand_zone.get_children():
		if child is not ColorRect:
			child.queue_free()

	if count == 0: return

	var step    = _calc_hand_step(count)
	var vp_w    = get_viewport().get_visible_rect().size.x
	var total_w = HAND_CARD_W + (count - 1) * step
	var start_x = (vp_w - total_w) / 2.0

	for i in range(count):
		var back = _make_card_back(opp_sleeve_id)
		back.position = Vector2(start_x + i * step, 6)
		back.z_index = i
		opp_hand_zone.add_child(back)

# ============================================================
# DRAG & DROP
# ============================================================
func _on_hand_card_drag_started(hand_index: int, card_id: String, card_node) -> void:
	var phase = current_state.get("phase", "")
	if phase == "SETUP_PLACE_ACTIVE": return
	if not my_turn: return

	_active_drag_card = card_node
	_active_drag_hand_index = hand_index
	_active_drag_card_id = card_id

	_highlight_drop_zones(card_id)
	_show_drag_hint(card_id)

func _on_hand_card_dropped(hand_index: int, card_id: String, drop_pos: Vector2, card_node) -> void:
	_clear_drop_highlights()
	_hide_drag_hint()

	_active_drag_card = null
	_active_drag_hand_index = -1
	_active_drag_card_id = ""

	var phase = current_state.get("phase", "")
	if phase == "SETUP_PLACE_ACTIVE": return

	if not my_turn:
		_add_log("No es tu turno")
		return

	var card_data = CardDatabase.get_card(card_id)
	var card_type = card_data.get("type", "")
	var stage     = card_data.get("stage", 0)
	var target    = _get_zone_at_position(drop_pos)

	var drop_accepted = false

	match card_type:
		"POKEMON":
			if str(stage) == "0" or str(stage) == "baby":
				if not target.is_empty() or true:
					NetworkManager.play_basic(hand_index)
					_add_log("Jugando " + card_data.get("name", card_id) + "...")
					drop_accepted = true
			else:
				if target.is_empty():
					_add_log("Suelta sobre un Pokémon para evolucionar")
				else:
					var evolves_from   = card_data.get("evolves_from", "")
					var zone_name      = target.get("zone", "")
					var zone_idx       = target.get("index", 0)
					var target_pokemon = _get_pokemon_at_zone(zone_name, zone_idx)
					if target_pokemon and _pokemon_name_matches(target_pokemon.get("card_id", ""), evolves_from):
						NetworkManager.evolve(hand_index, zone_name, zone_idx)
						_add_log("Evolucionando a " + card_data.get("name", card_id) + "...")
						drop_accepted = true
					else:
						_add_log("⚠ No puedes evolucionar ahí")

		"ENERGY":
			var my_state = current_state.get("my", {})
			if my_state.get("energy_played_this_turn", false):
				_add_log("⚠ Ya jugaste una energía este turno")
			elif target.is_empty():
				_add_log("Suelta la energía sobre un Pokémon")
			else:
				NetworkManager.attach_energy(hand_index, target.get("zone", "active"), target.get("index", 0))
				_add_log("Adjuntando energía...")
				drop_accepted = true

		"TRAINER":
			_handle_trainer_drop(hand_index, card_id, card_data)
			drop_accepted = true

	if drop_accepted and is_instance_valid(card_node):
		card_node.confirm_drop()

# ============================================================
# TRAINERS Y PODERES
# ============================================================
func _handle_trainer_drop(hand_index: int, card_id: String, card_data: Dictionary) -> void:
	if not my_turn:
		_add_log("No es tu turno")
		return

	var my_state     = current_state.get("my", {})
	var trainer_type = card_data.get("trainer_type", "")

	if trainer_type == "SUPPORTER" and my_state.get("supporter_played_this_turn", false):
		_add_log("⚠ Ya jugaste un Supporter este turno")
		return

	if my_state.get("elm_played_this_turn", false) and trainer_type != "POKEMON_TOOL":
		_add_log("⚠ Professor Elm: no puedes jugar más Trainers")
		return

	_trainer_hand_index = hand_index
	_trainer_card_id    = card_id
	_trainer_targets    = {}

	match card_id:
		"professor_elm", "mary", "energy_charge", "sprout_tower", "ecogym",\
		"new_pokedex", "pokegear", "arcade_game", "card_flip_game",\
		"bills_teleporter":
			_send_trainer()

		"moo_moo_milk", "focus_band", "gold_berry", "berry", "miracle_berry":
			_add_log("Elige el Pokémon objetivo...")
			_trainer_awaiting = "own_pokemon"
			_highlight_own_pokemon_zones()

		"super_scoop_up":
			_add_log("Elige el Pokémon a devolver a la mano...")
			_trainer_awaiting = "own_pokemon"
			_highlight_own_pokemon_zones()

		"time_capsule":
			_add_log("Elige la carta del descarte...")
			_show_discard_selector(false)

		"super_rod":
			_add_log("Elige 1 Pokémon del descarte...")
			_show_discard_selector(false, 1)

		"pokemon_march":
			_add_log("Elige el Pokémon Básico del descarte...")
			_show_discard_selector(true, 1)

		"double_gust":
			_add_log("Double Gust: elige tu Pokémon de banco...")
			_trainer_awaiting = "double_gust_mine"
			_highlight_own_bench_zones()

		"super_energy_retrieval":
			_add_log("Elige 2 cartas de tu mano para descartar...")
			_trainer_awaiting = "hand_discard"
			_trainer_targets["discardIndices"] = []
			_highlight_hand_for_discard()

		_:
			_add_log("⚠ Trainer no implementado: " + card_id)

func on_zone_clicked_for_trainer(zone: String, index: int) -> void:
	match _trainer_awaiting:
		"own_pokemon":
			_trainer_targets["targetZone"]  = zone
			_trainer_targets["targetIndex"] = index
			_clear_trainer_highlights()
			_send_trainer()

		"double_gust_mine":
			_trainer_targets["myBenchIndex"] = index
			_clear_trainer_highlights()
			_add_log("Ahora elige el Pokémon del rival...")
			_trainer_awaiting = "double_gust_opp"
			_highlight_opp_bench_zones()

		"double_gust_opp":
			_trainer_targets["opponentBenchIndex"] = index
			_clear_trainer_highlights()
			_send_trainer()

		"fire_recharge_target":
			_handle_fire_recharge_target(zone, index)

		"hand_discard":
			var indices: Array = _trainer_targets.get("discardIndices", [])
			if not indices.has(index) and index != _trainer_hand_index:
				indices.append(index)
				_trainer_targets["discardIndices"] = indices
				_add_log("Seleccionada carta " + str(indices.size()) + "/2")
				if indices.size() >= 2:
					_clear_trainer_highlights()
					_send_trainer()

func on_discard_selection_confirmed(selected_ids: Array) -> void:
	if _trainer_card_id in ["super_rod", "pokemon_march"]:
		_trainer_targets["selectedCardId"] = selected_ids[0] if selected_ids.size() > 0 else ""
	else:
		_trainer_targets["selectedCardIds"] = selected_ids

	_close_discard_selector()
	_send_trainer()

func on_discard_selection_cancelled() -> void:
	_close_discard_selector()
	_cancel_trainer()

func _highlight_own_pokemon_zones() -> void:
	var COLOR_SELECT = Color(0.20, 0.80, 0.95, 0.50)
	var my_data = current_state.get("my", {})
	if my_data.get("active"):
		_set_zone_glow(my_active_zone, COLOR_SELECT)
		_make_zone_clickable(my_active_zone, "active", 0)
	var bench = my_data.get("bench", [])
	for i in range(bench.size()):
		if bench[i] != null:
			_set_zone_glow(my_bench_zones[i], COLOR_SELECT)
			_make_zone_clickable(my_bench_zones[i], "bench", i)

func _highlight_own_bench_zones() -> void:
	var COLOR_SELECT = Color(0.20, 0.80, 0.95, 0.50)
	var bench = current_state.get("my", {}).get("bench", [])
	for i in range(bench.size()):
		if bench[i] != null:
			_set_zone_glow(my_bench_zones[i], COLOR_SELECT)
			_make_zone_clickable(my_bench_zones[i], "bench", i)

func _highlight_opp_bench_zones() -> void:
	var COLOR_SELECT = Color(0.95, 0.50, 0.20, 0.50)
	var bench = current_state.get("opponent", {}).get("bench", [])
	for i in range(bench.size()):
		if bench[i] != null:
			_set_zone_glow(opp_bench_zones[i], COLOR_SELECT)
			_make_zone_clickable(opp_bench_zones[i], "bench", i, true)

func _highlight_hand_for_discard() -> void:
	_add_log("Haz click en 2 cartas de tu mano para descartar (Esc = cancelar)")

func _make_zone_clickable(zone: Control, zone_name: String, zone_index: int, _is_opponent: bool = false) -> void:
	var btn = Button.new()
	btn.name = "TrainerClickArea"
	btn.set_anchors_preset(Control.PRESET_FULL_RECT)
	btn.flat = true
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover",  style)
	btn.add_theme_stylebox_override("pressed", style)
	btn.z_index = 10
	var zn = zone_name
	var zi = zone_index
	btn.pressed.connect(func(): on_zone_clicked_for_trainer(zn, zi))
	zone.add_child(btn)

func _clear_trainer_highlights() -> void:
	_trainer_awaiting = ""
	var all_zones = [my_active_zone, opp_active_zone] + my_bench_zones + opp_bench_zones
	for zone in all_zones:
		if not zone: continue
		_set_zone_glow(zone, Color(0, 0, 0, 0))
		var btn = zone.get_node_or_null("TrainerClickArea")
		if btn: btn.queue_free()

func _cancel_trainer() -> void:
	_clear_trainer_highlights()
	_trainer_hand_index = -1
	_trainer_card_id    = ""
	_trainer_targets    = {}
	_trainer_awaiting   = ""
	_add_log("Trainer cancelado")

func _show_discard_selector(only_basic_pokemon: bool, max_count: int = 1) -> void:
	var my_discard = current_state.get("my", {}).get("discard", [])
	var candidates: Array = []

	for c in my_discard:
		var cid   = c.get("card_id", "")
		var cdata = CardDatabase.get_card(cid)
		if cdata.is_empty(): continue
		if only_basic_pokemon:
			if cdata.get("type") == "POKEMON" and str(cdata.get("stage", "")) in ["0", "baby"]:
				candidates.append(cid)
		else:
			if cdata.get("type") == "POKEMON" or (cdata.get("type") == "ENERGY" and _is_basic_energy(cid)):
				candidates.append(cid)

	if candidates.is_empty():
		_add_log("⚠ No hay cartas válidas en el descarte")
		_cancel_trainer()
		return

	var vp    = get_viewport().get_visible_rect().size
	var popup = Control.new()
	popup.name = "DiscardSelector"
	popup.set_anchors_preset(Control.PRESET_FULL_RECT)
	popup.z_index = 100

	var dim = ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.65)
	popup.add_child(dim)

	var panel_w = min(600.0, vp.x - 80)
	var panel_h = 300.0
	var panel   = Panel.new()
	panel.position = Vector2((vp.x - panel_w) / 2.0, (vp.y - panel_h) / 2.0)
	panel.size     = Vector2(panel_w, panel_h)
	var pstyle = StyleBoxFlat.new()
	pstyle.bg_color     = Color(0.08, 0.14, 0.10)
	pstyle.border_color = COLOR_GOLD
	pstyle.border_width_left   = 2
	pstyle.border_width_right  = 2
	pstyle.border_width_top    = 2
	pstyle.border_width_bottom = 2
	pstyle.corner_radius_top_left     = 10
	pstyle.corner_radius_top_right    = 10
	pstyle.corner_radius_bottom_left  = 10
	pstyle.corner_radius_bottom_right = 10
	panel.add_theme_stylebox_override("panel", pstyle)
	popup.add_child(panel)

	var popup_title = Label.new()
	popup_title.text = "Elige " + ("1 carta" if max_count == 1 else "hasta " + str(max_count) + " cartas") + " del descarte"
	popup_title.position = Vector2(10, 8)
	popup_title.size = Vector2(panel_w - 20, 24)
	popup_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	popup_title.add_theme_font_size_override("font_size", 13)
	popup_title.add_theme_color_override("font_color", COLOR_GOLD)
	panel.add_child(popup_title)

	var selected_ids: Array = []
	var card_size     = Vector2(70, 98)
	var card_gap      = 10
	var cards_per_row = int((panel_w - 20) / (card_size.x + card_gap))
	var row = 0
	var col = 0

	for cid in candidates:
		var card_btn = Button.new()
		card_btn.position = Vector2(10 + col * (card_size.x + card_gap), 40 + row * (card_size.y + card_gap + 4))
		card_btn.size = card_size
		card_btn.flat = true

		var cdata    = CardDatabase.get_card(cid)
		var card_lbl = Label.new()
		card_lbl.text = cdata.get("name", cid)
		card_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
		card_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		card_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		card_lbl.add_theme_font_size_override("font_size", 9)
		card_lbl.add_theme_color_override("font_color", COLOR_TEXT)
		card_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		card_btn.add_child(card_lbl)

		var btn_style = StyleBoxFlat.new()
		btn_style.bg_color     = Color(0.15, 0.22, 0.16)
		btn_style.border_color = COLOR_GOLD_DIM
		btn_style.border_width_left   = 1
		btn_style.border_width_right  = 1
		btn_style.border_width_top    = 1
		btn_style.border_width_bottom = 1
		btn_style.corner_radius_top_left     = 4
		btn_style.corner_radius_top_right    = 4
		btn_style.corner_radius_bottom_left  = 4
		btn_style.corner_radius_bottom_right = 4
		card_btn.add_theme_stylebox_override("normal", btn_style)

		var cid_local = cid
		card_btn.pressed.connect(func():
			if selected_ids.has(cid_local):
				selected_ids.erase(cid_local)
				card_btn.modulate = Color.WHITE
			elif selected_ids.size() < max_count:
				selected_ids.append(cid_local)
				card_btn.modulate = Color(0.4, 1.0, 0.5)
			if max_count == 1 and selected_ids.size() == 1:
				on_discard_selection_confirmed(selected_ids)
		)

		panel.add_child(card_btn)
		col += 1
		if col >= cards_per_row:
			col = 0
			row += 1

	if max_count > 1:
		var confirm_btn = _make_button("Confirmar", "CONFIRM_DISCARD")
		confirm_btn.position = Vector2(panel_w / 2.0 - 80, panel_h - 40)
		confirm_btn.size = Vector2(80, 28)
		confirm_btn.pressed.connect(func():
			if selected_ids.size() > 0:
				on_discard_selection_confirmed(selected_ids)
			else:
				_add_log("Selecciona al menos 1 carta")
		)
		panel.add_child(confirm_btn)

	var cancel_btn = _make_button("Cancelar", "CANCEL_DISCARD")
	cancel_btn.position = Vector2(panel_w / 2.0 + 10, panel_h - 40)
	cancel_btn.size = Vector2(80, 28)
	cancel_btn.pressed.connect(func(): on_discard_selection_cancelled())
	panel.add_child(cancel_btn)

	_selection_popup = popup
	add_child(popup)

func _close_discard_selector() -> void:
	if _selection_popup:
		_selection_popup.queue_free()
		_selection_popup = null

func _send_trainer() -> void:
	if _trainer_hand_index < 0: return

	NetworkManager.send_action("PLAY_TRAINER", {
		"handIndex": _trainer_hand_index,
		"targets":   _trainer_targets,
	})

	var trainer_name = CardDatabase.get_card(_trainer_card_id).get("name", _trainer_card_id)
	_add_log("Jugando " + trainer_name + "...")

	_trainer_hand_index = -1
	_trainer_card_id    = ""
	_trainer_targets    = {}
	_trainer_awaiting   = ""

# ============================================================
# HIGHLIGHT / DROP ZONES
# ============================================================
func _highlight_drop_zones(card_id: String) -> void:
	var card_data   = CardDatabase.get_card(card_id)
	var card_type   = card_data.get("type", "")
	var stage       = card_data.get("stage", 0)
	var COLOR_VALID = Color(0.20, 0.90, 0.35, 0.50)

	match card_type:
		"POKEMON":
			if str(stage) == "0" or str(stage) == "baby":
				var active = current_state.get("my", {}).get("active")
				if not active:
					_set_zone_glow(my_active_zone, COLOR_VALID)
				var bench = current_state.get("my", {}).get("bench", [])
				for i in range(5):
					if i >= bench.size() or bench[i] == null:
						_set_zone_glow(my_bench_zones[i], COLOR_VALID)
			else:
				var evolves_from = card_data.get("evolves_from", "")
				var active = current_state.get("my", {}).get("active")
				if active and _pokemon_name_matches(active.get("card_id", ""), evolves_from):
					_set_zone_glow(my_active_zone, COLOR_VALID)
				var bench = current_state.get("my", {}).get("bench", [])
				for i in range(bench.size()):
					if bench[i] and _pokemon_name_matches(bench[i].get("card_id", ""), evolves_from):
						_set_zone_glow(my_bench_zones[i], COLOR_VALID)
		"ENERGY":
			if not current_state.get("my", {}).get("energy_played_this_turn", false):
				if current_state.get("my", {}).get("active"):
					_set_zone_glow(my_active_zone, COLOR_VALID)
				var bench = current_state.get("my", {}).get("bench", [])
				for i in range(bench.size()):
					if bench[i] != null:
						_set_zone_glow(my_bench_zones[i], COLOR_VALID)
		"TRAINER":
			pass

func _set_zone_glow(zone: Control, color: Color) -> void:
	if not zone: return
	var overlay = zone.get_node_or_null("DropOverlay")
	if not overlay:
		overlay = ColorRect.new()
		overlay.name = "DropOverlay"
		overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
		overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		overlay.z_index = 5
		zone.add_child(overlay)
	overlay.color = color

func _clear_drop_highlights() -> void:
	for zone in [my_active_zone] + my_bench_zones:
		_set_zone_glow(zone, Color(0, 0, 0, 0))

func _get_zone_at_position(drop_pos: Vector2) -> Dictionary:
	if my_active_zone and _pos_in_zone(drop_pos, my_active_zone):
		return {"zone": "active", "index": 0}
	for i in range(my_bench_zones.size()):
		if _pos_in_zone(drop_pos, my_bench_zones[i]):
			return {"zone": "bench", "index": i}
	return {}

func _pos_in_zone(pos: Vector2, zone: Control) -> bool:
	if not zone: return false
	return Rect2(zone.global_position, zone.size).has_point(pos)

func _get_pokemon_at_zone(zone_name: String, zone_idx: int):
	var my_data = current_state.get("my", {})
	if zone_name == "active":
		return my_data.get("active")
	var bench = my_data.get("bench", [])
	if zone_idx < bench.size():
		return bench[zone_idx]
	return null

func _show_drag_hint(card_id: String) -> void:
	var card_data = CardDatabase.get_card(card_id)
	var hints = {
		"POKEMON": "Suelta en una zona del campo",
		"ENERGY":  "Suelta sobre un Pokémon",
		"TRAINER": "Suelta para jugar el Trainer",
	}
	var hint = hints.get(card_data.get("type", ""), "Arrastra al campo")
	if not drag_hint_label:
		drag_hint_label = Label.new()
		drag_hint_label.add_theme_font_size_override("font_size", 13)
		drag_hint_label.add_theme_color_override("font_color", Color(0.95, 0.90, 0.50))
		drag_hint_label.position = Vector2(
			get_viewport().get_visible_rect().size.x / 2.0 - 150,
			get_viewport().get_visible_rect().size.y / 2.0 + 10
		)
		drag_hint_label.size = Vector2(300, 24)
		drag_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		add_child(drag_hint_label)
	drag_hint_label.text = hint
	drag_hint_label.visible = true

func _hide_drag_hint() -> void:
	if drag_hint_label:
		drag_hint_label.visible = false

var drag_hint_label: Label = null

func _pokemon_name_matches(card_id: String, species_name: String) -> bool:
	var data = CardDatabase.get_card(card_id)
	if data.is_empty(): return false
	return data.get("name", "").to_lower() == species_name.to_lower() or card_id.begins_with(species_name.to_lower())

func _is_basic_energy(card_id: String) -> bool:
	return card_id in ["fire_energy", "water_energy", "grass_energy",
		"lightning_energy", "psychic_energy", "fighting_energy"]

func _update_action_buttons() -> void:
	if not action_panel: return
	var phase = current_state.get("phase", "")
	var in_setup = phase == "SETUP_PLACE_ACTIVE"

	for child in action_panel.get_children():
		if not child is Button: continue
		child.disabled = not my_turn or in_setup

# ============================================================
# ACCIONES DEL JUGADOR
# ============================================================
func _on_hand_card_clicked(hand_index: int) -> void:
	var phase = current_state.get("phase", "")

	if phase == "SETUP_PLACE_ACTIVE":
		var my_data = current_state.get("my", {})
		if not my_data.get("active"):
			# ✅ REVERTIDO: Usamos el nombre original que tu servidor sí reconoce
			NetworkManager.send_action("PLACE_ACTIVE_SETUP", {"handIndex": hand_index})
			_add_log("Activo elegido (boca abajo)")
		else:
			# ✅ REVERTIDO: Usamos el nombre original
			NetworkManager.send_action("SETUP_PLACE_BENCH", {"handIndex": hand_index})
			_add_log("Pokémon agregado al banco")
		_update_setup_status()
		return

	if _trainer_awaiting == "hand_discard":
		on_zone_clicked_for_trainer("hand", hand_index)
		return

	selected_hand_index = hand_index
	_add_log("Carta seleccionada: posición " + str(hand_index))
	_highlight_hand_card(hand_index)
	
func _on_active_pokemon_clicked() -> void:
	if _trainer_awaiting == "own_pokemon":
		on_zone_clicked_for_trainer("active", 0)
		return
	var active = current_state.get("my", {}).get("active")
	if not active: return

	var phase = current_state.get("phase", "")
	if my_turn and phase in ["MAIN", "ATTACK"]:
		_show_action_zoom(active)
	else:
		_open_zoom(active.get("card_id", ""))

# ─── ACTION ZOOM ─────────────────────────────────────────────
var _action_zoom_card_instance = null

func _show_action_zoom(pokemon_data: Dictionary) -> void:
	if _action_zoom_overlay:
		_close_action_zoom()
		return

	var card_id = pokemon_data.get("card_id", "")
	if card_id == "": return

	var cdata = CardDatabase.get_card(card_id)
	if cdata.is_empty(): return

	var vp = get_viewport().get_visible_rect().size

	_action_zoom_overlay = Control.new()
	_action_zoom_overlay.name = "ActionZoomOverlay"
	_action_zoom_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_action_zoom_overlay.z_index = 250
	add_child(_action_zoom_overlay)

	var dim = ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.88)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_action_zoom_overlay.add_child(dim)

	var log_panel_w = 215.0
	var card_area_w = vp.x * 0.40
	var card_area_h = vp.y * 0.88
	var zoom_scale  = clamp(min(card_area_w / 130.0, card_area_h / 182.0), 1.5, 4.5)

	var card_w = 130.0 * zoom_scale
	var card_h = 182.0 * zoom_scale
	var card_pos_x = log_panel_w + 10.0
	var card_pos_y = round((vp.y - card_h) / 2.0)

	var card_instance = CardDatabase.create_card_instance(card_id)
	card_instance.scale        = Vector2(zoom_scale, zoom_scale)
	card_instance.is_draggable = false
	card_instance.position     = Vector2(round(card_pos_x), card_pos_y)
	card_instance.is_locked    = true
	card_instance.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if pokemon_data.get("damage_counters", 0) > 0:
		card_instance.damage_counters = pokemon_data.get("damage_counters", 0)

	_action_zoom_card_instance = card_instance
	_action_zoom_overlay.add_child(card_instance)

	var btn_x = card_pos_x + card_w + 24.0
	var btn_w = vp.x - btn_x - 20.0
	var btn_y = card_pos_y + card_h * 0.28
	var btn_h = card_h * 0.68

	var panel_bg = Panel.new()
	panel_bg.position = Vector2(btn_x - 10, btn_y - 10)
	panel_bg.size     = Vector2(btn_w + 20, btn_h + 20)
	var pbg_style = StyleBoxFlat.new()
	pbg_style.bg_color     = Color(0.04, 0.07, 0.05, 0.92)
	pbg_style.border_color = COLOR_GOLD_DIM
	pbg_style.border_width_left   = 1
	pbg_style.border_width_right  = 1
	pbg_style.border_width_top    = 1
	pbg_style.border_width_bottom = 1
	pbg_style.corner_radius_top_left     = 10
	pbg_style.corner_radius_top_right    = 10
	pbg_style.corner_radius_bottom_left  = 10
	pbg_style.corner_radius_bottom_right = 10
	panel_bg.add_theme_stylebox_override("panel", pbg_style)
	_action_zoom_overlay.add_child(panel_bg)

	var close_btn = Button.new()
	close_btn.text = "✕"
	close_btn.position = Vector2(btn_x + btn_w - 36, btn_y - 10)
	close_btn.size     = Vector2(36, 36)
	close_btn.flat     = false
	var close_normal = StyleBoxFlat.new()
	close_normal.bg_color     = Color(0.35, 0.08, 0.08, 0.90)
	close_normal.border_color = Color(0.75, 0.20, 0.20)
	close_normal.border_width_left   = 1
	close_normal.border_width_right  = 1
	close_normal.border_width_top    = 1
	close_normal.border_width_bottom = 1
	close_normal.corner_radius_top_left     = 6
	close_normal.corner_radius_top_right    = 6
	close_normal.corner_radius_bottom_left  = 6
	close_normal.corner_radius_bottom_right = 6
	close_btn.add_theme_stylebox_override("normal", close_normal)
	var close_hover = close_normal.duplicate()
	close_hover.bg_color = Color(0.65, 0.12, 0.12, 0.95)
	close_btn.add_theme_stylebox_override("hover", close_hover)
	close_btn.add_theme_font_size_override("font_size", 16)
	close_btn.add_theme_color_override("font_color", Color(1, 0.6, 0.6))
	close_btn.pressed.connect(_close_action_zoom)
	_action_zoom_overlay.add_child(close_btn)

	var vbox = VBoxContainer.new()
	vbox.position = Vector2(btn_x, btn_y)
	vbox.size     = Vector2(btn_w, btn_h)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 10)
	_action_zoom_overlay.add_child(vbox)

	var title_lbl = Label.new()
	title_lbl.text = "— ACCIONES —"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 13)
	title_lbl.add_theme_color_override("font_color", COLOR_GOLD)
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(title_lbl)

	var sep1 = HSeparator.new()
	sep1.add_theme_color_override("color", COLOR_GOLD_DIM)
	sep1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(sep1)

	var power = cdata.get("pokemon_power", null)
	if power != null:
		vbox.add_child(_create_styled_action_btn("⚡ " + power.get("name", "Poder"), "POWER", 0))

	var attacks = cdata.get("attacks", [])
	for i in range(attacks.size()):
		var atk      = attacks[i]
		var atk_name = atk.get("name", "Ataque")
		var atk_dmg  = atk.get("damage", 0)
		var label    = "⚔ " + atk_name
		if atk_dmg > 0:
			label += "  (" + str(atk_dmg) + ")"
		vbox.add_child(_create_styled_action_btn(label, "ATTACK", i))

	var sep2 = HSeparator.new()
	sep2.add_theme_color_override("color", COLOR_GOLD_DIM)
	sep2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(sep2)

	vbox.add_child(_create_styled_action_btn("🏃 Retirar", "RETREAT", 0))

	var hint = Label.new()
	hint.text = "Esc para cancelar"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.position = Vector2(0, vp.y - 32)
	hint.size     = Vector2(vp.x, 24)
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", Color(0.65, 0.62, 0.45))
	_action_zoom_overlay.add_child(hint)

	_action_zoom_overlay.modulate.a = 0.0
	var tw = create_tween()
	tw.tween_property(_action_zoom_overlay, "modulate:a", 1.0, 0.14)

func _create_styled_action_btn(text: String, type: String, index: int) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = Color(0.05, 0.08, 0.12, 0.80)
	normal_style.border_color = COLOR_GOLD_DIM
	normal_style.border_width_left = 2
	normal_style.border_width_right = 2
	normal_style.border_width_top = 2
	normal_style.border_width_bottom = 2
	normal_style.corner_radius_top_left = 6
	normal_style.corner_radius_top_right = 6
	normal_style.corner_radius_bottom_left = 6
	normal_style.corner_radius_bottom_right = 6
	btn.add_theme_stylebox_override("normal", normal_style)

	var hover_style = normal_style.duplicate()
	hover_style.bg_color = Color(0.2, 0.35, 0.25, 0.95)
	hover_style.border_color = COLOR_GOLD
	btn.add_theme_stylebox_override("hover", hover_style)
	btn.add_theme_stylebox_override("pressed", hover_style)

	btn.add_theme_font_size_override("font_size", 16)
	btn.add_theme_color_override("font_color", COLOR_TEXT)

	btn.pressed.connect(func():
		_close_action_zoom()
		if type == "ATTACK":
			NetworkManager.send_action("ATTACK", {"attackIndex": index})
		elif type == "POWER":
			_on_use_power_button()
		elif type == "RETREAT":
			if target_selector:
				target_selector.begin_retreat()
	)
	return btn

func _close_action_zoom() -> void:
	if _action_zoom_overlay:
		_action_zoom_overlay.queue_free()
		_action_zoom_overlay = null

func _set_mouse_filter_recursive(node: Node, filter: int) -> void:
	if node is Control:
		node.mouse_filter = filter
	for child in node.get_children():
		_set_mouse_filter_recursive(child, filter)

func _init_target_selector() -> void:
	target_selector = load("res://scripts/TargetSelector.gd").new()
	target_selector.board = self
	add_child(target_selector)
	target_selector.target_selected.connect(_on_target_selected)
	target_selector.selection_cancelled.connect(_on_selection_cancelled)
	target_selector.state_changed.connect(_on_selector_state_changed)

func _on_target_selected(action, hand_index: int, zone: String, zone_index: int) -> void:
	match action:
		target_selector.Action.PLAY_BASIC:    NetworkManager.play_basic(hand_index)
		target_selector.Action.ATTACH_ENERGY: NetworkManager.attach_energy(hand_index, zone, zone_index)
		target_selector.Action.EVOLVE:        NetworkManager.evolve(hand_index, zone, zone_index)
		target_selector.Action.RETREAT:       NetworkManager.retreat(zone_index)
		target_selector.Action.ATTACK:        NetworkManager.attack(zone_index)
	_add_log(_action_to_string(action) + " enviado")

func _on_selection_cancelled() -> void:
	_add_log("Acción cancelada (Esc)")
	_update_action_buttons()

func _on_selector_state_changed(new_state) -> void:
	match new_state:
		1: _add_log("Elige una carta de tu mano (Esc = cancelar)")
		2: _add_log("Elige el Pokémon objetivo (Esc = cancelar)")

func _action_to_string(action) -> String:
	match action:
		target_selector.Action.PLAY_BASIC:    return "Jugar básico"
		target_selector.Action.ATTACH_ENERGY: return "Energía"
		target_selector.Action.EVOLVE:        return "Evolución"
		target_selector.Action.RETREAT:       return "Retirada"
		target_selector.Action.ATTACK:        return "Ataque"
	return "Acción"

func _on_action_button(action: String) -> void:
	var phase = current_state.get("phase", "")
	if phase == "SETUP_PLACE_ACTIVE":
		if action == "CONFIRM_SETUP":
			_on_confirm_setup()
		return

	if not my_turn:
		_add_log("No es tu turno")
		return
	if not target_selector: return

	if not target_selector.is_idle():
		target_selector.cancel()
		return

	match action:
		"PLAY_BASIC":    target_selector.begin_play_basic()
		"ATTACH_ENERGY": target_selector.begin_attach_energy()
		"EVOLVE":        target_selector.begin_evolve()
		"RETREAT":       target_selector.begin_retreat()
		"END_TURN":
			if target_selector.is_idle():
				NetworkManager.end_turn()
				_add_log("Fin de turno")

func _on_use_power_button() -> void:
	var active = current_state.get("my", {}).get("active")
	if not active: return
	var power = active.get("pokemon_power", {})
	var power_name = power.get("name", "")

	match power_name:
		"Fire Recharge":
			_add_log("Fire Recharge: elige el Pokémon destino (clic en zona)...")
			_trainer_awaiting = "fire_recharge_target"
			_highlight_own_pokemon_zones()
		"Glaring Gaze":
			_add_log("Usando Glaring Gaze...")
			NetworkManager.send_action("USE_POWER", {"sourceZone": "active"})
		"Final Blow":
			_add_log("Final Blow activado — Megahorn hará 120 de daño")
			NetworkManager.send_action("USE_POWER", {"sourceZone": "active"})
		_:
			NetworkManager.send_action("USE_POWER", {"sourceZone": "active"})

func _handle_fire_recharge_target(zone: String, zone_index: int) -> void:
	_trainer_awaiting = ""
	_clear_trainer_highlights()
	NetworkManager.send_action("USE_POWER", {
		"sourceZone":  "active",
		"targetZone":  zone,
		"targetIndex": zone_index,
	})
	_add_log("Fire Recharge enviado")

func _highlight_hand_card(index: int) -> void:
	var idx = 0
	for child in my_hand_zone.get_children():
		if child is not ColorRect:
			if child.has_method("set_highlighted"):
				child.set_highlighted(idx == index)
			idx += 1

# ============================================================
# INPUT Y ZOOM GENERAL
# ============================================================
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_ESCAPE:
				if _action_zoom_overlay:
					_close_action_zoom()
					get_viewport().set_input_as_handled()
					return
				if _zoom_active:
					_close_zoom()
					get_viewport().set_input_as_handled()
					return
				if _trainer_awaiting != "":
					_cancel_trainer()
					get_viewport().set_input_as_handled()
					return
				if _selection_popup:
					on_discard_selection_cancelled()
					get_viewport().set_input_as_handled()
					return

			KEY_SPACE:
				get_viewport().set_input_as_handled()
				if _zoom_active:
					_close_zoom()
					return
				if _action_zoom_overlay:
					_close_action_zoom()
					return
				if selected_hand_index >= 0:
					_toggle_zoom_selected_card()
					return

func _toggle_zoom_selected_card() -> void:
	var my_data = current_state.get("my", {})
	var hand = my_data.get("hand", [])
	if selected_hand_index < 0 or selected_hand_index >= hand.size():
		return
	var card_id = hand[selected_hand_index].get("card_id", "")
	if card_id == "": return
	_open_zoom(card_id)

func _open_zoom(card_id: String) -> void:
	if _zoom_overlay: return

	var vp = get_viewport().get_visible_rect().size

	_zoom_overlay = Control.new()
	_zoom_overlay.name = "ZoomOverlay"
	_zoom_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_zoom_overlay.z_index = 200
	add_child(_zoom_overlay)

	var dim = ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.75)
	_zoom_overlay.add_child(dim)

	var max_w = vp.x * 0.80
	var max_h = vp.y * 0.82
	var zoom_scale = min(max_w / 130.0, max_h / 182.0)
	var card_w = 130.0 * zoom_scale
	var card_h = 182.0 * zoom_scale

	var card_instance = CardDatabase.create_card_instance(card_id)
	card_instance.scale = Vector2(zoom_scale, zoom_scale)
	card_instance.is_draggable = false
	card_instance.position = Vector2(
		round(vp.x / 2.0 - card_w / 2.0),
		round(vp.y / 2.0 - card_h / 2.0)
	)
	_zoom_overlay.add_child(card_instance)

	var hint = Label.new()
	hint.text = "Espacio / Esc / Clic para cerrar"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.position = Vector2(0, vp.y - 36)
	hint.size = Vector2(vp.x, 28)
	hint.add_theme_font_size_override("font_size", 13)
	hint.add_theme_color_override("font_color", Color(0.75, 0.72, 0.55))
	_zoom_overlay.add_child(hint)

	var click_btn = Button.new()
	click_btn.set_anchors_preset(Control.PRESET_FULL_RECT)
	click_btn.flat = true
	var invisible = StyleBoxFlat.new()
	invisible.bg_color = Color(0, 0, 0, 0)
	click_btn.add_theme_stylebox_override("normal", invisible)
	click_btn.add_theme_stylebox_override("hover", invisible)
	click_btn.add_theme_stylebox_override("pressed", invisible)
	click_btn.pressed.connect(_close_zoom)
	_zoom_overlay.add_child(click_btn)

	_zoom_overlay.modulate.a = 0.0
	var tw = create_tween()
	tw.tween_property(_zoom_overlay, "modulate:a", 1.0, 0.12)

	_zoom_active = true

func _close_zoom() -> void:
	if _zoom_overlay:
		_zoom_overlay.queue_free()
		_zoom_overlay = null
	_zoom_active = false

# ============================================================
# LOG
# ============================================================
const MAX_LOG_ENTRIES = 60

const LOG_CATEGORIES = {
	"attack":  {"icon": "⚔", "color": Color(0.95, 0.35, 0.35)},
	"ko":      {"icon": "💀", "color": Color(0.85, 0.20, 0.20)},
	"damage":  {"icon": "💥", "color": Color(0.95, 0.55, 0.20)},
	"prize":   {"icon": "🏆", "color": Color(0.90, 0.80, 0.20)},
	"heal":    {"icon": "💚", "color": Color(0.30, 0.90, 0.40)},
	"status":  {"icon": "🌀", "color": Color(0.70, 0.40, 0.95)},
	"flip":    {"icon": "🪙", "color": Color(0.85, 0.75, 0.30)},
	"energy":  {"icon": "⚡", "color": Color(0.40, 0.75, 0.95)},
	"trainer": {"icon": "🃏", "color": Color(0.60, 0.85, 0.60)},
	"setup":   {"icon": "🎴", "color": Color(0.75, 0.65, 0.45)},
	"turn":    {"icon": "🔄", "color": Color(0.55, 0.55, 0.75)},
	"warn":    {"icon": "⚠", "color": Color(0.95, 0.80, 0.20)},
	"error":   {"icon": "✖", "color": Color(0.90, 0.25, 0.25)},
	"info":    {"icon": "•", "color": Color(0.70, 0.75, 0.65)},
}

func _detect_log_category(text: String) -> String:
	var t = text.to_lower()
	if "ko" in t or "knocked out" in t or "derrotado" in t: return "ko"
	if "uses " in t or "ataca" in t or "usa " in t: return "attack"
	if "damage" in t or "daño" in t or "applied" in t: return "damage"
	if "prize" in t or "premio" in t: return "prize"
	if "heal" in t or "curó" in t or "recovered" in t or "despertó" in t: return "heal"
	if "paralyz" in t or "asleep" in t or "confused" in t or "poison" in t or "burn" in t \
		or "paraliz" in t or "dormido" in t or "envenen" in t or "quemad" in t or "confus" in t: return "status"
	if "flip" in t or "heads" in t or "tails" in t or "moneda" in t or "cara" in t: return "flip"
	if "energy" in t or "energía" in t or "attach" in t or "adjunt" in t: return "energy"
	if "plays " in t or "jugando" in t or "trainer" in t or "supporter" in t: return "trainer"
	if "setup" in t or "activo" in t or "boca abajo" in t or "revelac" in t: return "setup"
	if "turno" in t or "turn " in t or "--- turn" in t: return "turn"
	if "⚠" in t or "warning" in t or "cannot" in t or "no puedes" in t: return "warn"
	if "✖" in t or "error" in t: return "error"
	return "info"

func _add_log(text: String) -> void:
	if not log_panel: return
	var vbox = log_panel.get_node_or_null("LogScroll/LogEntries")
	if not vbox: return

	if vbox.get_child_count() >= MAX_LOG_ENTRIES:
		vbox.get_child(0).queue_free()

	var category = _detect_log_category(text)
	var cat_data = LOG_CATEGORIES.get(category, LOG_CATEGORIES["info"])

	var t = text.to_lower()
	if ("heads" in t or "tails" in t) or category == "damage" or category == "ko":
		_show_floating_text(text, cat_data["color"])

	var entry = Control.new()
	entry.custom_minimum_size = Vector2(196, 0)
	entry.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var entry_bg = ColorRect.new()
	entry_bg.color = Color(cat_data["color"].r, cat_data["color"].g, cat_data["color"].b, 0.06)
	entry_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	entry_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	entry.add_child(entry_bg)

	var side_bar = ColorRect.new()
	side_bar.color = cat_data["color"]
	side_bar.size = Vector2(2, 100)
	side_bar.position = Vector2(0, 0)
	side_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	entry.add_child(side_bar)

	var icon_lbl = Label.new()
	icon_lbl.text = cat_data["icon"]
	icon_lbl.position = Vector2(4, 2)
	icon_lbl.size = Vector2(16, 16)
	icon_lbl.add_theme_font_size_override("font_size", 10)
	entry.add_child(icon_lbl)

	var text_lbl = Label.new()
	text_lbl.text = text
	text_lbl.position = Vector2(22, 1)
	text_lbl.size = Vector2(172, 0)
	text_lbl.add_theme_font_size_override("font_size", 9)
	text_lbl.add_theme_color_override("font_color", cat_data["color"].lightened(0.15))
	text_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	entry.add_child(text_lbl)

	vbox.add_child(entry)

	await get_tree().process_frame
	if is_instance_valid(text_lbl) and is_instance_valid(entry):
		var h = max(18.0, text_lbl.get_minimum_size().y + 4)
		entry.custom_minimum_size = Vector2(196, h)
		if is_instance_valid(side_bar):
			side_bar.size.y = h
		if is_instance_valid(entry_bg):
			entry_bg.size = Vector2(196, h)

	entry.modulate.a = 0.0
	entry.position.x = -20.0
	var tw = create_tween()
	tw.set_parallel(true)
	tw.tween_property(entry, "modulate:a", 1.0, 0.15)
	tw.tween_property(entry, "position:x", 0.0, 0.15)

	await get_tree().process_frame
	var scroll = log_panel.get_node_or_null("LogScroll")
	if scroll and is_instance_valid(scroll):
		scroll.scroll_vertical = scroll.get_v_scroll_bar().max_value

# ============================================================
# GAME OVER — FIX: botón invisible para capturar el click
# ============================================================
func _show_game_over_screen(message: String, won: bool) -> void:
	var overlay = Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 500

	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0, 0, 0, 0.75)
	overlay.add_child(bg)

	var over_lbl = Label.new()
	over_lbl.text = message
	over_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	over_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	over_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	over_lbl.add_theme_font_size_override("font_size", 48)
	over_lbl.add_theme_color_override("font_color", COLOR_GOLD if won else Color(0.8, 0.3, 0.3))
	over_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(over_lbl)

	var hint = Label.new()
	hint.text = "Click para volver al menú"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.position = Vector2(0, get_viewport().get_visible_rect().size.y / 2.0 + 60)
	hint.size = Vector2(get_viewport().get_visible_rect().size.x, 30)
	hint.add_theme_font_size_override("font_size", 16)
	hint.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(hint)

	# FIX: botón invisible sobre toda la pantalla que captura el click
	var click_catcher = Button.new()
	click_catcher.set_anchors_preset(Control.PRESET_FULL_RECT)
	click_catcher.flat = true
	var invisible_style = StyleBoxFlat.new()
	invisible_style.bg_color = Color(0, 0, 0, 0)
	click_catcher.add_theme_stylebox_override("normal",  invisible_style)
	click_catcher.add_theme_stylebox_override("hover",   invisible_style)
	click_catcher.add_theme_stylebox_override("pressed", invisible_style)
	click_catcher.pressed.connect(func():
		NetworkManager.disconnect_from_server()
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
	)
	overlay.add_child(click_catcher)

	add_child(overlay)
	overlay.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(overlay, "modulate:a", 1.0, 0.5)

# ============================================================
# HELPERS VISUALES
# ============================================================
func _get_type_icon(type_str: String) -> Texture2D:
	var base_path = "res://assets/imagen/TypesIcons/"
	var file_name = ""
	match type_str.to_upper():
		"FIRE":      file_name = "fire.png"
		"WATER":     file_name = "water.png"
		"GRASS":     file_name = "grass.png"
		"LIGHTNING": file_name = "electric.png"
		"PSYCHIC":   file_name = "psy.png"
		"FIGHTING":  file_name = "figth.png"
		"COLORLESS": file_name = "incolor.png"
		"DARKNESS":  file_name = "dark.png"
		"METAL":     file_name = "metal.png"
		"DRAGON":    file_name = "dragon.png"
	if file_name == "": return null
	return load(base_path + file_name)

# ============================================================
# ANIMACIONES FLOTANTES
# ============================================================
func _show_floating_text(msg: String, color: Color) -> void:
	var vp = get_viewport().get_visible_rect().size

	var lbl = Label.new()
	lbl.text = msg
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.size = Vector2(vp.x, 60)

	var random_offset_y = randf_range(-30.0, 30.0)
	lbl.position = Vector2(0, vp.y / 2.0 - 80 + random_offset_y)
	lbl.z_index = 400

	lbl.add_theme_font_size_override("font_size", 28)
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	lbl.add_theme_constant_override("outline_size", 6)

	add_child(lbl)

	var tw = create_tween()
	tw.set_parallel(true)
	tw.tween_property(lbl, "position:y", lbl.position.y - 60, 2.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tw.tween_property(lbl, "modulate:a", 0.0, 2.5).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	tw.chain().tween_callback(lbl.queue_free)

# ============================================================
# GLARING GAZE POPUP (SLOWKING)
# ============================================================
var _gaze_popup: Control = null

func _check_glaring_gaze(state: Dictionary) -> void:
	if state.has("_glaring_gaze_peek") and my_turn:
		if not _gaze_popup:
			_show_glaring_gaze_popup(state.get("_glaring_gaze_peek", []))
	else:
		if _gaze_popup:
			_gaze_popup.queue_free()
			_gaze_popup = null

func _show_glaring_gaze_popup(revealed_trainers: Array) -> void:
	var vp = get_viewport().get_visible_rect().size
	_gaze_popup = Control.new()
	_gaze_popup.set_anchors_preset(Control.PRESET_FULL_RECT)
	_gaze_popup.z_index = 300
	add_child(_gaze_popup)

	var dim = ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.8)
	_gaze_popup.add_child(dim)

	var panel_w = min(600.0, vp.x - 40)
	var panel_h = 240.0
	var panel = Panel.new()
	panel.position = Vector2((vp.x - panel_w) / 2.0, (vp.y - panel_h) / 2.0)
	panel.size = Vector2(panel_w, panel_h)
	_gaze_popup.add_child(panel)

	var lbl = Label.new()
	lbl.text = "👁 GLARING GAZE 👁\nElige un Entrenador de la mano rival para devolverlo a su mazo:"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.position = Vector2(10, 10)
	lbl.size = Vector2(panel_w - 20, 40)
	lbl.add_theme_color_override("font_color", COLOR_GOLD)
	panel.add_child(lbl)

	var start_x = 20.0
	for t in revealed_trainers:
		var c_id = t.get("card_id", "")
		var h_idx = t.get("handIndex", 0)

		var btn = Button.new()
		btn.position = Vector2(start_x, 60)
		btn.size = Vector2(CARD_W, CARD_H)

		var card_inst = CardDatabase.create_card_instance(c_id)
		card_inst.position = Vector2.ZERO
		card_inst.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(card_inst)

		btn.pressed.connect(func():
			NetworkManager.resolve_glaring_gaze(h_idx)
			_gaze_popup.queue_free()
			_gaze_popup = null
		)
		panel.add_child(btn)
		start_x += CARD_W + 10
