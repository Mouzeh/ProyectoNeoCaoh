extends Control
class_name BattleLog

const MAX_LOG_ENTRIES = 80
const ICON_SIZE       = 16
const HEADER_H        = 34
const CHAT_H          = 82
const W_BASE          = 300
const W_EXPANDED      = 480

const C_BG       = Color(0.04, 0.06, 0.05, 0.97)
const C_HEADER   = Color(0.07, 0.12, 0.09, 1.00)
const C_BORDER   = Color(0.55, 0.45, 0.18)
const C_GOLD     = Color(0.85, 0.72, 0.30)
const C_GOLD_DIM = Color(0.55, 0.45, 0.18)

const LOG_CATEGORIES = {
	"attack":  {"icon": "⚔",  "icon_png": "attack",  "color": Color(0.95, 0.38, 0.38), "float": false},
	"ko":      {"icon": "💀", "icon_png": "ko",      "color": Color(1.00, 0.22, 0.22), "float": true },
	"damage":  {"icon": "💥", "icon_png": "damage",  "color": Color(0.98, 0.58, 0.22), "float": true },
	"prize":   {"icon": "🏆", "icon_png": "prize",   "color": Color(0.95, 0.82, 0.20), "float": true },
	"heal":    {"icon": "💚", "icon_png": "heal",    "color": Color(0.28, 0.92, 0.42), "float": false},
	"status":  {"icon": "🌀", "icon_png": "status",  "color": Color(0.72, 0.42, 0.98), "float": false},
	"flip":    {"icon": "🪙", "icon_png": "flip",    "color": Color(0.88, 0.78, 0.32), "float": true },
	"energy":  {"icon": "⚡", "icon_png": "energy",  "color": Color(0.42, 0.78, 0.98), "float": false},
	"trainer": {"icon": "🃏", "icon_png": "trainer", "color": Color(0.55, 0.88, 0.62), "float": false},
	"setup":   {"icon": "🎴", "icon_png": "setup",   "color": Color(0.78, 0.68, 0.48), "float": false},
	"turn":    {"icon": "🔄", "icon_png": "turn",    "color": Color(0.55, 0.60, 0.82), "float": false},
	"warn":    {"icon": "⚠",  "icon_png": "warn",    "color": Color(0.98, 0.82, 0.22), "float": false},
	"error":   {"icon": "✖",  "icon_png": "error",   "color": Color(0.92, 0.28, 0.28), "float": false},
	"info":    {"icon": "·",  "icon_png": "info",    "color": Color(0.68, 0.72, 0.65), "float": false},
	"chat_me": {"icon": "💬", "icon_png": "chat",    "color": Color(0.40, 0.85, 1.00), "float": false},
	"chat_opp":{"icon": "💬", "icon_png": "chat",    "color": Color(1.00, 0.65, 0.30), "float": false},
}

# BG alpha por categoría — las importantes resaltan más (mejora #5)
const CATEGORY_BG_ALPHA = {
	"ko":     0.22,
	"prize":  0.20,
	"damage": 0.18,
	"flip":   0.15,
	"attack": 0.12,
	"turn":   0.00,   # los turnos usan separador propio
	"default": 0.07,
}

signal chat_sent(text: String)

# ── Nodos ────────────────────────────────────────────────────
var _scroll:      ScrollContainer = null
var _vbox:        VBoxContainer   = null
var _expand_btn:  Button          = null
var _hide_btn:    Button          = null
var _show_tab:    Button          = null
var _counter_lbl: Label           = null
var _font_lbl:    Label           = null
var _chat_input:  LineEdit        = null
var _color_dot:   Button          = null
var _new_msgs_btn: Button         = null   # mejora #6

# ── Estado ───────────────────────────────────────────────────
var _is_expanded:     bool  = false
var _is_hidden:       bool  = false
var _base_rect:       Rect2
var _expanded_rect:   Rect2
var _font_size:       int   = 13
var _entry_count:     int   = 0
var _scroll_queued:   bool  = false
var _vp_h:            float = 600.0
var _user_scrolled_up: bool = false   # mejora #6
var _pending_new:      int  = 0       # mejora #6

# mejora #7 — filtro por categoría
var _active_filters: Dictionary = {}   # cat -> bool (true = visible)
var _filter_btns:    Dictionary = {}   # cat -> Button

const FILTER_CATS = ["attack", "ko", "damage", "prize", "heal", "status",
					  "flip", "energy", "trainer", "turn", "chat_me"]

var chat_color: Color  = Color(0.40, 0.85, 1.00)
var chat_name:  String = "Tú"

const CHAT_COLORS = [
	Color(0.40, 0.85, 1.00),
	Color(0.40, 1.00, 0.55),
	Color(1.00, 0.75, 0.30),
	Color(0.85, 0.45, 1.00),
	Color(1.00, 0.45, 0.45),
	Color(1.00, 1.00, 0.40),
	Color(1.00, 0.60, 0.85),
	Color(0.55, 0.90, 0.90),
]
var _color_idx: int = 0


# ============================================================
# SETUP
# ============================================================
func setup(W: float, H: float) -> void:
	name    = "BattleLog"
	z_index = 20
	_vp_h   = H
	var h_base = clamp(H * 0.36, 260.0, 400.0)
	var h_exp  = clamp(H * 0.80, 460.0, H - 40.0)
	_base_rect     = Rect2(12, H - h_base - 12, W_BASE,     h_base)
	_expanded_rect = Rect2(12, H - h_exp  - 12, W_EXPANDED, h_exp)
	position = _base_rect.position
	size     = _base_rect.size

	# inicializar filtros — todos activos por defecto
	for cat in FILTER_CATS:
		_active_filters[cat] = true

	_build_ui()
	call_deferred("_build_show_tab")


# ============================================================
# PESTAÑA FLOTANTE
# ============================================================
func _build_show_tab() -> void:
	if not get_parent(): return
	_show_tab        = Button.new()
	_show_tab.name   = "LogShowTab"
	_show_tab.visible = false
	_show_tab.z_index = 50
	var tab_y = _base_rect.position.y + _base_rect.size.y * 0.35
	_show_tab.position = Vector2(0, tab_y)
	_show_tab.size     = Vector2(44, 90)
	_show_tab.text     = "⚔\nL\nO\nG"
	_show_tab.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var sn = StyleBoxFlat.new()
	sn.bg_color = Color(0.06, 0.12, 0.08, 0.95); sn.border_color = C_GOLD
	sn.border_width_right = 2; sn.border_width_top = 2; sn.border_width_bottom = 2
	sn.corner_radius_top_right = 9; sn.corner_radius_bottom_right = 9
	sn.shadow_color = Color(0, 0, 0, 0.55); sn.shadow_size = 7
	_show_tab.add_theme_stylebox_override("normal", sn)
	var sh = StyleBoxFlat.new()
	sh.bg_color = Color(0.14, 0.28, 0.16, 0.98); sh.border_color = C_GOLD
	sh.border_width_right = 2; sh.border_width_top = 2; sh.border_width_bottom = 2
	sh.corner_radius_top_right = 9; sh.corner_radius_bottom_right = 9
	_show_tab.add_theme_stylebox_override("hover", sh)
	_show_tab.add_theme_color_override("font_color", C_GOLD)
	_show_tab.add_theme_font_size_override("font_size", 11)
	_show_tab.pressed.connect(_toggle_hide)
	get_parent().add_child(_show_tab)


# ============================================================
# UI PRINCIPAL
# ============================================================
func _build_ui() -> void:
	# Sombra
	var shadow = Panel.new()
	shadow.set_anchors_preset(Control.PRESET_FULL_RECT)
	shadow.offset_left = -3; shadow.offset_top = -3
	shadow.offset_right = 3; shadow.offset_bottom = 3
	var ss = StyleBoxFlat.new()
	ss.bg_color = Color(0, 0, 0, 0.50)
	ss.corner_radius_top_left = 11; ss.corner_radius_top_right = 11
	ss.corner_radius_bottom_left = 11; ss.corner_radius_bottom_right = 11
	shadow.add_theme_stylebox_override("panel", ss)
	shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shadow)

	# Fondo
	var bg = Panel.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	var bs = StyleBoxFlat.new()
	bs.bg_color = C_BG; bs.border_color = C_BORDER
	bs.border_width_left = 1; bs.border_width_right = 1
	bs.border_width_top = 1; bs.border_width_bottom = 1
	bs.corner_radius_top_left = 9; bs.corner_radius_top_right = 9
	bs.corner_radius_bottom_left = 9; bs.corner_radius_bottom_right = 9
	bg.add_theme_stylebox_override("panel", bs)
	add_child(bg)

	# Header
	var header = Panel.new()
	header.set_anchors_preset(Control.PRESET_TOP_WIDE)
	header.offset_bottom = HEADER_H
	var hs = StyleBoxFlat.new()
	hs.bg_color = C_HEADER; hs.border_color = C_BORDER; hs.border_width_bottom = 1
	hs.corner_radius_top_left = 9; hs.corner_radius_top_right = 9
	header.add_theme_stylebox_override("panel", hs)
	add_child(header)

	var accent = ColorRect.new()
	accent.color = C_GOLD; accent.mouse_filter = Control.MOUSE_FILTER_IGNORE
	accent.set_anchors_preset(Control.PRESET_TOP_WIDE)
	accent.offset_top = HEADER_H - 2; accent.offset_bottom = HEADER_H
	add_child(accent)

	var title = Label.new()
	title.text = "  ⚔  BATALLA"
	title.set_anchors_preset(Control.PRESET_TOP_LEFT)
	title.position = Vector2(0, 0); title.size = Vector2(120, HEADER_H)
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 11)
	title.add_theme_color_override("font_color", C_GOLD)
	add_child(title)

	_counter_lbl = Label.new()
	_counter_lbl.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_counter_lbl.offset_top = 0; _counter_lbl.offset_bottom = HEADER_H
	_counter_lbl.offset_left = 120; _counter_lbl.offset_right = -160
	_counter_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_counter_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_counter_lbl.add_theme_font_size_override("font_size", 9)
	_counter_lbl.add_theme_color_override("font_color", C_GOLD_DIM)
	add_child(_counter_lbl)

	# Botones del header
	const BW = 28; const BH = 24; const BY = 5; const GAP = 2; const MR = 5

	_hide_btn = _mk_btn("−", "Ocultar / mostrar log")
	_hide_btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_hide_btn.offset_right = -MR; _hide_btn.offset_left = -MR - BW
	_hide_btn.offset_top = BY; _hide_btn.offset_bottom = BY + BH
	_hide_btn.add_theme_color_override("font_color",       Color(0.80, 0.76, 0.65))
	_hide_btn.add_theme_color_override("font_hover_color", Color(1.00, 0.40, 0.40))
	_hide_btn.pressed.connect(_toggle_hide)
	add_child(_hide_btn)

	_expand_btn = _mk_btn("⛶", "Expandir log")
	_expand_btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_expand_btn.offset_right = -MR - BW - GAP; _expand_btn.offset_left = -MR - BW*2 - GAP
	_expand_btn.offset_top = BY; _expand_btn.offset_bottom = BY + BH
	_expand_btn.add_theme_color_override("font_color",       C_GOLD)
	_expand_btn.add_theme_color_override("font_hover_color", C_GOLD.lightened(0.3))
	_expand_btn.pressed.connect(_toggle_expand)
	add_child(_expand_btn)

	var copy_btn = _mk_btn("📋", "Copiar log")
	copy_btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	copy_btn.offset_right = -MR - BW*2 - GAP*2; copy_btn.offset_left = -MR - BW*3 - GAP*2
	copy_btn.offset_top = BY; copy_btn.offset_bottom = BY + BH
	copy_btn.add_theme_color_override("font_color",       Color(0.70, 0.85, 0.70))
	copy_btn.add_theme_color_override("font_hover_color", Color(0.40, 1.00, 0.50))
	copy_btn.pressed.connect(_copy_log)
	add_child(copy_btn)

	var vsep = ColorRect.new()
	vsep.color = C_GOLD_DIM; vsep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vsep.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	vsep.offset_right = -MR - BW*3 - GAP*2 - 4; vsep.offset_left = -MR - BW*3 - GAP*2 - 5
	vsep.offset_top = BY + 3; vsep.offset_bottom = BY + BH - 3
	add_child(vsep)

	_font_lbl = Label.new()
	_font_lbl.text = str(_font_size)
	_font_lbl.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_font_lbl.offset_right  = -MR - BW*3 - GAP*2 - 8
	_font_lbl.offset_left   = -MR - BW*3 - GAP*2 - 8 - 24
	_font_lbl.offset_top    = BY; _font_lbl.offset_bottom = BY + BH
	_font_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_font_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	_font_lbl.add_theme_font_size_override("font_size", 10)
	_font_lbl.add_theme_color_override("font_color", C_GOLD_DIM)
	add_child(_font_lbl)

	var fa_minus = _mk_btn("A−", "Reducir texto")
	fa_minus.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	fa_minus.offset_right  = -MR - BW*3 - GAP*2 - 8 - 24 - GAP
	fa_minus.offset_left   = -MR - BW*3 - GAP*2 - 8 - 24 - GAP - BW
	fa_minus.offset_top    = BY; fa_minus.offset_bottom = BY + BH
	fa_minus.add_theme_color_override("font_color",       Color(0.65, 0.70, 0.62))
	fa_minus.add_theme_color_override("font_hover_color", C_GOLD)
	fa_minus.pressed.connect(func(): _change_font(-1))
	add_child(fa_minus)

	var fa_plus = _mk_btn("A+", "Aumentar texto")
	fa_plus.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	fa_plus.offset_right  = -MR - BW*3 - GAP*2 - 8 - 24 - GAP*2 - BW
	fa_plus.offset_left   = -MR - BW*3 - GAP*2 - 8 - 24 - GAP*2 - BW*2
	fa_plus.offset_top    = BY; fa_plus.offset_bottom = BY + BH
	fa_plus.add_theme_color_override("font_color",       Color(0.65, 0.70, 0.62))
	fa_plus.add_theme_color_override("font_hover_color", C_GOLD)
	fa_plus.pressed.connect(func(): _change_font(1))
	add_child(fa_plus)

	# ── Scroll ───────────────────────────────────────────────
	_scroll = ScrollContainer.new()
	_scroll.name = "LogScroll"; _scroll.clip_contents = true
	_scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	_scroll.offset_top = HEADER_H + 2; _scroll.offset_bottom = -(CHAT_H + 5)
	_scroll.offset_left = 5; _scroll.offset_right = -5
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.vertical_scroll_mode   = ScrollContainer.SCROLL_MODE_AUTO
	add_child(_scroll)

	var grab = StyleBoxFlat.new()
	grab.bg_color = Color(0.45, 0.38, 0.14, 0.65)
	grab.corner_radius_top_left = 3; grab.corner_radius_top_right = 3
	grab.corner_radius_bottom_left = 3; grab.corner_radius_bottom_right = 3
	_scroll.get_v_scroll_bar().add_theme_stylebox_override("grabber",       grab)
	_scroll.get_v_scroll_bar().add_theme_stylebox_override("grabber_hover", grab)

	# detectar scroll manual del usuario (mejora #6)
	_scroll.get_v_scroll_bar().value_changed.connect(_on_scroll_changed)

	_vbox = VBoxContainer.new()
	_vbox.name = "LogEntries"
	_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_vbox.size_flags_vertical   = Control.SIZE_SHRINK_BEGIN
	_vbox.add_theme_constant_override("separation", 1)
	_scroll.add_child(_vbox)

	_build_new_msgs_btn()   # mejora #6
	_build_filter_bar()     # mejora #7
	_build_chat_zone()


# ============================================================
# MEJORA #6 — BOTÓN "N MENSAJES NUEVOS"
# ============================================================
func _build_new_msgs_btn() -> void:
	_new_msgs_btn = Button.new()
	_new_msgs_btn.visible = false
	_new_msgs_btn.z_index = 30
	_new_msgs_btn.focus_mode = Control.FOCUS_NONE
	_new_msgs_btn.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_new_msgs_btn.offset_top    = -(CHAT_H + 34)
	_new_msgs_btn.offset_bottom = -(CHAT_H + 6)
	_new_msgs_btn.offset_left   = 30
	_new_msgs_btn.offset_right  = -30
	_new_msgs_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	var sn = StyleBoxFlat.new()
	sn.bg_color    = Color(0.10, 0.20, 0.12, 0.95)
	sn.border_color = C_GOLD; sn.border_width_bottom = 1; sn.border_width_top = 1
	sn.border_width_left = 1; sn.border_width_right = 1
	sn.corner_radius_top_left = 8; sn.corner_radius_top_right = 8
	sn.corner_radius_bottom_left = 8; sn.corner_radius_bottom_right = 8
	_new_msgs_btn.add_theme_stylebox_override("normal", sn)

	var sh = StyleBoxFlat.new()
	sh.bg_color    = Color(0.18, 0.36, 0.20, 0.98)
	sh.border_color = C_GOLD; sh.border_width_bottom = 1; sh.border_width_top = 1
	sh.border_width_left = 1; sh.border_width_right = 1
	sh.corner_radius_top_left = 8; sh.corner_radius_top_right = 8
	sh.corner_radius_bottom_left = 8; sh.corner_radius_bottom_right = 8
	_new_msgs_btn.add_theme_stylebox_override("hover", sh)

	_new_msgs_btn.add_theme_color_override("font_color", C_GOLD)
	_new_msgs_btn.add_theme_font_size_override("font_size", 11)
	_new_msgs_btn.pressed.connect(_jump_to_bottom)
	add_child(_new_msgs_btn)


func _on_scroll_changed(value: float) -> void:
	var bar = _scroll.get_v_scroll_bar()
	var at_bottom = value >= bar.max_value - bar.page - 4
	if at_bottom:
		_user_scrolled_up = false
		_pending_new      = 0
		_new_msgs_btn.visible = false
	else:
		_user_scrolled_up = true


func _jump_to_bottom() -> void:
	_user_scrolled_up = false
	_pending_new      = 0
	_new_msgs_btn.visible = false
	_queue_scroll_down()


# ============================================================
# MEJORA #7 — BARRA DE FILTROS
# ============================================================
func _build_filter_bar() -> void:
	var bar = HBoxContainer.new()
	bar.name = "FilterBar"
	bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	bar.offset_top    = HEADER_H + 2
	bar.offset_bottom = HEADER_H + 22
	bar.offset_left   = 4
	bar.offset_right  = -4
	bar.add_theme_constant_override("separation", 2)
	bar.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(bar)

	# Reajustar el scroll para dejar espacio a la barra
	if _scroll:
		_scroll.offset_top = HEADER_H + 24

	const FILTER_ICONS = {
		"attack": "⚔", "ko": "💀", "damage": "💥", "prize": "🏆",
		"heal": "💚", "status": "🌀", "flip": "🪙", "energy": "⚡",
		"trainer": "🃏", "turn": "🔄", "chat_me": "💬",
	}

	for cat in FILTER_CATS:
		var icon = FILTER_ICONS.get(cat, "·")
		var btn  = Button.new()
		btn.text         = icon
		btn.flat         = true
		btn.focus_mode   = Control.FOCUS_NONE
		btn.tooltip_text = cat
		btn.custom_minimum_size = Vector2(22, 18)
		btn.add_theme_font_size_override("font_size", 11)
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

		var color = LOG_CATEGORIES.get(cat, {}).get("color", C_GOLD)
		btn.add_theme_color_override("font_color",       color)
		btn.add_theme_color_override("font_hover_color", color.lightened(0.3))

		var sn = StyleBoxFlat.new()
		sn.bg_color = Color(color.r, color.g, color.b, 0.20)
		sn.corner_radius_top_left    = 3; sn.corner_radius_top_right    = 3
		sn.corner_radius_bottom_left = 3; sn.corner_radius_bottom_right = 3
		btn.add_theme_stylebox_override("normal", sn)

		var sp = StyleBoxFlat.new()
		sp.bg_color = Color(0.10, 0.10, 0.10, 0.25)
		sp.corner_radius_top_left    = 3; sp.corner_radius_top_right    = 3
		sp.corner_radius_bottom_left = 3; sp.corner_radius_bottom_right = 3
		btn.add_theme_stylebox_override("pressed", sp)

		_filter_btns[cat] = btn
		btn.pressed.connect(func(): _toggle_filter(cat))
		bar.add_child(btn)

	# separador + botón "all"
	var sep = Label.new(); sep.text = "│"
	sep.add_theme_color_override("font_color", C_GOLD_DIM)
	sep.add_theme_font_size_override("font_size", 10)
	bar.add_child(sep)

	var all_btn = _mk_btn("✦", "Mostrar todo")
	all_btn.custom_minimum_size = Vector2(20, 18)
	all_btn.add_theme_font_size_override("font_size", 10)
	all_btn.pressed.connect(_reset_filters)
	bar.add_child(all_btn)


func _toggle_filter(cat: String) -> void:
	_active_filters[cat] = not _active_filters.get(cat, true)
	_refresh_filter_buttons()
	_apply_filters()


func _reset_filters() -> void:
	for cat in FILTER_CATS:
		_active_filters[cat] = true
	_refresh_filter_buttons()
	_apply_filters()


func _refresh_filter_buttons() -> void:
	for cat in _filter_btns:
		var btn   = _filter_btns[cat]
		var color = LOG_CATEGORIES.get(cat, {}).get("color", C_GOLD)
		var active = _active_filters.get(cat, true)
		var sn = StyleBoxFlat.new()
		sn.bg_color = Color(color.r, color.g, color.b, 0.20 if active else 0.04)
		sn.corner_radius_top_left    = 3; sn.corner_radius_top_right    = 3
		sn.corner_radius_bottom_left = 3; sn.corner_radius_bottom_right = 3
		btn.add_theme_stylebox_override("normal", sn)
		btn.modulate.a = 1.0 if active else 0.35


func _apply_filters() -> void:
	if not _vbox: return
	for entry in _vbox.get_children():
		var cat = entry.get_meta("category", "info")
		var visible_cat = cat if cat != "chat_opp" else "chat_me"
		entry.visible = _active_filters.get(visible_cat, true)


# ============================================================
# EVENTOS DE ENTRADA Y FOCO
# ============================================================
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if is_chat_focused():
			_chat_input.release_focus()
			get_viewport().set_input_as_handled()


func is_chat_focused() -> bool:
	if is_instance_valid(_chat_input):
		return _chat_input.has_focus()
	return false


# ============================================================
# ZONA DE CHAT
# ============================================================
func _build_chat_zone() -> void:
	var sep = ColorRect.new()
	sep.color = C_BORDER; sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sep.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	sep.offset_top = -(CHAT_H + 1); sep.offset_bottom = -CHAT_H
	add_child(sep)

	var chat_bg = ColorRect.new()
	chat_bg.color = Color(0.03, 0.05, 0.04, 1.0)
	chat_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chat_bg.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	chat_bg.offset_top = -CHAT_H; chat_bg.offset_bottom = 0
	add_child(chat_bg)

	var chat_lbl = Label.new()
	chat_lbl.text = "💬 Chat"
	chat_lbl.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	chat_lbl.offset_top = -(CHAT_H - 4); chat_lbl.offset_bottom = -(CHAT_H - 18)
	chat_lbl.offset_left = 8; chat_lbl.offset_right = 80
	chat_lbl.add_theme_font_size_override("font_size", 10)
	chat_lbl.add_theme_color_override("font_color", C_GOLD_DIM)
	add_child(chat_lbl)

	_color_dot = Button.new()
	_color_dot.text = "●"; _color_dot.flat = true; _color_dot.focus_mode = Control.FOCUS_NONE
	_color_dot.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_color_dot.offset_top = -(CHAT_H - 3); _color_dot.offset_bottom = -(CHAT_H - 21)
	_color_dot.offset_left = -32; _color_dot.offset_right = -4
	_color_dot.add_theme_font_size_override("font_size", 16)
	_color_dot.add_theme_color_override("font_color",       chat_color)
	_color_dot.add_theme_color_override("font_hover_color", chat_color.lightened(0.3))
	_color_dot.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_color_dot.tooltip_text = "Cambiar color del chat"
	_color_dot.pressed.connect(_cycle_chat_color)
	add_child(_color_dot)

	var hint = Label.new()
	hint.text = "● color  ·  Enter envía"
	hint.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	hint.offset_top = -(CHAT_H - 20); hint.offset_bottom = -(CHAT_H - 30)
	hint.offset_left = 8; hint.offset_right = 200
	hint.add_theme_font_size_override("font_size", 8)
	hint.add_theme_color_override("font_color", Color(0.35, 0.35, 0.30))
	add_child(hint)

	_chat_input = LineEdit.new()
	_chat_input.placeholder_text = "Escribe un mensaje..."
	_chat_input.max_length = 120
	_chat_input.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_chat_input.offset_top = -(CHAT_H - 32); _chat_input.offset_bottom = -(CHAT_H - 64)
	_chat_input.offset_left = 6; _chat_input.offset_right = -72
	var inp_s = StyleBoxFlat.new()
	inp_s.bg_color = Color(0.07, 0.11, 0.09); inp_s.border_color = C_BORDER
	inp_s.border_width_left = 1; inp_s.border_width_right = 1
	inp_s.border_width_top = 1; inp_s.border_width_bottom = 1
	inp_s.corner_radius_top_left = 5; inp_s.corner_radius_top_right = 5
	inp_s.corner_radius_bottom_left = 5; inp_s.corner_radius_bottom_right = 5
	inp_s.content_margin_left = 8; inp_s.content_margin_right = 8
	_chat_input.add_theme_stylebox_override("normal", inp_s)
	_chat_input.add_theme_stylebox_override("focus",  inp_s)
	_chat_input.add_theme_color_override("font_color",             Color(0.92, 0.88, 0.78))
	_chat_input.add_theme_color_override("font_placeholder_color", Color(0.40, 0.40, 0.36))
	_chat_input.add_theme_font_size_override("font_size", 13)
	_chat_input.text_submitted.connect(_on_chat_submitted)
	add_child(_chat_input)

	var send_btn = Button.new()
	send_btn.text = "Enviar"; send_btn.focus_mode = Control.FOCUS_NONE
	send_btn.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	send_btn.offset_top = -(CHAT_H - 32); send_btn.offset_bottom = -(CHAT_H - 64)
	send_btn.offset_left = -68; send_btn.offset_right = -4
	var sn = StyleBoxFlat.new()
	sn.bg_color = Color(0.10, 0.22, 0.14); sn.border_color = C_GOLD_DIM; sn.border_width_bottom = 1
	sn.corner_radius_top_left = 5; sn.corner_radius_top_right = 5
	sn.corner_radius_bottom_left = 5; sn.corner_radius_bottom_right = 5
	send_btn.add_theme_stylebox_override("normal", sn)
	var sh = StyleBoxFlat.new()
	sh.bg_color = Color(0.18, 0.38, 0.22); sh.border_color = C_GOLD; sh.border_width_bottom = 1
	sh.corner_radius_top_left = 5; sh.corner_radius_top_right = 5
	sh.corner_radius_bottom_left = 5; sh.corner_radius_bottom_right = 5
	send_btn.add_theme_stylebox_override("hover", sh)
	send_btn.add_theme_color_override("font_color", C_GOLD)
	send_btn.add_theme_font_size_override("font_size", 12)
	send_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	send_btn.pressed.connect(func(): _on_chat_submitted(_chat_input.text))
	add_child(send_btn)


# ============================================================
# CHAT
# ============================================================
func _on_chat_submitted(text: String) -> void:
	_chat_input.release_focus()
	text = text.strip_edges()
	if text == "": return
	_chat_input.clear()
	add_chat_message(chat_name, text, chat_color, true)
	emit_signal("chat_sent", text)


func receive_chat_message(player_name: String, text: String, color: Color = Color(1.0, 0.65, 0.30)) -> void:
	add_chat_message(player_name, text, color, false)


func add_chat_message(player_name: String, text: String, color: Color, is_mine: bool) -> void:
	if not _vbox: return
	_trim_entries()

	var cat = "chat_me" if is_mine else "chat_opp"
	var entry = _make_entry_container(Color(color.r, color.g, color.b, 0.13), color, 4)
	entry.set_meta("category", cat)
	# aplicar visibilidad según filtro activo
	entry.visible = _active_filters.get("chat_me", true)

	var hbox = entry.get_child(0)

	var mg = Control.new(); mg.custom_minimum_size = Vector2(4, 0); hbox.add_child(mg)

	var icon_data = LOG_CATEGORIES["chat_me" if is_mine else "chat_opp"].duplicate()
	icon_data["color"] = color
	hbox.add_child(_make_icon(icon_data, color))

	var mc = _make_margin_container()
	hbox.add_child(mc)

	var inner = VBoxContainer.new()
	inner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inner.add_theme_constant_override("separation", 0)
	mc.add_child(inner)

	var name_lbl = Label.new()
	name_lbl.text = ("%s  (tú)" % player_name) if is_mine else player_name
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.add_theme_font_size_override("font_size", max(9, _font_size - 3))
	name_lbl.add_theme_color_override("font_color", color.lightened(0.1))
	inner.add_child(name_lbl)

	var msg_lbl = _make_text_label(text, color.lightened(0.25))
	msg_lbl.add_theme_color_override("font_outline_color", color.darkened(0.15))
	msg_lbl.add_theme_constant_override("outline_size", 2)
	inner.add_child(msg_lbl)

	# mejora #1 — timestamp
	inner.add_child(_make_timestamp_label())

	_vbox.add_child(entry)
	_finish_entry(entry)


# ============================================================
# LOG NORMAL
# ============================================================
func add_message(text: String) -> void:
	if not _vbox: return
	_trim_entries()

	var cat      = _detect_category(text)
	var cat_data = LOG_CATEGORIES.get(cat, LOG_CATEGORIES["info"])
	var color: Color = cat_data["color"]

	if cat_data["float"]: _show_float(text, color)

	# mejora #2 — separador de turno
	if cat == "turn":
		_vbox.add_child(_make_turn_separator(text, color))
		_entry_count += 1
		if _counter_lbl: _counter_lbl.text = str(_entry_count)
		_queue_scroll_down()
		return

	var bg_alpha = CATEGORY_BG_ALPHA.get(cat, CATEGORY_BG_ALPHA["default"])
	var entry = _make_entry_container(Color(color.r, color.g, color.b, bg_alpha), color, 3)
	entry.set_meta("category", cat)
	# aplicar visibilidad según filtros
	entry.visible = _active_filters.get(cat, true)

	var hbox = entry.get_child(0)

	var margin = Control.new(); margin.custom_minimum_size = Vector2(4, 0); hbox.add_child(margin)
	hbox.add_child(_make_icon(cat_data, color))

	var mc = _make_margin_container()
	hbox.add_child(mc)

	var inner = VBoxContainer.new()
	inner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inner.add_theme_constant_override("separation", 0)
	mc.add_child(inner)

	inner.add_child(_make_text_label(text, color.lightened(0.18)))
	# mejora #1 — timestamp
	inner.add_child(_make_timestamp_label())

	_vbox.add_child(entry)
	_finish_entry(entry)


# ============================================================
# MEJORA #1 — TIMESTAMP
# ============================================================
func _make_timestamp_label() -> Label:
	var now = Time.get_time_dict_from_system()
	var ts  = "%02d:%02d:%02d" % [now.hour, now.minute, now.second]
	var lbl = Label.new()
	lbl.text = ts
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.add_theme_font_size_override("font_size", 8)
	lbl.add_theme_color_override("font_color", Color(0.38, 0.40, 0.35, 0.70))
	return lbl


# ============================================================
# MEJORA #2 — SEPARADOR DE TURNO
# ============================================================
func _make_turn_separator(text: String, color: Color) -> Control:
	var sep_container = Control.new()
	sep_container.set_meta("category", "turn")
	sep_container.visible = _active_filters.get("turn", true)
	sep_container.custom_minimum_size = Vector2(0, 22)
	sep_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var line_l = ColorRect.new()
	line_l.color = color.darkened(0.25)
	line_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line_l.set_anchors_preset(Control.PRESET_CENTER_LEFT)
	line_l.size   = Vector2(0, 1)   # se ajusta en _ready via resized
	line_l.name   = "LineLeft"
	sep_container.add_child(line_l)

	var lbl = Label.new()
	lbl.text = " %s " % text.strip_edges()
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.add_theme_color_override("font_color", color.lightened(0.2))
	lbl.set_anchors_preset(Control.PRESET_CENTER)
	lbl.name = "TurnLabel"
	sep_container.add_child(lbl)

	var line_r = ColorRect.new()
	line_r.color = color.darkened(0.25)
	line_r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line_r.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	line_r.size = Vector2(0, 1)
	line_r.name = "LineRight"
	sep_container.add_child(line_r)

	# posicionar líneas laterales cuando el nodo tenga tamaño real
	sep_container.resized.connect(func():
		if not is_instance_valid(sep_container): return
		var lbl_node  = sep_container.find_child("TurnLabel", false, false)
		var line_left  = sep_container.find_child("LineLeft",  false, false)
		var line_right = sep_container.find_child("LineRight", false, false)
		if not (lbl_node and line_left and line_right): return
		lbl_node.size = Vector2(0, 20)
		lbl_node.position = Vector2(0, 1)
		await sep_container.get_tree().process_frame
		if not is_instance_valid(lbl_node): return
		var lbl_w  = lbl_node.size.x
		var total  = sep_container.size.x
		var pad    = 6.0
		var center = total / 2.0
		line_left.size     = Vector2(center - lbl_w / 2.0 - pad, 1)
		line_left.position = Vector2(pad, sep_container.size.y / 2.0)
		line_right.size     = Vector2(center - lbl_w / 2.0 - pad, 1)
		line_right.position = Vector2(center + lbl_w / 2.0 + pad, sep_container.size.y / 2.0)
	)

	# fade-in
	sep_container.modulate.a = 0.0
	create_tween().tween_property(sep_container, "modulate:a", 1.0, 0.25)
	return sep_container


# ============================================================
# CONSTRUCTORES DE UI REUTILIZABLES
# ============================================================
func _make_entry_container(bg_color: Color, border_color: Color, border_left: int) -> PanelContainer:
	var entry = PanelContainer.new()
	entry.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	entry.size_flags_vertical   = Control.SIZE_SHRINK_BEGIN

	var es = StyleBoxFlat.new()
	es.bg_color          = bg_color
	es.border_color      = border_color
	es.border_width_left = border_left
	es.content_margin_left   = 2
	es.content_margin_right  = 4
	es.content_margin_top    = 1
	es.content_margin_bottom = 1
	entry.add_theme_stylebox_override("panel", es)

	var hbox = HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_theme_constant_override("separation", 4)
	entry.add_child(hbox)

	# mejora #4 — hover highlight
	entry.mouse_entered.connect(func(): _on_entry_hover(entry, es, border_color, true))
	entry.mouse_exited.connect(func():  _on_entry_hover(entry, es, border_color, false))
	entry.mouse_filter = Control.MOUSE_FILTER_PASS

	return entry


func _on_entry_hover(entry: PanelContainer, style: StyleBoxFlat, border_color: Color, hovered: bool) -> void:
	if not is_instance_valid(entry): return
	var tw = create_tween()
	var target_a = style.bg_color.a * (1.8 if hovered else (1.0 / 1.8))
	target_a = clamp(target_a, 0.0, 1.0)
	tw.tween_method(
		func(v: float): style.bg_color.a = v,
		style.bg_color.a,
		target_a,
		0.10
	)


func _make_text_label(text: String, color: Color) -> Label:
	var lbl = Label.new()
	lbl.name = "TextLabel"
	lbl.text = text
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.size_flags_vertical   = Control.SIZE_SHRINK_BEGIN
	lbl.autowrap_mode         = TextServer.AUTOWRAP_WORD_SMART
	lbl.add_theme_font_size_override("font_size", _font_size)
	lbl.add_theme_color_override("font_color", color)
	return lbl


func _make_margin_container() -> MarginContainer:
	var mc = MarginContainer.new()
	mc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mc.add_theme_constant_override("margin_top",    3)
	mc.add_theme_constant_override("margin_bottom", 3)
	mc.add_theme_constant_override("margin_right",  6)
	mc.add_theme_constant_override("margin_left",   2)
	return mc


func _make_icon(cat_data: Dictionary, color: Color = Color.WHITE) -> Control:
	var png_path = "res://assets/log_icons/" + cat_data.get("icon_png", "") + ".png"
	if ResourceLoader.exists(png_path):
		var tr = TextureRect.new()
		tr.texture      = load(png_path)
		tr.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)
		tr.size                = Vector2(ICON_SIZE, ICON_SIZE)
		tr.modulate            = color
		return tr
	var el = Label.new()
	el.text = cat_data.get("icon", "·")
	el.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)
	el.size                = Vector2(ICON_SIZE, ICON_SIZE)
	el.vertical_alignment  = VERTICAL_ALIGNMENT_CENTER
	el.add_theme_font_size_override("font_size", ICON_SIZE)
	return el


func _trim_entries() -> void:
	while _vbox.get_child_count() >= MAX_LOG_ENTRIES:
		var old = _vbox.get_child(0)
		_vbox.remove_child(old)
		old.free()


func _finish_entry(entry: Control) -> void:
	_entry_count += 1
	if _counter_lbl: _counter_lbl.text = str(_entry_count)

	# mejora #3 — animación slide + fade
	entry.modulate.a = 0.0
	entry.position.x += 8.0
	var tw = create_tween().set_parallel(true)
	tw.tween_property(entry, "modulate:a",  1.0, 0.18)
	tw.tween_property(entry, "position:x",  0.0, 0.14).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	# mejora #6 — contador de nuevos mensajes
	if _user_scrolled_up:
		_pending_new += 1
		_new_msgs_btn.text    = "↓  %d nuevo%s" % [_pending_new, "s" if _pending_new > 1 else ""]
		_new_msgs_btn.visible = true
	else:
		_queue_scroll_down()


# ============================================================
# CAMBIO DE FUENTE
# ============================================================
func _change_font(delta: int) -> void:
	_font_size = clamp(_font_size + delta, 9, 22)
	if _font_lbl: _font_lbl.text = str(_font_size)

	for entry in _vbox.get_children():
		var labels = _find_all_text_labels(entry)
		for lbl in labels:
			lbl.add_theme_font_size_override("font_size", _font_size)

	await get_tree().process_frame
	if is_instance_valid(_vbox):   _vbox.queue_sort()
	if is_instance_valid(_scroll): _scroll.queue_redraw()
	_queue_scroll_down()


func _find_all_text_labels(node: Node) -> Array:
	var result: Array = []
	for child in node.get_children():
		if child is Label and child.name == "TextLabel":
			result.append(child)
		elif child.get_child_count() > 0:
			result.append_array(_find_all_text_labels(child))
	return result


# ============================================================
# HELPERS
# ============================================================
func _queue_scroll_down() -> void:
	if _scroll_queued: return
	_scroll_queued = true
	await get_tree().process_frame
	if is_instance_valid(_scroll) and _scroll.get_v_scroll_bar():
		_scroll.scroll_vertical = int(_scroll.get_v_scroll_bar().max_value)
	_scroll_queued = false


func _mk_btn(lbl: String, tip: String = "") -> Button:
	var b = Button.new()
	b.text = lbl; b.flat = true; b.focus_mode = Control.FOCUS_NONE
	b.tooltip_text = tip
	b.custom_minimum_size = Vector2(28, 24)
	b.add_theme_font_size_override("font_size", 13)
	b.add_theme_color_override("font_color",       Color(0.75, 0.72, 0.65))
	b.add_theme_color_override("font_hover_color", C_GOLD)
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	return b


func set_chat_color(color: Color) -> void:
	chat_color = color
	if _color_dot: _color_dot.add_theme_color_override("font_color", chat_color)


func set_chat_name(player_name: String) -> void:
	chat_name = player_name


func _cycle_chat_color() -> void:
	_color_idx = (_color_idx + 1) % CHAT_COLORS.size()
	set_chat_color(CHAT_COLORS[_color_idx])


func clear() -> void:
	if _vbox:
		for c in _vbox.get_children(): c.queue_free()
	_entry_count  = 0
	_pending_new  = 0
	_user_scrolled_up = false
	if _counter_lbl:   _counter_lbl.text = ""
	if _new_msgs_btn:  _new_msgs_btn.visible = false


# ============================================================
# CONTROLES UI
# ============================================================
func _toggle_hide() -> void:
	_is_hidden = !_is_hidden
	if _show_tab: _show_tab.visible = _is_hidden

	if _is_hidden:
		if _scroll: _scroll.visible = false
		_hide_btn.text      = "＋"
		_expand_btn.visible = false
		var target_h = float(HEADER_H)
		var target_y = _base_rect.position.y + _base_rect.size.y - float(HEADER_H)
		var tw = create_tween().set_parallel(true)
		tw.tween_property(self, "size:y",     target_h, 0.20).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tw.tween_property(self, "position:y", target_y, 0.20).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	else:
		_hide_btn.text      = "−"
		_expand_btn.visible = true
		var target   = _expanded_rect if _is_expanded else _base_rect
		var tw = create_tween().set_parallel(true)
		tw.tween_property(self, "size:y",     target.size.y,     0.20).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tw.tween_property(self, "position:y", target.position.y, 0.20).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tw.chain().tween_callback(func():
			if _scroll: _scroll.visible = true
			_queue_scroll_down()
		)


func _toggle_expand() -> void:
	_is_expanded = !_is_expanded
	var target = _expanded_rect if _is_expanded else _base_rect
	_expand_btn.text = "✖" if _is_expanded else "⛶"
	var tw = create_tween().set_parallel(true)
	tw.tween_property(self, "position", target.position, 0.22).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "size",     target.size,     0.22).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.chain().tween_callback(func(): _queue_scroll_down())


func _copy_log() -> void:
	if not _vbox: return
	var lines: PackedStringArray = []
	for entry in _vbox.get_children():
		var lbl = entry.find_child("TextLabel", true, false)
		if lbl and lbl.text != "": lines.append(lbl.text)
	if lines.is_empty(): return
	DisplayServer.clipboard_set("\n".join(lines))
	_show_copy_toast()


func _show_copy_toast() -> void:
	var toast = Label.new()
	toast.text = "✔ Log copiado"
	toast.set_anchors_preset(Control.PRESET_TOP_WIDE)
	toast.offset_top = HEADER_H + 2; toast.offset_bottom = HEADER_H + 22
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast.add_theme_font_size_override("font_size", 11)
	toast.add_theme_color_override("font_color", Color(0.40, 1.0, 0.50))
	toast.z_index = 30
	add_child(toast)
	var tw = create_tween()
	tw.tween_property(toast, "modulate:a", 0.0, 1.2).set_delay(0.5)
	tw.chain().tween_callback(toast.queue_free)


# ============================================================
# TEXTO FLOTANTE
# ============================================================
func _show_float(msg: String, color: Color) -> void:
	var vp    = get_viewport().get_visible_rect().size
	var short = msg if msg.length() <= 50 else msg.substr(0, 48) + "…"
	var lbl   = Label.new()
	lbl.text = short
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	lbl.size     = Vector2(vp.x * 0.60, 56)
	lbl.position = Vector2((vp.x - vp.x * 0.60) / 2.0, vp.y / 2.0 - 100 + randf_range(-20, 20))
	lbl.z_index  = 500
	lbl.add_theme_font_size_override("font_size", 26)
	lbl.add_theme_color_override("font_color",         color)
	lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	lbl.add_theme_constant_override("outline_size", 7)
	add_child(lbl)
	var tw = create_tween().set_parallel(true)
	tw.tween_property(lbl, "position:y",  lbl.position.y - 55, 2.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tw.tween_property(lbl, "modulate:a",  0.0,                 2.2).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tw.chain().tween_callback(lbl.queue_free)


# ============================================================
# DETECCIÓN DE CATEGORÍA
# ============================================================
func _detect_category(text: String) -> String:
	var t = text.to_lower()
	if "ko" in t or "knocked out" in t or "derrotado" in t or "fuera de combate" in t: return "ko"
	if "usa " in t or "ataca" in t or "uses " in t or "attack" in t:                   return "attack"
	if "daño" in t or "damage" in t or "applied" in t:                                 return "damage"
	if "premio" in t or "prize" in t:                                                  return "prize"
	if "curó" in t or "heal" in t or "recovered" in t or "despertó" in t:              return "heal"
	if "paraliz" in t or "dormido" in t or "envenen" in t or "quemad" in t \
		or "confus" in t or "paralyz" in t or "asleep" in t \
		or "poison" in t or "burn" in t or "confused" in t:                            return "status"
	if "moneda" in t or "flip" in t or "cara" in t or "cruz" in t \
		or "heads" in t or "tails" in t or "sello" in t:                               return "flip"
	if "energía" in t or "energy" in t or "adjunt" in t or "attach" in t:              return "energy"
	if "jugando" in t or "trainer" in t or "supporter" in t or "plays " in t:          return "trainer"
	if "activo" in t or "boca abajo" in t or "setup" in t or "revelac" in t:           return "setup"
	if "turno" in t or "turn " in t or "--- turn" in t:                                return "turn"
	if "⚠" in t or "no puedes" in t or "cannot" in t or "warning" in t:               return "warn"
	if "✖" in t or "error" in t:                                                       return "error"
	return "info"
