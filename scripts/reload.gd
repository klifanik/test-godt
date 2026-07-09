extends TouchScreenButton

func _draw() -> void:
	if texture_normal:
		var center = Vector2(texture_normal.width / 2.0, texture_normal.height / 2.0)
		# МЕНЯЕМ ЦВЕТ НА ЧЕРНЫЙ
		var color = Color.BLACK
		var thickness = 4.0
		var radius = 18.0
		
		draw_arc(center, radius, 0.0, 1.5 * PI, 32, color, thickness)
		
		var arrow_pos = center + Vector2(0, -radius)
		draw_line(arrow_pos, arrow_pos + Vector2(-8, -4), color, thickness)
		draw_line(arrow_pos, arrow_pos + Vector2(-4, 8), color, thickness)
