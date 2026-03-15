extends Control

# ============================================================
# BattlePassScreen.gd — Rediseño v4 (fix claimed_bp)
# ============================================================

const XP_PER_LEVEL  = 1000
const PREMIUM_COST  = 500

var main_menu_ref:  Node
var lbl_status:     Label
var lbl_gems:       Label
var btn_buy:        Button
var http_buy:       HTTPRequest
var track_premium:  HBoxContainer
var track_free:     HBoxContainer
var _claim_queue:   Array = []

# ── Paleta ────────────────────────────────────────────────────
const C_BG        = Color(0.04, 0.03, 0.08, 1.00)
const C_PANEL     = Color(0.08, 0.07, 0.13, 0.99)
const C_GOLD      = Color(0.98, 0.82, 0.30, 1.00)
const C_GOLD_DIM  = Color(0.52, 0.42, 0.13, 1.00)
const C_GOLD_GLOW = Color(1.00, 0.85, 0.35, 0.18)
const C_PREM_BG   = Color(0.14, 0.09, 0.02, 0.98)
const C_PREM_CARD = Color(0.18, 0.12, 0.03, 0.97)
const C_FREE_BG   = Color(0.06, 0.08, 0.14, 0.98)
const C_FREE_CARD = Color(0.09, 0.11, 0.18, 0.97)
const C_ACCENT    = Color(0.40, 0.75, 1.00, 1.00)
const C_GREEN     = Color(0.28, 0.90, 0.45, 1.00)
const C_RED       = Color(0.95, 0.28, 0.28, 1.00)
const C_TEXT      = Color(0.92, 0.88, 0.74, 1.00)
const C_TEXT_DIM  = Color(0.42, 0.40, 0.32, 1.00)
const C_CLAIMED   = Color(0.24, 0.72, 0.35, 1.00)
const C_LOCKED    = Color(0.26, 0.24, 0.19, 1.00)

const PACK_IMAGE   = "res://assets/Sobres/SobreAgua.png"
const CARD_IMAGE   = "res://assets/cards/Neo Genesis/sneasel-alt.png"

# ============================================================
static func build(parent: Control, main_menu: Node) -> void:
	var screen = load("res://scenes/main_menu/screens/BattlePassScreen.gd").new()
	screen.main_menu_ref = main_menu
	screen.name          = "BattlePassScreenNode"
	screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	parent.add_child(screen)
	screen._setup_ui()

# ============================================================
func _setup_ui() -> void:
	http_buy   = HTTPRequest.new(); add_child(http_buy)
	http_buy.request_completed.connect(_on_buy_completed)

	var bg = ColorRect.new()
	bg.color = C_BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.z_index = -1
	add_child(bg)

	var root = VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 0)
	add_child(root)

	root.add_child(_build_header())
	root.add_child(_build_banner("res://assets/imagen/banner/banner1.png", "⭐  PASE PREMIUM", C_GOLD, C_PREM_BG))
	root.add_child(_build_scroll_row("premium"))
	root.add_child(_build_banner("res://assets/imagen/banner/banner2.png", "🆓  PASE GRATUITO", C_ACCENT, C_FREE_BG))
	root.add_child(_build_scroll_row("free"))

	_build_rewards_track()

# ─────────────────────────────────────────────────────────────
# HEADER
# ─────────────────────────────────────────────────────────────
func _build_header() -> Control:
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(0, 140)

	var s = StyleBoxFlat.new()
	s.bg_color            = C_PANEL
	s.border_color        = C_GOLD_DIM
	s.border_width_bottom = 2
	s.shadow_color        = Color(0, 0, 0, 0.60)
	s.shadow_size         = 18
	panel.add_theme_stylebox_override("panel", s)

	var top_line = ColorRect.new()
	top_line.color  = C_GOLD
	top_line.anchor_left  = 0; top_line.anchor_right  = 1
	top_line.anchor_top   = 0; top_line.anchor_bottom = 0
	top_line.offset_bottom = 2
	panel.add_child(top_line)

	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_child(center)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	center.add_child(vbox)

	var title = Label.new()
	title.text                 = "✦  PASE DE BATALLA  ✦"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", C_GOLD)
	vbox.add_child(title)

	var mid = HBoxContainer.new()
	mid.alignment = BoxContainer.ALIGNMENT_CENTER
	mid.add_theme_constant_override("separation", 14)
	vbox.add_child(mid)

	var lbl_lv = Label.new()
	lbl_lv.text = "Niv. %d" % PlayerData.battle_pass_level
	lbl_lv.add_theme_font_size_override("font_size", 14)
	lbl_lv.add_theme_color_override("font_color", C_GOLD)
	lbl_lv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mid.add_child(lbl_lv)

	var xp_wrap = Panel.new()
	xp_wrap.custom_minimum_size = Vector2(360, 18)
	xp_wrap.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var xp_bg_st = StyleBoxFlat.new()
	xp_bg_st.bg_color = Color(0.12, 0.10, 0.06, 1.0)
	xp_bg_st.border_color = C_GOLD_DIM
	xp_bg_st.border_width_left=1;xp_bg_st.border_width_right=1
	xp_bg_st.border_width_top=1;xp_bg_st.border_width_bottom=1
	xp_bg_st.corner_radius_top_left=9;xp_bg_st.corner_radius_top_right=9
	xp_bg_st.corner_radius_bottom_left=9;xp_bg_st.corner_radius_bottom_right=9
	xp_wrap.add_theme_stylebox_override("panel", xp_bg_st)
	mid.add_child(xp_wrap)

	var xp_fill = Panel.new()
	var pct = float(PlayerData.battle_pass_xp) / float(XP_PER_LEVEL)
	xp_fill.anchor_left   = 0;   xp_fill.anchor_right  = 0
	xp_fill.anchor_top    = 0;   xp_fill.anchor_bottom = 1
	xp_fill.offset_left   = 2;   xp_fill.offset_top    = 2
	xp_fill.offset_bottom = -2;  xp_fill.offset_right  = max(4, (360 - 4) * pct)
	var xp_fill_st = StyleBoxFlat.new()
	xp_fill_st.bg_color = C_GOLD
	xp_fill_st.corner_radius_top_left=7;xp_fill_st.corner_radius_top_right=7
	xp_fill_st.corner_radius_bottom_left=7;xp_fill_st.corner_radius_bottom_right=7
	xp_fill.add_theme_stylebox_override("panel", xp_fill_st)
	xp_wrap.add_child(xp_fill)

	var xp_lbl_ov = Label.new()
	xp_lbl_ov.text = "%d / %d XP" % [PlayerData.battle_pass_xp, XP_PER_LEVEL]
	xp_lbl_ov.set_anchors_preset(Control.PRESET_FULL_RECT)
	xp_lbl_ov.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	xp_lbl_ov.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	xp_lbl_ov.add_theme_font_size_override("font_size", 10)
	xp_lbl_ov.add_theme_color_override("font_color", Color(0.05, 0.04, 0.02, 1.0))
	xp_wrap.add_child(xp_lbl_ov)

	lbl_gems = Label.new()
	lbl_gems.add_theme_font_size_override("font_size", 14)
	lbl_gems.add_theme_color_override("font_color", C_ACCENT)
	lbl_gems.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mid.add_child(lbl_gems)

	var btn_row = HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 18)
	vbox.add_child(btn_row)

	lbl_status = Label.new()
	lbl_status.add_theme_font_size_override("font_size", 13)
	lbl_status.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	btn_row.add_child(lbl_status)

	var btn_all = _make_button("🎁  Reclamar Todo", Color(0.06, 0.22, 0.10, 0.97), C_GREEN, Vector2(200, 40))
	btn_all.pressed.connect(_on_claim_all_pressed)
	btn_row.add_child(btn_all)

	btn_buy = _make_button("💎  Comprar Pase (%d)" % PREMIUM_COST, C_PREM_BG, C_GOLD, Vector2(230, 40))
	btn_buy.pressed.connect(_on_buy_pressed)
	btn_row.add_child(btn_buy)

	_update_premium_ui()
	return panel

# ─────────────────────────────────────────────────────────────
# BANNER
# ─────────────────────────────────────────────────────────────
func _build_banner(img_path: String, txt: String, txt_color: Color, tint: Color) -> Control:
	var c = Control.new()
	c.custom_minimum_size   = Vector2(0, 52)
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var tex = TextureRect.new()
	tex.set_anchors_preset(Control.PRESET_FULL_RECT)
	tex.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	tex.stretch_mode = TextureRect.STRETCH_TILE
	var img = load(img_path)
	if img: tex.texture = img
	c.add_child(tex)

	var ov = ColorRect.new()
	ov.set_anchors_preset(Control.PRESET_FULL_RECT)
	ov.color = Color(tint.r, tint.g, tint.b, 0.82)
	c.add_child(ov)

	for is_top in [true, false]:
		var ln = ColorRect.new()
		ln.color = txt_color if txt_color == C_GOLD else C_GOLD_DIM
		ln.color.a = 0.55
		ln.anchor_left  = 0; ln.anchor_right  = 1
		ln.anchor_top   = 1 if not is_top else 0
		ln.anchor_bottom = 1 if not is_top else 0
		ln.offset_top    = -2 if not is_top else 0
		ln.offset_bottom = 0  if not is_top else 2
		c.add_child(ln)

	var lbl = Label.new()
	lbl.text                 = txt
	lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 15)
	lbl.add_theme_color_override("font_color", txt_color)
	c.add_child(lbl)

	return c

# ─────────────────────────────────────────────────────────────
# SCROLL ROW
# ─────────────────────────────────────────────────────────────
func _build_scroll_row(row_type: String) -> Control:
	var wrapper = Panel.new()
	wrapper.custom_minimum_size = Vector2(0, 200)
	wrapper.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var ws = StyleBoxFlat.new()
	ws.bg_color = C_PREM_BG if row_type == "premium" else C_FREE_BG
	wrapper.add_theme_stylebox_override("panel", ws)

	var scroll = ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode   = ScrollContainer.SCROLL_MODE_DISABLED
	wrapper.add_child(scroll)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left",   14)
	margin.add_theme_constant_override("margin_right",  14)
	margin.add_theme_constant_override("margin_top",    10)
	margin.add_theme_constant_override("margin_bottom", 10)
	scroll.add_child(margin)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	margin.add_child(hbox)

	if row_type == "premium":
		track_premium = hbox
	else:
		track_free = hbox

	return wrapper

# ─────────────────────────────────────────────────────────────
# HELPERS: normalizar claimed_bp para comparación segura
# ─────────────────────────────────────────────────────────────

# Convierte cualquier valor (int, float, String) a int para comparar
func _normalize_claimed_list(raw_list: Array) -> Array:
	var result: Array = []
	for item in raw_list:
		result.append(int(item))
	return result

func _is_claimed(row_type: String, level: int) -> bool:
	var raw_list = PlayerData.claimed_bp.get(row_type, [])
	var normalized = _normalize_claimed_list(raw_list)
	return normalized.has(level)

func _mark_claimed_local(row_type: String, level: int) -> void:
	if not PlayerData.claimed_bp.has(row_type):
		PlayerData.claimed_bp[row_type] = []
	# Normalizar lista existente a ints
	var normalized = _normalize_claimed_list(PlayerData.claimed_bp[row_type])
	if not normalized.has(level):
		normalized.append(level)
	PlayerData.claimed_bp[row_type] = normalized
	print("[BP] claimed_bp actualizado: ", PlayerData.claimed_bp)

# ─────────────────────────────────────────────────────────────
# CONSTRUIR/REBUILD recompensas
# ─────────────────────────────────────────────────────────────
func _build_rewards_track() -> void:
	print("[BP] claimed_bp al rebuild: ", PlayerData.claimed_bp)
	for ch in track_premium.get_children():
		track_premium.remove_child(ch)
		ch.free()
	for ch in track_free.get_children():
		track_free.remove_child(ch)
		ch.free()
	for i in range(1, 51):
		var r = _get_reward_data(i)
		track_premium.add_child(_create_card(i, "premium", r.premium))
		track_free.add_child(_create_card(i, "free", r.free))

func _create_card(level: int, row_type: String, data: Dictionary) -> Control:
	# FIX: usar _is_claimed() que normaliza tipos int/float/string
	var is_claimed   = _is_claimed(row_type, level)
	var is_unlocked  = PlayerData.battle_pass_level >= level
	var needs_prem   = row_type == "premium" and not PlayerData.has_premium_pass
	var is_prem      = row_type == "premium"

	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(130, 178)

	var ps = StyleBoxFlat.new()
	ps.bg_color = C_PREM_CARD if is_prem else C_FREE_CARD

	if is_claimed:
		ps.border_color = C_CLAIMED
		ps.shadow_color = Color(C_CLAIMED.r, C_CLAIMED.g, C_CLAIMED.b, 0.12)
		ps.shadow_size  = 6
		ps.bg_color     = (C_PREM_CARD if is_prem else C_FREE_CARD).lerp(Color(0.05, 0.14, 0.07), 0.35)
	elif is_unlocked and not needs_prem:
		ps.border_color = C_GOLD   if is_prem else C_ACCENT
		ps.shadow_color = (C_GOLD  if is_prem else C_ACCENT)
		ps.shadow_color.a = 0.25
		ps.shadow_size  = 8
	else:
		ps.border_color = C_LOCKED
		ps.bg_color     = (C_PREM_CARD if is_prem else C_FREE_CARD).darkened(0.15)

	ps.border_width_left  = 2; ps.border_width_right  = 2
	ps.border_width_top   = 2; ps.border_width_bottom = 2
	ps.corner_radius_top_left    = 10; ps.corner_radius_top_right    = 10
	ps.corner_radius_bottom_left = 10; ps.corner_radius_bottom_right = 10
	panel.add_theme_stylebox_override("panel", ps)

	var chip = Panel.new()
	chip.position = Vector2(96, 4)
	chip.size     = Vector2(30, 22)
	var cs = StyleBoxFlat.new()
	if is_claimed:
		cs.bg_color = C_CLAIMED
	elif is_unlocked and not needs_prem:
		cs.bg_color = C_GOLD if is_prem else C_ACCENT
	else:
		cs.bg_color = C_LOCKED
	cs.corner_radius_top_left     = 4; cs.corner_radius_top_right    = 8
	cs.corner_radius_bottom_left  = 8; cs.corner_radius_bottom_right = 4
	chip.add_theme_stylebox_override("panel", cs)
	var chip_lbl = Label.new()
	chip_lbl.text = str(level)
	chip_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	chip_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chip_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	chip_lbl.add_theme_font_size_override("font_size", 11)
	if is_claimed or (is_unlocked and not needs_prem):
		chip_lbl.add_theme_color_override("font_color", Color(0.04, 0.03, 0.01, 1))
	else:
		chip_lbl.add_theme_color_override("font_color", C_TEXT_DIM)
	chip.add_child(chip_lbl)
	panel.add_child(chip)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 6; vbox.offset_right = -6
	vbox.offset_top  = 6; vbox.offset_bottom = -6
	vbox.add_theme_constant_override("separation", 5)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(vbox)

	var icon_container = Control.new()
	icon_container.custom_minimum_size = Vector2(0, 80)
	icon_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(icon_container)

	var is_pack_or_card = data.type == "pack" or data.type == "card"
	var img_path = ""
	if data.type == "pack":
		img_path = PACK_IMAGE
	elif data.type == "card":
		img_path = CARD_IMAGE

	if is_pack_or_card and img_path != "":
		var img_tex = load(img_path)
		if img_tex:
			var img_rect = TextureRect.new()
			img_rect.texture     = img_tex
			img_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
			img_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			img_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
			img_rect.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			if not (is_claimed or needs_prem or not is_unlocked):
				img_rect.mouse_filter = Control.MOUSE_FILTER_STOP
				img_rect.gui_input.connect(func(ev):
					if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
						_show_image_zoom(img_path)
				)
			else:
				img_rect.modulate = Color(0.5, 0.5, 0.5, 0.6)
			icon_container.add_child(img_rect)
		else:
			var icon = Label.new()
			icon.text = "📦"
			icon.set_anchors_preset(Control.PRESET_FULL_RECT)
			icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			icon.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
			icon.add_theme_font_size_override("font_size", 36)
			icon_container.add_child(icon)
	else:
		var icon = Label.new()
		icon.set_anchors_preset(Control.PRESET_FULL_RECT)
		icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		icon.add_theme_font_size_override("font_size", 36)
		if not (is_unlocked and not needs_prem) or is_claimed:
			icon.modulate = Color(0.55, 0.55, 0.55, 0.6)
		match data.type:
			"coins": icon.text = "🪙"
			"gems":  icon.text = "💎"
		icon_container.add_child(icon)

	var div = ColorRect.new()
	div.custom_minimum_size = Vector2(0, 1)
	div.color = (C_GOLD if is_prem else C_ACCENT)
	div.color.a = 0.12
	vbox.add_child(div)

	var desc = Label.new()
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.add_theme_font_size_override("font_size", 12)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if is_claimed:
		desc.add_theme_color_override("font_color", C_CLAIMED.lerp(C_TEXT, 0.4))
	elif is_unlocked and not needs_prem:
		desc.add_theme_color_override("font_color", C_TEXT)
	else:
		desc.add_theme_color_override("font_color", C_TEXT_DIM)
	match data.type:
		"coins": desc.text = "%d Monedas" % data.amount
		"gems":  desc.text = "%d Gemas"   % data.amount
		"pack":  desc.text = "%dx Sobre"  % data.amount
		"card":  desc.text = "Sneasel Alt"
	vbox.add_child(desc)

	var btn = Button.new()
	btn.add_theme_font_size_override("font_size", 12)
	btn.custom_minimum_size        = Vector2(110, 30)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	if is_claimed:
		btn.text = "✓ Listo"; btn.disabled = true
		_style_btn(btn, Color(0.05, 0.16, 0.08, 0.85), C_CLAIMED)
	elif not is_unlocked:
		btn.text = "🔒"; btn.disabled = true
		_style_btn(btn, Color(0.07, 0.07, 0.09, 0.55), C_LOCKED)
	elif needs_prem:
		btn.text = "⭐ Premium"; btn.disabled = true
		_style_btn(btn, C_PREM_BG, C_GOLD_DIM)
	else:
		btn.text = "Reclamar"
		_style_btn(btn,
			C_PREM_BG if is_prem else Color(0.05, 0.11, 0.20, 0.97),
			C_GOLD    if is_prem else C_ACCENT)
		btn.pressed.connect(func(): _on_claim_pressed(level, row_type, btn, panel))
	vbox.add_child(btn)

	return panel

# ─────────────────────────────────────────────────────────────
# ZOOM DE IMAGEN (modal)
# ─────────────────────────────────────────────────────────────
func _show_image_zoom(img_path: String) -> void:
	var overlay = ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color   = Color(0, 0, 0, 0.78)
	overlay.z_index = 400
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	get_parent().add_child(overlay)

	var frame = Panel.new()
	frame.z_index = 401
	frame.custom_minimum_size = Vector2(280, 380)
	frame.anchor_left   = 0.5; frame.anchor_right  = 0.5
	frame.anchor_top    = 0.5; frame.anchor_bottom = 0.5
	frame.grow_horizontal = Control.GROW_DIRECTION_BOTH
	frame.grow_vertical   = Control.GROW_DIRECTION_BOTH
	var fst = StyleBoxFlat.new()
	fst.bg_color     = Color(0.07, 0.05, 0.02, 0.98)
	fst.border_color = C_GOLD
	fst.border_width_left=3;fst.border_width_right=3
	fst.border_width_top=3;fst.border_width_bottom=3
	fst.corner_radius_top_left=16;fst.corner_radius_top_right=16
	fst.corner_radius_bottom_left=16;fst.corner_radius_bottom_right=16
	fst.shadow_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.35)
	fst.shadow_size  = 28
	fst.content_margin_left=20;fst.content_margin_right=20
	fst.content_margin_top=20;fst.content_margin_bottom=20
	frame.add_theme_stylebox_override("panel", fst)
	get_parent().add_child(frame)

	var img_tex = load(img_path)
	if img_tex:
		var img_rect = TextureRect.new()
		img_rect.texture      = img_tex
		img_rect.expand_mode  = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		img_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		img_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		frame.add_child(img_rect)

	var close_lbl = Label.new()
	close_lbl.text = "✕  Cerrar"
	close_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	close_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	close_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_BOTTOM
	close_lbl.add_theme_font_size_override("font_size", 13)
	close_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 0.8))
	close_lbl.offset_bottom = -8
	frame.add_child(close_lbl)

	var _close = func():
		overlay.queue_free()
		frame.queue_free()

	overlay.gui_input.connect(func(ev):
		if ev is InputEventMouseButton and ev.pressed:
			_close.call()
	)
	frame.gui_input.connect(func(ev):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_RIGHT:
			_close.call()
	)

# ─────────────────────────────────────────────────────────────
# HELPERS ESTILO
# ─────────────────────────────────────────────────────────────
func _make_button(lbl_text: String, bg: Color, border: Color, sz: Vector2 = Vector2(160, 38)) -> Button:
	var btn = Button.new()
	btn.text = lbl_text
	btn.custom_minimum_size        = sz
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_style_btn(btn, bg, border)
	return btn

func _style_btn(btn: Button, bg: Color, border: Color) -> void:
	for st in ["normal", "hover", "pressed", "disabled"]:
		var s = StyleBoxFlat.new()
		s.bg_color = bg.lightened(0.10) if st == "hover" else bg
		if st == "disabled": s.bg_color = bg.darkened(0.30)
		s.border_color = border if st != "disabled" else border.darkened(0.45)
		s.border_width_left  = 2; s.border_width_right  = 2
		s.border_width_top   = 2; s.border_width_bottom = 2
		s.corner_radius_top_left    = 8; s.corner_radius_top_right    = 8
		s.corner_radius_bottom_left = 8; s.corner_radius_bottom_right = 8
		if st == "hover":
			s.shadow_color = Color(border.r, border.g, border.b, 0.35)
			s.shadow_size  = 10
		btn.add_theme_stylebox_override(st, s)
	btn.add_theme_color_override("font_color",          border)
	btn.add_theme_color_override("font_disabled_color", border.darkened(0.45))

# ─────────────────────────────────────────────────────────────
# DATOS
# ─────────────────────────────────────────────────────────────
func _get_reward_data(level: int) -> Dictionary:
	var packs = ["typhlosion_pack", "feraligatr_pack", "meganium_pack"]
	var pk    = packs[level % 3]
	var f = {"type": "coins", "amount": 25}
	var p = {"type": "coins", "amount": 100}

	if level % 5 == 0 and level % 10 != 0 and level != 50: f = {"type": "gems",  "amount": 5}
	elif level == 48: f = {"type": "pack", "id": pk, "amount": 3}
	elif level == 49: f = {"type": "pack", "id": pk, "amount": 5}
	elif level == 50: f = {"type": "card", "id": "sneasel", "amount": 1}

	if level % 10 == 0 and level != 50:                    p = {"type": "gems",  "amount": 10}
	elif level % 2 != 0 and level < 48: p = {"type": "pack", "id": pk, "amount": 1}
	elif level == 48: p = {"type": "pack", "id": pk, "amount": 5}
	elif level == 49: p = {"type": "pack", "id": pk, "amount": 10}
	elif level == 50: p = {"type": "card", "id": "sneasel", "amount": 1}

	return {"free": f, "premium": p}

# ─────────────────────────────────────────────────────────────
# UPDATE UI
# ─────────────────────────────────────────────────────────────
func _update_premium_ui() -> void:
	if not lbl_gems or not btn_buy or not lbl_status: return
	lbl_gems.text = "💎  %d" % PlayerData.gems
	if PlayerData.has_premium_pass:
		btn_buy.text = "✓  Pase Activado"; btn_buy.disabled = true
		_style_btn(btn_buy, Color(0.06, 0.22, 0.10, 0.97), C_GREEN)
		lbl_status.text = "¡Pase Premium activo!"
		lbl_status.add_theme_color_override("font_color", C_GREEN)
	else:
		btn_buy.text = "💎  Comprar Pase (%d)" % PREMIUM_COST; btn_buy.disabled = false
		_style_btn(btn_buy, C_PREM_BG, C_GOLD)
		lbl_status.text = "Desbloquea recompensas premium."
		lbl_status.add_theme_color_override("font_color", C_TEXT_DIM)

# ─────────────────────────────────────────────────────────────
# RECLAMAR TODO
# ─────────────────────────────────────────────────────────────
func _on_claim_all_pressed() -> void:
	_claim_queue.clear()
	for i in range(1, 51):
		for rt in ["free", "premium"]:
			# FIX: usar _is_claimed() normalizado
			var is_claimed  = _is_claimed(rt, i)
			var is_unlocked = PlayerData.battle_pass_level >= i
			var needs_prem  = rt == "premium" and not PlayerData.has_premium_pass
			if not is_claimed and is_unlocked and not needs_prem:
				_claim_queue.append({"level": i, "type": rt})

	if _claim_queue.is_empty():
		main_menu_ref._show_global_toast("No hay recompensas pendientes")
		return

	main_menu_ref._show_global_toast("Reclamando %d recompensas..." % _claim_queue.size())
	_process_claim_queue()

func _process_claim_queue() -> void:
	if _claim_queue.is_empty():
		_build_rewards_track()
		_update_premium_ui()
		main_menu_ref._show_global_toast("¡Todo reclamado!")
		return
	var nx = _claim_queue[0]
	_claim_queue.remove_at(0)
	_send_claim_request(nx.level, nx.type, null, null)

func _send_claim_request(level: int, row_type: String, btn_ref, card_ref) -> void:
	if btn_ref and is_instance_valid(btn_ref):
		btn_ref.disabled = true
		btn_ref.text = "..."
	var http = HTTPRequest.new()
	add_child(http)
	var url     = NetworkManager.BASE_URL + "/api/battlepass/claim"
	var headers = ["Content-Type: application/json", "Authorization: Bearer " + NetworkManager.token]
	var self_ref = weakref(self)
	http.request_completed.connect(func(result, code, _h, body):
		if is_instance_valid(http): http.queue_free()
		var s = self_ref.get_ref()
		if s == null or not is_instance_valid(s): return
		s._on_claim_completed(result, code, _h, body, level, row_type)
	)
	http.request(url, headers, HTTPClient.METHOD_POST,
		JSON.stringify({"level": level, "type": row_type}))

# ─────────────────────────────────────────────────────────────
# HTTP
# ─────────────────────────────────────────────────────────────
func _on_buy_pressed() -> void:
	if PlayerData.gems < PREMIUM_COST:
		lbl_status.text = "Gemas insuficientes."
		lbl_status.add_theme_color_override("font_color", C_RED)
		return
	btn_buy.disabled = true
	http_buy.request(NetworkManager.BASE_URL + "/api/battlepass/buy",
		["Content-Type: application/json", "Authorization: Bearer " + NetworkManager.token],
		HTTPClient.METHOD_POST, "")

func _on_buy_completed(_r: int, code: int, _h: PackedStringArray, body: PackedByteArray) -> void:
	if code == 200:
		var json = JSON.parse_string(body.get_string_from_utf8())
		if json and json.has("success"):
			PlayerData.has_premium_pass = true
			PlayerData.gems = json.get("gems_remaining", PlayerData.gems)
			_update_premium_ui()
			_build_rewards_track()
			main_menu_ref._show_global_toast("¡Pase Premium activado!")
	else:
		btn_buy.disabled = false

func _on_claim_pressed(level: int, row_type: String, btn_ref: Button, card_ref: Control) -> void:
	_send_claim_request(level, row_type, btn_ref, card_ref)

# FIX: recibe level y row_type como parámetros directos — ya no depende del JSON
func _on_claim_completed(_r: int, code: int, _h: PackedStringArray, body: PackedByteArray,
		level: int, row_type: String) -> void:
	var json = JSON.parse_string(body.get_string_from_utf8())
	print("[BP] _on_claim_completed code=", code, " level=", level, " type=", row_type)

	if code == 200:
		if json and json.has("success"):
			var reward = json.get("reward", {})
			match reward.get("type", ""):
				"gems":         PlayerData.gems  += reward.get("amount", 0)
				"coins":        PlayerData.coins += reward.get("amount", 0)
				"pack", "card": PlayerData.add_card(reward.get("id", ""), reward.get("amount", 1))

		# FIX: usar level/row_type del closure, no del JSON — evita problemas de tipo
		_mark_claimed_local(row_type, level)

		_update_premium_ui()
		if not _claim_queue.is_empty():
			_process_claim_queue()
		else:
			_build_rewards_track()
			main_menu_ref._show_global_toast("¡Recompensa reclamada!")

	elif code == 400:
		# Ya reclamado en el servidor — sincronizar localmente igual
		_mark_claimed_local(row_type, level)
		if not _claim_queue.is_empty():
			_process_claim_queue()
		else:
			_build_rewards_track()

	else:
		_claim_queue.clear()
		_build_rewards_track()
		main_menu_ref._show_global_toast("Error al reclamar, intenta de nuevo")
