extends CharacterBody3D

func ready():
	pass

func _physics_process(delta: float) -> void:
	# move_and_collide возвращает данные, если произошло столкновение
	var collision = move_and_collide(velocity * delta)
	
	if collision:
		var collider = collision.get_collider()
		
		if collider.has_method("hit"):
			collider.hit()
			
		queue_free() # Удаляем пулю после удара
