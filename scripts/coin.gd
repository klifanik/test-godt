extends Area3D

@export var rotation_speed: float = 2.0 # Скорость вращения монеты

func _ready() -> void:
	# Подключаем сигнал
	print("МОНЕТА: Скрипт готов, сигнал body_entered подключен.")

func _physics_process(delta: float) -> void:
	# Красиво вращаем монету вокруг оси Y каждый кадр
	rotate_y(rotation_speed * delta)

func _on_body_entered(body: Node3D) -> void:
	print("Объект: ", body.name, " | Слой: ", body.collision_layer, " | Группы: ", body.get_groups())
	
	# Тест 1: Срабатывает ли физика вообще?
	print("ФИЗИКА СРАБОТАЛА! В монету вошел объект: ", body.name)
	
	# Тест 2: В какой группе состоит этот объект?
	print("Группы этого объекта: ", body.get_groups())
	
	# Проверяем, что в монету врезался именно игрок
	if body.is_in_group("player"):
		print("МОНЕТА: Это игрок! Проверяем метод...")
		
		# Тест 3: Есть ли у него метод?
		if body.has_method("AddLocalCoin"):
			print("МОНЕТА: Метод AddLocalCoin найден у игрока, вызываем!")
			body.AddLocalCoin()
		else:
			print("КРИТИЧЕСКАЯ ОШИБКА: У игрока НЕТ метода с именем AddLocalCoin!")
		
		# Удаляем монету из игры
		queue_free()
	else:
		print("МОНЕТА: Объект ", body.name, " проигнорирован, так как у него нет группы 'player'.")
