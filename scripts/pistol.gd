extends Node3D

# Сигнал теперь передает: (патроны_в_стволе, патроны_в_кармане, макс_в_магазине)
signal ammo_changed(current_ammo, reserve_ammo, max_in_pack)

@export var bullet_scene: PackedScene = preload("res://scenes/bullet.tscn")

# Настройки
@export var max_ammo: int = 8          # Патронов в одном магазине
@export var total_ammo: int = 24       # ВСЕГО патронов на старте (включая заряженные)
@export var fire_rate: float = 0.3    
@export var reload_time: float = 1.5  

var current_ammo: int
var can_shoot: bool = true
var is_reloading: bool = false

@onready var muzzle: Marker3D = $Muzzle

func _ready() -> void:
	# На старте заряжаем оружие на максимум
	current_ammo = max_ammo
	_send_ammo_signal()

func shoot() -> void:
	if is_reloading or not can_shoot or current_ammo <= 0:
		return
		
	apply_recoil()

	current_ammo -= 1
	total_ammo -= 1 # Уменьшаем общий пул, так как патрон физически улетел
	can_shoot = false
	
	_spawn_bullet()
	_send_ammo_signal()

	await get_tree().create_timer(fire_rate).timeout
	if not is_reloading:
		can_shoot = true

func reload() -> void:
	# Чистый запас патронов в карманах
	var reserve_ammo = total_ammo - current_ammo
	
	# Если перезаряжаемся, пушка полная или в карманах пусто — отмена
	if is_reloading or current_ammo == max_ammo or reserve_ammo <= 0:
		return
		
	is_reloading = true
	can_shoot = false
	
	apply_reload_animation()
	
	await get_tree().create_timer(reload_time).timeout
	
	# Сколько патронов не хватает до полного магазина
	var ammo_needed = max_ammo - current_ammo
	
	if reserve_ammo >= ammo_needed:
		# Если в кармане хватает патронов, забиваем магазин полностью
		current_ammo = max_ammo
	else:
		# Если патронов мало, забираем из кармана всё, что осталось
		current_ammo += reserve_ammo
		
	# Обрати внимание: total_ammo здесь НЕ уменьшается, 
	# потому что патроны просто переместились из кармана в ствол.
	
	is_reloading = false
	can_shoot = true
	_send_ammo_signal()

# Функция для расчета запаса и отправки сигнала в интерфейс
func _send_ammo_signal() -> void:
	var reserve_ammo = total_ammo - current_ammo
	emit_signal("ammo_changed", current_ammo, reserve_ammo, max_ammo)

func _spawn_bullet() -> void:
	if not bullet_scene: return
	var camera = get_parent().get_parent() as Camera3D
	if not camera: return

	var target_transform = camera.global_transform
	var forward_offset = 0.5 
	var forward_vector = -target_transform.basis.z * forward_offset
	target_transform.origin += forward_vector
	
	var bullet = bullet_scene.instantiate()
	get_tree().root.add_child(bullet)
	bullet.global_transform = target_transform

# Функция для автомата: добавляет патроны в общую кучу
func add_magazine_to_reserve(amount: int = 1) -> void:
	# Покупаем пачку? Просто добавляем (кол-во пачек * патроны) к общему запасу
	total_ammo += amount * max_ammo
	_send_ammo_signal()
	
func apply_recoil() -> void:
	# Создаем твин для отдачи (смещения назад и поворота)
	var tween = create_tween().set_parallel(true)
	
	# 1. Отдача назад (сдвигаем по оси Z в локальных координатах)
	# В Godot 4 используем Tween.EASE_OUT и Tween.TRANS_SINE (или TRANS_QUAD)
	tween.tween_property(self, "position:z", 0.15, 0.05).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	# Поворот вверх (небольшой наклон по оси X)
	tween.tween_property(self, "rotation:x", deg_to_rad(10), 0.05).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	# 2. Возврат в исходное положение (вызывается следом)
	var return_tween = create_tween().set_parallel(true)
	return_tween.tween_property(self, "position:z", 0.0, 0.2).set_delay(0.05).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	return_tween.tween_property(self, "rotation:x", 0.0, 0.2).set_delay(0.05).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

@onready var left_hand: MeshInstance3D = $LeftHand
@onready var right_hand: MeshInstance3D = $RightHand

func apply_reload_animation() -> void:
	# Запоминаем исходную позицию левой руки (её дефолтный "дом")
	var hand_home = left_hand.position 
	
	# Точные координаты пистолета по оси X (берём из твоего скриншота)
	var gun_x = -2.083
	
	# Точка подсумка: уводим левую руку сильно левее пистолета и вниз
	var hand_pouch = Vector3(gun_x - 1.5, hand_home.y - 1.5, hand_home.z)
	
	# Точка касания: рука прилетает прямо к пистолету
	var hand_at_gun = Vector3(gun_x, hand_home.y, hand_home.z)
	
	# Точка затвора: рука поднимается чуть выше пистолета
	var hand_bolt_back = Vector3(gun_x, hand_home.y + 0.4, hand_home.z + 0.5)

	var tween = create_tween()

	# === ФАЗА 1: УВОДИМ РУКУ ЗА ПАТРОНАМИ (0.35 сек) ===
	# Пистолет слегка наклоняется, левая рука уходит влево-вниз под экран
	tween.tween_property(self, "rotation:x", deg_to_rad(-12), 0.35).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(left_hand, "position", hand_pouch, 0.35).set_trans(Tween.TRANS_SINE)
	
	# === ФАЗА 2: ПАУЗА ВНИЗУ (0.15 сек) ===
	tween.tween_interval(0.15)
	
	# === ФАЗА 3: РУКА ВСТАВЛЯЕТ МАГАЗИН В ПИСТОЛЕТ (0.2 сек) ===
	# Рука летит из угла СТРОГО к пистолету в точку gun_x
	tween.tween_property(left_hand, "position", hand_at_gun, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	# Пистолет подбрасывает вверх от удара
	tween.tween_property(self, "rotation:x", deg_to_rad(-5), 0.05)
	tween.tween_property(self, "rotation:x", deg_to_rad(-12), 0.05)
	
	# === ФАЗА 4: ВЗВОД ЗАТВОРА (0.3 сек суммарно) ===
	# Рука перемещается на верхнюю часть пистолета и тянет затвор назад
	tween.tween_property(left_hand, "position", hand_bolt_back, 0.15).set_trans(Tween.TRANS_SINE)
	# Возвращается обратно, завершая взвод
	tween.tween_property(left_hand, "position", hand_at_gun, 0.15).set_trans(Tween.TRANS_SINE)
	
	# === ФАЗА 5: ВОЗВРАТ РУКИ И ПИСТОЛЕТА НА МЕСТО (0.35 сек) ===
	# Пистолет выравнивается, левая рука возвращается в свою исходную позицию
	tween.tween_property(self, "rotation:x", 0.0, 0.35).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(left_hand, "position", hand_home, 0.35).set_trans(Tween.TRANS_SINE)
