extends StaticBody2D

var current_card: StaticBody2D = null
var occupied: bool
var occupied_lock: bool = false
var card_in_body: bool = false
var parent: String

func initialize(position: Vector2, parent: String, occupied: bool):
	modulate = Color(Color.WHITE, 0.2)
	global_position = position
	add_to_group(parent)
	self.occupied = occupied
	self.parent = parent

# Make the piles visible only when a card is being dragged
func _process(_delta):
	if global.is_dragging and not occupied:
		if global.dragged_card.is_in_group(parent):
			visible = true
		elif (global.dragged_card.is_in_group("draw_pile") or global.dragged_card.is_in_group("discarded")) and parent == "player":
			visible = true
	else:
		visible = false

func _to_string():
	return("pile, occupied: %s" % [occupied])
