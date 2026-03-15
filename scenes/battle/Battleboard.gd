extends Node2D

# ============================================================
# BattleBoard.gd
# ============================================================

signal action_requested(action_type, params)
signal card_selected(card_node, zone, index)

# ─── MANAGERS & HANDLERS ────────────────────────────────────
var overlays:        OverlayManager = null
var renderer:        BoardRenderer  = null
var hand_manager:    HandManager    = null
var trainer_handler: Node = null
var action_handler:  Node = null

# ─── REFERENCIAS A ZONAS ────────────────────────────────────
var my_active_zone:   Control = null
var my_bench_zones:   Array   = []
var my_hand_zone:     Control = null
var my_deck_zone:     Control = null
var my_discard_zone:  Control = null
var my_prizes_zone:   Control = null

var opp_active_zone:  Control = null
var opp_bench_zones:  Array   = []
var opp_hand_zone:    Control = null
var opp_deck_zone:    Control = null
var opp_discard_zone: Control = null
var opp_prizes_zone:  Control = null

var stadium_zone:  Control   = null
var end_turn_btn:  Button    = null
var battle_log:    BattleLog = null
var phase_label:   Label     = null

# ─── NOTIFICACIÓN DESLIZANTE ────────────────────────────────
var _notif_container: Control = null
var _notif_label:     Label   = null
var _notif_tween:     Tween   = null

# ─── ESTADO LOCAL ───────────────────────────────────────────
var current_state:            Dictionary = {}
var my_player_id:             String     = ""
var selected_hand_index:      int        = -1
var selected_card_node                   = null
var my_turn:                  bool       = false
var _processed_logs_count:    int        = 0
var _last_turn_player:        String     = ""

# ─── NOMBRES Y TIERS LEGIBLES ───────────────────────────────
var _my_display_name:  String = "Tú"
var _opp_display_name: String = "Rival"
var _opp_id:           String = ""
var _my_tier:          String = ""
var _opp_tier:         String = ""
var _vs_banner:        Label  = null

# ─── PROTECTORES ────────────────────────────────────────────
var my_sleeve_id:  String = "default"
var opp_sleeve_id: String = "default"

# ─── MONEDAS PERSONALIZABLES ────────────────────────────────
var my_coin_heads: String = "res://assets/imagen/tokens/TCG Flip Coins/CoinFont/ENERGY-SMALL-SILVER-NON.png"
var my_coin_tails: String = "res://assets/imagen/tokens/TCG Flip Coins/CoinBack/SMALL-SILVER-A.png"
var opp_coin_heads: String = "res://assets/imagen/tokens/TCG Flip Coins/CoinFont/ENERGY-SMALL-SILVER-NON.png"
var opp_coin_tails: String = "res://assets/imagen/tokens/TCG Flip Coins/CoinBack/SMALL-SILVER-A.png"
var _last_flip_was_opponent: bool = false

const COIN_BASE_PATH_FRONT = "res://assets/imagen/tokens/TCG Flip Coins/CoinFont/"
const COIN_BASE_PATH_BACK  = "res://assets/imagen/tokens/TCG Flip Coins/CoinBack/"

const COIN_FILES = {
	"default":             {"front": "ESPEON-LARGE-PURPLE-RAINBOW.png",      "back": "LARGE-YELLOW-A.png"},
	"chikorita":           {"front": "CHIKORITA-SMALL-GREEN-NON.png",        "back": "LARGE-YELLOW-A.png"},
	"cyndaquil":           {"front": "CYNDAQUIL-SMALL-GOLD-NON.png",         "back": "LARGE-YELLOW-A.png"},
	"totodile":            {"front": "TOTODILE-SMALL-BLUE-NON.png",          "back": "LARGE-YELLOW-A.png"},
	"pikachu_gold":        {"front": "PIKACHU-SMALL-GOLD-NON.png",           "back": "LARGE-YELLOW-A.png"},
	"pikachu_mirror":      {"front": "PIKACHU-SMALL-SILVER-MIRROR.png",      "back": "LARGE-YELLOW-A.png"},
	"lugia_mirror":        {"front": "LUGIA-LARGE-SILVER-MIRROR.png",        "back": "LARGE-YELLOW-A.png"},
	"ho_oh":               {"front": "HO-OH-LARGE-GOLD-MIRROR.png",          "back": "LARGE-YELLOW-A.png"},
	"rayquaza_green":      {"front": "RAYQUAZA-SMALL-GREEN-MIRROR.png",      "back": "LARGE-YELLOW-A.png"},
	"charizard_large":     {"front": "CHARIZARD-LARGE-ORANGE-MIRROR.png",    "back": "LARGE-YELLOW-A.png"},
	"mewtwo_x":            {"front": "M MEWTWO X-LARGE-BLUE-RAINBOW.png",    "back": "LARGE-YELLOW-A.png"},
	"lugia_cracked":       {"front": "LUGIA-LARGE-SILVER-CRACKED ICE.png",   "back": "LARGE-YELLOW-A.png"},
	"pikachu_waving_gold": {"front": "PIKACHU_waving-LARGE-GOLD-MIRROR.png", "back": "LARGE-YELLOW-A.png"},
	"mew_glitter":         {"front": "MEW-SMALL-SILVER-GLITTER.png",         "back": "LARGE-YELLOW-A.png"},
	"arceus_gold":         {"front": "ARCEUS-SMALL-GOLD-MIRROR.png",         "back": "LARGE-YELLOW-A.png"},
}

func _load_coin_textures(coin_id: String) -> void:
	var files = COIN_FILES.get(coin_id, COIN_FILES["default"])
	my_coin_heads = COIN_BASE_PATH_FRONT + files["front"]
	my_coin_tails = COIN_BASE_PATH_BACK  + files["back"]


func _load_opp_coin_textures(coin_id: String) -> void:
	var files = COIN_FILES.get(coin_id, COIN_FILES["default"])
	opp_coin_heads = COIN_BASE_PATH_FRONT + files["front"]
	opp_coin_tails = COIN_BASE_PATH_BACK  + files["back"]
	
# ─── DRAG EN CURSO ──────────────────────────────────────────
var _active_drag_card               = null
var _active_drag_hand_index: int    = -1
var _active_drag_card_id:    String = ""

# ─── TEMPORIZADOR DE TURNO ──────────────────────────────────
const TURN_SECONDS       := 120
const TIMER_WARN_SECONDS := 20
var _turn_timer:      Timer     = null
var _turn_time_left:  float     = 0.0
var _timer_bar:       Control   = null
var _timer_fill:      ColorRect = null
var _timer_label:     Label     = null
var _timer_tween:     Tween     = null
var _opp_turn_timer:     Timer = null
var _opp_turn_time_left: float = 0.0

# ─── BOTÓN ABANDONAR ────────────────────────────────────────
var _forfeit_btn:     Button  = null
var _forfeit_confirm: Control = null

# ─── COLORES ────────────────────────────────────────────────
const COLOR_GOLD     = Color(0.85, 0.72, 0.30)
const COLOR_GOLD_DIM = Color(0.55, 0.45, 0.18)
const COLOR_TEXT     = Color(0.92, 0.88, 0.75)
const CARD_W         = 130
const CARD_H         = 182


# ============================================================
# INICIO
# ============================================================
func _ready() -> void:
	overlays = OverlayManager.new()
	add_child(overlays)
	overlays.setup(self)
	overlays.setup_confirmed.connect(_on_confirm_setup)
	overlays.setup_reselect_active.connect(_on_setup_reselect_active)
	overlays.promote_selected.connect(func(idx):
		NetworkManager.send_action("PROMOTE", {"benchIndex": idx})
		battle_log.add_message("Promoviendo Pokémon al frente...")
	)
	overlays.glaring_gaze_resolved.connect(func(idx):
		NetworkManager.resolve_glaring_gaze(idx)
	)
	overlays.action_zoom_selected.connect(_handle_action_zoom_choice)
	overlays.bench_power_requested.connect(_on_bench_power_requested)
	overlays.game_over_closed.connect(func():
		NetworkManager.leave_room()
		get_tree().change_scene_to_file("res://scenes/main_menu/MainMenu.tscn")
	)

	_build_board()

	hand_manager = HandManager.new()
	add_child(hand_manager)
	hand_manager.setup(my_hand_zone, get_viewport().get_visible_rect().size.x)
	hand_manager.card_clicked.connect(func(idx, _cid): _on_hand_card_clicked(idx))
	hand_manager.card_drag_started.connect(_on_hand_card_drag_started)
	hand_manager.card_dropped.connect(_on_hand_card_dropped)

	trainer_handler = load("res://scripts/Battle/TrainerHandler.gd").new()
	trainer_handler.board = self
	add_child(trainer_handler)
	trainer_handler.trainer_message.connect(func(msg): battle_log.add_message(msg))
	trainer_handler.trainer_highlight_zones.connect(_on_trainer_highlight_zones)

	action_handler = load("res://scripts/Battle/ActionHandler.gd").new()
	action_handler.board = self
	action_handler.trainer_handler = trainer_handler
	add_child(action_handler)
	action_handler.setup()
	action_handler.action_message.connect(func(msg): battle_log.add_message(msg))
	action_handler.action_buttons_update_needed.connect(_update_action_buttons)

	_connect_network()
	_setup_turn_timer()


# ============================================================
# CONSTRUIR TABLERO VISUAL
# ============================================================
func _build_board() -> void:
	var vp = get_viewport().get_visible_rect().size
	var W  = vp.x
	var H  = vp.y

	var bg = TextureRect.new()
	bg.texture     = load("res://assets/imagen/tablero/tablero1.png")
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.size        = Vector2(W, H)
	bg.position    = Vector2.ZERO
	bg.z_index     = -10
	add_child(bg)

	var zones = BoardBuilder.build_all(self, vp)

	my_active_zone   = zones["my_active"]
	my_bench_zones   = zones["my_bench"]
	my_hand_zone     = zones["my_hand"]
	my_deck_zone     = zones["my_deck"]
	my_discard_zone  = zones["my_discard"]
	my_prizes_zone   = zones["my_prizes"]

	opp_active_zone  = zones["opp_active"]
	opp_bench_zones  = zones["opp_bench"]
	opp_hand_zone    = zones["opp_hand"]
	opp_deck_zone    = zones["opp_deck"]
	opp_discard_zone = zones["opp_discard"]
	opp_prizes_zone  = zones["opp_prizes"]

	stadium_zone = zones["stadium"]

	renderer = BoardRenderer.new()
	add_child(renderer)
	renderer.setup(zones, W)
	renderer.my_active_clicked.connect(_on_active_pokemon_clicked)
	renderer.my_discard_clicked.connect(_on_my_discard_clicked)
	renderer.opp_discard_clicked.connect(_on_opp_discard_clicked)

	end_turn_btn = _build_end_turn_button(W, H)
	add_child(end_turn_btn)

	_build_notification_bar(W)
	_build_timer_bar(W, H)
	_build_opp_timer_bar(W)
	_build_forfeit_button(W, H)

	_vs_banner = _build_vs_banner(W)
	add_child(_vs_banner)

	battle_log = BattleLog.new()
	battle_log.setup(W, H)
	add_child(battle_log)
	battle_log.chat_sent.connect(func(text): NetworkManager.send_chat(text))

	phase_label = Label.new()
	phase_label.position             = Vector2(8, H - 20)
	phase_label.size                 = Vector2(200, 16)
	phase_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	phase_label.add_theme_font_size_override("font_size", 9)
	phase_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.4, 0.6))
	add_child(phase_label)


func _ensure_bench_click_areas() -> void:
	for i in range(my_bench_zones.size()):
		var zone = my_bench_zones[i]
		if not zone: continue

		for child in zone.get_children():
			if child.has_meta("is_bench_area"):
				child.queue_free()

		var btn = Button.new()
		btn.name = "BenchClickArea"
		btn.set_meta("is_bench_area", true)
		btn.set_anchors_preset(Control.PRESET_FULL_RECT)
		btn.flat = true
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		btn.z_index = 5
		var transparent = StyleBoxFlat.new()
		transparent.bg_color = Color(0, 0, 0, 0)
		btn.add_theme_stylebox_override("normal",  transparent)
		btn.add_theme_stylebox_override("hover",   transparent)
		btn.add_theme_stylebox_override("pressed", transparent)

		# ── Propagar hover al CardInstance ──────────────────
		var zone_ref = zone
		btn.mouse_entered.connect(func():
			var card = zone_ref.get_node_or_null("CardInstance")
			if card and card.has_method("set"):
				card.set("is_hovered", true)
		)
		btn.mouse_exited.connect(func():
			var card = zone_ref.get_node_or_null("CardInstance")
			if card and card.has_method("set"):
				card.set("is_hovered", false)
		)
		# ────────────────────────────────────────────────────

		btn.pressed.connect(_on_bench_pokemon_clicked.bind(i))
		zone.add_child(btn)

# ============================================================
# BENCH POKEMON CLICKED
# ============================================================
func _on_bench_pokemon_clicked(bench_index: int) -> void:
	print("[BB] _on_bench_pokemon_clicked — bench_index=%d" % bench_index)

	if trainer_handler.is_awaiting():
		trainer_handler.on_zone_clicked("bench", bench_index)
		return

	if action_handler.power_handler and action_handler.power_handler.is_active():
		print("[BB]   → Clic en banco IGNORADO porque un PokéPower está activo esperando objetivo.")
		return

	if action_handler.is_busy():
		return

	var bench = current_state.get("my", {}).get("bench", [])
	if bench_index >= bench.size(): return
	var poke = bench[bench_index]
	if poke == null: return

	var card_id           = poke.get("card_id", "")
	var cdata             = CardDatabase.get_card(card_id)
	var power             = cdata.get("pokemon_power", null)
	var phase             = current_state.get("phase", "")
	var powers_used       = current_state.get("powers_used_this_turn", [])
	var instance_id       = poke.get("instance_id", "")
	var poke_status       = poke.get("status", "")
	var status_blocks     = ["ASLEEP", "CONFUSED", "PARALYZED"]
	var powers_suppressed = current_state.get("powers_suppressed", false)

	if power != null \
		and my_turn \
		and phase == "MAIN" \
		and not (instance_id in powers_used) \
		and not (poke_status in status_blocks) \
		and not powers_suppressed:
		overlays.show_bench_power_popup(bench_index, poke)
	else:
		overlays.open_zoom(card_id, poke)


func _on_bench_power_requested(bench_index: int, power_name: String) -> void:
	if bench_index == -1:
		action_handler.on_action_zoom_choice("POWER", power_name, "active", 0)
	else:
		action_handler.on_action_zoom_choice("POWER", power_name, "bench", bench_index)


# ============================================================
# BADGES ⚡ EN BANCO
# ============================================================
func _update_bench_power_badges(state: Dictionary) -> void:
	var bench             = state.get("my", {}).get("bench", [])
	var phase             = state.get("phase", "")
	var powers_used        = state.get("powers_used_this_turn", [])
	var is_main           = my_turn and phase == "MAIN"
	var status_blocks     = ["ASLEEP", "CONFUSED", "PARALYZED"]
	var powers_suppressed = state.get("powers_suppressed", false)

	for i in range(my_bench_zones.size()):
		var zone = my_bench_zones[i]
		if not zone: continue

		var old_badge = zone.get_node_or_null("PowerBadge")
		if old_badge: old_badge.queue_free()

		if i >= bench.size() or bench[i] == null: continue
		var poke    = bench[i]
		var card_id = poke.get("card_id", "")
		var cdata   = CardDatabase.get_card(card_id)
		var power   = cdata.get("pokemon_power", null)
		if power == null: continue

		var poke_status = poke.get("status", "")
		var available   = is_main \
			and not (poke.get("instance_id", "") in powers_used) \
			and not (poke_status in status_blocks) \
			and not powers_suppressed

		var badge = Label.new()
		badge.name     = "PowerBadge"
		badge.text     = "⚡"
		badge.position = Vector2(zone.size.x - 22, 2)
		badge.size     = Vector2(20, 20)
		badge.add_theme_font_size_override("font_size", 14)
		badge.add_theme_color_override("font_color",
			Color(0.95, 0.80, 0.20) if available else Color(0.40, 0.35, 0.15, 0.50))
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		badge.z_index      = 8
		zone.add_child(badge)


# ============================================================
# TEMPORIZADOR DE TURNO — VISUAL
# ============================================================
func _build_timer_bar(W: float, H: float) -> void:
	const BAR_W := 260.0
	const BAR_H := 26.0
	var bar_x := W - BAR_W - 14.0
	var bar_y := 14.0 + 42.0 + 6.0

	_timer_bar          = Control.new()
	_timer_bar.name     = "TurnTimerBar"
	_timer_bar.position = Vector2(bar_x, bar_y)
	_timer_bar.size     = Vector2(BAR_W, BAR_H)
	_timer_bar.z_index  = 10
	_timer_bar.visible  = false
	add_child(_timer_bar)

	var bg_rect = ColorRect.new()
	bg_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_rect.color = Color(0.06, 0.06, 0.10, 0.88)
	_timer_bar.add_child(bg_rect)

	var border = Panel.new()
	border.set_anchors_preset(Control.PRESET_FULL_RECT)
	var bs = StyleBoxFlat.new()
	bs.bg_color = Color(0, 0, 0, 0)
	bs.border_color = COLOR_GOLD_DIM
	bs.border_width_left = 1; bs.border_width_right  = 1
	bs.border_width_top  = 1; bs.border_width_bottom = 1
	bs.corner_radius_top_left    = 5; bs.corner_radius_top_right    = 5
	bs.corner_radius_bottom_left = 5; bs.corner_radius_bottom_right = 5
	border.add_theme_stylebox_override("panel", bs)
	_timer_bar.add_child(border)

	_timer_fill          = ColorRect.new()
	_timer_fill.name     = "TimerFill"
	_timer_fill.position = Vector2(2, 2)
	_timer_fill.size     = Vector2(260.0 - 4, BAR_H - 4)
	_timer_fill.color    = Color(0.20, 0.65, 0.30, 0.80)
	_timer_bar.add_child(_timer_fill)

	_timer_label = Label.new()
	_timer_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_timer_label.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	_timer_label.add_theme_font_size_override("font_size", 11)
	_timer_label.add_theme_color_override("font_color", COLOR_TEXT)
	_timer_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_timer_label.add_theme_constant_override("outline_size", 3)
	_timer_bar.add_child(_timer_label)

var _opp_timer_bar:   Control   = null
var _opp_timer_fill:  ColorRect = null
var _opp_timer_label: Label     = null

func _build_opp_timer_bar(W: float) -> void:
	const BAR_W := 260.0
	const BAR_H := 26.0
	var bar_x := W - BAR_W - 14.0
	var bar_y := 14.0 + 42.0 + 6.0 # justo debajo del timer propio

	_opp_timer_bar          = Control.new()
	_opp_timer_bar.name     = "OppTurnTimerBar"
	_opp_timer_bar.position = Vector2(bar_x, bar_y)
	_opp_timer_bar.size     = Vector2(BAR_W, BAR_H)
	_opp_timer_bar.z_index  = 10
	_opp_timer_bar.visible  = false
	add_child(_opp_timer_bar)

	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.06, 0.06, 0.10, 0.75)
	_opp_timer_bar.add_child(bg)
	
	
	
	var border = Panel.new()
	border.set_anchors_preset(Control.PRESET_FULL_RECT)
	var bs = StyleBoxFlat.new()
	bs.bg_color = Color(0, 0, 0, 0)
	bs.border_color = COLOR_GOLD_DIM
	bs.border_width_left = 1; bs.border_width_right  = 1
	bs.border_width_top  = 1; bs.border_width_bottom = 1
	bs.corner_radius_top_left    = 5; bs.corner_radius_top_right    = 5
	bs.corner_radius_bottom_left = 5; bs.corner_radius_bottom_right = 5
	border.add_theme_stylebox_override("panel", bs)
	_opp_timer_bar.add_child(border)

	_opp_timer_fill          = ColorRect.new()
	_opp_timer_fill.position = Vector2(2, 2)
	_opp_timer_fill.size     = Vector2(BAR_W - 4, BAR_H - 4)
	_opp_timer_fill.color    = Color(0.85, 0.18, 0.18, 0.90)
	_opp_timer_bar.add_child(_opp_timer_fill)

	_opp_timer_label = Label.new()
	_opp_timer_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_opp_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_opp_timer_label.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	_opp_timer_label.add_theme_font_size_override("font_size", 11)
	_opp_timer_label.add_theme_color_override("font_color", COLOR_TEXT)
	_opp_timer_bar.add_child(_opp_timer_label)


func _show_opp_timer(time_left: float) -> void:
	if not _opp_timer_bar: return
	_opp_turn_time_left    = time_left
	_opp_timer_bar.visible = true
	_update_opp_timer_visuals()
	if not _opp_turn_timer:
		_opp_turn_timer = Timer.new()
		_opp_turn_timer.wait_time = 1.0
		_opp_turn_timer.timeout.connect(_on_opp_timer_tick)
		add_child(_opp_turn_timer)
	_opp_turn_timer.start()


func _on_opp_timer_tick() -> void:
	_opp_turn_time_left -= 1.0
	_update_opp_timer_visuals()
	if _opp_turn_time_left <= 0.0:
		_opp_turn_timer.stop()


func _update_opp_timer_visuals() -> void:
	if not _opp_timer_fill or not _opp_timer_label: return
	var fraction = clampf(_opp_turn_time_left / float(TURN_SECONDS), 0.0, 1.0)
	_opp_timer_fill.size.x = maxf((_opp_timer_bar.size.x - 4.0) * fraction, 0.0)
	var secs = int(_opp_turn_time_left)
	_opp_timer_label.text = "⏱ Rival: %d:%02d" % [secs / 60, secs % 60]
	

# ============================================================
# TEMPORIZADOR DE TURNO — LÓGICA
# ============================================================
func _setup_turn_timer() -> void:
	_turn_timer = Timer.new()
	_turn_timer.wait_time = 1.0
	_turn_timer.autostart = false
	_turn_timer.timeout.connect(_on_timer_tick)
	add_child(_turn_timer)


func _start_turn_timer() -> void:
	if _opp_turn_timer:
		_opp_turn_timer.stop()
	if _opp_timer_bar:
		_opp_timer_bar.visible = false
	_turn_time_left    = float(TURN_SECONDS)
	_timer_bar.visible = true
	_update_timer_visuals()
	_turn_timer.start()
	

func _stop_turn_timer() -> void:
	_turn_timer.stop()
	if _timer_tween and _timer_tween.is_valid():
		_timer_tween.kill()
	if _timer_bar:
		_timer_bar.visible  = false
		_timer_bar.modulate = Color.WHITE


func _on_timer_tick() -> void:
	_turn_time_left -= 1.0
	_update_timer_visuals()
	if _turn_time_left <= 0.0:
		_turn_timer.stop()
		battle_log.add_message("⏰ Tiempo agotado — turno terminado automáticamente")
		_on_action_button("END_TURN")


func _update_timer_visuals() -> void:
	if not _timer_fill or not _timer_label: return

	var fraction := clampf(_turn_time_left / float(TURN_SECONDS), 0.0, 1.0)
	_timer_fill.size.x = maxf((_timer_bar.size.x - 4.0) * fraction, 0.0)

	if _turn_time_left > TIMER_WARN_SECONDS:
		_timer_fill.color = Color(0.20, 0.65, 0.30, 0.80)
	elif _turn_time_left > 10:
		_timer_fill.color = Color(0.80, 0.65, 0.10, 0.85)
	else:
		_timer_fill.color = Color(0.85, 0.18, 0.18, 0.90)

	if _turn_time_left <= 10.0 and _turn_time_left > 0.0:
		if not (_timer_tween and _timer_tween.is_valid()):
			_timer_tween = create_tween().set_loops()
			_timer_tween.tween_property(_timer_bar, "modulate:a", 0.45, 0.35)
			_timer_tween.tween_property(_timer_bar, "modulate:a", 1.0,  0.35)
	else:
		if _timer_tween and _timer_tween.is_valid():
			_timer_tween.kill()
		if _timer_bar: _timer_bar.modulate.a = 1.0

	var secs := int(_turn_time_left)
	_timer_label.text = "%d:%02d" % [secs / 60, secs % 60]


# ============================================================
# BOTÓN ABANDONAR
# ============================================================
func _build_forfeit_button(W: float, H: float) -> void:
	_forfeit_btn          = Button.new()
	_forfeit_btn.text     = "✕  Abandonar"
	_forfeit_btn.position = Vector2(14.0, 34.0)
	_forfeit_btn.size     = Vector2(260.0, 28.0)
	_forfeit_btn.z_index  = 10
	_forfeit_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	var s_n = StyleBoxFlat.new()
	s_n.bg_color     = Color(0.75, 0.08, 0.08, 1.0)
	s_n.border_color = Color(1.0, 0.20, 0.20, 1.0)
	s_n.border_width_left = 1; s_n.border_width_right  = 1
	s_n.border_width_top  = 1; s_n.border_width_bottom = 1
	s_n.corner_radius_top_left    = 5; s_n.corner_radius_top_right    = 5
	s_n.corner_radius_bottom_left = 5; s_n.corner_radius_bottom_right = 5
	_forfeit_btn.add_theme_stylebox_override("normal", s_n)

	var s_h = StyleBoxFlat.new()
	s_h.bg_color     = Color(0.95, 0.12, 0.12, 1.0)
	s_h.border_color = Color(1.0, 0.40, 0.40, 1.0)
	s_h.border_width_left = 1; s_h.border_width_right  = 1
	s_h.border_width_top  = 1; s_h.border_width_bottom = 1
	s_h.corner_radius_top_left    = 5; s_h.corner_radius_top_right    = 5
	s_h.corner_radius_bottom_left = 5; s_h.corner_radius_bottom_right = 5
	_forfeit_btn.add_theme_stylebox_override("hover", s_h)

	_forfeit_btn.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	_forfeit_btn.add_theme_font_size_override("font_size", 11)
	_forfeit_btn.pressed.connect(_on_forfeit_pressed)
	add_child(_forfeit_btn)


func _on_forfeit_pressed() -> void:
	if _forfeit_confirm and is_instance_valid(_forfeit_confirm): return
	_forfeit_confirm = _build_forfeit_confirm_popup()
	add_child(_forfeit_confirm)


func _build_forfeit_confirm_popup() -> Control:
	var vp    := get_viewport().get_visible_rect().size
	var popup := Control.new()
	popup.name = "ForfeitConfirm"
	popup.set_anchors_preset(Control.PRESET_FULL_RECT)
	popup.z_index = 300

	var dim = ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.72)
	popup.add_child(dim)

	const PW := 360.0
	const PH := 168.0
	var panel = Panel.new()
	panel.position = Vector2((vp.x - PW) / 2.0, (vp.y - PH) / 2.0)
	panel.size     = Vector2(PW, PH)
	var ps = StyleBoxFlat.new()
	ps.bg_color     = Color(0.08, 0.05, 0.05, 0.98)
	ps.border_color = Color(0.80, 0.25, 0.25)
	ps.border_width_left = 2; ps.border_width_right  = 2
	ps.border_width_top  = 2; ps.border_width_bottom = 2
	ps.corner_radius_top_left    = 12; ps.corner_radius_top_right    = 12
	ps.corner_radius_bottom_left = 12; ps.corner_radius_bottom_right = 12
	ps.shadow_color = Color(0, 0, 0, 0.6); ps.shadow_size = 16
	panel.add_theme_stylebox_override("panel", ps)
	popup.add_child(panel)

	var title = Label.new()
	title.text = "¿Abandonar la partida?"
	title.position = Vector2(0, 20)
	title.size     = Vector2(PW, 28)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(0.90, 0.35, 0.35))
	panel.add_child(title)

	var desc = Label.new()
	desc.text = "Perderás la partida y recibirás\nla pantalla de derrota."
	desc.position = Vector2(0, 58)
	desc.size     = Vector2(PW, 44)
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc.add_theme_font_size_override("font_size", 12)
	desc.add_theme_color_override("font_color", COLOR_TEXT)
	panel.add_child(desc)

	var confirm_btn = Button.new()
	confirm_btn.text     = "Sí, abandonar"
	confirm_btn.position = Vector2(PW / 2.0 - 158, PH - 50)
	confirm_btn.size     = Vector2(140, 34)
	confirm_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var cs = StyleBoxFlat.new()
	cs.bg_color     = Color(0.50, 0.07, 0.07, 0.90)
	cs.border_color = Color(0.90, 0.28, 0.28)
	cs.border_width_left = 1; cs.border_width_right  = 1
	cs.border_width_top  = 1; cs.border_width_bottom = 1
	cs.corner_radius_top_left    = 7; cs.corner_radius_top_right    = 7
	cs.corner_radius_bottom_left = 7; cs.corner_radius_bottom_right = 7
	var cs_h = cs.duplicate(); cs_h.bg_color = Color(0.65, 0.10, 0.10, 0.95)
	confirm_btn.add_theme_stylebox_override("normal", cs)
	confirm_btn.add_theme_stylebox_override("hover",  cs_h)
	confirm_btn.add_theme_color_override("font_color", Color(1, 0.75, 0.75))
	confirm_btn.add_theme_font_size_override("font_size", 12)
	confirm_btn.pressed.connect(func():
		popup.queue_free(); _forfeit_confirm = null
		_execute_forfeit()
	)
	panel.add_child(confirm_btn)

	var cancel_btn = Button.new()
	cancel_btn.text     = "Cancelar"
	cancel_btn.position = Vector2(PW / 2.0 + 18, PH - 50)
	cancel_btn.size     = Vector2(140, 34)
	cancel_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var ns = StyleBoxFlat.new()
	ns.bg_color     = Color(0, 0, 0, 0)
	ns.border_color = COLOR_GOLD_DIM
	ns.border_width_left = 1; ns.border_width_right  = 1
	ns.border_width_top  = 1; ns.border_width_bottom = 1
	ns.corner_radius_top_left    = 7; ns.corner_radius_top_right    = 7
	ns.corner_radius_bottom_left = 7; ns.corner_radius_bottom_right = 7
	var ns_h = ns.duplicate()
	ns_h.bg_color     = Color(COLOR_GOLD_DIM.r, COLOR_GOLD_DIM.g, COLOR_GOLD_DIM.b, 0.12)
	ns_h.border_color = COLOR_GOLD
	cancel_btn.add_theme_stylebox_override("normal", ns)
	cancel_btn.add_theme_stylebox_override("hover",  ns_h)
	cancel_btn.add_theme_color_override("font_color", COLOR_TEXT)
	cancel_btn.add_theme_font_size_override("font_size", 12)
	cancel_btn.pressed.connect(func():
		popup.queue_free(); _forfeit_confirm = null
	)
	panel.add_child(cancel_btn)

	panel.modulate.a = 0.0
	panel.scale      = Vector2(0.88, 0.88)
	var tw = panel.create_tween()
	tw.set_parallel(true)
	tw.tween_property(panel, "modulate:a", 1.0,         0.18)
	tw.tween_property(panel, "scale",      Vector2.ONE, 0.20) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	return popup


func _execute_forfeit() -> void:
	_stop_turn_timer()
	NetworkManager.send_action("FORFEIT", {})
	battle_log.add_message("Abandonaste la partida.")
	overlays.show_game_over_screen("Abandonaste la partida...", false)


# ============================================================
# VS BANNER
# ============================================================
func _build_vs_banner(W: float) -> Label:
	var lbl = Label.new()
	lbl.name    = "VsBanner"
	lbl.text    = ""
	lbl.z_index = 30
	lbl.position = Vector2(12, 10)
	lbl.size     = Vector2(min(W * 0.55, 600), 26)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color",         Color("#c9a84c"))
	lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	lbl.add_theme_constant_override("outline_size", 4)
	return lbl


func _update_vs_banner() -> void:
	if not _vs_banner: return
	var my_part  = _my_display_name  + (" [Tier %s]" % _my_tier  if _my_tier  != "" else "")
	var opp_part = _opp_display_name + (" [Tier %s]" % _opp_tier if _opp_tier != "" else "")
	_vs_banner.text = "%s  vs  %s" % [my_part, opp_part]


func _build_end_turn_button(W: float, H: float) -> Button:
	var btn = Button.new()
	btn.text     = "Terminar Turno"
	btn.position = Vector2(W - 200, H - 64)
	btn.size     = Vector2(184, 48)
	btn.z_index  = 10
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	var s_normal = StyleBoxFlat.new()
	s_normal.bg_color                  = Color(0.07, 0.16, 0.09, 0.95)
	s_normal.border_color              = COLOR_GOLD
	s_normal.border_width_left         = 2; s_normal.border_width_right  = 2
	s_normal.border_width_top          = 2; s_normal.border_width_bottom = 2
	s_normal.corner_radius_top_left    = 10; s_normal.corner_radius_top_right    = 10
	s_normal.corner_radius_bottom_left = 10; s_normal.corner_radius_bottom_right = 10
	s_normal.shadow_color = Color(0, 0, 0, 0.5); s_normal.shadow_size = 6
	btn.add_theme_stylebox_override("normal", s_normal)

	var s_hover = StyleBoxFlat.new()
	s_hover.bg_color                  = Color(0.14, 0.32, 0.17, 0.98)
	s_hover.border_color              = COLOR_GOLD
	s_hover.border_width_left         = 2; s_hover.border_width_right  = 2
	s_hover.border_width_top          = 2; s_hover.border_width_bottom = 2
	s_hover.corner_radius_top_left    = 10; s_hover.corner_radius_top_right    = 10
	s_hover.corner_radius_bottom_left = 10; s_hover.corner_radius_bottom_right = 10
	s_hover.shadow_color = Color(0.85, 0.72, 0.30, 0.3); s_hover.shadow_size = 10
	btn.add_theme_stylebox_override("hover", s_hover)

	var s_disabled = StyleBoxFlat.new()
	s_disabled.bg_color                  = Color(0.07, 0.07, 0.07, 0.45)
	s_disabled.border_color              = Color(0.28, 0.25, 0.15, 0.40)
	s_disabled.border_width_left         = 2; s_disabled.border_width_right  = 2
	s_disabled.border_width_top          = 2; s_disabled.border_width_bottom = 2
	s_disabled.corner_radius_top_left    = 10; s_disabled.corner_radius_top_right    = 10
	s_disabled.corner_radius_bottom_left = 10; s_disabled.corner_radius_bottom_right = 10
	btn.add_theme_stylebox_override("disabled", s_disabled)

	btn.add_theme_color_override("font_color",          COLOR_GOLD)
	btn.add_theme_color_override("font_disabled_color", Color(0.38, 0.35, 0.22, 0.45))
	btn.add_theme_font_size_override("font_size", 13)
	btn.disabled = true
	btn.pressed.connect(func(): _on_action_button("END_TURN"))
	return btn


func _build_notification_bar(W: float) -> void:
	const NOTIF_W := 260.0
	const NOTIF_H := 42.0

	_notif_container          = Control.new()
	_notif_container.name     = "NotifContainer"
	_notif_container.size     = Vector2(NOTIF_W, NOTIF_H)
	_notif_container.z_index  = 400
	_notif_container.position = Vector2(W + 10, 14)
	add_child(_notif_container)

	var panel = Panel.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	var style = StyleBoxFlat.new()
	style.bg_color                  = Color(0.05, 0.10, 0.07, 0.93)
	style.border_color              = COLOR_GOLD
	style.border_width_left         = 2; style.border_width_right  = 2
	style.border_width_top          = 2; style.border_width_bottom = 2
	style.corner_radius_top_left    = 10; style.corner_radius_top_right    = 10
	style.corner_radius_bottom_left = 10; style.corner_radius_bottom_right = 10
	style.shadow_color = Color(0, 0, 0, 0.55); style.shadow_size = 8
	panel.add_theme_stylebox_override("panel", style)
	_notif_container.add_child(panel)

	_notif_label = Label.new()
	_notif_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_notif_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_notif_label.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	_notif_label.add_theme_font_size_override("font_size", 13)
	_notif_label.add_theme_color_override("font_color", COLOR_GOLD)
	_notif_container.add_child(_notif_label)


func show_notification(text: String) -> void:
	if not _notif_container: return
	var W        = get_viewport().get_visible_rect().size.x
	var target_x = W - _notif_container.size.x - 14.0

	_notif_label.text           = text
	_notif_container.position.x = W + 10

	if _notif_tween and _notif_tween.is_valid():
		_notif_tween.kill()

	SoundManager.play("notification")
	_notif_tween = create_tween()
	_notif_tween.tween_property(_notif_container, "position:x", target_x, 0.28) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func show_coin_banner(result_text: String, reason_text: String = "", effect_text: String = "") -> void:

	var vp = get_viewport().get_visible_rect().size
	var W  = vp.x
	var H  = vp.y

	var old = get_node_or_null("CoinBanner")
	if old: old.queue_free()

	var container = Control.new()
	container.name     = "CoinBanner"
	container.z_index  = 500
	container.size     = Vector2(W, H)
	container.position = Vector2.ZERO
	add_child(container)

	var bg = ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.0)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(bg)

	const CIRCLE_R = 130.0
	const CIRCLE_D = CIRCLE_R * 2.0
	var cx = W / 2.0
	var cy = H / 2.0

	var glow = Panel.new()
	glow.size     = Vector2(CIRCLE_D + 28, CIRCLE_D + 28)
	glow.position = Vector2(cx - (CIRCLE_D + 28) / 2.0, cy - (CIRCLE_D + 28) / 2.0 - 20)
	var glow_s = StyleBoxFlat.new()
	glow_s.bg_color     = Color(COLOR_GOLD.r, COLOR_GOLD.g, COLOR_GOLD.b, 0.18)
	glow_s.border_color = Color(COLOR_GOLD.r, COLOR_GOLD.g, COLOR_GOLD.b, 0.0)
	glow_s.set_corner_radius_all(int((CIRCLE_D + 28) / 2.0))
	glow_s.anti_aliasing = true
	glow.add_theme_stylebox_override("panel", glow_s)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(glow)

	var circle = Panel.new()
	circle.name     = "CoinCircle"
	circle.size     = Vector2(CIRCLE_D, CIRCLE_D)
	circle.position = Vector2(cx - CIRCLE_R, cy - CIRCLE_R - 20)
	var c_s = StyleBoxFlat.new()
	c_s.bg_color     = Color(0.06, 0.08, 0.04, 0.97)
	c_s.border_color = COLOR_GOLD
	c_s.set_border_width_all(3)
	c_s.set_corner_radius_all(int(CIRCLE_R))
	c_s.anti_aliasing = true
	c_s.shadow_color  = Color(COLOR_GOLD.r, COLOR_GOLD.g, COLOR_GOLD.b, 0.55)
	c_s.shadow_size   = 18
	c_s.shadow_offset = Vector2(0, 4)
	circle.add_theme_stylebox_override("panel", c_s)
	circle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(circle)

	var heads = opp_coin_heads if _last_flip_was_opponent else my_coin_heads
	var tails = opp_coin_tails if _last_flip_was_opponent else my_coin_tails
	var img_path: String = heads if result_text == "¡CARA!" else tails
	var coin_img = TextureRect.new()
	coin_img.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	coin_img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	coin_img.size         = Vector2(CIRCLE_D - 24, CIRCLE_D - 24)
	coin_img.position     = Vector2(12, 12)
	coin_img.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if ResourceLoader.exists(img_path):
		coin_img.texture = load(img_path)
		circle.add_child(coin_img)
	else:
		var fallback = Label.new()
		fallback.text = "🪙"
		fallback.set_anchors_preset(Control.PRESET_FULL_RECT)
		fallback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		fallback.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		fallback.add_theme_font_size_override("font_size", 80)
		fallback.mouse_filter = Control.MOUSE_FILTER_IGNORE
		circle.add_child(fallback)

	var result_lbl = Label.new()
	result_lbl.text = result_text
	result_lbl.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	result_lbl.offset_top    = -38
	result_lbl.offset_bottom = 0
	result_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	result_lbl.add_theme_font_size_override("font_size", 22)
	result_lbl.add_theme_color_override("font_color",         COLOR_GOLD)
	result_lbl.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 1.0))
	result_lbl.add_theme_constant_override("outline_size", 5)
	result_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	circle.add_child(result_lbl)

	if reason_text != "":
		var reason_lbl = Label.new()
		reason_lbl.text = reason_text
		reason_lbl.size = Vector2(420, 32)
		reason_lbl.position = Vector2(cx - 210, cy + CIRCLE_R - 10)
		reason_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		reason_lbl.add_theme_font_size_override("font_size", 16)
		reason_lbl.add_theme_color_override("font_color",         Color(0.85, 0.82, 0.70))
		reason_lbl.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 1.0))
		reason_lbl.add_theme_constant_override("outline_size", 4)
		reason_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		container.add_child(reason_lbl)

	if effect_text != "":
		var effect_lbl = Label.new()
		effect_lbl.text = effect_text
		effect_lbl.size = Vector2(500, 32)
		effect_lbl.position = Vector2(cx - 250, cy + CIRCLE_R + 28)
		effect_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		effect_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		effect_lbl.add_theme_font_size_override("font_size", 20)
		effect_lbl.add_theme_color_override("font_color",         Color(1.0, 0.85, 0.30))
		effect_lbl.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 1.0))
		effect_lbl.add_theme_constant_override("outline_size", 5)
		effect_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		container.add_child(effect_lbl)

	circle.scale        = Vector2(0.3, 0.3)
	circle.pivot_offset = Vector2(CIRCLE_R, CIRCLE_R)
	glow.scale          = Vector2(0.3, 0.3)
	glow.pivot_offset   = Vector2((CIRCLE_D + 28) / 2.0, (CIRCLE_D + 28) / 2.0)
	container.modulate.a = 0.0

	var tw = create_tween()
	tw.set_parallel(true)
	tw.tween_property(bg,        "color",      Color(0.0, 0.0, 0.0, 0.60), 0.25)
	tw.tween_property(container, "modulate:a", 1.0,                         0.20)
	tw.tween_property(circle,    "scale",      Vector2(1.0, 1.0),           0.35) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(glow,      "scale",      Vector2(1.0, 1.0),           0.40) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	await get_tree().create_timer(3.2).timeout

	if not is_instance_valid(container): return
	var tw2 = create_tween()
	tw2.set_parallel(true)
	tw2.tween_property(container, "modulate:a", 0.0,               0.40)
	tw2.tween_property(circle,    "scale",      Vector2(0.85, 0.85), 0.40).set_trans(Tween.TRANS_SINE)
	await get_tree().create_timer(0.42).timeout
	if is_instance_valid(container):
		container.queue_free()
# ============================================================
# DETECCIÓN Y PROCESAMIENTO DE LOG DE MONEDA
# ============================================================
func _check_coin_log(msg: String) -> void:
	var lower = msg.to_lower()

	var is_coin = "heads" in lower or "tails" in lower \
		or "flip:" in lower or "– heads" in lower or "– tails" in lower \
		or "moneda:" in lower or "coin:" in lower \
		or "¡cara!" in lower or "cara!" in lower or "¡sello!" in lower \
		or "sleep check:" in lower


	if not is_coin: return

	var is_heads = "heads" in lower or "¡cara!" in lower or "cara!" in lower \
	or ("sleep check:" in lower and ("despertó" in lower or "woke" in lower))
	var is_tails = "tails" in lower or "¡sello!" in lower or "sello!" in lower \
	or ("sleep check:" in lower and ("sigue dormido" in lower or "still asleep" in lower or "no despertó" in lower))
	

	var is_first     = "moneda:" in lower and ("primero" in lower or "first" in lower)
	var is_baby      = "baby rule" in lower or "baby" in lower
	var is_trainer   = "plays " in lower and ("–" in lower or "--" in lower)
	var is_wake      = "despert" in lower or "wake"    in lower \
		or "dormid"  in lower or "asleep"   in lower or "sleep" in lower
	var is_burn      = "quemad"  in lower or "burn"    in lower
	var is_confuse   = "confus"  in lower
	var is_secondary = "secundari" in lower or "secondary" in lower \
		or "no effect" in lower or "sin efecto" in lower
	var is_power     = "pokemon power" in lower or "pokémon power" in lower \
		or "poké power" in lower or "poke power" in lower \
		or "long distance" in lower or "enviado" in lower

	var trainer_name = ""
	if is_trainer:
		var plays_idx = lower.find("plays ")
		var dash_idx  = msg.find("–")
		if plays_idx != -1 and dash_idx != -1 and dash_idx > plays_idx + 6:
			trainer_name = msg.substr(plays_idx + 6, dash_idx - plays_idx - 7).strip_edges()

	var power_name = ""
	if is_power:
		var colon_idx = msg.find(":")
		if colon_idx != -1:
			var raw = msg.substr(0, colon_idx).strip_edges()
			for prefix in ["⚡ ", "😴 ", "🔥 ", "💫 ", "☠ "]:
				if raw.begins_with(prefix):
					raw = raw.substr(prefix.length()).strip_edges()
			power_name = raw

	var reason: String
	if is_first:
		reason = "🎲  ¿Quién va primero?"
	elif is_baby:
		var baby_name = ""
		var par_open  = msg.find("(")
		var par_close = msg.find(")")
		if par_open != -1 and par_close != -1:
			baby_name = msg.substr(par_open + 1, par_close - par_open - 1)
		reason = "👶  Regla Baby — %s" % baby_name if baby_name != "" else "👶  Regla Baby"
	elif is_power and power_name != "":
		reason = "⚡  %s" % power_name
	elif is_trainer and trainer_name != "":
		reason = "🃏  %s" % trainer_name
	elif is_wake:
		reason = "💤  Intento de despertar"
	elif is_burn:
		reason = "🔥  Verificación de quemadura"
	elif is_confuse:
		reason = "💫  Verificación de confusión"
	elif is_secondary:
		reason = "⚔  Efecto secundario de ataque"
	else:
		reason = "🪙  Lanzamiento de moneda"

	var effect: String = ""

	if is_power:
		for result_word in ["¡Cara! ", "¡Sello! ", "Heads — ", "Tails — ",
							"Heads: ", "Tails: ", "Cara — ", "Sello — ",
							"Cara: ", "Sello: "]:
			var ridx = msg.find(result_word)
			if ridx != -1:
				effect = msg.substr(ridx + result_word.length()).strip_edges()
				break

	if effect == "":
		for dash in ["— ", "– ", "-- "]:
			var dash_pos = msg.rfind(dash)
			if dash_pos != -1:
				var candidate = msg.substr(dash_pos + dash.length()).strip_edges()
				if candidate.to_lower() not in ["heads", "tails", "cara", "sello"]:
					effect = candidate
				break

	if effect == "":
		if is_heads:
			if is_first:       effect = ""
			elif is_baby:      effect = "¡El ataque conecta!"
			elif is_wake:      effect = "¡Pokémon despertó!"
			elif is_burn:      effect = "¡Sigue quemado!"
			elif is_confuse:   effect = "¡Se golpeó a sí mismo!"
			elif is_secondary: effect = "¡Efecto activado!"
			else:              effect = "¡Éxito!"
		elif is_tails:
			if is_first:       effect = ""
			elif is_baby:      effect = "¡El ataque falla!"
			elif is_wake:      effect = "Sigue dormido..."
			elif is_burn:      effect = "Quemadura curada"
			elif is_confuse:   effect = "Sin efecto"
			elif is_secondary: effect = "Sin efecto secundario"
			else:              effect = "Fallo..."

	if is_first:
		var parts = msg.split(":")
		if parts.size() > 1:
			effect = parts[1].strip_edges()

	# Detectar quién lanzó
	if is_first:
		_last_flip_was_opponent = false
	elif _opp_display_name != "" and _opp_display_name in msg:
		_last_flip_was_opponent = true
	elif _my_display_name != "" and _my_display_name in msg:
		_last_flip_was_opponent = false
	else:
		_last_flip_was_opponent = not my_turn

	var result = "¡CARA!" if is_heads else ("SELLO" if is_tails else "?")
	show_coin_banner(result, reason, effect)
	
# ============================================================
# RED
# ============================================================
func _connect_network() -> void:
	if not NetworkManager: return
	NetworkManager.game_started.connect(_on_game_started)
	NetworkManager.state_updated.connect(_on_state_updated)
	NetworkManager.game_over.connect(_on_game_over)
	NetworkManager.error_received.connect(_on_error)
	NetworkManager.chat_received.connect(_on_chat_received)
	NetworkManager.spectator_chat_received.connect(_on_spectator_chat_received)
	NetworkManager.challenge_decision_received.connect(_on_challenge_decision)
	NetworkManager.challenge_pick_basics_received.connect(_on_challenge_pick_basics)
	NetworkManager.new_pokedex_peek_received.connect(_on_new_pokedex_peek)


	if not NetworkManager.pending_game_state.is_empty():
		_on_game_started(NetworkManager.pending_game_state)


func _on_chat_received(player_id: String, text: String) -> void:
	if not battle_log: return
	var is_mine = player_id == my_player_id
	var display_name: String
	if is_mine:
		display_name = _my_display_name
	elif player_id == _opp_id:
		display_name = _opp_display_name
	else:
		display_name = _clean_log(player_id)
	var color = Color("#7eb8e8") if is_mine else Color("#f5a94e")
	SoundManager.play("chat")
	battle_log.add_chat_message(display_name, text, color, is_mine)


func _on_spectator_chat_received(rid: String, _uid: String, uname: String, text: String) -> void:
	if not battle_log: return
	SoundManager.play("chat")
	battle_log.add_chat_message("👁 " + uname, text, Color("#7eb8e8"), false)


func _on_game_started(state: Dictionary) -> void:
	my_player_id = NetworkManager.player_id
	if PlayerData.get("username") != null and str(PlayerData.get("username")) != "":
		_my_display_name = str(PlayerData.get("username"))
	elif PlayerData.get("display_name") != null and str(PlayerData.get("display_name")) != "":
		_my_display_name = str(PlayerData.get("display_name"))
	else:
		_my_display_name = "Tú"
	var _pd_tier = PlayerData.get("selected_deck_tier") if PlayerData.get("selected_deck_tier") != null else ""
	_my_tier = str(state.get("my", {}).get("deck_tier", _pd_tier))
	var opp_info = state.get("opponent", {})
	_opp_id           = opp_info.get("id", "")
	_opp_display_name = opp_info.get("username",
		opp_info.get("display_name",
			opp_info.get("name", "Rival")))
	_opp_tier = str(opp_info.get("deck_tier", ""))
	if opp_info.has("sleeve_id"):
		opp_sleeve_id = opp_info.get("sleeve_id", "default")
		if renderer: renderer.set_opp_sleeve(opp_sleeve_id)

	# ── Cargar moneda propia ──
	var my_coin_id = state.get("my_coin", "default")
	if my_coin_id == null or my_coin_id == "":
		my_coin_id = "default"

	# ── Cargar moneda del rival ──
	var opp_coin_id = opp_info.get("equipped_coin", "default")
	if opp_coin_id == null or opp_coin_id == "":
		opp_coin_id = "default"



	_load_coin_textures(my_coin_id)
	_load_opp_coin_textures(opp_coin_id)

	_processed_logs_count = 0
	_last_turn_player     = ""
	_update_board(state)
	_update_vs_banner()
	if battle_log:
		SoundManager.play("game_start")
		SoundManager.play("match_begin")
		battle_log.set_chat_name(_my_display_name)
		battle_log.add_message("¡Partida iniciada!")
		

func _on_state_updated(state: Dictionary, log_arr: Array) -> void:
	var opp_info = state.get("opponent", {})
	if _opp_id == "":
		_opp_id = opp_info.get("id", "")
	var new_name = opp_info.get("username",
		opp_info.get("display_name",
			opp_info.get("name", "")))
	if new_name != "":
		var changed = new_name != _opp_display_name
		_opp_display_name = new_name
		if _opp_tier == "":
			_opp_tier = str(opp_info.get("deck_tier", ""))
		if changed: _update_vs_banner()

	var phase: String = state.get("phase", "")

	if phase != "WAITING_CHALLENGE":
		for popup_name in ["ChallengeDecision", "ChallengePick"]:
			var existing = get_node_or_null(popup_name)
			if existing:
				existing.queue_free()

	_update_board(state)

	if log_arr.size() < _processed_logs_count:
		_processed_logs_count = 0

	for i in range(_processed_logs_count, log_arr.size()):
		print("LOG RAW: ", log_arr[i])  # ← agregá esta línea
		var cleaned = _clean_log(log_arr[i])
		battle_log.add_message(cleaned)
		_check_coin_log(cleaned)
		_check_action_log(cleaned)

	_processed_logs_count = log_arr.size()



func _check_action_log(msg: String) -> void:
	var lower = msg.to_lower()

	if "knocked out" in lower or "fue derrotado" in lower or "is knocked" in lower:
		SoundManager.play("pokemon_ko")
	elif "evoluciona" in lower or "evolved" in lower or "evoluciona a" in lower:
		SoundManager.play("evolve")
	elif "attaches" in lower or "adjuntando" in lower:
		SoundManager.play("energy")
	elif "retreats" in lower or "retira" in lower:
		SoundManager.play("retreat")
	elif "drew" in lower or "robó" in lower or "draws" in lower:
		SoundManager.play("draw")
	elif "plays" in lower or "juega" in lower:
		SoundManager.play("trainer")
	elif "attacks" in lower or "ataca" in lower:
		SoundManager.play("attack")
	elif "shuffl" in lower or "baraja" in lower or "mezcla" in lower:
		SoundManager.play("shuffle")
		
# ============================================================
# GAME OVER
# ============================================================
func _on_game_over(winner: String, you_won: bool, rewards: Dictionary) -> void:
	_stop_turn_timer()

	if you_won:
		SoundManager.play("victory")

	var coins_gained: int = rewards.get("coins", 0)
	var xp_gained: int    = rewards.get("xp",    0)

	var cur_coins: int = int(PlayerData.get("coins"))          if PlayerData.get("coins")          != null else 0
	var cur_xp: int    = int(PlayerData.get("battle_pass_xp")) if PlayerData.get("battle_pass_xp") != null else 0
	var bp_level: int  = int(PlayerData.get("battle_pass_level")) if PlayerData.get("battle_pass_level") != null else 0

	PlayerData.coins          = cur_coins + coins_gained
	PlayerData.battle_pass_xp = cur_xp + xp_gained

	var bp_xp: int       = cur_xp + xp_gained
	var leveled_up: bool = false
	while bp_xp >= 1000:
		bp_xp    -= 1000
		bp_level += 1
		leveled_up = true
	PlayerData.battle_pass_xp    = bp_xp
	PlayerData.battle_pass_level = bp_level

	var result_line: String = "¡GANASTE! 🏆" if you_won else "Perdiste..."
	var reward_line: String = "🪙 +%d monedas   ⭐ +%d XP" % [coins_gained, xp_gained]
	var level_line:  String = "\n🎖 ¡Subiste al nivel %d del Pase!" % bp_level if leveled_up else ""

	overlays.show_game_over_screen(
		"%s\n\n%s%s" % [result_line, reward_line, level_line],
		you_won
	)


func _on_error(message: String) -> void:
	SoundManager.play("error")
	battle_log.add_message("⚠ " + message)
	if not current_state.is_empty():
		hand_manager.update_hand(current_state.get("my", {}).get("hand", []))
		_update_playable_mask(current_state)


# ============================================================
# LIMPIAR UUIDS DEL LOG
# ============================================================
func _clean_log(msg: String) -> String:
	if _opp_id != "" and _opp_id in msg:
		msg = msg.replace(_opp_id, _opp_display_name)
	if my_player_id != "" and my_player_id in msg:
		msg = msg.replace(my_player_id, _my_display_name)

	var all_pokemon: Array = []
	var my_data  = current_state.get("my", {})
	var opp_data = current_state.get("opponent", {})
	if my_data.get("active"):  all_pokemon.append(my_data["active"])
	if opp_data.get("active"): all_pokemon.append(opp_data["active"])
	for p in my_data.get("bench", []):
		if p: all_pokemon.append(p)
	for p in opp_data.get("bench", []):
		if p: all_pokemon.append(p)
	for p in my_data.get("discard", []):
		if p: all_pokemon.append(p)
	for p in opp_data.get("discard", []):
		if p: all_pokemon.append(p)

	for poke in all_pokemon:
		var iid = poke.get("instance_id", "")
		if iid != "" and iid in msg:
			var cdata = CardDatabase.get_card(poke.get("card_id", ""))
			var name  = cdata.get("name", poke.get("card_id", iid))
			msg = msg.replace(iid, name)

	return msg


# ============================================================
# ACTUALIZAR TABLERO
# ============================================================
func _update_board(state: Dictionary) -> void:
	print("STADIUM: ", state.get("stadium"))
	current_state = state
	my_turn       = state.get("current_player", "") == my_player_id
	var phase     = state.get("phase", "")

	renderer.render_board(state)
	hand_manager.update_hand(state.get("my", {}).get("hand", []))
	_update_playable_mask(state)
	_update_action_buttons()

	if phase_label:
		phase_label.text = phase

	var current_player = state.get("current_player", "")
	if phase == "MAIN" and current_player != _last_turn_player:
		_last_turn_player = current_player
		renderer.show_turn_banner(my_turn)
		show_notification("Tu turno" if my_turn else "Turno del rival")

		if my_turn:
			_start_turn_timer()
			SoundManager.play("my_turn")
			if _opp_timer_bar:
				_opp_timer_bar.visible = false
		else:
			_stop_turn_timer()
			SoundManager.play("opp_turn")
			var opp_time = state.get("turn_time_left", TURN_SECONDS)
			_show_opp_timer(opp_time)

	if phase == "SETUP_PLACE_ACTIVE":
		overlays.show_setup_overlay(state, my_player_id)
		overlays.update_setup_status(state)
	else:
		overlays.hide_setup_overlay()

	var my_data         = state.get("my", {})
	var waiting_promote = state.get("waiting_promote_player", null)
	var needs_promote   = (phase == "WAITING_PROMOTE") \
		and waiting_promote == my_player_id \
		and my_data.get("bench", []).size() > 0

	if needs_promote:
		overlays.show_promote_popup(my_data.get("bench", []))
	else:
		overlays.hide_promote_popup()

	overlays.check_glaring_gaze(state, my_turn)

	var march_opts = state.get("pokemon_march_options", null)
	if march_opts != null and trainer_handler:
		trainer_handler.handle_pokemon_march_options(march_opts)

	_update_bench_power_badges(state)
	_ensure_bench_click_areas()


func _on_confirm_setup() -> void:
	NetworkManager.send_action("CONFIRM_SETUP", {})
	battle_log.add_message("Confirmado, esperando al rival...")

func _on_setup_reselect_active() -> void:
	if current_state.has("my"):
		current_state["my"]["active"] = null
	NetworkManager.send_action("SETUP_DESELECT_ACTIVE", {})
	overlays.update_setup_status(current_state)
	battle_log.add_message("Elige de nuevo tu Pokémon Activo")


# ============================================================
# VISOR DE DESCARTE
# ============================================================
func _on_my_discard_clicked() -> void:
	var discard = current_state.get("my", {}).get("discard", [])
	overlays.show_discard_viewer(discard, "Mi Descarte")

func _on_opp_discard_clicked() -> void:
	var discard = current_state.get("opponent", {}).get("discard", [])
	overlays.show_discard_viewer(discard, "Descarte del Rival")


# ============================================================
# MÁSCARA DE JUGABILIDAD
# ============================================================
func _update_playable_mask(state: Dictionary) -> void:
	var my_data = state.get("my", {})
	var hand    = my_data.get("hand", [])
	var phase   = state.get("phase", "")

	if not my_turn or phase == "SETUP_PLACE_ACTIVE":
		hand_manager.clear_playable_mask()
		return

	var blocked_phases = [
		"WAITING_POKEMON_MARCH_OPPONENT",
		"WAITING_POKEMON_MARCH_PLAYER",
		"WAITING_CHALLENGE",
	]
	if phase in blocked_phases:
		hand_manager.clear_playable_mask()
		return

	var energy_used    = my_data.get("energy_played_this_turn",    false)
	var supporter_used = my_data.get("supporter_played_this_turn", false)
	var elm_used       = my_data.get("elm_played_this_turn",       false)
	var has_active     = my_data.get("active") != null
	var bench: Array   = my_data.get("bench", [])
	var mask:  Array   = []

	for i in range(hand.size()):
		var card_id   = hand[i].get("card_id", "")
		var cdata     = CardDatabase.get_card(card_id)
		var card_type = cdata.get("type", "")
		var stage     = str(cdata.get("stage", "0"))
		var playable  = false

		match card_type:
			"POKEMON":
				if stage in ["0", "baby"]:
					var bench_occupied = bench.filter(func(p): return p != null).size()
					playable = (not has_active) or (bench_occupied < 5)
				else:
					var evolves_from = cdata.get("evolves_from", "")
					if has_active and _pokemon_name_matches(
							my_data.get("active", {}).get("card_id", ""), evolves_from):
						playable = true
					if not playable:
						for bp in bench:
							if bp and _pokemon_name_matches(bp.get("card_id", ""), evolves_from):
								playable = true; break
			"ENERGY":
				var has_any = has_active or bench.any(func(p): return p != null)
				playable = (not energy_used) and has_any
			"TRAINER":
				if elm_used:
					playable = false
				else:
					var ttype = cdata.get("trainer_type", "")
					playable = not (ttype == "SUPPORTER" and supporter_used)

		mask.append(playable)

	hand_manager.set_playable_mask(mask)


# ============================================================
# DRAG & DROP
# ============================================================
func _on_hand_card_drag_started(hand_index: int, card_id: String, card_node) -> void:
	var phase = current_state.get("phase", "")
	if phase == "SETUP_PLACE_ACTIVE" or not my_turn: return
	_active_drag_card       = card_node
	_active_drag_hand_index = hand_index
	_active_drag_card_id    = card_id
	hand_manager.notify_drag_started(hand_index, card_id, card_node)
	_highlight_drop_zones(card_id)
	hand_manager.show_drag_hint(card_id, get_viewport().get_visible_rect().size)

func _on_hand_card_dropped(hand_index: int, card_id: String, drop_pos: Vector2, card_node) -> void:
	_clear_drop_highlights()
	hand_manager.hide_drag_hint()
	hand_manager.notify_drag_ended()
	_active_drag_card       = null
	_active_drag_hand_index = -1
	_active_drag_card_id    = ""

	var phase = current_state.get("phase", "")
	if phase == "SETUP_PLACE_ACTIVE": return
	if not my_turn:
		battle_log.add_message("No es tu turno"); return

	var card_data     = CardDatabase.get_card(card_id)
	var card_type     = card_data.get("type", "")
	var stage         = card_data.get("stage", 0)
	var target        = _get_zone_at_position(drop_pos)
	var drop_accepted = false

	match card_type:
		"POKEMON":
			if str(stage) == "0" or str(stage) == "baby":
				NetworkManager.play_basic(hand_index)
				battle_log.add_message("Jugando %s..." % card_data.get("name", card_id))
				drop_accepted = true
			else:
				if target.is_empty():
					battle_log.add_message("Suelta sobre un Pokémon para evolucionar")
				else:
					var evolves_from = card_data.get("evolves_from", "")
					var zone_name    = target.get("zone", "")
					var zone_idx     = target.get("index", 0)
					var target_poke  = _get_pokemon_at_zone(zone_name, zone_idx)
					if target_poke and _pokemon_name_matches(target_poke.get("card_id", ""), evolves_from):
						NetworkManager.evolve(hand_index, zone_name, zone_idx)
						battle_log.add_message("Evolucionando a %s..." % card_data.get("name", card_id))
						drop_accepted = true
					else:
						battle_log.add_message("No puedes evolucionar ahí")
		"ENERGY":
			var my_state = current_state.get("my", {})
			if my_state.get("energy_played_this_turn", false):
				battle_log.add_message("Ya jugaste una energía este turno")
				hand_manager.update_hand(current_state.get("my", {}).get("hand", []))
			elif target.is_empty():
				battle_log.add_message("Suelta la energía sobre un Pokémon")
				hand_manager.update_hand(current_state.get("my", {}).get("hand", []))
			else:
				NetworkManager.attach_energy(hand_index, target.get("zone", "active"), target.get("index", 0))
				battle_log.add_message("Adjuntando energía...")
		"TRAINER":
			trainer_handler.handle_trainer_drop(hand_index, card_id, card_data)
			if not trainer_handler.is_awaiting() and is_instance_valid(card_node):
				card_node.confirm_drop()
			return

	if drop_accepted and is_instance_valid(card_node):
		card_node.confirm_drop()


# ============================================================
# TRAINER: HIGHLIGHT DE ZONAS
# ============================================================
func _on_trainer_highlight_zones(zone_set: String) -> void:
	var COLOR_OWN = Color(0.20, 0.80, 0.95, 0.50)
	var COLOR_OPP = Color(0.95, 0.50, 0.20, 0.50)
	var COLOR_OFF = Color(0, 0, 0, 0)

	for zone in [my_active_zone, opp_active_zone] + my_bench_zones + opp_bench_zones:
		if zone: _set_zone_glow(zone, COLOR_OFF)
	_clear_zone_trainer_buttons()

	match zone_set:
		"own_pokemon":
			var md = current_state.get("my", {})
			if md.get("active"):
				_set_zone_glow(my_active_zone, COLOR_OWN)
				_make_zone_clickable(my_active_zone, "active", 0)
			var bench = md.get("bench", [])
			for i in range(bench.size()):
				if bench[i] != null:
					_set_zone_glow(my_bench_zones[i], COLOR_OWN)
					_make_zone_clickable(my_bench_zones[i], "bench", i)
		"own_bench":
			var bench = current_state.get("my", {}).get("bench", [])
			for i in range(bench.size()):
				if bench[i] != null:
					_set_zone_glow(my_bench_zones[i], COLOR_OWN)
					_make_zone_clickable(my_bench_zones[i], "bench", i)
		"opp_bench":
			var bench = current_state.get("opponent", {}).get("bench", [])
			for i in range(bench.size()):
				if bench[i] != null:
					_set_zone_glow(opp_bench_zones[i], COLOR_OPP)
					_make_zone_clickable(opp_bench_zones[i], "bench", i)
		"hand":
			battle_log.add_message("Haz click en 2 cartas de tu mano para descartar (Esc = cancelar)")
		"none":
			pass

func _make_zone_clickable(zone: Control, zone_name: String, zone_index: int) -> void:
	var btn = Button.new()
	btn.name = "TrainerClickArea"
	btn.set_anchors_preset(Control.PRESET_FULL_RECT)
	btn.flat = true
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	btn.add_theme_stylebox_override("normal",  style)
	btn.add_theme_stylebox_override("hover",   style)
	btn.add_theme_stylebox_override("pressed", style)
	btn.z_index = 10
	var zn = zone_name; var zi = zone_index
	btn.pressed.connect(func(): trainer_handler.on_zone_clicked(zn, zi))
	zone.add_child(btn)

func _clear_zone_trainer_buttons() -> void:
	for zone in [my_active_zone, opp_active_zone] + my_bench_zones + opp_bench_zones:
		if not zone: continue
		for child in zone.get_children():
			if "TrainerClickArea" in child.name:
				child.queue_free()


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
				if not current_state.get("my", {}).get("active"):
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
					if bench[i] != null: _set_zone_glow(my_bench_zones[i], COLOR_VALID)

func _set_zone_glow(zone: Control, color: Color) -> void:
	if not zone: return
	var overlay = zone.get_node_or_null("DropOverlay")
	if not overlay:
		overlay = ColorRect.new()
		overlay.name         = "DropOverlay"
		overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
		overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		overlay.z_index      = 5
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
	if zone_name == "active": return my_data.get("active")
	var bench = my_data.get("bench", [])
	if zone_idx < bench.size(): return bench[zone_idx]
	return null

func _pokemon_name_matches(card_id: String, species_name: String) -> bool:
	var data = CardDatabase.get_card(card_id)
	if data.is_empty(): return false
	return data.get("name", "").to_lower() == species_name.to_lower() \
		or card_id.begins_with(species_name.to_lower())


# ============================================================
# BOTONES DE ACCIÓN
# ============================================================
func _update_action_buttons() -> void:
	var phase = current_state.get("phase", "")
	var blocked_phases = [
		"SETUP_PLACE_ACTIVE",
		"WAITING_POKEMON_MARCH_OPPONENT",
		"WAITING_POKEMON_MARCH_PLAYER",
		"WAITING_CHALLENGE",
	]
	if end_turn_btn:
		end_turn_btn.disabled = not my_turn or phase in blocked_phases


# ============================================================
# ACCIONES DEL JUGADOR
# ============================================================
func _on_hand_card_clicked(hand_index: int) -> void:
	var phase = current_state.get("phase", "")

	var blocked_phases = [
		"WAITING_POKEMON_MARCH_OPPONENT",
		"WAITING_POKEMON_MARCH_PLAYER",
	]
	if phase in blocked_phases:
		battle_log.add_message("Espera a que se resuelva Pokémon March")
		return

	if phase == "SETUP_PLACE_ACTIVE":
		var my_data = current_state.get("my", {})
		if not my_data.get("active"):
			NetworkManager.send_action("PLACE_ACTIVE_SETUP", {"handIndex": hand_index})
			battle_log.add_message("Activo elegido (boca abajo)")
		else:
			NetworkManager.send_action("SETUP_PLACE_BENCH", {"handIndex": hand_index})
			battle_log.add_message("Pokémon agregado al banco")
		overlays.update_setup_status(current_state)
		return

	if trainer_handler.awaiting_type() == "hand_discard":
		trainer_handler.on_zone_clicked("hand", hand_index)
		return

	if trainer_handler.awaiting_type() == "hand_discard_one":
		trainer_handler.on_zone_clicked("hand", hand_index)
		return

	if action_handler.on_hand_card_clicked(hand_index):
		return

	selected_hand_index = hand_index
	hand_manager.highlight_card(hand_index)
	battle_log.add_message("Carta seleccionada: posición %d" % hand_index)


func _on_active_pokemon_clicked() -> void:
	if trainer_handler.awaiting_type() == "own_pokemon":
		trainer_handler.on_zone_clicked("active", 0)
		return
	if trainer_handler.awaiting_type() == "breeder_target":
		trainer_handler.on_zone_clicked("active", 0)
		return

	if action_handler.power_handler and action_handler.power_handler.is_active():
		return

	var active = current_state.get("my", {}).get("active")
	if not active:
		return

	var phase = current_state.get("phase", "")

	if my_turn and phase in ["MAIN", "ATTACK"]:
		overlays.show_action_zoom(active)
	else:
		overlays.open_zoom(active.get("card_id", ""), active)

func _handle_action_zoom_choice(type: String, data) -> void:
	action_handler.on_action_zoom_choice(type, data)

func _on_action_button(action: String) -> void:
	if action == "END_TURN":
		_stop_turn_timer()
	action_handler.on_action_button(action)


# ============================================================
# INPUT
# ============================================================
func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed): return
	if is_instance_valid(battle_log) and battle_log.is_chat_focused(): return

	match event.keycode:
		KEY_ESCAPE:
			var dz = _get_discard_zoom()
			if dz:
				dz.queue_free()
				get_viewport().set_input_as_handled()
				return
			if _forfeit_confirm and is_instance_valid(_forfeit_confirm):
				_forfeit_confirm.queue_free(); _forfeit_confirm = null
				get_viewport().set_input_as_handled(); return
			if overlays.bench_power_popup:    overlays.hide_bench_power_popup(); get_viewport().set_input_as_handled(); return
			if overlays.discard_viewer:       overlays.close_discard_viewer();   get_viewport().set_input_as_handled(); return
			if overlays.action_zoom_overlay:  overlays.close_action_zoom();      get_viewport().set_input_as_handled(); return
			if overlays.zoom_active:          overlays.close_zoom();             get_viewport().set_input_as_handled(); return
			if trainer_handler.is_awaiting(): trainer_handler.cancel();          get_viewport().set_input_as_handled(); return
			if action_handler.is_busy():      action_handler.cancel();           get_viewport().set_input_as_handled(); return
		KEY_SPACE:
			get_viewport().set_input_as_handled()
			if overlays.discard_viewer:      overlays.close_discard_viewer(); return
			if overlays.zoom_active:         overlays.close_zoom();           return
			if overlays.action_zoom_overlay: overlays.close_action_zoom();    return
			if selected_hand_index >= 0:     _toggle_zoom_selected_card()
		KEY_Z:
			get_viewport().set_input_as_handled()
			if overlays.zoom_active:         overlays.close_zoom();        return
			if overlays.action_zoom_overlay: overlays.close_action_zoom(); return
			_zoom_hovered_card()


func _input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.is_echo()): return
	if is_instance_valid(battle_log) and battle_log.is_chat_focused(): return

	var key = event.keycode if event.keycode != KEY_NONE else event.physical_keycode
	match key:
		KEY_ESCAPE:
			var dz = _get_discard_zoom()
			if dz:
				dz.queue_free()
				get_viewport().set_input_as_handled()
				return
			if _forfeit_confirm and is_instance_valid(_forfeit_confirm):
				_forfeit_confirm.queue_free(); _forfeit_confirm = null
				get_viewport().set_input_as_handled(); return
			if overlays.bench_power_popup:    overlays.hide_bench_power_popup(); get_viewport().set_input_as_handled(); return
			if overlays.discard_viewer:       overlays.close_discard_viewer();   get_viewport().set_input_as_handled(); return
			if overlays.action_zoom_overlay:  overlays.close_action_zoom();      get_viewport().set_input_as_handled(); return
			if overlays.zoom_active:          overlays.close_zoom();             get_viewport().set_input_as_handled(); return
			if trainer_handler.is_awaiting(): trainer_handler.cancel();          get_viewport().set_input_as_handled(); return
			if action_handler.is_busy():      action_handler.cancel();           get_viewport().set_input_as_handled(); return
		KEY_SPACE:
			get_viewport().set_input_as_handled()
			if overlays.discard_viewer:      overlays.close_discard_viewer(); return
			if overlays.zoom_active:         overlays.close_zoom();           return
			if overlays.action_zoom_overlay: overlays.close_action_zoom();    return
			if selected_hand_index >= 0:     _toggle_zoom_selected_card()
		KEY_Z:
			get_viewport().set_input_as_handled()
			if overlays.zoom_active:         overlays.close_zoom();        return
			if overlays.action_zoom_overlay: overlays.close_action_zoom(); return
			_zoom_hovered_card()
			

func _toggle_zoom_selected_card() -> void:
	var hand = current_state.get("my", {}).get("hand", [])
	if selected_hand_index < 0 or selected_hand_index >= hand.size(): return
	var card_id = hand[selected_hand_index].get("card_id", "")
	if card_id != "": overlays.open_zoom(card_id)

func _zoom_hovered_card() -> void:
	var hand_hovered_id = hand_manager.get_hovered_card_id()
	if hand_hovered_id != "":
		overlays.open_zoom(hand_hovered_id)
		return
	var board_hovered = renderer.get_hovered_pokemon_data()
	if not board_hovered.is_empty() and board_hovered.get("card_id", "") != "face_down":
		overlays.open_zoom(board_hovered.get("card_id", ""), board_hovered)
		

func _zoom_attached_card(card_id: String) -> void:
	overlays.open_zoom(card_id)

func _find_pokemon_data_by_card_id(card_id: String) -> Dictionary:
	var my_data  = current_state.get("my",       {})
	var opp_data = current_state.get("opponent", {})
	var active   = my_data.get("active")
	if active and active.get("card_id", "") == card_id: return active
	for poke in my_data.get("bench", []):
		if poke and poke.get("card_id", "") == card_id: return poke
	active = opp_data.get("active")
	if active and active.get("card_id", "") == card_id: return active
	for poke in opp_data.get("bench", []):
		if poke and poke.get("card_id", "") == card_id: return poke
	return {}


# ============================================================
# CHALLENGE! — POPUPS
# ============================================================
func _on_challenge_decision(available: Array) -> void:
	if my_turn: return
	var my_bench    = current_state.get("my", {}).get("bench", [])
	var bench_space = 5 - my_bench.filter(func(p): return p != null).size()
	var max_select  = mini(5, bench_space)
	_show_challenge_decision_popup(available, max_select)


func _on_challenge_pick_basics(available: Array, opp_placed_count: int) -> void:
	var old = get_node_or_null("ChallengeDecision")
	if old: old.queue_free()

	battle_log.add_message(
		"El rival aceptó Challenge! y colocó %d básico(s). Ahora elige los tuyos." % opp_placed_count
	)
	var my_bench    = current_state.get("my", {}).get("bench", [])
	var bench_space = 5 - my_bench.filter(func(p): return p != null).size()
	var max_select  = mini(4, bench_space)
	_show_challenge_pick_popup(available, false, max_select)


func _show_challenge_decision_popup(available: Array, max_select: int) -> void:
	var vp    := get_viewport().get_visible_rect().size
	var popup := Control.new()
	popup.name = "ChallengeDecision"
	popup.set_anchors_preset(Control.PRESET_FULL_RECT)
	popup.z_index = 250

	var dim = ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.85)
	popup.add_child(dim)

	var panel_w := 520.0
	var panel_h := 300.0
	var panel   := Panel.new()
	panel.position = Vector2((vp.x - panel_w) / 2.0, (vp.y - panel_h) / 2.0)
	panel.size     = Vector2(panel_w, panel_h)
	var ps = StyleBoxFlat.new()
	ps.bg_color = Color(0.06, 0.10, 0.08, 0.98)
	ps.border_color = COLOR_GOLD
	ps.border_width_left = 2; ps.border_width_right  = 2
	ps.border_width_top  = 2; ps.border_width_bottom = 2
	ps.corner_radius_top_left    = 14; ps.corner_radius_top_right    = 14
	ps.corner_radius_bottom_left = 14; ps.corner_radius_bottom_right = 14
	panel.add_theme_stylebox_override("panel", ps)
	popup.add_child(panel)

	var title = Label.new()
	title.text = "⚔  ¡Challenge!"
	title.position = Vector2(0, 22)
	title.size     = Vector2(panel_w, 32)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", COLOR_GOLD)
	panel.add_child(title)

	var has_basics := available.size() > 0 and max_select > 0
	var desc_text: String
	if not has_basics:
		desc_text = "El rival te desafía.\nNo tienes Básicos disponibles o tu banco está lleno\n— solo puedes rechazar."
	else:
		desc_text = "El rival te desafía.\nPuedes colocar hasta %d Pokémon Básico(s) de tu mazo en el banco.\n\nTienes %d tipo(s) disponibles." \
			% [max_select, available.size()]

	var desc = Label.new()
	desc.text = desc_text
	desc.position = Vector2(24, 68)
	desc.size     = Vector2(panel_w - 48, 110)
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc.add_theme_font_size_override("font_size", 13)
	desc.add_theme_color_override("font_color", COLOR_TEXT)
	panel.add_child(desc)

	if has_basics:
		var accept_btn = _make_challenge_button("✓  Aceptar")
		accept_btn.position = Vector2(panel_w / 2.0 - 170, panel_h - 68)
		accept_btn.size     = Vector2(150, 42)
		accept_btn.pressed.connect(func():
			popup.queue_free()
			_show_challenge_pick_popup(available, true, max_select)
		)
		panel.add_child(accept_btn)

	var reject_btn = _make_challenge_button("✕  Rechazar")
	reject_btn.position = Vector2(panel_w / 2.0 + 20, panel_h - 68)
	reject_btn.size     = Vector2(150, 42)
	reject_btn.pressed.connect(func():
		popup.queue_free()
		NetworkManager.send_action("RESOLVE_CHALLENGE", {"accept": false})
		battle_log.add_message("Rechazaste Challenge!")
	)
	panel.add_child(reject_btn)

	_animate_challenge_panel(panel)
	add_child(popup)


func _show_challenge_pick_popup(available: Array, is_opponent: bool, max_select: int) -> void:
	var vp    := get_viewport().get_visible_rect().size
	var popup := Control.new()
	popup.name = "ChallengePick"
	popup.set_anchors_preset(Control.PRESET_FULL_RECT)
	popup.z_index = 250

	var dim = ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.85)
	popup.add_child(dim)

	var panel_w: float = min(680.0, vp.x - 60)
	var panel_h: float = min(480.0, vp.y - 60)
	var panel   := Panel.new()
	panel.position = Vector2((vp.x - panel_w) / 2.0, (vp.y - panel_h) / 2.0)
	panel.size     = Vector2(panel_w, panel_h)
	var ps = StyleBoxFlat.new()
	ps.bg_color = Color(0.06, 0.10, 0.08, 0.98)
	ps.border_color = COLOR_GOLD
	ps.border_width_left = 2; ps.border_width_right  = 2
	ps.border_width_top  = 2; ps.border_width_bottom = 2
	ps.corner_radius_top_left    = 14; ps.corner_radius_top_right    = 14
	ps.corner_radius_bottom_left = 14; ps.corner_radius_bottom_right = 14
	panel.add_theme_stylebox_override("panel", ps)
	popup.add_child(panel)

	var title = Label.new()
	title.text     = "Challenge! — Elige hasta %d Básico(s) de tu mazo" % max_select
	title.position = Vector2(16, 12)
	title.size     = Vector2(panel_w - 32, 28)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", COLOR_GOLD)
	panel.add_child(title)

	var counter_lbl = Label.new()
	counter_lbl.name     = "CounterLabel"
	counter_lbl.text     = "Seleccionados: 0 / %d" % max_select
	counter_lbl.position = Vector2(0, 44)
	counter_lbl.size     = Vector2(panel_w, 20)
	counter_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	counter_lbl.add_theme_font_size_override("font_size", 12)
	counter_lbl.add_theme_color_override("font_color", COLOR_TEXT)
	panel.add_child(counter_lbl)

	var scroll = ScrollContainer.new()
	scroll.position = Vector2(12, 70)
	scroll.size     = Vector2(panel_w - 24, panel_h - 140)
	panel.add_child(scroll)

	var flow = HFlowContainer.new()
	flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	flow.add_theme_constant_override("h_separation", 12)
	flow.add_theme_constant_override("v_separation", 12)
	scroll.add_child(flow)

	var card_scale := 0.60
	var cw         := int(CARD_W * card_scale)
	var ch         := int(CARD_H * card_scale)

	var selected_slots: Dictionary = {}
	var max_sel: int = max_select

	for i in range(available.size()):
		var cid       = available[i]
		var cdata     := CardDatabase.get_card(cid)
		var cid_local := str(cid)

		var slot = Control.new()
		slot.custom_minimum_size = Vector2(cw, ch + 20)
		flow.add_child(slot)

		var slot_bg    = Panel.new()
		slot_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		var slot_style = StyleBoxFlat.new()
		slot_style.bg_color                  = Color(0.10, 0.16, 0.12, 0.9)
		slot_style.border_color              = COLOR_GOLD_DIM
		slot_style.border_width_left         = 1; slot_style.border_width_right  = 1
		slot_style.border_width_top          = 1; slot_style.border_width_bottom = 1
		slot_style.corner_radius_top_left    = 6; slot_style.corner_radius_top_right    = 6
		slot_style.corner_radius_bottom_left = 6; slot_style.corner_radius_bottom_right = 6
		slot_bg.add_theme_stylebox_override("panel", slot_style)
		slot.add_child(slot_bg)

		var card_inst = CardDatabase.create_card_instance(cid_local)
		card_inst.scale        = Vector2(card_scale, card_scale)
		card_inst.is_draggable = false
		card_inst.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card_inst.position     = Vector2.ZERO
		slot.add_child(card_inst)

		var name_lbl = Label.new()
		name_lbl.text     = cdata.get("name", cid_local)
		name_lbl.position = Vector2(0, ch + 2)
		name_lbl.size     = Vector2(cw, 16)
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.add_theme_font_size_override("font_size", 8)
		name_lbl.add_theme_color_override("font_color", COLOR_TEXT)
		slot.add_child(name_lbl)

		var check_overlay = ColorRect.new()
		check_overlay.name         = "CheckOverlay"
		check_overlay.position     = Vector2.ZERO
		check_overlay.size         = Vector2(cw, ch)
		check_overlay.color        = Color(0.2, 0.9, 0.4, 0.35)
		check_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		check_overlay.visible      = false
		slot.add_child(check_overlay)

		var check_lbl = Label.new()
		check_lbl.name     = "CheckLabel"
		check_lbl.text     = "✓"
		check_lbl.position = Vector2(cw / 2.0 - 14, ch / 2.0 - 20)
		check_lbl.size     = Vector2(28, 28)
		check_lbl.add_theme_font_size_override("font_size", 32)
		check_lbl.add_theme_color_override("font_color", Color(0.1, 0.9, 0.3))
		check_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		check_lbl.visible  = false
		slot.add_child(check_lbl)

		var btn = Button.new()
		btn.set_anchors_preset(Control.PRESET_FULL_RECT)
		btn.flat = true
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var hover_s = StyleBoxFlat.new()
		hover_s.bg_color                  = Color(1, 1, 1, 0.14)
		hover_s.corner_radius_top_left    = 6; hover_s.corner_radius_top_right    = 6
		hover_s.corner_radius_bottom_left = 6; hover_s.corner_radius_bottom_right = 6
		btn.add_theme_stylebox_override("hover", hover_s)

		btn.pressed.connect(func():
			var co  = slot.get_node_or_null("CheckOverlay")
			var cl  = slot.get_node_or_null("CheckLabel")
			var cl2 = panel.get_node_or_null("CounterLabel")

			if selected_slots.has(i):
				selected_slots.erase(i)
				if co: co.visible = false
				if cl: cl.visible = false
				slot_style.border_color = COLOR_GOLD_DIM
				slot_bg.add_theme_stylebox_override("panel", slot_style)
			elif selected_slots.size() < max_sel:
				selected_slots[i] = cid_local
				if co: co.visible = true
				if cl: cl.visible = true
				slot_style.border_color = Color(0.2, 0.9, 0.4)
				slot_bg.add_theme_stylebox_override("panel", slot_style)
			if cl2:
				cl2.text = "Seleccionados: %d / %d" % [selected_slots.size(), max_sel]
		)
		btn.mouse_entered.connect(func():
			slot.create_tween().tween_property(slot, "scale", Vector2(1.06, 1.06), 0.08)
		)
		btn.mouse_exited.connect(func():
			slot.create_tween().tween_property(slot, "scale", Vector2(1.0, 1.0), 0.08)
		)
		slot.add_child(btn)

	var btn_y: float = panel_h - 56.0

	var confirm_btn = _make_challenge_button("✓  Confirmar")
	confirm_btn.position = Vector2(panel_w / 2.0 - 170, btn_y)
	confirm_btn.size     = Vector2(150, 40)
	confirm_btn.pressed.connect(func():
		popup.queue_free()
		var final_selected_ids: Array[String] = []
		for val in selected_slots.values():
			final_selected_ids.append(val)
		if is_opponent:
			NetworkManager.send_action("RESOLVE_CHALLENGE", {"accept": true, "selectedIds": final_selected_ids})
			battle_log.add_message("Aceptaste Challenge! — colocando %d básico(s)..." % final_selected_ids.size())
		else:
			NetworkManager.send_action("RESOLVE_CHALLENGE", {"selectedIds": final_selected_ids})
			battle_log.add_message("Challenge! completado — colocaste %d básico(s)" % final_selected_ids.size())
	)
	panel.add_child(confirm_btn)

	var skip_btn = _make_challenge_button("↩  Pasar (0)")
	skip_btn.position = Vector2(panel_w / 2.0 + 20, btn_y)
	skip_btn.size     = Vector2(150, 40)
	skip_btn.pressed.connect(func():
		popup.queue_free()
		if is_opponent:
			NetworkManager.send_action("RESOLVE_CHALLENGE", {"accept": true, "selectedIds": []})
			battle_log.add_message("Aceptaste Challenge! sin colocar básicos")
		else:
			NetworkManager.send_action("RESOLVE_CHALLENGE", {"selectedIds": []})
			battle_log.add_message("Challenge! completado sin colocar básicos")
	)
	panel.add_child(skip_btn)

	_animate_challenge_panel(panel)
	add_child(popup)


func _make_challenge_button(label_text: String) -> Button:
	var btn = Button.new()
	btn.text = label_text
	var sn = StyleBoxFlat.new()
	sn.bg_color     = Color(0.12, 0.20, 0.14)
	sn.border_color = COLOR_GOLD_DIM
	sn.border_width_bottom = 1
	sn.corner_radius_top_left    = 6; sn.corner_radius_top_right    = 6
	sn.corner_radius_bottom_left = 6; sn.corner_radius_bottom_right = 6
	btn.add_theme_stylebox_override("normal", sn)
	var sh = StyleBoxFlat.new()
	sh.bg_color     = Color(0.20, 0.35, 0.22)
	sh.border_color = COLOR_GOLD
	sh.border_width_bottom = 1
	sh.corner_radius_top_left    = 6; sh.corner_radius_top_right    = 6
	sh.corner_radius_bottom_left = 6; sh.corner_radius_bottom_right = 6
	btn.add_theme_stylebox_override("hover", sh)
	btn.add_theme_color_override("font_color", COLOR_TEXT)
	btn.add_theme_font_size_override("font_size", 12)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	return btn

func _get_discard_zoom() -> Control:
	for child in overlays.board.get_children():
		if child.name.begins_with("DiscardCardZoom"):
			return child
	return null
	
func _on_new_pokedex_peek(cards: Array) -> void:
	trainer_handler.on_new_pokedex_options(cards)
	
func _animate_challenge_panel(panel: Control) -> void:
	panel.modulate.a = 0.0
	panel.scale      = Vector2(0.88, 0.88)
	var tw = panel.create_tween()
	tw.set_parallel(true)
	tw.tween_property(panel, "modulate:a", 1.0,         0.20)
	tw.tween_property(panel, "scale",      Vector2.ONE, 0.22) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
