extends Node
class_name OverlayManager

# ============================================================
# OverlayManager.gd — El gestor de modales
# Todo lo que aparece encima del tablero pasa por aquí.
# Delega setup y discard viewer a módulos dedicados.
# ============================================================

signal setup_confirmed()
signal setup_reselect_active()
signal promote_selected(bench_index)
signal action_zoom_selected(action_type, index)
signal glaring_gaze_resolved(hand_index)
signal game_over_closed()
signal bench_power_requested(bench_index: int, power_name: String)

# ─── CONSTANTES ─────────────────────────────────────────────
const CARD_W      = 130
const CARD_H      = 182

const COLOR_BG          = Color(0.04, 0.06, 0.10, 0.97)
const COLOR_BG2         = Color(0.07, 0.10, 0.16, 1.0)
const COLOR_GOLD        = Color(0.92, 0.78, 0.32)
const COLOR_GOLD_DIM    = Color(0.55, 0.45, 0.18)
const COLOR_GOLD_GLOW   = Color(0.92, 0.78, 0.32, 0.18)
const COLOR_TEXT        = Color(0.93, 0.90, 0.80)
const COLOR_TEXT_DIM    = Color(0.60, 0.58, 0.52)
const COLOR_RED         = Color(0.90, 0.28, 0.28)
const COLOR_GREEN       = Color(0.28, 0.88, 0.48)
const COLOR_BORDER_GOLD = Color(0.92, 0.78, 0.32, 0.55)

const PATH_TYPES  = "res://assets/imagen/TypesIcons/"
const PATH_TOKENS = "res://assets/imagen/tokens/"

# ─── REFERENCIAS ────────────────────────────────────────────
var board:   Node2D  = null
var vp_size: Vector2

# ─── MÓDULOS DELEGADOS ──────────────────────────────────────
var _setup_overlay:  SetupOverlay  = null
var _discard_viewer: DiscardViewer = null

# ─── ESTADO DE OVERLAYS ─────────────────────────────────────
var promote_popup:       Control = null
var zoom_overlay:        Control = null
var action_zoom_overlay: Control = null
var gaze_popup:          Control = null
var bench_power_popup:   Control = null
var zoom_active:         bool    = false

# ─── PROPIEDADES DELEGADAS (para compatibilidad con BattleBoard) ─
var discard_viewer: Control:
	get: return _discard_viewer._viewer if _discard_viewer else null


func setup(parent_board: Node2D) -> void:
	board   = parent_board
	vp_size = board.get_viewport().get_visible_rect().size

	_setup_overlay = SetupOverlay.new()
	board.add_child(_setup_overlay)
	_setup_overlay.setup(board, vp_size)
	_setup_overlay.setup_confirmed.connect(func(): emit_signal("setup_confirmed"))
	_setup_overlay.setup_reselect_active.connect(func(): emit_signal("setup_reselect_active"))

	_discard_viewer = DiscardViewer.new()
	board.add_child(_discard_viewer)
	_discard_viewer.setup(board, vp_size)


# ============================================================
# SETUP OVERLAY — delegado
# ============================================================
func show_setup_overlay(state: Dictionary, my_player_id: String) -> void:
	_setup_overlay.show_overlay(state, my_player_id)

func hide_setup_overlay() -> void:
	_setup_overlay.hide_overlay()

func update_setup_status(state: Dictionary) -> void:
	_setup_overlay.update_status(state)


# ============================================================
# DISCARD VIEWER — delegado
# ============================================================
func show_discard_viewer(discard_cards: Array, title: String = "Descarte") -> void:
	_discard_viewer.show_viewer(discard_cards, title)

func close_discard_viewer() -> void:
	_discard_viewer.close_viewer()


# ============================================================
# HELPER: expandir cost (Dict o Array) a lista plana de tipos
# ============================================================
func _expand_cost(cost) -> Array:
	var result = []
	if cost is Array:
		for entry in cost:
			result.append(str(entry).to_upper())
	elif cost is Dictionary:
		for raw_key in cost:
			var e_type = str(raw_key).to_upper()
			var count  = int(cost[raw_key])
			for _j in range(count):
				result.append(e_type)
	return result


# ============================================================
# HELPERS DE ESTILO
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


# ============================================================
# HELPER: detectar energía especial
# ============================================================
func _is_special_energy(card_id: String) -> bool:
	const SPECIAL_IDS = [
		"darkness_energy", "metal_energy", "recycle_energy",
		"lc_full-heal-energy", "lc_potion-energy",
	]
	if card_id in SPECIAL_IDS: return true
	var cdata = CardDatabase.get_card(card_id)
	if cdata.is_empty() or cdata.get("type", "") != "ENERGY": return false
	var effect = cdata.get("effect", "")
	return effect != "" and effect != null


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
	dim.color = Color(0, 0, 0, 0.85)
	promote_popup.add_child(dim)

	var valid_bench = bench.filter(func(p): return p != null)
	var card_cols   = min(valid_bench.size(), 5)
	var panel_w     = max(360.0, card_cols * (CARD_W + 20) + 60.0)
	var panel_h     = CARD_H + 140.0
	var panel       = Panel.new()
	panel.name     = "PromotePanel"
	panel.position = Vector2((vp_size.x - panel_w) / 2.0, (vp_size.y - panel_h) / 2.0)
	panel.size     = Vector2(panel_w, panel_h)
	panel.add_theme_stylebox_override("panel",
		_make_shadow_style(Color(0.05, 0.08, 0.06, 0.97), Color(0.9, 0.3, 0.3), 14, 2,
			Color(0.9, 0.2, 0.2, 0.45), 22))
	promote_popup.add_child(panel)

	var title = Label.new()
	title.text     = "☠  Tu Pokémon activo fue KO"
	title.position = Vector2(10, 14)
	title.size     = Vector2(panel_w - 20, 28)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.95, 0.35, 0.35))
	panel.add_child(title)

	var subtitle = Label.new()
	subtitle.text     = "Elige quién pasa al frente"
	subtitle.position = Vector2(10, 44)
	subtitle.size     = Vector2(panel_w - 20, 22)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 13)
	subtitle.add_theme_color_override("font_color", COLOR_GOLD)
	panel.add_child(subtitle)

	var sep = ColorRect.new()
	sep.color    = Color(COLOR_RED.r, COLOR_RED.g, COLOR_RED.b, 0.20)
	sep.position = Vector2(panel_w * 0.1, 70)
	sep.size     = Vector2(panel_w * 0.8, 1)
	panel.add_child(sep)

	var cards_total_w = card_cols * (CARD_W + 16) - 16
	var cards_start_x = (panel_w - cards_total_w) / 2.0
	var bench_col     = 0

	for i in range(bench.size()):
		var poke = bench[i]
		if poke == null: continue
		var card_id = poke.get("card_id", "")
		var slot    = PanelContainer.new()
		slot.position = Vector2(cards_start_x + bench_col * (CARD_W + 16), 78)
		slot.size     = Vector2(CARD_W, CARD_H + 8)
		var slot_style = _make_panel_style(Color(0.10, 0.15, 0.12, 0.8), COLOR_GOLD_DIM, 8, 1)
		slot.add_theme_stylebox_override("panel", slot_style)
		if not card_id.is_empty() and card_id != "face_down":
			var card_inst = CardDatabase.create_card_instance(card_id)
			card_inst.mouse_filter = Control.MOUSE_FILTER_IGNORE
			slot.add_child(card_inst)
		var btn = Button.new()
		btn.set_anchors_preset(Control.PRESET_FULL_RECT)
		btn.flat = true
		var hover_s = _make_panel_style(Color(COLOR_GOLD.r, COLOR_GOLD.g, COLOR_GOLD.b, 0.22), COLOR_GOLD, 8, 1)
		btn.add_theme_stylebox_override("hover", hover_s)
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var bench_index = i
		btn.pressed.connect(func():
			slot.create_tween().tween_property(slot, "scale", Vector2(1.12, 1.12), 0.08) \
				.set_trans(Tween.TRANS_BACK)
			await slot.get_tree().create_timer(0.1).timeout
			hide_promote_popup()
			emit_signal("promote_selected", bench_index)
		)
		btn.mouse_entered.connect(func():
			slot.create_tween().tween_property(slot, "scale", Vector2(1.06, 1.06), 0.10)
			slot_style.border_color = COLOR_GOLD
			slot.add_theme_stylebox_override("panel", slot_style)
		)
		btn.mouse_exited.connect(func():
			slot.create_tween().tween_property(slot, "scale", Vector2(1.0, 1.0), 0.10)
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
	zoom_overlay.size    = vp_size
	zoom_overlay.z_index = 350
	board.add_child(zoom_overlay)

	var dim = ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.0, 0.02, 0.05, 0.90)
	zoom_overlay.add_child(dim)

	var click_btn = Button.new()
	click_btn.set_anchors_preset(Control.PRESET_FULL_RECT)
	click_btn.flat = true
	click_btn.pressed.connect(close_zoom)
	zoom_overlay.add_child(click_btn)

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
	hint.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 0.7))
	center_pivot.add_child(hint)

	var start_scale = zoom_scale * 0.7
	card_instance.scale    = Vector2(start_scale, start_scale)
	card_instance.position = Vector2(
		(vp_size.x - (CARD_W * start_scale)) / 2.0,
		(vp_size.y - (CARD_H * start_scale)) / 2.0 - 30.0)
	center_pivot.modulate.a = 0.0

	var tw = center_pivot.create_tween()
	tw.set_parallel(true)
	tw.tween_property(card_instance, "scale",      Vector2(zoom_scale, zoom_scale), 0.20).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(card_instance, "position",   Vector2(card_x, card_y),         0.20).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(center_pivot,  "modulate:a", 1.0,                             0.15)
	zoom_active = true


func close_zoom() -> void:
	if zoom_overlay:
		var overlay_to_free = zoom_overlay
		zoom_overlay = null
		var tw = overlay_to_free.create_tween()
		tw.set_parallel(true)
		tw.tween_property(overlay_to_free, "modulate:a", 0.0, 0.12)
		tw.tween_property(overlay_to_free, "scale", Vector2(0.96, 0.96), 0.12)
		tw.chain().tween_callback(overlay_to_free.queue_free)
	zoom_active = false


# ============================================================
# TOKENS EN ZOOM
# ============================================================
func _add_zoom_tokens(card_node: Control, pokemon_data: Dictionary, zoom_scale: float) -> void:
	var overlay = Control.new()
	overlay.name          = "ZoomTokenOverlay"
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter  = Control.MOUSE_FILTER_IGNORE
	overlay.clip_contents = false
	card_node.add_child(overlay)

	var dmg: int = int(pokemon_data.get("damage_counters", 0))
	if dmg > 0:
		var fifties: int = dmg / 5
		var tens:    int = dmg % 5
		var ox: float    = 8.0
		var oy: float    = CARD_H / 2.0 - 20.0
		var tok_size     = 36.0
		for _i in range(fifties):
			_spawn_zoom_token(overlay, PATH_TOKENS + "damage_50.png", "50", Vector2(ox, oy), tok_size)
			ox += tok_size + 4.0
		for _i in range(tens):
			_spawn_zoom_token(overlay, PATH_TOKENS + "damage_10.png", "10", Vector2(ox, oy), tok_size)
			ox += tok_size + 4.0

	const TOKEN_FILES = {
		"POISONED": "poison.png", "BURNED": "burn.png",
		"ASLEEP": "asleep.png",   "PARALYZED": "paralyzed.png", "CONFUSED": "confused.png",
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
	var tool             = pokemon_data.get("tool", null)
	var icon_size := 28.0
	var gap       := 4.0
	var start_x   := -18.0
	var start_y   := 10.0

	for i in range(energies.size()):
		var energy_entry = energies[i]
		var card_id_e: String = energy_entry if energy_entry is String else str(energy_entry.get("card_id", ""))
		var is_special := _is_special_energy(card_id_e)
		var icon_tx: Texture2D

		if is_special:
			var sp_path = PATH_TYPES + "?.png"
			icon_tx = load(sp_path) if ResourceLoader.exists(sp_path) else null
		else:
			var cdata_e = CardDatabase.get_card(card_id_e)
			var e_type  = str(cdata_e.get("energy_type", "COLORLESS")).to_upper()
			icon_tx = _get_type_icon(e_type)

		var target_y = start_y + i * (icon_size + gap)
		var energy_node: Control

		if icon_tx:
			var icon = TextureRect.new()
			icon.texture      = icon_tx
			icon.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.size         = Vector2(icon_size, icon_size)
			energy_node       = icon
		else:
			var dot = Panel.new()
			dot.size = Vector2(icon_size, icon_size)
			var dot_s = StyleBoxFlat.new()
			dot_s.bg_color = Color(0.72, 0.70, 0.66)
			dot_s.set_corner_radius_all(int(icon_size / 2.0))
			dot_s.anti_aliasing = true
			dot.add_theme_stylebox_override("panel", dot_s)
			energy_node = dot

		if is_special and card_id_e != "":
			energy_node.mouse_filter = Control.MOUSE_FILTER_STOP
			energy_node.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			energy_node.tooltip_text = CardDatabase.get_card(card_id_e).get("name", card_id_e)
			var cid_cap = card_id_e
			energy_node.gui_input.connect(func(ev: InputEvent):
				if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
					close_zoom()
					open_zoom(cid_cap)
			)
		else:
			energy_node.mouse_filter = Control.MOUSE_FILTER_IGNORE

		overlay.add_child(energy_node)
		energy_node.position   = Vector2(start_x, target_y - 25.0)
		energy_node.modulate.a = 0.0
		var tw            = overlay.create_tween()
		var cascade_delay = i * 0.08
		tw.set_parallel(true)
		tw.tween_property(energy_node, "position:y", target_y, 0.3).set_delay(cascade_delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(energy_node, "modulate:a", 1.0,      0.2).set_delay(cascade_delay)

	if tool != null and str(tool) != "" and str(tool) != "null":
		var tool_id   := str(tool)
		var tool_path := PATH_TYPES + "entrenador.png"
		var tool_tex  := load(tool_path) if ResourceLoader.exists(tool_path) else null
		var tool_node: Control

		if tool_tex:
			var icon = TextureRect.new()
			icon.texture      = tool_tex
			icon.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.size         = Vector2(icon_size, icon_size)
			tool_node         = icon
		else:
			var lbl = Label.new()
			lbl.text = "🃏"
			lbl.add_theme_font_size_override("font_size", 20)
			tool_node = lbl

		tool_node.mouse_filter = Control.MOUSE_FILTER_STOP
		tool_node.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		tool_node.tooltip_text = CardDatabase.get_card(tool_id).get("name", tool_id)
		tool_node.position     = Vector2(CARD_W - icon_size - 4, 28.0)
		tool_node.modulate.a   = 0.0
		tool_node.z_index      = 10
		tool_node.gui_input.connect(func(ev: InputEvent):
			if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
				close_zoom()
				open_zoom(tool_id)
		)
		overlay.add_child(tool_node)
		tool_node.create_tween().tween_property(tool_node, "modulate:a", 1.0, 0.20)


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
	dim.color = Color(0.02, 0.03, 0.06, 0.92)
	action_zoom_overlay.add_child(dim)

	var zoom_scale = clamp(min((vp_size.x * 0.36) / CARD_W, (vp_size.y * 0.84) / CARD_H), 1.5, 4.0)
	var card_w     = CARD_W * zoom_scale
	var card_h     = CARD_H * zoom_scale
	var card_pos_x = round(vp_size.x * 0.08 + 20)
	var card_pos_y = round((vp_size.y - card_h) / 2.0)

	var card_inst = CardDatabase.create_card_instance(card_id)
	card_inst.is_draggable = false
	card_inst.is_locked    = true
	card_inst.pivot_offset = Vector2.ZERO
	card_inst.scale        = Vector2(zoom_scale * 0.82, zoom_scale * 0.82)
	card_inst.position     = Vector2(card_pos_x, card_pos_y)
	card_inst.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_inst.modulate.a   = 0.0
	action_zoom_overlay.add_child(card_inst)
	_add_zoom_tokens(card_inst, pokemon_data, zoom_scale)

	var panel_x = card_pos_x + card_w + 32.0
	var panel_w = vp_size.x - panel_x - 32.0
	var panel_h = card_h

	var actions_panel = Panel.new()
	actions_panel.position   = Vector2(panel_x, card_pos_y)
	actions_panel.size       = Vector2(panel_w, panel_h)
	actions_panel.modulate.a = 0.0
	var ap_s = StyleBoxFlat.new()
	ap_s.bg_color     = Color(0.05, 0.07, 0.12, 0.97)
	ap_s.border_color = Color(COLOR_GOLD.r, COLOR_GOLD.g, COLOR_GOLD.b, 0.28)
	ap_s.set_border_width_all(1)
	ap_s.set_corner_radius_all(16)
	ap_s.shadow_color = Color(0, 0, 0, 0.50)
	ap_s.shadow_size  = 18
	actions_panel.add_theme_stylebox_override("panel", ap_s)
	action_zoom_overlay.add_child(actions_panel)

	var HDR_H = 52.0
	var hdr = Panel.new()
	hdr.position = Vector2(0, 0)
	hdr.size     = Vector2(panel_w, HDR_H)
	var hdr_s = StyleBoxFlat.new()
	hdr_s.bg_color = Color(0.08, 0.11, 0.19, 1.0)
	hdr_s.corner_radius_top_left     = 16
	hdr_s.corner_radius_top_right    = 16
	hdr_s.corner_radius_bottom_left  = 0
	hdr_s.corner_radius_bottom_right = 0
	hdr.add_theme_stylebox_override("panel", hdr_s)
	actions_panel.add_child(hdr)

	var poke_type = cdata.get("pokemon_type", "")
	var type_icon = _get_type_icon(poke_type) if poke_type != "" else null
	if type_icon:
		var ttr = TextureRect.new()
		ttr.texture      = type_icon
		ttr.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
		ttr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ttr.size         = Vector2(22, 22)
		ttr.position     = Vector2(14, (HDR_H - 22) / 2.0)
		actions_panel.add_child(ttr)

	var name_lbl = Label.new()
	name_lbl.text     = cdata.get("name", "").to_upper()
	name_lbl.position = Vector2(44, 0)
	name_lbl.size     = Vector2(panel_w - 54, HDR_H)
	name_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 19)
	name_lbl.add_theme_color_override("font_color", COLOR_GOLD)
	actions_panel.add_child(name_lbl)

	var hdr_sep = ColorRect.new()
	hdr_sep.color    = Color(COLOR_GOLD.r, COLOR_GOLD.g, COLOR_GOLD.b, 0.14)
	hdr_sep.position = Vector2(0, HDR_H)
	hdr_sep.size     = Vector2(panel_w, 1)
	actions_panel.add_child(hdr_sep)

	var power     = cdata.get("pokemon_power", null)
	var attacks   = cdata.get("attacks", [])
	var btn_count = attacks.size() + 1
	if power != null: btn_count += 1

	var CLOSE_H   = 36.0
	var PAD_TOP   = 10.0
	var PAD_BOT   = 10.0
	var CLOSE_GAP = 8.0
	var SEP       = 8.0
	var available = panel_h - HDR_H - PAD_TOP - PAD_BOT - CLOSE_H - CLOSE_GAP
	var btn_h     = max(44.0, (available - SEP * (btn_count - 1)) / btn_count)

	var vbox = VBoxContainer.new()
	vbox.position  = Vector2(12, HDR_H + PAD_TOP)
	vbox.size      = Vector2(panel_w - 24, panel_h - HDR_H - PAD_TOP - PAD_BOT - CLOSE_H - CLOSE_GAP)
	vbox.add_theme_constant_override("separation", int(SEP))
	actions_panel.add_child(vbox)

	if power != null:
		var pb = _build_power_ui(power)
		pb.custom_minimum_size = Vector2(panel_w - 24, btn_h)
		vbox.add_child(pb)

	for i in range(attacks.size()):
		var ab = _build_attack_ui(attacks[i], i)
		ab.custom_minimum_size = Vector2(panel_w - 24, btn_h)
		vbox.add_child(ab)

	var rb = _build_retreat_ui(cdata)
	rb.custom_minimum_size = Vector2(panel_w - 24, btn_h)
	vbox.add_child(rb)

	var cancel_btn = _build_cancel_button()
	cancel_btn.position = Vector2(12, panel_h - PAD_BOT - CLOSE_H)
	cancel_btn.size     = Vector2(panel_w - 24, CLOSE_H)
	actions_panel.add_child(cancel_btn)

	var tw = board.create_tween()
	tw.set_parallel(true)
	tw.tween_property(card_inst,     "modulate:a", 1.0,                             0.20)
	tw.tween_property(card_inst,     "scale",      Vector2(zoom_scale, zoom_scale), 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(card_inst,     "position",   Vector2(card_pos_x, card_pos_y), 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(actions_panel, "modulate:a", 1.0,                             0.20).set_delay(0.08)


func close_action_zoom() -> void:
	if action_zoom_overlay:
		var overlay_to_free = action_zoom_overlay
		action_zoom_overlay = null
		var tw = overlay_to_free.create_tween()
		tw.tween_property(overlay_to_free, "modulate:a", 0.0, 0.12)
		tw.tween_callback(overlay_to_free.queue_free)


# ============================================================
# CONSTRUCTORES DE UI (ACTION ZOOM)
# ============================================================
func _build_attack_ui(atk: Dictionary, index: int) -> Control:
	var wrap = Control.new()
	wrap.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var btn = Button.new()
	btn.flat = true
	btn.set_anchors_preset(Control.PRESET_FULL_RECT)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	wrap.add_child(btn)

	var _style_btn_atk = func(s: StyleBoxFlat, hover: bool) -> void:
		s.bg_color     = Color(0.14, 0.19, 0.28, 0.98) if hover else Color(0.09, 0.12, 0.18, 0.95)
		s.border_color = COLOR_GOLD if hover else Color(COLOR_GOLD.r, COLOR_GOLD.g, COLOR_GOLD.b, 0.22)
		s.set_border_width_all(1)
		s.set_corner_radius_all(10)
		if hover: s.shadow_color = Color(COLOR_GOLD.r, COLOR_GOLD.g, COLOR_GOLD.b, 0.18); s.shadow_size = 8
		s.content_margin_left  = 14; s.content_margin_right  = 14
		s.content_margin_top   = 0;  s.content_margin_bottom = 0

	var s_n = StyleBoxFlat.new(); _style_btn_atk.call(s_n, false)
	var s_h = StyleBoxFlat.new(); _style_btn_atk.call(s_h, true)
	btn.add_theme_stylebox_override("normal",  s_n)
	btn.add_theme_stylebox_override("hover",   s_h)
	btn.add_theme_stylebox_override("pressed", s_h)
	btn.add_theme_stylebox_override("focus",   s_n)

	var hbox = HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.alignment    = BoxContainer.ALIGNMENT_CENTER
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_theme_constant_override("separation", 8)
	btn.add_child(hbox)

	var cost_list = _expand_cost(atk.get("cost", {}))
	for e_type in cost_list:
		var icon = TextureRect.new()
		icon.texture             = _get_type_icon(e_type)
		icon.expand_mode         = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode        = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2(26, 26)
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		icon.mouse_filter        = Control.MOUSE_FILTER_IGNORE
		hbox.add_child(icon)

	if cost_list.size() > 0:
		var sp = Control.new(); sp.custom_minimum_size = Vector2(4, 0)
		hbox.add_child(sp)

	var name_lbl = Label.new()
	name_lbl.text                  = atk.get("name", "").to_upper()
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.vertical_alignment    = VERTICAL_ALIGNMENT_CENTER
	name_lbl.mouse_filter          = Control.MOUSE_FILTER_IGNORE
	name_lbl.add_theme_font_size_override("font_size", 16)
	name_lbl.add_theme_color_override("font_color", COLOR_TEXT)
	hbox.add_child(name_lbl)

	var dmg = str(atk.get("damage", ""))
	if dmg != "" and dmg != "0":
		var dmg_lbl = Label.new()
		dmg_lbl.text               = dmg
		dmg_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		dmg_lbl.mouse_filter       = Control.MOUSE_FILTER_IGNORE
		dmg_lbl.add_theme_font_size_override("font_size", 24)
		dmg_lbl.add_theme_color_override("font_color", COLOR_GOLD)
		hbox.add_child(dmg_lbl)

	btn.pressed.connect(func():
		close_action_zoom()
		emit_signal("action_zoom_selected", "ATTACK", index)
	)
	return wrap


func _build_retreat_ui(cdata: Dictionary) -> Control:
	var wrap = Control.new()
	wrap.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var btn = Button.new()
	btn.flat = true
	btn.set_anchors_preset(Control.PRESET_FULL_RECT)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	var s_n = StyleBoxFlat.new()
	s_n.bg_color     = Color(0.07, 0.08, 0.11, 0.90)
	s_n.border_color = Color(0.50, 0.50, 0.55, 0.22)
	s_n.set_border_width_all(1)
	s_n.set_corner_radius_all(10)
	s_n.content_margin_left  = 14
	s_n.content_margin_right = 14
	btn.add_theme_stylebox_override("normal", s_n)
	var s_h = StyleBoxFlat.new()
	s_h.bg_color     = Color(0.12, 0.13, 0.18, 0.98)
	s_h.border_color = Color(0.70, 0.70, 0.75, 0.45)
	s_h.set_border_width_all(1)
	s_h.set_corner_radius_all(10)
	btn.add_theme_stylebox_override("hover",   s_h)
	btn.add_theme_stylebox_override("pressed", s_h)
	btn.add_theme_stylebox_override("focus",   s_n)
	wrap.add_child(btn)

	var hbox = HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.alignment    = BoxContainer.ALIGNMENT_CENTER
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_theme_constant_override("separation", 7)
	btn.add_child(hbox)

	var lbl = Label.new()
	lbl.text                  = "🏃  RETIRAR"
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.vertical_alignment    = VERTICAL_ALIGNMENT_CENTER
	lbl.mouse_filter          = Control.MOUSE_FILTER_IGNORE
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", COLOR_TEXT_DIM)
	hbox.add_child(lbl)

	var r_cost   = cdata.get("retreatCost", cdata.get("retreat_cost", []))
	var cost_val = r_cost.size() if typeof(r_cost) == TYPE_ARRAY else int(r_cost)
	if cost_val > 0:
		for _i in range(cost_val):
			var icon = TextureRect.new()
			icon.texture             = _get_type_icon("COLORLESS")
			icon.custom_minimum_size = Vector2(18, 18)
			icon.expand_mode         = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode        = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			icon.mouse_filter        = Control.MOUSE_FILTER_IGNORE
			hbox.add_child(icon)
	else:
		var free = Label.new()
		free.text               = "Gratis"
		free.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		free.mouse_filter       = Control.MOUSE_FILTER_IGNORE
		free.add_theme_color_override("font_color", COLOR_GREEN)
		free.add_theme_font_size_override("font_size", 12)
		hbox.add_child(free)

	btn.pressed.connect(func():
		close_action_zoom()
		emit_signal("action_zoom_selected", "RETREAT", 0)
	)
	return wrap


func _build_power_ui(power: Dictionary) -> Control:
	var wrap = Control.new()
	wrap.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var btn = Button.new()
	btn.flat = true
	btn.set_anchors_preset(Control.PRESET_FULL_RECT)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	var s_n = StyleBoxFlat.new()
	s_n.bg_color     = Color(0.22, 0.04, 0.04, 0.95)
	s_n.border_color = Color(0.85, 0.22, 0.22, 0.35)
	s_n.set_border_width_all(1)
	s_n.set_corner_radius_all(10)
	s_n.content_margin_left  = 14
	s_n.content_margin_right = 14
	btn.add_theme_stylebox_override("normal", s_n)
	var s_h = StyleBoxFlat.new()
	s_h.bg_color     = Color(0.35, 0.06, 0.06, 0.98)
	s_h.border_color = Color(0.95, 0.32, 0.32, 0.65)
	s_h.set_border_width_all(1)
	s_h.set_corner_radius_all(10)
	s_h.shadow_color = Color(0.9, 0.2, 0.2, 0.20)
	s_h.shadow_size  = 6
	btn.add_theme_stylebox_override("hover",   s_h)
	btn.add_theme_stylebox_override("pressed", s_h)
	btn.add_theme_stylebox_override("focus",   s_n)
	wrap.add_child(btn)

	var hbox = HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.alignment    = BoxContainer.ALIGNMENT_CENTER
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_theme_constant_override("separation", 8)
	btn.add_child(hbox)

	var badge = Label.new()
	badge.text               = "⚡"
	badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge.mouse_filter       = Control.MOUSE_FILTER_IGNORE
	badge.add_theme_font_size_override("font_size", 16)
	hbox.add_child(badge)

	var vbox_p = VBoxContainer.new()
	vbox_p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox_p.size_flags_vertical   = Control.SIZE_SHRINK_CENTER
	vbox_p.mouse_filter          = Control.MOUSE_FILTER_IGNORE
	vbox_p.add_theme_constant_override("separation", 2)
	hbox.add_child(vbox_p)

	var tag_lbl = Label.new()
	tag_lbl.text         = "POKÉMON POWER"
	tag_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tag_lbl.add_theme_font_size_override("font_size", 9)
	tag_lbl.add_theme_color_override("font_color", Color(0.85, 0.35, 0.35, 0.80))
	vbox_p.add_child(tag_lbl)

	var power_name = power.get("name", "")
	var name_lbl = Label.new()
	name_lbl.text         = power_name.to_upper()
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_lbl.add_theme_font_size_override("font_size", 16)
	name_lbl.add_theme_color_override("font_color", COLOR_TEXT)
	vbox_p.add_child(name_lbl)

	btn.pressed.connect(func():
		close_action_zoom()
		emit_signal("action_zoom_selected", "POWER", power_name)
	)
	return wrap


func _build_cancel_button() -> Button:
	var btn = Button.new()
	btn.text = "✕  Cerrar"
	btn.add_theme_stylebox_override("normal",
		_make_panel_style(Color(1,1,1,0.03), Color(1,1,1,0.06), 8, 1))
	var hover_s = _make_panel_style(Color(0.9,0.2,0.2,0.10), Color(0.9,0.25,0.25,0.35), 8, 1)
	btn.add_theme_stylebox_override("hover",   hover_s)
	btn.add_theme_stylebox_override("pressed", hover_s)
	btn.add_theme_color_override("font_color", COLOR_TEXT_DIM)
	btn.add_theme_font_size_override("font_size", 12)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.pressed.connect(close_action_zoom)
	return btn


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
	dim.color = Color(0, 0, 0, 0.82)
	gaze_popup.add_child(dim)

	var panel_w = min(600.0, vp_size.x - 40)
	var panel_h = 240.0
	var panel   = Panel.new()
	panel.position = Vector2((vp_size.x - panel_w) / 2.0, (vp_size.y - panel_h) / 2.0)
	panel.size     = Vector2(panel_w, panel_h)
	panel.add_theme_stylebox_override("panel",
		_make_shadow_style(COLOR_BG, COLOR_GOLD, 14, 2,
			Color(COLOR_GOLD.r, COLOR_GOLD.g, COLOR_GOLD.b, 0.25), 16))
	gaze_popup.add_child(panel)

	var lbl = Label.new()
	lbl.text = "👁 GLARING GAZE 👁\nElige un Entrenador de la mano rival para devolverlo a su mazo:"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.position = Vector2(10, 12)
	lbl.size     = Vector2(panel_w - 20, 44)
	lbl.add_theme_color_override("font_color", COLOR_GOLD)
	lbl.add_theme_font_size_override("font_size", 13)
	panel.add_child(lbl)

	var start_x = 20.0
	for t in revealed_trainers:
		var c_id  = t.get("card_id", "")
		var h_idx = t.get("handIndex", 0)
		var btn   = Button.new()
		btn.position = Vector2(start_x, 62)
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
	bg.color = Color(0, 0, 0, 0)
	overlay.add_child(bg)

	var panel_w = min(520.0, vp_size.x - 60)
	var panel_h = 270.0
	var panel   = Panel.new()
	panel.name    = "GameOverPanel"
	panel.position = Vector2((vp_size.x - panel_w) / 2.0, (vp_size.y - panel_h) / 2.0)
	panel.size    = Vector2(panel_w, panel_h)
	panel.z_index = 1
	panel.add_theme_stylebox_override("panel",
		_make_shadow_style(
			Color(0.04, 0.06, 0.05, 0.98),
			COLOR_GOLD if won else Color(0.75, 0.22, 0.22),
			18, 3,
			Color(0.85,0.72,0.30,0.40) if won else Color(0.75,0.20,0.20,0.38),
			30))
	overlay.add_child(panel)

	var header_bg = Panel.new()
	header_bg.position = Vector2(0, 0)
	header_bg.size     = Vector2(panel_w, 60)
	header_bg.add_theme_stylebox_override("panel",
		_make_panel_style(
			Color(0.12, 0.20, 0.10, 0.95) if won else Color(0.20, 0.06, 0.06, 0.95),
			Color(0,0,0,0), 18))
	panel.add_child(header_bg)

	var emoji_lbl = Label.new()
	emoji_lbl.text                = "🏆" if won else "💀"
	emoji_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	emoji_lbl.position            = Vector2(0, 6)
	emoji_lbl.size                = Vector2(panel_w, 50)
	emoji_lbl.add_theme_font_size_override("font_size", 42)
	panel.add_child(emoji_lbl)

	var over_lbl = Label.new()
	over_lbl.text                = message
	over_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	over_lbl.position            = Vector2(0, 70)
	over_lbl.size                = Vector2(panel_w, 52)
	over_lbl.add_theme_font_size_override("font_size", 34)
	over_lbl.add_theme_color_override("font_color", COLOR_GOLD if won else Color(0.90, 0.32, 0.32))
	panel.add_child(over_lbl)

	var sep = ColorRect.new()
	sep.color    = (COLOR_GOLD if won else Color(0.75, 0.22, 0.22)) * Color(1,1,1,0.30)
	sep.position = Vector2(panel_w * 0.15, 130)
	sep.size     = Vector2(panel_w * 0.70, 1)
	panel.add_child(sep)

	var menu_btn = Button.new()
	menu_btn.text     = "🏠  Volver al Menú Principal"
	menu_btn.position = Vector2((panel_w - 280) / 2.0, 148)
	menu_btn.size     = Vector2(280, 50)
	menu_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	menu_btn.add_theme_stylebox_override("normal",
		_make_shadow_style(
			Color(0.08,0.18,0.10,0.95) if won else Color(0.18,0.06,0.06,0.95),
			COLOR_GOLD if won else Color(0.75,0.22,0.22),
			10, 2, Color(0,0,0,0.35), 6))
	menu_btn.add_theme_stylebox_override("hover",
		_make_shadow_style(
			Color(0.15,0.35,0.18,0.98) if won else Color(0.32,0.10,0.10,0.98),
			COLOR_GOLD if won else Color(0.95,0.35,0.35),
			10, 2,
			(COLOR_GOLD if won else Color(0.9,0.3,0.3)) * Color(1,1,1,0.45), 12))
	menu_btn.add_theme_color_override("font_color", COLOR_GOLD if won else Color(0.95, 0.65, 0.65))
	menu_btn.add_theme_font_size_override("font_size", 15)
	menu_btn.pressed.connect(func(): emit_signal("game_over_closed"))
	panel.add_child(menu_btn)

	var hint_lbl = Label.new()
	hint_lbl.text                = "o haz clic en cualquier parte"
	hint_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_lbl.position            = Vector2(0, 210)
	hint_lbl.size                = Vector2(panel_w, 18)
	hint_lbl.add_theme_font_size_override("font_size", 10)
	hint_lbl.add_theme_color_override("font_color", Color(0.45, 0.45, 0.40, 0.65))
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
	tw.tween_property(bg,    "color",      Color(0, 0, 0, 0.80), 0.30)
	tw.tween_property(panel, "scale",      Vector2.ONE,          0.30).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(panel, "modulate:a", 1.0,                  0.22)
	var pulse_tw = menu_btn.create_tween().set_loops()
	pulse_tw.tween_property(menu_btn, "modulate:a", 0.78, 0.7).set_trans(Tween.TRANS_SINE).set_delay(0.5)
	pulse_tw.tween_property(menu_btn, "modulate:a", 1.0,  0.7).set_trans(Tween.TRANS_SINE)


# ============================================================
# BENCH POWER POPUP
# ============================================================
func show_bench_power_popup(bench_index: int, pokemon_data: Dictionary) -> void:
	if bench_power_popup:
		bench_power_popup.queue_free()
		bench_power_popup = null

	var card_id = pokemon_data.get("card_id", "")
	if card_id == "": return
	var cdata = CardDatabase.get_card(card_id)
	var power = cdata.get("pokemon_power", null)
	if power == null: return
	var power_name = power.get("name", "")

	bench_power_popup = Control.new()
	bench_power_popup.name = "BenchPowerPopup"
	bench_power_popup.set_anchors_preset(Control.PRESET_FULL_RECT)
	bench_power_popup.z_index = 260
	board.add_child(bench_power_popup)

	var dim = ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color        = Color(0, 0, 0, 0.70)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	bench_power_popup.add_child(dim)
	dim.gui_input.connect(func(ev):
		if ev is InputEventMouseButton and ev.pressed:
			hide_bench_power_popup()
	)

	var panel_w = min(360.0, vp_size.x - 60)
	var panel_h = 140.0
	var panel = Panel.new()
	panel.name     = "BPPanel"
	panel.position = Vector2((vp_size.x - panel_w) / 2.0, (vp_size.y - panel_h) / 2.0)
	panel.size     = Vector2(panel_w, panel_h)
	panel.add_theme_stylebox_override("panel",
		_make_shadow_style(Color(0.06, 0.04, 0.10, 0.98), Color(0.85, 0.22, 0.22, 0.60), 16, 2,
			Color(0.7, 0.1, 0.1, 0.35), 20))
	bench_power_popup.add_child(panel)

	var hdr = Panel.new()
	hdr.position = Vector2(0, 0)
	hdr.size     = Vector2(panel_w, 42)
	var hdr_s = StyleBoxFlat.new()
	hdr_s.bg_color                   = Color(0.20, 0.04, 0.04, 1.0)
	hdr_s.corner_radius_top_left     = 16
	hdr_s.corner_radius_top_right    = 16
	hdr_s.corner_radius_bottom_left  = 0
	hdr_s.corner_radius_bottom_right = 0
	hdr.add_theme_stylebox_override("panel", hdr_s)
	panel.add_child(hdr)

	var badge_lbl = Label.new()
	badge_lbl.text                = "⚡  POKÉMON POWER"
	badge_lbl.position            = Vector2(0, 0)
	badge_lbl.size                = Vector2(panel_w, 42)
	badge_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge_lbl.vertical_alignment  = VERTICAL_ALIGNMENT_CENTER
	badge_lbl.add_theme_font_size_override("font_size", 12)
	badge_lbl.add_theme_color_override("font_color", Color(0.85, 0.35, 0.35, 0.90))
	panel.add_child(badge_lbl)

	var sep = ColorRect.new()
	sep.color    = Color(0.85, 0.22, 0.22, 0.22)
	sep.position = Vector2(0, 42)
	sep.size     = Vector2(panel_w, 1)
	panel.add_child(sep)

	var name_lbl = Label.new()
	name_lbl.text                = power_name.to_upper()
	name_lbl.position            = Vector2(16, 52)
	name_lbl.size                = Vector2(panel_w - 32, 24)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 18)
	name_lbl.add_theme_color_override("font_color", Color(0.93, 0.90, 0.80))
	panel.add_child(name_lbl)

	var use_btn = Button.new()
	use_btn.text     = "⚡  USAR"
	use_btn.position = Vector2(16, panel_h - 48)
	use_btn.size     = Vector2((panel_w - 40) / 2.0, 34)
	use_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var use_n = StyleBoxFlat.new()
	use_n.bg_color     = Color(0.32, 0.06, 0.06, 0.95)
	use_n.border_color = Color(0.85, 0.22, 0.22, 0.50)
	use_n.set_border_width_all(1)
	use_n.set_corner_radius_all(8)
	var use_h = StyleBoxFlat.new()
	use_h.bg_color     = Color(0.50, 0.08, 0.08, 0.98)
	use_h.border_color = Color(0.95, 0.32, 0.32, 0.80)
	use_h.set_border_width_all(1)
	use_h.set_corner_radius_all(8)
	use_h.shadow_color = Color(0.9, 0.2, 0.2, 0.30)
	use_h.shadow_size  = 6
	use_btn.add_theme_stylebox_override("normal",  use_n)
	use_btn.add_theme_stylebox_override("hover",   use_h)
	use_btn.add_theme_stylebox_override("pressed", use_h)
	use_btn.add_theme_color_override("font_color", Color(0.95, 0.65, 0.65))
	use_btn.add_theme_font_size_override("font_size", 12)
	panel.add_child(use_btn)

	var cancel_btn = Button.new()
	cancel_btn.text     = "✕  Cancelar"
	cancel_btn.position = Vector2(16 + (panel_w - 40) / 2.0 + 8, panel_h - 48)
	cancel_btn.size     = Vector2((panel_w - 40) / 2.0, 34)
	cancel_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	cancel_btn.add_theme_stylebox_override("normal",
		_make_panel_style(Color(1,1,1,0.03), Color(1,1,1,0.06), 8, 1))
	var cancel_h = _make_panel_style(Color(0.9,0.2,0.2,0.10), Color(0.9,0.25,0.25,0.35), 8, 1)
	cancel_btn.add_theme_stylebox_override("hover",   cancel_h)
	cancel_btn.add_theme_stylebox_override("pressed", cancel_h)
	cancel_btn.add_theme_color_override("font_color", Color(0.55, 0.52, 0.48))
	cancel_btn.add_theme_font_size_override("font_size", 12)
	panel.add_child(cancel_btn)

	use_btn.pressed.connect(func():
		hide_bench_power_popup()
		emit_signal("bench_power_requested", bench_index, power_name)
	)
	cancel_btn.pressed.connect(func(): hide_bench_power_popup())

	panel.scale    = Vector2(0.85, 0.85)
	panel.modulate = Color(1, 1, 1, 0.0)
	var tw = board.create_tween()
	tw.set_parallel(true)
	tw.tween_property(panel, "scale",      Vector2.ONE, 0.20).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(panel, "modulate:a", 1.0,         0.16)


func hide_bench_power_popup() -> void:
	if bench_power_popup:
		var popup_to_free = bench_power_popup
		bench_power_popup = null
		var tw = popup_to_free.create_tween()
		tw.tween_property(popup_to_free, "modulate:a", 0.0, 0.10)
		tw.tween_callback(popup_to_free.queue_free)


# ============================================================
# HELPERS DE TIPO Y RAREZA
# ============================================================
func _get_type_icon(type_str: String) -> Texture2D:
	const FILES = {
		"FIRE":      "fire.png",     "WATER":    "water.png",   "GRASS":    "grass.png",
		"LIGHTNING": "electric.png", "PSYCHIC":  "psy.png",     "FIGHTING": "figth.png",
		"COLORLESS": "incolor.png",  "DARKNESS": "dark.png",    "METAL":    "metal.png",
		"DRAGON":    "dragon.png",
	}
	var file = FILES.get(type_str.to_upper(), "incolor.png")
	return load(PATH_TYPES + file)


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
