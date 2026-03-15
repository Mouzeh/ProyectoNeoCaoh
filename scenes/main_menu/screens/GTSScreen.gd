## ============================================================
## GTSScreen.gd — Global Trade System
## Zoom idéntico a CollectionScreen · Cartas tamaño Collection
## Mercado agrupado · Panel detalle expandido
## ============================================================
extends Control

const CollectionScreen = preload("res://scenes/main_menu/screens/CollectionScreen.gd")

var _menu = null

enum Tab { SCRAP, MARKET, TRADE, AUCTION }
var _current_tab: int = Tab.SCRAP

var _scrap_selected: Array    = []
var _market_listings: Array   = []
var _trade_listings:  Array   = []
var _auction_listings: Array  = []
var _market_grouped: Dictionary = {}   # { card_id -> [listing, ...] }

var _tab_scrap:   Control = null
var _tab_market:  Control = null
var _tab_trade:   Control = null
var _tab_auction: Control = null

var _scrap_grid:          GridContainer = null
var _scrap_preview_label: Label         = null
var _scrap_confirm_btn:   Button        = null
var _market_grid:         GridContainer = null
var _trade_grid:          GridContainer = null
var _auction_grid:        GridContainer = null
var _trade_my_card_menu:  OptionButton  = null
var _market_detail_panel: Control       = null
var _market_detail_scroll: ScrollContainer = null

var _market_min_power: int    = 0
var _market_max_price: int    = 999999
var _market_sort:      String = "price_asc"
var _trade_min_power:  int    = 0
var _trade_max_power:  int    = 999

var _tab_buttons: Array = []

# ── Paleta ────────────────────────────────────────────────
const C_DARK     := Color(0.03, 0.04, 0.07, 1.0)
const C_DARK2    := Color(0.05, 0.06, 0.10, 1.0)
const C_SURFACE  := Color(0.08, 0.10, 0.16, 1.0)
const C_SURFACE2 := Color(0.11, 0.14, 0.21, 1.0)
const C_GOLD     := Color(1.00, 0.82, 0.30, 1.0)
const C_GOLD_DIM := Color(0.70, 0.55, 0.18, 1.0)
const C_TEAL     := Color(0.20, 0.85, 0.75, 1.0)
const C_RED      := Color(1.00, 0.32, 0.32, 1.0)
const C_GREEN    := Color(0.30, 0.95, 0.55, 1.0)
const C_PURPLE   := Color(0.60, 0.50, 1.00, 1.0)
const C_TEXT     := Color(0.92, 0.90, 0.88, 1.0)
const C_TEXT_DIM := Color(0.50, 0.52, 0.58, 1.0)
const C_BORDER   := Color(1.00, 0.82, 0.30, 0.18)

# Mismo slot que CollectionScreen (100×140) × 1.55
const SLOT_W := 155
const SLOT_H := 217
const IMG_H  := 155   # imagen ocupa casi todo

const _DEBUG := true
func _log(tag: String, msg: String) -> void:
	if _DEBUG: print("[GTS][%s] %s" % [tag, msg])
func _log_request(m: String, u: String, b: String = "") -> void:
	if not _DEBUG: return
	print("[GTS][REQ] %s %s" % [m, u])
	if b != "" and b != "{}": print("[GTS][REQ] body: %s" % b.left(300))
func _log_response(tag: String, code: int, body: PackedByteArray) -> void:
	if not _DEBUG: return
	print("[GTS][RES][%s] %d  %s" % [tag, code, body.get_string_from_utf8().left(400)])


# ============================================================
static func build(container: Control, menu) -> void:
	var screen = load("res://scenes/main_menu/screens/GTSScreen.gd").new()
	screen.name = "GTSScreenNode"
	screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	screen._menu = menu
	container.add_child(screen)


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	_show_tab(Tab.SCRAP)


# ============================================================
# COINS LABEL REFRESH
# ============================================================
func _refresh_coins_label() -> void:
	var lbl = find_child("CoinsLabel", true, false) as Label
	if is_instance_valid(lbl):
		lbl.text = "🪙  " + str(PlayerData.coins)


# ============================================================
# ZOOM — Copia exacta del patrón de CollectionScreen._show_revealed_card_zoom
# ============================================================
func _show_card_zoom(card_id: String) -> void:
	# Igual que CollectionScreen: busca en el nodo raíz para no duplicar
	if get_node_or_null("CardZoom"): return

	var card     = CardDatabase.get_card(card_id)
	var img_path = _get_card_image_path(card_id)
	var rarity   = card.get("rarity", "COMMON")
	var rc       = _rarity_color(rarity)

	# 1. Overlay oscuro — igual que en CollectionScreen
	var zoom_overlay = ColorRect.new()
	zoom_overlay.name  = "CardZoom"
	zoom_overlay.color = Color(0, 0, 0, 0)
	zoom_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	zoom_overlay.z_index      = 400
	zoom_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(zoom_overlay)
	zoom_overlay.create_tween().tween_property(zoom_overlay, "color:a", 0.82, 0.15)

	# 2. CenterContainer para centrar — igual que CollectionScreen
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	zoom_overlay.add_child(center)

	var wrap = VBoxContainer.new()
	wrap.alignment = BoxContainer.ALIGNMENT_CENTER
	wrap.add_theme_constant_override("separation", 18)
	center.add_child(wrap)

	# 3. Panel de carta — mismo estilo que CollectionScreen
	var cpanel = PanelContainer.new()
	var cp_st = StyleBoxFlat.new()
	cp_st.bg_color     = Color(0.04, 0.05, 0.08, 0.99)
	cp_st.border_color = rc
	cp_st.set_border_width_all(3)
	cp_st.corner_radius_top_left    = 20; cp_st.corner_radius_top_right    = 20
	cp_st.corner_radius_bottom_left = 20; cp_st.corner_radius_bottom_right = 20
	cp_st.shadow_color = rc; cp_st.shadow_size = 40
	cpanel.add_theme_stylebox_override("panel", cp_st)
	wrap.add_child(cpanel)

	var cp_m = MarginContainer.new()
	cp_m.add_theme_constant_override("margin_left",  18)
	cp_m.add_theme_constant_override("margin_right", 18)
	cp_m.add_theme_constant_override("margin_top",   18)
	cp_m.add_theme_constant_override("margin_bottom",18)
	cpanel.add_child(cp_m)

	# 4. Imagen — mismo tamaño que CollectionScreen
	var zoom_img = TextureRect.new()
	var tex = CollectionScreen._get_texture(img_path)
	if tex == null and img_path != "":
		tex = load(img_path)
		if tex: CollectionScreen._cache_texture(img_path, tex)
	zoom_img.texture = tex
	zoom_img.custom_minimum_size = Vector2(300, 420)
	zoom_img.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	zoom_img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	zoom_img.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cp_m.add_child(zoom_img)

	# 5. Info debajo
	var info_v = VBoxContainer.new()
	info_v.alignment = BoxContainer.ALIGNMENT_CENTER
	info_v.add_theme_constant_override("separation", 4)
	wrap.add_child(info_v)

	var name_lbl = Label.new()
	name_lbl.text = card.get("name", card_id)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 18)
	name_lbl.add_theme_color_override("font_color", rc)
	info_v.add_child(name_lbl)

	var detail_lbl = Label.new()
	detail_lbl.text = rarity.replace("_"," ") + "  ·  ⚡ " + str(_get_local_power(card_id)) + "  ·  Nº " + card.get("number","?")
	detail_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail_lbl.add_theme_font_size_override("font_size", 12)
	detail_lbl.add_theme_color_override("font_color", Color(0.55, 0.55, 0.65))
	info_v.add_child(detail_lbl)

	var close_hint = Label.new()
	close_hint.text = "Clic para cerrar"
	close_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	close_hint.add_theme_font_size_override("font_size", 11)
	close_hint.add_theme_color_override("font_color", Color(0.4, 0.4, 0.5, 0.7))
	wrap.add_child(close_hint)

	# 6. Animación entrada — idéntica a CollectionScreen
	cpanel.scale        = Vector2(0.45, 0.45)
	cpanel.pivot_offset = cpanel.size * 0.5
	cpanel.create_tween().tween_property(cpanel, "scale", Vector2.ONE, 0.30)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# 7. Clic para cerrar — idéntico a CollectionScreen
	zoom_overlay.gui_input.connect(func(ev):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			var tc = zoom_overlay.create_tween().set_parallel(true)
			tc.tween_property(zoom_overlay, "color:a",    0.0,                0.14)
			tc.tween_property(cpanel,       "scale",      Vector2(0.85, 0.85),0.14)
			tc.tween_property(cpanel,       "modulate:a", 0.0,                0.14)
			zoom_overlay.get_tree().create_timer(0.15).timeout.connect(zoom_overlay.queue_free)
	)


# ============================================================
# UI ROOT
# ============================================================
func _build_ui() -> void:
	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = C_DARK
	add_child(bg)

	var root_vbox = VBoxContainer.new()
	root_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_vbox.add_theme_constant_override("separation", 0)
	add_child(root_vbox)

	root_vbox.add_child(_make_header())
	root_vbox.add_child(_make_tab_bar())

	var sep = ColorRect.new()
	sep.color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.15)
	sep.custom_minimum_size = Vector2(0, 1)
	root_vbox.add_child(sep)

	var content = Control.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	root_vbox.add_child(content)

	_tab_scrap   = _build_tab_scrap();   content.add_child(_tab_scrap)
	_tab_market  = _build_tab_market();  content.add_child(_tab_market)
	_tab_trade   = _build_tab_trade();   content.add_child(_tab_trade)
	_tab_auction = _build_tab_auction(); content.add_child(_tab_auction)

	for tab in [_tab_scrap, _tab_market, _tab_trade, _tab_auction]:
		tab.set_anchors_preset(Control.PRESET_FULL_RECT)
		tab.visible = false


# ─── Header ──────────────────────────────────────────────────
func _make_header() -> Control:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 60)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.05, 0.09, 0.99)
	style.border_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.20)
	style.border_width_bottom = 1
	style.content_margin_left = 24; style.content_margin_right  = 24
	style.content_margin_top  = 8;  style.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", style)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 16)
	panel.add_child(hbox)

	var icon = Label.new(); icon.text = "⚡"
	icon.add_theme_font_size_override("font_size", 26)
	icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(icon)

	var title_vbox = VBoxContainer.new()
	title_vbox.add_theme_constant_override("separation", 1)
	title_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_vbox.size_flags_vertical   = Control.SIZE_SHRINK_CENTER
	hbox.add_child(title_vbox)

	var title = Label.new(); title.text = "GLOBAL TRADE SYSTEM"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", C_GOLD)
	title_vbox.add_child(title)

	var sub = Label.new(); sub.text = "Compra · Vende · Intercambia · Subasta"
	sub.add_theme_font_size_override("font_size", 10)
	sub.add_theme_color_override("font_color", C_TEXT_DIM)
	title_vbox.add_child(sub)

	var coins_panel = PanelContainer.new()
	var cp = StyleBoxFlat.new()
	cp.bg_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.08)
	cp.border_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.35)
	cp.set_border_width_all(1); cp.set_corner_radius_all(10)
	cp.content_margin_left = 16; cp.content_margin_right  = 16
	cp.content_margin_top  = 5;  cp.content_margin_bottom = 5
	coins_panel.add_theme_stylebox_override("panel", cp)

	var coins_lbl = Label.new()
	coins_lbl.text = "🪙  " + str(PlayerData.coins)
	coins_lbl.add_theme_font_size_override("font_size", 15)
	coins_lbl.add_theme_color_override("font_color", C_GOLD)
	coins_lbl.name = "CoinsLabel"
	coins_panel.add_child(coins_lbl)
	hbox.add_child(coins_panel)
	return panel


# ─── Tab Bar ─────────────────────────────────────────────────
func _make_tab_bar() -> Control:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 50)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.06, 0.10, 1.0)
	style.content_margin_left = 16; style.content_margin_right  = 16
	style.content_margin_top  = 6;  style.content_margin_bottom = 6
	panel.add_theme_stylebox_override("panel", style)

	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 6)
	panel.add_child(hbox)

	_tab_buttons.clear()
	for t in [["♻️","SCRAP",Tab.SCRAP,C_TEAL],["🛒","MERCADO",Tab.MARKET,C_GREEN],["🔄","TRADE",Tab.TRADE,C_PURPLE],["🏆","SUBASTA",Tab.AUCTION,C_GOLD]]:
		var btn = _make_tab_btn(t[0], t[1], t[2], t[3])
		hbox.add_child(btn)
		_tab_buttons.append({"btn": btn, "tab": t[2], "color": t[3]})
	return panel


func _make_tab_btn(icon: String, label: String, tab_id: int, accent: Color) -> Button:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(148, 38)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.flat = true

	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 7)
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(hbox)

	var ico = Label.new(); ico.text = icon
	ico.add_theme_font_size_override("font_size", 15)
	ico.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(ico)

	var lbl = Label.new(); lbl.text = label
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.add_theme_color_override("font_color", C_TEXT_DIM)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(lbl)

	_style_tab_btn(btn, false, accent)
	btn.pressed.connect(func(): _show_tab(tab_id))
	return btn


func _style_tab_btn(btn: Button, active: bool, accent: Color) -> void:
	var s = StyleBoxFlat.new()
	s.bg_color = Color(accent.r, accent.g, accent.b, 0.12 if active else 0.0)
	s.border_color = Color(accent.r, accent.g, accent.b, 0.85 if active else 0.0)
	s.border_width_bottom = 2 if active else 0
	s.corner_radius_top_left = 7; s.corner_radius_top_right = 7
	s.content_margin_left = 14; s.content_margin_right = 14
	s.content_margin_top  = 4;  s.content_margin_bottom = 4
	btn.add_theme_stylebox_override("normal", s)
	var h = s.duplicate(); h.bg_color = Color(accent.r, accent.g, accent.b, 0.18)
	btn.add_theme_stylebox_override("hover", h)
	btn.add_theme_stylebox_override("pressed", s)
	for child in btn.get_children():
		if child is HBoxContainer:
			for sub in child.get_children():
				if sub is Label and sub.text.length() > 2:
					sub.add_theme_color_override("font_color", accent if active else C_TEXT_DIM)


func _refresh_tabs() -> void:
	for e in _tab_buttons:
		_style_tab_btn(e.btn, e.tab == _current_tab, e.color)


# ============================================================
# CARD SLOT — idéntico a CollectionScreen._make_set_card_slot escalado
# Clic en imagen → zoom igual que CollectionScreen
# ============================================================
func _make_card_slot(card_id: String, action_builder: Callable) -> Control:
	var card_data = CardDatabase.get_card(card_id)
	var img_path  = _get_card_image_path(card_id)
	CollectionScreen._request_texture(img_path)

	var rarity  = card_data.get("rarity", "COMMON")
	var r_color = _rarity_color(rarity)

	# Slot raíz — mismo patrón que CollectionScreen
	var slot = Control.new()
	slot.custom_minimum_size = Vector2(SLOT_W, SLOT_H)

	# Panel de fondo con borde de rareza — igual que CollectionScreen
	var panel = Panel.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	var st = StyleBoxFlat.new()
	st.bg_color     = Color(0.08, 0.10, 0.15)
	st.border_color = r_color
	st.border_width_left = 1; st.border_width_right  = 1
	st.border_width_top  = 1; st.border_width_bottom = 1
	st.corner_radius_top_left    = 8; st.corner_radius_top_right    = 8
	st.corner_radius_bottom_left = 8; st.corner_radius_bottom_right = 8
	panel.add_theme_stylebox_override("panel", st)
	slot.add_child(panel)

	# TextureRect con padding — igual que CollectionScreen
	var tr = TextureRect.new()
	tr.offset_left   = 3;  tr.offset_top    = 3
	tr.offset_right  = -3; tr.offset_bottom = -(SLOT_H - IMG_H)
	tr.set_anchors_preset(Control.PRESET_FULL_RECT)
	tr.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.mouse_filter = Control.MOUSE_FILTER_STOP
	tr.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	slot.add_child(tr)

	# Asignar textura async — igual que CollectionScreen
	var cached = CollectionScreen._get_texture(img_path)
	if cached:
		tr.texture = cached
	elif img_path != "":
		var timer = Timer.new()
		timer.wait_time = 0.05
		timer.autostart = true
		var path_ref = img_path
		timer.timeout.connect(func():
			if not is_instance_valid(tr): timer.queue_free(); return
			var c = CollectionScreen._get_texture(path_ref)
			if c: tr.texture = c; timer.queue_free(); return
			var status = ResourceLoader.load_threaded_get_status(path_ref)
			if status == ResourceLoader.THREAD_LOAD_LOADED:
				var t = ResourceLoader.load_threaded_get(path_ref) as Texture2D
				CollectionScreen._cache_texture(path_ref, t)
				tr.texture = t; timer.queue_free()
			elif status == ResourceLoader.THREAD_LOAD_FAILED:
				timer.queue_free()
		)
		slot.add_child(timer)

	# Clic en imagen → zoom — igual que CollectionScreen front.gui_input
	tr.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			_show_card_zoom(card_id)
	)

	# Badge rareza — esquina superior derecha
	var badge = _make_badge(_rarity_short(rarity), r_color)
	badge.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	badge.offset_left  = -34; badge.offset_right  = -3
	badge.offset_top   = 4;   badge.offset_bottom = 20
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(badge)

	# Franja de rareza en la parte inferior de la imagen
	var stripe = ColorRect.new()
	stripe.color = Color(r_color.r, r_color.g, r_color.b, 0.55)
	stripe.set_anchor_and_offset(SIDE_LEFT,   0.0,  0)
	stripe.set_anchor_and_offset(SIDE_RIGHT,  1.0,  0)
	stripe.set_anchor_and_offset(SIDE_TOP,    0.0,  float(IMG_H))
	stripe.set_anchor_and_offset(SIDE_BOTTOM, 0.0,  float(IMG_H) + 2.0)
	stripe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(stripe)

	# Nombre de carta debajo de la imagen
	var name_lbl = Label.new()
	name_lbl.text = card_data.get("name", card_id.replace("_"," ").capitalize())
	name_lbl.set_anchor_and_offset(SIDE_LEFT,   0.0,  3)
	name_lbl.set_anchor_and_offset(SIDE_RIGHT,  1.0, -3)
	name_lbl.set_anchor_and_offset(SIDE_TOP,    0.0,  float(IMG_H) + 5.0)
	name_lbl.set_anchor_and_offset(SIDE_BOTTOM, 0.0,  float(IMG_H) + 19.0)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 11)
	name_lbl.add_theme_color_override("font_color", C_TEXT)
	name_lbl.clip_text = true
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(name_lbl)

	# Poder
	var power_lbl = Label.new()
	power_lbl.text = "⚡ %d" % _get_local_power(card_id)
	power_lbl.set_anchor_and_offset(SIDE_LEFT,   0.0,  3)
	power_lbl.set_anchor_and_offset(SIDE_RIGHT,  1.0, -3)
	power_lbl.set_anchor_and_offset(SIDE_TOP,    0.0,  float(IMG_H) + 20.0)
	power_lbl.set_anchor_and_offset(SIDE_BOTTOM, 0.0,  float(IMG_H) + 33.0)
	power_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	power_lbl.add_theme_font_size_override("font_size", 11)
	power_lbl.add_theme_color_override("font_color", r_color)
	power_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(power_lbl)

	# Separador
	var sep = ColorRect.new()
	sep.color = Color(1, 1, 1, 0.06)
	sep.set_anchor_and_offset(SIDE_LEFT,   0.0,  4)
	sep.set_anchor_and_offset(SIDE_RIGHT,  1.0, -4)
	sep.set_anchor_and_offset(SIDE_TOP,    0.0,  float(IMG_H) + 34.0)
	sep.set_anchor_and_offset(SIDE_BOTTOM, 0.0,  float(IMG_H) + 35.0)
	sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(sep)

	# Área de acción (botones, precio, etc.) — en el espacio restante
	var action_zone = Control.new()
	action_zone.set_anchor_and_offset(SIDE_LEFT,   0.0,  3)
	action_zone.set_anchor_and_offset(SIDE_RIGHT,  1.0, -3)
	action_zone.set_anchor_and_offset(SIDE_TOP,    0.0,  float(IMG_H) + 36.0)
	action_zone.set_anchor_and_offset(SIDE_BOTTOM, 1.0, -3)
	action_zone.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(action_zone)
	action_builder.call(action_zone)

	# Hover — mismo efecto que CollectionScreen
	slot.mouse_filter = Control.MOUSE_FILTER_STOP
	slot.mouse_entered.connect(func():
		if is_instance_valid(panel):
			var s2 = st.duplicate()
			s2.bg_color = Color(0.16, 0.20, 0.30)
			panel.add_theme_stylebox_override("panel", s2)
	)
	slot.mouse_exited.connect(func():
		if is_instance_valid(panel):
			panel.add_theme_stylebox_override("panel", st)
	)

	return slot


# ============================================================
# SCRAP
# ============================================================
func _build_tab_scrap() -> Control:
	var root = VBoxContainer.new()
	root.add_theme_constant_override("separation", 0)

	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left",   20)
	margin.add_theme_constant_override("margin_right",  20)
	margin.add_theme_constant_override("margin_top",    14)
	margin.add_theme_constant_override("margin_bottom", 14)
	scroll.add_child(margin)

	var grid = GridContainer.new()
	grid.columns = 6
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	margin.add_child(grid)
	_scrap_grid = grid
	root.add_child(scroll)
	root.add_child(_make_scrap_bar())
	return root


func _make_scrap_bar() -> Control:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 58)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.07, 0.11, 0.98)
	style.border_color = Color(C_TEAL.r, C_TEAL.g, C_TEAL.b, 0.25)
	style.border_width_top = 2
	style.content_margin_left = 20; style.content_margin_right  = 20
	style.content_margin_top  = 8;  style.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", style)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 16)
	panel.add_child(hbox)

	var lbl = Label.new(); lbl.text = "Selecciona cartas para romper"
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", C_TEXT_DIM)
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.vertical_alignment    = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(lbl)
	_scrap_preview_label = lbl

	var btn = _make_btn("✅  Confirmar Scrap", C_TEAL, Vector2(190, 40))
	btn.disabled = true
	btn.pressed.connect(_on_scrap_confirm_pressed)
	hbox.add_child(btn)
	_scrap_confirm_btn = btn
	return panel


# ============================================================
# MARKET — grid izq + panel detalle der expandido
# ============================================================
func _build_tab_market() -> Control:
	var h_root = HBoxContainer.new()
	h_root.add_theme_constant_override("separation", 0)

	# — Columna izquierda —
	var left_col = VBoxContainer.new()
	left_col.add_theme_constant_override("separation", 0)
	left_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_col.size_flags_vertical   = Control.SIZE_EXPAND_FILL

	var toolbar = _make_toolbar()
	var tb = toolbar.get_child(0) as HBoxContainer

	var sell_btn = _make_btn("➕  Vender", C_GREEN, Vector2(120, 36))
	sell_btn.pressed.connect(_on_market_sell_pressed)
	tb.add_child(sell_btn)
	tb.add_child(_vsep())

	tb.add_child(_filter_label("Poder mín:"))
	var spin_power = SpinBox.new()
	spin_power.min_value = 0; spin_power.max_value = 999; spin_power.value = 0
	spin_power.custom_minimum_size = Vector2(70, 0)
	spin_power.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	spin_power.value_changed.connect(func(v): _market_min_power = int(v))
	tb.add_child(spin_power)
	tb.add_child(_vsep())

	tb.add_child(_filter_label("Precio máx:"))
	var spin_price = SpinBox.new()
	spin_price.min_value = 1; spin_price.max_value = 999999; spin_price.value = 999999
	spin_price.custom_minimum_size = Vector2(90, 0)
	spin_price.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	spin_price.value_changed.connect(func(v): _market_max_price = int(v))
	tb.add_child(spin_price)
	tb.add_child(_vsep())

	tb.add_child(_filter_label("Ordenar:"))
	var sort_ob = _make_option_btn(130)
	sort_ob.add_item("Precio ↑"); sort_ob.set_item_metadata(0, "price_asc")
	sort_ob.add_item("Precio ↓"); sort_ob.set_item_metadata(1, "price_desc")
	sort_ob.add_item("Poder ↑");  sort_ob.set_item_metadata(2, "power_asc")
	sort_ob.add_item("Poder ↓");  sort_ob.set_item_metadata(3, "power_desc")
	sort_ob.item_selected.connect(func(idx): _market_sort = sort_ob.get_item_metadata(idx))
	tb.add_child(sort_ob)

	var spacer = Control.new(); spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tb.add_child(spacer)

	var apply_btn = _make_btn("🔍  Buscar", Color(0.4, 0.7, 1.0, 1.0), Vector2(100, 36))
	apply_btn.pressed.connect(func(): _fetch_market(_market_min_power, _market_max_price, _market_sort))
	tb.add_child(apply_btn)
	tb.add_child(_make_icon_btn("🔄", C_TEXT_DIM, func(): _fetch_market()))

	left_col.add_child(toolbar)

	# Grid de cartas
	var scroll = _make_scroll_grid(4)
	_market_grid = _get_grid(scroll)
	left_col.add_child(scroll)

	h_root.add_child(left_col)

	# — Panel derecho de detalle (ancho fijo 420px) —
	_market_detail_panel = _build_market_detail_panel()
	_market_detail_panel.visible = false
	h_root.add_child(_market_detail_panel)

	return h_root


# Panel de detalle — 420px, scroll, bien estructurado
func _build_market_detail_panel() -> Control:
	var outer = PanelContainer.new()
	outer.custom_minimum_size = Vector2(420, 0)
	outer.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var ost = StyleBoxFlat.new()
	ost.bg_color = C_DARK2
	ost.border_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.18)
	ost.border_width_left = 2
	ost.content_margin_left   = 0; ost.content_margin_right  = 0
	ost.content_margin_top    = 0; ost.content_margin_bottom = 0
	outer.add_theme_stylebox_override("panel", ost)

	var scroll = ScrollContainer.new()
	scroll.name = "DScroll"
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	outer.add_child(scroll)
	_market_detail_scroll = scroll

	var vbox = VBoxContainer.new()
	vbox.name = "DVBox"
	vbox.add_theme_constant_override("separation", 0)
	scroll.add_child(vbox)

	return outer


func _show_market_detail(card_id: String) -> void:
	if not is_instance_valid(_market_detail_panel): return
	_market_detail_panel.visible = true

	var scroll = _market_detail_scroll
	if not is_instance_valid(scroll): return
	var vbox = scroll.get_node_or_null("DVBox") as VBoxContainer
	if not is_instance_valid(vbox): return
	for c in vbox.get_children(): c.queue_free()

	var listings  = _market_grouped.get(card_id, [])
	var card_data = CardDatabase.get_card(card_id)
	var rarity    = card_data.get("rarity", "COMMON")
	var r_color   = _rarity_color(rarity)
	var img_path  = _get_card_image_path(card_id)

	# ── HEADER: imagen + info + botón cerrar ──
	var hdr_bg = PanelContainer.new()
	var hbs = StyleBoxFlat.new()
	hbs.bg_color = Color(r_color.r * 0.07, r_color.g * 0.07, r_color.b * 0.07, 1.0)
	hbs.border_color = Color(r_color.r, r_color.g, r_color.b, 0.20)
	hbs.border_width_bottom = 1
	hbs.content_margin_left = 14; hbs.content_margin_right  = 14
	hbs.content_margin_top  = 14; hbs.content_margin_bottom = 14
	hdr_bg.add_theme_stylebox_override("panel", hbs)
	vbox.add_child(hdr_bg)

	var hdr_h = HBoxContainer.new()
	hdr_h.add_theme_constant_override("separation", 12)
	hdr_bg.add_child(hdr_h)

	# Miniatura clicable (misma imagen, mismo zoom)
	var thumb_ctrl = Control.new()
	thumb_ctrl.custom_minimum_size = Vector2(88, 123)
	thumb_ctrl.clip_contents = true
	hdr_h.add_child(thumb_ctrl)

	var thumb = TextureRect.new()
	thumb.set_anchors_preset(Control.PRESET_FULL_RECT)
	thumb.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	thumb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	thumb.mouse_filter = Control.MOUSE_FILTER_STOP
	thumb.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	thumb_ctrl.add_child(thumb)
	var cached = CollectionScreen._get_texture(img_path)
	if cached: thumb.texture = cached
	elif img_path != "":
		var timer = Timer.new(); timer.wait_time = 0.05; timer.autostart = true
		var pr = img_path
		timer.timeout.connect(func():
			if not is_instance_valid(thumb): timer.queue_free(); return
			var ct = CollectionScreen._get_texture(pr)
			if ct: thumb.texture = ct; timer.queue_free(); return
			var status = ResourceLoader.load_threaded_get_status(pr)
			if status == ResourceLoader.THREAD_LOAD_LOADED:
				var t = ResourceLoader.load_threaded_get(pr) as Texture2D
				CollectionScreen._cache_texture(pr, t)
				thumb.texture = t; timer.queue_free()
			elif status == ResourceLoader.THREAD_LOAD_FAILED: timer.queue_free()
		)
		vbox.add_child(timer)

	# Borde rareza en miniatura
	var thumb_border = Panel.new()
	thumb_border.set_anchors_preset(Control.PRESET_FULL_RECT)
	var tbs = StyleBoxFlat.new(); tbs.bg_color = Color(0,0,0,0)
	tbs.border_color = r_color; tbs.set_border_width_all(2); tbs.set_corner_radius_all(6)
	thumb_border.add_theme_stylebox_override("panel", tbs)
	thumb_border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	thumb_ctrl.add_child(thumb_border)

	# Zoom al clic en miniatura — mismo patrón
	thumb.gui_input.connect(func(ev):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			_show_card_zoom(card_id)
	)

	# Columna de info
	var info_col = VBoxContainer.new()
	info_col.add_theme_constant_override("separation", 6)
	info_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_col.size_flags_vertical   = Control.SIZE_SHRINK_CENTER
	hdr_h.add_child(info_col)

	var name_lbl = Label.new()
	name_lbl.text = card_data.get("name", card_id.replace("_"," ").capitalize())
	name_lbl.add_theme_font_size_override("font_size", 18)
	name_lbl.add_theme_color_override("font_color", C_TEXT)
	info_col.add_child(name_lbl)

	var meta_h = HBoxContainer.new(); meta_h.add_theme_constant_override("separation", 8)
	info_col.add_child(meta_h)
	meta_h.add_child(_make_badge(_rarity_short(rarity), r_color))
	var pw_lbl = Label.new(); pw_lbl.text = "⚡ %d" % _get_local_power(card_id)
	pw_lbl.add_theme_font_size_override("font_size", 13)
	pw_lbl.add_theme_color_override("font_color", r_color)
	meta_h.add_child(pw_lbl)
	var cnt_lbl = Label.new(); cnt_lbl.text = "· %d oferta%s" % [listings.size(), "s" if listings.size() != 1 else ""]
	cnt_lbl.add_theme_font_size_override("font_size", 12)
	cnt_lbl.add_theme_color_override("font_color", C_TEXT_DIM)
	meta_h.add_child(cnt_lbl)

	var hint = Label.new(); hint.text = "🔍 Clic en imagen para ampliar"
	hint.add_theme_font_size_override("font_size", 10)
	hint.add_theme_color_override("font_color", Color(r_color.r, r_color.g, r_color.b, 0.55))
	info_col.add_child(hint)

	# Botón cerrar
	var close_btn = Button.new(); close_btn.text = "✕"
	close_btn.flat = true
	close_btn.custom_minimum_size = Vector2(30, 30)
	close_btn.add_theme_font_size_override("font_size", 18)
	close_btn.add_theme_color_override("font_color", C_TEXT_DIM)
	close_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	close_btn.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	close_btn.pressed.connect(func(): _market_detail_panel.visible = false)
	hdr_h.add_child(close_btn)

	# ── SECCIÓN ESTADÍSTICAS DE PRECIOS ──
	var sorted_listings = listings.duplicate()
	sorted_listings.sort_custom(func(a, b): return a.get("price_coins",0) < b.get("price_coins",0))
	var prices: Array = []
	for l in sorted_listings: prices.append(l.get("price_coins",0))

	var stats_margin = MarginContainer.new()
	stats_margin.add_theme_constant_override("margin_left",   16)
	stats_margin.add_theme_constant_override("margin_right",  16)
	stats_margin.add_theme_constant_override("margin_top",    16)
	stats_margin.add_theme_constant_override("margin_bottom", 10)
	vbox.add_child(stats_margin)

	var stats_vbox = VBoxContainer.new()
	stats_vbox.add_theme_constant_override("separation", 12)
	stats_margin.add_child(stats_vbox)

	var s_title = Label.new(); s_title.text = "📊  Historial de precios (últimas ventas)"
	s_title.add_theme_font_size_override("font_size", 12)
	s_title.add_theme_color_override("font_color", C_TEXT_DIM)
	stats_vbox.add_child(s_title)

	if prices.size() > 0:
		var min_p = prices.min(); var max_p = prices.max()
		var avg_p = 0; for p in prices: avg_p += p
		avg_p = int(float(avg_p) / float(prices.size()))

		# Panel métricas
		var stat_panel = PanelContainer.new()
		var sps = StyleBoxFlat.new(); sps.bg_color = C_SURFACE
		sps.set_corner_radius_all(10)
		sps.content_margin_left = 16; sps.content_margin_right  = 16
		sps.content_margin_top  = 14; sps.content_margin_bottom = 14
		stat_panel.add_theme_stylebox_override("panel", sps)
		stats_vbox.add_child(stat_panel)

		var stat_vbox2 = VBoxContainer.new()
		stat_vbox2.add_theme_constant_override("separation", 14)
		stat_panel.add_child(stat_vbox2)

		# Fila min/avg/max — bien grande y legible
		var metrics_h = HBoxContainer.new()
		metrics_h.add_theme_constant_override("separation", 0)
		stat_vbox2.add_child(metrics_h)

		for triple in [["Min", "%d 🪙" % min_p, C_GREEN], ["Promedio", "%d 🪙" % avg_p, C_GOLD], ["Max", "%d 🪙" % max_p, C_RED]]:
			var col = VBoxContainer.new()
			col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			col.add_theme_constant_override("separation", 3)
			metrics_h.add_child(col)

			var val = Label.new(); val.text = triple[1]
			val.add_theme_font_size_override("font_size", 20)
			val.add_theme_color_override("font_color", triple[2])
			val.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			col.add_child(val)

			var key = Label.new(); key.text = triple[0]
			key.add_theme_font_size_override("font_size", 10)
			key.add_theme_color_override("font_color", C_TEXT_DIM)
			key.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			col.add_child(key)

		# Separador
		var dv = ColorRect.new(); dv.color = Color(1,1,1,0.06)
		dv.custom_minimum_size = Vector2(0,1); stat_vbox2.add_child(dv)

		# Mini chart — barras horizontales por oferta
		var chart_title = Label.new(); chart_title.text = "Rango de precios activos:"
		chart_title.add_theme_font_size_override("font_size", 10)
		chart_title.add_theme_color_override("font_color", C_TEXT_DIM)
		stat_vbox2.add_child(chart_title)

		var chart_vbox = VBoxContainer.new()
		chart_vbox.add_theme_constant_override("separation", 6)
		stat_vbox2.add_child(chart_vbox)

		for i in range(min(prices.size(), 10)):
			var p_val = prices[i]
			var ratio = 0.15 if max_p <= min_p else (0.15 + 0.85 * float(p_val - min_p) / float(max_p - min_p))

			var row_h = HBoxContainer.new(); row_h.add_theme_constant_override("separation", 8)
			chart_vbox.add_child(row_h)

			var ptag = Label.new(); ptag.text = "%d 🪙" % p_val
			ptag.add_theme_font_size_override("font_size", 11)
			ptag.add_theme_color_override("font_color", C_GREEN if i == 0 else C_TEXT_DIM)
			ptag.custom_minimum_size = Vector2(80, 0)
			row_h.add_child(ptag)

			# Barra de fondo
			var bar_bg = Control.new()
			bar_bg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			bar_bg.custom_minimum_size   = Vector2(0, 16)
			row_h.add_child(bar_bg)

			var bg_rect = ColorRect.new()
			bg_rect.color = C_SURFACE2
			bg_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
			bar_bg.add_child(bg_rect)

			var fill = ColorRect.new()
			fill.color = Color(C_GREEN.r, C_GREEN.g, C_GREEN.b, 0.70) if i == 0 else Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.45)
			fill.set_anchor_and_offset(SIDE_LEFT,   0.0,  0)
			fill.set_anchor_and_offset(SIDE_RIGHT,  ratio, 0)
			fill.set_anchor_and_offset(SIDE_TOP,    0.0,  0)
			fill.set_anchor_and_offset(SIDE_BOTTOM, 1.0,  0)
			bar_bg.add_child(fill)
	else:
		var nd = Label.new(); nd.text = "Sin datos de precios aún"
		nd.add_theme_font_size_override("font_size", 12)
		nd.add_theme_color_override("font_color", C_TEXT_DIM)
		nd.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		stats_vbox.add_child(nd)

	# Separador
	var sep2 = ColorRect.new(); sep2.color = Color(1,1,1,0.06)
	sep2.custom_minimum_size = Vector2(0,1); vbox.add_child(sep2)

	# ── LISTA DE OFERTAS ──
	var off_margin = MarginContainer.new()
	off_margin.add_theme_constant_override("margin_left",   16)
	off_margin.add_theme_constant_override("margin_right",  16)
	off_margin.add_theme_constant_override("margin_top",    14)
	off_margin.add_theme_constant_override("margin_bottom", 20)
	vbox.add_child(off_margin)

	var off_vbox = VBoxContainer.new()
	off_vbox.add_theme_constant_override("separation", 7)
	off_margin.add_child(off_vbox)

	var off_title = Label.new(); off_title.text = "🏷️  Ofertas disponibles (más barato primero)"
	off_title.add_theme_font_size_override("font_size", 12)
	off_title.add_theme_color_override("font_color", C_TEXT_DIM)
	off_vbox.add_child(off_title)

	for i in range(sorted_listings.size()):
		var listing = sorted_listings[i]
		var is_mine = listing.get("seller_id") == PlayerData.player_id
		var price   = listing.get("price_coins", 0)
		var is_best = (i == 0)

		var row = PanelContainer.new()
		var rs = StyleBoxFlat.new()
		rs.bg_color     = Color(C_GREEN.r, C_GREEN.g, C_GREEN.b, 0.07) if is_best else C_SURFACE
		rs.border_color = Color(C_GREEN.r, C_GREEN.g, C_GREEN.b, 0.40) if is_best else Color(1,1,1,0.05)
		rs.set_border_width_all(1); rs.set_corner_radius_all(8)
		rs.content_margin_left = 12; rs.content_margin_right  = 12
		rs.content_margin_top  = 10; rs.content_margin_bottom = 10
		row.add_theme_stylebox_override("panel", rs)
		off_vbox.add_child(row)

		var row_h = HBoxContainer.new(); row_h.add_theme_constant_override("separation", 8)
		row.add_child(row_h)

		var num = Label.new(); num.text = "#%d" % (i + 1)
		num.add_theme_font_size_override("font_size", 11)
		num.add_theme_color_override("font_color", C_GREEN if is_best else C_TEXT_DIM)
		num.custom_minimum_size = Vector2(28, 0)
		row_h.add_child(num)

		if is_best: row_h.add_child(_make_badge("MEJOR", C_GREEN))

		var seller = Label.new()
		seller.text = "👤 " + listing.get("seller_name","?") + (" (Tú)" if is_mine else "")
		seller.add_theme_font_size_override("font_size", 12)
		seller.add_theme_color_override("font_color", C_GOLD_DIM if is_mine else C_TEXT)
		seller.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row_h.add_child(seller)

		var pl = Label.new(); pl.text = "%d 🪙" % price
		pl.add_theme_font_size_override("font_size", 15)
		pl.add_theme_color_override("font_color", C_GREEN if is_best else C_GOLD)
		row_h.add_child(pl)

		if not is_mine:
			var buy_btn = _make_btn("Comprar", C_GREEN, Vector2(88, 32))
			buy_btn.pressed.connect(func(): _buy_market(listing.get("id"), price))
			row_h.add_child(buy_btn)
		else:
			var own = Label.new(); own.text = "📌"
			own.add_theme_font_size_override("font_size", 16)
			row_h.add_child(own)


# ─── Carta de mercado agrupada ────────────────────────────────
func _make_market_card_grouped(card_id: String, listings: Array) -> Control:
	var sorted = listings.duplicate()
	sorted.sort_custom(func(a, b): return a.get("price_coins",0) < b.get("price_coins",0))
	var cheapest = sorted[0].get("price_coins",0) if sorted.size() > 0 else 0
	var count    = sorted.size()
	var is_mine  = false
	for l in listings:
		if l.get("seller_id") == PlayerData.player_id: is_mine = true; break

	return _make_card_slot(card_id, func(container):
		var av = VBoxContainer.new()
		av.add_theme_constant_override("separation", 2)
		av.set_anchors_preset(Control.PRESET_FULL_RECT)
		av.mouse_filter = Control.MOUSE_FILTER_IGNORE
		container.add_child(av)

		var price_lbl = Label.new(); price_lbl.text = "💰 %d 🪙" % cheapest
		price_lbl.add_theme_font_size_override("font_size", 12)
		price_lbl.add_theme_color_override("font_color", C_GREEN)
		price_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		price_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		av.add_child(price_lbl)

		var cnt_lbl = Label.new(); cnt_lbl.text = "%d oferta%s" % [count, "s" if count > 1 else ""]
		cnt_lbl.add_theme_font_size_override("font_size", 9)
		cnt_lbl.add_theme_color_override("font_color", C_TEXT_DIM)
		cnt_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cnt_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		av.add_child(cnt_lbl)

		if is_mine:
			var ml = Label.new(); ml.text = "📌 Tienes una"
			ml.add_theme_font_size_override("font_size", 9)
			ml.add_theme_color_override("font_color", C_GOLD_DIM)
			ml.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			ml.mouse_filter = Control.MOUSE_FILTER_IGNORE
			av.add_child(ml)

		var det_btn = _make_btn("Ver ofertas", C_GREEN, Vector2(0, 24))
		det_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		det_btn.pressed.connect(func(): _show_market_detail(card_id))
		av.add_child(det_btn)
	)


# ============================================================
# TRADE
# ============================================================
func _build_tab_trade() -> Control:
	var root = VBoxContainer.new(); root.add_theme_constant_override("separation", 0)
	var toolbar = _make_toolbar(); var tb = toolbar.get_child(0) as HBoxContainer

	tb.add_child(_filter_label("Ofrezco:"))
	var card_menu = _make_option_btn(200); tb.add_child(card_menu); _trade_my_card_menu = card_menu
	tb.add_child(_vsep())

	tb.add_child(_filter_label("Poder mín:"))
	var spin_min = SpinBox.new(); spin_min.min_value = 0; spin_min.max_value = 999; spin_min.value = 0
	spin_min.custom_minimum_size = Vector2(68, 0); spin_min.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	spin_min.value_changed.connect(func(v): _trade_min_power = int(v)); tb.add_child(spin_min)

	tb.add_child(_filter_label("máx:"))
	var spin_max = SpinBox.new(); spin_max.min_value = 0; spin_max.max_value = 999; spin_max.value = 999
	spin_max.custom_minimum_size = Vector2(68, 0); spin_max.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	spin_max.value_changed.connect(func(v): _trade_max_power = int(v)); tb.add_child(spin_max)

	var spacer = Control.new(); spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL; tb.add_child(spacer)
	tb.add_child(_make_btn("🔍  Filtrar", C_PURPLE, Vector2(110, 36)))
	tb.get_child(tb.get_child_count()-1).pressed.connect(func(): _fetch_trade())
	tb.add_child(_make_btn("➕  Publicar Trade", C_PURPLE, Vector2(160, 36)))
	tb.get_child(tb.get_child_count()-1).pressed.connect(_on_trade_offer_pressed)

	root.add_child(toolbar)
	var scroll = _make_scroll_grid(5); _trade_grid = _get_grid(scroll); root.add_child(scroll)
	return root


# ============================================================
# AUCTION
# ============================================================
func _build_tab_auction() -> Control:
	var root = VBoxContainer.new(); root.add_theme_constant_override("separation", 0)
	var toolbar = _make_toolbar(); var tb = toolbar.get_child(0) as HBoxContainer

	tb.add_child(_make_btn("➕  Crear Subasta", C_GOLD, Vector2(155, 36)))
	tb.get_child(tb.get_child_count()-1).pressed.connect(_on_auction_create_pressed)
	var spacer = Control.new(); spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL; tb.add_child(spacer)
	tb.add_child(_make_btn("🔄  Actualizar", C_TEXT_DIM, Vector2(130, 36)))
	tb.get_child(tb.get_child_count()-1).pressed.connect(func(): _fetch_auction())

	root.add_child(toolbar)
	var scroll = _make_scroll_grid(5); _auction_grid = _get_grid(scroll); root.add_child(scroll)
	return root


# ─── Helpers de construcción ─────────────────────────────────
func _make_toolbar() -> PanelContainer:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 52)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.07, 0.11, 0.97)
	style.border_color = Color(C_BORDER.r, C_BORDER.g, C_BORDER.b, 0.12)
	style.border_width_bottom = 1
	style.content_margin_left = 14; style.content_margin_right  = 14
	style.content_margin_top  = 7;  style.content_margin_bottom = 7
	panel.add_theme_stylebox_override("panel", style)
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	hbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	panel.add_child(hbox)
	return panel


func _make_scroll_grid(columns: int) -> ScrollContainer:
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left",   18)
	margin.add_theme_constant_override("margin_right",  18)
	margin.add_theme_constant_override("margin_top",    14)
	margin.add_theme_constant_override("margin_bottom", 14)
	scroll.add_child(margin)
	var grid = GridContainer.new()
	grid.columns = columns
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	margin.add_child(grid)
	return scroll


func _get_grid(scroll: ScrollContainer) -> GridContainer:
	return scroll.get_child(0).get_child(0) as GridContainer


func _make_empty_state(msg: String, accent: Color) -> Control:
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	var v = VBoxContainer.new(); v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 10); center.add_child(v)
	var ico = Label.new(); ico.text = "📦"; ico.add_theme_font_size_override("font_size", 48)
	ico.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; v.add_child(ico)
	var lbl = Label.new(); lbl.text = msg; lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", C_TEXT_DIM)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; v.add_child(lbl)
	return center


func _filter_label(text: String) -> Label:
	var lbl = Label.new(); lbl.text = text
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.add_theme_color_override("font_color", C_TEXT_DIM)
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return lbl


func _vsep() -> VSeparator:
	var s = VSeparator.new()
	s.add_theme_color_override("separator_color", C_BORDER)
	s.custom_minimum_size = Vector2(1, 22)
	return s


# ============================================================
# NAVEGACIÓN
# ============================================================
func _show_tab(tab: int) -> void:
	_current_tab = tab
	if _tab_scrap:   _tab_scrap.visible   = (tab == Tab.SCRAP)
	if _tab_market:  _tab_market.visible  = (tab == Tab.MARKET)
	if _tab_trade:   _tab_trade.visible   = (tab == Tab.TRADE)
	if _tab_auction: _tab_auction.visible = (tab == Tab.AUCTION)
	_refresh_tabs()
	match tab:
		Tab.SCRAP:   _load_scrap_inventory()
		Tab.MARKET:  _fetch_market()
		Tab.TRADE:   _load_trade_my_cards(); _fetch_trade()
		Tab.AUCTION: _fetch_auction()


# ============================================================
# SCRAP — lógica completa
# ============================================================
func _load_scrap_inventory() -> void:
	_clear_grid(_scrap_grid); _scrap_selected.clear(); _update_scrap_label(0)
	var sorted = []
	for card_id in PlayerData.inventory:
		if PlayerData.inventory[card_id] > 0:
			sorted.append({"card_id": card_id, "qty": PlayerData.inventory[card_id]})
	sorted.sort_custom(func(a, b): return _get_local_power(a.card_id) > _get_local_power(b.card_id))
	for entry in sorted:
		_scrap_grid.add_child(_make_scrap_card_slot(entry.card_id, entry.qty))


func _make_scrap_card_slot(card_id: String, qty: int) -> Control:
	var slot = _make_card_slot(card_id, func(container):
		var av = VBoxContainer.new()
		av.add_theme_constant_override("separation", 2)
		av.set_anchors_preset(Control.PRESET_FULL_RECT)
		av.mouse_filter = Control.MOUSE_FILTER_IGNORE
		container.add_child(av)

		var val_lbl = Label.new(); val_lbl.text = "~%d 🪙" % _estimate_scrap(card_id)
		val_lbl.add_theme_font_size_override("font_size", 12)
		val_lbl.add_theme_color_override("font_color", C_TEAL)
		val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		val_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		av.add_child(val_lbl)

		if qty > 1:
			var ql = Label.new(); ql.text = "x%d en inv." % qty
			ql.add_theme_font_size_override("font_size", 9)
			ql.add_theme_color_override("font_color", C_TEXT_DIM)
			ql.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			ql.mouse_filter = Control.MOUSE_FILTER_IGNORE
			av.add_child(ql)
	)

	# Overlay de selección encima
	var wrap = Control.new()
	wrap.custom_minimum_size = Vector2(SLOT_W, SLOT_H)
	slot.set_anchors_preset(Control.PRESET_FULL_RECT)
	wrap.add_child(slot)

	var overlay = ColorRect.new()
	overlay.color = Color(C_TEAL.r, C_TEAL.g, C_TEAL.b, 0.25)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.visible = false; overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrap.add_child(overlay)

	var check = Label.new(); check.text = "✓"
	check.add_theme_font_size_override("font_size", 40)
	check.add_theme_color_override("font_color", C_TEAL)
	check.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	check.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	check.set_anchors_preset(Control.PRESET_FULL_RECT)
	check.visible = false; check.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrap.add_child(check)

	# Botón toggle en la zona inferior (deja la imagen libre para zoom)
	var btn = Button.new(); btn.flat = true
	btn.set_anchor_and_offset(SIDE_LEFT,   0.0, 0)
	btn.set_anchor_and_offset(SIDE_RIGHT,  1.0, 0)
	btn.set_anchor_and_offset(SIDE_TOP,    0.0, float(IMG_H))
	btn.set_anchor_and_offset(SIDE_BOTTOM, 1.0, 0)
	var empty = StyleBoxEmpty.new()
	btn.add_theme_stylebox_override("normal",  empty)
	btn.add_theme_stylebox_override("hover",   empty)
	btn.add_theme_stylebox_override("pressed", empty)
	btn.toggle_mode = true
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.toggled.connect(func(pressed):
		overlay.visible = pressed; check.visible = pressed
		_on_scrap_card_toggled(card_id, pressed)
	)
	wrap.add_child(btn)
	return wrap


func _on_scrap_card_toggled(card_id: String, selected: bool) -> void:
	if selected:
		if not _scrap_selected.has(card_id): _scrap_selected.append(card_id)
	else:
		_scrap_selected.erase(card_id)
	if _scrap_selected.size() > 0: _request_scrap_preview()
	else:
		_update_scrap_label(0)
		if _scrap_confirm_btn: _scrap_confirm_btn.disabled = true


func _request_scrap_preview() -> void:
	var url  = NetworkManager.BASE_URL + "/api/gts/scrap/preview"
	var body = JSON.stringify({"card_ids": _scrap_selected})
	_log_request("POST", url, body)
	var http = _make_http()
	http.request_completed.connect(func(result, code, _h, raw_body):
		http.queue_free(); _log_response("SCRAP_PREVIEW", code, raw_body)
		if code == 200:
			var data = _parse_json(raw_body)
			_update_scrap_label(data.get("total_coins", 0))
			if _scrap_confirm_btn: _scrap_confirm_btn.disabled = false
		else:
			_update_scrap_label(0)
	)
	http.request(url, _auth_headers(), HTTPClient.METHOD_POST, body)


func _update_scrap_label(coins: int) -> void:
	if not is_instance_valid(_scrap_preview_label): return
	if _scrap_selected.size() == 0:
		_scrap_preview_label.text = "Selecciona cartas para romper"
		_scrap_preview_label.add_theme_color_override("font_color", C_TEXT_DIM)
	else:
		_scrap_preview_label.text = "  %d carta(s)  →  %d 🪙" % [_scrap_selected.size(), coins]
		_scrap_preview_label.add_theme_color_override("font_color", C_TEAL)


func _on_scrap_confirm_pressed() -> void:
	if _scrap_selected.size() == 0: return
	if _scrap_confirm_btn: _scrap_confirm_btn.disabled = true
	var url  = NetworkManager.BASE_URL + "/api/gts/scrap/bulk-confirm"
	var body = JSON.stringify({"card_ids": _scrap_selected})
	_log_request("POST", url, body)
	var http = _make_http()
	http.request_completed.connect(func(result, code, _h, raw_body):
		http.queue_free(); _log_response("SCRAP_CONFIRM", code, raw_body)
		var data = _parse_json(raw_body)
		if code == 200:
			PlayerData.coins = data.get("new_balance", PlayerData.coins)
			_refresh_coins_label()
			for entry in data.get("scrapped", []): PlayerData.remove_card(entry["card_id"])
			_scrap_selected.clear(); _load_scrap_inventory()
			_show_toast("✅ Cartas rotas. Recibiste %d 🪙" % data.get("total_coins", 0))
		else:
			_show_toast("❌ " + data.get("error","Error al romper cartas"), true)
			if _scrap_confirm_btn: _scrap_confirm_btn.disabled = false
	)
	http.request(url, _auth_headers(), HTTPClient.METHOD_POST, body)


# ============================================================
# MARKET — lógica de red
# ============================================================
func _fetch_market(min_power: int = 0, max_price: int = 999999, sort: String = "price_asc") -> void:
	_clear_grid(_market_grid)
	if is_instance_valid(_market_detail_panel): _market_detail_panel.visible = false
	var url = "%s/api/gts/market?min_power=%d&max_price=%d&limit=200" % [NetworkManager.BASE_URL, min_power, max_price]
	_log_request("GET", url)
	var http = _make_http()
	http.request_completed.connect(func(result, code, _h, raw_body):
		http.queue_free(); _log_response("MARKET", code, raw_body)
		if code != 200: return
		var data = _parse_json(raw_body)
		_market_listings = data.get("listings", [])
		_market_grouped.clear()
		for l in _market_listings:
			var cid = l.get("card_id","")
			if not _market_grouped.has(cid): _market_grouped[cid] = []
			_market_grouped[cid].append(l)
		var keys = _market_grouped.keys()
		match sort:
			"price_asc":  keys.sort_custom(func(a,b): return _min_price_of(_market_grouped[a]) < _min_price_of(_market_grouped[b]))
			"price_desc": keys.sort_custom(func(a,b): return _min_price_of(_market_grouped[a]) > _min_price_of(_market_grouped[b]))
			"power_asc":  keys.sort_custom(func(a,b): return _get_local_power(a) < _get_local_power(b))
			"power_desc": keys.sort_custom(func(a,b): return _get_local_power(a) > _get_local_power(b))
		_log("MARKET", "✅ %d listings → %d únicas" % [_market_listings.size(), keys.size()])
		if keys.is_empty():
			_market_grid.add_child(_make_empty_state("No hay cartas en el mercado", C_GREEN)); return
		for cid in keys:
			_market_grid.add_child(_make_market_card_grouped(cid, _market_grouped[cid]))
	)
	http.request(url, _auth_headers(), HTTPClient.METHOD_GET)


func _min_price_of(listings: Array) -> int:
	var m = 999999
	for l in listings:
		var p = l.get("price_coins",999999); if p < m: m = p
	return m


func _buy_market(listing_id: int, price: int) -> void:
	if PlayerData.coins < price:
		_show_toast("❌ Monedas insuficientes (%d / %d)" % [PlayerData.coins, price], true); return
	var url  = NetworkManager.BASE_URL + "/api/gts/market/%d/buy" % listing_id
	var http = _make_http()
	http.request_completed.connect(func(result, code, _h, raw_body):
		http.queue_free(); _log_response("MARKET_BUY", code, raw_body)
		var data = _parse_json(raw_body)
		if code == 200:
			PlayerData.coins = data.get("new_balance", PlayerData.coins)
			_refresh_coins_label()
			PlayerData.add_card(data.get("card_id",""))
			_show_toast("✅ Carta comprada: %s" % data.get("card_id","")); _fetch_market()
		else:
			_show_toast("❌ " + data.get("error","Error al comprar"), true)
	)
	http.request(url, _auth_headers(), HTTPClient.METHOD_POST, "{}")


func _on_market_sell_pressed() -> void:
	var dialog = AcceptDialog.new(); dialog.title = "Vender carta en el Mercado"; dialog.min_size = Vector2(340, 230)
	var vbox = VBoxContainer.new(); vbox.add_theme_constant_override("separation", 12); dialog.add_child(vbox)
	vbox.add_child(_dlg_label("Carta a vender:"))
	var card_menu = _make_option_btn(300)
	for card_id in PlayerData.inventory:
		if PlayerData.inventory[card_id] > 0:
			card_menu.add_item("%s  (x%d)  ⚡%d" % [card_id, PlayerData.inventory[card_id], _get_local_power(card_id)])
			card_menu.set_item_metadata(card_menu.item_count - 1, card_id)
	vbox.add_child(card_menu)
	vbox.add_child(_dlg_label("Precio en monedas:"))
	var price_spin = SpinBox.new(); price_spin.min_value = 1; price_spin.max_value = 999999; price_spin.value = 10
	vbox.add_child(price_spin)
	add_child(dialog); dialog.popup_centered()
	dialog.confirmed.connect(func():
		var idx = card_menu.selected; if idx < 0: return
		_post_market_listing(card_menu.get_item_metadata(idx), int(price_spin.value)); dialog.queue_free()
	)


func _post_market_listing(card_id: String, price: int) -> void:
	var url  = NetworkManager.BASE_URL + "/api/gts/market"
	var body = JSON.stringify({"card_id": card_id, "price_coins": price})
	_log_request("POST", url, body)
	var http = _make_http()
	http.request_completed.connect(func(result, code, _h, raw_body):
		http.queue_free()
		var data = _parse_json(raw_body)
		if code == 201:
			PlayerData.remove_card(card_id); _show_toast("✅ Carta publicada en el mercado"); _fetch_market()
		else: _show_toast("❌ " + data.get("error","Error al publicar"), true)
	)
	http.request(url, _auth_headers(), HTTPClient.METHOD_POST, body)


# ============================================================
# TRADE — lógica completa
# ============================================================
func _load_trade_my_cards() -> void:
	if not is_instance_valid(_trade_my_card_menu): return
	_trade_my_card_menu.clear()
	_trade_my_card_menu.add_item("— Cualquier carta —"); _trade_my_card_menu.set_item_metadata(0, "")
	for card_id in PlayerData.inventory:
		if PlayerData.inventory[card_id] > 0:
			_trade_my_card_menu.add_item("%s  ⚡%d" % [card_id, _get_local_power(card_id)])
			_trade_my_card_menu.set_item_metadata(_trade_my_card_menu.item_count - 1, card_id)


func _fetch_trade() -> void:
	_clear_grid(_trade_grid)
	var selected = ""
	if is_instance_valid(_trade_my_card_menu) and _trade_my_card_menu.selected > 0:
		selected = _trade_my_card_menu.get_item_metadata(_trade_my_card_menu.selected)
	var url = "%s/api/gts/trade?limit=40" % NetworkManager.BASE_URL
	if selected != "": url += "&my_card_id=" + selected
	var http = _make_http()
	http.request_completed.connect(func(result, code, _h, raw_body):
		http.queue_free()
		if code != 200: return
		var data = _parse_json(raw_body)
		_trade_listings = data.get("listings",[])
		if _trade_min_power > 0 or _trade_max_power < 999:
			_trade_listings = _trade_listings.filter(func(l):
				var p = l.get("card_power",0); return p >= _trade_min_power and p <= _trade_max_power)
		_render_trade()
	)
	http.request(url, _auth_headers(), HTTPClient.METHOD_GET)


func _render_trade() -> void:
	_clear_grid(_trade_grid)
	if _trade_listings.is_empty():
		_trade_grid.add_child(_make_empty_state("No hay trades disponibles", C_PURPLE)); return
	for listing in _trade_listings:
		var card_id = listing.get("card_id","")
		var is_mine = listing.get("seller_id") == PlayerData.player_id
		var slot = _make_card_slot(card_id, func(container):
			var av = VBoxContainer.new(); av.add_theme_constant_override("separation", 2)
			av.set_anchors_preset(Control.PRESET_FULL_RECT); av.mouse_filter = Control.MOUSE_FILTER_IGNORE
			container.add_child(av)

			var rl = Label.new(); rl.text = "⚡ %d – %d" % [listing.get("min_power_want",0), listing.get("max_power_want",0)]
			rl.add_theme_font_size_override("font_size", 11); rl.add_theme_color_override("font_color", C_PURPLE)
			rl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; rl.mouse_filter = Control.MOUSE_FILTER_IGNORE; av.add_child(rl)

			var sl = Label.new(); sl.text = "👤 " + listing.get("seller_name","?")
			sl.add_theme_font_size_override("font_size", 9); sl.add_theme_color_override("font_color", C_TEXT_DIM)
			sl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; sl.mouse_filter = Control.MOUSE_FILTER_IGNORE; av.add_child(sl)

			if not is_mine:
				var btn = _make_btn("Ofrecer", C_PURPLE, Vector2(0, 24))
				btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				btn.pressed.connect(func(): _show_offer_dialog(listing)); av.add_child(btn)
			else:
				var ol = Label.new(); ol.text = "📌 Tuya"
				ol.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				ol.add_theme_font_size_override("font_size", 10); ol.add_theme_color_override("font_color", Color(C_PURPLE.r, C_PURPLE.g, C_PURPLE.b, 0.7))
				ol.mouse_filter = Control.MOUSE_FILTER_IGNORE; av.add_child(ol)
		)
		_trade_grid.add_child(slot)


func _on_trade_offer_pressed() -> void:
	var dialog = AcceptDialog.new(); dialog.title = "Publicar Trade"; dialog.min_size = Vector2(360, 290)
	var vbox = VBoxContainer.new(); vbox.add_theme_constant_override("separation", 12); dialog.add_child(vbox)
	vbox.add_child(_dlg_label("Carta que ofreces:"))
	var card_menu = _make_option_btn(320)
	for card_id in PlayerData.inventory:
		if PlayerData.inventory[card_id] > 0:
			card_menu.add_item("%s  ⚡%d" % [card_id, _get_local_power(card_id)])
			card_menu.set_item_metadata(card_menu.item_count - 1, card_id)
	vbox.add_child(card_menu)
	vbox.add_child(_dlg_label("Poder mínimo que aceptas:"))
	var spin_min = SpinBox.new(); spin_min.min_value = 0; spin_min.max_value = 999; spin_min.value = 0; vbox.add_child(spin_min)
	vbox.add_child(_dlg_label("Poder máximo que aceptas:"))
	var spin_max = SpinBox.new(); spin_max.min_value = 0; spin_max.max_value = 999; spin_max.value = 999; vbox.add_child(spin_max)
	add_child(dialog); dialog.popup_centered()
	dialog.confirmed.connect(func():
		var idx = card_menu.selected; if idx < 0: return
		_post_trade_listing(card_menu.get_item_metadata(idx), int(spin_min.value), int(spin_max.value)); dialog.queue_free()
	)


func _post_trade_listing(card_id: String, min_p: int, max_p: int) -> void:
	var url  = NetworkManager.BASE_URL + "/api/gts/trade"
	var body = JSON.stringify({"card_id": card_id, "min_power_want": min_p, "max_power_want": max_p})
	var http = _make_http()
	http.request_completed.connect(func(result, code, _h, raw_body):
		http.queue_free()
		var data = _parse_json(raw_body)
		if code == 201: PlayerData.remove_card(card_id); _show_toast("✅ Trade publicado"); _fetch_trade()
		else: _show_toast("❌ " + data.get("error","Error al publicar trade"), true)
	)
	http.request(url, _auth_headers(), HTTPClient.METHOD_POST, body)


func _show_offer_dialog(listing: Dictionary) -> void:
	var dialog = AcceptDialog.new(); dialog.title = "Ofrecer carta para trade"; dialog.min_size = Vector2(340, 220)
	var vbox = VBoxContainer.new(); vbox.add_theme_constant_override("separation", 12); dialog.add_child(vbox)
	var info = Label.new()
	info.text = "Ellos ofrecen: %s  (⚡%d)\nAceptan poder: %d – %d" % [listing.get("card_id","?"), listing.get("card_power",0), listing.get("min_power_want",0), listing.get("max_power_want",0)]
	info.add_theme_color_override("font_color", C_TEXT); vbox.add_child(info)
	var card_menu = _make_option_btn(300)
	var min_p = listing.get("min_power_want",0); var max_p = listing.get("max_power_want",9999)
	for card_id in PlayerData.inventory:
		if PlayerData.inventory[card_id] > 0:
			var power = _get_local_power(card_id)
			if power >= min_p and power <= max_p:
				card_menu.add_item("%s  ⚡%d" % [card_id, power]); card_menu.set_item_metadata(card_menu.item_count - 1, card_id)
	if card_menu.item_count == 0:
		var no = Label.new(); no.text = "⚠️ No tienes cartas en el rango (%d – %d)" % [min_p, max_p]
		no.add_theme_color_override("font_color", C_RED); vbox.add_child(no)
	else:
		vbox.add_child(card_menu)
	add_child(dialog); dialog.popup_centered()
	if card_menu.item_count > 0:
		dialog.confirmed.connect(func():
			var idx = card_menu.selected; if idx < 0: return
			_post_trade_offer(listing.get("id"), card_menu.get_item_metadata(idx)); dialog.queue_free()
		)


func _post_trade_offer(listing_id: int, card_id: String) -> void:
	var url  = NetworkManager.BASE_URL + "/api/gts/trade/%d/offer" % listing_id
	var body = JSON.stringify({"card_id": card_id})
	var http = _make_http()
	http.request_completed.connect(func(result, code, _h, raw_body):
		http.queue_free()
		var data = _parse_json(raw_body)
		if code == 201: _show_toast("✅ Oferta enviada")
		else: _show_toast("❌ " + data.get("error","Error al enviar oferta"), true)
	)
	http.request(url, _auth_headers(), HTTPClient.METHOD_POST, body)


# ============================================================
# AUCTION — lógica completa
# ============================================================
func _fetch_auction() -> void:
	_clear_grid(_auction_grid)
	var url = NetworkManager.BASE_URL + "/api/gts/auction?limit=40"
	var http = _make_http()
	http.request_completed.connect(func(result, code, _h, raw_body):
		http.queue_free()
		if code == 200:
			_auction_listings = _parse_json(raw_body).get("auctions",[])
			_render_auction()
	)
	http.request(url, _auth_headers(), HTTPClient.METHOD_GET)


func _render_auction() -> void:
	_clear_grid(_auction_grid)
	if _auction_listings.is_empty():
		_auction_grid.add_child(_make_empty_state("No hay subastas activas", C_GOLD)); return
	for auction in _auction_listings:
		var card_id = auction.get("card_id","")
		var is_mine = auction.get("seller_id") == PlayerData.player_id
		var cur_bid = auction.get("current_bid")
		var slot = _make_card_slot(card_id, func(container):
			var av = VBoxContainer.new(); av.add_theme_constant_override("separation", 2)
			av.set_anchors_preset(Control.PRESET_FULL_RECT); av.mouse_filter = Control.MOUSE_FILTER_IGNORE
			container.add_child(av)

			var bl = Label.new(); bl.text = "💎 %s" % ("%d 🪙" % cur_bid if cur_bid != null else "Sin pujas")
			bl.add_theme_font_size_override("font_size", 12)
			bl.add_theme_color_override("font_color", C_GOLD if cur_bid != null else C_TEXT_DIM)
			bl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; bl.mouse_filter = Control.MOUSE_FILTER_IGNORE; av.add_child(bl)

			var ml = Label.new(); ml.text = "%d pujas · ⏱ %s" % [auction.get("bid_count",0), _format_time(auction.get("expires_at",""))]
			ml.add_theme_font_size_override("font_size", 9); ml.add_theme_color_override("font_color", C_TEXT_DIM)
			ml.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; ml.mouse_filter = Control.MOUSE_FILTER_IGNORE; av.add_child(ml)

			if not is_mine:
				var btn = _make_btn("⬆️ Pujar", C_GOLD, Vector2(0, 24))
				btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				btn.pressed.connect(func(): _show_bid_dialog(auction)); av.add_child(btn)
			else:
				var ol = Label.new(); ol.text = "📌 Tuya"
				ol.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				ol.add_theme_font_size_override("font_size", 10); ol.add_theme_color_override("font_color", C_GOLD_DIM)
				ol.mouse_filter = Control.MOUSE_FILTER_IGNORE; av.add_child(ol)
		)
		_auction_grid.add_child(slot)


func _show_bid_dialog(auction: Dictionary) -> void:
	var dialog = AcceptDialog.new(); dialog.title = "Pujar en subasta"; dialog.min_size = Vector2(320, 200)
	var vbox = VBoxContainer.new(); vbox.add_theme_constant_override("separation", 12); dialog.add_child(vbox)
	var cur_bid  = auction.get("current_bid")
	var min_next = (cur_bid + 1) if cur_bid != null else auction.get("starting_price", 1)
	var info = Label.new()
	info.text = "Carta: %s  (⚡%d)\nPuja mínima: %d 🪙\nTus monedas: %d 🪙" % [auction.get("card_id","?"), auction.get("card_power",0), min_next, PlayerData.coins]
	info.add_theme_color_override("font_color", C_TEXT); vbox.add_child(info)
	var spin = SpinBox.new(); spin.min_value = min_next; spin.max_value = PlayerData.coins; spin.value = min_next; vbox.add_child(spin)
	add_child(dialog); dialog.popup_centered()
	dialog.confirmed.connect(func(): _post_bid(auction.get("id"), int(spin.value)); dialog.queue_free())


func _post_bid(listing_id: int, amount: int) -> void:
	var url  = NetworkManager.BASE_URL + "/api/gts/auction/%d/bid" % listing_id
	var body = JSON.stringify({"amount": amount})
	var http = _make_http()
	http.request_completed.connect(func(result, code, _h, raw_body):
		http.queue_free()
		var data = _parse_json(raw_body)
		if code == 200: _show_toast("✅ Puja de %d 🪙 registrada" % amount); _fetch_auction()
		else: _show_toast("❌ " + data.get("error","Error al pujar"), true)
	)
	http.request(url, _auth_headers(), HTTPClient.METHOD_POST, body)


func _on_auction_create_pressed() -> void:
	var dialog = AcceptDialog.new(); dialog.title = "Crear subasta"; dialog.min_size = Vector2(340, 290)
	var vbox = VBoxContainer.new(); vbox.add_theme_constant_override("separation", 12); dialog.add_child(vbox)
	vbox.add_child(_dlg_label("Carta a subastar:"))
	var card_menu = _make_option_btn(300)
	for card_id in PlayerData.inventory:
		if PlayerData.inventory[card_id] > 0:
			card_menu.add_item("%s  ⚡%d" % [card_id, _get_local_power(card_id)]); card_menu.set_item_metadata(card_menu.item_count - 1, card_id)
	vbox.add_child(card_menu)
	vbox.add_child(_dlg_label("Precio inicial:"))
	var price_spin = SpinBox.new(); price_spin.min_value = 1; price_spin.max_value = 999999; price_spin.value = 10; vbox.add_child(price_spin)
	vbox.add_child(_dlg_label("Duración:"))
	var dur = OptionButton.new()
	dur.add_item("12 horas"); dur.set_item_metadata(0, 12)
	dur.add_item("24 horas"); dur.set_item_metadata(1, 24)
	dur.add_item("48 horas"); dur.set_item_metadata(2, 48)
	dur.selected = 1; vbox.add_child(dur)
	add_child(dialog); dialog.popup_centered()
	dialog.confirmed.connect(func():
		var idx = card_menu.selected; if idx < 0: return
		_post_auction(card_menu.get_item_metadata(idx), int(price_spin.value), dur.get_item_metadata(dur.selected)); dialog.queue_free()
	)


func _post_auction(card_id: String, starting_price: int, duration_hours: int) -> void:
	var url  = NetworkManager.BASE_URL + "/api/gts/auction"
	var body = JSON.stringify({"card_id": card_id, "starting_price": starting_price, "duration_hours": duration_hours})
	var http = _make_http()
	http.request_completed.connect(func(result, code, _h, raw_body):
		http.queue_free()
		var data = _parse_json(raw_body)
		if code == 201:
			PlayerData.remove_card(card_id); _show_toast("✅ Subasta creada por %d horas" % duration_hours); _fetch_auction()
		else: _show_toast("❌ " + data.get("error","Error al crear subasta"), true)
	)
	http.request(url, _auth_headers(), HTTPClient.METHOD_POST, body)


# ============================================================
# WEBSOCKET
# ============================================================
func handle_ws_message(msg: Dictionary) -> void:
	var type = msg.get("type",""); var payload = msg.get("payload",{})
	_log("WS", "type=%s" % type)
	match type:
		"GTS_CARD_SOLD":
			PlayerData.add_coins(payload.get("coins",0))
			_refresh_coins_label()
			_show_toast("💰 Carta '%s' vendida por %d 🪙" % [payload.get("card_id","?"), payload.get("coins",0)])
			if _current_tab == Tab.MARKET: _fetch_market()
		"GTS_TRADE_OFFER":
			_show_toast("🔄 Nueva oferta en '%s'" % payload.get("offered_card","?"))
			if _current_tab == Tab.TRADE: _fetch_trade()
		"GTS_TRADE_ACCEPTED":
			PlayerData.add_card(payload.get("received_card",""))
			PlayerData.remove_card(payload.get("gave_card",""))
			_show_toast("🤝 ¡Trade aceptado! Recibiste: %s" % payload.get("received_card","?"))
			if _current_tab == Tab.TRADE: _fetch_trade()
		"GTS_AUCTION_WON":
			PlayerData.add_card(payload.get("card_id",""))
			PlayerData.coins -= payload.get("amount",0)
			_refresh_coins_label()
			_show_toast("🏆 ¡Ganaste la subasta! Recibiste: %s" % payload.get("card_id","?"))
			if _current_tab == Tab.AUCTION: _fetch_auction()
		"GTS_AUCTION_SOLD":
			PlayerData.add_coins(payload.get("amount",0))
			_refresh_coins_label()
			_show_toast("💰 Subasta de '%s': %d 🪙" % [payload.get("card_id","?"), payload.get("amount",0)])
		"GTS_AUCTION_EXPIRED","GTS_LISTING_EXPIRED":
			PlayerData.add_card(payload.get("card_id",""))
			_show_toast("⏱ Publicación expirada. Carta devuelta.")
			if _current_tab == Tab.AUCTION: _fetch_auction()
			if _current_tab == Tab.MARKET:  _fetch_market()
		"GTS_NEW_BID":
			if _current_tab == Tab.AUCTION: _fetch_auction()


# ============================================================
# UTILIDADES
# ============================================================
func _make_http() -> HTTPRequest:
	var h = HTTPRequest.new(); add_child(h); return h

func _auth_headers() -> PackedStringArray:
	return PackedStringArray(["Content-Type: application/json", "Authorization: Bearer " + NetworkManager.token])

func _parse_json(body: PackedByteArray) -> Dictionary:
	var raw = body.get_string_from_utf8()
	if raw.strip_edges() == "": return {}
	var json = JSON.new()
	if json.parse(raw) != OK: return {}
	var data = json.get_data()
	return data if data is Dictionary else {}

func _clear_grid(grid) -> void:
	if not is_instance_valid(grid): return
	for child in grid.get_children(): child.queue_free()

func _get_card_image_path(card_id: String) -> String:
	var card = CardDatabase.get_card(card_id)
	if card.is_empty(): return ""
	return LanguageManager.get_card_image(card)

func _get_local_power(card_id: String) -> int:
	return CardDatabase.get_card(card_id).get("power", 0)

func _estimate_scrap(card_id: String) -> int:
	var power  = _get_local_power(card_id)
	var factor = 1.5 if power >= 60 else (1.2 if power >= 35 else (0.8 if power >= 20 else 0.5))
	return max(1, int(max(1, roundi(float(power) / 92.0 * 100.0 * factor)) * 0.30))

func _format_time(iso: String) -> String:
	if iso == "": return "?"
	return iso.left(16).replace("T", " ")

func _rarity_color(rarity: String) -> Color:
	match rarity:
		"COMMON":    return Color(0.55, 0.55, 0.60, 1.0)
		"UNCOMMON":  return Color(0.40, 0.85, 0.40, 1.0)
		"RARE":      return Color(0.95, 0.85, 0.10, 1.0)
		"RARE_HOLO": return Color(0.20, 0.85, 1.00, 1.0)
		"ULTRA_RARE":return Color(1.00, 0.45, 0.05, 1.0)
		_:           return C_TEXT_DIM

func _rarity_short(rarity: String) -> String:
	match rarity:
		"COMMON":    return "C"
		"UNCOMMON":  return "UC"
		"RARE":      return "R"
		"RARE_HOLO": return "HR"
		"ULTRA_RARE":return "UR"
		_:           return "?"

func _make_badge(text: String, color: Color) -> PanelContainer:
	var badge = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(color.r, color.g, color.b, 0.88)
	style.set_corner_radius_all(4)
	style.content_margin_left = 4; style.content_margin_right  = 4
	style.content_margin_top  = 1; style.content_margin_bottom = 1
	badge.add_theme_stylebox_override("panel", style)
	var lbl = Label.new(); lbl.text = text
	lbl.add_theme_font_size_override("font_size", 9)
	lbl.add_theme_color_override("font_color", Color(0.05, 0.05, 0.07))
	badge.add_child(lbl); return badge

func _make_btn(text: String, accent: Color, size: Vector2 = Vector2(0, 34)) -> Button:
	var btn = Button.new(); btn.text = text
	if size != Vector2.ZERO: btn.custom_minimum_size = size
	btn.add_theme_font_size_override("font_size", 12)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var s = StyleBoxFlat.new()
	s.bg_color     = Color(accent.r, accent.g, accent.b, 0.16)
	s.border_color = Color(accent.r, accent.g, accent.b, 0.55)
	s.set_border_width_all(1); s.set_corner_radius_all(7)
	s.content_margin_left = 10; s.content_margin_right  = 10
	s.content_margin_top  = 3;  s.content_margin_bottom = 3
	btn.add_theme_stylebox_override("normal", s)
	var h = s.duplicate(); h.bg_color = Color(accent.r, accent.g, accent.b, 0.30)
	btn.add_theme_stylebox_override("hover", h)
	var p = s.duplicate(); p.bg_color = Color(accent.r, accent.g, accent.b, 0.44)
	btn.add_theme_stylebox_override("pressed", p)
	var d = s.duplicate(); d.bg_color = Color(0.2,0.2,0.2,0.25); d.border_color = Color(0.3,0.3,0.3,0.25)
	btn.add_theme_stylebox_override("disabled", d)
	btn.add_theme_color_override("font_color",         accent)
	btn.add_theme_color_override("font_hover_color",   accent)
	btn.add_theme_color_override("font_pressed_color", C_TEXT)
	btn.add_theme_color_override("font_disabled_color",C_TEXT_DIM)
	return btn

func _make_icon_btn(icon: String, color: Color, callback: Callable) -> Button:
	var btn = Button.new(); btn.text = icon
	btn.custom_minimum_size = Vector2(36, 36)
	btn.add_theme_font_size_override("font_size", 16)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var flat = StyleBoxFlat.new(); flat.bg_color = Color(0,0,0,0); flat.set_corner_radius_all(6)
	flat.content_margin_left = 4; flat.content_margin_right = 4
	flat.content_margin_top  = 3; flat.content_margin_bottom = 3
	btn.add_theme_stylebox_override("normal", flat)
	var hv = flat.duplicate(); hv.bg_color = Color(color.r, color.g, color.b, 0.15)
	btn.add_theme_stylebox_override("hover", hv)
	btn.add_theme_stylebox_override("pressed", flat)
	btn.add_theme_color_override("font_color", color)
	btn.pressed.connect(callback)
	return btn

func _make_option_btn(width: int) -> OptionButton:
	var ob = OptionButton.new()
	ob.custom_minimum_size = Vector2(width, 32)
	ob.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var s = StyleBoxFlat.new(); s.bg_color = C_SURFACE2
	s.border_color = Color(C_BORDER.r, C_BORDER.g, C_BORDER.b, 0.55)
	s.set_border_width_all(1); s.set_corner_radius_all(7)
	s.content_margin_left = 10; s.content_margin_right  = 8
	s.content_margin_top  = 3;  s.content_margin_bottom = 3
	ob.add_theme_stylebox_override("normal", s)
	ob.add_theme_stylebox_override("hover",  s)
	ob.add_theme_stylebox_override("focus",  s)
	ob.add_theme_color_override("font_color", C_TEXT)
	ob.add_theme_font_size_override("font_size", 12)
	return ob

func _dlg_label(text: String) -> Label:
	var lbl = Label.new(); lbl.text = text
	lbl.add_theme_color_override("font_color", C_TEXT_DIM)
	lbl.add_theme_font_size_override("font_size", 13)
	return lbl

func _show_toast(message: String, is_error: bool = false) -> void:
	_log("TOAST", message)
	if is_instance_valid(_menu) and _menu.has_method("show_toast"):
		_menu.show_toast(message, is_error); return
	var main_menu = get_tree().get_first_node_in_group("main_menu")
	if main_menu and main_menu.has_method("show_toast"):
		main_menu.show_toast(message, is_error)
