extends Node

# ─── MÁQUINA DE ESTADOS GENERAL ─────────────────────────────
enum GameState { LOGIN, LOBBY, DECK_BUILDER, SHOP, GTS, MATCHMAKING, BATTLE }

var current_state: GameState = GameState.LOGIN

# ─── DATOS DE BATALLA ───────────────────────────────────────
var current_battle_state: Dictionary = {}
var battle_logs:          Array      = []
var my_side:              String     = "player1"

# ─── ESCENAS ────────────────────────────────────────────────
const SCENE_MENU   = "res://scenes/MainMenu.tscn"
const SCENE_BATTLE = "res://scenes/battle/BattleBoard.tscn"

# ============================================================
func _ready() -> void:
	NetworkManager.game_started.connect(_on_game_started)
	NetworkManager.state_updated.connect(_on_state_updated)
	NetworkManager.game_over.connect(_on_game_over)
	NetworkManager.opponent_disconnected.connect(_on_opponent_disconnected)

# ─── CALLBACKS DE RED ────────────────────────────────────────
func _on_game_started(state: Dictionary) -> void:
	print("[GameManager] ¡Partida iniciada!")
	reset_battle(state)
	go_to(GameState.BATTLE)
	get_tree().change_scene_to_file(SCENE_BATTLE)

func _on_state_updated(state: Dictionary, logs: Array) -> void:
	current_battle_state = state
	if logs.size() > 0:
		battle_logs.append_array(logs)
	get_tree().call_group("battle_ui", "update_board", current_battle_state, battle_logs)

func _on_game_over(winner: String, you_won: bool) -> void:
	print("[GameManager] Fin de la partida. Ganador: ", winner)
	get_tree().call_group("battle_ui", "show_game_over", winner, you_won)
	# Limpia estado tras un frame para que la UI tenga tiempo de leerlo
	reset_battle.call_deferred({})

func _on_opponent_disconnected() -> void:
	print("[GameManager] Oponente desconectado")
	get_tree().call_group("battle_ui", "show_opponent_disconnected")

# ─── RESET DE BATALLA ────────────────────────────────────────
# Llama con un state dict al iniciar, o con {} al limpiar tras game over
func reset_battle(state: Dictionary = {}) -> void:
	current_battle_state = state
	battle_logs.clear()
	my_side = state.get("you", "player1")  # el servidor debe incluir "you"

# ─── NAVEGACIÓN ─────────────────────────────────────────────
func go_to(state: GameState) -> void:
	current_state = state
	print("[GameManager] Estado → ", GameState.keys()[state])

func go_to_lobby() -> void:
	go_to(GameState.LOBBY)
	get_tree().change_scene_to_file(SCENE_MENU)

func go_to_battle() -> void:
	go_to(GameState.BATTLE)
	get_tree().change_scene_to_file(SCENE_BATTLE)

func go_to_shop() -> void:
	go_to(GameState.SHOP)

func go_to_gts() -> void:
	go_to(GameState.GTS)

func go_to_deck_builder() -> void:
	go_to(GameState.DECK_BUILDER)
