extends Node

# ─── MÁQUINA DE ESTADOS GENERAL ─────────────────────────────
enum GameState { LOGIN, LOBBY, DECK_BUILDER, SHOP, GTS, MATCHMAKING, BATTLE }
var current_state: GameState = GameState.LOGIN

# ─── DATOS DE BATALLA ───────────────────────────────────────
var current_battle_state: Dictionary = {}
var battle_logs: Array = []
var my_side: String = "player1"

func _ready() -> void:
	NetworkManager.game_started.connect(_on_game_started)
	NetworkManager.state_updated.connect(_on_state_updated)
	NetworkManager.game_over.connect(_on_game_over)

# ─── CALLBACKS DE RED ────────────────────────────────────────
func _on_game_started(state: Dictionary) -> void:
	print("[GameManager] ¡Partida iniciada!")
	current_battle_state = state
	battle_logs.clear()
	go_to(GameState.BATTLE)
	go_to_battle()

func _on_state_updated(state: Dictionary, logs: Array) -> void:
	current_battle_state = state
	if logs.size() > 0:
		battle_logs.append_array(logs)
	get_tree().call_group("battle_ui", "update_board", current_battle_state, battle_logs)

func _on_game_over(winner: String, you_won: bool) -> void:
	print("[GameManager] Fin de la partida. Ganador: ", winner)
	get_tree().call_group("battle_ui", "show_game_over", winner, you_won)

# ─── NAVEGACIÓN ENTRE PANTALLAS ─────────────────────────────
func go_to(state: GameState) -> void:
	current_state = state
	print("[GameManager] Estado cambiado a: ", GameState.keys()[state])

func go_to_lobby() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func go_to_battle() -> void:
	# FIX: descomentado — GameManager es el único responsable de cambiar a la escena de batalla
	get_tree().change_scene_to_file("res://scenes/BattleBoard.tscn")

func go_to_shop() -> void:
	pass

func go_to_gts() -> void:
	pass

func go_to_deck_builder() -> void:
	pass
