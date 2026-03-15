extends Node

# ============================================================
# SoundManager.gd  — Autoload (agrega en Project > Autoloads)
# ============================================================
const PATH          = "res://assets/sounds/"
const SETTINGS_PATH = "user://settings.cfg"

const SOUNDS = {
	"game_start":    "Sonido al iniciar el juego.mp3",
	"match_begin":   "sonido al empezar la partida.mp3",
	"my_turn":       "Turno Tuyo.mp3",
	"opp_turn":      "Turno Rival.mp3",
	"notification":  "notificación global.mp3",
	"error":         "sonido de error.mp3",
	"save":          "sonido de guardado.mp3",
	"chat":          "sonido de mensaje en chat.mp3",
	"victory":       "sonido de victoria.mp3",
	"purchase":      "Compra exitosa.mp3",
	"reward":        "Entrega de Recompensas.mp3",
	"room_created":  "creación de mesa.mp3",
	"nav_click":     "MenuClickNavbar.mp3",
	"attack":        "ataque resuelto.mp3",
	"shuffle":       "barajar.mp3",
	"energy":        "energia.mp3",
	"evolve":        "evolución.mp3",
	"pokemon_ko":    "pokemonko.mp3",
	"retreat":       "retiro.mp3",
	"draw":          "robo de cartas.mp3",
	"trainer":       "uso de trainers.mp3",
}

var _players: Dictionary = {}

func _ready() -> void:
	for key in SOUNDS.keys():
		var path = PATH + SOUNDS[key]
		if not ResourceLoader.exists(path):
			push_warning("SoundManager: no existe '%s'" % path)
			continue
		var player = AudioStreamPlayer.new()
		player.stream   = load(path)
		player.bus      = "SFX"
		player.autoplay = false
		add_child(player)
		_players[key] = player
	_load_volume_settings()

func _load_volume_settings() -> void:
	var cfg = ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK: return
	for bus_name in ["Music", "SFX"]:
		var bus = AudioServer.get_bus_index(bus_name)
		if bus >= 0 and cfg.has_section_key("audio", bus_name):
			AudioServer.set_bus_volume_db(bus, cfg.get_value("audio", bus_name))

func save_volume(bus_name: String, value_db: float) -> void:
	var cfg = ConfigFile.new()
	cfg.load(SETTINGS_PATH)
	cfg.set_value("audio", bus_name, value_db)
	cfg.save(SETTINGS_PATH)

func play(sound_key: String, volume_db: float = 0.0) -> void:
	if not _players.has(sound_key):
		push_warning("SoundManager: clave desconocida '%s'" % sound_key)
		return
	var p: AudioStreamPlayer = _players[sound_key]
	p.volume_db = volume_db
	p.stop()
	p.play()

func stop(sound_key: String) -> void:
	if _players.has(sound_key):
		_players[sound_key].stop()
