extends Node

# ============================================================
# ChatScreen.gd — Rediseño visual completo
#   • Estilo dorado refinado con glassmorphism sutil
#   • Avatares con iniciales en burbujas
#   • Animaciones suaves de entrada
#   • Indicador "está escribiendo..."
#   • Panel de usuarios con cards mejoradas
#   • Header y tabs pulidos
#   • Input bar con efecto de foco elegante
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
const ROLE_ORDER = { 6: 0, 5: 1, 4: 2, 3: 3, 2: 4, 1: 5, 0: 6 }

const MAX_MESSAGES   = 100
const CHANNEL_GLOBAL = "global"
const CHANNEL_VIP    = "vip"
const CHANNEL_STAFF  = "staff"

# Paleta de colores para avatares (se asigna por hash del username)
const AVATAR_COLORS = [
	Color(0.85, 0.65, 0.10),  # dorado
	Color(0.20, 0.60, 0.85),  # azul
	Color(0.55, 0.25, 0.75),  # morado
	Color(0.20, 0.70, 0.45),  # verde
	Color(0.85, 0.35, 0.20),  # naranja
	Color(0.70, 0.20, 0.35),  # rojo
	Color(0.20, 0.65, 0.70),  # teal
	Color(0.75, 0.50, 0.15),  # ámbar
]

var current_channel  = CHANNEL_GLOBAL
var message_nodes    = []
var online_users     = []
var _muted_until     = null
var _slow_timer      = 0.0
var _slow_interval   = 0
var _typing_users    = {}   # username → timestamp
var _typing_timer    = 0.0

# Nodos
var _scroll:          ScrollContainer
var _msg_vbox:        VBoxContainer
var _input:           LineEdit
var _send_btn:        Button
var _online_lbl:      Label
var _channel_tabs:    HBoxContainer
var _mute_banner:     Panel
var _slow_lbl:        Label
var _users_vbox:      VBoxContainer
var _users_count_lbl: Label
var _typing_lbl:      Label

# ─── ENTRY POINT ─────────────────────────────────────────
static func build(container: Control, menu) -> void:
	var screen = load("res://scenes/main_menu/screens/ChatScreen.gd").new()
	screen.name = "ChatScreenNode"
	container.add_child(screen)
	screen._setup(container, menu)

func _setup(container: Control, menu) -> void:
	_my_bubble_color_idx = clamp(int(PlayerData.bubble_color_idx), 0, BUBBLE_COLORS.size() - 1)

	# ── Fondo con gradiente sutil ──────────────────────────
	var bg = ColorRect.new()
	bg.color = Color(0.03, 0.04, 0.06, 1.0)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(bg)

	# Acento decorativo superior dorado
	var top_glow = ColorRect.new()
	top_glow.color = Color(0.85, 0.65, 0.10, 0.04)
	top_glow.set_anchors_preset(Control.PRESET_FULL_RECT)
	top_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(top_glow)

	var root_margin = MarginContainer.new()
	root_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_margin.offset_top = 0
	root_margin.add_theme_constant_override("margin_left",   0)
	root_margin.add_theme_constant_override("margin_right",  0)
	root_margin.add_theme_constant_override("margin_top",    0)
	root_margin.add_theme_constant_override("margin_bottom", 0)
	container.add_child(root_margin)

	var split = HBoxContainer.new()
	split.set_anchors_preset(Control.PRESET_FULL_RECT)
	split.add_theme_constant_override("separation", 0)
	root_margin.add_child(split)

	# Panel izquierdo
	var left_panel = _build_left_panel(menu)
	left_panel.custom_minimum_size   = Vector2(230, 0)
	left_panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	split.add_child(left_panel)

	# Separador dorado con gradiente visual
	var divider = ColorRect.new()
	divider.color = Color(0.85, 0.65, 0.10, 0.20)
	divider.custom_minimum_size = Vector2(1, 0)
	divider.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.add_child(divider)

	# Panel derecho
	var right_panel = _build_right_panel(menu)
	right_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	split.add_child(right_panel)

	_request_history()


# ═══════════════════════════════════════════════════════════
# PANEL IZQUIERDO — usuarios conectados
# ═══════════════════════════════════════════════════════════
func _build_left_panel(menu) -> Control:
	var panel = PanelContainer.new()
	var st = StyleBoxFlat.new()
	st.bg_color = Color(0.04, 0.05, 0.08, 1.0)
	panel.add_theme_stylebox_override("panel", st)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 0)
	panel.add_child(vbox)

	# ── Cabecera izquierda refinada ──
	var header = _make_panel_header(menu, "👥  EN LÍNEA")
	vbox.add_child(header)

	# Contador con badge estilo pill
	var count_m = MarginContainer.new()
	count_m.add_theme_constant_override("margin_top",    10)
	count_m.add_theme_constant_override("margin_bottom",  6)
	count_m.add_theme_constant_override("margin_left",   12)
	count_m.add_theme_constant_override("margin_right",  12)
	vbox.add_child(count_m)

	var count_pill = PanelContainer.new()
	var pill_st = StyleBoxFlat.new()
	pill_st.bg_color = Color(0.85, 0.65, 0.10, 0.12)
	pill_st.border_color = Color(0.85, 0.65, 0.10, 0.25)
	pill_st.border_width_left=1; pill_st.border_width_right=1
	pill_st.border_width_top=1;  pill_st.border_width_bottom=1
	pill_st.corner_radius_top_left=20; pill_st.corner_radius_top_right=20
	pill_st.corner_radius_bottom_left=20; pill_st.corner_radius_bottom_right=20
	count_pill.add_theme_stylebox_override("panel", pill_st)
	count_m.add_child(count_pill)

	_users_count_lbl = Label.new()
	_users_count_lbl.text = "0 conectados"
	_users_count_lbl.add_theme_font_size_override("font_size", 10)
	_users_count_lbl.add_theme_color_override("font_color", Color(0.85, 0.65, 0.10, 0.9))
	_users_count_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var pill_m = MarginContainer.new()
	pill_m.add_theme_constant_override("margin_left",  10)
	pill_m.add_theme_constant_override("margin_right", 10)
	pill_m.add_theme_constant_override("margin_top",    4)
	pill_m.add_theme_constant_override("margin_bottom", 4)
	pill_m.add_child(_users_count_lbl)
	count_pill.add_child(pill_m)

	vbox.add_child(_make_separator(menu))

	# Selector de color de burbuja
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
	_users_vbox.add_theme_constant_override("separation", 3)
	var um = MarginContainer.new()
	um.add_theme_constant_override("margin_left",   8)
	um.add_theme_constant_override("margin_right",  8)
	um.add_theme_constant_override("margin_top",    8)
	um.add_theme_constant_override("margin_bottom", 8)
	um.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	um.add_child(_users_vbox)
	scroll.add_child(um)

	return panel


func _build_color_picker_section(menu) -> Control:
	var container = VBoxContainer.new()
	container.add_theme_constant_override("separation", 6)

	var title = Label.new()
	title.text = "🎨  MI BURBUJA"
	title.add_theme_font_size_override("font_size", 10)
	title.add_theme_color_override("font_color", Color(0.85, 0.65, 0.10, 0.7))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var tm = MarginContainer.new()
	tm.add_theme_constant_override("margin_top",    10)
	tm.add_theme_constant_override("margin_bottom",  4)
	tm.add_child(title)
	container.add_child(tm)

	var grid = GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	var gm = MarginContainer.new()
	gm.add_theme_constant_override("margin_left",   14)
	gm.add_theme_constant_override("margin_right",  14)
	gm.add_theme_constant_override("margin_bottom", 10)
	gm.add_child(grid)
	container.add_child(gm)

	var current_idx = clamp(int(PlayerData.bubble_color_idx), 0, BUBBLE_COLORS.size() - 1)
	var color_btns = []

	for i in range(BUBBLE_COLORS.size()):
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(38, 30)
		btn.tooltip_text = BUBBLE_COLOR_NAMES[i]

		var col = BUBBLE_COLORS[i]
		var is_selected = (i == current_idx)

		var bst = StyleBoxFlat.new()
		bst.bg_color = col.lightened(0.1)
		bst.corner_radius_top_left     = 6
		bst.corner_radius_top_right    = 6
		bst.corner_radius_bottom_left  = 6
		bst.corner_radius_bottom_right = 6
		if is_selected:
			bst.border_color = Color(1.0, 0.90, 0.40, 1.0)
			bst.border_width_left=2; bst.border_width_right=2
			bst.border_width_top=2;  bst.border_width_bottom=2
			bst.shadow_color = Color(1.0, 0.85, 0.20, 0.4)
			bst.shadow_size  = 6
		else:
			bst.border_color = Color(1,1,1,0.12)
			bst.border_width_left=1; bst.border_width_right=1
			bst.border_width_top=1;  bst.border_width_bottom=1

		btn.add_theme_stylebox_override("normal",  bst)
		btn.add_theme_stylebox_override("hover",   bst)
		btn.add_theme_stylebox_override("pressed", bst)

		if is_selected:
			btn.text = "✓"
			btn.add_theme_color_override("font_color", Color.WHITE)
			btn.add_theme_font_size_override("font_size", 13)

		var idx_capture  = i
		var all_btns_ref = color_btns
		btn.pressed.connect(func():
			_set_my_bubble_color(idx_capture)
			for j in range(all_btns_ref.size()):
				var b = all_btns_ref[j]
				if not is_instance_valid(b): continue
				var s = StyleBoxFlat.new()
				s.bg_color = BUBBLE_COLORS[j].lightened(0.1)
				s.corner_radius_top_left=6; s.corner_radius_top_right=6
				s.corner_radius_bottom_left=6; s.corner_radius_bottom_right=6
				if j == idx_capture:
					s.border_color = Color(1.0, 0.90, 0.40, 1.0)
					s.border_width_left=2; s.border_width_right=2
					s.border_width_top=2;  s.border_width_bottom=2
					s.shadow_color = Color(1.0, 0.85, 0.20, 0.4)
					s.shadow_size  = 6
				else:
					s.border_color = Color(1,1,1,0.12)
					s.border_width_left=1; s.border_width_right=1
					s.border_width_top=1;  s.border_width_bottom=1
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
	header.custom_minimum_size = Vector2(0, 50)
	var hs = StyleBoxFlat.new()
	hs.bg_color = Color(0.06, 0.07, 0.11, 1.0)
	hs.border_color = Color(0.85, 0.65, 0.10, 0.35)
	hs.border_width_bottom = 2
	header.add_theme_stylebox_override("panel", hs)

	var hbox = HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.add_theme_constant_override("separation", 0)
	header.add_child(hbox)

	# Acento lateral dorado
	var accent = ColorRect.new()
	accent.color = Color(0.85, 0.65, 0.10, 1.0)
	accent.custom_minimum_size = Vector2(3, 0)
	accent.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hbox.add_child(accent)

	var lbl = Label.new()
	lbl.text = title
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.add_theme_color_override("font_color", Color(0.95, 0.80, 0.35))
	hbox.add_child(lbl)

	return header


func _make_separator(menu) -> Control:
	var sep = ColorRect.new()
	sep.color = Color(0.85, 0.65, 0.10, 0.08)
	sep.custom_minimum_size = Vector2(0, 1)
	return sep


func _rebuild_users_list(menu) -> void:
	if not _users_vbox: return
	for c in _users_vbox.get_children(): c.queue_free()

	var sorted = online_users.duplicate()
	sorted.sort_custom(func(a, b):
		return ROLE_ORDER.get(a.get("role", 1), 5) < ROLE_ORDER.get(b.get("role", 1), 5)
	)

	var last_role_group = -1
	for u in sorted:
		var role = int(u.get("role", 1))

		if role != last_role_group:
			last_role_group = role
			var group_lbl = Label.new()
			var safe_role = int(role) # Aseguramos que sea entero sí o sí
			var badge = ROLE_BADGES.get(safe_role, "")
			
			group_lbl.text = (badge + "  " if badge != "" else "") + ROLE_NAMES.get(safe_role, "").to_upper()
			group_lbl.add_theme_font_size_override("font_size", 9)
			
			# Obtenemos el color de forma segura y le aplicamos 55% de opacidad
			var base_color = ROLE_COLORS.get(safe_role, Color.WHITE)
			group_lbl.add_theme_color_override("font_color", Color(base_color, 0.55))
			
			var gm = MarginContainer.new()
			gm.add_theme_constant_override("margin_left",  8)
			gm.add_theme_constant_override("margin_top",  10)
			gm.add_theme_constant_override("margin_bottom", 3)
			gm.add_child(group_lbl)
			_users_vbox.add_child(gm)

		var row = _make_user_row(u, menu)
		row.modulate.a = 0.0
		_users_vbox.add_child(row)
		# Animación de entrada escalonada
		var tw = row.create_tween()
		tw.tween_property(row, "modulate:a", 1.0, 0.20)

	if _users_count_lbl:
		var dot = "●  "
		_users_count_lbl.text = dot + "%d conectado%s" % [
			sorted.size(), "s" if sorted.size() != 1 else ""
		]


func _make_user_row(u: Dictionary, menu) -> Control:
	var role  = u.get("role", 1)
	var uname = u.get("username", "?")
	var is_me = u.get("user_id", "") == PlayerData.player_id

	var row = PanelContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var row_st = StyleBoxFlat.new()
	row_st.bg_color = Color(0, 0, 0, 0)
	row_st.corner_radius_top_left=8; row_st.corner_radius_top_right=8
	row_st.corner_radius_bottom_left=8; row_st.corner_radius_bottom_right=8
	row.add_theme_stylebox_override("panel", row_st)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	var rm = MarginContainer.new()
	rm.add_theme_constant_override("margin_left",   6)
	rm.add_theme_constant_override("margin_right",  6)
	rm.add_theme_constant_override("margin_top",    5)
	rm.add_theme_constant_override("margin_bottom", 5)
	rm.add_child(hbox)
	row.add_child(rm)

	# Mini avatar con inicial
	var avatar = _make_mini_avatar(uname, role)
	hbox.add_child(avatar)

	# Nombre
	var name_lbl = Label.new()
	name_lbl.text = uname + (" ✦" if is_me else "")
	name_lbl.add_theme_font_size_override("font_size", 12)
	name_lbl.add_theme_color_override("font_color",
		Color(0.95, 0.80, 0.35) if is_me else ROLE_COLORS.get(role, Color.WHITE).lightened(0.1))
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.clip_text = true
	hbox.add_child(name_lbl)

	# Badge de rol (solo para roles especiales)
	var badge_txt = ROLE_BADGES.get(role, "")
	if badge_txt != "":
		var badge_lbl = Label.new()
		badge_lbl.text = badge_txt
		badge_lbl.add_theme_font_size_override("font_size", 10)
		hbox.add_child(badge_lbl)

	return row


func _make_mini_avatar(username: String, role: int) -> Control:
	var container = Control.new()
	container.custom_minimum_size = Vector2(28, 28)

	var circle = ColorRect.new()
	circle.color = _get_avatar_color(username)
	circle.set_anchors_preset(Control.PRESET_FULL_RECT)
	# Hacemos círculo con Panel
	var av_panel = PanelContainer.new()
	av_panel.custom_minimum_size = Vector2(28, 28)
	var av_st = StyleBoxFlat.new()
	av_st.bg_color = _get_avatar_color(username)
	av_st.corner_radius_top_left=14; av_st.corner_radius_top_right=14
	av_st.corner_radius_bottom_left=14; av_st.corner_radius_bottom_right=14
	if role >= 2:
		av_st.border_color = ROLE_COLORS.get(role, Color.WHITE)
		av_st.border_width_left=2; av_st.border_width_right=2
		av_st.border_width_top=2;  av_st.border_width_bottom=2
	av_panel.add_theme_stylebox_override("panel", av_st)

	var initial_lbl = Label.new()
	initial_lbl.text = username.substr(0, 1).to_upper() if username.length() > 0 else "?"
	initial_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	initial_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	initial_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	initial_lbl.add_theme_font_size_override("font_size", 12)
	initial_lbl.add_theme_color_override("font_color", Color.WHITE)
	av_panel.add_child(initial_lbl)

	return av_panel


func _get_avatar_color(username: String) -> Color:
	var hash_val = 0
	for c in username:
		hash_val = (hash_val * 31 + c.unicode_at(0)) % AVATAR_COLORS.size()
	return AVATAR_COLORS[hash_val]


# ═══════════════════════════════════════════════════════════
# PANEL DERECHO
# ═══════════════════════════════════════════════════════════
func _build_right_panel(menu) -> Control:
	var panel = PanelContainer.new()
	var st = StyleBoxFlat.new()
	st.bg_color = Color(0.04, 0.05, 0.07, 1.0)
	panel.add_theme_stylebox_override("panel", st)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 0)
	panel.add_child(vbox)

	var header = _build_chat_header(menu)
	vbox.add_child(header)

	# ── Banner de silencio ──
	_mute_banner = Panel.new()
	_mute_banner.custom_minimum_size = Vector2(0, 34)
	_mute_banner.visible = false
	var mb_st = StyleBoxFlat.new()
	mb_st.bg_color = Color(0.40, 0.06, 0.06, 0.95)
	mb_st.border_color = Color(0.85, 0.20, 0.20, 0.5)
	mb_st.border_width_bottom = 1
	_mute_banner.add_theme_stylebox_override("panel", mb_st)
	var mb_lbl = Label.new()
	mb_lbl.name = "MuteLbl"
	mb_lbl.text = "🔇  Estás silenciado"
	mb_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	mb_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mb_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	mb_lbl.add_theme_font_size_override("font_size", 12)
	mb_lbl.add_theme_color_override("font_color", Color(1.0, 0.7, 0.7))
	_mute_banner.add_child(mb_lbl)
	vbox.add_child(_mute_banner)

	# ── Área de mensajes ──
	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	UITheme.apply_scrollbar_theme(_scroll)
	vbox.add_child(_scroll)

	var msg_margin = MarginContainer.new()
	msg_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	msg_margin.add_theme_constant_override("margin_left",   20)
	msg_margin.add_theme_constant_override("margin_right",  20)
	msg_margin.add_theme_constant_override("margin_top",    14)
	msg_margin.add_theme_constant_override("margin_bottom",  8)
	_scroll.add_child(msg_margin)

	_msg_vbox = VBoxContainer.new()
	_msg_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_msg_vbox.add_theme_constant_override("separation", 8)
	msg_margin.add_child(_msg_vbox)

	# ── Indicador "está escribiendo" ──
	var typing_bar = MarginContainer.new()
	typing_bar.add_theme_constant_override("margin_left",  24)
	typing_bar.add_theme_constant_override("margin_bottom", 2)
	typing_bar.add_theme_constant_override("margin_top",    2)
	vbox.add_child(typing_bar)

	_typing_lbl = Label.new()
	_typing_lbl.text = ""
	_typing_lbl.add_theme_font_size_override("font_size", 11)
	_typing_lbl.add_theme_color_override("font_color", Color(0.85, 0.65, 0.10, 0.65))
	_typing_lbl.visible = false
	typing_bar.add_child(_typing_lbl)

	# ── Input bar ──
	var input_area = _build_input_area(menu)
	vbox.add_child(input_area)

	return panel


func _build_chat_header(menu) -> Control:
	var header = Panel.new()
	header.custom_minimum_size = Vector2(0, 56)
	var hs = StyleBoxFlat.new()
	hs.bg_color = Color(0.05, 0.06, 0.10, 1.0)
	hs.border_color = Color(0.85, 0.65, 0.10, 0.30)
	hs.border_width_bottom = 2
	header.add_theme_stylebox_override("panel", hs)

	var hbox = HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.add_theme_constant_override("separation", 14)
	header.add_child(hbox)

	# Acento lateral
	var accent = ColorRect.new()
	accent.color = Color(0.85, 0.65, 0.10, 1.0)
	accent.custom_minimum_size = Vector2(3, 0)
	accent.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hbox.add_child(accent)

	var left_m = MarginContainer.new()
	left_m.add_theme_constant_override("margin_left", 12)
	hbox.add_child(left_m)

	var title_lbl = Label.new()
	title_lbl.text = "💬  CHAT"
	title_lbl.add_theme_font_size_override("font_size", 16)
	title_lbl.add_theme_color_override("font_color", Color(0.95, 0.80, 0.35))
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

	# Online pill
	var online_pill = PanelContainer.new()
	var op_st = StyleBoxFlat.new()
	op_st.bg_color = Color(0.15, 0.35, 0.15, 0.5)
	op_st.border_color = Color(0.30, 0.76, 0.30, 0.35)
	op_st.border_width_left=1; op_st.border_width_right=1
	op_st.border_width_top=1;  op_st.border_width_bottom=1
	op_st.corner_radius_top_left=12; op_st.corner_radius_top_right=12
	op_st.corner_radius_bottom_left=12; op_st.corner_radius_bottom_right=12
	online_pill.add_theme_stylebox_override("panel", op_st)
	online_pill.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	_online_lbl = Label.new()
	_online_lbl.text = "●  0 en línea"
	_online_lbl.add_theme_font_size_override("font_size", 11)
	_online_lbl.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
	var ol_m = MarginContainer.new()
	ol_m.add_theme_constant_override("margin_left",  10)
	ol_m.add_theme_constant_override("margin_right", 10)
	ol_m.add_theme_constant_override("margin_top",    5)
	ol_m.add_theme_constant_override("margin_bottom", 5)
	ol_m.add_child(_online_lbl)
	online_pill.add_child(ol_m)

	var right_m = MarginContainer.new()
	right_m.add_theme_constant_override("margin_right", 18)
	right_m.add_child(online_pill)
	hbox.add_child(right_m)

	return header


func _build_input_area(menu) -> Control:
	var container = Panel.new()
	container.custom_minimum_size = Vector2(0, 72)
	var st = StyleBoxFlat.new()
	st.bg_color = Color(0.05, 0.06, 0.10, 1.0)
	st.border_color = Color(0.85, 0.65, 0.10, 0.18)
	st.border_width_top = 1
	container.add_theme_stylebox_override("panel", st)

	var m = MarginContainer.new()
	m.add_theme_constant_override("margin_left",   18)
	m.add_theme_constant_override("margin_right",  18)
	m.add_theme_constant_override("margin_top",    14)
	m.add_theme_constant_override("margin_bottom", 14)
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	container.add_child(m)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	m.add_child(hbox)

	# Input con borde dorado al focus
	_input = LineEdit.new()
	_input.placeholder_text = "Escribe un mensaje... (Enter para enviar)"
	_input.max_length = 300
	_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var input_st = StyleBoxFlat.new()
	input_st.bg_color = Color(0.07, 0.08, 0.13, 1.0)
	input_st.border_color = Color(0.85, 0.65, 0.10, 0.22)
	input_st.border_width_left   = 1; input_st.border_width_right  = 1
	input_st.border_width_top    = 1; input_st.border_width_bottom = 1
	input_st.corner_radius_top_left     = 10
	input_st.corner_radius_top_right    = 10
	input_st.corner_radius_bottom_left  = 10
	input_st.corner_radius_bottom_right = 10
	input_st.content_margin_left   = 16
	input_st.content_margin_right  = 16
	input_st.content_margin_top    = 9
	input_st.content_margin_bottom = 9

	var input_focus_st = input_st.duplicate()
	input_focus_st.border_color = Color(0.95, 0.78, 0.25, 0.85)
	input_focus_st.shadow_color = Color(0.85, 0.65, 0.10, 0.15)
	input_focus_st.shadow_size  = 6

	_input.add_theme_stylebox_override("normal", input_st)
	_input.add_theme_stylebox_override("focus",  input_focus_st)
	_input.add_theme_font_size_override("font_size", 14)
	_input.add_theme_color_override("font_color",        Color(0.92, 0.92, 0.92))
	_input.add_theme_color_override("placeholder_color", Color(0.40, 0.40, 0.45))
	_input.text_submitted.connect(_on_send)
	# Notificar typing al escribir
	_input.text_changed.connect(func(_t): _on_typing())
	hbox.add_child(_input)

	# Slow mode label
	_slow_lbl = Label.new()
	_slow_lbl.text = ""
	_slow_lbl.add_theme_font_size_override("font_size", 11)
	_slow_lbl.add_theme_color_override("font_color", Color(1.0, 0.7, 0.2))
	_slow_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_slow_lbl.visible = false
	hbox.add_child(_slow_lbl)

	# Botón enviar refinado
	_send_btn = Button.new()
	_send_btn.text = "Enviar  ▶"
	_send_btn.custom_minimum_size = Vector2(100, 0)

	var sb_st = StyleBoxFlat.new()
	sb_st.bg_color = Color(0.55, 0.40, 0.05, 1.0)
	sb_st.border_color = Color(0.95, 0.78, 0.25, 0.6)
	sb_st.border_width_left   = 1; sb_st.border_width_right  = 1
	sb_st.border_width_top    = 1; sb_st.border_width_bottom = 1
	sb_st.corner_radius_top_left     = 10
	sb_st.corner_radius_top_right    = 10
	sb_st.corner_radius_bottom_left  = 10
	sb_st.corner_radius_bottom_right = 10
	sb_st.shadow_color = Color(0.85, 0.65, 0.10, 0.25)
	sb_st.shadow_size  = 4

	var sb_hover = sb_st.duplicate()
	sb_hover.bg_color   = Color(0.70, 0.52, 0.08, 1.0)
	sb_hover.shadow_size = 8
	sb_hover.shadow_color = Color(0.85, 0.65, 0.10, 0.40)

	_send_btn.add_theme_stylebox_override("normal",  sb_st)
	_send_btn.add_theme_stylebox_override("hover",   sb_hover)
	_send_btn.add_theme_stylebox_override("pressed", sb_st)
	_send_btn.add_theme_color_override("font_color", Color(0.98, 0.90, 0.50))
	_send_btn.add_theme_font_size_override("font_size", 13)
	_send_btn.pressed.connect(func(): _on_send(_input.text); _input.grab_focus())
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
		btn.custom_minimum_size = Vector2(72, 28)
		btn.toggle_mode = true
		btn.button_pressed = (ch == current_channel)

		var st_n = StyleBoxFlat.new()
		st_n.bg_color = Color(0.08, 0.10, 0.15, 0.8)
		st_n.border_color = Color(0.85, 0.65, 0.10, 0.15)
		st_n.border_width_left=1; st_n.border_width_right=1
		st_n.border_width_top=1;  st_n.border_width_bottom=1
		st_n.corner_radius_top_left    = 7; st_n.corner_radius_top_right    = 7
		st_n.corner_radius_bottom_left = 7; st_n.corner_radius_bottom_right = 7

		var st_p = StyleBoxFlat.new()
		st_p.bg_color = Color(0.55, 0.40, 0.05, 0.7)
		st_p.border_color = Color(0.95, 0.78, 0.25, 0.7)
		st_p.border_width_left=1; st_p.border_width_right=1
		st_p.border_width_top=1;  st_p.border_width_bottom=2
		st_p.corner_radius_top_left    = 7; st_p.corner_radius_top_right    = 7
		st_p.corner_radius_bottom_left = 7; st_p.corner_radius_bottom_right = 7
		st_p.shadow_color = Color(0.85, 0.65, 0.10, 0.20)
		st_p.shadow_size  = 4

		btn.add_theme_stylebox_override("normal",  st_n)
		btn.add_theme_stylebox_override("hover",   st_p)
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
	_input.grab_focus()


# ─── WS ──────────────────────────────────────────────────
func _request_history() -> void:
	NetworkManager.send_ws({
		"type":    "CHAT_HISTORY",
		"payload": { "channel": current_channel, "limit": 50 }
	})
	NetworkManager.send_ws({
		"type":    "CHAT_GET_ONLINE_USERS",
		"payload": { "channel": current_channel }
	})

func _on_typing() -> void:
	NetworkManager.send_ws({
		"type":    "CHAT_TYPING",
		"payload": { "channel": current_channel }
	})

func _on_send(text: String) -> void:
	text = text.strip_edges()
	if text.is_empty(): return

	if text.to_lower() == "/clear":
		_clear_local()
		_input.text = ""
		_input.grab_focus()

		return

	if text.to_lower() == "/clearall":
		var role = PlayerData.role if "role" in PlayerData else 1
		if role < 3:
			_add_system_msg("⛔  Sin permiso. /clearall requiere rol Mod o superior.")
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
			var sender_id  = m.get("user_id", "")
			var sender_col = m.get("bubble_color_idx", -1)
			if sender_id != "" and sender_col >= 0:
				_sender_color_cache[sender_id] = sender_col
			# Limpiar typing de este usuario
			_typing_users.erase(m.get("username", ""))
			_update_typing_label()
			_add_message_bubble(m, true)
			_scroll_to_bottom()

		"CHAT_TYPING":
			var uname = data.get("username", "")
			if uname != "" and uname != PlayerData.username:
				_typing_users[uname] = Time.get_ticks_msec()
				_update_typing_label()

		"CHAT_ANNOUNCEMENT":
			_add_announcement(data.get("message", {}))
			_scroll_to_bottom()

		"CHAT_DELETED":
			_delete_message_bubble(data.get("message_id", -1))

		"CHAT_CLEARALL":
			_clear_local()
			_add_system_msg("🧹  Chat limpiado por un moderador.")

		"CHAT_MUTED":
			_muted_until = data.get("muted_until", "")
			_show_mute_banner()

		"CHAT_MENTION":
			_show_mention_notification(data)

		"CHAT_ONLINE_COUNT":
			var count = data.get("count", 0)
			if _online_lbl:
				_online_lbl.text = "●  %d en línea" % count

		"CHAT_ONLINE_USERS":
			online_users = data.get("users", [])
			_rebuild_users_list(_get_menu())


func _update_typing_label() -> void:
	if not _typing_lbl: return
	var now = Time.get_ticks_msec()
	# Limpiar usuarios que dejaron de escribir (>3s)
	var to_remove = []
	for uname in _typing_users:
		if now - _typing_users[uname] > 3000:
			to_remove.append(uname)
	for u in to_remove:
		_typing_users.erase(u)

	var names = _typing_users.keys()
	if names.is_empty():
		_typing_lbl.visible = false
		_typing_lbl.text = ""
	else:
		_typing_lbl.visible = true
		if names.size() == 1:
			_typing_lbl.text = "✦  %s está escribiendo..." % names[0]
		elif names.size() == 2:
			_typing_lbl.text = "✦  %s y %s están escribiendo..." % [names[0], names[1]]
		else:
			_typing_lbl.text = "✦  Varias personas están escribiendo..."


func _get_menu():
	var nodes = get_tree().get_nodes_in_group("main_menu")
	return nodes[0] if nodes.size() > 0 else null


# ─── COLOR DE BURBUJA PROPIA ─────────────────────────────
const BUBBLE_COLORS = [
	Color(0.08, 0.20, 0.38, 0.95),
	Color(0.18, 0.38, 0.18, 0.95),
	Color(0.38, 0.10, 0.38, 0.95),
	Color(0.38, 0.18, 0.05, 0.95),
	Color(0.08, 0.30, 0.35, 0.95),
	Color(0.35, 0.05, 0.08, 0.95),
	Color(0.28, 0.24, 0.05, 0.95),
	Color(0.15, 0.15, 0.22, 0.95),
]
const BUBBLE_COLOR_NAMES = [
	"Azul", "Verde", "Morado", "Naranja", "Teal", "Rojo", "Dorado", "Gris"
]

var _my_bubble_color_idx: int = 0
var _sender_color_cache: Dictionary = {}

func _get_my_bubble_color() -> Color:
	var idx = clamp(int(_my_bubble_color_idx), 0, BUBBLE_COLORS.size() - 1)
	return BUBBLE_COLORS[idx]

func _set_my_bubble_color(idx: int) -> void:
	idx = clamp(idx, 0, BUBBLE_COLORS.size() - 1)
	_my_bubble_color_idx = idx
	PlayerData.bubble_color_idx = idx
	PlayerData.save_bubble_color_to_server()
	for entry in message_nodes:
		var row_node = entry.get("node")
		if not is_instance_valid(row_node): continue
		var uid = entry.get("user_id", "")
		if uid != PlayerData.player_id: continue
		for child in row_node.get_children():
			if child is PanelContainer:
				var base = BUBBLE_COLORS[idx]
				var s = StyleBoxFlat.new()
				s.bg_color     = base
				s.border_color = Color(base.r*1.4, base.g*1.4, base.b*1.4, 0.5).clamp()
				s.border_width_left=1; s.border_width_right=1
				s.border_width_top=1;  s.border_width_bottom=1
				s.corner_radius_top_left=12; s.corner_radius_top_right=12
				s.corner_radius_bottom_right=3; s.corner_radius_bottom_left=12
				child.add_theme_stylebox_override("panel", s)


# ─── BURBUJA DE MENSAJE ──────────────────────────────────
func _add_message_bubble(msg: Dictionary, animate: bool) -> void:
	if _msg_vbox.get_child_count() >= MAX_MESSAGES:
		_msg_vbox.get_child(0).queue_free()
		if message_nodes.size() > 0: message_nodes.pop_front()

	var role    = msg.get("role", 1)
	var uname   = msg.get("username", "?")
	var is_mine = msg.get("user_id", "") == PlayerData.player_id
	var is_del  = msg.get("is_deleted", 0) == 1

	# Fila exterior con avatar
	var row = HBoxContainer.new()
	row.name = "msg_%d" % msg.get("id", 0)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 10)
	_msg_vbox.add_child(row)
	message_nodes.append({ "id": msg.get("id", 0), "node": row, "user_id": msg.get("user_id", "") })

	var panel_w = _scroll.size.x if _scroll.size.x > 50 else 500.0
	var max_w   = panel_w * 0.62

	if is_mine:
		# Spacer a la izquierda para empujar a la derecha
		var sp = Control.new()
		sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(sp)
	else:
		# Avatar circular a la izquierda
		var av = _make_avatar(uname, role)
		av.size_flags_vertical = Control.SIZE_SHRINK_END
		row.add_child(av)

	# ── Burbuja ──
	var bubble = PanelContainer.new()
	bubble.custom_minimum_size   = Vector2(0, 0)
	bubble.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN

	var st = StyleBoxFlat.new()
	if is_mine:
		var base_col = _get_my_bubble_color()
		st.bg_color     = base_col
		st.border_color = Color(base_col.r * 1.5, base_col.g * 1.5, base_col.b * 1.5, 0.35).clamp()
		st.border_width_left = 1; st.border_width_right  = 1
		st.border_width_top  = 1; st.border_width_bottom = 1
		st.shadow_color = Color(0, 0, 0, 0.20)
		st.shadow_size  = 4
		st.corner_radius_top_left     = 14
		st.corner_radius_top_right    = 14
		st.corner_radius_bottom_right = 3
		st.corner_radius_bottom_left  = 14
	elif is_del:
		st.bg_color = Color(0.18, 0.05, 0.05, 0.75)
		st.corner_radius_top_left     = 14
		st.corner_radius_top_right    = 14
		st.corner_radius_bottom_right = 14
		st.corner_radius_bottom_left  = 3
	else:
		var rc = ROLE_COLORS.get(role, Color.WHITE)
		var sender_uid  = msg.get("user_id", "")
		var sender_cidx = msg.get("bubble_color_idx", _sender_color_cache.get(sender_uid, -1))
		if sender_cidx >= 0 and sender_cidx < BUBBLE_COLORS.size():
			var sc = BUBBLE_COLORS[sender_cidx]
			st.bg_color = Color(sc.r * 0.50, sc.g * 0.50, sc.b * 0.50, 0.90)
		else:
			st.bg_color = Color(0.08, 0.10, 0.16, 0.95)
		st.border_color      = Color(rc.r, rc.g, rc.b, 0.15)
		st.border_width_left = 2
		st.shadow_color = Color(0, 0, 0, 0.15)
		st.shadow_size  = 3
		st.corner_radius_top_left     = 14
		st.corner_radius_top_right    = 14
		st.corner_radius_bottom_right = 14
		st.corner_radius_bottom_left  = 3

	bubble.add_theme_stylebox_override("panel", st)
	row.add_child(bubble)

	if not is_mine:
		var sp = Control.new()
		sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(sp)
	else:
		# Avatar a la derecha en mensajes propios
		var av = _make_avatar(PlayerData.username, role)
		av.size_flags_vertical = Control.SIZE_SHRINK_END
		row.add_child(av)

	# ── Interior ──
	var bm = MarginContainer.new()
	bm.add_theme_constant_override("margin_left",   14)
	bm.add_theme_constant_override("margin_right",  14)
	bm.add_theme_constant_override("margin_top",     9)
	bm.add_theme_constant_override("margin_bottom",  9)
	bubble.add_child(bm)

	var bv = VBoxContainer.new()
	bv.add_theme_constant_override("separation", 4)
	bm.add_child(bv)

	# Nombre + badge (ajenos)
	if not is_mine:
		var name_row = HBoxContainer.new()
		name_row.add_theme_constant_override("separation", 5)
		bv.add_child(name_row)
		var badge = ROLE_BADGES.get(role, "")
		if badge != "":
			var bl = Label.new()
			bl.text = badge
			bl.add_theme_font_size_override("font_size", 10)
			name_row.add_child(bl)
		var nl = Label.new()
		nl.text = uname
		nl.add_theme_font_size_override("font_size", 13)
		nl.add_theme_color_override("font_color", ROLE_COLORS.get(role, Color.WHITE).lightened(0.15))
		name_row.add_child(nl)

	# Contenido
	var content_lbl = Label.new()
	content_lbl.text               = "[borrado]" if is_del else msg.get("content", "")
	content_lbl.autowrap_mode      = TextServer.AUTOWRAP_WORD
	content_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_lbl.custom_minimum_size   = Vector2(max_w - 80, 0)
	content_lbl.add_theme_font_size_override("font_size", 15)
	content_lbl.add_theme_color_override("font_color",
		Color(0.40, 0.40, 0.42) if is_del else Color(0.93, 0.93, 0.95))
	bv.add_child(content_lbl)

	# Timestamp alineado
	var ts = msg.get("created_at", "")
	if ts.length() >= 16:
		var ts_lbl = Label.new()
		ts_lbl.text = ts.substr(11, 5)
		ts_lbl.add_theme_font_size_override("font_size", 10)
		ts_lbl.add_theme_color_override("font_color", Color(0.35, 0.35, 0.38))
		ts_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT if is_mine else HORIZONTAL_ALIGNMENT_LEFT
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

	# ── Animación de entrada suave con slide ──
	if animate:
		row.modulate.a = 0.0
		var offset_start = 16.0 if is_mine else -16.0
		row.position.x   = offset_start
		var tw = row.create_tween().set_parallel(true)
		tw.tween_property(row, "modulate:a", 1.0, 0.22).set_trans(Tween.TRANS_CUBIC)
		tw.tween_property(row, "position:x", 0.0, 0.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _make_avatar(username: String, role: int) -> Control:
	var av_panel = PanelContainer.new()
	av_panel.custom_minimum_size = Vector2(34, 34)
	var av_st = StyleBoxFlat.new()
	av_st.bg_color = _get_avatar_color(username)
	av_st.corner_radius_top_left=17; av_st.corner_radius_top_right=17
	av_st.corner_radius_bottom_left=17; av_st.corner_radius_bottom_right=17
	if role >= 2:
		av_st.border_color = ROLE_COLORS.get(role, Color.WHITE)
		av_st.border_width_left=2; av_st.border_width_right=2
		av_st.border_width_top=2;  av_st.border_width_bottom=2
		av_st.shadow_color = ROLE_COLORS.get(role, Color.WHITE)
		av_st.shadow_color.a = 0.3
		av_st.shadow_size = 4
	av_panel.add_theme_stylebox_override("panel", av_st)

	var lbl = Label.new()
	lbl.text = username.substr(0, 1).to_upper() if username.length() > 0 else "?"
	lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.95))
	av_panel.add_child(lbl)

	return av_panel


# ─── ANUNCIO ─────────────────────────────────────────────
func _add_announcement(msg: Dictionary) -> void:
	var panel = PanelContainer.new()
	var st = StyleBoxFlat.new()
	st.bg_color = Color(0.28, 0.20, 0.02, 0.95)
	st.border_color = Color(0.95, 0.78, 0.15, 0.65)
	st.border_width_left  = 3; st.border_width_right  = 1
	st.border_width_top   = 1; st.border_width_bottom = 1
	st.corner_radius_top_left    = 10; st.corner_radius_top_right    = 10
	st.corner_radius_bottom_left = 10; st.corner_radius_bottom_right = 10
	st.shadow_color = Color(0.85, 0.65, 0.10, 0.20)
	st.shadow_size  = 6
	panel.add_theme_stylebox_override("panel", st)
	_msg_vbox.add_child(panel)

	var m = MarginContainer.new()
	m.add_theme_constant_override("margin_left",   18)
	m.add_theme_constant_override("margin_right",  18)
	m.add_theme_constant_override("margin_top",    10)
	m.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(m)

	var lbl = Label.new()
	lbl.text = "🔔  " + msg.get("content", msg.get("text", ""))
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.92, 0.50))
	m.add_child(lbl)

	# Animación
	panel.modulate.a = 0.0
	panel.create_tween().tween_property(panel, "modulate:a", 1.0, 0.30)


func _clear_local() -> void:
	for c in _msg_vbox.get_children(): c.queue_free()
	message_nodes.clear()
	_sender_color_cache.clear()


func _add_system_msg(text: String) -> void:
	var row = HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_msg_vbox.add_child(row)

	var sp1 = Control.new(); sp1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(sp1)

	var lbl = Label.new()
	lbl.text = text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.add_theme_color_override("font_color", Color(0.45, 0.45, 0.50))
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	row.add_child(lbl)

	var sp2 = Control.new(); sp2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(sp2)

	_scroll_to_bottom()


func _delete_message_bubble(msg_id: int) -> void:
	for entry in message_nodes:
		if entry["id"] == msg_id:
			var node = entry["node"] as Control
			if is_instance_valid(node):
				for child in node.get_children():
					if child is PanelContainer:
						var s = StyleBoxFlat.new()
						s.bg_color = Color(0.18, 0.05, 0.05, 0.75)
						s.corner_radius_top_left=14; s.corner_radius_top_right=14
						s.corner_radius_bottom_left=14; s.corner_radius_bottom_right=14
						child.add_theme_stylebox_override("panel", s)
			break


func _show_context_menu(anchor: Control, msg_id: int, msg_user_id: String) -> void:
	var popup = PopupMenu.new()
	popup.add_item("🚩  Reportar mensaje", 0)
	var role = PlayerData.role if "role" in PlayerData else 1
	if role >= 3:
		popup.add_separator()
		popup.add_item("🗑️  Borrar mensaje (Mod)", 1)
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


func _show_mute_banner() -> void:
	if not _mute_banner: return
	_mute_banner.visible = true
	_input.editable   = false
	_send_btn.disabled = true
	var lbl = _mute_banner.get_node_or_null("MuteLbl")
	if lbl and _muted_until:
		lbl.text = "🔇  Silenciado hasta %s" % _muted_until.substr(11, 5)

func _hide_mute_banner() -> void:
	if _mute_banner:   _mute_banner.visible = false
	if _input:         _input.editable      = true
	if _send_btn:      _send_btn.disabled   = false
	_input.grab_focus()  # ← aquí, cuando te desmutean


func _show_mention_notification(_data: Dictionary) -> void:
	if not _input: return
	var tw = _input.create_tween()
	tw.tween_property(_input, "modulate", Color(1.0, 0.95, 0.30, 1.0), 0.12)
	tw.tween_property(_input, "modulate", Color.WHITE, 0.60)

func _scroll_to_bottom() -> void:
	if not _scroll: return
	await get_tree().process_frame
	_input.grab_focus()
	_scroll.scroll_vertical = _scroll.get_v_scroll_bar().max_value

func _process(delta: float) -> void:
	# Slow mode countdown
	if _slow_timer > 0:
		_slow_timer -= delta
		if _slow_lbl:
			_slow_lbl.visible = true
			_slow_lbl.text = "⏱  %ds" % ceili(_slow_timer)
		if _slow_timer <= 0:
			_slow_timer = 0
			if _slow_lbl: _slow_lbl.visible = false

	# Typing indicator cleanup cada segundo
	_typing_timer += delta
	if _typing_timer >= 1.0:
		_typing_timer = 0.0
		_update_typing_label()
