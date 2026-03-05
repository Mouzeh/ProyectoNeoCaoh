extends Node

# ============================================================
# PlayerData.gd  —  Autoload
# ============================================================

# ─── Datos del jugador ──────────────────────────────────────
var player_id:         String = ""
var username:          String = ""
var coins:             int    = 0
var gems:              int    = 0
var elo:               int    = 1000
var rank:              String = "BRONZE"
var battle_pass_level: int    = 1
var battle_pass_xp:    int    = 0
var has_premium_pass:  bool   = false
var role:              int    = 1
var token:             String = ""
var bubble_color_idx:  int    = 0   # ← Color de burbuja de chat (0-7)
var claimed_bp:        Dictionary = {"free": [], "premium": []} # ← Registro del Pase de Batalla

# ─── Colección y mazos ──────────────────────────────────────
var inventory:        Dictionary = {}
var decks:            Dictionary = {}
var active_deck_slot: int        = 1

# ─── Estado ─────────────────────────────────────────────────
var is_logged_in: bool = false


# ============================================================
# Cargar desde respuesta del servidor
# ============================================================
func load_from_server(data: Dictionary) -> void:
	player_id         = data.get("id",       "")
	username          = data.get("username", "")
	coins             = data.get("coins",    0)
	gems              = data.get("gems",     0)
	elo               = data.get("elo",      1000)
	rank              = data.get("rank",     "BRONZE")
	battle_pass_level = data.get("bp_level", 1)
	battle_pass_xp    = data.get("bp_xp",    0)
	has_premium_pass  = data.get("has_premium_pass", false)
	role              = data.get("role",     1)
	bubble_color_idx  = data.get("bubble_color_idx", 0)   # ← cargar preferencia
	
	# Cargar historial del Pase de Batalla
	var raw_claimed = data.get("claimed_bp", '{"free":[], "premium":[]}')
	if typeof(raw_claimed) == TYPE_STRING:
		var json = JSON.new()
		if json.parse(raw_claimed) == OK:
			claimed_bp = json.get_data()
	elif typeof(raw_claimed) == TYPE_DICTIONARY:
		claimed_bp = raw_claimed
	else:
		claimed_bp = {"free": [], "premium": []}
		
	inventory         = data.get("inventory", {})

	var raw_decks = data.get("decks", {})
	decks.clear()

	if typeof(raw_decks) == TYPE_ARRAY:
		for d in raw_decks:
			if typeof(d) == TYPE_DICTIONARY:
				_process_and_store_deck(d)
	elif typeof(raw_decks) == TYPE_DICTIONARY:
		for key in raw_decks.keys():
			var d = raw_decks[key]
			if typeof(d) == TYPE_DICTIONARY:
				_process_and_store_deck(d)

	is_logged_in = true
	var active_cards = get_active_deck()
	print("[PlayerData] Loaded: '%s' | role:%d | bubble:%d | decks:%d | Active deck size: %d" % [username, role, bubble_color_idx, decks.size(), active_cards.size()])


func _process_and_store_deck(d: Dictionary) -> void:
	var slot_str  = str(d.get("slot", 1))
	var name_str  = d.get("name", "Mazo Nuevo")
	var raw_cards = d.get("cards", [])

	if typeof(raw_cards) == TYPE_STRING:
		var json = JSON.new()
		if json.parse(raw_cards) == OK:
			raw_cards = json.get_data()

	var clean_array = []
	if typeof(raw_cards) == TYPE_ARRAY:
		for item in raw_cards:
			if typeof(item) == TYPE_STRING:
				clean_array.append(item.strip_edges())
			elif typeof(item) == TYPE_DICTIONARY and item.has("card_id"):
				clean_array.append(str(item["card_id"]))
	elif typeof(raw_cards) == TYPE_DICTIONARY:
		for item in raw_cards.values():
			if typeof(item) == TYPE_STRING:
				clean_array.append(item.strip_edges())
			elif typeof(item) == TYPE_DICTIONARY and item.has("card_id"):
				clean_array.append(str(item["card_id"]))

	decks[slot_str] = {"name": name_str, "cards": clean_array}


# ============================================================
# Mazos
# ============================================================
func get_active_deck() -> Array:
	return get_deck(active_deck_slot)

func get_deck(slot: int) -> Array:
	var d = decks.get(str(slot), {})
	if d is Dictionary:
		return d.get("cards", [])
	return []

func get_deck_name(slot: int) -> String:
	var d = decks.get(str(slot), {})
	if d is Dictionary:
		return d.get("name", "")
	return ""

func save_deck_local(slot: int, name: String, cards: Array) -> void:
	decks[str(slot)] = {"name": name, "cards": cards}

func get_used_slots() -> Array:
	return decks.keys()


# ============================================================
# Inventario
# ============================================================
func has_card(card_id: String, amount: int = 1) -> bool:
	return get_card_count(card_id) >= amount

func get_card_count(card_id: String) -> int:
	return inventory.get(card_id, 0)

func add_card(card_id: String, amount: int = 1) -> void:
	inventory[card_id] = get_card_count(card_id) + amount

func remove_card(card_id: String, amount: int = 1) -> void:
	var current = get_card_count(card_id)
	if current <= amount:
		inventory.erase(card_id)
	else:
		inventory[card_id] = current - amount


# ============================================================
# Monedas
# ============================================================
func spend_coins(amount: int) -> bool:
	if coins < amount: return false
	coins -= amount
	return true

func add_coins(amount: int) -> void:
	coins += amount


# ============================================================
# Preferencias de chat
# ============================================================
func save_bubble_color_to_server() -> void:
	if not is_logged_in or token == "": return
	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(func(_r, _c, _h, _b): http.queue_free())
	var headers = [
		"Content-Type: application/json",
		"Authorization: Bearer " + token
	]
	http.request(
		NetworkManager.BASE_URL + "/api/player/preferences",
		headers,
		HTTPClient.METHOD_POST,
		JSON.stringify({ "bubble_color_idx": bubble_color_idx })
	)


# ============================================================
# Sesión
# ============================================================
func logout() -> void:
	player_id         = ""
	username          = ""
	coins             = 0
	gems              = 0
	elo               = 1000
	rank              = "BRONZE"
	battle_pass_level = 1
	battle_pass_xp    = 0
	has_premium_pass  = false
	role              = 1
	token             = ""
	bubble_color_idx  = 0   # ← resetear
	claimed_bp        = {"free": [], "premium": []} # ← resetear Pase de Batalla
	inventory         = {}
	decks             = {}
	active_deck_slot  = 1
	is_logged_in      = false
	NetworkManager.token     = ""
	NetworkManager.player_id = ""
	print("[PlayerData] Logged out")


# ============================================================
# API / Servidor
# ============================================================
func save_deck_to_server(slot: int, deck_name: String, cards_array: Array) -> void:
	save_deck_local(slot, deck_name, cards_array)

	if not is_logged_in or NetworkManager.token == "":
		print("[PlayerData] Jugador no logueado o sin token. Guardado localmente.")
		return

	var http = HTTPRequest.new()
	add_child(http)

	http.request_completed.connect(func(result, response_code, _headers, body):
		http.queue_free()
		if response_code == 200:
			print("[PlayerData] ¡Mazo guardado en el servidor exitosamente!")
		else:
			print("[PlayerData] Error al guardar. Código: ", response_code, " | Motivo: ", body.get_string_from_utf8())
	)

	var url     = "http://localhost:3000/api/decks/save"
	var headers = [
		"Content-Type: application/json",
		"Authorization: Bearer " + NetworkManager.token
	]
	var body = JSON.stringify({"slot": slot, "name": deck_name, "cards": cards_array})

	var err = http.request(url, headers, HTTPClient.METHOD_POST, body)
	if err != OK:
		print("[PlayerData] Error al iniciar la petición HTTP")
