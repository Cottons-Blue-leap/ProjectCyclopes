extends CharacterBody2D

## 기본 적 — 심볼 인카운터 + 필드 전투 AI

enum EnemyState { IDLE, WANDER, CHASE, ATTACK_WINDUP, ATTACK, HIT, DEAD }

@export var move_speed: float = 160.0
@export var chase_speed: float = 220.0
@export var detect_range: float = 240.0
@export var attack_range: float = 72.0
@export var max_hearts: int = 3
@export var windup_duration: float = 1.0
@export var attack_damage: int = 1
@export var wander_interval: float = 2.0

var current_hearts: int
var state: EnemyState = EnemyState.IDLE
var player: CharacterBody2D = null
var wander_direction: Vector2 = Vector2.ZERO
var wander_timer: float = 0.0
var windup_timer: float = 0.0
var windup_progress: float = 0.0  # 0~1, 눈 게이지바용
var hit_flash_timer: float = 0.0
var is_hit: bool = false


func _ready() -> void:
	current_hearts = max_hearts
	add_to_group("enemy")
	$Hurtbox.add_to_group("hurtbox")
	wander_timer = randf_range(0.5, wander_interval)


func _physics_process(delta: float) -> void:
	if state == EnemyState.DEAD:
		return

	_find_player()
	_handle_hit_flash(delta)

	match state:
		EnemyState.IDLE:
			_state_idle(delta)
		EnemyState.WANDER:
			_state_wander(delta)
		EnemyState.CHASE:
			_state_chase()
		EnemyState.ATTACK_WINDUP:
			_state_attack_windup(delta)
		EnemyState.ATTACK:
			_state_attack()

	move_and_slide()
	queue_redraw()


## 플레이어 탐지
func _find_player() -> void:
	if player != null:
		return
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]


## 대기 상태 — 일정 시간 후 배회
func _state_idle(delta: float) -> void:
	velocity = Vector2.ZERO
	wander_timer -= delta
	if wander_timer <= 0:
		_pick_wander_direction()
		state = EnemyState.WANDER
		wander_timer = randf_range(1.0, wander_interval)

	# 플레이어 감지 시 추격
	if _player_in_range(detect_range) and not CombatManager.is_in_combat:
		state = EnemyState.CHASE
	elif _player_in_range(detect_range) and CombatManager.is_in_combat:
		# 이미 다른 전투 진행 중이면 대기 (구경꾼이 될 수 있음)
		pass


## 배회 상태
func _state_wander(delta: float) -> void:
	velocity = wander_direction * move_speed
	wander_timer -= delta
	if wander_timer <= 0:
		state = EnemyState.IDLE
		wander_timer = randf_range(0.5, wander_interval)

	if _player_in_range(detect_range) and not CombatManager.is_in_combat:
		state = EnemyState.CHASE


## 추격 상태
func _state_chase() -> void:
	if player == null:
		state = EnemyState.IDLE
		return

	# 전투 시작 트리거
	if not CombatManager.is_in_combat:
		CombatManager.start_combat(self)
	elif self not in CombatManager.active_enemies:
		CombatManager.start_combat(self)

	var dir := (player.global_position - global_position).normalized()
	velocity = dir * chase_speed

	if _player_in_range(attack_range):
		state = EnemyState.ATTACK_WINDUP
		windup_timer = windup_duration
		windup_progress = 0.0
		velocity = Vector2.ZERO

	if not _player_in_range(detect_range * 1.5):
		state = EnemyState.IDLE


## 공격 예비 — 눈 게이지바 충전
func _state_attack_windup(delta: float) -> void:
	velocity = Vector2.ZERO

	# 플레이어가 공격 범위 밖으로 벗어나면 추격으로 복귀
	if not _player_in_range(attack_range * 2.0):
		state = EnemyState.CHASE
		windup_progress = 0.0
		return

	windup_timer -= delta
	windup_progress = 1.0 - (windup_timer / windup_duration)

	if windup_timer <= 0:
		state = EnemyState.ATTACK


## 공격 실행
func _state_attack() -> void:
	if player != null and _player_in_range(attack_range * 1.3):
		if player.has_method("take_damage"):
			player.take_damage(attack_damage, self)
	state = EnemyState.CHASE
	windup_progress = 0.0


## 피격
func take_damage(amount: int = 1) -> void:
	current_hearts -= amount
	is_hit = true
	hit_flash_timer = 0.15
	if current_hearts <= 0:
		_die()


func _handle_hit_flash(delta: float) -> void:
	if is_hit:
		hit_flash_timer -= delta
		if hit_flash_timer <= 0:
			is_hit = false


func _die() -> void:
	state = EnemyState.DEAD
	CombatManager.on_enemy_defeated(self)
	# 사망 연출 후 제거
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(queue_free)


## 유틸
func _player_in_range(range: float) -> bool:
	if player == null:
		return false
	return global_position.distance_to(player.global_position) <= range


func _pick_wander_direction() -> void:
	var angle := randf() * TAU
	wander_direction = Vector2(cos(angle), sin(angle))


## 플레이스홀더 그리기 — 적 + 눈 게이지바
func _draw() -> void:
	if state == EnemyState.DEAD:
		return

	# 몸통 색상 (피격 시 흰색 플래시)
	var body_color := Color(1, 1, 1) if is_hit else Color(0.6, 0.25, 0.25)
	var body_rect := Rect2(-24, -24, 48, 48)
	draw_rect(body_rect, body_color)

	# 눈 2개 (쌍눈박이 적)
	draw_circle(Vector2(-8, -8), 6.0, Color.WHITE)
	draw_circle(Vector2(8, -8), 6.0, Color.WHITE)
	draw_circle(Vector2(-8, -8), 3.0, Color(0.1, 0.1, 0.1))
	draw_circle(Vector2(8, -8), 3.0, Color(0.1, 0.1, 0.1))

	# 눈 게이지바 (공격 예비 중)
	if state == EnemyState.ATTACK_WINDUP:
		_draw_eye_gauge()


## 눈 모양 게이지바 — 눈이 서서히 열리며 공격 예고
func _draw_eye_gauge() -> void:
	var gauge_y := -48.0
	var eye_width := 32.0
	var eye_height := 16.0
	var open_amount: float = windup_progress  # 0(감김) → 1(완전히 뜸)

	# 눈 테두리 (타원)
	var points := PackedVector2Array()
	for i in range(20):
		var angle := float(i) / 19.0 * TAU
		var x := cos(angle) * eye_width * 0.5
		var y := sin(angle) * eye_height * 0.5 * open_amount
		points.append(Vector2(x, gauge_y + y))

	if points.size() >= 3:
		# 배경 (어두운 눈)
		draw_colored_polygon(points, Color(0.15, 0.0, 0.0, 0.8))

	# 동공 (열림 정도에 비례)
	if open_amount > 0.3:
		var pupil_size := open_amount * 2.0
		draw_circle(Vector2(0, gauge_y), pupil_size * 4.0, Color(1, 0.1, 0.1))

	# 완전히 뜨면 번쩍! 효과
	if open_amount > 0.9:
		draw_circle(Vector2(0, gauge_y), 20.0, Color(1, 0.3, 0.1, 0.3))
