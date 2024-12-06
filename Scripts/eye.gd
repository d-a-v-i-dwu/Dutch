extends AnimatedSprite2D

func initialize(position: Vector2):
	modulate.a = 0
	z_index = 2
	global_position = position
	var tween = get_tree().create_tween()
	tween.tween_property(self, "modulate:a", 1, 0.8)
	tween.tween_property(self, "modulate:a", 0, 0.8)
	tween.tween_callback(self.queue_free)
	await tween.finished
