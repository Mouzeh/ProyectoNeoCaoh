extends Node

func _ready():
	# Instanciar una carta de prueba
	var card = CardDatabase.create_card_instance("cyndaquil")
	card.position = Vector2(400, 300)
	add_child(card)
	print("Carta creada: ", card.card_name)
