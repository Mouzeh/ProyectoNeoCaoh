extends Node
class_name PokePowerHandler

# ============================================================
# PokePowerHandler.gd
# Maneja toda la lógica de UI y envío de Pokémon Powers activos.
# ============================================================

signal power_message(text: String)
signal power_cancelled()

# ── Referencias ──────────────────────────────────────────────
var board:           Node = null
var target_selector: Node = null

# ── Estado interno ───────────────────────────────────────────
var _power_name:    String = ""
var _source_zone:   String = "active"
var _source_index:  int    = 0
var _step:          int    = 0
var _from_zone:     String = ""
var _from_index:    int    = -1
var _active:        bool   = false

# ── Colores para highlights ──────────────────────────────────
const COLOR_OWN      = Color(0.20, 0.85, 0.40, 0.40)
const COLOR_OPPONENT = Color(0.95, 0.35, 0.20, 0.45)
const COLOR_CLEAR    = Color(0, 0, 0, 0)

# ============================================================
# TABLA DE POWERS
# ============================================================
const POWER_CONFIG: Dictionary = {
	# Neo Genesis
	"Fire Recharge": { "type": "one_own", "label": "Fire Recharge" },
	"Downpour":       { "type": "pick_from_hand",    "label": "Downpour",      "filter": "water_energy", "min": 1, "max": 1 },
	"Glaring Gaze":   { "type": "instant",  "label": "Glaring Gaze" },
	"Final Blow":     { "type": "instant",  "label": "Final Blow" },
	"Playful Punch":  { "type": "instant",  "label": "Playful Punch" },

	# Legendary Collection
	"Damage Swap":        { "type": "two_own",         "label": "Damage Swap" },
	"Energy Trans":       { "type": "two_own",         "label": "Energy Trans" },
	"Curse":              { "type": "two_opp",         "label": "Curse" },
	"Evolutionary Light": { "type": "pick_from_deck",    "label": "Evolutionary Light", "filter": "evolution",     "min": 1, "max": 1 },
	"Summon Minions":     { "type": "pick_from_deck",    "label": "Summon Minions",     "filter": "basic_pokemon", "min": 1, "max": 2 },
	"Reel In":            { "type": "pick_from_discard", "label": "Reel In",            "filter": "pokemon",       "min": 1, "max": 3 },
	"Cowardice":          { "type": "instant",  "label": "Cowardice" },
	"Energy Burn":        { "type": "instant",  "label": "Energy Burn" },
	"Long Distance Hypnosis": { "type": "instant", "label": "Long Distance Hypnosis" },
}

const PASSIVE_POWERS: Array = [
	"Wild Growth", "Mind Games", "Hydroelectric Power", 
	"Sleeping Gas", "Eon Eon", "Ambush", "Serene Grace", "Recycle",
	"Toxic Gas", "Strikes Back", "Transparency", "Retreat Aid",
	"Clairvoyance", "Thick Skinned", "Fire Boost", "Berserk", "Herbal Scent",
]

# ============================================================
# API PÚBLICA
# ============================================================
func begin_power(power_name: String, source_zone: String = "active", source_index: int = 0) -> void:
	print("[PPH] begin_power — power=%s  zone=%s  idx=%d  _active_prev=%s" % [power_name, source_zone, source_index, _active])
	if not board: return

	if power_name in PASSIVE_POWERS:
		emit_signal("power_message", "⚠ '%s' es un poder pasivo, se activa automáticamente" % power_name)
		return

	if not POWER_CONFIG.has(power_name):
		emit_signal("power_message", "⚠ Power no implementado: %s" % power_name)
		return

	_clear_highlights()

	_power_name   = power_name
	_source_zone  = source_zone
	_source_index = source_index
	_step         = 0
	_from_zone    = ""
	_from_index   = -1
	_active       = true

	var config: Dictionary = POWER_CONFIG[power_name]
	match config["type"]:
		"instant":
			_send({})
		"one_own":
			emit_signal("power_message", "⚡ %s — Elige el Pokémon destino (Esc = cancelar)" % power_name)
			_step = 1
			_highlight_own_pokemon()
		"two_own":
			emit_signal("power_message", "⚡ %s — Elige el Pokémon ORIGEN (Esc = cancelar)" % power_name)
			_step = 0
			_highlight_own_pokemon()
		"two_opp":
			emit_signal("power_message", "⚡ %s — Elige el Pokémon ORIGEN del rival (Esc = cancelar)" % power_name)
			_step = 0
			_highlight_opponent_pokemon()
		"pick_from_deck", "pick_from_discard", "pick_from_hand":
			_handle_card_picker(config)


func on_zone_clicked(zone: String, zone_index: int) -> void:
	if not _active: return
	var config: Dictionary = POWER_CONFIG.get(_power_name, {})

	match config.get("type", ""):
		"one_own":
			_clear_highlights()
			_send({ "targetZone": zone, "targetIndex": zone_index })

		"two_own":
			if _step == 0:
				_from_zone  = zone
				_from_index = zone_index
				_step       = 1
				_clear_highlights()
				emit_signal("power_message", "⚡ %s — Ahora elige el Pokémon DESTINO (Esc = cancelar)" % _power_name)
				_highlight_own_pokemon()
			else:
				_clear_highlights()
				_send({
					"fromZone":  _from_zone,
					"fromIndex": _from_index,
					"toZone":    zone,
					"toIndex":   zone_index,
				})

		"two_opp":
			if _step == 0:
				_from_zone  = zone
				_from_index = zone_index
				_step       = 1
				_clear_highlights()
				emit_signal("power_message", "⚡ %s — Ahora elige el Pokémon DESTINO del rival (Esc = cancelar)" % _power_name)
				_highlight_opponent_pokemon()
			else:
				_clear_highlights()
				_send({
					"fromZone":  _from_zone,
					"fromIndex": _from_index,
					"toZone":    zone,
					"toIndex":   zone_index,
				})


func cancel() -> void:
	if not _active: return
	_reset()
	emit_signal("power_cancelled")
	emit_signal("power_message", "Power cancelado (Esc)")


func is_active() -> bool:
	return _active


# ============================================================
# CARD PICKER MODAL
# ============================================================
func _handle_card_picker(config: Dictionary) -> void:
	var my_state = board.current_state.get("my", {})
	var source_array = []

	match config["type"]:
		"pick_from_deck": source_array = my_state.get("deck", [])
		"pick_from_discard": source_array = my_state.get("discard", [])
		"pick_from_hand": source_array = my_state.get("hand", [])

	var valid_cards = _filter_cards(source_array, config["filter"])

	if valid_cards.is_empty():
		emit_signal("power_message", "⚠ No hay cartas válidas para %s" % config["label"])
		cancel()
		return

	var picker = CardPickerModal.new()
	board.add_child(picker)
	picker.setup(config["label"], valid_cards, config["min"], config["max"])

	picker.cards_selected.connect(func(selected_indices):
		var selected_ids = []
		var selected_instance_ids = []

		for idx in selected_indices:
			var card_info = valid_cards[idx]
			selected_ids.append(card_info.get("card_id", ""))
			var inst_id = card_info.get("instance_id", card_info.get("card_id", ""))
			selected_instance_ids.append(inst_id)

		if selected_instance_ids.size() > 0:
			var targets_payload = {
				"selectedCardId": selected_ids[0],
				"selectedCardIds": selected_ids,
				"selectedInstanceIds": selected_instance_ids,
				"instanceId": selected_instance_ids[0]
			}
			_send(targets_payload)
		else:
			cancel()
	)

	picker.cancelled.connect(func(): cancel())


func _filter_cards(raw_cards: Array, filter_type: String) -> Array:
	var filtered = []
	for c in raw_cards:
		var c_id = str(c.get("card_id", ""))
		var data = CardDatabase.get_card(c_id)
		if data.is_empty(): continue

		var is_valid = false
		match filter_type:
			"evolution":
				var stage = data.get("stage", 0)
				is_valid = (data.get("type") == "POKEMON" and typeof(stage) != TYPE_STRING and stage > 0)
			"basic_pokemon":
				var stage = data.get("stage", 0)
				is_valid = (data.get("type") == "POKEMON" and (stage == 0 or str(stage) == "baby"))
			"pokemon":
				is_valid = (data.get("type") == "POKEMON")
			"fire_energy":
				is_valid = (c_id == "fire_energy")
			"water_energy":
				is_valid = (c_id == "water_energy")
			_:
				is_valid = true
		if is_valid:
			filtered.append(c)
	return filtered


# ============================================================
# ENVÍO AL SERVIDOR
# ============================================================
func _send(targets_dict: Dictionary) -> void:
	print("[PPH] _send — power=%s  source=%s[%d]  targets=%s" % [_power_name, _source_zone, _source_index, targets_dict])

	var payload: Dictionary = {
		"powerName":   _power_name,
		"sourceZone":  _source_zone,
		"sourceIndex": _source_index,
		"zone":        _source_zone,
		"index":       _source_index,
		"targets":     targets_dict
	}

	if _source_zone == "bench":
		payload["benchIndex"]   = _source_index
		payload["pokemonIndex"] = _source_index

	NetworkManager.send_action("USE_POWER", payload)
	var label = POWER_CONFIG.get(_power_name, {}).get("label", _power_name)
	emit_signal("power_message", "⚡ %s enviado..." % label)
	_reset()


# ============================================================
# HIGHLIGHTS
# ============================================================
func _highlight_own_pokemon() -> void:
	_apply_highlight_own()

func _highlight_opponent_pokemon() -> void:
	_apply_highlight_opp()

func _clear_highlights() -> void:
	_apply_clear_highlights()

func _apply_highlight_own() -> void:
	if not board: return
	var my = board.current_state.get("my", {})
	if board.my_active_zone and my.get("active") != null:
		_set_zone_color(board.my_active_zone, COLOR_OWN)
		_connect_zone(board.my_active_zone, "active", 0)
	var bench = my.get("bench", [])
	for i in range(bench.size()):
		if bench[i] != null:
			_set_zone_color(board.my_bench_zones[i], COLOR_OWN)
			_connect_zone(board.my_bench_zones[i], "bench", i)

func _apply_highlight_opp() -> void:
	if not board: return
	var opp = board.current_state.get("opponent", {})
	if board.opp_active_zone and opp.get("active") != null:
		_set_zone_color(board.opp_active_zone, COLOR_OPPONENT)
		_connect_zone(board.opp_active_zone, "active", 0)
	var bench = opp.get("bench", [])
	for i in range(bench.size()):
		if bench[i] != null:
			_set_zone_color(board.opp_bench_zones[i], COLOR_OPPONENT)
			_connect_zone(board.opp_bench_zones[i], "bench", i)

func _apply_clear_highlights() -> void:
	if not board: return
	var zones = [board.my_active_zone, board.opp_active_zone]
	zones += board.my_bench_zones + board.opp_bench_zones
	for z in zones:
		if not z: continue
		_set_zone_color(z, COLOR_CLEAR)
		for child in z.get_children():
			if child.has_meta("is_power_area"):
				if child is Button:
					child.disabled = true
				child.mouse_filter = Control.MOUSE_FILTER_IGNORE
				child.queue_free()

func _set_zone_color(zone: Control, color: Color) -> void:
	var overlay = zone.get_node_or_null("PowerOverlay")
	if not overlay:
		overlay = ColorRect.new()
		overlay.name         = "PowerOverlay"
		overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
		overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		zone.add_child(overlay)
	overlay.color = color

func _connect_zone(zone: Control, zone_name: String, zone_idx: int) -> void:
	for child in zone.get_children():
		if child.has_meta("is_power_area"):
			if child is Button:
				child.disabled = true
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE
			child.queue_free()

	var area = Button.new()
	area.name    = "PowerClickArea"
	area.set_meta("is_power_area", true)
	area.z_index = 10
	area.set_anchors_preset(Control.PRESET_FULL_RECT)
	area.flat    = true
	area.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	area.disabled = true
	zone.add_child(area)

	area.get_tree().create_timer(0.08).timeout.connect(func():
		if is_instance_valid(area):
			area.disabled = false
	)

	area.pressed.connect(func():
		on_zone_clicked(zone_name, zone_idx)
	)


# ============================================================
# RESET
# ============================================================
func _reset() -> void:
	print("[PPH] _reset — limpiando highlights y estado")
	_clear_highlights()
	_power_name   = ""
	_source_zone  = "active"
	_source_index = 0
	_step         = 0
	_from_zone    = ""
	_from_index   = -1

	if board and board.is_inside_tree():
		board.get_tree().create_timer(0.1).timeout.connect(func():
			_active = false
			print("[PPH]   _active ahora = false")
		)
	else:
		_active = false
