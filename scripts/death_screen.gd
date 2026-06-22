extends Control

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass



func _on_button_pressed() -> void:
	Engine.time_scale = 1.0
	Global.kills = 0
	get_tree().change_scene_to_file("res://scenes/node_3d.tscn")
	$".".visible = false


func _on_exit_btn_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
