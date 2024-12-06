extends Node2D

# NEED TO DO:

# - QOL improvements
	# - Animations- cards coming into hand at the start of the game
	# - Sound effects
	# - Counter of abilities able to be used in the corner

# - Tutorial

# TUTORIAL TEXT:
#Each player starts with four cards face down in their hand. Every card has a value, and the aim of the game is to have
#a hand with cards that sum to the lowest value. Ace is worth 1, 2 is worth 2, and so on. Face cards (J,Q,K) are worth 10, and
#Jokers are worth 0. 
#
#The game ends when a player thinks they have the lowest hand and, at the end of their turn, calls "Dutch", where other
#players get one more turn, and then all cards are revealed.
#
#Players take turns. On each turn you can draw a card either from the draw pile or the discard pile. However you can't take a discarded
#face card. Since there are no discarded cards, let's draw from the draw pile.
#
#You can look at the cards you draw, and you can either discard it directly or swap it with one of the cards in your hand, and discard
#the swapped card. Since it's nice to know what cards you have, let's swap this with one of our cards.
#
#If at any point you have a card with the same value as the top card in the discard pile, you can play it directly from your hand, 
#decreasing the number of cards in your hand by one. If you draw a card with the same value as the top card in the discard pile and
#discard it directly, you can discard an extra card from you hand.
#
#Face cards have abilities that trigger when you play them. A King gives an opponent an extra card in their hand. A Queen lets you
#look at any card in anyone's hand. A Jack lets you either look at any card, or swap one of any two player's cards.


var card = preload("res://Scenes/Components/Card.tscn")
var cardPile = preload("res://Scenes/Components/CardPile.tscn")

var end_turn_button
var dutch_button
var info_box

var button_height = 80
var end_turn_button_width = 250
var dutch_button_width = 200

var dutch_button_x
var dutch_button_y
var end_turn_button_x
var end_turn_button_y

var draw_pile

func _ready():
	global.reset()
	
	create_deck()
	
	var base_x = global.screen_size[0] / 4
	var base_y = global.screen_size[1] / 3
	# Spawn own cards
	for i in range(4):
		spawn_card(Vector2(base_x * (2 * i + 1), base_y * 5), "player")
	# Spawn opponent cards
	for i in range(4):
		spawn_card(Vector2(base_x * (2 * i + 1), base_y), "computer")

	for i in range(7):
			spawn_pile(base_x * (i + 1), base_y, i % 2 == 0)
	
	end_turn_button = $EndTurnButton
	dutch_button = $DutchButton
	info_box = $InfoBox
	draw_pile = $DrawPile
	
	dutch_button_x = base_x * 6 + (end_turn_button_width - dutch_button_width) / 2
	dutch_button_y = base_y * 3 + 15
	end_turn_button_x = base_x * 6
	end_turn_button_y = base_y * 3 - button_height - 15
	
	$DiscardPile.initialize(Vector2(base_x * 4, base_y * 3))
	$PlaceholderCard.initialize(Vector2(base_x * 4, base_y * 3))
	end_turn_button.initialize(Vector2(end_turn_button_x, end_turn_button_y))
	dutch_button.initialize(Vector2(dutch_button_x, dutch_button_y))
	info_box.initialize(Vector2(base_x, base_y * 3))
	draw_pile.initialize(Vector2(base_x * 5, base_y * 3))
	$Computer.initialize()
	$AbilityLabel.global_position = Vector2(base_x - 70, global.screen_size[1] * 2 - 120)

func spawn_card(origin: Vector2, parent: String):
	var card_obj = card.instantiate()
	add_child(card_obj)
	card_obj.create(origin, parent)

func spawn_pile(origin_x: float, origin_y: float, occupied: bool):
	var player_pile = cardPile.instantiate()
	var computer_pile = cardPile.instantiate()
	add_child(player_pile)
	add_child(computer_pile)
	player_pile.initialize(Vector2(origin_x, origin_y * 5), "player", occupied)
	computer_pile.initialize(Vector2(origin_x, origin_y), "computer", occupied)
	global.computer_piles.append(computer_pile)
	global.player_piles.append(player_pile)

# Function to create and shuffle the deck of cards
func create_deck():
	# Numbers 0 to 4 representing the suits in order: Spades, diamonds, clubs, hearts
	var suits = [0, 1, 2, 3]
	# 11, 12, 13 are Jack, Queen, King respectively
	var values = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13]

	# For each suit value pair append it to a global variable calle deck, then shuffle it all
	for value in values:
		for suit in suits:
			global.deck.append({"suit": suit,"value": value})
	global.deck.shuffle()
	#global.deck.reverse()


func _on_dutch_button_pressed():
	end_player_turn()
	global.dutch = true
	info_box.alert_dutch(true)

func _on_end_turn_button_pressed():
	end_player_turn()
	if global.dutch == true:
		await get_tree().create_timer(0.5).timeout
		global.end_game()

func end_player_turn():
	end_turn_button.visible = false
	dutch_button.visible = false
	info_box.remove_alert()
	if global.dutch:
		global.end_game()
	else:
		global.player_turn = false
		global.discard_card = false
		global.active_abilities.clear()
		draw_pile.next_card()
		if len(global.deck) == 0:
			global.deck_empty()

func _on_dutch_button_button_down():
	dutch_button.scale = Vector2(0.95, 0.95)
	dutch_button.global_position.x = dutch_button_x + dutch_button_width * 0.025
	dutch_button.global_position.y = dutch_button_y + button_height * 0.025

func _on_dutch_button_mouse_entered():
	dutch_button.scale = Vector2(1.05, 1.05)
	dutch_button.global_position.x = dutch_button_x - dutch_button_width * 0.025
	dutch_button.global_position.y = dutch_button_y - button_height * 0.025

func _on_dutch_button_mouse_exited():
	dutch_button.scale = Vector2(1, 1)
	dutch_button.global_position = Vector2(dutch_button_x, dutch_button_y)


func _on_end_turn_button_button_down():
	end_turn_button.scale = Vector2(0.95, 0.95)
	end_turn_button.global_position.x = end_turn_button_x + end_turn_button_width * 0.025
	end_turn_button.global_position.y = end_turn_button_y + button_height * 0.025

func _on_end_turn_button_mouse_entered():
	end_turn_button.scale = Vector2(1.05, 1.05)
	end_turn_button.global_position.x = end_turn_button_x - end_turn_button_width * 0.025
	end_turn_button.global_position.y = end_turn_button_y - button_height * 0.025

func _on_end_turn_button_mouse_exited():
	end_turn_button.scale = Vector2(1, 1)
	end_turn_button.global_position = Vector2(end_turn_button_x, end_turn_button_y)


func _on_menu_button_pressed():
	SceneSwitcher.switch_scene("res://Scenes/StartGame.tscn")

func _on_menu_button_button_down():
	global.menu_button.scale = Vector2(0.95, 0.95)
	global.menu_button.global_position.x = global.menu_button_position[0] + global.menu_button_width * 0.025
	global.menu_button.global_position.y = global.menu_button_position[1] + global.menu_button_height * 0.025

func _on_menu_button_mouse_entered():
	global.menu_button.scale = Vector2(1.05,1.05)
	global.menu_button.global_position.x = global.menu_button_position[0] - global.menu_button_width * 0.025
	global.menu_button.global_position.y = global.menu_button_position[1] - global.menu_button_height * 0.025

func _on_menu_button_mouse_exited():
	global.menu_button.scale = Vector2(1,1)
	global.menu_button.global_position = global.menu_button_position
