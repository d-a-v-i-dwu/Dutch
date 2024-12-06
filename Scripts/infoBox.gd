extends Control

var default_position
var label

func initialize(position: Vector2):
	visible = true
	default_position = position
	label = get_node("PanelContainer/VBoxContainer/Label")
	label.text = "Press any of the keys 1, 2, 3, or 4 to view the cards in your hand."
	global_position.x = position[0]
	global_position.y = position[1] - (label.get_line_height() / 2) - 17.5

func reposition():
	global_position.y = default_position[1] - (label.get_line_count() * label.get_line_height() / 2) - 17.5

func alert_player_discard():
	visible = true
	label.text = "You may discard a card from your hand"
	reposition()

func alert_player_turn():
	visible = true
	label.text = "Your turn"
	reposition()

func alert_empty_deck():
	visible = true
	label.text = "The deck is empty, the game will end"
	reposition()

func alert_dutch(player: bool = false):
	if player:
		label.text = "The player called dutch!"
	else:
		label.text = "The computer called dutch!"
	visible = true
	reposition()

func alert_hand_full(player: bool):
	if player:
		label.text = "Player's hand is full"
	else:
		label.text = "Computer's hand is full"
	visible = true
	reposition()

func remove_alert():
	visible = false
