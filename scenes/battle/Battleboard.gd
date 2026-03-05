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
	overlays.promote_selected.connect(func(idx):
		NetworkManager.send_action("PROMOTE", {"benchIndex": idx})
		battle_log.add_message("Promoviendo Pokémon al frente...")
	)
	overlays.glaring_gaze_resolved.connect(func(idx):
		NetworkManager.resolve_glaring_gaze(idx)
	)
	overlays.action_zoom_selected.connect(_handle_action_zoom_choice)
	
	# Aquí enviamos la señal de salir de la sala antes de ir al menú
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

	# ── Botón Terminar Turno — esquina inferior derecha ─────
	end_turn_btn = _build_end_turn_button(W, H)
	add_child(end_turn_btn)

	# ── Notificación deslizante — esquina superior derecha ──
	_build_notification_bar(W)

	# ── Battle log ──────────────────────────────────────────
	battle_log = BattleLog.new()
	battle_log.setup(W, H)
	add_child(battle_log)
	battle_log.chat_sent.connect(func(text): NetworkManager.send_chat(text))

	# ── Phase label discreto ────────────────────────────────
	phase_label = Label.new()
	phase_label.position             = Vector2(8, H - 20)
	phase_label.size                 = Vector2(200, 16)
	phase_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	phase_label.add_theme_font_size_override("font_size", 9)
	phase_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.4, 0.6))
	add_child(phase_label)


# ── Botón único Terminar Turno — esquina inferior derecha ────
func _build_end_turn_button(W: float, H: float) -> Button:
	var btn = Button.new()
	btn.text     = "⏭  Terminar Turno"
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


# ── Notificación tipo toast — esquina superior derecha ───────
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

	# Solo entra y se queda — sale cuando cambie el turno y se llame de nuevo
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

	if not NetworkManager.pending_game_state.is_empty():
		_on_game_started(NetworkManager.pending_game_state)

func _on_chat_received(player_id: String, text: String) -> void:
	if battle_log:
		battle_log.receive_chat_message(player_id, text)

func _on_game_started(state: Dictionary) -> void:
	my_player_id      = NetworkManager.player_id
	var opp_info      = state.get("opponent", {})
	if opp_info.has("sleeve_id"):
		opp_sleeve_id = opp_info.get("sleeve_id", "default")
		if renderer: renderer.set_opp_sleeve(opp_sleeve_id)
	_processed_logs_count = 0
	_last_turn_player     = ""
	_update_board(state)
	battle_log.add_message("¡Partida iniciada!")

func _on_state_updated(state: Dictionary, log_arr: Array) -> void:
	_update_board(state)
	if log_arr.size() >= _processed_logs_count:
		for i in range(_processed_logs_count, log_arr.size()):
			battle_log.add_message(log_arr[i])
		_processed_logs_count = log_arr.size()
	else:
		for entry in log_arr:
			battle_log.add_message(entry)

func _on_game_over(winner: String, you_won: bool) -> void:
	overlays.show_game_over_screen("¡GANASTE! 🏆" if you_won else "Perdiste...", you_won)

func _on_error(message: String) -> void:
	battle_log.add_message("⚠ " + message)


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

	phase_label.text = phase

	# ── Banner + notificación solo al cambiar de turno ──────
	var current_player = state.get("current_player", "")
	if phase == "MAIN" and current_player != _last_turn_player:
		_last_turn_player = current_player
		renderer.show_turn_banner(my_turn)
		show_notification("🟢  Tu turno" if my_turn else "⏳  Turno del rival")

	# ── Setup overlay ───────────────────────────────────────
	if phase == "SETUP_PLACE_ACTIVE":
		overlays.show_setup_overlay(state, my_player_id)
		overlays.update_setup_status(state)
	else:
		overlays.hide_setup_overlay()

	# ── Promote popup ───────────────────────────────────────
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


func _on_confirm_setup() -> void:
	NetworkManager.send_action("CONFIRM_SETUP", {})
	battle_log.add_message("Confirmado, esperando al rival...")


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

	var energy_used    = my_data.get("energy_played_this_turn",   false)
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
	_highlight_drop_zones(card_id)
	hand_manager.show_drag_hint(card_id, get_viewport().get_visible_rect().size)

func _on_hand_card_dropped(hand_index: int, card_id: String, drop_pos: Vector2, card_node) -> void:
	_clear_drop_highlights()
	hand_manager.hide_drag_hint()
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
						battle_log.add_message("⚠ No puedes evolucionar ahí")
		"ENERGY":
			var my_state = current_state.get("my", {})
			if my_state.get("energy_played_this_turn", false):
				battle_log.add_message("⚠ Ya jugaste una energía este turno")
			elif target.is_empty():
				battle_log.add_message("Suelta la energía sobre un Pokémon")
			else:
				NetworkManager.attach_energy(hand_index, target.get("zone", "active"), target.get("index", 0))
				battle_log.add_message("Adjuntando energía...")
				drop_accepted = true
		"TRAINER":
			trainer_handler.handle_trainer_drop(hand_index, card_id, card_data)
			drop_accepted = true

	if drop_accepted and is_instance_valid(card_node):
		card_node.confirm_drop()


# ============================================================
# TRAINER: HIGHLIGHT
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

func _update_action_buttons() -> void:
	var in_setup = current_state.get("phase", "") == "SETUP_PLACE_ACTIVE"
	if end_turn_btn:
		end_turn_btn.disabled = not my_turn or in_setup


# ============================================================
# ACCIONES DEL JUGADOR
# ============================================================
func _on_hand_card_clicked(hand_index: int) -> void:
	var phase = current_state.get("phase", "")

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

	if action_handler.on_hand_card_clicked(hand_index):
		return

	selected_hand_index = hand_index
	hand_manager.highlight_card(hand_index)
	battle_log.add_message("Carta seleccionada: posición %d" % hand_index)

func _on_active_pokemon_clicked() -> void:
	if trainer_handler.awaiting_type() == "own_pokemon":
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
