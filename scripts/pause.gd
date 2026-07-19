extends Control

func _ready() -> void:
	pass

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and not $"../DeathScreen".visible:
		if get_tree().paused:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			set_paused(false)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			set_paused(true)

func set_paused(is_paused: bool) -> void:
	get_tree().paused = is_paused
	visible = is_paused
	
	
func _on_continue_pressed() -> void:
	set_paused(false)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
func _on_exit_pressed() -> void:
	set_paused(false)
	Engine.time_scale = 1.0
	SaveManager.player_data["coins"] += Global.Coins
	if SaveManager.player_data["kills"] < Global.kills:
		SaveManager.player_data["kills"] = Global.kills
	SaveManager.save_game()
	Global.kills = 0
	Global.Coins = 0
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
	

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		Input.action_press("ui_cance")
