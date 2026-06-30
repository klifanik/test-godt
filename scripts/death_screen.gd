extends Control

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_button_pressed() -> void:
	Engine.time_scale = 1.0
	SaveManager.player_data["coins"] += Global.Coins
	if SaveManager.player_data["kills"] < Global.kills:
		SaveManager.player_data["kills"] = Global.kills
	SaveManager.save_game()
	Global.kills = 0
	Global.Coins = 0
	get_tree().change_scene_to_file("res://scenes/node_3d.tscn")
	$".".visible = false


func _on_exit_btn_pressed() -> void:
	Engine.time_scale = 1.0
	SaveManager.player_data["coins"] += Global.Coins
	if SaveManager.player_data["kills"] < Global.kills:
		SaveManager.player_data["kills"] = Global.kills
	SaveManager.save_game()
	Global.kills = 0
	Global.Coins = 0
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
	$".".visible = false


func _on_ad_btn_pressed() -> void:
	# Вызываем рекламу
	SaveManager.show_rewarded_ad()

	# Ждем ответ: true (досмотрел) или false (закрыл раньше)
	var success = await SaveManager.rewarded_ad_finished

	if success:

		Engine.time_scale = 1.0
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		
		var player = get_tree().get_first_node_in_group("player")
		if player and player.has_method("update_health_ui"):
			player.health = 100
			player.update_health_ui()
			player.health_bar.value = 100
			
		var nodes = get_tree().get_nodes_in_group("zombie")
		for node in nodes:
			node.queue_free()
			
		$".".visible = false
	else:
		print("Реклама не досмотрена.")
