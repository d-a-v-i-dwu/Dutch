extends StaticBody2D

var sprite_idx: int
var draggable: bool
var selected: bool

func initialize(position: Vector2, sprite_idx: int):
	$AnimatedSprite2D.frame = sprite_idx
	self.sprite_idx = sprite_idx
	global_position = position
	z_index = 2

func _input(event):
	if event is InputEventMouseButton:
		if event.is_action_pressed("click") and draggable:
			scale = Vector2(0.95,0.95)
			selected = true
		if event.is_action_released("click") and selected:
			global.card_back = sprite_idx + 53
			selected = false
			if draggable:
				scale = Vector2(1.05,1.05)
			else:
				scale = Vector2(1,1)

func _on_area_2d_mouse_entered():
	draggable = true
	scale = Vector2(1.05,1.05)

func _on_area_2d_mouse_exited():
	draggable = false
	scale = Vector2(1,1)
