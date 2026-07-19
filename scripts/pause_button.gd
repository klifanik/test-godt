extends Button

var is_mobile: bool

func _ready() -> void:
	
	if OS.get_name() == "Android" or OS.get_name() == "iOS":
		is_mobile = true
	elif OS.get_name() == "Web":
		is_mobile = DisplayServer.is_touchscreen_available()
	else:
		is_mobile = false
		
	visible = is_mobile


func _on_button_up() -> void:
	get_node("/root/main/CanvasLayer/pause").set_paused(true)
