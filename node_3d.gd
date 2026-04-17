extends Node3D

# Загружаем сцену зомби
var zombie_scene = preload("res://zombie.tscn")

# Границы спавна (исходя из размера пола 100x100)
var spawn_range = 45.0 

func _ready():
	# Подключаем сигнал таймера кодом, если не сделали этого в редакторе
	$Timer.timeout.connect(_on_spawn_timer_timeout)

func _on_spawn_timer_timeout():
	spawn_zombie()

func spawn_zombie():
	var zombie = zombie_scene.instantiate()
	
	# Генерируем случайную точку
	var random_pos = Vector3(
		randf_range(-spawn_range, spawn_range),
		1.0,
		randf_range(-spawn_range, spawn_range)
	)
	
	# Находим ближайшую точку на навигационной сетке
	var map = get_world_3d().navigation_map
	var safe_pos = NavigationServer3D.map_get_closest_point(map, random_pos)
	
	zombie.global_position = safe_pos
	add_child(zombie)
