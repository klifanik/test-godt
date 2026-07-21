extends Node3D

# Загружаем сцену зомби
var zombie_scene: PackedScene = preload("res://scenes/zombie.tscn")
var coin_scene: PackedScene = preload("res://scenes/coin.tscn")
# var coin_scene = preload()

# Границы спавна (исходя из размера пола 100x100)
var spawn_range: float = 45.0

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
	var zombie = coin_scene.instantiate()
	
	# СНАЧАЛА добавляем в дерево
	add_child(zombie)
	
	# ТЕПЕРЬ задаем позицию
	var random_x = randf_range(-spawn_range, spawn_range)
	var random_z = randf_range(-spawn_range, spawn_range)
	zombie.global_position = Vector3(random_x, 1.0, random_z)

func spawn_zombie() -> void:
	var zombie = zombie_scene.instantiate()
	
	# СНАЧАЛА добавляем в дерево
	add_child(zombie)
	
	# ТЕПЕРЬ задаем позицию
	var random_x = randf_range(-spawn_range, spawn_range)
	var random_z = randf_range(-spawn_range, spawn_range)
	zombie.global_position = Vector3(random_x, 1.0, random_z)
