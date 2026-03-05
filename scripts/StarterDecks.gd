extends Node

# ============================================================
# StarterDecks.gd — Autoload o static
# Mazos predefinidos + validación de deck
# ============================================================

static func fire() -> Array:
	var d = []
	for i in 4:  d.append("cyndaquil_1")
	for i in 3:  d.append("cyndaquil_2")
	for i in 3:  d.append("quilava_1")
	for i in 2:  d.append("quilava_2")
	for i in 2:  d.append("typhlosion_1")
	for i in 2:  d.append("typhlosion_2")
	for i in 2:  d.append("pichu")
	for i in 2:  d.append("pikachu")
	for i in 2:  d.append("magmar")
	for i in 2:  d.append("magby")
	for i in 4:  d.append("professor_elm")
	for i in 3:  d.append("bills_teleporter")
	for i in 3:  d.append("moo_moo_milk")
	for i in 2:  d.append("super_rod")
	for i in 2:  d.append("double_gust")
	for i in 2:  d.append("focus_band")
	for i in 2:  d.append("gold_berry")
	for i in 14: d.append("fire_energy")
	for i in 4:  d.append("lightning_energy")
	return d  # 60 cartas

static func water() -> Array:
	var d = []
	for i in 4:  d.append("totodile_1")
	for i in 3:  d.append("croconaw_1")
	for i in 2:  d.append("feraligatr_1")
	for i in 3:  d.append("slowpoke")
	for i in 2:  d.append("slowking")
	for i in 4:  d.append("horsea")
	for i in 4:  d.append("seadra")
	for i in 4:  d.append("mary")
	for i in 4:  d.append("professor_elm")
	for i in 4:  d.append("super_scoop_up")
	for i in 3:  d.append("moo_moo_milk")
	for i in 3:  d.append("time_capsule")
	for i in 20: d.append("water_energy")
	return d  # 60 cartas

static func grass() -> Array:
	var d = []
	for i in 4:  d.append("chikorita_1")
	for i in 3:  d.append("bayleef_1")
	for i in 2:  d.append("meganium_1")
	for i in 3:  d.append("hoppip")
	for i in 2:  d.append("skiploom")
	for i in 2:  d.append("jumpluff")
	for i in 4:  d.append("spinarak")
	for i in 4:  d.append("professor_elm")
	for i in 4:  d.append("sprout_tower")
	for i in 4:  d.append("berry")
	for i in 4:  d.append("pokemon_march")
	for i in 4:  d.append("bills_teleporter")
	for i in 20: d.append("grass_energy")
	return d  # 60 cartas

static func lightning() -> Array:
	var d = []
	for i in 4:  d.append("mareep")
	for i in 3:  d.append("flaaffy")
	for i in 2:  d.append("ampharos")
	for i in 3:  d.append("chinchou")
	for i in 2:  d.append("lanturn")
	for i in 4:  d.append("elekid")
	for i in 4:  d.append("pikachu")
	for i in 4:  d.append("professor_elm")
	for i in 4:  d.append("pokegear")
	for i in 4:  d.append("energy_charge")
	for i in 3:  d.append("double_gust")
	for i in 3:  d.append("super_rod")
	for i in 20: d.append("lightning_energy")
	return d  # 60 cartas

static func validate(deck: Array) -> Dictionary:
	if deck.size() != 60:
		return { "valid": false, "error": str(deck.size()) + "/60 cartas" }
	var species_counts: Dictionary = {}
	for id in deck:
		var data = CardDatabase.get_card(id)
		if data.is_empty():
			return { "valid": false, "error": "Carta desconocida: " + id }
		if data.get("type") != "ENERGY":
			var species = data.get("name", id).to_lower()
			species_counts[species] = species_counts.get(species, 0) + 1
			if species_counts[species] > 4:
				return { "valid": false, "error": "Máx 4 copias de " + data.get("name", id) }
	for id in deck:
		var c = CardDatabase.get_card(id)
		if c.get("type") == "POKEMON" and int(c.get("stage", 0)) == 0:
			return { "valid": true }
	return { "valid": false, "error": "Necesitas al menos 1 Pokémon básico" }

static func status_text(deck: Array, deck_name: String) -> String:
	var v = validate(deck)
	if v.valid:
		return "✓  Deck: " + deck_name + "  (" + str(deck.size()) + " cartas)"
	return "⚠  " + v.error
