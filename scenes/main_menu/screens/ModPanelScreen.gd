extends Node

# ============================================================
# ModPanelScreen.gd
# Panel de moderación — visible solo si PlayerData.role >= 3
#
# Pestañas:
#   • Reportes         (role >= 3)
#   • Buscar usuario   (role >= 3)
#   • Log de chat      (role >= 3)
#   • Recompensas      (role >= 4)
#   • Gestión de roles (role >= 5)
#   • Bans activos     (role >= 5)
#   • Estadísticas     (role >= 5)
#   • Anuncios         (role >= 5)
#   • Slow mode        (role >= 5)
#   • Log de acciones  (role >= 6)
# ============================================================

const ROLE_NAMES = {
	0: "Invitado", 1: "Usuario", 2: "VIP",
	3: "Mod", 4: "Coordinador", 5: "Admin", 6: "Owner"
}

var _menu
var _container: Control
var _tab_content: Control
var _active_tab = ""

# ─── ENTRY POINT ──────────────────────────────────────────
static func build(container: Control, menu) -> void:
	var screen = load("res://scenes/main_menu/screens/ModPanelScreen.gd").new()
	screen.name = "ModPanelNode"
	container.add_child(screen)
	screen._setup(container, menu)

func _setup(container: Control, menu) -> void:
	_menu = menu
	_container = container
	var C = menu

	var role = PlayerData.role if "role" in PlayerData else 1
	if role < 3:
		_show_no_access(container, C)
		return

	var bg = TextureRect.new()
	var bg_tex = load("res://assets/imagen/fondomenu.png")
	if bg_tex: bg.texture = bg_tex
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.modulate = Color(0.12, 0.12, 0.14, 1)
	container.add_child(bg)

	var header = Panel.new()
	header.anchor_left = 0; header.anchor_right  = 1
	header.anchor_top  = 0; header.anchor_bottom = 0
	header.offset_top  = 50; header.offset_bottom = 110
	var hs = StyleBoxFlat.new()
	hs.bg_color = Color(0.08, 0.06, 0.04, 0.95)
	hs.border_color = Color(1.0, 0.60, 0.0, 0.5)
	hs.border_width_bottom = 2
	header.add_theme_stylebox_override("panel", hs)
	container.add_child(header)

	var hbox = HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	var hm = MarginContainer.new()
	hm.add_theme_constant_override("margin_left", 24)
	header.add_child(hm)
	hm.add_child(hbox)

	var title = Label.new()
	title.text = "⚙️ PANEL DE MODERACIÓN  —  " + ROLE_NAMES.get(role, "Staff")
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(1.0, 0.65, 0.0))
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(title)

	var layout = HBoxContainer.new()
	layout.anchor_left   = 0; layout.anchor_right  = 1
	layout.anchor_top    = 0; layout.anchor_bottom = 1
	layout.offset_top    = 110; layout.offset_bottom = -8
	layout.offset_left   = 8;  layout.offset_right  = -8
	layout.add_theme_constant_override("separation", 0)
	container.add_child(layout)

	var sidebar = _build_sidebar(layout, role, C)
	layout.add_child(sidebar)

	var content_wrapper = PanelContainer.new()
	content_wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_wrapper.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	var cw_st = StyleBoxFlat.new()
	cw_st.bg_color = Color(0.06, 0.07, 0.10, 0.97)
	cw_st.border_color = Color(0.2, 0.2, 0.25)
	cw_st.border_width_left = 1; cw_st.border_width_right  = 1
	cw_st.border_width_top  = 1; cw_st.border_width_bottom = 1
	cw_st.corner_radius_top_right    = 12; cw_st.corner_radius_bottom_right = 12
	content_wrapper.add_theme_stylebox_override("panel", cw_st)
	layout.add_child(content_wrapper)

	_tab_content = content_wrapper
	_switch_tab("reports", C)

# ─── SIDEBAR ────────────────────────────────────────────
func _build_sidebar(parent: Control, role: int, C) -> Control:
	var sidebar = PanelContainer.new()
	sidebar.custom_minimum_size = Vector2(180, 0)
	var sb_st = StyleBoxFlat.new()
	sb_st.bg_color = Color(0.05, 0.05, 0.08, 0.98)
	sb_st.border_color = Color(0.15, 0.15, 0.2)
	sb_st.border_width_right = 1
	sb_st.corner_radius_top_left    = 12; sb_st.corner_radius_bottom_left = 12
	sidebar.add_theme_stylebox_override("panel", sb_st)

	var sv = VBoxContainer.new()
	sv.add_theme_constant_override("separation", 4)
	var sm = MarginContainer.new()
	sm.add_theme_constant_override("margin_left",   8)
	sm.add_theme_constant_override("margin_right",  8)
	sm.add_theme_constant_override("margin_top",   16)
	sm.add_theme_constant_override("margin_bottom", 16)
	sidebar.add_child(sm)
	sm.add_child(sv)

	var tabs = []
	if role >= 3:
		tabs.append(["reports",     "🚩  Reportes"])
		tabs.append(["search",      "🔍  Buscar usuario"])
		tabs.append(["chat_log",    "📜  Log de chat"])
	if role >= 4:
		tabs.append(["rewards",     "🎁  Recompensas"])
	if role >= 5:
		tabs.append(["roles",       "👑  Gestión roles"])
		tabs.append(["bans",        "🔨  Bans activos"])
		tabs.append(["stats",       "📊  Estadísticas"])
		tabs.append(["announce",    "📢  Anuncios"])
		tabs.append(["slowmode",    "🐢  Slow mode"])
	if role >= 6:
		tabs.append(["action_log",  "🗂️  Log de acciones"])
		tabs.append(["mod_ranking", "🏅  Ranking mods"])

	for tab in tabs:
		var btn = Button.new()
		btn.text = tab[1]
		btn.custom_minimum_size = Vector2(0, 36)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.add_theme_font_size_override("font_size", 13)

		var st_n = StyleBoxFlat.new()
		st_n.bg_color = Color(0,0,0,0)
		st_n.corner_radius_top_left    = 6; st_n.corner_radius_top_right    = 6
		st_n.corner_radius_bottom_left = 6; st_n.corner_radius_bottom_right = 6
		var st_h = st_n.duplicate(); st_h.bg_color = Color(0.15, 0.15, 0.22, 0.8)
		var st_p = st_n.duplicate()
		st_p.bg_color = Color(0.15, 0.10, 0.02, 0.9)
		st_p.border_color = Color(1.0, 0.65, 0.0, 0.6)
		st_p.border_width_left = 3

		btn.add_theme_stylebox_override("normal",  st_n)
		btn.add_theme_stylebox_override("hover",   st_h)
		btn.add_theme_stylebox_override("pressed", st_p)
		btn.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		btn.add_theme_color_override("font_hover_color",   Color(0.9, 0.9, 0.9))
		btn.add_theme_color_override("font_pressed_color", Color(1.0, 0.75, 0.2))

		var tab_id = tab[0]
		btn.pressed.connect(func(): _switch_tab(tab_id, C))
		sv.add_child(btn)

	return sidebar

# ─── CAMBIAR PESTAÑA ────────────────────────────────────
func _switch_tab(tab_id: String, C) -> void:
	_active_tab = tab_id
	for c in _tab_content.get_children(): c.queue_free()

	match tab_id:
		"reports":    _build_reports_tab(C)
		"search":     _build_search_tab(C)
		"chat_log":   _build_chat_log_tab(C)
		"rewards":    _build_rewards_tab(C)
		"roles":      _build_roles_tab(C)
		"bans":       _build_bans_tab(C)
		"stats":      _build_stats_tab(C)
		"announce":   _build_announce_tab(C)
		"slowmode":   _build_slowmode_tab(C)
		"action_log": _build_action_log_tab(C)
		"mod_ranking":_build_mod_ranking_tab(C)

# ─── HELPERS ────────────────────────────────────────────
func _content_vbox() -> VBoxContainer:
	var m = MarginContainer.new()
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	m.add_theme_constant_override("margin_left",   24)
	m.add_theme_constant_override("margin_right",  24)
	m.add_theme_constant_override("margin_top",    20)
	m.add_theme_constant_override("margin_bottom", 20)
	_tab_content.add_child(m)

	var v = VBoxContainer.new()
	v.add_theme_constant_override("separation", 16)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	m.add_child(v)
	return v

func _tab_title(parent: Control, text: String) -> void:
	var lbl = Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.65, 0.0))
	parent.add_child(lbl)

func _make_button(text: String, color: Color) -> Button:
	var btn = Button.new()
	btn.text = text
	var st = StyleBoxFlat.new()
	st.bg_color = color
	st.corner_radius_top_left    = 6; st.corner_radius_top_right    = 6
	st.corner_radius_bottom_left = 6; st.corner_radius_bottom_right = 6
	btn.add_theme_stylebox_override("normal", st)
	btn.add_theme_color_override("font_color", Color.WHITE)
	return btn

func _api_post(endpoint: String, body: Dictionary, callback: Callable) -> void:
	var http = HTTPRequest.new()
	add_child(http)
	var headers = [
		"Content-Type: application/json",
		"Authorization: Bearer " + PlayerData.token
	]
	http.request(NetworkManager.BASE_URL + endpoint,
		headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	http.request_completed.connect(func(result, code, _h, resp_body):
		var data = {}
		if resp_body.size() > 0:
			var parsed = JSON.parse_string(resp_body.get_string_from_utf8())
			if parsed is Dictionary:
				data = parsed
		callback.call(code, data)
		http.queue_free()
	)

func _api_get(endpoint: String, callback: Callable) -> void:
	var http = HTTPRequest.new()
	add_child(http)
	var headers = ["Authorization: Bearer " + PlayerData.token]
	http.request(NetworkManager.BASE_URL + endpoint, headers)
	http.request_completed.connect(func(result, code, _h, resp_body):
		var data = {}
		if resp_body.size() > 0:
			var parsed = JSON.parse_string(resp_body.get_string_from_utf8())
			if parsed is Dictionary:
				data = parsed
		callback.call(code, data)
		http.queue_free()
	)

func _status_label(parent: Control) -> Label:
	var lbl = Label.new()
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(lbl)
	return lbl

func _form_lbl(txt: String) -> Label:
	var l = Label.new()
	l.text = txt
	l.add_theme_font_size_override("font_size", 13)
	l.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return l

# ─── DIÁLOGO DE CONFIRMACIÓN ────────────────────────────
func _show_confirm_dialog(message: String, on_confirm: Callable) -> void:
	var overlay = ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0, 0, 0, 0.65)
	overlay.z_index = 300
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_container.add_child(overlay)

	var panel = PanelContainer.new()
	panel.z_index = 301
	panel.custom_minimum_size = Vector2(420, 0)
	panel.anchor_left   = 0.5; panel.anchor_right  = 0.5
	panel.anchor_top    = 0.5; panel.anchor_bottom = 0.5
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical   = Control.GROW_DIRECTION_BOTH

	var st = StyleBoxFlat.new()
	st.bg_color = Color(0.08, 0.08, 0.12, 0.98)
	st.border_color = Color(1.0, 0.65, 0.0, 0.8)
	st.border_width_left = 2; st.border_width_right  = 2
	st.border_width_top  = 2; st.border_width_bottom = 2
	st.corner_radius_top_left    = 12; st.corner_radius_top_right    = 12
	st.corner_radius_bottom_left = 12; st.corner_radius_bottom_right = 12
	st.shadow_color = Color(0, 0, 0, 0.7); st.shadow_size = 30
	st.content_margin_left   = 28; st.content_margin_right  = 28
	st.content_margin_top    = 24; st.content_margin_bottom = 24
	panel.add_theme_stylebox_override("panel", st)
	_container.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	panel.add_child(vbox)

	var title_lbl = Label.new()
	title_lbl.text = "⚠️ Confirmar acción"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 16)
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.65, 0.0))
	vbox.add_child(title_lbl)

	var sep = ColorRect.new()
	sep.custom_minimum_size = Vector2(0, 1)
	sep.color = Color(1.0, 0.65, 0.0, 0.3)
	vbox.add_child(sep)

	var msg_lbl = Label.new()
	msg_lbl.text = message
	msg_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	msg_lbl.add_theme_font_size_override("font_size", 14)
	msg_lbl.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	msg_lbl.custom_minimum_size = Vector2(360, 0)
	vbox.add_child(msg_lbl)

	var btn_row = HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 16)
	vbox.add_child(btn_row)

	var cancel_btn = _make_button("✕  Cancelar", Color(0.25, 0.25, 0.3, 0.95))
	cancel_btn.custom_minimum_size = Vector2(140, 40)
	cancel_btn.add_theme_font_size_override("font_size", 14)
	cancel_btn.pressed.connect(func():
		overlay.queue_free()
		panel.queue_free()
	)
	btn_row.add_child(cancel_btn)

	var confirm_btn = _make_button("✔  Confirmar", Color(0.1, 0.45, 0.15, 0.95))
	confirm_btn.custom_minimum_size = Vector2(140, 40)
	confirm_btn.add_theme_font_size_override("font_size", 14)
	confirm_btn.pressed.connect(func():
		overlay.queue_free()
		panel.queue_free()
		on_confirm.call()
	)
	btn_row.add_child(confirm_btn)

# ─── PESTAÑA: REPORTES ──────────────────────────────────
func _build_reports_tab(C) -> void:
	var v = _content_vbox()
	_tab_title(v, "🚩 Reportes Pendientes")

	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	UITheme.apply_scrollbar_theme(scroll)
	v.add_child(scroll)

	var list = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 8)
	scroll.add_child(list)

	var status_lbl = _status_label(v)
	status_lbl.text = "Cargando..."

	_api_get("/api/mod/reports?status=pending", func(code, data):
		if not is_instance_valid(status_lbl) or not is_instance_valid(list): return
		status_lbl.text = ""
		if code != 200:
			status_lbl.text = "Error al cargar reportes"
			return
		var reports = data.get("reports", [])
		if reports.is_empty():
			status_lbl.text = "✅ No hay reportes pendientes"
			return
		for r in reports:
			_add_report_card(list, r)
	)

func _add_report_card(parent: Control, r: Dictionary) -> void:
	var card = PanelContainer.new()
	var st = StyleBoxFlat.new()
	st.bg_color = Color(0.12, 0.08, 0.08, 0.9)
	st.border_color = Color(0.6, 0.2, 0.2, 0.5)
	st.border_width_left = 3
	st.corner_radius_top_left    = 8; st.corner_radius_top_right    = 8
	st.corner_radius_bottom_left = 8; st.corner_radius_bottom_right = 8
	st.content_margin_left   = 16; st.content_margin_right  = 16
	st.content_margin_top    = 12; st.content_margin_bottom = 12
	card.add_theme_stylebox_override("panel", st)
	parent.add_child(card)

	var cv = VBoxContainer.new()
	cv.add_theme_constant_override("separation", 6)
	card.add_child(cv)

	var info = Label.new()
	info.text = "🔴 %s reportó a %s  ·  Motivo: %s  ·  %s" % [
		r.get("reporter_name","?"),
		r.get("reported_name","?"),
		r.get("reason","?"),
		r.get("created_at","").substr(0,16)
	]
	info.add_theme_font_size_override("font_size", 13)
	info.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	cv.add_child(info)

	if r.get("message_content","") != "":
		var msg_lbl = Label.new()
		msg_lbl.text = "Mensaje: \"" + r.get("message_content","") + "\""
		msg_lbl.add_theme_font_size_override("font_size", 12)
		msg_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		msg_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		cv.add_child(msg_lbl)

	var btn_row = HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 8)
	cv.add_child(btn_row)

	var report_id = r.get("id", 0)
	var reported_id = r.get("reported_id","")

	for dur in [["Silenciar 1h", 1], ["Silenciar 24h", 24], ["Silenciar 7d", 168]]:
		var btn = _make_button(dur[0], Color(0.5, 0.3, 0.0, 0.9))
		btn.custom_minimum_size = Vector2(100, 30)
		btn.add_theme_font_size_override("font_size", 11)
		var hours = dur[1]
		btn.pressed.connect(func():
			_api_post("/api/mod/mute", {"user_id": reported_id, "duration_hours": hours, "reason": "report"}, func(code, d):
				if not is_instance_valid(btn): return
				if code == 200: btn.text = "✅ Silenciado"
			)
		)
		btn_row.add_child(btn)

	var dismiss_btn = _make_button("Ignorar", Color(0.2, 0.2, 0.2, 0.9))
	dismiss_btn.custom_minimum_size = Vector2(80, 30)
	dismiss_btn.add_theme_font_size_override("font_size", 11)
	dismiss_btn.pressed.connect(func():
		_api_post("/api/mod/reports/%d/resolve" % report_id, {"action": "dismiss"}, func(code, _d):
			if not is_instance_valid(card): return
			if code == 200: card.queue_free()
		)
	)
	btn_row.add_child(dismiss_btn)

# ─── PESTAÑA: BUSCAR USUARIO ─────────────────────────────
func _build_search_tab(C) -> void:
	var v = _content_vbox()
	_tab_title(v, "🔍 Buscar Usuario")

	var search_row = HBoxContainer.new()
	search_row.add_theme_constant_override("separation", 8)
	v.add_child(search_row)

	var input = LineEdit.new()
	input.placeholder_text = "Nombre de usuario..."
	input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	input.add_theme_stylebox_override("normal", UITheme.input_style(Color(0.15, 0.15, 0.2)))
	search_row.add_child(input)

	var btn = _make_button("Buscar", Color(0.2, 0.4, 0.7, 0.9))
	search_row.add_child(btn)

	var result_v = VBoxContainer.new()
	result_v.add_theme_constant_override("separation", 12)
	v.add_child(result_v)

	var status_lbl = _status_label(v)

	var do_search = func():
		for c in result_v.get_children(): c.queue_free()
		status_lbl.text = "Buscando..."
		_api_get("/api/mod/search-user?q=" + input.text.uri_encode(), func(code, data):
			if not is_instance_valid(status_lbl) or not is_instance_valid(result_v): return
			status_lbl.text = ""
			if code != 200:
				status_lbl.text = "Error en la búsqueda"
				return
			var users = data.get("users", [])
			if users.is_empty():
				status_lbl.text = "No se encontraron usuarios"
				return
			for u in users:
				_add_user_card(result_v, u)
		)

	btn.pressed.connect(do_search)
	input.text_submitted.connect(func(_t): do_search.call())

func _add_user_card(parent: Control, u: Dictionary) -> void:
	var card = PanelContainer.new()
	var st = StyleBoxFlat.new()
	st.bg_color = Color(0.1, 0.12, 0.18, 0.9)
	st.border_color = Color(0.2, 0.25, 0.35)
	st.border_width_left = 2
	st.corner_radius_top_left    = 8; st.corner_radius_top_right    = 8
	st.corner_radius_bottom_left = 8; st.corner_radius_bottom_right = 8
	st.content_margin_left   = 16; st.content_margin_right  = 16
	st.content_margin_top    = 12; st.content_margin_bottom = 12
	card.add_theme_stylebox_override("panel", st)
	parent.add_child(card)

	var cv = VBoxContainer.new()
	cv.add_theme_constant_override("separation", 8)
	card.add_child(cv)

	var info_lbl = Label.new()
	var is_banned = u.get("ban_reason", null) != null
	var is_muted  = u.get("muted_until", null) != null
	info_lbl.text = "%s  [%s]  ELO: %s  Monedas: %s  %s%s" % [
		u.get("username","?"),
		ROLE_NAMES.get(u.get("role",1), "?"),
		str(u.get("elo", 0)),
		str(u.get("coins", 0)),
		"🔨 BANEADO  " if is_banned else "",
		"🔇 SILENCIADO  " if is_muted else "",
	]
	info_lbl.add_theme_font_size_override("font_size", 14)
	info_lbl.add_theme_color_override("font_color",
		Color(0.9, 0.3, 0.3) if is_banned else Color(0.9, 0.9, 0.9))
	cv.add_child(info_lbl)

	var role_self = PlayerData.role if "role" in PlayerData else 3
	var target_role = u.get("role", 1)
	var user_id = u.get("id", "")

	if target_role < role_self:
		var action_row = HBoxContainer.new()
		action_row.add_theme_constant_override("separation", 8)
		cv.add_child(action_row)

		if role_self >= 3:
			for dur in [["Mutear 1h", 1], ["Mutear 24h", 24]]:
				var b = _make_button(dur[0], Color(0.5, 0.3, 0.0, 0.9))
				b.custom_minimum_size = Vector2(90, 28)
				b.add_theme_font_size_override("font_size", 11)
				var h = dur[1]
				b.pressed.connect(func():
					_api_post("/api/mod/mute", {"user_id": user_id, "duration_hours": h, "reason": "panel"}, func(code, _d):
						if not is_instance_valid(b): return
						if code == 200: b.text = "✅"
					)
				)
				action_row.add_child(b)

		if role_self >= 5 and not is_banned:
			var ban_b = _make_button("🔨 Banear", Color(0.5, 0.1, 0.1, 0.9))
			ban_b.custom_minimum_size = Vector2(90, 28)
			ban_b.add_theme_font_size_override("font_size", 11)
			ban_b.pressed.connect(func():
				_api_post("/api/mod/ban", {"user_id": user_id, "reason": "ban desde panel"}, func(code, _d):
					if not is_instance_valid(ban_b): return
					if code == 200: ban_b.text = "✅ Baneado"
				)
			)
			action_row.add_child(ban_b)

		if role_self >= 5 and is_banned:
			var unban_b = _make_button("✅ Desbanear", Color(0.1, 0.4, 0.1, 0.9))
			unban_b.custom_minimum_size = Vector2(90, 28)
			unban_b.add_theme_font_size_override("font_size", 11)
			unban_b.pressed.connect(func():
				_api_post("/api/mod/unban", {"user_id": user_id}, func(code, _d):
					if not is_instance_valid(unban_b): return
					if code == 200: unban_b.text = "✅"
				)
			)
			action_row.add_child(unban_b)

# ─── PESTAÑA: LOG DE CHAT ───────────────────────────────
func _build_chat_log_tab(C) -> void:
	var v = _content_vbox()
	_tab_title(v, "📜 Log de Chat")

	var filter_row = HBoxContainer.new()
	filter_row.add_theme_constant_override("separation", 8)
	v.add_child(filter_row)

	var user_input = LineEdit.new()
	user_input.placeholder_text = "Filtrar por usuario..."
	user_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	user_input.add_theme_stylebox_override("normal", UITheme.input_style(Color(0.15,0.15,0.2)))
	filter_row.add_child(user_input)

	var ch_opt = OptionButton.new()
	for ch in ["global", "vip", "staff"]: ch_opt.add_item(ch)
	filter_row.add_child(ch_opt)

	var btn = _make_button("Filtrar", Color(0.2, 0.4, 0.7, 0.9))
	filter_row.add_child(btn)

	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	UITheme.apply_scrollbar_theme(scroll)
	v.add_child(scroll)

	var list = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 4)
	scroll.add_child(list)

	var load_log = func():
		for c in list.get_children(): c.queue_free()
		var channel = ch_opt.get_item_text(ch_opt.selected)
		var url = "/api/mod/chat-log?channel=%s&limit=100" % channel
		if user_input.text.strip_edges() != "":
			url += "&user=" + user_input.text.strip_edges().uri_encode()
		_api_get(url, func(code, data):
			if not is_instance_valid(list): return
			if code != 200: return
			for m in data.get("messages", []):
				var row = HBoxContainer.new()
				row.add_theme_constant_override("separation", 8)
				list.add_child(row)

				var ts = Label.new()
				ts.text = m.get("created_at","").substr(11,5)
				ts.custom_minimum_size = Vector2(40, 0)
				ts.add_theme_font_size_override("font_size", 11)
				ts.add_theme_color_override("font_color", Color(0.4,0.4,0.4))
				row.add_child(ts)

				var name = Label.new()
				name.text = m.get("username","?")
				name.custom_minimum_size = Vector2(100, 0)
				name.add_theme_font_size_override("font_size", 12)
				name.add_theme_color_override("font_color",
					Color(0.6,0.2,0.2) if m.get("is_deleted",0) == 1 else Color(0.4,0.8,0.4))
				row.add_child(name)

				var content = Label.new()
				content.text = m.get("content","")
				content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				content.autowrap_mode = TextServer.AUTOWRAP_OFF
				content.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
				content.add_theme_font_size_override("font_size", 12)
				content.add_theme_color_override("font_color",
					Color(0.4,0.4,0.4) if m.get("is_deleted",0) == 1 else Color(0.85,0.85,0.85))
				row.add_child(content)
		)

	btn.pressed.connect(load_log)
	load_log.call()

# ─── PESTAÑA: RECOMPENSAS ───────────────────────────────
func _build_rewards_tab(C) -> void:
	var v = _content_vbox()
	_tab_title(v, "🎁 Otorgar / Quitar Recursos")

	var note = Label.new()
	note.text = "Selecciona el tipo de recurso, la cantidad y el jugador. Confirma antes de aplicar."
	note.autowrap_mode = TextServer.AUTOWRAP_WORD
	note.add_theme_font_size_override("font_size", 12)
	note.add_theme_color_override("font_color", Color(0.55, 0.55, 0.55))
	v.add_child(note)

	var form = GridContainer.new()
	form.columns = 2
	form.add_theme_constant_override("h_separation", 16)
	form.add_theme_constant_override("v_separation", 12)
	v.add_child(form)

	# Usuario
	form.add_child(_form_lbl("Usuario (nombre exacto):"))
	var user_input = LineEdit.new()
	user_input.placeholder_text = "Ej: Rudy"
	user_input.add_theme_stylebox_override("normal", UITheme.input_style(Color(0.15,0.15,0.2)))
	form.add_child(user_input)

	# Tipo
	form.add_child(_form_lbl("Tipo:"))
	var type_opt = OptionButton.new()
	type_opt.add_item("💎 Gemas",                0)
	type_opt.add_item("🪙 Monedas",              1)
	type_opt.add_item("⭐ XP Pase de Batalla",   2)
	type_opt.add_item("🎟️ Activar Pase Premium", 3)
	type_opt.add_item("📦 Sobres",               4)
	form.add_child(type_opt)

	# Tipo de sobre (oculto por defecto)
	var pack_lbl = _form_lbl("Tipo de sobre:")
	form.add_child(pack_lbl)
	var pack_opt = OptionButton.new()
	for p in ["typhlosion_pack", "feraligatr_pack", "meganium_pack"]:
		pack_opt.add_item(p)
	form.add_child(pack_opt)
	pack_lbl.hide(); pack_opt.hide()

	# Cantidad
	var qty_lbl = _form_lbl("Cantidad:")
	form.add_child(qty_lbl)
	var qty_input = SpinBox.new()
	qty_input.min_value = 1; qty_input.max_value = 10000; qty_input.value = 100
	form.add_child(qty_input)

	type_opt.item_selected.connect(func(idx):
		var t = type_opt.get_item_id(idx)
		pack_lbl.visible  = (t == 4)
		pack_opt.visible  = (t == 4)
		qty_lbl.visible   = (t != 3)
		qty_input.visible = (t != 3)
	)

	var status_lbl = _status_label(v)

	# ── Botones OTORGAR / QUITAR ──
	var btn_row = HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 16)
	v.add_child(btn_row)
	v.add_child(status_lbl)

	var give_btn = _make_button("🎁  Otorgar", Color(0.1, 0.42, 0.15, 0.95))
	give_btn.custom_minimum_size = Vector2(160, 42)
	give_btn.add_theme_font_size_override("font_size", 14)
	btn_row.add_child(give_btn)

	var take_btn = _make_button("➖  Quitar", Color(0.48, 0.1, 0.1, 0.95))
	take_btn.custom_minimum_size = Vector2(160, 42)
	take_btn.add_theme_font_size_override("font_size", 14)
	btn_row.add_child(take_btn)

	# ── Lógica compartida ──
	var _do_send = func(is_take: bool):
		var target_user = user_input.text.strip_edges()
		if target_user == "":
			status_lbl.text = "❌ Ingresa el nombre del usuario."
			return

		var t         = type_opt.get_item_id(type_opt.selected)
		var qty       = int(qty_input.value)
		var type_name = type_opt.get_item_text(type_opt.selected)
		var pack_name = pack_opt.get_item_text(pack_opt.selected) if t == 4 else ""

		# Texto legible para el diálogo
		var action_str: String
		if t == 3:
			action_str = "%s el Pase Premium a «%s»" % [
				"quitar" if is_take else "activar", target_user
			]
		elif t == 4:
			action_str = "%s %d sobre(s) «%s» %s «%s»" % [
				"quitar" if is_take else "entregar",
				qty, pack_name,
				"de" if is_take else "a",
				target_user
			]
		else:
			action_str = "%s %d %s %s «%s»" % [
				"quitar" if is_take else "entregar",
				qty, type_name,
				"de" if is_take else "a",
				target_user
			]

		var body: Dictionary = {
			"username": target_user,
			"amount":   -qty if is_take else qty
		}
		match t:
			0: body["reward_type"] = "gems"
			1: body["reward_type"] = "coins"
			2: body["reward_type"] = "bp_xp"
			3: body["reward_type"] = "premium_pass"
			4:
				body["reward_type"] = "pack"
				body["pack_id"]     = pack_name

		_show_confirm_dialog(
			"¿Estás seguro de %s?" % action_str,
			func():
				if not is_instance_valid(status_lbl): return
				status_lbl.text = "Enviando..."
				_api_post("/api/mod/give-reward", body, func(code, data):
					if not is_instance_valid(status_lbl): return
					if code == 200:
						status_lbl.text = "✅ " + data.get("message", "Operación completada.")
					else:
						status_lbl.text = "❌ " + data.get("error", "Error.")
				)
		)

	give_btn.pressed.connect(func(): _do_send.call(false))
	take_btn.pressed.connect(func(): _do_send.call(true))

# ─── PESTAÑA: GESTIÓN DE ROLES ──────────────────────────
func _build_roles_tab(C) -> void:
	var v = _content_vbox()
	_tab_title(v, "👑 Gestión de Roles")

	var search_row = HBoxContainer.new()
	search_row.add_theme_constant_override("separation", 8)
	v.add_child(search_row)

	var input = LineEdit.new()
	input.placeholder_text = "Nombre de usuario..."
	input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	input.add_theme_stylebox_override("normal", UITheme.input_style(Color(0.15,0.15,0.2)))
	search_row.add_child(input)

	var search_btn = _make_button("Buscar", Color(0.2,0.4,0.7,0.9))
	search_row.add_child(search_btn)

	var result_v = VBoxContainer.new()
	result_v.add_theme_constant_override("separation", 10)
	v.add_child(result_v)

	var status_lbl = _status_label(v)

	search_btn.pressed.connect(func():
		for c in result_v.get_children(): c.queue_free()
		status_lbl.text = "Buscando..."
		_api_get("/api/mod/search-user?q=" + input.text.uri_encode(), func(code, data):
			if not is_instance_valid(status_lbl) or not is_instance_valid(result_v): return
			status_lbl.text = ""
			for u in data.get("users", []):
				var row = HBoxContainer.new()
				row.add_theme_constant_override("separation", 12)
				result_v.add_child(row)

				var name_lbl = Label.new()
				name_lbl.text = u.get("username","?") + "  [" + ROLE_NAMES.get(u.get("role",1),"?") + "]"
				name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				name_lbl.add_theme_font_size_override("font_size", 14)
				name_lbl.add_theme_color_override("font_color", Color(0.9,0.9,0.9))
				row.add_child(name_lbl)

				var role_opt = OptionButton.new()
				var my_role = PlayerData.role if "role" in PlayerData else 5
				for r in range(0, my_role):
					role_opt.add_item(ROLE_NAMES.get(r,"?"))
				role_opt.selected = min(u.get("role",1), my_role - 1)
				row.add_child(role_opt)

				var apply_btn = _make_button("Aplicar", Color(0.4,0.2,0.0,0.9))
				var uid = u.get("id","")
				apply_btn.pressed.connect(func():
					_api_post("/api/mod/set-role", {"user_id": uid, "new_role": role_opt.selected}, func(code, d):
						if not is_instance_valid(name_lbl) or not is_instance_valid(status_lbl): return
						if code == 200:
							name_lbl.text = u.get("username","?") + "  [" + ROLE_NAMES.get(role_opt.selected,"?") + "] ✅"
						else:
							status_lbl.text = "❌ " + d.get("error","Error")
					)
				)
				row.add_child(apply_btn)
		)
	)

# ─── PESTAÑA: BANS ACTIVOS ──────────────────────────────
func _build_bans_tab(C) -> void:
	var v = _content_vbox()
	_tab_title(v, "🔨 Bans Activos")

	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	UITheme.apply_scrollbar_theme(scroll)
	v.add_child(scroll)

	var list = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 8)
	scroll.add_child(list)

	var status_lbl = _status_label(v)
	status_lbl.text = "Cargando..."

	_api_get("/api/mod/bans", func(code, data):
		if not is_instance_valid(status_lbl) or not is_instance_valid(list): return
		status_lbl.text = ""
		if code != 200:
			status_lbl.text = "Error al cargar"
			return
		var bans = data.get("bans", [])
		if bans.is_empty():
			status_lbl.text = "✅ No hay usuarios baneados"
			return
		for b in bans:
			var row = HBoxContainer.new()
			row.add_theme_constant_override("separation", 12)
			list.add_child(row)

			var info = Label.new()
			info.text = "🔨 %s  —  %s  ·  %s" % [
				b.get("username","?"),
				b.get("ban_reason","?"),
				b.get("banned_at","").substr(0,16)
			]
			info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			info.add_theme_font_size_override("font_size", 13)
			info.add_theme_color_override("font_color", Color(0.9,0.5,0.5))
			row.add_child(info)

			var unban_btn = _make_button("✅ Desbanear", Color(0.1,0.4,0.1,0.9))
			unban_btn.custom_minimum_size = Vector2(100, 28)
			unban_btn.add_theme_font_size_override("font_size", 11)
			var uid = b.get("id","")
			unban_btn.pressed.connect(func():
				_api_post("/api/mod/unban", {"user_id": uid}, func(code2, _d):
					if not is_instance_valid(row): return
					if code2 == 200: row.queue_free()
				)
			)
			row.add_child(unban_btn)
	)

# ─── PESTAÑA: ESTADÍSTICAS ──────────────────────────────
func _build_stats_tab(C) -> void:
	var v = _content_vbox()
	_tab_title(v, "📊 Estadísticas del Servidor")

	var status_lbl = _status_label(v)
	status_lbl.text = "Cargando..."

	_api_get("/api/mod/stats", func(code, data):
		if not is_instance_valid(status_lbl) or not is_instance_valid(v): return
		status_lbl.text = ""
		if code != 200:
			status_lbl.text = "Error al cargar estadísticas"
			return

		var grid = GridContainer.new()
		grid.columns = 2
		grid.add_theme_constant_override("h_separation", 24)
		grid.add_theme_constant_override("v_separation", 12)
		v.add_child(grid)

		var sections = {
			"👥 Usuarios": data.get("users", {}),
			"💬 Chat":     data.get("chat",  {}),
			"🎮 Juego":    data.get("game",  {}),
			"🚩 Reportes": data.get("reports",{}),
		}

		for section_name in sections:
			var sec_data = sections[section_name]
			var card = PanelContainer.new()
			var st = StyleBoxFlat.new()
			st.bg_color = Color(0.1,0.12,0.18,0.9)
			st.border_color = Color(0.2,0.25,0.35)
			st.border_width_left = 3
			st.corner_radius_top_left = 8; st.corner_radius_top_right = 8
			st.corner_radius_bottom_left = 8; st.corner_radius_bottom_right = 8
			st.content_margin_left = 16; st.content_margin_right = 16
			st.content_margin_top = 12; st.content_margin_bottom = 12
			card.add_theme_stylebox_override("panel", st)
			grid.add_child(card)

			var cv = VBoxContainer.new()
			cv.add_theme_constant_override("separation", 6)
			card.add_child(cv)

			var title_lbl = Label.new()
			title_lbl.text = section_name
			title_lbl.add_theme_font_size_override("font_size", 14)
			title_lbl.add_theme_color_override("font_color", Color(1.0,0.65,0.0))
			cv.add_child(title_lbl)

			for key in sec_data:
				var kv = Label.new()
				kv.text = "%s:  %s" % [key.replace("_"," "), str(sec_data[key])]
				kv.add_theme_font_size_override("font_size", 13)
				kv.add_theme_color_override("font_color", Color(0.85,0.85,0.85))
				cv.add_child(kv)
	)

# ─── PESTAÑA: ANUNCIOS ──────────────────────────────────
func _build_announce_tab(C) -> void:
	var v = _content_vbox()
	_tab_title(v, "📢 Enviar Anuncio al Servidor")

	var input = TextEdit.new()
	input.placeholder_text = "Escribe el anuncio aquí (máx. 500 caracteres)..."
	input.custom_minimum_size = Vector2(0, 120)
	input.add_theme_stylebox_override("normal", UITheme.input_style(Color(0.1,0.1,0.15)))
	v.add_child(input)

	var status_lbl = _status_label(v)

	var btn = _make_button("📢 Enviar Anuncio a todos", Color(0.5, 0.3, 0.0, 0.9))
	btn.custom_minimum_size = Vector2(220, 40)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.pressed.connect(func():
		var text = input.text.strip_edges()
		if text.is_empty():
			status_lbl.text = "❌ Escribe algo primero"
			return
		_api_post("/api/mod/announce", {"text": text}, func(code, data):
			if not is_instance_valid(status_lbl) or not is_instance_valid(input): return
			if code == 200:
				status_lbl.text = "✅ Anuncio enviado"
				input.text = ""
			else:
				status_lbl.text = "❌ " + data.get("error","Error")
		)
	)
	v.add_child(btn)
	v.add_child(status_lbl)

# ─── PESTAÑA: SLOW MODE ─────────────────────────────────
func _build_slowmode_tab(C) -> void:
	var v = _content_vbox()
	_tab_title(v, "🐢 Slow Mode por Canal")

	for ch in ["global", "vip", "staff"]:
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 16)
		v.add_child(row)

		var ch_lbl = Label.new()
		ch_lbl.text = "#" + ch
		ch_lbl.custom_minimum_size = Vector2(80, 0)
		ch_lbl.add_theme_font_size_override("font_size", 14)
		ch_lbl.add_theme_color_override("font_color", Color(0.8,0.8,0.8))
		ch_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(ch_lbl)

		var spin = SpinBox.new()
		spin.min_value = 0; spin.max_value = 120; spin.value = 0
		spin.suffix = "s"
		row.add_child(spin)

		var apply_btn = _make_button("Aplicar", Color(0.3,0.3,0.5,0.9))
		apply_btn.custom_minimum_size = Vector2(80, 28)
		var channel = ch
		apply_btn.pressed.connect(func():
			_api_post("/api/mod/slowmode", {"channel": channel, "seconds": int(spin.value)}, func(code, _data):
				if not is_instance_valid(apply_btn): return
				if code == 200: apply_btn.text = "✅"
			)
		)
		row.add_child(apply_btn)

	var note = Label.new()
	note.text = "0 segundos = desactivado"
	note.add_theme_font_size_override("font_size", 12)
	note.add_theme_color_override("font_color", Color(0.5,0.5,0.5))
	v.add_child(note)

# ─── PESTAÑA: LOG DE ACCIONES ────────────────────────────
func _build_action_log_tab(C) -> void:
	var v = _content_vbox()
	_tab_title(v, "🗂️ Log Completo de Acciones")

	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	UITheme.apply_scrollbar_theme(scroll)
	v.add_child(scroll)

	var list = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 4)
	scroll.add_child(list)

	var status_lbl = _status_label(v)
	status_lbl.text = "Cargando..."

	_api_get("/api/mod/action-log?limit=100", func(code, data):
		if not is_instance_valid(status_lbl) or not is_instance_valid(list): return
		status_lbl.text = ""
		if code != 200:
			status_lbl.text = "Error al cargar"
			return
		for a in data.get("actions", []):
			var lbl = Label.new()
			var details = a.get("details","")
			lbl.text = "[%s]  %s  →  %s  ·  %s  %s" % [
				a.get("created_at","").substr(0,16),
				a.get("mod_name","?"),
				a.get("action_type","?"),
				a.get("target_name","—"),
				("(" + details.substr(0,60) + ")") if details else ""
			]
			lbl.add_theme_font_size_override("font_size", 12)
			lbl.add_theme_color_override("font_color", Color(0.7,0.7,0.7))
			list.add_child(lbl)
	)

# ─── PESTAÑA: RANKING MODS ──────────────────────────────
func _build_mod_ranking_tab(C) -> void:
	var v = _content_vbox()
	_tab_title(v, "🏅 Ranking de Moderadores (esta semana)")

	var status_lbl = _status_label(v)
	status_lbl.text = "Cargando..."

	_api_get("/api/mod/mod-ranking", func(code, data):
		if not is_instance_valid(status_lbl) or not is_instance_valid(v): return
		status_lbl.text = ""
		if code != 200:
			status_lbl.text = "Error al cargar"
			return
		var ranking = data.get("ranking", [])
		if ranking.is_empty():
			status_lbl.text = "Sin datos esta semana"
			return

		for i in range(ranking.size()):
			var r = ranking[i]
			var row = HBoxContainer.new()
			row.add_theme_constant_override("separation", 12)
			v.add_child(row)

			var pos_lbl = Label.new()
			pos_lbl.text = "#%d" % (i + 1)
			pos_lbl.custom_minimum_size = Vector2(30, 0)
			pos_lbl.add_theme_font_size_override("font_size", 14)
			pos_lbl.add_theme_color_override("font_color", Color(1.0,0.65,0.0))
			row.add_child(pos_lbl)

			var name_lbl = Label.new()
			name_lbl.text = r.get("mod_name","?")
			name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			name_lbl.add_theme_font_size_override("font_size", 14)
			name_lbl.add_theme_color_override("font_color", Color(0.9,0.9,0.9))
			row.add_child(name_lbl)

			var count_lbl = Label.new()
			count_lbl.text = str(r.get("actions",0)) + " acciones"
			count_lbl.add_theme_font_size_override("font_size", 13)
			count_lbl.add_theme_color_override("font_color", Color(0.4,0.8,0.4))
			row.add_child(count_lbl)
	)

# ─── SIN ACCESO ─────────────────────────────────────────
func _show_no_access(container: Control, C) -> void:
	var lbl = Label.new()
	lbl.text = "🔒 Sin acceso"
	lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 20)
	lbl.add_theme_color_override("font_color", Color(0.4,0.4,0.4))
	container.add_child(lbl)
