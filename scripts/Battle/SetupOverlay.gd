extends Node
class_name SetupOverlay

# ============================================================
# SetupOverlay.gd
# Maneja el overlay de fase de preparación (SETUP_PLACE_ACTIVE).
# OverlayManager lo instancia y conecta sus señales.
# ============================================================

signal setup_confirmed()
signal setup_reselect_active()

const CARD_W = 130
const CARD_H = 182

const COLOR_BG          = Color(0.04, 0.06, 0.10, 0.97)
const COLOR_BG2         = Color(0.07, 0.10, 0.16, 1.0)
const COLOR_GOLD        = Color(0.92, 0.78, 0.32)
const COLOR_GOLD_DIM    = Color(0.55, 0.45, 0.18)
const COLOR_TEXT        = Color(0.93, 0.90, 0.80)
const COLOR_GREEN       = Color(0.28, 0.88, 0.48)

var board:    Node2D  = null
var vp_size:  Vector2 = Vector2.ZERO

var _overlay:              Control = null
var _setup_active_card_id: String  = ""
var _setup_active_preview: Control = null


# ============================================================
# SETUP
# ============================================================
func setup(parent_board: Node2D, viewport_size: Vector2) -> void:
	board   = parent_board
	vp_size = viewport_size


# ============================================================
# MOSTRAR
# ============================================================
func show_overlay(state: Dictionary, my_player_id: String) -> void:
	var setup_ready = state.get("setup_ready", {})
	var yo_listo    = setup_ready.get(my_player_id, false)

	if yo_listo:
		if _overlay:
			var btn = _overlay.get_node_or_null("SetupPanel/BtnRow/ConfirmBtn")
			if btn: btn.disabled = true
			var re_btn = _overlay.get_node_or_null("SetupPanel/BtnRow/ReelectBtn")
			if re_btn: re_btn.hide()
			var title = _overlay.get_node_or_null("SetupPanel/TitleLbl")
			if title: title.text = "⏳  Esperando al rival..."
		return

	if _overlay: return
	_setup_active_card_id = ""

	_overlay = Control.new()
	_overlay.name = "SetupOverlay"
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.z_index = 50
	board.add_child(_overlay)

	var dim = ColorRect.new()
	dim.name = "Dim"
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0)
	_overlay.add_child(dim)

	var panel_w = min(820.0, vp_size.x - 40)
	var panel_h = 320.0
	var panel   = Panel.new()
	panel.name     = "SetupPanel"
	panel.position = Vector2((vp_size.x - panel_w) / 2.0, (vp_size.y - panel_h) / 2.0)
	panel.size     = Vector2(panel_w, panel_h)
	panel.add_theme_stylebox_override("panel",
		_make_shadow_style(COLOR_BG, COLOR_GOLD, 18, 2,
			Color(COLOR_GOLD.r, COLOR_GOLD.g, COLOR_GOLD.b, 0.30), 22))
	_overlay.add_child(panel)

	var header_bg = Panel.new()
	header_bg.position = Vector2(0, 0)
	header_bg.size     = Vector2(panel_w, 58)
	header_bg.add_theme_stylebox_override("panel",
		_make_panel_style(COLOR_BG2, Color(0,0,0,0), 18))
	panel.add_child(header_bg)

	var title_lbl = Label.new()
	title_lbl.name = "TitleLbl"
	title_lbl.text = "⚔  FASE DE PREPARACIÓN"
	title_lbl.position = Vector2(0, 16)
	title_lbl.size     = Vector2(panel_w, 30)
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 20)
	title_lbl.add_theme_color_override("font_color", COLOR_GOLD)
	panel.add_child(title_lbl)

	var sep_top = ColorRect.new()
	sep_top.color    = Color(COLOR_GOLD.r, COLOR_GOLD.g, COLOR_GOLD.b, 0.22)
	sep_top.position = Vector2(0, 58)
	sep_top.size     = Vector2(panel_w, 1)
	panel.add_child(sep_top)

	var content_x = 24.0
	var content_y = 74.0
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
	active_tag.add_theme_color_override("font_color", Color(COLOR_GOLD.r, COLOR_GOLD.g, COLOR_GOLD.b, 0.55))
	panel.add_child(active_tag)

	var preview_bg = Panel.new()
	preview_bg.name     = "PreviewBg"
	preview_bg.position = Vector2(content_x, content_y)
	preview_bg.size     = Vector2(preview_w, preview_h)
	preview_bg.add_theme_stylebox_override("panel",
		_make_panel_style(Color(0.08, 0.12, 0.10, 0.9),
			Color(COLOR_GOLD.r, COLOR_GOLD.g, COLOR_GOLD.b, 0.25), 10, 1))
	panel.add_child(preview_bg)

	var placeholder_lbl = Label.new()
	placeholder_lbl.name = "PlaceholderLbl"
	placeholder_lbl.text = "?\nActivo"
	placeholder_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	placeholder_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	placeholder_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	placeholder_lbl.add_theme_font_size_override("font_size", 22)
	placeholder_lbl.add_theme_color_override("font_color", Color(COLOR_GOLD.r, COLOR_GOLD.g, COLOR_GOLD.b, 0.25))
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
	chosen_lbl.add_theme_color_override("font_color", COLOR_GREEN)
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
	bench_hint.add_theme_color_override("font_color", Color(0.50, 0.50, 0.42, 0.50))
	panel.add_child(bench_hint)

	var dots_y = content_y + 144.0
	for i in range(5):
		var slot_dot = Panel.new()
		slot_dot.name     = "BenchDot%d" % i
		slot_dot.position = Vector2(info_x + i * 26.0, dots_y)
		slot_dot.size     = Vector2(20, 20)
		slot_dot.add_theme_stylebox_override("panel",
			_make_panel_style(Color(0.10, 0.16, 0.12, 0.8),
				Color(COLOR_GOLD.r, COLOR_GOLD.g, COLOR_GOLD.b, 0.15), 4, 1))
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

	var confirm_btn = _build_confirm_button()
	confirm_btn.name     = "ConfirmBtn"
	confirm_btn.disabled = true
	confirm_btn.pressed.connect(func(): emit_signal("setup_confirmed"))
	btn_row.add_child(confirm_btn)

	panel.position.y += 40
	panel.modulate.a  = 0.0
	var tw = board.create_tween()
	tw.set_parallel(true)
	tw.tween_property(dim,   "color",      Color(0, 0, 0, 0.75), 0.25)
	tw.tween_property(panel, "modulate:a", 1.0,                  0.25)
	tw.tween_property(panel, "position:y", panel.position.y - 40, 0.28) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


# ============================================================
# OCULTAR
# ============================================================
func hide_overlay() -> void:
	if _overlay:
		_overlay.queue_free()
		_overlay = null
	_setup_active_card_id = ""
	_setup_active_preview = null


# ============================================================
# ACTUALIZAR ESTADO
# ============================================================
func update_status(state: Dictionary) -> void:
	if not _overlay: return
	var my_data     = state.get("my", {})
	var has_active  = my_data.get("active") != null
	var bench_list  = my_data.get("bench", [])
	var bench_count = bench_list.filter(func(p): return p != null).size()
	var active_data = my_data.get("active", null)

	var preview_bg = _overlay.get_node_or_null("SetupPanel/PreviewBg")
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
			tw.tween_property(card_inst, "scale",      Vector2(1.0, 1.0), 0.22) \
				.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			preview_bg.add_theme_stylebox_override("panel",
				_make_shadow_style(Color(0.08, 0.12, 0.10, 0.9), COLOR_GOLD, 10, 2,
					Color(COLOR_GOLD.r, COLOR_GOLD.g, COLOR_GOLD.b, 0.45), 14))

	var instr_lbl = _overlay.get_node_or_null("SetupPanel/InstrLbl")
	if instr_lbl:
		if not has_active:
			instr_lbl.text = "Haz clic en un Pokémon Básico\nde tu mano para el Activo"
			instr_lbl.add_theme_color_override("font_color", Color(0.90, 0.85, 0.65))
		elif bench_count == 0:
			instr_lbl.text = "¡Activo listo!\nAgrega Pokémon al Banco o confirma"
			instr_lbl.add_theme_color_override("font_color", COLOR_GREEN)
		else:
			instr_lbl.text = "¡Todo listo!\nConfirma o agrega más al Banco"
			instr_lbl.add_theme_color_override("font_color", COLOR_GREEN)

	var chosen_lbl = _overlay.get_node_or_null("SetupPanel/ChosenLbl")
	if chosen_lbl:
		if has_active and active_data != null:
			var cdata = CardDatabase.get_card(active_data.get("card_id", ""))
			chosen_lbl.text = "✓  %s" % cdata.get("name", "Pokémon elegido")
		else:
			chosen_lbl.text = ""

	var bench_lbl = _overlay.get_node_or_null("SetupPanel/BenchLbl")
	if bench_lbl:
		if has_active:
			bench_lbl.text = "Banco: %d / 5 Pokémon" % bench_count
			bench_lbl.add_theme_color_override("font_color",
				COLOR_GREEN if bench_count > 0 else Color(0.55, 0.55, 0.45, 0.70))
		else:
			bench_lbl.text = ""

	var panel_node = _overlay.get_node_or_null("SetupPanel")
	if panel_node:
		for i in range(5):
			var dot = panel_node.get_node_or_null("BenchDot%d" % i)
			if dot:
				var filled = i < bench_count
				dot.add_theme_stylebox_override("panel",
					_make_panel_style(
						Color(0.30, 0.78, 0.38, 0.85) if filled else Color(0.10, 0.16, 0.12, 0.8),
						COLOR_GOLD if filled else Color(COLOR_GOLD.r, COLOR_GOLD.g, COLOR_GOLD.b, 0.18),
						4, 1))

	var reelect_btn = _overlay.get_node_or_null("SetupPanel/BtnRow/ReelectBtn")
	if reelect_btn:
		if has_active and not reelect_btn.visible:
			reelect_btn.modulate.a = 0.0
			reelect_btn.show()
			reelect_btn.create_tween().tween_property(reelect_btn, "modulate:a", 1.0, 0.20)
		elif not has_active and reelect_btn.visible:
			var tw = reelect_btn.create_tween()
			tw.tween_property(reelect_btn, "modulate:a", 0.0, 0.15)
			tw.tween_callback(func(): reelect_btn.hide())

	var confirm_btn = _overlay.get_node_or_null("SetupPanel/BtnRow/ConfirmBtn")
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


func is_active() -> bool:
	return _overlay != null


# ============================================================
# REELECT
# ============================================================
func _on_reelect_pressed() -> void:
	if not _overlay: return
	var preview_bg = _overlay.get_node_or_null("SetupPanel/PreviewBg")
	if preview_bg:
		if _setup_active_preview and is_instance_valid(_setup_active_preview):
			_setup_active_preview.queue_free()
			_setup_active_preview = null
		preview_bg.add_theme_stylebox_override("panel",
			_make_panel_style(Color(0.08, 0.12, 0.10, 0.9),
				Color(COLOR_GOLD.r, COLOR_GOLD.g, COLOR_GOLD.b, 0.25), 10, 1))
		var ph = preview_bg.get_node_or_null("PlaceholderLbl")
		if ph:
			ph.show()
			ph.modulate.a = 0.0
			ph.create_tween().tween_property(ph, "modulate:a", 1.0, 0.20)

	var chosen_lbl = _overlay.get_node_or_null("SetupPanel/ChosenLbl")
	if chosen_lbl: chosen_lbl.text = ""

	var instr_lbl = _overlay.get_node_or_null("SetupPanel/InstrLbl")
	if instr_lbl:
		instr_lbl.text = "Haz clic en un Pokémon Básico\nde tu mano para el Activo"
		instr_lbl.add_theme_color_override("font_color", Color(0.90, 0.85, 0.65))

	var bench_lbl = _overlay.get_node_or_null("SetupPanel/BenchLbl")
	if bench_lbl: bench_lbl.text = ""

	var reelect_btn = _overlay.get_node_or_null("SetupPanel/BtnRow/ReelectBtn")
	if reelect_btn:
		var tw = reelect_btn.create_tween()
		tw.tween_property(reelect_btn, "modulate:a", 0.0, 0.15)
		tw.tween_callback(func(): reelect_btn.hide())

	var confirm_btn = _overlay.get_node_or_null("SetupPanel/BtnRow/ConfirmBtn")
	if confirm_btn:
		confirm_btn.disabled = true
		var pulse = confirm_btn.get_node_or_null("PulseTween")
		if pulse: pulse.queue_free()
		confirm_btn.modulate.a = 1.0

	_setup_active_card_id = ""
	emit_signal("setup_reselect_active")


# ============================================================
# BUILDERS
# ============================================================
func _build_reelect_button() -> Button:
	var btn = Button.new()
	btn.text = "↩  Elegir de nuevo"
	btn.custom_minimum_size = Vector2(160, 44)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.add_theme_stylebox_override("normal",
		_make_shadow_style(Color(0.18, 0.08, 0.06, 0.95), Color(0.80, 0.32, 0.20), 8, 2,
			Color(0.8, 0.3, 0.2, 0.2), 5))
	btn.add_theme_stylebox_override("hover",
		_make_shadow_style(Color(0.35, 0.12, 0.08, 0.98), Color(0.95, 0.42, 0.25), 8, 2,
			Color(0.9, 0.4, 0.2, 0.4), 8))
	btn.add_theme_color_override("font_color", Color(0.95, 0.62, 0.45))
	btn.add_theme_font_size_override("font_size", 13)
	return btn


func _build_confirm_button() -> Button:
	var btn = Button.new()
	btn.text = "✓  Confirmar"
	btn.custom_minimum_size = Vector2(160, 44)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.add_theme_stylebox_override("normal",
		_make_shadow_style(Color(0.08, 0.20, 0.10, 0.95), COLOR_GOLD, 8, 2,
			Color(COLOR_GOLD.r, COLOR_GOLD.g, COLOR_GOLD.b, 0.25), 6))
	btn.add_theme_stylebox_override("hover",
		_make_shadow_style(Color(0.15, 0.38, 0.18, 0.98), COLOR_GOLD, 8, 2,
			Color(COLOR_GOLD.r, COLOR_GOLD.g, COLOR_GOLD.b, 0.50), 10))
	var s_d = _make_panel_style(Color(0.06, 0.06, 0.06, 0.40), Color(0.28, 0.25, 0.15, 0.28), 8, 2)
	btn.add_theme_stylebox_override("disabled", s_d)
	btn.add_theme_color_override("font_color",          COLOR_GOLD)
	btn.add_theme_color_override("font_disabled_color", Color(0.38, 0.35, 0.22, 0.35))
	btn.add_theme_font_size_override("font_size", 14)
	return btn


# ============================================================
# HELPERS DE ESTILO (locales, funciones puras)
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
