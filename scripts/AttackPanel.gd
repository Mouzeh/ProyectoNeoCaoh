extends Control

# ============================================================
# AttackPanel.gd
# Muestra los ataques del Pokémon activo con costo y disponibilidad
# Se activa al hacer click en el Pokémon activo propio
# ============================================================

signal attack_chosen(attack_index)
signal panel_closed

# ─── PALETA ─────────────────────────────────────────────────
const COLOR_BG           = Color(0.04, 0.06, 0.10, 0.97)
const COLOR_BG_SECONDARY = Color(0.07, 0.10, 0.16, 1.0)
const COLOR_GOLD         = Color(0.95, 0.80, 0.30)
const COLOR_GOLD_DIM     = Color(0.55, 0.45, 0.18)
const COLOR_GOLD_GLOW    = Color(0.95, 0.80, 0.30, 0.15)
const COLOR_TEXT         = Color(0.93, 0.90, 0.80)
const COLOR_TEXT_DIM     = Color(0.60, 0.58, 0.52)
const COLOR_AVAILABLE    = Color(0.08, 0.20, 0.12, 0.95)
const COLOR_DISABLED     = Color(0.14, 0.08, 0.08, 0.85)
const COLOR_BORDER_ON    = Color(0.25, 0.75, 0.40, 0.70)
const COLOR_BORDER_OFF   = Color(0.55, 0.20, 0.20, 0.35)
const COLOR_ACCENT_GREEN = Color(0.30, 0.90, 0.50)
const COLOR_ACCENT_RED   = Color(0.90, 0.35, 0.35)

# ─── ESTADO ─────────────────────────────────────────────────
var current_pokemon_data: Dictionary = {}
var current_card_data: Dictionary = {}
var attached_energies: Array = []

func _ready() -> void:
	visible = false
	z_index = 100
	mouse_filter = Control.MOUSE_FILTER_STOP

# ============================================================
# MOSTRAR / OCULTAR PANEL
# ============================================================
func show_for_pokemon(pokemon_data: Dictionary, can_attack: bool) -> void:
	current_pokemon_data = pokemon_data
	var card_id = pokemon_data.get("card_id", "")
	current_card_data = CardDatabase.get_card(card_id)
	attached_energies = pokemon_data.get("attached_energy", [])

	_clear()
	_build_panel(can_attack)
	visible = true

	modulate.a = 0.0
	scale = Vector2(0.88, 0.88)
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 1.0, 0.18)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func hide_panel() -> void:
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, 0.12)
	tween.tween_property(self, "scale", Vector2(0.94, 0.94), 0.12)
	tween.chain().tween_callback(func(): visible = false)
	emit_signal("panel_closed")

# ============================================================
# CONSTRUIR UI
# ============================================================
func _clear() -> void:
	for child in get_children():
		child.queue_free()

func _build_panel(can_attack: bool) -> void:
	var attacks = current_card_data.get("attacks", [])
	var pokemon_name = current_card_data.get("name", "?")
	var hp = current_card_data.get("hp", 0)
	var damage_counters = current_pokemon_data.get("damage_counters", 0)
	var current_hp = hp - (damage_counters * 10)

	# Calcular energías únicas para decidir si mostrar sección condensada
	var total_attached = attached_energies.size()

	# Altura dinámica por ataques
	var panel_h = 90 + attacks.size() * 100 + 46
	if total_attached == 0:
		panel_h -= 4
	size = Vector2(310, panel_h)

	# ══ Fondo Principal con borde dorado sutil ══
	var bg = Panel.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	var style = StyleBoxFlat.new()
	style.bg_color = COLOR_BG
	style.border_color = Color(COLOR_GOLD.r, COLOR_GOLD.g, COLOR_GOLD.b, 0.40)
	style.set_border_width_all(1)
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_left = 14
	style.corner_radius_bottom_right = 14
	style.shadow_color = Color(0, 0, 0, 0.70)
	style.shadow_size = 28
	style.shadow_offset = Vector2(0, 8)
	bg.add_theme_stylebox_override("panel", style)
	add_child(bg)

	# ── Franja header con fondo diferenciado ──
	var header_bg = Panel.new()
	header_bg.position = Vector2(0, 0)
	header_bg.size = Vector2(310, 66)
	var hbg_st = StyleBoxFlat.new()
	hbg_st.bg_color = COLOR_BG_SECONDARY
	hbg_st.corner_radius_top_left = 14
	hbg_st.corner_radius_top_right = 14
	hbg_st.corner_radius_bottom_left = 0
	hbg_st.corner_radius_bottom_right = 0
	header_bg.add_theme_stylebox_override("panel", hbg_st)
	add_child(header_bg)

	# ── Nombre del Pokémon ──
	var name_lbl = Label.new()
	name_lbl.text = pokemon_name
	name_lbl.position = Vector2(16, 10)
	name_lbl.size = Vector2(200, 26)
	name_lbl.add_theme_font_size_override("font_size", 19)
	name_lbl.add_theme_color_override("font_color", COLOR_GOLD)
	add_child(name_lbl)

	# ── Status badge (arriba derecha) ──
	var status = current_pokemon_data.get("status", "")
	if status and status != "":
		var status_lbl = Label.new()
		status_lbl.text = _status_text(status)
		status_lbl.position = Vector2(220, 12)
		status_lbl.size = Vector2(82, 20)
		status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		status_lbl.add_theme_font_size_override("font_size", 10)
		status_lbl.add_theme_color_override("font_color", _status_color(status))
		add_child(status_lbl)

	# ── HP label ──
	var hp_color = _hp_color(current_hp, hp)
	var hp_lbl = Label.new()
	hp_lbl.text = str(current_hp) + "/" + str(hp) + " HP"
	hp_lbl.position = Vector2(16, 38)
	hp_lbl.add_theme_font_size_override("font_size", 11)
	hp_lbl.add_theme_color_override("font_color", hp_color)
	add_child(hp_lbl)

	# ── Barra HP ──
	var BAR_X = 82.0
	var BAR_W = 204.0
	var bar_bg = Panel.new()
	var bg_st = StyleBoxFlat.new()
	bg_st.bg_color = Color(0.10, 0.06, 0.06)
	bg_st.set_corner_radius_all(4)
	bar_bg.add_theme_stylebox_override("panel", bg_st)
	bar_bg.position = Vector2(BAR_X, 42)
	bar_bg.size = Vector2(BAR_W, 9)
	add_child(bar_bg)

	var hp_ratio = clampf(float(current_hp) / float(hp), 0.0, 1.0)
	if hp_ratio > 0:
		var bar_fill = Panel.new()
		var fill_st = StyleBoxFlat.new()
		fill_st.bg_color = hp_color
		fill_st.set_corner_radius_all(4)
		bar_fill.add_theme_stylebox_override("panel", fill_st)
		bar_fill.position = Vector2(BAR_X, 42)
		bar_fill.size = Vector2(BAR_W * hp_ratio, 9)
		add_child(bar_fill)

	# ── Separador dorado ──
	var div = ColorRect.new()
	div.color = Color(COLOR_GOLD.r, COLOR_GOLD.g, COLOR_GOLD.b, 0.20)
	div.position = Vector2(0, 66)
	div.size = Vector2(310, 1)
	add_child(div)

	# ── Sección energías adjuntas ──
	var energy_section = Control.new()
	energy_section.position = Vector2(14, 72)
	energy_section.size = Vector2(282, 22)
	add_child(energy_section)

	var e_lbl = Label.new()
	e_lbl.text = "Energías:"
	e_lbl.position = Vector2(0, 3)
	e_lbl.add_theme_font_size_override("font_size", 10)
	e_lbl.add_theme_color_override("font_color", COLOR_TEXT_DIM)
	energy_section.add_child(e_lbl)

	if attached_energies.is_empty():
		var no_e = Label.new()
		no_e.text = "Ninguna"
		no_e.position = Vector2(60, 3)
		no_e.add_theme_font_size_override("font_size", 10)
		no_e.add_theme_color_override("font_color", Color(0.40, 0.40, 0.38))
		energy_section.add_child(no_e)
	else:
		# Agrupar energías para mostrar "icono × cantidad"
		var grouped = _group_energies(attached_energies)
		var ex = 60.0
		for e_type in grouped:
			var count = grouped[e_type]
			var icon_tex = _get_type_icon(e_type)
			if icon_tex:
				var tr = TextureRect.new()
				tr.texture = icon_tex
				tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				tr.size = Vector2(16, 16)
				tr.position = Vector2(ex, 2)
				energy_section.add_child(tr)
				ex += 18
			if count > 1:
				var cnt_lbl = Label.new()
				cnt_lbl.text = "×" + str(count)
				cnt_lbl.position = Vector2(ex, 3)
				cnt_lbl.add_theme_font_size_override("font_size", 10)
				cnt_lbl.add_theme_color_override("font_color", COLOR_TEXT_DIM)
				energy_section.add_child(cnt_lbl)
				ex += 22
			else:
				ex += 4

	# Separador secundario
	var div2 = ColorRect.new()
	div2.color = Color(1, 1, 1, 0.05)
	div2.position = Vector2(0, 97)
	div2.size = Vector2(310, 1)
	add_child(div2)

	# ── Ataques ──
	var y = 104.0
	if attacks.is_empty():
		var no_atk = Label.new()
		no_atk.text = "Sin ataques disponibles"
		no_atk.position = Vector2(16, y + 14)
		no_atk.size = Vector2(278, 20)
		no_atk.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		no_atk.add_theme_font_size_override("font_size", 12)
		no_atk.add_theme_color_override("font_color", COLOR_TEXT_DIM)
		add_child(no_atk)
	else:
		for i in range(attacks.size()):
			var attack = attacks[i]
			var can_use = can_attack and _can_use_attack(attack)
			y = _build_attack_button(attack, i, y, can_use)

	# ── Botón cerrar ──
	var close_btn = Button.new()
	close_btn.text = "✕  Cerrar"
	close_btn.position = Vector2(14, size.y - 42)
	close_btn.size = Vector2(282, 32)
	close_btn.add_theme_font_size_override("font_size", 11)
	close_btn.add_theme_color_override("font_color", COLOR_TEXT_DIM)

	var close_style = StyleBoxFlat.new()
	close_style.bg_color = Color(1, 1, 1, 0.03)
	close_style.border_color = Color(1, 1, 1, 0.07)
	close_style.set_border_width_all(1)
	close_style.set_corner_radius_all(8)

	var close_hover = close_style.duplicate()
	close_hover.bg_color = Color(0.9, 0.2, 0.2, 0.12)
	close_hover.border_color = Color(0.9, 0.25, 0.25, 0.40)

	close_btn.add_theme_stylebox_override("normal", close_style)
	close_btn.add_theme_stylebox_override("hover", close_hover)
	close_btn.add_theme_stylebox_override("pressed", close_hover)
	close_btn.pressed.connect(hide_panel)
	add_child(close_btn)

# ============================================================
# CONSTRUIR BOTÓN DE ATAQUE
# ============================================================
func _build_attack_button(attack: Dictionary, index: int, y: float, can_use: bool) -> float:
	var atk_name   = attack.get("name", "?")
	var atk_damage = attack.get("damage", 0)
	var atk_cost   = attack.get("cost", {})
	var atk_effect = attack.get("effect", "")

	var btn_h = 90.0

	var container = Control.new()
	container.position = Vector2(14, y)
	container.size = Vector2(282, btn_h)
	add_child(container)

	# Fondo
	var btn_bg = Panel.new()
	btn_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	var style = StyleBoxFlat.new()
	style.bg_color = COLOR_AVAILABLE if can_use else COLOR_DISABLED
	style.border_color = COLOR_BORDER_ON if can_use else COLOR_BORDER_OFF
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	btn_bg.add_theme_stylebox_override("panel", style)
	container.add_child(btn_bg)

	# Línea de acento izquierda (estética)
	var accent = ColorRect.new()
	accent.color = COLOR_ACCENT_GREEN if can_use else COLOR_ACCENT_RED
	accent.color.a = 0.7 if can_use else 0.35
	accent.position = Vector2(0, 6)
	accent.size = Vector2(3, btn_h - 12)
	var accent_panel = Panel.new()
	accent_panel.position = Vector2(0, 6)
	accent_panel.size = Vector2(3, btn_h - 12)
	var acc_st = StyleBoxFlat.new()
	acc_st.bg_color = accent.color
	acc_st.set_corner_radius_all(2)
	accent_panel.add_theme_stylebox_override("panel", acc_st)
	container.add_child(accent_panel)

	# ── Nombre del ataque ──
	var name_lbl = Label.new()
	name_lbl.text = atk_name
	name_lbl.position = Vector2(14, 9)
	name_lbl.size = Vector2(195, 22)
	name_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_lbl.clip_text = true
	name_lbl.add_theme_font_size_override("font_size", 14)
	name_lbl.add_theme_color_override("font_color", COLOR_TEXT if can_use else Color(0.60, 0.56, 0.56))
	container.add_child(name_lbl)

	# ── Daño (derecha, prominente) ──
	if atk_damage > 0:
		var dmg_lbl = Label.new()
		dmg_lbl.text = str(atk_damage)
		dmg_lbl.position = Vector2(224, 5)
		dmg_lbl.size = Vector2(50, 28)
		dmg_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		dmg_lbl.add_theme_font_size_override("font_size", 22)
		dmg_lbl.add_theme_color_override("font_color", COLOR_GOLD if can_use else COLOR_GOLD_DIM)
		container.add_child(dmg_lbl)

	# ── Costo de energía: TODOS los iconos individualmente ──
	# FIX: Soporta tanto Dictionary {"WATER": 3} como Array ["WATER","WATER","WATER"]
	var cost_x = 14.0
	var cost_y = 36.0
	var cost_icons = _expand_cost_to_list(atk_cost)
	
	for e_type in cost_icons:
		var icon_tex = _get_type_icon(e_type)
		if icon_tex:
			var tr = TextureRect.new()
			tr.texture = icon_tex
			tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tr.size = Vector2(18, 18)
			tr.position = Vector2(cost_x, cost_y)
			if not can_use:
				tr.modulate = Color(0.5, 0.5, 0.5, 0.6)
			container.add_child(tr)
		else:
			var dot = Panel.new()
			dot.size = Vector2(14, 14)
			dot.position = Vector2(cost_x, cost_y + 2)
			var dot_st = StyleBoxFlat.new()
			dot_st.bg_color = Color(0.5, 0.5, 0.5, 0.5) if not can_use else Color(0.7, 0.7, 0.7)
			dot_st.set_corner_radius_all(7)
			dot.add_theme_stylebox_override("panel", dot_st)
			container.add_child(dot)
		cost_x += 22

	# ── Efecto del ataque ──
	if atk_effect != "" and can_use:
		var effect_lbl = Label.new()
		effect_lbl.text = atk_effect
		effect_lbl.position = Vector2(14, 60)
		effect_lbl.size = Vector2(256, 22)
		effect_lbl.add_theme_font_size_override("font_size", 9)
		effect_lbl.add_theme_color_override("font_color", Color(0.70, 0.80, 0.72))
		effect_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		effect_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		effect_lbl.clip_text = true
		container.add_child(effect_lbl)
	elif not can_use:
		# Energía insuficiente: muestra qué falta
		var missing_label = Label.new()
		missing_label.text = "✖ Energía insuficiente"
		missing_label.position = Vector2(14, 62)
		missing_label.size = Vector2(256, 18)
		missing_label.add_theme_font_size_override("font_size", 9)
		missing_label.add_theme_color_override("font_color", Color(0.85, 0.38, 0.38))
		container.add_child(missing_label)

	# ── Área clickeable (solo si puede atacar) ──
	if can_use:
		var click_btn = Button.new()
		click_btn.set_anchors_preset(Control.PRESET_FULL_RECT)
		click_btn.flat = true

		var transparent = StyleBoxFlat.new()
		transparent.bg_color = Color(0, 0, 0, 0)
		click_btn.add_theme_stylebox_override("normal", transparent)
		click_btn.add_theme_stylebox_override("focus", transparent)

		var hover_style = StyleBoxFlat.new()
		hover_style.bg_color = Color(0.35, 1.0, 0.55, 0.07)
		hover_style.border_color = Color(0.40, 1.0, 0.55, 0.60)
		hover_style.set_border_width_all(1)
		hover_style.set_corner_radius_all(10)
		click_btn.add_theme_stylebox_override("hover", hover_style)

		var pressed_style = StyleBoxFlat.new()
		pressed_style.bg_color = Color(0.35, 1.0, 0.55, 0.14)
		pressed_style.set_corner_radius_all(10)
		click_btn.add_theme_stylebox_override("pressed", pressed_style)

		var atk_index = index
		click_btn.pressed.connect(func():
			emit_signal("attack_chosen", atk_index)
			hide_panel()
		)
		container.add_child(click_btn)

	return y + btn_h + 8

# ============================================================
# HELPERS
# ============================================================

# Convierte cost (Dictionary O Array) en una lista plana de tipos
# Ej: {"WATER": 3, "COLORLESS": 1} → ["WATER","WATER","WATER","COLORLESS"]
# Ej: ["WATER","WATER","WATER","COLORLESS"] → mismo array
func _expand_cost_to_list(cost) -> Array:
	var result = []
	if cost is Array:
		for entry in cost:
			result.append(str(entry).to_upper())
	elif cost is Dictionary:
		for raw_key in cost:
			var e_type = str(raw_key).to_upper()   # normaliza StringName, minúsculas, etc.
			var count  = int(cost[raw_key])         # int() protege contra "3" string
			for _j in range(count):
				result.append(e_type)
	return result

# Agrupa Array de energías en Dictionary para la sección de "energías adjuntas"
func _group_energies(energies: Array) -> Dictionary:
	var grouped = {}
	for e_id in energies:
		var e_type = CardDatabase.get_energy_type(e_id)
		grouped[e_type] = grouped.get(e_type, 0) + 1
	return grouped

func _can_use_attack(attack: Dictionary) -> bool:
	var cost = attack.get("cost", {})
	if cost is Array and cost.is_empty():
		return true
	if cost is Dictionary and cost.is_empty():
		return true

	# Construir mapa de disponibles
	var available = {}
	for e_id in attached_energies:
		var e_type = CardDatabase.get_energy_type(e_id)
		available[e_type] = available.get(e_type, 0) + 1

	# Expandir costo a lista y verificar
	var cost_list = _expand_cost_to_list(cost)
	var colorless_needed = 0
	for e_type in cost_list:
		if e_type == "COLORLESS":
			colorless_needed += 1
		else:
			if available.get(e_type, 0) <= 0:
				return false
			available[e_type] -= 1

	# COLORLESS puede ser cubierto por cualquier energía restante
	var total_remaining = 0
	for v in available.values():
		total_remaining += v
	return total_remaining >= colorless_needed

func _hp_color(current: int, max_hp: int) -> Color:
	if max_hp <= 0:
		return Color(0.5, 0.5, 0.5)
	var ratio = float(current) / float(max_hp)
	if ratio > 0.50:
		return Color(0.30, 0.88, 0.48)
	elif ratio > 0.25:
		return Color(0.95, 0.82, 0.20)
	else:
		return Color(0.95, 0.32, 0.32)

func _status_text(status: String) -> String:
	match status:
		"POISONED":  return "☠ Envenenado"
		"BURNED":    return "🔥 Quemado"
		"ASLEEP":    return "💤 Dormido"
		"PARALYZED": return "⚡ Paralizado"
		"CONFUSED":  return "💫 Confundido"
	return status

func _status_color(status: String) -> Color:
	match status:
		"POISONED":  return Color(0.78, 0.32, 0.92)
		"BURNED":    return Color(0.95, 0.52, 0.15)
		"ASLEEP":    return Color(0.42, 0.62, 0.92)
		"PARALYZED": return Color(0.95, 0.90, 0.22)
		"CONFUSED":  return Color(0.88, 0.32, 0.78)
	return Color(0.7, 0.7, 0.7)

func _get_type_icon(t: String) -> Texture2D:
	var base_path = "res://assets/imagen/TypesIcons/"
	var file_name = ""

	match t.to_upper():
		"FIRE":      file_name = "fire.png"
		"WATER":     file_name = "water.png"
		"GRASS":     file_name = "grass.png"
		"LIGHTNING": file_name = "electric.png"
		"PSYCHIC":   file_name = "psy.png"
		"FIGHTING":  file_name = "figth.png"
		"COLORLESS": file_name = "incolor.png"
		"DARKNESS":  file_name = "dark.png"
		"METAL":     file_name = "metal.png"
		"DRAGON":    file_name = "dragon.png"

	if file_name == "":
		return null

	return load(base_path + file_name)
