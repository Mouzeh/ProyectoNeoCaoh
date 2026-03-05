extends Control

const XP_PER_LEVEL = 1000
const PREMIUM_COST = 500

var main_menu_ref: Node
var lbl_status: Label
var lbl_gems: Label
var btn_buy: Button
var http_buy: HTTPRequest
var http_claim: HTTPRequest
var track_hbox: HBoxContainer

# ============================================================
# Patrón BUILD para integrarse con MainMenu.gd
# ============================================================
static func build(parent: Control, main_menu: Node) -> void:
	var screen = load("res://scenes/main_menu/screens/BattlePassScreen.gd").new()
	screen.main_menu_ref = main_menu
	screen.name = "BattlePassScreenNode"
	screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	parent.add_child(screen)
	screen._setup_ui()

func _setup_ui() -> void:
	# Nodos HTTP
	http_buy = HTTPRequest.new()
	add_child(http_buy)
	http_buy.request_completed.connect(_on_buy_completed)
	
	http_claim = HTTPRequest.new()
	add_child(http_claim)
	http_claim.request_completed.connect(_on_claim_completed)

	# Contenedor Principal
	var main_vbox = VBoxContainer.new()
	main_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_vbox.add_theme_constant_override("separation", 15)
	add_child(main_vbox)

	# --- SECCIÓN SUPERIOR (HEADER) ---
	var header_bg = PanelContainer.new()
	var header_style = StyleBoxFlat.new()
	header_style.bg_color = main_menu_ref.COLOR_PANEL
	header_style.content_margin_bottom = 15
	header_style.content_margin_top = 15
	header_bg.add_theme_stylebox_override("panel", header_style)
	main_vbox.add_child(header_bg)
	
	var header_vbox = VBoxContainer.new()
	header_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	header_bg.add_child(header_vbox)

	var title = Label.new()
	title.text = "PASE DE BATALLA"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", main_menu_ref.COLOR_GOLD)
	header_vbox.add_child(title)

	var data_hbox = HBoxContainer.new()
	data_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	data_hbox.add_theme_constant_override("separation", 40)
	header_vbox.add_child(data_hbox)

	var lbl_level = Label.new()
	lbl_level.text = "Nivel Actual: " + str(PlayerData.battle_pass_level)
	data_hbox.add_child(lbl_level)

	lbl_gems = Label.new()
	lbl_gems.text = "💎 Gemas: " + str(PlayerData.gems)
	lbl_gems.add_theme_color_override("font_color", main_menu_ref.COLOR_ACCENT)
	data_hbox.add_child(lbl_gems)

	var xp_bar = ProgressBar.new()
	xp_bar.custom_minimum_size = Vector2(300, 20)
	xp_bar.max_value = XP_PER_LEVEL
	xp_bar.value = PlayerData.battle_pass_xp
	header_vbox.add_child(xp_bar)

	# --- BOTÓN PREMIUM ---
	var premium_hbox = HBoxContainer.new()
	premium_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	header_vbox.add_child(premium_hbox)
	
	lbl_status = Label.new()
	lbl_status.custom_minimum_size = Vector2(250, 0)
	premium_hbox.add_child(lbl_status)
	
	btn_buy = Button.new()
	btn_buy.custom_minimum_size = Vector2(200, 40)
	btn_buy.pressed.connect(_on_buy_pressed)
	premium_hbox.add_child(btn_buy)

	# --- SECCIÓN INFERIOR (TRACK ESTILO FORTNITE) ---
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	main_vbox.add_child(scroll)
	
	var track_margin = MarginContainer.new()
	track_margin.add_theme_constant_override("margin_left", 20)
	track_margin.add_theme_constant_override("margin_right", 20)
	track_margin.add_theme_constant_override("margin_top", 20)
	scroll.add_child(track_margin)

	track_hbox = HBoxContainer.new()
	track_hbox.add_theme_constant_override("separation", 15)
	track_margin.add_child(track_hbox)

	_update_premium_ui()
	_build_rewards_track()


# ============================================================
# CONSTRUIR LA LÍNEA DE RECOMPENSAS
# ============================================================
func _build_rewards_track() -> void:
	for child in track_hbox.get_children():
		child.queue_free()

	for i in range(1, 51):
		var col = VBoxContainer.new()
		col.add_theme_constant_override("separation", 10)
		col.alignment = BoxContainer.ALIGNMENT_CENTER
		
		var rewards = _get_reward_data(i)
		
		# 1. Bloque Premium (Arriba)
		col.add_child(_create_reward_panel(i, "premium", rewards.premium))
		
		# 2. Número de Nivel (Medio)
		var lvl_panel = PanelContainer.new()
		var s_lvl = StyleBoxFlat.new()
		s_lvl.bg_color = main_menu_ref.COLOR_BG
		s_lvl.border_color = main_menu_ref.COLOR_GOLD if i <= PlayerData.battle_pass_level else main_menu_ref.COLOR_TEXT_DIM
		s_lvl.border_width_bottom = 2; s_lvl.border_width_top = 2
		lvl_panel.add_theme_stylebox_override("panel", s_lvl)
		var lbl_n = Label.new()
		lbl_n.text = "Lvl " + str(i)
		lbl_n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lvl_panel.add_child(lbl_n)
		col.add_child(lvl_panel)
		
		# 3. Bloque Gratuito (Abajo)
		col.add_child(_create_reward_panel(i, "free", rewards.free))
		
		track_hbox.add_child(col)

func _create_reward_panel(level: int, type: String, data: Dictionary) -> Control:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(140, 160)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.12, 0.05, 0.9) if type == "premium" else Color(0.1, 0.1, 0.1, 0.9)
	style.border_color = main_menu_ref.COLOR_GOLD if type == "premium" else main_menu_ref.COLOR_TEXT_DIM
	style.border_width_left = 2; style.border_width_right = 2
	style.border_width_top = 2; style.border_width_bottom = 2
	style.corner_radius_top_left = 8; style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8; style.corner_radius_bottom_right = 8
	panel.add_theme_stylebox_override("panel", style)
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(vbox)
	
	# Icono/Texto de la recompensa
	var icon = Label.new()
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.add_theme_font_size_override("font_size", 30)
	
	var desc = Label.new()
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.add_theme_font_size_override("font_size", 12)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	
	match data.type:
		"coins":
			icon.text = "🪙"
			desc.text = str(data.amount) + " Monedas"
		"gems":
			icon.text = "💎"
			desc.text = str(data.amount) + " Gemas"
		"pack":
			icon.text = "📦"
			desc.text = str(data.amount) + "x Sobre"
		"card":
			icon.text = "🃏"
			desc.text = "Sneasel"
			icon.add_theme_color_override("font_color", main_menu_ref.COLOR_PURPLE)
			
	vbox.add_child(icon)
	vbox.add_child(desc)
	
	# Botón de Reclamar
	var btn = Button.new()
	btn.text = "Reclamar"
	btn.add_theme_font_size_override("font_size", 12)
	
	# Lógica de estados del botón
	var claimed_list = PlayerData.claimed_bp.get(type, [])
	var is_claimed = claimed_list.has(level) or claimed_list.has(str(level))
	var is_unlocked = PlayerData.battle_pass_level >= level
	var needs_premium = type == "premium" and not PlayerData.has_premium_pass
	
	if is_claimed:
		btn.text = "Reclamado"
		btn.disabled = true
	elif not is_unlocked:
		btn.text = "Bloqueado"
		btn.disabled = true
	elif needs_premium:
		btn.text = "Pase Premium"
		btn.disabled = true
	else:
		btn.pressed.connect(func(): _on_claim_pressed(level, type, btn))
		btn.add_theme_color_override("font_color", main_menu_ref.COLOR_GREEN)
		
	vbox.add_child(btn)
	return panel

# ============================================================
# LÓGICA DE DATOS (Espejo del Backend)
# ============================================================
func _get_reward_data(level: int) -> Dictionary:
	var packs = ["typhlosion_pack", "feraligatr_pack", "meganium_pack"]
	var current_pack = packs[level % 3]
	
	var free_r = {"type": "coins", "amount": 25}
	var prem_r = {"type": "coins", "amount": 100}
	
	# Free Logic
	if level % 5 == 0 and level % 10 != 0 and level != 50:
		free_r = {"type": "gems", "amount": 5}
	elif level == 48: free_r = {"type": "pack", "id": current_pack, "amount": 3}
	elif level == 49: free_r = {"type": "pack", "id": current_pack, "amount": 5}
	elif level == 50: free_r = {"type": "card", "id": "sneasel", "amount": 1}
	
	# Premium Logic
	if level % 10 == 0 and level != 50:
		prem_r = {"type": "gems", "amount": 10}
	elif level % 2 != 0 and level < 48:
		prem_r = {"type": "pack", "id": current_pack, "amount": 1}
	elif level == 48: prem_r = {"type": "pack", "id": current_pack, "amount": 5}
	elif level == 49: prem_r = {"type": "pack", "id": current_pack, "amount": 10}
	elif level == 50: prem_r = {"type": "card", "id": "sneasel", "amount": 1}
	
	return {"free": free_r, "premium": prem_r}

# ============================================================
# ACTUALIZAR ESTADO SUPERIOR
# ============================================================
func _update_premium_ui() -> void:
	lbl_gems.text = "💎 Gemas: " + str(PlayerData.gems)
	if PlayerData.has_premium_pass:
		btn_buy.text = "Pase Premium Activado"
		btn_buy.disabled = true
		lbl_status.text = "¡Disfruta de tus recompensas!"
		lbl_status.add_theme_color_override("font_color", main_menu_ref.COLOR_GREEN)
	else:
		btn_buy.text = "Comprar (" + str(PREMIUM_COST) + "💎)"
		btn_buy.disabled = false
		lbl_status.text = "Desbloquea la fila superior."
		lbl_status.add_theme_color_override("font_color", main_menu_ref.COLOR_TEXT_DIM)

# ============================================================
# PETICIONES HTTP
# ============================================================
func _on_buy_pressed() -> void:
	if PlayerData.gems < PREMIUM_COST:
		lbl_status.text = "Gemas insuficientes."
		lbl_status.add_theme_color_override("font_color", main_menu_ref.COLOR_RED)
		return
	btn_buy.disabled = true
	var url = NetworkManager.BASE_URL + "/api/battlepass/buy"
	var headers = ["Content-Type: application/json", "Authorization: Bearer " + NetworkManager.token]
	http_buy.request(url, headers, HTTPClient.METHOD_POST, "")

func _on_buy_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	if response_code == 200:
		var json = JSON.parse_string(body.get_string_from_utf8())
		if json and json.has("success"):
			PlayerData.has_premium_pass = true
			PlayerData.gems = json.get("gems_remaining", PlayerData.gems)
			_update_premium_ui()
			_build_rewards_track() # Refrescar botones
	else:
		btn_buy.disabled = false

func _on_claim_pressed(level: int, type: String, btn_ref: Button) -> void:
	btn_ref.disabled = true
	btn_ref.text = "..."
	var url = NetworkManager.BASE_URL + "/api/battlepass/claim"
	var headers = ["Content-Type: application/json", "Authorization: Bearer " + NetworkManager.token]
	var payload = JSON.stringify({"level": level, "type": type})
	http_claim.request(url, headers, HTTPClient.METHOD_POST, payload)

func _on_claim_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	if response_code == 200:
		var json = JSON.parse_string(body.get_string_from_utf8())
		if json and json.has("success"):
			# Actualizar datos locales
			var reward = json.get("reward", {})
			if reward.get("type") == "gems": 
				PlayerData.gems += reward.get("amount", 0)
			elif reward.get("type") == "coins": 
				PlayerData.coins += reward.get("amount", 0)
			elif reward.get("type") == "pack" or reward.get("type") == "card":
				# ¡AQUÍ ESTÁ LA MAGIA QUE FALTABA! Agregamos el sobre/carta al inventario de Godot
				PlayerData.add_card(reward.get("id", ""), reward.get("amount", 1)) 
			
			main_menu_ref._show_global_toast("¡Recompensa reclamada con éxito!")
			_update_premium_ui()
