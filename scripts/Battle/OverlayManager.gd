extends Node
class_name OverlayManager

# ─── SEÑALES ────────────────────────────────────────────────
signal setup_confirmed()
signal setup_reselect_active()
signal promote_selected(bench_index)
signal action_zoom_selected(action_type, index)
signal glaring_gaze_resolved(hand_index)
signal game_over_closed()

# ─── CONSTANTES ─────────────────────────────────────────────
const CARD_W      = 130
const CARD_H      = 182
const COLOR_GOLD      = Color(0.85, 0.72, 0.30)
const COLOR_GOLD_DIM  = Color(0.55, 0.45, 0.18)
const COLOR_TEXT      = Color(0.92, 0.88, 0.75)
const PATH_TYPES  = "res://assets/imagen/TypesIcons/"
const PATH_TOKENS = "res://assets/imagen/tokens/"

# ─── REFERENCIAS Y ESTADO ───────────────────────────────────
var board:               Node2D  = null
var vp_size:             Vector2

var setup_overlay:       Control = null
var promote_popup:       Control = null
var zoom_overlay:        Control = null
var action_zoom_overlay: Control = null
var gaze_popup:          Control = null
var discard_viewer:      Control = null
var zoom_active:         bool    = false

var _setup_active_card_id: String  = ""
var _setup_active_preview: Control = null

func setup(parent_board: Node2D) -> void:
	board   = parent_board
	vp_size = board.get_viewport().get_visible_rect().size


# ============================================================
# SETUP OVERLAY
# ============================================================
func show_setup_overlay(state: Dictionary, my_player_id: String) -> void:
	var setup_ready = state.get("setup_ready", {})
	var yo_listo    = setup_ready.get(my_player_id, false)

	if yo_listo:
		if setup_overlay:
			var btn = setup_overlay.get_node_or_null("SetupPanel/BtnRow/ConfirmBtn")
			if btn: btn.disabled = true
			var re_btn = setup_overlay.get_node_or_null("SetupPanel/BtnRow/ReelectBtn")
			if re_btn: re_btn.hide()
			var title = setup_overlay.get_node_or_null("SetupPanel/TitleLbl")
			if title: title.text = "⏳  Esperando al rival..."
		return

	if setup_overlay: return

	_setup_active_card_id = ""

	setup_overlay = Control.new()
	setup_overlay.name = "SetupOverlay"
	setup_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	setup_overlay.z_index = 50
	board.add_child(setup_overlay)

	var dim = ColorRect.new()
	dim.name = "Dim"
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.0, 0.0, 0.0, 0.0)
	setup_overlay.add_child(dim)

	var panel_w = min(820.0, vp_size.x - 40)
	var panel_h = 320.0
	var panel   = Panel.new()
	panel.name     = "SetupPanel"
	panel.position = Vector2((vp_size.x - panel_w) / 2.0, (vp_size.y - panel_h) / 2.0)
	panel.size     = Vector2(panel_w, panel_h)

	var pstyle = StyleBoxFlat.new()
	pstyle.bg_color          = Color(0.04, 0.07, 0.06, 0.98)
	pstyle.border_color      = COLOR_GOLD
	pstyle.border_width_left = 2; pstyle.border_width_right  = 2
	pstyle.border_width_top  = 2; pstyle.border_width_bottom = 2
	pstyle.corner_radius_top_left    = 18; pstyle.corner_radius_top_right    = 18
	pstyle.corner_radius_bottom_left = 18; pstyle.corner_radius_bottom_right = 18
	pstyle.shadow_color = Color(0.85, 0.72, 0.30, 0.30)
	pstyle.shadow_size  = 20
	panel.add_theme_stylebox_override("panel", pstyle)
	setup_overlay.add_child(panel)

	var title_lbl = Label.new()
	title_lbl.name = "TitleLbl"
	title_lbl.text = "⚔  FASE DE PREPARACIÓN"
	title_lbl.position = Vector2(0, 18)
	title_lbl.size     = Vector2(panel_w, 30)
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 20)
	title_lbl.add_theme_color_override("font_color", COLOR_GOLD)
	panel.add_child(title_lbl)

	var sep_top = ColorRect.new()
	sep_top.color    = Color(COLOR_GOLD.r, COLOR_GOLD.g, COLOR_GOLD.b, 0.30)
	sep_top.position = Vector2(panel_w * 0.1, 56)
	sep_top.size     = Vector2(panel_w * 0.8, 1)
	panel.add_child(sep_top)

	var content_x = 24.0
	var content_y = 72.0
	var preview_w = CARD_W * 1.1
	var preview_h = CARD_H * 1.1
	var info_x    = content_x + preview_w + 32.0
	var info_w    = panel_w - info_x - 24.0

	var active_tag = Label.new()
	active_tag.text     = "POKÉMON ACTIVO"
	active_tag.position = Vector2(content_x, content_y - 18)
	active_tag.size     = Vector2(preview_w, 16)
	active_tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	active_tag.add_theme_font_size_override("font_size", 9)
	active_tag.add_theme_color_override("font_color", Color(COLOR_GOLD.r, COLOR_GOLD.g, COLOR_GOLD.b, 0.60))
	panel.add_child(active_tag)

	var preview_bg = Panel.new()
	preview_bg.name     = "PreviewBg"
	preview_bg.position = Vector2(content_x, content_y)
	preview_bg.size     = Vector2(preview_w, preview_h)
	var prev_style = StyleBoxFlat.new()
	prev_style.bg_color          = Color(0.08, 0.12, 0.10, 0.9)
	prev_style.border_color      = Color(COLOR_GOLD.r, COLOR_GOLD.g, COLOR_GOLD.b, 0.30)
	prev_style.border_width_left = 1; prev_style.border_width_right  = 1
	prev_style.border_width_top  = 1; prev_style.border_width_bottom = 1
	prev_style.corner_radius_top_left    = 10; prev_style.corner_radius_top_right    = 10
	prev_style.corner_radius_bottom_left = 10; prev_style.corner_radius_bottom_right = 10
	preview_bg.add_theme_stylebox_override("panel", prev_style)
	panel.add_child(preview_bg)

	var placeholder_lbl = Label.new()
	placeholder_lbl.name = "PlaceholderLbl"
	placeholder_lbl.text = "?\nActivo"
	placeholder_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	placeholder_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	placeholder_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	placeholder_lbl.add_theme_font_size_override("font_size", 22)
	placeholder_lbl.add_theme_color_override("font_color", Color(COLOR_GOLD.r, COLOR_GOLD.g, COLOR_GOLD.b, 0.28))
	preview_bg.add_child(placeholder_lbl)

	var instr_lbl = Label.new()
	instr_lbl.name          = "InstrLbl"
	instr_lbl.text          = "Haz clic en un Pokémon Básico\nde tu mano para el Activo"
	instr_lbl.position      = Vector2(info_x, content_y)
	instr_lbl.size          = Vector2(info_w, 56)
	instr_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	instr_lbl.add_theme_font_size_override("font_size", 16)
	instr_lbl.add_theme_color_override("font_color", Color(0.90, 0.85, 0.65))
	panel.add_child(instr_lbl)

	var chosen_lbl = Label.new()
	chosen_lbl.name     = "ChosenLbl"
	chosen_lbl.text     = ""
	chosen_lbl.position = Vector2(info_x, content_y + 62)
	chosen_lbl.size     = Vector2(info_w, 28)
	chosen_lbl.add_theme_font_size_override("font_size", 17)
	chosen_lbl.add_theme_color_override("font_color", Color(0.40, 0.92, 0.50))
	panel.add_child(chosen_lbl)

	var bench_lbl = Label.new()
	bench_lbl.name     = "BenchLbl"
	bench_lbl.text     = ""
	bench_lbl.position = Vector2(info_x, content_y + 96)
	bench_lbl.size     = Vector2(info_w, 22)
	bench_lbl.add_theme_font_size_override("font_size", 12)
	bench_lbl.add_theme_color_override("font_color", Color(0.65, 0.65, 0.55, 0.85))
	panel.add_child(bench_lbl)

	var bench_hint = Label.new()
	bench_hint.name     = "BenchHint"
	bench_hint.text     = "Puedes agregar hasta 5 Pokémon al Banco (opcional)"
	bench_hint.position = Vector2(info_x, content_y + 120)
	bench_hint.size     = Vector2(info_w, 18)
	bench_hint.add_theme_font_size_override("font_size", 10)
	bench_hint.add_theme_color_override("font_color", Color(0.50, 0.50, 0.42, 0.55))
	panel.add_child(bench_hint)

	var dots_y = content_y + 144.0
	for i in range(5):
		var slot_dot = Panel.new()
		slot_dot.name     = "BenchDot%d" % i
		slot_dot.position = Vector2(info_x + i * 26.0, dots_y)
		slot_dot.size     = Vector2(20, 20)
		var dot_s = StyleBoxFlat.new()
		dot_s.bg_color     = Color(0.10, 0.16, 0.12, 0.8)
		dot_s.border_color = Color(COLOR_GOLD.r, COLOR_GOLD.g, COLOR_GOLD.b, 0.18)
		dot_s.border_width_left = 1; dot_s.border_width_right  = 1
		dot_s.border_width_top  = 1; dot_s.border_width_bottom = 1
		dot_s.set_corner_radius_all(4)
		slot_dot.add_theme_stylebox_override("panel", dot_s)
		panel.add_child(slot_dot)

	var btn_row = HBoxContainer.new()
	btn_row.name      = "BtnRow"
	btn_row.position  = Vector2(info_x, panel_h - 60)
	btn_row.size      = Vector2(info_w, 44)
	btn_row.alignment = BoxContainer.ALIGNMENT_BEGIN
	btn_row.add_theme_constant_override("separation", 12)
	panel.add_child(btn_row)

	var reelect_btn = _build_reelect_button()
	reelect_btn.name = "ReelectBtn"
	reelect_btn.hide()
	reelect_btn.pressed.connect(_on_reelect_pressed)
	btn_row.add_child(reelect_btn)

	var confirm_btn = _build_confirm_button_new()
	confirm_btn.name     = "ConfirmBtn"
	confirm_btn.disabled = true
	confirm_btn.pressed.connect(func(): emit_signal("setup_confirmed"))
	btn_row.add_child(confirm_btn)

	panel.position.y += 40
	panel.modulate.a  = 0.0
	var tw = board.create_tween()
	tw.set_parallel(true)
	tw.tween_property(dim,   "color",        Color(0, 0, 0, 0.72), 0.25)
	tw.tween_property(panel, "modulate:a",   1.0,                  0.25)
	tw.tween_property(panel, "position:y",   panel.position.y - 40, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _build_reelect_button() -> Button:
	var btn = Button.new()
	btn.text = "↩  Elegir de nuevo"
	btn.custom_minimum_size = Vector2(160, 44)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var s_n = StyleBoxFlat.new()
	s_n.bg_color          = Color(0.18, 0.08, 0.06, 0.95)
	s_n.border_color      = Color(0.80, 0.32, 0.20)
	s_n.border_width_left = 2; s_n.border_width_right  = 2
	s_n.border_width_top  = 2; s_n.border_width_bottom = 2
	s_n.set_corner_radius_all(8)
	s_n.shadow_color = Color(0.8, 0.3, 0.2, 0.25)
	s_n.shadow_size  = 5
	btn.add_theme_stylebox_override("normal", s_n)
	var s_h = StyleBoxFlat.new()
	s_h.bg_color          = Color(0.35, 0.12, 0.08, 0.98)
	s_h.border_color      = Color(0.95, 0.42, 0.25)
	s_h.border_width_left = 2; s_h.border_width_right  = 2
	s_h.border_width_top  = 2; s_h.border_width_bottom = 2
	s_h.set_corner_radius_all(8)
	s_h.shadow_color = Color(0.9, 0.4, 0.2, 0.45)
	s_h.shadow_size  = 8
	btn.add_theme_stylebox_override("hover", s_h)
	btn.add_theme_color_override("font_color", Color(0.95, 0.62, 0.45))
	btn.add_theme_font_size_override("font_size", 13)
	return btn


func _build_confirm_button_new() -> Button:
	var btn = Button.new()
	btn.text = "✓  Confirmar"
	btn.custom_minimum_size = Vector2(160, 44)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var s_n = StyleBoxFlat.new()
	s_n.bg_color          = Color(0.08, 0.20, 0.10, 0.95)
	s_n.border_color      = COLOR_GOLD
	s_n.border_width_left = 2; s_n.border_width_right  = 2
	s_n.border_width_top  = 2; s_n.border_width_bottom = 2
	s_n.set_corner_radius_all(8)
	s_n.shadow_color = Color(0.85, 0.72, 0.30, 0.28)
	s_n.shadow_size  = 6
	btn.add_theme_stylebox_override("normal", s_n)
	var s_h = StyleBoxFlat.new()
	s_h.bg_color          = Color(0.15, 0.38, 0.18, 0.98)
	s_h.border_color      = COLOR_GOLD
	s_h.border_width_left = 2; s_h.border_width_right  = 2
	s_h.border_width_top  = 2; s_h.border_width_bottom = 2
	s_h.set_corner_radius_all(8)
	s_h.shadow_color = Color(0.85, 0.72, 0.30, 0.55)
	s_h.shadow_size  = 10
	btn.add_theme_stylebox_override("hover", s_h)
	var s_d = StyleBoxFlat.new()
	s_d.bg_color          = Color(0.06, 0.06, 0.06, 0.40)
	s_d.border_color      = Color(0.28, 0.25, 0.15, 0.30)
	s_d.border_width_left = 2; s_d.border_width_right  = 2
	s_d.border_width_top  = 2; s_d.border_width_bottom = 2
	s_d.set_corner_radius_all(8)
	btn.add_theme_stylebox_override("disabled", s_d)
	btn.add_theme_color_override("font_color",          COLOR_GOLD)
	btn.add_theme_color_override("font_disabled_color", Color(0.38, 0.35, 0.22, 0.38))
	btn.add_theme_font_size_override("font_size", 14)
	return btn


func _on_reelect_pressed() -> void:
	if not setup_overlay: return
	var preview_bg = setup_overlay.get_node_or_null("SetupPanel/PreviewBg")
	if preview_bg:
		if _setup_active_preview and is_instance_valid(_setup_active_preview):
			_setup_active_preview.queue_free()
			_setup_active_preview = null
		var prev_style = StyleBoxFlat.new()
		prev_style.bg_color          = Color(0.08, 0.12, 0.10, 0.9)
		prev_style.border_color      = Color(COLOR_GOLD.r, COLOR_GOLD.g, COLOR_GOLD.b, 0.30)
		prev_style.border_width_left = 1; prev_style.border_width_right  = 1
		prev_style.border_width_top  = 1; prev_style.border_width_bottom = 1
		prev_style.corner_radius_top_left    = 10; prev_style.corner_radius_top_right    = 10
		prev_style.corner_radius_bottom_left = 10; prev_style.corner_radius_bottom_right = 10
		preview_bg.add_theme_stylebox_override("panel", prev_style)
		var ph = preview_bg.get_node_or_null("PlaceholderLbl")
		if ph:
			ph.show()
			ph.modulate.a = 0.0
			var tw_ph = ph.create_tween()
			tw_ph.tween_property(ph, "modulate:a", 1.0, 0.20)
	var chosen_lbl = setup_overlay.get_node_or_null("SetupPanel/ChosenLbl")
	if chosen_lbl: chosen_lbl.text = ""
	var instr_lbl = setup_overlay.get_node_or_null("SetupPanel/InstrLbl")
	if instr_lbl:
		instr_lbl.text = "Haz clic en un Pokémon Básico\nde tu mano para el Activo"
		instr_lbl.add_theme_color_override("font_color", Color(0.90, 0.85, 0.65))
	var bench_lbl = setup_overlay.get_node_or_null("SetupPanel/BenchLbl")
	if bench_lbl: bench_lbl.text = ""
	var reelect_btn = setup_overlay.get_node_or_null("SetupPanel/BtnRow/ReelectBtn")
	if reelect_btn:
		var tw = reelect_btn.create_tween()
		tw.tween_property(reelect_btn, "modulate:a", 0.0, 0.15)
		tw.tween_callback(func(): reelect_btn.hide())
	var confirm_btn = setup_overlay.get_node_or_null("SetupPanel/BtnRow/ConfirmBtn")
	if confirm_btn:
		confirm_btn.disabled = true
		var pulse = confirm_btn.get_node_or_null("PulseTween")
		if pulse: pulse.queue_free()
		confirm_btn.modulate.a = 1.0
	_setup_active_card_id = ""
	emit_signal("setup_reselect_active")


func hide_setup_overlay() -> void:
	if setup_overlay:
		setup_overlay.queue_free()
		setup_overlay = null
	_setup_active_card_id = ""
	_setup_active_preview = null


func update_setup_status(state: Dictionary) -> void:
	if not setup_overlay: return
	var my_data     = state.get("my", {})
	var has_active  = my_data.get("active") != null
	var bench_list  = my_data.get("bench", [])
	var bench_count = bench_list.filter(func(p): return p != null).size()
	var active_data = my_data.get("active", null)

	var preview_bg = setup_overlay.get_node_or_null("SetupPanel/PreviewBg")
	if preview_bg and has_active and active_data != null:
		var new_card_id = active_data.get("card_id", "")
		if new_card_id != _setup_active_card_id and new_card_id != "":
			_setup_active_card_id = new_card_id
			if _setup_active_preview and is_instance_valid(_setup_active_preview):
				_setup_active_preview.queue_free()
				_setup_active_preview = null
			var ph = preview_bg.get_node_or_null("PlaceholderLbl")
			if ph: ph.hide()
			var card_inst = CardDatabase.create_card_instance(new_card_id)
			card_inst.is_draggable = false
			card_inst.is_locked    = true
			card_inst.mouse_filter = Control.MOUSE_FILTER_IGNORE
			card_inst.position     = Vector2.ZERO
			card_inst.modulate.a   = 0.0
			card_inst.scale        = Vector2(0.85, 0.85)
			preview_bg.add_child(card_inst)
			_setup_active_preview = card_inst
			var tw = card_inst.create_tween()
			tw.set_parallel(true)
			tw.tween_property(card_inst, "modulate:a", 1.0,               0.22)
			tw.tween_property(card_inst, "scale",      Vector2(1.0, 1.0), 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			var pstyle = StyleBoxFlat.new()
			pstyle.bg_color          = Color(0.08, 0.12, 0.10, 0.9)
			pstyle.border_color      = COLOR_GOLD
			pstyle.border_width_left = 2; pstyle.border_width_right  = 2
			pstyle.border_width_top  = 2; pstyle.border_width_bottom = 2
			pstyle.corner_radius_top_left    = 10; pstyle.corner_radius_top_right    = 10
			pstyle.corner_radius_bottom_left = 10; pstyle.corner_radius_bottom_right = 10
			pstyle.shadow_color = Color(COLOR_GOLD.r, COLOR_GOLD.g, COLOR_GOLD.b, 0.50)
			pstyle.shadow_size  = 12
			preview_bg.add_theme_stylebox_override("panel", pstyle)

	var instr_lbl = setup_overlay.get_node_or_null("SetupPanel/InstrLbl")
	if instr_lbl:
		if not has_active:
			instr_lbl.text = "Haz clic en un Pokémon Básico\nde tu mano para el Activo"
			instr_lbl.add_theme_color_override("font_color", Color(0.90, 0.85, 0.65))
		elif bench_count == 0:
			instr_lbl.text = "¡Activo listo!\nAgrega Pokémon al Banco o confirma"
			instr_lbl.add_theme_color_override("font_color", Color(0.40, 0.88, 0.45))
		else:
			instr_lbl.text = "¡Todo listo!\nConfirma o agrega más al Banco"
			instr_lbl.add_theme_color_override("font_color", Color(0.40, 0.88, 0.45))

	var chosen_lbl = setup_overlay.get_node_or_null("SetupPanel/ChosenLbl")
	if chosen_lbl:
		if has_active and active_data != null:
			var cdata = CardDatabase.get_card(active_data.get("card_id", ""))
			chosen_lbl.text = "✓  %s" % cdata.get("name", "Pokémon elegido")
		else:
			chosen_lbl.text = ""

	var bench_lbl = setup_overlay.get_node_or_null("SetupPanel/BenchLbl")
	if bench_lbl:
		if has_active:
			bench_lbl.text = "Banco: %d / 5 Pokémon" % bench_count
			bench_lbl.add_theme_color_override("font_color",
				Color(0.40, 0.88, 0.45) if bench_count > 0 else Color(0.55, 0.55, 0.45, 0.70))
		else:
			bench_lbl.text = ""

	var panel_node = setup_overlay.get_node_or_null("SetupPanel")
	if panel_node:
		for i in range(5):
			var dot = panel_node.get_node_or_null("BenchDot%d" % i)
			if dot:
				var filled  = i < bench_count
				var dot_s   = StyleBoxFlat.new()
				dot_s.bg_color     = Color(0.30, 0.78, 0.38, 0.85) if filled else Color(0.10, 0.16, 0.12, 0.8)
				dot_s.border_color = COLOR_GOLD if filled else Color(COLOR_GOLD.r, COLOR_GOLD.g, COLOR_GOLD.b, 0.20)
				dot_s.border_width_left = 1; dot_s.border_width_right  = 1
				dot_s.border_width_top  = 1; dot_s.border_width_bottom = 1
				dot_s.set_corner_radius_all(4)
				dot.add_theme_stylebox_override("panel", dot_s)

	var reelect_btn = setup_overlay.get_node_or_null("SetupPanel/BtnRow/ReelectBtn")
	if reelect_btn:
		if has_active and not reelect_btn.visible:
			reelect_btn.modulate.a = 0.0
			reelect_btn.show()
			var tw_re = reelect_btn.create_tween()
			tw_re.tween_property(reelect_btn, "modulate:a", 1.0, 0.20)
		elif not has_active and reelect_btn.visible:
			var tw_re = reelect_btn.create_tween()
			tw_re.tween_property(reelect_btn, "modulate:a", 0.0, 0.15)
			tw_re.tween_callback(func(): reelect_btn.hide())

	var confirm_btn = setup_overlay.get_node_or_null("SetupPanel/BtnRow/ConfirmBtn")
	if confirm_btn:
		confirm_btn.disabled = not has_active
		if has_active and not confirm_btn.get_node_or_null("PulseTween"):
			var pulse_marker = Node.new()
			pulse_marker.name = "PulseTween"
			confirm_btn.add_child(pulse_marker)
			var tw_p = confirm_btn.create_tween().set_loops()
			tw_p.tween_property(confirm_btn, "modulate:a", 0.72, 0.65).set_trans(Tween.TRANS_SINE)
			tw_p.tween_property(confirm_btn, "modulate:a", 1.0,  0.65).set_trans(Tween.TRANS_SINE)
		elif not has_active:
			var pulse = confirm_btn.get_node_or_null("PulseTween")
			if pulse: pulse.queue_free()
			confirm_btn.modulate.a = 1.0


# ============================================================
# PROMOTE POPUP
# ============================================================
func show_promote_popup(bench: Array) -> void:
	if promote_popup: return

	promote_popup = Control.new()
	promote_popup.name = "PromotePopup"
	promote_popup.set_anchors_preset(Control.PRESET_FULL_RECT)
	promote_popup.z_index = 250
	board.add_child(promote_popup)

	var dim = ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.82)
	promote_popup.add_child(dim)

	var valid_bench = bench.filter(func(p): return p != null)
	var card_cols   = min(valid_bench.size(), 5)
	var panel_w     = max(360.0, card_cols * (CARD_W + 20) + 60.0)
	var panel_h     = CARD_H + 140.0
	var panel       = Panel.new()
	panel.name     = "PromotePanel"
	panel.position = Vector2((vp_size.x - panel_w) / 2.0, (vp_size.y - panel_h) / 2.0)
	panel.size     = Vector2(panel_w, panel_h)

	var pstyle = StyleBoxFlat.new()
	pstyle.bg_color                  = Color(0.06, 0.10, 0.08, 0.97)
	pstyle.border_color              = Color(0.9, 0.3, 0.3)
	pstyle.border_width_left         = 3; pstyle.border_width_right  = 3
	pstyle.border_width_top          = 3; pstyle.border_width_bottom = 3
	pstyle.corner_radius_top_left    = 14; pstyle.corner_radius_top_right    = 14
	pstyle.corner_radius_bottom_left = 14; pstyle.corner_radius_bottom_right = 14
	pstyle.shadow_color = Color(0.9, 0.2, 0.2, 0.5)
	pstyle.shadow_size  = 20
	panel.add_theme_stylebox_override("panel", pstyle)
	promote_popup.add_child(panel)

	var title = Label.new()
	title.text = "☠  Tu Pokémon activo fue KO"
	title.position = Vector2(10, 12)
	title.size     = Vector2(panel_w - 20, 28)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.95, 0.35, 0.35))
	panel.add_child(title)

	var subtitle = Label.new()
	subtitle.text = "Elige quién pasa al frente"
	subtitle.position = Vector2(10, 42)
	subtitle.size     = Vector2(panel_w - 20, 22)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 13)
	subtitle.add_theme_color_override("font_color", COLOR_GOLD)
	panel.add_child(subtitle)

	var cards_total_w = card_cols * (CARD_W + 16) - 16
	var cards_start_x = (panel_w - cards_total_w) / 2.0
	var bench_col     = 0

	for i in range(bench.size()):
		var poke = bench[i]
		if poke == null: continue
		var card_id = poke.get("card_id", "")
		var slot    = PanelContainer.new()
		slot.position = Vector2(cards_start_x + bench_col * (CARD_W + 16), 72)
		slot.size     = Vector2(CARD_W, CARD_H + 8)
		var slot_style = StyleBoxFlat.new()
		slot_style.bg_color                  = Color(0.1, 0.15, 0.12, 0.8)
		slot_style.border_color              = COLOR_GOLD_DIM
		slot_style.border_width_left         = 1; slot_style.border_width_right  = 1
		slot_style.border_width_top          = 1; slot_style.border_width_bottom = 1
		slot_style.corner_radius_top_left    = 8; slot_style.corner_radius_top_right    = 8
		slot_style.corner_radius_bottom_left = 8; slot_style.corner_radius_bottom_right = 8
		slot.add_theme_stylebox_override("panel", slot_style)
		if not card_id.is_empty() and card_id != "face_down":
			var card_inst = CardDatabase.create_card_instance(card_id)
			card_inst.mouse_filter = Control.MOUSE_FILTER_IGNORE
			slot.add_child(card_inst)
		var btn = Button.new()
		btn.set_anchors_preset(Control.PRESET_FULL_RECT)
		btn.flat = true
		var hover_s = StyleBoxFlat.new()
		hover_s.bg_color                  = Color(0.85, 0.72, 0.30, 0.25)
		hover_s.corner_radius_top_left    = 8; hover_s.corner_radius_top_right    = 8
		hover_s.corner_radius_bottom_left = 8; hover_s.corner_radius_bottom_right = 8
		btn.add_theme_stylebox_override("hover", hover_s)
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var bench_index = i
		btn.pressed.connect(func():
			var tw_out = slot.create_tween()
			tw_out.tween_property(slot, "scale", Vector2(1.15, 1.15), 0.1)
			tw_out.tween_callback(func():
				hide_promote_popup()
				emit_signal("promote_selected", bench_index)
			)
		)
		btn.mouse_entered.connect(func():
			var tw = slot.create_tween()
			tw.tween_property(slot, "scale", Vector2(1.06, 1.06), 0.1)
			slot_style.border_color = COLOR_GOLD
			slot.add_theme_stylebox_override("panel", slot_style)
		)
		btn.mouse_exited.connect(func():
			var tw = slot.create_tween()
			tw.tween_property(slot, "scale", Vector2(1.0, 1.0), 0.1)
			slot_style.border_color = COLOR_GOLD_DIM
			slot.add_theme_stylebox_override("panel", slot_style)
		)
		slot.add_child(btn)
		panel.add_child(slot)
		bench_col += 1

	panel.scale    = Vector2(0.85, 0.85)
	panel.modulate = Color(1, 1, 1, 0.0)
	var tw = board.create_tween()
	tw.set_parallel(true)
	tw.tween_property(panel, "scale",      Vector2(1.0, 1.0), 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(panel, "modulate:a", 1.0,               0.18)

func hide_promote_popup() -> void:
	if promote_popup:
		promote_popup.queue_free()
		promote_popup = null


# ============================================================
# ZOOM NORMAL
# ============================================================
func open_zoom(card_id: String, pokemon_data: Dictionary = {}) -> void:
	if zoom_overlay: return
	zoom_overlay = Control.new()
	zoom_overlay.name = "ZoomOverlay"
	zoom_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	zoom_overlay.size = vp_size
	zoom_overlay.z_index = 350
	board.add_child(zoom_overlay)
	var dim = ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.0, 0.02, 0.05, 0.88)
	zoom_overlay.add_child(dim)
	var center_pivot = Control.new()
	center_pivot.name = "CenterPivot"
	center_pivot.set_anchors_preset(Control.PRESET_FULL_RECT)
	zoom_overlay.add_child(center_pivot)
	var zoom_scale = clamp(min((vp_size.x * 0.55) / CARD_W, (vp_size.y * 0.72) / CARD_H), 1.5, 4.5)
	var card_w     = CARD_W * zoom_scale
	var card_h     = CARD_H * zoom_scale
	var card_x     = round(vp_size.x / 2.0 - card_w / 2.0)
	var card_y     = round(vp_size.y / 2.0 - card_h / 2.0 - 30.0)
	var card_instance = CardDatabase.create_card_instance(card_id)
	card_instance.is_draggable = false
	card_instance.is_locked    = true
	card_instance.pivot_offset = Vector2.ZERO
	center_pivot.add_child(card_instance)
	if not pokemon_data.is_empty():
		_add_zoom_tokens(card_instance, pokemon_data, zoom_scale)
	var cdata  = CardDatabase.get_card(card_id)
	var rarity = cdata.get("rarity", "")
	if rarity != "":
		var rarity_lbl = Label.new()
		rarity_lbl.text = _rarity_badge(rarity)
		rarity_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rarity_lbl.position = Vector2(card_x, card_y + card_h + 10)
		rarity_lbl.size     = Vector2(card_w, 28)
		rarity_lbl.add_theme_font_size_override("font_size", 14)
		rarity_lbl.add_theme_color_override("font_color", _rarity_color(rarity))
		center_pivot.add_child(rarity_lbl)
	var hint = Label.new()
	hint.text = "Clic / Z / Espacio / Esc para cerrar"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.position = Vector2(0, vp_size.y - 36)
	hint.size     = Vector2(vp_size.x, 24)
	hint.add_theme_font_size_override("font_size", 11)
	hint.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 0.8))
	center_pivot.add_child(hint)
	var click_btn = Button.new()
	click_btn.set_anchors_preset(Control.PRESET_FULL_RECT)
	click_btn.flat = true
	click_btn.pressed.connect(close_zoom)
	zoom_overlay.add_child(click_btn)
	var start_scale = zoom_scale * 0.7
	card_instance.scale    = Vector2(start_scale, start_scale)
	card_instance.position = Vector2((vp_size.x - (CARD_W * start_scale)) / 2.0, (vp_size.y - (CARD_H * start_scale)) / 2.0 - 30.0)
	center_pivot.modulate.a = 0.0
	var tw = center_pivot.create_tween()
	tw.set_parallel(true)
	tw.tween_property(card_instance, "scale",    Vector2(zoom_scale, zoom_scale), 0.20).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(card_instance, "position", Vector2(card_x, card_y),         0.20).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(center_pivot,  "modulate:a", 1.0,                           0.15)
	zoom_active = true

func close_zoom() -> void:
	if zoom_overlay:
		var tw = zoom_overlay.create_tween()
		tw.tween_property(zoom_overlay, "modulate:a", 0.0, 0.12)
		tw.tween_callback(func():
			zoom_overlay.queue_free()
			zoom_overlay = null
		)
	zoom_active = false


# ============================================================
# TOKENS EN ZOOM
# ============================================================
func _add_zoom_tokens(card_node: Control, pokemon_data: Dictionary, zoom_scale: float) -> void:
	var overlay = Control.new()
	overlay.name = "ZoomTokenOverlay"
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_node.add_child(overlay)
	var dmg: int = int(pokemon_data.get("damage_counters", 0))
	if dmg > 0:
		var fifties: int = dmg / 5
		var tens:    int = dmg % 5
		var ox:      float = 8.0
		var oy:      float = CARD_H / 2.0 - 20.0
		var tok_size       = 36.0
		for _i in range(fifties):
			_spawn_zoom_token(overlay, PATH_TOKENS + "damage_50.png", "50", Vector2(ox, oy), tok_size)
			ox += tok_size + 4.0
		for _i in range(tens):
			_spawn_zoom_token(overlay, PATH_TOKENS + "damage_10.png", "10", Vector2(ox, oy), tok_size)
			ox += tok_size + 4.0
	const TOKEN_FILES = {
		"POISONED": "poison.png", "BURNED": "burn.png",
		"ASLEEP": "asleep.png", "PARALYZED": "paralyzed.png", "CONFUSED": "confused.png",
	}
	const EMOJIS = {
		"POISONED": "☠", "BURNED": "🔥", "ASLEEP": "💤", "PARALYZED": "⚡", "CONFUSED": "💫"
	}
	var status_list: Array = []
	var status = str(pokemon_data.get("status", ""))
	if status != "" and status != "null": status_list.append(status)
	if pokemon_data.get("is_poisoned", false): status_list.append("POISONED")
	if pokemon_data.get("is_burned",   false): status_list.append("BURNED")
	var sx: float = CARD_W - 36.0
	var sy: float = 24.0
	var st_size   = 30.0
	for st in status_list:
		var fname = TOKEN_FILES.get(st, "")
		if fname != "":
			_spawn_zoom_token(overlay, PATH_TOKENS + fname, EMOJIS.get(st, "?"), Vector2(sx, sy), st_size)
		sx -= st_size + 4.0
	var energies: Array = pokemon_data.get("attached_energy", [])
	if energies.is_empty(): return
	var icon_size = 24.0
	var gap       = 4.0
	var start_x   = -15.0
	var start_y   = 10.0
	for i in range(energies.size()):
		var e_type   = str(CardDatabase.get_energy_type(energies[i]))
		var icon_tx  = _get_type_icon(e_type)
		var target_y = start_y + i * (icon_size + gap)
		var energy_node: Control
		if icon_tx:
			var icon = TextureRect.new()
			icon.texture      = icon_tx
			icon.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.size         = Vector2(icon_size, icon_size)
			energy_node = icon
		else:
			var dot = Panel.new()
			dot.size = Vector2(icon_size, icon_size)
			var dot_s = StyleBoxFlat.new()
			dot_s.bg_color = _energy_color(e_type)
			dot_s.set_corner_radius_all(int(icon_size / 2.0))
			dot_s.anti_aliasing = true
			dot.add_theme_stylebox_override("panel", dot_s)
			energy_node = dot
		overlay.add_child(energy_node)
		energy_node.position   = Vector2(start_x, target_y - 25.0)
		energy_node.modulate.a = 0.0
		var tw            = overlay.create_tween()
		var cascade_delay = i * 0.08
		tw.set_parallel(true)
		tw.tween_property(energy_node, "position:y", target_y, 0.3).set_delay(cascade_delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(energy_node, "modulate:a", 1.0,      0.2).set_delay(cascade_delay)

func _spawn_zoom_token(overlay: Control, path: String, fallback: String, pos: Vector2, size: float) -> void:
	if ResourceLoader.exists(path):
		var tex = load(path) as Texture2D
		if tex:
			var icon = TextureRect.new()
			icon.texture      = tex
			icon.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.size         = Vector2(size, size)
			icon.position     = pos
			overlay.add_child(icon)
			return
	var lbl = Label.new()
	lbl.text     = fallback
	lbl.position = pos
	lbl.add_theme_font_size_override("font_size", int(size * 0.7))
	overlay.add_child(lbl)


# ============================================================
# ACTION ZOOM
# ============================================================
func show_action_zoom(pokemon_data: Dictionary) -> void:
	if action_zoom_overlay: close_action_zoom()
	var card_id = pokemon_data.get("card_id", "")
	if card_id == "": return
	var cdata = CardDatabase.get_card(card_id)
	if cdata.is_empty(): return

	action_zoom_overlay = Control.new()
	action_zoom_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	action_zoom_overlay.size    = vp_size
	action_zoom_overlay.z_index = 250
	board.add_child(action_zoom_overlay)

	var dim = ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.88)
	action_zoom_overlay.add_child(dim)

	var zoom_scale = clamp(min((vp_size.x * 0.40) / CARD_W, (vp_size.y * 0.88) / CARD_H), 1.5, 4.5)
	var card_w     = CARD_W * zoom_scale
	var card_h     = CARD_H * zoom_scale
	var card_pos_x = 225.0
	var card_pos_y = round((vp_size.y - card_h) / 2.0)

	var card_inst = CardDatabase.create_card_instance(card_id)
	card_inst.is_draggable = false
	card_inst.is_locked    = true
	card_inst.pivot_offset = Vector2.ZERO
	card_inst.scale        = Vector2(zoom_scale, zoom_scale)
	card_inst.position     = Vector2(card_pos_x, card_pos_y)
	card_inst.mouse_filter = Control.MOUSE_FILTER_IGNORE
	action_zoom_overlay.add_child(card_inst)

	_add_zoom_tokens(card_inst, pokemon_data, zoom_scale)

	var btn_x = card_pos_x + card_w + 40.0
	var btn_w = vp_size.x - btn_x - 60.0

	var vbox = VBoxContainer.new()
	vbox.position  = Vector2(btn_x, card_pos_y)
	vbox.size      = Vector2(btn_w, card_h)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 15)
	action_zoom_overlay.add_child(vbox)

	var power = cdata.get("pokemon_power", null)
	if power != null:
		vbox.add_child(_build_power_ui(power))

	var attacks = cdata.get("attacks", [])
	for i in range(attacks.size()):
		vbox.add_child(_build_attack_ui(attacks[i], i))

	var sep = Control.new()
	sep.custom_minimum_size = Vector2(0, 10)
	vbox.add_child(sep)

	vbox.add_child(_build_retreat_ui(cdata))

	var cancel_btn = _create_system_btn("CERRAR", "CANCEL", 0)
	cancel_btn.custom_minimum_size = Vector2(0, 40)
	vbox.add_child(cancel_btn)

func close_action_zoom() -> void:
	if action_zoom_overlay:
		action_zoom_overlay.queue_free()
		action_zoom_overlay = null


# ============================================================
# VISOR DE DESCARTE
# ============================================================
func show_discard_viewer(discard_cards: Array, title: String = "Descarte") -> void:
	if discard_viewer: return
	if discard_cards.is_empty(): return
	discard_viewer = Control.new()
	discard_viewer.name = "DiscardViewer"
	discard_viewer.set_anchors_preset(Control.PRESET_FULL_RECT)
	discard_viewer.z_index = 250
	board.add_child(discard_viewer)
	var dim = ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.86)
	discard_viewer.add_child(dim)
	var panel_w = min(vp_size.x - 80, 860.0)
	var panel_h = min(vp_size.y - 100, 580.0)
	var panel   = Panel.new()
	panel.name     = "DVPanel"
	panel.position = Vector2((vp_size.x - panel_w) / 2.0, (vp_size.y - panel_h) / 2.0)
	panel.size     = Vector2(panel_w, panel_h)
	var pstyle = StyleBoxFlat.new()
	pstyle.bg_color                  = Color(0.06, 0.09, 0.12, 0.98)
	pstyle.border_color              = COLOR_GOLD
	pstyle.border_width_left         = 2; pstyle.border_width_right  = 2
	pstyle.border_width_top          = 2; pstyle.border_width_bottom = 2
	pstyle.corner_radius_top_left    = 14; pstyle.corner_radius_top_right    = 14
	pstyle.corner_radius_bottom_left = 14; pstyle.corner_radius_bottom_right = 14
	panel.add_theme_stylebox_override("panel", pstyle)
	discard_viewer.add_child(panel)
	var header_lbl = Label.new()
	header_lbl.text = "🗑  %s  (%d cartas)" % [title, discard_cards.size()]
	header_lbl.position = Vector2(20, 12)
	header_lbl.size     = Vector2(panel_w - 100, 30)
	header_lbl.add_theme_font_size_override("font_size", 17)
	header_lbl.add_theme_color_override("font_color", COLOR_GOLD)
	panel.add_child(header_lbl)
	var close_btn = Button.new()
	close_btn.text     = "✕"
	close_btn.position = Vector2(panel_w - 46, 8)
	close_btn.size     = Vector2(36, 36)
	close_btn.flat     = true
	close_btn.add_theme_font_size_override("font_size", 18)
	close_btn.add_theme_color_override("font_color", Color(0.7, 0.4, 0.4))
	close_btn.pressed.connect(close_discard_viewer)
	panel.add_child(close_btn)
	var scroll = ScrollContainer.new()
	scroll.position = Vector2(12, 52)
	scroll.size     = Vector2(panel_w - 24, panel_h - 64)
	panel.add_child(scroll)
	var flow = HFlowContainer.new()
	flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	flow.add_theme_constant_override("h_separation", 12)
	flow.add_theme_constant_override("v_separation", 12)
	scroll.add_child(flow)
	var card_scale = 0.72
	var cw = int(CARD_W * card_scale)
	var ch = int(CARD_H * card_scale)
	for card_entry in discard_cards:
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
		var hover_s = StyleBoxFlat.new()
		hover_s.bg_color                  = Color(1, 1, 1, 0.12)
		hover_s.corner_radius_top_left    = 4; hover_s.corner_radius_top_right    = 4
		hover_s.corner_radius_bottom_left = 4; hover_s.corner_radius_bottom_right = 4
		click_area.add_theme_stylebox_override("hover", hover_s)
		var cid_local = card_id
		click_area.pressed.connect(func(): open_zoom(cid_local))
		slot.add_child(click_area)
	panel.modulate.a = 0.0
	panel.scale      = Vector2(0.92, 0.92)
	var tw = panel.create_tween()
	tw.set_parallel(true)
	tw.tween_property(panel, "modulate:a", 1.0,         0.18)
	tw.tween_property(panel, "scale",      Vector2.ONE, 0.20).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.gui_input.connect(func(ev):
		if ev is InputEventMouseButton and ev.pressed:
			close_discard_viewer()
	)

func close_discard_viewer() -> void:
	if discard_viewer:
		var tw = discard_viewer.create_tween()
		tw.tween_property(discard_viewer, "modulate:a", 0.0, 0.12)
		tw.tween_callback(func():
			discard_viewer.queue_free()
			discard_viewer = null
		)


# ============================================================
# CONSTRUCTORES DE UI (ACTION ZOOM)
# ============================================================
func _build_attack_ui(atk: Dictionary, index: int) -> Control:
	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.14, 0.18, 0.95)
	style.border_color = COLOR_GOLD
	style.border_width_left = 2; style.border_width_right  = 2
	style.border_width_top  = 2; style.border_width_bottom = 2
	style.corner_radius_top_left    = 10; style.corner_radius_top_right    = 10
	style.corner_radius_bottom_left = 10; style.corner_radius_bottom_right = 10
	style.content_margin_left  = 25; style.content_margin_right  = 25
	style.content_margin_top   = 20; style.content_margin_bottom = 20
	panel.add_theme_stylebox_override("panel", style)
	var hbox = HBoxContainer.new()
	hbox.alignment    = BoxContainer.ALIGNMENT_CENTER
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_theme_constant_override("separation", 15)
	panel.add_child(hbox)
	var cost = atk.get("cost", [])
	for e in cost:
		var icon = TextureRect.new()
		icon.texture = _get_type_icon(str(e))
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.custom_minimum_size = Vector2(32, 32)
		hbox.add_child(icon)
	var lbl     = Label.new()
	var dmg     = str(atk.get("damage", ""))
	var dmg_txt = (" [" + dmg + "]" if dmg != "" and dmg != "0" else "")
	lbl.text = " " + atk.get("name", "").to_upper() + dmg_txt
	lbl.add_theme_font_size_override("font_size", 24)
	lbl.add_theme_color_override("font_color", COLOR_GOLD)
	hbox.add_child(lbl)
	panel.add_child(_make_overlay_button(func():
		close_action_zoom()
		emit_signal("action_zoom_selected", "ATTACK", index)
	))
	return panel

func _build_retreat_ui(cdata: Dictionary) -> Control:
	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color     = Color(0.08, 0.08, 0.10, 0.90)
	style.border_color = Color(0.5, 0.5, 0.5)
	style.border_width_left = 1; style.border_width_right  = 1
	style.border_width_top  = 1; style.border_width_bottom = 1
	style.corner_radius_top_left    = 6; style.corner_radius_top_right    = 6
	style.corner_radius_bottom_left = 6; style.corner_radius_bottom_right = 6
	style.content_margin_left  = 16; style.content_margin_right  = 16
	style.content_margin_top   = 12; style.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", style)
	var hbox = HBoxContainer.new()
	hbox.alignment    = BoxContainer.ALIGNMENT_CENTER
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_theme_constant_override("separation", 8)
	panel.add_child(hbox)
	var lbl = Label.new()
	lbl.text = "🏃 RETIRAR "
	lbl.add_theme_font_size_override("font_size", 14)
	hbox.add_child(lbl)
	var r_cost   = cdata.get("retreatCost", cdata.get("retreat_cost", []))
	var cost_val = r_cost.size() if typeof(r_cost) == TYPE_ARRAY else int(r_cost)
	if cost_val > 0:
		for i in range(cost_val):
			var icon = TextureRect.new()
			icon.texture = _get_type_icon("COLORLESS")
			icon.custom_minimum_size = Vector2(18, 18)
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			hbox.add_child(icon)
	else:
		var free = Label.new()
		free.text = "(Gratis)"
		free.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
		free.add_theme_font_size_override("font_size", 12)
		hbox.add_child(free)
	panel.add_child(_make_overlay_button(func():
		close_action_zoom()
		emit_signal("action_zoom_selected", "RETREAT", 0)
	))
	return panel

# ── CAMBIO: ahora emite el nombre del power en lugar de 0 ────
func _build_power_ui(power: Dictionary) -> Control:
	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color     = Color(0.3, 0.05, 0.05, 0.95)
	style.border_color = Color(0.9, 0.2, 0.2)
	style.border_width_left = 1; style.border_width_right  = 1
	style.border_width_top  = 1; style.border_width_bottom = 1
	style.corner_radius_top_left    = 6; style.corner_radius_top_right    = 6
	style.corner_radius_bottom_left = 6; style.corner_radius_bottom_right = 6
	style.content_margin_top = 10; style.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", style)

	var power_name: String = power.get("name", "")

	var lbl = Label.new()
	lbl.text = "⚡ POKÉMON POWER: " + power_name.to_upper()
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 16)
	panel.add_child(lbl)

	# FIX: emitir el nombre del power, no 0
	panel.add_child(_make_overlay_button(func():
		close_action_zoom()
		emit_signal("action_zoom_selected", "POWER", power_name)
	))
	return panel

func _make_overlay_button(callback: Callable) -> Button:
	var btn = Button.new()
	btn.set_anchors_preset(Control.PRESET_FULL_RECT)
	btn.flat = true
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var hover = StyleBoxFlat.new()
	hover.bg_color                  = Color(1, 1, 1, 0.1)
	hover.corner_radius_top_left    = 8; hover.corner_radius_top_right    = 8
	hover.corner_radius_bottom_left = 8; hover.corner_radius_bottom_right = 8
	btn.add_theme_stylebox_override("hover", hover)
	btn.pressed.connect(callback)
	return btn

func _create_system_btn(text: String, type: String, index: int) -> Button:
	var btn = Button.new()
	btn.text = text
	var s = StyleBoxFlat.new()
	s.bg_color                  = Color(0.2, 0.2, 0.2, 0.8)
	s.corner_radius_top_left    = 4; s.corner_radius_top_right    = 4
	s.corner_radius_bottom_left = 4; s.corner_radius_bottom_right = 4
	btn.add_theme_stylebox_override("normal", s)
	btn.pressed.connect(func():
		close_action_zoom()
		if type != "CANCEL": emit_signal("action_zoom_selected", type, index)
	)
	return btn

func _get_type_icon(type_str: String) -> Texture2D:
	const FILES = {
		"FIRE":      "fire.png",     "WATER":    "water.png",   "GRASS":    "grass.png",
		"LIGHTNING": "electric.png", "PSYCHIC":  "psy.png",     "FIGHTING": "figth.png",
		"COLORLESS": "incolor.png",  "DARKNESS": "dark.png",    "METAL":    "metal.png",
		"DRAGON":    "dragon.png",
	}
	var file = FILES.get(type_str.to_upper(), "incolor.png")
	return load(PATH_TYPES + file)


# ============================================================
# HELPERS DE COLOR Y RAREZA
# ============================================================
func _energy_color(type_str: String) -> Color:
	match type_str.to_upper():
		"FIRE":      return Color(0.92, 0.42, 0.15)
		"WATER":     return Color(0.18, 0.62, 0.88)
		"GRASS":     return Color(0.32, 0.72, 0.36)
		"LIGHTNING": return Color(0.98, 0.85, 0.10)
		"PSYCHIC":   return Color(0.80, 0.25, 0.72)
		"FIGHTING":  return Color(0.78, 0.52, 0.30)
		"DARKNESS":  return Color(0.22, 0.22, 0.38)
		"METAL":     return Color(0.55, 0.62, 0.70)
		"COLORLESS": return Color(0.72, 0.70, 0.66)
	return Color(0.55, 0.55, 0.55)

func _rarity_badge(rarity: String) -> String:
	match rarity:
		"COMMON":     return "◆ Común"
		"UNCOMMON":   return "◆◆ Poco común"
		"RARE":       return "★ Rara"
		"RARE_HOLO":  return "★★ Rara Holográfica"
		"ULTRA_RARE": return "★★★ Ultra Rara"
	return rarity

func _rarity_color(rarity: String) -> Color:
	match rarity:
		"COMMON":     return Color(0.7, 0.7, 0.7)
		"UNCOMMON":   return Color(0.4, 0.9, 0.4)
		"RARE":       return Color(0.95, 0.85, 0.1)
		"RARE_HOLO":  return Color(0.2, 0.85, 1.0)
		"ULTRA_RARE": return Color(1.0, 0.45, 0.05)
	return Color.WHITE


# ============================================================
# GLARING GAZE
# ============================================================
func check_glaring_gaze(state: Dictionary, my_turn: bool) -> void:
	if state.has("_glaring_gaze_peek") and my_turn:
		if not gaze_popup:
			_build_glaring_gaze(state.get("_glaring_gaze_peek", []))
	else:
		if gaze_popup:
			gaze_popup.queue_free()
			gaze_popup = null

func _build_glaring_gaze(revealed_trainers: Array) -> void:
	gaze_popup = Control.new()
	gaze_popup.set_anchors_preset(Control.PRESET_FULL_RECT)
	gaze_popup.z_index = 300
	board.add_child(gaze_popup)
	var dim = ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.8)
	gaze_popup.add_child(dim)
	var panel_w = min(600.0, vp_size.x - 40)
	var panel_h = 240.0
	var panel   = Panel.new()
	panel.position = Vector2((vp_size.x - panel_w) / 2.0, (vp_size.y - panel_h) / 2.0)
	panel.size     = Vector2(panel_w, panel_h)
	gaze_popup.add_child(panel)
	var lbl = Label.new()
	lbl.text = "👁 GLARING GAZE 👁\nElige un Entrenador de la mano rival para devolverlo a su mazo:"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.position = Vector2(10, 10)
	lbl.size     = Vector2(panel_w - 20, 40)
	lbl.add_theme_color_override("font_color", COLOR_GOLD)
	panel.add_child(lbl)
	var start_x = 20.0
	for t in revealed_trainers:
		var c_id  = t.get("card_id", "")
		var h_idx = t.get("handIndex", 0)
		var btn   = Button.new()
		btn.position = Vector2(start_x, 60)
		btn.size     = Vector2(CARD_W, CARD_H)
		var card_inst = CardDatabase.create_card_instance(c_id)
		card_inst.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(card_inst)
		btn.pressed.connect(func():
			gaze_popup.queue_free()
			gaze_popup = null
			emit_signal("glaring_gaze_resolved", h_idx)
		)
		panel.add_child(btn)
		start_x += CARD_W + 10


# ============================================================
# GAME OVER
# ============================================================
func show_game_over_screen(message: String, won: bool) -> void:
	var overlay = Control.new()
	overlay.name = "GameOverOverlay"
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 500
	board.add_child(overlay)
	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.0, 0.0, 0.0, 0.0)
	overlay.add_child(bg)
	var panel_w = min(520.0, vp_size.x - 60)
	var panel_h = 260.0
	var panel   = Panel.new()
	panel.name     = "GameOverPanel"
	panel.position = Vector2((vp_size.x - panel_w) / 2.0, (vp_size.y - panel_h) / 2.0)
	panel.size     = Vector2(panel_w, panel_h)
	panel.z_index  = 1
	var pstyle = StyleBoxFlat.new()
	pstyle.bg_color = Color(0.04, 0.06, 0.05, 0.98)
	pstyle.border_color = COLOR_GOLD if won else Color(0.75, 0.22, 0.22)
	pstyle.shadow_color = Color(0.85, 0.72, 0.30, 0.45) if won else Color(0.75, 0.20, 0.20, 0.40)
	pstyle.border_width_left = 3; pstyle.border_width_right  = 3
	pstyle.border_width_top  = 3; pstyle.border_width_bottom = 3
	pstyle.corner_radius_top_left    = 18; pstyle.corner_radius_top_right    = 18
	pstyle.corner_radius_bottom_left = 18; pstyle.corner_radius_bottom_right = 18
	pstyle.shadow_size = 28
	panel.add_theme_stylebox_override("panel", pstyle)
	overlay.add_child(panel)
	var emoji_lbl = Label.new()
	emoji_lbl.text = "🏆" if won else "💀"
	emoji_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	emoji_lbl.position = Vector2(0, 28)
	emoji_lbl.size     = Vector2(panel_w, 56)
	emoji_lbl.add_theme_font_size_override("font_size", 48)
	panel.add_child(emoji_lbl)
	var over_lbl = Label.new()
	over_lbl.text = message
	over_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	over_lbl.position = Vector2(0, 90)
	over_lbl.size     = Vector2(panel_w, 52)
	over_lbl.add_theme_font_size_override("font_size", 36)
	over_lbl.add_theme_color_override("font_color", COLOR_GOLD if won else Color(0.90, 0.32, 0.32))
	panel.add_child(over_lbl)
	var sep = ColorRect.new()
	sep.color    = (COLOR_GOLD if won else Color(0.75, 0.22, 0.22)) * Color(1,1,1,0.35)
	sep.position = Vector2(panel_w * 0.15, 150)
	sep.size     = Vector2(panel_w * 0.70, 1)
	panel.add_child(sep)
	var menu_btn = Button.new()
	menu_btn.text     = "🏠  Volver al Menú Principal"
	menu_btn.position = Vector2((panel_w - 280) / 2.0, 168)
	menu_btn.size     = Vector2(280, 50)
	menu_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var s_normal = StyleBoxFlat.new()
	s_normal.bg_color     = Color(0.08, 0.18, 0.10, 0.95) if won else Color(0.18, 0.06, 0.06, 0.95)
	s_normal.border_color = COLOR_GOLD if won else Color(0.75, 0.22, 0.22)
	s_normal.border_width_left = 2; s_normal.border_width_right  = 2
	s_normal.border_width_top  = 2; s_normal.border_width_bottom = 2
	s_normal.corner_radius_top_left    = 10; s_normal.corner_radius_top_right    = 10
	s_normal.corner_radius_bottom_left = 10; s_normal.corner_radius_bottom_right = 10
	s_normal.shadow_color = Color(0,0,0,0.4)
	s_normal.shadow_size  = 6
	menu_btn.add_theme_stylebox_override("normal", s_normal)
	var s_hover = StyleBoxFlat.new()
	s_hover.bg_color     = Color(0.15, 0.35, 0.18, 0.98) if won else Color(0.32, 0.10, 0.10, 0.98)
	s_hover.border_color = COLOR_GOLD if won else Color(0.95, 0.35, 0.35)
	s_hover.border_width_left = 2; s_hover.border_width_right  = 2
	s_hover.border_width_top  = 2; s_hover.border_width_bottom = 2
	s_hover.corner_radius_top_left    = 10; s_hover.corner_radius_top_right    = 10
	s_hover.corner_radius_bottom_left = 10; s_hover.corner_radius_bottom_right = 10
	s_hover.shadow_color = (COLOR_GOLD if won else Color(0.9, 0.3, 0.3)) * Color(1,1,1,0.5)
	s_hover.shadow_size  = 12
	menu_btn.add_theme_stylebox_override("hover", s_hover)
	menu_btn.add_theme_color_override("font_color", COLOR_GOLD if won else Color(0.95, 0.65, 0.65))
	menu_btn.add_theme_font_size_override("font_size", 15)
	menu_btn.pressed.connect(func(): emit_signal("game_over_closed"))
	panel.add_child(menu_btn)
	var hint_lbl = Label.new()
	hint_lbl.text = "o haz clic en cualquier parte"
	hint_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_lbl.position = Vector2(0, 225)
	hint_lbl.size     = Vector2(panel_w, 18)
	hint_lbl.add_theme_font_size_override("font_size", 10)
	hint_lbl.add_theme_color_override("font_color", Color(0.45, 0.45, 0.40, 0.7))
	panel.add_child(hint_lbl)
	var click_catcher = Button.new()
	click_catcher.set_anchors_preset(Control.PRESET_FULL_RECT)
	click_catcher.flat    = true
	click_catcher.z_index = 0
	click_catcher.pressed.connect(func(): emit_signal("game_over_closed"))
	overlay.add_child(click_catcher)
	bg.color       = Color(0, 0, 0, 0)
	panel.scale    = Vector2(0.80, 0.80)
	panel.modulate = Color(1, 1, 1, 0.0)
	var tw = board.create_tween()
	tw.set_parallel(true)
	tw.tween_property(bg,    "color",      Color(0, 0, 0, 0.78), 0.30)
	tw.tween_property(panel, "scale",      Vector2.ONE,          0.30).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(panel, "modulate:a", 1.0,                  0.22)
	var pulse_tw = menu_btn.create_tween().set_loops()
	pulse_tw.tween_property(menu_btn, "modulate:a", 0.78, 0.7).set_trans(Tween.TRANS_SINE).set_delay(0.5)
	pulse_tw.tween_property(menu_btn, "modulate:a", 1.0,  0.7).set_trans(Tween.TRANS_SINE)
