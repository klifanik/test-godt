extends Camera3D

# Ссылка на твоего игрока. 
# Укажи правильный путь к узлу игрока в твоей сцене через Инспектор или код
@export var player: CharacterBody3D

@onready var panel: Panel = $"../../../Panel"
@onready var view: SubViewportContainer = $"../.."

func _ready() -> void:
	var is_mobile: bool = false
	if OS.get_name() == "Android" or OS.get_name() == "iOS":
		is_mobile = true
	elif OS.get_name() == "Web":
		is_mobile = DisplayServer.is_touchscreen_available()
	else:
		is_mobile = false
		
	if not is_mobile:
		view.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT, Control.PRESET_MODE_MINSIZE)
		view.grow_horizontal = Control.GROW_DIRECTION_BEGIN
		view.grow_vertical = Control.GROW_DIRECTION_BEGIN
		panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
		panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
		panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
		view.position += Vector2(-20, -20)
		panel.position += Vector2(-20, -20)

func _physics_process(_delta: float) -> void:
	if player:
		# Копируем координаты игрока по осям X и Z (вперед-назад, влево-вправо)
		# Но оставляем высоту камеры (Y) неизменной в небе
		global_position.x = player.global_position.x
		global_position.z = player.global_position.z
