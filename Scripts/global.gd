extends Node

var screen_size: Vector2

var card_back: int = 53

var dutch: bool = false

var is_dragging: bool = false
var dragged_card: StaticBody2D = null

var deck = [{"value": 0, "suit": -1}, {"value": 0, "suit": -1}]

var computer_piles = []
var player_piles = []

var card_look: bool = true
var player_turn: bool = true
var draw_card: bool = true
var discard_card: bool = false

var active_abilities: Array = []

var draw_pile: StaticBody2D
var computer: Node
var result_label: RichTextLabel
var info_box: Control
var menu_button: Button
var menu_button_width: float = 380
var menu_button_height: float = 130
var menu_button_position: Vector2

var observed_cards = {}

func reset():
	screen_size = get_node("/root/Main/Game Camera").get_size()
	draw_pile = get_node("/root/Main/DrawPile")
	computer = get_node("/root/Main/Computer")
	result_label = get_node("/root/Main/ResultLabel")
	info_box = get_node("/root/Main/InfoBox")
	menu_button = get_node("/root/Main/MenuButton")
	deck = [{"value": 0, "suit": -1}, {"value": 0, "suit": -1}]
	
	dutch = false
	
	is_dragging = false
	dragged_card = null
	
	computer_piles = []
	player_piles = []
	
	card_look = true
	player_turn = true
	draw_card = true
	discard_card = false
	
	active_abilities = []

func punish(delay: float = 0.8, player: bool = true):
	await get_tree().create_timer(delay).timeout
	draw_pile.next_card()
	var card = get_tree().get_first_node_in_group("draw_pile")
	
	var selected_pile: StaticBody2D = null
	var possible_piles: Array
	var parent: String
	
	if player:
		possible_piles = player_piles
		parent = "player"
	else:
		possible_piles = computer_piles
		parent = "computer"
	
	for pile in possible_piles:
		if not pile.occupied:
			selected_pile = pile
			break
	
	if selected_pile:
		card.current_pile = selected_pile
		card.resting_spot = selected_pile.global_position
		card.return_to_resting = true
		card.remove_from_group("draw_pile")
		card.add_to_group(parent)
		selected_pile.occupied = true
		
		computer.gain_unknown_card(card, parent)
		
		draw_pile.next_card()
	else:
		info_box.alert_hand_full(player)

func _input(event):
	if global.card_look:
		if Input.is_action_just_pressed("look_1"):
			get_tree().get_nodes_in_group("player")[0].show_value()
			observed_cards[0] = null
		if Input.is_action_just_pressed("look_2"):
			get_tree().get_nodes_in_group("player")[1].show_value()
			observed_cards[1] = null
		if Input.is_action_just_pressed("look_3"):
			get_tree().get_nodes_in_group("player")[2].show_value()
			observed_cards[2] = null
		if Input.is_action_just_pressed("look_4"):
			get_tree().get_nodes_in_group("player")[3].show_value()
			observed_cards[3] = null

		if Input.is_action_just_released("look_1"):
			get_tree().get_nodes_in_group("player")[0].hide_value()
		if Input.is_action_just_released("look_2"):
			get_tree().get_nodes_in_group("player")[1].hide_value()
		if Input.is_action_just_released("look_3"):
			get_tree().get_nodes_in_group("player")[2].hide_value()
		if Input.is_action_just_released("look_4"):
			get_tree().get_nodes_in_group("player")[3].hide_value()

		if Input.is_action_just_released("all_look"):
			global.card_look = false
			info_box.alert_player_turn()
			var computer_cards = get_tree().get_nodes_in_group("computer")
			
			for card_idx in observed_cards.keys():
				computer.observe_card(computer_cards[card_idx], true)
			observed_cards.clear()

func deck_empty():
	info_box.alert_empty_deck()
	draw_pile.queue_free()
	global.dutch = true

func tally_score():
	var computer_score = 0
	var player_score = 0
	
	for node in get_tree().get_nodes_in_group("player"):
		if node.is_in_group("card"):
			player_score += min(10, node.value)
			node.show_value()
			await get_tree().create_timer(0.4).timeout
	
	await get_tree().create_timer(0.2).timeout
	
	for node in get_tree().get_nodes_in_group("computer"):
		if node.is_in_group("card"):
			computer_score += min(10, node.value)
			node.show_value()
			await get_tree().create_timer(0.4).timeout
	
	return(Vector2(computer_score, player_score))

func end_game():
	var scores = await tally_score()
	var result_text
	if scores[0] < scores[1] or scores[0] == scores[1] and not player_turn:
		result_text = "You Lost"
	else:
		result_text = "You Won"
	result_label.global_position = screen_size - (result_label.custom_minimum_size / 2)
	result_label.z_index = 3
	result_label.text = "[center]Computer Score: %s\nPlayer Score: %s\n%s[/center]" % [scores[0], scores[1], result_text]
	
	menu_button_position = Vector2(screen_size[0] - (menu_button_width / 2), screen_size[1] + (result_label.custom_minimum_size[1] + menu_button_height) / 3)
	menu_button.global_position = menu_button_position
	menu_button.z_index = 4
