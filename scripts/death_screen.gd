extends Control

@export var game_sound: AudioStream
@export var main_sound: AudioStream
@export var balance_sound: AudioStream

@onready var coinsearnl: Label = $coinsall
@onready var cl: CanvasLayer = $".."
@onready var VObx: VBoxContainer = $VBoxContainer

var counr: int = 0
var killas: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	coinsearnl.text = tr("KEY_COINSEARN") % [counr]
	VObx.modulate.a = 0.0
	VObx.visible = false

func start() -> void:
	killas = Global.kills
	
	for i in range(Global.Coins):
		await get_tree().create_timer(0.025).timeout
		Global.DelCoin()
		cl.get_node("CoinsText").text = tr("KEY_COINSLABEL") % Global.Coins
		counr += 1
		coinsearnl.text = tr("KEY_COINSEARN") % [counr]
		SoundManager.play_sound_ui(balance_sound)
		
	await get_tree().create_timer(0.35).timeout
	
	for i in range(Global.kills):
		await get_tree().create_timer(0.025).timeout
		Global.DelKill()
		cl.get_node("KillsText").text = tr("KEY_KILLSLABEL") % Global.kills
		counr += 2
		coinsearnl.text = tr("KEY_COINSEARN") % [counr]
		SoundManager.play_sound_ui(balance_sound)
		
	show_smoothly()
	lift_to(233.0)

func _on_button_pressed() -> void:
	get_tree().paused = false
	SaveManager.player_data["coins"] += counr
	if SaveManager.player_data["kills"] < killas:
		SaveManager.player_data["kills"] = killas
	print(killas)
	SaveManager.save_game()
	Global.kills = 0
	Global.Coins = 0
	var success = await SaveManager.show_regular_ad()
	if success:
		get_tree().change_scene_to_file("res://scenes/node_3d.tscn")
		$".".visible = false
		
		SoundManager.stop_music()
		SoundManager.play_music(game_sound)


func _on_exit_btn_pressed() -> void:
	get_tree().paused = false
	SaveManager.player_data["coins"] += counr
	if SaveManager.player_data["kills"] < killas:
		SaveManager.player_data["kills"] = killas
	SaveManager.save_game()
	Global.kills = 0
	Global.Coins = 0
	$".".visible = false
	var success = await SaveManager.show_regular_ad()
	if success:
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")


func _on_ad_btn_pressed() -> void:
	print("[AdButton] Клик по кнопке Возрождение. Запрашиваем рекламу...")
	
	# Убран лишний дублирующий вызов! Вызываем ОДИН раз и ждем результат
	var success = await SaveManager.show_rewarded_ad()
	
	if success:
		print("[AdButton] Награда получена, оживляем игрока.")
		get_tree().paused = false
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
		
		SoundManager.stop_music()
		SoundManager.play_music(game_sound)
	else:
		print("[AdButton] Реклама не досмотрена. Награда не выдана.")
		
func show_smoothly(duration: float = 1.0) -> void:
	# Делаем объект видимым перед анимацией
	VObx.visible = true
	
	# Создаем Tween
	var tween := create_tween()
	
	# Анимируем альфа-канал (прозрачность) от текущего значения (0.0) до 1.0
	tween.tween_property(VObx, "modulate:a", 1.0, duration)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)

func lift_to(target_y: float, duration: float = 1.0) -> void:
	var tween := create_tween()
	
	# Плавно меняем координату Y с текущей до target_y
	tween.tween_property(coinsearnl, "position:y", target_y, duration)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_OUT)
