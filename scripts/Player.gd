extends CharacterBody3D

@onready var skin: MeshInstance3D = $Skin
@onready var camera_3d: Camera3D = $head/Camera3D
@onready var pos: Node3D = $head/pistol/pos
@onready var head: Node3D = $head
@onready var health_bar = $"../CanvasLayer/HealthBar"
@onready var joystick: Control = $"../CanvasLayer/Joystick"
@onready var shoot_button: Control = $"../CanvasLayer/ShootButton"

const MOUSE_SENSITIVITY = 0.002
const TOUCH_SENSITIVITY = 0.004
const SPEED             = 5.0
const JUMP_VELOCITY     = 4.5

var camera_pitch: float = 0.0
var health: int = 100
var LocalCoins: int = 0
var is_mobile: bool = false

var cam_touch_index: int = -1
var cam_last_pos: Vector2 = Vector2.ZERO

func _ready() -> void:
	var os_name = OS.get_name()
	if os_name == "Android" or os_name == "iOS":
		is_mobile = true
	elif os_name == "Web":
		is_mobile = DisplayServer.is_touchscreen_available()
	else:
		is_mobile = false

	if is_mobile:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		# Подключаем сигнал кнопки стрельбы
		if shoot_button and shoot_button.has_signal("shoot_pressed"):
			shoot_button.shoot_pressed.connect(_shoot)
			shoot_button.visible = true
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		if shoot_button:
			shoot_button.visible = false

	health_bar.max_value = 100
	health_bar.value = health
	Global.kills = 0
	update_health_ui()

func _input(event: InputEvent) -> void:

	if $"../CanvasLayer/DeathScreen".visible:
		return

	# ── ПК: стрельба и поворот мышью ──────────────────────────────────
	if not is_mobile:
		if Input.is_action_just_pressed("attack"):
			_shoot()
		if event is InputEventMouseMotion:
			rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
			camera_pitch -= event.relative.y * MOUSE_SENSITIVITY
			camera_pitch = clamp(camera_pitch, deg_to_rad(-89), deg_to_rad(89))
			head.rotation.x = camera_pitch
		return

	# ── Мобайл: свайп правой зоны = поворот камеры ────────────────────
	var screen_w = get_viewport().get_visible_rect().size.x

	if event is InputEventScreenTouch:
		if event.pressed:
			if event.position.x >= screen_w / 2.0 and cam_touch_index == -1:
				cam_touch_index = event.index
				cam_last_pos    = event.position
		else:
			if event.index == cam_touch_index:
				cam_touch_index = -1

	elif event is InputEventScreenDrag:
		if event.index == cam_touch_index:
			var delta = event.position - cam_last_pos
			cam_last_pos = event.position
			rotate_y(-delta.x * TOUCH_SENSITIVITY)
			camera_pitch -= delta.y * TOUCH_SENSITIVITY
			camera_pitch = clamp(camera_pitch, deg_to_rad(-89), deg_to_rad(89))
			head.rotation.x = camera_pitch

func _shoot() -> void:
	var bullet = preload("res://scenes/bullet.tscn").instantiate()
	get_tree().root.add_child(bullet)
	bullet.global_position = pos.global_position
	var direction = pos.global_transform.basis.x
	bullet.velocity = direction * 30.0
	bullet.look_at(bullet.global_position + direction)

func take_damage(amount: int) -> void:
	health -= amount
	health_bar.value = health
	update_health_ui()
	if health <= 0:
		die()
		
func AddLocalCoin() -> void:
	Global.AddRoundCoin()

func update_health_ui() -> void:
	var label = $"../CanvasLayer/HealthBar/Label"
	label.text = tr("KEY_HEALTHBAR") % [health, health_bar.max_value]

func die() -> void:
	if is_inside_tree():
		$"../CanvasLayer/DeathScreen".visible = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		Engine.time_scale = 0

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var input_dir := Vector2.ZERO
	if joystick and joystick.has_method("get_velocity"):
		input_dir = joystick.get_velocity()

	if input_dir == Vector2.ZERO and not is_mobile:
		input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
