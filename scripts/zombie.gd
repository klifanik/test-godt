extends CharacterBody3D

@export var speed = 3.0
@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D

@export var attack_damage = 10
@export var attack_range = 1.5
@export var attack_cooldown = 1.0 # Задержка между ударами

@onready var cl: CanvasLayer = $"../CanvasLayer"

@export var minimap_color: Color = Color.RED

@export var kill_sound: AudioStream

var can_attack: bool = true
var player = null

var ball_scene = preload("res://scenes/ball.tscn")

func _ready() -> void:
	# Даем время всем узлам загрузиться
	await get_tree().process_frame
	find_player()
	
	_create_minimap_marker()

func find_player() -> void:
	var nodes = get_tree().get_nodes_in_group("player")
	for node in nodes:
		# Проверяем, что это именно игрок, а не уровень или меш зомби
		if node is CharacterBody3D and node.name != "Zombie":
			player = node
			return

func _physics_process(delta: float) -> void:
	if not player or not is_instance_valid(player):
		return
		
	if not $"../CanvasLayer/DeathScreen".visible:
		# Расстояние до игрока
		var dist = global_position.distance_to(player.global_position)
		
		# Если зомби близко и может атаковать
		if dist <= attack_range and can_attack:
			attack_player()
			
		# Обновляем цель (позицию игрока)
		nav_agent.target_position = player.global_position
		
		# Гравитация
		if not is_on_floor():
			velocity += get_gravity() * delta
		
		# Если дошли - стоим
		if nav_agent.is_navigation_finished():
			velocity.x = 0
			velocity.z = 0
			move_and_slide()
			return

		# Движение
		var next_path_pos = nav_agent.get_next_path_position()
		var current_pos = global_position
		var new_velocity = (next_path_pos - current_pos).normalized() * speed
		
		velocity.x = new_velocity.x
		velocity.z = new_velocity.z
		
		# Поворот к игроку
		var look_target = Vector3(player.global_position.x, global_position.y, player.global_position.z)
		if global_position.distance_to(look_target) > 0.1:
			look_at(look_target, Vector3.UP)
		
		move_and_slide()
	
# Функция, которую вызовет пуля при попадании
func hit() -> void:
	Global.AddKill()
	cl.get_node("KillsText").text = tr("KEY_KILLSLABEL") % Global.kills
	get_tree().get_first_node_in_group("lable").play_effect(0)
	
	SoundManager.play_sound_3d(kill_sound, global_position)
	
	for i in range(10): # Создаем 10 шариков
		var ball = ball_scene.instantiate()
		get_tree().root.add_child(ball) # Добавляем в корень сцены
		ball.global_position = global_position
		
	queue_free() # Удаляет зомби из сцены
	
	
func attack_player() -> void:
	# Проверка: если зомби уже удаляется или не в дереве, ничего не делаем
	if not is_inside_tree() or not player:
		return
		
	can_attack = false
	if player.has_method("take_damage"):
		player.take_damage(attack_damage)
	
	if not $"../CanvasLayer/DeathScreen".visible:
		# Безопасный способ создания таймера
		var tree = get_tree()
		if tree:
			await tree.create_timer(attack_cooldown).timeout
			can_attack = true
			
			
func _create_minimap_marker() -> void:
	# 1. Создаем плоский 3D-диск (Цилиндр с минимальной высотой)
	var marker_mesh = CylinderMesh.new()
	marker_mesh.top_radius = 1
	marker_mesh.bottom_radius = 0.6
	marker_mesh.height = 0.01 # Делаем его плоским как блин
	
	# 2. Создаем узел, который будет отображать этот диск в мире
	var marker_node = MeshInstance3D.new()
	marker_node.mesh = marker_mesh
	marker_node.name = "MinimapMarker"
	
	# 3. Настраиваем слои видимости: выключаем 1-й (мир), включаем только 2-й (мини-карта)
	marker_node.layers = 0 # Сбрасываем все слои
	marker_node.set_layer_mask_value(1, false) # Не видно основной камере
	marker_node.set_layer_mask_value(2, true)  # Видно камере мини-карты
	
	# 4. Создаем и красим материал в выбранный цвет
	var material = StandardMaterial3D.new()
	material.albedo_color = minimap_color
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED # Чтобы круг всегда ярко светился
	marker_node.set_surface_override_material(0, material)
	
	# 5. Добавляем маркер внутрь нашего зомби
	add_child(marker_node)
	
	# 6. Приподнимаем его над головой объекта (например, на 2.5 метра вверх)
	marker_node.position = Vector3(0.0, 2.5, 0.0)
