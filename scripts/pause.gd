extends Control

# Загружаем твою сцену настроек
const SETTINGS_SCENE = preload("res://scenes/settings.tscn")
@onready var cl: CanvasLayer = $".."

# Храним ссылку на открытое окно настроек
var current_settings: Control = null

@export var game_sound: AudioStream

var counr: int = 0
var killas: int = 0

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and not $"../DeathScreen".visible and $"../../minimap".visible:
		# 1. Если открыты настройки — закрываем ТОЛЬКО настройки и возвращаем меню паузы
		if is_instance_valid(current_settings):
			_close_settings()
		# 2. Если настройки не открыты — переключаем паузу как обычно
		else:
			if get_tree().paused:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
				set_paused(false)
				SoundManager.play_music(game_sound)
			else:
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
				set_paused(true)

func set_paused(is_paused: bool) -> void:
	SoundManager.stop_music()
	# Если снимаем с паузы, а настройки были открыты — удаляем их
	if not is_paused and is_instance_valid(current_settings):
		_close_settings()
		
	get_tree().paused = is_paused
	visible = is_paused

func _on_continue_pressed() -> void:
	set_paused(false)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	SoundManager.play_music(game_sound)

func _on_exit_pressed() -> void:
	set_paused(false)
	Engine.time_scale = 1.0
	
	killas = Global.kills
	for i in range(Global.Coins):
		Global.DelCoin()
		cl.get_node("CoinsText").text = tr("KEY_COINSLABEL") % Global.Coins
		counr += 1
		
	for i in range(Global.kills):
		Global.DelKill()
		cl.get_node("KillsText").text = tr("KEY_KILLSLABEL") % Global.kills
		counr += 2
		
	SaveManager.player_data["coins"] += counr
	if SaveManager.player_data["kills"] < Global.kills:
		SaveManager.player_data["kills"] = Global.kills
	SaveManager.save_game()
	Global.kills = 0
	Global.Coins = 0
	
	var success = await SaveManager.show_regular_ad()
	if success:
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

# ─── ИЗМЕНЕННАЯ ФУНКЦИЯ НАСТРОЕК ──────────────────────────────────────
func _on_settings_pressed() -> void:
	if not is_instance_valid(current_settings):
		# Создаем сцену настроек
		current_settings = SETTINGS_SCENE.instantiate() as Control
		
		# Добавляем её поверх меню паузы (к родителю, чтобы не перекрывалась элементами этой панели)
		get_parent().add_child(current_settings)
		
		# Прячем само меню паузы, пока открыты настройки
		visible = false
		
		# Если в скрипте res://scenes/settings.tscn есть сигнал "back_pressed" — цепляемся к нему
		if current_settings.has_signal("back_pressed"):
			current_settings.connect("back_pressed", Callable(self, "_close_settings"))

# Вспомогательная функция закрытия настроек
func _close_settings() -> void:
	if is_instance_valid(current_settings):
		current_settings.queue_free()
		current_settings = null
	
	# Возвращаем видимость меню паузы
	visible = true
	
	var player = get_tree().get_first_node_in_group("player")
	player.update_label(Global.Coins)
	player.update_health_ui()
	
	cl.get_node("KillsText").text = tr("KEY_KILLSLABEL") % Global.kills
	
	var pistol = get_tree().get_first_node_in_group("weapon")
	pistol._send_ammo_signal()
	
	cl.get_node("DeathScreen")._ready()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		Input.action_press("ui_cancel")
