extends RigidBody3D

func _ready() -> void:
	# 1. Делаем материал уникальным для ЭТОГО шарика
	var mesh = $MeshInstance3D
	var mat = mesh.get_active_material(0)
	
	if mat:
		# .duplicate() создает копию материала именно для этого узла
		mesh.material_override = mat.duplicate()
	
	# Импульс
	var random_force = Vector3(randf_range(-5, 5), randf_range(2, 6), randf_range(-5, 5))
	apply_impulse(random_force)
	
	fade_out()

func fade_out() -> void:
	var tween = create_tween()
	
	# Используем mesh.material_override, так как мы его только что создали
	var mat = $MeshInstance3D.material_override
	
	tween.tween_interval(1.5)
	# Меняем альфа-канал у нашей уникальной копии материала
	tween.tween_property(mat, "albedo_color:a", 0.0, 2.0)
	
	tween.tween_callback(queue_free)
