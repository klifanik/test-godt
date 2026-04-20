extends Node3D

# Загружаем сцену зомби
var zombie_scene = preload("res://scenes/zombie.tscn")

# Границы спавна (исходя из размера пола 100x100)
var spawn_range = 45.0 

func _ready():
	# Подключаем сигнал таймера кодом, если не сделали этого в редакторе
	$Timer.timeout.connect(_on_spawn_timer_timeout)

func _on_spawn_timer_timeout():
	spawn_zombie()
	
func _on_button_pressed() -> void:
	Engine.time_scale = 1.0
	Global.kills = 0
	get_tree().reload_current_scene()

func spawn_zombie():
	var zombie = zombie_scene.instantiate()
	
	# СНАЧАЛА добавляем в дерево
	add_child(zombie)
	
	# ТЕПЕРЬ задаем позицию
	var random_x = randf_range(-spawn_range, spawn_range)
	var random_z = randf_range(-spawn_range, spawn_range)
	zombie.global_position = Vector3(random_x, 2.0, random_z)
