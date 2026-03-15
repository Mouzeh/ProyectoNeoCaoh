extends Node
class_name CoinBannerManager


# ============================================================
# CoinBannerManager.gd
# Maneja las texturas de monedas, detección de lanzamientos
# en el log, y el banner visual animado de resultado.
# ============================================================

# ─── CONSTANTES ─────────────────────────────────────────────
const COLOR_GOLD = Color(0.85, 0.72, 0.30)
const COLOR_TEXT = Color(0.92, 0.88, 0.75)

const COIN_BASE_PATH_FRONT = "res://assets/imagen/tokens/TCG Flip Coins/CoinFont/"
const COIN_BASE_PATH_BACK  = "res://assets/imagen/tokens/TCG Flip Coins/CoinBack/"

const COIN_FILES = {
	"default":             {"front": "ESPEON-LARGE-PURPLE-RAINBOW.png",      "back": "LARGE-YELLOW-A.png"},
	"chikorita":           {"front": "CHIKORITA-SMALL-GREEN-NON.png",        "back": "LARGE-YELLOW-A.png"},
	"cyndaquil":           {"front": "CYNDAQUIL-SMALL-GOLD-NON.png",         "back": "LARGE-YELLOW-A.png"},
	"totodile":            {"front": "TOTODILE-SMALL-BLUE-NON.png",          "back": "LARGE-YELLOW-A.png"},
	"pikachu_gold":        {"front": "PIKACHU-SMALL-GOLD-NON.png",           "back": "LARGE-YELLOW-A.png"},
	"pikachu_mirror":      {"front": "PIKACHU-SMALL-SILVER-MIRROR.png",      "back": "LARGE-YELLOW-A.png"},
	"lugia_mirror":        {"front": "LUGIA-LARGE-SILVER-MIRROR.png",        "back": "LARGE-YELLOW-A.png"},
	"ho_oh":               {"front": "HO-OH-LARGE-GOLD-MIRROR.png",          "back": "LARGE-YELLOW-A.png"},
	"rayquaza_green":      {"front": "RAYQUAZA-SMALL-GREEN-MIRROR.png",      "back": "LARGE-YELLOW-A.png"},
	"charizard_large":     {"front": "CHARIZARD-LARGE-ORANGE-MIRROR.png",    "back": "LARGE-YELLOW-A.png"},
	"mewtwo_x":            {"front": "M MEWTWO X-LARGE-BLUE-RAINBOW.png",    "back": "LARGE-YELLOW-A.png"},
	"lugia_cracked":       {"front": "LUGIA-LARGE-SILVER-CRACKED ICE.png",   "back": "LARGE-YELLOW-A.png"},
	"pikachu_waving_gold": {"front": "PIKACHU_waving-LARGE-GOLD-MIRROR.png", "back": "LARGE-YELLOW-A.png"},
	"mew_glitter":         {"front": "MEW-SMALL-SILVER-GLITTER.png",         "back": "LARGE-YELLOW-A.png"},
	"arceus_gold":         {"front": "ARCEUS-SMALL-GOLD-MIRROR.png",         "back": "LARGE-YELLOW-A.png"},
}

# ─── ESTADO ─────────────────────────────────────────────────
var my_coin_heads: String = COIN_BASE_PATH_FRONT + "ENERGY-SMALL-SILVER-NON.png"
var my_coin_tails: String = COIN_BASE_PATH_BACK  + "SMALL-SILVER-A.png"
var opp_coin_heads: String = COIN_BASE_PATH_FRONT + "ENERGY-SMALL-SILVER-NON.png"
var opp_coin_tails: String = COIN_BASE_PATH_BACK  + "SMALL-SILVER-A.png"
var _last_flip_was_opponent: bool = false

# ─── REFERENCIAS EXTERNAS ───────────────────────────────────
var _parent: Node2D       = null
var _my_display_name: String  = "Tú"
var _opp_display_name: String = "Rival"
var _my_turn: bool = false


# ============================================================
# SETUP
# ============================================================
func setup(parent: Node2D) -> void:
	_parent = parent


func set_context(my_name: String, opp_name: String, my_turn: bool) -> void:
	_my_display_name  = my_name
	_opp_display_name = opp_name
	_my_turn          = my_turn


# ============================================================
# CARGAR TEXTURAS
# ============================================================
func load_my_coin(coin_id: String) -> void:
	var files = COIN_FILES.get(coin_id, COIN_FILES["default"])
	my_coin_heads = COIN_BASE_PATH_FRONT + files["front"]
	my_coin_tails = COIN_BASE_PATH_BACK  + files["back"]


func load_opp_coin(coin_id: String) -> void:
	var files = COIN_FILES.get(coin_id, COIN_FILES["default"])
	opp_coin_heads = COIN_BASE_PATH_FRONT + files["front"]
	opp_coin_tails = COIN_BASE_PATH_BACK  + files["back"]


# ============================================================
# DETECCIÓN DE LOG
# ============================================================
func check_coin_log(msg: String) -> void:
	var lower = msg.to_lower()

	var is_coin = "heads" in lower or "tails" in lower \
		or "flip:" in lower or "– heads" in lower or "– tails" in lower \
		or "moneda:" in lower or "coin:" in lower \
		or "¡cara!" in lower or "cara!" in lower or "¡sello!" in lower \
		or "sleep check:" in lower

	if not is_coin: return

	var is_heads = "heads" in lower or "¡cara!" in lower or "cara!" in lower \
		or ("sleep check:" in lower and ("despertó" in lower or "woke" in lower))
	var is_tails = "tails" in lower or "¡sello!" in lower or "sello!" in lower \
		or ("sleep check:" in lower and ("sigue dormido" in lower or "still asleep" in lower or "no despertó" in lower))

	var is_first     = "moneda:" in lower and ("primero" in lower or "first" in lower)
	var is_baby      = "baby rule" in lower or "baby" in lower
	var is_trainer   = "plays " in lower and ("–" in lower or "--" in lower)
	var is_wake      = "despert" in lower or "wake" in lower \
		or "dormid" in lower or "asleep" in lower or "sleep" in lower
	var is_burn      = "quemad" in lower or "burn" in lower
	var is_confuse   = "confus" in lower
	var is_secondary = "secundari" in lower or "secondary" in lower \
		or "no effect" in lower or "sin efecto" in lower
	var is_power     = "pokemon power" in lower or "pokémon power" in lower \
		or "poké power" in lower or "poke power" in lower \
		or "long distance" in lower or "enviado" in lower

	var trainer_name = ""
	if is_trainer:
		var plays_idx = lower.find("plays ")
		var dash_idx  = msg.find("–")
		if plays_idx != -1 and dash_idx != -1 and dash_idx > plays_idx + 6:
			trainer_name = msg.substr(plays_idx + 6, dash_idx - plays_idx - 7).strip_edges()

	var power_name = ""
	if is_power:
		var colon_idx = msg.find(":")
		if colon_idx != -1:
			var raw = msg.substr(0, colon_idx).strip_edges()
			for prefix in ["⚡ ", "😴 ", "🔥 ", "💫 ", "☠ "]:
				if raw.begins_with(prefix):
					raw = raw.substr(prefix.length()).strip_edges()
			power_name = raw

	var reason: String
	if is_first:
		reason = "🎲  ¿Quién va primero?"
	elif is_baby:
		var baby_name = ""
		var par_open  = msg.find("(")
		var par_close = msg.find(")")
		if par_open != -1 and par_close != -1:
			baby_name = msg.substr(par_open + 1, par_close - par_open - 1)
		reason = "👶  Regla Baby — %s" % baby_name if baby_name != "" else "👶  Regla Baby"
	elif is_power and power_name != "":
		reason = "⚡  %s" % power_name
	elif is_trainer and trainer_name != "":
		reason = "🃏  %s" % trainer_name
	elif is_wake:
		reason = "💤  Intento de despertar"
	elif is_burn:
		reason = "🔥  Verificación de quemadura"
	elif is_confuse:
		reason = "💫  Verificación de confusión"
	elif is_secondary:
		reason = "⚔  Efecto secundario de ataque"
	else:
		reason = "🪙  Lanzamiento de moneda"

	var effect: String = ""

	if is_power:
		for result_word in ["¡Cara! ", "¡Sello! ", "Heads — ", "Tails — ",
							"Heads: ", "Tails: ", "Cara — ", "Sello — ",
							"Cara: ", "Sello: "]:
			var ridx = msg.find(result_word)
			if ridx != -1:
				effect = msg.substr(ridx + result_word.length()).strip_edges()
				break

	if effect == "":
		for dash in ["— ", "– ", "-- "]:
			var dash_pos = msg.rfind(dash)
			if dash_pos != -1:
				var candidate = msg.substr(dash_pos + dash.length()).strip_edges()
				if candidate.to_lower() not in ["heads", "tails", "cara", "sello"]:
					effect = candidate
				break

	if effect == "":
		if is_heads:
			if is_first:       effect = ""
			elif is_baby:      effect = "¡El ataque conecta!"
			elif is_wake:      effect = "¡Pokémon despertó!"
			elif is_burn:      effect = "¡Sigue quemado!"
			elif is_confuse:   effect = "¡Se golpeó a sí mismo!"
			elif is_secondary: effect = "¡Efecto activado!"
			else:              effect = "¡Éxito!"
		elif is_tails:
			if is_first:       effect = ""
			elif is_baby:      effect = "¡El ataque falla!"
			elif is_wake:      effect = "Sigue dormido..."
			elif is_burn:      effect = "Quemadura curada"
			elif is_confuse:   effect = "Sin efecto"
			elif is_secondary: effect = "Sin efecto secundario"
			else:              effect = "Fallo..."

	if is_first:
		var parts = msg.split(":")
		if parts.size() > 1:
			effect = parts[1].strip_edges()

	if is_first:
		_last_flip_was_opponent = false
	elif _opp_display_name != "" and _opp_display_name in msg:
		_last_flip_was_opponent = true
	elif _my_display_name != "" and _my_display_name in msg:
		_last_flip_was_opponent = false
	else:
		_last_flip_was_opponent = not _my_turn

	var result = "¡CARA!" if is_heads else ("SELLO" if is_tails else "?")
	show_coin_banner(result, reason, effect)


# ============================================================
# BANNER VISUAL
# ============================================================
func show_coin_banner(result_text: String, reason_text: String = "", effect_text: String = "") -> void:
	if not _parent: return
	var vp = _parent.get_viewport().get_visible_rect().size
	var W  = vp.x
	var H  = vp.y

	var old = _parent.get_node_or_null("CoinBanner")
	if old: old.queue_free()

	var container = Control.new()
	container.name     = "CoinBanner"
	container.z_index  = 500
	container.size     = Vector2(W, H)
	container.position = Vector2.ZERO
	_parent.add_child(container)

	var bg = ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.0)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(bg)

	const CIRCLE_R = 130.0
	const CIRCLE_D = CIRCLE_R * 2.0
	var cx = W / 2.0
	var cy = H / 2.0

	var glow = Panel.new()
	glow.size     = Vector2(CIRCLE_D + 28, CIRCLE_D + 28)
	glow.position = Vector2(cx - (CIRCLE_D + 28) / 2.0, cy - (CIRCLE_D + 28) / 2.0 - 20)
	var glow_s = StyleBoxFlat.new()
	glow_s.bg_color     = Color(COLOR_GOLD.r, COLOR_GOLD.g, COLOR_GOLD.b, 0.18)
	glow_s.border_color = Color(COLOR_GOLD.r, COLOR_GOLD.g, COLOR_GOLD.b, 0.0)
	glow_s.set_corner_radius_all(int((CIRCLE_D + 28) / 2.0))
	glow_s.anti_aliasing = true
	glow.add_theme_stylebox_override("panel", glow_s)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(glow)

	var circle = Panel.new()
	circle.name     = "CoinCircle"
	circle.size     = Vector2(CIRCLE_D, CIRCLE_D)
	circle.position = Vector2(cx - CIRCLE_R, cy - CIRCLE_R - 20)
	var c_s = StyleBoxFlat.new()
	c_s.bg_color     = Color(0.06, 0.08, 0.04, 0.97)
	c_s.border_color = COLOR_GOLD
	c_s.set_border_width_all(3)
	c_s.set_corner_radius_all(int(CIRCLE_R))
	c_s.anti_aliasing = true
	c_s.shadow_color  = Color(COLOR_GOLD.r, COLOR_GOLD.g, COLOR_GOLD.b, 0.55)
	c_s.shadow_size   = 18
	c_s.shadow_offset = Vector2(0, 4)
	circle.add_theme_stylebox_override("panel", c_s)
	circle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(circle)

	var heads    = opp_coin_heads if _last_flip_was_opponent else my_coin_heads
	var tails    = opp_coin_tails if _last_flip_was_opponent else my_coin_tails
	var img_path = heads if result_text == "¡CARA!" else tails

	var coin_img = TextureRect.new()
	coin_img.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	coin_img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	coin_img.size         = Vector2(CIRCLE_D - 24, CIRCLE_D - 24)
	coin_img.position     = Vector2(12, 12)
	coin_img.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if ResourceLoader.exists(img_path):
		coin_img.texture = load(img_path)
		circle.add_child(coin_img)
	else:
		var fallback = Label.new()
		fallback.text = "🪙"
		fallback.set_anchors_preset(Control.PRESET_FULL_RECT)
		fallback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		fallback.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		fallback.add_theme_font_size_override("font_size", 80)
		fallback.mouse_filter = Control.MOUSE_FILTER_IGNORE
		circle.add_child(fallback)

	var result_lbl = Label.new()
	result_lbl.text = result_text
	result_lbl.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	result_lbl.offset_top    = -38
	result_lbl.offset_bottom = 0
	result_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	result_lbl.add_theme_font_size_override("font_size", 22)
	result_lbl.add_theme_color_override("font_color",         COLOR_GOLD)
	result_lbl.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 1.0))
	result_lbl.add_theme_constant_override("outline_size", 5)
	result_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	circle.add_child(result_lbl)

	if reason_text != "":
		var reason_lbl = Label.new()
		reason_lbl.text     = reason_text
		reason_lbl.size     = Vector2(420, 32)
		reason_lbl.position = Vector2(cx - 210, cy + CIRCLE_R - 10)
		reason_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		reason_lbl.add_theme_font_size_override("font_size", 16)
		reason_lbl.add_theme_color_override("font_color",         Color(0.85, 0.82, 0.70))
		reason_lbl.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 1.0))
		reason_lbl.add_theme_constant_override("outline_size", 4)
		reason_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		container.add_child(reason_lbl)

	if effect_text != "":
		var effect_lbl = Label.new()
		effect_lbl.text          = effect_text
		effect_lbl.size          = Vector2(500, 32)
		effect_lbl.position      = Vector2(cx - 250, cy + CIRCLE_R + 28)
		effect_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		effect_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		effect_lbl.add_theme_font_size_override("font_size", 20)
		effect_lbl.add_theme_color_override("font_color",         Color(1.0, 0.85, 0.30))
		effect_lbl.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 1.0))
		effect_lbl.add_theme_constant_override("outline_size", 5)
		effect_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		container.add_child(effect_lbl)

	circle.scale        = Vector2(0.3, 0.3)
	circle.pivot_offset = Vector2(CIRCLE_R, CIRCLE_R)
	glow.scale          = Vector2(0.3, 0.3)
	glow.pivot_offset   = Vector2((CIRCLE_D + 28) / 2.0, (CIRCLE_D + 28) / 2.0)
	container.modulate.a = 0.0

	var tw = _parent.create_tween()
	tw.set_parallel(true)
	tw.tween_property(bg,        "color",      Color(0.0, 0.0, 0.0, 0.60), 0.25)
	tw.tween_property(container, "modulate:a", 1.0,                         0.20)
	tw.tween_property(circle,    "scale",      Vector2(1.0, 1.0),           0.35) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(glow,      "scale",      Vector2(1.0, 1.0),           0.40) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	await _parent.get_tree().create_timer(3.2).timeout

	if not is_instance_valid(container): return
	var tw2 = _parent.create_tween()
	tw2.set_parallel(true)
	tw2.tween_property(container, "modulate:a", 0.0,                0.40)
	tw2.tween_property(circle,    "scale",      Vector2(0.85, 0.85), 0.40).set_trans(Tween.TRANS_SINE)
	await _parent.get_tree().create_timer(0.42).timeout
	if is_instance_valid(container):
		container.queue_free()
