extends Node
class_name BoardBuilder

# ─── CONSTANTES DE TAMAÑO (Pensadas para 1920x1080) ─────────
const ACTIVE_W  = 130
const ACTIVE_H  = 182

const BENCH_W   = 128
const BENCH_H   = 176
const BENCH_GAP = 15

const SIDE_W    = 100
const SIDE_H    = 140
const SIDE_GAP  = 15

const DECK_W    = 128
const DECK_H    = 176
const DECK_GAP  = 40

const HAND_H    = 180

# ============================================================
# 🚨 MODO DE PRUEBA 🚨
const MODO_PRUEBA = true

static func build_all(parent: Node2D, vp_size: Vector2) -> Dictionary:
	var W = vp_size.x
	var H = vp_size.y

	var zones = { "my_bench": [], "opp_bench": [] }

	# ── Centro exacto de la pantalla ──
	var center_x = W / 2.0
	var center_y = H / 2.0

	# ── 1. ACTIVOS ───────────────────────────────────────────
	var active_x = center_x - ACTIVE_W / 2.0
	var my_active_y  = center_y + -10
	var opp_active_y = center_y - ACTIVE_H - 40 

	zones["my_active"] = _make_zone(Vector2(active_x, my_active_y), Vector2(ACTIVE_W, ACTIVE_H), parent)
	zones["opp_active"] = _make_zone(Vector2(active_x, opp_active_y), Vector2(ACTIVE_W, ACTIVE_H), parent)

	# ── 2. BANCAS ────────────────────────────────────────────
	var bench_total_w = 5 * BENCH_W + 4 * BENCH_GAP
	var bench_start_x = (center_x - bench_total_w / 2.0) + 14

	var opp_bench_y = 120
	var my_bench_y  = H - 345

	for i in range(5):
		var pos_m = Vector2(bench_start_x + i * (BENCH_W + BENCH_GAP), my_bench_y)
		zones["my_bench"].append(_make_zone(pos_m, Vector2(BENCH_W, BENCH_H), parent))

		var pos_o = Vector2(bench_start_x + i * (BENCH_W + BENCH_GAP), opp_bench_y)
		zones["opp_bench"].append(_make_zone(pos_o, Vector2(BENCH_W, BENCH_H), parent))

	# ── 3. LATERALES (MAZOS Y DESCARTES AGRANDADOS) ──────────
	var left_x  = 80.0
	var right_x = W - SIDE_W - 80.0

	# Mazo y Descarte Rival (Pegados arriba a la Izquierda)
	var opp_cartas_x  = left_x + 2 # 20px MÁS A LA IZQ (antes +30)
	var opp_deck_y    = opp_bench_y - 35 # 20px MÁS ARRIBA (antes -20)
	var opp_discard_y = opp_deck_y + DECK_H + DECK_GAP + 25 
	zones["opp_deck"]    = _make_zone(Vector2(opp_cartas_x, opp_deck_y), Vector2(DECK_W, DECK_H), parent)
	zones["opp_discard"] = _make_zone(Vector2(opp_cartas_x, opp_discard_y), Vector2(DECK_W, DECK_H), parent)

	# Mazo y Descarte Propios (Pegados abajo a la Derecha)
	var mis_cartas_x = right_x - 30 # 20px MÁS A LA IZQ (antes +5)
	var my_discard_y = my_bench_y + 80 # 10px MÁS ABAJO (antes +45)
	var my_deck_y    = my_discard_y - DECK_H - DECK_GAP - 20
	zones["my_deck"]    = _make_zone(Vector2(mis_cartas_x, my_deck_y), Vector2(DECK_W, DECK_H), parent)
	zones["my_discard"] = _make_zone(Vector2(mis_cartas_x, my_discard_y), Vector2(DECK_W, DECK_H), parent)

	# ── 4. PREMIOS (DEL MISMO PORTE QUE EL DECK Y MÁS ABAJO) ─
	# Premios Rival (A la derecha, flotando hacia el centro)
	var opp_prizes_x = right_x - SIDE_W - 175 # 10px MÁS A LA DERECHA (antes -185)
	var opp_prizes_y = opp_discard_y - 50     # 40px MÁS ARRIBA (antes +15)
	zones["opp_prizes"] = _make_zone(Vector2(opp_prizes_x, opp_prizes_y), Vector2(DECK_W, DECK_H), parent)

	# Mis Premios (A la izquierda, flotando hacia el centro)
	var my_prizes_x = left_x + SIDE_W + 150   # 10px MÁS A LA IZQ (antes +160)
	var my_prizes_y = my_deck_y + 43          # 20px MÁS ABAJO (antes +15)
	zones["my_prizes"] = _make_zone(Vector2(my_prizes_x, my_prizes_y), Vector2(DECK_W, DECK_H), parent)

# ── 5. STADIUM ───────────────────────────────────────────
	# Le damos el tamaño de una carta normal
	var stadium_w = DECK_W
	var stadium_h = DECK_H
	
	# Lo posicionamos a la izquierda de la Pokéball y del Pokémon Activo
	var stadium_x = center_x - (ACTIVE_W / 2.0) - stadium_w - 60 
	
	# Lo centramos verticalmente justo en la línea media de la Pokéball
	var stadium_y = center_y - (stadium_h / 2.0)
	
	zones["stadium"] = _make_zone(Vector2(stadium_x, stadium_y), Vector2(stadium_w, stadium_h), parent)
	
	# ── 6. MANO DEL JUGADOR ──────────────────────────────────
	var my_hand = Control.new()
	my_hand.name = "MyHand"
	my_hand.position = Vector2(0, H - HAND_H - 10)
	my_hand.size = Vector2(W, HAND_H)
	var hand_bg = ColorRect.new()
	hand_bg.color = Color(0, 0, 0, 0.4 if MODO_PRUEBA else 0.0)
	hand_bg.size = Vector2(W, HAND_H)
	my_hand.add_child(hand_bg)
	parent.add_child(my_hand)
	zones["my_hand"] = my_hand

	var opp_hand = Control.new()
	opp_hand.name = "OppHand"
	opp_hand.position = Vector2(0, 0)
	opp_hand.size = Vector2(W, HAND_H * 0.55)
	var opp_hand_bg = ColorRect.new()
	opp_hand_bg.color = Color(0, 0, 0, 0.4 if MODO_PRUEBA else 0.0)
	opp_hand_bg.size = Vector2(W, HAND_H * 0.55)
	opp_hand.add_child(opp_hand_bg)
	parent.add_child(opp_hand)
	zones["opp_hand"] = opp_hand

	return zones

# ─── HELPER PARA CREAR ZONAS ────────────────────────────────
static func _make_zone(pos: Vector2, sz: Vector2, parent: Node) -> Control:
	var zone = Control.new()
	zone.position = pos
	zone.size     = sz

	var bg = Panel.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	var style = StyleBoxFlat.new()
	
	if MODO_PRUEBA:
		style.bg_color = Color(0.6, 0.1, 0.9, 0.5)
		style.border_color = Color(1.0, 1.0, 1.0, 0.8)
		style.border_width_left = 2; style.border_width_right = 2
		style.border_width_top = 2; style.border_width_bottom = 2
	else:
		style.bg_color = Color(0, 0, 0, 0)
		style.border_width_left = 0; style.border_width_right = 0
		style.border_width_top = 0; style.border_width_bottom = 0

	bg.add_theme_stylebox_override("panel", style)
	zone.add_child(bg)
	parent.add_child(zone)
	return zone
