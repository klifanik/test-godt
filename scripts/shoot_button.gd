extends Control

# ── Настройки — меняй здесь ───────────────────────────────────────────
@export var button_size:  float = 100.0
@export var margin_right: float = 150.0
@export var margin_bottom: float = 80.0

# Сигнал — подключается в character_body_3d.gd
signal shoot_pressed

var _touch_index: int = -1
var _panel: Panel

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_panel = Panel.new()
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.size = Vector2(button_size, button_size)

	var style = StyleBoxFlat.new()
	style.bg_color          = Color(0.9, 0.2, 0.2, 0.85)
	style.border_color      = Color(1.0, 0.5, 0.5, 1.0)
	style.border_width_left   = 3
	style.border_width_right  = 3
	style.border_width_top    = 3
	style.border_width_bottom = 3
	var r = int(button_size / 2.0)
	style.corner_radius_top_left     = r
	style.corner_radius_top_right    = r
	style.corner_radius_bottom_left  = r
	style.corner_radius_bottom_right = r
	_panel.add_theme_stylebox_override("panel", style)

	# Иконка пули
	var label = Label.new()
	label.text = "🔥"
	label.add_theme_font_size_override("font_size", 36)
	
	# Растягиваем контейнер текста на весь размер панели
	label.size = Vector2(button_size, button_size) 
	label.position = Vector2.ZERO # Сбрасываем позицию в левый верхний угол панели
	
	# Выравниваем сам символ внутри этого контейнера
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(label)

	add_child(_panel)
	_reposition()

func _reposition() -> void:
	var vp = get_viewport().get_visible_rect().size
	_panel.position = Vector2(
		vp.x - button_size - margin_right,
		vp.y - button_size - margin_bottom
	)

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		if _panel:
			_reposition()

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and _touch_index == -1:
			if _panel.get_rect().has_point(event.position):
				_touch_index = event.index
				_set_pressed(true)
				emit_signal("shoot_pressed")
		elif not event.pressed and event.index == _touch_index:
			_touch_index = -1
			_set_pressed(false)

func _set_pressed(on: bool) -> void:
	var style = _panel.get_theme_stylebox("panel") as StyleBoxFlat
	if on:
		style.bg_color = Color(1.0, 0.35, 0.35, 0.95)
		_panel.scale = Vector2(0.92, 0.92)
		_panel.pivot_offset = _panel.size / 2.0
	else:
		style.bg_color = Color(0.9, 0.2, 0.2, 0.85)
		_panel.scale = Vector2(1.0, 1.0)
