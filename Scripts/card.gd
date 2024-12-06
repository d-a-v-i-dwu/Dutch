extends StaticBody2D

var value: int
var suit: int
var sprite_idx: int
var ability: String = "None"

var selected: bool = false
var draggable: bool = false
var mouse_in_shape: bool = false

var resting_spot: Vector2
var return_to_resting = false
var offset: Vector2

var is_inside_pile: bool = false
var current_pile: StaticBody2D = null
var pile_ref: StaticBody2D = null
var discard_pile: StaticBody2D

var is_inside_card: bool = false
var card_ref: StaticBody2D

var info_box: Control
var end_turn_button: Button
var dutch_button: Button
var computer: Node

var show_cards: bool = false

func _ready():
	discard_pile = get_node("../DiscardPile")
	end_turn_button = get_node("../EndTurnButton")
	dutch_button = get_node("../DutchButton")
	info_box = get_node("../InfoBox")
	computer = get_node("../Computer")

func create(origin: Vector2, parent: String):
	z_index = 1
	
	var card = global.deck.pop_front()
	
	if card["value"] == 0:
		sprite_idx = 0
	else:
		set_value(card["value"])
		sprite_idx = card["suit"] * 13 + card["value"]
	
	suit = card["suit"]
	
	if show_cards:
		show_value()
	else:
		hide_value()
	set_pos(origin)
	add_to_group(parent)

# Sets the resting spot and instantiated spot to origin
func set_pos(pos: Vector2):
	resting_spot = pos
	global_position = pos

func set_value(val: int):
	value = val
	if value == 11:
		ability = "Jack"
	elif value == 12:
		ability = "Queen"
	elif value == 13:
		ability = "King"

# Set the sprite of the card as the back of the card
func hide_value():
	$AnimatedSprite2D.frame = global.card_back

# Set the sprite of the card to its value
func show_value():
	$AnimatedSprite2D.frame = sprite_idx

func _to_string():
	return "value: %s, suit: %s" % [value, suit]

func _input(event):
	if event is InputEventMouseButton:
		# If LMB is pressed down on the card and the card is draggable
		if draggable and event.is_action_pressed("click"):
			offset = get_global_mouse_position() - global_position
			if abs(offset[0]) > $Area2D/CollisionShape2D.shape.get_rect().size[0] / 2 or abs(offset[1]) > $Area2D/CollisionShape2D.shape.get_rect().size[1] / 2:
				draggable = false
				mouse_in_shape = false
				return
			
			scale = Vector2(0.95, 0.95)
			selected = true
			global.dragged_card = self
			global.is_dragging = true
			global.card_look = false
			return_to_resting = false
			
			# Bring it in front of other sprites
			z_index = 2
			
			if is_in_group("draw_pile"):
				if global.draw_card:
					show_value()
			
			elif event.button_index == MOUSE_BUTTON_RIGHT:
				var active_ability = global.active_abilities.pop_back()
				if active_ability != null:
					show_value()
		
		# If LMB is released and the card is the one currently being dragged
		if event.is_action_released("click"):
			if selected:
				scale = Vector2(1, 1)
				draggable = false
				selected = false
				global.is_dragging = false
				global.dragged_card = null
				
				var discarded_card: StaticBody2D = discard_pile.get_discarded_card()
				
				if event.button_index == MOUSE_BUTTON_RIGHT:
					pass
				# If it's released inside the pile
				elif is_inside_pile and not pile_ref.occupied:
					if is_in_group("computer"):
						if pile_ref.is_in_group("computer"):
							swap_piles(pile_ref)
					
					if is_in_group("player"):
						if pile_ref.is_in_group("player"):
							swap_piles(pile_ref)
						# If the player tries to discard a card from their hand at the start of the game, do nothing
						elif not discarded_card:
							pass
						# If the value of the card and the previous discarded card match, allow it to be discarded
						elif discarded_card.value == value:
							discard_card(self)
						elif global.discard_card:
							discard_card(self)
							toggle_extra_discard()
							end_turn()
						# Otherwise the player has incorrectly tried to play a card, and therefore gains a card
						else:
							show_value()
							await get_tree().create_timer(0.6).timeout
							global.punish()
					
					elif is_in_group("draw_pile") and pile_ref.is_in_group("discard_pile"):
						discard_card(self)
						if discarded_card and discarded_card.value == value:
							toggle_extra_discard()
						else:
							end_turn()
				
				elif is_inside_card:
					# Player can swap the positions of two cards belonging to the same player
					if card_ref.is_in_group("computer") and is_in_group("computer") or card_ref.is_in_group("player") and is_in_group("player"):
						swap_card_positions(card_ref.global_position, resting_spot)
						swap_piles(null, card_ref)
					
					# If a Jack has been played this turn the player can one of their cards with a computer's card
					elif card_ref.is_in_group("computer") and is_in_group("player") or card_ref.is_in_group("player") and is_in_group("computer"):
						if not global.active_abilities.is_empty() and global.active_abilities[0] == "Jack":
							global.active_abilities.pop_front()
							if card_ref.is_in_group("computer"):
								computer.swap_card_with_player(self, card_ref)
							else:
								computer.swap_card_with_player(card_ref, self)
							
							swap_card_positions(card_ref.global_position, resting_spot)
							swap_piles(null, card_ref)
					
					# If the card is drawn from the correct pile during the draw card phase and the card being swapped is the player's card
					elif card_ref.is_in_group("player") and global.draw_card:
						if is_in_group("draw_pile") or is_in_group("discarded") and ability == "None":
							# Swap the card positions, discard the card that was in hand, and set the group of the new card to player
							swap_card_positions(card_ref.global_position, discard_pile.global_position)
							
							current_pile = card_ref.current_pile
							card_ref.current_pile = discard_pile
							
							# If the card being discarded is the same as the card it's played on top of, discard one more
							if is_in_group("discarded") and card_ref.value == discard_pile.get_placeholder_value() or discarded_card and card_ref.value == discarded_card.value:
								toggle_extra_discard()
							
							remove_from_all_groups()
							add_to_group("player")
							
							discard_card(card_ref)
							
							end_turn()
				
				# When the LMB is released always return the card to its resting position
				return_to_resting = true
			
			elif mouse_in_shape:
				draggable = true
				scale = Vector2(1.05, 1.05)

func remove_from_all_groups():
	remove_from_group("player")
	remove_from_group("computer")
	remove_from_group("draw_pile")
	remove_from_group("discarded")

func discard_card(card: StaticBody2D, player: bool = true):
	card.resting_spot = discard_pile.global_position
	if card.current_pile:
		card.current_pile.occupied = false
	card.current_pile = discard_pile
	card.return_to_resting = true
	
	card.remove_from_all_groups()
	card.add_to_group("discarded")
	card.z_index = 1
	
	# If drawing from the discard pile, don't delete any cards and just swap them
	if discard_pile.get_discarded_card() == self:
		# If it's the player discarding, let the computer know
		if player:
			computer.player_discards_card(card_ref, self, true)
		discard_pile.swap_discarded_card(card)
		return
	
	discard_pile.discard_card(card)
	
	if card.ability == "King":
		global.punish(1, not player)
	
	# Delete the previously discarded card if there exists one, reference this card as the next to be deleted
	if player:
		if card.ability in ["Jack", "Queen"]:
			global.active_abilities.append(card.ability)
			global.active_abilities.sort()
		if card == self:
			computer.player_discards_card(self)
		else:
			computer.player_discards_card(card_ref, self)
	else:
		if card.ability in ["Jack", "Queen"]:
			await get_tree().create_timer(0.5).timeout
			await computer.use_ability(card.ability)

func end_turn():
	global.draw_card = false
	end_turn_button.visible = true
	if not global.dutch:
		dutch_button.visible = true

func toggle_extra_discard():
	if global.discard_card:
		global.discard_card = false
		info_box.remove_alert()
	else:
		global.discard_card = true
		info_box.alert_player_discard()

func swap_card_positions(this_card_resting_spot: Vector2, other_card_resting_spot: Vector2):
	resting_spot = this_card_resting_spot
	card_ref.resting_spot = other_card_resting_spot
	card_ref.return_to_resting = true
	is_inside_card = false

func swap_piles(new_pile: StaticBody2D, other_card: StaticBody2D = null, ):
	# If swapping the piles of two cards
	if other_card:
		var other_pile = other_card.current_pile
		other_card.current_pile = current_pile
		current_pile = other_pile
		# If the cards are from different players, swap their groups
		if other_card.is_in_group("computer") and is_in_group("player"):
			other_card.remove_from_group("computer")
			other_card.add_to_group("player")
			remove_from_group("player")
			add_to_group("computer")
		elif other_card.is_in_group("player") and is_in_group("computer"):
			other_card.remove_from_group("player")
			other_card.add_to_group("computer")
			remove_from_group("computer")
			add_to_group("player")
	# If putting a card in an empty pile
	else:
		current_pile.occupied = false
		current_pile = new_pile
		new_pile.occupied = true
		resting_spot = new_pile.global_position

func _process(delta):
	# if it's the card being dragged, move the card to follow the mouse but maintaining the distance from the mouse to the center of the card
	if selected:
		global_position = global_position.lerp(get_global_mouse_position() - offset, 25 * delta)
	
	# When a dragged card is let go
	if return_to_resting:
		# Move the card to its resting position with the tween which deccelerates the card as it gets closer to the resting spot
		var tween = get_tree().create_tween()
		tween.tween_property(self, "global_position", resting_spot, 0.3).set_ease(Tween.EASE_OUT)
		
		# If within 40 units of the resting spot, teleport it to the resting spot
		if (global_position - resting_spot).length() <= 30:
			global_position = resting_spot
			return_to_resting = false
			is_inside_card = false
			card_ref = null
			
			if is_in_group("discarded") or is_in_group("draw_pile") and global.draw_card:
				show_value()
			else:
				if show_cards:
					show_value()
				else:
					hide_value()
			
			z_index = 1
			
			# Allow the card to be picked up again
			if mouse_in_shape:
				draggable = true
				scale = Vector2(1.05, 1.05)

# Detects when it's in contact with another object
func _on_area_2d_body_entered(body):
	if not current_pile and body.is_in_group("pile"):
		current_pile = body
	# If it's inside a pile, change the colour of the pile
	if body.is_in_group("pile"):
		is_inside_pile = true
		body.scale = Vector2(0.95, 0.95)
		if body.is_in_group("discard_pile"):
			body.modulate = Color(Color.WHITE, 0.8)
		else:
			body.modulate = Color(Color.WHITE, 0.4)
		pile_ref = body
	elif body.is_in_group("card") and not body == self:
		is_inside_card = true
		card_ref = body
		# If it's inside another card enlarge the sedentary card to display this
		if selected:
			body.scale = Vector2(1.05, 1.05)

func _on_area_2d_body_exited(body):
	if body.is_in_group("pile"):
		is_inside_pile = false
		if body.is_in_group("discard_pile"):
			body.modulate = Color(Color.WHITE, 0.5)
		else:
			body.modulate = Color(Color.WHITE, 0.2)
		body.scale = Vector2(1, 1)
		pile_ref = null
	elif body.is_in_group("card"):
		is_inside_card = false
		card_ref = null
		body.scale = Vector2(1, 1)

# When the mouse is inisde the card and no other card is being dragged and the card is not moving, then the current card can be dragged
func _on_area_2d_mouse_entered():
	if not return_to_resting:
		mouse_in_shape = true
		if not global.is_dragging:
			draggable = true
			scale = Vector2(1.05, 1.05)

# When the mouse has exited the object body the card is no longer able to be dragged, normalizes the card size
func _on_area_2d_mouse_exited():
	mouse_in_shape = false
	if not global.is_dragging:
		draggable = false
		scale = Vector2(1,1)
