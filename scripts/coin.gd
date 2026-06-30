extends Area3D

@export var rotation_speed: float = 2.0 # Скорость вращения монеты

func _ready() -> void:
	pass

func _physics_process(delta: float) -> void:
	# Красиво вращаем монету вокруг оси Y каждый кадр
	rotate_y(rotation_speed * delta)

func _on_body_entered(body: Node3D) -> void:
	# Проверяем, что в монету врезался именно игрок
	if body.is_in_group("player"):
		
		# Тест 3: Есть ли у него метод?
		if body.has_method("AddCoin"):
			body.AddCoin()
			
		# Удаляем монету из игры
		queue_free()
	else:
		print("МОНЕТА: Объект ", body.name, " проигнорирован, так как у него нет группы 'player'.")
