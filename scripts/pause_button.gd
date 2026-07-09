extends Button

var is_mobile: bool
@onready var box: HBoxContainer = $HBoxContainer

func _ready() -> void:
	box.modulate = Color(1, 1, 1, 1)
	
	if OS.get_name() == "Android" or OS.get_name() == "iOS":
		is_mobile = true
	elif OS.get_name() == "Web":
		is_mobile = DisplayServer.is_touchscreen_available()
	else:
		is_mobile = false
		
	visible = is_mobile


func _on_mouse_entered() -> void:
	box.modulate = Color(0.7, 0.7, 0.7, 1)

func _on_mouse_exited() -> void:
	if not button_pressed:
		box.modulate = Color(1, 1, 1, 1)

func _on_button_down() -> void:
	box.modulate = Color(0.4, 0.4, 0.4, 1)

func _on_button_up() -> void:
	box.modulate = Color(0.7, 0.7, 0.7, 1)
	get_node("/root/main/CanvasLayer/pause").set_paused(true)
