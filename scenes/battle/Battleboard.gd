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
var current_state:          Dictionary = {}
var my_player_id:           String     = ""
var selected_hand_index:    int        = -1
var selected_card_node                 = null
var my_turn:                bool       = false
var _processed_logs_count:  int        = 0
var _last_turn_player:      String     = ""

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

# ─── DRAG EN CURSO ──────────────────────────────────────────
var _active_drag_card               = null
var _active_drag_hand_index: int    = -1
var _active_drag_card_id:    String = ""

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

	# ── Banner "J1 [Tier X]  vs  J2 [Tier Y]" ────────────────
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


# ── Banner vs ────────────────────────────────────────────────
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
	s_normal.shadow_color = Color(0, 0, 0, 0.5)
	s_normal.shadow_size  = 6
	btn.add_theme_stylebox_override("normal", s_normal)

	var s_hover = StyleBoxFlat.new()
	s_hover.bg_color                  = Color(0.14, 0.32, 0.17, 0.98)
	s_hover.border_color              = COLOR_GOLD
	s_hover.border_width_left         = 2; s_hover.border_width_right  = 2
	s_hover.border_width_top          = 2; s_hover.border_width_bottom = 2
	s_hover.corner_radius_top_left    = 10; s_hover.corner_radius_top_right    = 10
	s_hover.corner_radius_bottom_left = 10; s_hover.corner_radius_bottom_right = 10
	s_hover.shadow_color = Color(0.85, 0.72, 0.30, 0.3)
	s_hover.shadow_size  = 10
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
	style.shadow_color = Color(0, 0, 0, 0.55)
	style.shadow_size  = 8
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

	if not NetworkManager.pending_game_state.is_empty():
		_on_game_started(NetworkManager.pending_game_state)


# ── FIX: resolver UUID a nombre antes de mandar al log ──────
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
	battle_log.add_chat_message(display_name, text, color, is_mine)


func _on_spectator_chat_received(rid: String, _uid: String, uname: String, text: String) -> void:
	if not battle_log: return
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

	_processed_logs_count = 0
	_last_turn_player     = ""
	_update_board(state)
	_update_vs_banner()

	if battle_log:
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

	# ── FIX Challenge!: cerrar popups si la fase ya no es WAITING_CHALLENGE ──
	# Cuando el oponente rechaza, el servidor manda STATE_UPDATE con phase=MAIN.
	# El jugador que jugó la carta necesita que sus popups se limpien.
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
		battle_log.add_message(_clean_log(log_arr[i]))
	_processed_logs_count = log_arr.size()


func _on_game_over(winner: String, you_won: bool) -> void:
	overlays.show_game_over_screen("¡GANASTE! 🏆" if you_won else "Perdiste...", you_won)

func _on_error(message: String) -> void:
	battle_log.add_message("⚠ " + message)
	# Re-renderizar la mano para restaurar cartas de drags fallidos
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
	return msg


# ============================================================
# ACTUALIZAR TABLERO
# ============================================================
func _update_board(state: Dictionary) -> void:
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

	var active = current_state.get("my", {}).get("active")
	if not active: return

	var phase = current_state.get("phase", "")
	if my_turn and phase in ["MAIN", "ATTACK"]:
		overlays.show_action_zoom(active)
	else:
		overlays.open_zoom(active.get("card_id", ""), active)

func _handle_action_zoom_choice(type: String, index: int) -> void:
	action_handler.on_action_zoom_choice(type, index)

func _on_action_button(action: String) -> void:
	action_handler.on_action_button(action)


# ============================================================
# INPUT
# ============================================================
func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed): return
	match event.keycode:
		KEY_ESCAPE:
			if overlays.discard_viewer:       overlays.close_discard_viewer();  get_viewport().set_input_as_handled(); return
			if overlays.action_zoom_overlay:  overlays.close_action_zoom();     get_viewport().set_input_as_handled(); return
			if overlays.zoom_active:          overlays.close_zoom();            get_viewport().set_input_as_handled(); return
			if trainer_handler.is_awaiting(): trainer_handler.cancel();         get_viewport().set_input_as_handled(); return
			if action_handler.is_busy():      action_handler.cancel();          get_viewport().set_input_as_handled(); return
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
	var key = event.keycode if event.keycode != KEY_NONE else event.physical_keycode
	match key:
		KEY_ESCAPE:
			if overlays.discard_viewer:       overlays.close_discard_viewer();  get_viewport().set_input_as_handled(); return
			if overlays.action_zoom_overlay:  overlays.close_action_zoom();     get_viewport().set_input_as_handled(); return
			if overlays.zoom_active:          overlays.close_zoom();            get_viewport().set_input_as_handled(); return
			if trainer_handler.is_awaiting(): trainer_handler.cancel();         get_viewport().set_input_as_handled(); return
			if action_handler.is_busy():      action_handler.cancel();          get_viewport().set_input_as_handled(); return
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
	var board_hovered_id = renderer.get_hovered_card_id()
	if board_hovered_id != "" and board_hovered_id != "face_down":
		var pokemon_data: Dictionary = _find_pokemon_data_by_card_id(board_hovered_id)
		overlays.open_zoom(board_hovered_id, pokemon_data)

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
	# ── FIX: solo el oponente (quien NO jugó el Challenge) ve este popup ──
	# El jugador que jugó la carta tiene my_turn=true en ese momento;
	# el servidor solo manda CHALLENGE_DECISION al oponente,
	# pero por si acaso hay algún edge-case, lo filtramos aquí.
	if my_turn:
		return
	_show_challenge_decision_popup(available)

func _on_challenge_pick_basics(available: Array, opp_placed_count: int) -> void:
	battle_log.add_message("El rival aceptó Challenge! y colocó %d básico(s). Ahora elige los tuyos." % opp_placed_count)
	_show_challenge_pick_popup(available, false)


func _show_challenge_decision_popup(available: Array) -> void:
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

	var has_basics := available.size() > 0
	var desc = Label.new()
	desc.text = "El rival te desafía.\nPuedes colocar hasta 4 Pokémon Básicos de tu mazo en el banco.\n\n" + \
		("Tienes %d básico(s) disponibles." % available.size() if has_basics \
		else "No tienes Básicos en el mazo — solo puedes rechazar.")
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
			_show_challenge_pick_popup(available, true)
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


func _show_challenge_pick_popup(available: Array, is_opponent: bool) -> void:
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
	title.text     = "Challenge! — Elige hasta 4 Básicos de tu mazo"
	title.position = Vector2(16, 12)
	title.size     = Vector2(panel_w - 32, 28)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", COLOR_GOLD)
	panel.add_child(title)

	var counter_lbl = Label.new()
	counter_lbl.name     = "CounterLabel"
	counter_lbl.text     = "Seleccionados: 0 / 4"
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
	var selected_ids: Array[String] = []
	const MAX_SELECT := 4

	for cid in available:
		var cdata     := CardDatabase.get_card(cid)
		var cid_local := str(cid)

		var slot = Control.new()
		slot.custom_minimum_size = Vector2(cw, ch + 20)
		flow.add_child(slot)

		var slot_bg    = Panel.new()
		slot_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		var slot_style = StyleBoxFlat.new()
		slot_style.bg_color     = Color(0.10, 0.16, 0.12, 0.9)
		slot_style.border_color = COLOR_GOLD_DIM
		slot_style.border_width_left = 1; slot_style.border_width_right  = 1
		slot_style.border_width_top  = 1; slot_style.border_width_bottom = 1
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
		hover_s.bg_color = Color(1, 1, 1, 0.14)
		hover_s.corner_radius_top_left    = 6; hover_s.corner_radius_top_right    = 6
		hover_s.corner_radius_bottom_left = 6; hover_s.corner_radius_bottom_right = 6
		btn.add_theme_stylebox_override("hover", hover_s)

		btn.pressed.connect(func():
			var co  = slot.get_node_or_null("CheckOverlay")
			var cl  = slot.get_node_or_null("CheckLabel")
			var cl2 = panel.get_node_or_null("CounterLabel")
			if selected_ids.has(cid_local):
				selected_ids.erase(cid_local)
				if co: co.visible = false
				if cl: cl.visible = false
				slot_style.border_color = COLOR_GOLD_DIM
				slot_bg.add_theme_stylebox_override("panel", slot_style)
			elif selected_ids.size() < MAX_SELECT:
				selected_ids.append(cid_local)
				if co: co.visible = true
				if cl: cl.visible = true
				slot_style.border_color = Color(0.2, 0.9, 0.4)
				slot_bg.add_theme_stylebox_override("panel", slot_style)
			if cl2:
				cl2.text = "Seleccionados: %d / %d" % [selected_ids.size(), MAX_SELECT]
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
		if is_opponent:
			NetworkManager.send_action("RESOLVE_CHALLENGE", {"accept": true, "selectedIds": selected_ids})
			battle_log.add_message("Aceptaste Challenge! — colocando %d básico(s)..." % selected_ids.size())
		else:
			NetworkManager.send_action("RESOLVE_CHALLENGE", {"selectedIds": selected_ids})
			battle_log.add_message("Challenge! completado — colocaste %d básico(s)" % selected_ids.size())
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


func _animate_challenge_panel(panel: Control) -> void:
	panel.modulate.a = 0.0
	panel.scale      = Vector2(0.88, 0.88)
	var tw = panel.create_tween()
	tw.set_parallel(true)
	tw.tween_property(panel, "modulate:a", 1.0,         0.20)
	tw.tween_property(panel, "scale",      Vector2.ONE, 0.22) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
