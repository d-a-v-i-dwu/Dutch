extends Label

func _process(_delta):
	text = " ".join(global.active_abilities)
