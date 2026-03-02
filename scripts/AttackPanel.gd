extends Control

# ============================================================
# AttackPanel.gd
# Muestra los ataques del Pokémon activo con costo y disponibilidad
# Se activa al hacer click en el Pokémon activo propio
# ============================================================

signal attack_chosen(attack_index)
signal panel_closed

# ─── COLORES ────────────────────────────────────────────────
const COLOR_BG        = Color(0.05, 0.08, 0.12, 0.95)
const COLOR_GOLD      = Color(0.90, 0.75, 0.25)
const COLOR_GOLD_DIM  = Color(0.55, 0.45, 0.18)
const COLOR_TEXT      = Color(0.92, 0.88, 0.75)
const COLOR_AVAILABLE = Color(0.15, 0.28, 0.18, 0.9)   # Fondo ataque disponible
const COLOR_DISABLED  = Color(0.18, 0.12, 0.12, 0.7)   # Fondo ataque bloqueado

# ─── ESTADO ─────────────────────────────────────────────────
var current_pokemon_data: Dictionary = {}
var current_card_data: Dictionary = {}
var attached_energies: Array = []

func _ready() -> void:
	visible = false
	z_index = 100
	mouse_filter = Control.MOUSE_FILTER_STOP

# ============================================================
# MOSTRAR PANEL
# ============================================================
func show_for_pokemon(pokemon_data: Dictionary, can_attack: bool) -> void:
	current_pokemon_data = pokemon_data
	var card_id = pokemon_data.get("card_id", "")
	current_card_data = CardDatabase.get_card(card_id)
	attached_energies = pokemon_data.get("attached_energy", [])

	_clear()
	_build_panel(can_attack)
	visible = true

	# Animación entrada fluida
	modulate.a = 0.0
	scale = Vector2(0.90, 0.90)
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 1.0, 0.15)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func hide_panel() -> void:
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.10)
	tween.tween_callback(func(): visible = false)
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

	# Calcular altura necesaria dinámicamente
	var panel_h = 75 + attacks.size() * 95 + 40
	size = Vector2(300, panel_h)

	# ── Fondo Principal ──
	var bg = Panel.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	var style = StyleBoxFlat.new()
	style.bg_color = COLOR_BG
	style.border_color = Color(COLOR_GOLD.r, COLOR_GOLD.g, COLOR_GOLD.b, 0.5)
	style.border_width_left = 1; style.border_width_right = 1
	style.border_width_top = 1; style.border_width_bottom = 1
	style.corner_radius_top_left = 12; style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12; style.corner_radius_bottom_right = 12
	style.shadow_color = Color(0, 0, 0, 0.6)
	style.shadow_size = 30
	style.shadow_offset = Vector2(0, 10)
	bg.add_theme_stylebox_override("panel", style)
	add_child(bg)

	# ── Header: nombre + HP ──
	var header = Control.new()
	header.position = Vector2(0, 0)
	header.size = Vector2(300, 60)
	add_child(header)

	var name_lbl = Label.new()
	name_lbl.text = pokemon_name
	name_lbl.position = Vector2(16, 10)
	name_lbl.add_theme_font_size_override("font_size", 18)
	name_lbl.add_theme_color_override("font_color", COLOR_GOLD)
	header.add_child(name_lbl)

	# HP Texto
	var hp_color = _hp_color(current_hp, hp)
	var hp_lbl = Label.new()
	hp_lbl.text = str(current_hp) + "/" + str(hp) + " HP"
	hp_lbl.position = Vector2(16, 36)
	hp_lbl.add_theme_font_size_override("font_size", 12)
	hp_lbl.add_theme_color_override("font_color", hp_color)
	header.add_child(hp_lbl)

	# Barra de HP (Con bordes redondeados)
	var bar_bg = Panel.new()
	var bg_st = StyleBoxFlat.new()
	bg_st.bg_color = Color(0.15, 0.10, 0.10)
	bg_st.corner_radius_top_left = 4; bg_st.corner_radius_top_right = 4
	bg_st.corner_radius_bottom_left = 4; bg_st.corner_radius_bottom_right = 4
	bar_bg.add_theme_stylebox_override("panel", bg_st)
	bar_bg.position = Vector2(100, 42)
	bar_bg.size = Vector2(170, 8)
	header.add_child(bar_bg)

	var hp_ratio = clampf(float(current_hp) / float(hp), 0.0, 1.0)
	if hp_ratio > 0:
		var bar_fill = Panel.new()
		var fill_st = StyleBoxFlat.new()
		fill_st.bg_color = hp_color
		fill_st.corner_radius_top_left = 4; fill_st.corner_radius_top_right = 4
		fill_st.corner_radius_bottom_left = 4; fill_st.corner_radius_bottom_right = 4
		bar_fill.add_theme_stylebox_override("panel", fill_st)
		bar_fill.position = Vector2(100, 42)
		bar_fill.size = Vector2(170 * hp_ratio, 8)
		header.add_child(bar_fill)

	# Status badge
	var status = current_pokemon_data.get("status", "")
	if status and status != "":
		var status_lbl = Label.new()
		status_lbl.text = _status_text(status)
		status_lbl.position = Vector2(210, 14)
		status_lbl.add_theme_font_size_override("font_size", 11)
		status_lbl.add_theme_color_override("font_color", _status_color(status))
		header.add_child(status_lbl)

	# Separador
	var div = ColorRect.new()
	div.color = Color(COLOR_GOLD_DIM.r, COLOR_GOLD_DIM.g, COLOR_GOLD_DIM.b, 0.3)
	div.position = Vector2(16, 62)
	div.size = Vector2(268, 1)
	add_child(div)

	# ── Energías adjuntas (CON ICONOS) ──
	var energy_row = Control.new()
	energy_row.position = Vector2(16, 68)
	energy_row.size = Vector2(268, 20)
	add_child(energy_row)

	var e_lbl = Label.new()
	e_lbl.text = "Energía actual:"
	e_lbl.position = Vector2(0, 2)
	e_lbl.add_theme_font_size_override("font_size", 11)
	e_lbl.add_theme_color_override("font_color", Color(0.65, 0.65, 0.60))
	energy_row.add_child(e_lbl)

	var ex = 90.0
	for e_id in attached_energies:
		var e_type = CardDatabase.get_energy_type(e_id)
		var icon_tex = _get_type_icon(e_type)
		
		if icon_tex:
			var tr = TextureRect.new()
			tr.texture = icon_tex
			tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tr.size = Vector2(16, 16)
			tr.position = Vector2(ex, 1)
			energy_row.add_child(tr)
		else:
			# Respaldo visual si no encuentra icono
			var dot = ColorRect.new()
			dot.size = Vector2(12, 12)
			dot.position = Vector2(ex, 3)
			dot.color = Color(0.5, 0.5, 0.5)
			energy_row.add_child(dot)
		ex += 20

	if attached_energies.is_empty():
		var no_e = Label.new()
		no_e.text = "Ninguna"
		no_e.position = Vector2(90, 2)
		no_e.add_theme_font_size_override("font_size", 11)
		no_e.add_theme_color_override("font_color", Color(0.45, 0.45, 0.40))
		energy_row.add_child(no_e)

	# ── Ataques ──
	var y = 96.0
	if attacks.is_empty():
		var no_atk = Label.new()
		no_atk.text = "Sin ataques disponibles"
		no_atk.position = Vector2(16, y + 10)
		no_atk.size = Vector2(268, 20)
		no_atk.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		no_atk.add_theme_font_size_override("font_size", 12)
		no_atk.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		add_child(no_atk)
	else:
		for i in range(attacks.size()):
			var attack = attacks[i]
			var can_use = can_attack and _can_use_attack(attack)
			y = _build_attack_button(attack, i, y, can_use)

	# ── Botón cerrar ──
	var close_btn = Button.new()
	close_btn.text = "Cerrar Panel"
	close_btn.position = Vector2(16, size.y - 40)
	close_btn.size = Vector2(268, 30)
	close_btn.add_theme_font_size_override("font_size", 12)
	close_btn.add_theme_color_override("font_color", Color(0.8, 0.75, 0.70))

	var close_style = StyleBoxFlat.new()
	close_style.bg_color = Color(1, 1, 1, 0.05)
	close_style.border_color = Color(1, 1, 1, 0.1)
	close_style.border_width_left = 1; close_style.border_width_right = 1
	close_style.border_width_top = 1; close_style.border_width_bottom = 1
	close_style.corner_radius_top_left = 6; close_style.corner_radius_top_right = 6
	close_style.corner_radius_bottom_left = 6; close_style.corner_radius_bottom_right = 6
	
	var close_hover = close_style.duplicate()
	close_hover.bg_color = Color(1, 0.2, 0.2, 0.15)
	close_hover.border_color = Color(1, 0.2, 0.2, 0.3)

	close_btn.add_theme_stylebox_override("normal", close_style)
	close_btn.add_theme_stylebox_override("hover", close_hover)
	close_btn.pressed.connect(hide_panel)
	add_child(close_btn)

func _build_attack_button(attack: Dictionary, index: int, y: float, can_use: bool) -> float:
	var atk_name   = attack.get("name", "?")
	var atk_damage = attack.get("damage", 0)
	var atk_cost   = attack.get("cost", {})
	var atk_effect = attack.get("effect", "")

	var btn_h = 85.0

	# Contenedor del ataque
	var container = Control.new()
	container.position = Vector2(16, y)
	container.size = Vector2(268, btn_h)
	add_child(container)

	# Fondo del botón
	var btn_bg = Panel.new()
	btn_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	var style = StyleBoxFlat.new()
	style.bg_color = COLOR_AVAILABLE if can_use else COLOR_DISABLED
	style.border_color = Color(0.3, 0.8, 0.4, 0.5) if can_use else Color(0.8, 0.3, 0.3, 0.2)
	style.border_width_left = 1; style.border_width_right = 1
	style.border_width_top = 1; style.border_width_bottom = 1
	style.corner_radius_top_left = 8; style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8; style.corner_radius_bottom_right = 8
	btn_bg.add_theme_stylebox_override("panel", style)
	container.add_child(btn_bg)

	# Nombre del ataque (Controlado)
	var name_lbl = Label.new()
	name_lbl.text = atk_name
	name_lbl.position = Vector2(12, 8)
	name_lbl.size = Vector2(190, 20) # Límite de ancho para que no choque con el daño
	name_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_lbl.clip_text = true
	name_lbl.add_theme_font_size_override("font_size", 14)
	name_lbl.add_theme_color_override("font_color", COLOR_TEXT if can_use else Color(0.65, 0.60, 0.60))
	container.add_child(name_lbl)

	# Daño
	if atk_damage > 0:
		var dmg_lbl = Label.new()
		dmg_lbl.text = str(atk_damage)
		dmg_lbl.position = Vector2(216, 6)
		dmg_lbl.size = Vector2(40, 24)
		dmg_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		dmg_lbl.add_theme_font_size_override("font_size", 20)
		dmg_lbl.add_theme_color_override("font_color", COLOR_GOLD if can_use else COLOR_GOLD_DIM)
		container.add_child(dmg_lbl)

	# Costo de energía (CON ICONOS)
	var cost_x = 12.0
	var cost_y = 32.0
	for e_type in atk_cost:
		var count = atk_cost[e_type]
		for _j in range(count):
			var icon_tex = _get_type_icon(e_type)
			if icon_tex:
				var tr = TextureRect.new()
				tr.texture = icon_tex
				tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				tr.size = Vector2(18, 18)
				tr.position = Vector2(cost_x, cost_y)
				container.add_child(tr)
			else:
				var dot = ColorRect.new()
				dot.size = Vector2(14, 14)
				dot.position = Vector2(cost_x, cost_y + 2)
				dot.color = Color(0.6, 0.6, 0.6)
				container.add_child(dot)
			cost_x += 20

	# Efecto del ataque (Estrictamente delimitado)
	if atk_effect != "":
		var effect_lbl = Label.new()
		effect_lbl.text = atk_effect
		effect_lbl.position = Vector2(12, 54)
		effect_lbl.size = Vector2(244, 24) # Altura máxima rígida
		effect_lbl.add_theme_font_size_override("font_size", 9)
		effect_lbl.add_theme_color_override("font_color", Color(0.8, 0.85, 0.80) if can_use else Color(0.6, 0.6, 0.6))
		effect_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		effect_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS # Corta con "..." dinámicamente
		effect_lbl.clip_text = true # No permite que nada se dibuje fuera del size
		container.add_child(effect_lbl)

	# Área clickeable e interacción si puede atacar
	if can_use:
		var click_btn = Button.new()
		click_btn.set_anchors_preset(Control.PRESET_FULL_RECT)
		click_btn.flat = true
		
		var transparent = StyleBoxFlat.new()
		transparent.bg_color = Color(0, 0, 0, 0)
		click_btn.add_theme_stylebox_override("normal", transparent)
		
		var hover_style = StyleBoxFlat.new()
		hover_style.bg_color = Color(1, 1, 1, 0.08)
		hover_style.border_color = Color(0.5, 1.0, 0.6, 0.8)
		hover_style.border_width_left = 1; hover_style.border_width_right = 1
		hover_style.border_width_top = 1; hover_style.border_width_bottom = 1
		hover_style.corner_radius_top_left = 8; hover_style.corner_radius_top_right = 8
		hover_style.corner_radius_bottom_left = 8; hover_style.corner_radius_bottom_right = 8
		click_btn.add_theme_stylebox_override("hover", hover_style)
		
		var atk_index = index
		click_btn.pressed.connect(func():
			emit_signal("attack_chosen", atk_index)
			hide_panel()
		)
		container.add_child(click_btn)
	else:
		var no_energy = Label.new()
		no_energy.text = "✖ Energía insuficiente"
		no_energy.position = Vector2(12, 54)
		if atk_effect != "":
			no_energy.position = Vector2(130, 32) # Lo anclamos arriba a la derecha para que no pise el efecto
			no_energy.size = Vector2(126, 20)
			no_energy.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		no_energy.add_theme_font_size_override("font_size", 9)
		no_energy.add_theme_color_override("font_color", Color(0.85, 0.40, 0.40))
		container.add_child(no_energy)

	return y + btn_h + 10

# ============================================================
# HELPERS
# ============================================================

func _can_use_attack(attack: Dictionary) -> bool:
	var cost = attack.get("cost", {})
	if cost.is_empty():
		return true

	var available = {}
	for e_id in attached_energies:
		var e_type = CardDatabase.get_energy_type(e_id)
		available[e_type] = available.get(e_type, 0) + 1

	var colorless_needed = cost.get("COLORLESS", 0)
	for e_type in cost:
		if e_type == "COLORLESS":
			continue
		var needed = cost[e_type]
		var have = available.get(e_type, 0)
		if have < needed:
			return false
		available[e_type] -= needed

	var total_remaining = 0
	for v in available.values():
		total_remaining += v
	return total_remaining >= colorless_needed

func _hp_color(current: int, max_hp: int) -> Color:
	var ratio = float(current) / float(max_hp)
	if ratio > 0.5:
		return Color(0.35, 0.85, 0.45)   # Verde
	elif ratio > 0.25:
		return Color(0.95, 0.80, 0.20)   # Amarillo
	else:
		return Color(0.95, 0.30, 0.30)   # Rojo

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
		"POISONED":  return Color(0.75, 0.30, 0.90)
		"BURNED":    return Color(0.95, 0.50, 0.15)
		"ASLEEP":    return Color(0.40, 0.60, 0.90)
		"PARALYZED": return Color(0.95, 0.90, 0.20)
		"CONFUSED":  return Color(0.85, 0.30, 0.75)
	return Color(0.7, 0.7, 0.7)

func _get_type_icon(t: String) -> Texture2D:
	var base_path = "res://assets/imagen/TypesIcons/"
	var file_name = "?.png"
	
	match t.to_upper():
		"FIRE":       file_name = "fire.png"
		"WATER":      file_name = "water.png"
		"GRASS":      file_name = "grass.png"
		"LIGHTNING":  file_name = "electric.png"
		"PSYCHIC":    file_name = "psy.png"
		"FIGHTING":   file_name = "figth.png" 
		"COLORLESS":  file_name = "incolor.png"
		"DARKNESS":   file_name = "dark.png"
		"METAL":      file_name = "metal.png"
		"DRAGON":     file_name = "dragon.png"
		
	if file_name == "?.png" and t.to_upper() in ["TRAINER", "ENERGY"]:
		return null
		
	return load(base_path + file_name)
