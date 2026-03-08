extends Node
class_name GymChallengeAlert

# ============================================================
# Pop-up dinámico para aceptar/rechazar retos de GYM PvP
# ============================================================

static func show(container: Node, msg: Dictionary) -> void:
	var payload = msg.get("payload", msg)
	var challenger_id = payload.get("challenger_id", "")
	var gym_id = payload.get("gym_id", "")
	var c_tier = payload.get("challenger_tier", "C")
	var c_deck = payload.get("challenger_deck", [])
	
	# ── Fondo oscuro (Dimmer) ──
	var dimmer = ColorRect.new()
	dimmer.set_anchors_preset(Control.PRESET_FULL_RECT)
	dimmer.color = Color(0, 0, 0, 0.7)
	dimmer.z_index = 300 # Muy alto para que tape todo
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	container.add_child(dimmer)

	# ── Panel del Pop-up ──
	var popup = Panel.new()
	popup.anchor_left = 0.5; popup.anchor_right = 0.5
	popup.anchor_top = 0.5;  popup.anchor_bottom = 0.5
	popup.offset_left = -200; popup.offset_right = 200
	popup.offset_top = -120;  popup.offset_bottom = 120
	
	var st = StyleBoxFlat.new()
	st.bg_color = Color(0.1, 0.12, 0.18, 0.98)
	st.border_color = Color(0.9, 0.2, 0.2, 0.8) # Borde rojo desafío
	st.border_width_left = 2; st.border_width_right = 2
	st.border_width_top = 2; st.border_width_bottom = 2
	st.corner_radius_top_left = 12; st.corner_radius_top_right = 12
	st.corner_radius_bottom_left = 12; st.corner_radius_bottom_right = 12
	popup.add_theme_stylebox_override("panel", st)
	dimmer.add_child(popup)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 15)
	popup.add_child(vbox)

	# ── Textos ──
	var title = Label.new()
	title.text = "¡NUEVO RETADOR!"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
	vbox.add_child(title)

	var desc = Label.new()
	desc.text = "Un jugador con Mazo Tier [" + c_tier + "]\nestá desafiando tu gimnasio."
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.add_theme_font_size_override("font_size", 14)
	vbox.add_child(desc)

	# ── Botones ──
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 20)
	vbox.add_child(hbox)

	var btn_reject = Button.new()
	btn_reject.text = "Rechazar"
	btn_reject.custom_minimum_size = Vector2(120, 40)
	var st_rej = StyleBoxFlat.new()
	st_rej.bg_color = Color(0.3, 0.1, 0.1); st_rej.corner_radius_top_left = 6; st_rej.corner_radius_bottom_right = 6
	btn_reject.add_theme_stylebox_override("normal", st_rej)
	
	var btn_accept = Button.new()
	btn_accept.text = "Aceptar Reto"
	btn_accept.custom_minimum_size = Vector2(120, 40)
	var st_acc = StyleBoxFlat.new()
	st_acc.bg_color = Color(0.1, 0.5, 0.2); st_acc.corner_radius_top_left = 6; st_acc.corner_radius_bottom_right = 6
	btn_accept.add_theme_stylebox_override("normal", st_acc)

	hbox.add_child(btn_reject)
	hbox.add_child(btn_accept)

	# ── Lógica de clics ──
	btn_reject.pressed.connect(func():
		_send_response(false, challenger_id, gym_id, c_tier, c_deck)
		dimmer.queue_free()
	)

	btn_accept.pressed.connect(func():
		_send_response(true, challenger_id, gym_id, c_tier, c_deck)
		btn_accept.text = "Preparando sala..."
		btn_accept.disabled = true
		btn_reject.disabled = true
	)

static func _send_response(accept: bool, c_id: String, gym_id: String, tier: String, deck: Array) -> void:
	var msg = {
		"type": "GYM_CHALLENGE_RESPONSE",
		"payload": {
			"accept": accept,
			"challenger_id": c_id,
			"gym_id": gym_id,
			"challenger_tier": tier,
			"challenger_deck": deck
		}
	}
	# Usamos el NetworkManager directamente
	NetworkManager.send_ws(msg)
