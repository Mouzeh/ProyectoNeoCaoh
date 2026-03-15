extends Node
class_name ChallengePopupHandler


# ============================================================
# ChallengePopupHandler.gd
# Maneja los dos popups del trainer "Challenge!":
#   - Decision popup (aceptar / rechazar)
#   - Pick popup (seleccionar básicos del mazo)
# ============================================================

const COLOR_GOLD     = Color(0.85, 0.72, 0.30)
const COLOR_GOLD_DIM = Color(0.55, 0.45, 0.18)
const COLOR_TEXT     = Color(0.92, 0.88, 0.75)
const CARD_W         = 130
const CARD_H         = 182

var _parent: Node2D = null


# ============================================================
# SETUP
# ============================================================
func setup(parent: Node2D) -> void:
	_parent = parent


# ============================================================
# DECISION POPUP
# ============================================================
func show_decision(available: Array, max_select: int) -> void:
	var vp    := _parent.get_viewport().get_visible_rect().size
	var popup := Control.new()
	popup.name    = "ChallengeDecision"
	popup.set_anchors_preset(Control.PRESET_FULL_RECT)
	popup.z_index = 250

	var dim = ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.85)
	popup.add_child(dim)

	var panel_w := 520.0
	var panel_h := 300.0
	var panel   := Panel.new()
	panel.position = Vector2((vp.x - panel_w) / 2.0, (vp.y - panel_h) / 2.0)
	panel.size     = Vector2(panel_w, panel_h)
	var ps = StyleBoxFlat.new()
	ps.bg_color     = Color(0.06, 0.10, 0.08, 0.98)
	ps.border_color = COLOR_GOLD
	ps.border_width_left = 2; ps.border_width_right  = 2
	ps.border_width_top  = 2; ps.border_width_bottom = 2
	ps.corner_radius_top_left    = 14; ps.corner_radius_top_right    = 14
	ps.corner_radius_bottom_left = 14; ps.corner_radius_bottom_right = 14
	panel.add_theme_stylebox_override("panel", ps)
	popup.add_child(panel)

	var title = Label.new()
	title.text     = "⚔  ¡Challenge!"
	title.position = Vector2(0, 22)
	title.size     = Vector2(panel_w, 32)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", COLOR_GOLD)
	panel.add_child(title)

	var has_basics := available.size() > 0 and max_select > 0
	var desc_text: String
	if not has_basics:
		desc_text = "El rival te desafía.\nNo tienes Básicos disponibles o tu banco está lleno\n— solo puedes rechazar."
	else:
		desc_text = "El rival te desafía.\nPuedes colocar hasta %d Pokémon Básico(s) de tu mazo en el banco.\n\nTienes %d tipo(s) disponibles." \
			% [max_select, available.size()]

	var desc = Label.new()
	desc.text          = desc_text
	desc.position      = Vector2(24, 68)
	desc.size          = Vector2(panel_w - 48, 110)
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc.add_theme_font_size_override("font_size", 13)
	desc.add_theme_color_override("font_color", COLOR_TEXT)
	panel.add_child(desc)

	if has_basics:
		var accept_btn = _make_button("✓  Aceptar")
		accept_btn.position = Vector2(panel_w / 2.0 - 170, panel_h - 68)
		accept_btn.size     = Vector2(150, 42)
		accept_btn.pressed.connect(func():
			popup.queue_free()
			show_pick(available, true, max_select)
		)
		panel.add_child(accept_btn)

	var reject_btn = _make_button("✕  Rechazar")
	reject_btn.position = Vector2(panel_w / 2.0 + 20, panel_h - 68)
	reject_btn.size     = Vector2(150, 42)
	reject_btn.pressed.connect(func():
		popup.queue_free()
		NetworkManager.send_action("RESOLVE_CHALLENGE", {"accept": false})
	)
	panel.add_child(reject_btn)

	_animate_panel(panel)
	_parent.add_child(popup)


# ============================================================
# PICK POPUP
# ============================================================
func show_pick(available: Array, is_opponent: bool, max_select: int) -> void:
	var vp    := _parent.get_viewport().get_visible_rect().size
	var popup := Control.new()
	popup.name    = "ChallengePick"
	popup.set_anchors_preset(Control.PRESET_FULL_RECT)
	popup.z_index = 250

	var dim = ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.85)
	popup.add_child(dim)

	var panel_w: float = min(680.0, vp.x - 60)
	var panel_h: float = min(480.0, vp.y - 60)
	var panel   := Panel.new()
	panel.position = Vector2((vp.x - panel_w) / 2.0, (vp.y - panel_h) / 2.0)
	panel.size     = Vector2(panel_w, panel_h)
	var ps = StyleBoxFlat.new()
	ps.bg_color     = Color(0.06, 0.10, 0.08, 0.98)
	ps.border_color = COLOR_GOLD
	ps.border_width_left = 2; ps.border_width_right  = 2
	ps.border_width_top  = 2; ps.border_width_bottom = 2
	ps.corner_radius_top_left    = 14; ps.corner_radius_top_right    = 14
	ps.corner_radius_bottom_left = 14; ps.corner_radius_bottom_right = 14
	panel.add_theme_stylebox_override("panel", ps)
	popup.add_child(panel)

	var title = Label.new()
	title.text     = "Challenge! — Elige hasta %d Básico(s) de tu mazo" % max_select
	title.position = Vector2(16, 12)
	title.size     = Vector2(panel_w - 32, 28)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", COLOR_GOLD)
	panel.add_child(title)

	var counter_lbl = Label.new()
	counter_lbl.name     = "CounterLabel"
	counter_lbl.text     = "Seleccionados: 0 / %d" % max_select
	counter_lbl.position = Vector2(0, 44)
	counter_lbl.size     = Vector2(panel_w, 20)
	counter_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	counter_lbl.add_theme_font_size_override("font_size", 12)
	counter_lbl.add_theme_color_override("font_color", COLOR_TEXT)
	panel.add_child(counter_lbl)

	var scroll = ScrollContainer.new()
	scroll.position = Vector2(12, 70)
	scroll.size     = Vector2(panel_w - 24, panel_h - 140)
	panel.add_child(scroll)

	var flow = HFlowContainer.new()
	flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	flow.add_theme_constant_override("h_separation", 12)
	flow.add_theme_constant_override("v_separation", 12)
	scroll.add_child(flow)

	var card_scale    := 0.60
	var cw            := int(CARD_W * card_scale)
	var ch            := int(CARD_H * card_scale)
	var selected_slots: Dictionary = {}
	var max_sel: int  = max_select

	for i in range(available.size()):
		var cid       = available[i]
		var cdata     := CardDatabase.get_card(cid)
		var cid_local := str(cid)

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
		hover_s.bg_color                  = Color(1, 1, 1, 0.14)
		hover_s.corner_radius_top_left    = 6; hover_s.corner_radius_top_right    = 6
		hover_s.corner_radius_bottom_left = 6; hover_s.corner_radius_bottom_right = 6
		btn.add_theme_stylebox_override("hover", hover_s)

		btn.pressed.connect(func():
			var co  = slot.get_node_or_null("CheckOverlay")
			var cl  = slot.get_node_or_null("CheckLabel")
			var cl2 = panel.get_node_or_null("CounterLabel")
			if selected_slots.has(i):
				selected_slots.erase(i)
				if co: co.visible = false
				if cl: cl.visible = false
				slot_style.border_color = COLOR_GOLD_DIM
				slot_bg.add_theme_stylebox_override("panel", slot_style)
			elif selected_slots.size() < max_sel:
				selected_slots[i] = cid_local
				if co: co.visible = true
				if cl: cl.visible = true
				slot_style.border_color = Color(0.2, 0.9, 0.4)
				slot_bg.add_theme_stylebox_override("panel", slot_style)
			if cl2:
				cl2.text = "Seleccionados: %d / %d" % [selected_slots.size(), max_sel]
		)
		btn.mouse_entered.connect(func():
			slot.create_tween().tween_property(slot, "scale", Vector2(1.06, 1.06), 0.08)
		)
		btn.mouse_exited.connect(func():
			slot.create_tween().tween_property(slot, "scale", Vector2(1.0, 1.0), 0.08)
		)
		slot.add_child(btn)

	var btn_y: float = panel_h - 56.0

	var confirm_btn = _make_button("✓  Confirmar")
	confirm_btn.position = Vector2(panel_w / 2.0 - 170, btn_y)
	confirm_btn.size     = Vector2(150, 40)
	confirm_btn.pressed.connect(func():
		popup.queue_free()
		var final_ids: Array[String] = []
		for val in selected_slots.values():
			final_ids.append(val)
		if is_opponent:
			NetworkManager.send_action("RESOLVE_CHALLENGE", {"accept": true, "selectedIds": final_ids})
		else:
			NetworkManager.send_action("RESOLVE_CHALLENGE", {"selectedIds": final_ids})
	)
	panel.add_child(confirm_btn)

	var skip_btn = _make_button("↩  Pasar (0)")
	skip_btn.position = Vector2(panel_w / 2.0 + 20, btn_y)
	skip_btn.size     = Vector2(150, 40)
	skip_btn.pressed.connect(func():
		popup.queue_free()
		if is_opponent:
			NetworkManager.send_action("RESOLVE_CHALLENGE", {"accept": true, "selectedIds": []})
		else:
			NetworkManager.send_action("RESOLVE_CHALLENGE", {"selectedIds": []})
	)
	panel.add_child(skip_btn)

	_animate_panel(panel)
	_parent.add_child(popup)


# ============================================================
# HELPERS
# ============================================================
func _make_button(label_text: String) -> Button:
	var btn = Button.new()
	btn.text = label_text
	var sn = StyleBoxFlat.new()
	sn.bg_color     = Color(0.12, 0.20, 0.14)
	sn.border_color = COLOR_GOLD_DIM
	sn.border_width_bottom = 1
	sn.corner_radius_top_left    = 6; sn.corner_radius_top_right    = 6
	sn.corner_radius_bottom_left = 6; sn.corner_radius_bottom_right = 6
	btn.add_theme_stylebox_override("normal", sn)
	var sh = StyleBoxFlat.new()
	sh.bg_color     = Color(0.20, 0.35, 0.22)
	sh.border_color = COLOR_GOLD
	sh.border_width_bottom = 1
	sh.corner_radius_top_left    = 6; sh.corner_radius_top_right    = 6
	sh.corner_radius_bottom_left = 6; sh.corner_radius_bottom_right = 6
	btn.add_theme_stylebox_override("hover", sh)
	btn.add_theme_color_override("font_color", COLOR_TEXT)
	btn.add_theme_font_size_override("font_size", 12)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	return btn


func _animate_panel(panel: Control) -> void:
	panel.modulate.a = 0.0
	panel.scale      = Vector2(0.88, 0.88)
	var tw = panel.create_tween()
	tw.set_parallel(true)
	tw.tween_property(panel, "modulate:a", 1.0,         0.20)
	tw.tween_property(panel, "scale",      Vector2.ONE, 0.22) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
