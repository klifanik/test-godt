extends CharacterBody3D

@onready var skin: MeshInstance3D = $Skin
@onready var camera_3d: Camera3D = $head/Camera3D
@onready var pos: Node3D = $head/pistol/pos
@onready var head: Node3D = $head

# Путь к прогрессбару
@onready var health_bar = $"../CanvasLayer/HealthBar"

const BUL = preload("res://scenes/bullet.tscn")
const MOUSE_SENSITIVITY = 0.002
var camera_pitch: float = 0.0

var health = 100

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	health_bar.max_value = 100
	health_bar.value = health
	
	# Обновляем текст при старте
	update_health_ui()

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("attack") and not $"../CanvasLayer/DeathScreen".visible:
		var bullet_scene = preload("res://scenes/bullet.tscn")
		var bullet = bullet_scene.instantiate()
		get_tree().root.add_child(bullet)
		var muzzle = pos
		bullet.global_position = muzzle.global_position
		var direction = muzzle.global_transform.basis.x
		bullet.velocity = direction * 30.0 
		bullet.look_at(bullet.global_position + direction)
		
	if event is InputEventMouseMotion and not $"../CanvasLayer/DeathScreen".visible:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		camera_pitch -= event.relative.y * MOUSE_SENSITIVITY
		camera_pitch = clamp(camera_pitch, deg_to_rad(-89), deg_to_rad(89))
		head.rotation.x = camera_pitch
		
func take_damage(amount: int):
	health -= amount
	health_bar.value = health
	
	# Обновляем текст при получении урона
	update_health_ui()
	
	if health <= 0:
		die()

# Вынес обновление текста в отдельную функцию, чтобы не дублировать код
func update_health_ui():
	var localized_text = tr("KEY_HEALTHBAR")
	var final_string = localized_text % [health, health_bar.max_value]
	var label = $"../CanvasLayer/HealthBar/Label"
	label.text = final_string
		
func die():
	if is_inside_tree():
		$"../CanvasLayer/DeathScreen".visible = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		Engine.time_scale = 0

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
