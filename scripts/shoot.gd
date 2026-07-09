extends TouchScreenButton

func _draw() -> void:
	if texture_normal:
		var center = Vector2(texture_normal.width / 2.0, texture_normal.height / 2.0)
		# МЕНЯЕМ ЦВЕТ НА ЧЕРНЫЙ
		var color = Color.BLACK
		var thickness = 3.0
		
		draw_arc(center, 15.0, 0, 2 * PI, 32, color, thickness)
		draw_line(center + Vector2(0, -25), center + Vector2(0, -10), color, thickness)
		draw_line(center + Vector2(0, 10), center + Vector2(0, 25), color, thickness)
		draw_line(center + Vector2(-25, 0), center + Vector2(-10, 0), color, thickness)
		draw_line(center + Vector2(10, 0), center + Vector2(25, 0), color, thickness)
