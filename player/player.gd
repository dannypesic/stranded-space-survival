extends CharacterBody2D

@export var speed: float = 220.0
var movement_enabled: bool = true


func _physics_process(_delta: float) -> void:
	if not movement_enabled:
		velocity = Vector2.ZERO
		return
	var direction: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * speed
	move_and_slide()
	if direction.x != 0.0:
		$Visuals.scale.x = signf(direction.x)
