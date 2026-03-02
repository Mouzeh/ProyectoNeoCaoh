extends Node

# ============================================================
# TestBattleState.gd
# Adjunta este script como hijo de BattleBoard.tscn para probar
# el tablero sin servidor. Eliminar en producción.
# ============================================================

func _ready() -> void:
	await get_tree().process_frame
	var board = get_parent()
	if not board or not board.has_method("_on_game_started"):
		print("[TestBattleState] ERROR: Parent no es BattleBoard")
		return

	print("[TestBattleState] Inyectando estado de prueba...")
	board.my_player_id = "jugador_1"

	var fake_state = _make_fake_state()
	board._on_game_started(fake_state)

	# Simular turno activo
	await get_tree().create_timer(0.5).timeout
	board._on_state_updated(fake_state, [
		"--- Turno 1 (jugador_1) ---",
		"jugador_1 roba una carta",
		"¡Es tu turno!",
	])

func _make_fake_state() -> Dictionary:
	return {
		"game_id": "test_game_001",
		"phase": "MAIN",
		"turn": 1,
		"current_player": "jugador_1",
		"winner": null,
		"stadium": null,

		"my": {
			"id": "jugador_1",
			"active": {
				"instance_id": "cyndaquil_1_0",
				"card_id": "cyndaquil_1",
				"damage_counters": 2,
				"attached_energy": ["fire_energy", "fire_energy"],
				"status": null,
				"tool": null,
				"first_turn": false,
				"zone": "active"
			},
			"bench": [
				{
					"instance_id": "pichu_0",
					"card_id": "pichu",
					"damage_counters": 0,
					"attached_energy": [],
					"status": null,
					"tool": null,
					"first_turn": false,
					"zone": "bench"
				},
				{
					"instance_id": "magmar_0",
					"card_id": "magmar",
					"damage_counters": 0,
					"attached_energy": ["fire_energy"],
					"status": null,
					"tool": null,
					"first_turn": false,
					"zone": "bench"
				},
				null,
				null,
				null
			],
			"hand": [
				{ "instance_id": "quilava_1_0", "card_id": "quilava_1" },
				{ "instance_id": "fire_e_0",    "card_id": "fire_energy" },
				{ "instance_id": "fire_e_1",    "card_id": "fire_energy" },
				{ "instance_id": "prof_elm_0",  "card_id": "professor_elm" },
				{ "instance_id": "pikachu_0",   "card_id": "pikachu" },
				{ "instance_id": "moo_0",       "card_id": "moo_moo_milk" },
			],
			"deck":    _make_fake_deck(40),
			"discard": [],
			"prizes":  _make_fake_deck(6),
			"energy_played_this_turn": false,
			"has_attacked_this_turn": false,
		},

		"opponent": {
			"id": "jugador_2",
			"active": {
				"instance_id": "totodile_1_0",
				"card_id": "totodile_1",
				"damage_counters": 0,
				"attached_energy": ["water_energy"],
				"status": "POISONED",
				"tool": null,
				"first_turn": false,
				"zone": "active"
			},
			"bench": [
				{
					"instance_id": "marill_0",
					"card_id": "marill",
					"damage_counters": 0,
					"attached_energy": [],
					"status": null,
					"tool": null,
					"first_turn": false,
					"zone": "bench"
				},
				null,
				null,
				null,
				null
			],
			"hand_count": 5,
			"deck_count": 38,
			"discard": [],
			"prizes_count": 6,
			"energy_played_this_turn": false,
			"has_attacked_this_turn": false,
		}
	}

func _make_fake_deck(count: int) -> Array:
	var deck = []
	for i in range(count):
		deck.append({ "instance_id": "card_" + str(i), "card_id": "fire_energy" })
	return deck
