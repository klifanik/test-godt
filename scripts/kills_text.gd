extends Label

func _ready() -> void:
	await get_tree().process_frame
	update_text(Global.kills)

func _process(_delta: float) -> void:
	pass

func update_text(current_kills: int) -> void:
	var localized_text = tr("KEY_KILLSLABEL")
	text = localized_text % current_kills
