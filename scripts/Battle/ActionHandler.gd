extends Node

# ============================================================
# ActionHandler.gd
# ============================================================

signal action_message(text: String)
signal action_buttons_update_needed()

var board:             Node = null
var trainer_handler:   Node = null
var target_selector:   Node = null
var power_handler:     Node = null   # ← PokePowerHandler

# ─── Estado interno del selector de energía ─────────────────
var _retreat_bench_index:     int     = -1
var _retreat_energy_popup:    Control = null

const COLOR_GOLD     := Color(0.85, 0.72, 0.30)
const COLOR_GOLD_DIM := Color(0.55, 0.45, 0.18)
const COLOR_TEXT     := Color(0.92, 0.88, 0.75)
const CARD_W         := 130
const CARD_H         := 182


func setup() -> void:
	assert(board != null, "ActionHandler: board no asignado")
	_init_target_selector()
	_init_power_handler()


func _init_target_selector() -> void:
	target_selector = load("res://scripts/TargetSelector.gd").new()
	target_selector.board = board
	add_child(target_selector)
	target_selector.target_selected.connect(_on_target_selected)
	target_selector.selection_cancelled.connect(_on_selection_cancelled)
	target_selector.state_changed.connect(_on_selector_state_changed)


func _init_power_handler() -> void:
	power_handler = load("res://scripts/Battle/PokePowerHandler.gd").new()
	power_handler.board           = board
	power_handler.target_selector = target_selector
	add_child(power_handler)
	power_handler.power_message.connect(_on_power_message)
	power_handler.power_cancelled.connect(_on_power_cancelled)


func on_action_button(action: String) -> void:
	var phase: String = board.current_state.get("phase", "")

	if phase == "SETUP_PLACE_ACTIVE":
		if action == "CONFIRM_SETUP":
			NetworkManager.send_action("CONFIRM_SETUP", {})
			emit_signal("action_message", "Confirmado, esperando al rival...")
		return

	if not board.my_turn:
		emit_signal("action_message", "No es tu turno")
		return

	if power_handler.is_active():
		power_handler.cancel()
		return

	if not target_selector.is_idle():
		target_selector.cancel()
		return

	match action:
		"PLAY_BASIC":    target_selector.begin_play_basic()
		"ATTACH_ENERGY": target_selector.begin_attach_energy()
		"EVOLVE":        target_selector.begin_evolve()
		"RETREAT":       target_selector.begin_retreat()
		"END_TURN":
			if target_selector.is_idle() and not power_handler.is_active():
				NetworkManager.end_turn()
				emit_signal("action_message", "Fin de turno")


func on_action_zoom_choice(type: String, data, source_zone: String = "active", source_index: int = 0) -> void:
	match type:
		"ATTACK":
			var attack_index: int = int(data)
			var atk_name = _get_attack_name(attack_index)
			if atk_name in target_selector.TARGETED_ATTACKS:
				emit_signal("action_message", "Elige el Pokémon objetivo del rival...")
				target_selector.begin_attack_target(attack_index)
			else:
				NetworkManager.send_action("ATTACK", {"attackIndex": attack_index})

		"POWER":
			var power_name: String = str(data)

			if power_name == "" or power_name == "0":
				if source_zone == "bench":
					power_name = _get_bench_power_name(source_index)
				else:
					power_name = _get_active_power_name()

			if power_name != "":
				if source_index == -1:
					power_handler.begin_power(power_name, "active", 0)
				else:
					power_handler.begin_power(power_name, source_zone, source_index)
			else:
				emit_signal("action_message", "⚠ No se pudo identificar el Pokémon Power")

		"RETREAT":
			target_selector.begin_retreat()


func on_hand_card_clicked(hand_index: int) -> bool:
	if target_selector.is_idle():
		return false
	target_selector.on_hand_card_clicked(hand_index)
	return true


func is_busy() -> bool:
	return not target_selector.is_idle() or power_handler.is_active()


func cancel() -> void:
	if _retreat_energy_popup and is_instance_valid(_retreat_energy_popup):
		_retreat_energy_popup.queue_free()
		_retreat_energy_popup = null
		_retreat_bench_index  = -1
		emit_signal("action_message", "Retirada cancelada (Esc)")
		emit_signal("action_buttons_update_needed")
		return
	if power_handler.is_active():
		power_handler.cancel()
	elif not target_selector.is_idle():
		target_selector.cancel()


# ============================================================
# TARGET SELECTOR — CALLBACKS
# ============================================================

func _on_target_selected(action, hand_index: int, zone: String, zone_index: int) -> void:
	match action:
		target_selector.Action.PLAY_BASIC:
			NetworkManager.play_basic(hand_index)
		target_selector.Action.ATTACH_ENERGY:
			NetworkManager.attach_energy(hand_index, zone, zone_index)
		target_selector.Action.EVOLVE:
			NetworkManager.evolve(hand_index, zone, zone_index)
		target_selector.Action.RETREAT:
			# ── RETREAT: mostrar selector de energía antes de enviar ──
			_begin_retreat_energy_selection(zone_index)
			return   # ← NO emitir action_message todavía
		target_selector.Action.ATTACK:
			NetworkManager.attack(zone_index)
	emit_signal("action_message", _action_to_string(action) + " enviado")


func _on_selection_cancelled() -> void:
	emit_signal("action_message", "Acción cancelada (Esc)")
	emit_signal("action_buttons_update_needed")


func _on_selector_state_changed(new_state) -> void:
	match new_state:
		1: emit_signal("action_message", "Elige una carta de tu mano (Esc = cancelar)")
		2: emit_signal("action_message", "Elige el Pokémon objetivo (Esc = cancelar)")


func _on_power_message(text: String) -> void:
	emit_signal("action_message", text)

func _on_power_cancelled() -> void:
	emit_signal("action_buttons_update_needed")


func _action_to_string(action) -> String:
	match action:
		target_selector.Action.PLAY_BASIC:         return "Jugar básico"
		target_selector.Action.ATTACH_ENERGY:      return "Energía"
		target_selector.Action.EVOLVE:             return "Evolución"
		target_selector.Action.RETREAT:            return "Retirada"
		target_selector.Action.ATTACK:             return "Ataque"
		target_selector.Action.ATTACK_WITH_TARGET: return "Ataque dirigido"
	return "Acción"


# ============================================================
# RETREAT — SELECTOR DE ENERGÍAS A DESCARTAR
# ============================================================

func _begin_retreat_energy_selection(bench_index: int) -> void:
	var active = board.current_state.get("my", {}).get("active")
	if not active:
		emit_signal("action_message", "⚠ No hay Pokémon activo")
		return

	var energies: Array     = active.get("attached_energy", [])
	var cdata:    Dictionary = CardDatabase.get_card(active.get("card_id", ""))
	var cost:     int        = int(cdata.get("retreat_cost", 0))

	# Sin costo de retirada → enviar directo
	if cost == 0:
		NetworkManager.send_action("RETREAT", {
			"benchIndex":     bench_index,
			"discardIndices": [],
		})
		emit_signal("action_message", "Retirada enviada")
		return

	# No hay suficientes energías (validación básica cliente)
	if energies.size() < cost:
		emit_signal("action_message",
			"⚠ No tienes suficientes energías para retirarte (necesitas %d)" % cost)
		return

	# Solo hay exactamente las necesarias → no hay elección, enviar directo
	if energies.size() == cost:
		var indices: Array[int] = []
		for i in range(energies.size()):
			indices.append(i)
		NetworkManager.send_action("RETREAT", {
			"benchIndex":     bench_index,
			"discardIndices": indices,
		})
		emit_signal("action_message", "Retirada enviada")
		return

	# Hay más energías que el costo → mostrar popup de selección
	_retreat_bench_index = bench_index
	_show_retreat_energy_popup(active, energies, cost)


func _show_retreat_energy_popup(active: Dictionary, energies: Array, cost: int) -> void:
	if _retreat_energy_popup and is_instance_valid(_retreat_energy_popup):
		_retreat_energy_popup.queue_free()

	var vp: Vector2 = board.get_viewport().get_visible_rect().size
	var popup       = _build_retreat_energy_popup(vp, active, energies, cost)
	_retreat_energy_popup = popup
	board.add_child(popup)
	emit_signal("action_message",
		"Elige %d energía(s) a descartar para la retirada (Esc = cancelar)" % cost)


func _build_retreat_energy_popup(
		vp: Vector2,
		active: Dictionary,
		energies: Array,
		cost: int) -> Control:

	var pokemon_name = CardDatabase.get_card(
		active.get("card_id", "")).get("name", "Pokémon activo")

	var popup = Control.new()
	popup.name = "RetreatEnergySelector"
	popup.set_anchors_preset(Control.PRESET_FULL_RECT)
	popup.z_index = 250

	# ── Fondo oscuro ──
	var dim = ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.82)
	popup.add_child(dim)

	# ── Panel ──
	const PW := 480.0
	const PH := 340.0
	var panel = Panel.new()
	panel.position = Vector2((vp.x - PW) / 2.0, (vp.y - PH) / 2.0)
	panel.size     = Vector2(PW, PH)

	var ps = StyleBoxFlat.new()
	ps.bg_color                  = Color(0.06, 0.10, 0.08, 0.98)
	ps.border_color              = COLOR_GOLD
	ps.border_width_left         = 2; ps.border_width_right  = 2
	ps.border_width_top          = 2; ps.border_width_bottom = 2
	ps.corner_radius_top_left    = 14; ps.corner_radius_top_right    = 14
	ps.corner_radius_bottom_left = 14; ps.corner_radius_bottom_right = 14
	ps.shadow_color = Color(0, 0, 0, 0.60); ps.shadow_size = 14
	panel.add_theme_stylebox_override("panel", ps)
	popup.add_child(panel)

	# ── Título ──
	var title = Label.new()
	title.text = "Retirada — Elige %d energía(s) a descartar" % cost
	title.position = Vector2(0, 18)
	title.size     = Vector2(PW, 28)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 15)
	title.add_theme_color_override("font_color", COLOR_GOLD)
	panel.add_child(title)

	var sub = Label.new()
	sub.text = pokemon_name + " — elige las energías que se descartarán"
	sub.position = Vector2(0, 50)
	sub.size     = Vector2(PW, 22)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 11)
	sub.add_theme_color_override("font_color", COLOR_TEXT)
	panel.add_child(sub)

	# ── Contador ──
	var counter_lbl = Label.new()
	counter_lbl.name     = "CounterLabel"
	counter_lbl.text     = "Seleccionadas: 0 / %d" % cost
	counter_lbl.position = Vector2(0, 72)
	counter_lbl.size     = Vector2(PW, 18)
	counter_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	counter_lbl.add_theme_font_size_override("font_size", 11)
	counter_lbl.add_theme_color_override("font_color",
		Color(0.95, 0.40, 0.40) if cost > 0 else COLOR_GOLD)
	panel.add_child(counter_lbl)

	# ── Flow de energías ──
	var scroll = ScrollContainer.new()
	scroll.position = Vector2(16, 96)
	scroll.size     = Vector2(PW - 32, PH - 162)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)

	var flow = HFlowContainer.new()
	flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	flow.add_theme_constant_override("h_separation", 10)
	flow.add_theme_constant_override("v_separation", 10)
	scroll.add_child(flow)

	# Escala de carta de energía
	const ESCALE  := 0.55
	const EW      := int(CARD_W * ESCALE)
	const EH      := int(CARD_H * ESCALE)

	var selected_indices: Array[int] = []

	for i in range(energies.size()):
		var energy      = energies[i]
		var energy_id   = energy if energy is String else energy.get("card_id", "")  # 
		var energy_data = CardDatabase.get_card(energy_id)
		var energy_name = energy_data.get("name", energy_id)
		var i_local     = i

		var slot = Control.new()
		slot.custom_minimum_size = Vector2(EW, EH + 20)
		flow.add_child(slot)

		# fondo de slot
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

		# imagen de la carta
		var card_inst = CardDatabase.create_card_instance(energy_id)
		card_inst.scale        = Vector2(ESCALE, ESCALE)
		card_inst.is_draggable = false
		card_inst.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card_inst.position     = Vector2.ZERO
		slot.add_child(card_inst)

		# nombre bajo la carta
		var name_lbl = Label.new()
		name_lbl.text     = energy_name
		name_lbl.position = Vector2(0, EH + 2)
		name_lbl.size     = Vector2(EW, 16)
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.add_theme_font_size_override("font_size", 8)
		name_lbl.add_theme_color_override("font_color", COLOR_TEXT)
		slot.add_child(name_lbl)

		# overlay de selección
		var check_overlay = ColorRect.new()
		check_overlay.name         = "CheckOverlay"
		check_overlay.position     = Vector2.ZERO
		check_overlay.size         = Vector2(EW, EH)
		check_overlay.color        = Color(0.95, 0.30, 0.20, 0.40)
		check_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		check_overlay.visible      = false
		slot.add_child(check_overlay)

		var check_lbl = Label.new()
		check_lbl.name     = "CheckLabel"
		check_lbl.text     = "✕"
		check_lbl.position = Vector2(EW / 2.0 - 14, EH / 2.0 - 20)
		check_lbl.size     = Vector2(28, 28)
		check_lbl.add_theme_font_size_override("font_size", 32)
		check_lbl.add_theme_color_override("font_color", Color(1.0, 0.35, 0.25))
		check_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		check_lbl.visible  = false
		slot.add_child(check_lbl)

		# botón invisible sobre el slot
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
			var co  = slot.get_node_or_null("CheckOverlay")
			var cl  = slot.get_node_or_null("CheckLabel")
			var cl2 = panel.get_node_or_null("CounterLabel")

			if selected_indices.has(i_local):
				# Deseleccionar
				selected_indices.erase(i_local)
				if co: co.visible = false
				if cl: cl.visible = false
				slot_style.border_color = COLOR_GOLD_DIM
				slot_bg.add_theme_stylebox_override("panel", slot_style)
			elif selected_indices.size() < cost:
				# Seleccionar
				selected_indices.append(i_local)
				if co: co.visible = true
				if cl: cl.visible = true
				slot_style.border_color = Color(0.95, 0.35, 0.20)
				slot_bg.add_theme_stylebox_override("panel", slot_style)

			if cl2:
				cl2.text = "Seleccionadas: %d / %d" % [selected_indices.size(), cost]
		)
		btn.mouse_entered.connect(func():
			slot.create_tween().tween_property(slot, "scale", Vector2(1.06, 1.06), 0.08)
		)
		btn.mouse_exited.connect(func():
			slot.create_tween().tween_property(slot, "scale", Vector2(1.0, 1.0), 0.08)
		)
		slot.add_child(btn)

	# ── Botones de acción ──
	var btn_y := PH - 52.0

	var confirm_btn = _make_popup_button("✓  Confirmar retirada")
	confirm_btn.position = Vector2(PW / 2.0 - 168, btn_y)
	confirm_btn.size     = Vector2(155, 36)
	confirm_btn.pressed.connect(func():
		if selected_indices.size() < cost:
			emit_signal("action_message",
				"⚠ Debes seleccionar %d energía(s)" % cost)
			return
		_close_retreat_popup()
		NetworkManager.send_action("RETREAT", {
			"benchIndex":     _retreat_bench_index,
			"discardIndices": selected_indices,
		})
		_retreat_bench_index = -1
		emit_signal("action_message", "Retirada enviada")
	)
	panel.add_child(confirm_btn)

	var cancel_btn = _make_popup_button("✕  Cancelar")
	cancel_btn.position = Vector2(PW / 2.0 + 14, btn_y)
	cancel_btn.size     = Vector2(155, 36)
	cancel_btn.pressed.connect(func():
		_close_retreat_popup()
		emit_signal("action_message", "Retirada cancelada")
	)
	panel.add_child(cancel_btn)

	# ── Animación entrada ──
	panel.modulate.a = 0.0
	panel.scale      = Vector2(0.88, 0.88)
	var tw = panel.create_tween()
	tw.set_parallel(true)
	tw.tween_property(panel, "modulate:a", 1.0,         0.18)
	tw.tween_property(panel, "scale",      Vector2.ONE, 0.20) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	return popup


func _close_retreat_popup() -> void:
	if _retreat_energy_popup and is_instance_valid(_retreat_energy_popup):
		_retreat_energy_popup.queue_free()
	_retreat_energy_popup = null


func _make_popup_button(label_text: String) -> Button:
	var btn = Button.new()
	btn.text = label_text
	var sn = StyleBoxFlat.new()
	sn.bg_color     = Color(0.12, 0.20, 0.14)
	sn.border_color = COLOR_GOLD_DIM
	sn.border_width_left = 1; sn.border_width_right  = 1
	sn.border_width_top  = 1; sn.border_width_bottom = 1
	sn.corner_radius_top_left    = 7; sn.corner_radius_top_right    = 7
	sn.corner_radius_bottom_left = 7; sn.corner_radius_bottom_right = 7
	btn.add_theme_stylebox_override("normal", sn)
	var sh = StyleBoxFlat.new()
	sh.bg_color     = Color(0.20, 0.35, 0.22)
	sh.border_color = COLOR_GOLD
	sh.border_width_left = 1; sh.border_width_right  = 1
	sh.border_width_top  = 1; sh.border_width_bottom = 1
	sh.corner_radius_top_left    = 7; sh.corner_radius_top_right    = 7
	sh.corner_radius_bottom_left = 7; sh.corner_radius_bottom_right = 7
	btn.add_theme_stylebox_override("hover", sh)
	btn.add_theme_color_override("font_color", COLOR_TEXT)
	btn.add_theme_font_size_override("font_size", 12)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	return btn


# ============================================================
# HELPERS
# ============================================================

func _get_attack_name(attack_index: int) -> String:
	var active = board.current_state.get("my", {}).get("active")
	if not active: return ""
	var cdata   = CardDatabase.get_card(active.get("card_id", ""))
	var attacks = cdata.get("attacks", [])
	if attack_index < attacks.size():
		return attacks[attack_index].get("name", "")
	return ""


func _get_active_power_name() -> String:
	var active = board.current_state.get("my", {}).get("active")
	if not active: return ""
	var card_id = active.get("card_id", "")
	if card_id == "": return ""
	var cdata = CardDatabase.get_card(card_id)
	var power = cdata.get("pokemon_power", null)
	if power == null: return ""
	return str(power.get("name", ""))


func _get_bench_power_name(bench_index: int) -> String:
	var bench = board.current_state.get("my", {}).get("bench", [])
	if bench_index < 0 or bench_index >= bench.size(): return ""
	var poke = bench[bench_index]
	if poke == null: return ""
	var card_id = poke.get("card_id", "")
	if card_id == "": return ""
	var cdata = CardDatabase.get_card(card_id)
	var power = cdata.get("pokemon_power", null)
	if power == null: return ""
	return str(power.get("name", ""))
