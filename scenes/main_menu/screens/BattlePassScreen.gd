extends Control

# ============================================================
# BattlePassScreen.gd — Rediseño v3 con banners separadores
# ============================================================

const XP_PER_LEVEL = 1000
const PREMIUM_COST = 500

var main_menu_ref: Node
var lbl_status:    Label
var lbl_gems:      Label
var btn_buy:       Button
var http_buy:      HTTPRequest
var http_claim:    HTTPRequest
var track_premium: HBoxContainer
var track_free:    HBoxContainer
var _claim_queue:  Array = []

# ── Paleta ───────────────────────────────────────────────────
const C_BG        = Color(0.05, 0.04, 0.09, 1.00)
const C_PANEL     = Color(0.09, 0.08, 0.15, 0.98)
const C_GOLD      = Color(0.95, 0.78, 0.28, 1.00)
const C_GOLD_DIM  = Color(0.50, 0.40, 0.12, 1.00)
const C_PREM_BG   = Color(0.16, 0.10, 0.02, 0.97)
const C_FREE_BG   = Color(0.07, 0.08, 0.13, 0.97)
const C_ACCENT    = Color(0.38, 0.72, 1.00, 1.00)
const C_GREEN     = Color(0.28, 0.88, 0.42, 1.00)
const C_RED       = Color(0.95, 0.28, 0.28, 1.00)
const C_TEXT      = Color(0.90, 0.86, 0.72, 1.00)
const C_TEXT_DIM  = Color(0.45, 0.43, 0.34, 1.00)
const C_CLAIMED   = Color(0.22, 0.68, 0.32, 1.00)
const C_LOCKED    = Color(0.28, 0.26, 0.20, 1.00)

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
	http_claim = HTTPRequest.new(); add_child(http_claim)
	http_claim.request_completed.connect(_on_claim_completed)

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
	root.add_child(_build_banner("res://assets/imagen/banner/banner1.png", "⭐  PASE PREMIUM", C_GOLD,   C_PREM_BG))
	root.add_child(_build_scroll_row("premium"))
	root.add_child(_build_banner("res://assets/imagen/banner/banner2.png", "🆓  PASE GRATUITO", C_ACCENT, C_FREE_BG))
	root.add_child(_build_scroll_row("free"))

	_build_rewards_track()

# ─────────────────────────────────────────────────────────────
# HEADER — centrado, compacto
# ─────────────────────────────────────────────────────────────
func _build_header() -> Control:
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(0, 130)

	var s = StyleBoxFlat.new()
	s.bg_color            = C_PANEL
	s.border_color        = C_GOLD_DIM
	s.border_width_bottom = 2
	s.shadow_color        = Color(0, 0, 0, 0.55)
	s.shadow_size         = 14
	panel.add_theme_stylebox_override("panel", s)

	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_child(center)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	center.add_child(vbox)

	# Título
	var title = Label.new()
	title.text                 = "✦  PASE DE BATALLA  ✦"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", C_GOLD)
	vbox.add_child(title)

	# Nivel + barra XP + gemas — en fila centrada
	var mid = HBoxContainer.new()
	mid.alignment = BoxContainer.ALIGNMENT_CENTER
	mid.add_theme_constant_override("separation", 16)
	vbox.add_child(mid)

	var lbl_lv = Label.new()
	lbl_lv.text = "Niv. %d" % PlayerData.battle_pass_level
	lbl_lv.add_theme_font_size_override("font_size", 13)
	lbl_lv.add_theme_color_override("font_color", C_TEXT)
	lbl_lv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mid.add_child(lbl_lv)

	var xp_bar = ProgressBar.new()
	xp_bar.custom_minimum_size = Vector2(340, 14)
	xp_bar.max_value           = XP_PER_LEVEL
	xp_bar.value               = PlayerData.battle_pass_xp
	xp_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mid.add_child(xp_bar)

	var lbl_xp = Label.new()
	lbl_xp.text = "%d / %d XP" % [PlayerData.battle_pass_xp, XP_PER_LEVEL]
	lbl_xp.add_theme_font_size_override("font_size", 11)
	lbl_xp.add_theme_color_override("font_color", C_TEXT_DIM)
	lbl_xp.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mid.add_child(lbl_xp)

	lbl_gems = Label.new()
	lbl_gems.add_theme_font_size_override("font_size", 13)
	lbl_gems.add_theme_color_override("font_color", C_ACCENT)
	lbl_gems.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mid.add_child(lbl_gems)

	# Botones centrados
	var btn_row = HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 18)
	vbox.add_child(btn_row)

	lbl_status = Label.new()
	lbl_status.add_theme_font_size_override("font_size", 12)
	lbl_status.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	btn_row.add_child(lbl_status)

	var btn_all = _make_button("🎁  Reclamar Todo", Color(0.06, 0.20, 0.10, 0.97), C_GREEN, Vector2(186, 36))
	btn_all.pressed.connect(_on_claim_all_pressed)
	btn_row.add_child(btn_all)

	btn_buy = _make_button("💎  Comprar Pase (%d)" % PREMIUM_COST, C_PREM_BG, C_GOLD, Vector2(218, 36))
	btn_buy.pressed.connect(_on_buy_pressed)
	btn_row.add_child(btn_buy)

	_update_premium_ui()
	return panel

# ─────────────────────────────────────────────────────────────
# BANNER separador con imagen + overlay + texto centrado
# ─────────────────────────────────────────────────────────────
func _build_banner(img_path: String, txt: String, txt_color: Color, tint: Color) -> Control:
	var c = Control.new()
	c.custom_minimum_size = Vector2(0, 48)
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# Imagen de fondo tileada
	var tex = TextureRect.new()
	tex.set_anchors_preset(Control.PRESET_FULL_RECT)
	tex.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	tex.stretch_mode = TextureRect.STRETCH_TILE
	var img = load(img_path)
	if img:
		tex.texture = img
	c.add_child(tex)

	# Overlay semitransparente del color del tipo de pase
	var ov = ColorRect.new()
	ov.set_anchors_preset(Control.PRESET_FULL_RECT)
	ov.color = Color(tint.r, tint.g, tint.b, 0.75)
	c.add_child(ov)

	# Borde dorado arriba
	var ln_top = ColorRect.new()
	ln_top.color = C_GOLD_DIM
	ln_top.anchor_left = 0; ln_top.anchor_right  = 1
	ln_top.anchor_top  = 0; ln_top.anchor_bottom = 0
	ln_top.offset_bottom = 2
	c.add_child(ln_top)

	# Borde dorado abajo
	var ln_bot = ColorRect.new()
	ln_bot.color = C_GOLD_DIM
	ln_bot.anchor_left = 0; ln_bot.anchor_right  = 1
	ln_bot.anchor_top  = 1; ln_bot.anchor_bottom = 1
	ln_bot.offset_top = -2
	c.add_child(ln_bot)

	# Label centrado
	var lbl = Label.new()
	lbl.text                 = txt
	lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", txt_color)
	c.add_child(lbl)

	return c

# ─────────────────────────────────────────────────────────────
# FILA DE SCROLL para una fila de recompensas
# ─────────────────────────────────────────────────────────────
func _build_scroll_row(row_type: String) -> Control:
	var wrapper = Panel.new()
	wrapper.custom_minimum_size = Vector2(0, 162)
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
	margin.add_theme_constant_override("margin_left",   12)
	margin.add_theme_constant_override("margin_right",  12)
	margin.add_theme_constant_override("margin_top",    8)
	margin.add_theme_constant_override("margin_bottom", 8)
	scroll.add_child(margin)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	margin.add_child(hbox)

	if row_type == "premium":
		track_premium = hbox
	else:
		track_free = hbox

	return wrapper

# ─────────────────────────────────────────────────────────────
# CONSTRUIR/REBUILD recompensas
# ─────────────────────────────────────────────────────────────
func _build_rewards_track() -> void:
	for ch in track_premium.get_children(): ch.queue_free()
	for ch in track_free.get_children():    ch.queue_free()
	for i in range(1, 51):
		var r = _get_reward_data(i)
		track_premium.add_child(_create_card(i, "premium", r.premium))
		track_free.add_child(_create_card(i, "free",    r.free))

func _create_card(level: int, row_type: String, data: Dictionary) -> Control:
	var claimed_list = PlayerData.claimed_bp.get(row_type, [])
	var is_claimed   = claimed_list.has(level) or claimed_list.has(str(level))
	var is_unlocked  = PlayerData.battle_pass_level >= level
	var needs_prem   = row_type == "premium" and not PlayerData.has_premium_pass
	var is_prem      = row_type == "premium"

	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(118, 138)

	var ps = StyleBoxFlat.new()
	ps.bg_color = C_PREM_BG if is_prem else C_FREE_BG
	if is_claimed:
		ps.border_color = C_CLAIMED
	elif is_unlocked and not needs_prem:
		ps.border_color = C_GOLD   if is_prem else C_ACCENT
		ps.shadow_color = C_GOLD   if is_prem else C_ACCENT
		ps.shadow_size  = 5
	else:
		ps.border_color = C_LOCKED
	ps.border_width_left  = 2; ps.border_width_right  = 2
	ps.border_width_top   = 2; ps.border_width_bottom = 2
	ps.corner_radius_top_left    = 8; ps.corner_radius_top_right    = 8
	ps.corner_radius_bottom_left = 8; ps.corner_radius_bottom_right = 8
	panel.add_theme_stylebox_override("panel", ps)

	# Chip de nivel — esquina sup-derecha
	var chip = Panel.new()
	chip.position = Vector2(83, 3)
	chip.size     = Vector2(32, 20)
	var cs = StyleBoxFlat.new()
	cs.bg_color = C_GOLD if (is_unlocked and not needs_prem) else C_LOCKED
	cs.corner_radius_top_right    = 6; cs.corner_radius_bottom_left = 4
	cs.corner_radius_top_left     = 4; cs.corner_radius_bottom_right = 4
	chip.add_theme_stylebox_override("panel", cs)
	var chip_lbl = Label.new()
	chip_lbl.text = str(level)
	chip_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	chip_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chip_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	chip_lbl.add_theme_font_size_override("font_size", 10)
	chip_lbl.add_theme_color_override("font_color", C_BG if (is_unlocked and not needs_prem) else C_TEXT_DIM)
	chip.add_child(chip_lbl)
	panel.add_child(chip)

	# Contenido
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 4)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(vbox)

	var icon = Label.new()
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.add_theme_font_size_override("font_size", 28)
	match data.type:
		"coins": icon.text = "🪙"
		"gems":  icon.text = "💎"
		"pack":  icon.text = "📦"
		"card":
			icon.text = "🃏"
			icon.add_theme_color_override("font_color", Color(0.68, 0.38, 1.00))
	vbox.add_child(icon)

	var desc = Label.new()
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.add_theme_font_size_override("font_size", 11)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_color_override("font_color", C_TEXT)
	match data.type:
		"coins": desc.text = "%d Monedas" % data.amount
		"gems":  desc.text = "%d Gemas"   % data.amount
		"pack":  desc.text = "%dx Sobre"  % data.amount
		"card":  desc.text = "Sneasel"
	vbox.add_child(desc)

	var btn = Button.new()
	btn.add_theme_font_size_override("font_size", 11)
	btn.custom_minimum_size        = Vector2(100, 26)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	if is_claimed:
		btn.text = "✓ Listo"; btn.disabled = true
		_style_btn(btn, Color(0.07, 0.17, 0.09, 0.8), C_CLAIMED)
	elif not is_unlocked:
		btn.text = "🔒"; btn.disabled = true
		_style_btn(btn, Color(0.07, 0.07, 0.09, 0.6), C_LOCKED)
	elif needs_prem:
		btn.text = "⭐ Premium"; btn.disabled = true
		_style_btn(btn, C_PREM_BG, C_GOLD_DIM)
	else:
		btn.text = "Reclamar"
		_style_btn(btn, C_PREM_BG if is_prem else Color(0.05, 0.11, 0.19, 0.97),
						C_GOLD    if is_prem else C_ACCENT)
		btn.pressed.connect(func(): _on_claim_pressed(level, row_type, btn))
	vbox.add_child(btn)
	return panel

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
		s.bg_color     = bg.lightened(0.08) if st == "hover" else bg
		if st == "disabled": s.bg_color = bg.darkened(0.25)
		s.border_color = border if st != "disabled" else border.darkened(0.4)
		s.border_width_left  = 2; s.border_width_right  = 2
		s.border_width_top   = 2; s.border_width_bottom = 2
		s.corner_radius_top_left    = 7; s.corner_radius_top_right    = 7
		s.corner_radius_bottom_left = 7; s.corner_radius_bottom_right = 7
		if st == "hover": s.shadow_color = border; s.shadow_size = 8
		btn.add_theme_stylebox_override(st, s)
	btn.add_theme_color_override("font_color",          border)
	btn.add_theme_color_override("font_disabled_color", border.darkened(0.4))

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
		_style_btn(btn_buy, Color(0.06, 0.20, 0.10, 0.97), C_GREEN)
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
			var cl = PlayerData.claimed_bp.get(rt, [])
			var is_claimed  = cl.has(i) or cl.has(str(i))
			var is_unlocked = PlayerData.battle_pass_level >= i
			var needs_prem  = rt == "premium" and not PlayerData.has_premium_pass
			if not is_claimed and is_unlocked and not needs_prem:
				_claim_queue.append({"level": i, "type": rt})
	if _claim_queue.is_empty():
		main_menu_ref._show_global_toast("No hay recompensas pendientes"); return

	for entry in _claim_queue:
		if not PlayerData.claimed_bp.has(entry.type):
			PlayerData.claimed_bp[entry.type] = []
		if not PlayerData.claimed_bp[entry.type].has(entry.level):
			PlayerData.claimed_bp[entry.type].append(entry.level)

	_build_rewards_track()
	main_menu_ref._show_global_toast("Reclamando %d recompensas..." % _claim_queue.size())
	_process_claim_queue()

func _process_claim_queue() -> void:
	if _claim_queue.is_empty():
		main_menu_ref._show_global_toast("¡Todo reclamado!"); _update_premium_ui(); return
	var nx = _claim_queue[0]; _claim_queue.remove_at(0)
	_send_claim_request(nx.level, nx.type, null)

func _send_claim_request(level: int, row_type: String, btn_ref) -> void:
	if btn_ref: btn_ref.disabled = true; btn_ref.text = "..."
	var url     = NetworkManager.BASE_URL + "/api/battlepass/claim"
	var headers = ["Content-Type: application/json", "Authorization: Bearer " + NetworkManager.token]
	http_claim.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify({"level": level, "type": row_type}))

# ─────────────────────────────────────────────────────────────
# HTTP
# ─────────────────────────────────────────────────────────────
func _on_buy_pressed() -> void:
	if PlayerData.gems < PREMIUM_COST:
		lbl_status.text = "Gemas insuficientes."
		lbl_status.add_theme_color_override("font_color", C_RED); return
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
			_update_premium_ui(); _build_rewards_track()
			main_menu_ref._show_global_toast("¡Pase Premium activado!")
	else:
		btn_buy.disabled = false

func _on_claim_pressed(level: int, row_type: String, btn_ref: Button) -> void:
	_send_claim_request(level, row_type, btn_ref)

func _on_claim_completed(_r: int, code: int, _h: PackedStringArray, body: PackedByteArray) -> void:
	if code == 200:
		var json = JSON.parse_string(body.get_string_from_utf8())
		if json and json.has("success"):
			var reward = json.get("reward", {})
			match reward.get("type", ""):
				"gems":         PlayerData.gems   += reward.get("amount", 0)
				"coins":        PlayerData.coins  += reward.get("amount", 0)
				"pack", "card": PlayerData.add_card(reward.get("id", ""), reward.get("amount", 1))

			var lvl = json.get("level", -1); var tp = json.get("type", "")
			if lvl > 0 and tp != "":
				if not PlayerData.claimed_bp.has(tp): PlayerData.claimed_bp[tp] = []
				if not PlayerData.claimed_bp[tp].has(lvl): PlayerData.claimed_bp[tp].append(lvl)

			_update_premium_ui()
			if not _claim_queue.is_empty():
				_process_claim_queue()
			else:
				_build_rewards_track()
				main_menu_ref._show_global_toast("¡Recompensa reclamada!")
