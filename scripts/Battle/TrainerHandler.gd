extends Node

# ============================================================
# TrainerHandler.gd
# Los powers Fire Recharge y Downpour fueron movidos a PokePowerHandler.gd
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

var _last_hand_index: int    = -1
var _last_card_id:    String = ""
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

		"breeder_target":
			_targets["targetZone"]  = zone
			_targets["targetIndex"] = index
			_clear_highlights()
			_show_breeder_stage2_selector(zone, index)

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

		"hand_discard_one":
			if index != _hand_index:
				_targets["discardIndex"] = index
				_clear_highlights()
				_send()
			else:
				emit_signal("trainer_message", "Elige una carta diferente al trainer")

		"hand_discard":
			var indices: Array = _targets.get("discardIndices", [])
			if indices.has(index):
				indices.erase(index)
				_targets["discardIndices"] = indices
				emit_signal("trainer_message", "Deseleccionada. %d/2 elegidas" % indices.size())
			elif index != _hand_index:
				indices.append(index)
				_targets["discardIndices"] = indices
				emit_signal("trainer_message", "Seleccionada carta %d/2" % indices.size())
				if indices.size() >= 2:
					_clear_highlights()
					_send()

func on_discard_selection_confirmed(selected_ids: Array) -> void:
	if _card_id == "super_rod":
		_targets["selectedCardInstanceId"] = selected_ids[0] if selected_ids.size() > 0 else ""
		_targets["phase"] = "select"
	else:
		_targets["selectedCardInstanceIds"] = selected_ids
	_close_selection_popup()
	_send()

func on_discard_selection_cancelled() -> void:
	_close_selection_popup()
	cancel()

func on_pokegear_options(options: Array) -> void:
	if options.is_empty():
		return
	if options.size() == 1:
		_targets["selectedCardInstanceId"] = options[0].get("instance_id", "")
		_send()
		return
	_show_pokegear_selector(options)

func on_super_rod_options(flip_result: String, valid_options: Array) -> void:
	if valid_options.is_empty():
		emit_signal("trainer_message", "Super Rod: no hay Pokémon %s en el descarte" % flip_result)
		return
	_show_super_rod_selector(flip_result, valid_options)

func on_time_capsule_opponent_options(options: Array) -> void:
	_show_time_capsule_opponent_selector(options)

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

		# ── Neo Genesis ──────────────────────────────────────
		"professor_elm", "energy_charge", "sprout_tower", "ecogym", \
		"new_pokedex", "arcade_game", "card_flip_game", "bills_teleporter":
			_send()
			
		"mary":
			emit_signal("trainer_message", "Elige 2 cartas de tu mano para barajar al mazo...")
			_awaiting = "hand_discard"
			_targets["discardIndices"] = []
			emit_signal("trainer_highlight_zones", "hand")

		"pokegear":
			_send()

		"moo_moo_milk", "focus_band", "gold_berry", "berry", "miracle_berry", "super_scoop_up":
			emit_signal("trainer_message", "Elige el Pokémon objetivo...")
			_awaiting = "own_pokemon"
			emit_signal("trainer_highlight_zones", "own_pokemon")

		"time_capsule":
			emit_signal("trainer_message", "Elige la carta del descarte...")
			_show_discard_selector(false)

		"super_rod":
			_targets["phase"] = "flip"
			emit_signal("trainer_message", "Super Rod: tirando la moneda...")
			_send()

		"pokemon_march":
			_send()

		"double_gust":
			var my_data: Dictionary  = board.current_state.get("my", {})
			var my_bench: Array      = my_data.get("bench", [])
			var opp_data: Dictionary = board.current_state.get("opponent", {})
			var opp_bench: Array     = opp_data.get("bench", [])

			if my_bench.is_empty() and opp_bench.is_empty():
				emit_signal("trainer_message", "⚠ Double Gust: ningún banco tiene Pokémon")
				cancel()
				return

			if my_bench.is_empty():
				emit_signal("trainer_message", "Double Gust: elige el Pokémon del rival...")
				_awaiting = "double_gust_opp"
				emit_signal("trainer_highlight_zones", "opp_bench")
			elif opp_bench.is_empty():
				emit_signal("trainer_message", "Double Gust: elige tu Pokémon de banco...")
				_awaiting = "double_gust_mine"
				emit_signal("trainer_highlight_zones", "own_bench")
			else:
				emit_signal("trainer_message", "Double Gust: elige tu Pokémon de banco...")
				_awaiting = "double_gust_mine"
				emit_signal("trainer_highlight_zones", "own_bench")

		"super_energy_retrieval":
			emit_signal("trainer_message", "Elige 2 cartas de tu mano para descartar...")
			_awaiting = "hand_discard"
			_targets["discardIndices"] = []
			emit_signal("trainer_highlight_zones", "hand")

		# ── Legendary Collection ─────────────────────────────
		"lc_bill":
			_send()

		"lc_potion":
			emit_signal("trainer_message", "Elige el Pokémon objetivo...")
			_awaiting = "own_pokemon"
			emit_signal("trainer_highlight_zones", "own_pokemon")

		"lc_scoop-up":
			emit_signal("trainer_message", "Elige el Pokémon a devolver a la mano...")
			_awaiting = "own_pokemon"
			emit_signal("trainer_highlight_zones", "own_pokemon")

		"lc_energy-retrieval":
			emit_signal("trainer_message", "Elige 1 carta de tu mano para descartar...")
			_awaiting = "hand_discard_one"
			emit_signal("trainer_highlight_zones", "hand")

		"lc_pokemon-breeder":
			emit_signal("trainer_message", "Elige el Pokémon Básico a evolucionar directamente...")
			_awaiting = "breeder_target"
			emit_signal("trainer_highlight_zones", "own_pokemon")

		"lc_pokemon-trader":
			emit_signal("trainer_message", "Elige el Pokémon de tu mano a intercambiar...")
			_show_trader_hand_popup()

		"lc_challenge":
			# El cliente solo manda la acción. El servidor responde con
			# CHALLENGE_DECISION al rival y CHALLENGE_PICK_YOUR_BASICS al iniciador.
			# Los popups se muestran en on_challenge_decision / on_challenge_pick_basics.
			_send()

		"lc_the-boss-s-way":
			_send()

		"lc_mysterious-fossil":
			_send()

		"lc_full-heal-energy", "lc_potion-energy":
			emit_signal("trainer_message", "⚠ Esta es una carta de energía, no un Trainer")

		_:
			emit_signal("trainer_message", "⚠ Trainer no implementado: " + card_id)


# ============================================================
# ENVÍO DE ACCIÓN
# ============================================================
func _send() -> void:
	if _hand_index < 0:
		return
	_last_hand_index = _hand_index
	_last_card_id    = _card_id
	
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
# POKÉMON TRADER — popup en dos pasos: mano → mazo
# ============================================================
func _show_trader_hand_popup() -> void:
	if not board: return
	var my_data: Dictionary = board.current_state.get("my", {})
	var hand: Array         = my_data.get("hand", [])

	var valid_hand: Array = []
	for i in range(hand.size()):
		if i == _hand_index: continue
		var cid:   String     = hand[i].get("card_id", "")
		var cdata: Dictionary = CardDatabase.get_card(cid)
		if cdata.get("type", "") == "POKEMON":
			valid_hand.append({
				"hand_index":  i,
				"card_id":     cid,
				"instance_id": hand[i].get("instance_id", ""),
			})

	if valid_hand.is_empty():
		emit_signal("trainer_message", "⚠ No tienes Pokémon en la mano para intercambiar")
		cancel()
		return

	var vp: Vector2 = board.get_viewport().get_visible_rect().size
	var popup = _build_trader_hand_popup(vp, valid_hand)
	_selection_popup = popup
	board.add_child(popup)


func _build_trader_hand_popup(vp: Vector2, valid_hand: Array) -> Control:
	var popup = Control.new()
	popup.name = "TraderHandSelector"
	popup.set_anchors_preset(Control.PRESET_FULL_RECT)
	popup.z_index = 200

	var dim = ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.82)
	popup.add_child(dim)

	var panel_w: float = min(650.0, vp.x - 60)
	var panel_h: float = min(400.0, vp.y - 80)
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

	var title_lbl = Label.new()
	title_lbl.text        = "Pokémon Trader — Paso 1: elige el Pokémon de tu mano a ofrecer"
	title_lbl.position    = Vector2(16, 12)
	title_lbl.size        = Vector2(panel_w - 32, 36)
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.autowrap_mode        = TextServer.AUTOWRAP_WORD
	title_lbl.add_theme_font_size_override("font_size", 13)
	title_lbl.add_theme_color_override("font_color", COLOR_GOLD)
	panel.add_child(title_lbl)

	var scroll = ScrollContainer.new()
	scroll.position = Vector2(12, 58)
	scroll.size     = Vector2(panel_w - 24, panel_h - 118)
	panel.add_child(scroll)

	var flow = HFlowContainer.new()
	flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	flow.add_theme_constant_override("h_separation", 16)
	flow.add_theme_constant_override("v_separation", 12)
	scroll.add_child(flow)

	var card_scale: float = 0.65
	var cw: int = int(CARD_W * card_scale)
	var ch: int = int(CARD_H * card_scale)

	for entry in valid_hand:
		var cid:       String     = entry["card_id"]
		var iid:       String     = entry["instance_id"]
		var cdata:     Dictionary = CardDatabase.get_card(cid)
		var iid_local: String     = iid

		var slot = Control.new()
		slot.custom_minimum_size = Vector2(cw, ch + 24)
		flow.add_child(slot)

		var slot_bg    = Panel.new()
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

		var card_inst = CardDatabase.create_card_instance(cid)
		card_inst.scale        = Vector2(card_scale, card_scale)
		card_inst.is_draggable = false
		card_inst.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card_inst.position     = Vector2.ZERO
		slot.add_child(card_inst)

		var name_lbl = Label.new()
		name_lbl.text     = cdata.get("name", cid)
		name_lbl.position = Vector2(0, ch + 2)
		name_lbl.size     = Vector2(cw, 18)
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.add_theme_font_size_override("font_size", 9)
		name_lbl.add_theme_color_override("font_color", COLOR_TEXT)
		slot.add_child(name_lbl)

		var btn = Button.new()
		btn.set_anchors_preset(Control.PRESET_FULL_RECT)
		btn.flat = true
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var hover_s = StyleBoxFlat.new()
		hover_s.bg_color                  = Color(1, 1, 1, 0.14)
		hover_s.corner_radius_top_left    = 6; hover_s.corner_radius_top_right    = 6
		hover_s.corner_radius_bottom_left = 6; hover_s.corner_radius_bottom_right = 6
		btn.add_theme_stylebox_override("hover", hover_s)

		btn.pressed.connect(func():
			_close_selection_popup()
			_targets["handCardInstanceId"] = iid_local
			emit_signal("trainer_message", "Ahora elige el Pokémon del mazo que quieres...")
			_show_trader_deck_popup()
		)
		btn.mouse_entered.connect(func():
			slot.create_tween().tween_property(slot, "scale", Vector2(1.06, 1.06), 0.08)
		)
		btn.mouse_exited.connect(func():
			slot.create_tween().tween_property(slot, "scale", Vector2(1.0, 1.0), 0.08)
		)
		slot.add_child(btn)

	var cancel_btn = _make_button("✕  Cancelar", "CANCEL")
	cancel_btn.position = Vector2(panel_w / 2.0 - 50, panel_h - 48.0)
	cancel_btn.size     = Vector2(100, 32)
	cancel_btn.pressed.connect(func():
		_close_selection_popup()
		cancel()
	)
	panel.add_child(cancel_btn)

	_animate_panel_in(panel)
	return popup


func _show_trader_deck_popup() -> void:
	if not board: return
	var my_data: Dictionary = board.current_state.get("my", {})
	var deck_pokemon: Array = my_data.get("deck_pokemon_ids", [])

	if deck_pokemon.is_empty():
		emit_signal("trainer_message", "⚠ No hay Pokémon en tu mazo para intercambiar")
		cancel()
		return

	var vp: Vector2 = board.get_viewport().get_visible_rect().size
	var popup = _build_trader_deck_popup(vp, deck_pokemon)
	_selection_popup = popup
	board.add_child(popup)


func _build_trader_deck_popup(vp: Vector2, deck_pokemon: Array) -> Control:
	var popup = Control.new()
	popup.name = "TraderDeckSelector"
	popup.set_anchors_preset(Control.PRESET_FULL_RECT)
	popup.z_index = 200

	var dim = ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.82)
	popup.add_child(dim)

	var panel_w: float = min(650.0, vp.x - 60)
	var panel_h: float = min(400.0, vp.y - 80)
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

	var title_lbl = Label.new()
	title_lbl.text        = "Pokémon Trader — Paso 2: elige el Pokémon de tu mazo que quieres"
	title_lbl.position    = Vector2(16, 12)
	title_lbl.size        = Vector2(panel_w - 32, 36)
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.autowrap_mode        = TextServer.AUTOWRAP_WORD
	title_lbl.add_theme_font_size_override("font_size", 13)
	title_lbl.add_theme_color_override("font_color", COLOR_GOLD)
	panel.add_child(title_lbl)

	var scroll = ScrollContainer.new()
	scroll.position = Vector2(12, 58)
	scroll.size     = Vector2(panel_w - 24, panel_h - 118)
	panel.add_child(scroll)

	var flow = HFlowContainer.new()
	flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	flow.add_theme_constant_override("h_separation", 16)
	flow.add_theme_constant_override("v_separation", 12)
	scroll.add_child(flow)

	var card_scale: float = 0.65
	var cw: int = int(CARD_W * card_scale)
	var ch: int = int(CARD_H * card_scale)

	for cid in deck_pokemon:
		var cdata:     Dictionary = CardDatabase.get_card(cid)
		var cid_local: String     = str(cid)

		var slot = Control.new()
		slot.custom_minimum_size = Vector2(cw, ch + 24)
		flow.add_child(slot)

		var slot_bg    = Panel.new()
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

		var card_inst = CardDatabase.create_card_instance(cid_local)
		card_inst.scale        = Vector2(card_scale, card_scale)
		card_inst.is_draggable = false
		card_inst.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card_inst.position     = Vector2.ZERO
		slot.add_child(card_inst)

		var name_lbl = Label.new()
		name_lbl.text     = cdata.get("name", cid_local)
		name_lbl.position = Vector2(0, ch + 2)
		name_lbl.size     = Vector2(cw, 18)
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.add_theme_font_size_override("font_size", 9)
		name_lbl.add_theme_color_override("font_color", COLOR_TEXT)
		slot.add_child(name_lbl)

		var btn = Button.new()
		btn.set_anchors_preset(Control.PRESET_FULL_RECT)
		btn.flat = true
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var hover_s = StyleBoxFlat.new()
		hover_s.bg_color                  = Color(1, 1, 1, 0.14)
		hover_s.corner_radius_top_left    = 6; hover_s.corner_radius_top_right    = 6
		hover_s.corner_radius_bottom_left = 6; hover_s.corner_radius_bottom_right = 6
		btn.add_theme_stylebox_override("hover", hover_s)

		btn.pressed.connect(func():
			_close_selection_popup()
			_targets["deckCardId"] = cid_local
			_send()
			emit_signal("trainer_message",
				"Pokémon Trader: intercambiando por %s..." % cdata.get("name", cid_local))
		)
		btn.mouse_entered.connect(func():
			slot.create_tween().tween_property(slot, "scale", Vector2(1.06, 1.06), 0.08)
		)
		btn.mouse_exited.connect(func():
			slot.create_tween().tween_property(slot, "scale", Vector2(1.0, 1.0), 0.08)
		)
		slot.add_child(btn)

	var cancel_btn = _make_button("✕  Cancelar", "CANCEL")
	cancel_btn.position = Vector2(panel_w / 2.0 - 50, panel_h - 48.0)
	cancel_btn.size     = Vector2(100, 32)
	cancel_btn.pressed.connect(func():
		_close_selection_popup()
		cancel()
	)
	panel.add_child(cancel_btn)

	_animate_panel_in(panel)
	return popup


# ============================================================
# POKÉGEAR — popup de selección de Trainer
# ============================================================
func _show_pokegear_selector(options: Array) -> void:
	if not board: return
	var vp: Vector2 = board.get_viewport().get_visible_rect().size
	var popup: Control = _build_pokegear_popup(vp, options)
	_selection_popup = popup
	board.add_child(popup)


func _build_pokegear_popup(vp: Vector2, options: Array) -> Control:
	var popup = Control.new()
	popup.name = "PokegearSelector"
	popup.set_anchors_preset(Control.PRESET_FULL_RECT)
	popup.z_index = 200

	var dim = ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.82)
	popup.add_child(dim)

	var panel_w: float = min(600.0, vp.x - 60)
	var panel_h: float = min(380.0, vp.y - 80)
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

	var title_lbl = Label.new()
	title_lbl.text        = "Pokégear — Elige un Trainer del top 7"
	title_lbl.position    = Vector2(16, 12)
	title_lbl.size        = Vector2(panel_w - 32, 36)
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.autowrap_mode        = TextServer.AUTOWRAP_WORD
	title_lbl.add_theme_font_size_override("font_size", 13)
	title_lbl.add_theme_color_override("font_color", COLOR_GOLD)
	panel.add_child(title_lbl)

	var scroll = ScrollContainer.new()
	scroll.position = Vector2(12, 58)
	scroll.size     = Vector2(panel_w - 24, panel_h - 118)
	panel.add_child(scroll)

	var flow = HFlowContainer.new()
	flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	flow.add_theme_constant_override("h_separation", 16)
	flow.add_theme_constant_override("v_separation", 12)
	scroll.add_child(flow)

	var card_scale: float = 0.65
	var cw: int = int(CARD_W * card_scale)
	var ch: int = int(CARD_H * card_scale)

	for entry in options:
		var cid:       String     = entry.get("card_id", "")
		var iid:       String     = entry.get("instance_id", "")
		var cdata:     Dictionary = CardDatabase.get_card(cid)
		var iid_local: String     = iid

		var slot = Control.new()
		slot.custom_minimum_size = Vector2(cw, ch + 24)
		flow.add_child(slot)

		var slot_bg    = Panel.new()
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

		var card_inst = CardDatabase.create_card_instance(cid)
		card_inst.scale        = Vector2(card_scale, card_scale)
		card_inst.is_draggable = false
		card_inst.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card_inst.position     = Vector2.ZERO
		slot.add_child(card_inst)

		var name_lbl = Label.new()
		name_lbl.text     = cdata.get("name", cid)
		name_lbl.position = Vector2(0, ch + 2)
		name_lbl.size     = Vector2(cw, 18)
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.add_theme_font_size_override("font_size", 9)
		name_lbl.add_theme_color_override("font_color", COLOR_TEXT)
		slot.add_child(name_lbl)

		var btn = Button.new()
		btn.set_anchors_preset(Control.PRESET_FULL_RECT)
		btn.flat = true
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var hover_s = StyleBoxFlat.new()
		hover_s.bg_color                  = Color(1, 1, 1, 0.14)
		hover_s.corner_radius_top_left    = 6; hover_s.corner_radius_top_right    = 6
		hover_s.corner_radius_bottom_left = 6; hover_s.corner_radius_bottom_right = 6
		btn.add_theme_stylebox_override("hover", hover_s)

		btn.pressed.connect(func():
			_close_selection_popup()
			_targets["selectedCardInstanceId"] = iid_local
			_send()
			emit_signal("trainer_message",
				"Pokégear: tomando %s..." % cdata.get("name", cid))
		)
		btn.mouse_entered.connect(func():
			slot.create_tween().tween_property(slot, "scale", Vector2(1.06, 1.06), 0.08)
		)
		btn.mouse_exited.connect(func():
			slot.create_tween().tween_property(slot, "scale", Vector2(1.0, 1.0), 0.08)
		)
		slot.add_child(btn)

	var cancel_btn = _make_button("✕  Cancelar", "CANCEL")
	cancel_btn.position = Vector2(panel_w / 2.0 - 50, panel_h - 48.0)
	cancel_btn.size     = Vector2(100, 32)
	cancel_btn.pressed.connect(func():
		_close_selection_popup()
		cancel()
	)
	panel.add_child(cancel_btn)

	_animate_panel_in(panel)
	return popup


# ============================================================
# SUPER ROD — popup de selección post-moneda
# ============================================================
func _show_super_rod_selector(flip_result: String, valid_options: Array) -> void:
	if not board: return
	var vp: Vector2    = board.get_viewport().get_visible_rect().size
	var popup: Control = _build_super_rod_popup(vp, flip_result, valid_options)
	_selection_popup   = popup
	board.add_child(popup)


func _build_super_rod_popup(vp: Vector2, flip_result: String, valid_options: Array) -> Control:
	var popup = Control.new()
	popup.name = "SuperRodSelector"
	popup.set_anchors_preset(Control.PRESET_FULL_RECT)
	popup.z_index = 200

	var dim = ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.82)
	popup.add_child(dim)

	var panel_w: float = min(600.0, vp.x - 60)
	var panel_h: float = min(400.0, vp.y - 80)
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

	var type_label: String = "Evolución" if flip_result == "evolution" else "Pokémon Básico"
	var coin_label: String = "🪙 Cara — elige 1 %s" % type_label if flip_result == "evolution" \
		else "🪙 Cruz — elige 1 %s" % type_label

	var title_lbl = Label.new()
	title_lbl.text        = "Super Rod: %s del descarte" % coin_label
	title_lbl.position    = Vector2(16, 12)
	title_lbl.size        = Vector2(panel_w - 32, 36)
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.autowrap_mode        = TextServer.AUTOWRAP_WORD
	title_lbl.add_theme_font_size_override("font_size", 13)
	title_lbl.add_theme_color_override("font_color", COLOR_GOLD)
	panel.add_child(title_lbl)

	var scroll = ScrollContainer.new()
	scroll.position = Vector2(12, 58)
	scroll.size     = Vector2(panel_w - 24, panel_h - 118)
	panel.add_child(scroll)

	var flow = HFlowContainer.new()
	flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	flow.add_theme_constant_override("h_separation", 16)
	flow.add_theme_constant_override("v_separation", 12)
	scroll.add_child(flow)

	var card_scale: float = 0.65
	var cw: int = int(CARD_W * card_scale)
	var ch: int = int(CARD_H * card_scale)

	for entry in valid_options:
		var cid:       String     = entry.get("card_id", "")
		var iid:       String     = entry.get("instance_id", "")
		var cdata:     Dictionary = CardDatabase.get_card(cid)
		var iid_local: String     = iid

		var slot = Control.new()
		slot.custom_minimum_size = Vector2(cw, ch + 24)
		flow.add_child(slot)

		var slot_bg    = Panel.new()
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

		var card_inst = CardDatabase.create_card_instance(cid)
		card_inst.scale        = Vector2(card_scale, card_scale)
		card_inst.is_draggable = false
		card_inst.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card_inst.position     = Vector2.ZERO
		slot.add_child(card_inst)

		var name_lbl = Label.new()
		name_lbl.text     = cdata.get("name", cid)
		name_lbl.position = Vector2(0, ch + 2)
		name_lbl.size     = Vector2(cw, 18)
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.add_theme_font_size_override("font_size", 9)
		name_lbl.add_theme_color_override("font_color", COLOR_TEXT)
		slot.add_child(name_lbl)

		var btn = Button.new()
		btn.set_anchors_preset(Control.PRESET_FULL_RECT)
		btn.flat = true
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var hover_s = StyleBoxFlat.new()
		hover_s.bg_color                  = Color(1, 1, 1, 0.14)
		hover_s.corner_radius_top_left    = 6; hover_s.corner_radius_top_right    = 6
		hover_s.corner_radius_bottom_left = 6; hover_s.corner_radius_bottom_right = 6
		btn.add_theme_stylebox_override("hover", hover_s)

		btn.pressed.connect(func():
			_close_selection_popup()
			on_discard_selection_confirmed([iid_local])
			emit_signal("trainer_message",
				"Super Rod: recuperando %s..." % cdata.get("name", cid))
		)
		btn.mouse_entered.connect(func():
			slot.create_tween().tween_property(slot, "scale", Vector2(1.06, 1.06), 0.08)
		)
		btn.mouse_exited.connect(func():
			slot.create_tween().tween_property(slot, "scale", Vector2(1.0, 1.0), 0.08)
		)
		slot.add_child(btn)

	var cancel_btn = _make_button("✕  No recuperar nada", "CANCEL")
	cancel_btn.position = Vector2(panel_w / 2.0 - 70, panel_h - 48.0)
	cancel_btn.size     = Vector2(140, 32)
	cancel_btn.pressed.connect(func():
		_close_selection_popup()
		_targets["phase"] = "select"
		_targets["selectedCardInstanceId"] = ""
		_send()
	)
	panel.add_child(cancel_btn)

	_animate_panel_in(panel)
	return popup


# ============================================================
# TIME CAPSULE — popup para que el RIVAL elija sus cartas
# ============================================================
func _show_time_capsule_opponent_selector(options: Array) -> void:
	if not board: return
	var vp: Vector2    = board.get_viewport().get_visible_rect().size
	var popup: Control = _build_time_capsule_opponent_popup(vp, options)
	_selection_popup   = popup
	board.add_child(popup)


func _build_time_capsule_opponent_popup(vp: Vector2, options: Array) -> Control:
	var popup = Control.new()
	popup.name = "TimeCapsuleSelector"
	popup.set_anchors_preset(Control.PRESET_FULL_RECT)
	popup.z_index = 200

	var dim = ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.88)
	popup.add_child(dim)

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

	var title_lbl = Label.new()
	title_lbl.text        = "Time Capsule — Elige hasta 5 cartas para barajar en tu mazo"
	title_lbl.position    = Vector2(16, 12)
	title_lbl.size        = Vector2(panel_w - 32, 36)
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.autowrap_mode        = TextServer.AUTOWRAP_WORD
	title_lbl.add_theme_font_size_override("font_size", 13)
	title_lbl.add_theme_color_override("font_color", COLOR_GOLD)
	panel.add_child(title_lbl)

	var scroll = ScrollContainer.new()
	scroll.position = Vector2(12, 58)
	scroll.size     = Vector2(panel_w - 24, panel_h - 118)
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

	for entry in options:
		var cid:       String     = entry.get("card_id", "")
		var cdata:     Dictionary = CardDatabase.get_card(cid)
		var cid_local: String     = cid

		var slot = Control.new()
		slot.custom_minimum_size = Vector2(cw, ch + 20)
		flow.add_child(slot)

		var slot_bg    = Panel.new()
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

		var card_inst = CardDatabase.create_card_instance(cid)
		card_inst.scale        = Vector2(card_scale, card_scale)
		card_inst.is_draggable = false
		card_inst.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card_inst.position     = Vector2.ZERO
		slot.add_child(card_inst)

		var name_lbl = Label.new()
		name_lbl.text     = cdata.get("name", cid)
		name_lbl.position = Vector2(0, ch + 2)
		name_lbl.size     = Vector2(cw, 16)
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.add_theme_font_size_override("font_size", 8)
		name_lbl.add_theme_color_override("font_color", COLOR_TEXT)
		slot.add_child(name_lbl)

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
			elif selected_ids.size() < 5:
				selected_ids.append(cid_local)
				if co: co.visible = true
				if cl: cl.visible = true
				slot_style.border_color = Color(0.2, 0.9, 0.4)
				slot_bg.add_theme_stylebox_override("panel", slot_style)
		)
		btn.mouse_entered.connect(func():
			slot.create_tween().tween_property(slot, "scale", Vector2(1.06, 1.06), 0.08)
		)
		btn.mouse_exited.connect(func():
			slot.create_tween().tween_property(slot, "scale", Vector2(1.0, 1.0), 0.08)
		)
		slot.add_child(btn)

	var btn_row_y = panel_h - 48.0

	var confirm_btn = _make_button("✓  Confirmar", "CONFIRM")
	confirm_btn.position = Vector2(panel_w / 2.0 - 110, btn_row_y)
	confirm_btn.size     = Vector2(100, 32)
	confirm_btn.pressed.connect(func():
		_close_selection_popup()
		NetworkManager.send_action("RESOLVE_TIME_CAPSULE_OPPONENT", {
			"oppSelectedIds": selected_ids,
		})
		emit_signal("trainer_message", "Time Capsule: confirmado (%d cartas)" % selected_ids.size())
	)
	panel.add_child(confirm_btn)

	var skip_btn = _make_button("↩  No elegir nada", "SKIP")
	skip_btn.position = Vector2(panel_w / 2.0 + 10, btn_row_y)
	skip_btn.size     = Vector2(130, 32)
	skip_btn.pressed.connect(func():
		_close_selection_popup()
		NetworkManager.send_action("RESOLVE_TIME_CAPSULE_OPPONENT", {"oppSelectedIds": []})
		emit_signal("trainer_message", "Time Capsule: decidiste no barajar nada")
	)
	panel.add_child(skip_btn)

	_animate_panel_in(panel)
	return popup


# ============================================================
# POKÉMON BREEDER — selector de Stage 2
# ============================================================
func handle_pokemon_march_options(options: Dictionary) -> void:
	if _selection_popup != null \
			and is_instance_valid(_selection_popup) \
			and _selection_popup.name == "PokemonMarchSelector":
		return

	var available:  Array = options.get("available", [])
	var bench_full: bool  = options.get("benchFull", false)

	if bench_full:
		NetworkManager.send_action("RESOLVE_POKEMON_MARCH", {"selectedCardId": ""})
		emit_signal("trainer_message", "Tu banco está lleno, Pokémon March sin efecto para ti")
		return

	_show_deck_march_popup(available)


func _show_breeder_stage2_selector(target_zone: String, target_index: int) -> void:
	if not board: return

	var my_data = board.current_state.get("my", {})

	var target_poke: Dictionary = {}
	if target_zone == "active":
		target_poke = my_data.get("active", {})
	else:
		var bench = my_data.get("bench", [])
		if target_index < bench.size() and bench[target_index] != null:
			target_poke = bench[target_index]

	var basic_id   = target_poke.get("card_id", "")
	var basic_data = CardDatabase.get_card(basic_id)
	var basic_name = basic_data.get("name", basic_id)

	var hand: Array = my_data.get("hand", [])
	var valid_stage2: Array = []

	for i in range(hand.size()):
		if i == _hand_index: continue
		var cid   = hand[i].get("card_id", "")
		var cdata = CardDatabase.get_card(cid)
		if cdata.get("type", "") != "POKEMON": continue
		if int(str(cdata.get("stage", 0))) != 2: continue
		valid_stage2.append({"hand_index": i, "card_id": cid})

	if valid_stage2.is_empty():
		emit_signal("trainer_message", "⚠ No tienes cartas Stage 2 en la mano")
		cancel()
		return

	if valid_stage2.size() == 1:
		_targets["stage2CardId"] = valid_stage2[0]["card_id"]
		_send()
		return

	var vp: Vector2 = board.get_viewport().get_visible_rect().size
	var popup = _build_breeder_popup(vp, valid_stage2, basic_name)
	_selection_popup = popup
	board.add_child(popup)


func _build_breeder_popup(vp: Vector2, valid_stage2: Array, basic_name: String) -> Control:
	var popup = Control.new()
	popup.name = "BreederSelector"
	popup.set_anchors_preset(Control.PRESET_FULL_RECT)
	popup.z_index = 200

	var dim = ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.82)
	popup.add_child(dim)

	var panel_w: float = min(600.0, vp.x - 60)
	var panel_h: float = min(380.0, vp.y - 80)
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

	var title_lbl = Label.new()
	title_lbl.text        = "Pokémon Breeder — Elige el Stage 2 para %s" % basic_name
	title_lbl.position    = Vector2(16, 12)
	title_lbl.size        = Vector2(panel_w - 32, 36)
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.autowrap_mode        = TextServer.AUTOWRAP_WORD
	title_lbl.add_theme_font_size_override("font_size", 13)
	title_lbl.add_theme_color_override("font_color", COLOR_GOLD)
	panel.add_child(title_lbl)

	var scroll = ScrollContainer.new()
	scroll.position = Vector2(12, 58)
	scroll.size     = Vector2(panel_w - 24, panel_h - 118)
	panel.add_child(scroll)

	var flow = HFlowContainer.new()
	flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	flow.add_theme_constant_override("h_separation", 16)
	flow.add_theme_constant_override("v_separation", 12)
	scroll.add_child(flow)

	var card_scale: float = 0.65
	var cw: int = int(CARD_W * card_scale)
	var ch: int = int(CARD_H * card_scale)

	for entry in valid_stage2:
		var cid:   String     = entry["card_id"]
		var cdata: Dictionary = CardDatabase.get_card(cid)

		var slot = Control.new()
		slot.custom_minimum_size = Vector2(cw, ch + 24)
		flow.add_child(slot)

		var slot_bg    = Panel.new()
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

		var card_inst = CardDatabase.create_card_instance(cid)
		card_inst.scale        = Vector2(card_scale, card_scale)
		card_inst.is_draggable = false
		card_inst.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card_inst.position     = Vector2.ZERO
		slot.add_child(card_inst)

		var name_lbl = Label.new()
		name_lbl.text     = cdata.get("name", cid)
		name_lbl.position = Vector2(0, ch + 2)
		name_lbl.size     = Vector2(cw, 18)
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.add_theme_font_size_override("font_size", 9)
		name_lbl.add_theme_color_override("font_color", COLOR_TEXT)
		slot.add_child(name_lbl)

		var btn = Button.new()
		btn.set_anchors_preset(Control.PRESET_FULL_RECT)
		btn.flat = true
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var hover_s = StyleBoxFlat.new()
		hover_s.bg_color                  = Color(1, 1, 1, 0.14)
		hover_s.corner_radius_top_left    = 6; hover_s.corner_radius_top_right    = 6
		hover_s.corner_radius_bottom_left = 6; hover_s.corner_radius_bottom_right = 6
		btn.add_theme_stylebox_override("hover", hover_s)

		var cid_local: String = cid
		btn.pressed.connect(func():
			_close_selection_popup()
			_targets["stage2CardId"] = cid_local
			_send()
			emit_signal("trainer_message",
				"Pokémon Breeder: evolucionando a %s..." % cdata.get("name", cid_local))
		)
		btn.mouse_entered.connect(func():
			slot.create_tween().tween_property(slot, "scale", Vector2(1.06, 1.06), 0.08)
		)
		btn.mouse_exited.connect(func():
			slot.create_tween().tween_property(slot, "scale", Vector2(1.0, 1.0), 0.08)
		)
		slot.add_child(btn)

	var cancel_btn = _make_button("✕  Cancelar", "CANCEL")
	cancel_btn.position = Vector2(panel_w / 2.0 - 50, panel_h - 48.0)
	cancel_btn.size     = Vector2(100, 32)
	cancel_btn.pressed.connect(func():
		_close_selection_popup()
		cancel()
	)
	panel.add_child(cancel_btn)

	_animate_panel_in(panel)
	return popup


# ============================================================
# POKÉMON MARCH — popup del MAZO
# ============================================================
func _show_deck_march_popup(available: Array) -> void:
	if not board: return
	var vp: Vector2 = board.get_viewport().get_visible_rect().size
	var popup: Control = _build_deck_march_popup(vp, available)
	_selection_popup = popup
	board.add_child(popup)


func _build_deck_march_popup(vp: Vector2, available: Array) -> Control:
	var popup = Control.new()
	popup.name = "PokemonMarchSelector"
	popup.set_anchors_preset(Control.PRESET_FULL_RECT)
	popup.z_index = 200

	var dim = ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.82)
	popup.add_child(dim)

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

	var title_lbl = Label.new()
	title_lbl.position = Vector2(16, 12)
	title_lbl.size     = Vector2(panel_w - 32, 30)
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 15)
	title_lbl.add_theme_color_override("font_color", COLOR_GOLD)
	panel.add_child(title_lbl)

	var skip_btn = _make_button("↩  No poner nada", "SKIP")
	skip_btn.position = Vector2(panel_w / 2.0 - 80, panel_h - 48.0)
	skip_btn.size     = Vector2(160, 32)
	skip_btn.pressed.connect(func():
		_close_selection_popup()
		NetworkManager.send_action("RESOLVE_POKEMON_MARCH", {"selectedCardId": ""})
		emit_signal("trainer_message", "Pokémon March: decidiste no poner nada")
	)
	panel.add_child(skip_btn)

	if available.is_empty():
		title_lbl.text = "Pokémon March — No hay Básicos en tu mazo"
		var empty_lbl = Label.new()
		empty_lbl.text = "No tienes Pokémon Básicos en el mazo"
		empty_lbl.position = Vector2(0, panel_h / 2.0 - 20)
		empty_lbl.size     = Vector2(panel_w, 30)
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_lbl.add_theme_color_override("font_color", COLOR_TEXT)
		empty_lbl.add_theme_font_size_override("font_size", 13)
		panel.add_child(empty_lbl)
		_animate_panel_in(panel)
		return popup

	title_lbl.text = "Pokémon March — Elige 1 Básico de tu mazo (o salta)"

	var scroll = ScrollContainer.new()
	scroll.position = Vector2(12, 50)
	scroll.size     = Vector2(panel_w - 24, panel_h - 110)
	panel.add_child(scroll)

	var flow = HFlowContainer.new()
	flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	flow.add_theme_constant_override("h_separation", 12)
	flow.add_theme_constant_override("v_separation", 12)
	scroll.add_child(flow)

	var card_scale := 0.65
	var cw         := int(CARD_W * card_scale)
	var ch         := int(CARD_H * card_scale)

	for cid in available:
		var cdata:     Dictionary = CardDatabase.get_card(cid)
		var cid_local: String     = str(cid)

		var slot = Control.new()
		slot.custom_minimum_size = Vector2(cw, ch + 20)
		flow.add_child(slot)

		var slot_bg    = Panel.new()
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

		var card_inst = CardDatabase.create_card_instance(cid_local)
		card_inst.scale        = Vector2(card_scale, card_scale)
		card_inst.is_draggable = false
		card_inst.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card_inst.position     = Vector2.ZERO
		slot.add_child(card_inst)

		var name_lbl = Label.new()
		name_lbl.text     = cdata.get("name", cid_local)
		name_lbl.position = Vector2(0, ch + 2)
		name_lbl.size     = Vector2(cw, 16)
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.add_theme_font_size_override("font_size", 8)
		name_lbl.add_theme_color_override("font_color", COLOR_TEXT)
		slot.add_child(name_lbl)

		var btn = Button.new()
		btn.set_anchors_preset(Control.PRESET_FULL_RECT)
		btn.flat = true
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var hover_s = StyleBoxFlat.new()
		hover_s.bg_color                  = Color(1, 1, 1, 0.14)
		hover_s.corner_radius_top_left    = 6; hover_s.corner_radius_top_right    = 6
		hover_s.corner_radius_bottom_left = 6; hover_s.corner_radius_bottom_right = 6
		btn.add_theme_stylebox_override("hover", hover_s)

		btn.pressed.connect(func():
			_close_selection_popup()
			NetworkManager.send_action("RESOLVE_POKEMON_MARCH", {"selectedCardId": cid_local})
			emit_signal("trainer_message",
				"Pokémon March: poniendo %s en el banco..." % cdata.get("name", cid_local))
		)
		btn.mouse_entered.connect(func():
			slot.create_tween().tween_property(slot, "scale", Vector2(1.06, 1.06), 0.08)
		)
		btn.mouse_exited.connect(func():
			slot.create_tween().tween_property(slot, "scale", Vector2(1.0, 1.0), 0.08)
		)
		slot.add_child(btn)

	_animate_panel_in(panel)
	return popup


# ============================================================
# POPUP DE SELECCIÓN DE DESCARTE
# ============================================================
func _show_discard_selector(only_basic_pokemon: bool, max_count: int = 99) -> void:
	if not board: return

	var my_discard: Array = board.current_state.get("my", {}).get("discard", [])
	var candidates: Array = _build_discard_candidates(my_discard, only_basic_pokemon)

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

	var dim = ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.82)
	popup.add_child(dim)

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

	var title_lbl = Label.new()
	title_lbl.text = "🗑  Elige %s del descarte" % \
		("1 carta" if max_count == 1 else "hasta %d cartas" % max_count)
	title_lbl.position = Vector2(16, 12)
	title_lbl.size     = Vector2(panel_w - 32, 30)
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 15)
	title_lbl.add_theme_color_override("font_color", COLOR_GOLD)
	panel.add_child(title_lbl)

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
		var cdata:     Dictionary = CardDatabase.get_card(cid)
		var cid_local: String     = str(cid)

		var slot = Control.new()
		slot.custom_minimum_size = Vector2(cw, ch + 20)
		flow.add_child(slot)

		var slot_bg    = Panel.new()
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

		var card_inst = CardDatabase.create_card_instance(cid_local)
		card_inst.scale        = Vector2(card_scale, card_scale)
		card_inst.is_draggable = false
		card_inst.position     = Vector2.ZERO
		card_inst.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(card_inst)

		var name_lbl = Label.new()
		name_lbl.text     = cdata.get("name", cid_local)
		name_lbl.position = Vector2(0, ch + 2)
		name_lbl.size     = Vector2(cw, 16)
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.add_theme_font_size_override("font_size", 8)
		name_lbl.add_theme_color_override("font_color", COLOR_TEXT)
		slot.add_child(name_lbl)

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
			slot.create_tween().tween_property(slot, "scale", Vector2(1.06, 1.06), 0.08)
		)
		btn.mouse_exited.connect(func():
			slot.create_tween().tween_property(slot, "scale", Vector2(1.0, 1.0), 0.08)
		)
		slot.add_child(btn)

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

	_animate_panel_in(panel)
	return popup


# ============================================================
# HELPERS COMPARTIDOS DE POPUP
# ============================================================
func _close_selection_popup() -> void:
	if _selection_popup and is_instance_valid(_selection_popup):
		_selection_popup.queue_free()
	_selection_popup = null

func _animate_panel_in(panel: Control) -> void:
	panel.modulate.a = 0.0
	panel.scale      = Vector2(0.90, 0.90)
	var tw = panel.create_tween()
	tw.set_parallel(true)
	tw.tween_property(panel, "modulate:a", 1.0,         0.18)
	tw.tween_property(panel, "scale",      Vector2.ONE, 0.20) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


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
	style_normal.bg_color                  = Color(0.12, 0.20, 0.14)
	style_normal.border_color              = COLOR_GOLD_DIM
	style_normal.border_width_bottom       = 1
	style_normal.corner_radius_top_left    = 4; style_normal.corner_radius_top_right    = 4
	style_normal.corner_radius_bottom_left = 4; style_normal.corner_radius_bottom_right = 4
	btn.add_theme_stylebox_override("normal", style_normal)

	var style_hover = StyleBoxFlat.new()
	style_hover.bg_color                  = Color(0.20, 0.35, 0.22)
	style_hover.border_color              = COLOR_GOLD
	style_hover.border_width_bottom       = 1
	style_hover.corner_radius_top_left    = 4; style_hover.corner_radius_top_right    = 4
	style_hover.corner_radius_bottom_left = 4; style_hover.corner_radius_bottom_right = 4
	btn.add_theme_stylebox_override("hover", style_hover)

	btn.add_theme_color_override("font_color", COLOR_TEXT)
	btn.add_theme_font_size_override("font_size", 11)
	return btn

func on_new_pokedex_options(cards: Array) -> void:
	if cards.is_empty(): return
	if not board: return
	var vp: Vector2 = board.get_viewport().get_visible_rect().size
	var popup = _build_new_pokedex_popup(vp, cards)
	_selection_popup = popup
	board.add_child(popup)


func _build_new_pokedex_popup(vp: Vector2, cards: Array) -> Control:
	var popup = Control.new()
	popup.name = "NewPokedexSelector"
	popup.set_anchors_preset(Control.PRESET_FULL_RECT)
	popup.z_index = 200

	var dim = ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.88)
	popup.add_child(dim)

	var panel_w: float = min(560.0, vp.x - 60)
	var panel_h: float = min(580.0, vp.y - 60)
	var panel = Panel.new()
	panel.position = Vector2((vp.x - panel_w) / 2.0, (vp.y - panel_h) / 2.0)
	panel.size     = Vector2(panel_w, panel_h)

	var pstyle = StyleBoxFlat.new()
	pstyle.bg_color                  = Color(0.04, 0.05, 0.08, 0.99)
	pstyle.border_color              = COLOR_GOLD
	pstyle.border_width_left         = 2; pstyle.border_width_right  = 2
	pstyle.border_width_top          = 2; pstyle.border_width_bottom = 2
	pstyle.corner_radius_top_left    = 18; pstyle.corner_radius_top_right    = 18
	pstyle.corner_radius_bottom_left = 18; pstyle.corner_radius_bottom_right = 18
	pstyle.shadow_color = Color(COLOR_GOLD.r, COLOR_GOLD.g, COLOR_GOLD.b, 0.25)
	pstyle.shadow_size  = 24
	panel.add_theme_stylebox_override("panel", pstyle)
	popup.add_child(panel)

	# Header
	var header_bg = Panel.new()
	header_bg.position = Vector2(0, 0)
	header_bg.size     = Vector2(panel_w, 62)
	var hdr_s = StyleBoxFlat.new()
	hdr_s.bg_color = Color(0.08, 0.10, 0.16, 1.0)
	hdr_s.corner_radius_top_left  = 18; hdr_s.corner_radius_top_right = 18
	header_bg.add_theme_stylebox_override("panel", hdr_s)
	panel.add_child(header_bg)

	var title_lbl = Label.new()
	title_lbl.text     = "📖  NEW POKÉDEX"
	title_lbl.position = Vector2(0, 8)
	title_lbl.size     = Vector2(panel_w, 28)
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 20)
	title_lbl.add_theme_color_override("font_color", COLOR_GOLD)
	panel.add_child(title_lbl)

	var hint = Label.new()
	hint.text     = "Reordena el top 5 de tu mazo con ↑ ↓"
	hint.position = Vector2(0, 38)
	hint.size     = Vector2(panel_w, 18)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 11)
	hint.add_theme_color_override("font_color", Color(0.55, 0.55, 0.65))
	panel.add_child(hint)

	var sep = ColorRect.new()
	sep.color    = Color(COLOR_GOLD.r, COLOR_GOLD.g, COLOR_GOLD.b, 0.18)
	sep.position = Vector2(0, 62)
	sep.size     = Vector2(panel_w, 1)
	panel.add_child(sep)

	# Lista reordenable
	var list_container = VBoxContainer.new()
	list_container.name     = "CardList"
	list_container.position = Vector2(20, 72)
	list_container.size     = Vector2(panel_w - 40, panel_h - 140)
	list_container.add_theme_constant_override("separation", 8)
	panel.add_child(list_container)

	var ordered: Array = cards.duplicate()

	# Colores por tipo de carta
	var _type_color = func(card_id: String) -> Color:
		var cd = CardDatabase.get_card(card_id)
		var t  = cd.get("pokemon_type", cd.get("type", "")).to_upper()
		match t:
			"FIRE":      return Color(0.92, 0.42, 0.15)
			"WATER":     return Color(0.18, 0.62, 0.88)
			"GRASS":     return Color(0.32, 0.72, 0.36)
			"LIGHTNING": return Color(0.98, 0.85, 0.10)
			"PSYCHIC":   return Color(0.80, 0.25, 0.72)
			"FIGHTING":  return Color(0.78, 0.52, 0.30)
			"DARKNESS":  return Color(0.40, 0.35, 0.65)
			"METAL":     return Color(0.55, 0.62, 0.70)
			"ENERGY":    return Color(0.55, 0.55, 0.55)
			"TRAINER":   return Color(0.85, 0.72, 0.30)
		return Color(0.55, 0.55, 0.55)

	var refresh_list = func(self_ref: Callable):
		for c in list_container.get_children(): c.queue_free()

		for i in range(ordered.size()):
			var entry    = ordered[i]
			var cid:     String     = entry.get("card_id", "")
			var cdata:   Dictionary = CardDatabase.get_card(cid)
			var i_local: int        = i
			var accent:  Color      = _type_color.call(cid)

			var row_panel = Panel.new()
			row_panel.custom_minimum_size = Vector2(panel_w - 40, 72)
			var row_s = StyleBoxFlat.new()
			row_s.bg_color     = Color(accent.r * 0.12, accent.g * 0.12, accent.b * 0.12, 0.95)
			row_s.border_color = Color(accent.r, accent.g, accent.b, 0.40)
			row_s.border_width_left  = 3
			row_s.border_width_right = 1
			row_s.border_width_top   = 1
			row_s.border_width_bottom = 1
			row_s.corner_radius_top_left    = 10; row_s.corner_radius_top_right    = 10
			row_s.corner_radius_bottom_left = 10; row_s.corner_radius_bottom_right = 10
			row_panel.add_theme_stylebox_override("panel", row_s)
			list_container.add_child(row_panel)

			var row = HBoxContainer.new()
			row.set_anchors_preset(Control.PRESET_FULL_RECT)
			row.add_theme_constant_override("separation", 10)
			row.offset_left  = 8; row.offset_right  = -8
			row.offset_top   = 4; row.offset_bottom = -4
			row_panel.add_child(row)

			# Número de posición
			var pos_lbl = Label.new()
			pos_lbl.text = str(i + 1)
			pos_lbl.custom_minimum_size = Vector2(22, 0)
			pos_lbl.add_theme_font_size_override("font_size", 18)
			pos_lbl.add_theme_color_override("font_color", Color(accent.r, accent.g, accent.b, 0.70))
			pos_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
			pos_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			row.add_child(pos_lbl)

			# Miniatura de la carta
			var card_tex_rect = TextureRect.new()
			card_tex_rect.custom_minimum_size = Vector2(44, 62)
			card_tex_rect.expand_mode         = TextureRect.EXPAND_IGNORE_SIZE
			card_tex_rect.stretch_mode        = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			card_tex_rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			var img_path = LanguageManager.get_card_image(cdata) if cdata.has("image") else ""
			if img_path != "" and ResourceLoader.exists(img_path):
				card_tex_rect.texture = load(img_path)
			row.add_child(card_tex_rect)

			# Nombre y tipo
			var info_col = VBoxContainer.new()
			info_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			info_col.size_flags_vertical   = Control.SIZE_SHRINK_CENTER
			info_col.add_theme_constant_override("separation", 2)
			row.add_child(info_col)

			var name_lbl = Label.new()
			name_lbl.text = cdata.get("name", cid).to_upper()
			name_lbl.add_theme_font_size_override("font_size", 14)
			name_lbl.add_theme_color_override("font_color", COLOR_TEXT)
			info_col.add_child(name_lbl)

			var type_lbl = Label.new()
			var card_type = cdata.get("type", "").to_upper()
			var poke_type = cdata.get("pokemon_type", "").to_upper()
			type_lbl.text = poke_type if poke_type != "" else card_type
			type_lbl.add_theme_font_size_override("font_size", 10)
			type_lbl.add_theme_color_override("font_color", Color(accent.r, accent.g, accent.b, 0.80))
			info_col.add_child(type_lbl)

			# Botones ↑ ↓
			var btn_col = VBoxContainer.new()
			btn_col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			btn_col.add_theme_constant_override("separation", 4)
			row.add_child(btn_col)

			var up_btn = Button.new()
			up_btn.text = "↑"
			up_btn.custom_minimum_size = Vector2(34, 28)
			up_btn.disabled = (i == 0)
			up_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			var up_s = StyleBoxFlat.new()
			up_s.bg_color     = Color(0.15, 0.22, 0.15, 0.9) if not up_btn.disabled else Color(0.08, 0.08, 0.08, 0.5)
			up_s.border_color = Color(0.30, 0.80, 0.35, 0.6) if not up_btn.disabled else Color(0.2, 0.2, 0.2, 0.3)
			up_s.set_border_width_all(1)
			up_s.set_corner_radius_all(6)
			up_btn.add_theme_stylebox_override("normal", up_s)
			var up_h = up_s.duplicate()
			up_h.bg_color = Color(0.22, 0.38, 0.22, 1.0)
			up_btn.add_theme_stylebox_override("hover", up_h)
			up_btn.add_theme_font_size_override("font_size", 14)
			up_btn.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
			up_btn.pressed.connect(func():
				var tmp = ordered[i_local - 1]
				ordered[i_local - 1] = ordered[i_local]
				ordered[i_local]     = tmp
				# Animación flash
				var tw = row_panel.create_tween()
				tw.tween_property(row_panel, "modulate", Color(1.4, 1.4, 1.0), 0.08)
				tw.tween_property(row_panel, "modulate", Color.WHITE, 0.15)
				self_ref.call(self_ref)
			)
			btn_col.add_child(up_btn)

			var dn_btn = Button.new()
			dn_btn.text = "↓"
			dn_btn.custom_minimum_size = Vector2(34, 28)
			dn_btn.disabled = (i == ordered.size() - 1)
			dn_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			var dn_s = StyleBoxFlat.new()
			dn_s.bg_color     = Color(0.15, 0.22, 0.15, 0.9) if not dn_btn.disabled else Color(0.08, 0.08, 0.08, 0.5)
			dn_s.border_color = Color(0.30, 0.80, 0.35, 0.6) if not dn_btn.disabled else Color(0.2, 0.2, 0.2, 0.3)
			dn_s.set_border_width_all(1)
			dn_s.set_corner_radius_all(6)
			dn_btn.add_theme_stylebox_override("normal", dn_s)
			var dn_h = dn_s.duplicate()
			dn_h.bg_color = Color(0.22, 0.38, 0.22, 1.0)
			dn_btn.add_theme_stylebox_override("hover", dn_h)
			dn_btn.add_theme_font_size_override("font_size", 14)
			dn_btn.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
			dn_btn.pressed.connect(func():
				var tmp = ordered[i_local + 1]
				ordered[i_local + 1] = ordered[i_local]
				ordered[i_local]     = tmp
				var tw = row_panel.create_tween()
				tw.tween_property(row_panel, "modulate", Color(1.4, 1.4, 1.0), 0.08)
				tw.tween_property(row_panel, "modulate", Color.WHITE, 0.15)
				self_ref.call(self_ref)
			)
			btn_col.add_child(dn_btn)

	refresh_list.call(refresh_list)

	# Botones de acción
	var sep2 = ColorRect.new()
	sep2.color    = Color(COLOR_GOLD.r, COLOR_GOLD.g, COLOR_GOLD.b, 0.14)
	sep2.position = Vector2(0, panel_h - 64)
	sep2.size     = Vector2(panel_w, 1)
	panel.add_child(sep2)

	var confirm_btn = Button.new()
	confirm_btn.text = "✓  Confirmar orden"
	confirm_btn.position = Vector2(20, panel_h - 54)
	confirm_btn.size     = Vector2((panel_w - 52) / 2.0, 40)
	confirm_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var cb_s = StyleBoxFlat.new()
	cb_s.bg_color     = Color(0.08, 0.22, 0.10, 0.95)
	cb_s.border_color = COLOR_GOLD
	cb_s.set_border_width_all(1)
	cb_s.set_corner_radius_all(10)
	var cb_h = cb_s.duplicate(); cb_h.bg_color = Color(0.14, 0.38, 0.16, 1.0)
	confirm_btn.add_theme_stylebox_override("normal", cb_s)
	confirm_btn.add_theme_stylebox_override("hover",  cb_h)
	confirm_btn.add_theme_color_override("font_color", COLOR_GOLD)
	confirm_btn.add_theme_font_size_override("font_size", 13)
	confirm_btn.pressed.connect(func():
		_close_selection_popup()
		var reordered_ids: Array = ordered.map(func(e): return e.get("instance_id", ""))
		NetworkManager.send_action("PLAY_TRAINER", {
			"handIndex": _last_hand_index,
			"targets": {
				"phase":                "reorder",
				"reorderedInstanceIds": reordered_ids,
			}
		})
		emit_signal("trainer_message", "New Pokédex: orden confirmado")
	)
	panel.add_child(confirm_btn)

	var keep_btn = Button.new()
	keep_btn.text = "↩  Dejar como está"
	keep_btn.position = Vector2(24 + (panel_w - 52) / 2.0, panel_h - 54)
	keep_btn.size     = Vector2((panel_w - 52) / 2.0, 40)
	keep_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var kb_s = StyleBoxFlat.new()
	kb_s.bg_color     = Color(0.06, 0.06, 0.10, 0.90)
	kb_s.border_color = Color(0.35, 0.35, 0.45, 0.50)
	kb_s.set_border_width_all(1)
	kb_s.set_corner_radius_all(10)
	var kb_h = kb_s.duplicate(); kb_h.bg_color = Color(0.12, 0.12, 0.20, 1.0)
	keep_btn.add_theme_stylebox_override("normal", kb_s)
	keep_btn.add_theme_stylebox_override("hover",  kb_h)
	keep_btn.add_theme_color_override("font_color", COLOR_TEXT)
	keep_btn.add_theme_font_size_override("font_size", 13)
	keep_btn.pressed.connect(func():
		_close_selection_popup()
		NetworkManager.send_action("PLAY_TRAINER", {
			"handIndex": _last_hand_index,
			"targets": {
				"phase":                "reorder",
				"reorderedInstanceIds": [],
			}
		})
		emit_signal("trainer_message", "New Pokédex: mazo sin cambios")
	)
	panel.add_child(keep_btn)

	_animate_panel_in(panel)
	return popup
	
