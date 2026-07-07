extends Area3D

@export var speed: float = 30.0 # Скорость полета пули

func _physics_process(delta: float) -> void:
	# Движение строго вперед по вектору -Z (это стандарт направления "вперед" в Godot)
	# global_translate двигает пулю в мировых координатах, но относительно её собственного поворота
	global_translate(-global_transform.basis.z * speed * delta)

func _on_body_entered(body: Node3D) -> void:
	# Важная проверка: если пуля при спавне задела самого игрока, 
	# мы игнорируем это столкновение, чтобы игрок сам себя не застрелил
	if body.is_in_group("player"):
		return
		
	# Если объект, в который врезалась пуля, имеет метод hit (например, враг)
	if body.has_method("hit"):
		body.hit() # Наносим урон
		
	# Уничтожаем пулю после любого столкновения (со стеной или врагом)
	queue_free()
