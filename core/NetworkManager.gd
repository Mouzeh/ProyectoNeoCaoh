extends Node

# ─── SEÑALES ────────────────────────────────────────────────
signal connected_to_server
signal disconnected_from_server
signal auth_ok(player_id)
signal game_started(state)
signal state_updated(state, log)
signal game_over(winner, you_won)
signal error_received(message)
signal opponent_disconnected
signal chat_received(player_id, text)
signal room_list_updated(rooms)
signal room_created(room_id)
signal room_left

# ─── CONFIGURACIÓN ──────────────────────────────────────────
const SERVER_URL      = "ws://localhost:3000"
const BASE_URL        = "http://localhost:3000"
const RECONNECT_DELAY = 3.0
const PING_INTERVAL   = 20.0
const MAX_DECK_SIZE   = 60

# ─── ESTADO ─────────────────────────────────────────────────
var socket:             WebSocketPeer = WebSocketPeer.new()
var ws_connected:       bool          = false
var player_id:          String        = ""
var token:              String        = ""
var reconnect_timer:    float         = 0.0
var should_reconnect:   bool          = false
var ping_timer:         float         = 0.0
var pending_game_state: Dictionary    = {}

var _was_in_battle: bool = false

# ============================================================
func _ready() -> void:
	print("[NetworkManager] Ready")
	connect_to_server()

func _process(delta: float) -> void:
	socket.poll()
	var state = socket.get_ready_state()

	match state:
		WebSocketPeer.STATE_OPEN:
			if not ws_connected:
				ws_connected = true
				ping_timer   = 0.0
				emit_signal("connected_to_server")
				print("[NetworkManager] Connected to server")
				if player_id != "":
					authenticate(player_id, token)
					if _was_in_battle:
						_send({"type": "RECONNECT_BATTLE"})

			while socket.get_available_packet_count() > 0:
				var packet = socket.get_packet()
				var text   = packet.get_string_from_utf8()
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
	socket = WebSocketPeer.new()
	var err = socket.connect_to_url(SERVER_URL)
	if err != OK:
		print("[NetworkManager] Failed to connect: ", err)
		reconnect_timer = RECONNECT_DELAY

func disconnect_from_server() -> void:
	should_reconnect = false
	ws_connected     = false
	_was_in_battle   = false
	socket.close()

# ─── ENVIAR ─────────────────────────────────────────────────
func _send(data: Dictionary) -> void:
	if not ws_connected:
		push_warning("[NetworkManager] _send ignorado: no conectado")
		return
	socket.send_text(JSON.stringify(data))

func send_ws(data: Dictionary) -> void:
	_send(data)

func authenticate(pid: String, tok: String = "") -> void:
	player_id = pid
	token     = tok
	_send({"type": "AUTH", "payload": {"player_id": pid, "token": tok}})

# ─── SALAS ──────────────────────────────────────────────────
func get_room_list() -> void:
	_send({"type": "GET_ROOM_LIST", "payload": {}})

func create_room(deck: Array) -> void:
	if not _validate_deck(deck, "crear mesa"): return
	_send({"type": "CREATE_ROOM", "payload": {"deck": deck}})

func join_room(room_id: String, deck: Array) -> void:
	if not _validate_deck(deck, "unirse a mesa"): return
	_send({"type": "JOIN_ROOM", "payload": {"room_id": room_id, "deck": deck}})

func leave_room() -> void:
	_send({"type": "LEAVE_ROOM", "payload": {}})

# ─── CHAT (en partida) ──────────────────────────────────────
func send_chat(text: String) -> void:
	if text.strip_edges() == "": return
	_send({"type": "CHAT", "payload": {"text": text}})

# ─── ACCIONES DE JUEGO ──────────────────────────────────────
func send_action(action_type: String, extra: Dictionary = {}) -> void:
	var payload = {"type": action_type}
	payload.merge(extra)
	_send({"type": "GAME_ACTION", "payload": payload})

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

func setup_place_active(hand_index: int) -> void:
	send_action("SETUP_ACTIVE", {"handIndex": hand_index})

func setup_place_bench(hand_index: int) -> void:
	send_action("SETUP_BENCH", {"handIndex": hand_index})

func confirm_setup() -> void:
	send_action("CONFIRM_SETUP")

func use_power(targets: Dictionary = {}) -> void:
	send_action("USE_POWER", {"targets": targets})

func resolve_glaring_gaze(hand_index: int) -> void:
	send_action("RESOLVE_GLARING_GAZE", {"targetHandIndex": hand_index})

# ─── RECIBIR ────────────────────────────────────────────────
func _handle_message(text: String) -> void:
	var json = JSON.new()
	if json.parse(text) != OK:
		push_warning("[NetworkManager] Mensaje no parseable: " + text.left(100))
		return
	var msg = json.get_data()
	if typeof(msg) != TYPE_DICTIONARY:
		push_warning("[NetworkManager] Mensaje inesperado (no dict)")
		return

	var type = msg.get("type", "")

	# ── Mensajes de chat global → redirigir al MainMenu ──
	if type.begins_with("CHAT_") or type == "BANNED":
		var main_menu = get_tree().get_first_node_in_group("main_menu")
		if main_menu and main_menu.has_method("handle_ws_message"):
			main_menu.handle_ws_message(msg)
		return

	# ── Lógica de juego ──────────────────────────────────
	match type:
		"AUTH_OK":
			emit_signal("auth_ok", msg.get("player_id", ""))
		"ROOM_LIST_UPDATE":
			emit_signal("room_list_updated", msg.get("rooms", []))
		"ROOM_CREATED":
			emit_signal("room_created", msg.get("room_id", ""))
		"ROOM_LEFT":
			_was_in_battle = false
			emit_signal("room_left")
		"GAME_START":
			print("[NetworkManager] GAME_START received")
			_was_in_battle     = true
			pending_game_state = msg.get("state", {})
			emit_signal("game_started", pending_game_state)
		"STATE_UPDATE":
			emit_signal("state_updated", msg.get("state", {}), msg.get("log", []))
		"GAME_OVER":
			_was_in_battle = false
			emit_signal("game_over", msg.get("winner", ""), msg.get("you_won", false))
		"OPPONENT_DISCONNECTED":
			emit_signal("opponent_disconnected")
		"ERROR":
			push_warning("[NetworkManager] Error del servidor: " + str(msg.get("message", "")))
			emit_signal("error_received", msg.get("message", "Error desconocido"))
		"PONG":
			pass
		"CHAT":
			emit_signal("chat_received", msg.get("player_id", "Rival"), msg.get("text", ""))

		# ── Actualización de datos del jugador en tiempo real ──
		"PLAYER_DATA_UPDATE":
			var payload = msg.get("payload", {})
			if payload.has("coins"):             PlayerData.coins             = payload["coins"]
			if payload.has("gems"):              PlayerData.gems              = payload["gems"]
			if payload.has("battle_pass_level"): PlayerData.battle_pass_level = payload["battle_pass_level"]
			if payload.has("battle_pass_xp"):    PlayerData.battle_pass_xp   = payload["battle_pass_xp"]
			if payload.has("has_premium_pass"):  PlayerData.has_premium_pass  = payload["has_premium_pass"]
			# Notificar al MainMenu para que refresque la UI
			var main_menu = get_tree().get_first_node_in_group("main_menu")
			if main_menu and main_menu.has_method("handle_ws_message"):
				main_menu.handle_ws_message(msg)

		_:
			push_warning("[NetworkManager] Tipo desconocido: " + type)

# ─── HELPERS PRIVADOS ───────────────────────────────────────
func _validate_deck(deck: Array, context: String) -> bool:
	if deck.size() != MAX_DECK_SIZE:
		var msg = "Tu mazo no está completo para %s (%d/60)." % [context, deck.size()]
		push_warning("[NetworkManager] " + msg)
		emit_signal("error_received", msg)
		return false
	return true
