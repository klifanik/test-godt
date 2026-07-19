extends Area3D

var is_player_inside: bool = false
var player_body: Node3D = null

func _ready() -> void:
	get_node("/root/main/CanvasLayer/PreesToBuy").visible = false

func _process(delta: float) -> void:
	if is_player_inside and Input.is_action_just_pressed("interact"):
		if Global.Coins >= 5:
			Global.Coins -= 5
			
			if is_instance_valid(player_body) and player_body.has_method("update_label"):
				player_body.update_label(Global.Coins)
				
			var weapon = get_node_or_null("/root/main/Player/head/Camera3D/WeaponHandler/pistol")
			if weapon and weapon.has_method("add_magazine_to_reserve"):
				weapon.add_magazine_to_reserve(1)
		else:
			get_node("/root/main/CanvasLayer/Warning").play_effect()

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		is_player_inside = true
		player_body = body
		get_node("/root/main/CanvasLayer/PreesToBuy").visible = true

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		is_player_inside = false
		player_body = null
		get_node("/root/main/CanvasLayer/PreesToBuy").visible = false
