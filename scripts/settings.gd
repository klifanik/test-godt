extends Control

signal back_pressed

func _ready() -> void:
	if get_tree().paused:
		$background.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	
	if OS.get_name() in ["Android", "iOS", "Web"]:
		$VBoxContainer/fullscreen.visible = false
		
	$VBoxContainer/fullscreen.button_pressed = SaveManager.player_data["fullscreen"]
	
	$VBoxContainer/music.value = SaveManager.player_data["music"]
	$VBoxContainer/sound.value = SaveManager.player_data["sounds"]
	
	# Используем set_pressed_no_signal, чтобы кнопка НЕ генерировала сигнал toggled при открытии меню
	$VBoxContainer/hitboxes.set_pressed_no_signal(SaveManager.player_data["hitboxes"])

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		SaveManager.save_game()
		if get_tree().paused:
			back_pressed.emit()
			queue_free()
		else:
			get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _on_music_value_changed(value: float) -> void:
	var bus_index = AudioServer.get_bus_index("Music")
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(value))
	SaveManager.player_data["music"] = value

func _on_sound_value_changed(value: float) -> void:
	var bus_index = AudioServer.get_bus_index("SFX")
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(value))
	SaveManager.player_data["sounds"] = value

func _on_check_button_toggled(toggled_on: bool) -> void:
	SaveManager.player_data["hitboxes"] = toggled_on
	SaveManager.save_game()
	HitboxDebugger.update_hitboxes()

func _on_lang_pressed() -> void:
	if TranslationServer.get_locale().begins_with("en"):
		TranslationServer.set_locale("ru")
		SaveManager.player_data["language"] = "ru"
	else:
		TranslationServer.set_locale("en")
		SaveManager.player_data["language"] = "en"

func _on_reset_pressed() -> void:
	SaveManager.reset_all_data_completely()

func _on_exit_pressed() -> void:
	SaveManager.save_game()
	if get_tree().paused:
		back_pressed.emit()
		queue_free()
	else:
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _on_fullscreen_toggled(toggled_on: bool) -> void:
	SaveManager.player_data["fullscreen"] = toggled_on
	
	if toggled_on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
