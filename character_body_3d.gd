extends CharacterBody3D

@onready var skin: MeshInstance3D = $Skin
@onready var camera_3d: Camera3D = $head/Camera3D
@onready var pos: Node3D = $head/pistol/pos
@onready var head: Node3D = $head

const BUL = preload("res://bullet.tscn")

const MOUSE_SENSITIVITY = 0.002
var camera_pitch: float = 0.0

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("attack"):
		var bullet_scene = preload("res://bullet.tscn")
		var bullet = bullet_scene.instantiate()
		
		# Добавляем на уровень, чтобы пуля не двигалась вместе с игроком
		get_tree().root.add_child(bullet)
		
		# Точка выхода пули
		var muzzle = $head/pistol/pos 
		bullet.global_position = muzzle.global_position
		
		# Определяем направление. 
		# В Godot вперед - это -muzzle.global_transform.basis.z.
		# Если летит в бок, попробуй сменить .z на .x или .y
		var direction = muzzle.global_transform.basis.x
		
		# Задаем скорость и поворот
		bullet.velocity = direction * 30.0 
		bullet.look_at(bullet.global_position + direction)
		
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		camera_pitch -= event.relative.y * MOUSE_SENSITIVITY
		camera_pitch = clamp(camera_pitch, deg_to_rad(-89), deg_to_rad(89))
		head.rotation.x = camera_pitch

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
