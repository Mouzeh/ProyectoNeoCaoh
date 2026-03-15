extends Node
# ============================================================
# scenes/main_menu/screens/SpectateScreen.gd
# ============================================================

var _current_room_id:     String     = ""
var _signal_callables:    Array      = []
var _processed_log_count: int        = 0
var _container:           Control    = null
var _menu                            = null
var _battle_log:          BattleLog  = null
var _last_state:          Dictionary = {}


func build(container: Control, menu, room: Dictionary) -> void:
	_container           = container
	_menu                = menu
	_current_room_id     = room.get("room_id", room.get("id", ""))
	_processed_log_count = 0
	_last_state          = {}

	var vp_size = menu.get_viewport().get_visible_rect().size
	var W = vp_size.x
	var H = vp_size.y

	# ── Header ────────────────────────────────────────────────
	var header = Panel.new()
	header.set_anchors_preset(Control.PRESET_TOP_WIDE)
	header.custom_minimum_size = Vector2(0, 46)
	header.z_index = 200   # alto para estar siempre encima del BattleLog
	header.mouse_filter = Control.MOUSE_FILTER_PASS # <--- NUEVO: Deja pasar el clic si no le das al botón
	
	var hs = StyleBoxFlat.new()
	hs.bg_color            = Color(0.05, 0.07, 0.09, 0.97)
	hs.border_color        = Color(0.55, 0.45, 0.18, 0.6)
	hs.border_width_bottom = 2
	header.add_theme_stylebox_override("panel", hs)
	container.add_child(header)

	var hm = MarginContainer.new()
	hm.set_anchors_preset(Control.PRESET_FULL_RECT)
	hm.add_theme_constant_override("margin_left",  14)
	hm.add_theme_constant_override("margin_right", 14)
	hm.mouse_filter = Control.MOUSE_FILTER_PASS # <--- NUEVO
	header.add_child(hm)

	var hrow = HBoxContainer.new()
	hrow.add_theme_constant_override("separation", 16)
	hrow.set_anchors_preset(Control.PRESET_FULL_RECT)
	hrow.mouse_filter = Control.MOUSE_FILTER_PASS # <--- NUEVO
	hm.add_child(hrow)

	# ── Botón "✕ Dejar de ver" — rojo sólido, más grande ─────
	var back_btn = Button.new()
	back_btn.text = "✕  Dejar de ver"
	back_btn.custom_minimum_size = Vector2(148, 34)
	back_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	back_btn.z_index = 210
	
	var s_n = StyleBoxFlat.new()
	s_n.bg_color     = Color(0.75, 0.08, 0.08, 1.0)
	s_n.border_color = Color(1.0, 0.20, 0.20, 1.0)
	s_n.border_width_left = 1; s_n.border_width_right  = 1
	s_n.border_width_top  = 1; s_n.border_width_bottom = 1
	s_n.corner_radius_top_left    = 6; s_n.corner_radius_top_right    = 6
	s_n.corner_radius_bottom_left = 6; s_n.corner_radius_bottom_right = 6
	back_btn.add_theme_stylebox_override("normal", s_n)
	
	var s_h = StyleBoxFlat.new()
	s_h.bg_color     = Color(0.95, 0.12, 0.12, 1.0)
	s_h.border_color = Color(1.0, 0.40, 0.40, 1.0)
	s_h.border_width_left = 1; s_h.border_width_right  = 1
	s_h.border_width_top  = 1; s_h.border_width_bottom = 1
	s_h.corner_radius_top_left    = 6; s_h.corner_radius_top_right    = 6
	s_h.corner_radius_bottom_left = 6; s_h.corner_radius_bottom_right = 6
	back_btn.add_theme_stylebox_override("hover", s_h)
	
	back_btn.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	back_btn.add_theme_font_size_override("font_size", 13)
	
	back_btn.pressed.connect(func():
		_disconnect_signals()
		NetworkManager.stop_spectating(_current_room_id)
		_menu._show_screen(_menu.Screen.HOME) 
	)
	hrow.add_child(back_btn)

	# Nombre de sala
	var raw_name  = room.get("name", "")
	var host_user = room.get("host_username", room.get("host", ""))
	var room_name: String
	if raw_name == "" or (raw_name.length() > 20 and "-" in raw_name):
		room_name = "Mesa de " + host_user if host_user != "" else "Mesa de juego"
	else:
		room_name = raw_name
	var mode      = room.get("mode", "casual")
	var tier      = room.get("deck_tier", "C")
	var title_lbl = Label.new()
	title_lbl.text = "👁  %s  [%s · Tier %s]" % [room_name, mode.capitalize(), tier]
	title_lbl.add_theme_font_size_override("font_size", 13)
	title_lbl.add_theme_color_override("font_color", Color("#c9a84c"))
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_lbl.vertical_alignment    = VERTICAL_ALIGNMENT_CENTER
	hrow.add_child(title_lbl)

	var phase_lbl = Label.new()
	phase_lbl.name = "PhaseLabel"
	phase_lbl.text = ""
	phase_lbl.add_theme_font_size_override("font_size", 11)
	phase_lbl.add_theme_color_override("font_color", Color("#aaaaaa"))
	phase_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hrow.add_child(phase_lbl)

	var spec_lbl = Label.new()
	spec_lbl.name = "SpectatorCount"
	spec_lbl.text = "👁 " + str(room.get("spectators", 0))
	spec_lbl.add_theme_font_size_override("font_size", 11)
	spec_lbl.add_theme_color_override("font_color", Color("#7eb8e8"))
	spec_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hrow.add_child(spec_lbl)

	# ── Área del tablero ──────────────────────────────────────
	var board_area = Control.new()
	board_area.name = "BoardArea"
	board_area.set_anchors_preset(Control.PRESET_FULL_RECT)
	board_area.offset_top = 46
	container.add_child(board_area)

	var status = room.get("status", "waiting")
	if status == "waiting":
		var bg = ColorRect.new()
		bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		bg.color        = Color(0.05, 0.07, 0.10, 1)
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		board_area.add_child(bg)
		_add_wait_message(board_area)
	else:
		_build_live_board(board_area, room.get("initial_state", {}))

	# ── BattleLog — z_index bajo para no tapar el header ─────
	_battle_log          = BattleLog.new()
	_battle_log.name     = "BattleLog"
	_battle_log.z_index  = 20   
	container.add_child(_battle_log)

	var log_offset: float = 100.0
	_battle_log.setup(W, H - 46 - log_offset)
	_battle_log.position = Vector2(0, 46 + log_offset)

	var my_name: String = "Espectador"
	if PlayerData.get("username") != null and str(PlayerData.get("username")) != "":
		my_name = str(PlayerData.get("username"))
	_battle_log.set_chat_name(my_name)
	_battle_log.chat_sent.connect(func(text: String):
		NetworkManager.send_spectator_chat(_current_room_id, text)
	)

	_connect_signals()

	# <--- NUEVO: Aseguramos que el header se dibuje al final para que intercepte los clics primero
	container.move_child(header, -1) 


# ─────────────────────────────────────────────────────────────
func _add_wait_message(parent: Control) -> void:
	var wm = CenterContainer.new()
	wm.name = "WaitMessage"
	wm.set_anchors_preset(Control.PRESET_FULL_RECT)
	parent.add_child(wm)

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 12)
	wm.add_child(vbox)

	var icon = Label.new()
	icon.text = "⏳"
	icon.add_theme_font_size_override("font_size", 52)
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(icon)

	var lbl = Label.new()
	lbl.text = "Esperando a que la partida comience..."
	lbl.add_theme_font_size_override("font_size", 15)
	lbl.add_theme_color_override("font_color", Color("#888888"))
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(lbl)


# ─────────────────────────────────────────────────────────────
func _build_live_board(board_area: Control, initial_state: Dictionary) -> void:
	for child in board_area.get_children():
		child.queue_free()

	var vp_size  = board_area.get_viewport().get_visible_rect().size
	var board_vp = Vector2(vp_size.x, vp_size.y - 46)

	if ResourceLoader.exists("res://assets/imagen/tablero/tablero1.png"):
		var bg_tex = TextureRect.new()
		bg_tex.name         = "BoardBg"
		bg_tex.texture      = load("res://assets/imagen/tablero/tablero1.png")
		bg_tex.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
		bg_tex.stretch_mode = TextureRect.STRETCH_SCALE
		bg_tex.size         = board_vp
		bg_tex.position     = Vector2.ZERO
		bg_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bg_tex.z_index      = 0
		board_area.add_child(bg_tex)
	else:
		var bg = ColorRect.new()
		bg.size         = board_vp
		bg.position     = Vector2.ZERO
		bg.color        = Color(0.05, 0.07, 0.10, 1)
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		board_area.add_child(bg)

	var board_node = Node2D.new()
	board_node.name     = "SpectateBoard"
	board_node.position = Vector2(0, -46)
	board_area.add_child(board_node)

	var zones: Dictionary = BoardBuilder.build_all(board_node, vp_size)

	var my_hand = zones.get("my_hand")
	if my_hand: my_hand.visible = false

	var renderer = BoardRenderer.new()
	renderer.name = "Renderer"
	board_node.add_child(renderer)
	renderer.setup(zones, vp_size.x)

	board_node.set_meta("renderer", renderer)
	board_node.set_meta("zones",    zones)

	if not initial_state.is_empty():
		renderer.render_board(initial_state)


# ─────────────────────────────────────────────────────────────
func _connect_signals() -> void:
	_disconnect_signals()

	var c1 = func(rid, _uid, uname, text):
		if rid != _current_room_id and rid != "": return
		if _battle_log: _battle_log.add_chat_message(uname, text, Color("#7eb8e8"), false)
	NetworkManager.spectator_chat_received.connect(c1)
	_signal_callables.append([NetworkManager.spectator_chat_received, c1])

	var c_battle_chat = func(pid: String, text: String):
		if not _battle_log: return
		var display_name = _resolve_player_name(pid)
		_battle_log.add_chat_message(display_name, text, Color("#f5a94e"), false)
	NetworkManager.chat_received.connect(c_battle_chat)
	_signal_callables.append([NetworkManager.chat_received, c_battle_chat])

	var c2 = func(rid, _uid, count):
		if rid != _current_room_id: return
		_update_spectator_count(count)
	NetworkManager.spectator_joined.connect(c2)
	_signal_callables.append([NetworkManager.spectator_joined, c2])

	var c3 = func(rid, _uid, count):
		if rid != _current_room_id: return
		_update_spectator_count(count)
	NetworkManager.spectator_left.connect(c3)
	_signal_callables.append([NetworkManager.spectator_left, c3])

	var c4 = func(rid, _mode):
		if rid != "": _current_room_id = rid
		var board_area = _container.get_node_or_null("BoardArea")
		if board_area: _build_live_board(board_area, {})
		if _battle_log: _battle_log.add_message("⚔  ¡La partida ha comenzado!")
	NetworkManager.spectate_game_start.connect(c4)
	_signal_callables.append([NetworkManager.spectate_game_start, c4])

	var c5 = func(state: Dictionary, log_arr):
		var board_area = _container.get_node_or_null("BoardArea")
		if not board_area: return

		var render_state := state
		if state.has("player1") and state.has("player2"):
			render_state = {
				"current_player": state.get("current_player", ""),
				"phase":          state.get("phase", "MAIN"),
				"turn":           state.get("turn", 1),
				"my":             state.get("player1", {}),
				"opponent":       state.get("player2", {}),
			}

		_last_state = render_state

		var board_node = board_area.get_node_or_null("SpectateBoard")
		if not board_node:
			_build_live_board(board_area, render_state)
		else:
			var renderer = board_node.get_meta("renderer", null) as BoardRenderer
			if renderer: renderer.render_board(render_state)

		var phase_lbl = _container.get_node_or_null("PhaseLabel")
		if phase_lbl:
			var turn    = render_state.get("turn",  1)
			var phase   = render_state.get("phase", "MAIN")
			var p1_name = render_state.get("my",       {}).get("username", "J1")
			var p2_name = render_state.get("opponent", {}).get("username", "J2")
			phase_lbl.text = "T%d | %s | %s vs %s" % [turn, phase, p1_name, p2_name]

		if _battle_log and log_arr is Array:
			for i in range(_processed_log_count, log_arr.size()):
				_battle_log.add_message(_clean_log(log_arr[i], render_state))
			_processed_log_count = log_arr.size()
	NetworkManager.spectate_state_updated.connect(c5)
	_signal_callables.append([NetworkManager.spectate_state_updated, c5])

	var c6 = func(winner):
		if _battle_log: _battle_log.add_message("🏆  Partida terminada · Ganador: " + str(winner))
	NetworkManager.spectate_game_over.connect(c6)
	_signal_callables.append([NetworkManager.spectate_game_over, c6])

	var c7 = func(rid):
		if rid != _current_room_id: return
		_disconnect_signals()
		_menu._show_screen(_menu.Screen.HOME) 
	NetworkManager.spectate_ended.connect(c7)
	_signal_callables.append([NetworkManager.spectate_ended, c7])


func _disconnect_signals() -> void:
	for pair in _signal_callables:
		var sig: Signal = pair[0]
		var cb          = pair[1]
		if sig.is_connected(cb): sig.disconnect(cb)
	_signal_callables.clear()


func _resolve_player_name(pid: String) -> String:
	var p1 = _last_state.get("my",       {})
	var p2 = _last_state.get("opponent", {})
	if p1.get("id", "") == pid:
		return p1.get("username", p1.get("display_name", "J1"))
	if p2.get("id", "") == pid:
		return p2.get("username", p2.get("display_name", "J2"))
	if pid.length() > 20 and "-" in pid:
		return "Jugador"
	return pid


func _clean_log(msg: String, state: Dictionary) -> String:
	var p1 = state.get("my", {})
	var p2 = state.get("opponent", {})
	var p1_id   = p1.get("id", "")
	var p2_id   = p2.get("id", "")
	var p1_name = p1.get("username", "J1")
	var p2_name = p2.get("username", "J2")
	if p1_id != "" and p1_id in msg:
		msg = msg.replace(p1_id, p1_name)
	if p2_id != "" and p2_id in msg:
		msg = msg.replace(p2_id, p2_name)
	return msg


func _update_spectator_count(count: int) -> void:
	var lbl = _container.get_node_or_null("SpectatorCount")
	if lbl: lbl.text = "👁 " + str(count)
