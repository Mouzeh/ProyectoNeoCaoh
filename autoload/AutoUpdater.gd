extends Node

# ============================================================
# AutoUpdater.gd
# Colócalo en: autoload/AutoUpdater.gd
# Registrarlo en Project > Project Settings > Autoload
# ============================================================

const CURRENT_VERSION := "0.1.0"

# Cambia esto por tu usuario/repo de GitHub
const GITHUB_USER    := "Mouzeh"
const GITHUB_REPO    := "ProyectoNeoCaoh"

const VERSION_URL    := "https://raw.githubusercontent.com/{user}/{repo}/main/version.json"
const DOWNLOAD_BASE  := "https://github.com/{user}/{repo}/releases/download/{tag}/{file}"

signal update_available(latest_version: String, download_url: String)
signal update_not_needed()
signal update_error(message: String)
signal download_progress(percent: float)
signal update_ready_to_install(zip_path: String)

var _http_version : HTTPRequest
var _http_download: HTTPRequest
var _latest_version: String = ""
var _download_url:   String = ""
var _zip_save_path:  String = ""

# ----------------------------------------------------------
# INIT
# ----------------------------------------------------------
func _ready() -> void:
	_http_version = HTTPRequest.new()
	add_child(_http_version)
	_http_version.request_completed.connect(_on_version_check_completed)

	_http_download = HTTPRequest.new()
	add_child(_http_download)
	_http_download.request_completed.connect(_on_download_completed)
	_http_download.use_threads = true

# ----------------------------------------------------------
# PASO 1: Consultar version.json en GitHub
# ----------------------------------------------------------
func check_for_updates() -> void:
	var url = VERSION_URL.replace("{user}", GITHUB_USER).replace("{repo}", GITHUB_REPO)
	var err = _http_version.request(url)
	if err != OK:
		emit_signal("update_error", "No se pudo conectar al servidor de versiones.")

func _on_version_check_completed(result, response_code, _headers, body) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		emit_signal("update_error", "Error al consultar versión remota (código %d)" % response_code)
		return

	var json = JSON.new()
	var parse_err = json.parse(body.get_string_from_utf8())
	if parse_err != OK:
		emit_signal("update_error", "Error al leer version.json")
		return

	var data: Dictionary = json.get_data()
	_latest_version = data.get("version", "")

	if _latest_version == "" or _latest_version == CURRENT_VERSION:
		emit_signal("update_not_needed")
		return

	# Determinar plataforma y URL de descarga
	var platform_key := _get_platform_key()
	var downloads: Dictionary = data.get("downloads", {})

	if not downloads.has(platform_key):
		emit_signal("update_error", "No hay build disponible para tu plataforma (%s)" % platform_key)
		return

	_download_url = downloads[platform_key]
	emit_signal("update_available", _latest_version, _download_url)

# ----------------------------------------------------------
# PASO 2: Descargar el .zip
# ----------------------------------------------------------
func start_download() -> void:
	if _download_url == "":
		emit_signal("update_error", "URL de descarga no definida.")
		return

	_zip_save_path = OS.get_temp_dir().path_join("pokemon_tcg_update.zip")
	_http_download.download_file = _zip_save_path

	var err = _http_download.request(_download_url)
	if err != OK:
		emit_signal("update_error", "Error al iniciar descarga.")

func _process(_delta) -> void:
	if _http_download and _http_download.get_body_size() > 0:
		var downloaded := float(_http_download.get_downloaded_bytes())
		var total      := float(_http_download.get_body_size())
		emit_signal("download_progress", (downloaded / total) * 100.0)

func _on_download_completed(result, response_code, _headers, _body) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		emit_signal("update_error", "Error durante la descarga (código %d)" % response_code)
		return
	emit_signal("update_ready_to_install", _zip_save_path)

# ----------------------------------------------------------
# PASO 3: Extraer y reemplazar ejecutable
# ----------------------------------------------------------
func install_update(zip_path: String) -> void:
	var install_script := _write_install_script(zip_path)
	if install_script == "":
		emit_signal("update_error", "No se pudo crear el script de instalación.")
		return

	# Lanzar script externo y cerrar el juego
	var os_name := OS.get_name()
	if os_name == "Windows":
		OS.create_process("cmd.exe", ["/c", install_script])
	elif os_name == "macOS" or os_name == "Linux":
		OS.execute("chmod", ["+x", install_script])
		OS.create_process("bash", [install_script])

	get_tree().quit()

func _write_install_script(zip_path: String) -> String:
	var exe_dir  := OS.get_executable_path().get_base_dir()
	var os_name  := OS.get_name()

	if os_name == "Windows":
		var script_path := OS.get_temp_dir().path_join("pokemon_update.bat")
		var script := """@echo off
timeout /t 2 /nobreak > nul
cd /d "{exe_dir}"
powershell -command "Expand-Archive -Force '{zip}' '{exe_dir}'"
start "" "{exe_dir}\\PokemonTCG.exe"
del "%~f0"
""".format({"exe_dir": exe_dir, "zip": zip_path})
		_write_file(script_path, script)
		return script_path

	elif os_name == "macOS":
		var script_path := OS.get_temp_dir().path_join("pokemon_update.sh")
		var script := """#!/bin/bash
sleep 2
cd "{exe_dir}"
unzip -o "{zip}" -d "{exe_dir}"
chmod +x "{exe_dir}/PokemonTCG.app/Contents/MacOS/PokemonTCG"
open "{exe_dir}/PokemonTCG.app"
rm -- "$0"
""".format({"exe_dir": exe_dir, "zip": zip_path})
		_write_file(script_path, script)
		return script_path

	else: # Linux
		var script_path := OS.get_temp_dir().path_join("pokemon_update.sh")
		var script := """#!/bin/bash
sleep 2
cd "{exe_dir}"
unzip -o "{zip}" -d "{exe_dir}"
chmod +x "{exe_dir}/PokemonTCG"
"{exe_dir}/PokemonTCG" &
rm -- "$0"
""".format({"exe_dir": exe_dir, "zip": zip_path})
		_write_file(script_path, script)
		return script_path

	return ""

func _write_file(path: String, content: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f:
		f.store_string(content)
		f.close()

# ----------------------------------------------------------
# HELPERS
# ----------------------------------------------------------
func _get_platform_key() -> String:
	match OS.get_name():
		"Windows": return "windows"
		"macOS":   return "macos"
		_:         return "linux"

func get_current_version() -> String:
	return CURRENT_VERSION
