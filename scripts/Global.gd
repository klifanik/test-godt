extends Node

var kills = 0

func _ready() -> void:
	var localized_text = tr("KEY_KILLSLABEL")
	var final_string = localized_text % kills
	var label = get_tree().root.find_child("KillsText", true, false)
	label.text = final_string

func AddKill():
	kills += 1
	var localized_text = tr("KEY_KILLSLABEL")
	var final_string = localized_text % kills
	var label = get_tree().root.find_child("KillsText", true, false)
	label.text = final_string
