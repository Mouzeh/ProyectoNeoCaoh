extends Node
class_name DiscardViewer

# ============================================================
# DiscardViewer.gd
# Visor de descarte con grid de cartas y zoom navegable.
# OverlayManager lo instancia y delega show/close.
# ============================================================

const CARD_W = 130
const CARD_H = 182

const COLOR_BG2      = Color(0.07, 0.10, 0.16, 1.0)
const COLOR_GOLD     = Color(0.92, 0.78, 0.32)
const COLOR_TEXT     = Color(0.93, 0.90, 0.80)
const COLOR_TEXT_DIM = Color(0.60, 0.58, 0.52)

var board:   Node2D  = null
var vp_size: Vector2 = Vector2.ZERO

var _viewer:                 Control = null
var _cards_cache:            Array   = []
var _current_index:          int     = 0
var _zoom_navigating:        bool    = false


# ============================================================
# SETUP
# ============================================================
func setup(parent_board: Node2D, viewport_size: Vector2) -> void:
	board   = parent_board
	vp_size = viewport_size


# ============================================================
# API PÚBLICA
# ============================================================
func is_open() -> bool:
	return _viewer != null


func show_viewer(discard_cards: Array, title: String = "Descarte") -> void:
	if _viewer: return
	if discard_cards.is_empty(): return

	_cards_cache   = discard_cards
	_current_index = 0

	_viewer = Control.new()
	_viewer.name = "DiscardViewer"
	_viewer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_viewer.z_index = 250
	board.add_child(_viewer)

	var dim = ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.88)
	_viewer.add_child(dim)

	var panel_w = min(vp_size.x - 80, 860.0)
	var panel_h = min(vp_size.y - 100, 580.0)
	var panel   = Panel.new()
	panel.name     = "DVPanel"
	panel.position = Vector2((vp_size.x - panel_w) / 2.0, (vp_size.y - panel_h) / 2.0)
	panel.size     = Vector2(panel_w, panel_h)
	panel.add_theme_stylebox_override("panel",
		_make_shadow_style(Color(0.05, 0.08, 0.12, 0.98), COLOR_GOLD, 14, 2, Color(0,0,0,0.5), 16))
	_viewer.add_child(panel)

	var header_bg = Panel.new()
	header_bg.position = Vector2(0, 0)
	header_bg.size     = Vector2(panel_w, 52)
	header_bg.add_theme_stylebox_override("panel", _make_panel_style(COLOR_BG2, Color(0,0,0,0), 14))
	panel.add_child(header_bg)

	var header_lbl = Label.new()
	header_lbl.text     = "🗑  %s  (%d cartas)" % [title, discard_cards.size()]
	header_lbl.position = Vector2(20, 14)
	header_lbl.size     = Vector2(panel_w - 100, 26)
	header_lbl.add_theme_font_size_override("font_size", 16)
	header_lbl.add_theme_color_override("font_color", COLOR_GOLD)
	panel.add_child(header_lbl)

	var close_btn = Button.new()
	close_btn.text     = "✕"
	close_btn.position = Vector2(panel_w - 46, 8)
	close_btn.size     = Vector2(36, 36)
	close_btn.flat     = true
	close_btn.add_theme_font_size_override("font_size", 18)
	close_btn.add_theme_color_override("font_color", Color(0.7, 0.4, 0.4))
	close_btn.pressed.connect(close_viewer)
	panel.add_child(close_btn)

	var sep = ColorRect.new()
	sep.color    = Color(COLOR_GOLD.r, COLOR_GOLD.g, COLOR_GOLD.b, 0.18)
	sep.position = Vector2(0, 52)
	sep.size     = Vector2(panel_w, 1)
	panel.add_child(sep)

	var scroll = ScrollContainer.new()
	scroll.position = Vector2(12, 58)
	scroll.size     = Vector2(panel_w - 24, panel_h - 70)
	panel.add_child(scroll)

	var flow = HFlowContainer.new()
	flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	flow.add_theme_constant_override("h_separation", 12)
	flow.add_theme_constant_override("v_separation", 12)
	scroll.add_child(flow)

	var card_scale = 0.72
	var cw = int(CARD_W * card_scale)
	var ch = int(CARD_H * card_scale)

	for i in range(discard_cards.size()):
		var card_entry = discard_cards[i]
		var card_id = card_entry.get("card_id", "") if card_entry is Dictionary else str(card_entry)
		if card_id == "": continue

		var slot = Control.new()
		slot.custom_minimum_size = Vector2(cw, ch + 22)
		flow.add_child(slot)

		var card_inst = CardDatabase.create_card_instance(card_id)
		card_inst.scale        = Vector2(card_scale, card_scale)
		card_inst.is_draggable = false
		card_inst.position     = Vector2.ZERO
		card_inst.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(card_inst)

		var name_lbl = Label.new()
		var cdata_dv = CardDatabase.get_card(card_id)
		name_lbl.text = cdata_dv.get("name", card_id)
		name_lbl.position = Vector2(0, ch + 2)
		name_lbl.size     = Vector2(cw, 18)
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.add_theme_font_size_override("font_size", 9)
		name_lbl.add_theme_color_override("font_color", COLOR_TEXT)
		slot.add_child(name_lbl)

		var click_area = Button.new()
		click_area.set_anchors_preset(Control.PRESET_FULL_RECT)
		click_area.flat = true
		click_area.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var hover_s = _make_panel_style(Color(1,1,1,0.10),
			Color(COLOR_GOLD.r, COLOR_GOLD.g, COLOR_GOLD.b, 0.60), 4, 2)
		click_area.add_theme_stylebox_override("hover", hover_s)
		var idx_local = i
		click_area.pressed.connect(func(): _open_card_zoom(idx_local))
		slot.add_child(click_area)

	panel.modulate.a = 0.0
	panel.scale      = Vector2(0.92, 0.92)
	var tw = panel.create_tween()
	tw.set_parallel(true)
	tw.tween_property(panel, "modulate:a", 1.0,         0.18)
	tw.tween_property(panel, "scale",      Vector2.ONE, 0.20) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.gui_input.connect(func(ev):
		if ev is InputEventMouseButton and ev.pressed:
			close_viewer()
	)


func close_viewer() -> void:
	if _viewer:
		var tw = _viewer.create_tween()
		tw.tween_property(_viewer, "modulate:a", 0.0, 0.12)
		tw.tween_callback(func():
			_viewer.queue_free()
			_viewer = null
		)


# ============================================================
# ZOOM DE CARTA INDIVIDUAL
# ============================================================
func _open_card_zoom(index: int) -> void:
	if _zoom_navigating: return
	if index < 0 or index >= _cards_cache.size(): return
	_current_index   = index
	_zoom_navigating = true

	for child in board.get_children():
		if child.name.begins_with("DiscardCardZoom"):
			child.name = "_old_dcz_%d" % child.get_instance_id()
			child.queue_free()

	_zoom_navigating = false

	var card_entry = _cards_cache[index]
	if card_entry == null: return
	var card_id = card_entry.get("card_id", "") if card_entry is Dictionary else str(card_entry)
	if card_id == "": return

	var overlay = Control.new()
	overlay.name         = "DiscardCardZoom"
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.z_index      = 300
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.focus_mode   = Control.FOCUS_ALL
	board.add_child(overlay)
	overlay.grab_focus()

	var dim = ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color        = Color(0, 0, 0, 0.82)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(dim)

	var zoom_scale = clamp(min((vp_size.x * 0.45) / CARD_W, (vp_size.y * 0.70) / CARD_H), 1.5, 3.5)
	var card_w = CARD_W * zoom_scale
	var card_h = CARD_H * zoom_scale
	var card_x = round(vp_size.x / 2.0 - card_w / 2.0)
	var card_y = round(vp_size.y / 2.0 - card_h / 2.0 - 30.0)
	var card_rect = Rect2(card_x, card_y, card_w, card_h)

	var card_inst = CardDatabase.create_card_instance(card_id)
	card_inst.name         = "ZoomCard"
	card_inst.is_draggable = false
	card_inst.is_locked    = true
	card_inst.scale        = Vector2(zoom_scale, zoom_scale)
	card_inst.position     = Vector2(card_x, card_y)
	card_inst.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(card_inst)

	var counter_lbl = Label.new()
	counter_lbl.text                = "%d / %d" % [index + 1, _cards_cache.size()]
	counter_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	counter_lbl.position            = Vector2(0, card_y + card_h + 12)
	counter_lbl.size                = Vector2(vp_size.x, 24)
	counter_lbl.add_theme_font_size_override("font_size", 13)
	counter_lbl.add_theme_color_override("font_color", COLOR_TEXT_DIM)
	counter_lbl.mouse_filter        = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(counter_lbl)

	var cdata = CardDatabase.get_card(card_id)
	var name_lbl = Label.new()
	name_lbl.text                = cdata.get("name", card_id)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.position            = Vector2(0, card_y + card_h + 38)
	name_lbl.size                = Vector2(vp_size.x, 24)
	name_lbl.add_theme_font_size_override("font_size", 15)
	name_lbl.add_theme_color_override("font_color", COLOR_GOLD)
	name_lbl.mouse_filter        = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(name_lbl)

	var btn_prev = _build_arrow_btn("◀", index > 0)
	btn_prev.position = Vector2(card_x - 64, vp_size.y / 2.0 - 28)
	btn_prev.size     = Vector2(52, 56)
	btn_prev.pressed.connect(func():
		if _current_index > 0:
			_open_card_zoom(_current_index - 1)
	)
	overlay.add_child(btn_prev)

	var btn_next = _build_arrow_btn("▶", index < _cards_cache.size() - 1)
	btn_next.position = Vector2(card_x + card_w + 12, vp_size.y / 2.0 - 28)
	btn_next.size     = Vector2(52, 56)
	btn_next.pressed.connect(func():
		if _current_index < _cards_cache.size() - 1:
			_open_card_zoom(_current_index + 1)
	)
	overlay.add_child(btn_next)

	var hint = Label.new()
	hint.text                = "← → para navegar  •  Esc para cerrar zoom  •  clic fuera para cerrar"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.position            = Vector2(0, vp_size.y - 36)
	hint.size                = Vector2(vp_size.x, 24)
	hint.add_theme_font_size_override("font_size", 11)
	hint.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 0.7))
	hint.mouse_filter        = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(hint)

	var close_btn = Button.new()
	close_btn.text     = "✕"
	close_btn.position = Vector2(card_x + card_w - 40, card_y - 44)
	close_btn.size     = Vector2(44, 44)
	close_btn.z_index  = 10
	close_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	close_btn.add_theme_font_size_override("font_size", 22)
	close_btn.add_theme_color_override("font_color", Color(1, 1, 1))
	var close_style = StyleBoxFlat.new()
	close_style.bg_color     = Color(0.7, 0.1, 0.1, 0.95)
	close_style.border_color = Color(1, 0.3, 0.3)
	close_style.set_border_width_all(2)
	close_style.set_corner_radius_all(8)
	close_btn.add_theme_stylebox_override("normal", close_style)
	var close_hover = close_style.duplicate()
	close_hover.bg_color = Color(0.9, 0.15, 0.15, 1.0)
	close_btn.add_theme_stylebox_override("hover", close_hover)
	close_btn.pressed.connect(func(): _close_all_zooms())
	overlay.add_child(close_btn)

	overlay.gui_input.connect(func(ev):
		if ev is InputEventKey and ev.pressed:
			if ev.keycode == KEY_ESCAPE:
				_close_all_zooms()
				board.get_viewport().set_input_as_handled()
			elif ev.keycode == KEY_LEFT:
				if _current_index > 0:
					_open_card_zoom(_current_index - 1)
				board.get_viewport().set_input_as_handled()
			elif ev.keycode == KEY_RIGHT:
				if _current_index < _cards_cache.size() - 1:
					_open_card_zoom(_current_index + 1)
				board.get_viewport().set_input_as_handled()
		elif ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT and ev.pressed:
			if not card_rect.has_point(ev.position):
				_close_all_zooms()
			board.get_viewport().set_input_as_handled()
	)

	card_inst.modulate.a = 0.0
	card_inst.create_tween().tween_property(card_inst, "modulate:a", 1.0, 0.15)


func _close_all_zooms() -> void:
	for child in board.get_children():
		if child.name.begins_with("DiscardCardZoom"):
			child.queue_free()


# ============================================================
# BUILDERS
# ============================================================
func _build_arrow_btn(text: String, enabled: bool) -> Button:
	var btn = Button.new()
	btn.text     = text
	btn.disabled = not enabled
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var sn = StyleBoxFlat.new()
	sn.bg_color     = Color(0.10, 0.14, 0.20, 0.90) if enabled else Color(0.06, 0.06, 0.08, 0.40)
	sn.border_color = COLOR_GOLD if enabled else Color(0.3, 0.3, 0.3, 0.20)
	sn.set_border_width_all(1)
	sn.set_corner_radius_all(10)
	btn.add_theme_stylebox_override("normal", sn)
	var sh = StyleBoxFlat.new()
	sh.bg_color     = Color(0.18, 0.25, 0.38, 0.98)
	sh.border_color = COLOR_GOLD
	sh.set_border_width_all(2)
	sh.set_corner_radius_all(10)
	sh.shadow_color = Color(COLOR_GOLD.r, COLOR_GOLD.g, COLOR_GOLD.b, 0.30)
	sh.shadow_size  = 8
	btn.add_theme_stylebox_override("hover", sh)
	btn.add_theme_color_override("font_color", COLOR_GOLD if enabled else Color(0.3, 0.3, 0.3, 0.4))
	btn.add_theme_font_size_override("font_size", 22)
	return btn


# ============================================================
# HELPERS DE ESTILO (funciones puras)
# ============================================================
func _make_panel_style(bg: Color, border: Color, radius: float = 12.0, border_w: float = 1.0) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(int(border_w))
	s.set_corner_radius_all(int(radius))
	return s


func _make_shadow_style(bg: Color, border: Color, radius: float, border_w: float, shadow_col: Color, shadow_sz: float) -> StyleBoxFlat:
	var s = _make_panel_style(bg, border, radius, border_w)
	s.shadow_color = shadow_col
	s.shadow_size  = int(shadow_sz)
	return s
