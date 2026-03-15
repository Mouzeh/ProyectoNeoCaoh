extends Node2D

# ============================================================
# BattleBoard.gd — El director de orquesta
# No hace nada por sí solo. Recibe eventos de la red,
# los distribuye a los módulos correctos, y escucha sus señales.
# Es el único que habla directamente con NetworkManager.
# ============================================================

signal action_requested(action_type, params)
signal card_selected(card_node, zone, index)

# ─── MÓDULOS CORE ───────────────────────────────────────────
var overlays:         OverlayManager       = null
var renderer:         BoardRenderer        = null
var hand_manager:     HandManager          = null
var trainer_handler:  Node                 = null
var action_handler:   Node                 = null

# ─── MÓDULOS NUEVOS ─────────────────────────────────────────
var turn_timer:       TurnTimerManager     = null
var coin_banner:      CoinBannerManager    = null
var forfeit_manager:  ForfeitManager       = null
var challenge_popup:  ChallengePopupHandler = null
var drop_zones:       DropZoneManager      = null

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
var current_state:         Dictionary = {}
var my_player_id:          String     = ""
var selected_hand_index:   int        = -1
var selected_card_node                = null
var my_turn:               bool       = false
var _processed_logs_count: int        = 0
var _last_turn_player:     String     = ""

# ─── NOMBRES Y TIERS ────────────────────────────────────────
var _my_display_name:  String = "Tú"
var _opp_display_name: String = "Rival"
var _opp_id:           String = ""
var _my_tier:          String = ""
var _opp_tier:         String = ""
var _vs_banner:        Label  = null

# ─── PROTECTORES ────────────────────────────────────────────
var my_sleeve_id:  String = "default"
var opp_sleeve_id: String = "default"

# ─── DRAG EN CURSO ──────────────────────────────────────────
var _active_drag_card               = null
var _active_drag_hand_index: int    = -1
var _active_drag_card_id:    String = ""

# ─── CONSTANTES VISUALES ────────────────────────────────────
const COLOR_GOLD     = Color(0.85, 0.72, 0.30)
const COLOR_GOLD_DIM = Color(0.55, 0.45, 0.18)
const COLOR_TEXT     = Color(0.92, 0.88, 0.75)
const CARD_W         = 130
const CARD_H         = 182
const TURN_SECONDS   = 120


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

	# ── Módulos nuevos ───────────────────────────────────────
	turn_timer = TurnTimerManager.new()
	add_child(turn_timer)
	turn_timer.setup(self, vp)
	turn_timer.time_expired.connect(func():
		battle_log.add_message("⏰ Tiempo agotado — turno terminado automáticamente")
		_on_action_button("END_TURN")
	)

	forfeit_manager = ForfeitManager.new()
	add_child(forfeit_manager)
	forfeit_manager.setup(self, vp)
	forfeit_manager.forfeit_confirmed.connect(_execute_forfeit)

	coin_banner = CoinBannerManager.new()
	add_child(coin_banner)
	coin_banner.setup(self)

	challenge_popup = ChallengePopupHandler.new()
	add_child(challenge_popup)
	challenge_popup.setup(self)

	drop_zones = DropZoneManager.new()
	add_child(drop_zones)
	drop_zones.setup(my_active_zone, my_bench_zones)
	# ─────────────────────────────────────────────────────────

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


# ============================================================
# BENCH CLICK AREAS
# ============================================================
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
		btn.pressed.connect(_on_bench_pokemon_clicked.bind(i))
		zone.add_child(btn)


# ============================================================
# BENCH POKEMON CLICKED
# ============================================================
func _on_bench_pokemon_clicked(bench_index: int) -> void:
	if trainer_handler.is_awaiting():
		trainer_handler.on_zone_clicked("bench", bench_index)
		return

	if action_handler.power_handler and action_handler.power_handler.is_active():
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
	var powers_used       = state.get("powers_used_this_turn", [])
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
# VS BANNER
# ============================================================
func _build_vs_banner(W: float) -> Label:
	var lbl = Label.new()
	lbl.name     = "VsBanner"
	lbl.text     = ""
	lbl.z_index  = 30
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


# ============================================================
# BOTÓN FIN DE TURNO
# ============================================================
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


# ============================================================
# NOTIFICACIÓN DESLIZANTE
# ============================================================
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


func _on_spectator_chat_received(_rid: String, _uid: String, uname: String, text: String) -> void:
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
		opp_info.get("display_name", opp_info.get("name", "Rival")))
	_opp_tier = str(opp_info.get("deck_tier", ""))

	if opp_info.has("sleeve_id"):
		opp_sleeve_id = opp_info.get("sleeve_id", "default")
		if renderer: renderer.set_opp_sleeve(opp_sleeve_id)

	var my_coin_id  = state.get("my_coin", "default")
	if my_coin_id == null or my_coin_id == "": my_coin_id = "default"
	var opp_coin_id = opp_info.get("equipped_coin", "default")
	if opp_coin_id == null or opp_coin_id == "": opp_coin_id = "default"

	coin_banner.load_my_coin(my_coin_id)
	coin_banner.load_opp_coin(opp_coin_id)

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
		opp_info.get("display_name", opp_info.get("name", "")))
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
			if existing: existing.queue_free()

	_update_board(state)

	if log_arr.size() < _processed_logs_count:
		_processed_logs_count = 0

	for i in range(_processed_logs_count, log_arr.size()):
		var cleaned = _clean_log(log_arr[i])
		battle_log.add_message(cleaned)
		coin_banner.set_context(_my_display_name, _opp_display_name, my_turn)
		coin_banner.check_coin_log(cleaned)
		_check_action_log(cleaned)

	_processed_logs_count = log_arr.size()


func _check_action_log(msg: String) -> void:
	var lower = msg.to_lower()
	if "knocked out" in lower or "fue derrotado" in lower or "is knocked" in lower:
		SoundManager.play("pokemon_ko")
	elif "evoluciona" in lower or "evolved" in lower:
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
	turn_timer.stop_my_timer()

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

	var result_line = "¡GANASTE! 🏆" if you_won else "Perdiste..."
	var reward_line = "🪙 +%d monedas   ⭐ +%d XP" % [coins_gained, xp_gained]
	var level_line  = "\n🎖 ¡Subiste al nivel %d del Pase!" % bp_level if leveled_up else ""

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
# FORFEIT
# ============================================================
func _execute_forfeit() -> void:
	turn_timer.stop_my_timer()
	NetworkManager.send_action("FORFEIT", {})
	battle_log.add_message("Abandonaste la partida.")
	overlays.show_game_over_screen("Abandonaste la partida...", false)


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
			turn_timer.start_my_timer()
			turn_timer.hide_opp_timer()
			SoundManager.play("my_turn")
		else:
			turn_timer.stop_my_timer()
			SoundManager.play("opp_turn")
			turn_timer.show_opp_timer(state.get("turn_time_left", TURN_SECONDS))

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
	drop_zones.highlight_for_card(card_id, current_state)
	hand_manager.show_drag_hint(card_id, get_viewport().get_visible_rect().size)


func _on_hand_card_dropped(hand_index: int, card_id: String, drop_pos: Vector2, card_node) -> void:
	drop_zones.clear_highlights()
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
	var target        = drop_zones.get_zone_at_position(drop_pos)
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
		if zone: drop_zones.set_zone_glow(zone, COLOR_OFF)
	_clear_zone_trainer_buttons()

	match zone_set:
		"own_pokemon":
			var md = current_state.get("my", {})
			if md.get("active"):
				drop_zones.set_zone_glow(my_active_zone, COLOR_OWN)
				_make_zone_clickable(my_active_zone, "active", 0)
			var bench = md.get("bench", [])
			for i in range(bench.size()):
				if bench[i] != null:
					drop_zones.set_zone_glow(my_bench_zones[i], COLOR_OWN)
					_make_zone_clickable(my_bench_zones[i], "bench", i)
		"own_bench":
			var bench = current_state.get("my", {}).get("bench", [])
			for i in range(bench.size()):
				if bench[i] != null:
					drop_zones.set_zone_glow(my_bench_zones[i], COLOR_OWN)
					_make_zone_clickable(my_bench_zones[i], "bench", i)
		"opp_bench":
			var bench = current_state.get("opponent", {}).get("bench", [])
			for i in range(bench.size()):
				if bench[i] != null:
					drop_zones.set_zone_glow(opp_bench_zones[i], COLOR_OPP)
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
# HELPERS DE ZONA
# ============================================================
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
	if not active: return

	var phase = current_state.get("phase", "")
	if my_turn and phase in ["MAIN", "ATTACK"]:
		overlays.show_action_zoom(active)
	else:
		overlays.open_zoom(active.get("card_id", ""), active)


func _handle_action_zoom_choice(type: String, data) -> void:
	action_handler.on_action_zoom_choice(type, data)


func _on_action_button(action: String) -> void:
	if action == "END_TURN":
		turn_timer.stop_my_timer()
	action_handler.on_action_button(action)


# ============================================================
# CHALLENGE!
# ============================================================
func _on_challenge_decision(available: Array) -> void:
	if my_turn: return
	var my_bench    = current_state.get("my", {}).get("bench", [])
	var bench_space = 5 - my_bench.filter(func(p): return p != null).size()
	var max_select  = mini(5, bench_space)
	challenge_popup.show_decision(available, max_select)


func _on_challenge_pick_basics(available: Array, opp_placed_count: int) -> void:
	var old = get_node_or_null("ChallengeDecision")
	if old: old.queue_free()
	battle_log.add_message(
		"El rival aceptó Challenge! y colocó %d básico(s). Ahora elige los tuyos." % opp_placed_count
	)
	var my_bench    = current_state.get("my", {}).get("bench", [])
	var bench_space = 5 - my_bench.filter(func(p): return p != null).size()
	var max_select  = mini(4, bench_space)
	challenge_popup.show_pick(available, false, max_select)


# ============================================================
# INPUT
# ============================================================
func _input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.is_echo()): return
	if is_instance_valid(battle_log) and battle_log.is_chat_focused(): return

	var key = event.keycode if event.keycode != KEY_NONE else event.physical_keycode
	match key:
		KEY_ESCAPE:
			var dz = _get_discard_zoom()
			if dz:
				dz.queue_free(); get_viewport().set_input_as_handled(); return
			if forfeit_manager.has_confirm_open():
				forfeit_manager.close_confirm(); get_viewport().set_input_as_handled(); return
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


# ============================================================
# HELPERS
# ============================================================
func _get_discard_zoom() -> Control:
	for child in overlays.board.get_children():
		if child.name.begins_with("DiscardCardZoom"):
			return child
	return null


func _on_new_pokedex_peek(cards: Array) -> void:
	trainer_handler.on_new_pokedex_options(cards)
