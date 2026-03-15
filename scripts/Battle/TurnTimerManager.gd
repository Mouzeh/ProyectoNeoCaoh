extends Node
class_name TurnTimerManager

# ============================================================
# TurnTimerManager.gd
# Maneja los timers visuales de turno (propio y del rival).
# BattleBoard lo instancia, conecta sus señales, y llama:
#   - start_my_timer()
#   - stop_my_timer()
#   - show_opp_timer(time_left)
#   - hide_opp_timer()
# ============================================================

signal time_expired   # el jugador se quedó sin tiempo
signal tick(seconds_left: float, is_mine: bool)

# ─── CONSTANTES ─────────────────────────────────────────────
const TURN_SECONDS       := 120
const TIMER_WARN_SECONDS := 20

const COLOR_GOLD     = Color(0.85, 0.72, 0.30)
const COLOR_GOLD_DIM = Color(0.55, 0.45, 0.18)
const COLOR_TEXT     = Color(0.92, 0.88, 0.75)

# ─── ESTADO ─────────────────────────────────────────────────
var _turn_time_left:  float = 0.0
var _opp_turn_time_left: float = 0.0

# ─── TIMERS ─────────────────────────────────────────────────
var _turn_timer:     Timer = null
var _opp_turn_timer: Timer = null

# ─── NODOS VISUALES — PROPIO ────────────────────────────────
var _timer_bar:   Control   = null
var _timer_fill:  ColorRect = null
var _timer_label: Label     = null
var _timer_tween: Tween     = null

# ─── NODOS VISUALES — RIVAL ─────────────────────────────────
var _opp_timer_bar:   Control   = null
var _opp_timer_fill:  ColorRect = null
var _opp_timer_label: Label     = null


# ============================================================
# SETUP — llamar desde BattleBoard._build_board()
# ============================================================
func setup(parent: Node2D, viewport_size: Vector2) -> void:
	var W := viewport_size.x
	_build_my_timer_bar(parent, W)
	_build_opp_timer_bar(parent, W)
	_create_timers(parent)


# ============================================================
# API PÚBLICA
# ============================================================
func start_my_timer() -> void:
	if _opp_turn_timer:
		_opp_turn_timer.stop()
	if _opp_timer_bar:
		_opp_timer_bar.visible = false

	_turn_time_left    = float(TURN_SECONDS)
	_timer_bar.visible = true
	_update_my_visuals()
	_turn_timer.start()


func stop_my_timer() -> void:
	if not _turn_timer: return
	_turn_timer.stop()
	if _timer_tween and _timer_tween.is_valid():
		_timer_tween.kill()
	if _timer_bar:
		_timer_bar.visible  = false
		_timer_bar.modulate = Color.WHITE


func show_opp_timer(time_left: float) -> void:
	if not _opp_timer_bar: return
	_opp_turn_time_left    = time_left
	_opp_timer_bar.visible = true
	_update_opp_visuals()
	if not _opp_turn_timer:
		return
	_opp_turn_timer.start()


func hide_opp_timer() -> void:
	if _opp_turn_timer:
		_opp_turn_timer.stop()
	if _opp_timer_bar:
		_opp_timer_bar.visible = false


# ============================================================
# TICKS INTERNOS
# ============================================================
func _on_my_tick() -> void:
	_turn_time_left -= 1.0
	_update_my_visuals()
	emit_signal("tick", _turn_time_left, true)
	if _turn_time_left <= 0.0:
		_turn_timer.stop()
		emit_signal("time_expired")


func _on_opp_tick() -> void:
	_opp_turn_time_left -= 1.0
	_update_opp_visuals()
	emit_signal("tick", _opp_turn_time_left, false)
	if _opp_turn_time_left <= 0.0:
		_opp_turn_timer.stop()


# ============================================================
# VISUALES — PROPIO
# ============================================================
func _update_my_visuals() -> void:
	if not _timer_fill or not _timer_label: return

	var fraction := clampf(_turn_time_left / float(TURN_SECONDS), 0.0, 1.0)
	_timer_fill.size.x = maxf((_timer_bar.size.x - 4.0) * fraction, 0.0)

	if _turn_time_left > TIMER_WARN_SECONDS:
		_timer_fill.color = Color(0.20, 0.65, 0.30, 0.80)
	elif _turn_time_left > 10:
		_timer_fill.color = Color(0.80, 0.65, 0.10, 0.85)
	else:
		_timer_fill.color = Color(0.85, 0.18, 0.18, 0.90)

	if _turn_time_left <= 10.0 and _turn_time_left > 0.0:
		if not (_timer_tween and _timer_tween.is_valid()):
			_timer_tween = _timer_bar.create_tween().set_loops()
			_timer_tween.tween_property(_timer_bar, "modulate:a", 0.45, 0.35)
			_timer_tween.tween_property(_timer_bar, "modulate:a", 1.0,  0.35)
	else:
		if _timer_tween and _timer_tween.is_valid():
			_timer_tween.kill()
		if _timer_bar: _timer_bar.modulate.a = 1.0

	var secs := int(_turn_time_left)
	_timer_label.text = "%d:%02d" % [secs / 60, secs % 60]


# ============================================================
# VISUALES — RIVAL
# ============================================================
func _update_opp_visuals() -> void:
	if not _opp_timer_fill or not _opp_timer_label: return
	var fraction = clampf(_opp_turn_time_left / float(TURN_SECONDS), 0.0, 1.0)
	_opp_timer_fill.size.x = maxf((_opp_timer_bar.size.x - 4.0) * fraction, 0.0)
	var secs = int(_opp_turn_time_left)
	_opp_timer_label.text = "⏱ Rival: %d:%02d" % [secs / 60, secs % 60]


# ============================================================
# CONSTRUCCIÓN DE NODOS
# ============================================================
func _create_timers(parent: Node) -> void:
	_turn_timer = Timer.new()
	_turn_timer.wait_time = 1.0
	_turn_timer.autostart = false
	_turn_timer.timeout.connect(_on_my_tick)
	parent.add_child(_turn_timer)

	_opp_turn_timer = Timer.new()
	_opp_turn_timer.wait_time = 1.0
	_opp_turn_timer.autostart = false
	_opp_turn_timer.timeout.connect(_on_opp_tick)
	parent.add_child(_opp_turn_timer)


func _build_my_timer_bar(parent: Node, W: float) -> void:
	const BAR_W := 260.0
	const BAR_H := 26.0
	var bar_x := W - BAR_W - 14.0
	var bar_y := 14.0 + 42.0 + 6.0

	_timer_bar          = Control.new()
	_timer_bar.name     = "TurnTimerBar"
	_timer_bar.position = Vector2(bar_x, bar_y)
	_timer_bar.size     = Vector2(BAR_W, BAR_H)
	_timer_bar.z_index  = 10
	_timer_bar.visible  = false
	parent.add_child(_timer_bar)

	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.06, 0.06, 0.10, 0.88)
	_timer_bar.add_child(bg)

	var border = Panel.new()
	border.set_anchors_preset(Control.PRESET_FULL_RECT)
	var bs = StyleBoxFlat.new()
	bs.bg_color = Color(0, 0, 0, 0)
	bs.border_color = COLOR_GOLD_DIM
	bs.border_width_left = 1; bs.border_width_right  = 1
	bs.border_width_top  = 1; bs.border_width_bottom = 1
	bs.corner_radius_top_left    = 5; bs.corner_radius_top_right    = 5
	bs.corner_radius_bottom_left = 5; bs.corner_radius_bottom_right = 5
	border.add_theme_stylebox_override("panel", bs)
	_timer_bar.add_child(border)

	_timer_fill          = ColorRect.new()
	_timer_fill.name     = "TimerFill"
	_timer_fill.position = Vector2(2, 2)
	_timer_fill.size     = Vector2(BAR_W - 4, BAR_H - 4)
	_timer_fill.color    = Color(0.20, 0.65, 0.30, 0.80)
	_timer_bar.add_child(_timer_fill)

	_timer_label = Label.new()
	_timer_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_timer_label.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	_timer_label.add_theme_font_size_override("font_size", 11)
	_timer_label.add_theme_color_override("font_color", COLOR_TEXT)
	_timer_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_timer_label.add_theme_constant_override("outline_size", 3)
	_timer_bar.add_child(_timer_label)


func _build_opp_timer_bar(parent: Node, W: float) -> void:
	const BAR_W := 260.0
	const BAR_H := 26.0
	var bar_x := W - BAR_W - 14.0
	var bar_y := 14.0 + 42.0 + 6.0

	_opp_timer_bar          = Control.new()
	_opp_timer_bar.name     = "OppTurnTimerBar"
	_opp_timer_bar.position = Vector2(bar_x, bar_y)
	_opp_timer_bar.size     = Vector2(BAR_W, BAR_H)
	_opp_timer_bar.z_index  = 10
	_opp_timer_bar.visible  = false
	parent.add_child(_opp_timer_bar)

	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.06, 0.06, 0.10, 0.75)
	_opp_timer_bar.add_child(bg)

	var border = Panel.new()
	border.set_anchors_preset(Control.PRESET_FULL_RECT)
	var bs = StyleBoxFlat.new()
	bs.bg_color = Color(0, 0, 0, 0)
	bs.border_color = COLOR_GOLD_DIM
	bs.border_width_left = 1; bs.border_width_right  = 1
	bs.border_width_top  = 1; bs.border_width_bottom = 1
	bs.corner_radius_top_left    = 5; bs.corner_radius_top_right    = 5
	bs.corner_radius_bottom_left = 5; bs.corner_radius_bottom_right = 5
	border.add_theme_stylebox_override("panel", bs)
	_opp_timer_bar.add_child(border)

	_opp_timer_fill          = ColorRect.new()
	_opp_timer_fill.position = Vector2(2, 2)
	_opp_timer_fill.size     = Vector2(BAR_W - 4, BAR_H - 4)
	_opp_timer_fill.color    = Color(0.85, 0.18, 0.18, 0.90)
	_opp_timer_bar.add_child(_opp_timer_fill)

	_opp_timer_label = Label.new()
	_opp_timer_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_opp_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_opp_timer_label.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	_opp_timer_label.add_theme_font_size_override("font_size", 11)
	_opp_timer_label.add_theme_color_override("font_color", COLOR_TEXT)
	_opp_timer_bar.add_child(_opp_timer_label)
