extends Node

# ============================================================
# LoginScreen.gd — con email + verificación 6 dígitos
#                  + recordar sesión (ConfigFile)
# ============================================================

const API_URL      = "https://caoh-tcg.fly.dev/api/auth"
const SESSION_FILE = "user://session.cfg"
const SESSION_SEC  = "session"


# ── Guardar sesión en disco ──────────────────────────────────
static func _save_session(username: String, token: String) -> void:
	var cfg = ConfigFile.new()
	cfg.set_value(SESSION_SEC, "username", username)
	cfg.set_value(SESSION_SEC, "token",    token)
	cfg.save(SESSION_FILE)


# ── Cargar sesión desde disco ────────────────────────────────
static func _load_session() -> Dictionary:
	var cfg = ConfigFile.new()
	if cfg.load(SESSION_FILE) != OK:
		return {}
	return {
		"username": cfg.get_value(SESSION_SEC, "username", ""),
		"token":    cfg.get_value(SESSION_SEC, "token",    ""),
	}


# ── Borrar sesión (logout) ───────────────────────────────────
static func _clear_session() -> void:
	var dir = DirAccess.open("user://")
	if dir and dir.file_exists("session.cfg"):
		dir.remove("session.cfg")


# ── Validar token guardado contra el servidor ────────────────
static func _try_auto_login(saved: Dictionary, menu, on_fail: Callable) -> void:
	var http = HTTPRequest.new()
	menu.add_child(http)
	http.request_completed.connect(func(result, code, _h, body):
		http.queue_free()
		if not is_instance_valid(menu): return
		if result != HTTPRequest.RESULT_SUCCESS or code != 200:
			_clear_session()
			on_fail.call()
			return
		var data = JSON.parse_string(body.get_string_from_utf8())
		if not data:
			_clear_session(); on_fail.call(); return
		var token  = data.get("token",  saved.token)
		var player = data.get("player", {})
		PlayerData.load_from_server(player)
		PlayerData.token         = token
		NetworkManager.token     = token
		menu.player_id           = PlayerData.player_id
		NetworkManager.player_id = PlayerData.player_id
		_save_session(PlayerData.username, token)
		_go_to_lobby(menu)
	)
	http.request(API_URL + "/refresh",
		["Content-Type: application/json",
		 "Authorization: Bearer " + saved.token],
		HTTPClient.METHOD_POST, "")


static func build(container: Control, menu) -> void:
	var C = menu

	# ── Intentar auto-login antes de mostrar UI ───────────────
	var saved = _load_session()
	if saved.get("token", "") != "":
		var loading_lbl = Label.new()
		loading_lbl.name = "AutoLoginLbl"
		loading_lbl.text = "⏳ Iniciando sesión..."
		loading_lbl.set_anchors_preset(Control.PRESET_CENTER)
		loading_lbl.add_theme_font_size_override("font_size", 16)
		loading_lbl.add_theme_color_override("font_color", C.COLOR_GOLD)
		container.add_child(loading_lbl)

		_try_auto_login(saved, menu, func():
			if is_instance_valid(loading_lbl): loading_lbl.queue_free()
			_build_login_ui(container, menu, saved.get("username", ""))
		)
		return

	_build_login_ui(container, menu, "")


static func _build_login_ui(container: Control, menu, prefill_username: String) -> void:
	var C = menu

	var bg_image = TextureRect.new()
	var bg_tex = load("res://assets/imagen/loginbackgraund.png")
	if bg_tex: bg_image.texture = bg_tex
	bg_image.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_image.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	bg_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg_image.modulate     = Color(0.1, 0.1, 0.1, 0)
	var vp_size = container.get_viewport().get_visible_rect().size
	bg_image.pivot_offset = vp_size / 2.0
	bg_image.scale = Vector2(1.02, 1.02)
	container.add_child(bg_image)
	var tween = container.create_tween().set_parallel(true)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUINT)
	tween.tween_property(bg_image, "modulate", Color(1, 1, 1, 1), 3.0)
	tween.tween_property(bg_image, "scale",    Vector2(1.0, 1.0), 6.0)

	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	container.add_child(center)

	var card = PanelContainer.new()
	card.name = "LoginCard"
	card.custom_minimum_size = Vector2(920, 560)
	card.clip_contents = true
	var st_card = StyleBoxFlat.new()
	st_card.bg_color = C.COLOR_PANEL
	st_card.border_color = Color(C.COLOR_GOLD_DIM.r, C.COLOR_GOLD_DIM.g, C.COLOR_GOLD_DIM.b, 0.5)
	st_card.border_width_left = 1; st_card.border_width_right  = 1
	st_card.border_width_top  = 1; st_card.border_width_bottom = 1
	st_card.corner_radius_top_left    = 20; st_card.corner_radius_top_right    = 20
	st_card.corner_radius_bottom_left = 20; st_card.corner_radius_bottom_right = 20
	st_card.shadow_color = Color(0, 0, 0, 0.4)
	st_card.shadow_size = 40; st_card.shadow_offset = Vector2(0, 15)
	card.add_theme_stylebox_override("panel", st_card)
	center.add_child(card)

	var card_hbox = HBoxContainer.new()
	card_hbox.add_theme_constant_override("separation", 0)
	card.add_child(card_hbox)

	var left_panel = PanelContainer.new()
	left_panel.custom_minimum_size = Vector2(380, 0)
	left_panel.clip_contents = true
	var st_left_bg = StyleBoxFlat.new()
	st_left_bg.bg_color = C.COLOR_BG.darkened(0.3)
	left_panel.add_theme_stylebox_override("panel", st_left_bg)
	card_hbox.add_child(left_panel)

	var banner_img = TextureRect.new()
	banner_img.name = "BannerImg"
	var banner_tex = load("res://assets/imagen/banner/banner1.png")
	if banner_tex: banner_img.texture = banner_tex
	banner_img.set_anchors_preset(Control.PRESET_FULL_RECT)
	banner_img.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	banner_img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	banner_img.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left_panel.add_child(banner_img)

	var overlay_l = ColorRect.new()
	overlay_l.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay_l.color = Color(0, 0, 0, 0.45)
	overlay_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left_panel.add_child(overlay_l)

	var left_m = MarginContainer.new()
	left_m.set_anchors_preset(Control.PRESET_FULL_RECT)
	left_m.add_theme_constant_override("margin_left",   32)
	left_m.add_theme_constant_override("margin_right",  32)
	left_m.add_theme_constant_override("margin_top",    32)
	left_m.add_theme_constant_override("margin_bottom", 32)
	left_panel.add_child(left_m)

	var left_v = VBoxContainer.new()
	left_m.add_child(left_v)

	var brand_lbl = Label.new()
	brand_lbl.text = "◈ Neo Caoh TCG"
	brand_lbl.add_theme_font_size_override("font_size", 16)
	brand_lbl.add_theme_color_override("font_color", C.COLOR_GOLD)
	left_v.add_child(brand_lbl)

	var spacer_l = Control.new()
	spacer_l.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_v.add_child(spacer_l)

	var sub_msg = Label.new()
	sub_msg.text = "Bienvenido"
	sub_msg.add_theme_font_size_override("font_size", 14)
	sub_msg.add_theme_color_override("font_color", Color(1, 1, 1, 0.7))
	left_v.add_child(sub_msg)

	var main_msg = Label.new()
	main_msg.text = "Colecciona, construye y batalla con las 111 cartas de Neo Genesis."
	main_msg.autowrap_mode = TextServer.AUTOWRAP_WORD
	main_msg.add_theme_font_size_override("font_size", 24)
	main_msg.add_theme_color_override("font_color", Color.WHITE)
	left_v.add_child(main_msg)

	left_v.add_child(UITheme.vspace(8))
	var ver_msg = Label.new()
	ver_msg.text = "v0.1 Pre Alpha · Neo Caoh TCG · 111 cartas disponibles"
	ver_msg.add_theme_font_size_override("font_size", 11)
	ver_msg.add_theme_color_override("font_color", Color(1, 1, 1, 0.4))
	left_v.add_child(ver_msg)

	var right_m = MarginContainer.new()
	right_m.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_m.add_theme_constant_override("margin_left",   32)
	right_m.add_theme_constant_override("margin_right",  32)
	right_m.add_theme_constant_override("margin_top",    40)
	right_m.add_theme_constant_override("margin_bottom", 40)
	card_hbox.add_child(right_m)

	var form_view = _build_form_view(right_m, menu, C, prefill_username)
	form_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	form_view.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	right_m.add_child(form_view)

	var verify_view = _build_verify_view(right_m, menu, C)
	verify_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	verify_view.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	verify_view.visible = false
	right_m.add_child(verify_view)

	var state = {
		"is_login":      true,
		"pending_email": "",
		"pending_user":  "",
		"pending_pass":  "",
	}

	_wire_form(form_view, verify_view, state, menu, C, card)
	_wire_verify(verify_view, form_view, state, menu, C)


# ─── VISTA FORMULARIO ────────────────────────────────────────
static func _build_form_view(parent: Node, menu, C, prefill_username: String = "") -> Control:
	var v = VBoxContainer.new()
	v.name = "FormView"
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 10)

	var star = Label.new()
	star.text = "✱"
	star.add_theme_font_size_override("font_size", 34)
	star.add_theme_color_override("font_color", C.COLOR_GOLD)
	v.add_child(star)

	var title = Label.new()
	title.name = "Title"
	title.text = "Iniciar Sesión"
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", C.COLOR_TEXT)
	v.add_child(title)

	var toggle_hb = HBoxContainer.new()
	toggle_hb.alignment = BoxContainer.ALIGNMENT_CENTER
	toggle_hb.add_theme_constant_override("separation", 0)
	v.add_child(toggle_hb)

	var btn_login = Button.new()
	btn_login.name = "BtnLogin"
	btn_login.text = "Iniciar Sesión"
	btn_login.custom_minimum_size = Vector2(140, 34)
	btn_login.add_theme_font_size_override("font_size", 12)
	toggle_hb.add_child(btn_login)

	var btn_register = Button.new()
	btn_register.name = "BtnRegister"
	btn_register.text = "Crear Cuenta"
	btn_register.custom_minimum_size = Vector2(140, 34)
	btn_register.add_theme_font_size_override("font_size", 12)
	toggle_hb.add_child(btn_register)

	_style_toggle(btn_login, btn_register, true, C)

	v.add_child(_make_label("Trainer Name", C))
	var name_input = _make_input("ej: AshKetchum", false, C)
	name_input.name = "NameInput"
	if prefill_username != "":
		name_input.text = prefill_username
	v.add_child(name_input)

	var email_row = VBoxContainer.new()
	email_row.name = "EmailRow"
	email_row.visible = false
	email_row.add_child(_make_label("Correo electrónico", C))
	var email_input = _make_input("trainer@ejemplo.com", false, C)
	email_input.name = "EmailInput"
	email_row.add_child(email_input)
	v.add_child(email_row)

	v.add_child(_make_label("Password", C))
	var pass_input = _make_input("••••••••", true, C)
	pass_input.name = "PassInput"
	v.add_child(pass_input)

	var confirm_row = VBoxContainer.new()
	confirm_row.name = "ConfirmRow"
	confirm_row.visible = false
	confirm_row.add_child(_make_label("Repite tu contraseña", C))
	var confirm_input = _make_input("••••••••", true, C)
	confirm_input.name = "ConfirmInput"
	confirm_row.add_child(confirm_input)
	v.add_child(confirm_row)

	var status_lbl = Label.new()
	status_lbl.name = "StatusLabel"
	status_lbl.text = ""
	status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_lbl.add_theme_font_size_override("font_size", 11)
	status_lbl.add_theme_color_override("font_color", C.COLOR_TEXT_DIM)
	status_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	v.add_child(status_lbl)

	var btn_main = _make_primary_button("Entrar", C)
	btn_main.name = "BtnMain"
	v.add_child(btn_main)

	# ── Checkbox "Recordar sesión" ────────────────────────────
	var remember_hb = HBoxContainer.new()
	remember_hb.alignment = BoxContainer.ALIGNMENT_CENTER
	remember_hb.add_theme_constant_override("separation", 6)
	v.add_child(remember_hb)

	var remember_chk = CheckBox.new()
	remember_chk.name = "RememberChk"
	remember_chk.button_pressed = true
	remember_chk.text = "Recordar sesión"
	remember_chk.add_theme_font_size_override("font_size", 11)
	remember_chk.add_theme_color_override("font_color", C.COLOR_TEXT_DIM)
	remember_hb.add_child(remember_chk)

	v.add_child(_make_divider(C))

	var btn_local = _make_ghost_button("Juego Local (Sin Servidor)", C)
	v.add_child(btn_local)
	btn_local.pressed.connect(func(): _on_local_pressed(name_input, menu))

	var conn_text  = "● Servidor conectado" if NetworkManager.ws_connected else "○ Sin conexión"
	var conn_color = C.COLOR_GREEN if NetworkManager.ws_connected else C.COLOR_TEXT_DIM
	var srv_lbl = Label.new()
	srv_lbl.name = "SrvLabel"
	srv_lbl.text = conn_text
	srv_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	srv_lbl.add_theme_font_size_override("font_size", 10)
	srv_lbl.add_theme_color_override("font_color", conn_color)
	v.add_child(srv_lbl)

	if prefill_username != "":
		pass_input.call_deferred("grab_focus")

	return v


# ─── VISTA VERIFICACIÓN ──────────────────────────────────────
static func _build_verify_view(parent: Node, menu, C) -> Control:
	var v = VBoxContainer.new()
	v.name = "VerifyView"
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 18)

	var icon = Label.new()
	icon.text = "✉"
	icon.add_theme_font_size_override("font_size", 48)
	icon.add_theme_color_override("font_color", C.COLOR_GOLD)
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(icon)

	var title = Label.new()
	title.text = "Verifica tu correo"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", C.COLOR_TEXT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)

	var desc = Label.new()
	desc.name = "VerifyDesc"
	desc.text = "Enviamos un código de 6 dígitos a\ntu@correo.com"
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc.add_theme_font_size_override("font_size", 12)
	desc.add_theme_color_override("font_color", C.COLOR_TEXT_DIM)
	v.add_child(desc)

	var digits_hb = HBoxContainer.new()
	digits_hb.name = "DigitsBox"
	digits_hb.alignment = BoxContainer.ALIGNMENT_CENTER
	digits_hb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	digits_hb.add_theme_constant_override("separation", 8)
	v.add_child(digits_hb)

	for i in range(6):
		var d = LineEdit.new()
		d.name = "Digit%d" % i
		d.max_length = 1
		d.custom_minimum_size = Vector2(52, 56)
		d.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		d.alignment = HORIZONTAL_ALIGNMENT_CENTER
		d.add_theme_font_size_override("font_size", 22)
		d.add_theme_color_override("font_color", C.COLOR_TEXT)
		d.add_theme_color_override("caret_color", C.COLOR_GOLD)
		var st = StyleBoxFlat.new()
		st.bg_color = C.COLOR_BG
		st.border_color = Color(C.COLOR_GOLD_DIM.r, C.COLOR_GOLD_DIM.g, C.COLOR_GOLD_DIM.b, 0.4)
		st.border_width_left = 1; st.border_width_right  = 1
		st.border_width_top  = 1; st.border_width_bottom = 1
		st.corner_radius_top_left    = 8; st.corner_radius_top_right    = 8
		st.corner_radius_bottom_left = 8; st.corner_radius_bottom_right = 8
		var st_focus = st.duplicate()
		st_focus.border_color = C.COLOR_GOLD
		st_focus.border_width_left = 2; st_focus.border_width_right  = 2
		st_focus.border_width_top  = 2; st_focus.border_width_bottom = 2
		d.add_theme_stylebox_override("normal", st)
		d.add_theme_stylebox_override("focus",  st_focus)
		digits_hb.add_child(d)

	var status_lbl = Label.new()
	status_lbl.name = "VerifyStatus"
	status_lbl.text = ""
	status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_lbl.add_theme_font_size_override("font_size", 11)
	status_lbl.add_theme_color_override("font_color", C.COLOR_TEXT_DIM)
	v.add_child(status_lbl)

	var btn_verify = _make_primary_button("Verificar código", C)
	btn_verify.name = "BtnVerify"
	v.add_child(btn_verify)

	var btn_resend = _make_ghost_button("Reenviar código", C)
	btn_resend.name = "BtnResend"
	v.add_child(btn_resend)

	var btn_back = Button.new()
	btn_back.name = "BtnBack"
	btn_back.text = "← Volver"
	btn_back.flat = true
	btn_back.add_theme_font_size_override("font_size", 11)
	btn_back.add_theme_color_override("font_color", C.COLOR_TEXT_DIM)
	v.add_child(btn_back)

	return v


# ─── CONECTAR LÓGICA FORM ────────────────────────────────────
static func _wire_form(form: Control, verify: Control, state: Dictionary, menu, C, card: Control = null) -> void:
	var title        = form.find_child("Title",        true, false)
	var btn_login    = form.find_child("BtnLogin",     true, false)
	var btn_register = form.find_child("BtnRegister",  true, false)
	var name_input   = form.find_child("NameInput",    true, false)
	var email_row    = form.find_child("EmailRow",     true, false)
	var email_input  = form.find_child("EmailInput",   true, false)
	var pass_input   = form.find_child("PassInput",    true, false)
	var status_lbl   = form.find_child("StatusLabel",  true, false)
	var btn_main     = form.find_child("BtnMain",      true, false)
	var confirm_row2 = form.find_child("ConfirmRow",   true, false)

	var fade_overlay = ColorRect.new()
	fade_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_overlay.color = Color(0, 0, 0, 0)
	fade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_overlay.z_index = 10
	form.add_child(fade_overlay)

	btn_login.pressed.connect(func():
		if state.is_login: return
		_fade_switch_content(fade_overlay, form, func():
			state.is_login = true
			title.text = "Iniciar Sesión"
			btn_main.text = "Entrar"
			email_row.visible    = false
			confirm_row2.visible = false
			status_lbl.text = ""
			_style_toggle(btn_login, btn_register, true, C)
			var b = form.get_parent().get_parent().find_child("BannerImg", true, false)
			if b:
				var t = load("res://assets/imagen/banner/banner1.png")
				if t: b.texture = t
		)
		if card: _animate_card_height(card, 560, form)
	)

	btn_register.pressed.connect(func():
		if not state.is_login: return
		_fade_switch_content(fade_overlay, form, func():
			state.is_login = false
			title.text = "Crear Cuenta"
			btn_main.text = "Registrarse"
			email_row.visible    = true
			confirm_row2.visible = true
			status_lbl.text = ""
			_style_toggle(btn_login, btn_register, false, C)
			var b = form.get_parent().get_parent().find_child("BannerImg", true, false)
			if b:
				var t = load("res://assets/imagen/banner/banner3.png")
				if t: b.texture = t
		)
		if card: _animate_card_height(card, 680, form)
	)

	var do_submit = func():
		_on_main_pressed(
			name_input, email_input, pass_input,
			status_lbl, btn_main,
			state, form, verify, menu, C
		)

	btn_main.pressed.connect(do_submit)
	pass_input.text_submitted.connect(func(_t): do_submit.call())


# ─── CONECTAR LÓGICA VERIFICACIÓN ────────────────────────────
static func _wire_verify(verify: Control, form: Control, state: Dictionary, menu, C) -> void:
	var digits_hb  = verify.find_child("DigitsBox",    true, false)
	var status_lbl = verify.find_child("VerifyStatus", true, false)
	var btn_verify = verify.find_child("BtnVerify",    true, false)
	var btn_resend = verify.find_child("BtnResend",    true, false)
	var btn_back   = verify.find_child("BtnBack",      true, false)

	for i in range(6):
		var d = digits_hb.get_child(i)
		d.text_changed.connect(func(new_text: String):
			if new_text != "" and not new_text[-1].is_valid_int():
				d.text = new_text.left(new_text.length() - 1)
				d.caret_column = d.text.length()
				return
			if new_text.length() == 1 and i < 5:
				digits_hb.get_child(i + 1).grab_focus()
		)

	btn_verify.pressed.connect(func():
		var code = ""
		for i in range(6):
			code += digits_hb.get_child(i).text
		if code.length() < 6:
			_set_status(status_lbl, "⚠ Ingresa los 6 dígitos", C.COLOR_RED); return
		_submit_verification(code, state, status_lbl, btn_verify, menu, C)
	)

	btn_resend.pressed.connect(func():
		_set_status(status_lbl, "Reenviando código...", C.COLOR_TEXT_DIM)
		_request_resend(state.pending_email, status_lbl, C, menu)
	)

	btn_back.pressed.connect(func():
		_animate_switch(verify, form, verify)
	)


# ─── ACCIÓN PRINCIPAL ────────────────────────────────────────
static func _on_main_pressed(
	name_input: LineEdit, email_input: LineEdit, pass_input: LineEdit,
	status_lbl: Label, btn_main: Button,
	state: Dictionary, form: Control, verify: Control,
	menu, C
) -> void:
	var username = name_input.text.strip_edges()
	var email    = email_input.text.strip_edges().to_lower()
	var password = pass_input.text.strip_edges()

	if username == "":
		_set_status(status_lbl, "⚠ Ingresa tu nombre de entrenador", C.COLOR_RED); return
	if password == "":
		_set_status(status_lbl, "⚠ Ingresa tu contraseña", C.COLOR_RED); return

	if not state.is_login:
		if not _is_valid_email(email):
			_set_status(status_lbl, "⚠ Ingresa un correo electrónico válido", C.COLOR_RED); return
		if password.length() < 4:
			_set_status(status_lbl, "⚠ La contraseña debe tener al menos 4 caracteres", C.COLOR_RED); return
		var confirm_input2 = form.find_child("ConfirmInput", true, false)
		if confirm_input2 and confirm_input2.text != password:
			_set_status(status_lbl, "⚠ Las contraseñas no coinciden", C.COLOR_RED); return

	btn_main.disabled = true
	_set_status(status_lbl, "Conectando...", C.COLOR_TEXT_DIM)

	var remember_chk = form.find_child("RememberChk", true, false)
	var should_remember = remember_chk != null and remember_chk.button_pressed

	if state.is_login:
		_do_login_request(username, password, should_remember, status_lbl, btn_main, menu, C)
	else:
		state.pending_email = email
		state.pending_user  = username
		state.pending_pass  = password
		_do_register_request(username, email, password, status_lbl, btn_main, form, verify, state, menu, C)


# ─── HTTP: LOGIN ─────────────────────────────────────────────
static func _do_login_request(
	username: String, password: String, should_remember: bool,
	status_lbl: Label, btn_main: Button,
	menu, C
) -> void:
	var http = HTTPRequest.new()
	menu.add_child(http)
	http.request_completed.connect(func(result, code, _headers, response_bytes):
		http.queue_free()
		if not is_instance_valid(menu): return
		if is_instance_valid(btn_main): btn_main.disabled = false
		if result != HTTPRequest.RESULT_SUCCESS:
			_set_status(status_lbl, "⚠ No se pudo conectar al servidor", C.COLOR_RED); return
		var json = JSON.new()
		if json.parse(response_bytes.get_string_from_utf8()) != OK:
			_set_status(status_lbl, "⚠ Respuesta inválida del servidor", C.COLOR_RED); return
		var data = json.get_data()
		if code == 200:
			var token  = data.get("token", "")
			var player = data.get("player", {})
			PlayerData.load_from_server(player)
			PlayerData.token         = token
			NetworkManager.token     = token
			menu.player_id           = PlayerData.player_id
			NetworkManager.player_id = PlayerData.player_id
			if should_remember:
				_save_session(PlayerData.username, token)
			else:
				_clear_session()
			_set_status(status_lbl, "✓ Bienvenido, " + PlayerData.username + "!", C.COLOR_GREEN)
			_go_to_lobby(menu)
		else:
			_set_status(status_lbl, "⚠ " + data.get("error", "Error desconocido"), C.COLOR_RED)
	)
	http.request(API_URL + "/login", ["Content-Type: application/json"],
		HTTPClient.METHOD_POST,
		JSON.stringify({"username": username, "password": password}))


# ─── HTTP: REGISTRO ──────────────────────────────────────────
static func _do_register_request(
	username: String, email: String, password: String,
	status_lbl: Label, btn_main: Button,
	form: Control, verify: Control,
	state: Dictionary, menu, C
) -> void:
	var http = HTTPRequest.new()
	menu.add_child(http)
	http.request_completed.connect(func(result, code, _headers, response_bytes):
		http.queue_free()
		if not is_instance_valid(menu): return
		if is_instance_valid(btn_main): btn_main.disabled = false
		if result != HTTPRequest.RESULT_SUCCESS:
			_set_status(status_lbl, "⚠ No se pudo conectar al servidor", C.COLOR_RED); return
		var json = JSON.new()
		if json.parse(response_bytes.get_string_from_utf8()) != OK:
			_set_status(status_lbl, "⚠ Respuesta inválida del servidor", C.COLOR_RED); return
		var data = json.get_data()
		if code == 200 or code == 201:
			var desc = verify.find_child("VerifyDesc", true, false)
			desc.text = "Enviamos un código de 6 dígitos a\n" + email
			var digits_hb = verify.find_child("DigitsBox", true, false)
			for i in range(6):
				digits_hb.get_child(i).text = ""
			_animate_switch(form, verify, menu)
			digits_hb.get_child(0).grab_focus()
		else:
			_set_status(status_lbl, "⚠ " + data.get("error", "Error desconocido"), C.COLOR_RED)
	)
	http.request(API_URL + "/register", ["Content-Type: application/json"],
		HTTPClient.METHOD_POST,
		JSON.stringify({"username": username, "email": email, "password": password}))


# ─── HTTP: VERIFICAR CÓDIGO ──────────────────────────────────
static func _submit_verification(
	code: String, state: Dictionary,
	status_lbl: Label, btn_verify: Button,
	menu, C
) -> void:
	btn_verify.disabled = true
	_set_status(status_lbl, "Verificando...", C.COLOR_TEXT_DIM)
	var http = HTTPRequest.new()
	menu.add_child(http)
	http.request_completed.connect(func(result, code_http, _headers, response_bytes):
		http.queue_free()
		if not is_instance_valid(menu): return
		if is_instance_valid(btn_verify): btn_verify.disabled = false
		if result != HTTPRequest.RESULT_SUCCESS:
			_set_status(status_lbl, "⚠ Error de conexión", C.COLOR_RED); return
		var json = JSON.new()
		if json.parse(response_bytes.get_string_from_utf8()) != OK:
			_set_status(status_lbl, "⚠ Respuesta inválida", C.COLOR_RED); return
		var data = json.get_data()
		if code_http == 200:
			var token  = data.get("token", "")
			var player = data.get("player", {})
			PlayerData.load_from_server(player)
			NetworkManager.token     = token
			menu.player_id           = PlayerData.player_id
			NetworkManager.player_id = PlayerData.player_id
			_save_session(PlayerData.username, token)
			_set_status(status_lbl, "✓ ¡Cuenta verificada!", C.COLOR_GREEN)
			_go_to_lobby(menu)
		else:
			_set_status(status_lbl, "⚠ " + data.get("error", "Código incorrecto"), C.COLOR_RED)
	)
	http.request(API_URL + "/verify-email", ["Content-Type: application/json"],
		HTTPClient.METHOD_POST,
		JSON.stringify({"email": state.pending_email, "code": code}))


# ─── HTTP: REENVIAR CÓDIGO ───────────────────────────────────
static func _request_resend(email: String, status_lbl: Label, C, menu) -> void:
	var http = HTTPRequest.new()
	menu.add_child(http)
	http.request_completed.connect(func(result, code, _headers, response_bytes):
		http.queue_free()
		if not is_instance_valid(menu): return
		if result != HTTPRequest.RESULT_SUCCESS or code != 200:
			_set_status(status_lbl, "⚠ No se pudo reenviar el código", C.COLOR_RED); return
		_set_status(status_lbl, "✓ Código reenviado a " + email, C.COLOR_GREEN)
	)
	http.request(API_URL + "/resend-code", ["Content-Type: application/json"],
		HTTPClient.METHOD_POST,
		JSON.stringify({"email": email}))


# ─── NAVEGACIÓN ──────────────────────────────────────────────
static func _go_to_lobby(menu) -> void:
	if not is_instance_valid(menu): return
	if NetworkManager.ws_connected:
		NetworkManager.authenticate(PlayerData.player_id, NetworkManager.token)
		NetworkManager.auth_ok.connect(func(_p):
			if is_instance_valid(menu): menu._show_screen(menu.Screen.LOBBY)
			, CONNECT_ONE_SHOT)
	else:
		NetworkManager.connect_to_server()
		NetworkManager.auth_ok.connect(func(_p):
			if is_instance_valid(menu): menu._show_screen(menu.Screen.LOBBY)
			, CONNECT_ONE_SHOT)


static func _on_local_pressed(name_input: LineEdit, menu) -> void:
	var name = name_input.text.strip_edges()
	if name == "":
		name_input.placeholder_text = "⚠ Ingresa un nombre primero"; return
	PlayerData.player_id     = name
	PlayerData.username      = name
	menu.player_id           = name
	NetworkManager.player_id = name
	menu._show_screen(menu.Screen.LOBBY)


# ─── ANIMACIONES ─────────────────────────────────────────────
static func _animate_card_height(card: Control, target_h: float, parent: Node) -> void:
	var from_h = card.custom_minimum_size.y
	var tween  = parent.create_tween()
	tween.set_parallel(true); tween.set_ease(Tween.EASE_OUT); tween.set_trans(Tween.TRANS_QUART)
	tween.tween_method(func(h: float): card.custom_minimum_size = Vector2(920, h), from_h, target_h, 0.30)

static func _fade_switch_content(overlay: ColorRect, parent: Node, swap_fn: Callable) -> void:
	var tween = parent.create_tween()
	tween.set_ease(Tween.EASE_IN_OUT); tween.set_trans(Tween.TRANS_SINE)
	tween.tween_property(overlay, "color", Color(0, 0, 0, 0.85), 0.12)
	tween.tween_callback(swap_fn)
	tween.tween_property(overlay, "color", Color(0, 0, 0, 0.0),  0.15)

static func _animate_switch(from_view: Control, to_view: Control, parent: Node) -> void:
	var panel   = from_view.get_parent()
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0); overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE; overlay.z_index = 10
	if panel: overlay.set_anchors_preset(Control.PRESET_FULL_RECT); panel.add_child(overlay)
	var tween = parent.create_tween()
	tween.set_ease(Tween.EASE_IN_OUT); tween.set_trans(Tween.TRANS_SINE)
	tween.tween_property(overlay, "color", Color(0, 0, 0, 0.85), 0.13)
	tween.tween_callback(func(): from_view.visible = false; to_view.visible = true; to_view.modulate = Color(1,1,1,1))
	tween.tween_property(overlay, "color", Color(0, 0, 0, 0.0), 0.16)
	tween.tween_callback(func(): overlay.queue_free())


# ─── HELPERS UI ──────────────────────────────────────────────
static func _make_label(text: String, C) -> Label:
	var lbl = Label.new(); lbl.text = text
	lbl.add_theme_font_size_override("font_size", 11); lbl.add_theme_color_override("font_color", C.COLOR_TEXT)
	return lbl

static func _make_input(placeholder: String, secret: bool, C) -> LineEdit:
	var input = LineEdit.new(); input.placeholder_text = placeholder; input.secret = secret
	input.custom_minimum_size = Vector2(0, 44); input.add_theme_font_size_override("font_size", 14)
	input.add_theme_color_override("font_color", C.COLOR_TEXT); input.add_theme_color_override("caret_color", C.COLOR_GOLD)
	_apply_input_style(input, C); return input

static func _make_primary_button(text: String, C) -> Button:
	var btn = Button.new(); btn.text = text; btn.custom_minimum_size = Vector2(0, 46)
	btn.add_theme_font_size_override("font_size", 15); btn.add_theme_color_override("font_color", C.COLOR_PANEL)
	var st = StyleBoxFlat.new(); st.bg_color = C.COLOR_GOLD
	st.corner_radius_top_left = 8; st.corner_radius_top_right = 8
	st.corner_radius_bottom_left = 8; st.corner_radius_bottom_right = 8
	st.shadow_color = Color(C.COLOR_GOLD.r, C.COLOR_GOLD.g, C.COLOR_GOLD.b, 0.2); st.shadow_size = 15; st.shadow_offset = Vector2(0, 4)
	var st_hov = st.duplicate(); st_hov.bg_color = C.COLOR_GOLD.lightened(0.1)
	var st_press = st.duplicate(); st_press.bg_color = C.COLOR_GOLD.darkened(0.1)
	btn.add_theme_stylebox_override("normal", st); btn.add_theme_stylebox_override("hover", st_hov); btn.add_theme_stylebox_override("pressed", st_press)
	return btn

static func _make_ghost_button(text: String, C) -> Button:
	var btn = Button.new(); btn.text = text; btn.custom_minimum_size = Vector2(0, 42)
	btn.add_theme_font_size_override("font_size", 13); btn.add_theme_color_override("font_color", C.COLOR_GOLD_DIM)
	var st = StyleBoxFlat.new(); st.bg_color = Color(0,0,0,0)
	st.border_color = Color(C.COLOR_GOLD_DIM.r, C.COLOR_GOLD_DIM.g, C.COLOR_GOLD_DIM.b, 0.4)
	st.border_width_left = 1; st.border_width_right = 1; st.border_width_top = 1; st.border_width_bottom = 1
	st.corner_radius_top_left = 8; st.corner_radius_top_right = 8; st.corner_radius_bottom_left = 8; st.corner_radius_bottom_right = 8
	var st_hov = st.duplicate(); st_hov.bg_color = Color(1,1,1,0.03)
	btn.add_theme_stylebox_override("normal", st); btn.add_theme_stylebox_override("hover", st_hov); return btn

static func _make_divider(C) -> Control:
	var hb = HBoxContainer.new()
	var lc = Color(C.COLOR_GOLD_DIM.r, C.COLOR_GOLD_DIM.g, C.COLOR_GOLD_DIM.b, 0.2)
	var l = ColorRect.new(); l.color = lc; l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.custom_minimum_size = Vector2(0,1); l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var lbl = Label.new(); lbl.text = "  o continuar sin cuenta  "
	lbl.add_theme_font_size_override("font_size", 11); lbl.add_theme_color_override("font_color", C.COLOR_TEXT_DIM)
	var r = ColorRect.new(); r.color = lc; r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	r.custom_minimum_size = Vector2(0,1); r.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hb.add_child(l); hb.add_child(lbl); hb.add_child(r); return hb

static func _apply_input_style(input: LineEdit, C) -> void:
	var st = StyleBoxFlat.new(); st.bg_color = C.COLOR_BG
	st.border_color = Color(C.COLOR_GOLD_DIM.r, C.COLOR_GOLD_DIM.g, C.COLOR_GOLD_DIM.b, 0.3)
	st.border_width_left = 1; st.border_width_right = 1; st.border_width_top = 1; st.border_width_bottom = 1
	st.corner_radius_top_left = 6; st.corner_radius_top_right = 6; st.corner_radius_bottom_left = 6; st.corner_radius_bottom_right = 6
	st.content_margin_left = 14
	var st_focus = st.duplicate(); st_focus.border_color = C.COLOR_GOLD
	input.add_theme_stylebox_override("normal", st); input.add_theme_stylebox_override("focus", st_focus)

static func _style_toggle(btn_login: Button, btn_register: Button, login_active: bool, C) -> void:
	var st_a = StyleBoxFlat.new(); st_a.bg_color = C.COLOR_GOLD
	st_a.corner_radius_top_left = 6; st_a.corner_radius_top_right = 6
	st_a.corner_radius_bottom_left = 6; st_a.corner_radius_bottom_right = 6
	var st_i = StyleBoxFlat.new(); st_i.bg_color = Color(0,0,0,0)
	st_i.border_color = Color(C.COLOR_GOLD_DIM.r, C.COLOR_GOLD_DIM.g, C.COLOR_GOLD_DIM.b, 0.4)
	st_i.border_width_left = 1; st_i.border_width_right = 1; st_i.border_width_top = 1; st_i.border_width_bottom = 1
	st_i.corner_radius_top_left = 6; st_i.corner_radius_top_right = 6; st_i.corner_radius_bottom_left = 6; st_i.corner_radius_bottom_right = 6
	if login_active:
		btn_login.add_theme_stylebox_override("normal", st_a); btn_login.add_theme_stylebox_override("hover", st_a)
		btn_login.add_theme_color_override("font_color", C.COLOR_PANEL)
		btn_register.add_theme_stylebox_override("normal", st_i); btn_register.add_theme_stylebox_override("hover", st_i)
		btn_register.add_theme_color_override("font_color", C.COLOR_GOLD_DIM)
	else:
		btn_register.add_theme_stylebox_override("normal", st_a); btn_register.add_theme_stylebox_override("hover", st_a)
		btn_register.add_theme_color_override("font_color", C.COLOR_PANEL)
		btn_login.add_theme_stylebox_override("normal", st_i); btn_login.add_theme_stylebox_override("hover", st_i)
		btn_login.add_theme_color_override("font_color", C.COLOR_GOLD_DIM)

static func _is_valid_email(email: String) -> bool:
	var at_pos = email.find("@"); if at_pos < 1: return false
	var domain = email.substr(at_pos + 1); return domain.contains(".") and domain.length() > 2

static func _set_status(lbl: Label, text: String, color: Color) -> void:
	if is_instance_valid(lbl): lbl.text = text; lbl.add_theme_color_override("font_color", color)
