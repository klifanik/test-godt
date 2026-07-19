extends Node

signal rewarded_ad_finished(success: bool)
signal interstitial_ad_finished

const SAVE_FILE_PATH = "user://save_game.dat"

var player_data: Dictionary = {
	"coins": 0,
	"kills": 0,
}

var _is_reward_earned: bool = false
var _need_focus_recovery: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	print("[SaveManager] Глобальный менеджер запущен.")
	load_game_local()
	
	if OS.has_feature("web") and has_node("/root/WebBus"):
		if WebBus.has_signal("ad_closed"):
			WebBus.ad_closed.connect(_on_any_ad_closed)
		if WebBus.has_signal("reward_added"):
			WebBus.reward_added.connect(_on_reward_added)
		if WebBus.has_signal("data_loaded"):
			WebBus.data_loaded.connect(_on_webbus_data_loaded)
		
		if WebBus.has_method("load_data"):
			WebBus.load_data()
			
		# Подстраховка: если облако долго отвечает, через 1.5 секунды
		# всё равно принудительно вызываем опрос SDK
		get_tree().create_timer(1.5).timeout.connect(func():
			if not self.has_meta("lang_setup_done"):
				print("[SaveManager] Облако задержалось. Запуск принудительного опроса SDK.")
				setup_yandex_localization()
		)

# Этот метод перехватывает клик/движение мыши для возврата фокуса в браузер
func _input(event: InputEvent) -> void:
	if _need_focus_recovery:
		if event is InputEventMouseButton or event is InputEventMouseMotion or event is InputEventKey:
			_need_focus_recovery = false
			_apply_focus_and_capture()

# --- СИСТЕМА СОХРАНЕНИЙ ---

func save_game_local() -> void:
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(player_data))
		file.close()

func load_game_local() -> void:
	if not FileAccess.file_exists(SAVE_FILE_PATH):
		return
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if file:
		var json = JSON.new()
		if json.parse(file.get_as_text()) == OK:
			for key in json.data.keys():
				player_data[key] = json.data[key]
		file.close()

func save_game() -> void:
	save_game_local()
	if OS.has_feature("web") and has_node("/root/WebBus") and WebBus.has_method("save_data"):
		WebBus.save_data(player_data)

func _on_webbus_data_loaded(cloud_data: Dictionary) -> void:
	if cloud_data:
		print("[SaveManager] Данные из облака получены.")
		for key in cloud_data.keys():
			player_data[key] = cloud_data[key]
		save_game_local()
	
	setup_yandex_localization()

# --- ЛОКАЛИЗАЦИЯ ЯНДЕКСА ---

func setup_yandex_localization() -> void:
	var ya_lang = "" 
	var found_lang = false
	
	# ОПРАШИВАЕМ ТОЛЬКО ЯНДЕКС SDK И ПЛАГИН
	if OS.has_feature("web") and has_node("/root/WebBus"):
		# 1. Проверяем словарь в WebBus
		if WebBus.system_info.has("lang") and str(WebBus.system_info["lang"]) != "":
			ya_lang = str(WebBus.system_info["lang"]).to_lower().strip_edges()
			found_lang = true
			print("[SaveManager] Язык найден в WebBus.system_info -> ", ya_lang)
			
		# 2. Проверяем через глобальный window.ysdk в JS напрямую
		if not found_lang:
			var js_lang = JavaScriptBridge.eval("typeof window.ysdk !== 'undefined' && window.ysdk.environment ? window.ysdk.environment.i18n.lang : null")
			if js_lang != null:
				ya_lang = str(js_lang).to_lower().strip_edges()
				found_lang = true
				print("[SaveManager] Язык получен напрямую через window.ysdk -> ", ya_lang)
				
		# 3. Проверяем свойство ysdk внутри самого узла WebBus
		if not found_lang and "ysdk" in WebBus and WebBus.ysdk != null:
			var js_node_lang = JavaScriptBridge.eval("ysdk.environment.i18n.lang")
			if js_node_lang != null:
				ya_lang = str(js_node_lang).to_lower().strip_edges()
				found_lang = true
				print("[SaveManager] Язык получен через свойство WebBus.ysdk -> ", ya_lang)

	# ЕСЛИ ЯНДЕКС SDK ЕЩЕ НЕ ИНИЦИАЛИЗИРОВАЛСЯ
	if not found_lang:
		if not self.has_meta("lang_attempts"):
			self.set_meta("lang_attempts", 0)
		
		var attempts = self.get_meta("lang_attempts") + 1
		self.set_meta("lang_attempts", attempts)
		
		# Даем Яндексу до 10 секунд на раскачку (10 попыток с интервалом в 1 секунду)
		if attempts < 10:
			print("[SaveManager] Попытка %d: Яндекс SDK еще грузится. Ждем 1 секунду..." % attempts)
			get_tree().create_timer(1.0).timeout.connect(setup_yandex_localization)
			return
		else:
			print("[SaveManager] КРИТИЧЕСКАЯ ОШИБКА: Яндекс SDK не ответил за 10 секунд. Ставим заглушку 'en'.")
			ya_lang = "en"

	# Фиксируем, что настройка завершена
	self.set_meta("lang_setup_done", true)

	# ПРИМЕНЕНИЕ ЯЗЫКА В GODOT
	var supported_languages = ["ru", "en", "tr"] 
	
	if ya_lang in supported_languages:
		TranslationServer.set_locale(ya_lang)
	else:
		TranslationServer.set_locale("en")
	
	# Принудительно обновляем локаль, чтобы Godot перерисовал текст на экране
	var current_locale = TranslationServer.get_locale()
	TranslationServer.set_locale(current_locale) 
	
	print("[SaveManager] Финальный язык игры установлен строго по SDK: ", TranslationServer.get_locale())

# --- РЕКЛАМА ---

func show_regular_ad() -> bool:
	if OS.has_feature("web") and has_node("/root/WebBus"):
		get_tree().paused = true
		WebBus.show_ad()
		# Ждем завершения или таймер подстраховки
		await AnySignals([self.interstitial_ad_finished, get_tree().create_timer(5.0).timeout])
		get_tree().paused = false
		return true # В вебе реклама прошла (или сработал таймер)
	else:
		# На ПК рекламы нет, сразу возвращаем true, чтобы игра шла дальше
		return true

func show_rewarded_ad() -> bool:
	_is_reward_earned = false
	if OS.has_feature("web") and has_node("/root/WebBus"):
		get_tree().paused = true
		WebBus.show_rewarded_ad()
		# Ждем окончания видео
		await AnySignals([self.rewarded_ad_finished, get_tree().create_timer(8.0).timeout])
		get_tree().paused = false
		return _is_reward_earned # Вернет true, если Яндекс подтвердил награду
	else:
		# На ПК рекламы нет, сразу выдаем награду для тестов
		_is_reward_earned = true
		return true

func _on_any_ad_closed() -> void:
	_finalize_ad_state()

func _on_reward_added() -> void:
	_is_reward_earned = true

func _finalize_ad_state() -> void:
	get_tree().paused = false
	_need_focus_recovery = true
	_apply_focus_and_capture()
	interstitial_ad_finished.emit()
	rewarded_ad_finished.emit(_is_reward_earned)

func _apply_focus_and_capture() -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.focus();")
		JavaScriptBridge.eval("if(document.querySelector('canvas')) { document.querySelector('canvas').focus(); }")
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func AnySignals(signals: Array) -> Signal:
	var dummy_signal = Signal(self, "interstitial_ad_finished")
	for sig in signals:
		if sig is Signal:
			sig.connect(func(_a=null): dummy_signal.emit(), ConnectFlags.CONNECT_ONE_SHOT)
	return dummy_signal

func reset_all_data_completely() -> void:
	print("[SaveManager] ЗАПУСК ПОЛНОГО СБРОСА ДАННЫХ...")
	
	# 1. Возвращаем словарь к начальным дефолтным значениям
	player_data = {
		"coins": 0,
		"kills": 0,
		"high_score": 0,
		"level": 1,
		"unlocked_skins": ["default"]
	}
	
	# 2. Удаляем локальный файл с ПК
	if FileAccess.file_exists(SAVE_FILE_PATH):
		var dir = DirAccess.open("user://")
		if dir:
			dir.remove("save_game.dat")
			print("[SaveManager] Локальный файл сохранения удален.")
	
	# 3. Отправляем пустой словарь в Яндекс Облако
	if OS.has_feature("web") and has_node("/root/WebBus") and WebBus.has_method("save_data"):
		WebBus.save_data(player_data)
		print("[SaveManager] Облако Яндекса перезаписано дефолтными данными.")
		
	# 4. Перезагружаем текущую сцену, чтобы интерфейс сразу обновился
	get_tree().reload_current_scene()
