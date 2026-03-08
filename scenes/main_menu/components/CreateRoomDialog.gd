extends Node

# ============================================================
# scenes/main_menu/components/CreateRoomDialog.gd
# ============================================================

const TIERS       = ["C", "B", "A", "S", "SS"]
const TIER_COLORS = [
	Color("#8ecae6"),
	Color("#52b788"),
	Color("#f4a261"),
	Color("#e63946"),
	Color("#c77dff"),
]
const TIER_ACCESS_OPTIONS = [
	{"label": "Todos los tiers",    "value": "all"},
	{"label": "Solo mi tier",       "value": "equal"},
	{"label": "Mi tier o inferior", "value": "down"},
]
const WAGER_TYPE_OPTIONS = [
	{"label": "🪙 Monedas", "value": "coins"},
	{"label": "💎 Gemas",   "value": "gems"},
	{"label": "📦 Sobres",  "value": "packs"},
]

var _C
var _container:   Control
var _dialog:      PanelContainer
var _overlay:     ColorRect
var _center:      CenterContainer

var _selected_mode:        String = "casual"
var _selected_tier:        String = "C"   # se setea al abrir, no editable por el usuario
var _selected_tier_access: String = "all"
var _selected_wager_type:  String = "coins"

var _wager_section:   Control
var _wager_amount_sp: SpinBox
var _password_input:  LineEdit
var _name_input:      LineEdit
var _confirm_btn:     Button

# ─────────────────────────────────────────────────────────────
func open(container: Control, menu) -> void:
	_C         = menu
	_container = container
	container.add_child(self)
	_build()

func _build() -> void:
	# ── Overlay ──
	_overlay = ColorRect.new()
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.color = Color(0, 0, 0, 0.65)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_container.add_child(_overlay)
	_overlay.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed: _close()
	)

	# ── Panel centrado ──
	_center = CenterContainer.new()
	_center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_container.add_child(_center)

	_dialog = PanelContainer.new()
	_dialog.custom_minimum_size = Vector2(480, 0)
	var ps = StyleBoxFlat.new()
	ps.bg_color     = Color("#0d1117")
	ps.border_color = Color("#c9a84c")
	ps.border_width_left = 2; ps.border_width_right  = 2
	ps.border_width_top  = 2; ps.border_width_bottom = 2
	ps.corner_radius_top_left    = 12; ps.corner_radius_top_right    = 12
	ps.corner_radius_bottom_left = 12; ps.corner_radius_bottom_right = 12
	ps.shadow_color = Color(0,0,0,0.6); ps.shadow_size = 24
	_dialog.add_theme_stylebox_override("panel", ps)
	_center.add_child(_dialog)

	var outer = VBoxContainer.new()
	outer.add_theme_constant_override("separation", 0)
	_dialog.add_child(outer)

	var strip = ColorRect.new()
	strip.color = Color("#c9a84c")
	strip.custom_minimum_size = Vector2(0, 4)
	outer.add_child(strip)

	var body = MarginContainer.new()
	body.add_theme_constant_override("margin_left",   28)
	body.add_theme_constant_override("margin_right",  28)
	body.add_theme_constant_override("margin_top",    20)
	body.add_theme_constant_override("margin_bottom", 24)
	outer.add_child(body)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 18)
	body.add_child(vbox)

	# ── Título + botón X ──
	var title_row = HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 8)
	var title_lbl = Label.new()
	title_lbl.text = "◈ CREAR NUEVA MESA"
	title_lbl.add_theme_font_size_override("font_size", 17)
	title_lbl.add_theme_color_override("font_color", Color("#c9a84c"))
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(title_lbl)

	var close_btn = Button.new()
	close_btn.text = "✕"
	close_btn.flat = true
	close_btn.add_theme_color_override("font_color", Color("#aaa"))
	close_btn.add_theme_font_size_override("font_size", 16)
	close_btn.custom_minimum_size = Vector2(32, 32)
	close_btn.pressed.connect(func(): _close())
	title_row.add_child(close_btn)
	vbox.add_child(title_row)

	vbox.add_child(_divider())

	# ── Nombre de la mesa ──
	vbox.add_child(_section_label("Nombre de la mesa"))
	_name_input = LineEdit.new()
	_name_input.placeholder_text = "Ej: Mesa Tier A · Sin prisas"
	_name_input.max_length = 50
	_style_input(_name_input)
	vbox.add_child(_name_input)

	# ── Modo ──
	vbox.add_child(_section_label("Modo de juego"))
	var mode_hbox = HBoxContainer.new()
	mode_hbox.add_theme_constant_override("separation", 10)
	vbox.add_child(mode_hbox)
	_add_mode_btn(mode_hbox, "casual",  "🎮 Casual",  Color("#3a4a6b"))
	_add_mode_btn(mode_hbox, "ranking", "🏆 Ranking", Color("#3a4a2b"))
	_add_mode_btn(mode_hbox, "wager",   "💰 Apuesta", Color("#4a3a1b"))

	# ── Sección apuesta ──
	_wager_section = VBoxContainer.new()
	_wager_section.add_theme_constant_override("separation", 10)
	_wager_section.visible = false
	vbox.add_child(_wager_section)

	_wager_section.add_child(_section_label("Tipo de apuesta"))
	var wager_hbox = HBoxContainer.new()
	wager_hbox.add_theme_constant_override("separation", 8)
	_wager_section.add_child(wager_hbox)
	for opt in WAGER_TYPE_OPTIONS:
		_add_wager_type_btn(wager_hbox, opt.value, opt.label)

	var amount_row = HBoxContainer.new()
	amount_row.add_theme_constant_override("separation", 10)
	_wager_section.add_child(amount_row)

	var amt_lbl = Label.new()
	amt_lbl.text = "Cantidad:"
	amt_lbl.add_theme_color_override("font_color", Color("#aaa"))
	amt_lbl.add_theme_font_size_override("font_size", 12)
	amt_lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	amount_row.add_child(amt_lbl)

	_wager_amount_sp = SpinBox.new()
	_wager_amount_sp.min_value = 1
	_wager_amount_sp.max_value = max(1, PlayerData.coins)
	_wager_amount_sp.value     = 1
	_wager_amount_sp.step      = 1
	_wager_amount_sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	amount_row.add_child(_wager_amount_sp)

	var funds_lbl = Label.new()
	funds_lbl.name = "FundsLabel"
	funds_lbl.add_theme_font_size_override("font_size", 10)
	_wager_section.add_child(funds_lbl)

	# ── Tier del deck — badge informativo, no editable ──
	var auto_tier = _get_active_deck_tier()
	_selected_tier = auto_tier

	var tier_info_row = HBoxContainer.new()
	tier_info_row.add_theme_constant_override("separation", 8)
	tier_info_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(tier_info_row)

	var tier_desc = Label.new()
	tier_desc.text = "Tier del deck:"
	tier_desc.add_theme_font_size_override("font_size", 12)
	tier_desc.add_theme_color_override("font_color", Color("#c9a84c"))
	tier_desc.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tier_info_row.add_child(tier_desc)

	var tier_idx    = TIERS.find(auto_tier)
	var tier_color  = TIER_COLORS[tier_idx] if tier_idx >= 0 else Color("#aaa")
	var tier_badge  = Label.new()
	tier_badge.text = "  " + auto_tier + "  "
	tier_badge.add_theme_font_size_override("font_size", 13)
	tier_badge.add_theme_color_override("font_color", tier_color)
	var badge_style = StyleBoxFlat.new()
	badge_style.bg_color     = Color(tier_color.r, tier_color.g, tier_color.b, 0.18)
	badge_style.border_color = tier_color
	badge_style.border_width_left = 1; badge_style.border_width_right  = 1
	badge_style.border_width_top  = 1; badge_style.border_width_bottom = 1
	badge_style.corner_radius_top_left    = 6; badge_style.corner_radius_top_right    = 6
	badge_style.corner_radius_bottom_left = 6; badge_style.corner_radius_bottom_right = 6
	tier_badge.add_theme_stylebox_override("normal", badge_style)
	tier_badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tier_info_row.add_child(tier_badge)

	var tier_hint = Label.new()
	tier_hint.text = "(calculado automáticamente desde tu mazo activo)"
	tier_hint.add_theme_font_size_override("font_size", 10)
	tier_hint.add_theme_color_override("font_color", Color("#666"))
	tier_hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tier_hint.size_flags_vertical   = Control.SIZE_SHRINK_CENTER
	tier_info_row.add_child(tier_hint)

	# ── Acceso por tier ──
	vbox.add_child(_section_label("¿Quién puede entrar?"))
	var access_hbox = HBoxContainer.new()
	access_hbox.add_theme_constant_override("separation", 8)
	vbox.add_child(access_hbox)
	for opt in TIER_ACCESS_OPTIONS:
		_add_access_btn(access_hbox, opt.value, opt.label)

	# ── Contraseña ──
	var pw_row = HBoxContainer.new()
	pw_row.add_theme_constant_override("separation", 8)
	vbox.add_child(pw_row)
	var pw_lbl = Label.new()
	pw_lbl.text = "🔒 Contraseña (opcional):"
	pw_lbl.add_theme_color_override("font_color", Color("#888"))
	pw_lbl.add_theme_font_size_override("font_size", 11)
	pw_lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pw_row.add_child(pw_lbl)
	_password_input = LineEdit.new()
	_password_input.placeholder_text = "Dejar vacío = pública"
	_password_input.secret = true
	_password_input.max_length = 20
	_password_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_input(_password_input)
	pw_row.add_child(_password_input)

	vbox.add_child(_divider())

	# ── Confirmar ──
	_confirm_btn = Button.new()
	_confirm_btn.text = "CREAR MESA"
	_confirm_btn.custom_minimum_size = Vector2(0, 46)
	_confirm_btn.add_theme_font_size_override("font_size", 14)
	_confirm_btn.add_theme_color_override("font_color", Color("#0d1117"))
	var st = StyleBoxFlat.new()
	st.bg_color = Color("#c9a84c")
	st.corner_radius_top_left    = 8; st.corner_radius_top_right    = 8
	st.corner_radius_bottom_left = 8; st.corner_radius_bottom_right = 8
	_confirm_btn.add_theme_stylebox_override("normal", st)
	_confirm_btn.add_theme_stylebox_override("hover",  st)
	_confirm_btn.pressed.connect(func(): _on_confirm())
	vbox.add_child(_confirm_btn)

	# Selecciones por defecto
	_select_mode("casual")
	_select_access("all")
	_select_wager_type("coins")

# ── Autodetección del tier del deck activo ───────────────────
func _get_active_deck_tier() -> String:
	var slot_str  = str(PlayerData.active_deck_slot)
	var deck_data = PlayerData.decks.get(slot_str)
	if deck_data is Dictionary:
		var t = deck_data.get("tier", "")
		if t != "" and t in TIERS:
			return t
	return PlayerData.tier if PlayerData.tier in TIERS else "C"

# ── Helpers de UI ────────────────────────────────────────────
func _section_label(text: String) -> Label:
	var lbl = Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.add_theme_color_override("font_color", Color("#c9a84c"))
	return lbl

func _divider() -> ColorRect:
	var d = ColorRect.new()
	d.color = Color("#c9a84c", 0.25)
	d.custom_minimum_size = Vector2(0, 1)
	return d

func _style_input(input: LineEdit) -> void:
	var st = StyleBoxFlat.new()
	st.bg_color     = Color("#1a2030")
	st.border_color = Color("#3a4560")
	st.border_width_left = 1; st.border_width_right  = 1
	st.border_width_top  = 1; st.border_width_bottom = 1
	st.corner_radius_top_left    = 6; st.corner_radius_top_right    = 6
	st.corner_radius_bottom_left = 6; st.corner_radius_bottom_right = 6
	input.add_theme_stylebox_override("normal", st)
	input.add_theme_stylebox_override("focus",  st)
	input.add_theme_color_override("font_color", Color("#ddd"))

func _pill_btn(parent: Control, id: String, label: String, base_color: Color) -> Button:
	var btn = Button.new()
	btn.text = label
	btn.name = "btn_" + id
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.custom_minimum_size = Vector2(0, 36)
	btn.add_theme_font_size_override("font_size", 12)
	var st_normal = StyleBoxFlat.new()
	st_normal.bg_color     = Color(base_color.r, base_color.g, base_color.b, 0.4)
	st_normal.border_color = Color(base_color.r, base_color.g, base_color.b, 0.5)
	st_normal.border_width_left = 1; st_normal.border_width_right  = 1
	st_normal.border_width_top  = 1; st_normal.border_width_bottom = 1
	st_normal.corner_radius_top_left    = 6; st_normal.corner_radius_top_right    = 6
	st_normal.corner_radius_bottom_left = 6; st_normal.corner_radius_bottom_right = 6
	var st_selected = StyleBoxFlat.new()
	st_selected.bg_color = base_color
	st_selected.corner_radius_top_left    = 6; st_selected.corner_radius_top_right    = 6
	st_selected.corner_radius_bottom_left = 6; st_selected.corner_radius_bottom_right = 6
	btn.set_meta("st_normal",   st_normal)
	btn.set_meta("st_selected", st_selected)
	btn.add_theme_stylebox_override("normal", st_normal)
	btn.add_theme_stylebox_override("hover",  st_normal)
	btn.add_theme_color_override("font_color", Color("#ccc"))
	parent.add_child(btn)
	return btn

func _add_mode_btn(parent, mode_id, label, color) -> void:
	var btn = _pill_btn(parent, mode_id, label, color)
	btn.pressed.connect(func(): _select_mode(mode_id))

func _add_access_btn(parent, access_id, label) -> void:
	var btn = _pill_btn(parent, access_id, label, Color("#334"))
	btn.pressed.connect(func(): _select_access(access_id))

func _add_wager_type_btn(parent, wt_id, label) -> void:
	var btn = _pill_btn(parent, wt_id, label, Color("#443"))
	btn.pressed.connect(func(): _select_wager_type(wt_id))

# ── Selección ────────────────────────────────────────────────
func _select_mode(mode: String) -> void:
	_selected_mode = mode
	_refresh_btns(_dialog, ["casual", "ranking", "wager"], mode)
	_wager_section.visible = (mode == "wager")

func _select_access(access: String) -> void:
	_selected_tier_access = access
	_refresh_btns(_dialog, ["all", "equal", "down"], access)

func _select_wager_type(wt: String) -> void:
	_selected_wager_type = wt
	_refresh_btns(_dialog, ["coins", "gems", "packs"], wt)
	_update_funds_label()

func _update_funds_label() -> void:
	if not _wager_amount_sp: return
	var funds_lbl: Label = _wager_section.get_node_or_null("FundsLabel") if _wager_section else null
	var available: int
	var icon: String
	match _selected_wager_type:
		"coins":
			available = PlayerData.coins
			icon = "🪙"
		"gems":
			available = PlayerData.gems
			icon = "💎"
		"packs":
			available = PlayerData.unopened_packs if "unopened_packs" in PlayerData else 0
			icon = "📦"
		_:
			available = 0
			icon = "?"
	_wager_amount_sp.max_value = max(1, available)
	_wager_amount_sp.value     = clamp(_wager_amount_sp.value, 1, _wager_amount_sp.max_value)
	if funds_lbl:
		var col = Color("#52b788") if available > 0 else Color("#e63946")
		funds_lbl.text = "Tienes: " + icon + " " + str(available)
		funds_lbl.add_theme_color_override("font_color", col)

func _refresh_btns(root: Control, ids: Array, selected: String) -> void:
	for id in ids:
		var btn: Button = UITheme.find_node(root, "btn_" + id)
		if btn:
			var is_sel = (id == selected)
			btn.add_theme_stylebox_override("normal",
				btn.get_meta("st_selected") if is_sel else btn.get_meta("st_normal"))
			btn.add_theme_stylebox_override("hover",
				btn.get_meta("st_selected") if is_sel else btn.get_meta("st_normal"))

# ── Confirmar ────────────────────────────────────────────────
func _on_confirm() -> void:
	if not NetworkManager.ws_connected:
		push_warning("[CreateRoomDialog] No conectado al servidor")
		return
	var active_deck = PlayerData.get_active_deck()
	if active_deck.size() != 60:
		push_warning("[CreateRoomDialog] Deck incompleto: %d/60" % active_deck.size())
		return
	if _selected_mode == "wager":
		var amount = int(_wager_amount_sp.value)
		match _selected_wager_type:
			"coins":
				if PlayerData.coins < amount:
					push_warning("[CreateRoomDialog] Monedas insuficientes (%d/%d)" % [PlayerData.coins, amount])
					return
			"gems":
				if PlayerData.gems < amount:
					push_warning("[CreateRoomDialog] Gemas insuficientes (%d/%d)" % [PlayerData.gems, amount])
					return
			"packs":
				var avail = PlayerData.unopened_packs if "unopened_packs" in PlayerData else 0
				if avail < amount:
					push_warning("[CreateRoomDialog] Sobres insuficientes (%d/%d)" % [avail, amount])
					return

	var options: Dictionary = {
		"mode":        _selected_mode,
		"deck_tier":   _selected_tier,
		"tier_access": _selected_tier_access,
		"name":        _name_input.text.strip_edges(),
		"password":    _password_input.text.strip_edges(),
	}
	if _selected_mode == "wager":
		options["wager"] = {
			"type":   _selected_wager_type,
			"amount": int(_wager_amount_sp.value),
		}
	NetworkManager.create_room(active_deck, options)
	_close()

# ── Cerrar — borra overlay + center + self ───────────────────
func _close() -> void:
	if is_instance_valid(_overlay): _overlay.queue_free()
	if is_instance_valid(_center):  _center.queue_free()
	queue_free()
