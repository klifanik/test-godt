extends Node

# --- НАСТРОЙКИ 3D ПО УМОЛЧАНИЮ ---
@export var default_attenuation_start: float = 1.0  # Дистанция, с которой звук начинает затухать
@export var default_max_distance: float = 30.0     # Максимальная дистанция слышимости

# Словарь для отслеживания кулдаунов (чтобы звуки не вызывались слишком часто)
var _cooldowns: Dictionary = {}


## 1. Обычный 3D-звук (одноразовый: выстрел, шаг, удар)
## Автоматически удаляется из памяти после завершения.
func play_sound_3d(
	stream: AudioStream, 
	position: Vector3, 
	bus_name: String = "SFX",
	pitch_randomness: float = 0.1,
	max_distance: float = default_max_distance
) -> void:
	if stream == null:
		return
		
	var player = AudioStreamPlayer3D.new()
	player.stream = stream
	player.global_position = position
	player.bus = bus_name
	
	player.unit_size = default_attenuation_start
	player.max_distance = max_distance
	
	if pitch_randomness > 0.0:
		player.pitch_scale = randf_range(1.0 - pitch_randomness, 1.0 + pitch_randomness)
		
	add_child(player)
	player.play()
	
	# Автоудаление узла после окончания воспроизведения
	player.finished.connect(player.queue_free)


## 2. Безопасный 3D-звук с кулдауном (защита от "треска" в _process / _physics_process)
## Не даёт проиграть один и тот же файл чаще, чем раз в `cooldown_time` секунд.
func play_sound_3d_cooldown(
	stream: AudioStream, 
	position: Vector3, 
	cooldown_time: float = 0.15,
	bus_name: String = "SFX",
	pitch_randomness: float = 0.1
) -> void:
	if stream == null:
		return
		
	var current_time = Time.get_ticks_msec() / 1000.0
	
	# Если этот звук уже вызывался недавно — игнорируем вызов
	if _cooldowns.has(stream):
		if current_time - _cooldowns[stream] < cooldown_time:
			return
			
	_cooldowns[stream] = current_time
	play_sound_3d(stream, position, bus_name, pitch_randomness)


## 3. Длинный или зацикленный 3D-звук (гул мотора, сирена, перезарядка)
## Возвращает ссылку на плеер, чтобы его можно было остановить вручную.
func play_looping_sound_3d(
	stream: AudioStream, 
	position: Vector3, 
	bus_name: String = "SFX"
) -> AudioStreamPlayer3D:
	if stream == null:
		return null
		
	var player = AudioStreamPlayer3D.new()
	player.stream = stream
	player.global_position = position
	player.bus = bus_name
	player.unit_size = default_attenuation_start
	player.max_distance = default_max_distance
	
	add_child(player)
	player.play()
	
	return player


## 4. UI-звук (без 3D-позиционирования: клики кнопок, закадровая музыка, интерфейс)
func play_sound_ui(
	stream: AudioStream, 
	bus_name: String = "SFX",
	pitch_randomness: float = 0.0
) -> void:
	if stream == null:
		return
		
	var player = AudioStreamPlayer.new()
	player.stream = stream
	player.bus = bus_name
	
	if pitch_randomness > 0.0:
		player.pitch_scale = randf_range(1.0 - pitch_randomness, 1.0 + pitch_randomness)
		
	add_child(player)
	player.play()
	
	player.finished.connect(player.queue_free)
