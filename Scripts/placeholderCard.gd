extends StaticBody2D

var value: int

func initialize(position: Vector2):
	visible = false
	global_position = position

func show_card(sprite_idx: int, val: int):
	$AnimatedSprite2D.frame = sprite_idx
	value = val
	visible = true

func change_card(sprite_idx: int, val: int):
	$AnimatedSprite2D.frame = sprite_idx
	value = val

func get_value() -> int:
	return value
