extends CharacterBody3D

@export var speed = 3.0
@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D

@export var attack_damage = 10
@export var attack_range = 1.5
@export var attack_cooldown = 1.0 # Задержка между ударами

var can_attack = true

var player = null

func _ready() -> void:
	# Даем время всем узлам загрузиться
	await get_tree().process_frame
	find_player()

func find_player():
	var nodes = get_tree().get_nodes_in_group("player")
	for node in nodes:
		# Проверяем, что это именно игрок, а не уровень или меш зомби
		if node is CharacterBody3D and node.name != "Zombie":
			player = node
			print("Зомби успешно зацепился за: ", player.name, " путь: ", player.get_path())
			return
	
	if not player:
		print("ВНИМАНИЕ: Настоящий игрок не найден в группе 'player'!")

func _physics_process(delta: float) -> void:
	if not player or not is_instance_valid(player):
		return
		
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
func hit():
	queue_free() # Удаляет зомби из сцены
	
func attack_player():
	# Проверка: если зомби уже удаляется или не в дереве, ничего не делаем
	if not is_inside_tree() or not player:
		return
		
	can_attack = false
	if player.has_method("take_damage"):
		player.take_damage(attack_damage)
	
	# Безопасный способ создания таймера
	var tree = get_tree()
	if tree:
		await tree.create_timer(attack_cooldown).timeout
		can_attack = true
