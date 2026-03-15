extends Node

var CARDS: Dictionary = {
	# ═══════════════════════════════════
	# RARAS HOLOGRÁFICAS (#1-19)
	# ═══════════════════════════════════
	"lc_alakazam": {
		"id": "lc_alakazam", "name": "Alakazam", "number": "1/110",
		"image": "res://assets/cards/Legendary Collection/lc_alakazam_001.jpg",
		"image_es": "res://assets/cards/Legendary Collection ES/lc_alakazam_ES_001.png",
		"type": "POKEMON", "pokemon_type": "PSYCHIC",
		"hp": 80, "stage": 2, "evolves_from": "kadabra",
		"retreat_cost": 3, "weakness": "PSYCHIC", "resistance": "",
		"rarity": "RARE_HOLO",
		"pokemon_power": {"name": "Damage Swap", "effect": "As often as you like during your turn (before your attack), you may move 1 damage counter from 1 of your Pokemon to another as long as you don't Knock Out that Pokemon. This power can't be used if Alakazam is affected by a Special Condition."},
		"attacks": [
			{"name": "Confuse Ray", "cost": {"PSYCHIC": 3}, "damage": 30, "effect": "Flip a coin. If heads, the Defending Pokemon is now Confused."},
		]
	},
	"lc_articuno": {
		"id": "lc_articuno", "name": "Articuno", "number": "2/110",
		"image": "res://assets/cards/Legendary Collection/lc_articuno_002.jpg",
		"image_es": "res://assets/cards/Legendary Collection ES/lc_articuno_ES_002.jpg",
		"type": "POKEMON", "pokemon_type": "WATER",
		"hp": 70, "stage": 0, "evolves_from": "",
		"retreat_cost": 2, "weakness": "", "resistance": "FIGHTING",
		"rarity": "RARE_HOLO",
		"pokemon_power": null,
		"attacks": [
			{"name": "Freeze Dry", "cost": {"WATER": 3}, "damage": 30, "effect": "Flip a coin. If heads, the Defending Pokemon is now Paralyzed."},
			{"name": "Blizzard", "cost": {"WATER": 4}, "damage": 50, "effect": "Flip a coin. If heads, this attack does 10 damage to each of your opponent's Benched Pokemon. If tails, this attack does 10 damage to each of your own Benched Pokemon. (Don't apply Weakness and Resistance for Benched Pokemon.)"},
		]
	},
	"lc_charizard": {
		"id": "lc_charizard", "name": "Charizard", "number": "3/110",
		"image": "res://assets/cards/Legendary Collection/lc_charizard_003.jpg",
		"image_es": "res://assets/cards/Legendary Collection ES/lc_charizard_ES_003.jpg",
		"type": "POKEMON", "pokemon_type": "FIRE",
		"hp": 120, "stage": 2, "evolves_from": "charmeleon",
		"retreat_cost": 3, "weakness": "WATER", "resistance": "FIGHTING",
		"rarity": "RARE_HOLO",
		"pokemon_power": {"name": "Energy Burn", "effect": "As often as you like during your turn (before your attack), you may turn all Energy attached to Charizard into Fire Energy for the rest of the turn. This power can't be used if Charizard is affected by a Special Condition."},
		"attacks": [
			{"name": "Fire Spin", "cost": {"FIRE": 4}, "damage": 100, "effect": "Discard 2 Energy cards attached to Charizard or this attack does nothing."},
		]
	},
	"lc_dark-blastoise": {
		"id": "lc_dark-blastoise", "name": "Dark Blastoise", "number": "4/110",
		"image": "res://assets/cards/Legendary Collection/lc_dark-blastoise_004.jpg",
		"image_es": "res://assets/cards/Legendary Collection ES/lc_dark-blastoise_ES_004.jpg",
		"type": "POKEMON", "pokemon_type": "WATER",
		"hp": 70, "stage": 2, "evolves_from": "dark wartortle",
		"retreat_cost": 2, "weakness": "LIGHTNING", "resistance": "",
		"rarity": "RARE_HOLO",
		"pokemon_power": null,
		"attacks": [
			{"name": "Hydrocannon", "cost": {"WATER": 2}, "damage": 30, "effect": "Does 30 damage plus 20 more damage for each extra Water Energy attached."},
			{"name": "Rocket Tackle", "cost": {"WATER": 1, "COLORLESS": 2}, "damage": 40, "effect": "Dark Blastoise does 10 damage to itself. Flip a coin. If heads, prevent all damage done to Dark Blastoise during your opponent's next turn. (Any other effects of attacks still happen.)"},
		]
	},
	"lc_dark-dragonite": {
		"id": "lc_dark-dragonite", "name": "Dark Dragonite", "number": "5/110",
		"image": "res://assets/cards/Legendary Collection/lc_dark-dragonite_005.jpg",
		"image_es": "res://assets/cards/Legendary Collection ES/lc_dark-dragonite_ES_005.jpg",
		"type": "POKEMON", "pokemon_type": "COLORLESS",
		"hp": 70, "stage": 2, "evolves_from": "dark dragonair",
		"retreat_cost": 2, "weakness": "", "resistance": "FIGHTING",
		"rarity": "RARE_HOLO",
		"pokemon_power": {"name": "Summon Minions", "effect": "When you play Dark Dragonite from your hand, search your deck for up to 2 Basic Pokemon and put them onto your Bench. Shuffle your deck afterward."},
		"attacks": [
			{"name": "Giant Tail", "cost": {"COLORLESS": 4}, "damage": 70, "effect": "Flip a coin. If tails, this attack does nothing."},
		]
	},
	"lc_dark-persian": {
		"id": "lc_dark-persian", "name": "Dark Persian", "number": "6/110",
		"image": "res://assets/cards/Legendary Collection/lc_dark-persian_006.jpg",
		"image_es": "res://assets/cards/Legendary Collection ES/lc_dark-persian_ES_006.jpg",
		"type": "POKEMON", "pokemon_type": "COLORLESS",
		"hp": 60, "stage": 1, "evolves_from": "meowth",
		"retreat_cost": 0, "weakness": "FIGHTING", "resistance": "PSYCHIC",
		"rarity": "RARE_HOLO",
		"pokemon_power": null,
		"attacks": [
			{"name": "Fascinate", "cost": {"COLORLESS": 1}, "damage": 0, "effect": "Flip a coin. If heads, choose 1 of your opponent's Benched Pokemon and switch it with the Defending Pokemon. This attack can't be used if your opponent has no Benched Pokemon."},
			{"name": "Poison Claws", "cost": {"COLORLESS": 2}, "damage": 10, "effect": "Flip a coin. If heads, the Defending Pokemon is now Poisoned."},
		]
	},
	"lc_dark-raichu": {
		"id": "lc_dark-raichu", "name": "Dark Raichu", "number": "7/110",
		"image": "res://assets/cards/Legendary Collection/lc_dark-raichu_007.jpg",
		"image_es": "res://assets/cards/Legendary Collection ES/lc_dark-raichu_ES_007.jpg",
		"type": "POKEMON", "pokemon_type": "LIGHTNING",
		"hp": 70, "stage": 1, "evolves_from": "pikachu",
		"retreat_cost": 1, "weakness": "FIGHTING", "resistance": "FIGHTING",
		"rarity": "RARE_HOLO",
		"pokemon_power": null,
		"attacks": [
			{"name": "Surprise Thunder", "cost": {"LIGHTNING": 3}, "damage": 30, "effect": "Flip a coin. If heads, flip another coin. If the second coin is heads, this attack does 20 damage to each of your opponent's Benched Pokemon. If the second coin is tails, this attack does 10 damage to each of your opponent's Benched Pokemon. (Don't apply Weakness and Resistance for Benched Pokemon.)"},
		]
	},
	"lc_dark-slowbro": {
		"id": "lc_dark-slowbro", "name": "Dark Slowbro", "number": "8/110",
		"image": "res://assets/cards/Legendary Collection/lc_dark-slowbro_008.jpg",
		"image_es": "res://assets/cards/Legendary Collection ES/lc_dark-slowbro_ES_008.jpg",
		"type": "POKEMON", "pokemon_type": "PSYCHIC",
		"hp": 60, "stage": 1, "evolves_from": "slowpoke",
		"retreat_cost": 2, "weakness": "PSYCHIC", "resistance": "",
		"rarity": "RARE_HOLO",
		"pokemon_power": {"name": "Reel In", "effect": "When you play Dark Slowbro from your hand, choose up to 3 Basic Pokemon and/or Evolution cards from your discard pile and put them into your hand."},
		"attacks": [
			{"name": "Fickle Attack", "cost": {"PSYCHIC": 2}, "damage": 40, "effect": "Flip a coin. If tails, this attack does nothing."},
		]
	},
	"lc_dark-vaporeon": {
		"id": "lc_dark-vaporeon", "name": "Dark Vaporeon", "number": "9/110",
		"image": "res://assets/cards/Legendary Collection/lc_dark-vaporeon_009.jpg",
		"image_es": "res://assets/cards/Legendary Collection ES/lc_dark-vaporeon_ES_009.jpg",
		"type": "POKEMON", "pokemon_type": "WATER",
		"hp": 60, "stage": 1, "evolves_from": "eevee",
		"retreat_cost": 1, "weakness": "LIGHTNING", "resistance": "",
		"rarity": "RARE_HOLO",
		"pokemon_power": null,
		"attacks": [
			{"name": "Bite", "cost": {"COLORLESS": 3}, "damage": 30, "effect": ""},
			{"name": "Whirlpool", "cost": {"WATER": 2, "COLORLESS": 1}, "damage": 20, "effect": "If the Defending Pokemon has any Energy cards attached to it, choose 1 of them and discard it."},
		]
	},
	"lc_flareon": {
		"id": "lc_flareon", "name": "Flareon", "number": "10/110",
		"image": "res://assets/cards/Legendary Collection/lc_flareon_010.jpg",
		"image_es": "res://assets/cards/Legendary Collection ES/lc_flareon_ES_010.jpg",
		"type": "POKEMON", "pokemon_type": "FIRE",
		"hp": 70, "stage": 1, "evolves_from": "eevee",
		"retreat_cost": 1, "weakness": "WATER", "resistance": "",
		"rarity": "RARE_HOLO",
		"pokemon_power": null,
		"attacks": [
			{"name": "Quick Attack", "cost": {"COLORLESS": 2}, "damage": 0, "effect": "Flip a coin. If heads, this attack does 10 damage plus 20 more damage; if tails, this attack does 10 damage."},
			{"name": "Flamethrower", "cost": {"FIRE": 2, "COLORLESS": 2}, "damage": 60, "effect": "Discard 1 Fire Energy attached to Flareon."},
		]
	},
	"lc_gengar": {
		"id": "lc_gengar", "name": "Gengar", "number": "11/110",
		"image": "res://assets/cards/Legendary Collection/lc_gengar_011.jpg",
		"image_es": "res://assets/cards/Legendary Collection ES/lc_gengar_ES_011.jpg",
		"type": "POKEMON", "pokemon_type": "PSYCHIC",
		"hp": 80, "stage": 2, "evolves_from": "haunter",
		"retreat_cost": 1, "weakness": "", "resistance": "FIGHTING",
		"rarity": "RARE_HOLO",
		"pokemon_power": {"name": "Curse", "effect": "Once during your turn (before your attack), you may move 1 damage counter from 1 of your opponent's Pokemon to another (even if it would Knock Out the other Pokemon). This power can't be used if Gengar is affected by a Special Condition."},
		"attacks": [
			{"name": "Dark Mind", "cost": {"PSYCHIC": 3}, "damage": 30, "effect": "If your opponent has any Benched Pokemon, choose 1 of them and this attack does 10 damage to it. (Don't apply Weakness and Resistance for Benched Pokemon.)"},
		]
	},
	"lc_gyarados": {
		"id": "lc_gyarados", "name": "Gyarados", "number": "12/110",
		"image": "res://assets/cards/Legendary Collection/lc_gyarados_012.jpg",
		"image_es": "res://assets/cards/Legendary Collection ES/lc_gyarados_ES_012.jpg",
		"type": "POKEMON", "pokemon_type": "WATER",
		"hp": 100, "stage": 1, "evolves_from": "magikarp",
		"retreat_cost": 3, "weakness": "GRASS", "resistance": "FIGHTING",
		"rarity": "RARE_HOLO",
		"pokemon_power": null,
		"attacks": [
			{"name": "Dragon Rage", "cost": {"WATER": 3}, "damage": 50, "effect": ""},
			{"name": "Bubblebeam", "cost": {"WATER": 4}, "damage": 40, "effect": "Flip a coin. If heads, the Defending Pokemon is now Paralyzed."},
		]
	},
	"lc_hitmonlee": {
		"id": "lc_hitmonlee", "name": "Hitmonlee", "number": "13/110",
		"image": "res://assets/cards/Legendary Collection/lc_hitmonlee_013.jpg",
		"image_es": "res://assets/cards/Legendary Collection ES/lc_hitmonlee_ES_013.jpg",
		"type": "POKEMON", "pokemon_type": "FIGHTING",
		"hp": 60, "stage": 0, "evolves_from": "",
		"retreat_cost": 1, "weakness": "FIGHTING", "resistance": "",
		"rarity": "RARE_HOLO",
		"pokemon_power": null,
		"attacks": [
			{"name": "Stretch Kick", "cost": {"FIGHTING": 2}, "damage": 20, "effect": "Choose 1 of your opponent's Benched Pokemon, and this attack does 20 damage to it. (Don't apply Weakness and Resistance for Benched Pokemon.)"},
			{"name": "High Jump Kick", "cost": {"FIGHTING": 3}, "damage": 50, "effect": ""},
		]
	},
	"lc_jolteon": {
		"id": "lc_jolteon", "name": "Jolteon", "number": "14/110",
		"image": "res://assets/cards/Legendary Collection/lc_jolteon_014.jpg",
		"image_es": "res://assets/cards/Legendary Collection ES/lc_jolteon_ES_014.jpg",
		"type": "POKEMON", "pokemon_type": "LIGHTNING",
		"hp": 70, "stage": 1, "evolves_from": "eevee",
		"retreat_cost": 1, "weakness": "FIGHTING", "resistance": "",
		"rarity": "RARE_HOLO",
		"pokemon_power": null,
		"attacks": [
			{"name": "Quick Attack", "cost": {"COLORLESS": 2}, "damage": 0, "effect": "Flip a coin. If heads, this attack does 10 damage plus 20 more damage; if tails, this attack does 10 damage."},
			{"name": "Pin Missile", "cost": {"LIGHTNING": 2, "COLORLESS": 1}, "damage": 0, "effect": "Flip 4 coins. This attack does 20 damage times the number of heads."},
		]
	},
	"lc_machamp": {
		"id": "lc_machamp", "name": "Machamp", "number": "15/110",
		"image": "res://assets/cards/Legendary Collection/lc_machamp_015.jpg",
		"image_es": "res://assets/cards/Legendary Collection ES/lc_machamp_ES_015.jpg",
		"type": "POKEMON", "pokemon_type": "FIGHTING",
		"hp": 100, "stage": 2, "evolves_from": "machoke",
		"retreat_cost": 3, "weakness": "PSYCHIC", "resistance": "",
		"rarity": "RARE_HOLO",
		"pokemon_power": {"name": "Strikes Back", "effect": "Whenever your opponent's attack damages Machamp (even if Machamp is Knocked Out), this power does 10 damage to the attacking Pokemon. (Don't apply Weakness and Resistance.) This power can't be used if Machamp is already affected by a Special Condition when your opponent attacks."},
		"attacks": [
			{"name": "Seismic Toss", "cost": {"FIGHTING": 3, "COLORLESS": 1}, "damage": 60, "effect": ""},
		]
	},
	"lc_muk": {
		"id": "lc_muk", "name": "Muk", "number": "16/110",
		"image": "res://assets/cards/Legendary Collection/lc_muk_016.jpg",
		"image_es": "res://assets/cards/Legendary Collection ES/lc_muk_ES_016.jpg",
		"type": "POKEMON", "pokemon_type": "GRASS",
		"hp": 70, "stage": 1, "evolves_from": "grimer",
		"retreat_cost": 2, "weakness": "PSYCHIC", "resistance": "",
		"rarity": "RARE_HOLO",
		"pokemon_power": {"name": "Toxic Gas", "effect": "Ignore all Pokemon Powers other than Toxic Gases. This power stops working while Muk is affected by a Special Condition."},
		"attacks": [
			{"name": "Sludge", "cost": {"GRASS": 3}, "damage": 30, "effect": "Flip a coin. If heads, the Defending Pokemon is now Poisoned."},
		]
	},
	"lc_ninetales": {
		"id": "lc_ninetales", "name": "Ninetales", "number": "17/110",
		"image": "res://assets/cards/Legendary Collection/lc_ninetales_017.jpg",
		"image_es": "res://assets/cards/Legendary Collection ES/lc_ninetales_ES_017.jpg",
		"type": "POKEMON", "pokemon_type": "FIRE",
		"hp": 80, "stage": 1, "evolves_from": "vulpix",
		"retreat_cost": 1, "weakness": "WATER", "resistance": "",
		"rarity": "RARE_HOLO",
		"pokemon_power": null,
		"attacks": [
			{"name": "Lure", "cost": {"COLORLESS": 2}, "damage": 0, "effect": "If your opponent has any Benched Pokemon, choose 1 of them and switch it with the Defending Pokemon."},
			{"name": "Fire Blast", "cost": {"FIRE": 4}, "damage": 80, "effect": "Discard 1 Fire Energy attached to Ninetales."},
		]
	},
	"lc_venusaur": {
		"id": "lc_venusaur", "name": "Venusaur", "number": "18/110",
		"image": "res://assets/cards/Legendary Collection/lc_venusaur_018.jpg",
		"image_es": "res://assets/cards/Legendary Collection ES/lc_venusaur_ES_018.jpg",
		"type": "POKEMON", "pokemon_type": "GRASS",
		"hp": 100, "stage": 2, "evolves_from": "ivysaur",
		"retreat_cost": 2, "weakness": "FIRE", "resistance": "",
		"rarity": "RARE_HOLO",
		"pokemon_power": {"name": "Energy Trans", "effect": "As often as you like during your turn (before your attack), you may take 1 Grass Energy card attached to 1 of your Pokemon and attach it to a different one. This power can't be used if Venusaur is affected by a Special Condition."},
		"attacks": [
			{"name": "Solarbeam", "cost": {"GRASS": 4}, "damage": 60, "effect": ""},
		]
	},
	"lc_zapdos": {
		"id": "lc_zapdos", "name": "Zapdos", "number": "19/110",
		"image": "res://assets/cards/Legendary Collection/lc_zapdos_019.jpg",
		"image_es": "res://assets/cards/Legendary Collection ES/lc_zapdos_ES_019.jpg",
		"type": "POKEMON", "pokemon_type": "LIGHTNING",
		"hp": 90, "stage": 0, "evolves_from": "",
		"retreat_cost": 3, "weakness": "", "resistance": "FIGHTING",
		"rarity": "RARE_HOLO",
		"pokemon_power": null,
		"attacks": [
			{"name": "Thunder", "cost": {"LIGHTNING": 3, "COLORLESS": 1}, "damage": 60, "effect": "Flip a coin. If tails, Zapdos does 30 damage to itself."},
			{"name": "Thunderbolt", "cost": {"LIGHTNING": 4}, "damage": 100, "effect": "Discard all Energy cards attached to Zapdos or this attack does nothing."},
		]
	},
	# ═══════════════════════════════════
	# RARAS (#20-35)
	# ═══════════════════════════════════
	"lc_beedrill": {
		"id": "lc_beedrill", "name": "Beedrill", "number": "20/110",
		"image": "res://assets/cards/Legendary Collection/lc_beedrill_020.jpg",
		"image_es": "res://assets/cards/Legendary Collection ES/lc_beedrill_ES_020.jpg",
		"type": "POKEMON", "pokemon_type": "GRASS",
		"hp": 80, "stage": 2, "evolves_from": "kakuna",
		"retreat_cost": 0, "weakness": "FIRE", "resistance": "FIGHTING",
		"rarity": "RARE",
		"pokemon_power": null,
		"attacks": [
			{"name": "Twineedle", "cost": {"COLORLESS": 3}, "damage": 30, "effect": "Flip 2 coins. This attack does 30 damage times the number of heads."},
			{"name": "Poison Sting", "cost": {"GRASS": 3}, "damage": 40, "effect": "Flip a coin. If heads, the Defending Pokemon is now Poisoned."},
		]
	},
	"lc_butterfree": {
		"id": "lc_butterfree", "name": "Butterfree", "number": "21/110",
		"image": "res://assets/cards/Legendary Collection/lc_butterfree_021.jpg",
		"image_es": "res://assets/cards/Legendary Collection ES/lc_butterfree_ES_021.jpg",
		"type": "POKEMON", "pokemon_type": "GRASS",
		"hp": 70, "stage": 2, "evolves_from": "metapod",
		"retreat_cost": 0, "weakness": "FIRE", "resistance": "FIGHTING",
		"rarity": "RARE",
		"pokemon_power": null,
		"attacks": [
			{"name": "Whirlwind", "cost": {"COLORLESS": 2}, "damage": 20, "effect": "Your opponent switches the Defending Pokemon with 1 of his or her Benched Pokemon, if any."},
			{"name": "Mega Drain", "cost": {"GRASS": 4}, "damage": 40, "effect": "Remove a number of damage counters from Butterfree equal to half the damage done to the Defending Pokemon (after applying Weakness and Resistance)."},
		]
	},
	"lc_electrode": {
		"id": "lc_electrode", "name": "Electrode", "number": "22/110",
		"image": "res://assets/cards/Legendary Collection/lc_electrode_022.jpg",
		"image_es": "res://assets/cards/Legendary Collection ES/lc_electrode_ES_022.jpg",
		"type": "POKEMON", "pokemon_type": "LIGHTNING",
		"hp": 90, "stage": 1, "evolves_from": "voltorb",
		"retreat_cost": 1, "weakness": "FIGHTING", "resistance": "",
		"rarity": "RARE",
		"pokemon_power": null,
		"attacks": [
			{"name": "Tackle", "cost": {"COLORLESS": 2}, "damage": 20, "effect": ""},
			{"name": "Chain Lightning", "cost": {"LIGHTNING": 3}, "damage": 20, "effect": "If the Defending Pokemon isn't Colorless, this attack does 10 damage to each Benched Pokemon of the same type as the Defending Pokemon (including your own). (Don't apply Weakness and Resistance for Benched Pokemon.)"},
		]
	},
	"lc_exeggutor": {
		"id": "lc_exeggutor", "name": "Exeggutor", "number": "23/110",
		"image": "res://assets/cards/Legendary Collection/lc_exeggutor_023.jpg",
		"image_es": "res://assets/cards/Legendary Collection ES/lc_exeggutor_ES_023.jpg",
		"type": "POKEMON", "pokemon_type": "GRASS",
		"hp": 80, "stage": 1, "evolves_from": "exeggcute",
		"retreat_cost": 3, "weakness": "FIRE", "resistance": "",
		"rarity": "RARE",
		"pokemon_power": null,
		"attacks": [
			{"name": "Teleport", "cost": {"PSYCHIC": 1}, "damage": 0, "effect": "Switch Exeggutor with 1 of your Benched Pokemon."},
			{"name": "Big Eggsplosion", "cost": {"COLORLESS": 1}, "damage": 20, "effect": "Flip a number of coins equal to the number of Energy attached to Exeggutor. This attack does 20 damage times the number of heads."},
		]
	},
	"lc_golem": {
		"id": "lc_golem", "name": "Golem", "number": "24/110",
		"image": "res://assets/cards/Legendary Collection/lc_golem_024.jpg",
		"image_es": "res://assets/cards/Legendary Collection ES/lc_golem_ES_024.jpg",
		"type": "POKEMON", "pokemon_type": "FIGHTING",
		"hp": 80, "stage": 2, "evolves_from": "graveler",
		"retreat_cost": 4, "weakness": "GRASS", "resistance": "",
		"rarity": "RARE",
		"pokemon_power": null,
		"attacks": [
			{"name": "Avalanche", "cost": {"FIGHTING": 3, "COLORLESS": 1}, "damage": 60, "effect": ""},
			{"name": "Selfdestruct", "cost": {"FIGHTING": 4}, "damage": 100, "effect": "Does 20 damage to each Pokemon on each player's Bench. (Don't apply Weakness and Resistance for Benched Pokemon.) Golem does 100 damage to itself."},
		]
	},
	"lc_hypno": {
		"id": "lc_hypno", "name": "Hypno", "number": "25/110",
		"image": "res://assets/cards/Legendary Collection/lc_hypno_025.jpg",
		"image_es": "res://assets/cards/Legendary Collection ES/lc_hypno_ES_025.jpg",
		"type": "POKEMON", "pokemon_type": "PSYCHIC",
		"hp": 90, "stage": 1, "evolves_from": "drowzee",
		"retreat_cost": 2, "weakness": "PSYCHIC", "resistance": "",
		"rarity": "RARE",
		"pokemon_power": null,
		"attacks": [
			{"name": "Prophecy", "cost": {"PSYCHIC": 1}, "damage": 0, "effect": "Look at up to 3 cards from the top of either player's deck and rearrange them as you like."},
			{"name": "Dark Mind", "cost": {"PSYCHIC": 3}, "damage": 30, "effect": "If your opponent has any Benched Pokemon, choose 1 of them and this attack does 10 damage to it. (Don't apply Weakness and Resistance for Benched Pokemon.)"},
		]
	},
	"lc_jynx": {
		"id": "lc_jynx", "name": "Jynx", "number": "26/110",
		"image": "res://assets/cards/Legendary Collection/lc_jynx_026.jpg",
		"image_es": "res://assets/cards/Legendary Collection ES/lc_jynx_ES_026.jpg",
		"type": "POKEMON", "pokemon_type": "PSYCHIC",
		"hp": 70, "stage": 0, "evolves_from": "",
		"retreat_cost": 2, "weakness": "PSYCHIC", "resistance": "",
		"rarity": "RARE",
		"pokemon_power": null,
		"attacks": [
			{"name": "Doubleslap", "cost": {"PSYCHIC": 1}, "damage": 10, "effect": "Flip 2 coins. This attack does 10 damage times the number of heads."},
			{"name": "Meditate", "cost": {"PSYCHIC": 2, "COLORLESS": 1}, "damage": 20, "effect": "Does 20 damage plus 10 more damage for each damage counter on the Defending Pokemon."},
		]
	},
	"lc_kabutops": {
		"id": "lc_kabutops", "name": "Kabutops", "number": "27/110",
		"image": "res://assets/cards/Legendary Collection/lc_kabutops_027.jpg",
		"image_es": "res://assets/cards/Legendary Collection ES/lc_kabutops_ES_027.jpg",
		"type": "POKEMON", "pokemon_type": "FIGHTING",
		"hp": 60, "stage": 2, "evolves_from": "kabuto",
		"retreat_cost": 1, "weakness": "GRASS", "resistance": "",
		"rarity": "RARE",
		"pokemon_power": null,
		"attacks": [
			{"name": "Sharp Sickle", "cost": {"FIGHTING": 2}, "damage": 30, "effect": ""},
			{"name": "Absorb", "cost": {"FIGHTING": 4}, "damage": 40, "effect": "Remove a number of damage counters from Kabutops equal to half the damage done to the Defending Pokemon (after applying Weakness and Resistance) (rounded up to the nearest 10)."},
		]
	},
	"lc_magneton": {
		"id": "lc_magneton", "name": "Magneton", "number": "28/110",
		"image": "res://assets/cards/Legendary Collection/lc_magneton_028.jpg",
		"image_es": "res://assets/cards/Legendary Collection ES/lc_magneton_ES_028.jpg",
		"type": "POKEMON", "pokemon_type": "LIGHTNING",
		"hp": 80, "stage": 1, "evolves_from": "magnemite",
		"retreat_cost": 2, "weakness": "LIGHTNING", "resistance": "",
		"rarity": "RARE",
		"pokemon_power": null,
		"attacks": [
			{"name": "Sonicboom", "cost": {"LIGHTNING": 1, "COLORLESS": 1}, "damage": 20, "effect": "Don't apply Weakness and Resistance for this attack."},
			{"name": "Selfdestruct", "cost": {"LIGHTNING": 4}, "damage": 100, "effect": "Does 20 damage to each Pokemon on each player's Bench. (Don't apply Weakness and Resistance for Benched Pokemon.) Magneton does 100 damage to itself."},
		]
	},
	"lc_mewtwo": {
		"id": "lc_mewtwo", "name": "Mewtwo", "number": "29/110",
		"image": "res://assets/cards/Legendary Collection/lc_mewtwo_029.jpg",
		"image_es": "res://assets/cards/Legendary Collection ES/lc_mewtwo_ES_029.jpg",
		"type": "POKEMON", "pokemon_type": "PSYCHIC",
		"hp": 60, "stage": 0, "evolves_from": "",
		"retreat_cost": 2, "weakness": "PSYCHIC", "resistance": "",
		"rarity": "RARE",
		"pokemon_power": null,
		"attacks": [
			{"name": "Energy Control", "cost": {"PSYCHIC": 1}, "damage": 0, "effect": "Flip a coin. If heads, choose a basic Energy card attached to 1 of your opponent's Pokemon and attach it to another of your opponent's Pokemon of your choice."},
			{"name": "Telekinesis", "cost": {"PSYCHIC": 3}, "damage": 0, "effect": "Choose 1 of your opponent's Pokemon. This attack does 30 damage to that Pokemon. Don't apply Weakness and Resistance for this attack."},
		]
	},
	"lc_moltres": {
		"id": "lc_moltres", "name": "Moltres", "number": "30/110",
		"image": "res://assets/cards/Legendary Collection/lc_moltres_030.jpg",
		"image_es": "res://assets/cards/Legendary Collection ES/lc_moltres_ES_030.jpg",
		"type": "POKEMON", "pokemon_type": "FIRE",
		"hp": 70, "stage": 0, "evolves_from": "",
		"retreat_cost": 2, "weakness": "", "resistance": "FIGHTING",
		"rarity": "RARE",
		"pokemon_power": null,
		"attacks": [
			{"name": "Wildfire", "cost": {"FIRE": 1}, "damage": 0, "effect": "You may discard any number of Fire Energy cards attached to Moltres when you use this attack. If you do, discard that many cards from the top of your opponent's deck."},
			{"name": "Dive Bomb", "cost": {"FIRE": 4}, "damage": 80, "effect": "Flip a coin. If tails, this attack does nothing."},
		]
	},
	"lc_nidoking": {
		"id": "lc_nidoking", "name": "Nidoking", "number": "31/110",
		"image": "res://assets/cards/Legendary Collection/lc_nidoking_031.jpg",
		"image_es": "res://assets/cards/Legendary Collection ES/lc_nidoking_ES_031.jpg",
		"type": "POKEMON", "pokemon_type": "GRASS",
		"hp": 90, "stage": 2, "evolves_from": "nidorino",
		"retreat_cost": 3, "weakness": "PSYCHIC", "resistance": "",
		"rarity": "RARE",
		"pokemon_power": null,
		"attacks": [
			{"name": "Thrash", "cost": {"GRASS": 1, "COLORLESS": 2}, "damage": 30, "effect": "Flip a coin. If heads, this attack does 30 damage plus 10 more damage; if tails, this attack does 30 damage and Nidoking does 10 damage to itself."},
			{"name": "Toxic", "cost": {"GRASS": 1}, "damage": 20, "effect": "The Defending Pokemon is now Poisoned. It now takes 20 Poison damage instead of 10 after each player's turn (even if it was already Poisoned)."},
		]
	},
	"lc_nidoqueen": {
		"id": "lc_nidoqueen", "name": "Nidoqueen", "number": "32/110",
		"image": "res://assets/cards/Legendary Collection/lc_nidoqueen_032.jpg",
		"image_es": "res://assets/cards/Legendary Collection ES/lc_nidoqueen_ES_032.jpg",
		"type": "POKEMON", "pokemon_type": "GRASS",
		"hp": 90, "stage": 2, "evolves_from": "nidorina",
		"retreat_cost": 3, "weakness": "PSYCHIC", "resistance": "",
		"rarity": "RARE",
		"pokemon_power": null,
		"attacks": [
			{"name": "Boyfriends", "cost": {"GRASS": 1, "COLORLESS": 1}, "damage": 20, "effect": "Does 20 damage plus 20 more damage for each Nidoking you have in play."},
			{"name": "Mega Punch", "cost": {"GRASS": 2, "COLORLESS": 2}, "damage": 50, "effect": ""},
		]
	},
	"lc_pidgeot": {
		"id": "lc_pidgeot", "name": "Pidgeot", "number": "33/110",
		"image": "res://assets/cards/Legendary Collection/lc_pidgeot_033.jpg",
		"image_es": "res://assets/cards/Legendary Collection ES/lc_pidgeot_ES_033.jpg",
		"type": "POKEMON", "pokemon_type": "COLORLESS",
		"hp": 80, "stage": 2, "evolves_from": "pidgeotto",
		"retreat_cost": 0, "weakness": "LIGHTNING", "resistance": "FIGHTING",
		"rarity": "RARE",
		"pokemon_power": null,
		"attacks": [
			{"name": "Wing Attack", "cost": {"COLORLESS": 2}, "damage": 20, "effect": ""},
			{"name": "Hurricane", "cost": {"COLORLESS": 3}, "damage": 30, "effect": "Unless this attack Knocks Out the Defending Pokemon, return the Defending Pokemon and all cards attached to it to your opponent's hand."},
		]
	},
	"lc_pidgeotto": {
		"id": "lc_pidgeotto", "name": "Pidgeotto", "number": "34/110",
		"image": "res://assets/cards/Legendary Collection/lc_pidgeotto_034.jpg",
		"image_es": "res://assets/cards/Legendary Collection ES/lc_pidgeotto_ES_034.jpg",
		"type": "POKEMON", "pokemon_type": "COLORLESS",
		"hp": 60, "stage": 1, "evolves_from": "pidgey",
		"retreat_cost": 1, "weakness": "LIGHTNING", "resistance": "FIGHTING",
		"rarity": "RARE",
		"pokemon_power": null,
		"attacks": [
			{"name": "Whirlwind", "cost": {"COLORLESS": 2}, "damage": 20, "effect": "Your opponent switches the Defending Pokemon with 1 of his or her Benched Pokemon, if any."},
			{"name": "Mirror Move", "cost": {"COLORLESS": 3}, "damage": 0, "effect": "If Pidgeotto was attacked last turn, do the final result of that attack on Pidgeotto to the Defending Pokemon."},
		]
	},
	"lc_rhydon": {
		"id": "lc_rhydon", "name": "Rhydon", "number": "35/110",
		"image": "res://assets/cards/Legendary Collection/lc_rhydon_035.jpg",
		"image_es": "res://assets/cards/Legendary Collection ES/lc_rhydon_ES_035.jpg",
		"type": "POKEMON", "pokemon_type": "FIGHTING",
		"hp": 100, "stage": 1, "evolves_from": "rhyhorn",
		"retreat_cost": 3, "weakness": "GRASS", "resistance": "LIGHTNING",
		"rarity": "RARE",
		"pokemon_power": null,
		"attacks": [
			{"name": "Horn Attack", "cost": {"FIGHTING": 1, "COLORLESS": 2}, "damage": 30, "effect": ""},
			{"name": "Ram", "cost": {"FIGHTING": 4}, "damage": 50, "effect": "Rhydon does 20 damage to itself. Your opponent switches the Defending Pokemon with 1 of his or her Benched Pokemon, if any."},
		]
	},
	# ═══════════════════════════════════
	# POCO COMUNES (#36-66)
	# ═══════════════════════════════════
	"lc_arcanine": {
		"id": "lc_arcanine", "name": "Arcanine", "number": "36/110",
		"image": "res://assets/cards/Legendary Collection/lc_arcanine_036.jpg",
		"image_es": "res://assets/cards/Legendary Collection ES/lc_arcanine_ES_036.jpg",
		"type": "POKEMON", "pokemon_type": "FIRE",
		"hp": 100, "stage": 1, "evolves_from": "growlithe",
		"retreat_cost": 3, "weakness": "WATER", "resistance": "",
		"rarity": "UNCOMMON",
		"pokemon_power": null,
		"attacks": [
			{"name": "Flamethrower", "cost": {"FIRE": 2, "COLORLESS": 1}, "damage": 50, "effect": "Discard 1 Fire Energy attached to Arcanine."},
			{"name": "Take Down", "cost": {"FIRE": 2, "COLORLESS": 2}, "damage": 80, "effect": "Arcanine does 30 damage to itself."},
		]
	},
	"lc_charmeleon": {
		"id": "lc_charmeleon", "name": "Charmeleon", "number": "37/110",
		"image": "res://assets/cards/Legendary Collection/lc_charmeleon_037.jpg",
		"image_es": "res://assets/cards/Legendary Collection ES/lc_charmeleon_ES_037.jpg",
		"type": "POKEMON", "pokemon_type": "FIRE",
		"hp": 80, "stage": 1, "evolves_from": "charmander",
		"retreat_cost": 1, "weakness": "WATER", "resistance": "",
		"rarity": "UNCOMMON",
		"pokemon_power": null,
		"attacks": [
			{"name": "Slash", "cost": {"COLORLESS": 3}, "damage": 30, "effect": ""},
			{"name": "Flamethrower", "cost": {"FIRE": 2, "COLORLESS": 1}, "damage": 50, "effect": "Discard 1 Fire Energy attached to Charmeleon."},
		]
	},
	"lc_dark-dragonair": {
		"id": "lc_dark-dragonair", "name": "Dark Dragonair", "number": "38/110",
		"image": "res://assets/cards/Legendary Collection/lc_dark-dragonair_038.jpg",
		"image_es": "res://assets/cards/Legendary Collection ES/lc_dark-dragonair_ES_038.jpg",
		"type": "POKEMON", "pokemon_type": "COLORLESS",
		"hp": 60, "stage": 1, "evolves_from": "dratini",
		"retreat_cost": 2, "weakness": "", "resistance": "PSYCHIC",
		"rarity": "UNCOMMON",
		"pokemon_power": {"name": "Evolutionary Light", "effect": "Once during your turn (before your attack), you may search your deck for an Evolution card. Show it to your opponent and put it into your hand. Shuffle your deck afterward. This power can't be used if Dark Dragonair is affected by a Special Condition."},
		"attacks": [
			{"name": "Tail Strike", "cost": {"COLORLESS": 3}, "damage": 20, "effect": "Flip a coin. If heads, this attack does 20 damage plus 20 more damage; if tails, this attack does 20 damage."},
		]
	},
	"lc_dark-wartortle": {
		"id": "lc_dark-wartortle", "name": "Dark Wartortle", "number": "39/110",
		"image": "res://assets/cards/Legendary Collection/lc_dark-wartortle_039.jpg",
		"image_es": "res://assets/cards/Legendary Collection ES/lc_dark-wartortle_ES_039.jpg",
		"type": "POKEMON", "pokemon_type": "WATER",
		"hp": 60, "stage": 1, "evolves_from": "squirtle",
		"retreat_cost": 1, "weakness": "LIGHTNING", "resistance": "",
		"rarity": "UNCOMMON",
		"pokemon_power": null,
		"attacks": [
			{"name": "Doubleslap", "cost": {"WATER": 1}, "damage": 10, "effect": "Flip 2 coins. This attack does 10 damage times the number of heads."},
			{"name": "Mirror Shell", "cost": {"WATER": 1, "COLORLESS": 1}, "damage": 0, "effect": "If an attack does damage to Dark Wartortle during your opponent's next turn (even if Dark Wartortle is Knocked Out), Dark Wartortle does an equal amount of damage to the Defending Pokemon."},
		]
	},
	"lc_dewgong": {
		"id": "lc_dewgong", "name": "Dewgong", "number": "40/110",
		"image": "res://assets/cards/Legendary Collection/lc_dewgong_040.jpg",
		"image_es": "res://assets/cards/Legendary Collection ES/lc_dewgong_ES_040.jpg",
		"type": "POKEMON", "pokemon_type": "WATER",
		"hp": 80, "stage": 1, "evolves_from": "seel",
		"retreat_cost": 3, "weakness": "LIGHTNING", "resistance": "",
		"rarity": "UNCOMMON",
		"pokemon_power": null,
		"attacks": [
			{"name": "Aurora Beam", "cost": {"WATER": 2, "COLORLESS": 1}, "damage": 50, "effect": ""},
			{"name": "Ice Beam", "cost": {"WATER": 2, "COLORLESS": 2}, "damage": 30, "effect": "Flip a coin. If heads, the Defending Pokemon is now Paralyzed."},
		]
	},
	"lc_dodrio": {
		"id": "lc_dodrio", "name": "Dodrio", "number": "41/110",
		"image": "res://assets/cards/Legendary Collection/lc_dodrio_041.jpg",
		"image_es": "res://assets/cards/Legendary Collection ES/lc_dodrio_ES_041.jpg",
		"type": "POKEMON", "pokemon_type": "COLORLESS",
		"hp": 70, "stage": 1, "evolves_from": "doduo",
		"retreat_cost": 0, "weakness": "LIGHTNING", "resistance": "FIGHTING",
		"rarity": "UNCOMMON",
		"pokemon_power": {"name": "Retreat Aid", "effect": "As long as Dodrio is Benched, pay 1 Colorless Energy less to retreat your Active Pokemon."},
		"attacks": [
			{"name": "Rage", "cost": {"COLORLESS": 3}, "damage": 10, "effect": "Does 10 damage plus 10 more damage for each damage counter on Dodrio."},
		]
	},
	"lc_fearow": {
		"id": "lc_fearow", "name": "Fearow", "number": "42/110",
		"image": "res://assets/cards/Legendary Collection/lc_fearow_042.jpg",
		"image_es": "res://assets/cards/Legendary Collection ES/lc_fearow_ES_042.jpg",
		"type": "POKEMON", "pokemon_type": "COLORLESS",
		"hp": 70, "stage": 1, "evolves_from": "spearow",
		"retreat_cost": 0, "weakness": "LIGHTNING", "resistance": "FIGHTING",
		"rarity": "UNCOMMON",
		"pokemon_power": null,
		"attacks": [
			{"name": "Agility", "cost": {"COLORLESS": 3}, "damage": 20, "effect": "Flip a coin. If heads, during your opponent's next turn, prevent all effects of attacks, including damage, done to Fearow."},
			{"name": "Drill Peck", "cost": {"COLORLESS": 4}, "damage": 40, "effect": ""},
		]
	},
	"lc_golduck": {
		"id": "lc_golduck", "name": "Golduck", "number": "43/110",
		"image": "res://assets/cards/Legendary Collection/lc_golduck_043.jpg",
		"image_es": "res://assets/cards/Legendary Collection ES/lc_golduck_ES_043.jpg",
		"type": "POKEMON", "pokemon_type": "WATER",
		"hp": 70, "stage": 1, "evolves_from": "psyduck",
		"retreat_cost": 1, "weakness": "LIGHTNING", "resistance": "",
		"rarity": "UNCOMMON",
		"pokemon_power": null,
		"attacks": [
			{"name": "Psyshock", "cost": {"PSYCHIC": 1}, "damage": 10, "effect": "Flip a coin. If heads, the Defending Pokemon is now Paralyzed."},
			{"name": "Hyper Beam", "cost": {"WATER": 2, "COLORLESS": 1}, "damage": 20, "effect": "If the Defending Pokemon has any Energy cards attached to it, choose 1 of them and discard it."},
		]
	},
	"lc_graveler": {
		"id": "lc_graveler", "name": "Graveler", "number": "44/110",
		"image": "res://assets/cards/Legendary Collection/lc_graveler_044.jpg",
		"image_es": "res://assets/cards/Legendary Collection ES/lc_graveler_ES_044.jpg",
		"type": "POKEMON", "pokemon_type": "FIGHTING",
		"hp": 60, "stage": 1, "evolves_from": "geodude",
		"retreat_cost": 2, "weakness": "GRASS", "resistance": "",
		"rarity": "UNCOMMON",
		"pokemon_power": null,
		"attacks": [
			{"name": "Harden", "cost": {"FIGHTING": 2}, "damage": 0, "effect": "During your opponent's next turn, whenever 30 or less damage is done to Graveler (after applying Weakness and Resistance), prevent that damage."},
			{"name": "Rock Throw", "cost": {"FIGHTING": 2, "COLORLESS": 1}, "damage": 40, "effect": ""},
		]
	},
	"lc_growlithe": {
		"id": "lc_growlithe", "name": "Growlithe", "number": "45/110",
		"image": "res://assets/cards/Legendary Collection/lc_growlithe_045.jpg",
		"image_es": "res://assets/cards/Legendary Collection ES/lc_growlithe_ES_045.jpg",
		"type": "POKEMON", "pokemon_type": "FIRE",
		"hp": 60, "stage": 0, "evolves_from": "",
		"retreat_cost": 1, "weakness": "WATER", "resistance": "",
		"rarity": "UNCOMMON",
		"pokemon_power": null,
		"attacks": [
			{"name": "Flare", "cost": {"FIRE": 1, "COLORLESS": 1}, "damage": 20, "effect": ""},
		]
	},
	"lc_haunter": {
		"id": "lc_haunter", "name": "Haunter", "number": "46/110",
		"image": "res://assets/cards/Legendary Collection/lc_haunter_046.jpg",
		"image_es": "res://assets/cards/Legendary Collection ES/lc_haunter_ES_046.jpg",
		"type": "POKEMON", "pokemon_type": "PSYCHIC",
		"hp": 50, "stage": 1, "evolves_from": "gastly",
		"retreat_cost": 0, "weakness": "", "resistance": "FIGHTING",
		"rarity": "UNCOMMON",
		"pokemon_power": {"name": "Transparency", "effect": "Whenever an attack does anything to Haunter, flip a coin. If heads, prevent all effects of that attack, including damage, done to Haunter. This power stops working while Haunter is affected by a Special Condition."},
		"attacks": [
			{"name": "Nightmare", "cost": {"PSYCHIC": 1, "COLORLESS": 1}, "damage": 10, "effect": "The Defending Pokemon is now Asleep."},
		]
	},
	"lc_ivysaur": {
		"id": "lc_ivysaur", "name": "Ivysaur", "number": "47/110",
		"image": "res://assets/cards/Legendary Collection/lc_ivysaur_047.jpg",
		"image_es": "res://assets/cards/Legendary Collection ES/lc_ivysaur_ES_047.jpg",
		"type": "POKEMON", "pokemon_type": "GRASS",
		"hp": 60, "stage": 1, "evolves_from": "bulbasaur",
		"retreat_cost": 1, "weakness": "FIRE", "resistance": "",
		"rarity": "UNCOMMON",
		"pokemon_power": null,
		"attacks": [
			{"name": "Vine Whip", "cost": {"GRASS": 1, "COLORLESS": 2}, "damage": 30, "effect": ""},
			{"name": "Poisonpowder", "cost": {"GRASS": 3}, "damage": 20, "effect": "The Defending Pokemon is now Poisoned."},
		]
	},
	"lc_kabuto": {
		"id": "lc_kabuto", "name": "Kabuto", "number": "48/110",
		"image": "res://assets/cards/Legendary Collection/lc_kabuto_048.jpg",
		"image_es": "res://assets/cards/Legendary Collection ES/lc_kabuto_ES_048.jpg",
		"type": "POKEMON", "pokemon_type": "FIGHTING",
		"hp": 30, "stage": 1, "evolves_from": "mysterious fossil",
		"retreat_cost": 1, "weakness": "GRASS", "resistance": "",
		"rarity": "UNCOMMON",
		"pokemon_power": null,
		"attacks": [
			{"name": "Scratch", "cost": {"COLORLESS": 1}, "damage": 10, "effect": ""},
		]
	},
	"lc_kadabra": {
		"id": "lc_kadabra", "name": "Kadabra", "number": "49/110",
		"image": "res://assets/cards/Legendary Collection/lc_kadabra_049.jpg",
		"image_es": "res://assets/cards/Legendary Collection ES/lc_kadabra_ES_049.jpg",
		"type": "POKEMON", "pokemon_type": "PSYCHIC",
		"hp": 60, "stage": 1, "evolves_from": "abra",
		"retreat_cost": 3, "weakness": "PSYCHIC", "resistance": "",
		"rarity": "UNCOMMON",
		"pokemon_power": null,
		"attacks": [
			{"name": "Recover", "cost": {"PSYCHIC": 2}, "damage": 0, "effect": "Discard 1 Psychic Energy attached to Kadabra or this attack does nothing. Remove all damage counters from Kadabra."},
			{"name": "Super Psy", "cost": {"PSYCHIC": 2, "COLORLESS": 1}, "damage": 50, "effect": ""},
		]
	},
	"lc_kakuna": {
		"id": "lc_kakuna", "name": "Kakuna", "number": "50/110",
		"image": "res://assets/cards/Legendary Collection/lc_kakuna_050.jpg",
		"image_es": "res://assets/cards/Legendary Collection ES/lc_kakuna_ES_050.jpg",
		"type": "POKEMON", "pokemon_type": "GRASS",
		"hp": 80, "stage": 1, "evolves_from": "weedle",
		"retreat_cost": 2, "weakness": "FIRE", "resistance": "",
		"rarity": "UNCOMMON",
		"pokemon_power": null,
		"attacks": [
			{"name": "Stiffen", "cost": {"COLORLESS": 2}, "damage": 0, "effect": "Flip a coin. If heads, prevent all damage done to Kakuna during your opponent's next turn."},
			{"name": "Poisonpowder", "cost": {"GRASS": 2}, "damage": 20, "effect": "Flip a coin. If heads, the Defending Pokemon is now Poisoned."},
		]
	},
	"lc_machoke": {
		"id": "lc_machoke", "name": "Machoke", "number": "51/110",
		"image": "res://assets/cards/Legendary Collection/lc_machoke_051.jpg",
		"image_es": "res://assets/cards/Legendary Collection ES/lc_machoke_ES_051.jpg",
		"type": "POKEMON", "pokemon_type": "FIGHTING",
		"hp": 80, "stage": 1, "evolves_from": "machop",
		"retreat_cost": 3, "weakness": "PSYCHIC", "resistance": "",
		"rarity": "UNCOMMON",
		"pokemon_power": null,
		"attacks": [
			{"name": "Karate Chop", "cost": {"FIGHTING": 2, "COLORLESS": 1}, "damage": 50, "effect": "Does 50 damage minus 10 damage for each damage counter on Machoke."},
			{"name": "Submission", "cost": {"FIGHTING": 2, "COLORLESS": 2}, "damage": 60, "effect": "Machoke does 20 damage to itself."},
		]
	},
	"lc_magikarp": {
		"id": "lc_magikarp", "name": "Magikarp", "number": "52/110",
		"image": "res://assets/cards/Legendary Collection/lc_magikarp_052.jpg",
		"image_es": "res://assets/cards/Legendary Collection ES/lc_magikarp_ES_052.jpg",
		"type": "POKEMON", "pokemon_type": "WATER",
		"hp": 30, "stage": 0, "evolves_from": "",
		"retreat_cost": 1, "weakness": "LIGHTNING", "resistance": "",
		"rarity": "UNCOMMON",
		"pokemon_power": null,
		"attacks": [
			{"name": "Tackle", "cost": {"COLORLESS": 1}, "damage": 10, "effect": ""},
			{"name": "Flail", "cost": {"WATER": 1}, "damage": 10, "effect": "Does 10 damage times the number of damage counters on Magikarp."},
		]
	},
	"lc_meowth": {
		"id": "lc_meowth", "name": "Meowth", "number": "53/110",
		"image": "res://assets/cards/Legendary Collection/lc_meowth_053.jpg",
		"image_es": "res://assets/cards/Legendary Collection ES/lc_meowth_ES_053.jpg",
		"type": "POKEMON", "pokemon_type": "COLORLESS",
		"hp": 50, "stage": 0, "evolves_from": "",
		"retreat_cost": 1, "weakness": "FIGHTING", "resistance": "PSYCHIC",
		"rarity": "UNCOMMON",
		"pokemon_power": null,
		"attacks": [
			{"name": "Pay Day", "cost": {"COLORLESS": 2}, "damage": 10, "effect": "Flip a coin. If heads, draw a card."},
		]
	},
	"lc_metapod": {
		"id": "lc_metapod", "name": "Metapod", "number": "54/110",
		"image": "res://assets/cards/Legendary Collection/lc_metapod_054.jpg",
		"image_es": "res://assets/cards/Legendary Collection ES/lc_metapod_ES_054.jpg",
		"type": "POKEMON", "pokemon_type": "GRASS",
		"hp": 70, "stage": 1, "evolves_from": "caterpie",
		"retreat_cost": 2, "weakness": "FIRE", "resistance": "",
		"rarity": "UNCOMMON",
		"pokemon_power": null,
		"attacks": [
			{"name": "Stiffen", "cost": {"COLORLESS": 2}, "damage": 0, "effect": "Flip a coin. If heads, prevent all damage done to Metapod during your opponent's next turn."},
			{"name": "Stun Spore", "cost": {"GRASS": 2}, "damage": 20, "effect": "Flip a coin. If heads, the Defending Pokemon is now Paralyzed."},
		]
	},
	"lc_nidorina": {
		"id": "lc_nidorina", "name": "Nidorina", "number": "55/110",
		"image": "res://assets/cards/Legendary Collection/lc_nidorina_055.jpg",
		"image_es": "res://assets/cards/Legendary Collection ES/lc_nidorina_ES_055.jpg",
		"type": "POKEMON", "pokemon_type": "GRASS",
		"hp": 70, "stage": 1, "evolves_from": "nidoran female",
		"retreat_cost": 1, "weakness": "PSYCHIC", "resistance": "",
		"rarity": "UNCOMMON",
		"pokemon_power": null,
		"attacks": [
			{"name": "Supersonic", "cost": {"GRASS": 1}, "damage": 0, "effect": "Flip a coin. If heads, the Defending Pokemon is now Confused."},
			{"name": "Double Kick", "cost": {"GRASS": 1, "COLORLESS": 2}, "damage": 30, "effect": "Flip 2 coins. This attack does 30 damage times the number of heads."},
		]
	},
	"lc_nidorino": {
		"id": "lc_nidorino", "name": "Nidorino", "number": "56/110",
		"image": "res://assets/cards/Legendary Collection/lc_nidorino_056.jpg",
		"image_es": "res://assets/cards/Legendary Collection ES/lc_nidorino_ES_056.jpg",
		"type": "POKEMON", "pokemon_type": "GRASS",
		"hp": 60, "stage": 1, "evolves_from": "nidoran male",
		"retreat_cost": 1, "weakness": "PSYCHIC", "resistance": "",
		"rarity": "UNCOMMON",
		"pokemon_power": null,
		"attacks": [
			{"name": "Double Kick", "cost": {"GRASS": 1, "COLORLESS": 2}, "damage": 30, "effect": "Flip 2 coins. This attack does 30 damage times the number of heads."},
			{"name": "Horn Drill", "cost": {"GRASS": 2, "COLORLESS": 2}, "damage": 50, "effect": ""},
		]
	},
	"lc_omanyte": {
		"id": "lc_omanyte", "name": "Omanyte", "number": "57/110",
		"image": "res://assets/cards/Legendary Collection/lc_omanyte_057.jpg",
		"image_es": "res://assets/cards/Legendary Collection ES/lc_omanyte_ES_057.jpg",
		"type": "POKEMON", "pokemon_type": "WATER",
		"hp": 40, "stage": 1, "evolves_from": "mysterious fossil",
		"retreat_cost": 1, "weakness": "GRASS", "resistance": "",
		"rarity": "UNCOMMON",
		"pokemon_power": {"name": "Clairvoyance", "effect": "Your opponent plays with his or her hand face up. This power stops working while Omanyte is affected by a Special Condition."},
		"attacks": [
			{"name": "Water Gun", "cost": {"WATER": 1}, "damage": 10, "effect": "Does 10 damage plus 10 more damage for each extra Water Energy attached."},
		]
	},
	"lc_omastar": {
		"id": "lc_omastar", "name": "Omastar", "number": "58/110",
		"image": "res://assets/cards/Legendary Collection/lc_omastar_058.jpg",
		"image_es": "res://assets/cards/Legendary Collection ES/lc_omastar_ES_058.jpg",
		"type": "POKEMON", "pokemon_type": "WATER",
		"hp": 70, "stage": 2, "evolves_from": "omanyte",
		"retreat_cost": 1, "weakness": "GRASS", "resistance": "",
		"rarity": "UNCOMMON",
		"pokemon_power": null,
		"attacks": [
			{"name": "Water Gun", "cost": {"WATER": 1, "COLORLESS": 1}, "damage": 20, "effect": "Does 20 damage plus 10 more damage for each extra Water Energy attached."},
			{"name": "Spike Cannon", "cost": {"WATER": 2}, "damage": 30, "effect": "Flip 2 coins. This attack does 30 damage times the number of heads."},
		]
	},
	"lc_primeape": {
		"id": "lc_primeape", "name": "Primeape", "number": "59/110",
		"image": "res://assets/cards/Legendary Collection/lc_primeape_059.jpg",
		"image_es": "res://assets/cards/Legendary Collection ES/lc_primeape_ES_059.jpg",
		"type": "POKEMON", "pokemon_type": "FIGHTING",
		"hp": 70, "stage": 1, "evolves_from": "mankey",
		"retreat_cost": 1, "weakness": "PSYCHIC", "resistance": "",
		"rarity": "UNCOMMON",
		"pokemon_power": null,
		"attacks": [
			{"name": "Fury Swipes", "cost": {"FIGHTING": 2}, "damage": 20, "effect": "Flip 3 coins. This attack does 20 damage times the number of heads."},
			{"name": "Tantrum", "cost": {"FIGHTING": 2, "COLORLESS": 1}, "damage": 50, "effect": "Flip a coin. If tails, Primeape is now Confused (after doing damage)."},
		]
	},
	"lc_rapidash": {
		"id": "lc_rapidash", "name": "Rapidash", "number": "60/110",
		"image": "res://assets/cards/Legendary Collection/lc_rapidash_060.jpg",
		"image_es": "res://assets/cards/Legendary Collection ES/lc_rapidash_ES_060.jpg",
		"type": "POKEMON", "pokemon_type": "FIRE",
		"hp": 70, "stage": 1, "evolves_from": "ponyta",
		"retreat_cost": 0, "weakness": "WATER", "resistance": "",
		"rarity": "UNCOMMON",
		"pokemon_power": null,
		"attacks": [
			{"name": "Stomp", "cost": {"COLORLESS": 1}, "damage": 20, "effect": "Flip a coin. If heads, this attack does 20 damage plus 10 more damage; if tails, this attack does 20 damage."},
			{"name": "Agility", "cost": {"FIRE": 2, "COLORLESS": 1}, "damage": 30, "effect": "Flip a coin. If heads, during your opponent's next turn, prevent all effects of attacks, including damage, done to Rapidash."},
		]
	},
	"lc_raticate": {
		"id": "lc_raticate", "name": "Raticate", "number": "61/110",
		"image": "res://assets/cards/Legendary Collection/lc_raticate_061.jpg",
		"image_es": "res://assets/cards/Legendary Collection ES/lc_raticate_ES_061.jpg",
		"type": "POKEMON", "pokemon_type": "COLORLESS",
		"hp": 60, "stage": 1, "evolves_from": "rattata",
		"retreat_cost": 1, "weakness": "FIGHTING", "resistance": "PSYCHIC",
		"rarity": "UNCOMMON",
		"pokemon_power": null,
		"attacks": [
			{"name": "Bite", "cost": {"COLORLESS": 1}, "damage": 20, "effect": ""},
			{"name": "Super Fang", "cost": {"COLORLESS": 3}, "damage": 0, "effect": "Does damage to the Defending Pokemon equal to half the Defending Pokemon's remaining HP (rounded up to the nearest 10)."},
		]
	},
	"lc_sandslash": {
		"id": "lc_sandslash", "name": "Sandslash", "number": "62/110",
		"image": "res://assets/cards/Legendary Collection/lc_sandslash_062.jpg",
		"image_es": "res://assets/cards/Legendary Collection ES/lc_sandslash_ES_062.jpg",
		"type": "POKEMON", "pokemon_type": "FIGHTING",
		"hp": 70, "stage": 1, "evolves_from": "sandshrew",
		"retreat_cost": 1, "weakness": "GRASS", "resistance": "LIGHTNING",
		"rarity": "UNCOMMON",
		"pokemon_power": null,
		"attacks": [
			{"name": "Slash", "cost": {"COLORLESS": 2}, "damage": 20, "effect": ""},
			{"name": "Fury Swipes", "cost": {"FIGHTING": 2}, "damage": 20, "effect": "Flip 3 coins. This attack does 20 damage times the number of heads."},
		]
	},
	"lc_seadra": {
		"id": "lc_seadra", "name": "Seadra", "number": "63/110",
		"image": "res://assets/cards/Legendary Collection/lc_seadra_063.jpg",
		"image_es": "res://assets/cards/Legendary Collection ES/lc_seadra_ES_063.jpg",
		"type": "POKEMON", "pokemon_type": "WATER",
		"hp": 60, "stage": 1, "evolves_from": "horsea",
		"retreat_cost": 1, "weakness": "LIGHTNING", "resistance": "",
		"rarity": "UNCOMMON",
		"pokemon_power": null,
		"attacks": [
			{"name": "Water Gun", "cost": {"WATER": 1, "COLORLESS": 1}, "damage": 20, "effect": "Does 20 damage plus 10 more damage for each extra Water Energy attached."},
			{"name": "Agility", "cost": {"WATER": 1, "COLORLESS": 2}, "damage": 20, "effect": "Flip a coin. If heads, during your opponent's next turn, prevent all effects of attacks, including damage, done to Seadra."},
		]
	},
	"lc_snorlax": {
		"id": "lc_snorlax", "name": "Snorlax", "number": "64/110",
		"image": "res://assets/cards/Legendary Collection/lc_snorlax_064.jpg",
		"image_es": "res://assets/cards/Legendary Collection ES/lc_snorlax_ES_064.jpg",
		"type": "POKEMON", "pokemon_type": "COLORLESS",
		"hp": 90, "stage": 0, "evolves_from": "",
		"retreat_cost": 4, "weakness": "FIGHTING", "resistance": "PSYCHIC",
		"rarity": "UNCOMMON",
		"pokemon_power": {"name": "Thick Skinned", "effect": "Snorlax can't become Asleep, Confused, Paralyzed, Poisoned, or Burned. This power stops working while Snorlax is affected by a Special Condition."},
		"attacks": [
			{"name": "Body Slam", "cost": {"COLORLESS": 4}, "damage": 30, "effect": "Flip a coin. If heads, the Defending Pokemon is now Paralyzed."},
		]
	},
	"lc_tauros": {
		"id": "lc_tauros", "name": "Tauros", "number": "65/110",
		"image": "res://assets/cards/Legendary Collection/lc_tauros_065.jpg",
		"image_es": "res://assets/cards/Legendary Collection ES/lc_tauros_ES_065.jpg",
		"type": "POKEMON", "pokemon_type": "COLORLESS",
		"hp": 60, "stage": 0, "evolves_from": "",
		"retreat_cost": 2, "weakness": "FIGHTING", "resistance": "PSYCHIC",
		"rarity": "UNCOMMON",
		"pokemon_power": null,
		"attacks": [
			{"name": "Stomp", "cost": {"COLORLESS": 2}, "damage": 20, "effect": "Flip a coin. If heads, this attack does 20 damage plus 10 more damage; if tails, this attack does 20 damage."},
			{"name": "Rampage", "cost": {"COLORLESS": 3}, "damage": 20, "effect": "Does 20 damage plus 10 more damage for each damage counter on Tauros. Flip a coin. If tails, Tauros is now Confused (after doing damage)."},
		]
	},
	"lc_tentacruel": {
		"id": "lc_tentacruel", "name": "Tentacruel", "number": "66/110",
		"image": "res://assets/cards/Legendary Collection/lc_tentacruel_066.jpg",
		"image_es": "res://assets/cards/Legendary Collection ES/lc_tentacruel_ES_066.jpg",
		"type": "POKEMON", "pokemon_type": "WATER",
		"hp": 60, "stage": 1, "evolves_from": "tentacool",
		"retreat_cost": 0, "weakness": "LIGHTNING", "resistance": "",
		"rarity": "UNCOMMON",
		"pokemon_power": null,
		"attacks": [
			{"name": "Supersonic", "cost": {"WATER": 1}, "damage": 0, "effect": "Flip a coin. If heads, the Defending Pokemon is now Confused."},
			{"name": "Jellyfish Sting", "cost": {"WATER": 2}, "damage": 10, "effect": "The Defending Pokemon is now Poisoned."},
		]
	},
	# ═══════════════════════════════════
	# COMUNES (#67-99)
	# ═══════════════════════════════════
	"lc_abra": {
		"id": "lc_abra", "name": "Abra", "number": "67/110",
		"image": "res://assets/cards/Legendary Collection/lc_abra_067.jpg",
		"image_es": "res://assets/cards/Legendary Collection ES/lc_abra_ES_067.jpg",
		"type": "POKEMON", "pokemon_type": "PSYCHIC",
		"hp": 30, "stage": 0, "evolves_from": "",
		"retreat_cost": 0, "weakness": "PSYCHIC", "resistance": "",
		"rarity": "COMMON",
		"pokemon_power": null,
		"attacks": [
			{"name": "Psyshock", "cost": {"PSYCHIC": 1}, "damage": 10, "effect": "Flip a coin. If heads, the Defending Pokemon is now Paralyzed."},
		]
	},
	"lc_bulbasaur": {
		"id": "lc_bulbasaur", "name": "Bulbasaur", "number": "68/110",
		"image": "res://assets/cards/Legendary Collection/lc_bulbasaur_068.jpg",
		"image_es": "res://assets/cards/Legendary Collection ES/lc_bulbasaur_ES_068.jpg",
		"type": "POKEMON", "pokemon_type": "GRASS",
		"hp": 40, "stage": 0, "evolves_from": "",
		"retreat_cost": 1, "weakness": "FIRE", "resistance": "",
		"rarity": "COMMON",
		"pokemon_power": null,
		"attacks": [
			{"name": "Leech Seed", "cost": {"GRASS": 2}, "damage": 20, "effect": "Unless all damage from this attack is prevented, you may remove 1 damage counter from Bulbasaur."},
		]
	},
	"lc_caterpie": {
		"id": "lc_caterpie", "name": "Caterpie", "number": "69/110",
		"image": "res://assets/cards/Legendary Collection/lc_caterpie_069.jpg",
		"image_es": "res://assets/cards/Legendary Collection ES/lc_caterpie_ES_069.jpg",
		"type": "POKEMON", "pokemon_type": "GRASS",
		"hp": 40, "stage": 0, "evolves_from": "",
		"retreat_cost": 1, "weakness": "FIRE", "resistance": "",
		"rarity": "COMMON",
		"pokemon_power": null,
		"attacks": [
			{"name": "String Shot", "cost": {"GRASS": 1}, "damage": 10, "effect": "Flip a coin. If heads, the Defending Pokemon is now Paralyzed."},
		]
	},
	"lc_charmander": {
		"id": "lc_charmander", "name": "Charmander", "number": "70/110",
		"image": "res://assets/cards/Legendary Collection/lc_charmander_070.jpg",
		"image_es": "res://assets/cards/Legendary Collection ES/lc_charmander_ES_070.jpg",
		"type": "POKEMON", "pokemon_type": "FIRE",
		"hp": 50, "stage": 0, "evolves_from": "",
		"retreat_cost": 1, "weakness": "WATER", "resistance": "",
		"rarity": "COMMON",
		"pokemon_power": null,
		"attacks": [
			{"name": "Scratch", "cost": {"COLORLESS": 1}, "damage": 10, "effect": ""},
			{"name": "Ember", "cost": {"FIRE": 1, "COLORLESS": 1}, "damage": 30, "effect": "Discard 1 Fire Energy attached to Charmander."},
		]
	},
	"lc_doduo": {
		"id": "lc_doduo", "name": "Doduo", "number": "71/110",
		"image": "res://assets/cards/Legendary Collection/lc_doduo_071.jpg",
		"image_es": "res://assets/cards/Legendary Collection ES/lc_doduo_ES_071.jpg",
		"type": "POKEMON", "pokemon_type": "COLORLESS",
		"hp": 50, "stage": 0, "evolves_from": "",
		"retreat_cost": 0, "weakness": "LIGHTNING", "resistance": "FIGHTING",
		"rarity": "COMMON",
		"pokemon_power": null,
		"attacks": [
			{"name": "Fury Attack", "cost": {"COLORLESS": 1}, "damage": 10, "effect": "Flip 2 coins. This attack does 10 damage times the number of heads."},
		]
	},
	"lc_dratini": {
		"id": "lc_dratini", "name": "Dratini", "number": "72/110",
		"image": "res://assets/cards/Legendary Collection/lc_dratini_072.jpg",
		"image_es": "res://assets/cards/Legendary Collection ES/lc_dratini_ES_072.jpg",
		"type": "POKEMON", "pokemon_type": "COLORLESS",
		"hp": 40, "stage": 0, "evolves_from": "",
		"retreat_cost": 1, "weakness": "", "resistance": "PSYCHIC",
		"rarity": "COMMON",
		"pokemon_power": null,
		"attacks": [
			{"name": "Pound", "cost": {"COLORLESS": 1}, "damage": 10, "effect": ""},
		]
	},
	"lc_drowzee": {
		"id": "lc_drowzee", "name": "Drowzee", "number": "73/110",
		"image": "res://assets/cards/Legendary Collection/lc_drowzee_073.jpg",
		"image_es": "res://assets/cards/Legendary Collection ES/lc_drowzee_ES_073.jpg",
		"type": "POKEMON", "pokemon_type": "PSYCHIC",
		"hp": 50, "stage": 0, "evolves_from": "",
		"retreat_cost": 1, "weakness": "PSYCHIC", "resistance": "",
		"rarity": "COMMON",
		"pokemon_power": {"name": "Long Distance Hypnosis", "effect": "Once during your turn (before your attack), you may flip a coin. If heads, the Defending Pokemon is now Asleep; if tails, your Active Pokemon is now Asleep. This power can't be used if Drowzee is affected by a Special Condition."},
		"attacks": [
			{"name": "Nightmare", "cost": {"PSYCHIC": 1, "COLORLESS": 1}, "damage": 10, "effect": "The Defending Pokemon is now Asleep."},
		]
	},
	"lc_eevee": {
		"id": "lc_eevee", "name": "Eevee", "number": "74/110",
		"image": "res://assets/cards/Legendary Collection/lc_eevee_074.jpg",
		"image_es": "res://assets/cards/Legendary Collection ES/lc_eevee_ES_074.jpg",
		"type": "POKEMON", "pokemon_type": "COLORLESS",
		"hp": 50, "stage": 0, "evolves_from": "",
		"retreat_cost": 1, "weakness": "FIGHTING", "resistance": "PSYCHIC",
		"rarity": "COMMON",
		"pokemon_power": null,
		"attacks": [
			{"name": "Tail Wag", "cost": {"COLORLESS": 1}, "damage": 0, "effect": "Flip a coin. If heads, the Defending Pokemon can't attack Eevee during your opponent's next turn."},
			{"name": "Quick Attack", "cost": {"COLORLESS": 2}, "damage": 10, "effect": "Flip a coin. If heads, this attack does 10 damage plus 20 more damage; if tails, this attack does 10 damage."},
		]
	},
	"lc_exeggcute": {
		"id": "lc_exeggcute", "name": "Exeggcute", "number": "75/110",
		"image": "res://assets/cards/Legendary Collection/lc_exeggcute_075.jpg",
		"image_es": "res://assets/cards/Legendary Collection ES/lc_exeggcute_ES_075.jpg",
		"type": "POKEMON", "pokemon_type": "GRASS",
		"hp": 50, "stage": 0, "evolves_from": "",
		"retreat_cost": 1, "weakness": "FIRE", "resistance": "",
		"rarity": "COMMON",
		"pokemon_power": null,
		"attacks": [
			{"name": "Hypnosis", "cost": {"PSYCHIC": 1}, "damage": 0, "effect": "The Defending Pokemon is now Asleep."},
			{"name": "Leech Seed", "cost": {"GRASS": 2}, "damage": 20, "effect": "Unless all damage from this attack is prevented, you may remove 1 damage counter from Exeggcute."},
		]
	},
	"lc_gastly": {
		"id": "lc_gastly", "name": "Gastly", "number": "76/110",
		"image": "res://assets/cards/Legendary Collection/lc_gastly_076.jpg",
		"image_es": "res://assets/cards/Legendary Collection ES/lc_gastly_ES_076.jpg",
		"type": "POKEMON", "pokemon_type": "PSYCHIC",
		"hp": 50, "stage": 0, "evolves_from": "",
		"retreat_cost": 0, "weakness": "", "resistance": "FIGHTING",
		"rarity": "COMMON",
		"pokemon_power": null,
		"attacks": [
			{"name": "Lick", "cost": {"PSYCHIC": 1}, "damage": 10, "effect": "Flip a coin. If heads, the Defending Pokemon is now Paralyzed."},
			{"name": "Energy Conversion", "cost": {"PSYCHIC": 1}, "damage": 0, "effect": "Put up to 2 Energy cards from your discard pile into your hand. Gastly does 10 damage to itself."},
		]
	},
	"lc_geodude": {
		"id": "lc_geodude", "name": "Geodude", "number": "77/110",
		"image": "res://assets/cards/Legendary Collection/lc_geodude_077.jpg",
		"image_es": "res://assets/cards/Legendary Collection ES/lc_geodude_ES_077.jpg",
		"type": "POKEMON", "pokemon_type": "FIGHTING",
		"hp": 50, "stage": 0, "evolves_from": "",
		"retreat_cost": 1, "weakness": "GRASS", "resistance": "",
		"rarity": "COMMON",
		"pokemon_power": null,
		"attacks": [
			{"name": "Stone Barrage", "cost": {"FIGHTING": 1, "COLORLESS": 1}, "damage": 10, "effect": "Flip a coin until you get tails. This attack does 10 damage times the number of heads."},
		]
	},
	"lc_grimer": {
		"id": "lc_grimer", "name": "Grimer", "number": "78/110",
		"image": "res://assets/cards/Legendary Collection/lc_grimer_078.jpg",
		"image_es": "res://assets/cards/Legendary Collection ES/lc_grimer_ES_078.jpg",
		"type": "POKEMON", "pokemon_type": "GRASS",
		"hp": 50, "stage": 0, "evolves_from": "",
		"retreat_cost": 1, "weakness": "PSYCHIC", "resistance": "",
		"rarity": "COMMON",
		"pokemon_power": null,
		"attacks": [
			{"name": "Nasty Goo", "cost": {"COLORLESS": 1}, "damage": 10, "effect": "Flip a coin. If heads, the Defending Pokemon is now Paralyzed."},
			{"name": "Minimized", "cost": {"GRASS": 1}, "damage": 0, "effect": "All damage done by attacks to Grimer during your opponent's next turn is reduced by 20 (after applying Weakness and Resistance)."},
		]
	},
	"lc_machop": {
		"id": "lc_machop", "name": "Machop", "number": "79/110",
		"image": "res://assets/cards/Legendary Collection/lc_machop_079.jpg",
		"image_es": "res://assets/cards/Legendary Collection ES/lc_machop_ES_079.jpg",
		"type": "POKEMON", "pokemon_type": "FIGHTING",
		"hp": 50, "stage": 0, "evolves_from": "",
		"retreat_cost": 1, "weakness": "PSYCHIC", "resistance": "",
		"rarity": "COMMON",
		"pokemon_power": null,
		"attacks": [
			{"name": "Punch", "cost": {"COLORLESS": 2}, "damage": 20, "effect": ""},
			{"name": "Kick", "cost": {"FIGHTING": 1, "COLORLESS": 2}, "damage": 30, "effect": ""},
		]
	},
	"lc_magnemite": {
		"id": "lc_magnemite", "name": "Magnemite", "number": "80/110",
		"image": "res://assets/cards/Legendary Collection/lc_magnemite_080.jpg",
		"image_es": "res://assets/cards/Legendary Collection ES/lc_magnemite_ES_080.jpg",
		"type": "POKEMON", "pokemon_type": "LIGHTNING",
		"hp": 40, "stage": 0, "evolves_from": "",
		"retreat_cost": 1, "weakness": "FIGHTING", "resistance": "",
		"rarity": "COMMON",
		"pokemon_power": null,
		"attacks": [
			{"name": "Thunder Wave", "cost": {"LIGHTNING": 1}, "damage": 10, "effect": "Flip a coin. If heads, the Defending Pokemon is now Paralyzed."},
			{"name": "Selfdestruct", "cost": {"LIGHTNING": 1, "COLORLESS": 1}, "damage": 40, "effect": "Does 10 damage to each Pokemon on each player's Bench. (Don't apply Weakness and Resistance for Benched Pokemon.) Magnemite does 40 damage to itself."},
		]
	},
	"lc_mankey": {
		"id": "lc_mankey", "name": "Mankey", "number": "81/110",
		"image": "res://assets/cards/Legendary Collection/lc_mankey_081.jpg",
		"image_es": "res://assets/cards/Legendary Collection ES/lc_mankey_ES_081.jpg",
		"type": "POKEMON", "pokemon_type": "FIGHTING",
		"hp": 40, "stage": 0, "evolves_from": "",
		"retreat_cost": 0, "weakness": "PSYCHIC", "resistance": "",
		"rarity": "COMMON",
		"pokemon_power": null,
		"attacks": [
			{"name": "Mischief", "cost": {"COLORLESS": 1}, "damage": 0, "effect": "Shuffle your opponent's deck."},
			{"name": "Anger", "cost": {"FIGHTING": 1, "COLORLESS": 1}, "damage": 20, "effect": "Flip a coin. If heads, this attack does 20 damage plus 20 more damage; if tails, this attack does 20 damage."},
		]
	},
	"lc_nidoran-female": {
		"id": "lc_nidoran-female", "name": "Nidoran Female", "number": "82/110",
		"image": "res://assets/cards/Legendary Collection/lc_nidoran-female_082.jpg",
		"image_es": "res://assets/cards/Legendary Collection ES/lc_nidoran-female_ES_082.jpg",
		"type": "POKEMON", "pokemon_type": "GRASS",
		"hp": 60, "stage": 0, "evolves_from": "",
		"retreat_cost": 1, "weakness": "PSYCHIC", "resistance": "",
		"rarity": "COMMON",
		"pokemon_power": null,
		"attacks": [
			{"name": "Fury Swipes", "cost": {"GRASS": 1}, "damage": 10, "effect": "Flip 3 coins. This attack does 10 damage times the number of heads."},
			{"name": "Call for Family", "cost": {"GRASS": 1}, "damage": 0, "effect": "Search your deck for a Basic Pokemon named Nidoran Female or Nidoran Male and put it onto your Bench. Shuffle your deck afterward."},
		]
	},
	"lc_nidoran-male": {
		"id": "lc_nidoran-male", "name": "Nidoran Male", "number": "83/110",
		"image": "res://assets/cards/Legendary Collection/lc_nidoran-male_083.jpg",
		"image_es": "res://assets/cards/Legendary Collection ES/lc_nidoran-male_ES_083.jpg",
		"type": "POKEMON", "pokemon_type": "GRASS",
		"hp": 40, "stage": 0, "evolves_from": "",
		"retreat_cost": 1, "weakness": "PSYCHIC", "resistance": "",
		"rarity": "COMMON",
		"pokemon_power": null,
		"attacks": [
			{"name": "Horn Hazard", "cost": {"GRASS": 1}, "damage": 30, "effect": "Flip a coin. If tails, this attack does nothing."},
		]
	},
	"lc_onix": {
		"id": "lc_onix", "name": "Onix", "number": "84/110",
		"image": "res://assets/cards/Legendary Collection/lc_onix_084.jpg",
		"image_es": "res://assets/cards/Legendary Collection ES/lc_onix_ES_084.jpg",
		"type": "POKEMON", "pokemon_type": "FIGHTING",
		"hp": 90, "stage": 0, "evolves_from": "",
		"retreat_cost": 3, "weakness": "GRASS", "resistance": "",
		"rarity": "COMMON",
		"pokemon_power": null,
		"attacks": [
			{"name": "Rock Throw", "cost": {"FIGHTING": 1}, "damage": 10, "effect": ""},
			{"name": "Harden", "cost": {"FIGHTING": 2}, "damage": 0, "effect": "During your opponent's next turn, whenever 30 or less damage is done to Onix (after applying Weakness and Resistance), prevent that damage."},
		]
	},
	"lc_pidgey": {
		"id": "lc_pidgey", "name": "Pidgey", "number": "85/110",
		"image": "res://assets/cards/Legendary Collection/lc_pidgey_085.jpg",
		"image_es": "res://assets/cards/Legendary Collection ES/lc_pidgey_ES_085.jpg",
		"type": "POKEMON", "pokemon_type": "COLORLESS",
		"hp": 40, "stage": 0, "evolves_from": "",
		"retreat_cost": 1, "weakness": "LIGHTNING", "resistance": "FIGHTING",
		"rarity": "COMMON",
		"pokemon_power": null,
		"attacks": [
			{"name": "Whirlwind", "cost": {"COLORLESS": 2}, "damage": 10, "effect": "Your opponent switches the Defending Pokemon with 1 of his or her Benched Pokemon, if any."},
		]
	},
	"lc_pikachu": {
		"id": "lc_pikachu", "name": "Pikachu", "number": "86/110",
		"image": "res://assets/cards/Legendary Collection/lc_pikachu_086.jpg",
		"image_es": "res://assets/cards/Legendary Collection ES/lc_pikachu_ES_086.jpg",
		"type": "POKEMON", "pokemon_type": "LIGHTNING",
		"hp": 50, "stage": 0, "evolves_from": "",
		"retreat_cost": 1, "weakness": "FIGHTING", "resistance": "",
		"rarity": "COMMON",
		"pokemon_power": null,
		"attacks": [
			{"name": "Spark", "cost": {"LIGHTNING": 2}, "damage": 20, "effect": "If your opponent has any Benched Pokemon, choose 1 of them and this attack does 10 damage to it. (Don't apply Weakness and Resistance for Benched Pokemon.)"},
		]
	},
	"lc_ponyta": {
		"id": "lc_ponyta", "name": "Ponyta", "number": "87/110",
		"image": "res://assets/cards/Legendary Collection/lc_ponyta_087.jpg",
		"image_es": "res://assets/cards/Legendary Collection ES/lc_ponyta_ES_087.jpg",
		"type": "POKEMON", "pokemon_type": "FIRE",
		"hp": 40, "stage": 0, "evolves_from": "",
		"retreat_cost": 1, "weakness": "WATER", "resistance": "",
		"rarity": "COMMON",
		"pokemon_power": null,
		"attacks": [
			{"name": "Smash Kick", "cost": {"COLORLESS": 2}, "damage": 20, "effect": ""},
			{"name": "Flame Tail", "cost": {"FIRE": 2}, "damage": 30, "effect": ""},
		]
	},
	"lc_psyduck": {
		"id": "lc_psyduck", "name": "Psyduck", "number": "88/110",
		"image": "res://assets/cards/Legendary Collection/lc_psyduck_088.jpg",
		"image_es": "res://assets/cards/Legendary Collection ES/lc_psyduck_ES_088.jpg",
		"type": "POKEMON", "pokemon_type": "WATER",
		"hp": 50, "stage": 0, "evolves_from": "",
		"retreat_cost": 0, "weakness": "LIGHTNING", "resistance": "",
		"rarity": "COMMON",
		"pokemon_power": null,
		"attacks": [
			{"name": "Dizziness", "cost": {"PSYCHIC": 1}, "damage": 0, "effect": "Draw a card."},
			{"name": "Water Gun", "cost": {"WATER": 1, "COLORLESS": 1}, "damage": 20, "effect": "Does 20 damage plus 10 more damage for each extra Water Energy attached."},
		]
	},
	"lc_rattata": {
		"id": "lc_rattata", "name": "Rattata", "number": "89/110",
		"image": "res://assets/cards/Legendary Collection/lc_rattata_089.jpg",
		"image_es": "res://assets/cards/Legendary Collection ES/lc_rattata_ES_089.jpg",
		"type": "POKEMON", "pokemon_type": "COLORLESS",
		"hp": 30, "stage": 0, "evolves_from": "",
		"retreat_cost": 0, "weakness": "FIGHTING", "resistance": "PSYCHIC",
		"rarity": "COMMON",
		"pokemon_power": null,
		"attacks": [
			{"name": "Bite", "cost": {"COLORLESS": 1}, "damage": 20, "effect": ""},
		]
	},
	"lc_rhyhorn": {
		"id": "lc_rhyhorn", "name": "Rhyhorn", "number": "90/110",
		"image": "res://assets/cards/Legendary Collection/lc_rhyhorn_090.jpg",
		"image_es": "res://assets/cards/Legendary Collection ES/lc_rhyhorn_ES_090.jpg",
		"type": "POKEMON", "pokemon_type": "FIGHTING",
		"hp": 70, "stage": 0, "evolves_from": "",
		"retreat_cost": 3, "weakness": "GRASS", "resistance": "LIGHTNING",
		"rarity": "COMMON",
		"pokemon_power": null,
		"attacks": [
			{"name": "Leer", "cost": {"COLORLESS": 1}, "damage": 0, "effect": "Flip a coin. If heads, the Defending Pokemon can't attack during your opponent's next turn."},
			{"name": "Horn Attack", "cost": {"FIGHTING": 1, "COLORLESS": 2}, "damage": 30, "effect": ""},
		]
	},
	"lc_sandshrew": {
		"id": "lc_sandshrew", "name": "Sandshrew", "number": "91/110",
		"image": "res://assets/cards/Legendary Collection/lc_sandshrew_091.jpg",
		"image_es": "res://assets/cards/Legendary Collection ES/lc_sandshrew_ES_091.jpg",
		"type": "POKEMON", "pokemon_type": "FIGHTING",
		"hp": 40, "stage": 0, "evolves_from": "",
		"retreat_cost": 1, "weakness": "GRASS", "resistance": "LIGHTNING",
		"rarity": "COMMON",
		"pokemon_power": null,
		"attacks": [
			{"name": "Sand-attack", "cost": {"FIGHTING": 1}, "damage": 10, "effect": "If the Defending Pokemon tries to attack during your opponent's next turn, your opponent flips a coin. If tails, that attack does nothing."},
		]
	},
	"lc_seel": {
		"id": "lc_seel", "name": "Seel", "number": "92/110",
		"image": "res://assets/cards/Legendary Collection/lc_seel_092.jpg",
		"image_es": "res://assets/cards/Legendary Collection ES/lc_seel_ES_092.jpg",
		"type": "POKEMON", "pokemon_type": "WATER",
		"hp": 60, "stage": 0, "evolves_from": "",
		"retreat_cost": 1, "weakness": "LIGHTNING", "resistance": "",
		"rarity": "COMMON",
		"pokemon_power": null,
		"attacks": [
			{"name": "Headbutt", "cost": {"WATER": 1}, "damage": 10, "effect": ""},
		]
	},
	"lc_slowpoke": {
		"id": "lc_slowpoke", "name": "Slowpoke", "number": "93/110",
		"image": "res://assets/cards/Legendary Collection/lc_slowpoke_093.jpg",
		"image_es": "res://assets/cards/Legendary Collection ES/lc_slowpoke_ES_093.jpg",
		"type": "POKEMON", "pokemon_type": "PSYCHIC",
		"hp": 50, "stage": 0, "evolves_from": "",
		"retreat_cost": 1, "weakness": "PSYCHIC", "resistance": "",
		"rarity": "COMMON",
		"pokemon_power": null,
		"attacks": [
			{"name": "Spacing Out", "cost": {"COLORLESS": 1}, "damage": 0, "effect": "Flip a coin. If heads, remove a damage counter from Slowpoke. This attack can't be used if Slowpoke has no damage counters on it."},
			{"name": "Scavenge", "cost": {"PSYCHIC": 2}, "damage": 0, "effect": "Discard 1 Psychic Energy attached to Slowpoke and put a card from your discard pile into your hand."},
		]
	},
	"lc_spearow": {
		"id": "lc_spearow", "name": "Spearow", "number": "94/110",
		"image": "res://assets/cards/Legendary Collection/lc_spearow_094.jpg",
		"image_es": "res://assets/cards/Legendary Collection ES/lc_spearow_ES_094.jpg",
		"type": "POKEMON", "pokemon_type": "COLORLESS",
		"hp": 50, "stage": 0, "evolves_from": "",
		"retreat_cost": 0, "weakness": "LIGHTNING", "resistance": "FIGHTING",
		"rarity": "COMMON",
		"pokemon_power": null,
		"attacks": [
			{"name": "Peck", "cost": {"COLORLESS": 1}, "damage": 10, "effect": ""},
			{"name": "Mirror Move", "cost": {"COLORLESS": 3}, "damage": 0, "effect": "If Spearow was attacked last turn, do the final result of that attack on Spearow to the Defending Pokemon."},
		]
	},
	"lc_squirtle": {
		"id": "lc_squirtle", "name": "Squirtle", "number": "95/110",
		"image": "res://assets/cards/Legendary Collection/lc_squirtle_095.jpg",
		"image_es": "res://assets/cards/Legendary Collection ES/lc_squirtle_ES_095.jpg",
		"type": "POKEMON", "pokemon_type": "WATER",
		"hp": 40, "stage": 0, "evolves_from": "",
		"retreat_cost": 1, "weakness": "LIGHTNING", "resistance": "",
		"rarity": "COMMON",
		"pokemon_power": null,
		"attacks": [
			{"name": "Bubble", "cost": {"WATER": 1}, "damage": 10, "effect": "Flip a coin. If heads, the Defending Pokemon is now Paralyzed."},
			{"name": "Withdraw", "cost": {"WATER": 1, "COLORLESS": 1}, "damage": 0, "effect": "Flip a coin. If heads, prevent all damage done to Squirtle during your opponent's next turn."},
		]
	},
	"lc_tentacool": {
		"id": "lc_tentacool", "name": "Tentacool", "number": "96/110",
		"image": "res://assets/cards/Legendary Collection/lc_tentacool_096.jpg",
		"image_es": "res://assets/cards/Legendary Collection ES/lc_tentacool_ES_096.jpg",
		"type": "POKEMON", "pokemon_type": "WATER",
		"hp": 30, "stage": 0, "evolves_from": "",
		"retreat_cost": 0, "weakness": "LIGHTNING", "resistance": "",
		"rarity": "COMMON",
		"pokemon_power": {"name": "Cowardice", "effect": "At any time during your turn (before your attack), you may return Tentacool to your hand. (Discard all cards attached to Tentacool.) This power can't be used the turn you put Tentacool into play or if Tentacool is affected by a Special Condition."},
		"attacks": [
			{"name": "Acid", "cost": {"WATER": 1}, "damage": 10, "effect": ""},
		]
	},
	"lc_voltorb": {
		"id": "lc_voltorb", "name": "Voltorb", "number": "97/110",
		"image": "res://assets/cards/Legendary Collection/lc_voltorb_097.jpg",
		"image_es": "res://assets/cards/Legendary Collection ES/lc_voltorb_ES_097.jpg",
		"type": "POKEMON", "pokemon_type": "LIGHTNING",
		"hp": 40, "stage": 0, "evolves_from": "",
		"retreat_cost": 1, "weakness": "FIGHTING", "resistance": "",
		"rarity": "COMMON",
		"pokemon_power": null,
		"attacks": [
			{"name": "Tackle", "cost": {"COLORLESS": 1}, "damage": 10, "effect": ""},
		]
	},
	"lc_vulpix": {
		"id": "lc_vulpix", "name": "Vulpix", "number": "98/110",
		"image": "res://assets/cards/Legendary Collection/lc_vulpix_098.jpg",
		"image_es": "res://assets/cards/Legendary Collection ES/lc_vulpix_ES_098.jpg",
		"type": "POKEMON", "pokemon_type": "FIRE",
		"hp": 50, "stage": 0, "evolves_from": "",
		"retreat_cost": 1, "weakness": "WATER", "resistance": "",
		"rarity": "COMMON",
		"pokemon_power": null,
		"attacks": [
			{"name": "Confuse Ray", "cost": {"FIRE": 2}, "damage": 10, "effect": "Flip a coin. If heads, the Defending Pokemon is now Confused."},
		]
	},
	"lc_weedle": {
		"id": "lc_weedle", "name": "Weedle", "number": "99/110",
		"image": "res://assets/cards/Legendary Collection/lc_weedle_099.jpg",
		"image_es": "res://assets/cards/Legendary Collection ES/lc_weedle_ES_099.jpg",
		"type": "POKEMON", "pokemon_type": "GRASS",
		"hp": 40, "stage": 0, "evolves_from": "",
		"retreat_cost": 1, "weakness": "FIRE", "resistance": "",
		"rarity": "COMMON",
		"pokemon_power": null,
		"attacks": [
			{"name": "Poison Sting", "cost": {"GRASS": 1}, "damage": 10, "effect": "Flip a coin. If heads, the Defending Pokemon is now Poisoned."},
		]
	},
	# ═══════════════════════════════════
	# ENERGÍAS ESPECIALES (#100-101)
	# ═══════════════════════════════════
	"lc_full-heal-energy": {"id": "lc_full-heal-energy", "name": "Full Heal Energy", "number": "100/110", "image": "res://assets/cards/Legendary Collection/lc_full-heal-energy_100.jpg", "image_es": "res://assets/cards/Legendary Collection ES/lc_full-heal-energy_ES_100.jpg", "type": "ENERGY", "energy_type": "COLORLESS", "provides": 1, "rarity": "UNCOMMON"},
	"lc_potion-energy": {"id": "lc_potion-energy", "name": "Potion Energy", "number": "101/110", "image": "res://assets/cards/Legendary Collection/lc_potion-energy_101.jpg", "image_es": "res://assets/cards/Legendary Collection ES/lc_potion-energy_ES_101.jpg", "type": "ENERGY", "energy_type": "COLORLESS", "provides": 1, "rarity": "UNCOMMON"},
	# ═══════════════════════════════════
	# TRAINERS (#102-110)
	# ═══════════════════════════════════
	"lc_pokemon-breeder": {"id": "lc_pokemon-breeder", "name": "Pokemon Breeder", "number": "102/110", "image": "res://assets/cards/Legendary Collection/lc_pokemon-breeder_102.jpg", "image_es": "res://assets/cards/Legendary Collection ES/lc_pokemon-breeder_ES_102.jpg", "type": "TRAINER", "trainer_type": "ITEM", "rarity": "RARE", "effect": "Put a Stage 2 card from your hand onto the matching Basic Pokemon (ignore the Stage 1). You can't use this card if that Basic Pokemon was put into play this turn."},
	"lc_pokemon-trader": {"id": "lc_pokemon-trader", "name": "Pokemon Trader", "number": "103/110", "image": "res://assets/cards/Legendary Collection/lc_pokemon-trader_103.jpg", "image_es": "res://assets/cards/Legendary Collection ES/lc_pokemon-trader_ES_103.jpg", "type": "TRAINER", "trainer_type": "ITEM", "rarity": "RARE", "effect": "Trade 1 of your Evolution cards in your hand for 1 of your opponent's Evolution cards in his or her hand. Either player may refuse the trade."},
	"lc_scoop-up": {"id": "lc_scoop-up", "name": "Scoop Up", "number": "104/110", "image": "res://assets/cards/Legendary Collection/lc_scoop-up_104.jpg", "image_es": "res://assets/cards/Legendary Collection ES/lc_scoop-up_ES_104.jpg", "type": "TRAINER", "trainer_type": "ITEM", "rarity": "RARE", "effect": "Return 1 of your Pokemon and all cards attached to it to your hand."},
	"lc_the-boss-s-way": {"id": "lc_the-boss-s-way", "name": "The Boss's Way", "number": "105/110", "image": "res://assets/cards/Legendary Collection/lc_the-boss-s-way_105.jpg", "image_es": "res://assets/cards/Legendary Collection ES/lc_the-boss-s-way_ES_105.jpg", "type": "TRAINER", "trainer_type": "ITEM", "rarity": "UNCOMMON", "effect": "Search your deck for a Pokemon with Team Rocket in its name and put it into your hand. Shuffle your deck afterward."},
	"lc_challenge": {"id": "lc_challenge", "name": "Challenge!", "number": "106/110", "image": "res://assets/cards/Legendary Collection/lc_challenge_106.jpg", "image_es": "res://assets/cards/Legendary Collection ES/lc_challenge_ES_106.jpg", "type": "TRAINER", "trainer_type": "ITEM", "rarity": "UNCOMMON", "effect": "Your opponent may search his or her deck for up to 4 Basic Pokemon cards and put them onto his or her Bench. If your opponent does, search your deck for up to 4 Basic Pokemon cards and put them onto your Bench. Either player shuffles his or her deck afterward."},
	"lc_energy-retrieval": {"id": "lc_energy-retrieval", "name": "Energy Retrieval", "number": "107/110", "image": "res://assets/cards/Legendary Collection/lc_energy-retrieval_107.jpg", "image_es": "res://assets/cards/Legendary Collection ES/lc_energy-retrieval_ES_107.jpg", "type": "TRAINER", "trainer_type": "ITEM", "rarity": "UNCOMMON", "effect": "Trade 1 of the other cards in your hand for up to 2 basic Energy cards from your discard pile."},
	"lc_bill": {"id": "lc_bill", "name": "Bill", "number": "108/110", "image": "res://assets/cards/Legendary Collection/lc_bill_108.jpg", "image_es": "res://assets/cards/Legendary Collection ES/lc_bill_ES_108.jpg", "type": "TRAINER", "trainer_type": "ITEM", "rarity": "COMMON", "effect": "Draw 2 cards."},
	"lc_mysterious-fossil": {"id": "lc_mysterious-fossil", "name": "Mysterious Fossil", "number": "109/110", "image": "res://assets/cards/Legendary Collection/lc_mysterious-fossil_109.jpg", "image_es": "res://assets/cards/Legendary Collection ES/lc_mysterious-fossil_ES_109.jpg", "type": "TRAINER", "trainer_type": "ITEM", "hp": 10, "rarity": "COMMON", "effect": "Play Mysterious Fossil as if it were a Basic Pokemon. Mysterious Fossil has 10 HP. If Mysterious Fossil is Knocked Out, it doesn't count as a Knocked Out Pokemon. At any time during your turn (before your attack), you may discard Mysterious Fossil from play."},
	"lc_potion": {"id": "lc_potion", "name": "Potion", "number": "110/110", "image": "res://assets/cards/Legendary Collection/lc_potion_110.jpg", "image_es": "res://assets/cards/Legendary Collection ES/lc_potion_ES_110.jpg", "type": "TRAINER", "trainer_type": "ITEM", "rarity": "COMMON", "effect": "Remove up to 2 damage counters from 1 of your Pokemon."},
}

func get_card(card_id: String) -> Dictionary:
	return CARDS.get(card_id, {})

func get_all_ids() -> Array:
	return CARDS.keys()

func get_all_pokemon_ids() -> Array:
	var result = []
	for id in CARDS:
		if CARDS[id].get("type") == "POKEMON":
			result.append(id)
	return result

func get_cards_by_type(type: String) -> Array:
	var result = []
	for id in CARDS:
		if CARDS[id].get("type") == type:
			result.append(CARDS[id])
	return result
