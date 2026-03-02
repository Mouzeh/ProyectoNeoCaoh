extends Node

# ─── SEÑALES ────────────────────────────────────────────────
signal connected_to_server
signal disconnected_from_server
signal auth_ok(player_id)
signal queue_joined(position)
signal game_started(state)
signal state_updated(state, log)
signal game_over(winner, you_won)
signal error_received(message)
signal opponent_disconnected

# ─── CONFIGURACIÓN ──────────────────────────────────────────
const SERVER_URL = "ws://localhost:3000"
const RECONNECT_DELAY = 3.0

# ─── ESTADO ─────────────────────────────────────────────────
var socket: WebSocketPeer = WebSocketPeer.new()
var ws_connected: bool = false
var player_id: String = ""
var token: String = ""
var reconnect_timer: float = 0.0
var should_reconnect: bool = false
var ping_timer: float = 0.0
const PING_INTERVAL = 20.0

# Cache del último estado de partida (para cuando BattleBoard carga tarde)
var pending_game_state: Dictionary = {}

func _ready() -> void:
	print("[NetworkManager] Ready")

func _process(delta: float) -> void:
	socket.poll()
	var state = socket.get_ready_state()

	match state:
		WebSocketPeer.STATE_OPEN:
			if not ws_connected:
				ws_connected = true
				emit_signal("connected_to_server")
				print("[NetworkManager] Connected to server")
				if player_id != "":
					authenticate(player_id, token)

			while socket.get_available_packet_count() > 0:
				var packet = socket.get_packet()
				var text = packet.get_string_from_utf8()
				_handle_message(text)

			ping_timer += delta
			if ping_timer >= PING_INTERVAL:
				ping_timer = 0.0
				_send({"type": "PING"})

		WebSocketPeer.STATE_CLOSED:
			if ws_connected:
				ws_connected = false
				emit_signal("disconnected_from_server")
				print("[NetworkManager] Disconnected")
				if should_reconnect:
					reconnect_timer = RECONNECT_DELAY

		WebSocketPeer.STATE_CONNECTING:
			pass

	if not ws_connected and should_reconnect and reconnect_timer > 0:
		reconnect_timer -= delta
		if reconnect_timer <= 0:
			print("[NetworkManager] Reconnecting...")
			connect_to_server()

# ─── CONEXIÓN ───────────────────────────────────────────────
func connect_to_server() -> void:
	should_reconnect = true
	var err = socket.connect_to_url(SERVER_URL)
	if err != OK:
		print("[NetworkManager] Failed to connect: ", err)
		reconnect_timer = RECONNECT_DELAY

func disconnect_from_server() -> void:
	should_reconnect = false
	ws_connected = false
	socket.close()

# ─── ENVIAR ─────────────────────────────────────────────────
func _send(data: Dictionary) -> void:
	if not ws_connected:
		return
	socket.send_text(JSON.stringify(data))

func authenticate(pid: String, tok: String = "") -> void:
	player_id = pid
	token = tok
	_send({"type": "AUTH", "payload": {"player_id": pid, "token": tok}})

func join_queue(deck: Array) -> void:
	_send({"type": "JOIN_QUEUE", "payload": {"deck": deck}})

func leave_queue() -> void:
	_send({"type": "LEAVE_QUEUE", "payload": {}})

func send_action(action_type: String, extra: Dictionary = {}) -> void:
	var payload = {"type": action_type}
	payload.merge(extra)
	_send({"type": "GAME_ACTION", "payload": payload})

# ─── SHORTCUTS DE ACCIONES ──────────────────────────────────
func play_basic(hand_index: int) -> void:
	send_action("PLAY_BASIC", {"handIndex": hand_index})

func attach_energy(hand_index: int, target_zone: String, target_index: int = 0) -> void:
	send_action("ATTACH_ENERGY", {"handIndex": hand_index, "targetZone": target_zone, "targetIndex": target_index})

func evolve(hand_index: int, target_zone: String, target_index: int = 0) -> void:
	send_action("EVOLVE", {"handIndex": hand_index, "targetZone": target_zone, "targetIndex": target_index})

func retreat(bench_index: int) -> void:
	send_action("RETREAT", {"benchIndex": bench_index})

func attack(attack_index: int) -> void:
	send_action("ATTACK", {"attackIndex": attack_index})

func end_turn() -> void:
	send_action("END_TURN")

func play_trainer(hand_index: int, targets: Dictionary = {}) -> void:
	send_action("PLAY_TRAINER", {"handIndex": hand_index, "targets": targets})

func promote(bench_index: int) -> void:
	send_action("PROMOTE", {"benchIndex": bench_index})
	
# ─── RECIBIR ────────────────────────────────────────────────
func _handle_message(text: String) -> void:
	var json = JSON.new()
	if json.parse(text) != OK:
		return
	var msg = json.get_data()
	var type = msg.get("type", "")

	match type:
		"AUTH_OK":
			emit_signal("auth_ok", msg.get("player_id"))
		"QUEUE_JOINED":
			emit_signal("queue_joined", msg.get("position"))
		"GAME_START":
			print("[NetworkManager] GAME_START received, state keys: ", msg.get("state", {}).keys())
			pending_game_state = msg.get("state", {})
			emit_signal("game_started", pending_game_state)
		"STATE_UPDATE":
			emit_signal("state_updated", msg.get("state"), msg.get("log", []))
		"GAME_OVER":
			emit_signal("game_over", msg.get("winner"), msg.get("you_won", false))
		"OPPONENT_DISCONNECTED":
			emit_signal("opponent_disconnected")
		"ERROR":
			print("[NetworkManager] Error: ", msg.get("message"))
			emit_signal("error_received", msg.get("message"))
		"PONG":
			pass
		_:
			print("[NetworkManager] Unknown: ", type)
			
			# --- FASE DE SETUP ---
func setup_place_active(hand_index: int) -> void:
	send_action("SETUP_ACTIVE", {"handIndex": hand_index}) # Asegúrate de que este string coincida con tu server.js

func setup_place_bench(hand_index: int) -> void:
	send_action("SETUP_BENCH", {"handIndex": hand_index})

func confirm_setup() -> void:
	send_action("CONFIRM_SETUP")

# --- PODERES Y EXTRAS ---
func use_power(targets: Dictionary = {}) -> void:
	send_action("USE_POWER", {"targets": targets})

func resolve_glaring_gaze(hand_index: int) -> void:
	send_action("RESOLVE_GLARING_GAZE", {"targetHandIndex": hand_index})
