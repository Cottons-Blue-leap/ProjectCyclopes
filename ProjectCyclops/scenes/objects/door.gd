extends Area2D

## 문/출구 — F키로 씬 전환 트리거

@export var target_scene: String = ""
@export var door_name: String = "출구"

var player_in_range: bool = false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	add_to_group("door")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _unhandled_input(event: InputEvent) -> void:
	if not player_in_range:
		return
	if not GameManager.is_state(GameManager.GameState.EXPLORE):
		return
	if event.is_action_pressed("interact"):
		if target_scene != "":
			SceneTransition.transition_to(target_scene)
			get_viewport().set_input_as_handled()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = true
		queue_redraw()


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = false
		queue_redraw()


func _draw() -> void:
	# 문 시각 표현 — 사각형 + 표시
	draw_rect(Rect2(-24, -32, 48, 64), Color(0.45, 0.3, 0.15))
	draw_rect(Rect2(-20, -28, 40, 56), Color(0.55, 0.4, 0.2))
	# 상호작용 가능 표시
	if player_in_range and GameManager.is_state(GameManager.GameState.EXPLORE):
		draw_circle(Vector2(0, -48), 8.0, Color(0.5, 1.0, 0.5, 0.8))
