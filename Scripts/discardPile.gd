extends StaticBody2D

var current_card: StaticBody2D = null
var placeholder_card: StaticBody2D

var num_of_cards: int = 0
var occupied = false

func initialize(position: Vector2):
	placeholder_card = get_node('../PlaceholderCard')
	modulate = Color(Color.WHITE, 0.5)
	global_position = position

# Make the piles visible only when a card is being dragged
func _process(_delta):
	if global.is_dragging and num_of_cards == 0:
		visible = true
	else:
		visible = false

func discard_card(card: StaticBody2D):
	# If it's the first card on the pile, let it sit there
	if num_of_cards == 0:
		num_of_cards += 1
	# If it's the second, delete the card beneath and create an un-interactable image of it
	elif num_of_cards == 1:
		num_of_cards += 1
		placeholder_card.show_card(current_card.sprite_idx, current_card.value)
		current_card.queue_free()
	# If there are already cards beneath, change the image to the previous card and then delete it
	else:
		placeholder_card.change_card(current_card.sprite_idx, current_card.value)
		current_card.queue_free()
	
	# Store a reference of the card just discarded
	current_card = card

func swap_discarded_card(card: StaticBody2D):
	# Dereference the previously discarded card as someone has now picked it up, reference the new discarded card
	current_card = card

func get_discarded_card() -> StaticBody2D:
	return current_card

func get_placeholder_value() -> int:
	return placeholder_card.get_value()

func reset():
	num_of_cards = 0
	current_card = null
	placeholder_card.visible = false
