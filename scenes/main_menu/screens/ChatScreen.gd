extends Node

# ============================================================
# ChatScreen.gd — Layout de dos paneles
#   IZQUIERDO: usuarios conectados ordenados por rango
#   DERECHO:   chat grande + input abajo
# ============================================================

const ROLE_COLORS = {
	0: Color(0.45, 0.45, 0.45),
	1: Color(0.88, 0.88, 0.88),
	2: Color(1.0,  0.84, 0.0),
	3: Color(0.30, 0.76, 0.30),
	4: Color(0.13, 0.59, 0.95),
	5: Color(1.0,  0.60, 0.0),
	6: Color(0.96, 0.26, 0.21),
}
const ROLE_BADGES = {
	0: "",     1: "",     2: "⭐",
	3: "🛡️",  4: "🔵",  5: "⚙️",  6: "👑",
}
const ROLE_NAMES = {
	0: "Invitado", 1: "Usuario", 2: "VIP",
	3: "Mod", 4: "Coord", 5: "Admin", 6: "Owner",
}
# Orden de prioridad visual (mayor = aparece primero)
const ROLE_ORDER = { 6: 0, 5: 1, 4: 2, 3: 3, 2: 4, 1: 5, 0: 6 }

const MAX_MESSAGES   = 100
const CHANNEL_GLOBAL = "global"
const CHANNEL_VIP    = "vip"
const CHANNEL_STAFF  = "staff"

var current_channel  = CHANNEL_GLOBAL
var message_nodes    = []
var online_users     = []   # Array de dicts {username, role, user_id}
var _muted_until     = null
var _slow_timer      = 0.0
var _slow_interval   = 0

# Nodos
var _scroll:        ScrollContainer
var _msg_vbox:      VBoxContainer
var _input:         LineEdit
var _send_btn:      Button
var _online_lbl:    Label
var _channel_tabs:  HBoxContainer
var _mute_banner:   Panel
var _slow_lbl:      Label
var _users_vbox:    VBoxContainer
var _users_count_lbl: Label

# ─── ENTRY POINT ─────────────────────────────────────────
static func build(container: Control, menu) -> void:
	var screen = load("res://scenes/main_menu/screens/ChatScreen.gd").new()
	screen.name = "ChatScreenNode"
	container.add_child(screen)
	screen._setup(container, menu)

func _setup(container: Control, menu) -> void:
	# Restaurar color guardado en PlayerData al iniciar
	_my_bubble_color_idx = clamp(int(PlayerData.bubble_color_idx), 0, BUBBLE_COLORS.size() - 1)

	# ── Fondo general ──────────────────────────────────────
	var bg = ColorRect.new()
	bg.color = Color(0.04, 0.05, 0.07, 1.0)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(bg)

	# ── Contenedor principal (HBox de dos paneles) ──────────
	var root_margin = MarginContainer.new()
	root_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_margin.offset_top = 54   # debajo del navbar
	root_margin.add_theme_constant_override("margin_left",   0)
	root_margin.add_theme_constant_override("margin_right",  0)
	root_margin.add_theme_constant_override("margin_top",    0)
	root_margin.add_theme_constant_override("margin_bottom", 0)
	container.add_child(root_margin)

	var split = HBoxContainer.new()
	split.set_anchors_preset(Control.PRESET_FULL_RECT)
	split.add_theme_constant_override("separation", 0)
	root_margin.add_child(split)

	# ═══════════════════════════════════════════════════════
	# PANEL IZQUIERDO — usuarios conectados
	# ═══════════════════════════════════════════════════════
	var left_panel = _build_left_panel(menu)
	left_panel.custom_minimum_size = Vector2(220, 0)
	left_panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	split.add_child(left_panel)

	# Separador vertical dorado
	var divider = ColorRect.new()
	divider.color = Color(menu.COLOR_GOLD.r, menu.COLOR_GOLD.g, menu.COLOR_GOLD.b, 0.15)
	divider.custom_minimum_size = Vector2(1, 0)
	divider.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.add_child(divider)

	# ═══════════════════════════════════════════════════════
	# PANEL DERECHO — chat + input
	# ═══════════════════════════════════════════════════════
	var right_panel = _build_right_panel(menu)
	right_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	split.add_child(right_panel)

	_request_history()

# ═══════════════════════════════════════════════════════════
# PANEL IZQUIERDO
# ═══════════════════════════════════════════════════════════
func _build_left_panel(menu) -> Control:
	var panel = PanelContainer.new()
	var st = StyleBoxFlat.new()
	st.bg_color = Color(0.05, 0.06, 0.09, 1.0)
	panel.add_theme_stylebox_override("panel", st)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 0)
	panel.add_child(vbox)

	# ── Cabecera izquierda ──
	var header = _make_panel_header(menu, "👥 EN LÍNEA")
	vbox.add_child(header)

	# Contador
	_users_count_lbl = Label.new()
	_users_count_lbl.text = "0 conectados"
	_users_count_lbl.add_theme_font_size_override("font_size", 10)
	_users_count_lbl.add_theme_color_override("font_color", Color(0.4, 0.8, 0.4, 0.9))
	_users_count_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var count_margin = MarginContainer.new()
	count_margin.add_theme_constant_override("margin_top",    6)
	count_margin.add_theme_constant_override("margin_bottom", 6)
	count_margin.add_child(_users_count_lbl)
	vbox.add_child(count_margin)

	# Separador
	vbox.add_child(_make_separator(menu))

	# ── Selector de color de burbuja ──
	var color_section = _build_color_picker_section(menu)
	vbox.add_child(color_section)
	vbox.add_child(_make_separator(menu))

	# Scroll de usuarios
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	UITheme.apply_scrollbar_theme(scroll)
	vbox.add_child(scroll)

	_users_vbox = VBoxContainer.new()
	_users_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_users_vbox.add_theme_constant_override("separation", 2)
	var um = MarginContainer.new()
	um.add_theme_constant_override("margin_left",   8)
	um.add_theme_constant_override("margin_right",  8)
	um.add_theme_constant_override("margin_top",    6)
	um.add_theme_constant_override("margin_bottom", 6)
	um.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	um.add_child(_users_vbox)
	scroll.add_child(um)

	return panel



func _build_color_picker_section(menu) -> Control:
	var container = VBoxContainer.new()
	container.add_theme_constant_override("separation", 6)

	var title = Label.new()
	title.text = "🎨 MI BURBUJA"
	title.add_theme_font_size_override("font_size", 10)
	title.add_theme_color_override("font_color", menu.COLOR_GOLD_DIM)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var tm = MarginContainer.new()
	tm.add_theme_constant_override("margin_top", 8)
	tm.add_theme_constant_override("margin_bottom", 2)
	tm.add_child(title)
	container.add_child(tm)

	# Grid de colores 4x2
	var grid = GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	var gm = MarginContainer.new()
	gm.add_theme_constant_override("margin_left",   12)
	gm.add_theme_constant_override("margin_right",  12)
	gm.add_theme_constant_override("margin_bottom",  8)
	gm.add_child(grid)
	container.add_child(gm)

	var current_idx = clamp(int(PlayerData.bubble_color_idx), 0, BUBBLE_COLORS.size() - 1)
	var color_btns = []

	for i in range(BUBBLE_COLORS.size()):
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(36, 28)
		btn.tooltip_text = BUBBLE_COLOR_NAMES[i]

		var col = BUBBLE_COLORS[i]
		var is_selected = (i == current_idx)

		var bst = StyleBoxFlat.new()
		bst.bg_color = col
		bst.corner_radius_top_left     = 5
		bst.corner_radius_top_right    = 5
		bst.corner_radius_bottom_left  = 5
		bst.corner_radius_bottom_right = 5
		bst.border_color = menu.COLOR_GOLD if is_selected else Color(1,1,1,0.15)
		bst.border_width_left=2; bst.border_width_right=2
		bst.border_width_top=2;  bst.border_width_bottom=2
		btn.add_theme_stylebox_override("normal",  bst)
		btn.add_theme_stylebox_override("hover",   bst)
		btn.add_theme_stylebox_override("pressed", bst)

		# Checkmark si está seleccionado
		if is_selected:
			btn.text = "✓"
			btn.add_theme_color_override("font_color", Color.WHITE)
			btn.add_theme_font_size_override("font_size", 12)

		var idx_capture = i
		var all_btns_ref = color_btns
		btn.pressed.connect(func():
			_set_my_bubble_color(idx_capture)
			# Actualizar apariencia de todos los botones
			for j in range(all_btns_ref.size()):
				var b = all_btns_ref[j]
				if not is_instance_valid(b): continue
				var s = StyleBoxFlat.new()
				s.bg_color = BUBBLE_COLORS[j]
				s.corner_radius_top_left=5; s.corner_radius_top_right=5
				s.corner_radius_bottom_left=5; s.corner_radius_bottom_right=5
				s.border_color = menu.COLOR_GOLD if j == idx_capture else Color(1,1,1,0.15)
				s.border_width_left=2; s.border_width_right=2
				s.border_width_top=2;  s.border_width_bottom=2
				b.add_theme_stylebox_override("normal",  s)
				b.add_theme_stylebox_override("hover",   s)
				b.add_theme_stylebox_override("pressed", s)
				b.text = "✓" if j == idx_capture else ""
		)
		color_btns.append(btn)
		grid.add_child(btn)

	return container

func _make_panel_header(menu, title: String) -> Control:
	var header = Panel.new()
	header.custom_minimum_size = Vector2(0, 46)
	var hs = StyleBoxFlat.new()
	hs.bg_color = Color(0.07, 0.08, 0.12, 1.0)
	hs.border_color = Color(menu.COLOR_GOLD.r, menu.COLOR_GOLD.g, menu.COLOR_GOLD.b, 0.3)
	hs.border_width_bottom = 2
	header.add_theme_stylebox_override("panel", hs)
	var lbl = Label.new()
	lbl.text = title
	lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", menu.COLOR_GOLD)
	header.add_child(lbl)
	return header


func _make_separator(menu) -> Control:
	var sep = ColorRect.new()
	sep.color = Color(menu.COLOR_GOLD.r, menu.COLOR_GOLD.g, menu.COLOR_GOLD.b, 0.1)
	sep.custom_minimum_size = Vector2(0, 1)
	return sep


func _rebuild_users_list(menu) -> void:
	if not _users_vbox: return
	for c in _users_vbox.get_children(): c.queue_free()

	# Ordenar por role DESC
	var sorted = online_users.duplicate()
	sorted.sort_custom(func(a, b):
		return ROLE_ORDER.get(a.get("role", 1), 5) < ROLE_ORDER.get(b.get("role", 1), 5)
	)

	var last_role_group = -1
	for u in sorted:
		var role = u.get("role", 1)

		# Separador de grupo de rol
		if role != last_role_group:
			last_role_group = role
			var group_lbl = Label.new()
			var badge = ROLE_BADGES.get(role, "")
			group_lbl.text = (badge + " " if badge != "" else "") + ROLE_NAMES.get(role, "")
			group_lbl.add_theme_font_size_override("font_size", 9)
			group_lbl.add_theme_color_override("font_color",
				Color(ROLE_COLORS[role].r, ROLE_COLORS[role].g, ROLE_COLORS[role].b, 0.65))
			var gm = MarginContainer.new()
			gm.add_theme_constant_override("margin_left",  6)
			gm.add_theme_constant_override("margin_top",   8)
			gm.add_theme_constant_override("margin_bottom",2)
			gm.add_child(group_lbl)
			_users_vbox.add_child(gm)

		# Fila de usuario
		var row = _make_user_row(u, menu)
		_users_vbox.add_child(row)

	if _users_count_lbl:
		_users_count_lbl.text = "%d conectado%s" % [
			sorted.size(), "s" if sorted.size() != 1 else ""
		]


func _make_user_row(u: Dictionary, menu) -> Control:
	var role  = u.get("role", 1)
	var uname = u.get("username", "?")
	var is_me = u.get("user_id", "") == PlayerData.player_id

	var btn = Button.new()
	btn.flat = true
	btn.custom_minimum_size = Vector2(0, 36)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var btn_st = StyleBoxFlat.new()
	btn_st.bg_color = Color(1, 1, 1, 0.0)
	btn_st.corner_radius_top_left     = 6
	btn_st.corner_radius_top_right    = 6
	btn_st.corner_radius_bottom_left  = 6
	btn_st.corner_radius_bottom_right = 6
	var btn_st_hover = btn_st.duplicate()
	btn_st_hover.bg_color = Color(
		ROLE_COLORS[role].r, ROLE_COLORS[role].g, ROLE_COLORS[role].b, 0.08
	)
	btn.add_theme_stylebox_override("normal", btn_st)
	btn.add_theme_stylebox_override("hover",  btn_st_hover)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(hbox)

	# Punto de presencia coloreado por rol
	var dot = ColorRect.new()
	dot.color = ROLE_COLORS.get(role, Color.WHITE)
	dot.custom_minimum_size = Vector2(6, 6)
	dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(dot)

	# Nombre
	var name_lbl = Label.new()
	name_lbl.text = uname + (" (tú)" if is_me else "")
	name_lbl.add_theme_font_size_override("font_size", 12)
	name_lbl.add_theme_color_override("font_color",
		menu.COLOR_GOLD if is_me else ROLE_COLORS.get(role, Color.WHITE))
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.clip_text = true
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(name_lbl)

	# Badge
	var badge_txt = ROLE_BADGES.get(role, "")
	if badge_txt != "":
		var badge_lbl = Label.new()
		badge_lbl.text = badge_txt
		badge_lbl.add_theme_font_size_override("font_size", 11)
		badge_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hbox.add_child(badge_lbl)

	return btn


# ═══════════════════════════════════════════════════════════
# PANEL DERECHO
# ═══════════════════════════════════════════════════════════
func _build_right_panel(menu) -> Control:
	var panel = PanelContainer.new()
	var st = StyleBoxFlat.new()
	st.bg_color = Color(0.04, 0.05, 0.08, 1.0)
	panel.add_theme_stylebox_override("panel", st)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 0)
	panel.add_child(vbox)

	# ── Cabecera derecha (título + canal tabs + online) ──
	var header = _build_chat_header(menu)
	vbox.add_child(header)

	# ── Banner de silencio ──
	_mute_banner = Panel.new()
	_mute_banner.custom_minimum_size = Vector2(0, 36)
	_mute_banner.visible = false
	var mb_st = StyleBoxFlat.new()
	mb_st.bg_color = Color(0.45, 0.08, 0.08, 0.95)
	_mute_banner.add_theme_stylebox_override("panel", mb_st)
	var mb_lbl = Label.new()
	mb_lbl.name = "MuteLbl"
	mb_lbl.text = "🔇 Estás silenciado"
	mb_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	mb_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mb_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	mb_lbl.add_theme_font_size_override("font_size", 13)
	mb_lbl.add_theme_color_override("font_color", Color.WHITE)
	_mute_banner.add_child(mb_lbl)
	vbox.add_child(_mute_banner)

	# ── Área de mensajes ──
	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	UITheme.apply_scrollbar_theme(_scroll)
	vbox.add_child(_scroll)

	var msg_margin = MarginContainer.new()
	msg_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	msg_margin.add_theme_constant_override("margin_left",   16)
	msg_margin.add_theme_constant_override("margin_right",  16)
	msg_margin.add_theme_constant_override("margin_top",    10)
	msg_margin.add_theme_constant_override("margin_bottom", 10)
	_scroll.add_child(msg_margin)

	_msg_vbox = VBoxContainer.new()
	_msg_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_msg_vbox.add_theme_constant_override("separation", 6)
	msg_margin.add_child(_msg_vbox)

	# ── Input bar ──
	var input_area = _build_input_area(menu)
	vbox.add_child(input_area)

	return panel


func _build_chat_header(menu) -> Control:
	var header = Panel.new()
	header.custom_minimum_size = Vector2(0, 52)
	var hs = StyleBoxFlat.new()
	hs.bg_color = Color(0.06, 0.08, 0.12, 1.0)
	hs.border_color = Color(menu.COLOR_GOLD.r, menu.COLOR_GOLD.g, menu.COLOR_GOLD.b, 0.3)
	hs.border_width_bottom = 2
	header.add_theme_stylebox_override("panel", hs)

	var hbox = HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.add_theme_constant_override("separation", 14)
	header.add_child(hbox)

	var left_m = MarginContainer.new()
	left_m.add_theme_constant_override("margin_left", 18)
	hbox.add_child(left_m)

	var title_lbl = Label.new()
	title_lbl.text = "💬 CHAT"
	title_lbl.add_theme_font_size_override("font_size", 16)
	title_lbl.add_theme_color_override("font_color", menu.COLOR_GOLD)
	title_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	left_m.add_child(title_lbl)

	# Canal tabs
	_channel_tabs = HBoxContainer.new()
	_channel_tabs.add_theme_constant_override("separation", 6)
	_channel_tabs.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox.add_child(_channel_tabs)
	_build_channel_tabs(menu)

	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(spacer)

	# Online indicator
	_online_lbl = Label.new()
	_online_lbl.text = "● 0 en línea"
	_online_lbl.add_theme_font_size_override("font_size", 12)
	_online_lbl.add_theme_color_override("font_color", Color(0.3, 0.85, 0.3))
	_online_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var right_m = MarginContainer.new()
	right_m.add_theme_constant_override("margin_right", 20)
	right_m.add_child(_online_lbl)
	hbox.add_child(right_m)

	return header


func _build_input_area(menu) -> Control:
	var container = Panel.new()
	container.custom_minimum_size = Vector2(0, 68)
	var st = StyleBoxFlat.new()
	st.bg_color = Color(0.06, 0.07, 0.11, 1.0)
	st.border_color = Color(menu.COLOR_GOLD.r, menu.COLOR_GOLD.g, menu.COLOR_GOLD.b, 0.2)
	st.border_width_top = 1
	container.add_theme_stylebox_override("panel", st)

	var hbox = HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.add_theme_constant_override("separation", 10)
	var m = MarginContainer.new()
	m.add_theme_constant_override("margin_left",   16)
	m.add_theme_constant_override("margin_right",  16)
	m.add_theme_constant_override("margin_top",    12)
	m.add_theme_constant_override("margin_bottom", 12)
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	container.add_child(m)
	m.add_child(hbox)

	_input = LineEdit.new()
	_input.placeholder_text = "Escribe un mensaje... (Enter para enviar)"
	_input.max_length = 300
	_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var input_st = StyleBoxFlat.new()
	input_st.bg_color = Color(0.09, 0.10, 0.15, 1.0)
	input_st.border_color = Color(menu.COLOR_GOLD_DIM.r, menu.COLOR_GOLD_DIM.g, menu.COLOR_GOLD_DIM.b, 0.35)
	input_st.border_width_left   = 1; input_st.border_width_right  = 1
	input_st.border_width_top    = 1; input_st.border_width_bottom = 1
	input_st.corner_radius_top_left     = 8
	input_st.corner_radius_top_right    = 8
	input_st.corner_radius_bottom_left  = 8
	input_st.corner_radius_bottom_right = 8
	input_st.content_margin_left   = 14
	input_st.content_margin_right  = 14
	input_st.content_margin_top    = 8
	input_st.content_margin_bottom = 8
	var input_focus_st = input_st.duplicate()
	input_focus_st.border_color = menu.COLOR_GOLD
	_input.add_theme_stylebox_override("normal", input_st)
	_input.add_theme_stylebox_override("focus",  input_focus_st)
	_input.add_theme_font_size_override("font_size", 14)
	_input.add_theme_color_override("font_color", Color(0.92, 0.92, 0.92))
	_input.text_submitted.connect(_on_send)
	hbox.add_child(_input)

	# Slow mode label
	_slow_lbl = Label.new()
	_slow_lbl.text = ""
	_slow_lbl.add_theme_font_size_override("font_size", 11)
	_slow_lbl.add_theme_color_override("font_color", Color(1.0, 0.7, 0.2))
	_slow_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_slow_lbl.visible = false
	hbox.add_child(_slow_lbl)

	# Botón enviar
	_send_btn = Button.new()
	_send_btn.text = "Enviar ▶"
	_send_btn.custom_minimum_size = Vector2(90, 0)
	var sb_st = StyleBoxFlat.new()
	sb_st.bg_color = Color(menu.COLOR_GOLD.r * 0.7, menu.COLOR_GOLD.g * 0.5, 0.05, 1.0)
	sb_st.border_color = menu.COLOR_GOLD
	sb_st.border_width_left   = 1; sb_st.border_width_right  = 1
	sb_st.border_width_top    = 1; sb_st.border_width_bottom = 1
	sb_st.corner_radius_top_left     = 8
	sb_st.corner_radius_top_right    = 8
	sb_st.corner_radius_bottom_left  = 8
	sb_st.corner_radius_bottom_right = 8
	var sb_hover = sb_st.duplicate()
	sb_hover.bg_color = Color(menu.COLOR_GOLD.r * 0.85, menu.COLOR_GOLD.g * 0.65, 0.1, 1.0)
	_send_btn.add_theme_stylebox_override("normal",  sb_st)
	_send_btn.add_theme_stylebox_override("hover",   sb_hover)
	_send_btn.add_theme_stylebox_override("pressed", sb_st)
	_send_btn.add_theme_color_override("font_color", menu.COLOR_GOLD)
	_send_btn.add_theme_font_size_override("font_size", 13)
	_send_btn.pressed.connect(func(): _on_send(_input.text))
	hbox.add_child(_send_btn)

	return container

# ─── TABS DE CANAL ───────────────────────────────────────
func _build_channel_tabs(menu) -> void:
	var role = PlayerData.role if "role" in PlayerData else 1
	var channels = [CHANNEL_GLOBAL]
	if role >= 2: channels.append(CHANNEL_VIP)
	if role >= 3: channels.append(CHANNEL_STAFF)

	for ch in channels:
		var btn = Button.new()
		btn.text = "#" + ch
		btn.custom_minimum_size = Vector2(70, 28)
		btn.toggle_mode = true
		btn.button_pressed = (ch == current_channel)

		var st_n = StyleBoxFlat.new()
		st_n.bg_color = Color(0.10, 0.12, 0.18, 0.7)
		st_n.corner_radius_top_left    = 6; st_n.corner_radius_top_right    = 6
		st_n.corner_radius_bottom_left = 6; st_n.corner_radius_bottom_right = 6
		var st_p = st_n.duplicate()
		st_p.bg_color = Color(menu.COLOR_GOLD.r * 0.25, menu.COLOR_GOLD.g * 0.18, 0.0, 1.0)
		st_p.border_color = menu.COLOR_GOLD
		st_p.border_width_bottom = 2

		btn.add_theme_stylebox_override("normal",  st_n)
		btn.add_theme_stylebox_override("pressed", st_p)
		btn.add_theme_font_size_override("font_size", 11)
		btn.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))

		var channel = ch
		btn.pressed.connect(func():
			_switch_channel(channel)
			for b in _channel_tabs.get_children():
				if b != btn: b.button_pressed = false
		)
		_channel_tabs.add_child(btn)

# ─── CAMBIAR DE CANAL ────────────────────────────────────
func _switch_channel(channel: String) -> void:
	current_channel = channel
	for c in _msg_vbox.get_children(): c.queue_free()
	message_nodes.clear()
	_request_history()

# ─── WS ──────────────────────────────────────────────────
func _request_history() -> void:
	NetworkManager.send_ws({
		"type":    "CHAT_HISTORY",
		"payload": { "channel": current_channel, "limit": 50 }
	})

func _on_send(text: String) -> void:
	text = text.strip_edges()
	if text.is_empty(): return

	# ── Comandos especiales ──────────────────────────────
	if text.to_lower() == "/clear":
		_clear_local()
		_input.text = ""
		return

	if text.to_lower() == "/clearall":
		var role = PlayerData.role if "role" in PlayerData else 1
		if role < 3:
			_add_system_msg("⛔ Sin permiso. /clearall requiere rol Mod o superior.")
			_input.text = ""
			return
		NetworkManager.send_ws({
			"type":    "CHAT_CLEARALL",
			"payload": { "channel": current_channel }
		})
		_input.text = ""
		return

	if _muted_until != null and Time.get_datetime_string_from_system() < _muted_until: return
	if _slow_timer > 0: return
	NetworkManager.send_ws({
		"type":    "CHAT_GLOBAL",
		"payload": {
			"content":          text,
			"channel":          current_channel,
			"bubble_color_idx": PlayerData.bubble_color_idx
		}
	})
	_input.text = ""

func handle_ws_message(data: Dictionary) -> void:
	match data.get("type", ""):
		"CHAT_HISTORY":
			if data.get("channel", "") != current_channel: return
			for m in data.get("messages", []):
				var sid = m.get("user_id", "")
				var sc  = m.get("bubble_color_idx", -1)
				if sid != "" and sc >= 0:
					_sender_color_cache[sid] = sc
				_add_message_bubble(m, false)
			_scroll_to_bottom()

		"CHAT_MESSAGE":
			var m = data.get("message", {})
			if m.get("channel", "") != current_channel: return
			# Cachear color del remitente si viene en el mensaje
			var sender_id  = m.get("user_id", "")
			var sender_col = m.get("bubble_color_idx", -1)
			if sender_id != "" and sender_col >= 0:
				_sender_color_cache[sender_id] = sender_col
			_add_message_bubble(m, true)
			_scroll_to_bottom()

		"CHAT_ANNOUNCEMENT":
			_add_announcement(data.get("message", {}))
			_scroll_to_bottom()

		"CHAT_DELETED":
			_delete_message_bubble(data.get("message_id", -1))

		"CHAT_CLEARALL":
			_clear_local()
			_add_system_msg("🧹 Chat limpiado por un moderador.")

		"CHAT_MUTED":
			_muted_until = data.get("muted_until", "")
			_show_mute_banner()

		"CHAT_MENTION":
			_show_mention_notification(data)

		"CHAT_ONLINE_COUNT":
			var count = data.get("count", 0)
			if _online_lbl:
				_online_lbl.text = "● %d en línea" % count

		"CHAT_ONLINE_USERS":
			# El servidor debe enviar lista de usuarios conectados
			online_users = data.get("users", [])
			_rebuild_users_list(_get_menu())

# Obtener referencia al menu para colores
func _get_menu():
	var nodes = get_tree().get_nodes_in_group("main_menu")
	return nodes[0] if nodes.size() > 0 else null


# ─── COLOR DE BURBUJA PROPIA ─────────────────────────────
# Paleta de colores disponibles para el jugador
const BUBBLE_COLORS = [
	Color(0.08, 0.20, 0.38, 0.95),   # Azul oscuro (default)
	Color(0.18, 0.38, 0.18, 0.95),   # Verde bosque
	Color(0.38, 0.10, 0.38, 0.95),   # Morado
	Color(0.38, 0.18, 0.05, 0.95),   # Naranja oscuro
	Color(0.08, 0.30, 0.35, 0.95),   # Teal
	Color(0.35, 0.05, 0.08, 0.95),   # Rojo oscuro
	Color(0.28, 0.24, 0.05, 0.95),   # Dorado oscuro
	Color(0.15, 0.15, 0.22, 0.95),   # Gris azulado
]
const BUBBLE_COLOR_NAMES = [
	"Azul", "Verde", "Morado", "Naranja", "Teal", "Rojo", "Dorado", "Gris"
]

var _my_bubble_color_idx: int = 0  # se sincroniza con PlayerData en _setup
var _sender_color_cache: Dictionary = {}   # user_id → bubble_color_idx

func _get_my_bubble_color() -> Color:
	# Leer de PlayerData si existe
	var idx = _my_bubble_color_idx
	idx = clamp(int(idx), 0, BUBBLE_COLORS.size() - 1)
	return BUBBLE_COLORS[idx]

func _set_my_bubble_color(idx: int) -> void:
	idx = clamp(idx, 0, BUBBLE_COLORS.size() - 1)
	_my_bubble_color_idx = idx
	PlayerData.bubble_color_idx = idx
	PlayerData.save_bubble_color_to_server()   # persiste en servidor
	# Actualizar burbujas existentes en pantalla
	for entry in message_nodes:
		var row_node = entry.get("node")
		if not is_instance_valid(row_node): continue
		var uid = entry.get("user_id", "")
		if uid != PlayerData.player_id: continue
		for child in row_node.get_children():
			if child is PanelContainer:
				var base = BUBBLE_COLORS[idx]
				var st = StyleBoxFlat.new()
				st.bg_color = base
				st.border_color = Color(base.r*1.4, base.g*1.4, base.b*1.4, 0.5).clamp()
				st.border_width_left=1; st.border_width_right=1
				st.border_width_top=1;  st.border_width_bottom=1
				st.corner_radius_top_left=10; st.corner_radius_top_right=10
				st.corner_radius_bottom_right=2; st.corner_radius_bottom_left=10
				child.add_theme_stylebox_override("panel", st)

# ─── BURBUJA DE MENSAJE ─────────────────────────────────
# Patrón correcto en Godot 4:
#   row (VBoxContainer) alinea burbuja a izq/der con alignment
#   burbuja tiene ancho MÁXIMO fijo → el contenido puede ser menor
#   Label con SIZE_EXPAND_FILL recibe ancho definido → autowrap funciona
func _add_message_bubble(msg: Dictionary, animate: bool) -> void:
	if _msg_vbox.get_child_count() >= MAX_MESSAGES:
		_msg_vbox.get_child(0).queue_free()
		if message_nodes.size() > 0: message_nodes.pop_front()

	var role    = msg.get("role", 1)
	var is_mine = msg.get("user_id", "") == PlayerData.player_id
	var is_del  = msg.get("is_deleted", 0) == 1

	# ── Contenedor de fila: alineación derecha o izquierda ──
	var row = HBoxContainer.new()
	row.name = "msg_%d" % msg.get("id", 0)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 0)
	_msg_vbox.add_child(row)
	message_nodes.append({ "id": msg.get("id", 0), "node": row, "user_id": msg.get("user_id", "") })

	# Ancho máximo de la burbuja: 65% del área de scroll
	var panel_w  = _scroll.size.x if _scroll.size.x > 50 else 500.0
	var max_w    = panel_w * 0.65

	# Spacer empuja burbuja al lado correcto
	if is_mine:
		var sp = Control.new()
		sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(sp)

	# ── Burbuja ──────────────────────────────────────────────
	var bubble = PanelContainer.new()
	# custom_minimum_size.x = max_w hace que la burbuja NUNCA supere ese ancho.
	# SIZE_SHRINK_BEGIN la encoge si el contenido es menor.
	# PERO Godot 4 PanelContainer con SHRINK no encoge abajo del contenido mínimo,
	# así que esto da: burbuja = max(contenido, min_size) capped a max_w.
	bubble.custom_minimum_size   = Vector2(max_w, 0)
	bubble.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN

	var st = StyleBoxFlat.new()
	if is_mine:
		var base_col = _get_my_bubble_color()
		st.bg_color     = base_col
		st.border_color = Color(base_col.r * 1.4, base_col.g * 1.4, base_col.b * 1.4, 0.5).clamp()
		st.border_width_left = 1; st.border_width_right  = 1
		st.border_width_top  = 1; st.border_width_bottom = 1
	elif is_del:
		st.bg_color = Color(0.22, 0.06, 0.06, 0.7)
	else:
		var rc           = ROLE_COLORS.get(role, Color.WHITE)
		var sender_uid   = msg.get("user_id", "")
		var sender_cidx  = msg.get("bubble_color_idx", _sender_color_cache.get(sender_uid, -1))
		if sender_cidx >= 0 and sender_cidx < BUBBLE_COLORS.size():
			var sc = BUBBLE_COLORS[sender_cidx]
			st.bg_color = Color(sc.r * 0.55, sc.g * 0.55, sc.b * 0.55, 0.88)
		else:
			st.bg_color = Color(0.09, 0.11, 0.17, 0.92)
		st.border_color      = Color(rc.r, rc.g, rc.b, 0.18)
		st.border_width_left = 2
	st.corner_radius_top_left     = 10
	st.corner_radius_top_right    = 10
	st.corner_radius_bottom_right = 2  if is_mine  else 10
	st.corner_radius_bottom_left  = 10 if is_mine  else 2
	bubble.add_theme_stylebox_override("panel", st)
	row.add_child(bubble)

	if not is_mine:
		var sp = Control.new()
		sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(sp)

	# ── Interior de la burbuja ────────────────────────────────
	var bm = MarginContainer.new()
	bm.add_theme_constant_override("margin_left",   12)
	bm.add_theme_constant_override("margin_right",  12)
	bm.add_theme_constant_override("margin_top",     7)
	bm.add_theme_constant_override("margin_bottom",  7)
	bubble.add_child(bm)

	var bv = VBoxContainer.new()
	bv.add_theme_constant_override("separation", 3)
	bm.add_child(bv)

	# Nombre + badge (mensajes ajenos)
	if not is_mine:
		var name_row = HBoxContainer.new()
		name_row.add_theme_constant_override("separation", 4)
		bv.add_child(name_row)
		var badge = ROLE_BADGES.get(role, "")
		if badge != "":
			var bl = Label.new()
			bl.text = badge
			bl.add_theme_font_size_override("font_size", 11)
			name_row.add_child(bl)
		var nl = Label.new()
		nl.text = msg.get("username", "?")
		nl.add_theme_font_size_override("font_size", 15)
		nl.add_theme_color_override("font_color", ROLE_COLORS.get(role, Color.WHITE))
		name_row.add_child(nl)

	# Contenido — SIZE_EXPAND_FILL le da el ancho completo de la burbuja → autowrap funciona
	var content_lbl = Label.new()
	content_lbl.text              = "[borrado]" if is_del else msg.get("content", "")
	content_lbl.autowrap_mode     = TextServer.AUTOWRAP_WORD
	content_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_lbl.add_theme_font_size_override("font_size", 16)
	content_lbl.add_theme_color_override("font_color",
		Color(0.45, 0.45, 0.45) if is_del else Color(0.93, 0.93, 0.93))
	bv.add_child(content_lbl)

	# Timestamp
	var ts = msg.get("created_at", "")
	if ts.length() >= 16:
		var ts_lbl = Label.new()
		ts_lbl.text = ts.substr(11, 5)
		ts_lbl.add_theme_font_size_override("font_size", 10)
		ts_lbl.add_theme_color_override("font_color", Color(0.38, 0.38, 0.38))
		ts_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		bv.add_child(ts_lbl)

	# Click derecho
	bubble.mouse_filter = Control.MOUSE_FILTER_STOP
	var msg_id   = msg.get("id", 0)
	var msg_user = msg.get("user_id", "")
	bubble.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed \
		   and event.button_index == MOUSE_BUTTON_RIGHT:
			_show_context_menu(bubble, msg_id, msg_user)
	)

	if animate:
		bubble.modulate.a = 0.0
		var tw = bubble.create_tween()
		tw.tween_property(bubble, "modulate:a", 1.0, 0.18)

# ─── ANUNCIO ─────────────────────────────────────────────
func _add_announcement(msg: Dictionary) -> void:
	var panel = PanelContainer.new()
	var st = StyleBoxFlat.new()
	st.bg_color = Color(0.30, 0.22, 0.0, 0.95)
	st.border_color = Color(1.0, 0.84, 0.0, 0.75)
	st.border_width_left  = 3; st.border_width_right  = 1
	st.border_width_top   = 1; st.border_width_bottom = 1
	st.corner_radius_top_left    = 8; st.corner_radius_top_right    = 8
	st.corner_radius_bottom_left = 8; st.corner_radius_bottom_right = 8
	panel.add_theme_stylebox_override("panel", st)
	_msg_vbox.add_child(panel)

	var m = MarginContainer.new()
	m.add_theme_constant_override("margin_left",   16)
	m.add_theme_constant_override("margin_right",  16)
	m.add_theme_constant_override("margin_top",     9)
	m.add_theme_constant_override("margin_bottom",  9)
	panel.add_child(m)

	var lbl = Label.new()
	lbl.text = "🔔 " + msg.get("content", msg.get("text", ""))
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.93, 0.55))
	m.add_child(lbl)


# ─── LIMPIAR CHAT LOCAL ──────────────────────────────────
func _clear_local() -> void:
	for c in _msg_vbox.get_children():
		c.queue_free()
	message_nodes.clear()
	_sender_color_cache.clear()


func _add_system_msg(text: String) -> void:
	var lbl = Label.new()
	lbl.text = text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	_msg_vbox.add_child(lbl)
	_scroll_to_bottom()

# ─── BORRAR BURBUJA ─────────────────────────────────────
func _delete_message_bubble(msg_id: int) -> void:
	for entry in message_nodes:
		if entry["id"] == msg_id:
			var node = entry["node"] as Control
			if is_instance_valid(node):
				for child in node.get_children():
					if child is PanelContainer:
						var st = StyleBoxFlat.new()
						st.bg_color = Color(0.22, 0.06, 0.06, 0.7)
						st.corner_radius_top_left    = 10; st.corner_radius_top_right    = 10
						st.corner_radius_bottom_left = 10; st.corner_radius_bottom_right = 10
						child.add_theme_stylebox_override("panel", st)
			break

# ─── MENÚ CONTEXTUAL ────────────────────────────────────
func _show_context_menu(anchor: Control, msg_id: int, msg_user_id: String) -> void:
	var popup = PopupMenu.new()
	popup.add_item("🚩 Reportar mensaje", 0)
	var role = PlayerData.role if "role" in PlayerData else 1
	if role >= 3:
		popup.add_separator()
		popup.add_item("🗑️ Borrar mensaje (Mod)", 1)
	anchor.add_child(popup)
	popup.popup(Rect2(anchor.global_position, Vector2.ZERO))
	popup.id_pressed.connect(func(id):
		match id:
			0: _show_report_dialog(msg_id)
			1: _mod_delete_message(msg_id)
		popup.queue_free()
	)

func _show_report_dialog(msg_id: int) -> void:
	var dialog = AcceptDialog.new()
	dialog.title = "Reportar mensaje"
	dialog.dialog_text = "¿Por qué reportas este mensaje?"
	var vbox = VBoxContainer.new()
	dialog.add_child(vbox)
	var reasons = ["spam", "toxicidad", "trampa", "acoso", "otro"]
	var opt = OptionButton.new()
	for r in reasons: opt.add_item(r)
	vbox.add_child(opt)
	get_tree().root.add_child(dialog)
	dialog.popup_centered()
	dialog.confirmed.connect(func():
		_send_report(msg_id, reasons[opt.selected])
		dialog.queue_free()
	)

func _send_report(msg_id: int, reason: String) -> void:
	var http = HTTPRequest.new()
	add_child(http)
	var headers = ["Content-Type: application/json", "Authorization: Bearer " + PlayerData.token]
	http.request(NetworkManager.BASE_URL + "/api/chat/report",
		headers, HTTPClient.METHOD_POST, JSON.stringify({ "message_id": msg_id, "reason": reason }))
	http.request_completed.connect(func(_r, _c, _h, _b): http.queue_free())

func _mod_delete_message(msg_id: int) -> void:
	var http = HTTPRequest.new()
	add_child(http)
	http.request(NetworkManager.BASE_URL + "/api/mod/message/" + str(msg_id),
		["Authorization: Bearer " + PlayerData.token], HTTPClient.METHOD_DELETE)
	http.request_completed.connect(func(_r, _c, _h, _b): http.queue_free())

# ─── MUTE ────────────────────────────────────────────────
func _show_mute_banner() -> void:
	if not _mute_banner: return
	_mute_banner.visible = true
	_input.editable = false
	_send_btn.disabled = true
	var lbl = _mute_banner.get_node_or_null("MuteLbl")
	if lbl and _muted_until:
		lbl.text = "🔇 Silenciado hasta %s" % _muted_until.substr(11, 5)

func _hide_mute_banner() -> void:
	if _mute_banner: _mute_banner.visible = false
	if _input: _input.editable = true
	if _send_btn: _send_btn.disabled = false

# ─── MENCIÓN ─────────────────────────────────────────────
func _show_mention_notification(_data: Dictionary) -> void:
	if not _input: return
	var tw = _input.create_tween()
	tw.tween_property(_input, "modulate", Color(1.0, 1.0, 0.3, 1.0), 0.15)
	tw.tween_property(_input, "modulate", Color.WHITE, 0.8)

# ─── SCROLL ──────────────────────────────────────────────
func _scroll_to_bottom() -> void:
	if not _scroll: return
	await get_tree().process_frame
	_scroll.scroll_vertical = _scroll.get_v_scroll_bar().max_value

# ─── PROCESS ─────────────────────────────────────────────
func _process(delta: float) -> void:
	if _slow_timer > 0:
		_slow_timer -= delta
		if _slow_lbl:
			_slow_lbl.visible = true
			_slow_lbl.text = "⏱ %ds" % ceili(_slow_timer)
		if _slow_timer <= 0:
			_slow_timer = 0
			if _slow_lbl: _slow_lbl.visible = false
