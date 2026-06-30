extends Label

# Переменная для хранения текущей анимации
var current_tween: Tween

func _ready() -> void:
	# Изначально делаем текст полностью прозрачным, чтобы его не было видно при старте игры
	self_modulate.a = 0.0

func play_effect(Yneed: int) -> void:
	# Если старая анимация еще идет — принудительно завершаем её
	if current_tween and current_tween.is_running():
		current_tween.kill()
	
	# Сбрасываем позицию и делаем объект видимым перед началом новой анимации
	position.y = Yneed
	self_modulate.a = 1.0
	
	# Создаем новый Tween и сохраняем ссылку на него
	current_tween = create_tween()
	
	# Мгновенно фиксируем видимость (на всякий случай для цепочки твина)
	current_tween.tween_property(self, "self_modulate:a", 1.0, 0.0) 
	
	# Ждем ровно 1 секунду
	current_tween.tween_interval(1.0)
	
	# Плавно меняем прозрачность до 0 за 1 секунду
	current_tween.tween_property(self, "self_modulate:a", 0.0, 1.0)
