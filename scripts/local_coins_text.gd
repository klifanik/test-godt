extends Label

func _ready() -> void:
	await get_tree().process_frame
	update_text(Global.RoundCoins)
	
func  _process(delta: float) -> void:
	pass

func update_text(c: int) -> void:
	var localized_text = tr("KEY_LOCALCOINS_LABEL")
	text = localized_text % c
