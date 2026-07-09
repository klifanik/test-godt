extends Control

signal shoot_pressed
signal reload_pressed
signal interact_pressed

@onready var shoot_btn: TouchScreenButton = $shoot
@onready var reload_btn: TouchScreenButton = $reload
@onready var interact_btn: TouchScreenButton = $use

# Переменные для хранения базовых позиций кнопок
var _shoot_base_pos: Vector2
var _reload_base_pos: Vector2
var _interact_base_pos: Vector2

func _ready() -> void:
	# Сохраняем исходные позиции кнопок, которые ты настроил в редакторе
	_shoot_base_pos = shoot_btn.position
	_reload_base_pos = reload_btn.position
	_interact_base_pos = interact_btn.position

	# Подключаем сигналы
	shoot_btn.pressed.connect(_on_shoot_pressed)
	shoot_btn.released.connect(_on_shoot_released)
	
	reload_btn.pressed.connect(_on_reload_pressed)
	reload_btn.released.connect(_on_reload_released)
	
	interact_btn.pressed.connect(_on_interact_pressed)
	interact_btn.released.connect(_on_interact_released)

func _on_shoot_pressed() -> void:
	_animate_button(shoot_btn, _shoot_base_pos, true)
	shoot_pressed.emit()

func _on_shoot_released() -> void:
	_animate_button(shoot_btn, _shoot_base_pos, false)

func _on_reload_pressed() -> void:
	_animate_button(reload_btn, _reload_base_pos, true)
	reload_pressed.emit()

func _on_reload_released() -> void:
	_animate_button(reload_btn, _reload_base_pos, false)

func _on_interact_pressed() -> void:
	_animate_button(interact_btn, _interact_base_pos, true)
	Input.action_press("interact")

func _on_interact_released() -> void:
	_animate_button(interact_btn, _interact_base_pos, false)
	Input.action_release("interact")

# Универсальная функция анимации, которая компенсирует отсутствие Пивота у TouchScreenButton
func _animate_button(button: TouchScreenButton, base_pos: Vector2, is_pressed: bool) -> void:
	if is_pressed:
		# Уменьшаем масштаб кнопки
		button.scale = Vector2(0.92, 0.92)
		button.modulate = Color(1.3, 1.3, 1.3, 1.0)
		
		# Высчитываем сдвиг, чтобы кнопка визуально уменьшалась к своему центру
		if button.texture_normal:
			var size = button.texture_normal.get_size()
			var shift = (size - (size * 0.92)) / 2.0
			button.position = base_pos + shift
	else:
		# Возвращаем всё в исходное состояние
		button.scale = Vector2(1.0, 1.0)
		button.modulate = Color(1.0, 1.0, 1.0, 1.0)
		button.position = base_pos
	
	button.queue_redraw()
