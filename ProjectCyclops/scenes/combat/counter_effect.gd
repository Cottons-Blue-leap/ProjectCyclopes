extends Node2D

## 반격 시각 효과 — 원형 파동

var timer: float = 0.25
var max_radius: float = 80.0


func _process(delta: float) -> void:
	timer -= delta
	if timer <= 0:
		queue_free()
	queue_redraw()


func _draw() -> void:
	var progress := 1.0 - (timer / 0.25)
	var radius := max_radius * progress
	var alpha := 1.0 - progress
	draw_arc(Vector2.ZERO, radius, 0, TAU, 24, Color(1, 0.9, 0.3, alpha), 2.0)
