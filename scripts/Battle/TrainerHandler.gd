extends Node

# ============================================================
# TrainerHandler.gd
# ============================================================

signal trainer_message(text: String)
signal trainer_highlight_zones(zone_set: String)
signal trainer_set_zone_glow(zone: Control, color: Color)
signal trainer_clear_trainer_area_buttons()

var board: Node = null

var _hand_index: int        = -1
var _card_id:    String     = ""
var _targets:    Dictionary = {}
var _awaiting:   String     = ""

var _selection_popup: Control = null

const COLOR_GOLD     := Color(0.85, 0.72, 0.30)
const COLOR_GOLD_DIM := Color(0.55, 0.45, 0.18)
const COLOR_TEXT     := Color(0.92, 0.88, 0.75)
const CARD_W         := 130
const CARD_H         := 182

# ============================================================
# API PÚBLICA
# ============================================================
func handle_trainer_drop(hand_index: int, card_id: String, card_data: Dictionary) -> void:
	if not _validate_can_play(card_id, card_data):
		return
	_hand_index = hand_index
	_card_id    = card_id
	_targets    = {}
	_awaiting   = ""
	_dispatch(card_id)

func on_zone_clicked(zone: String, index: int) -> void:
	match _awaiting:
		"own_pokemon":
			_targets["targetZone"]  = zone
			_targets["targetIndex"] = index
			_clear_highlights()
			_send()

		"double_gust_mine":
			_targets["myBenchIndex"] = index
			_clear_highlights()
			emit_signal("trainer_message", "Ahora elige el Pokémon del rival...")
			_awaiting = "double_gust_opp"
			emit_signal("trainer_highlight_zones", "opp_bench")

		"double_gust_opp":
			_targets["opponentBenchIndex"] = index
			_clear_highlights()
			_send()

		"fire_recharge_target":
			_awaiting = ""
			_clear_highlights()
			NetworkManager.send_action("USE_POWER", {
				"sourceZone": "active",
				"targetZone": zone,
				"targetIndex": index,
			})
			emit_signal("trainer_message", "Fire Recharge enviado")

		"downpour_target":
			_awaiting = ""
			_clear_highlights()
			NetworkManager.send_action("USE_POWER", {
				"sourceZone": "active",
				"targetZone": zone,
				"targetIndex": index,
			})
			emit_signal("trainer_message", "Downpour enviado")

		"hand_discard":
			var indices: Array = _targets.get("discardIndices", [])
			if not indices.has(index) and index != _hand_index:
				indices.append(index)
				_targets["discardIndices"] = indices
				emit_signal("trainer_message", "Seleccionada carta %d/2" % indices.size())
				if indices.size() >= 2:
					_clear_highlights()
					_send()

func on_discard_selection_confirmed(selected_ids: Array) -> void:
	if _card_id in ["super_rod", "pokemon_march"]:
		_targets["selectedCardId"]  = selected_ids[0] if selected_ids.size() > 0 else ""
	else:
		_targets["selectedCardIds"] = selected_ids
	_close_discard_selector()
	_send()

func on_discard_selection_cancelled() -> void:
	_close_discard_selector()
	cancel()

func cancel() -> void:
	_clear_highlights()
	_hand_index = -1
	_card_id    = ""
	_targets    = {}
	_awaiting   = ""
	emit_signal("trainer_message", "Trainer cancelado")

func is_awaiting() -> bool:
	return _awaiting != ""

func awaiting_type() -> String:
	return _awaiting


# ============================================================
# VALIDACIÓN
# ============================================================
func _validate_can_play(card_id: String, card_data: Dictionary) -> bool:
	if not board:
		push_error("TrainerHandler: board no asignado")
		return false

	var state:        Dictionary = board.current_state
	var my_state:     Dictionary = state.get("my", {})
	var trainer_type: String     = card_data.get("trainer_type", "")

	if trainer_type == "SUPPORTER" and my_state.get("supporter_played_this_turn", false):
		emit_signal("trainer_message", "⚠ Ya jugaste un Supporter este turno")
		return false

	if my_state.get("elm_played_this_turn", false) and trainer_type != "POKEMON_TOOL":
		emit_signal("trainer_message", "⚠ Professor Elm: no puedes jugar más Trainers")
		return false

	return true


# ============================================================
# DESPACHO POR CARTA
# ============================================================
func _dispatch(card_id: String) -> void:
	match card_id:
		"professor_elm", "mary", "energy_charge", "sprout_tower", "ecogym", \
		"new_pokedex", "pokegear", "arcade_game", "card_flip_game", "bills_teleporter":
			_send()

		"moo_moo_milk", "focus_band", "gold_berry", "berry", "miracle_berry", "super_scoop_up":
			emit_signal("trainer_message", "Elige el Pokémon objetivo...")
			_awaiting = "own_pokemon"
			emit_signal("trainer_highlight_zones", "own_pokemon")

		"time_capsule":
			emit_signal("trainer_message", "Elige la carta del descarte...")
			_show_discard_selector(false)

		"super_rod":
			emit_signal("trainer_message", "Elige 1 Pokémon del descarte...")
			_show_discard_selector(false, 1)

		"pokemon_march":
			emit_signal("trainer_message", "Elige el Pokémon Básico del descarte...")
			_show_discard_selector(true, 1)

		"double_gust":
			emit_signal("trainer_message", "Double Gust: elige tu Pokémon de banco...")
			_awaiting = "double_gust_mine"
			emit_signal("trainer_highlight_zones", "own_bench")

		"super_energy_retrieval":
			emit_signal("trainer_message", "Elige 2 cartas de tu mano para descartar...")
			_awaiting = "hand_discard"
			_targets["discardIndices"] = []
			emit_signal("trainer_highlight_zones", "hand")

		_:
			emit_signal("trainer_message", "⚠ Trainer no implementado: " + card_id)


# ============================================================
# ENVÍO DE ACCIÓN
# ============================================================
func _send() -> void:
	if _hand_index < 0:
		return

	NetworkManager.send_action("PLAY_TRAINER", {
		"handIndex": _hand_index,
		"targets":   _targets,
	})

	var name_display: String = CardDatabase.get_card(_card_id).get("name", _card_id)
	emit_signal("trainer_message", "Jugando %s..." % name_display)

	_hand_index = -1
	_card_id    = ""
	_targets    = {}
	_awaiting   = ""


# ============================================================
# HIGHLIGHTS
# ============================================================
func _clear_highlights() -> void:
	emit_signal("trainer_highlight_zones", "none")
	_awaiting = ""


# ============================================================
# POPUP DE SELECCIÓN DE DESCARTE — con imágenes reales
# ============================================================
func _show_discard_selector(only_basic_pokemon: bool, max_count: int = 99) -> void:
	if not board: return

	var my_discard: Array  = board.current_state.get("my", {}).get("discard", [])
	var candidates: Array  = _build_discard_candidates(my_discard, only_basic_pokemon)

	if candidates.is_empty():
		emit_signal("trainer_message", "⚠ No hay cartas válidas en el descarte")
		cancel()
		return

	var vp:    Vector2 = board.get_viewport().get_visible_rect().size
	var popup: Control = _build_discard_popup(vp, candidates, max_count)
	_selection_popup = popup
	board.add_child(popup)


func _build_discard_candidates(discard: Array, only_basic_pokemon: bool) -> Array[String]:
	var result: Array[String] = []
	for c in discard:
		var cid:   String     = c.get("card_id", "")
		var cdata: Dictionary = CardDatabase.get_card(cid)
		if cdata.is_empty(): continue
		if only_basic_pokemon:
			if cdata.get("type") == "POKEMON" \
			and str(cdata.get("stage", "")) in ["0", "baby"]:
				result.append(cid)
		else:
			if cdata.get("type") == "POKEMON" \
			or (cdata.get("type") == "ENERGY" and _is_basic_energy(cid)):
				result.append(cid)
	return result


func _build_discard_popup(vp: Vector2, candidates: Array, max_count: int) -> Control:
	var popup = Control.new()
	popup.name = "DiscardSelector"
	popup.set_anchors_preset(Control.PRESET_FULL_RECT)
	popup.z_index = 100

	# Fondo oscuro
	var dim = ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.82)
	popup.add_child(dim)

	# Panel central
	var panel_w: float = min(700.0, vp.x - 60)
	var panel_h: float = min(460.0, vp.y - 80)
	var panel = Panel.new()
	panel.position = Vector2((vp.x - panel_w) / 2.0, (vp.y - panel_h) / 2.0)
	panel.size     = Vector2(panel_w, panel_h)

	var pstyle = StyleBoxFlat.new()
	pstyle.bg_color                  = Color(0.06, 0.10, 0.08, 0.98)
	pstyle.border_color              = COLOR_GOLD
	pstyle.border_width_left         = 2; pstyle.border_width_right  = 2
	pstyle.border_width_top          = 2; pstyle.border_width_bottom = 2
	pstyle.corner_radius_top_left    = 14; pstyle.corner_radius_top_right    = 14
	pstyle.corner_radius_bottom_left = 14; pstyle.corner_radius_bottom_right = 14
	panel.add_theme_stylebox_override("panel", pstyle)
	popup.add_child(panel)

	# Título
	var title_lbl = Label.new()
	title_lbl.text = "🗑  Elige %s del descarte" % \
		("1 carta" if max_count == 1 else "hasta %d cartas" % max_count)
	title_lbl.position = Vector2(16, 12)
	title_lbl.size     = Vector2(panel_w - 32, 30)
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 15)
	title_lbl.add_theme_color_override("font_color", COLOR_GOLD)
	panel.add_child(title_lbl)

	# Scroll con cartas
	var scroll = ScrollContainer.new()
	scroll.position = Vector2(12, 50)
	scroll.size     = Vector2(panel_w - 24, panel_h - 110)
	panel.add_child(scroll)

	var flow = HFlowContainer.new()
	flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	flow.add_theme_constant_override("h_separation", 12)
	flow.add_theme_constant_override("v_separation", 12)
	scroll.add_child(flow)

	var card_scale: float = 0.65
	var cw: int = int(CARD_W * card_scale)
	var ch: int = int(CARD_H * card_scale)

	var selected_ids: Array[String] = []

	for cid in candidates:
		var cdata:      Dictionary = CardDatabase.get_card(cid)
		var cid_local:  String     = str(cid)

		# Slot
		var slot = Control.new()
		slot.custom_minimum_size = Vector2(cw, ch + 20)
		flow.add_child(slot)

		# Fondo del slot
		var slot_bg = Panel.new()
		slot_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		var slot_style = StyleBoxFlat.new()
		slot_style.bg_color                  = Color(0.10, 0.16, 0.12, 0.9)
		slot_style.border_color              = COLOR_GOLD_DIM
		slot_style.border_width_left         = 1; slot_style.border_width_right  = 1
		slot_style.border_width_top          = 1; slot_style.border_width_bottom = 1
		slot_style.corner_radius_top_left    = 6; slot_style.corner_radius_top_right    = 6
		slot_style.corner_radius_bottom_left = 6; slot_style.corner_radius_bottom_right = 6
		slot_bg.add_theme_stylebox_override("panel", slot_style)
		slot.add_child(slot_bg)

		# Imagen real de la carta
		var card_inst = CardDatabase.create_card_instance(cid_local)
		card_inst.scale        = Vector2(card_scale, card_scale)
		card_inst.is_draggable = false
		card_inst.position     = Vector2.ZERO
		card_inst.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(card_inst)

		# Nombre debajo
		var name_lbl = Label.new()
		name_lbl.text = cdata.get("name", cid_local)
		name_lbl.position = Vector2(0, ch + 2)
		name_lbl.size     = Vector2(cw, 16)
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.add_theme_font_size_override("font_size", 8)
		name_lbl.add_theme_color_override("font_color", COLOR_TEXT)
		slot.add_child(name_lbl)

		# Overlay de selección (checkmark verde)
		var check_overlay = ColorRect.new()
		check_overlay.name         = "CheckOverlay"
		check_overlay.position     = Vector2.ZERO
		check_overlay.size         = Vector2(cw, ch)
		check_overlay.color        = Color(0.2, 0.9, 0.4, 0.35)
		check_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		check_overlay.visible      = false
		slot.add_child(check_overlay)

		var check_lbl = Label.new()
		check_lbl.name     = "CheckLabel"
		check_lbl.text     = "✓"
		check_lbl.position = Vector2(cw / 2.0 - 14, ch / 2.0 - 20)
		check_lbl.size     = Vector2(28, 28)
		check_lbl.add_theme_font_size_override("font_size", 32)
		check_lbl.add_theme_color_override("font_color", Color(0.1, 0.9, 0.3))
		check_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		check_lbl.visible  = false
		slot.add_child(check_lbl)

		# Botón invisible encima
		var btn = Button.new()
		btn.set_anchors_preset(Control.PRESET_FULL_RECT)
		btn.flat = true
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var hover_s = StyleBoxFlat.new()
		hover_s.bg_color                  = Color(1, 1, 1, 0.12)
		hover_s.corner_radius_top_left    = 6; hover_s.corner_radius_top_right    = 6
		hover_s.corner_radius_bottom_left = 6; hover_s.corner_radius_bottom_right = 6
		btn.add_theme_stylebox_override("hover", hover_s)

		btn.pressed.connect(func():
			var co = slot.get_node_or_null("CheckOverlay")
			var cl = slot.get_node_or_null("CheckLabel")
			if selected_ids.has(cid_local):
				selected_ids.erase(cid_local)
				if co: co.visible = false
				if cl: cl.visible = false
				slot_style.border_color = COLOR_GOLD_DIM
				slot_bg.add_theme_stylebox_override("panel", slot_style)
			elif selected_ids.size() < max_count:
				selected_ids.append(cid_local)
				if co: co.visible = true
				if cl: cl.visible = true
				slot_style.border_color = Color(0.2, 0.9, 0.4)
				slot_bg.add_theme_stylebox_override("panel", slot_style)

			if max_count == 1 and selected_ids.size() == 1:
				on_discard_selection_confirmed(selected_ids)
		)

		btn.mouse_entered.connect(func():
			var tw = slot.create_tween()
			tw.tween_property(slot, "scale", Vector2(1.06, 1.06), 0.08)
		)
		btn.mouse_exited.connect(func():
			var tw = slot.create_tween()
			tw.tween_property(slot, "scale", Vector2(1.0, 1.0), 0.08)
		)
		slot.add_child(btn)

	# Botones de acción
	var btn_row_y = panel_h - 48.0

	if max_count > 1:
		var confirm_btn = _make_button("✓  Confirmar", "CONFIRM_DISCARD")
		confirm_btn.position = Vector2(panel_w / 2.0 - 110, btn_row_y)
		confirm_btn.size     = Vector2(100, 32)
		confirm_btn.pressed.connect(func():
			if selected_ids.size() > 0:
				on_discard_selection_confirmed(selected_ids)
			else:
				emit_signal("trainer_message", "Selecciona al menos 1 carta")
		)
		panel.add_child(confirm_btn)

	var cancel_btn = _make_button("✕  Cancelar", "CANCEL_DISCARD")
	cancel_btn.position = Vector2(panel_w / 2.0 + 10, btn_row_y)
	cancel_btn.size     = Vector2(100, 32)
	cancel_btn.pressed.connect(func(): on_discard_selection_cancelled())
	panel.add_child(cancel_btn)

	# Animación de entrada
	panel.modulate.a = 0.0
	panel.scale      = Vector2(0.90, 0.90)
	var tw = panel.create_tween()
	tw.set_parallel(true)
	tw.tween_property(panel, "modulate:a", 1.0,         0.18)
	tw.tween_property(panel, "scale",      Vector2.ONE, 0.20).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	return popup


func _close_discard_selector() -> void:
	if _selection_popup:
		_selection_popup.queue_free()
		_selection_popup = null


# ============================================================
# HELPERS
# ============================================================
func _is_basic_energy(card_id: String) -> bool:
	return card_id in [
		"fire_energy", "water_energy", "grass_energy",
		"lightning_energy", "psychic_energy", "fighting_energy",
	]

func _make_button(label_text: String, _action: String) -> Button:
	var btn = Button.new()
	btn.text = label_text

	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color     = Color(0.12, 0.20, 0.14)
	style_normal.border_color = COLOR_GOLD_DIM
	style_normal.border_width_bottom = 1
	style_normal.corner_radius_top_left    = 4; style_normal.corner_radius_top_right    = 4
	style_normal.corner_radius_bottom_left = 4; style_normal.corner_radius_bottom_right = 4
	btn.add_theme_stylebox_override("normal", style_normal)

	var style_hover = StyleBoxFlat.new()
	style_hover.bg_color     = Color(0.20, 0.35, 0.22)
	style_hover.border_color = COLOR_GOLD
	style_hover.border_width_bottom = 1
	style_hover.corner_radius_top_left    = 4; style_hover.corner_radius_top_right    = 4
	style_hover.corner_radius_bottom_left = 4; style_hover.corner_radius_bottom_right = 4
	btn.add_theme_stylebox_override("hover", style_hover)

	btn.add_theme_color_override("font_color", COLOR_TEXT)
	btn.add_theme_font_size_override("font_size", 11)
	return btn
