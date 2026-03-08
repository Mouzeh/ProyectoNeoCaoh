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

# ─── ESTADO Y CACHÉ ─────────────────────────────────────────
var zones:         Dictionary = {}
var opp_sleeve_id: String     = "default"
var vp_width:      float      = 0.0
var _parent:       Node       = null
var _turn_banner:  Control    = null

var _zone_card_cache:      Dictionary = {}
var _tex_cache:            Dictionary = {}
var _opp_hand_count_cache: int        = -1
var _discard_btns_added:   bool       = false

# ─── CACHÉ DE TEXTURAS ──────────────────────────────────────
func _get_cached_tex(path: String) -> Texture2D:
	if _tex_cache.has(path): return _tex_cache[path]
	var tex: Texture2D = load(path) if ResourceLoader.exists(path) else null
	_tex_cache[path] = tex
	return tex

# ─── SETUP ──────────────────────────────────────────────────
func setup(board_zones: Dictionary, viewport_width: float) -> void:
	zones    = board_zones
	vp_width = viewport_width
	_parent  = get_parent()
	_setup_discard_buttons()

func set_opp_sleeve(sleeve_id: String) -> void:
	opp_sleeve_id = sleeve_id

# ============================================================
# HOVER ZOOM
# ============================================================
func get_hovered_card_id() -> String:
	for key in zones.keys():
		var item = zones[key]
		if typeof(item) == TYPE_ARRAY:
			for zone in item:
				if zone and zone.has_node("CardInstance"):
					if zone.get_node("CardInstance").get("is_hovered"):
						return str(_zone_card_cache.get(zone.name, "")).replace("_oculto", "")
		else:
			var zone = item
			if zone and zone.has_node("CardInstance"):
				if zone.get_node("CardInstance").get("is_hovered"):
					return str(_zone_card_cache.get(zone.name, "")).replace("_oculto", "")
	return ""

# ============================================================
# BOTONES DE DESCARTE (se agregan una sola vez)
# ============================================================
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


# ============================================================
# RENDER PRINCIPAL
# ============================================================
# FIX: Se usa _get_count() para deck y prizes, que acepta tanto
#      un Array (modo jugador) como un int/deck_count (modo espectador).
# ============================================================
func render_board(state: Dictionary) -> void:
	var my_data  = state.get("my",       {})
	var opp_data = state.get("opponent", {})

	_update_zone_pokemon(zones["my_active"],  my_data.get("active"),  true,  true)
	_update_zone_pokemon(zones["opp_active"], opp_data.get("active"), true,  false)

	var my_bench  = my_data.get("bench",  [])
	var opp_bench = opp_data.get("bench", [])
	for i in range(5):
		_update_zone_pokemon(zones["my_bench"][i],  my_bench[i]  if i < my_bench.size()  else null, false, true)
		_update_zone_pokemon(zones["opp_bench"][i], opp_bench[i] if i < opp_bench.size() else null, false, false)

	# FIX: usar _get_count para ambos jugadores — funciona con array O con int
	_update_counter_zone(zones["my_deck"],    _get_count(my_data,  "deck",   "deck_count"),   "Mazo")
	_update_counter_zone(zones["my_prizes"],  _get_count(my_data,  "prizes", "prizes_count"), "Premios")
	_update_counter_zone(zones["opp_deck"],   _get_count(opp_data, "deck",   "deck_count"),   "Mazo")
	_update_counter_zone(zones["opp_prizes"], _get_count(opp_data, "prizes", "prizes_count"), "Premios")

	_update_discard_zone(zones["my_discard"],  my_data.get("discard",  []))
	_update_discard_zone(zones["opp_discard"], opp_data.get("discard", []))

	# FIX: hand_count para ambos lados (espectador no tiene hand array de ninguno)
	var opp_hand_count = _get_count(opp_data, "hand", "hand_count")
	_update_opponent_hand(zones["opp_hand"], opp_hand_count)


## Helper: obtiene el conteo de un campo que puede ser Array o int.
## Primero intenta el array_key (.size()), luego el count_key (int directo).
func _get_count(data: Dictionary, array_key: String, count_key: String) -> int:
	var arr = data.get(array_key, null)
	if arr is Array and arr.size() > 0:
		return arr.size()
	var cnt = data.get(count_key, 0)
	if cnt is float: cnt = int(cnt)
	if cnt is int: return cnt
	# Fallback: si el array existe pero está vacío, y no hay count_key, devolver 0
	if arr is Array: return arr.size()
	return 0


# ============================================================
# ZONA DE DESCARTE
# ============================================================
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
	card_inst.is_draggable = false
	card_inst.z_index      = 5
	card_inst.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fit_node_to_zone(card_inst, zone, 4)
	zone.add_child(card_inst)


# ============================================================
# TURNO BANNER
# ============================================================
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
	lbl.add_theme_color_override("font_color",
		Color(0.10, 0.10, 0.10) if is_my_turn else Color(0.92, 0.88, 0.75))
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


# ============================================================
# ACTUALIZAR ZONA POKEMON
# ============================================================
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

	# Solo reconstruir si la carta cambió o se dio vuelta
	if cache_value != cached_id:
		for child in zone.get_children():
			if child.name not in ["Background", "DropOverlay", "SelectOverlay",
								  "ClickArea", "TrainerClickArea",
								  "DiscardBtn", "DiscardLabel", "DiscardCount"]:
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

			# TokenOverlay vacío inicial
			var ov = Control.new()
			ov.name         = "TokenOverlay"
			ov.size         = Vector2(CARD_W, CARD_H)
			ov.mouse_filter = Control.MOUSE_FILTER_IGNORE
			card_instance.add_child(ov)

	# Si no hay carta, nada más que hacer
	if new_card_id == "" or is_face_down or new_card_id == "face_down":
		return

	var card_instance = zone.get_node_or_null("CardInstance")
	if not card_instance: return

	# Limpiar y redibujar solo los tokens (sin tocar posición/scale)
	var overlay = card_instance.get_node_or_null("TokenOverlay")
	if overlay == null:
		overlay = Control.new()
		overlay.name         = "TokenOverlay"
		overlay.size         = Vector2(CARD_W, CARD_H)
		overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card_instance.add_child(overlay)
	else:
		for child in overlay.get_children():
			child.free()

	# HP Badge
	if is_active:
		var card_data: Dictionary = CardDatabase.get_card(new_card_id)
		var max_hp: int = int(card_data.get("hp", 0))
		var dmg: int    = int(pokemon_data.get("damage_counters", 0))
		var cur_hp: int = max(0, max_hp - dmg * 10)
		if max_hp > 0:
			_add_hp_badge(overlay, cur_hp, max_hp)

	# Estados
	var status: String = str(pokemon_data.get("status", ""))
	if status != "" and status != "null":
		_add_status_token(overlay, status)
	if pokemon_data.get("is_poisoned", false):
		_add_status_token(overlay, "POISONED")
	if pokemon_data.get("is_burned", false):
		_add_status_token(overlay, "BURNED")

	# Daño
	var dmg_counters: int = int(pokemon_data.get("damage_counters", 0))
	if dmg_counters > 0:
		_add_damage_tokens(overlay, dmg_counters)

	# Energías
	var energies: Array = pokemon_data.get("attached_energy", [])
	if energies.size() > 0:
		_add_energy_indicators(overlay, energies)


# ─── HP BADGE ────────────────────────────────────────────────
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
# TOKENS DE ESTADO
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
		const EMOJIS = {
			"POISONED": "☠", "BURNED": "🔥",
			"ASLEEP": "💤", "PARALYZED": "⚡", "CONFUSED": "💫"
		}
		var badge = Label.new()
		badge.name     = "StatusToken_" + status
		badge.text     = EMOJIS.get(status, "?")
		badge.position = Vector2(CARD_W - 22 - existing * 20, 26)
		badge.add_theme_font_size_override("font_size", 14)
		overlay.add_child(badge)


# ============================================================
# TOKENS DE DAÑO
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
# ENERGÍAS
# ============================================================
func _add_energy_indicators(overlay: Control, energies: Array) -> void:
	var start_y: float = CARD_H - 20.0
	for i in range(min(energies.size(), 6)):
		var e_type:  String    = str(CardDatabase.get_energy_type(energies[i]))
		var icon_tx: Texture2D = _get_type_icon(e_type)
		if icon_tx:
			var icon = TextureRect.new()
			icon.texture      = icon_tx
			icon.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.size         = Vector2(16, 16)
			icon.position     = Vector2(4 + i * 16, start_y)
			overlay.add_child(icon)
		else:
			var dot = ColorRect.new()
			dot.size     = Vector2(10, 10)
			dot.position = Vector2(4 + i * 12, start_y + 3)
			dot.color    = Color(0.5, 0.5, 0.5)
			overlay.add_child(dot)


# ============================================================
# CONTADORES DE ZONA
# ============================================================
func _update_counter_zone(zone: Control, count: int, label: String) -> void:
	if not zone: return

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
		sub_lbl.add_theme_color_override("font_color", Color(0.70, 0.65, 0.40))
		zone.add_child(sub_lbl)
	sub_lbl.text = label


# ============================================================
# MANO DEL OPONENTE
# ============================================================
func _update_opponent_hand(opp_hand_zone: Control, count: int) -> void:
	if not opp_hand_zone: return
	if count == _opp_hand_count_cache: return
	_opp_hand_count_cache = count

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
		var back = _make_mini_card_back(opp_sleeve_id, CARD_BACK_W, CARD_BACK_H)
		back.position = Vector2(start_x + float(i) * step, card_y)
		back.z_index  = i
		opp_hand_zone.add_child(back)

func _make_mini_card_back(sleeve_id: String, w: int, h: int) -> Control:
	var container = Control.new()
	container.size = Vector2(w, h)

	var tex_path:   String    = PATH_SLEEVES + sleeve_id + ".png"
	var cached_tex: Texture2D = _get_cached_tex(tex_path)

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


# ============================================================
# HELPERS
# ============================================================
func _fit_node_to_zone(node: Node, zone: Control, padding: int) -> void:
	var target_w: float = zone.size.x - padding * 2
	var target_h: float = zone.size.y - padding * 2 - 22
	node.scale    = Vector2(target_w / float(CARD_W), target_h / float(CARD_H))
	node.position = Vector2(padding, 22)

func _get_type_icon(type_str: String) -> Texture2D:
	const FILES = {
		"FIRE": "fire.png",          "WATER": "water.png",      "GRASS": "grass.png",
		"LIGHTNING": "electric.png", "PSYCHIC": "psy.png",      "FIGHTING": "figth.png",
		"COLORLESS": "incolor.png",  "DARKNESS": "dark.png",    "METAL": "metal.png",
		"DRAGON": "dragon.png",
	}
	var file: String = str(FILES.get(type_str.to_upper(), ""))
	if file == "": return null
	return _get_cached_tex(PATH_TYPES + file)
