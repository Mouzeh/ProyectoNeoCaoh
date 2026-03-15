extends CanvasLayer
class_name CardPickerModal

# ─── SEÑALES ────────────────────────────────────────────────
signal cards_selected(selected_indices: Array)
signal cancelled()

# ─── VARIABLES DE ESTADO ────────────────────────────────────
var _cards_array: Array = []
var _min_picks: int = 1
var _max_picks: int = 1
var _selected_indices: Array = []

# ─── REFERENCIAS A NODOS (Para evitar crashes de rutas) ──────
var _title_label: Label
var _confirm_btn: Button
var _grid: GridContainer

# ============================================================
# CONSTRUCTOR DINÁMICO
# ============================================================
func _init() -> void:
	layer = 100 

	# 1. Fondo oscuro
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.85)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# 2. Panel Central
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(850, 600)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.12, 0.15, 1)
	style.border_color = Color(0.85, 0.72, 0.30)
	style.border_width_left = 3; style.border_width_right = 3
	style.border_width_top = 3; style.border_width_bottom = 3
	style.corner_radius_top_left = 8; style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8; style.corner_radius_bottom_right = 8
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)

	# 3. Contenedor Vertical
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 15)
	vbox.offset_left = 20; vbox.offset_top = 20
	vbox.offset_right = -20; vbox.offset_bottom = -20
	panel.add_child(vbox)

	# 4. Título (Guardamos referencia directa)
	_title_label = Label.new()
	_title_label.text = "Selecciona cartas"
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 24)
	_title_label.add_theme_color_override("font_color", Color(0.95, 0.85, 0.45))
	vbox.add_child(_title_label)

	# 5. Área de Scroll
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)

	# 6. Grilla (Guardamos referencia directa)
	_grid = GridContainer.new()
	_grid.columns = 5 
	_grid.add_theme_constant_override("h_separation", 20)
	_grid.add_theme_constant_override("v_separation", 20)
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_grid)

	# 7. Botones Inferiores
	var hbox = HFlowContainer.new() # Usamos Flow para que se acomoden mejor
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("h_separation", 40)
	vbox.add_child(hbox)

	var cancel_btn = Button.new()
	cancel_btn.text = "Cancelar"
	cancel_btn.custom_minimum_size = Vector2(150, 40)
	cancel_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	cancel_btn.pressed.connect(_on_cancel)
	hbox.add_child(cancel_btn)

	_confirm_btn = Button.new()
	_confirm_btn.text = "Confirmar"
	_confirm_btn.custom_minimum_size = Vector2(150, 40)
	_confirm_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_confirm_btn.pressed.connect(_on_confirm)
	hbox.add_child(_confirm_btn)

# ============================================================
# SETUP PÚBLICO
# ============================================================
func setup(title_text: String, cards: Array, min_picks: int = 1, max_picks: int = 1) -> void:
	# Actualizamos el Label usando la referencia directa
	if _title_label:
		_title_label.text = title_text
	
	_cards_array = cards
	_min_picks = min_picks
	_max_picks = max_picks
	_selected_indices.clear()

	# Limpiamos la grilla antes de poblar por si se llama dos veces
	if _grid:
		for child in _grid.get_children():
			child.queue_free()
		
		_populate_grid()
		_update_confirm_btn()

func _populate_grid() -> void:
	var target_w = 130.0 * 0.9 
	var target_h = 182.0 * 0.9

	for i in range(_cards_array.size()):
		var card_data = _cards_array[i]
		var card_id = card_data if typeof(card_data) == TYPE_STRING else str(card_data.get("card_id", ""))
		
		var wrapper = Control.new()
		wrapper.custom_minimum_size = Vector2(target_w, target_h)
		
		var card_inst = CardDatabase.create_card_instance(card_id)
		card_inst.is_draggable = false
		card_inst.scale = Vector2(0.9, 0.9)
		card_inst.mouse_filter = Control.MOUSE_FILTER_IGNORE
		wrapper.add_child(card_inst)
		
		var highlight = ColorRect.new()
		highlight.name = "Highlight"
		highlight.color = Color(0.2, 0.9, 0.2, 0.4)
		highlight.set_anchors_preset(Control.PRESET_FULL_RECT)
		highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
		highlight.visible = false
		wrapper.add_child(highlight)

		var btn = Button.new()
		btn.set_anchors_preset(Control.PRESET_FULL_RECT)
		btn.flat = true
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		# Usamos bind para pasar los datos correctos a la función
		btn.pressed.connect(_on_card_clicked.bind(i, wrapper))
		wrapper.add_child(btn)

		_grid.add_child(wrapper)

# ============================================================
# LÓGICA DE SELECCIÓN
# ============================================================
func _on_card_clicked(idx: int, wrapper: Control) -> void:
	var hl = wrapper.get_node_or_null("Highlight")
	
	if _selected_indices.has(idx):
		_selected_indices.erase(idx)
		if hl: hl.visible = false
	else:
		if _selected_indices.size() >= _max_picks:
			if _max_picks == 1:
				# Auto-reemplazo si solo se permite una
				var old_idx = _selected_indices[0]
				var old_wrapper = _grid.get_child(old_idx)
				if old_wrapper:
					var old_hl = old_wrapper.get_node_or_null("Highlight")
					if old_hl: old_hl.visible = false
				
				_selected_indices.clear()
				_selected_indices.append(idx)
				if hl: hl.visible = true
			else:
				return # Ya alcanzó el máximo
		else:
			_selected_indices.append(idx)
			if hl: hl.visible = true

	_update_confirm_btn()

func _update_confirm_btn() -> void:
	if _confirm_btn:
		_confirm_btn.disabled = _selected_indices.size() < _min_picks

func _on_confirm() -> void:
	emit_signal("cards_selected", _selected_indices)
	queue_free()

func _on_cancel() -> void:
	emit_signal("cancelled")
	queue_free()
