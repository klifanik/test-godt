extends Node

var kills: int = 0
var coins: int = 0
var RoundCoins: int = 0

func AddKill() -> void:
	kills += 1
	var label = get_tree().get_first_node_in_group("kills_label")
	if label and label.has_method("update_text"):
		label.update_text(Global.kills)

func AddCoin(value) -> void:
	coins += value
	
func AddRoundCoin() -> void:
	RoundCoins += 1
	print(RoundCoins)
	var label = get_tree().get_first_node_in_group("coins_label")
	if label and label.has_method("update_text"):
		label.update_text(Global.RoundCoins)
