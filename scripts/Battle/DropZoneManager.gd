extends Node
class_name DropZoneManager


# ============================================================
# DropZoneManager.gd
# Maneja los highlights visuales de zonas válidas durante
# drag & drop, y la detección de en qué zona se soltó una carta.
# ============================================================

var _active_zone:  Control = null
var _bench_zones:  Array   = []


# ============================================================
# SETUP
# ============================================================
func setup(active_zone: Control, bench_zones: Array) -> void:
	_active_zone = active_zone
	_bench_zones = bench_zones


# ============================================================
# HIGHLIGHT
# ============================================================
func highlight_for_card(card_id: String, state: Dictionary) -> void:
	var card_data   = CardDatabase.get_card(card_id)
	var card_type   = card_data.get("type", "")
	var stage       = card_data.get("stage", 0)
	var COLOR_VALID = Color(0.20, 0.90, 0.35, 0.50)

	match card_type:
		"POKEMON":
			if str(stage) == "0" or str(stage) == "baby":
				if not state.get("my", {}).get("active"):
					set_zone_glow(_active_zone, COLOR_VALID)
				var bench = state.get("my", {}).get("bench", [])
				for i in range(5):
					if i >= bench.size() or bench[i] == null:
						set_zone_glow(_bench_zones[i], COLOR_VALID)
			else:
				var evolves_from = card_data.get("evolves_from", "")
				var active = state.get("my", {}).get("active")
				if active and _name_matches(active.get("card_id", ""), evolves_from):
					set_zone_glow(_active_zone, COLOR_VALID)
				var bench = state.get("my", {}).get("bench", [])
				for i in range(bench.size()):
					if bench[i] and _name_matches(bench[i].get("card_id", ""), evolves_from):
						set_zone_glow(_bench_zones[i], COLOR_VALID)
		"ENERGY":
			if not state.get("my", {}).get("energy_played_this_turn", false):
				if state.get("my", {}).get("active"):
					set_zone_glow(_active_zone, COLOR_VALID)
				var bench = state.get("my", {}).get("bench", [])
				for i in range(bench.size()):
					if bench[i] != null:
						set_zone_glow(_bench_zones[i], COLOR_VALID)


func clear_highlights() -> void:
	set_zone_glow(_active_zone, Color(0, 0, 0, 0))
	for zone in _bench_zones:
		set_zone_glow(zone, Color(0, 0, 0, 0))


func set_zone_glow(zone: Control, color: Color) -> void:
	if not zone: return
	var overlay = zone.get_node_or_null("DropOverlay")
	if not overlay:
		overlay = ColorRect.new()
		overlay.name         = "DropOverlay"
		overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
		overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		overlay.z_index      = 5
		zone.add_child(overlay)
	overlay.color = color


# ============================================================
# DETECCIÓN DE ZONA
# ============================================================
func get_zone_at_position(drop_pos: Vector2) -> Dictionary:
	if _active_zone and _pos_in_zone(drop_pos, _active_zone):
		return {"zone": "active", "index": 0}
	for i in range(_bench_zones.size()):
		if _pos_in_zone(drop_pos, _bench_zones[i]):
			return {"zone": "bench", "index": i}
	return {}


func _pos_in_zone(pos: Vector2, zone: Control) -> bool:
	if not zone: return false
	return Rect2(zone.global_position, zone.size).has_point(pos)


func _name_matches(card_id: String, species_name: String) -> bool:
	var data = CardDatabase.get_card(card_id)
	if data.is_empty(): return false
	return data.get("name", "").to_lower() == species_name.to_lower() \
		or card_id.begins_with(species_name.to_lower())
