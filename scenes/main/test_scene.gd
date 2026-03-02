extends Node2D

func _ready() -> void:
	var test_cards = [
		"lugia",
		"typhlosion_1",
		"cyndaquil_1",
		"meganium_1",
		"pichu",
		"totodile_1",
		"feraligatr_1",
		"professor_elm",
		"fire_energy",
		"water_energy",
	]

	var start_x = 80
	var start_y = 120
	var spacing_x = 150
	var per_row = 5

	for i in range(test_cards.size()):
		var card = CardDatabase.create_card_instance(test_cards[i])
		var col = i % per_row
		var row = i / per_row
		card.position = Vector2(start_x + col * spacing_x, start_y + row * 200)
		add_child(card)

	print("TestScene: ", test_cards.size(), " cartas creadas")
