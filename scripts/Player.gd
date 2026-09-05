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

# Настройки чувствительности для геймпада
@export var joystick_sensitivity: float = 2.5

@export var minimap_color: Color = Color.YELLOW

@export var step_sound: AudioStream
@export var hit_sound: AudioStream
@export var game_sound: AudioStream
@export var main_sound: AudioStream

# Ограничения обзора по вертикали (чтобы не закидывать голову назад на 360 градусов)
const MIND_LOOK_ANGLE: float = -85.0
const MAX_LOOK_ANGLE: float = 85.0

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
	_create_minimap_marker()

	health_bar.max_value = 100
	health_bar.value = health
	Global.kills = 0
	Global.Coins = 0
	update_health_ui()
	update_label(Global.Coins)
	
	SoundManager.play_music(game_sound)

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
	SoundManager.play_sound_3d(hit_sound, global_position)
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
	cl.get_node("CoinsText").text = tr("KEY_COINSLABEL") % c

func update_health_ui() -> void:
	var label = $"../CanvasLayer/HealthBar/Label"
	label.text = tr("KEY_HEALTHBAR") % [health, health_bar.max_value]

func die() -> void:
	if is_inside_tree():
		SoundManager.stop_music()
		SoundManager.play_music(main_sound)
		$"../CanvasLayer/DeathScreen".visible = true
		$"../CanvasLayer/DeathScreen".start()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		get_tree().paused = true
	
		
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


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
		
	if global_position.y <= -10:
		global_position = Vector3(0.0, 2.0, 0.0)		

	if Input.get_connected_joypads().size() > 0:
		_handle_joystick_look(delta)

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var input_dir := Vector2.ZERO
	if joystick and joystick.has_method("get_velocity"):
		input_dir = joystick.get_velocity()

	if input_dir == Vector2.ZERO and not is_mobile:
		input_dir = Input.get_vector("leftward", "rightward", "forward", "backward")

	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		SoundManager.play_sound_3d_cooldown(step_sound, global_position, 0.55)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
	
func _handle_joystick_look(delta: float) -> void:
	# Получаем вектор отклонения правого стика по осям X и Y
	# get_vector автоматически учитывает мертвую зону (deadzone) геймпада
	var input_vector = Input.get_vector("look_left", "look_right", "look_up", "look_down")
	
	if input_vector.length() > 0:
		# 1. Поворот персонажа влево/вправо (вокруг оси Y)
		# Умножаем на delta, чтобы скорость обзора не зависела от FPS
		var yaw = -input_vector.x * joystick_sensitivity * delta
		rotate_y(yaw)
		
		# 2. Наклон камеры вверх/вниз (вокруг оси X)
		var pitch = -input_vector.y * joystick_sensitivity * delta
		camera_3d.rotate_x(pitch)
		
		# Ограничиваем наклон камеры, чтобы игрок не делал сальто глазами
		var cam_rot = camera_3d.rotation_degrees
		cam_rot.x = clamp(cam_rot.x, MIND_LOOK_ANGLE, MAX_LOOK_ANGLE)
		camera_3d.rotation_degrees = cam_rot
