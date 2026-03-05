extends Node

# ============================================================
# ActionHandler.gd
# ============================================================

signal action_message(text: String)
signal action_buttons_update_needed()

var board:           Node = null
var trainer_handler: Node = null
var target_selector: Node = null

func setup() -> void:
	assert(board != null, "ActionHandler: board no asignado")
	_init_target_selector()


func _init_target_selector() -> void:
	target_selector = load("res://scripts/TargetSelector.gd").new()
	target_selector.board = board
	add_child(target_selector)
	target_selector.target_selected.connect(_on_target_selected)
	target_selector.selection_cancelled.connect(_on_selection_cancelled)
	target_selector.state_changed.connect(_on_selector_state_changed)


func on_action_button(action: String) -> void:
	var phase: String = board.current_state.get("phase", "")

	if phase == "SETUP_PLACE_ACTIVE":
		if action == "CONFIRM_SETUP":
			NetworkManager.send_action("CONFIRM_SETUP", {})
			emit_signal("action_message", "Confirmado, esperando al rival...")
		return

	if not board.my_turn:
		emit_signal("action_message", "No es tu turno")
		return

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
				emit_signal("action_message", "Fin de turno")


func on_action_zoom_choice(type: String, index: int) -> void:
	match type:
		"ATTACK":
			# Verificar si este ataque necesita elegir objetivo
			var atk_name = _get_attack_name(index)
			if atk_name in target_selector.TARGETED_ATTACKS:
				emit_signal("action_message", "Elige el Pokémon objetivo del rival...")
				target_selector.begin_attack_target(index)
			else:
				NetworkManager.send_action("ATTACK", {"attackIndex": index})
		"POWER":
			_on_use_power()
		"RETREAT":
			target_selector.begin_retreat()


func on_hand_card_clicked(hand_index: int) -> bool:
	if target_selector.is_idle():
		return false
	target_selector.on_hand_card_clicked(hand_index)
	return true


func is_busy() -> bool:
	return not target_selector.is_idle()


func cancel() -> void:
	if not target_selector.is_idle():
		target_selector.cancel()


# ============================================================
# TARGET SELECTOR — CALLBACKS
# ============================================================

func _on_target_selected(action, hand_index: int, zone: String, zone_index: int) -> void:
	match action:
		target_selector.Action.PLAY_BASIC:
			NetworkManager.play_basic(hand_index)
		target_selector.Action.ATTACH_ENERGY:
			NetworkManager.attach_energy(hand_index, zone, zone_index)
		target_selector.Action.EVOLVE:
			NetworkManager.evolve(hand_index, zone, zone_index)
		target_selector.Action.RETREAT:
			NetworkManager.retreat(zone_index)
		target_selector.Action.ATTACK:
			NetworkManager.attack(zone_index)
	emit_signal("action_message", _action_to_string(action) + " enviado")


func _on_selection_cancelled() -> void:
	emit_signal("action_message", "Acción cancelada (Esc)")
	emit_signal("action_buttons_update_needed")


func _on_selector_state_changed(new_state) -> void:
	match new_state:
		1: emit_signal("action_message", "Elige una carta de tu mano (Esc = cancelar)")
		2: emit_signal("action_message", "Elige el Pokémon objetivo (Esc = cancelar)")


func _action_to_string(action) -> String:
	match action:
		target_selector.Action.PLAY_BASIC:          return "Jugar básico"
		target_selector.Action.ATTACH_ENERGY:        return "Energía"
		target_selector.Action.EVOLVE:               return "Evolución"
		target_selector.Action.RETREAT:              return "Retirada"
		target_selector.Action.ATTACK:               return "Ataque"
		target_selector.Action.ATTACK_WITH_TARGET:   return "Ataque dirigido"
	return "Acción"


# ============================================================
# HELPER — nombre del ataque activo por índice
# ============================================================

func _get_attack_name(attack_index: int) -> String:
	var active = board.current_state.get("my", {}).get("active")
	if not active: return ""
	var card_id = active.get("card_id", "")
	var cdata   = CardDatabase.get_card(card_id)
	var attacks = cdata.get("attacks", [])
	if attack_index < attacks.size():
		return attacks[attack_index].get("name", "")
	return ""


# ============================================================
# POKEMON POWERS
# ============================================================

func _on_use_power() -> void:
	var active = board.current_state.get("my", {}).get("active")
	if not active: return

	var power_name: String = str(
		active.get("pokemon_power", {}).get("name", "")
		if active.get("pokemon_power") != null else ""
	)

	match power_name:
		"Fire Recharge":
			emit_signal("action_message", "Elige el Pokémon destino para Fire Recharge...")
			trainer_handler._awaiting = "fire_recharge_target"
			trainer_handler.trainer_highlight_zones.emit("own_pokemon")

		"Downpour":
			emit_signal("action_message", "Elige el Pokémon destino para Downpour...")
			trainer_handler._awaiting = "downpour_target"
			trainer_handler.trainer_highlight_zones.emit("own_pokemon")

		_:
			# Final Blow, Glaring Gaze, Playful Punch — sin target
			NetworkManager.send_action("USE_POWER", {"sourceZone": "active"})
