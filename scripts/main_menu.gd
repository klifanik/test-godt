extends Control

# Вместо preload используем обычный строковый путь. 
# ВНИМАНИЕ: Проверь, чтобы этот путь СТРОГО, до каждой буквы, совпадал с твоим файлом в проводнике!
const NEXT_LEVEL_PATH = "res://scenes/node_3d.tscn"

func _ready() -> void:
	
	# Меню работает в обычном режиме
	process_mode = Node.PROCESS_MODE_INHERIT
	
	var coinsTR = tr("KEY_COINSALL")
	var killsTR = tr("KEY_KILLSALL")
	$Coins.text = coinsTR % SaveManager.player_data["coins"]
	$Record.text = killsTR % SaveManager.player_data["kills"]

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		var coinsTR = tr("KEY_COINSALL")
		var killsTR = tr("KEY_KILLSALL")
		$Coins.text = coinsTR % SaveManager.player_data["coins"]
		$Record.text = killsTR % SaveManager.player_data["kills"]
		
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		Input.action_press("ui_cancel")

func _on_button_pressed() -> void:
	print("[PlayButton] Клик по кнопке Играть. Запрашиваем рекламу...")
	
	# Теперь функция возвращает true, и условие сработает!
	var success = await SaveManager.show_regular_ad()
	
	if success:
		print("[PlayButton] Рекламный блок завершен. Возвращаем фокус и загружаем уровень.")
		
		if OS.has_feature("web"):
			JavaScriptBridge.eval("window.focus();")
		
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		get_tree().change_scene_to_file(NEXT_LEVEL_PATH)

func _on_button_3_pressed() -> void:
	get_tree().quit()
	
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()


func reset_data_pressed() -> void:
	SaveManager.reset_all_data_completely()
