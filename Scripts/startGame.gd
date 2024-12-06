extends Control

var start_game_button: Button
var start_game_button_x: float
var start_game_button_y: float
var start_game_button_height: float = 110
var start_game_button_width: float = 350

var card_pick_button: Button
var card_pick_button_x: float
var card_pick_button_y: float
var card_pick_button_height: float = 90
var card_pick_button_width: float = 340

func _ready():
	start_game_button = $StartGameButton
	card_pick_button = $CardPickButton
	var camera_size = $Camera2D.get_size()
	
	start_game_button_x = camera_size[0] - (start_game_button_width / 2)
	start_game_button_y = camera_size[1] - (start_game_button_height / 2)
	start_game_button.global_position = Vector2(start_game_button_x, start_game_button_y)
	
	card_pick_button_x = camera_size[0] - (card_pick_button_width / 2)
	card_pick_button_y = camera_size[1] - (card_pick_button_height / 2) + card_pick_button_height * 1.5
	card_pick_button.global_position = Vector2(card_pick_button_x, card_pick_button_y)
	
	RenderingServer.set_default_clear_color(Color(39 / (255.0 * 2), 163 / (255.0 * 2), 39 / (255.0 * 2)))

func _on_start_game_button_pressed():
	SceneSwitcher.switch_scene("res://Scenes/Main.tscn")

func _on_start_game_button_button_down():
	start_game_button.scale = Vector2(0.95, 0.95)
	start_game_button.global_position.x = start_game_button_x + start_game_button_width * 0.025
	start_game_button.global_position.y = start_game_button_y + start_game_button_height * 0.025

func _on_start_game_button_mouse_entered():
	start_game_button.scale = Vector2(1.05, 1.05)
	start_game_button.global_position.x = start_game_button_x - start_game_button_width * 0.025
	start_game_button.global_position.y = start_game_button_y - start_game_button_height * 0.025

func _on_start_game_button_mouse_exited():
	start_game_button.scale = Vector2(1, 1)
	start_game_button.global_position.x = start_game_button_x
	start_game_button.global_position.y = start_game_button_y


func _on_card_pick_button_pressed():
	SceneSwitcher.switch_scene("res://Scenes/PickCard.tscn")

func _on_card_pick_button_button_down():
	card_pick_button.scale = Vector2(0.95, 0.95)
	card_pick_button.global_position.x = card_pick_button_x + card_pick_button_width * 0.025
	card_pick_button.global_position.y = card_pick_button_y + card_pick_button_height * 0.025

func _on_card_pick_button_mouse_entered():
	card_pick_button.scale = Vector2(1.05, 1.05)
	card_pick_button.global_position.x = card_pick_button_x - card_pick_button_width * 0.025
	card_pick_button.global_position.y = card_pick_button_y - card_pick_button_height * 0.025

func _on_card_pick_button_mouse_exited():
	card_pick_button.scale = Vector2(1, 1)
	card_pick_button.global_position.x = card_pick_button_x
	card_pick_button.global_position.y = card_pick_button_y
