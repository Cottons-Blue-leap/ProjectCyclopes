extends CharacterBody2D

## 플레이어 캐릭터 — 8방향 이동 + 마우스 기반 공격 방향

@export var move_speed: float = 320.0
@export var sprint_speed: float = 520.0
@export var sprint_cost: float = 20.0  ## 초당 스태미나 소모
@export var acceleration: float = 1600.0
@export var friction: float = 1200.0
@export var dodge_speed: float = 800.0
@export var dodge_duration: float = 0.3
@export var max_stamina: float = 100.0
@export var stamina_regen: float = 30.0
@export var dodge_cost: float = 30.0
@export var parry_cost: float = 25.0
@export var parry_window: float = 0.15
@export var max_hearts: int = 5
@export var attack_cooldown: float = 0.3
@export var attack_cost: float = 15.0

const ATTACK_HITBOX_SCENE := preload("res://scenes/player/attack_hitbox.tscn")

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var camera: Camera2D = $Camera2D

var current_hearts: int
var stamina: float
var facing_direction: Vector2 = Vector2.DOWN
var attack_direction: Vector2 = Vector2.RIGHT
var is_dodging: bool = false
var is_parrying: bool = false
var is_attacking: bool = false
var is_invincible: bool = false
var is_hit: bool = false
var dodge_timer: float = 0.0
var parry_timer: float = 0.0
var invincible_timer: float = 0.0
var hit_flash_timer: float = 0.0
var dodge_lockout_timer: float = 0.0

@export var invincible_duration: float = 0.5
@export var counter_attack_damage: int = 3
@export var counter_attack_range: float = 120.0

## 전투 시 카메라 고정용
var camera_locked: bool = false
var camera_lock_position: Vector2 = Vector2.ZERO


func _ready() -> void:
	current_hearts = max_hearts
	stamina = max_stamina
	add_to_group("player")
	queue_redraw()
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)


func _on_dialogue_ended() -> void:
	dodge_lockout_timer = 1.5


## 플레이스홀더 스프라이트 — 외눈박이 캐릭터 간이 표현
func _draw() -> void:
	# 피격 시 깜빡임 (무적 중 반투명)
	if is_invincible and not is_dodging:
		if int(Time.get_ticks_msec() / 80) % 2 == 0:
			return  # 깜빡임: 프레임 건너뛰기

	# 몸통 색상 (피격 플래시)
	var body_color := Color(1, 1, 1) if is_hit else Color(0.85, 0.75, 0.55)
	# 구르기 중 반투명
	if is_dodging:
		body_color.a = 0.4

	var body_rect := Rect2(-24, -24, 48, 48)
	draw_rect(body_rect, body_color)

	# 패링 자세 표시
	if is_parrying:
		draw_rect(Rect2(-32, -32, 64, 64), Color(0.3, 0.6, 1.0, 0.4))

	# 눈 (하나!) — 바라보는 방향 쪽에 배치
	var eye_offset := facing_direction * 8.0
	draw_circle(Vector2(eye_offset.x, -4 + eye_offset.y), 8.0, Color.WHITE)
	draw_circle(Vector2(eye_offset.x, -4 + eye_offset.y), 4.0, Color(0.15, 0.15, 0.15))

	# 공격 방향 표시 (에임 점)
	var aim := attack_direction * 40.0
	draw_circle(aim, 6.0, Color(1, 0.3, 0.3, 0.5))

	# 하트 UI (머리 위)
	_draw_hearts()
	# 스태미나 바 (하트 아래)
	_draw_stamina_bar()


## 하트 UI
func _draw_hearts() -> void:
	var start_x := -float(max_hearts) * 12.0
	for i in range(max_hearts):
		var x := start_x + i * 24.0
		var color := Color(1, 0.2, 0.2) if i < current_hearts else Color(0.3, 0.3, 0.3, 0.5)
		draw_circle(Vector2(x + 12.0, -48.0), 8.0, color)


## 스태미나 바
func _draw_stamina_bar() -> void:
	var bar_width := 80.0
	var bar_height := 6.0
	var bar_x := -bar_width / 2.0
	var bar_y := -34.0
	# 배경
	draw_rect(Rect2(bar_x, bar_y, bar_width, bar_height), Color(0.2, 0.2, 0.2, 0.6))
	# 현재 스태미나
	var fill := bar_width * (stamina / max_stamina)
	draw_rect(Rect2(bar_x, bar_y, fill, bar_height), Color(0.3, 0.8, 0.3, 0.8))


func _physics_process(delta: float) -> void:
	if not GameManager.is_state(GameManager.GameState.EXPLORE) and not GameManager.is_state(GameManager.GameState.COMBAT):
		velocity = Vector2.ZERO
		return

	_update_stamina(delta)
	_update_attack_direction()
	_handle_invincibility(delta)
	_handle_hit_flash(delta)
	_handle_dodge(delta)
	_handle_parry(delta)

	if not is_dodging:
		_handle_movement()

	move_and_slide()
	_update_camera()
	queue_redraw()


## 이동 처리 (8방향, 가감속 보간, Shift 달리기)
func _handle_movement() -> void:
	var input_dir := Vector2.ZERO
	if Input.is_action_pressed("move_up"):
		input_dir.y -= 1
	if Input.is_action_pressed("move_down"):
		input_dir.y += 1
	if Input.is_action_pressed("move_left"):
		input_dir.x -= 1
	if Input.is_action_pressed("move_right"):
		input_dir.x += 1

	var delta := get_physics_process_delta_time()
	var is_sprinting := Input.is_action_pressed("sprint") and stamina > 0 and input_dir != Vector2.ZERO
	var current_speed := sprint_speed if is_sprinting else move_speed

	if is_sprinting:
		stamina -= sprint_cost * delta

	if input_dir != Vector2.ZERO:
		input_dir = input_dir.normalized()
		facing_direction = input_dir
		velocity = velocity.move_toward(input_dir * current_speed, acceleration * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)


## 마우스 커서 기준 공격 방향 계산
func _update_attack_direction() -> void:
	var mouse_pos := get_global_mouse_position()
	attack_direction = (mouse_pos - global_position).normalized()


## 구르기 (회피)
func _handle_dodge(delta: float) -> void:
	if is_dodging:
		dodge_timer -= delta
		if dodge_timer <= 0:
			is_dodging = false
			# 피격 무적이 별도로 걸려있지 않으면 무적 해제
			if invincible_timer <= 0:
				is_invincible = false
		else:
			velocity = facing_direction * dodge_speed
		return

	if dodge_lockout_timer > 0:
		dodge_lockout_timer -= delta
		return

	if Input.is_action_just_pressed("dodge") and stamina >= dodge_cost and not is_attacking:
		is_dodging = true
		is_invincible = true
		dodge_timer = dodge_duration
		stamina -= dodge_cost


## 패링 (막기)
func _handle_parry(delta: float) -> void:
	if is_parrying:
		parry_timer -= delta
		if parry_timer <= 0:
			is_parrying = false
		return

	if Input.is_action_just_pressed("parry") and stamina >= parry_cost and not is_dodging:
		is_parrying = true
		parry_timer = parry_window
		stamina -= parry_cost


## 공격
func _unhandled_input(event: InputEvent) -> void:
	if not GameManager.is_state(GameManager.GameState.COMBAT) and not GameManager.is_state(GameManager.GameState.EXPLORE):
		return

	if event.is_action_pressed("attack") and not is_dodging and not is_attacking and stamina >= attack_cost:
		_perform_attack()


func _perform_attack() -> void:
	is_attacking = true
	stamina -= attack_cost
	# 히트박스 생성 — 마우스 방향으로
	var hitbox := ATTACK_HITBOX_SCENE.instantiate()
	hitbox.direction = attack_direction
	add_child(hitbox)
	await get_tree().create_timer(attack_cooldown).timeout
	is_attacking = false


## 스태미나 자연 회복 (달리기 중 회복 안 함)
func _update_stamina(delta: float) -> void:
	var is_sprinting := Input.is_action_pressed("sprint") and velocity.length() > move_speed * 0.5
	if not is_dodging and not is_parrying and not is_sprinting:
		stamina = min(stamina + stamina_regen * delta, max_stamina)


## 무적 시간 처리
func _handle_invincibility(delta: float) -> void:
	if is_invincible and not is_dodging:
		invincible_timer -= delta
		if invincible_timer <= 0:
			is_invincible = false


## 피격 플래시 처리
func _handle_hit_flash(delta: float) -> void:
	if is_hit:
		hit_flash_timer -= delta
		if hit_flash_timer <= 0:
			is_hit = false


## 피격 — 저스트 패링 시 반격기 즉발
func take_damage(amount: int = 1, attacker: Node2D = null) -> void:
	# 구르기 중 → 무적 (반격 없음, 안전하게 회피만)
	if is_dodging:
		return

	# 저스트 패링 → 반격기
	if is_parrying:
		_counter_attack(attacker)
		return

	# 무적 중이면 무시
	if is_invincible:
		return

	# 실제 피격
	current_hearts -= amount
	is_hit = true
	hit_flash_timer = 0.3
	is_invincible = true
	invincible_timer = invincible_duration

	if current_hearts <= 0:
		current_hearts = 0
		_die()


## 반격기 — 주변 적에게 강화 데미지
func _counter_attack(attacker: Node2D = null) -> void:
	# 반격 시각 효과용 플래그
	_spawn_counter_effect()
	if attacker != null and attacker.has_method("take_damage"):
		attacker.take_damage(counter_attack_damage)
	else:
		# attacker가 없으면 범위 내 적 전부에게
		var enemies := get_tree().get_nodes_in_group("enemy")
		for enemy in enemies:
			if global_position.distance_to(enemy.global_position) <= counter_attack_range:
				if enemy.has_method("take_damage"):
					enemy.take_damage(counter_attack_damage)


func _spawn_counter_effect() -> void:
	# 반격 시각 효과 (원형 파동)
	var effect := Node2D.new()
	effect.set_script(load("res://scenes/combat/counter_effect.gd"))
	add_child(effect)


func _die() -> void:
	# 사망 처리 — 프로토타입에서는 리스폰
	current_hearts = max_hearts
	global_position = Vector2(640, 360)


## 카메라 — 전투 시 offset으로 고정, 탐색 시 자동 추적
## Camera2D는 플레이어 자식 + process_callback=PHYSICS → position 건드리지 않음
## offset만 조정하여 전투 시 카메라 중심 이동
func _update_camera() -> void:
	if camera_locked:
		camera.offset = camera_lock_position - global_position
	else:
		camera.offset = Vector2.ZERO


func lock_camera(pos: Vector2) -> void:
	camera_locked = true
	camera_lock_position = pos


func unlock_camera() -> void:
	camera_locked = false
