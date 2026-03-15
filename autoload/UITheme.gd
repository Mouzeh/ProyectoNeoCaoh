extends Node
# ============================================================
# UITheme.gd  —  AUTOLOAD
# Paleta de colores, helpers de widgets y estilos compartidos.
# Registrar en Project → Project Settings → Autoload como "UITheme"
# ============================================================

# ─── TAMAÑOS DE FUENTE CENTRALIZADOS ────────────────────────
const FS_XS     = 11   # badges pequeños, detalles mínimos
const FS_SM     = 13   # textos secundarios, subtítulos pequeños
const FS_BASE   = 15   # texto base del chat, labels generales
const FS_MD     = 17   # botones, items de menú
const FS_LG     = 20   # títulos de sección
const FS_XL     = 24   # títulos principales
const FS_PILL   = 12   # pills / badges
const FS_DOT    = 10   # decoradores (◆)

# ─── PALETA ─────────────────────────────────────────────────
const COLOR_BG       = Color(0.04, 0.05, 0.08)
const COLOR_PANEL    = Color(0.07, 0.09, 0.14, 0.97)
const COLOR_GOLD     = Color(0.95, 0.82, 0.40)
const COLOR_GOLD_DIM = Color(0.55, 0.44, 0.18)
const COLOR_TEXT     = Color(0.93, 0.90, 0.80)
const COLOR_TEXT_DIM = Color(0.55, 0.54, 0.48)
const COLOR_ACCENT   = Color(0.22, 0.58, 0.92)
const COLOR_ACCENT2  = Color(0.15, 0.75, 0.80)
const COLOR_RED      = Color(0.80, 0.22, 0.22)
const COLOR_GREEN    = Color(0.22, 0.72, 0.38)
const COLOR_PURPLE   = Color(0.45, 0.22, 0.72)

# ─── COLOR POR TIPO ─────────────────────────────────────────
func type_color(t: String) -> Color:
	match t.to_upper():
		"FIRE":      return Color(0.90, 0.35, 0.15)
		"WATER":     return Color(0.20, 0.55, 0.90)
		"GRASS":     return Color(0.25, 0.75, 0.30)
		"LIGHTNING": return Color(0.95, 0.85, 0.10)
		"PSYCHIC":   return Color(0.75, 0.25, 0.80)
		"FIGHTING":  return Color(0.80, 0.45, 0.20)
		"COLORLESS": return Color(0.65, 0.65, 0.65)
		"DARKNESS":  return Color(0.20, 0.25, 0.30)
		"METAL":     return Color(0.60, 0.65, 0.70)
		"TRAINER":   return Color(0.30, 0.50, 0.80)
		"ENERGY":    return Color(0.50, 0.50, 0.50)
		_:           return Color(0.35, 0.35, 0.45)

# ─── ICONO DE TIPO ──────────────────────────────────────────
func type_icon(t: String) -> Texture2D:
	const BASE = "res://assets/imagen/TypesIcons/"
	var file: String
	match t.to_upper():
		"FIRE":      file = "fire.png"
		"WATER":     file = "water.png"
		"GRASS":     file = "grass.png"
		"LIGHTNING": file = "electric.png"
		"PSYCHIC":   file = "psy.png"
		"FIGHTING":  file = "figth.png"
		"COLORLESS": file = "incolor.png"
		"DARKNESS":  file = "dark.png"
		"METAL":     file = "metal.png"
		"DRAGON":    file = "dragon.png"
		"TRAINER":   file = "entrenador.png"
		"ENERGY":    file = "energia.png"
		_:           return null
	return load(BASE + file)

# ============================================================
# WIDGETS
# ============================================================

# ─── Label centrado ─────────────────────────────────────────
func clbl(text: String, fs: int = FS_BASE, color: Color = COLOR_TEXT) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.add_theme_font_size_override("font_size", fs)
	l.add_theme_color_override("font_color", color)
	return l

# ─── Label alineado a la izquierda ──────────────────────────
func llbl(text: String, fs: int = FS_BASE, color: Color = COLOR_TEXT) -> Label:
	var l := Label.new()
	l.text = text
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.add_theme_font_size_override("font_size", fs)
	l.add_theme_color_override("font_color", color)
	return l

# ─── Espacio vertical ───────────────────────────────────────
func vspace(px: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, px)
	return c

# ─── Divisor decorativo ─────────────────────────────────────
func divider() -> Control:
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 0)
	hb.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var line_color := Color(COLOR_GOLD_DIM.r, COLOR_GOLD_DIM.g, COLOR_GOLD_DIM.b, 0.35)
	for side in [true, false]:
		if side:
			var ll := ColorRect.new()
			ll.color = line_color
			ll.custom_minimum_size = Vector2(0, 1)
			ll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			ll.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			hb.add_child(ll)
			var dot := Label.new()
			dot.text = " ◆ "
			dot.add_theme_font_size_override("font_size", FS_DOT)
			dot.add_theme_color_override("font_color", COLOR_GOLD_DIM)
			hb.add_child(dot)
		else:
			var rl := ColorRect.new()
			rl.color = line_color
			rl.custom_minimum_size = Vector2(0, 1)
			rl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			rl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			hb.add_child(rl)

	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_top", 4)
	m.add_theme_constant_override("margin_bottom", 4)
	m.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	m.add_child(hb)
	return m

# ─── Pill / badge ───────────────────────────────────────────
func pill(text: String, bg: Color, fg: Color, min_h: int) -> Control:
	var pc := PanelContainer.new()
	pc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pc.custom_minimum_size   = Vector2(0, min_h)

	var st := StyleBoxFlat.new()
	st.bg_color     = bg
	st.border_color = Color(fg.r, fg.g, fg.b, 0.40)
	st.border_width_left   = 1; st.border_width_right  = 1
	st.border_width_top    = 1; st.border_width_bottom = 1
	st.corner_radius_top_left    = 5; st.corner_radius_top_right    = 5
	st.corner_radius_bottom_left = 5; st.corner_radius_bottom_right = 5
	pc.add_theme_stylebox_override("panel", st)

	var l := Label.new()
	l.text = text
	l.horizontal_alignment  = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment    = VERTICAL_ALIGNMENT_CENTER
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	l.add_theme_font_size_override("font_size", FS_PILL)
	l.add_theme_color_override("font_color", fg)
	pc.add_child(l)
	return pc

# ─── Botón estilizado ────────────────────────────────────────
func btn(text: String, color: Color, min_h: int = 44, fs: int = FS_MD) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size   = Vector2(0, min_h)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.add_theme_font_size_override("font_size", fs)
	b.add_theme_color_override("font_color", Color.WHITE)

	for st_name in ["normal", "hover", "pressed", "focus", "disabled"]:
		var st := StyleBoxFlat.new()
		match st_name:
			"disabled": st.bg_color = Color(0.10, 0.10, 0.12)
			"hover":    st.bg_color = color.lightened(0.18)
			"pressed":  st.bg_color = color.darkened(0.12)
			_:          st.bg_color = color
		st.corner_radius_top_left    = 6; st.corner_radius_top_right    = 6
		st.corner_radius_bottom_left = 6; st.corner_radius_bottom_right = 6
		b.add_theme_stylebox_override(st_name, st)
	return b

# ─── Botón primario (gold) ───────────────────────────────────
func primary_btn(text: String, min_h: int = 52, fs: int = FS_MD) -> Button:
	var b := btn(text, COLOR_GOLD, min_h, fs)
	b.add_theme_color_override("font_color", COLOR_PANEL)
	var normal := b.get_theme_stylebox("normal") as StyleBoxFlat
	normal.shadow_color  = Color(COLOR_GOLD.r, COLOR_GOLD.g, COLOR_GOLD.b, 0.2)
	normal.shadow_size   = 15
	normal.shadow_offset = Vector2(0, 4)
	var hover := b.get_theme_stylebox("hover") as StyleBoxFlat
	hover.shadow_color  = normal.shadow_color
	hover.shadow_size   = 15
	hover.shadow_offset = Vector2(0, 4)
	return b

# ─── Botón outline (sin fondo) ───────────────────────────────
func outline_btn(text: String, fg: Color, min_h: int = 48, fs: int = FS_MD) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size   = Vector2(0, min_h)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.add_theme_font_size_override("font_size", fs)
	b.add_theme_color_override("font_color", fg)

	var st := StyleBoxFlat.new()
	st.bg_color     = Color(0, 0, 0, 0)
	st.border_color = Color(fg.r, fg.g, fg.b, 0.4)
	st.border_width_left   = 1; st.border_width_right  = 1
	st.border_width_top    = 1; st.border_width_bottom = 1
	st.corner_radius_top_left    = 8; st.corner_radius_top_right    = 8
	st.corner_radius_bottom_left = 8; st.corner_radius_bottom_right = 8

	var st_hov := st.duplicate() as StyleBoxFlat
	st_hov.bg_color     = Color(1, 1, 1, 0.03)
	st_hov.border_color = fg

	var st_press := st.duplicate() as StyleBoxFlat
	st_press.bg_color = Color(0, 0, 0, 0.1)

	b.add_theme_stylebox_override("normal",  st)
	b.add_theme_stylebox_override("hover",   st_hov)
	b.add_theme_stylebox_override("pressed", st_press)
	return b

# ─── Barra de color (header accent) ─────────────────────────
func color_strip(color: Color, height: int, rounded_top: bool = false) -> Control:
	var p := Panel.new()
	p.custom_minimum_size   = Vector2(0, height)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var st := StyleBoxFlat.new()
	st.bg_color = color
	if rounded_top:
		st.corner_radius_top_left  = 10
		st.corner_radius_top_right = 10
	p.add_theme_stylebox_override("panel", st)
	return p

# ─── Ícono circular ─────────────────────────────────────────
func circle_icon(symbol: String, radius: int, color: Color) -> Control:
	var pc := PanelContainer.new()
	pc.custom_minimum_size = Vector2(radius * 2, radius * 2)

	var st := StyleBoxFlat.new()
	st.bg_color     = Color(0.10, 0.12, 0.20)
	st.border_color = color
	st.border_width_left   = 2; st.border_width_right  = 2
	st.border_width_top    = 2; st.border_width_bottom = 2
	st.corner_radius_top_left    = radius; st.corner_radius_top_right    = radius
	st.corner_radius_bottom_left = radius; st.corner_radius_bottom_right = radius
	pc.add_theme_stylebox_override("panel", st)

	var l := Label.new()
	l.text = symbol
	l.horizontal_alignment  = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment    = VERTICAL_ALIGNMENT_CENTER
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	l.add_theme_font_size_override("font_size", radius - 4)
	l.add_theme_color_override("font_color", color)
	pc.add_child(l)
	return pc

# ─── StyleBox para LineEdit ──────────────────────────────────
func input_style(border_color: Color) -> StyleBoxFlat:
	var st := StyleBoxFlat.new()
	st.bg_color     = Color(0.05, 0.07, 0.12)
	st.border_color = border_color
	st.border_width_bottom = 2; st.border_width_left  = 1
	st.border_width_right  = 1; st.border_width_top   = 1
	st.corner_radius_top_left    = 6; st.corner_radius_top_right    = 6
	st.corner_radius_bottom_left = 6; st.corner_radius_bottom_right = 6
	st.content_margin_left   = 14; st.content_margin_top    = 10
	st.content_margin_right  = 14; st.content_margin_bottom = 10
	return st

# ─── Panel estilizado genérico ───────────────────────────────
func styled_panel(
	bg: Color = COLOR_PANEL,
	border: Color = COLOR_GOLD_DIM,
	border_alpha: float = 0.4,
	corner: int = 8,
	shadow: bool = false
) -> StyleBoxFlat:
	var st := StyleBoxFlat.new()
	st.bg_color     = bg
	st.border_color = Color(border.r, border.g, border.b, border_alpha)
	st.border_width_left   = 1; st.border_width_right  = 1
	st.border_width_top    = 1; st.border_width_bottom = 1
	st.corner_radius_top_left    = corner; st.corner_radius_top_right    = corner
	st.corner_radius_bottom_left = corner; st.corner_radius_bottom_right = corner
	if shadow:
		st.shadow_color  = Color(0, 0, 0, 0.4)
		st.shadow_size   = 25
		st.shadow_offset = Vector2(0, 10)
	return st

# ─── Card (panel con franja de color arriba) ─────────────────
func card(accent: Color, children: Array) -> Control:
	var pc := PanelContainer.new()
	pc.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var ps := StyleBoxFlat.new()
	ps.bg_color     = COLOR_PANEL
	ps.border_color = Color(COLOR_GOLD_DIM.r, COLOR_GOLD_DIM.g, COLOR_GOLD_DIM.b, 0.50)
	ps.border_width_left   = 1; ps.border_width_right  = 1
	ps.border_width_top    = 1; ps.border_width_bottom = 1
	ps.corner_radius_top_left    = 10; ps.corner_radius_top_right    = 10
	ps.corner_radius_bottom_left = 10; ps.corner_radius_bottom_right = 10
	pc.add_theme_stylebox_override("panel", ps)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 0)
	pc.add_child(vb)

	vb.add_child(color_strip(accent, 4, true))

	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left",   16)
	m.add_theme_constant_override("margin_right",  16)
	m.add_theme_constant_override("margin_top",    14)
	m.add_theme_constant_override("margin_bottom", 14)
	vb.add_child(m)

	var inner := VBoxContainer.new()
	inner.name = "CardInner"
	inner.add_theme_constant_override("separation", 8)
	m.add_child(inner)

	for child in children:
		inner.add_child(child)
	return pc

# ─── Scrollbar dorada personalizada ─────────────────────────
func apply_scrollbar_theme(scroll: ScrollContainer) -> void:
	var theme := Theme.new()

	var rail := StyleBoxFlat.new()
	rail.bg_color = Color(0.1, 0.1, 0.15, 0.5)
	rail.corner_radius_top_left    = 4; rail.corner_radius_top_right    = 4
	rail.corner_radius_bottom_left = 4; rail.corner_radius_bottom_right = 4

	var grabber := StyleBoxFlat.new()
	grabber.bg_color = Color(COLOR_GOLD_DIM.r, COLOR_GOLD_DIM.g, COLOR_GOLD_DIM.b, 0.6)
	grabber.corner_radius_top_left    = 4; grabber.corner_radius_top_right    = 4
	grabber.corner_radius_bottom_left = 4; grabber.corner_radius_bottom_right = 4

	theme.set_stylebox("scroll",            "VScrollBar", rail)
	theme.set_stylebox("grabber",           "VScrollBar", grabber)
	theme.set_stylebox("grabber_highlight", "VScrollBar", grabber)
	theme.set_stylebox("grabber_pressed",   "VScrollBar", grabber)

	var empty := StyleBoxEmpty.new()
	theme.set_stylebox("scroll",   "HScrollBar", empty)
	theme.set_stylebox("grabber",  "HScrollBar", empty)

	scroll.theme = theme

# ─── Helper: buscar nodo por nombre ─────────────────────────
func find_node(root: Node, target: String) -> Node:
	if root.name == target:
		return root
	for c in root.get_children():
		var f := find_node(c, target)
		if f:
			return f
	return null
