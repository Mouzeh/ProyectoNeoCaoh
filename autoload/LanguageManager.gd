extends Node

enum Language { EN, ES }

const SAVE_PATH = "user://settings.cfg"

var _current: Language = Language.EN

func _ready() -> void:
	_load_language()

func set_language(lang: Language) -> void:
	_current = lang
	_save_language()

func get_language() -> Language:
	return _current

func is_spanish() -> bool:
	return _current == Language.ES

func is_english() -> bool:
	return _current == Language.EN

func _save_language() -> void:
	var cfg = ConfigFile.new()
	cfg.set_value("settings", "language", _current)
	cfg.save(SAVE_PATH)

func _load_language() -> void:
	var cfg = ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		_current = cfg.get_value("settings", "language", Language.EN)

# ── Helper principal ─────────────────────────────────────────
# Úsalo en cualquier parte del juego:
#   var img = LanguageManager.get_card_image(CardDatabase.get_card("pichu"))
func get_card_image(card: Dictionary) -> String:
	if card.is_empty():
		return ""
	if is_spanish() and card.has("image_es"):
		if ResourceLoader.exists(card["image_es"]):
			return card["image_es"]
	return card.get("image", "")
