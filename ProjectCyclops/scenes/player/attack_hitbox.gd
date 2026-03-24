extends Area2D

## 공격 히트박스 — 마우스 방향으로 생성, 짧은 수명

@export var damage: int = 1
@export var lifetime: float = 0.15
@export var hitbox_range: float = 56.0

var direction: Vector2 = Vector2.RIGHT
var timer: float = 0.0
var hit_targets: Array = []


func _ready() -> void:
	timer = lifetime
	# 방향에 따라 위치 설정
	position = direction * hitbox_range
	# 히트박스 회전 (방향 기준)
	rotation = direction.angle()
	# 충돌 감지 연결 — Hurtbox(Area2D)만 사용, body 감지 비활성화
	area_entered.connect(_on_area_entered)


func _process(delta: float) -> void:
	timer -= delta
	if timer <= 0:
		queue_free()


func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("hurtbox") and area not in hit_targets:
		hit_targets.append(area)
		var target := area.get_parent()
		if target.has_method("take_damage"):
			target.take_damage(damage)


## 플레이스홀더 시각 표현
func _draw() -> void:
	# 반투명 빨간 부채꼴 느낌의 사각형
	var rect := Rect2(-12, -20, 40, 40)
	draw_rect(rect, Color(1, 0.2, 0.2, 0.5))
