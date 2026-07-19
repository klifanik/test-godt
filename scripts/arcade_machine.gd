extends Area3D

@export var minimap_color: Color = Color.BLUE

var is_player_inside: bool = false
var player_body: Node3D = null

func _ready() -> void:
	get_node("/root/main/CanvasLayer/PreesToBuy").visible = false
	_create_minimap_marker()

func _process(delta: float) -> void:
	if is_player_inside and Input.is_action_just_pressed("interact"):
		if Global.Coins >= 5:
			Global.Coins -= 5
			
			if is_instance_valid(player_body) and player_body.has_method("update_label"):
				player_body.update_label(Global.Coins)
				
			var weapon = get_node_or_null("/root/main/Player/head/Camera3D/WeaponHandler/pistol")
			if weapon and weapon.has_method("add_magazine_to_reserve"):
				weapon.add_magazine_to_reserve(1)
		else:
			get_node("/root/main/CanvasLayer/Warning").play_effect()

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		is_player_inside = true
		player_body = body
		get_node("/root/main/CanvasLayer/PreesToBuy").visible = true

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		is_player_inside = false
		player_body = null
		get_node("/root/main/CanvasLayer/PreesToBuy").visible = false
		

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
