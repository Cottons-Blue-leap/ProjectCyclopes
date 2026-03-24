extends CanvasLayer

## 씬 전환 — 페이드 효과 (코드 기반 트윈)

@onready var color_rect: ColorRect = $ColorRect

var is_transitioning: bool = false
var fade_duration: float = 0.4


func _ready() -> void:
	color_rect.color = Color(0, 0, 0, 0)
	color_rect.visible = false


## 페이드 전환으로 씬 이동
func transition_to(scene_path: String) -> void:
	if is_transitioning:
		return
	is_transitioning = true
	GameManager.change_state(GameManager.GameState.TRANSITION)

	# 페이드 아웃
	color_rect.visible = true
	color_rect.color = Color(0, 0, 0, 0)
	var tween_out := create_tween()
	tween_out.tween_property(color_rect, "color:a", 1.0, fade_duration)
	await tween_out.finished

	# 씬 교체
	get_tree().change_scene_to_file(scene_path)

	# 페이드 인
	var tween_in := create_tween()
	tween_in.tween_property(color_rect, "color:a", 0.0, fade_duration)
	await tween_in.finished

	color_rect.visible = false
	is_transitioning = false
	GameManager.change_state(GameManager.GameState.EXPLORE)
