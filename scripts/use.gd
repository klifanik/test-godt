extends TouchScreenButton

func _draw() -> void:
	if texture_normal:
		var center = Vector2(texture_normal.width / 2.0, texture_normal.height / 2.0)
		# МЕНЯЕМ ЦВЕТ НА ЧЕРНЫЙ
		var color = Color.BLACK
		var thickness = 3.0
		
		draw_rect(Rect2(center.x - 12, center.y, 24, 15), color, false, thickness)
		draw_line(center + Vector2(-8, 0), center + Vector2(-8, -18), color, thickness)
		draw_line(center + Vector2(-2, 0), center + Vector2(-2, -22), color, thickness)
		draw_line(center + Vector2(4, 0), center + Vector2(4, -18), color, thickness)
		draw_line(center + Vector2(10, 2), center + Vector2(10, -10), color, thickness)
		draw_line(center + Vector2(-12, 6), center + Vector2(-20, 2), color, thickness)
