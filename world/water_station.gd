extends Area2D

signal interacted

var _player_nearby: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _unhandled_input(event: InputEvent) -> void:
	if _player_nearby and event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		interacted.emit()


func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		_player_nearby = true
		$Prompt.show()


func _on_body_exited(body: Node2D) -> void:
	if body is CharacterBody2D:
		_player_nearby = false
		$Prompt.hide()
