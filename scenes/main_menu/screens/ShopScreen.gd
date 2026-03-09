extends Node

# ============================================================
# ShopScreen.gd
# ============================================================

const MiniCard = preload("res://scenes/main_menu/components/MiniCard.gd")

# ── Cache de texturas ────────────────────────────────────────
static var _tex_cache:       Dictionary = {}
static var _tex_cache_order: Array      = []
const TEX_CACHE_MAX = 100

static func _cache_texture(path: String, tex: Texture2D) -> void:
	if path in _tex_cache:
		_tex_cache_order.erase(path)
		_tex_cache_order.append(path)
		return
	while _tex_cache_order.size() >= TEX_CACHE_MAX:
		var oldest = _tex_cache_order.pop_front()
		_tex_cache.erase(oldest)
	_tex_cache[path] = tex
	_tex_cache_order.append(path)

static func _get_texture(path: String) -> Texture2D:
	if path == "": return null
	if path in _tex_cache: return _tex_cache[path]
	var status = ResourceLoader.load_threaded_get_status(path)
	if status == ResourceLoader.THREAD_LOAD_LOADED:
		var tex = ResourceLoader.load_threaded_get(path)
		_cache_texture(path, tex)
		return tex
	return null

static func _request_texture(path: String) -> void:
	if path == "" or path in _tex_cache: return
	var status = ResourceLoader.load_threaded_get_status(path)
	if status in [ResourceLoader.THREAD_LOAD_IN_PROGRESS, ResourceLoader.THREAD_LOAD_LOADED]: return
	ResourceLoader.load_threaded_request(path)

static func _load_texture_into(rect: TextureRect, path: String) -> void:
	if path == "": return
	var cached = _get_texture(path)
	if cached:
		rect.texture = cached
		return
	_request_texture(path)
	var timer = Timer.new()
	timer.wait_time = 0.05
	timer.autostart = true
	timer.timeout.connect(func():
		if not is_instance_valid(rect):
			timer.queue_free(); return
		var status = ResourceLoader.load_threaded_get_status(path)
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			var tex = ResourceLoader.load_threaded_get(path)
			_cache_texture(path, tex)
			rect.texture = tex
			timer.queue_free()
		elif status == ResourceLoader.THREAD_LOAD_FAILED:
			timer.queue_free()
	)
	rect.add_child(timer)


static func build(container: Control, menu) -> void:
	var C = menu

	var shop_root = Control.new()
	shop_root.name = "ShopRoot"
	shop_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	container.add_child(shop_root)

	var bg_image = TextureRect.new()
	var bg_tex = load("res://assets/imagen/fondomenu.png")
	if bg_tex: bg_image.texture = bg_tex
	bg_image.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_image.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	bg_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg_image.modulate = Color(0.15, 0.15, 0.15, 1)
	shop_root.add_child(bg_image)

	# ── Header ──────────────────────────────────────────────
	var header = Panel.new()
	header.anchor_left = 0; header.anchor_right  = 1
	header.anchor_top  = 0; header.anchor_bottom = 0
	header.offset_top  = 50; header.offset_bottom = 120
	var hs = StyleBoxFlat.new()
	hs.bg_color = Color(C.COLOR_PANEL.r, C.COLOR_PANEL.g, C.COLOR_PANEL.b, 0.85)
	hs.border_color = Color(C.COLOR_GOLD_DIM.r, C.COLOR_GOLD_DIM.g, C.COLOR_GOLD_DIM.b, 0.3)
	hs.border_width_bottom = 1
	header.add_theme_stylebox_override("panel", hs)
	shop_root.add_child(header)

	var header_hbox = HBoxContainer.new()
	header_hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	header_hbox.add_theme_constant_override("separation", 0)
	header.add_child(header_hbox)

	var accent = ColorRect.new()
	accent.color = C.COLOR_GOLD
	accent.custom_minimum_size = Vector2(6, 0)
	header_hbox.add_child(accent)

	var title_m = MarginContainer.new()
	title_m.add_theme_constant_override("margin_left", 20)
	title_m.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_hbox.add_child(title_m)

	var title_lbl = Label.new()
	title_lbl.text = "🏪 TIENDA"
	title_lbl.add_theme_font_size_override("font_size", 20)
	title_lbl.add_theme_color_override("font_color", C.COLOR_GOLD)
	title_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_m.add_child(title_lbl)

	var currency_hbox = HBoxContainer.new()
	currency_hbox.add_theme_constant_override("separation", 20)
	currency_hbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var currency_m = MarginContainer.new()
	currency_m.add_theme_constant_override("margin_right", 40)
	currency_m.add_child(currency_hbox)
	header_hbox.add_child(currency_m)

	var coins_lbl = Label.new()
	coins_lbl.name = "CoinsLabel"
	coins_lbl.text = "🪙 " + str(PlayerData.coins)
	coins_lbl.add_theme_font_size_override("font_size", 17)
	coins_lbl.add_theme_color_override("font_color", C.COLOR_GOLD)
	currency_hbox.add_child(coins_lbl)

	var gems_lbl = Label.new()
	gems_lbl.name = "GemsLabel"
	gems_lbl.text = "💎 " + str(PlayerData.gems)
	gems_lbl.add_theme_font_size_override("font_size", 17)
	gems_lbl.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0))
	currency_hbox.add_child(gems_lbl)

	# ── Scroll principal ─────────────────────────────────────
	var scroll = ScrollContainer.new()
	scroll.anchor_left = 0; scroll.anchor_right  = 1
	scroll.anchor_top  = 0; scroll.anchor_bottom = 1
	scroll.offset_top  = 130; scroll.offset_bottom = -10
	scroll.offset_left = 40;  scroll.offset_right  = -40
	UITheme.apply_scrollbar_theme(scroll)
	shop_root.add_child(scroll)

	var main_vbox = VBoxContainer.new()
	main_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_vbox.add_theme_constant_override("separation", 30)
	scroll.add_child(main_vbox)

	# Precargar imágenes
	_request_texture("res://assets/Sobres/SobreFuego.png")
	_request_texture("res://assets/Sobres/SobreAgua.png")
	_request_texture("res://assets/Sobres/SobreHierba.png")
	_request_texture("res://assets/Sobres/legendary.png")
	_request_texture("res://assets/Sobres/Lava.jpg")
	_request_texture("res://assets/Sobres/Turmoil.jpg")
	_request_texture("res://assets/cards/Neo Genesis/sneasel-alt.png")

	# ── Sección: Sobres Neo Genesis ──────────────────────────
	_section_label(main_vbox, "SOBRES DE EXPANSIÓN · Neo Genesis", C.COLOR_GOLD_DIM)

	var packs_hbox = HBoxContainer.new()
	packs_hbox.add_theme_constant_override("separation", 30)
	main_vbox.add_child(packs_hbox)

	_create_pack_card(shop_root, menu, packs_hbox, "typhlosion_pack", "Sobre Typhlosion",
		"res://assets/Sobres/SobreFuego.png",  100, Color(0.8, 0.2, 0.2), "coins")
	_create_pack_card(shop_root, menu, packs_hbox, "feraligatr_pack", "Sobre Feraligatr",
		"res://assets/Sobres/SobreAgua.png",   100, Color(0.2, 0.4, 0.8), "coins")
	_create_pack_card(shop_root, menu, packs_hbox, "meganium_pack",   "Sobre Meganium",
		"res://assets/Sobres/SobreHierba.png", 100, Color(0.2, 0.7, 0.3), "coins")

	main_vbox.add_child(UITheme.vspace(10))

	# ── Sección: Sobres Legendary Collection ─────────────────
	_section_label(main_vbox, "SOBRES DE EXPANSIÓN · Legendary Collection", Color(0.85, 0.65, 0.1))

	var lc_packs_hbox = HBoxContainer.new()
	lc_packs_hbox.add_theme_constant_override("separation", 30)
	main_vbox.add_child(lc_packs_hbox)

	_create_pack_card(shop_root, menu, lc_packs_hbox, "legendary_collection_pack", "Sobre Legendary Collection",
		"res://assets/Sobres/legendary.png", 150, Color(0.85, 0.65, 0.1), "coins")

	main_vbox.add_child(UITheme.vspace(10))

	# ── Sección: Starter Decks LC ─────────────────────────────
	_section_label(main_vbox, "🃏 STARTER DECKS · Legendary Collection", Color(0.6, 0.85, 0.4))

	var decks_hbox = HBoxContainer.new()
	decks_hbox.name = "DecksHBox"
	decks_hbox.add_theme_constant_override("separation", 30)
	main_vbox.add_child(decks_hbox)

	# Consultar al servidor qué decks ya compró el usuario
	_fetch_bought_decks(shop_root, menu, decks_hbox)

	main_vbox.add_child(UITheme.vspace(10))

	# ── Sección: Cartas Promo ────────────────────────────────
	_section_label(main_vbox, "✨ CARTAS PROMO · Edición Especial", Color(0.5, 0.8, 1.0))

	var promo_hbox = HBoxContainer.new()
	promo_hbox.add_theme_constant_override("separation", 30)
	main_vbox.add_child(promo_hbox)

	_create_promo_card(shop_root, menu, promo_hbox,
		"sneasel_alt", "Sneasel Full Art",
		"res://assets/cards/Neo Genesis/sneasel-alt.png",
		100, Color(0.3, 0.0, 0.5)
	)

	main_vbox.add_child(UITheme.vspace(10))

	# ── Sección: Mejoras ─────────────────────────────────────
	_section_label(main_vbox, "MEJORAS DE CUENTA", C.COLOR_GOLD_DIM)

	var upgrades_hbox = HBoxContainer.new()
	upgrades_hbox.add_theme_constant_override("separation", 30)
	main_vbox.add_child(upgrades_hbox)

	_create_slot_upgrade_card(shop_root, menu, upgrades_hbox, 500)

	main_vbox.add_child(UITheme.vspace(40))


# ─── HELPER: label de sección ────────────────────────────────
static func _section_label(parent: Control, text: String, color: Color) -> void:
	var lbl = Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 15)
	lbl.add_theme_color_override("font_color", color)
	parent.add_child(lbl)


# ─── HTTP: cargar qué decks ya compró ────────────────────────
static func _fetch_bought_decks(shop_root: Control, menu, decks_hbox: Control) -> void:
	# Placeholder mientras carga
	var loading_lbl = Label.new()
	loading_lbl.name = "DecksLoading"
	loading_lbl.text = "Cargando..."
	loading_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	decks_hbox.add_child(loading_lbl)

	var http = HTTPRequest.new()
	shop_root.add_child(http)

	http.request_completed.connect(func(result, code, _h, body):
		http.queue_free()
		loading_lbl.queue_free()

		var bought: Array = []
		if result == HTTPRequest.RESULT_SUCCESS and code == 200:
			var data = JSON.parse_string(body.get_string_from_utf8())
			if data: bought = data.get("bought_decks", [])
		else:
			# Mostrar error si falla la carga
			var err_lbl = Label.new()
			err_lbl.text = "⚠ Error al cargar decks"
			err_lbl.add_theme_color_override("font_color", Color(0.8, 0.3, 0.3))
			decks_hbox.add_child(err_lbl)
			return

		_create_deck_card(shop_root, menu, decks_hbox,
			"lc_starter_turmoil", "Deck Turmoil",
			"res://assets/Sobres/Turmoil.jpg",
			"⚡🌊 Dark Pokémon + Lightning",
			300, Color(0.2, 0.5, 0.9),
			"lc_starter_turmoil" in bought
		)
		_create_deck_card(shop_root, menu, decks_hbox,
			"lc_starter_lava", "Deck Lava",
			"res://assets/Sobres/Lava.jpg",
			"🔥🥊 Fire + Fighting",
			300, Color(0.9, 0.3, 0.1),
			"lc_starter_lava" in bought
		)
	)

	http.request(
		NetworkManager.BASE_URL + "/api/shop/my-decks",
		["Authorization: Bearer " + NetworkManager.token],
		HTTPClient.METHOD_GET, ""
	)


# ─── CARD DE STARTER DECK ────────────────────────────────────
static func _create_deck_card(shop_root: Control, menu, parent: Control,
		deck_id: String, deck_name: String, img_path: String,
		description: String, price: int, glow_color: Color,
		already_bought: bool) -> void:
	var C   = menu
	var box = PanelContainer.new()
	box.custom_minimum_size = Vector2(240, 340)

	var st = StyleBoxFlat.new()
	st.bg_color = Color(0.08, 0.10, 0.14, 0.97)
	st.border_width_left = 2; st.border_width_right  = 2
	st.border_width_top  = 2; st.border_width_bottom = 2
	st.border_color = glow_color.darkened(0.2) if not already_bought else Color(0.3, 0.5, 0.3)
	st.corner_radius_top_left    = 12; st.corner_radius_top_right    = 12
	st.corner_radius_bottom_left = 12; st.corner_radius_bottom_right = 12
	if not already_bought:
		st.shadow_color = Color(glow_color.r, glow_color.g, glow_color.b, 0.25)
		st.shadow_size  = 10
	box.add_theme_stylebox_override("panel", st)
	parent.add_child(box)

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 8)
	box.add_child(vbox)

	# Imagen del deck
	var img_rect = TextureRect.new()
	img_rect.custom_minimum_size = Vector2(200, 140)
	img_rect.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	img_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	vbox.add_child(img_rect)
	_load_texture_into(img_rect, img_path)

	# Nombre
	var name_lbl = Label.new()
	name_lbl.text = deck_name
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 15)
	name_lbl.add_theme_color_override("font_color", C.COLOR_GOLD if not already_bought else Color(0.5, 0.7, 0.5))
	vbox.add_child(name_lbl)

	# Descripción
	var desc_lbl = Label.new()
	desc_lbl.text = description
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.add_theme_font_size_override("font_size", 11)
	desc_lbl.add_theme_color_override("font_color", C.COLOR_TEXT_DIM)
	vbox.add_child(desc_lbl)

	# Info
	var info_lbl = Label.new()
	info_lbl.text = "60 cartas · 1 por jugador"
	info_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_lbl.add_theme_font_size_override("font_size", 10)
	info_lbl.add_theme_color_override("font_color", Color(0.4, 0.4, 0.5))
	vbox.add_child(info_lbl)

	vbox.add_child(UITheme.vspace(4))

	# Botón
	var buy_btn = Button.new()
	buy_btn.custom_minimum_size   = Vector2(180, 38)
	buy_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	buy_btn.add_theme_font_size_override("font_size", 13)

	if already_bought:
		buy_btn.text     = "✅ Ya obtenido"
		buy_btn.disabled = true
		var st_d = StyleBoxFlat.new()
		st_d.bg_color = Color(0.15, 0.3, 0.15, 0.8)
		st_d.corner_radius_top_left    = 6; st_d.corner_radius_top_right    = 6
		st_d.corner_radius_bottom_left = 6; st_d.corner_radius_bottom_right = 6
		buy_btn.add_theme_stylebox_override("disabled", st_d)
		buy_btn.add_theme_color_override("font_disabled_color", Color(0.4, 0.7, 0.4))
	else:
		buy_btn.text = "🪙 " + str(price) + " monedas"
		var st_btn = StyleBoxFlat.new()
		st_btn.bg_color = glow_color.darkened(0.25)
		st_btn.corner_radius_top_left    = 6; st_btn.corner_radius_top_right    = 6
		st_btn.corner_radius_bottom_left = 6; st_btn.corner_radius_bottom_right = 6
		var st_hov = st_btn.duplicate()
		st_hov.bg_color = glow_color.darkened(0.1)
		buy_btn.add_theme_stylebox_override("normal", st_btn)
		buy_btn.add_theme_stylebox_override("hover",  st_hov)
		buy_btn.add_theme_color_override("font_color", Color.WHITE)
		buy_btn.pressed.connect(func():
			_buy_deck(shop_root, menu, deck_id, price, buy_btn)
		)
	vbox.add_child(buy_btn)


# ─── HTTP: COMPRAR DECK ──────────────────────────────────────
static func _buy_deck(shop_root: Control, menu, deck_id: String, price: int, btn: Button) -> void:
	if PlayerData.coins < price:
		_show_toast(shop_root, "🪙 Monedas insuficientes", Color(0.8, 0.2, 0.2))
		return

	btn.disabled = true
	btn.text     = "Comprando..."

	var http = HTTPRequest.new()
	shop_root.add_child(http)

	http.request_completed.connect(func(result, code, _h, body):
		http.queue_free()

		if result != HTTPRequest.RESULT_SUCCESS or code != 200:
			var err_data = JSON.parse_string(body.get_string_from_utf8())
			var msg = err_data.get("error", "Error al comprar") if err_data else "Error de red"
			_show_toast(shop_root, "⚠ " + msg, Color(0.8, 0.2, 0.2))
			btn.disabled = false
			btn.text     = "🪙 " + str(price) + " monedas"
			return

		var data = JSON.parse_string(body.get_string_from_utf8())
		if not data or not data.get("success", false):
			_show_toast(shop_root, "⚠ " + data.get("error", "Error"), Color(0.8, 0.2, 0.2))
			btn.disabled = false
			btn.text     = "🪙 " + str(price) + " monedas"
			return

		# Actualizar monedas localmente
		if data.has("coins_left"): PlayerData.coins = data["coins_left"]
		_update_currency_ui(shop_root)

		# Añadir cartas del deck a PlayerData
		var cards_list = data.get("cards_list", [])
		for card_id in cards_list:
			PlayerData.add_card(card_id)

		# Marcar botón como obtenido
		btn.text     = "✅ Ya obtenido"
		btn.disabled = true
		var st_d = StyleBoxFlat.new()
		st_d.bg_color = Color(0.15, 0.3, 0.15, 0.8)
		st_d.corner_radius_top_left    = 6; st_d.corner_radius_top_right    = 6
		st_d.corner_radius_bottom_left = 6; st_d.corner_radius_bottom_right = 6
		btn.add_theme_stylebox_override("disabled", st_d)
		btn.add_theme_color_override("font_disabled_color", Color(0.4, 0.7, 0.4))

		var cards_added = data.get("cards_added", 0)
		_show_toast(shop_root,
			"✓ Deck obtenido · " + str(cards_added) + " cartas añadidas a tu colección",
			Color(0.2, 0.7, 0.3))
	)

	http.request(
		NetworkManager.BASE_URL + "/api/shop/buy-deck",
		["Content-Type: application/json", "Authorization: Bearer " + NetworkManager.token],
		HTTPClient.METHOD_POST,
		JSON.stringify({"deck_id": deck_id, "currency": "coins"})
	)


# ─── CARD DE SOBRE ───────────────────────────────────────────
static func _create_pack_card(shop_root, menu, parent, pack_id, pack_name, img_path, price, glow_color, currency := "coins") -> void:
	var C   = menu
	var box = PanelContainer.new()
	box.custom_minimum_size = Vector2(220, 340)

	var st = StyleBoxFlat.new()
	st.bg_color = Color(0.1, 0.12, 0.18, 0.95)
	st.border_width_left = 2; st.border_width_right  = 2
	st.border_width_top  = 2; st.border_width_bottom = 2
	st.border_color = glow_color.darkened(0.3)
	st.corner_radius_top_left    = 12; st.corner_radius_top_right    = 12
	st.corner_radius_bottom_left = 12; st.corner_radius_bottom_right = 12
	box.add_theme_stylebox_override("panel", st)
	parent.add_child(box)

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 8)
	box.add_child(vbox)

	var img_rect = TextureRect.new()
	img_rect.custom_minimum_size = Vector2(160, 200)
	img_rect.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	img_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	vbox.add_child(img_rect)
	_load_texture_into(img_rect, img_path)

	var name_lbl = Label.new()
	name_lbl.text = pack_name
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 14)
	name_lbl.add_theme_color_override("font_color", C.COLOR_TEXT)
	vbox.add_child(name_lbl)

	var price_lbl = Label.new()
	price_lbl.text = ("💎 " if currency == "gems" else "🪙 ") + str(price) + (" gemas" if currency == "gems" else " monedas")
	price_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	price_lbl.add_theme_font_size_override("font_size", 12)
	price_lbl.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0) if currency == "gems" else C.COLOR_GOLD_DIM)
	vbox.add_child(price_lbl)

	var buy_btn = Button.new()
	buy_btn.text = "Comprar"
	buy_btn.custom_minimum_size = Vector2(160, 38)
	buy_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var st_btn = StyleBoxFlat.new()
	st_btn.bg_color = glow_color.darkened(0.2)
	st_btn.corner_radius_top_left    = 6; st_btn.corner_radius_top_right    = 6
	st_btn.corner_radius_bottom_left = 6; st_btn.corner_radius_bottom_right = 6
	buy_btn.add_theme_stylebox_override("normal", st_btn)
	buy_btn.add_theme_color_override("font_color", Color.WHITE)
	buy_btn.add_theme_font_size_override("font_size", 13)
	buy_btn.pressed.connect(func(): _buy_pack(shop_root, menu, pack_id, price, buy_btn, currency))
	vbox.add_child(buy_btn)


# ─── CARD DE CARTA PROMO ─────────────────────────────────────
static func _create_promo_card(shop_root, menu, parent, card_id, card_name, img_path, price_gems, glow_color) -> void:
	var C   = menu
	var box = PanelContainer.new()
	box.custom_minimum_size = Vector2(220, 360)

	var st = StyleBoxFlat.new()
	st.bg_color = Color(0.08, 0.06, 0.14, 0.97)
	st.border_width_left = 2; st.border_width_right  = 2
	st.border_width_top  = 2; st.border_width_bottom = 2
	st.border_color = glow_color.lightened(0.2)
	st.corner_radius_top_left    = 12; st.corner_radius_top_right    = 12
	st.corner_radius_bottom_left = 12; st.corner_radius_bottom_right = 12
	st.shadow_color = Color(glow_color.r, glow_color.g, glow_color.b, 0.4)
	st.shadow_size  = 12
	box.add_theme_stylebox_override("panel", st)
	parent.add_child(box)

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 8)
	box.add_child(vbox)

	var badge = Label.new()
	badge.text = "✨ PROMO"
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.add_theme_font_size_override("font_size", 11)
	badge.add_theme_color_override("font_color", Color(0.5, 0.9, 1.0))
	vbox.add_child(badge)

	var img_rect = TextureRect.new()
	img_rect.custom_minimum_size = Vector2(150, 210)
	img_rect.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	img_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	vbox.add_child(img_rect)
	_load_texture_into(img_rect, img_path)

	var name_lbl = Label.new()
	name_lbl.text = card_name
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 13)
	name_lbl.add_theme_color_override("font_color", C.COLOR_TEXT)
	vbox.add_child(name_lbl)

	var price_lbl = Label.new()
	price_lbl.text = "💎 " + str(price_gems) + " gemas"
	price_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	price_lbl.add_theme_font_size_override("font_size", 13)
	price_lbl.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0))
	vbox.add_child(price_lbl)

	var buy_btn = Button.new()
	buy_btn.text = "💎 Comprar"
	buy_btn.custom_minimum_size = Vector2(160, 38)
	buy_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	buy_btn.add_theme_font_size_override("font_size", 13)
	var st_btn = StyleBoxFlat.new()
	st_btn.bg_color = Color(0.2, 0.05, 0.45, 0.95)
	st_btn.border_color = Color(0.5, 0.4, 1.0, 0.6)
	st_btn.border_width_left = 1; st_btn.border_width_right  = 1
	st_btn.border_width_top  = 1; st_btn.border_width_bottom = 1
	st_btn.corner_radius_top_left    = 6; st_btn.corner_radius_top_right    = 6
	st_btn.corner_radius_bottom_left = 6; st_btn.corner_radius_bottom_right = 6
	var st_btn_hover = st_btn.duplicate()
	st_btn_hover.bg_color = Color(0.3, 0.1, 0.6, 0.95)
	buy_btn.add_theme_stylebox_override("normal", st_btn)
	buy_btn.add_theme_stylebox_override("hover",  st_btn_hover)
	buy_btn.add_theme_color_override("font_color", Color.WHITE)
	buy_btn.pressed.connect(func(): _buy_promo_card(shop_root, menu, card_id, price_gems, buy_btn))
	vbox.add_child(buy_btn)


# ─── CARD DE SLOT ────────────────────────────────────────────
static func _create_slot_upgrade_card(shop_root, menu, parent, price) -> void:
	var C   = menu
	var box = PanelContainer.new()
	box.custom_minimum_size = Vector2(220, 200)
	var st = StyleBoxFlat.new()
	st.bg_color = Color(0.15, 0.12, 0.18, 0.95)
	st.border_width_left = 2; st.border_width_right  = 2
	st.border_width_top  = 2; st.border_width_bottom = 2
	st.border_color = C.COLOR_PURPLE
	st.corner_radius_top_left    = 12; st.corner_radius_top_right    = 12
	st.corner_radius_bottom_left = 12; st.corner_radius_bottom_right = 12
	box.add_theme_stylebox_override("panel", st)
	parent.add_child(box)

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 8)
	box.add_child(vbox)

	var icon = Label.new()
	icon.text = "🗃️"
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.add_theme_font_size_override("font_size", 40)
	vbox.add_child(icon)

	var n = Label.new()
	n.text = "Nuevo Slot de Mazo"
	n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	n.add_theme_font_size_override("font_size", 14)
	n.add_theme_color_override("font_color", C.COLOR_TEXT)
	vbox.add_child(n)

	vbox.add_child(UITheme.vspace(8))

	var btn = Button.new()
	btn.text = "🪙 " + str(price) + " monedas"
	btn.custom_minimum_size = Vector2(160, 38)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var st_btn = StyleBoxFlat.new()
	st_btn.bg_color = C.COLOR_PURPLE.darkened(0.2)
	st_btn.corner_radius_top_left    = 6; st_btn.corner_radius_top_right    = 6
	st_btn.corner_radius_bottom_left = 6; st_btn.corner_radius_bottom_right = 6
	btn.add_theme_stylebox_override("normal", st_btn)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_font_size_override("font_size", 13)
	btn.pressed.connect(func(): _buy_slot(shop_root, menu, price, btn))
	vbox.add_child(btn)


# ─── HTTP: COMPRAR SOBRE ─────────────────────────────────────
static func _buy_pack(shop_root: Control, menu, pack_id: String, price: int, btn: Button, currency := "coins") -> void:
	var balance = PlayerData.gems if currency == "gems" else PlayerData.coins
	if balance < price:
		_show_toast(shop_root, ("💎" if currency == "gems" else "🪙") + " Saldo insuficiente", Color(0.8, 0.2, 0.2))
		return

	btn.disabled = true
	btn.text     = "Comprando..."

	var http = HTTPRequest.new()
	shop_root.add_child(http)

	http.request_completed.connect(func(result, code, _h, body):
		http.queue_free()
		btn.disabled = false
		btn.text     = "Comprar"

		if result != HTTPRequest.RESULT_SUCCESS or code != 200:
			var err_data = JSON.parse_string(body.get_string_from_utf8())
			var msg = err_data.get("error", "Error al comprar") if err_data else "Error de red"
			_show_toast(shop_root, "⚠ " + msg, Color(0.8, 0.2, 0.2))
			return

		var data = JSON.parse_string(body.get_string_from_utf8())
		if not data or not data.get("success", false):
			_show_toast(shop_root, "⚠ " + data.get("error", "Error"), Color(0.8, 0.2, 0.2))
			return

		if data.has("coins_left"): PlayerData.coins = data["coins_left"]
		if data.has("gems_left"):  PlayerData.gems  = data["gems_left"]
		_update_currency_ui(shop_root)

		var pending = data.get("pending_packs", 0)
		_show_toast(shop_root,
			"✓ Sobre guardado · " + str(pending) + " sin abrir en tu colección",
			Color(0.2, 0.7, 0.3))
	)

	http.request(
		NetworkManager.BASE_URL + "/api/shop/buy",
		["Content-Type: application/json", "Authorization: Bearer " + NetworkManager.token],
		HTTPClient.METHOD_POST,
		JSON.stringify({"pack_type": pack_id, "currency": currency})
	)


# ─── HTTP: COMPRAR CARTA PROMO ───────────────────────────────
static func _buy_promo_card(shop_root: Control, menu, card_id: String, price_gems: int, btn: Button) -> void:
	if PlayerData.gems < price_gems:
		_show_toast(shop_root, "💎 Gemas insuficientes", Color(0.8, 0.2, 0.2))
		return

	btn.disabled = true
	btn.text     = "Comprando..."

	var http = HTTPRequest.new()
	shop_root.add_child(http)

	http.request_completed.connect(func(result, code, _h, body):
		http.queue_free()
		btn.disabled = false
		btn.text     = "💎 Comprar"

		if result != HTTPRequest.RESULT_SUCCESS or code != 200:
			var err_data = JSON.parse_string(body.get_string_from_utf8())
			var msg = err_data.get("error", "Error al comprar") if err_data else "Error de red"
			_show_toast(shop_root, "⚠ " + msg, Color(0.8, 0.2, 0.2))
			return

		var data = JSON.parse_string(body.get_string_from_utf8())
		if not data or not data.get("success", false):
			_show_toast(shop_root, "⚠ " + data.get("error", "Error"), Color(0.8, 0.2, 0.2))
			return

		if data.has("coins_left"): PlayerData.coins = data["coins_left"]
		if data.has("gems_left"):  PlayerData.gems  = data["gems_left"]
		_update_currency_ui(shop_root)

		PlayerData.add_card(data.get("card_id", card_id))
		btn.text     = "✅ Obtenida"
		btn.disabled = true
		_show_toast(shop_root, "✨ ¡Carta promo obtenida!", Color(0.4, 0.2, 0.9))
	)

	http.request(
		NetworkManager.BASE_URL + "/api/shop/buy-card",
		["Content-Type: application/json", "Authorization: Bearer " + NetworkManager.token],
		HTTPClient.METHOD_POST,
		JSON.stringify({"card_id": card_id, "currency": "gems"})
	)


# ─── HTTP: ABRIR SOBRE ────────────────────────────────────────
static func open_pack_from_collection(shop_root: Control, menu, pack_type: String, on_done: Callable) -> void:
	var http = HTTPRequest.new()
	shop_root.add_child(http)

	http.request_completed.connect(func(result, code, _h, body):
		http.queue_free()
		if result != HTTPRequest.RESULT_SUCCESS or code != 200:
			_show_toast(shop_root, "⚠ Error al abrir sobre", Color(0.8, 0.2, 0.2))
			return
		var data = JSON.parse_string(body.get_string_from_utf8())
		if data and data.get("success"):
			var cards = data.get("cards_received", [])
			for card in cards:
				PlayerData.add_card(card)
			on_done.call(cards)
	)

	http.request(
		NetworkManager.BASE_URL + "/api/shop/open-pack",
		["Content-Type: application/json", "Authorization: Bearer " + NetworkManager.token],
		HTTPClient.METHOD_POST,
		JSON.stringify({"pack_type": pack_type})
	)


# ─── HTTP: COMPRAR SLOT ───────────────────────────────────────
static func _buy_slot(shop_root: Control, menu, price: int, btn: Button) -> void:
	if PlayerData.coins < price:
		_show_toast(shop_root, "🪙 Monedas insuficientes", Color(0.8, 0.2, 0.2))
		return

	btn.disabled = true
	var http = HTTPRequest.new()
	shop_root.add_child(http)

	http.request_completed.connect(func(result, code, _h, body):
		http.queue_free()
		btn.disabled = false
		if result != HTTPRequest.RESULT_SUCCESS or code != 200:
			_show_toast(shop_root, "⚠ Error", Color(0.8, 0.2, 0.2))
			return
		var data = JSON.parse_string(body.get_string_from_utf8())
		if data and data.get("success"):
			PlayerData.coins = data.get("coins_left", PlayerData.coins)
			_update_currency_ui(shop_root)
			_show_toast(shop_root, "✓ Nuevo slot desbloqueado", Color(0.2, 0.7, 0.3))
	)

	http.request(
		NetworkManager.BASE_URL + "/api/shop/buy-slot",
		["Content-Type: application/json", "Authorization: Bearer " + NetworkManager.token],
		HTTPClient.METHOD_POST, "{}"
	)


# ─── HELPERS ─────────────────────────────────────────────────
static func _update_currency_ui(shop_root: Control) -> void:
	var coins_lbl = UITheme.find_node(shop_root, "CoinsLabel") as Label
	if coins_lbl: coins_lbl.text = "🪙 " + str(PlayerData.coins)
	var gems_lbl = UITheme.find_node(shop_root, "GemsLabel") as Label
	if gems_lbl: gems_lbl.text = "💎 " + str(PlayerData.gems)

static func _update_coins_ui(shop_root: Control) -> void:
	_update_currency_ui(shop_root)

static func _show_toast(parent: Control, msg: String, color: Color) -> void:
	var toast = Label.new()
	toast.text = msg
	toast.add_theme_font_size_override("font_size", 14)
	toast.add_theme_color_override("font_color", Color.WHITE)
	var st = StyleBoxFlat.new()
	st.bg_color = Color(color.r * 0.4, color.g * 0.4, color.b * 0.4, 0.95)
	st.border_color = color
	st.border_width_left = 1; st.border_width_right  = 1
	st.border_width_top  = 1; st.border_width_bottom = 1
	st.corner_radius_top_left    = 8; st.corner_radius_top_right    = 8
	st.corner_radius_bottom_left = 8; st.corner_radius_bottom_right = 8
	st.content_margin_left = 16; st.content_margin_right  = 16
	st.content_margin_top  = 10; st.content_margin_bottom = 10
	toast.add_theme_stylebox_override("normal", st)
	toast.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	toast.offset_bottom = -60
	toast.offset_top    = -100
	toast.offset_left   = -250
	toast.offset_right  = 250
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast.z_index = 100
	parent.add_child(toast)
	var tw = toast.create_tween()
	tw.tween_interval(2.0)
	tw.tween_property(toast, "modulate:a", 0.0, 0.5)
	tw.tween_callback(toast.queue_free)


# ─── RAREZA ──────────────────────────────────────────────────
static func rarity_color(rarity: String) -> Color:
	match rarity:
		"RARE":       return Color(0.95, 0.85, 0.1,  1.0)
		"RARE_HOLO":  return Color(0.2,  0.85, 1.0,  1.0)
		"ULTRA_RARE": return Color(1.0,  0.45, 0.05, 1.0)
		_:            return Color(0.6,  0.6,  0.6,  1.0)

static func rarity_weight(rarity: String) -> int:
	match rarity:
		"COMMON":     return 0
		"UNCOMMON":   return 1
		"RARE":       return 2
		"RARE_HOLO":  return 3
		"ULTRA_RARE": return 4
	return 0

static func clicks_needed(rarity: String) -> int:
	match rarity:
		"RARE":       return 2
		"RARE_HOLO":  return 3
		"ULTRA_RARE": return 6
		_:            return 1

const ULTRA_RARE_CHARGE_COLORS = [
	Color(0.3,  0.0,  0.6,  0.8),
	Color(0.0,  0.2,  0.9,  0.8),
	Color(0.0,  0.8,  0.4,  0.8),
	Color(0.95, 0.8,  0.0,  0.8),
	Color(1.0,  0.3,  0.0,  0.8),
	Color(1.0,  0.05, 0.05, 0.9),
]

static func spawn_particles(parent: Control, origin: Vector2, rarity: String) -> void:
	var base_color = rarity_color(rarity)
	var count = 12 if rarity == "RARE" else (20 if rarity == "RARE_HOLO" else 35)
	for i in range(count):
		var p = ColorRect.new()
		var size = randf_range(3.0, 8.0)
		p.custom_minimum_size = Vector2(size, size)
		p.color = base_color.lightened(randf_range(0.0, 0.4))
		p.position = origin
		parent.add_child(p)
		var angle  = randf_range(0.0, TAU)
		var speed  = randf_range(60.0, 220.0)
		var target = origin + Vector2(cos(angle), sin(angle)) * speed
		var tw = p.create_tween().set_parallel(true)
		tw.tween_property(p, "position", target, randf_range(0.5, 1.0)).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.tween_property(p, "modulate:a", 0.0, randf_range(0.4, 0.9)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_callback(p.queue_free).set_delay(1.0)
