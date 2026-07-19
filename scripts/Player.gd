extends CharacterBody3D

@onready var skin: MeshInstance3D = $Skin
@onready var camera_3d: Camera3D = $head/Camera3D
@onready var head: Node3D = $head
@onready var health_bar = $"../CanvasLayer/HealthBar"

@onready var joystick: Control = $"../CanvasLayer/Joystick"
@onready var shoot_button: TouchScreenButton = $"../CanvasLayer/MobileControls/shoot"
@onready var reload_button: TouchScreenButton = $"../CanvasLayer/MobileControls/reload"
@onready var use_button: TouchScreenButton = $"../CanvasLayer/MobileControls/use"

@onready var weapon_handler: Node3D = $head/Camera3D/WeaponHandler
@export var weapon_scene: PackedScene = preload("res://scenes/pistol.tscn")
var current_weapon: Node3D = null

const MOUSE_SENSITIVITY = 0.002
const TOUCH_SENSITIVITY = 0.004
const SPEED             = 5.0
const JUMP_VELOCITY     = 4.5

var camera_pitch: float = 0.0
var health: int = 100
var is_mobile: bool = false
var cam_touch_index: int = -1
var cam_last_pos: Vector2 = Vector2.ZERO

@onready var cl: CanvasLayer = $"../CanvasLayer"
@onready var ammo_label: Label = $HUD/AmmoLabel

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
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		
	shoot_button.visible = is_mobile
	reload_button.visible = is_mobile
	use_button.visible = is_mobile
			
	_init_weapon()

	health_bar.max_value = 100
	health_bar.value = health
	Global.kills = 0
	Global.Coins = 0
	update_health_ui()
	update_label(Global.Coins)

func _input(event: InputEvent) -> void:

	if $"../CanvasLayer/DeathScreen".visible:
		return

	# ── ПК: стрельба, перезарядка и поворот мышью ──────────────────────────
	if not is_mobile:
		if Input.is_action_just_pressed("attack"):
			_shoot()
		if Input.is_action_just_pressed("reload"):
			_reload()
			
		if event is InputEventMouseMotion:
			rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
			camera_pitch -= event.relative.y * MOUSE_SENSITIVITY
			camera_pitch = clamp(camera_pitch, deg_to_rad(-89), deg_to_rad(89))
			head.rotation.x = camera_pitch
		return 

	# ── МОБАЙЛ: Ввод ──────────────────────────────────────────────────────
	# Никаких проверок девайсов! Сюда попадут только чистые экшены от UI-кнопок
	if Input.is_action_just_pressed("attack"):
		_shoot()
	if Input.is_action_just_pressed("reload"):
		_reload()

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
	if current_weapon and current_weapon.has_method("shoot"):
			current_weapon.shoot()
			
func _reload() -> void:
	if current_weapon and current_weapon.has_method("reload"):
			current_weapon.reload()

func take_damage(amount: int) -> void:
	health -= amount
	health_bar.value = health
	update_health_ui()
	if health <= 0:
		die()
		
func AddCoin() -> void:
	Global.AddCoin()
	get_tree().get_first_node_in_group("lable").play_effect(50)
	update_label(Global.Coins)
	
func update_label(c: int) -> void:
	var localized_text = tr("KEY_COINSLABEL")
	cl.get_node("CoinsText").text = localized_text % c

func update_health_ui() -> void:
	var label = $"../CanvasLayer/HealthBar/Label"
	label.text = tr("KEY_HEALTHBAR") % [health, health_bar.max_value]

func die() -> void:
	if is_inside_tree():
		$"../CanvasLayer/DeathScreen".visible = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		Engine.time_scale = 0
		
func _on_weapon_ammo_changed(current: int, reserve_ammo: int, max_in_pack: int) -> void:
	if ammo_label:
		ammo_label.text = tr("KEY_AMMOLABEL") % [current, max_in_pack, reserve_ammo]

func _init_weapon() -> void:
	if weapon_scene:
		if current_weapon:
			current_weapon.queue_free()
		
		current_weapon = weapon_scene.instantiate()
		weapon_handler.add_child(current_weapon)
		current_weapon.position = Vector3.ZERO
		current_weapon.rotation = Vector3.ZERO
		
		if current_weapon.has_signal("ammo_changed"):
			if not current_weapon.is_connected("ammo_changed", _on_weapon_ammo_changed):
				current_weapon.connect("ammo_changed", _on_weapon_ammo_changed)
		
		# Первичная инициализация при спавне пушки
		if current_weapon.has_method("_send_ammo_signal"):
			current_weapon._send_ammo_signal()
	else:
		print("Внимание: Сцена оружия не задана в инспекторе игрока.")

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
