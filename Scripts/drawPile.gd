extends StaticBody2D

var card = preload("res://Scenes/Components/Card.tscn")

func initialize(position: Vector2):
	$AnimatedSprite2D.frame = global.card_back - 53
	global_position = position
	spawn_card(position, "draw_pile")
	z_index = 0

func spawn_card(origin: Vector2, parent: String):
	if len(global.deck) == 0:
		$"../InfoBox".alert_empty_deck()
		return
	
	var card_obj = card.instantiate()
	get_parent().add_child(card_obj)
	card_obj.create(origin, parent)

func next_card():
	if len(get_tree().get_nodes_in_group('draw_pile')) == 0:
		spawn_card(global_position, "draw_pile")
