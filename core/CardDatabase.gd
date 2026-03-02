extends Node

const CARDS: Dictionary = {
	# ═══════════════════════════════════
	# RARAS HOLOGRÁFICAS (#1-18)
	# ═══════════════════════════════════
	"ampharos": {
		"id": "ampharos", "name": "Ampharos", "number": "1/111",
		"image": "res://assets/cards/Neo Genesis/ampharos-neo-genesis-1.jpg",
		"type": "POKEMON", "pokemon_type": "LIGHTNING",
		"hp": 80, "stage": 2, "evolves_from": "flaaffy",
		"retreat_cost": 2, "weakness": "FIGHTING", "resistance": "",
		"rarity": "RARE_HOLO",
		"attacks": [
			{"name": "Gigaspark", "cost": {"LIGHTNING": 3}, "damage": 40, "effect": "Flip a coin. If heads, the Defending Pokémon is now Paralyzed and this attack does 10 damage to each of your opponent’s Benched Pokémon. Don’t apply Weakness and Resistance for Benched Pokémon."},
		]
	},
	"azumarill": {
		"id": "azumarill", "name": "Azumarill", "number": "2/111",
		"image": "res://assets/cards/Neo Genesis/azumarill-neo-genesis-2.jpg",
		"type": "POKEMON", "pokemon_type": "WATER",
		"hp": 70, "stage": 1, "evolves_from": "marill",
		"retreat_cost": 1, "weakness": "LIGHTNING", "resistance": "",
		"rarity": "RARE_HOLO",
		"attacks": [
			{"name": "Tackle", "cost": {"COLORLESS": 2}, "damage": 20, "effect": ""},
			{"name": "Bubble Shower", "cost": {"WATER": 3}, "damage": 30, "effect": "Flip a coin. If heads, the Defending Pokémon is now Paralyzed and this attack does 10 damage to each of your opponent’s Benched Pokémon. Don’t apply Weakness and Resistance for Benched Pokémon."},
		]
	},
	"bellossom": {
		"id": "bellossom", "name": "Bellossom", "number": "3/111",
		"image": "res://assets/cards/Neo Genesis/bellossom-neo-genesis-3.jpg",
		"type": "POKEMON", "pokemon_type": "GRASS",
		"hp": 70, "stage": 2, "evolves_from": "gloom",
		"retreat_cost": 1, "weakness": "FIRE", "resistance": "",
		"rarity": "RARE_HOLO",
		"attacks": [
			{"name": "Sweet Nectar", "cost": {"GRASS": 1}, "damage": 0, "effect": "Flip a coin. If heads, remove all damage counters from 1 of your Pokémon."},
			{"name": "Flower Dance", "cost": {"GRASS": 2, "COLORLESS": 1}, "damage": 30, "effect": "Does 30 damage times the number of cards with Bellossom in their names that you have in play including this one."},
		]
	},
	"feraligatr_1": {
		"id": "feraligatr_1", "name": "Feraligatr", "number": "4/111",
		"image": "res://assets/cards/Neo Genesis/feraligatr-neo-genesis-4.jpg",
		"type": "POKEMON", "pokemon_type": "WATER",
		"hp": 100, "stage": 2, "evolves_from": "croconaw",
		"retreat_cost": 3, "weakness": "GRASS", "resistance": "",
		"rarity": "RARE_HOLO",
		"pokemon_power": {
			"name": "Berserk",
			"effect": "When you play Feraligatr from your hand, flip a coin. If heads, discard the top 5 cards from your opponent's deck. If tails, discard the top 5 cards from your deck."
		},
		"attacks": [
			{"name": "Chomp", "cost": {"WATER": 4}, "damage": 50, "effect": "Flip a number of coins equal to the number of damage counters on Feraligatr. This attack does 50 damage plus 10 more damage for each heads."}
		]
	},
	"feraligatr_2": {
		"id": "feraligatr_2", "name": "Feraligatr", "number": "5/111",
		"image": "res://assets/cards/Neo Genesis/feraligatr-neo-genesis-5.jpg",
		"type": "POKEMON", "pokemon_type": "WATER",
		"hp": 120, "stage": 2, "evolves_from": "croconaw",
		"retreat_cost": 3, "weakness": "GRASS", "resistance": "",
		"rarity": "RARE_HOLO",
		"pokemon_power": {
			"name": "Downpour",
			"effect": "As often as you like during your turn (before your attack), you may discard a Water Energy card from your hand. This power can't be used if Feraligatr is Asleep, Confused, or Paralyzed."
		},
		"attacks": [
			{"name": "Riptide", "cost": {"WATER": 1, "COLORLESS": 2}, "damage": 10, "effect": "Does 10 damage plus 10 damage times the number of Water Energy cards in your discard pile. Then, shuffle all Water Energy cards from your discard pile into your deck."}
		]
	},
   "heracross": {
		"id": "heracross", "name": "Heracross", "number": "6/111",
		"image": "res://assets/cards/Neo Genesis/heracross-neo-genesis-6.jpg",
		"type": "POKEMON", "pokemon_type": "GRASS",
		"hp": 60, "stage": 0, "evolves_from": "",
		"retreat_cost": 2, "weakness": "FIRE", "resistance": "",
		"rarity": "RARE_HOLO",
		"pokemon_power": {
			"name": "Final Blow",
			"effect": "If Heracross's remaining HP are 20 or less, you may make its Megahorn attack's base damage 120 instead of 60. This power can't be used if Heracross is Asleep, Confused, or Paralyzed."
		},
		"attacks": [
			{"name": "Megahorn", "cost": {"GRASS": 3}, "damage": 60, "effect": "Flip a coin. If tails, this attack does nothing."}
		]
	},
	"jumpluff": {
		"id": "jumpluff", "name": "Jumpluff", "number": "7/111",
		"image": "res://assets/cards/Neo Genesis/jumpluff-neo-genesis-7.jpg",
		"type": "POKEMON", "pokemon_type": "GRASS",
		"hp": 70, "stage": 2, "evolves_from": "skiploom",
		"retreat_cost": 0, "weakness": "FIRE", "resistance": "FIGHTING",
		"rarity": "RARE_HOLO",
		"attacks": [
			{"name": "Sleep Powder", "cost": {"GRASS": 1}, "damage": 20, "effect": "The Defending Pokémon is now Asleep."},
			{"name": "Leech Seed", "cost": {"GRASS": 1}, "damage": 20, "effect": "If this attack damages the Defending Pokémon after applying Weakness and Resistance, remove 1 damage counter from Jumpluff, if it has any."},
		]
	},
	"kingdra": {
		"id": "kingdra", "name": "Kingdra", "number": "8/111",
		"image": "res://assets/cards/Neo Genesis/kingdra-neo-genesis-8.jpg",
		"type": "POKEMON", "pokemon_type": "WATER",
		"hp": 90, "stage": 2, "evolves_from": "seadra",
		"retreat_cost": 2, "weakness": "", "resistance": "",
		"rarity": "RARE_HOLO",
		"attacks": [
			{"name": "Agility", "cost": {"WATER": 2, "COLORLESS": 1}, "damage": 30, "effect": "Flip a coin. If heads, during your opponent’s next turn, prevent all effects of attacks, including damage, done to Kingdra."},
			{"name": "Dragon Tornado", "cost": {"WATER": 4}, "damage": 50, "effect": "If this attack doesn’t Knock Out the Defending Pokémon, and if there are any Pokémon on your opponent’s Bench, choose 1 of them and switch it with the Defending Pokémon."},
		]
	},
	"lugia": {
		"id": "lugia", "name": "Lugia", "number": "9/111",
		"image": "res://assets/cards/Neo Genesis/lugia-neo-genesis-9.jpg",
		"type": "POKEMON", "pokemon_type": "COLORLESS",
		"hp": 90, "stage": 0, "evolves_from": "",
		"retreat_cost": 2, "weakness": "LIGHTNING", "resistance": "FIGHTING",
		"rarity": "ULTRA_RARE",
		"attacks": [
			{"name": "Elemental Blast", "cost": {"WATER": 1,"FIRE": 1,"LIGHTNING": 1}, "damage": 90,"effect": "Discard a Fire Energy card, a Water Energy card, and a lighninth Energy card attached to Lugia in order to use this attack."},
		]
	},
	"meganium_1": {
		"id": "meganium_1", "name": "Meganium", "number": "10/111",
		"image": "res://assets/cards/Neo Genesis/meganium-neo-genesis-10.jpg",
		"type": "POKEMON", "pokemon_type": "GRASS",
		"hp": 100, "stage": 2, "evolves_from": "bayleef",
		"retreat_cost": 3, "weakness": "FIRE", "resistance": "",
		"rarity": "RARE_HOLO",
		"pokemon_power": {
			"name": "Herbal Scent",
			"effect": "When you play Meganium from your hand, you may flip a coin. If heads, remove all damage counters from all Grass Pokémon in play."
		},
		"attacks": [
			{"name": "Body Slam", "cost": {"GRASS": 2, "COLORLESS": 2}, "damage": 40, "effect": "Flip a coin. If heads, the Defending Pokémon is now Paralyzed."}
		]
	},
	"meganium_2": {
		"id": "meganium_2", "name": "Meganium", "number": "11/111",
		"image": "res://assets/cards/Neo Genesis/meganium-neo-genesis-11.jpg",
		"type": "POKEMON", "pokemon_type": "GRASS",
		"hp": 100, "stage": 2, "evolves_from": "bayleef",
		"retreat_cost": 3, "weakness": "FIRE", "resistance": "",
		"rarity": "RARE_HOLO",
		"pokemon_power": {
			"name": "Wild Growth",
			"effect": "As long as Meganium is in play, each Grass Energy card attached to your Grass Pokémon instead provides 2 Grass Energy. This power stops working while Meganium is Asleep, Confused, or Paralyzed."
		},
		"attacks": [
			{"name": "Soothing Scent", "cost": {"GRASS": 4}, "damage": 40, "effect": "The Defending Pokémon is now Asleep."}
		]
	},
	"pichu": {
		"id": "pichu", "name": "Pichu", "number": "12/111",
		"image": "res://assets/cards/Neo Genesis/pichu-neo-genesis-12.jpg",
		"type": "POKEMON", "pokemon_type": "LIGHTNING",
		"hp": 30, "stage": "baby", "evolves_from": "",
		"retreat_cost": 0, "weakness": "", "resistance": "",
		"rarity": "RARE_HOLO",
		"attacks": [
			{"name": "Zzzap", "cost": {"LIGHTNING": 1}, "damage": 0, "effect": "Does 20 damage to each Pokémon in play that has a Pokémon Power. Don’t apply Weakness and Resistance."},
		]
	},
	"skarmory": {
		"id": "skarmory", "name": "Skarmory", "number": "13/111",
		"image": "res://assets/cards/Neo Genesis/skarmory-neo-genesis-13.jpg",
		"type": "POKEMON", "pokemon_type": "METAL",
		"hp": 60, "stage": 0, "evolves_from": "",
		"retreat_cost": 1, "weakness": "FIRE", "resistance": "GRASS",
		"rarity": "RARE_HOLO",
		"attacks": [
			{"name": "Claw", "cost": {"COLORLESS": 1}, "damage": 20, "effect": "Flip a coin. If tails, this attack does nothing."},
			{"name": "Steel Wing", "cost": {"METAL": 1, "COLORLESS": 2}, "damage": 30, "effect": "Flip a coin. If heads, all damage done by attacks to Skarmory during your opponent’s next turn is reduced by 20 after applying Weakness and Resistance."},
		]
	},
	"slowking": {
		"id": "slowking", "name": "Slowking", "number": "14/111",
		"image": "res://assets/cards/Neo Genesis/slowking-neo-genesis-14.jpg",
		"type": "POKEMON", "pokemon_type": "PSYCHIC",
		"hp": 80, "stage": 1, "evolves_from": "slowpoke",
		"retreat_cost": 3, "weakness": "PSYCHIC", "resistance": "",
		"rarity": "RARE_HOLO",
		"pokemon_power": {
			"name": "Mind Games",
			"effect": "Only if Slowking is Active Pokemon. Whenever your opponent plays a Trainer card, you may flip a coin. If heads, that card does nothing. Put it on top of your opponent's deck. This power can't be used if Slowking is Asleep, Confused, or Paralyzed."
		},
		"attacks": [
			{"name": "Mind Blast", "cost": {"PSYCHIC": 3}, "damage": 20, "effect": "Flip a coin. If heads, this attack does 20 damage plus 10 more damage and the Defending Pokémon is now Confused. If tails, this attack does 20 damage."},
		]
	},
	"steelix": {
		"id": "steelix", "name": "Steelix", "number": "15/111",
		"image": "res://assets/cards/Neo Genesis/steelix-neo-genesis-15.jpg",
		"type": "POKEMON", "pokemon_type": "METAL",
		"hp": 110, "stage": 1, "evolves_from": "onix",
		"retreat_cost": 4, "weakness": "FIRE", "resistance": "GRASS",
		"rarity": "RARE_HOLO",
		"attacks": [
			{"name": "Tackle", "cost": {"COLORLESS": 2}, "damage": 20, "effect": ""},
			{"name": "Tail Crush", "cost": {"METAL": 1, "COLORLESS": 2}, "damage": 30, "effect": "Flip a coin. If heads, this attack does 30 damage plus 20 more damage; if tails, this attack does 30 damage"},
		]
	},
	"togetic": {
		"id": "togetic", "name": "Togetic", "number": "16/111",
		"image": "res://assets/cards/Neo Genesis/togetic-neo-genesis-16.jpg",
		"type": "POKEMON", "pokemon_type": "COLORLESS",
		"hp": 60, "stage": 1, "evolves_from": "togepi",
		"retreat_cost": 1, "weakness": "", "resistance": "FIGHTING",
		"rarity": "RARE_HOLO",
		"attacks": [
			{"name": "Super Metronome", "cost": {"COLORLESS": 1}, "damage": 0, "effect": "Flip a coin. If heads, choose an attack on 1 of your opponent’s Pokémon. Super Metronome copies that attack except for its Energy cost. You must still do anything else in order to use that attack. No matter what type the Defending Pokémon is, Togetic’s type is still COLORLESS. Togetic performs that attack. Togetic can make that attack even if it does not have the appropriate number or type of Energy attached to it necessary to make the attack."},
			{"name": "Fly", "cost": {"COLORLESS": 3}, "damage": 30, "effect": "Flip a coin. If heads, during your opponent’s next turn, prevent all effects of attacks, including damage, done to Togetic; if tails, this attack does nothing, not even damage."},
		]
	},
	"typhlosion_1": {
		"id": "typhlosion_1", "name": "Typhlosion", "number": "17/111",
		"image": "res://assets/cards/Neo Genesis/typhlosion-neo-genesis-17.jpg",
		"type": "POKEMON", "pokemon_type": "FIRE",
		"hp": 100, "stage": 2, "evolves_from": "quilava",
		"retreat_cost": 2, "weakness": "WATER", "resistance": "",
		"rarity": "RARE_HOLO",
		"pokemon_power": {
			"name": "Fire Recharge",
			"effect": "Once during your turn before your attack, you may flip a coin. If heads, attach a Fire Energy card from your discard pile to 1 of your Fire Pokémon. This power can't be used if Typhlosion is Asleep, Confused, or Paralyzed."
		},
		"attacks": [
			{"name": "Flame Burst", "cost": {"FIRE": 4}, "damage": 60, "effect": "Flip a coin. If heads, this attack does 60 damage plus 20 more damage and does 20 damage to Typhlosion. If tails, this attack does 60 damage."}
		]
	},
"typhlosion_2": {
		"id": "typhlosion_2", "name": "Typhlosion", "number": "18/111",
		"image": "res://assets/cards/Neo Genesis/typhlosion-neo-genesis-18.jpg",
		"type": "POKEMON", "pokemon_type": "FIRE",
		"hp": 100, "stage": 2, "evolves_from": "quilava",
		"retreat_cost": 2, "weakness": "WATER", "resistance": "",
		"rarity": "RARE_HOLO",
		"pokemon_power": {
			"name": "Fire Boost",
			"effect": "When you play Typhlosion from your hand, you may flip a coin. If heads, search your deck for up to 4 Fire Energy cards and attach them to Typhlosion. Shuffle your deck afterward."
		},
		"attacks": [
			{
				"name": "Flame Wheel", 
				"cost": {"FIRE": 4}, 
				"damage": 80, 
				"effect": "Discard 3 Fire Energy cards attached to Typhlosion in order to use this attack. Do 20 damage to each Benched Pokémon (yours and your opponent's). (Don't apply Weakness and Resistance for Benched Pokémon.)"
			}
		]
	},
	"metal_energy": {
		"id": "metal_energy", "name": "Metal Energy", "number": "19/111",
		"image": "res://assets/cards/Neo Genesis/metal-energy-neo-genesis-19.jpg",
		"type": "ENERGY", "energy_type": "METAL", "provides": 1, "rarity": "RARE"
	},
	"cleffa": {
		"id": "cleffa", "name": "Cleffa", "number": "20/111",
		"image": "res://assets/cards/Neo Genesis/cleffa-neo-genesis-20.jpg",
		"type": "POKEMON", "pokemon_type": "COLORLESS",
		"hp": 30, "stage": "baby", "evolves_from": "",
		"retreat_cost": 0, "weakness": "", "resistance": "",
		"rarity": "UNCOMMON",
		"attacks": [
			{"name": "Eeeeeeek", "cost": {"COLORLESS": 1}, "damage": 0, "effect": "Shuffle your hand into your deck, then draw 7 cards. Your turn ends."},
		]
	},
	"donphan": {
		"id": "donphan", "name": "Donphan", "number": "21/111",
		"image": "res://assets/cards/Neo Genesis/donphan-neo-genesis-21.jpg",
		"type": "POKEMON", "pokemon_type": "FIGHTING",
		"hp": 70, "stage": 1, "evolves_from": "phanpy",
		"retreat_cost": 3, "weakness": "GRASS", "resistance": "LIGHTNING",
		"rarity": "UNCOMMON",
		"attacks": [
			{"name": "Flail", "cost": {"FIGHTING": 1}, "damage": 10, "effect": "Does 10 damage times the number of damage counters on Donphan."},
			{"name": "Rapid Spin", "cost": {"FIGHTING": 2, "COLORLESS": 1}, "damage": 50, "effect": "If your opponent has any Benched Pokémon, he or she chooses 1 of them and switches it with his or her Active Pokémon, then, if you have any Benched Pokémon, you switch 1 of them with your Active Pokémon. Do the damage before switching the Pokémon."},
		]
	},
	"elekid": {
		"id": "elekid", "name": "Elekid", "number": "22/111",
		"image": "res://assets/cards/Neo Genesis/elekid-neo-genesis-22.jpg",
		"type": "POKEMON", "pokemon_type": "LIGHTNING",
		"hp": 30, "stage": "baby", "evolves_from": "",
		"retreat_cost": 0, "weakness": "", "resistance": "",
		"rarity": "UNCOMMON",
		"pokemon_power": {
			"name": "Playful Punch",
			"effect": "Once during your turn (before your attack), you may flip a coin. If heads, do 20 damage to your opponent’s Active Pokémon. (Apply Weakness and Resistance.) Either way, this ends your turn. This power can’t be used if Elekid is Asleep, Confused, or Paralyzed."
		},
		"attacks": []
	},
	"magby": {
		"id": "magby", "name": "Magby", "number": "23/111",
		"image": "res://assets/cards/Neo Genesis/magby-neo-genesis-23.jpg",
		"type": "POKEMON", "pokemon_type": "FIRE",
		"hp": 30, "stage": "baby", "evolves_from": "",
		"retreat_cost": 0, "weakness": "", "resistance": "",
		"rarity": "UNCOMMON",
		"attacks": [
			{"name": "Sputter", "cost": {"FIRE": 1}, "damage": 10, "effect": "All Pokémon Powers stop working until the end of your next turn."},
		]
	},
	"murkrow": {
		"id": "murkrow", "name": "Murkrow", "number": "24/111",
		"image": "res://assets/cards/Neo Genesis/murkrow-neo-genesis-24.jpg",
		"type": "POKEMON", "pokemon_type": "DARKNESS",
		"hp": 50, "stage": 0, "evolves_from": "",
		"retreat_cost": 1, "weakness": "", "resistance": "FIGHTING",
		"rarity": "UNCOMMON",
		"attacks": [
			{"name": "Mean Look", "cost": {"DARKNESS": 1}, "damage": 0, "effect": "Choose 1 of your opponent’s Pokémon. This attack does 20 damage to that Pokémon. This attack’s damage isn’t affected by Weakness, Resistance, Pokémon Powers, or any other effects on the Defending Pokémon."},
			{"name": "Feint Attack", "cost": {"DARKNESS": 1, "COLORLESS": 1}, "damage": 0, "effect": "Choose 1 of your opponent’s Pokémon. This attack does 20 damage to that Pokémon. This attack’s damage isn’t affected by Weakness, Resistance, Pokémon Powers, or any other effects on the Defending Pokémon."},
		]
	},
	"sneasel": {
		"id": "sneasel", "name": "Sneasel", "number": "25/111",
		"image": "res://assets/cards/Neo Genesis/sneasel-neo-genesis-25.jpg",
		"type": "POKEMON", "pokemon_type": "DARKNESS",
		"hp": 60, "stage": 0, "evolves_from": "",
		"retreat_cost": 1, "weakness": "", "resistance": "PSYCHIC",
		"rarity": "UNCOMMON",
		"attacks": [
			{"name": "Fury Swipes", "cost": {"COLORLESS": 1}, "damage": 10, "effect": "Flip 3 coins. This attack does 10 damage times the number of heads."},
			{"name": "Beat Up", "cost": {"DARKNESS": 2}, "damage": 20, "effect": "Flip a coin for each of your Pokémon in play including this one. This attack does 20 damage times the number of heads."},
		]
	},
	"aipom": {
		"id": "aipom", "name": "Aipom", "number": "26/111",
		"image": "res://assets/cards/Neo Genesis/aipom-neo-genesis-26.jpg",
		"type": "POKEMON", "pokemon_type": "COLORLESS",
		"hp": 40, "stage": 0, "evolves_from": "",
		"retreat_cost": 1, "weakness": "FIGHTING", "resistance": "PSYCHIC",
		"rarity": "COMMON",
		"attacks": [
			{"name": "Pilfer", "cost": {"COLORLESS": 1}, "damage": 0, "effect": "Shuffle Aipom and all cards attached to it into your deck. Flip a coin. If heads, shuffle a card from your discard pile into your deck."},
			{"name": "Tail Rap", "cost": {"COLORLESS": 2}, "damage": 10, "effect": "Flip 2 coins. This attack does 10 damage times the number of heads."},
		]
	},
	"ariados": {
		"id": "ariados", "name": "Ariados", "number": "27/111",
		"image": "res://assets/cards/Neo Genesis/ariados-neo-genesis-27.jpg",
		"type": "POKEMON", "pokemon_type": "GRASS",
		"hp": 60, "stage": 1, "evolves_from": "spinarak",
		"retreat_cost": 2, "weakness": "FIRE", "resistance": "",
		"rarity": "UNCOMMON",
		"attacks": [
			{"name": "Spider Web", "cost": {"GRASS": 1}, "damage": 0, "effect": "Flip a coin. If heads, the Defending Pokémon can’t retreat. Benching or evolving that Pokémon ends this effect."},
			{"name": "Poison Bite", "cost": {"GRASS": 3}, "damage": 20, "effect": "If this attack damages the Defending Pokémon, the Defending Pokémon is now Poisoned and you remove a number of damage counters from Ariados equal to half that damage rounded up to the nearest 10. If Ariados has fewer damage counters than that, remove all of them."},
		]
	},
	"bayleef_1": {
		"id": "bayleef_1", "name": "Bayleef", "number": "28/111",
		"image": "res://assets/cards/Neo Genesis/bayleef-neo-genesis-28.jpg",
		"type": "POKEMON", "pokemon_type": "GRASS",
		"hp": 70, "stage": 1, "evolves_from": "chikorita",
		"retreat_cost": 1, "weakness": "FIRE", "resistance": "",
		"rarity": "UNCOMMON",
		"attacks": [
			{"name": "Poisonpowder", "cost": {"GRASS": 1, "COLORLESS": 1}, "damage": 20, "effect": "Flip a coin. If heads, the Defending Pokémon is now Poisoned."},
			{"name": "Pollen Shield ", "cost": {"GRASS": 2, "COLORLESS": 1}, "damage": 30, "effect": "During your opponent’s next turn, Bayleef can’t become Asleep, Confused, Paralyzed, or Poisoned. All other effects of attacks, Pokémon Powers and Trainer cards still happen."},
		]
	},
	"bayleef_2": {
		"id": "bayleef_2", "name": "Bayleef", "number": "29/111",
		"image": "res://assets/cards/Neo Genesis/bayleef-neo-genesis-29.jpg",
		"type": "POKEMON", "pokemon_type": "GRASS",
		"hp": 80, "stage": 1, "evolves_from": "chikorita",
		"retreat_cost": 2, "weakness": "FIRE", "resistance": "",
		"rarity": "UNCOMMON",
		"attacks": [
			{"name": "Sweet Scent", "cost": {"GRASS": 1}, "damage": 0, "effect": "Flip a coin. If heads and if any of your Pokémon have any damage counters on them, then remove 2 damage counters from 1 of them or 1 if it only has 1. If tails and if any of your opponent’s Pokémon have any damage counters on them, choose 1 of them and remove 2 damage counters from it or 1 if it only has 1."},
			{"name": "Double Razor Leaf", "cost": {"GRASS": 3}, "damage": 40, "effect": "Flip 2 coins. This attack does 40 damage times the number of heads."},
		]
	},
	"clefairy": {
		"id": "clefairy", "name": "Clefairy", "number": "30/111",
		"image": "res://assets/cards/Neo Genesis/clefairy-neo-genesis-30.jpg",
		"type": "POKEMON", "pokemon_type": "COLORLESS",
		"hp": 50, "stage": 0, "evolves_from": "",
		"retreat_cost": 1, "weakness": "FIGHTING", "resistance": "PSYCHIC",
		"rarity": "UNCOMMON",
		"attacks": [
			{"name": "Doubleslap", "cost": {"COLORLESS": 2}, "damage": 10, "effect": "Flip 2 coins. This attack does 10 damage times the number of heads."},
			{"name": "Squaredance", "cost": {"COLORLESS": 3}, "damage": 0, "effect": "Flip a number of coins equal to the total number of Pokémon in play. For each heads, you may search your deck for a basic Energy card, show it to your opponent, and put it into your hand. Shuffle your deck afterward."},
		]
	},
	"croconaw_1": {
		"id": "croconaw_1", "name": "Croconaw", "number": "31/111",
		"image": "res://assets/cards/Neo Genesis/croconaw-neo-genesis-31.jpg",
		"type": "POKEMON", "pokemon_type": "WATER",
		"hp": 70, "stage": 1, "evolves_from": "totodile",
		"retreat_cost": 2, "weakness": "GRASS", "resistance": "",
		"rarity": "UNCOMMON",
		"attacks": [
			{"name": "Screech", "cost": {"WATER": 1}, "damage": 0, "effect": "Until the end of your next turn, if an attack damages the Defending Pokémon (after applying Weakness and Resistance), that attack does 20 more damage to the Defending Pokémon"},
			{"name": "Jaw Clamp", "cost": {"WATER": 2, "COLORLESS": 1}, "damage": 30, "effect": "Until the end of your opponent’s next turn, as long as Croconaw is your Active Pokémon, the Defending Pokémon can’t retreat, and if the effect of an attack, Pokémon Power, or Trainer card would change that player’s Active Pokémon, that part of the effect does nothing."},
		]
	},
	"croconaw_2": {
		"id": "croconaw_2", "name": "Croconaw", "number": "32/111",
		"image": "res://assets/cards/Neo Genesis/croconaw-neo-genesis-32.jpg",
		"type": "POKEMON", "pokemon_type": "WATER",
		"hp": 80, "stage": 1, "evolves_from": "totodile",
		"retreat_cost": 2, "weakness": "GRASS", "resistance": "",
		"rarity": "UNCOMMON",
		"attacks": [
			{"name": "Tackle", "cost": {"COLORLESS": 2}, "damage": 20, "effect": ""},
			{"name": "Sweep Away", "cost": {"WATER": 2, "COLORLESS": 1}, "damage": 50, "effect": "Discard the top 3 cards from your deck."},
		]
	},
	"electabuzz": {
		"id": "electabuzz", "name": "Electabuzz", "number": "33/111",
		"image": "res://assets/cards/Neo Genesis/electabuzz-neo-genesis-33.jpg",
		"type": "POKEMON", "pokemon_type": "LIGHTNING",
		"hp": 70, "stage": 0, "evolves_from": "",
		"retreat_cost": 1, "weakness": "FIGHTING", "resistance": "",
		"rarity": "UNCOMMON",
		"attacks": [
			{"name": "Punch", "cost": {"COLORLESS": 2}, "damage": 20, "effect": ""},
			{"name": "Swift", "cost": {"LIGHTNING": 3}, "damage": 30, "effect": "This attack’s damage isn’t affected by Weakness, Resistance, Pokémon Powers, or any other effects on the Defending Pokémon."},
		]
	},
	"flaaffy": {
		"id": "flaaffy", "name": "Flaaffy", "number": "34/111",
		"image": "res://assets/cards/Neo Genesis/flaaffy-neo-genesis-34.jpg",
		"type": "POKEMON", "pokemon_type": "LIGHTNING",
		"hp": 60, "stage": 1, "evolves_from": "mareep",
		"retreat_cost": 1, "weakness": "FIGHTING", "resistance": "",
		"rarity": "UNCOMMON",
		"attacks": [
			{"name": "Discharge", "cost": {"LIGHTNING": 1}, "damage": 30, "effect": "Discard all LIGHTNING Energy cards attached to Flaaffy in order to use this attack. Flip a number of coins equal to the number of LIGHTNING Energy cards you discarded. This attack does 30 damage times then number of heads."},
			{"name": "Electric Current", "cost": {"LIGHTNING": 2}, "damage": 30, "effect": "Take 1 LIGHTNING Energy cards attached to Flaaffy and attach it to 1 of your Benched Pokémon. If you have no Benched Pokémon, discard that Energy card."},
		]
	},
	"furret": {
		"id": "furret", "name": "Furret", "number": "35/111",
		"image": "res://assets/cards/Neo Genesis/furret-neo-genesis-35.jpg",
		"type": "POKEMON", "pokemon_type": "COLORLESS",
		"hp": 60, "stage": 1, "evolves_from": "sentret",
		"retreat_cost": 1, "weakness": "FIGHTING", "resistance": "PSYCHIC",
		"rarity": "UNCOMMON",
		"attacks": [
			{"name": "Quick Attack", "cost": {"COLORLESS": 2}, "damage": 20, "effect": "Flip a coin. If heads, this attack does 20 damage plus 10 more damage; if tails, this attack does 20 damage."},
			{"name": "Slam", "cost": {"COLORLESS": 3}, "damage": 30, "effect": "Flip 2 coins. This attack does 30 damage times the number of heads."},
		]
	},
	"gloom": {
		"id": "gloom", "name": "Gloom", "number": "36/111",
		"image": "res://assets/cards/Neo Genesis/gloom-neo-genesis-36.jpg",
		"type": "POKEMON", "pokemon_type": "GRASS",
		"hp": 60, "stage": 1, "evolves_from": "oddish",
		"retreat_cost": 2, "weakness": "FIRE", "resistance": "",
		"rarity": "UNCOMMON",
		"attacks": [
			{"name": "Strange Powder", "cost": {"GRASS": 1, "COLORLESS": 1}, "damage": 20, "effect": "Flip a coin. If heads, the Defending Pokémon is now Confused; if tails, the Defending Pokémon is now Asleep."},
			{"name": "Sticky Nectar", "cost": {"GRASS": 2, "COLORLESS": 1}, "damage": 20, "effect": "Flip a coin. If heads, this attack does 20 damage plus 10 more damage and, until the end of your opponent’s next turn, as long as Gloom is your Active Pokémon, the Defending Pokémon can’t retreat, and if the effect of an attack, Pokémon Power, or Trainer card would change that player’s Active Pokémon, that part of the effect does nothing. If tails, this attack does 20 damage."},
		]
	},
	"granbull": {
		"id": "granbull", "name": "Granbull", "number": "37/111",
		"image": "res://assets/cards/Neo Genesis/granbull-neo-genesis-37.jpg",
		"type": "POKEMON", "pokemon_type": "COLORLESS",
		"hp": 70, "stage": 1, "evolves_from": "snubbull",
		"retreat_cost": 2, "weakness": "FIGHTING", "resistance": "PSYCHIC",
		"rarity": "UNCOMMON",
		"attacks": [
			{"name": "Tackle", "cost": {"COLORLESS": 2}, "damage": 20, "effect": ""},
			{"name": "Raging Charge", "cost": {"COLORLESS": 3}, "damage": 10, "effect": "This attack does 10 damage plus 10 damage for each damage counter on Granbull. Then, Granbull does 20 damage to itself."},
		]
	},
	"lanturn": {
		"id": "lanturn", "name": "Lanturn", "number": "38/111",
		"image": "res://assets/cards/Neo Genesis/lanturn-neo-genesis-38.jpg",
		"type": "POKEMON", "pokemon_type": "LIGHTNING",
		"hp": 70, "stage": 1, "evolves_from": "chinchou",
		"retreat_cost": 2, "weakness": "FIGHTING", "resistance": "",
		"rarity": "UNCOMMON",
		"pokemon_power": {
			"name": "Hydroelectric Power",
			"effect": "You may make Floodlight do 10 more damage for each Water Energy attached to Lanturn but not used to pay for Floodlight's Energy cost. This power can't be used if Lanturn is Asleep, Confused, or Paralyzed."
		},
		"attacks": [
			{"name": "Floodlight", "cost": {"LIGHTNING": 2}, "damage": 20, "effect": "Flip a coin. If heads, the Defending Pokémon is now Paralyzed."}
		]
	},
	"ledian": {
		"id": "ledian", "name": "Ledian", "number": "39/111",
		"image": "res://assets/cards/Neo Genesis/ledian-neo-genesis-39.jpg",
		"type": "POKEMON", "pokemon_type": "GRASS",
		"hp": 60, "stage": 1, "evolves_from": "ledyba",
		"retreat_cost": 1, "weakness": "FIRE", "resistance": "FIGHTING",
		"rarity": "UNCOMMON",
		"attacks": [
			{"name": "Baton Pass", "cost": {"GRASS": 2}, "damage": 30, "effect": "f you have any GRASS Pokémon on your Bench, remove all GRASS Energy cards from Ledian and attach them to 1 of those Pokémon, then switch Ledian with that Pokémon."},
		]
	},
	"magmar": {
		"id": "magmar", "name": "Magmar", "number": "40/111",
		"image": "res://assets/cards/Neo Genesis/magmar-neo-genesis-40.jpg",
		"type": "POKEMON", "pokemon_type": "FIRE",
		"hp": 70, "stage": 0, "evolves_from": "",
		"retreat_cost": 2, "weakness": "WATER", "resistance": "",
		"rarity": "UNCOMMON",
		"attacks": [
			{"name": "Tail Slap", "cost": {"COLORLESS": 2}, "damage": 20, "effect": ""},
			{"name": "Magma Punch", "cost": {"FIRE": 2, "COLORLESS": 1}, "damage": 40, "effect": ""},
		]
	},
	"miltank": {
		"id": "miltank", "name": "Miltank", "number": "41/111",
		"image": "res://assets/cards/Neo Genesis/miltank-neo-genesis-41.jpg",
		"type": "POKEMON", "pokemon_type": "COLORLESS",
		"hp": 70, "stage": 0, "evolves_from": "",
		"retreat_cost": 2, "weakness": "FIGHTING", "resistance": "PSYCHIC",
		"rarity": "UNCOMMON",
		"attacks": [
			{"name": "Milk Drink", "cost": {"COLORLESS": 1}, "damage": 0, "effect": "Flip 2 coins. Remove 2 damage counters times the number of heads from Miltank. If it has fewer damage counters than that, remove all of them."},
			{"name": "Body Slam", "cost": {"COLORLESS": 3}, "damage": 20, "effect": "Flip a coin. If heads, the Defending Pokémon is now Paralyzed."},
		]
	},
	"noctowl": {
		"id": "noctowl", "name": "Noctowl", "number": "42/111",
		"image": "res://assets/cards/Neo Genesis/noctowl-neo-genesis-42.jpg",
		"type": "POKEMON", "pokemon_type": "COLORLESS",
		"hp": 60, "stage": 1, "evolves_from": "hoothoot",
		"retreat_cost": 0, "weakness": "LIGHTNING", "resistance": "FIGHTING",
		"rarity": "UNCOMMON",
		"pokemon_power": {
			"name": "Glaring Gaze",
			"effect": "Once during your turn (before your attack), you may flip a coin. If heads, look at your opponent's hand. If your opponent has any Trainer cards there, choose 1 of them. Your opponent shuffles that card into his or her deck. This power can't be used if Noctowl is Asleep, Confused, or Paralyzed."
		},
		"attacks": [
			{"name": "Wing Attack", "cost": {"COLORLESS": 3}, "damage": 30, "effect": ""}
		]
	},
	"phanpy": {
		"id": "phanpy", "name": "Phanpy", "number": "43/111",
		"image": "res://assets/cards/Neo Genesis/phanpy-neo-genesis-43.jpg",
		"type": "POKEMON", "pokemon_type": "FIGHTING",
		"hp": 40, "stage": 0, "evolves_from": "",
		"retreat_cost": 1, "weakness": "GRASS", "resistance": "LIGHTNING",
		"rarity": "UNCOMMON",
		"attacks": [
			{"name": "Tackle", "cost": {"COLORLESS": 1}, "damage": 10, "effect": ""},
			{"name": "Endure", "cost": {"FIGHTING": 1}, "damage": 0, "effect": "Flip a coin. If heads, then if, during your opponent’s next turn, Phanpy would be Knocked Out by an attack, Phanpy isn’t Knocked Out and its remaining HP become 10 instead."},
		]
	},
	"piloswine": {
		"id": "piloswine", "name": "Piloswine", "number": "44/111",
		"image": "res://assets/cards/Neo Genesis/piloswine-neo-genesis-44.jpg",
		"type": "POKEMON", "pokemon_type": "WATER",
		"hp": 80, "stage": 1, "evolves_from": "swinub",
		"retreat_cost": 3, "weakness": "GRASS", "resistance": "LIGHTNING",
		"rarity": "UNCOMMON",
		"attacks": [
			{"name": "Freeze", "cost": {"WATER": 2}, "damage": 10, "effect": "Flip a coin. If heads, the Defending Pokémon can’t attack. Benching or evolving the Defending Pokémon ends this effect"},
			{"name": "Blizzard", "cost": {"WATER": 3}, "damage": 30, "effect": "Flip a coin. If heads, this attack does 10 damage to each of your opponent’s Benched Pokémon; if tails, this attack does 10 damage to each of your own Benched Pokémon. Don’t apply Weakness and Resistance for Benched Pokémon."},
		]
	},
	"quagsire": {
		"id": "quagsire", "name": "Quagsire", "number": "45/111",
		"image": "res://assets/cards/Neo Genesis/quagsire-neo-genesis-45.jpg",
		"type": "POKEMON", "pokemon_type": "WATER",
		"hp": 70, "stage": 1, "evolves_from": "wooper",
		"retreat_cost": 2, "weakness": "GRASS", "resistance": "LIGHTNING",
		"rarity": "UNCOMMON",
		"attacks": [
			{"name": "Surf", "cost": {"WATER": 2}, "damage": 30, "effect": ""},
			{"name": "Earthquake", "cost": {"FIGHTING": 2, "COLORLESS": 2}, "damage": 60, "effect": "Does 10 damage to each of your own Benched Pokémon. Don’t apply Weakness and Resistance for Benched Pokémon."},
		]
	},
	"quilava_1": {
		"id": "quilava_1", "name": "Quilava", "number": "46/111",
		"image": "res://assets/cards/Neo Genesis/quilava-neo-genesis-46.jpg",
		"type": "POKEMON", "pokemon_type": "FIRE",
		"hp": 60, "stage": 1, "evolves_from": "cyndaquil",
		"retreat_cost": 1, "weakness": "WATER", "resistance": "",
		"rarity": "UNCOMMON",
		"attacks": [
			{"name": "Ember", "cost": {"FIRE": 1, "COLORLESS": 1}, "damage": 30, "effect": "Discard 1 FIRE Energy card attached to Quilava in order to use this attack."},
			{"name": "Fire Wind", "cost": {"FIRE": 2}, "damage": 20, "effect": "f your opponent has any Benched Pokémon, choose 1 of them. Flip 2 coins. For each heads, this attack does 10 damage to that Pokémon. Don’t apply Weakness and Resistance."},
		]
	},
	"quilava_2": {
		"id": "quilava_2", "name": "Quilava", "number": "47/111",
		"image": "res://assets/cards/Neo Genesis/quilava-neo-genesis-47.jpg",
		"type": "POKEMON", "pokemon_type": "FIRE",
		"hp": 70, "stage": 1, "evolves_from": "cyndaquil",
		"retreat_cost": 1, "weakness": "WATER", "resistance": "",
		"rarity": "UNCOMMON",
		"attacks": [
			{"name": "Smokescreen", "cost": {"FIRE": 2}, "damage": 20, "effect": "f the Defending Pokémon tries to attack during your opponent’s next turn, your opponent flips a coin. If tails, that attack does nothing."},
			{"name": "Char", "cost": {"FIRE": 3}, "damage": 30, "effect": "If the Defending Pokémon doesn’t have a Char counter on it, flip a coin. If heads, put a Char counter on it. A Char counter requires your opponent to flip a coin after every turn. If tails, put 2 damage counters on the Pokémon with that Char counter. Char counters stay on the Pokémon as long as it’s in play."},
		]
	},
	"seadra": {
		"id": "seadra", "name": "Seadra", "number": "48/111",
		"image": "res://assets/cards/Neo Genesis/seadra-neo-genesis-48.jpg",
		"type": "POKEMON", "pokemon_type": "WATER",
		"hp": 70, "stage": 1, "evolves_from": "horsea",
		"retreat_cost": 1, "weakness": "LIGHTNING", "resistance": "",
		"rarity": "UNCOMMON",
		"attacks": [
			{"name": "Bubble", "cost": {"WATER": 1}, "damage": 10, "effect": "Flip a coin. If heads, the Defending Pokémon is now Paralyzed."},
			{"name": "Mud Splash", "cost": {"WATER": 2}, "damage": 30, "effect": "If your opponent has any Benched Pokémon, choose 1 of them and flip a coin. If heads, this attack does 10 damage to that Pokémon. Don’t apply Weakness and Resistance for Benched Pokémon."},
		]
	},
	"skiploom": {
		"id": "skiploom", "name": "Skiploom", "number": "49/111",
		"image": "res://assets/cards/Neo Genesis/skiploom-neo-genesis-49.jpg",
		"type": "POKEMON", "pokemon_type": "GRASS",
		"hp": 60, "stage": 1, "evolves_from": "hoppip",
		"retreat_cost": 0, "weakness": "FIRE", "resistance": "FIGHTING",
		"rarity": "UNCOMMON",
		"attacks": [
			{"name": "PoisonPowder", "cost": {"GRASS": 1}, "damage": 10, "effect": "The Defending Pokémon is now Poisoned."},
			{"name": "Stun Spore", "cost": {"GRASS": 1}, "damage": 10, "effect": "Flip a coin. If heads, the Defending Pokémon is now Paralyzed."},
		]
	},
	"sunflora": {
		"id": "sunflora", "name": "Sunflora", "number": "50/111",
		"image": "res://assets/cards/Neo Genesis/sunflora-neo-genesis-50.jpg",
		"type": "POKEMON", "pokemon_type": "GRASS",
		"hp": 70, "stage": 1, "evolves_from": "sunkern",
		"retreat_cost": 1, "weakness": "FIRE", "resistance": "",
		"rarity": "UNCOMMON",
		"attacks": [
			{"name": "Petal Dance ", "cost": {"GRASS": 3}, "damage": 0, "effect": "Flip 3 coins. This attack does 30 damage times the number of heads. Sunflora is now Confused. after doing damage."},
		]
	},
	"togepi": {
		"id": "togepi", "name": "Togepi", "number": "51/111",
		"image": "res://assets/cards/Neo Genesis/togepi-neo-genesis-51.jpg",
		"type": "POKEMON", "pokemon_type": "COLORLESS",
		"hp": 40, "stage": 0, "evolves_from": "",
		"retreat_cost": 1, "weakness": "", "resistance": "PSYCHIC",
		"rarity": "UNCOMMON",
		"attacks": [
			{"name": "Poison Barb", "cost": {"COLORLESS": 1}, "damage": 10, "effect": "The Defending Pokémon is now Poisoned."},
		]
	},
	"xatu": {
		"id": "xatu", "name": "Xatu", "number": "52/111",
		"image": "res://assets/cards/Neo Genesis/xatu-neo-genesis-52.jpg",
		"type": "POKEMON", "pokemon_type": "PSYCHIC",
		"hp": 80, "stage": 1, "evolves_from": "natu",
		"retreat_cost": 1, "weakness": "PSYCHIC", "resistance": "FIGHTING",
		"rarity": "UNCOMMON",
		"attacks": [
			{"name": "Psy Bolt", "cost": {"PSYCHIC": 1}, "damage": 0, "effect": "Look at the top 3 cards of either player’s deck and rearrange them as you like."},
			{"name": "Confuse Ray", "cost": {"PSYCHIC": 3}, "damage": 30, "effect": "Flip a coin. If heads, the Defending Pokémon is now Confused."},
		]
	},
	"chikorita_1": {
		"id": "chikorita_1", "name": "Chikorita", "number": "53/111",
		"image": "res://assets/cards/Neo Genesis/chikorita-neo-genesis-53.jpg",
		"type": "POKEMON", "pokemon_type": "GRASS",
		"hp": 40, "stage": 0, "evolves_from": "",
		"retreat_cost": 1, "weakness": "FIRE", "resistance": "",
		"rarity": "COMMON",
		"attacks": [
			{"name": "Tackle", "cost": {"COLORLESS": 1}, "damage": 10, "effect": ""},
			{"name": "Deflector", "cost": {"GRASS": 1, "COLORLESS": 1}, "damage": 0, "effect": "During your opponent’s next turn, whenever Chikorita takes damage, divide that damage in half rounded down to the nearest 10. Any other effects still happen."},
		]
	},
	"chikorita_2": {
		"id": "chikorita_2", "name": "Chikorita", "number": "54/111",
		"image": "res://assets/cards/Neo Genesis/chikorita-neo-genesis-54.jpg",
		"type": "POKEMON", "pokemon_type": "GRASS",
		"hp": 50, "stage": 0, "evolves_from": "",
		"retreat_cost": 1, "weakness": "FIRE", "resistance": "",
		"rarity": "COMMON",
		"attacks": [
			{"name": "Growl", "cost": {"GRASS": 1}, "damage": 0, "effect": "If the Defending Pokémon attacks Chikorita during your opponent’s next turn, any damage done to Chikorita is reduced by 10 before applying Weakness and Resistance. Benching or evolving either Pokémon ends this effect."},
			{"name": "Poisonpowder", "cost": {"GRASS": 1, "COLORLESS": 1}, "damage": 20, "effect": ""},
		]
	},
	"chinchou": {
		"id": "chinchou", "name": "Chinchou", "number": "55/111",
		"image": "res://assets/cards/Neo Genesis/chinchou-neo-genesis-55.jpg",
		"type": "POKEMON", "pokemon_type": "LIGHTNING",
		"hp": 50, "stage": 0, "evolves_from": "",
		"retreat_cost": 1, "weakness": "FIGHTING", "resistance": "",
		"rarity": "COMMON",
		"attacks": [
			{"name": "Supersonic", "cost": {"LIGHTNING": 1}, "damage": 10, "effect": "Flip a coin. If heads, the Defending Pokémon is now Confused."},
			{"name": "Bubble", "cost": {"WATER": 1}, "damage": 10, "effect": "Does 10 damage times the number of damage counters on Chinchou."},
		]
	},
	"cyndaquil_1": {
		"id": "cyndaquil_1", "name": "Cyndaquil", "number": "56/111",
		"image": "res://assets/cards/Neo Genesis/cyndaquil-neo-genesis-56.jpg",
		"type": "POKEMON", "pokemon_type": "FIRE",
		"hp": 40, "stage": 0, "evolves_from": "",
		"retreat_cost": 1, "weakness": "WATER", "resistance": "",
		"rarity": "COMMON",
		"attacks": [
			{"name": "Leer", "cost": {"COLORLESS": 1}, "damage": 0, "effect": "Flip a coin. If heads, the Defending Pokémon can’t attack Cyndaquil during your opponent’s next turn. Benching or evolving either Pokémon ends this effect."},
			{"name": "Swift", "cost": {"FIRE": 1, "COLORLESS": 1 }, "damage": 20, "effect": "This attack’s damage isn’t affected by Weakness, Resistance, Pokémon Powers, or any other effects on the Defending Pokémon."},
		]
	},
	"cyndaquil_2": {
		"id": "cyndaquil_2", "name": "Cyndaquil", "number": "57/111",
		"image": "res://assets/cards/Neo Genesis/cyndaquil-neo-genesis-57.jpg",
		"type": "POKEMON", "pokemon_type": "FIRE",
		"hp": 50, "stage": 0, "evolves_from": "",
		"retreat_cost": 1, "weakness": "WATER", "resistance": "",
		"rarity": "COMMON",
		"attacks": [
			{"name": "Fireworks", "cost": {"FIRE": 1}, "damage": 20, "effect": "Flip a coin. If tails, discard 1 Energy card attached to Cyndaquil."},
			{"name": "Quick Attack", "cost": {"COLORLESS": 2}, "damage": 10, "effect": "Flip a coin. If heads, this attack does 10 damage plus 20 more damage; if tails, this attack does 10 damage."},
		]
	},
	"girafarig": {
		"id": "girafarig", "name": "Girafarig", "number": "58/111",
		"image": "res://assets/cards/Neo Genesis/girafarig-neo-genesis-58.jpg",
		"type": "POKEMON", "pokemon_type": "PSYCHIC",
		"hp": 60, "stage": 0, "evolves_from": "",
		"retreat_cost": 1, "weakness": "", "resistance": "",
		"rarity": "COMMON",
		"attacks": [
			{"name": "Agility", "cost": {"COLORLESS": 2}, "damage": 10, "effect": "Flip a coin. If heads, during your opponent’s next turn, prevent all effects of attacks, including damage, done to Girafarig."},
			{"name": "Psybeam", "cost": {"PSYCHIC": 2}, "damage": 20, "effect": "Flip a coin. If heads, the Defending Pokémon is now Confused."},
		]
	},
	"gligar": {
		"id": "gligar", "name": "Gligar", "number": "59/111",
		"image": "res://assets/cards/Neo Genesis/gligar-neo-genesis-59.jpg",
		"type": "POKEMON", "pokemon_type": "FIGHTING",
		"hp": 60, "stage": 0, "evolves_from": "",
		"retreat_cost": 1, "weakness": "GRASS", "resistance": "FIGHTING",
		"rarity": "COMMON",
		"attacks": [
			{"name": "Poison Sting", "cost": {"FIGHTING": 1}, "damage": 10, "effect": "Flip a coin. If heads, the Defending Pokémon is now Poisoned."},
			{"name": "Slash", "cost": {"COLORLESS": 2}, "damage": 20, "effect": ""},
		]
	},
	"hoothoot": {
		"id": "hoothoot", "name": "Hoothoot", "number": "60/111",
		"image": "res://assets/cards/Neo Genesis/hoothoot-neo-genesis-60.jpg",
		"type": "POKEMON", "pokemon_type": "COLORLESS",
		"hp": 50, "stage": 0, "evolves_from": "",
		"retreat_cost": 1, "weakness": "LIGHTNING", "resistance": "FIGHTING",
		"rarity": "COMMON",
		"attacks": [
			{"name": "Hypnosis", "cost": {"COLORLESS": 1}, "damage": 0, "effect": "The Defending Pokémon is now Asleep."},
			{"name": "Peck", "cost": {"COLORLESS": 2}, "damage": 20, "effect": ""},
		]
	},
	"hoppip": {
		"id": "hoppip", "name": "Hoppip", "number": "61/111",
		"image": "res://assets/cards/Neo Genesis/hoppip-neo-genesis-61.jpg",
		"type": "POKEMON", "pokemon_type": "GRASS",
		"hp": 50, "stage": 0, "evolves_from": "",
		"retreat_cost": 0, "weakness": "FIRE", "resistance": "FIGHTING",
		"rarity": "COMMON",
		"attacks": [
			{"name": "Hop", "cost": {"GRASS": 1}, "damage": 10, "effect": ""},
			{"name": "Sprout", "cost": {"GRASS": 1}, "damage": 0, "effect": "Search your deck for a Basic Pokémon named Hoppip and put it onto your Bench. Shuffle your deck afterward. You can’t use this attack if your Bench is full."},
		]
	},
	"horsea": {
		"id": "horsea", "name": "Horsea", "number": "62/111",
		"image": "res://assets/cards/Neo Genesis/horsea-neo-genesis-62.jpg",
		"type": "POKEMON", "pokemon_type": "WATER",
		"hp": 50, "stage": 0, "evolves_from": "",
		"retreat_cost": 0, "weakness": "LIGHTNING", "resistance": "",
		"rarity": "COMMON",
		"attacks": [
			{"name": "Fin Slap", "cost": {"WATER": 2}, "damage": 20, "effect": "If an attack damaged Horsea during your opponent’s last turn, this attack does 20 damage plus 10 more damage. If not, this attack does 20 damage."},
		]
	},
	"ledyba": {
		"id": "ledyba", "name": "Ledyba", "number": "63/111",
		"image": "res://assets/cards/Neo Genesis/ledyba-neo-genesis-63.jpg",
		"type": "POKEMON", "pokemon_type": "GRASS",
		"hp": 40, "stage": 0, "evolves_from": "",
		"retreat_cost": 0, "weakness": "FIRE", "resistance": "FIGHTING",
		"rarity": "COMMON",
		"attacks": [
			{"name": "Supersonic", "cost": {"GRASS": 1}, "damage": 0, "effect": "Flip a coin. If heads, the Defending Pokémon is now Confused."},
			{"name": "Comet Punch", "cost": {"GRASS": 2}, "damage": 10, "effect": "Flip 4 coins. This attack does 10 damage times the number of heads."},
		]
	},
	"mantine": {
		"id": "mantine", "name": "Mantine", "number": "64/111",
		"image": "res://assets/cards/Neo Genesis/mantine-neo-genesis-64.jpg",
		"type": "POKEMON", "pokemon_type": "WATER",
		"hp": 60, "stage": 0, "evolves_from": "",
		"retreat_cost": 1, "weakness": "LIGHTNING", "resistance": "FIGHTING",
		"rarity": "COMMON",
		"attacks": [
			{"name": "Undulate", "cost": {"WATER": 2}, "damage": 20, "effect": "Flip a coin. If heads, during your opponent’s next turn, prevent all effects of attacks, including damage, done to Mantine."},
		]
	},
	"mareep": {
		"id": "mareep", "name": "Mareep", "number": "65/111",
		"image": "res://assets/cards/Neo Genesis/mareep-neo-genesis-65.jpg",
		"type": "POKEMON", "pokemon_type": "LIGHTNING",
		"hp": 50, "stage": 0, "evolves_from": "",
		"retreat_cost": 1, "weakness": "FIGHTING", "resistance": "",
		"rarity": "COMMON",
		"attacks": [
			{"name": "Static Electricity", "cost": {"LIGHTNING": 1}, "damage": 0, "effect": "For each Mareep in play, you may search your deck for a LIGHTNING Energy card and attach it to Mareep. Shuffle your deck afterward."},
			{"name": "Thundershock", "cost": {"LIGHTNING": 2}, "damage": 20, "effect": "Flip a coin. If heads, the Defending Pokémon is now Paralyzed."},
		]
	},
	"marill": {
		"id": "marill", "name": "Marill", "number": "66/111",
		"image": "res://assets/cards/Neo Genesis/marill-neo-genesis-66.jpg",
		"type": "POKEMON", "pokemon_type": "WATER",
		"hp": 40, "stage": 0, "evolves_from": "",
		"retreat_cost": 1, "weakness": "LIGHTNING", "resistance": "",
		"rarity": "COMMON",
		"attacks": [
			{"name": "Defense Curle", "cost": {"COLORLESS": 1}, "damage": 10, "effect": "Flip a coin. If heads, prevent all damage done to Marill during your opponent’s next turn. Any other effects of attacks still happen."},
			{"name": "Bubble Bomb", "cost": {"WATER": 2}, "damage": 20, "effect": "Flip a coin. If heads, the Defending Pokémon is now Paralyzed. If tails, Marril does 10 damage to itself."},
		]
	},
	"natu": {
		"id": "natu", "name": "Natu", "number": "67/111",
		"image": "res://assets/cards/Neo Genesis/natu-neo-genesis-67.jpg",
		"type": "POKEMON", "pokemon_type": "PSYCHIC",
		"hp": 30, "stage": 0, "evolves_from": "",
		"retreat_cost": 0, "weakness": "PSYCHIC", "resistance": "FIGHTING",
		"rarity": "COMMON",
		"attacks": [
			{"name": "Peck", "cost": {"COLORLESS": 1}, "damage": 10, "effect": ""},
			{"name": "Telekinesis", "cost": {"PSYCHIC": 1}, "damage": 0, "effect": "Choose 1 of your opponent’s Pokémon. This attack does 20 damage to that Pokémon. Don’t apply Weakness and Resistance for this attack. (Any other effects that would happen after applying Weakness and Resistance still happen.)"},
		]
	},
	"oddish": {
		"id": "oddish", "name": "Oddish", "number": "68/111",
		"image": "res://assets/cards/Neo Genesis/oddish-neo-genesis-68.jpg",
		"type": "POKEMON", "pokemon_type": "GRASS",
		"hp": 40, "stage": 0, "evolves_from": "",
		"retreat_cost": 1, "weakness": "FIRE", "resistance": "",
		"rarity": "COMMON",
		"attacks": [
			{"name": "Hide", "cost": {"COLORLESS": 1}, "damage": 0, "effect": "Flip a coin. If heads, during your opponent’s next turn, prevent all effects of attacks, including damage, done to Oddish."},
			{"name": "Absorb", "cost": {"GRASS": 2}, "damage": 20, "effect": "Remove a number of damage counters from Oddish equal to half the damage done to the Defending Pokémon after applying Weakness and Resistance ,rounded up to the nearest 10. If Oddish has fewer damage counters than that, remove all of them."},
		]
	},
	"onix": {
		"id": "onix", "name": "Onix", "number": "69/111",
		"image": "res://assets/cards/Neo Genesis/onix-neo-genesis-69.jpg",
		"type": "POKEMON", "pokemon_type": "FIGHTING",
		"hp": 60, "stage": 0, "evolves_from": "",
		"retreat_cost": 2, "weakness": "GRASS", "resistance": "",
		"rarity": "COMMON",
		"attacks": [
			{"name": "Screech", "cost": {"COLORLESS": 1}, "damage": 0, "effect": "Until the end of your next turn, if an attack damages the Defending Pokémon after applying Weakness and Resistance, that attack does 20 more damage to the Defending Pokémon."},
			{"name": "Rage", "cost": {"FIGHTING": 2}, "damage": 20, "effect": "Does 10 damage plus 10 more damage for each damage counter on Onix."},
		]
	},
	"pikachu": {
		"id": "pikachu", "name": "Pikachu", "number": "70/111",
		"image": "res://assets/cards/Neo Genesis/pikachu-neo-genesis-70.jpg",
		"type": "POKEMON", "pokemon_type": "LIGHTNING",
		"hp": 50, "stage": 0, "evolves_from": "",
		"retreat_cost": 1, "weakness": "FIGHTING", "resistance": "",
		"rarity": "COMMON",
		"attacks": [
			{"name": "Quick Attack", "cost": {"COLORLESS": 1}, "damage": 10, "effect": "Flip a coin. If heads, this attack does 10 damage plus 20 more damage; if tails, this attack does 10 damage.Flip a coin. If heads, this attack does 10 damage plus 20 more damage; if tails, this attack does 10 damage."},
			{"name": "Agility", "cost": {"LIGHTNING": 2, "COLORLESS": 1}, "damage": 20, "effect": "Flip a coin. If heads, during your opponent’s next turn, prevent all effects of attacks, including damage, done to Pikachu."},
		]
	},
	"sentret": {
		"id": "sentret", "name": "Sentret", "number": "71/111",
		"image": "res://assets/cards/Neo Genesis/sentret-neo-genesis-71.jpg",
		"type": "POKEMON", "pokemon_type": "COLORLESS",
		"hp": 40, "stage": 0, "evolves_from": "",
		"retreat_cost": 1, "weakness": "FIGHTING", "resistance": "PSYCHIC",
		"rarity": "COMMON",
		"attacks": [
			{"name": "Fury Swipes", "cost": {"COLORLESS": 1}, "damage": 10, "effect": "Flip 3 coins. This attack does 10 damage times the number of heads."},
		]
	},
	"shuckle": {
		"id": "shuckle", "name": "Shuckle", "number": "72/111",
		"image": "res://assets/cards/Neo Genesis/shuckle-neo-genesis-72.jpg",
		"type": "POKEMON", "pokemon_type": "GRASS",
		"hp": 30, "stage": 0, "evolves_from": "",
		"retreat_cost": 1, "weakness": "GRASS", "resistance": "LIGHTNING",
		"rarity": "COMMON",
		"attacks": [
			{"name": "Withdraw", "cost": {"GRASS": 1}, "damage": 0, "effect": "Flip a coin. If heads, prevent all damage done to Shuckle during your opponent’s next turn. Any other effects of attacks still happen."},
			{"name": "Wrap", "cost": {"GRASS": 2}, "damage": 20, "effect": "Flip a coin. If heads, the Defending Pokémon is now Paralyzed."},
		]
	},
	"slowpoke": {
		"id": "slowpoke", "name": "Slowpoke", "number": "73/111",
		"image": "res://assets/cards/Neo Genesis/slowpoke-neo-genesis-73.jpg",
		"type": "POKEMON", "pokemon_type": "PSYCHIC",
		"hp": 50, "stage": 0, "evolves_from": "",
		"retreat_cost": 1, "weakness": "PSYCHIC", "resistance": "",
		"rarity": "COMMON",
		"attacks": [
			{"name": "Psyshock", "cost": {"PSYCHIC": 1}, "damage": 10, "effect": "Flip a coin. If heads, the Defending Pokémon is now Paralyzed."},
			{"name": "Water Gun", "cost": {"WATER": 1}, "damage": 10, "effect": "Does 10 damage plus 10 more damage for each {W} Energy attached to Slowpoke but not used to pay for this attack’s Energy cost. You can’t add more than 20 damage in this way."},
		]
	},
	"snubbull": {
		"id": "snubbull", "name": "Snubbull", "number": "74/111",
		"image": "res://assets/cards/Neo Genesis/snubbull-neo-genesis-74.jpg",
		"type": "POKEMON", "pokemon_type": "COLORLESS",
		"hp": 50, "stage": 0, "evolves_from": "",
		"retreat_cost": 1, "weakness": "FIGHTING", "resistance": "PSYCHIC",
		"rarity": "COMMON",
		"attacks": [
			{"name": "Roar", "cost": {"COLORLESS": 1}, "damage": 0, "effect": "Flip a coin. If heads and if your opponent has any Benched Pokémon, he of she chooses 1 of them and switches it with the Defending Pokémon. Do the damage before switching the Pokémon"},
			{"name": "Lick", "cost": {"COLORLESS": 2}, "damage": 10, "effect": "Flip a coin. If heads, the Defending Pokémon is now Paralyzed."},
		]
	},
	"spinarak": {
		"id": "spinarak", "name": "Spinarak", "number": "75/111",
		"image": "res://assets/cards/Neo Genesis/spinarak-neo-genesis-75.jpg",
		"type": "POKEMON", "pokemon_type": "GRASS",
		"hp": 40, "stage": 0, "evolves_from": "",
		"retreat_cost": 1, "weakness": "FIRE", "resistance": "",
		"rarity": "COMMON",
		"attacks": [
			{"name": "Scary Face", "cost": {"GRASS": 1}, "damage": 0, "effect": "Flip a coin. If heads, until the end of your opponent’s next turn, the Defending Pokémon can’t attack or retreat."},
			{"name": "String Shot", "cost": {"GRASS": 1}, "damage": 10, "effect": "Flip a coin. If heads, the Defending Pokémon is now Paralyzed."},
		]
	},
	"stantler": {
		"id": "stantler", "name": "Stantler", "number": "76/111",
		"image": "res://assets/cards/Neo Genesis/stantler-neo-genesis-76.jpg",
		"type": "POKEMON", "pokemon_type": "COLORLESS",
		"hp": 60, "stage": 0, "evolves_from": "",
		"retreat_cost": 2, "weakness": "FIGHTING", "resistance": "PSYCHIC",
		"rarity": "COMMON",
		"attacks": [
			{"name": "Stomp", "cost": {"COLORLESS": 2}, "damage": 20, "effect": "Flip a coin. If heads, this attack does 20 damage plus 10 more damage; if tails, this attack does 20 damage."},
			{"name": "Mystifying Horns", "cost": {"COLORLESS": 3}, "damage": 20, "effect": "Flip a coin. If heads, the Defending Pokémon is now Confused."},
		]
	},
	"sudowoodo": {
		"id": "sudowoodo", "name": "Sudowoodo", "number": "77/111",
		"image": "res://assets/cards/Neo Genesis/sudowoodo-neo-genesis-77.jpg",
		"type": "POKEMON", "pokemon_type": "FIGHTING",
		"hp": 60, "stage": 0, "evolves_from": "",
		"retreat_cost": 3, "weakness": "GRASS", "resistance": "LIGHTNING",
		"rarity": "COMMON",
		"attacks": [
			{"name": "Flail", "cost": {"FIGHTING": 2}, "damage": 10, "effect": "Does 10 damage times the number of damage counters on Sudowoodo."},
			{"name": "Rock Throw", "cost": {"FIGHTING": 1, "COLORLESS": 1}, "damage": 30, "effect": ""},
		]
	},
	"sunkern": {
		"id": "sunkern", "name": "Sunkern", "number": "78/111",
		"image": "res://assets/cards/Neo Genesis/sunkern-neo-genesis-78.jpg",
		"type": "POKEMON", "pokemon_type": "GRASS",
		"hp": 40, "stage": 0, "evolves_from": "",
		"retreat_cost": 2, "weakness": "FIRE", "resistance": "",
		"rarity": "COMMON",
		"attacks": [
			{"name": "Growth", "cost": {"GRASS": 1}, "damage": 0, "effect": "Flip a coin. If heads, you may attach up to 2 GRASS Energy cards from your hand to Sunkern."},
			{"name": "Mega Drain", "cost": {"GRASS": 3}, "damage": 30, "effect": "Remove a number of damage counters from Sunkern equal to half the damage done to the Defending Pokémon , after applying Weakness and Resistance,rounded up to the nearest 10. If Sunkern has fewer damage counters than that, remove all of them."},
		]
	},
	"swinub": {
		"id": "swinub", "name": "Swinub", "number": "79/111",
		"image": "res://assets/cards/Neo Genesis/swinub-neo-genesis-79.jpg",
		"type": "POKEMON", "pokemon_type": "WATER",
		"hp": 40, "stage": 0, "evolves_from": "",
		"retreat_cost": 1, "weakness": "GRASS", "resistance": "LIGHTNING",
		"rarity": "COMMON",
		"attacks": [
			{"name": "Powder Snow", "cost": {"WATER": 1}, "damage": 10, "effect": "The Defending Pokémon is now Asleep."},
		]
	},
	"totodile_1": {
		"id": "totodile_1", "name": "Totodile", "number": "80/111",
		"image": "res://assets/cards/Neo Genesis/totodile-neo-genesis-80.jpg",
		"type": "POKEMON", "pokemon_type": "WATER",
		"hp": 40, "stage": 0, "evolves_from": "",
		"retreat_cost": 1, "weakness": "GRASS", "resistance": "",
		"rarity": "COMMON",
		"attacks": [
			{"name": "Bite", "cost": {"COLORLESS": 1}, "damage": 10, "effect": ""},
			{"name": "Rage", "cost": {"WATER": 1, "COLORLESS": 1}, "damage": 20, "effect": "Does 10 damage plus 10 more damage for each damage counter on Totodile."},
		]
	},
	"totodile_2": {
		"id": "totodile_2", "name": "Totodile", "number": "81/111",
		"image": "res://assets/cards/Neo Genesis/totodile-neo-genesis-81.jpg",
		"type": "POKEMON", "pokemon_type": "WATER",
		"hp": 50, "stage": 0, "evolves_from": "",
		"retreat_cost": 1, "weakness": "LIGHTNING", "resistance": "",
		"rarity": "COMMON",
		"attacks": [
			{"name": "Leer", "cost": {"COLORLESS": 1}, "damage": 0, "effect": "Flip a coin. If heads, the Defending Pokémon can’t attack Totodile during your opponent’s next turn. Benching or evolving either Pokémon ends this effect."},
			{"name": "Fury Swipes", "cost": {"WATER": 1}, "damage": 10, "effect": "Flip 3 coins. This attack does 10 damage times the number of heads."},
		]
	},
	"wooper": {
		"id": "wooper", "name": "Wooper", "number": "82/111",
		"image": "res://assets/cards/Neo Genesis/wooper-neo-genesis-82.jpg",
		"type": "POKEMON", "pokemon_type": "WATER",
		"hp": 50, "stage": 0, "evolves_from": "",
		"retreat_cost": 2, "weakness": "GRASS", "resistance": "LIGHTNING",
		"rarity": "COMMON",
		"attacks": [
			{"name": "Amnesia", "cost": {"WATER": 1}, "damage": 10, "effect": "Choose 1 of the Defending Pokémon’s attacks. That Pokémon can’t use that attack during your opponent’s next turn."},
			{"name": "Slam", "cost": {"COLORLESS": 2}, "damage": 20, "effect": "Flip 2 coins. This attack does 20 damage times the number of heads."},
		]
	},
	# TRAINERS
	"arcade_game": {"id": "arcade_game", "name": "Arcade Game", "number": "83/111", "image": "res://assets/cards/Neo Genesis/arcade-game-neo-genesis-83.jpg", "type": "TRAINER", "trainer_type": "ITEM", "rarity": "UNCOMMON", "effect": "Shuffle your deck, then reveal the top 3 cards of it. If at least 2 of those cards share the same name, put all of the ones with that name into your hand and shuffle the rest into your deck. If none of them do, shuffle all 3 into your deck."},
	"ecogym": {"id": "ecogym", "name": "Ecogym", "number": "84/111", "image": "res://assets/cards/Neo Genesis/ecogym-neo-genesis-84.jpg", "type": "TRAINER", "trainer_type": "STADIUM", "rarity": "UNCOMMON", "effect": "Whenever an attack, Pokémon Power, or Trainer card discards another player’s non- COLORLESS Energy card from a Pokémon, return that Energy card to its owner’s hand. Energy cards that are discarded when that Pokémon is Knocked Out don’t count."},
	"energy_charge": {"id": "energy_charge", "name": "Energy Charge", "number": "85/111", "image": "res://assets/cards/Neo Genesis/energy-charge-neo-genesis-85.jpg", "type": "TRAINER", "trainer_type": "ITEM", "rarity": "UNCOMMON", "effect": "Flip a coin. If heads, shuffle up to 2 Energy cards from your discard pile into your deck.."},
	"focus_band": {"id": "focus_band", "name": "Focus Band", "number": "86/111", "image": "res://assets/cards/Neo Genesis/focus-band-neo-genesis-86.jpg", "type": "TRAINER", "trainer_type": "POKEMON_TOOL", "rarity": "UNCOMMON", "effect": "If the Pokémon Focus Band is attached to would be Knocked Out by your opponent’s attack, flip a coin. If heads, that Pokémon is not Knocked Out and its remaining HP become 10 instead. Then, discard Focus Band."},
	"mary": {"id": "mary", "name": "Mary", "number": "87/111", "image": "res://assets/cards/Neo Genesis/mary-neo-genesis-87.jpg", "type": "TRAINER", "trainer_type": "SUPPORTER", "rarity": "UNCOMMON", "effect": "Draw 2 cards. Then, shuffle 2 cards from your hand into your deck."},
	"pokegear": {"id": "pokegear", "name": "Pokégear", "number": "88/111", "image": "res://assets/cards/Neo Genesis/pokegear-neo-genesis-88.jpg", "type": "TRAINER", "trainer_type": "ITEM", "rarity": "UNCOMMON", "effect": "Look at the top 7 cards of your deck. If any of them are Trainer cards, you may show 1 of them to your opponent and put it into your hand. Shuffle your deck afterward. You can’t play any more Trainer cards this turn."},
	"super_energy_retrieval": {"id": "super_energy_retrieval", "name": "Super Energy Retrieval", "number": "89/111", "image": "res://assets/cards/Neo Genesis/super-energy-retrieval-neo-genesis-89.jpg", "type": "TRAINER", "trainer_type": "ITEM", "rarity": "UNCOMMON", "effect": "You can use this card only if you discard 1 Basic Energy card from your hand. Choose up to 4 Basic Energy cards from your discard pile and put them into your hand. You cannot choose any cards discarded to pay the cost of using this card."},
	"time_capsule": {"id": "time_capsule", "name": "Time Capsule", "number": "90/111", "image": "res://assets/cards/Neo Genesis/time-capsule-neo-genesis-90.jpg", "type": "TRAINER", "trainer_type": "ITEM", "rarity": "UNCOMMON", "effect": "Your opponent may choose 5 Basic Pokémon, Evolution, and/or basic Energy cards in his or her discard pile. (If your opponent doesn’t have that many, he or she chooses all or none of them.) If your opponent chooses any cards, he or she shuffles them into his or her deck. Either way, you may do the same, and you can’t play any more Trainer cards this turn."},
	"bills_teleporter": {"id": "bills_teleporter", "name": "Bill's Teleporter", "number": "91/111", "image": "res://assets/cards/Neo Genesis/bills-teleporter-neo-genesis-91.jpg", "type": "TRAINER", "trainer_type": "ITEM", "rarity": "COMMON", "effect": "Flip a coin. If heads, draw 4 cards."},
	"card_flip_game": {"id": "card_flip_game", "name": "Card-Flip Game", "number": "92/111", "image": "res://assets/cards/Neo Genesis/card-flip-game-neo-genesis-92.jpg", "type": "TRAINER", "trainer_type": "ITEM", "rarity": "COMMON", "effect": "Choose 1 of your opponent’s face-down Prizes. Guess whether it is an Energy card, a Trainer card, or a Pokémon (Basic or Evolution) card. Flip the card face up (and leave it face up). If you guessed right, draw 2 cards"},
	"gold_berry": {"id": "gold_berry", "name": "Gold Berry", "number": "93/111", "image": "res://assets/cards/Neo Genesis/gold-berry-neo-genesis-93.jpg", "type": "TRAINER", "trainer_type": "POKEMON_TOOL", "rarity": "UNCOMMON", "effect": "At any time between turns, if there are at least 4 damage counters on the Pokémon Gold Berry is attached to, you may remove 4 of them and discard Gold Berry. At the start of each turn, if there are at least 4 damage counters on the Pokémon Gold Berry is attached to, remove 4 of them and discard Gold Berry"},
	"miracle_berry": {"id": "miracle_berry", "name": "Miracle Berry", "number": "94/111", "image": "res://assets/cards/Neo Genesis/miracle-berry-neo-genesis-94.jpg", "type": "TRAINER", "trainer_type": "POKEMON_TOOL", "rarity": "UNCOMMON", "effect": "At any time between turns, if the Pokémon Miracle Berry is attached to is Asleep, Confused, Paralyzed, or Poisoned, you may remove all those effects from that Pokémon and discard Miracle Berry. At the start of each turn, if the Pokémon Miracle Berry is attached to is Asleep, Confused, Paralyzed, or Poisoned, remove all of those effects from that Pokémon and discard Miracle Berry."},
	"new_pokedex": {"id": "new_pokedex", "name": "New Pokédex", "number": "95/111", "image": "res://assets/cards/Neo Genesis/new-pokedex-neo-genesis-95.jpg", "type": "TRAINER", "trainer_type": "ITEM", "rarity": "COMMON", "effect": "Shuffle your deck. Then, look at up to 5 cards from the top of your deck and rearrange them as you like."},
	"professor_elm": {"id": "professor_elm", "name": "Professor Elm", "number": "96/111", "image": "res://assets/cards/Neo Genesis/professor-elm-neo-genesis-96.jpg", "type": "TRAINER", "trainer_type": "SUPPORTER", "rarity": "UNCOMMON", "effect": "Shuffle your hand into your deck. Then, draw 7 cards. You can’t play any more Trainer cards this turn."},
	"sprout_tower": {"id": "sprout_tower", "name": "Sprout Tower", "number": "97/111", "image": "res://assets/cards/Neo Genesis/sprout-tower-neo-genesis-97.jpg", "type": "TRAINER", "trainer_type": "STADIUM", "rarity": "COMMON", "effect": "All damage done by COLORLESS Pokémon’s attacks is reduced by 30 after applying Weakness and Resistance."},
	"super_scoop_up": {"id": "super_scoop_up", "name": "Super Scoop Up", "number": "98/111", "image": "res://assets/cards/Neo Genesis/super-scoop-up-neo-genesis-98.jpg", "type": "TRAINER", "trainer_type": "ITEM", "rarity": "UNCOMMON", "effect": "Flip a coin. If heads, return 1 of your Pokémon and all cards attached to it to your hand."},
	"berry": {"id": "berry", "name": "Berry", "number": "99/111", "image": "res://assets/cards/Neo Genesis/berry-neo-genesis-99.jpg", "type": "TRAINER", "trainer_type": "POKEMON_TOOL", "rarity": "COMMON", "effect": "At any time between turns, if there are at least 2 damage counters on the Pokémon Berry is attached to, you may remove 2 of them and discard Berry. At the start of each turn, if there are at least 2 damage counters on the Pokémon Berry is attached to, remove 2 of them and discard Berry."},
	"double_gust": {"id": "double_gust", "name": "Double Gust", "number": "100/111", "image": "res://assets/cards/Neo Genesis/double-gust-neo-genesis-100.jpg", "type": "TRAINER", "trainer_type": "ITEM", "rarity": "COMMON", "effect": "If you have any Benched Pokémon, your opponent chooses 1 of them and switches it with your Active Pokémon. Then, if your opponent has any Benched Pokémon, choose 1 of them and switch it with his or her Active Pokémon."},
	"moo_moo_milk": {"id": "moo_moo_milk", "name": "Moo-Moo Milk", "number": "101/111", "image": "res://assets/cards/Neo Genesis/moo-moo-milk-neo-genesis-101.jpg", "type": "TRAINER", "trainer_type": "ITEM", "rarity": "COMMON", "effect": "Choose 1 of your Pokémon. Flip 2 coins. Remove 2 damage counters times the number of heads from that Pokémon. If the Pokémon has fewer damage counters than that, remove all of them."},
	"pokemon_march": {"id": "pokemon_march", "name": "Pokémon March", "number": "102/111", "image": "res://assets/cards/Neo Genesis/pokemon-march-neo-genesis-102.jpg", "type": "TRAINER", "trainer_type": "ITEM", "rarity": "COMMON", "effect": "Your opponent may search his or her deck for 1 Basic Pokémon card and put it onto his or her Bench. Then, you may search your deck for 1 Basic Pokémon card and put it onto your Bench. Then, each player shuffles his or her deck. A player can’t do any of this if his or her Bench is full."},
	"super_rod": {"id": "super_rod", "name": "Super Rod", "number": "103/111", "image": "res://assets/cards/Neo Genesis/super-rod-neo-genesis-103.jpg", "type": "TRAINER", "trainer_type": "ITEM", "rarity": "COMMON", "effect": "Flip a coin. If heads, put an Evolution card from your discard pile, if any, into your hand. If tails, put a Basic Pokémon card from your discard pile, if any, into your hand."},

	# ENERGÍAS ESPECIALES
	"darkness_energy": {"id": "darkness_energy", "name": "Darkness Energy", "number": "104/111", "image": "res://assets/cards/Neo Genesis/darkness-energy-neo-genesis-104.jpg", "type": "ENERGY", "energy_type": "DARKNESS", "provides": 1, "rarity": "RARE"},
	"recycle_energy": {"id": "recycle_energy", "name": "Recycle Energy", "number": "105/111", "image": "res://assets/cards/Neo Genesis/recycle-energy-neo-genesis-105.jpg", "type": "ENERGY", "energy_type": "COLORLESS", "provides": 1, "rarity": "UNCOMMON"},

	# ENERGÍAS BÁSICAS
	"fighting_energy": {"id": "fighting_energy", "name": "Fighting Energy", "number": "106/111", "image": "res://assets/cards/Neo Genesis/fighting-energy-neo-genesis-106.jpg", "type": "ENERGY", "energy_type": "FIGHTING", "provides": 1, "rarity": "COMMON"},
	"fire_energy": {"id": "fire_energy", "name": "Fire Energy", "number": "107/111", "image": "res://assets/cards/Neo Genesis/fire-energy-neo-genesis-107.jpg", "type": "ENERGY", "energy_type": "FIRE", "provides": 1, "rarity": "COMMON"},
	"grass_energy": {"id": "grass_energy", "name": "Grass Energy", "number": "108/111", "image": "res://assets/cards/Neo Genesis/grass-energy-neo-genesis-108.jpg", "type": "ENERGY", "energy_type": "GRASS", "provides": 1, "rarity": "COMMON"},
	"lightning_energy": {"id": "lightning_energy", "name": "Lightning Energy", "number": "109/111", "image": "res://assets/cards/Neo Genesis/lightning-energy-neo-genesis-109.jpg", "type": "ENERGY", "energy_type": "LIGHTNING", "provides": 1, "rarity": "COMMON"},
	"psychic_energy": {"id": "psychic_energy", "name": "Psychic Energy", "number": "110/111", "image": "res://assets/cards/Neo Genesis/psychic-energy-neo-genesis-110.jpg", "type": "ENERGY", "energy_type": "PSYCHIC", "provides": 1, "rarity": "COMMON"},
	"water_energy": {"id": "water_energy", "name": "Water Energy", "number": "111/111", "image": "res://assets/cards/Neo Genesis/water-energy-neo-genesis-111.jpg", "type": "ENERGY", "energy_type": "WATER", "provides": 1, "rarity": "COMMON"},
}

func get_card(card_id: String) -> Dictionary:
	return CARDS.get(card_id, {})

func get_energy_type(card_id: String) -> String:
	return CARDS.get(card_id, {}).get("energy_type", "COLORLESS")

func create_card_instance(card_id: String) -> Node:
	var card_scene = load("res://scenes/components/Card.tscn")
	if card_scene == null:
		push_error("CardDatabase: Could not load Card.tscn")
		return Node.new()
	var instance = card_scene.instantiate()
	var data = get_card(card_id)
	if not data.is_empty():
		instance.setup(data)
	return instance

func get_cards_by_type(type: String) -> Array:
	var result = []
	for id in CARDS:
		if CARDS[id].get("type") == type:
			result.append(CARDS[id])
	return result

func get_all_ids() -> Array:
	return CARDS.keys()

func get_all_pokemon_ids() -> Array:
	var result = []
	for id in CARDS:
		if CARDS[id].get("type") == "POKEMON":
			result.append(id)
	return result
