extends Node

# ============================================================
# TargetSelector.gd
# Maneja el flujo: elegir acción → elegir carta de mano → elegir target
# Los Pokémon Powers ahora son responsabilidad de PokePowerHandler.gd
# ============================================================

signal target_selected(action, hand_index, zone, zone_index)
signal selection_cancelled
signal state_changed(new_state)

enum State { IDLE, WAITING_HAND, WAITING_TARGET }
enum Action { NONE, PLAY_BASIC, ATTACH_ENERGY, EVOLVE, RETREAT, ATTACK, ATTACK_WITH_TARGET }

var current_state:  State  = State.IDLE
var current_action: Action = Action.NONE
var selected_hand_index: int = -1
var _pending_attack_index:   int = -1
var board = null

const COLOR_SELECTABLE = Color(0.20, 0.85, 0.40, 0.40)
const COLOR_OPPONENT   = Color(0.95, 0.35, 0.20, 0.45)
const COLOR_INVALID    = Color(0.85, 0.20, 0.20, 0.40)
const COLOR_CLEAR      = Color(0, 0, 0, 0)

# Ataques que requieren elegir objetivo rival
const TARGETED_ATTACKS = ["Mean Look", "Feint Attack", "Telekinesis"]

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if current_state != State.IDLE:
			cancel()


# ============================================================
# API PÚBLICA
# ============================================================

func begin_play_basic() -> void:
	_set_state(State.WAITING_HAND, Action.PLAY_BASIC)
	_highlight_hand_cards(_can_play_basic)

func begin_attach_energy() -> void:
	if board.current_state.get("my", {}).get("energy_played_this_turn", false):
		board.battle_log.add_message("⚠ Ya jugaste una energía este turno")
		cancel()
		return
	_set_state(State.WAITING_HAND, Action.ATTACH_ENERGY)
	_highlight_hand_cards(_is_energy_card)

func begin_evolve() -> void:
	_set_state(State.WAITING_HAND, Action.EVOLVE)
	_highlight_hand_cards(_is_evolution_card)

func begin_retreat() -> void:
	var my_data = board.current_state.get("my", {})
	if my_data.get("retreat_performed_this_turn", false):
		board.battle_log.add_message("⚠ Ya retiraste un Pokémon este turno")
		return
	_set_state(State.WAITING_TARGET, Action.RETREAT)
	_highlight_my_bench_for_retreat()

func begin_attack_target(attack_index: int) -> void:
	_pending_attack_index = attack_index
	_set_state(State.WAITING_TARGET, Action.ATTACK_WITH_TARGET)
	board.battle_log.add_message("Elige el Pokémon objetivo del rival (Esc = cancelar)")
	_highlight_opponent_pokemon_zones()

func cancel() -> void:
	_clear_all_highlights()
	_set_state(State.IDLE, Action.NONE)
	selected_hand_index   = -1
	_pending_attack_index = -1
	emit_signal("selection_cancelled")


# ============================================================
# MANEJO DE SELECCIÓN
# ============================================================

func on_hand_card_clicked(hand_index: int, card_id: String = "") -> void:
	if current_state != State.WAITING_HAND: return

	if card_id == "":
		var hand = board.current_state.get("my", {}).get("hand", [])
		if hand_index < hand.size():
			card_id = hand[hand_index].get("card_id", "")

	match current_action:
		Action.PLAY_BASIC:
			if _can_play_basic(card_id):
				selected_hand_index = hand_index
				emit_signal("target_selected", Action.PLAY_BASIC, hand_index, "auto", 0)
				_finish_selection()
			else:
				_flash_invalid_hand(hand_index)

		Action.ATTACH_ENERGY:
			if _is_energy_card(card_id):
				selected_hand_index = hand_index
				_set_state(State.WAITING_TARGET, Action.ATTACH_ENERGY)
				_clear_all_highlights()
				_highlight_my_pokemon_zones()
			else:
				_flash_invalid_hand(hand_index)

		Action.EVOLVE:
			if _is_evolution_card(card_id):
				selected_hand_index = hand_index
				_set_state(State.WAITING_TARGET, Action.EVOLVE)
				_clear_all_highlights()
				_highlight_valid_evolution_targets(card_id)
			else:
				_flash_invalid_hand(hand_index)

func on_zone_clicked(zone: String, zone_index: int) -> void:
	if current_state != State.WAITING_TARGET: return

	if current_action == Action.ATTACK_WITH_TARGET:
		var target_index = 0
		if zone == "bench":
			target_index = zone_index + 1
		NetworkManager.send_action("ATTACK", {
			"attackIndex":        _pending_attack_index,
			"targetPokemonIndex": target_index,
		})
		board.battle_log.add_message("Ataque dirigido enviado...")
		_finish_selection()
		return

	emit_signal("target_selected", current_action, selected_hand_index, zone, zone_index)
	_finish_selection()

func _finish_selection() -> void:
	_clear_all_highlights()
	_set_state(State.IDLE, Action.NONE)
	selected_hand_index   = -1
	_pending_attack_index = -1


# ============================================================
# HIGHLIGHTS Y FILTROS
# ============================================================

func _highlight_hand_cards(filter_func: Callable) -> void:
	if not board or not board.my_hand_zone: return
	var hand = board.current_state.get("my", {}).get("hand", [])
	var i = 0
	for child in board.my_hand_zone.get_children():
		if child is ColorRect: continue
		var card_id = hand[i].get("card_id", "") if i < hand.size() else ""
		if child.has_method("set_highlighted"):
			child.set_highlighted(filter_func.call(card_id))
		else:
			_set_zone_highlight(child, COLOR_SELECTABLE if filter_func.call(card_id) else COLOR_CLEAR)
		i += 1

func _highlight_my_pokemon_zones() -> void:
	if board.my_active_zone and board.current_state.get("my", {}).get("active") != null:
		_set_zone_highlight(board.my_active_zone, COLOR_SELECTABLE)
		_connect_zone_click(board.my_active_zone, "active", 0)
	var bench = board.current_state.get("my", {}).get("bench", [])
	for i in range(5):
		if i < bench.size() and bench[i] != null:
			_set_zone_highlight(board.my_bench_zones[i], COLOR_SELECTABLE)
			_connect_zone_click(board.my_bench_zones[i], "bench", i)

func _highlight_my_bench_for_retreat() -> void:
	var bench = board.current_state.get("my", {}).get("bench", [])
	if bench.size() == 0:
		board.battle_log.add_message("⚠ No tienes Pokémon en la banca para retirar")
		cancel()
		return
	for i in range(bench.size()):
		if bench[i] != null:
			_set_zone_highlight(board.my_bench_zones[i], COLOR_SELECTABLE)
			_connect_zone_click(board.my_bench_zones[i], "bench", i)

func _highlight_opponent_pokemon_zones() -> void:
	var opp = board.current_state.get("opponent", {})
	if board.opp_active_zone and opp.get("active") != null:
		_set_zone_highlight(board.opp_active_zone, COLOR_OPPONENT)
		_connect_zone_click(board.opp_active_zone, "active", 0)
	var bench = opp.get("bench", [])
	for i in range(bench.size()):
		if bench[i] != null:
			_set_zone_highlight(board.opp_bench_zones[i], COLOR_OPPONENT)
			_connect_zone_click(board.opp_bench_zones[i], "bench", i)

func _highlight_valid_evolution_targets(evolution_card_id: String) -> void:
	var evolves_from = CardDatabase.get_card(evolution_card_id).get("evolves_from", "").to_lower()
	var active = board.current_state.get("my", {}).get("active")
	if active and _check_evolution_match(active, evolves_from):
		_set_zone_highlight(board.my_active_zone, COLOR_SELECTABLE)
		_connect_zone_click(board.my_active_zone, "active", 0)
	var bench = board.current_state.get("my", {}).get("bench", [])
	for i in range(bench.size()):
		if bench[i] and _check_evolution_match(bench[i], evolves_from):
			_set_zone_highlight(board.my_bench_zones[i], COLOR_SELECTABLE)
			_connect_zone_click(board.my_bench_zones[i], "bench", i)

func _check_evolution_match(p_data: Dictionary, evolves_from_name: String) -> bool:
	if p_data.get("first_turn", false): return false
	var base_card = CardDatabase.get_card(p_data.get("card_id", ""))
	return base_card.get("name", "").to_lower() == evolves_from_name


# ============================================================
# HELPERS VISUALES
# ============================================================

func _set_zone_highlight(zone: Control, color: Color) -> void:
	if not zone: return
	var overlay = zone.get_node_or_null("SelectOverlay")
	if not overlay:
		overlay = ColorRect.new()
		overlay.name         = "SelectOverlay"
		overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
		overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		zone.add_child(overlay)
	overlay.color = color

func _clear_all_highlights() -> void:
	if not board: return
	if board.my_hand_zone:
		for child in board.my_hand_zone.get_children():
			if child is ColorRect: continue
			if child.has_method("set_highlighted"):
				child.set_highlighted(false)
			else:
				_set_zone_highlight(child, COLOR_CLEAR)
	var all_zones = [board.my_active_zone, board.opp_active_zone] \
		+ board.my_bench_zones + board.opp_bench_zones
	for z in all_zones:
		if z:
			_set_zone_highlight(z, COLOR_CLEAR)
			var area = z.get_node_or_null("ClickArea")
			if area: area.queue_free()

func _connect_zone_click(zone: Control, zone_name: String, zone_idx: int) -> void:
	var area = zone.get_node_or_null("ClickArea")
	if not area:
		area = Button.new()
		area.name = "ClickArea"
		area.set_anchors_preset(Control.PRESET_FULL_RECT)
		area.flat = true
		area.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		zone.add_child(area)
	if area.pressed.is_connected(on_zone_clicked):
		area.pressed.disconnect(on_zone_clicked)
	area.pressed.connect(on_zone_clicked.bind(zone_name, zone_idx))

func _flash_invalid_hand(_index: int) -> void:
	board.battle_log.add_message("⚠ Esa carta no es válida para esta acción")

func _can_play_basic(card_id: String) -> bool:
	var d = CardDatabase.get_card(card_id)
	var s = str(d.get("stage", "0")).to_lower()
	return d.get("type") == "POKEMON" and (s == "0" or s == "baby")

func _is_energy_card(card_id: String) -> bool:
	return CardDatabase.get_card(card_id).get("type") == "ENERGY"

func _is_evolution_card(card_id: String) -> bool:
	var d = CardDatabase.get_card(card_id)
	return d.get("type") == "POKEMON" and int(d.get("stage", 0)) > 0

func _set_state(s: State, a: Action) -> void:
	current_state  = s
	current_action = a
	emit_signal("state_changed", s)

func is_idle() -> bool:
	return current_state == State.IDLE
