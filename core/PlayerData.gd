extends Node

var player_id: String = ""
var username: String = ""
var coins: int = 0
var battle_pass_level: int = 1
var battle_pass_xp: int = 0
var rank: String = "BRONZE"
var elo: int = 1000
var inventory: Dictionary = {}
var decks: Dictionary = {}
var active_deck_slot: int = 1

func load_from_server(data: Dictionary) -> void:
	player_id         = data.get("id", "")
	username          = data.get("username", "")
	coins             = data.get("coins", 0)
	battle_pass_level = data.get("bp_level", 1)
	battle_pass_xp    = data.get("bp_xp", 0)
	rank              = data.get("rank", "BRONZE")
	elo               = data.get("elo", 1000)
	inventory         = data.get("inventory", {})
	decks             = data.get("decks", {})
	print("PlayerData: Loaded player '", username, "'")

func get_active_deck() -> Array:
	return decks.get(str(active_deck_slot), [])

func has_card(card_id: String) -> bool:
	return inventory.get(card_id, 0) > 0

func get_card_count(card_id: String) -> int:
	return inventory.get(card_id, 0)

func spend_coins(amount: int) -> bool:
	if coins < amount:
		return false
	coins -= amount
	return true

func add_coins(amount: int) -> void:
	coins += amount
