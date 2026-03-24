extends CharacterBody2D

## 외눈박이 NPC — 동족 (한쪽 눈)

@export var npc_name: String = "NPC"
@export var dialogue_file: String = ""
@export var interact_range: float = 80.0

var player: CharacterBody2D = null
var player_in_range: bool = false


func _ready() -> void:
	add_to_group("npc")
	queue_redraw()
	var area := Area2D.new()
	area.collision_layer = 0
	area.collision_mask = 1
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = interact_range
	shape.shape = circle
	area.add_child(shape)
	add_child(area)
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)


func _unhandled_input(event: InputEvent) -> void:
	if player_in_range and event.is_action_pressed("interact"):
		if GameManager.is_state(GameManager.GameState.EXPLORE):
			_start_dialogue()
			get_viewport().set_input_as_handled()


func _start_dialogue() -> void:
	if dialogue_file == "":
		return
	var data := DialogueManager.load_dialogue_file(dialogue_file)
	if data.is_empty():
		return
	var dialogue_box := get_tree().get_first_node_in_group("dialogue_box")
	if dialogue_box == null:
		return
	DialogueManager.start_dialogue(data)
	dialogue_box.start(data)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player = body
		player_in_range = true
		queue_redraw()


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = false
		queue_redraw()


## 플레이스홀더 그리기 — 외눈박이 NPC (동족)
func _draw() -> void:
	# 몸통 — 따뜻한 톤
	draw_rect(Rect2(-24, -24, 48, 48), Color(0.7, 0.55, 0.4))
	# 눈 하나 (중앙)
	draw_circle(Vector2(0, -8), 7.0, Color.WHITE)
	draw_circle(Vector2(0, -8), 3.5, Color(0.15, 0.15, 0.15))
	# 상호작용 가능 표시
	if player_in_range and GameManager.is_state(GameManager.GameState.EXPLORE):
		draw_circle(Vector2(0, -48), 8.0, Color(1, 1, 0.5, 0.8))
