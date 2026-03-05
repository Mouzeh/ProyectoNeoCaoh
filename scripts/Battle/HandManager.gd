extends Node
class_name HandManager

# ─── SEÑALES ────────────────────────────────────────────────
signal card_clicked(hand_index: int, card_id: String)
signal card_drag_started(hand_index: int, card_id: String, card_node: Node)
signal card_dropped(hand_index: int, card_id: String, drop_pos: Vector2, card_node: Node)
signal request_zoom(card_id: String)

# ─── CONSTANTES ─────────────────────────────────────────────
const CARD_W          = 130
const CARD_H          = 182
const HAND_MARGIN     = 220
const HAND_IDEAL_STEP = 44
const HAND_MIN_STEP   = 22
const MAX_ARC_HEIGHT  = 25.0
const MAX_ROTATION    = 10.0

const COLOR_UNPLAYABLE = Color(0.45, 0.45, 0.45, 0.7)
const COLOR_PLAYABLE   = Color(1.0,  1.0,  1.0,  1.0)

# ─── REFERENCIAS ────────────────────────────────────────────
var hand_zone: Control = null
var vp_width:  float   = 0.0

# ─── ESTADO ─────────────────────────────────────────────────
var selected_index:   int        = -1
var _drag_hint_label: Label      = null
var _card_cache:      Dictionary = {}   # índice → { "card_id", "node" }
var _playable_mask:   Array      = []
var _hovered_card_id: String     = ""


func setup(my_hand_zone: Control, viewport_width: float) -> void:
	hand_zone = my_hand_zone
	vp_width  = viewport_width


# ============================================================
# ACTUALIZAR MANO
# ============================================================
func update_hand(hand_cards: Array) -> void:
	if not hand_zone: return

	var count:   int   = hand_cards.size()
	var new_ids: Array = []
	for c in hand_cards:
		new_ids.append(str(c.get("card_id", "")))

	# Eliminar los que cambiaron o sobran
	var to_remove: Array = []
	for idx in _card_cache.keys():
		if idx >= count or _card_cache[idx]["card_id"] != new_ids[idx]:
			to_remove.append(idx)
	for idx in to_remove:
		var n = _card_cache[idx]["node"]
		if is_instance_valid(n) and not n.get("is_dragging"):
			n.queue_free()
		_card_cache.erase(idx)

	if count == 0: return

	var step:    float = _calc_hand_step(count)
	var total_w: float = CARD_W + (count - 1) * step
	var start_x: float = (vp_width - total_w) / 2.0
	var base_y:  float = 10.0
	if hand_zone.size.y > CARD_H:
		base_y = (hand_zone.size.y - CARD_H) / 2.0

	for i in range(count):
		var card_id: String = new_ids[i]
		if card_id == "": continue

		var half_count:       float = (count - 1) / 2.0
		var dist_from_center: float = 0.0
		if half_count > 0:
			dist_from_center = (i - half_count) / half_count

		var y_offset:   float   = (dist_from_center * dist_from_center) * MAX_ARC_HEIGHT
		var target_pos: Vector2 = Vector2(start_x + i * step, base_y + y_offset)
		var target_rot: float   = dist_from_center * MAX_ROTATION

		if _card_cache.has(i):
			var n = _card_cache[i]["node"]
			if is_instance_valid(n) and not n.get("is_dragging"):
				# FIX: Resetear estado hover ANTES de reposicionar.
				# Si la carta estaba con hover activo y la reposicionamos,
				# _base_pos queda desactualizado y causa saltos.
				if n.has_method("reset_hover_state"):
					n.reset_hover_state()
				n.position         = target_pos
				n.rotation_degrees = target_rot
				n.z_index          = i
		else:
			var card = CardDatabase.create_card_instance(card_id)
			card.scale            = Vector2.ONE
			card.is_draggable     = true
			card.pivot_offset     = Vector2(CARD_W / 2.0, CARD_H)
			card.position         = target_pos
			card.rotation_degrees = target_rot
			card.z_index          = i

			var hi: int    = i
			var ci: String = card_id

			card.card_clicked.connect(func(_c):       emit_signal("card_clicked",      hi, ci))
			card.card_drag_started.connect(func(_c):  emit_signal("card_drag_started", hi, ci, card))
			card.card_dropped.connect(func(_c, dp):   emit_signal("card_dropped",      hi, ci, dp, card))

			card.mouse_entered.connect(func(): _hovered_card_id = ci)
			card.mouse_exited.connect(func():  if _hovered_card_id == ci: _hovered_card_id = "")

			if card.has_signal("request_zoom"):
				card.request_zoom.connect(func(id): emit_signal("request_zoom", id))

			hand_zone.add_child(card)
			_card_cache[i] = { "card_id": card_id, "node": card }

	# Aplicar máscara de jugabilidad si existe
	if not _playable_mask.is_empty():
		_apply_playable_mask()


func clear_hand() -> void:
	for idx in _card_cache.keys():
		var n = _card_cache[idx]["node"]
		if is_instance_valid(n): n.queue_free()
	_card_cache.clear()
	_playable_mask.clear()
	_hovered_card_id = ""


# ============================================================
# OBTENER CARTA BAJO EL MOUSE
# ============================================================
func get_hovered_card_id() -> String:
	for idx in _card_cache.keys():
		var card = _card_cache[idx]["node"]
		if is_instance_valid(card) and card.get("is_hovered"):
			return str(_card_cache[idx]["card_id"])
	return ""


# ============================================================
# MÁSCARA DE JUGABILIDAD
# ============================================================
func set_playable_mask(mask: Array) -> void:
	_playable_mask = mask
	_apply_playable_mask()

func clear_playable_mask() -> void:
	_playable_mask = []
	for idx in _card_cache.keys():
		var n = _card_cache[idx]["node"]
		if is_instance_valid(n):
			n.modulate     = COLOR_PLAYABLE
			n.is_draggable = true

func _apply_playable_mask() -> void:
	for idx in _card_cache.keys():
		var n = _card_cache[idx]["node"]
		if not is_instance_valid(n): continue

		var playable: bool = true
		if idx < _playable_mask.size():
			playable = _playable_mask[idx]

		if playable:
			var tw = n.create_tween()
			tw.tween_property(n, "modulate", COLOR_PLAYABLE, 0.18)
			n.is_draggable = true
		else:
			var tw = n.create_tween()
			tw.tween_property(n, "modulate", COLOR_UNPLAYABLE, 0.18)
			n.is_draggable = false


# ============================================================
# HIGHLIGHT
# ============================================================
func highlight_card(index: int) -> void:
	selected_index = index
	var idx = 0
	for child in hand_zone.get_children():
		if child is ColorRect or child is Label: continue
		if child.has_method("set_highlighted"):
			child.set_highlighted(idx == index)
		idx += 1

func clear_highlight() -> void:
	highlight_card(-1)


# ============================================================
# DRAG HINT
# ============================================================
func show_drag_hint(card_id: String, vp_size: Vector2) -> void:
	var hints = {
		"POKEMON": "Suelta en una zona del campo",
		"ENERGY":  "Suelta sobre un Pokémon",
		"TRAINER": "Suelta para jugar el Trainer",
	}
	var card_data = CardDatabase.get_card(card_id)
	var hint      = hints.get(card_data.get("type", ""), "Arrastra al campo")

	if not _drag_hint_label:
		_drag_hint_label = Label.new()
		_drag_hint_label.add_theme_font_size_override("font_size", 13)
		_drag_hint_label.add_theme_color_override("font_color", Color(0.95, 0.90, 0.50))
		_drag_hint_label.size = Vector2(300, 24)
		_drag_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hand_zone.get_parent().add_child(_drag_hint_label)

	_drag_hint_label.position = Vector2(vp_size.x / 2.0 - 150, vp_size.y / 2.0 + 10)
	_drag_hint_label.text     = hint
	_drag_hint_label.visible  = true

func hide_drag_hint() -> void:
	if _drag_hint_label:
		_drag_hint_label.visible = false


# ============================================================
# HELPERS
# ============================================================
func _calc_hand_step(count: int) -> float:
	if count <= 1: return float(CARD_W)
	var avail    = vp_width - HAND_MARGIN * 2.0 - CARD_W
	var max_step = avail / float(count - 1)
	return clamp(min(HAND_IDEAL_STEP, max_step), HAND_MIN_STEP, CARD_W)
