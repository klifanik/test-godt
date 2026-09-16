extends Node3D

# Загружаем сцену зомби
var zombie_scene: PackedScene = preload("res://scenes/zombie.tscn")
var coin_scene: PackedScene = preload("res://scenes/coin.tscn")
# var coin_scene = preload()

# Границы спавна (исходя из размера пола 100x100)
var spawn_range: float = 45.0
var min_distance_from_houses: float = 6.0

func _ready() -> void:
	# Захватываем курсор мыши. В Web-билде это ключевой триггер для возврата клавиатуры!
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	print("[Level] Сцена уровня загружена, фокус ввода и мышь захвачены.")
	
	# Подключаем сигнал таймера кодом, если не сделали этого в редакторе
	$Timer.timeout.connect(_on_spawn_timer_timeout)

func _on_spawn_timer_timeout() -> void:
	spawn_zombie()
	spawn_coin()

func spawn_coin() -> void:
	if coin_scene == null:
		return

	# Находим генератор карт, чтобы взять список сгенерированных позиций
	var map_gen = get_tree().get_first_node_in_group("MapGenerator")
	var house_positions: Array[Vector3] = []
	if map_gen != null:
		house_positions = map_gen.spawned_positions

	var max_attempts: int = 50
	var final_x: float = 0.0
	var final_z: float = 0.0
	var found_valid_spot: bool = false

	# Подбираем точку, которая не пересекается ни с одним домом на плоскости XZ
	for attempt in max_attempts:
		var random_x = randf_range(-spawn_range, spawn_range)
		var random_z = randf_range(-spawn_range, spawn_range)
		
		var is_safe = true
		var candidate_2d = Vector2(random_x, random_z)

		for house_pos in house_positions:
			var house_2d = Vector2(house_pos.x, house_pos.z)
			if candidate_2d.distance_to(house_2d) < min_distance_from_houses:
				is_safe = false
				break

		if is_safe:
			final_x = random_x
			final_z = random_z
			found_valid_spot = true
			break

	# Если не удалось найти идеальную точку за 50 попыток — берём случайную
	if not found_valid_spot:
		final_x = randf_range(-spawn_range, spawn_range)
		final_z = randf_range(-spawn_range, spawn_range)
	
	var zombie = coin_scene.instantiate()
	
	# СНАЧАЛА добавляем в дерево
	add_child(zombie)
	
	zombie.global_position = Vector3(final_x, 1.0, final_z)

func spawn_zombie() -> void:
	if zombie_scene == null:
		return

	# Находим генератор карт, чтобы взять список сгенерированных позиций
	var map_gen = get_tree().get_first_node_in_group("MapGenerator")
	var house_positions: Array[Vector3] = []
	if map_gen != null:
		house_positions = map_gen.spawned_positions

	var max_attempts: int = 50
	var final_x: float = 0.0
	var final_z: float = 0.0
	var found_valid_spot: bool = false

	# Подбираем точку, которая не пересекается ни с одним домом на плоскости XZ
	for attempt in max_attempts:
		var random_x = randf_range(-spawn_range, spawn_range)
		var random_z = randf_range(-spawn_range, spawn_range)
		
		var is_safe = true
		var candidate_2d = Vector2(random_x, random_z)

		for house_pos in house_positions:
			var house_2d = Vector2(house_pos.x, house_pos.z)
			if candidate_2d.distance_to(house_2d) < min_distance_from_houses:
				is_safe = false
				break

		if is_safe:
			final_x = random_x
			final_z = random_z
			found_valid_spot = true
			break

	# Если не удалось найти идеальную точку за 50 попыток — берём случайную
	if not found_valid_spot:
		final_x = randf_range(-spawn_range, spawn_range)
		final_z = randf_range(-spawn_range, spawn_range)

	var zombie = zombie_scene.instantiate()
	
	# СНАЧАЛА добавляем в дерево
	add_child(zombie)
	
	# ТЕПЕРЬ задаем позицию
	zombie.global_position = Vector3(final_x, 1.0, final_z)
