extends Node

# ============================================================
# scenes/main_menu/components/RoomCard.gd
# ============================================================

const TIER_COLORS = {
	"C":  Color("#8ecae6"),
	"B":  Color("#52b788"),
	"A":  Color("#f4a261"),
	"S":  Color("#e63946"),
	"SS": Color("#c77dff"),
}
const MODE_COLORS = {
	"casual":  Color("#4a90d9"),
	"ranking": Color("#52b788"),
	"wager":   Color("#e8a838"),
}
const MODE_ICONS = {
	"casual":  "🎮",
	"ranking": "🏆",
	"wager":   "💰",
}
const TIER_ACCESS_LABELS = {
	"all":   "Todos",
	"equal": "Solo mi tier",
	"down":  "Mi tier o ↓",
}

static func make(room: Dictionary, menu) -> Control:
	var C = menu

	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(340, 0)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var ps = StyleBoxFlat.new()
	ps.bg_color     = Color(C.COLOR_PANEL.r, C.COLOR_PANEL.g, C.COLOR_PANEL.b, 0.92)
	ps.border_color = Color(C.COLOR_GOLD_DIM.r, C.COLOR_GOLD_DIM.g, C.COLOR_GOLD_DIM.b, 0.25)
	ps.border_width_left = 1; ps.border_width_right  = 1
	ps.border_width_top  = 1; ps.border_width_bottom = 1
	ps.corner_radius_top_left    = 10; ps.corner_radius_top_right    = 10
	ps.corner_radius_bottom_left = 10; ps.corner_radius_bottom_right = 10
	ps.shadow_color = Color(0,0,0,0.3); ps.shadow_size = 8
	panel.add_theme_stylebox_override("panel", ps)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 0)
	panel.add_child(vbox)

	# ── Franja de color del modo ──
	var mode     = room.get("mode", "casual")
	var tier     = room.get("deck_tier", "C")
	var status   = room.get("status", "waiting")
	var mode_col = MODE_COLORS.get(mode, Color("#555"))
	var tier_col = TIER_COLORS.get(tier, Color("#888"))

	var top_strip = ColorRect.new()
	top_strip.color = mode_col
	top_strip.custom_minimum_size = Vector2(0, 4)
	vbox.add_child(top_strip)

	var body_m = MarginContainer.new()
	body_m.add_theme_constant_override("margin_left",   18)
	body_m.add_theme_constant_override("margin_right",  18)
	body_m.add_theme_constant_override("margin_top",    14)
	body_m.add_theme_constant_override("margin_bottom", 14)
	vbox.add_child(body_m)

	var body = VBoxContainer.new()
	body.add_theme_constant_override("separation", 10)
	body_m.add_child(body)

	# ── Fila: modo + tier + estado ──
	var row1 = HBoxContainer.new()
	row1.add_theme_constant_override("separation", 6)
	body.add_child(row1)

	row1.add_child(_badge(MODE_ICONS.get(mode, "?") + " " + mode.capitalize(), mode_col, Color("#fff")))
	row1.add_child(_badge("Tier " + tier, tier_col, Color("#fff")))

	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row1.add_child(spacer)

	var status_col = Color("#52b788") if status == "waiting" else Color("#e63946")
	var status_lbl = Label.new()
	status_lbl.text = "● EN ESPERA" if status == "waiting" else "● EN JUEGO"
	status_lbl.add_theme_font_size_override("font_size", 10)
	status_lbl.add_theme_color_override("font_color", status_col)
	row1.add_child(status_lbl)

	# ── Nombre de la mesa ──
	# Usar host_username si existe, si no el campo name, si no "Mesa de <username>"
	var host_username = room.get("host_username", room.get("host_name", ""))
	var fallback_name = ("Mesa de " + host_username) if host_username != "" else "Mesa sin nombre"
	var name_str = room.get("name", fallback_name)
	if name_str == "" or name_str == null:
		name_str = fallback_name

	var name_lbl = Label.new()
	name_lbl.text = name_str
	name_lbl.add_theme_font_size_override("font_size", 15)
	name_lbl.add_theme_color_override("font_color", Color("#ffffff"))
	name_lbl.clip_text = true
	body.add_child(name_lbl)

	# ── Host info ──
	if host_username != "":
		var host_row = HBoxContainer.new()
		host_row.add_theme_constant_override("separation", 4)
		body.add_child(host_row)
		var host_lbl = Label.new()
		host_lbl.text = "🧢 " + host_username
		host_lbl.add_theme_font_size_override("font_size", 11)
		host_lbl.add_theme_color_override("font_color", Color("#aaaaaa"))
		host_row.add_child(host_lbl)

		# ELO del host si viene
		var h_elo = room.get("h_elo", 0)
		if h_elo > 0:
			var elo_lbl = Label.new()
			elo_lbl.text = "· ELO " + str(h_elo)
			elo_lbl.add_theme_font_size_override("font_size", 11)
			elo_lbl.add_theme_color_override("font_color", Color("#666"))
			host_row.add_child(elo_lbl)

	# ── Fila: jugadores + espectadores + cerrojo + acceso ──
	var row2 = HBoxContainer.new()
	row2.add_theme_constant_override("separation", 10)
	body.add_child(row2)

	_info_lbl(row2, "👥 " + str(room.get("players", 1)) + "/2", Color("#aaa"))
	_info_lbl(row2, "👁 " + str(room.get("spectators", 0)), Color("#aaa"))
	if room.get("has_password", false):
		_info_lbl(row2, "🔒", Color("#f4a261"))
	_info_lbl(row2, "🎯 " + TIER_ACCESS_LABELS.get(room.get("tier_access", "all"), "Todos"), Color("#888"))

	# ── Apuesta ──
	var wager = room.get("wager", null)
	if wager and mode == "wager":
		var wager_icon = "🪙" if wager.get("type","") == "coins" else ("💎" if wager.get("type","") == "gems" else "📦")
		var wl = Label.new()
		wl.text = "Apuesta: " + wager_icon + " " + str(wager.get("amount", 0))
		wl.add_theme_font_size_override("font_size", 12)
		wl.add_theme_color_override("font_color", Color("#e8a838"))
		body.add_child(wl)

	# ── Botones ──
	var btn_row = HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 8)
	body.add_child(btn_row)

	var the_room_id = room.get("room_id", room.get("id", ""))

	var spectate_btn = _mk_btn("👁 ESPECTAR", Color(0.15, 0.2, 0.3), Color("#7eb8e8"), 0)
	spectate_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spectate_btn.pressed.connect(func():
		if not NetworkManager.ws_connected: return
		if the_room_id == "": push_warning("[RoomCard] room_id vacío"); return
		NetworkManager.spectate_room(the_room_id)
	)
	btn_row.add_child(spectate_btn)

	if status == "waiting" and room.get("players", 1) < 2:
		var join_btn = _mk_btn("⚔ UNIRSE", C.COLOR_GOLD, C.COLOR_PANEL, 0)
		join_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		join_btn.pressed.connect(func():
			if not NetworkManager.ws_connected: return
			var active_deck = PlayerData.get_active_deck()
			if active_deck.size() != 60:
				push_warning("[RoomCard] Deck incompleto (%d/60)" % active_deck.size()); return
			NetworkManager.join_room(the_room_id, active_deck, PlayerData.get_deck_tier(PlayerData.active_deck_slot))
		)
		btn_row.add_child(join_btn)

	return panel


static func _badge(text: String, bg: Color, fg: Color) -> Label:
	var lbl = Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.add_theme_color_override("font_color", fg)
	var st = StyleBoxFlat.new()
	st.bg_color = Color(bg.r, bg.g, bg.b, 0.85)
	st.corner_radius_top_left    = 4; st.corner_radius_top_right    = 4
	st.corner_radius_bottom_left = 4; st.corner_radius_bottom_right = 4
	st.content_margin_left  = 6; st.content_margin_right  = 6
	st.content_margin_top   = 2; st.content_margin_bottom = 2
	lbl.add_theme_stylebox_override("normal", st)
	return lbl

static func _info_lbl(parent: Control, text: String, color: Color) -> void:
	var lbl = Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.add_theme_color_override("font_color", color)
	parent.add_child(lbl)

static func _mk_btn(text: String, bg: Color, fg: Color, min_w: int) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(min_w if min_w > 0 else 0, 36)
	btn.add_theme_font_size_override("font_size", 12)
	btn.add_theme_color_override("font_color", fg)
	var st = StyleBoxFlat.new()
	st.bg_color = bg
	st.corner_radius_top_left    = 6; st.corner_radius_top_right    = 6
	st.corner_radius_bottom_left = 6; st.corner_radius_bottom_right = 6
	var st_hov = st.duplicate()
	st_hov.bg_color = Color(bg.r * 1.2, bg.g * 1.2, bg.b * 1.2, 1.0).clamp()
	btn.add_theme_stylebox_override("normal", st)
	btn.add_theme_stylebox_override("hover",  st_hov)
	return btn
