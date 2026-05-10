extends Control

@onready var base = $Base
@onready var handle = $Base/Handle

# Радиус, в пределах которого может двигаться рукоятка
@export var max_distance := 100.0

# Ссылка на игрока, чтобы передавать ему направление
@onready var player = $"../../Player" # Проверь путь к узлу игрока!

var dragging := false

func _input(event):
	if event is InputEventScreenTouch or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT):
		# Проверяем, нажали ли мы в области джойстика
		var dist = event.position.distance_to(base.global_position + base.size / 2)
		if event.pressed:
			if dist < max_distance:
				dragging = true
		else:
			dragging = false
			reset_joystick()

	if event is InputEventScreenDrag or (event is InputEventMouseMotion and dragging):
		if dragging:
			update_joystick(event.position)

func update_joystick(touch_pos: Vector2):
	var center = base.global_position + base.size / 2
	var direction = touch_pos - center
	
	# Ограничиваем движение рукоятки радиусом
	if direction.length() > max_distance:
		direction = direction.normalized() * max_distance
	
	handle.global_position = center + direction - handle.size / 2
	
	# Передаем нормализованный вектор игроку (от -1 до 1)
	if player:
		player.joystick_velocity = direction / max_distance

func reset_joystick():
	handle.position = base.size / 2 - handle.size / 2
	if player:
		player.joystick_velocity = Vector2.ZERO
