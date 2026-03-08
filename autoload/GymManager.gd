## GymManager.gd
## Autoload singleton — res://autoload/GymManager.gd
##
## SETUP: Agregar en Project → Project Settings → Autoload
##   Path: res://autoload/GymManager.gd
##   Name: GymManager
##
## USO TÍPICO (en LoginScreen.gd, después de cargar PlayerData):
##   GymManager.load_from_server(server_response.gyms, server_response.gym_progress, server_response.medals)
extends Node

# ─── SEÑALES ─────────────────────────────────────────────────────────────────
signal gym_data_loaded
signal gym_challenge_started(progress: Dictionary)
signal gym_battle_ready(opponent: Dictionary)
signal gym_grunt_defeated(gym_id: String, rewards: Array)
signal gym_challenge_completed(gym_id: String, rewards: Array)
signal gym_already_completed(gym_id: String)
signal gym_member_added(gym_id: String, user_id: String)
signal gym_member_removed(gym_id: String, user_id: String)

# ─── CONSTANTES ──────────────────────────────────────────────────────────────
# TIER_MAP eliminado — reemplazado por get_leader_tier_for_challenger()
const TIER_ORDER = ["C", "B", "A", "S", "SS"]

const GYM_TYPES = {
	"gym_grass":     { "id": "gym_grass",     "type": "GRASS",     "name": "Gimnasio Planta"   },
	"gym_fire":      { "id": "gym_fire",      "type": "FIRE",      "name": "Gimnasio Fuego"    },
	"gym_water":     { "id": "gym_water",     "type": "WATER",     "name": "Gimnasio Agua"     },
	"gym_lightning": { "id": "gym_lightning", "type": "LIGHTNING", "name": "Gimnasio Rayo"     },
	"gym_psychic":   { "id": "gym_psychic",   "type": "PSYCHIC",   "name": "Gimnasio Psíquico" },
	"gym_fighting":  { "id": "gym_fighting",  "type": "FIGHTING",  "name": "Gimnasio Lucha"    },
	"gym_darkness":  { "id": "gym_darkness",  "type": "DARKNESS",  "name": "Gimnasio Oscuridad"},
	"gym_metal":     { "id": "gym_metal",     "type": "METAL",     "name": "Gimnasio Metal"    },
	"gym_colorless": { "id": "gym_colorless", "type": "COLORLESS", "name": "Gimnasio Incoloro" },
}

# ─── ESTADO EN MEMORIA ───────────────────────────────────────────────────────
var _gym_data: Dictionary = {}
var _active_progress: Dictionary = {}
var _medals: Dictionary = {}

# ─── INICIALIZACIÓN ──────────────────────────────────────────────────────────
func _ready() -> void:
	_init_empty_gyms()

func _init_empty_gyms() -> void:
	for gym_id in GYM_TYPES:
		_gym_data[gym_id] = {
			"leader_user_id":      "",
			"leader_username":     "",
			"sub_leader_user_id":  "",
			"sub_leader_username": "",
			"grunt_ids":           [],
			"leader_decks":        { "SS": "", "S": "", "A": "", "B": "" },
			"members":             [],
		}

# ─────────────────────────────────────────────────────────────────────────────
# CARGA DESDE SERVIDOR  (llamada al login)
# ─────────────────────────────────────────────────────────────────────────────
func load_from_server(gyms_array: Array, progress: Dictionary, medals: Array) -> void:
	_load_gyms_array(gyms_array)

	if not progress.is_empty() and progress.get("gym_id", "") != "":
		var grunts = progress.get("grunts_defeated", [])
		if typeof(grunts) == TYPE_STRING:
			var json = JSON.new()
			if json.parse(grunts) == OK:
				grunts = json.get_data()
			else:
				grunts = []
		_active_progress = {
			"gym_id":          progress.get("gym_id",          ""),
			"grunts_defeated": grunts,
			"leader_defeated": progress.get("leader_defeated", false),
			"attempt_tier":    progress.get("attempt_tier",    "C"),
		}

	_medals.clear()
	for medal_gym_id in medals:
		_medals[medal_gym_id] = true

	emit_signal("gym_data_loaded")
	print("[GymManager] Cargado: %d GYMs | progreso: %s | medallas: %d" % [
		gyms_array.size(),
		_active_progress.get("gym_id", "ninguno"),
		_medals.size()
	])

# ─────────────────────────────────────────────────────────────────────────────
# FETCH FRESCO DESDE SERVIDOR
# Llama GET /api/gym/all y actualiza el estado en memoria.
# callback(ok: bool) se invoca al terminar.
# ─────────────────────────────────────────────────────────────────────────────
func fetch_gyms(callback: Callable = Callable()) -> void:
	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(func(result, code, _headers, body):
		http.queue_free()
		if code != 200:
			push_warning("[GymManager] fetch_gyms error %d: %s" % [code, body.get_string_from_utf8()])
			if callback.is_valid():
				callback.call(false)
			return

		var json = JSON.new()
		if json.parse(body.get_string_from_utf8()) != OK:
			push_warning("[GymManager] fetch_gyms: JSON inválido")
			if callback.is_valid():
				callback.call(false)
			return

		var data = json.get_data()

		# Actualizar gyms
		var gyms_array = data.get("gyms", [])
		_load_gyms_array(gyms_array)

		# Actualizar medallas
		_medals.clear()
		for medal_gym_id in data.get("medals", []):
			_medals[medal_gym_id] = true

		# Actualizar progreso activo si hay uno sin completar
		var prog = data.get("gym_progress", {})
		if typeof(prog) == TYPE_DICTIONARY and prog.get("gym_id", "") != "":
			var grunts = prog.get("grunts_defeated", [])
			if typeof(grunts) == TYPE_STRING:
				var jj = JSON.new()
				grunts = jj.get_data() if jj.parse(grunts) == OK else []
			_active_progress = {
				"gym_id":          prog.get("gym_id",          ""),
				"grunts_defeated": grunts,
				"leader_defeated": prog.get("leader_defeated", false),
				"attempt_tier":    prog.get("attempt_tier",    "C"),
			}

		emit_signal("gym_data_loaded")
		print("[GymManager] fetch_gyms OK — %d GYMs, %d medallas" % [gyms_array.size(), _medals.size()])

		if callback.is_valid():
			callback.call(true)
	)

	var err = http.request(
		NetworkManager.BASE_URL + "/api/gym/all",
		["Content-Type: application/json", "Authorization: Bearer " + NetworkManager.token],
		HTTPClient.METHOD_GET
	)
	if err != OK:
		push_warning("[GymManager] fetch_gyms: no se pudo lanzar la request")
		http.queue_free()
		if callback.is_valid():
			callback.call(false)

# ─────────────────────────────────────────────────────────────────────────────
# HELPER INTERNO — parsea un array de gyms del servidor al estado local
# ─────────────────────────────────────────────────────────────────────────────
func _load_gyms_array(gyms_array: Array) -> void:
	for gym in gyms_array:
		var gid = gym.get("gym_id", "")
		if gid == "" or gid not in _gym_data:
			continue
		_gym_data[gid]["leader_user_id"]      = gym.get("leader_user_id",      "")
		_gym_data[gid]["leader_username"]      = gym.get("leader_username",     "")
		_gym_data[gid]["sub_leader_user_id"]   = gym.get("sub_leader_user_id",  "")
		_gym_data[gid]["sub_leader_username"]  = gym.get("sub_leader_username", "")
		_gym_data[gid]["grunt_ids"]            = gym.get("grunt_ids",           [])
		_gym_data[gid]["leader_decks"]         = gym.get("leader_decks",        { "SS": "", "S": "", "A": "", "B": "" })
		_gym_data[gid]["members"]              = gym.get("members",             [])

# ─────────────────────────────────────────────────────────────────────────────
# LÓGICA DE VENTAJA DEL LÍDER
#
# Tabla de tiers:
#   Retador SS  →  Líder usa deck SS
#   Retador S   →  Líder usa deck SS
#   Retador A   →  Líder usa deck S
#   Retador B   →  Líder usa deck A
#   Retador C   →  Líder usa deck B   (B y C comparten deck del líder)
# ─────────────────────────────────────────────────────────────────────────────
func get_leader_tier_for_challenger(challenger_tier: String) -> String:
	match challenger_tier:
		"SS": return "SS"
		"S":  return "SS"
		"A":  return "S"
		"B":  return "A"
		"C":  return "B"
		_:    return "B"

# ─────────────────────────────────────────────────────────────────────────────
# RETO DE GYM  —  Flujo principal
# ─────────────────────────────────────────────────────────────────────────────
func start_gym_challenge(gym_id: String) -> void:
	if has_medal(gym_id):
		emit_signal("gym_already_completed", gym_id)
		return

	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(func(result, code, _headers, body):
		http.queue_free()
		if code != 200:
			push_warning("[GymManager] Error al iniciar reto: " + body.get_string_from_utf8())
			return
		var json = JSON.new()
		if json.parse(body.get_string_from_utf8()) != OK:
			return
		var data = json.get_data()

		_active_progress = {
			"gym_id":          gym_id,
			"grunts_defeated": [],
			"leader_defeated": false,
			"attempt_tier":    data.get("attempt_tier", "C"),
		}

		emit_signal("gym_challenge_started", _active_progress)

		var opponent = _build_opponent_from_response(data, gym_id)
		emit_signal("gym_battle_ready", opponent)
	)

	http.request(
		NetworkManager.BASE_URL + "/api/gym/%s/challenge/start" % gym_id,
		["Content-Type: application/json", "Authorization: Bearer " + NetworkManager.token],
		HTTPClient.METHOD_POST,
		""
	)

func report_battle_result(gym_id: String, won: bool, opponent_type: String, opponent_id: String) -> void:
	var payload = JSON.stringify({
		"won":           won,
		"opponent_type": opponent_type,
		"opponent_id":   opponent_id,
	})

	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(func(result, code, _headers, body):
		http.queue_free()
		if code != 200:
			push_warning("[GymManager] Error reportando resultado: " + body.get_string_from_utf8())
			return
		var json = JSON.new()
		if json.parse(body.get_string_from_utf8()) != OK:
			return
		var data = json.get_data()

		if not data.get("success", false):
			return

		if not won:
			return

		if opponent_type == "grunt":
			if opponent_id not in _active_progress.get("grunts_defeated", []):
				_active_progress["grunts_defeated"].append(opponent_id)

			var rewards = _parse_rewards(data.get("reward", {}))
			emit_signal("gym_grunt_defeated", gym_id, rewards)
			_fetch_next_opponent(gym_id)

		elif opponent_type == "leader":
			_active_progress["leader_defeated"] = true
			_medals[gym_id] = true
			PlayerData.medals.append(gym_id)

			var rewards = _parse_rewards(data.get("reward", {}))
			rewards.append({ "type": "medal", "gym_id": gym_id })
			emit_signal("gym_challenge_completed", gym_id, rewards)
	)

	http.request(
		NetworkManager.BASE_URL + "/api/gym/%s/challenge/result" % gym_id,
		["Content-Type: application/json", "Authorization: Bearer " + NetworkManager.token],
		HTTPClient.METHOD_POST,
		payload
	)

func _fetch_next_opponent(gym_id: String) -> void:
	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(func(result, code, _headers, body):
		http.queue_free()
		if code != 200:
			return
		var json = JSON.new()
		if json.parse(body.get_string_from_utf8()) != OK:
			return
		var data = json.get_data()
		var opponent = _build_opponent_from_response(data, gym_id)
		emit_signal("gym_battle_ready", opponent)
	)
	http.request(
		NetworkManager.BASE_URL + "/api/gym/%s/challenge/start" % gym_id,
		["Content-Type: application/json", "Authorization: Bearer " + NetworkManager.token],
		HTTPClient.METHOD_POST,
		""
	)

# ─────────────────────────────────────────────────────────────────────────────
# GESTIÓN DE MIEMBROS  (solo Líder)
# ─────────────────────────────────────────────────────────────────────────────
func add_gym_member(gym_id: String, target_user_id: String, role: String) -> void:
	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(func(result, code, _headers, body):
		http.queue_free()
		if code != 200:
			push_warning("[GymManager] Error agregando miembro: " + body.get_string_from_utf8())
			return
		match role:
			"leader":     _gym_data[gym_id]["leader_user_id"]     = target_user_id
			"sub_leader": _gym_data[gym_id]["sub_leader_user_id"] = target_user_id
			"grunt":
				if target_user_id not in _gym_data[gym_id]["grunt_ids"]:
					_gym_data[gym_id]["grunt_ids"].append(target_user_id)
		emit_signal("gym_member_added", gym_id, target_user_id)
	)
	http.request(
		NetworkManager.BASE_URL + "/api/gym/%s/member" % gym_id,
		["Content-Type: application/json", "Authorization: Bearer " + NetworkManager.token],
		HTTPClient.METHOD_POST,
		JSON.stringify({ "target_user_id": target_user_id, "role": role })
	)

func remove_gym_member(gym_id: String, user_id: String) -> void:
	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(func(result, code, _headers, body):
		http.queue_free()
		if code != 200:
			push_warning("[GymManager] Error removiendo miembro: " + body.get_string_from_utf8())
			return
		_gym_data[gym_id]["grunt_ids"].erase(user_id)
		if _gym_data[gym_id]["sub_leader_user_id"] == user_id:
			_gym_data[gym_id]["sub_leader_user_id"] = ""
		emit_signal("gym_member_removed", gym_id, user_id)
	)
	http.request(
		NetworkManager.BASE_URL + "/api/gym/%s/member/%s" % [gym_id, user_id],
		["Content-Type: application/json", "Authorization: Bearer " + NetworkManager.token],
		HTTPClient.METHOD_DELETE,
		""
	)

func assign_leader_deck(gym_id: String, tier: String, deck_id: String) -> void:
	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(func(result, code, _headers, body):
		http.queue_free()
		if code != 200:
			push_warning("[GymManager] Error asignando deck: " + body.get_string_from_utf8())
			return
		_gym_data[gym_id]["leader_decks"][tier] = deck_id
	)
	http.request(
		NetworkManager.BASE_URL + "/api/gym/%s/leader-deck" % gym_id,
		["Content-Type: application/json", "Authorization: Bearer " + NetworkManager.token],
		HTTPClient.METHOD_PUT,
		JSON.stringify({ "tier": tier, "deck_id": deck_id })
	)

# ─────────────────────────────────────────────────────────────────────────────
# HELPERS PÚBLICOS
# ─────────────────────────────────────────────────────────────────────────────
func has_medal(gym_id: String) -> bool:
	return _medals.get(gym_id, false)

func get_gym_data(gym_id: String) -> Dictionary:
	return _gym_data.get(gym_id, {})

func get_gym_type_info(gym_id: String) -> Dictionary:
	return GYM_TYPES.get(gym_id, {})

func get_gym_members(gym_id: String) -> Array:
	return _gym_data.get(gym_id, {}).get("members", [])

func get_active_progress() -> Dictionary:
	return _active_progress.duplicate()

func get_leader_deck_for_tier(gym_id: String, challenger_tier: String) -> String:
	var leader_tier = get_leader_tier_for_challenger(challenger_tier)
	return _gym_data.get(gym_id, {}).get("leader_decks", {}).get(leader_tier, "")

# ─────────────────────────────────────────────────────────────────────────────
# HELPERS PRIVADOS
# ─────────────────────────────────────────────────────────────────────────────
func _build_opponent_from_response(data: Dictionary, gym_id: String) -> Dictionary:
	var opponent_type = data.get("opponent_type", "grunt")
	if opponent_type == "grunt":
		return {
			"type":        "grunt",
			"user_id":     data.get("opponent_id", ""),
			"gym_id":      gym_id,
			"attempt_tier": data.get("attempt_tier", "C"),
		}
	else:
		return {
			"type":         "leader",
			"user_id":      data.get("opponent_id", ""),
			"deck_id":      data.get("leader_deck_id", ""),
			"gym_id":       gym_id,
			"attempt_tier": data.get("attempt_tier", "C"),
		}

func _parse_rewards(reward) -> Array:
	if typeof(reward) == TYPE_ARRAY:
		return reward
	if typeof(reward) == TYPE_DICTIONARY and not reward.is_empty():
		return [reward]
	return []
