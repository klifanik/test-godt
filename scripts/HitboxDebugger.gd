extends Node

# Группа для служебных мешей подсветки
const DEBUG_MESH_GROUP = "debug_hitbox_meshes"

func _ready() -> void:
	# Следим за появлением новых объектов на сцене (монеты, спавн зомби)
	get_tree().node_added.connect(_on_node_added)
	
	# Даем слене инициализироваться и сразу обновляем хитбоксы на основе сохранения
	await get_tree().process_frame
	update_hitboxes()

# ─── ФУНКЦИЯ ОБНОВЛЕНИЯ (Вызывай её при клике по кнопке в настройках) ─
func update_hitboxes() -> void:
	# Считываем значение напрямую из твоей сохраненной переменной
	var is_enabled: bool = SaveManager.player_data.get("hitboxes", false)
	
	if is_enabled:
		_show_hitboxes()
	else:
		_hide_hitboxes()

# ─── АВТОМАТИЧЕСКИЙ ПЕРЕХВАТ СПАВНЯЩИХСЯ ОБЪЕКТОВ (МОНЕТЫ/ЗОМБИ) ───────
func _on_node_added(node: Node) -> void:
	# Проверяем переменную из сохранения
	if SaveManager.player_data.get("hitboxes", false) and node is CollisionShape3D:
		# Ждём кадр, чтобы объект полностью добавился в дерево
		await get_tree().process_frame
		if is_instance_valid(node) and node.shape:
			if not _is_inside_ignored_node(node):
				_create_debug_mesh(node)

# ─── ОТРИСОВКА ХИТБОКСОВ ──────────────────────────────────────────────
func _show_hitboxes() -> void:
	_hide_hitboxes() # Очищаем старые меши
	
	if get_tree().current_scene:
		_find_and_draw_shapes(get_tree().current_scene)

func _find_and_draw_shapes(node: Node) -> void:
	# Игнорируем игрока, навигацию и сами меши отладки
	if _is_ignored_node(node):
		return

	# Если нашли CollisionShape3D с формой
	if node is CollisionShape3D and node.shape:
		_create_debug_mesh(node)

	# Идем глубже по дочерним узлам
	for child in node.get_children():
		_find_and_draw_shapes(child)

# ─── СОЗДАНИЕ И НАСТРОЙКА ВИЗУАЛЬНОГО МЕША ────────────────────────────
func _create_debug_mesh(col_shape: CollisionShape3D) -> void:
	# Защита от дубликатов
	for child in col_shape.get_children():
		if child.is_in_group(DEBUG_MESH_GROUP):
			return

	var shape_mesh = col_shape.shape.get_debug_mesh()
	if not shape_mesh:
		return

	var debug_mesh = MeshInstance3D.new()
	debug_mesh.mesh = shape_mesh
	debug_mesh.add_to_group(DEBUG_MESH_GROUP)

	# ─── ОПРЕДЕЛЕНИЕ ЦВЕТА ПО ГРУППАМ И ТИПАМ ─────────────────────────
	var color: Color = Color(0.0, 1.0, 0.0, 0.4) # Зеленый по умолчанию (декор/стены)

	if _has_group_in_parents(col_shape, "enemy") or col_shape.get_parent() is CharacterBody3D:
		color = Color(1.0, 0.0, 0.0, 0.4) # Красный для зомби и врагов
	elif _has_group_in_parents(col_shape, "coin") or _has_group_in_parents(col_shape, "loot"):
		color = Color(1.0, 0.8, 0.0, 0.5) # Золотисто-желтый для монет
	elif col_shape.get_parent() is Area3D:
		color = Color(0.0, 0.8, 1.0, 0.4) # Голубой для зон и триггеров

	# ─── СОЗДАНИЕ МАТЕРИАЛА ────────────────────────────────────────────
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.no_depth_test = true # Отображается поверх моделей без мерцания

	debug_mesh.material_override = mat
	col_shape.add_child(debug_mesh)

# ─── ВСПОМОГАТЕЛЬНЫЕ ПРОВЕРКИ ─────────────────────────────────────────

func _is_ignored_node(node: Node) -> bool:
	return node.is_in_group("player") or node is NavigationRegion3D or node.is_in_group(DEBUG_MESH_GROUP)

func _is_inside_ignored_node(node: Node) -> bool:
	var current: Node = node
	while current != null:
		if _is_ignored_node(current):
			return true
		current = current.get_parent()
	return false

func _has_group_in_parents(node: Node, group_name: String) -> bool:
	var current: Node = node
	while current != null:
		if current.is_in_group(group_name):
			return true
		current = current.get_parent()
	return false

# ─── ОЧИСТКА ─────────────────────────────────────────────────────────
func _hide_hitboxes() -> void:
	var debug_meshes = get_tree().get_nodes_in_group(DEBUG_MESH_GROUP)
	for mesh in debug_meshes:
		mesh.queue_free()
