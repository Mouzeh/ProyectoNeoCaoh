extends Node
class_name BoardRenderer

# ─── SEÑALES ────────────────────────────────────────────────
signal my_active_clicked()
signal my_discard_clicked()
signal opp_discard_clicked()

# ─── CONSTANTES ─────────────────────────────────────────────
const CARD_W = 130
const CARD_H = 182
const COLOR_GOLD = Color(0.85, 0.72, 0.30)
const COLOR_TEXT = Color(0.92, 0.88, 0.75)
const HP_HIGH = Color(0.20, 0.85, 0.30)
const HP_MID  = Color(0.95, 0.80, 0.10)
const HP_LOW  = Color(0.90, 0.20, 0.15)

# ─── RUTAS ──────────────────────────────────────────────────
const PATH_TOKENS  = "res://assets/imagen/tokens/"
const PATH_TYPES   = "res://assets/imagen/TypesIcons/"
const PATH_SLEEVES = "res://assets/sleeves/"

# IDs de energías especiales que tienen efecto propio (muestran ícono "?")
const SPECIAL_ENERGY_IDS = [
	"darkness_energy", "recycle_energy",
	"lc_full-heal-energy", "lc_potion-energy",
	"metal_energy",
]

# ─── ESTADO Y CACHÉ ─────────────────────────────────────────
var zones:         Dictionary = {}
var opp_sleeve_id: String     = "default"
var vp_width:      float      = 0.0
var _parent:       Node       = null
var _turn_banner:  Control    = null
var _zone_card_cache:      Dictionary = {}
var _tex_cache:            Dictionary = {}
var _opp_hand_cache_str:   String     = ""
var _discard_btns_added:   bool       = false
var _last_render_state:    Dictionary = {}

func _get_cached_tex(path: String) -> Texture2D:
	if _tex_cache.has(path): return _tex_cache[path]
	var tex: Texture2D = load(path) if ResourceLoader.exists(path) else null
	_tex_cache[path] = tex
	return tex

func setup(board_zones: Dictionary, viewport_width: float) -> void:
	zones    = board_zones
	vp_width = viewport_width
	_parent  = get_parent()
	_setup_discard_buttons()

func set_opp_sleeve(sleeve_id: String) -> void:
	opp_sleeve_id = sleeve_id

func get_hovered_card_id() -> String:
	for key in zones.keys():
		if key in ["opp_hand", "my_discard", "opp_discard"]: continue
		var item = zones[key]
		if typeof(item) == TYPE_ARRAY:
			for zone in item:
				if zone and zone.has_node("CardInstance") and zone.get_node("CardInstance").get("is_hovered"):
					return str(_zone_card_cache.get(zone.name, "")).replace("_oculto", "")
		else:
			var zone = item
			if zone and zone.has_node("CardInstance") and zone.get_node("CardInstance").get("is_hovered"):
				return str(_zone_card_cache.get(zone.name, "")).replace("_oculto", "")

	if zones.has("opp_hand") and zones["opp_hand"]:
		for child in zones["opp_hand"].get_children():
			if child.get("is_hovered") and child.has_meta("card_id"):
				return str(child.get_meta("card_id"))

	for key in ["my_discard", "opp_discard"]:
		if zones.has(key) and zones[key]:
			var top_card = zones[key].get_node_or_null("DiscardTopCard")
			if top_card and top_card.get("is_hovered") and top_card.has_meta("card_id"):
				return str(top_card.get_meta("card_id"))
	return ""

func get_hovered_pokemon_data() -> Dictionary:
	var my_data  = _last_render_state.get("my",       {})
	var opp_data = _last_render_state.get("opponent", {})

	var active_zone = zones.get("my_active")
	if active_zone and active_zone.has_node("CardInstance"):
		if active_zone.get_node("CardInstance").get("is_hovered"):
			var active = my_data.get("active", null)
			if active != null and active is Dictionary:
				return active

	var my_bench_zones = zones.get("my_bench", [])
	var my_bench_data  = my_data.get("bench", [])
	for i in range(my_bench_zones.size()):
		var zone = my_bench_zones[i]
		if zone and zone.has_node("CardInstance"):
			if zone.get_node("CardInstance").get("is_hovered"):
				if i < my_bench_data.size() and my_bench_data[i] is Dictionary:
					return my_bench_data[i]

	var opp_active_zone = zones.get("opp_active")
	if opp_active_zone and opp_active_zone.has_node("CardInstance"):
		if opp_active_zone.get_node("CardInstance").get("is_hovered"):
			var opp_active = opp_data.get("active", null)
			if opp_active != null and opp_active is Dictionary:
				return opp_active

	var opp_bench_zones = zones.get("opp_bench", [])
	var opp_bench_data  = opp_data.get("bench", [])
	for i in range(opp_bench_zones.size()):
		var zone = opp_bench_zones[i]
		if zone and zone.has_node("CardInstance"):
			if zone.get_node("CardInstance").get("is_hovered"):
				if i < opp_bench_data.size() and opp_bench_data[i] is Dictionary:
					return opp_bench_data[i]

	return {}

func _setup_discard_buttons() -> void:
	if _discard_btns_added: return
	_discard_btns_added = true
	_add_discard_button(zones.get("my_discard"),  true)
	_add_discard_button(zones.get("opp_discard"), false)

func _add_discard_button(zone: Control, is_mine: bool) -> void:
	if not zone: return
	var lbl = Label.new()
	lbl.name = "DiscardLabel"
	lbl.text = "Descarte"
	lbl.position = Vector2(0, zone.size.y - 16)
	lbl.size     = Vector2(zone.size.x, 14)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 9)
	lbl.add_theme_color_override("font_color", Color(0.65, 0.60, 0.38))
	zone.add_child(lbl)

	var btn = Button.new()
	btn.name    = "DiscardBtn"
	btn.set_anchors_preset(Control.PRESET_FULL_RECT)
	btn.flat    = true
	btn.z_index = 20
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var normal_s = StyleBoxFlat.new()
	normal_s.bg_color = Color(0, 0, 0, 0)
	btn.add_theme_stylebox_override("normal", normal_s)
	var hover_s = StyleBoxFlat.new()
	hover_s.bg_color                  = Color(0.85, 0.72, 0.30, 0.18)
	hover_s.corner_radius_top_left    = 6; hover_s.corner_radius_top_right    = 6
	hover_s.corner_radius_bottom_left = 6; hover_s.corner_radius_bottom_right = 6
	btn.add_theme_stylebox_override("hover", hover_s)

	if is_mine:
		btn.pressed.connect(func(): emit_signal("my_discard_clicked"))
	else:
		btn.pressed.connect(func(): emit_signal("opp_discard_clicked"))
	zone.add_child(btn)

func render_board(state: Dictionary) -> void:
	_last_render_state = state

	var my_data  = state.get("my",       {})
	var opp_data = state.get("opponent", {})

	_update_zone_pokemon(zones["my_active"],  my_data.get("active"),  true,  true)
	_update_zone_pokemon(zones["opp_active"], opp_data.get("active"), true,  false)

	var my_bench  = my_data.get("bench",  [])
	var opp_bench = opp_data.get("bench", [])
	for i in range(5):
		_update_zone_pokemon(zones["my_bench"][i],  my_bench[i]  if i < my_bench.size()  else null, false, true)
		_update_zone_pokemon(zones["opp_bench"][i], opp_bench[i] if i < opp_bench.size() else null, false, false)

	_update_counter_zone(zones["my_deck"],    _get_count(my_data,  "deck",   "deck_count"),   "Mazo")
	_update_counter_zone(zones["my_prizes"],  _get_count(my_data,  "prizes", "prizes_count"), "Premios")
	_update_counter_zone(zones["opp_deck"],   _get_count(opp_data, "deck",   "deck_count"),   "Mazo")
	_update_counter_zone(zones["opp_prizes"], _get_count(opp_data, "prizes", "prizes_count"), "Premios")

	_update_discard_zone(zones["my_discard"],  my_data.get("discard",  []))
	_update_discard_zone(zones["opp_discard"], opp_data.get("discard", []))

	var opp_hand_count = _get_count(opp_data, "hand", "hand_count")
	var revealed_hand  = opp_data.get("revealed_hand", [])
	_update_opponent_hand(zones["opp_hand"], opp_hand_count, revealed_hand)

	var stadium_id = state.get("stadium", "")
	if stadium_id == null: stadium_id = ""
	_update_stadium_zone(zones.get("stadium"), stadium_id)

func _get_count(data: Dictionary, array_key: String, count_key: String) -> int:
	var arr = data.get(array_key, null)
	if arr is Array and arr.size() > 0: return arr.size()
	var cnt = data.get(count_key, 0)
	if cnt is float: cnt = int(cnt)
	if cnt is int: return cnt
	if arr is Array: return arr.size()
	return 0

func _update_discard_zone(zone: Control, discard) -> void:
	if not zone: return
	var count: int = discard.size() if discard is Array else 0
	var old_card = zone.get_node_or_null("DiscardTopCard")
	if old_card: old_card.free()

	var num_lbl = zone.get_node_or_null("DiscardCount")
	if not num_lbl:
		num_lbl = Label.new()
		num_lbl.name = "DiscardCount"
		num_lbl.position = Vector2(0, 2)
		num_lbl.size     = Vector2(zone.size.x, 16)
		num_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		num_lbl.add_theme_font_size_override("font_size", 11)
		num_lbl.add_theme_color_override("font_color", COLOR_GOLD)
		zone.add_child(num_lbl)
	num_lbl.text = str(count) if count > 0 else ""

	if count == 0: return
	var top = discard[count - 1]
	if not top: return
	var top_id = top.get("card_id", "") if top is Dictionary else str(top)
	if top_id == "": return

	var card_inst = CardDatabase.create_card_instance(top_id)
	card_inst.name         = "DiscardTopCard"
	card_inst.set_meta("card_id", top_id)
	card_inst.is_draggable = false
	card_inst.z_index      = 5
	card_inst.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fit_node_to_zone(card_inst, zone, 4)
	zone.add_child(card_inst)

func show_turn_banner(is_my_turn: bool) -> void:
	if not _parent: return
	_kill_banner()
	var vp_size = _parent.get_viewport().get_visible_rect().size
	var banner  = Control.new()
	banner.name    = "TurnBanner"
	banner.z_index = 500
	banner.set_anchors_preset(Control.PRESET_FULL_RECT)
	_parent.add_child(banner)
	_turn_banner = banner

	var panel_w: float = vp_size.x * 0.70
	var panel_h := 52.0
	var panel   := Panel.new()
	panel.size     = Vector2(panel_w, panel_h)
	panel.position = Vector2((vp_size.x - panel_w) / 2.0, vp_size.y / 2.0 - panel_h / 2.0)

	var style = StyleBoxFlat.new()
	style.bg_color = Color(1, 1, 1, 0.90) if is_my_turn else Color(0.12, 0.12, 0.14, 0.90)
	style.corner_radius_top_left    = 8; style.corner_radius_top_right    = 8
	style.corner_radius_bottom_left = 8; style.corner_radius_bottom_right = 8
	panel.add_theme_stylebox_override("panel", style)
	banner.add_child(panel)

	var lbl = Label.new()
	lbl.text = "TU TURNO" if is_my_turn else "TURNO DEL RIVAL"
	lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 22)
	lbl.add_theme_color_override("font_color", Color(0.10, 0.10, 0.10) if is_my_turn else Color(0.92, 0.88, 0.75))
	panel.add_child(lbl)

	panel.modulate.a = 0.0
	var tween = _parent.create_tween()
	tween.tween_property(panel, "modulate:a", 1.0, 0.25)
	tween.tween_interval(1.4)
	tween.tween_property(panel, "modulate:a", 0.0, 0.35)
	tween.tween_callback(func(): _kill_banner())

func _kill_banner() -> void:
	if _turn_banner and is_instance_valid(_turn_banner):
		_turn_banner.free()
	_turn_banner = null

func _update_zone_pokemon(zone: Control, pokemon_data, is_active: bool, is_mine: bool) -> void:
	if not zone: return

	var new_card_id:  String = ""
	var is_face_down: bool   = false

	if pokemon_data != null:
		new_card_id  = str(pokemon_data.get("card_id", ""))
		is_face_down = pokemon_data.get("face_down", false)

	var cache_value: String = new_card_id
	if is_face_down or new_card_id == "face_down":
		cache_value += "_oculto"

	var zone_key:  String = zone.name
	var cached_id: String = str(_zone_card_cache.get(zone_key, ""))

	if cache_value != cached_id:
		for child in zone.get_children():
			if child.name not in ["Background", "DropOverlay", "SelectOverlay",
								  "ClickArea", "TrainerClickArea", "BenchClickArea",
								  "DiscardBtn", "DiscardLabel", "DiscardCount",
								  "PowerClickArea", "PowerOverlay"]:
				child.free()
		_zone_card_cache[zone_key] = cache_value

		if new_card_id != "":
			var card_instance
			if is_face_down or new_card_id == "face_down":
				card_instance = _make_card_back("default")
			else:
				var card_data: Dictionary = CardDatabase.get_card(new_card_id)
				if card_data.is_empty(): return
				card_instance = CardDatabase.create_card_instance(new_card_id)
				card_instance.is_draggable = false
				if is_active and is_mine and card_instance.has_signal("card_clicked"):
					card_instance.card_clicked.connect(func(_c): emit_signal("my_active_clicked"))

			card_instance.name    = "CardInstance"
			card_instance.z_index = 1
			_fit_node_to_zone(card_instance, zone, 4)
			zone.add_child(card_instance)

			var ov = Control.new()
			ov.name         = "TokenOverlay"
			ov.size         = Vector2(CARD_W, CARD_H)
			ov.mouse_filter = Control.MOUSE_FILTER_IGNORE
			card_instance.add_child(ov)

	if new_card_id == "" or is_face_down or new_card_id == "face_down":
		return

	var card_instance = zone.get_node_or_null("CardInstance")
	if not card_instance: return

	var overlay = card_instance.get_node_or_null("TokenOverlay")
	if overlay == null:
		overlay = Control.new()
		overlay.name         = "TokenOverlay"
		overlay.size         = Vector2(CARD_W, CARD_H)
		overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card_instance.add_child(overlay)
	else:
		for child in overlay.get_children():
			overlay.remove_child(child)
			child.queue_free()

	if is_active:
		var card_data: Dictionary = CardDatabase.get_card(new_card_id)
		var max_hp: int = int(card_data.get("hp", 0))
		var dmg: int    = int(pokemon_data.get("damage_counters", 0))
		var cur_hp: int = max(0, max_hp - dmg * 10)
		if max_hp > 0:
			_add_hp_badge(overlay, cur_hp, max_hp)

	var status: String = str(pokemon_data.get("status", ""))
	if status != "" and status != "null":
		_add_status_token(overlay, status)
	if pokemon_data.get("is_poisoned", false):
		_add_status_token(overlay, "POISONED")
	if pokemon_data.get("is_burned", false):
		_add_status_token(overlay, "BURNED")

	var dmg_counters: int = int(pokemon_data.get("damage_counters", 0))
	if dmg_counters > 0:
		_add_damage_tokens(overlay, dmg_counters)

	var energies: Array = pokemon_data.get("attached_energy", [])
	if energies.size() > 0:
		_add_energy_indicators(overlay, energies)

	# ── PokéTools ──────────────────────────────────────────
	var tool = pokemon_data.get("tool", null)
	if tool != null and str(tool) != "" and str(tool) != "null":
		_add_tool_indicators(overlay, [tool])


# ============================================================
# HP BADGE
# ============================================================
func _add_hp_badge(overlay: Control, cur_hp: int, max_hp: int) -> void:
	var ratio:    float = float(cur_hp) / float(max_hp)
	var hp_color: Color = HP_HIGH if ratio > 0.50 else (HP_MID if ratio > 0.25 else HP_LOW)
	var badge = Panel.new()
	badge.name     = "HpBadge"
	var bw: float  = CARD_W - 8
	var bh: float  = 20.0
	badge.size     = Vector2(bw, bh)
	badge.position = Vector2(4, 2)
	var style = StyleBoxFlat.new()
	style.bg_color                  = Color(0, 0, 0, 0.72)
	style.corner_radius_top_left    = 4; style.corner_radius_top_right    = 4
	style.corner_radius_bottom_left = 4; style.corner_radius_bottom_right = 4
	badge.add_theme_stylebox_override("panel", style)

	var bar_bg = ColorRect.new()
	bar_bg.size     = Vector2(bw - 4, 5)
	bar_bg.position = Vector2(2, bh - 7)
	bar_bg.color    = Color(0.2, 0.2, 0.2)
	badge.add_child(bar_bg)

	var bar_fill = ColorRect.new()
	bar_fill.size     = Vector2((bw - 4) * ratio, 5)
	bar_fill.position = Vector2(2, bh - 7)
	bar_fill.color    = hp_color
	badge.add_child(bar_fill)

	var lbl = Label.new()
	lbl.text     = "%d/%d" % [cur_hp, max_hp]
	lbl.position = Vector2(0, 1)
	lbl.size     = Vector2(bw, 14)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.add_theme_color_override("font_color", hp_color)
	badge.add_child(lbl)
	overlay.add_child(badge)


# ============================================================
# STATUS TOKEN
# ============================================================
func _add_status_token(overlay: Control, status: String) -> void:
	const TOKEN_FILES = {
		"POISONED":  "poison.png",   "BURNED":    "burn.png",
		"ASLEEP":    "asleep.png",   "PARALYZED": "paralyzed.png",
		"CONFUSED":  "confused.png",
	}
	var file_name: String = str(TOKEN_FILES.get(status, ""))
	if file_name == "": return
	var existing: int = 0
	for child in overlay.get_children():
		if child.name.begins_with("StatusToken_"): existing += 1
	var tex_path:   String    = PATH_TOKENS + file_name
	var cached_tex: Texture2D = _get_cached_tex(tex_path)

	if cached_tex:
		var icon = TextureRect.new()
		icon.name         = "StatusToken_" + status
		icon.texture      = cached_tex
		icon.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.size         = Vector2(24, 24)
		icon.position     = Vector2(CARD_W - 28 - existing * 26, 26)
		overlay.add_child(icon)
	else:
		const EMOJIS = {"POISONED": "☠", "BURNED": "🔥", "ASLEEP": "💤", "PARALYZED": "⚡", "CONFUSED": "💫"}
		var badge = Label.new()
		badge.name     = "StatusToken_" + status
		badge.text     = EMOJIS.get(status, "?")
		badge.position = Vector2(CARD_W - 22 - existing * 20, 26)
		badge.add_theme_font_size_override("font_size", 14)
		overlay.add_child(badge)


# ============================================================
# DAMAGE TOKENS
# ============================================================
func _add_damage_tokens(overlay: Control, counters: int) -> void:
	var fifties:  int   = counters / 5
	var tens:     int   = counters % 5
	var offset_x: float = 6.0
	var token_y:  float = CARD_H / 2.0 - 10.0
	for _i in range(fifties):
		_spawn_token_sprite(overlay, PATH_TOKENS + "damage_50.png", Vector2(offset_x, token_y), "50")
		offset_x += 18.0
	for _i in range(tens):
		_spawn_token_sprite(overlay, PATH_TOKENS + "damage_10.png", Vector2(offset_x, token_y), "10")
		offset_x += 18.0

func _spawn_token_sprite(overlay: Control, path: String, pos: Vector2, fallback: String) -> void:
	var cached_tex: Texture2D = _get_cached_tex(path)
	if cached_tex:
		var icon = TextureRect.new()
		icon.texture      = cached_tex
		icon.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.size         = Vector2(24, 24)
		icon.position     = pos
		overlay.add_child(icon)
	else:
		var bg = ColorRect.new()
		bg.color    = Color(0.75, 0.10, 0.10, 0.90)
		bg.size     = Vector2(20, 20)
		bg.position = pos
		var lbl = Label.new()
		lbl.text = fallback
		lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 9)
		bg.add_child(lbl)
		overlay.add_child(bg)


# ============================================================
# ENERGY INDICATORS
# ── Tamaño aumentado a 24×24 (antes 16×16)
# ── Energías especiales muestran ícono "?" y permiten zoom
# ============================================================
func _add_energy_indicators(overlay: Control, energies: Array) -> void:
	const ICON_SIZE   := 24
	const ICON_SPACING := 24
	var start_y: float = CARD_H - 26.0

	for i in range(min(energies.size(), 6)):
		var energy_entry = energies[i]

		# Obtener card_id de la entrada (puede ser string o dict)
		var card_id: String = ""
		if energy_entry is Dictionary:
			card_id = str(energy_entry.get("card_id", ""))
		else:
			card_id = str(energy_entry)

		var is_special := _is_special_energy(card_id)
		var icon_path:  String
		var icon_tex:   Texture2D

		if is_special:
			icon_path = PATH_TYPES + "?.png"
			icon_tex  = _get_cached_tex(icon_path)
		else:
			var e_type: String = str(CardDatabase.get_energy_type(energy_entry))
			icon_tex  = _get_type_icon(e_type)

		var pos = Vector2(4 + i * ICON_SPACING, start_y)

		if icon_tex:
			var icon = TextureRect.new()
			icon.name         = "EnergyIcon_%d" % i
			icon.texture      = icon_tex
			icon.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.size         = Vector2(ICON_SIZE, ICON_SIZE)
			icon.position     = pos
			icon.mouse_filter = Control.MOUSE_FILTER_IGNORE

			# Zoom al hacer Z → guardamos card_id como meta para que
			# get_hovered_card_id() lo pueda devolver si se necesita.
			# Pero lo más limpio es hacer que el BoardRenderer notifique
			# al Battleboard directamente cuando se haga hover + Z.
			# Por ahora guardamos meta en el ícono:
			if is_special and card_id != "":
				icon.set_meta("zoom_card_id", card_id)
				icon.mouse_filter = Control.MOUSE_FILTER_STOP
				icon.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
				# Tooltip rápido
				icon.tooltip_text = CardDatabase.get_card(card_id).get("name", card_id)
				# Al hacer gui_input (clic) → zoom
				icon.gui_input.connect(func(ev: InputEvent):
					if ev is InputEventMouseButton and ev.pressed \
							and ev.button_index == MOUSE_BUTTON_LEFT:
						_request_card_zoom(card_id)
				)

			overlay.add_child(icon)
		else:
			# Fallback dot
			var dot = ColorRect.new()
			dot.name     = "EnergyDot_%d" % i
			dot.size     = Vector2(ICON_SIZE - 2, ICON_SIZE - 2)
			dot.position = pos + Vector2(1, 1)
			dot.color    = Color(0.9, 0.2, 0.8)
			overlay.add_child(dot)


# ============================================================
# TOOL INDICATORS
# ── Ícono entrenador.png al lado DERECHO de la carta
# ── Clic abre zoom de la carta del tool
# ============================================================
func _add_tool_indicators(overlay: Control, tools: Array) -> void:
	const ICON_SIZE    := 24
	const ICON_SPACING := 26

	for i in range(min(tools.size(), 3)):
		var tool_entry = tools[i]

		var card_id: String = ""
		if tool_entry is Dictionary:
			card_id = str(tool_entry.get("card_id", ""))
		else:
			card_id = str(tool_entry)

		var icon_path := PATH_TYPES + "?.png"
		var icon_tex  := _get_cached_tex(icon_path)

		# Posición: esquina derecha, apilados verticalmente
		var pos = Vector2(CARD_W - ICON_SIZE - 6, 28 + i * ICON_SPACING)

		if icon_tex:
			var icon = TextureRect.new()
			icon.name         = "ToolIcon_%d" % i
			icon.texture      = icon_tex
			icon.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.size         = Vector2(ICON_SIZE, ICON_SIZE)
			icon.position     = pos
			icon.mouse_filter = Control.MOUSE_FILTER_STOP
			icon.z_index = 10
			icon.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

			if card_id != "":
				icon.tooltip_text = CardDatabase.get_card(card_id).get("name", card_id)
				icon.set_meta("zoom_card_id", card_id)
				icon.gui_input.connect(func(ev: InputEvent):
					if ev is InputEventMouseButton and ev.pressed \
							and ev.button_index == MOUSE_BUTTON_LEFT:
						_request_card_zoom(card_id)
				)

			overlay.add_child(icon)
		else:
			# Fallback label
			var lbl = Label.new()
			lbl.name     = "ToolLabel_%d" % i
			lbl.text     = "🃏"
			lbl.position = pos
			lbl.add_theme_font_size_override("font_size", 14)
			overlay.add_child(lbl)


# ============================================================
# ZOOM DE CARTA ADJUNTA (energía especial o tool)
# ── Llama al OverlayManager del padre si existe
# ============================================================
func _request_card_zoom(card_id: String) -> void:
	if not _parent: return
	# Intentar llamar open_zoom a través del overlays del BattleBoard
	if _parent.has_method("_zoom_attached_card"):
		_parent._zoom_attached_card(card_id)
		return
	# Fallback: buscar overlays directamente
	var overlays = _parent.get("overlays")
	if overlays and overlays.has_method("open_zoom"):
		overlays.open_zoom(card_id)


# ============================================================
# HELPERS
# ============================================================
func _is_special_energy(card_id: String) -> bool:
	if card_id == "": return false
	# Por ID explícito
	if card_id in SPECIAL_ENERGY_IDS: return true
	# Por datos de la DB: energías con efecto propio (tienen "effect" en su data)
	var cdata = CardDatabase.get_card(card_id)
	if cdata.is_empty(): return false
	if cdata.get("type", "") != "ENERGY": return false
	# Si tiene texto de efecto, es especial
	var effect = cdata.get("effect", "")
	if effect != "" and effect != null: return true
	return false


func _update_counter_zone(zone: Control, count: int, label: String) -> void:
	if not zone: return
	if not zone.get_node_or_null("CardBackBg"):
		var bg_tex = _get_cached_tex("res://assets/imagen/back.jpg")
		if bg_tex:
			var bg = TextureRect.new()
			bg.name         = "CardBackBg"
			bg.texture      = bg_tex
			bg.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
			bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			bg.set_anchors_preset(Control.PRESET_FULL_RECT)
			bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
			bg.z_index      = 0
			zone.add_child(bg)

	if not zone.get_node_or_null("CounterOverlay"):
		var overlay = ColorRect.new()
		overlay.name         = "CounterOverlay"
		overlay.color        = Color(0, 0, 0, 0.52)
		overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
		overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		overlay.z_index      = 1
		zone.add_child(overlay)

	var num_lbl = zone.get_node_or_null("CountNum")
	if not num_lbl:
		num_lbl = Label.new()
		num_lbl.name     = "CountNum"
		num_lbl.position = Vector2(0, 8)
		num_lbl.size     = Vector2(zone.size.x, zone.size.y - 22)
		num_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		num_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		num_lbl.add_theme_font_size_override("font_size", 28)
		num_lbl.add_theme_color_override("font_color", COLOR_GOLD)
		num_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
		num_lbl.add_theme_constant_override("outline_size", 4)
		num_lbl.z_index = 2
		zone.add_child(num_lbl)
	num_lbl.text = str(count)

	var sub_lbl = zone.get_node_or_null("CountSub")
	if not sub_lbl:
		sub_lbl = Label.new()
		sub_lbl.name     = "CountSub"
		sub_lbl.position = Vector2(0, zone.size.y - 18)
		sub_lbl.size     = Vector2(zone.size.x, 16)
		sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sub_lbl.add_theme_font_size_override("font_size", 9)
		sub_lbl.add_theme_color_override("font_color", Color(0.90, 0.82, 0.50))
		sub_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
		sub_lbl.add_theme_constant_override("outline_size", 3)
		sub_lbl.z_index = 2
		zone.add_child(sub_lbl)
	sub_lbl.text = label

func _update_opponent_hand(opp_hand_zone: Control, count: int, revealed_hand: Array = []) -> void:
	if not opp_hand_zone: return
	var current_cache_str = str(count) + "_" + str(revealed_hand)
	if current_cache_str == _opp_hand_cache_str: return
	_opp_hand_cache_str = current_cache_str

	for child in opp_hand_zone.get_children():
		if not (child is ColorRect):
			child.free()

	if count == 0: return

	const CARD_BACK_W := 52
	const CARD_BACK_H := 73
	var margin:  float = 160.0
	var avail:   float = vp_width - margin * 2.0 - float(CARD_BACK_W)
	var step:    float = clamp(avail / float(max(count - 1, 1)), 14, float(CARD_BACK_W) + 4) if count > 1 else float(CARD_BACK_W)
	var total_w: float = float(CARD_BACK_W) + float(count - 1) * step
	var start_x: float = (vp_width - total_w) / 2.0
	var card_y:  float = (opp_hand_zone.size.y - float(CARD_BACK_H)) / 2.0

	for i in range(count):
		var node_to_add: Control
		if i < revealed_hand.size() and str(revealed_hand[i]) != "":
			var card_id = str(revealed_hand[i])
			node_to_add = CardDatabase.create_card_instance(card_id)
			node_to_add.set_meta("card_id", card_id)
			node_to_add.is_draggable = false
			node_to_add.scale = Vector2(float(CARD_BACK_W) / float(CARD_W), float(CARD_BACK_H) / float(CARD_H))
			if node_to_add.has_node("DropOverlay"):
				node_to_add.get_node("DropOverlay").mouse_filter = Control.MOUSE_FILTER_IGNORE
		else:
			node_to_add = _make_mini_card_back(opp_sleeve_id, CARD_BACK_W, CARD_BACK_H)

		node_to_add.position = Vector2(start_x + float(i) * step, card_y)
		node_to_add.z_index  = i
		opp_hand_zone.add_child(node_to_add)

func _make_mini_card_back(sleeve_id: String, w: int, h: int) -> Control:
	var container = Control.new()
	container.size = Vector2(w, h)
	var tex_path:   String    = PATH_SLEEVES + sleeve_id + ".png"
	var cached_tex: Texture2D = _get_cached_tex(tex_path)
	if not cached_tex:
		cached_tex = _get_cached_tex("res://assets/imagen/back.jpg")

	if cached_tex:
		var tex = TextureRect.new()
		tex.texture      = cached_tex
		tex.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		tex.size         = Vector2(w, h)
		container.add_child(tex)
	else:
		var panel = Panel.new()
		panel.size = Vector2(w, h)
		var style = StyleBoxFlat.new()
		style.bg_color          = Color(0.10, 0.12, 0.35)
		style.border_color      = Color(0.60, 0.50, 0.20)
		style.border_width_left = 2; style.border_width_right  = 2
		style.border_width_top  = 2; style.border_width_bottom = 2
		panel.add_theme_stylebox_override("panel", style)
		container.add_child(panel)
	return container

func _make_card_back(sleeve_id: String) -> Control:
	return _make_mini_card_back(sleeve_id, CARD_W, CARD_H)

func _update_stadium_zone(zone: Control, card_id: String) -> void:
	if not zone: return
	if card_id == null or card_id == "null": card_id = ""
	var zone_key:  String = zone.name + "_stadium"
	var cached_id: String = str(_zone_card_cache.get(zone_key, ""))
	if card_id == cached_id: return
	_zone_card_cache[zone_key] = card_id

	for child in zone.get_children():
		if child.name not in ["Background", "DropOverlay", "StadiumLabel"]:
			child.free()

	if card_id == "":
		_update_stadium_background("")
		var lbl = zone.get_node_or_null("StadiumLabel")
		if lbl: lbl.text = ""
		return

	var card_inst = CardDatabase.create_card_instance(card_id)
	card_inst.name         = "CardInstance"
	card_inst.is_draggable = false
	card_inst.z_index      = 0
	_fit_node_to_zone(card_inst, zone, 4)
	zone.add_child(card_inst)

	var lbl = zone.get_node_or_null("StadiumLabel")
	if not lbl:
		lbl = Label.new()
		lbl.name     = "StadiumLabel"
		lbl.position = Vector2(0, zone.size.y - 16)
		lbl.size     = Vector2(zone.size.x, 14)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 9)
		lbl.add_theme_color_override("font_color", Color(0.75, 0.65, 0.35))
		lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
		lbl.add_theme_constant_override("outline_size", 3)
		zone.add_child(lbl)
	lbl.text = CardDatabase.get_card(card_id).get("name", card_id)
	_update_stadium_background(card_id)

func _update_stadium_background(card_id: String) -> void:
	if not _parent: return
	const STADIUM_BG_MAP = {
		"sprout_tower": "res://assets/imagen/tablero/Stadium/S-Bellsprout.png",
		"ecogym":       "res://assets/imagen/tablero/Stadium/S-Bellsprout.png",
	}
	var old_bg = _parent.get_node_or_null("StadiumBg")
	if old_bg:
		var tw = old_bg.create_tween()
		tw.tween_property(old_bg, "modulate:a", 0.0, 0.30)
		tw.tween_callback(old_bg.queue_free)

	if card_id == "": return
	var bg_path: String = STADIUM_BG_MAP.get(card_id, "")
	if bg_path == "" or not ResourceLoader.exists(bg_path): return

	var bg = TextureRect.new()
	bg.name         = "StadiumBg"
	bg.texture      = load(bg_path)
	bg.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.z_index      = -1
	var vp_size     = _parent.get_viewport().get_visible_rect().size
	bg.position     = Vector2.ZERO
	bg.size         = vp_size
	bg.modulate     = Color(1, 1, 1, 0.0)
	_parent.add_child(bg)
	bg.create_tween().tween_property(bg, "modulate:a", 1.00, 0.40)

func _fit_node_to_zone(node: Node, zone: Control, padding: int) -> void:
	var target_w: float = zone.size.x - padding * 2
	var target_h: float = zone.size.y - padding * 2 - 22
	node.scale    = Vector2(target_w / float(CARD_W), target_h / float(CARD_H))
	node.position = Vector2(padding, 22)

func _get_type_icon(type_str: String) -> Texture2D:
	var t = type_str.to_upper()
	if "GRASS" in t: t = "GRASS"
	elif "FIRE" in t: t = "FIRE"
	elif "WATER" in t: t = "WATER"
	elif "LIGHTNING" in t or "ELECTRIC" in t: t = "LIGHTNING"
	elif "PSYCHIC" in t: t = "PSYCHIC"
	elif "FIGHTING" in t: t = "FIGHTING"
	elif "COLORLESS" in t: t = "COLORLESS"
	elif "DARKNESS" in t or "DARK" in t: t = "DARKNESS"
	elif "METAL" in t: t = "METAL"
	elif "DRAGON" in t: t = "DRAGON"

	const FILES = {
		"FIRE":      "fire.png",     "WATER":    "water.png",   "GRASS":    "grass.png",
		"LIGHTNING": "electric.png", "PSYCHIC":  "psy.png",     "FIGHTING": "figth.png",
		"COLORLESS": "incolor.png",  "DARKNESS": "dark.png",    "METAL":    "metal.png",
		"DRAGON":    "dragon.png",
	}
	var file: String = str(FILES.get(t, ""))
	if file == "": return null
	return _get_cached_tex(PATH_TYPES + file)
