extends Node

@onready var top_camera: Camera3D = $"../Camera3D"
@onready var player_node: CharacterBody3D = $"../Player"

@onready var minimap: CanvasLayer = $"../minimap"
@onready var HUD: CanvasLayer = $"../CanvasLayer"

@export var spawn_sound: AudioStream

# --- Настройки сцен объектов (привяжите в Инспекторе) ---
@export var small_home: PackedScene
@export var middle_home: PackedScene
@export var big_home: PackedScene
@export var arcade_machine: PackedScene

# --- Настройки количества объектов ---
@export var SPAWNS: int = 1
@export var smallers: int = 5
@export var middlers: int = 3
@export var biggers: int = 2
@export var arcades: int = 4

# --- Настройки зоны спавна и дистанции ---
@export var spawn_area_size: Vector3 = Vector3(40, 0, 40)
@export var min_distance_between_houses: float = 8.0 # Увеличено для габаритов домов
@export var min_distance_for_arcade: float = 4.0      # Минимальный отступ автомата от домов
@export var center_safe_zone_size: float = 2.5        # Радиус безопасной зоны 5x5 (от -2.5 до +2.5 по X и Z)

var spawned_positions: Array[Vector3] = []

func _ready() -> void:
	# Добавляем нод в группу, чтобы скрипт спавна зомби мог легко найти позиции домов
	add_to_group("MapGenerator")
	
	get_tree().paused = true
	$"../CanvasLayer".visible = false
	$"../minimap".visible = false
	player_node.ammo_label.visible = false
	await get_tree().create_timer(0.5, true).timeout
	generate_map()

func start_next_action() -> void:
	print("Спавн завершен!")

func generate_map() -> void:
	spawned_positions.clear()

	var house_types = [
		{"scene": small_home, "spawn_y": 2.65, "count": smallers, "is_arcade": false},
		{"scene": middle_home, "spawn_y": 3.65, "count": middlers, "is_arcade": false},
		{"scene": big_home, "spawn_y": 5.15, "count": biggers, "is_arcade": false},
		{"scene": arcade_machine, "spawn_y": 0.185, "count": arcades, "is_arcade": true}
	]

	for i in range(SPAWNS):
		for house in house_types:
			if house["scene"] == null or house["count"] <= 0:
				continue
				
			for j in range(house["count"]):
				await get_tree().create_timer(0.05, true).timeout
				spawn_homes(house["scene"], house["spawn_y"], house["is_arcade"])
				
	start_camera_flight()

func spawn_homes(house_scene: PackedScene, spawn_y: float, is_arcade: bool) -> void:
	var free_position = get_random_free_position(spawn_y, is_arcade)
	
	if free_position != Vector3.ZERO:
		SoundManager.play_sound_ui(spawn_sound)
		var new_house = house_scene.instantiate()
		add_child(new_house)
		new_house.global_position = free_position
		
		# Если это игровой автомат — разворачиваем его к центру мира
		if is_arcade:
			var center_target = Vector3(0.0, spawn_y, 0.0)
			if free_position.distance_to(center_target) > 0.1:
				new_house.look_at(center_target, Vector3.UP)
		
		spawned_positions.append(free_position)
	else:
		print("Не удалось найти свободное место для объекта на высоте Y = ", spawn_y)

func get_random_free_position(spawn_y: float, is_arcade: bool) -> Vector3:
	var max_attempts = 100
	var attempt = 0
	
	var required_distance = min_distance_for_arcade if is_arcade else min_distance_between_houses
	
	while attempt < max_attempts:
		var random_x = randf_range(-spawn_area_size.x, spawn_area_size.x)
		var random_z = randf_range(-spawn_area_size.z, spawn_area_size.z)
		
		# Проверка 1: Запрет спавна в центральной зоне 5x5 (от -2.5 до +2.5 по X и Z)
		if abs(random_x) <= center_safe_zone_size and abs(random_z) <= center_safe_zone_size:
			attempt += 1
			continue
		
		var target_pos = Vector3(random_x, spawn_y, random_z)
		var position_is_free = true
		
		# Проверка 2: Расстояние до уже созданных объектов только по осям X и Z
		for pos in spawned_positions:
			var pos_2d_existing = Vector2(pos.x, pos.z)
			var pos_2d_target = Vector2(target_pos.x, target_pos.z)
			
			if pos_2d_target.distance_to(pos_2d_existing) < required_distance:
				position_is_free = false
				break 
				
		if position_is_free:
			return target_pos
			
		attempt += 1
		
	return Vector3.ZERO

func start_camera_intro() -> void:
	if top_camera == null or player_node == null:
		print("Ошибка: Привяжите top_camera и player_node в Инспекторе!")
		return
		
	var player_camera = player_node.my_camera
	if player_camera == null:
		print("Ошибка: В скрипте игрока не найдена переменная my_camera!")
		return

	top_camera.make_current()
	top_camera.global_position.x = 1.691
	top_camera.global_position.z = 6.014
	
	var tween = create_tween()
	
	tween.tween_property(top_camera, "global_position:y", 5.0, 3.5)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_IN_OUT)
		
	tween.finished.connect(start_camera_flight)

func start_camera_flight() -> void:
	var player_camera = player_node.camera_3d
	var fly_tween = create_tween()
	
	fly_tween.parallel().tween_property(top_camera, "global_position", player_camera.global_position, 1.5)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)
		
	fly_tween.parallel().tween_property(top_camera, "global_basis", player_camera.global_basis, 1.5)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)
		
	fly_tween.finished.connect(func(): 
		player_camera.make_current()
		print("Вступление завершено, камера игрока активна!")
		strt()
	)

func strt() -> void:
	$"../CanvasLayer".visible = true
	$"../minimap".visible = true
	player_node.ammo_label.visible = true
	get_tree().paused = false
