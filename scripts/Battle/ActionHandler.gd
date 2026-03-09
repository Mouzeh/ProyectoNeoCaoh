extends Node

# ============================================================
# ActionHandler.gd
# ============================================================

signal action_message(text: String)
signal action_buttons_update_needed()

var board:             Node = null
var trainer_handler:   Node = null
var target_selector:   Node = null
var power_handler:     Node = null   # ← NUEVO: PokePowerHandler

func setup() -> void:
	assert(board != null, "ActionHandler: board no asignado")
	_init_target_selector()
	_init_power_handler()   # ← NUEVO


func _init_target_selector() -> void:
	target_selector = load("res://scripts/TargetSelector.gd").new()
	target_selector.board = board
	add_child(target_selector)
	target_selector.target_selected.connect(_on_target_selected)
	target_selector.selection_cancelled.connect(_on_selection_cancelled)
	target_selector.state_changed.connect(_on_selector_state_changed)


# ── NUEVO ────────────────────────────────────────────────────
func _init_power_handler() -> void:
	power_handler = load("res://scripts/Battle/PokePowerHandler.gd").new()
	power_handler.board           = board
	power_handler.target_selector = target_selector
	add_child(power_handler)
	power_handler.power_message.connect(_on_power_message)
	power_handler.power_cancelled.connect(_on_power_cancelled)
# ─────────────────────────────────────────────────────────────


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

	# Cancelar si hay algo activo
	if power_handler.is_active():
		power_handler.cancel()
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
			if target_selector.is_idle() and not power_handler.is_active():
				NetworkManager.end_turn()
				emit_signal("action_message", "Fin de turno")


func on_action_zoom_choice(type: String, index) -> void:
	match type:
		"ATTACK":
			var attack_index: int = int(index)
			var atk_name = _get_attack_name(attack_index)
			if atk_name in target_selector.TARGETED_ATTACKS:
				emit_signal("action_message", "Elige el Pokémon objetivo del rival...")
				target_selector.begin_attack_target(attack_index)
			else:
				NetworkManager.send_action("ATTACK", {"attackIndex": attack_index})

		"POWER":
			# index ahora es el nombre del power (String)
			# OverlayManager._build_power_ui() debe emitir el nombre, no 0
			var power_name: String = str(index)
			if power_name == "" or power_name == "0":
				# Fallback: leer el power del activo actual
				power_name = _get_active_power_name()
			if power_name != "":
				power_handler.begin_power(power_name, "active", 0)
			else:
				emit_signal("action_message", "⚠ No se pudo identificar el Pokémon Power")

		"RETREAT":
			target_selector.begin_retreat()


func on_hand_card_clicked(hand_index: int) -> bool:
	if target_selector.is_idle():
		return false
	target_selector.on_hand_card_clicked(hand_index)
	return true


func is_busy() -> bool:
	return not target_selector.is_idle() or power_handler.is_active()


func cancel() -> void:
	if power_handler.is_active():
		power_handler.cancel()
	elif not target_selector.is_idle():
		target_selector.cancel()


# ============================================================
# TARGET SELECTOR — CALLBACKS
# ============================================================

func _on_target_selected(action, hand_index: int, zone: String, zone_index: int) -> void:
	match action:
		target_selector.Action.PLAY_BASIC:    NetworkManager.play_basic(hand_index)
		target_selector.Action.ATTACH_ENERGY: NetworkManager.attach_energy(hand_index, zone, zone_index)
		target_selector.Action.EVOLVE:        NetworkManager.evolve(hand_index, zone, zone_index)
		target_selector.Action.RETREAT:       NetworkManager.retreat(zone_index)
		target_selector.Action.ATTACK:        NetworkManager.attack(zone_index)
	emit_signal("action_message", _action_to_string(action) + " enviado")


func _on_selection_cancelled() -> void:
	emit_signal("action_message", "Acción cancelada (Esc)")
	emit_signal("action_buttons_update_needed")


func _on_selector_state_changed(new_state) -> void:
	match new_state:
		1: emit_signal("action_message", "Elige una carta de tu mano (Esc = cancelar)")
		2: emit_signal("action_message", "Elige el Pokémon objetivo (Esc = cancelar)")


# ── NUEVOS callbacks del PokePowerHandler ────────────────────
func _on_power_message(text: String) -> void:
	emit_signal("action_message", text)

func _on_power_cancelled() -> void:
	emit_signal("action_buttons_update_needed")
# ─────────────────────────────────────────────────────────────


func _action_to_string(action) -> String:
	match action:
		target_selector.Action.PLAY_BASIC:        return "Jugar básico"
		target_selector.Action.ATTACH_ENERGY:     return "Energía"
		target_selector.Action.EVOLVE:            return "Evolución"
		target_selector.Action.RETREAT:           return "Retirada"
		target_selector.Action.ATTACK:            return "Ataque"
		target_selector.Action.ATTACK_WITH_TARGET: return "Ataque dirigido"
	return "Acción"


# ============================================================
# HELPERS
# ============================================================

func _get_attack_name(attack_index: int) -> String:
	var active = board.current_state.get("my", {}).get("active")
	if not active: return ""
	var cdata   = CardDatabase.get_card(active.get("card_id", ""))
	var attacks = cdata.get("attacks", [])
	if attack_index < attacks.size():
		return attacks[attack_index].get("name", "")
	return ""


func _get_active_power_name() -> String:
	var active = board.current_state.get("my", {}).get("active")
	if not active: return ""
	var power = active.get("pokemon_power", null)
	if power == null: return ""
	return str(power.get("name", ""))
