extends Control

# Вместо preload используем обычный строковый путь. 
# ВНИМАНИЕ: Проверь, чтобы этот путь СТРОГО, до каждой буквы, совпадал с твоим файлом в проводнике!
const NEXT_LEVEL_PATH = "res://scenes/node_3d.tscn"

func _ready() -> void:
	print("Ваш язык:"+SaveManager.player_data["language"])
	
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	SoundManager.stop_music()
	
	if SaveManager.player_data["fullscreen"]:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(SaveManager.player_data["music"]))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(SaveManager.player_data["sounds"]))
	
	if OS.get_name() == "Web":
		$VBoxContainer/Button3.text = tr("KEY_SHOP")

	$Coins.text = tr("KEY_COINSALL") % SaveManager.player_data.get("coins", 0)
	$Record.text = tr("KEY_KILLSALL") % SaveManager.player_data.get("kills", 0)
	
	#SaveManager.call_game_ready()

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		if SaveManager.player_data["language"] != "":
			TranslationServer.set_locale(SaveManager.player_data["language"])
		
		$Coins.text = tr("KEY_COINSALL") % SaveManager.player_data["coins"]
		$Record.text = tr("KEY_KILLSALL") % SaveManager.player_data["kills"]
		
		if OS.get_name() == "Web":
			$VBoxContainer/Button3.text = tr("KEY_SHOP")
			SaveManager.call_game_ready()
		
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		Input.action_press("ui_cancel")

func _on_button_pressed() -> void:
	print("[PlayButton] Клик по кнопке Играть. Запрашиваем рекламу...")
	
	## Теперь функция возвращает true, и условие сработает!
	#var success = await SaveManager.show_regular_ad()
	#
	#if success:
		#print("[PlayButton] Рекламный блок завершен. Возвращаем фокус и загружаем уровень.")
		
		#if OS.has_feature("web"):
			#JavaScriptBridge.eval("window.focus();")
		
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	get_tree().change_scene_to_file(NEXT_LEVEL_PATH)
		
func _on_button_2_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/settings.tscn")

func _on_button_3_pressed() -> void:
	if OS.get_name() != "Web":
		get_tree().quit()
	
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and OS.get_name() != "Web":
		get_tree().quit()
