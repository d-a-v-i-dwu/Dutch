extends Node

var rng
var playing_turn: bool = false

var unknown_computer_cards = []
var known_computer_cards = []

var unknown_player_cards = []
var known_player_cards = []

var remaining_cards = []
var remaining_card_counts = [0,4,4,4,4,4,4,4,4,4,4,4,4,4]

var discard_pile: StaticBody2D
var draw_pile: StaticBody2D
var info_box: Control
var eye = preload("res://Scenes/Components/Eye.tscn")

func _ready():
	discard_pile = $"../DiscardPile"
	draw_pile = $"../DrawPile"
	info_box = $"../InfoBox"
	rng = RandomNumberGenerator.new()

func initialize():
	remaining_cards = global.deck.duplicate(true)
	for node in get_tree().get_nodes_in_group("computer"):
		if node.is_in_group("card"):
			unknown_computer_cards.append(node)
	for node in get_tree().get_nodes_in_group("player"):
		if node.is_in_group("card"):
			unknown_player_cards.append(node)

var discarding = false

func _process(_delta):
	if !global.player_turn and !playing_turn:
		playing_turn = true
		await get_tree().create_timer(0.5).timeout
		play_turn()
	
	var discarded_card = discard_pile.get_discarded_card()
	if discarded_card and not discarding:
		discarding = true
		var discarded_value = discarded_card.value
		for card in known_computer_cards:
			if card.value == discarded_value:
				await get_tree().create_timer(0.8).timeout
				await card.discard_card(card, false)
				known_computer_cards.erase(card)
		discarding = false


func play_turn():
	var discarded_card = discard_pile.get_discarded_card()
	var discarded_card_val = discarded_card.value
	# If the discarded card is a joker, take it. If it's an ace and hand value is more than 1, sometimes take it
	if discarded_card_val == 0 or discarded_card_val == 1 and rng.randi_range(0, 5) == 0 and probable_hand_value() > 1:
		var new_discarded_card = choose_discard_card(null, discarded_card_val)
		await take_and_discard(discarded_card, new_discarded_card)
	else:
		var drawn_card = draw_card()
		if not drawn_card:
			pass
		# If you can discard the drawn card do so, then discard a bonus card
		elif drawn_card.value == discarded_card_val:
			await drawn_card.discard_card(drawn_card, false)
			await get_tree().create_timer(0.6).timeout
			
			await extra_discard(drawn_card.value)
		# Otherwise, determine which card to discard
		else:
			var discard_card = choose_discard_card(drawn_card, discarded_card_val)
			if discard_card == drawn_card:
				await drawn_card.discard_card(drawn_card, false)
			else:
				await take_and_discard(drawn_card, discard_card)
	
	end_turn()

func call_dutch():
	var num_cards = len(unknown_computer_cards) + len(known_computer_cards)
	var num_player_cards = len(unknown_player_cards) + len(known_player_cards)
	var hand_value = probable_hand_value()
	
	if num_cards == 0 or probable_hand_value() == 0:
		global.dutch = true
		return
	
	var player_hand_value = probable_player_hand()
	
	if len(remaining_cards) < 38 or rng.randi_range(0,20) == 0:
		if hand_value <= 2 and player_hand_value > 5 and num_player_cards > 1 and rng.randi_range(0,3) == 0:
			global.dutch = true
		elif num_cards < num_player_cards - 1 and hand_value < player_hand_value and rng.randi_range(0,3) == 0:
			global.dutch = true
		elif hand_value * rng.randf_range(2,3) < player_hand_value and num_cards <= num_player_cards:
			global.dutch = true

func end_turn():
	if global.dutch:
		global.end_game()
	else:
		global.player_turn = true
		global.draw_card = true
		playing_turn = false
		draw_pile.next_card()
		call_dutch()
		
		if len(global.deck) == 0:
			global.deck_empty()
		elif global.dutch == true:
			info_box.alert_dutch()
		else:
			info_box.alert_player_turn()

func choose_discard_card(drawn_card: StaticBody2D = null, discarded_card_val: int = -1) -> StaticBody2D:
	var highest_card = null
	var highest_last_of_kind = null
	
	for card in known_computer_cards:
		if card.value == discarded_card_val:
			return card
		
		if not highest_card or card.value > highest_card.value:
			highest_card = card
		
		if remaining_card_counts[card.value] == 0 and card.value > 3:
			if not highest_last_of_kind or card.value > highest_last_of_kind.value:
				highest_last_of_kind = card
	
	var worst_card_in_hand = highest_card if not highest_last_of_kind or rng.randi_range(0,1) == 0 else highest_last_of_kind
	var discard_unknown = rng.randi_range(0, 2) < len(unknown_computer_cards)
	
	# If drawing from the discard pile, choose a card without regard to the drawn card
	if not drawn_card:
		# If there are known computer cards, have a chance to discard them over unknown, otherwise discard unknown computer cards
		return worst_card_in_hand if highest_card and not discard_unknown else unknown_computer_cards[0]
	
	var drawn_card_value = drawn_card.value
	# If the card has a high value and it's the last of its value, discard it
	if drawn_card_value > 3 and remaining_card_counts[drawn_card_value] == 0:
		return drawn_card
	
	if discard_unknown:
		return unknown_computer_cards[0]

	# If it's the last of its kind and worse than the worst card in hand, discard it
	if remaining_card_counts[drawn_card_value] == 0 and drawn_card_value > worst_card_in_hand.value:
		return drawn_card
	# Otherwise check if there is a card of the same value in hand
	var has_same_val_card = false
	for card in known_computer_cards:
		if card.value == drawn_card_value:
			has_same_val_card = true
			break
	# If there is a card of the same value, have a chance to discard the drawn card to get rid of the card in hand as well
	return drawn_card if has_same_val_card and rng.randi_range(0,1) == 0 else worst_card_in_hand

func extra_discard(discarded_card_val: int):
	while len(unknown_computer_cards) + len(known_computer_cards) > 0:
		var extra_discard_card = choose_discard_card(null, discarded_card_val)
		known_computer_cards.erase(extra_discard_card)
		
		await observe_card(extra_discard_card)
		await extra_discard_card.discard_card(extra_discard_card, false)
		
		if extra_discard_card.value != discarded_card_val:
			break

func remaining_average() -> float:
	var unknown_sum: float = 0
	var num_unknowns: int = len(remaining_cards) + len(unknown_computer_cards) + len(unknown_player_cards)
	
	for card in remaining_cards:
		unknown_sum += min(card["value"], 10)
	for card in unknown_computer_cards:
		unknown_sum += min(card["value"], 10)
	for card in unknown_player_cards:
		unknown_sum += min(card["value"], 10)
	
	return unknown_sum / num_unknowns

func probable_hand_value() -> float:
	var value: float = remaining_average() * len(unknown_computer_cards)
	for card in known_computer_cards:
		value += min(card.value, 10)
	return value

func probable_player_hand() -> float:
	var probable_value: float = remaining_average() * len(unknown_player_cards)
	for card in known_player_cards:
		probable_value += min(card.value, 10)
	return probable_value

func set_card_position(card: StaticBody2D, resting_spot: Vector2):
	card.resting_spot = resting_spot
	card.return_to_resting = true

func draw_card() -> StaticBody2D:
	var drawn_card = get_tree().get_first_node_in_group("draw_pile")
	drawn_card.z_index = 2
	drawn_card.remove_from_group("draw_pile")
	observe_card(drawn_card)
	
	return drawn_card

func take_and_discard(taken_card: StaticBody2D, discarded_card: StaticBody2D):
	set_card_position(taken_card, discarded_card.global_position)
	await get_tree().create_timer(0.6).timeout
	set_card_position(discarded_card, discard_pile.global_position)
	
	taken_card.add_to_group("computer")
	taken_card.hide_value()
	known_computer_cards.append(taken_card)
	taken_card.current_pile = discarded_card.current_pile
	discarded_card.current_pile = discard_pile
	
	if discarded_card in known_computer_cards:
		known_computer_cards.erase(discarded_card)
	else:
		await observe_card(discarded_card)
	
	await taken_card.discard_card(discarded_card, false)
	
	if discarded_card.value == discard_pile.get_placeholder_value():
		extra_discard(discarded_card.value)

func observe_card(card: StaticBody2D, ability: bool = false):
	var value = card.value
	var suit = card.suit
	var card_object = {"value": value, "suit": suit}
	
	# Remove from groups of unknown cards
	remaining_cards.erase(card_object)
	unknown_player_cards.erase(card)
	unknown_computer_cards.erase(card)
	
	# If it was a card the computer knew and it's discarded, remove it from that group
	if card in known_player_cards:
		known_player_cards.erase(card)
		return
	
	# If it was completely unknown, if it was seen by using a face card ability it's a known card in a hand
	remaining_card_counts[value] -= 1
	if ability:
		if card.is_in_group("computer"):
			known_computer_cards.append(card)
		else:
			known_player_cards.append(card)
		await looking_animation(card.global_position)

func player_discards_card(discarded_card: StaticBody2D, taken_card: StaticBody2D = null, from_discard_pile: bool = false):
	observe_card(discarded_card)
	# If they discarded it directly without drawing
	if not taken_card:
		return
	# If they took it from the discard pile, the computer will know what card it is	
	if from_discard_pile:
		known_player_cards.append(taken_card)
	else:
		unknown_player_cards.append(taken_card)

func swap_card_with_player(taken_card: StaticBody2D, given_card: StaticBody2D):
	if taken_card in known_player_cards:
		known_computer_cards.append(taken_card)
		known_player_cards.erase(taken_card)
	else:
		unknown_player_cards.erase(taken_card)
		unknown_computer_cards.append(taken_card)
	
	if given_card in known_computer_cards:
		known_player_cards.append(given_card)
		known_computer_cards.erase(given_card)
	else:
		unknown_player_cards.append(given_card)
		unknown_computer_cards.erase(given_card)

func gain_unknown_card(card: StaticBody2D, parent: String):
	var card_object = {"value": card.value, "suit": card.suit}
	remaining_cards.erase(card_object)
	
	if parent == "player":
		unknown_player_cards.append(card)
	else:
		unknown_computer_cards.append(card)

func use_ability(ability: String):
	await get_tree().create_timer(0.8).timeout
	if ability == "Jack":
		for card in known_player_cards:
			if card.value == 0 or card.value == 1 and rng.randi_range(0, 3) < 3:
				var swapped_card = choose_discard_card()
				swap_card_with_player(card, swapped_card)
				card.swap_piles(null, swapped_card)
				
				card.return_to_resting = true
				swapped_card.return_to_resting = true
				return
	
	if len(unknown_computer_cards) > 0:
		await observe_card(unknown_computer_cards[0], true)
	elif len(unknown_player_cards) > 0:
		await observe_card(unknown_player_cards[0], true)

func looking_animation(position: Vector2):
	var eye_obj = eye.instantiate()
	add_child(eye_obj)
	await eye_obj.initialize(position)
