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
var tier:              String = "C"
var battle_pass_level: int    = 1
var battle_pass_xp:    int    = 0
var has_premium_pass:  bool   = false
var role:              int    = 1
var token:             String = ""
var bubble_color_idx:  int    = 0
var claimed_bp:        Dictionary = {"free": [], "premium": []}
var medals:            Array  = []
var unopened_packs:    int    = 0

# ─── GYM ────────────────────────────────────────────────────
var gym_id:   String = ""
var gym_role: String = ""

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
	tier              = data.get("tier",     "C")
	battle_pass_level = data.get("bp_level", 1)
	battle_pass_xp    = data.get("bp_xp",    0)
	has_premium_pass  = data.get("has_premium_pass", false)
	role              = data.get("role",     1)
	bubble_color_idx  = data.get("bubble_color_idx", 0)
	unopened_packs    = data.get("unopened_packs", 0)

	# ─── GYM: proteger contra null del servidor ───────────────
	var raw_gym_id   = data.get("gym_id",   "")
	var raw_gym_role = data.get("gym_role", "")
	gym_id   = str(raw_gym_id)   if raw_gym_id   != null else ""
	gym_role = str(raw_gym_role) if raw_gym_role != null else ""
	if gym_id   == "null": gym_id   = ""
	if gym_role == "null": gym_role = ""

	if data.has("medals"):
		medals = data.get("medals", [])

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

	inventory = data.get("inventory", {})

	var raw_decks = data.get("decks", {})

	# ── DEBUG ──────────────────────────────────────────────────
	print("[PlayerData] raw_decks tipo: ", typeof(raw_decks))
	print("[PlayerData] raw_decks valor: ", raw_decks)
	# ──────────────────────────────────────────────────────────

	decks.clear()

	if typeof(raw_decks) == TYPE_ARRAY:
		print("[PlayerData] procesando como ARRAY, size: ", raw_decks.size())
		for d in raw_decks:
			print("[PlayerData] elemento: ", d)
			if typeof(d) == TYPE_DICTIONARY:
				_process_and_store_deck(d)
	elif typeof(raw_decks) == TYPE_DICTIONARY:
		print("[PlayerData] procesando como DICT, keys: ", raw_decks.keys())
		for key in raw_decks.keys():
			var d = raw_decks[key]
			print("[PlayerData] key=%s d=%s" % [str(key), str(d)])
			if typeof(d) == TYPE_DICTIONARY:
				_process_and_store_deck(d)

	is_logged_in = true
	var active_cards = get_active_deck()
	print("[PlayerData] Loaded: '%s' | role:%d | gym_id:'%s' | gym_role:'%s' | tier:%s | decks:%d | Active deck: %d" % [
		username, role, gym_id, gym_role, tier, decks.size(), active_cards.size()
	])
	print("[PlayerData] decks final: ", decks)


func _process_and_store_deck(d: Dictionary) -> void:
	var slot_raw  = d.get("slot", 1)
	var slot_str  = str(int(slot_raw))   # 1.0 → 1 → "1"
	var name_str  = d.get("name", "Mazo Nuevo")
	var raw_cards = d.get("cards", [])

	var tier_str = d.get("tier", "C")
	if not tier_str in ["C", "B", "A", "S", "SS"]:
		tier_str = "C"

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

	print("[PlayerData] _process_and_store_deck slot=%s name=%s cards=%d tier=%s" % [slot_str, name_str, clean_array.size(), tier_str])
	decks[slot_str] = {"name": name_str, "cards": clean_array, "tier": tier_str}


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

func get_deck_tier(slot: int) -> String:
	var d = decks.get(str(slot), {})
	if d is Dictionary:
		var t = d.get("tier", "C")
		return t if t in ["C", "B", "A", "S", "SS"] else "C"
	return "C"

func save_deck_local(slot: int, name: String, cards: Array, deck_tier: String = "C") -> void:
	decks[str(slot)] = {"name": name, "cards": cards, "tier": deck_tier}

func get_used_slots() -> Array:
	return decks.keys()

# ─── Helpers de GYM ─────────────────────────────────────────
func is_gym_leader() -> bool:
	return gym_role == "leader"

func is_gym_member() -> bool:
	return gym_id != "" and gym_role != ""


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
	tier              = "C"
	battle_pass_level = 1
	battle_pass_xp    = 0
	has_premium_pass  = false
	role              = 1
	token             = ""
	bubble_color_idx  = 0
	unopened_packs    = 0
	claimed_bp        = {"free": [], "premium": []}
	inventory         = {}
	decks             = {}
	medals.clear()
	gym_id            = ""
	gym_role          = ""
	active_deck_slot  = 1
	is_logged_in      = false
	NetworkManager.token     = ""
	NetworkManager.player_id = ""
	print("[PlayerData] Logged out")


# ============================================================
# API / Servidor
# ============================================================
func save_deck_to_server(slot: int, deck_name: String, cards_array: Array, deck_tier: String = "C") -> void:
	save_deck_local(slot, deck_name, cards_array, deck_tier)

	if not is_logged_in or NetworkManager.token == "":
		print("[PlayerData] Jugador no logueado o sin token. Guardado localmente.")
		return

	var http = HTTPRequest.new()
	add_child(http)

	http.request_completed.connect(func(result, response_code, _headers, body_response):
		http.queue_free()
		if response_code == 200:
			print("[PlayerData] ¡Mazo guardado en el servidor exitosamente!")
		else:
			var error_msg = body_response.get_string_from_utf8()
			print("[PlayerData] Error al guardar. Código: ", response_code, " | Motivo: ", error_msg)
	)

	var url = NetworkManager.BASE_URL + "/api/decks/save"
	var headers = [
		"Content-Type: application/json",
		"Authorization: Bearer " + NetworkManager.token
	]
	var payload = JSON.stringify({"slot": slot, "name": deck_name, "cards": cards_array, "tier": deck_tier})

	var err = http.request(url, headers, HTTPClient.METHOD_POST, payload)
	if err != OK:
		print("[PlayerData] Error al iniciar la petición HTTP: ", err)
		http.queue_free()
