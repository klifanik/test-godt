extends Control

func _draw():
	# Вычисляем центр: берем текущий размер узла и делим на 2
	var center = size / 2
	
	var radius = 40.0
	var circle_color = Color(0, 0, 0, 0.5) # Полупрозрачный черный
	
	# Рисуем круг, используя вычисленный центр
	draw_circle(center, radius, circle_color)

func _process(_delta):
	# Если джойстик перемещается по экрану, принудительно обновляем рисунок
	queue_redraw()
