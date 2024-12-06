extends Control

var card_preview = preload("res://Scenes/Components/CardPreview.tscn")
var back_button: Button

func _ready():
	var screen_size = $Camera2D.get_size() * 2
	
	back_button = $BackButton
	back_button.global_position = Vector2(screen_size[0] / 60, screen_size[1] / 15)
	
	var x_gap = screen_size[0] * 2 / 15
	var x_start = screen_size[0] * 7 / 15
	
	var y_gap = screen_size[1] / 10
	var y_start = y_gap * 2
	
	for x_mult in range(4):
		for y_mult in range(3):
			var card_preview_obj = card_preview.instantiate()
			add_child(card_preview_obj)
			card_preview_obj.initialize(Vector2(x_start + x_gap * x_mult,  y_start + y_gap * 3 * y_mult), x_mult * 3 + y_mult)
	
	$AnimatedSprite2D.global_position = Vector2(screen_size[0] / 6, screen_size[1] / 2)

func _process(_delta):
	$AnimatedSprite2D.frame = global.card_back - 53


func _on_back_button_pressed():
	SceneSwitcher.switch_scene("res://Scenes/StartGame.tscn")
