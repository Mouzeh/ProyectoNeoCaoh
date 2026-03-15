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
#   • 🏟️ Gimnasios     (role >= 5)   ← NUEVO
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
	header.offset_top  = 0; header.offset_bottom = 80
	var hs = StyleBoxFlat.new()
	hs.bg_color = Color(0.07, 0.05, 0.03, 0.98)
	hs.border_color = Color(1.0, 0.65, 0.0, 0.6)
	hs.border_width_bottom = 3
	hs.shadow_color = Color(1.0, 0.55, 0.0, 0.12)
	hs.shadow_size  = 12
	header.add_theme_stylebox_override("panel", hs)
	container.add_child(header)

	# Línea decorativa de acento izquierda
	var accent_bar = ColorRect.new()
	accent_bar.color = Color(1.0, 0.65, 0.0, 1.0)
	accent_bar.anchor_left = 0; accent_bar.anchor_right  = 0
	accent_bar.anchor_top  = 0; accent_bar.anchor_bottom = 1
	accent_bar.offset_right = 5
	header.add_child(accent_bar)

	var hbox = HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.add_theme_constant_override("separation", 16)
	var hm = MarginContainer.new()
	hm.add_theme_constant_override("margin_left",  20)
	hm.add_theme_constant_override("margin_right", 24)
	header.add_child(hm)
	hm.add_child(hbox)

	var title_vbox = VBoxContainer.new()
	title_vbox.add_theme_constant_override("separation", 3)
	title_vbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox.add_child(title_vbox)

	var title = Label.new()
	title.text = "⚙️  PANEL DE MODERACIÓN"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(1.0, 0.72, 0.15))
	title_vbox.add_child(title)

	var role_badge_lbl = Label.new()
	role_badge_lbl.text = "Acceso: " + ROLE_NAMES.get(role, "Staff")
	role_badge_lbl.add_theme_font_size_override("font_size", 12)
	role_badge_lbl.add_theme_color_override("font_color", Color(1.0, 0.65, 0.0, 0.60))
	title_vbox.add_child(role_badge_lbl)

	var layout = HBoxContainer.new()
	layout.anchor_left   = 0; layout.anchor_right  = 1
	layout.anchor_top    = 0; layout.anchor_bottom = 1
	layout.offset_top    = 80; layout.offset_bottom = -8
	layout.offset_left   = 8;  layout.offset_right  = -8
	layout.add_theme_constant_override("separation", 0)
	container.add_child(layout)

	var sidebar = _build_sidebar(layout, role, C)
	layout.add_child(sidebar)

	var content_wrapper = PanelContainer.new()
	content_wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_wrapper.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	var cw_st = StyleBoxFlat.new()
	cw_st.bg_color = Color(0.05, 0.06, 0.09, 0.98)
	cw_st.border_color = Color(1.0, 0.55, 0.0, 0.14)
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
	sidebar.custom_minimum_size = Vector2(290, 0)
	var sb_st = StyleBoxFlat.new()
	sb_st.bg_color = Color(0.05, 0.04, 0.03, 0.99)
	sb_st.border_color = Color(1.0, 0.60, 0.0, 0.18)
	sb_st.border_width_right = 1
	sb_st.corner_radius_top_left    = 12; sb_st.corner_radius_bottom_left = 12
	sidebar.add_theme_stylebox_override("panel", sb_st)

	var sv = VBoxContainer.new()
	sv.add_theme_constant_override("separation", 3)
	var sm = MarginContainer.new()
	sm.add_theme_constant_override("margin_left",   10)
	sm.add_theme_constant_override("margin_right",  10)
	sm.add_theme_constant_override("margin_top",    18)
	sm.add_theme_constant_override("margin_bottom", 18)
	sidebar.add_child(sm)
	sm.add_child(sv)

	# Mini header de la sidebar
	var nav_lbl = Label.new()
	nav_lbl.text = "NAVEGACIÓN"
	nav_lbl.add_theme_font_size_override("font_size", 10)
	nav_lbl.add_theme_color_override("font_color", Color(1.0, 0.65, 0.0, 0.45))
	var nav_m = MarginContainer.new()
	nav_m.add_theme_constant_override("margin_left", 12)
	nav_m.add_theme_constant_override("margin_bottom", 6)
	nav_m.add_child(nav_lbl)
	sv.add_child(nav_m)

	var sep_line = ColorRect.new()
	sep_line.custom_minimum_size = Vector2(0, 1)
	sep_line.color = Color(1.0, 0.60, 0.0, 0.12)
	sv.add_child(sep_line)

	var spacer_top = Control.new()
	spacer_top.custom_minimum_size = Vector2(0, 6)
	sv.add_child(spacer_top)

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
		tabs.append(["gyms",        "🏟️  Gimnasios"])  # ← NUEVO
	if role >= 6:
		tabs.append(["action_log",  "🗂️  Log de acciones"])
		tabs.append(["mod_ranking", "🏅  Ranking mods"])

	for tab in tabs:
		var btn = Button.new()
		btn.text = tab[1]
		btn.custom_minimum_size = Vector2(0, 68)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.add_theme_font_size_override("font_size", 18)

		var st_n = StyleBoxFlat.new()
		st_n.bg_color = Color(0,0,0,0)
		st_n.corner_radius_top_left    = 8; st_n.corner_radius_top_right    = 8
		st_n.corner_radius_bottom_left = 8; st_n.corner_radius_bottom_right = 8
		st_n.content_margin_left = 12
		var st_h = st_n.duplicate()
		st_h.bg_color = Color(1.0, 0.65, 0.0, 0.08)
		st_h.border_color = Color(1.0, 0.65, 0.0, 0.18)
		st_h.border_width_left = 2
		var st_p = st_n.duplicate()
		st_p.bg_color = Color(1.0, 0.55, 0.0, 0.14)
		st_p.border_color = Color(1.0, 0.72, 0.0, 0.90)
		st_p.border_width_left = 3
		st_p.shadow_color = Color(1.0, 0.55, 0.0, 0.15)
		st_p.shadow_size  = 6

		btn.add_theme_stylebox_override("normal",  st_n)
		btn.add_theme_stylebox_override("hover",   st_h)
		btn.add_theme_stylebox_override("pressed", st_p)
		btn.add_theme_color_override("font_color",           Color(0.72, 0.68, 0.62))
		btn.add_theme_color_override("font_hover_color",     Color(0.95, 0.90, 0.80))
		btn.add_theme_color_override("font_pressed_color",   Color(1.0,  0.80, 0.25))

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
		"gyms":       _build_gyms_tab(C)  # ← NUEVO
		"action_log": _build_action_log_tab(C)
		"mod_ranking":_build_mod_ranking_tab(C)

# ─── HELPERS ────────────────────────────────────────────
func _content_vbox() -> VBoxContainer:
	var m = MarginContainer.new()
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	m.add_theme_constant_override("margin_left",   32)
	m.add_theme_constant_override("margin_right",  32)
	m.add_theme_constant_override("margin_top",    28)
	m.add_theme_constant_override("margin_bottom", 28)
	_tab_content.add_child(m)

	var v = VBoxContainer.new()
	v.add_theme_constant_override("separation", 20)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	m.add_child(v)
	return v

func _tab_title(parent: Control, text: String) -> void:
	var title_container = HBoxContainer.new()
	title_container.add_theme_constant_override("separation", 12)
	parent.add_child(title_container)

	var bar = ColorRect.new()
	bar.color = Color(1.0, 0.65, 0.0, 1.0)
	bar.custom_minimum_size = Vector2(4, 0)
	bar.size_flags_vertical = Control.SIZE_EXPAND_FILL
	title_container.add_child(bar)

	var vb = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 2)
	title_container.add_child(vb)

	var lbl = Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 20)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.78, 0.28))
	vb.add_child(lbl)

	var div = ColorRect.new()
	div.custom_minimum_size = Vector2(0, 1)
	div.color = Color(1.0, 0.65, 0.0, 0.15)
	div.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(div)

func _make_button(text: String, color: Color) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	var st = StyleBoxFlat.new()
	st.bg_color = Color(color.r, color.g, color.b, color.a * 0.85)
	st.border_color = Color(color.r * 1.3, color.g * 1.3, color.b * 1.3, 0.55).clamp()
	st.border_width_left = 1; st.border_width_right  = 1
	st.border_width_top  = 1; st.border_width_bottom = 1
	st.corner_radius_top_left    = 8; st.corner_radius_top_right    = 8
	st.corner_radius_bottom_left = 8; st.corner_radius_bottom_right = 8
	st.content_margin_left   = 14; st.content_margin_right  = 14
	st.content_margin_top    = 6;  st.content_margin_bottom = 6

	var st_h = st.duplicate()
	st_h.bg_color = Color(color.r * 1.2, color.g * 1.2, color.b * 1.2, 1.0).clamp()
	st_h.shadow_color = Color(color.r, color.g, color.b, 0.30)
	st_h.shadow_size  = 6

	var st_p = st.duplicate()
	st_p.bg_color = Color(color.r * 0.8, color.g * 0.8, color.b * 0.8, 1.0).clamp()

	btn.add_theme_stylebox_override("normal",  st)
	btn.add_theme_stylebox_override("hover",   st_h)
	btn.add_theme_stylebox_override("pressed", st_p)
	btn.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.95))
	btn.add_theme_font_size_override("font_size", 13)
	return btn

func _api_post(endpoint: String, body: Dictionary, callback: Callable) -> void:
	var http = HTTPRequest.new()
	add_child(http)
	var headers = [
		"Content-Type: application/json",
		"Authorization: Bearer " + NetworkManager.token
	]
	http.request(NetworkManager.BASE_URL + endpoint,
		headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	var self_ref = weakref(self)
	http.request_completed.connect(func(result, code, _h, resp_body):
		var s = self_ref.get_ref()
		if s == null or not is_instance_valid(s):
			if is_instance_valid(http): http.queue_free()
			return
		var data = {}
		if resp_body.size() > 0:
			var parsed = JSON.parse_string(resp_body.get_string_from_utf8())
			if parsed is Dictionary:
				data = parsed
		if is_instance_valid(http): http.queue_free()
		if callback.is_valid():
			callback.call(code, data)
	)

func _api_get(endpoint: String, callback: Callable) -> void:
	var http = HTTPRequest.new()
	add_child(http)
	var headers = ["Authorization: Bearer " + NetworkManager.token]
	http.request(NetworkManager.BASE_URL + endpoint, headers)
	var self_ref = weakref(self)
	http.request_completed.connect(func(result, code, _h, resp_body):
		var s = self_ref.get_ref()
		if s == null or not is_instance_valid(s):
			if is_instance_valid(http): http.queue_free()
			return
		var data = {}
		if resp_body.size() > 0:
			var parsed = JSON.parse_string(resp_body.get_string_from_utf8())
			if parsed is Dictionary:
				data = parsed
		if is_instance_valid(http): http.queue_free()
		if callback.is_valid():
			callback.call(code, data)
	)

func _status_label(parent: Control) -> Label:
	var lbl = Label.new()
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(lbl)
	return lbl

func _form_lbl(txt: String) -> Label:
	var l = Label.new()
	l.text = txt
	l.add_theme_font_size_override("font_size", 14)
	l.add_theme_color_override("font_color", Color(0.78, 0.74, 0.68))
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
	st.bg_color = Color(0.14, 0.07, 0.07, 0.95)
	st.border_color = Color(0.75, 0.20, 0.20, 0.70)
	st.border_width_left = 4
	st.border_width_right = 1; st.border_width_top = 1; st.border_width_bottom = 1
	st.corner_radius_top_left    = 10; st.corner_radius_top_right    = 10
	st.corner_radius_bottom_left = 10; st.corner_radius_bottom_right = 10
	st.content_margin_left   = 18; st.content_margin_right  = 18
	st.content_margin_top    = 14; st.content_margin_bottom = 14
	st.shadow_color = Color(0.6, 0.1, 0.1, 0.18)
	st.shadow_size  = 6
	card.add_theme_stylebox_override("panel", st)
	parent.add_child(card)

	var cv = VBoxContainer.new()
	cv.add_theme_constant_override("separation", 8)
	card.add_child(cv)

	var info = Label.new()
	info.text = "🔴  %s  reportó a  %s   ·   Motivo: %s   ·   %s" % [
		r.get("reporter_name","?"),
		r.get("reported_name","?"),
		r.get("reason","?"),
		r.get("created_at","").substr(0,16)
	]
	info.add_theme_font_size_override("font_size", 14)
	info.add_theme_color_override("font_color", Color(0.95, 0.88, 0.88))
	cv.add_child(info)

	if r.get("message_content","") != "":
		var msg_panel = PanelContainer.new()
		var mp_st = StyleBoxFlat.new()
		mp_st.bg_color = Color(0.08, 0.05, 0.05, 0.80)
		mp_st.border_color = Color(0.5, 0.2, 0.2, 0.30)
		mp_st.border_width_left = 2
		mp_st.corner_radius_top_left    = 6; mp_st.corner_radius_top_right    = 6
		mp_st.corner_radius_bottom_left = 6; mp_st.corner_radius_bottom_right = 6
		mp_st.content_margin_left = 12; mp_st.content_margin_right = 12
		mp_st.content_margin_top  = 8;  mp_st.content_margin_bottom = 8
		msg_panel.add_theme_stylebox_override("panel", mp_st)
		cv.add_child(msg_panel)
		var msg_lbl = Label.new()
		msg_lbl.text = "\"" + r.get("message_content","") + "\""
		msg_lbl.add_theme_font_size_override("font_size", 13)
		msg_lbl.add_theme_color_override("font_color", Color(0.65, 0.60, 0.60))
		msg_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		msg_panel.add_child(msg_lbl)

	var btn_row = HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 8)
	cv.add_child(btn_row)

	var report_id = r.get("id", 0)
	var reported_id = r.get("reported_id","")

	for dur in [["🔇 Silenciar 1h", 1], ["🔇 Silenciar 24h", 24], ["🔇 Silenciar 7d", 168]]:
		var btn = _make_button(dur[0], Color(0.50, 0.28, 0.0, 0.95))
		btn.custom_minimum_size = Vector2(120, 34)
		var hours = dur[1]
		btn.pressed.connect(func():
			_api_post("/api/mod/mute", {"user_id": reported_id, "duration_hours": hours, "reason": "report"}, func(code, d):
				if not is_instance_valid(btn): return
				if code == 200: btn.text = "✅ Silenciado"
			)
		)
		btn_row.add_child(btn)

	var dismiss_btn = _make_button("✕ Ignorar", Color(0.22, 0.22, 0.26, 0.95))
	dismiss_btn.custom_minimum_size = Vector2(90, 34)
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
	var is_banned = u.get("ban_reason", null) != null
	var is_muted  = u.get("muted_until", null) != null
	st.bg_color = Color(0.18, 0.06, 0.06, 0.92) if is_banned else Color(0.10, 0.12, 0.18, 0.92)
	st.border_color = Color(0.70, 0.18, 0.18, 0.65) if is_banned else Color(0.25, 0.32, 0.48, 0.55)
	st.border_width_left = 4
	st.border_width_right = 1; st.border_width_top = 1; st.border_width_bottom = 1
	st.corner_radius_top_left    = 10; st.corner_radius_top_right    = 10
	st.corner_radius_bottom_left = 10; st.corner_radius_bottom_right = 10
	st.content_margin_left   = 18; st.content_margin_right  = 18
	st.content_margin_top    = 14; st.content_margin_bottom = 14
	card.add_theme_stylebox_override("panel", st)
	parent.add_child(card)

	var cv = VBoxContainer.new()
	cv.add_theme_constant_override("separation", 10)
	card.add_child(cv)

	# Info row
	var info_row = HBoxContainer.new()
	info_row.add_theme_constant_override("separation", 16)
	cv.add_child(info_row)

	var name_lbl = Label.new()
	name_lbl.text = u.get("username","?")
	name_lbl.add_theme_font_size_override("font_size", 17)
	name_lbl.add_theme_color_override("font_color",
		Color(0.95, 0.45, 0.45) if is_banned else Color(0.95, 0.92, 0.85))
	info_row.add_child(name_lbl)

	var role_pill = PanelContainer.new()
	var rp_st = StyleBoxFlat.new()
	rp_st.bg_color = Color(1.0, 0.65, 0.0, 0.12)
	rp_st.border_color = Color(1.0, 0.65, 0.0, 0.30)
	rp_st.border_width_left=1; rp_st.border_width_right=1
	rp_st.border_width_top=1;  rp_st.border_width_bottom=1
	rp_st.corner_radius_top_left=12; rp_st.corner_radius_top_right=12
	rp_st.corner_radius_bottom_left=12; rp_st.corner_radius_bottom_right=12
	rp_st.content_margin_left=10; rp_st.content_margin_right=10
	rp_st.content_margin_top=3;   rp_st.content_margin_bottom=3
	role_pill.add_theme_stylebox_override("panel", rp_st)
	role_pill.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var role_lbl_inner = Label.new()
	role_lbl_inner.text = ROLE_NAMES.get(u.get("role",1), "?")
	role_lbl_inner.add_theme_font_size_override("font_size", 11)
	role_lbl_inner.add_theme_color_override("font_color", Color(1.0, 0.78, 0.28))
	role_pill.add_child(role_lbl_inner)
	info_row.add_child(role_pill)

	var stats_lbl = Label.new()
	stats_lbl.text = "ELO %s  ·  🪙 %s" % [str(u.get("elo", 0)), str(u.get("coins", 0))]
	stats_lbl.add_theme_font_size_override("font_size", 13)
	stats_lbl.add_theme_color_override("font_color", Color(0.55, 0.55, 0.62))
	info_row.add_child(stats_lbl)

	if is_banned:
		var ban_lbl = Label.new()
		ban_lbl.text = "🔨 BANEADO"
		ban_lbl.add_theme_font_size_override("font_size", 13)
		ban_lbl.add_theme_color_override("font_color", Color(0.95, 0.35, 0.35))
		info_row.add_child(ban_lbl)
	if is_muted:
		var mute_lbl = Label.new()
		mute_lbl.text = "🔇 SILENCIADO"
		mute_lbl.add_theme_font_size_override("font_size", 13)
		mute_lbl.add_theme_color_override("font_color", Color(0.95, 0.65, 0.20))
		info_row.add_child(mute_lbl)

	var role_self = PlayerData.role if "role" in PlayerData else 3
	var target_role = u.get("role", 1)
	var user_id = u.get("id", "")

	if target_role < role_self:
		var action_row = HBoxContainer.new()
		action_row.add_theme_constant_override("separation", 8)
		cv.add_child(action_row)

		if role_self >= 3:
			for dur in [["🔇 Mutear 1h", 1], ["🔇 Mutear 24h", 24]]:
				var b = _make_button(dur[0], Color(0.50, 0.28, 0.0, 0.95))
				b.custom_minimum_size = Vector2(110, 34)
				var h = dur[1]
				b.pressed.connect(func():
					_api_post("/api/mod/mute", {"user_id": user_id, "duration_hours": h, "reason": "panel"}, func(code, _d):
						if not is_instance_valid(b): return
						if code == 200: b.text = "✅"
					)
				)
				action_row.add_child(b)

		if role_self >= 5 and not is_banned:
			var ban_b = _make_button("🔨 Banear", Color(0.52, 0.08, 0.08, 0.95))
			ban_b.custom_minimum_size = Vector2(110, 34)
			ban_b.pressed.connect(func():
				_api_post("/api/mod/ban", {"user_id": user_id, "reason": "ban desde panel"}, func(code, _d):
					if not is_instance_valid(ban_b): return
					if code == 200: ban_b.text = "✅ Baneado"
				)
			)
			action_row.add_child(ban_b)

		if role_self >= 5 and is_banned:
			var unban_b = _make_button("✅ Desbanear", Color(0.08, 0.42, 0.12, 0.95))
			unban_b.custom_minimum_size = Vector2(110, 34)
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
				ts.custom_minimum_size = Vector2(46, 0)
				ts.add_theme_font_size_override("font_size", 12)
				ts.add_theme_color_override("font_color", Color(0.38,0.38,0.44))
				row.add_child(ts)

				var name = Label.new()
				name.text = m.get("username","?")
				name.custom_minimum_size = Vector2(110, 0)
				name.add_theme_font_size_override("font_size", 13)
				name.add_theme_color_override("font_color",
					Color(0.65,0.20,0.20) if m.get("is_deleted",0) == 1 else Color(0.38,0.82,0.48))
				row.add_child(name)

				var content = Label.new()
				content.text = m.get("content","")
				content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				content.autowrap_mode = TextServer.AUTOWRAP_OFF
				content.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
				content.add_theme_font_size_override("font_size", 13)
				content.add_theme_color_override("font_color",
					Color(0.38,0.38,0.40) if m.get("is_deleted",0) == 1 else Color(0.88,0.88,0.90))
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
	note.add_theme_font_size_override("font_size", 13)
	note.add_theme_color_override("font_color", Color(0.58, 0.55, 0.50))
	v.add_child(note)

	var form = GridContainer.new()
	form.columns = 2
	form.add_theme_constant_override("h_separation", 20)
	form.add_theme_constant_override("v_separation", 14)
	v.add_child(form)

	form.add_child(_form_lbl("Usuario (nombre exacto):"))
	var user_input = LineEdit.new()
	user_input.placeholder_text = "Ej: Rudy"
	user_input.add_theme_stylebox_override("normal", UITheme.input_style(Color(0.15,0.15,0.2)))
	form.add_child(user_input)

	form.add_child(_form_lbl("Tipo:"))
	var type_opt = OptionButton.new()
	type_opt.add_item("💎 Gemas",                0)
	type_opt.add_item("🪙 Monedas",              1)
	type_opt.add_item("⭐ XP Pase de Batalla",   2)
	type_opt.add_item("🎟️ Activar Pase Premium", 3)
	type_opt.add_item("📦 Sobres",               4)
	form.add_child(type_opt)

	var pack_lbl = _form_lbl("Tipo de sobre:")
	form.add_child(pack_lbl)
	var pack_opt = OptionButton.new()
	for p in ["typhlosion_pack", "feraligatr_pack", "meganium_pack"]:
		pack_opt.add_item(p)
	form.add_child(pack_opt)
	pack_lbl.hide(); pack_opt.hide()

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

	var btn_row = HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 16)
	v.add_child(btn_row)

	var status_lbl = _status_label(v)

	var give_btn = _make_button("🎁  Otorgar", Color(0.08, 0.42, 0.14, 0.95))
	give_btn.custom_minimum_size = Vector2(180, 48)
	give_btn.add_theme_font_size_override("font_size", 16)
	btn_row.add_child(give_btn)

	var take_btn = _make_button("➖  Quitar", Color(0.48, 0.08, 0.08, 0.95))
	take_btn.custom_minimum_size = Vector2(180, 48)
	take_btn.add_theme_font_size_override("font_size", 16)
	btn_row.add_child(take_btn)

	var _do_send = func(is_take: bool):
		var target_user = user_input.text.strip_edges()
		if target_user == "":
			status_lbl.text = "❌ Ingresa el nombre del usuario."
			return
		var t         = type_opt.get_item_id(type_opt.selected)
		var qty       = int(qty_input.value)
		var type_name = type_opt.get_item_text(type_opt.selected)
		var pack_name = pack_opt.get_item_text(pack_opt.selected) if t == 4 else ""
		var action_str: String
		if t == 3:
			action_str = "%s el Pase Premium a «%s»" % ["quitar" if is_take else "activar", target_user]
		elif t == 4:
			action_str = "%s %d sobre(s) «%s» %s «%s»" % ["quitar" if is_take else "entregar", qty, pack_name, "de" if is_take else "a", target_user]
		else:
			action_str = "%s %d %s %s «%s»" % ["quitar" if is_take else "entregar", qty, type_name, "de" if is_take else "a", target_user]
		var body: Dictionary = {"username": target_user, "amount": -qty if is_take else qty}
		match t:
			0: body["reward_type"] = "gems"
			1: body["reward_type"] = "coins"
			2: body["reward_type"] = "bp_xp"
			3: body["reward_type"] = "premium_pass"
			4: body["reward_type"] = "pack"; body["pack_id"] = pack_name
		_show_confirm_dialog("¿Estás seguro de %s?" % action_str, func():
			if not is_instance_valid(status_lbl): return
			status_lbl.text = "Enviando..."
			_api_post("/api/mod/give-reward", body, func(code, data):
				if not is_instance_valid(status_lbl): return
				if code == 200: status_lbl.text = "✅ " + data.get("message", "Operación completada.")
				else: status_lbl.text = "❌ " + data.get("error", "Error.")
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
						if code == 200: name_lbl.text = u.get("username","?") + "  [" + ROLE_NAMES.get(role_opt.selected,"?") + "] ✅"
						else: status_lbl.text = "❌ " + d.get("error","Error")
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
		if code != 200: status_lbl.text = "Error al cargar"; return
		var bans = data.get("bans", [])
		if bans.is_empty(): status_lbl.text = "✅ No hay usuarios baneados"; return
		for b in bans:
			var row = HBoxContainer.new()
			row.add_theme_constant_override("separation", 12)
			list.add_child(row)
			var info = Label.new()
			info.text = "🔨 %s  —  %s  ·  %s" % [b.get("username","?"), b.get("ban_reason","?"), b.get("banned_at","").substr(0,16)]
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
		if code != 200: status_lbl.text = "Error al cargar estadísticas"; return
		var grid = GridContainer.new()
		grid.columns = 2
		grid.add_theme_constant_override("h_separation", 24)
		grid.add_theme_constant_override("v_separation", 12)
		v.add_child(grid)
		var sections = {"👥 Usuarios": data.get("users", {}), "💬 Chat": data.get("chat", {}), "🎮 Juego": data.get("game", {}), "🚩 Reportes": data.get("reports",{})}
		for section_name in sections:
			var sec_data = sections[section_name]
			var card = PanelContainer.new()
			var st = StyleBoxFlat.new()
			st.bg_color = Color(0.09,0.11,0.17,0.95)
			st.border_color = Color(1.0, 0.60, 0.0, 0.28)
			st.border_width_left = 4
			st.border_width_right = 1; st.border_width_top = 1; st.border_width_bottom = 1
			st.corner_radius_top_left = 10; st.corner_radius_top_right = 10
			st.corner_radius_bottom_left = 10; st.corner_radius_bottom_right = 10
			st.content_margin_left = 18; st.content_margin_right = 18
			st.content_margin_top = 14; st.content_margin_bottom = 14
			st.shadow_color = Color(0.0, 0.0, 0.0, 0.22)
			st.shadow_size  = 5
			card.add_theme_stylebox_override("panel", st)
			grid.add_child(card)
			var cv = VBoxContainer.new()
			cv.add_theme_constant_override("separation", 8)
			card.add_child(cv)
			var title_lbl = Label.new()
			title_lbl.text = section_name
			title_lbl.add_theme_font_size_override("font_size", 16)
			title_lbl.add_theme_color_override("font_color", Color(1.0,0.72,0.18))
			cv.add_child(title_lbl)
			var div2 = ColorRect.new()
			div2.custom_minimum_size = Vector2(0,1)
			div2.color = Color(1.0, 0.60, 0.0, 0.15)
			cv.add_child(div2)
			for key in sec_data:
				var kv = Label.new()
				kv.text = "%s:  %s" % [key.replace("_"," "), str(sec_data[key])]
				kv.add_theme_font_size_override("font_size", 14)
				kv.add_theme_color_override("font_color", Color(0.88,0.85,0.80))
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
	var btn = _make_button("📢  Enviar Anuncio a todos", Color(0.50, 0.28, 0.0, 0.95))
	btn.custom_minimum_size = Vector2(260, 48)
	btn.add_theme_font_size_override("font_size", 16)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(btn)
	var status_lbl = _status_label(v)
	btn.pressed.connect(func():
		var text = input.text.strip_edges()
		if text.is_empty(): status_lbl.text = "❌ Escribe algo primero"; return
		_api_post("/api/mod/announce", {"text": text}, func(code, data):
			if not is_instance_valid(status_lbl) or not is_instance_valid(input): return
			if code == 200: status_lbl.text = "✅ Anuncio enviado"; input.text = ""
			else: status_lbl.text = "❌ " + data.get("error","Error")
		)
	)

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
		ch_lbl.custom_minimum_size = Vector2(90, 0)
		ch_lbl.add_theme_font_size_override("font_size", 16)
		ch_lbl.add_theme_color_override("font_color", Color(0.88,0.85,0.78))
		ch_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(ch_lbl)
		var spin = SpinBox.new()
		spin.min_value = 0; spin.max_value = 120; spin.value = 0; spin.suffix = "s"
		row.add_child(spin)
		var apply_btn = _make_button("Aplicar", Color(0.28,0.28,0.48,0.95))
		apply_btn.custom_minimum_size = Vector2(100, 38)
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
	note.add_theme_font_size_override("font_size", 13)
	note.add_theme_color_override("font_color", Color(0.48,0.46,0.42))
	v.add_child(note)

# ─── PESTAÑA: GIMNASIOS ─────────────────────────────────────
func _build_gyms_tab(C) -> void:
	var v = _content_vbox()
	_tab_title(v, "🏟️ Gestión de Líderes de Gimnasio")

	var note = Label.new()
	note.text = "Asigna o remueve líderes y sub-líderes. Un usuario solo puede liderar un gym a la vez."
	note.autowrap_mode = TextServer.AUTOWRAP_WORD
	note.add_theme_font_size_override("font_size", 13)
	note.add_theme_color_override("font_color", Color(0.58, 0.55, 0.50))
	v.add_child(note)

	var status_lbl = _status_label(v)
	status_lbl.text = "Cargando gimnasios..."

	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	UITheme.apply_scrollbar_theme(scroll)
	v.add_child(scroll)

	var list = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 10)
	scroll.add_child(list)

	_api_get("/api/mod/gyms", func(code, data):
		if not is_instance_valid(status_lbl) or not is_instance_valid(list): return
		status_lbl.text = ""
		if code != 200:
			status_lbl.text = "❌ Error al cargar gimnasios (código %d)" % code
			return
		var gyms = data.get("gyms", [])
		if gyms.is_empty():
			status_lbl.text = "No se encontraron gimnasios"
			return
		for gym in gyms:
			_add_gym_card(list, gym, status_lbl)
	)

func _add_gym_card(parent: Control, gym: Dictionary, status_lbl: Label) -> void:
	var card = PanelContainer.new()
	var st = StyleBoxFlat.new()
	st.bg_color = Color(0.07, 0.09, 0.14, 0.97)
	st.border_color = Color(0.28, 0.40, 0.65, 0.75)
	st.border_width_left   = 4
	st.border_width_right  = 1
	st.border_width_top    = 1
	st.border_width_bottom = 1
	st.corner_radius_top_left    = 10; st.corner_radius_top_right    = 10
	st.corner_radius_bottom_left = 10; st.corner_radius_bottom_right = 10
	st.content_margin_left   = 18; st.content_margin_right  = 18
	st.content_margin_top    = 14; st.content_margin_bottom = 14
	st.shadow_color = Color(0.0, 0.0, 0.0, 0.20)
	st.shadow_size  = 6
	card.add_theme_stylebox_override("panel", st)
	parent.add_child(card)

	var cv = VBoxContainer.new()
	cv.add_theme_constant_override("separation", 10)
	card.add_child(cv)

	var gym_type_colors = {
		"GRASS": Color(0.3, 0.8, 0.3), "FIRE": Color(1.0, 0.4, 0.1),
		"WATER": Color(0.2, 0.6, 1.0), "LIGHTNING": Color(1.0, 0.9, 0.1),
		"PSYCHIC": Color(0.9, 0.3, 0.9), "FIGHTING": Color(0.9, 0.4, 0.2),
		"DARKNESS": Color(0.5, 0.3, 0.7), "METAL": Color(0.6, 0.7, 0.8),
		"COLORLESS": Color(0.8, 0.8, 0.8)
	}
	var type_color = gym_type_colors.get(gym.get("gym_type", ""), Color(0.7, 0.7, 0.7))

	var title_row = HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 8)
	cv.add_child(title_row)

	var gym_name_lbl = Label.new()
	gym_name_lbl.text = gym.get("name", "?")
	gym_name_lbl.add_theme_font_size_override("font_size", 17)
	gym_name_lbl.add_theme_color_override("font_color", type_color)
	gym_name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(gym_name_lbl)

	var type_badge = Label.new()
	type_badge.text = gym.get("gym_type", "")
	type_badge.add_theme_font_size_override("font_size", 13)
	type_badge.add_theme_color_override("font_color", type_color.lerp(Color.WHITE, 0.3))
	title_row.add_child(type_badge)

	var sep = ColorRect.new()
	sep.custom_minimum_size = Vector2(0, 1)
	sep.color = Color(0.2, 0.25, 0.35, 0.5)
	cv.add_child(sep)

	var gym_id = gym.get("gym_id", "")
	_add_leader_row(cv, gym_id, "leader",
		gym.get("leader_user_id", null),
		gym.get("leader_username", null),
		status_lbl)
	_add_leader_row(cv, gym_id, "sub_leader",
		gym.get("sub_leader_user_id", null),
		gym.get("sub_leader_username", null),
		status_lbl)

func _add_leader_row(
	parent: Control,
	gym_id: String,
	role_type: String,
	current_id,
	current_name,
	status_lbl: Label
) -> void:
	var role_label = "Líder" if role_type == "leader" else "Sub-Líder"
	var icon = "👑" if role_type == "leader" else "🥈"

	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	parent.add_child(row)

	var role_lbl = Label.new()
	role_lbl.text = "%s %s:" % [icon, role_label]
	role_lbl.custom_minimum_size = Vector2(100, 0)
	role_lbl.add_theme_font_size_override("font_size", 14)
	role_lbl.add_theme_color_override("font_color", Color(0.78, 0.74, 0.68))
	role_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(role_lbl)

	var current_lbl = Label.new()
	if current_name:
		current_lbl.text = current_name
		current_lbl.add_theme_color_override("font_color", Color(0.95, 0.88, 0.50))
	else:
		current_lbl.text = "— Sin asignar —"
		current_lbl.add_theme_color_override("font_color", Color(0.38, 0.38, 0.42))
	current_lbl.custom_minimum_size = Vector2(150, 0)
	current_lbl.add_theme_font_size_override("font_size", 14)
	current_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(current_lbl)

	var search_input = LineEdit.new()
	search_input.placeholder_text = "Buscar usuario..."
	search_input.custom_minimum_size = Vector2(160, 0)
	search_input.add_theme_stylebox_override("normal", UITheme.input_style(Color(0.12, 0.12, 0.18)))
	row.add_child(search_input)

	var results_opt = OptionButton.new()
	results_opt.custom_minimum_size = Vector2(160, 0)
	results_opt.hide()
	row.add_child(results_opt)

	# Array como contenedor para captura por referencia en lambdas
	var sel = [current_id]  # sel[0] = selected_user_id

	var search_btn = _make_button("🔍", Color(0.2, 0.3, 0.5, 0.9))
	search_btn.custom_minimum_size = Vector2(36, 0)
	row.add_child(search_btn)

	search_btn.pressed.connect(func():
		var q = search_input.text.strip_edges()
		if q.length() < 2:
			status_lbl.text = "❌ Escribe al menos 2 caracteres"
			return
		_api_get("/api/mod/gym-search-user?q=" + q.uri_encode(), func(code, data):
			if not is_instance_valid(results_opt): return
			results_opt.clear()
			var users = data.get("users", [])
			if users.is_empty():
				status_lbl.text = "No se encontraron usuarios"
				results_opt.hide()
				return
			for u in users:
				results_opt.add_item("%s (ELO %d)" % [u.get("username","?"), u.get("elo",0)])
				results_opt.set_item_metadata(results_opt.item_count - 1, u.get("id",""))
			results_opt.show()
			sel[0] = results_opt.get_item_metadata(0)
		)
	)

	results_opt.item_selected.connect(func(idx):
		sel[0] = results_opt.get_item_metadata(idx)
	)

	var assign_btn = _make_button("✔ Asignar", Color(0.08, 0.42, 0.14, 0.95))
	assign_btn.custom_minimum_size = Vector2(100, 34)
	row.add_child(assign_btn)

	assign_btn.pressed.connect(func():
		if not sel[0]:
			status_lbl.text = "❌ Selecciona un usuario primero"
			return
		var user_label = results_opt.get_item_text(results_opt.selected) if results_opt.visible else (current_name if current_name else "?")
		_show_confirm_dialog(
			"¿Asignar %s como %s del %s?" % [user_label, role_label, gym_id],
			func():
				_api_put_gym_leader(gym_id, sel[0], role_type, func(code, data):
					if not is_instance_valid(status_lbl) or not is_instance_valid(current_lbl): return
					if code == 200:
						status_lbl.text = "✅ " + data.get("message", "Asignado correctamente")
						current_lbl.text = user_label.split(" (")[0]
						current_lbl.add_theme_color_override("font_color", Color(0.9, 0.85, 0.5))
						results_opt.hide()
						search_input.text = ""
					else:
						status_lbl.text = "❌ " + data.get("error", "Error al asignar")
				)
		)
	)

	if current_id:
		var remove_btn = _make_button("✕ Remover", Color(0.45, 0.08, 0.08, 0.95))
		remove_btn.custom_minimum_size = Vector2(100, 34)
		row.add_child(remove_btn)
		remove_btn.pressed.connect(func():
			_show_confirm_dialog(
				"¿Remover a %s como %s de %s?" % [current_name, role_label, gym_id],
				func():
					_api_put_gym_leader(gym_id, null, role_type, func(code, data):
						if not is_instance_valid(status_lbl) or not is_instance_valid(current_lbl): return
						if code == 200:
							status_lbl.text = "✅ " + data.get("message", "Removido")
							current_lbl.text = "— Sin asignar —"
							current_lbl.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
							remove_btn.queue_free()
						else:
							status_lbl.text = "❌ " + data.get("error", "Error")
					)
			)
		)

func _api_put_gym_leader(gym_id: String, user_id, role_type: String, callback: Callable) -> void:
	var http = HTTPRequest.new()
	add_child(http)
	var headers = [
		"Content-Type: application/json",
		"Authorization: Bearer " + NetworkManager.token
	]
	var body = JSON.stringify({"user_id": user_id, "role_type": role_type})
	http.request(
		NetworkManager.BASE_URL + "/api/mod/gyms/" + gym_id + "/leader",
		headers,
		HTTPClient.METHOD_PUT,
		body
	)
	http.request_completed.connect(func(result, code, _h, resp_body):
		var data = {}
		if resp_body.size() > 0:
			var parsed = JSON.parse_string(resp_body.get_string_from_utf8())
			if parsed is Dictionary: data = parsed
		callback.call(code, data)
		http.queue_free()
	)

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
		if code != 200: status_lbl.text = "Error al cargar"; return
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
			lbl.add_theme_font_size_override("font_size", 13)
			lbl.add_theme_color_override("font_color", Color(0.70,0.68,0.65))
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
		if code != 200: status_lbl.text = "Error al cargar"; return
		var ranking = data.get("ranking", [])
		if ranking.is_empty(): status_lbl.text = "Sin datos esta semana"; return
		for i in range(ranking.size()):
			var r = ranking[i]
			var row = HBoxContainer.new()
			row.add_theme_constant_override("separation", 12)
			v.add_child(row)
			var pos_lbl = Label.new()
			pos_lbl.text = "#%d" % (i + 1)
			pos_lbl.custom_minimum_size = Vector2(40, 0)
			pos_lbl.add_theme_font_size_override("font_size", 18)
			pos_lbl.add_theme_color_override("font_color", Color(1.0,0.72,0.18))
			row.add_child(pos_lbl)
			var name_lbl = Label.new()
			name_lbl.text = r.get("mod_name","?")
			name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			name_lbl.add_theme_font_size_override("font_size", 16)
			name_lbl.add_theme_color_override("font_color", Color(0.92,0.90,0.86))
			row.add_child(name_lbl)
			var count_lbl = Label.new()
			count_lbl.text = str(r.get("actions",0)) + " acciones"
			count_lbl.add_theme_font_size_override("font_size", 15)
			count_lbl.add_theme_color_override("font_color", Color(0.38,0.82,0.48))
			row.add_child(count_lbl)
	)

# ─── SIN ACCESO ─────────────────────────────────────────
func _show_no_access(container: Control, C) -> void:
	var lbl = Label.new()
	lbl.text = "🔒  Sin acceso"
	lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 24)
	lbl.add_theme_color_override("font_color", Color(0.38,0.36,0.34))
	container.add_child(lbl)
