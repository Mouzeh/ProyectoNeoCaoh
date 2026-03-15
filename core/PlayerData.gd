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

# ─── Monedas Personalizables ────────────────────────────────
var equipped_coin:     String = "default"

# ─── Slots de mazo desbloqueados (mínimo 3, máximo 6) ───────
var deck_slots: int = 3

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
# Normaliza una lista de claimed a Array[int] siempre
# ============================================================
static func _normalize_bp_list(raw: Array) -> Array:
	var result: Array = []
	for item in raw:
		var v = int(item)
		if not result.has(v):
			result.append(v)
	return result

static func _normalize_claimed_bp(raw: Dictionary) -> Dictionary:
	var out = {"free": [], "premium": []}
	if raw.has("free")    and typeof(raw["free"])    == TYPE_ARRAY:
		out["free"]    = _normalize_bp_list(raw["free"])
	if raw.has("premium") and typeof(raw["premium"]) == TYPE_ARRAY:
		out["premium"] = _normalize_bp_list(raw["premium"])
	return out


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

	# ── Slots desbloqueados — debe cargarse ANTES de active_deck_slot
	deck_slots = int(data.get("deck_slots", 3))
	deck_slots = clampi(deck_slots, 3, 6)

	var raw_slot = data.get("active_deck_slot", 1)
	active_deck_slot = int(raw_slot) if raw_slot != null else 1
	if active_deck_slot < 1 or active_deck_slot > deck_slots:
		active_deck_slot = 1

	var raw_gym_id   = data.get("gym_id",   null)
	var raw_gym_role = data.get("gym_role", null)
	if raw_gym_id == null or typeof(raw_gym_id) == TYPE_DICTIONARY or typeof(raw_gym_id) == TYPE_ARRAY:
		gym_id = ""
	else:
		gym_id = str(raw_gym_id)
		if gym_id == "null" or gym_id == "<null>": gym_id = ""
	if raw_gym_role == null or typeof(raw_gym_role) == TYPE_DICTIONARY or typeof(raw_gym_role) == TYPE_ARRAY:
		gym_role = ""
	else:
		gym_role = str(raw_gym_role)
		if gym_role == "null" or gym_role == "<null>": gym_role = ""

	if data.has("medals"):
		medals = data.get("medals", [])

	var raw_claimed = data.get("claimed_bp", null)
	print("[PlayerData] claimed_bp raw tipo=", typeof(raw_claimed), " valor=", raw_claimed)

	var parsed_claimed: Dictionary = {"free": [], "premium": []}

	if raw_claimed == null or (typeof(raw_claimed) == TYPE_STRING and raw_claimed == ""):
		parsed_claimed = {"free": [], "premium": []}
	elif typeof(raw_claimed) == TYPE_STRING:
		var json = JSON.new()
		var err = json.parse(raw_claimed)
		if err == OK and typeof(json.get_data()) == TYPE_DICTIONARY:
			parsed_claimed = json.get_data()
		else:
			print("[PlayerData] ERROR parseando claimed_bp string: ", err)
	elif typeof(raw_claimed) == TYPE_DICTIONARY:
		parsed_claimed = raw_claimed
	else:
		print("[PlayerData] claimed_bp tipo inesperado: ", typeof(raw_claimed))

	claimed_bp = _normalize_claimed_bp(parsed_claimed)
	print("[PlayerData] claimed_bp normalizado: ", claimed_bp)

	inventory = data.get("inventory", {})

	var raw_decks = data.get("decks", {})

	print("[PlayerData] raw_decks tipo: ", typeof(raw_decks))
	print("[PlayerData] raw_decks valor: ", raw_decks)

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
	
	# ─── Cargar moneda equipada desde el servidor en segundo plano ───
	_fetch_equipped_coin_from_server()
	
	var active_cards = get_active_deck()
	print("[PlayerData] Loaded: '%s' | role:%d | gym_id:'%s' | gym_role:'%s' | tier:%s | decks:%d | active_slot:%d | deck_slots:%d | Active deck: %d" % [
		username, role, gym_id, gym_role, tier, decks.size(), active_deck_slot, deck_slots, active_cards.size()
	])
	print("[PlayerData] decks final: ", decks)


func _fetch_equipped_coin_from_server() -> void:
	if NetworkManager.token == "": return
	
	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(func(result, code, _h, body):
		http.queue_free()
		if result == HTTPRequest.RESULT_SUCCESS and code == 200:
			var json_data = JSON.parse_string(body.get_string_from_utf8())
			if json_data and json_data.has("equipped"):
				equipped_coin = json_data["equipped"]
				print("[PlayerData] Moneda equipada sincronizada: ", equipped_coin)
	)
	http.request(
		NetworkManager.BASE_URL + "/api/shop/my-coins",
		["Authorization: Bearer " + NetworkManager.token],
		HTTPClient.METHOD_GET, ""
	)


func _process_and_store_deck(d: Dictionary) -> void:
	var slot_raw  = d.get("slot", 1)
	var slot_str  = str(int(slot_raw))
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

	var raw_featured = d.get("featured_cards", [])
	if typeof(raw_featured) == TYPE_STRING:
		var json2 = JSON.new()
		if json2.parse(raw_featured) == OK:
			raw_featured = json2.get_data()

	var featured_array : Array = []
	if typeof(raw_featured) == TYPE_ARRAY:
		for item in raw_featured:
			if typeof(item) == TYPE_STRING:
				featured_array.append(item.strip_edges())

	var validated_featured : Array = []
	for fid in featured_array:
		if fid in clean_array:
			validated_featured.append(fid)
	if validated_featured.size() > 3:
		validated_featured = validated_featured.slice(0, 3)

	print("[PlayerData] _process_and_store_deck slot=%s name=%s cards=%d tier=%s featured=%d" % [
		slot_str, name_str, clean_array.size(), tier_str, validated_featured.size()
	])

	decks[slot_str] = {
		"name":           name_str,
		"cards":          clean_array,
		"tier":           tier_str,
		"featured_cards": validated_featured,
	}


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

func get_deck_featured(slot: int) -> Array:
	var d = decks.get(str(slot), {})
	if d is Dictionary:
		return d.get("featured_cards", [])
	return []

func set_deck_featured_local(slot: int, featured: Array) -> void:
	var d = decks.get(str(slot), {})
	if d is Dictionary:
		d["featured_cards"] = featured
		decks[str(slot)] = d

func save_deck_local(slot: int, name: String, cards: Array,
		deck_tier: String = "C", featured: Array = [], preserve_featured: bool = false) -> void:
	var final_featured : Array
	if preserve_featured:
		final_featured = get_deck_featured(slot)
	else:
		final_featured = featured
		if final_featured.size() > 3:
			final_featured = final_featured.slice(0, 3)

	decks[str(slot)] = {
		"name":           name,
		"cards":          cards,
		"tier":           deck_tier,
		"featured_cards": final_featured,
	}

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
	deck_slots        = 3
	equipped_coin     = "default" # <-- Reset al salir
	is_logged_in      = false
	NetworkManager.token     = ""
	NetworkManager.player_id = ""
	print("[PlayerData] Logged out")


# ============================================================
# API / Servidor
# ============================================================
func save_deck_to_server(slot: int, deck_name: String, cards_array: Array,
		deck_tier: String = "C", featured_cards: Array = []) -> void:

	save_deck_local(slot, deck_name, cards_array, deck_tier, featured_cards, false)

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
	var payload = JSON.stringify({
		"slot":           slot,
		"name":           deck_name,
		"cards":          cards_array,
		"tier":           deck_tier,
		"featured_cards": featured_cards,
	})

	var err = http.request(url, headers, HTTPClient.METHOD_POST, payload)
	if err != OK:
		print("[PlayerData] Error al iniciar la petición HTTP: ", err)
		http.queue_free()


# ============================================================
# Guardar mazo activo en servidor
# ============================================================
func save_active_deck_to_server(slot: int) -> void:
	active_deck_slot = slot

	if not is_logged_in or NetworkManager.token == "":
		print("[PlayerData] Sin sesión, slot guardado solo localmente: ", slot)
		return

	var http = HTTPRequest.new()
	add_child(http)

	http.request_completed.connect(func(_result, response_code, _headers, body_response):
		http.queue_free()
		if response_code == 200:
			print("[PlayerData] Mazo activo guardado en servidor: slot ", slot)
		else:
			print("[PlayerData] Error guardando mazo activo. Código: ", response_code,
				" | ", body_response.get_string_from_utf8())
	)

	var url     = NetworkManager.BASE_URL + "/api/decks/active"
	var headers = [
		"Content-Type: application/json",
		"Authorization: Bearer " + NetworkManager.token
	]
	var payload = JSON.stringify({"active_deck_slot": slot})

	var err = http.request(url, headers, HTTPClient.METHOD_PUT, payload)
	if err != OK:
		print("[PlayerData] Error iniciando request: ", err)
		http.queue_free()
