extends Node

enum Language { EN, ES }

var _current: Language = Language.EN

func set_language(lang: Language) -> void:
	_current = lang

func get_language() -> Language:
	return _current

func is_spanish() -> bool:
	return _current == Language.ES

func is_english() -> bool:
	return _current == Language.EN

# ── Helper principal ─────────────────────────────────────────
# Úsalo en cualquier parte del juego:
#   var img = LanguageManager.get_card_image(CardDatabase.get_card("pichu"))
func get_card_image(card: Dictionary) -> String:
	if card.is_empty():
		return ""
	if is_spanish() and card.has("image_es"):
		return card["image_es"]
	return card.get("image", "")
