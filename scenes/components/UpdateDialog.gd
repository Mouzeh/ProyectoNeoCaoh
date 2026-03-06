extends CanvasLayer

# ============================================================
# UpdateDialog.gd
# Colócalo en: scenes/components/UpdateDialog.gd
# Es un CanvasLayer con UI encima de todo
# ============================================================

# Nodos (ajusta los NodePaths según tu escena .tscn)
@onready var panel          : Panel        = $Panel
@onready var lbl_title      : Label        = $Panel/VBox/Title
@onready var lbl_message    : Label        = $Panel/VBox/Message
@onready var progress_bar   : ProgressBar  = $Panel/VBox/ProgressBar
@onready var btn_update     : Button       = $Panel/VBox/BtnUpdate
@onready var btn_skip       : Button       = $Panel/VBox/BtnSkip
@onready var lbl_status     : Label        = $Panel/VBox/Status

func _ready() -> void:
	hide()
	panel.hide()

	# Conectar señales del AutoUpdater
	AutoUpdater.update_available.connect(_on_update_available)
	AutoUpdater.update_not_needed.connect(_on_no_update)
	AutoUpdater.update_error.connect(_on_error)
	AutoUpdater.download_progress.connect(_on_download_progress)
	AutoUpdater.update_ready_to_install.connect(_on_ready_to_install)

	btn_update.pressed.connect(_on_btn_update_pressed)
	btn_skip.pressed.connect(_on_btn_skip_pressed)

	# Iniciar verificación
	AutoUpdater.check_for_updates()

# ----------------------------------------------------------
# SEÑALES DEL UPDATER
# ----------------------------------------------------------
func _on_update_available(latest: String, _url: String) -> void:
	show()
	panel.show()
	lbl_title.text   = "🎮 ¡Nueva versión disponible!"
	lbl_message.text = "Versión actual:  %s\nNueva versión:   %s\n\nSe descargará e instalará automáticamente." % [
		AutoUpdater.get_current_version(), latest
	]
	progress_bar.hide()
	btn_update.show()
	btn_skip.show()
	lbl_status.text = ""

func _on_no_update() -> void:
	# Todo OK, no mostrar nada — continúa al juego normal
	pass

func _on_error(message: String) -> void:
	show()
	panel.show()
	lbl_title.text   = "⚠️ Error de actualización"
	lbl_message.text = message + "\n\nPuedes continuar jugando, pero puede haber incompatibilidades."
	progress_bar.hide()
	btn_update.hide()
	btn_skip.show()
	btn_skip.text    = "Continuar de todas formas"
	lbl_status.text  = ""

func _on_download_progress(percent: float) -> void:
	progress_bar.value = percent
	lbl_status.text    = "Descargando... %.0f%%" % percent

func _on_ready_to_install(zip_path: String) -> void:
	lbl_status.text  = "✅ Descarga completa. Instalando..."
	btn_update.hide()
	btn_skip.hide()
	progress_bar.value = 100.0
	await get_tree().create_timer(1.0).timeout
	AutoUpdater.install_update(zip_path)

# ----------------------------------------------------------
# BOTONES
# ----------------------------------------------------------
func _on_btn_update_pressed() -> void:
	btn_update.disabled = true
	btn_skip.disabled   = true
	progress_bar.show()
	progress_bar.value  = 0.0
	lbl_status.text     = "Iniciando descarga..."
	AutoUpdater.start_download()

func _on_btn_skip_pressed() -> void:
	hide()
	# Continúa al juego con versión desactualizada
