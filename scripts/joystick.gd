extends Control

# ── Настройки ──────────────────────────────────────────────────────────
@export var radius: float = 80.0          # макс. отклонение кружка от центра

# ── Ноды (задаются в _ready через код, не нужны отдельные TextureRect) ──
var base_node: Control      # подложка (серый круг)
var knob_node: Control      # кружок (белый)

# ── Внутреннее состояние ───────────────────────────────────────────────
var touch_index: int = -1
var start_pos: Vector2 = Vector2.ZERO
var current_value: Vector2 = Vector2.ZERO   # нормализованный вектор (-1..1)

const BASE_SIZE  = 160.0
const KNOB_SIZE  = 70.0

func _ready() -> void:
	# Растягиваем на весь экран — обрабатываем только левую половину
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE   # не блокируем мышь

	# Создаём подложку
	base_node = _make_circle(BASE_SIZE, Color(1, 1, 1, 0.15), Color(1, 1, 1, 0.35))
	add_child(base_node)
	base_node.visible = false

	# Создаём кружок
	knob_node = _make_circle(KNOB_SIZE, Color(1, 1, 1, 0.55), Color(1, 1, 1, 0.8))
	base_node.add_child(knob_node)
	_center_knob()

func _make_circle(size: float, fill: Color, border: Color) -> Control:
	var c = Control.new()
	c.custom_minimum_size = Vector2(size, size)
	c.size = Vector2(size, size)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var draw = func(_node):
		c.draw_circle(Vector2(size, size) / 2.0, size / 2.0, fill)
		c.draw_arc(Vector2(size, size) / 2.0, size / 2.0 - 1.5, 0, TAU, 64, border, 2.5)
	c.connect("draw", Callable(c, "queue_redraw").unbind(0))
	# Простой способ рисовать — используем ColorRect + скругление через StyleBox не нужно,
	# просто переопределим _draw через скрипт-лямбду через SubClass не выйдет в рантайме,
	# поэтому рисуем через встроенный механизм draw_circle напрямую на Panel
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(size, size)
	panel.size = Vector2(size, size)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var style = StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.border_width_left   = 2
	style.border_width_right  = 2
	style.border_width_top    = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left     = int(size / 2.0)
	style.corner_radius_top_right    = int(size / 2.0)
	style.corner_radius_bottom_left  = int(size / 2.0)
	style.corner_radius_bottom_right = int(size / 2.0)
	panel.add_theme_stylebox_override("panel", style)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return panel

func _center_knob() -> void:
	knob_node.position = (Vector2(BASE_SIZE, BASE_SIZE) - Vector2(KNOB_SIZE, KNOB_SIZE)) / 2.0

# ── Публичный API ──────────────────────────────────────────────────────
func get_velocity() -> Vector2:
	return current_value

# ── Ввод ───────────────────────────────────────────────────────────────
func _input(event: InputEvent) -> void:
	var screen_w = get_viewport().get_visible_rect().size.x

	if event is InputEventScreenTouch:
		if event.pressed:
			# Принимаем только касания в левой половине экрана
			if event.position.x < screen_w / 2.0 and touch_index == -1:
				touch_index = event.index
				start_pos   = event.position
				_show_at(event.position)
		else:
			if event.index == touch_index:
				_reset()

	elif event is InputEventScreenDrag:
		if event.index == touch_index:
			_update(event.position)

# ── Приватные методы ───────────────────────────────────────────────────
func _show_at(pos: Vector2) -> void:
	base_node.visible = true
	base_node.position = pos - Vector2(BASE_SIZE, BASE_SIZE) / 2.0
	_center_knob()

func _update(touch_pos: Vector2) -> void:
	var offset = touch_pos - start_pos
	if offset.length() > radius:
		offset = offset.normalized() * radius

	knob_node.position = (Vector2(BASE_SIZE, BASE_SIZE) - Vector2(KNOB_SIZE, KNOB_SIZE)) / 2.0 + offset
	current_value = offset / radius

func _reset() -> void:
	touch_index   = -1
	current_value = Vector2.ZERO
	base_node.visible = false
	_center_knob()
