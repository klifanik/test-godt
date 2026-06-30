extends Area3D

@export var speed: float = 30.0 # Скорость теперь задается здесь

func _physics_process(delta: float) -> void:
	# Двигаемся вперед по направлению, в которое повернута пуля
	position += -transform.basis.z * speed * delta

func _on_body_entered(body: Node3D) -> void:
	if body.has_method("hit"):
		body.hit()
	queue_free()
