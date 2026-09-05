extends Area3D

@export var rotation_speed: float = 2.0 # Скорость вращения монеты
@export var minimap_color: Color = Color.GREEN

@export var sound_coin: AudioStream

func _ready() -> void:
	_create_minimap_marker()

func _physics_process(delta: float) -> void:
	# Красиво вращаем монету вокруг оси Y каждый кадр
	rotate_y(rotation_speed * delta)

func _on_body_entered(body: Node3D) -> void:
	# Проверяем, что в монету врезался именно игрок
	if body.is_in_group("player"):
		
		SoundManager.play_sound_3d(sound_coin, global_position)
		# Тест 3: Есть ли у него метод?
		if body.has_method("AddCoin"):
			body.AddCoin()
			
		# Удаляем монету из игры
		queue_free()

func _create_minimap_marker() -> void:
	# 1. Создаем плоский 3D-диск (Цилиндр с минимальной высотой)
	var marker_mesh = CylinderMesh.new()
	marker_mesh.top_radius = 1
	marker_mesh.bottom_radius = 0.6
	marker_mesh.height = 0.01 # Делаем его плоским как блин
	
	# 2. Создаем узел, который будет отображать этот диск в мире
	var marker_node = MeshInstance3D.new()
	marker_node.mesh = marker_mesh
	marker_node.name = "MinimapMarker"
	
	# 3. Настраиваем слои видимости: выключаем 1-й (мир), включаем только 2-й (мини-карта)
	marker_node.layers = 0 # Сбрасываем все слои
	marker_node.set_layer_mask_value(1, false) # Не видно основной камере
	marker_node.set_layer_mask_value(2, true)  # Видно камере мини-карты
	
	# 4. Создаем и красим материал в выбранный цвет
	var material = StandardMaterial3D.new()
	material.albedo_color = minimap_color
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED # Чтобы круг всегда ярко светился
	marker_node.set_surface_override_material(0, material)
	
	# 5. Добавляем маркер внутрь нашего зомби
	add_child(marker_node)
	
	# 6. Приподнимаем его над головой объекта (например, на 2.5 метра вверх)
	marker_node.position = Vector3(0.0, 2.5, 0.0)
