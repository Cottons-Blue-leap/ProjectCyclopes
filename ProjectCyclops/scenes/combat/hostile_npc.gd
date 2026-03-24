extends CharacterBody2D

## 차별주의자 NPC — 대화 먼저, 적대 선택지 시 전투 전환

enum State { IDLE, WANDER, TALK_RANGE, IN_DIALOGUE, COMBAT_CHASE, COMBAT_WINDUP, COMBAT_ATTACK, HIT, DEAD }

@export var npc_name: String = "차별주의자"
@export var dialogue_file: String = ""
@export var move_speed: float = 160.0
@export var chase_speed: float = 220.0
@export var detect_range: float = 240.0
@export var talk_range: float = 80.0
@export var attack_range: float = 72.0
@export var max_hearts: int = 3
@export var windup_duration: float = 1.0
@export var attack_damage: int = 1
@export var wander_interval: float = 2.0
@export var faction: String = "twoeye"
@export var aggro_flag: String = ""  ## 이 플래그가 true면 적대화 (대화 선택지에서 설정)

var current_hearts: int
var state: State = State.IDLE
var player: CharacterBody2D = null
var player_in_range: bool = false
var wander_direction: Vector2 = Vector2.ZERO
var wander_timer: float = 0.0
var windup_timer: float = 0.0
var windup_progress: float = 0.0
var hit_flash_timer: float = 0.0
var is_hit: bool = false
var has_talked: bool = false
var became_hostile: bool = false
var facing_direction: Vector2 = Vector2.DOWN


func _ready() -> void:
	current_hearts = max_hearts
	add_to_group("enemy")
	add_to_group("npc")
	wander_timer = randf_range(0.5, wander_interval)
	queue_redraw()

	# 상호작용 영역
	var area := Area2D.new()
	area.collision_layer = 0
	area.collision_mask = 1
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = talk_range
	shape.shape = circle
	area.add_child(shape)
	add_child(area)
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)

	# Hurtbox
	var hurtbox := Area2D.new()
	hurtbox.collision_layer = 4
	hurtbox.collision_mask = 2
	hurtbox.add_to_group("hurtbox")
	var hurtbox_shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(48, 48)
	hurtbox_shape.shape = rect
	hurtbox.add_child(hurtbox_shape)
	add_child(hurtbox)

	# 대화 종료 시 결과 확인
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)


func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return

	_find_player()
	_handle_hit_flash(delta)

	match state:
		State.IDLE:
			_state_idle(delta)
		State.WANDER:
			_state_wander(delta)
		State.TALK_RANGE:
			velocity = Vector2.ZERO
			if player != null:
				facing_direction = (player.global_position - global_position).normalized()
		State.IN_DIALOGUE:
			velocity = Vector2.ZERO
		State.COMBAT_CHASE:
			_state_combat_chase()
		State.COMBAT_WINDUP:
			_state_combat_windup(delta)
		State.COMBAT_ATTACK:
			_state_combat_attack()

	move_and_slide()
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if not player_in_range:
		return
	if state != State.TALK_RANGE:
		return
	if not GameManager.is_state(GameManager.GameState.EXPLORE):
		return
	if event.is_action_pressed("interact"):
		_start_dialogue()
		get_viewport().set_input_as_handled()


func _start_dialogue() -> void:
	if dialogue_file == "":
		return
	var data := DialogueManager.load_dialogue_file(dialogue_file)
	if data.is_empty():
		return
	state = State.IN_DIALOGUE
	var dialogue_box := get_tree().get_first_node_in_group("dialogue_box")
	if dialogue_box:
		DialogueManager.start_dialogue(data)
		dialogue_box.start(data)


func _on_dialogue_ended() -> void:
	if state != State.IN_DIALOGUE:
		return
	has_talked = true

	# aggro_flag 체크 — 대화 선택지에서 설정된 플래그 확인
	if not became_hostile and aggro_flag != "":
		if EventFlags.get_flag(aggro_flag) == true:
			became_hostile = true

	# 적대 플래그 확인
	if became_hostile:
		state = State.COMBAT_CHASE
		CombatManager.start_combat(self)
	else:
		state = State.TALK_RANGE if player_in_range else State.IDLE


## 외부에서 호출 — 대화 선택지의 flags에서 트리거
func trigger_hostile() -> void:
	became_hostile = true


## 대기
func _state_idle(delta: float) -> void:
	velocity = Vector2.ZERO
	wander_timer -= delta
	if wander_timer <= 0:
		_pick_wander_direction()
		state = State.WANDER
		wander_timer = randf_range(1.0, wander_interval)

	if player_in_range and not became_hostile:
		state = State.TALK_RANGE

	if became_hostile and _player_in_range(detect_range):
		state = State.COMBAT_CHASE
		CombatManager.start_combat(self)


## 배회
func _state_wander(delta: float) -> void:
	velocity = wander_direction * move_speed
	facing_direction = wander_direction
	wander_timer -= delta
	if wander_timer <= 0:
		state = State.IDLE
		wander_timer = randf_range(0.5, wander_interval)

	if player_in_range and not became_hostile:
		state = State.TALK_RANGE

	if became_hostile and _player_in_range(detect_range):
		state = State.COMBAT_CHASE
		CombatManager.start_combat(self)


## 전투 추격
func _state_combat_chase() -> void:
	if player == null:
		state = State.IDLE
		return

	var dir := (player.global_position - global_position).normalized()
	velocity = dir * chase_speed
	facing_direction = dir

	if _player_in_range(attack_range):
		state = State.COMBAT_WINDUP
		windup_timer = windup_duration
		windup_progress = 0.0
		velocity = Vector2.ZERO

	if not _player_in_range(detect_range * 1.5):
		state = State.IDLE


## 공격 예비
func _state_combat_windup(delta: float) -> void:
	velocity = Vector2.ZERO
	if not _player_in_range(attack_range * 2.0):
		state = State.COMBAT_CHASE
		windup_progress = 0.0
		return
	windup_timer -= delta
	windup_progress = 1.0 - (windup_timer / windup_duration)
	if windup_timer <= 0:
		state = State.COMBAT_ATTACK


## 공격
func _state_combat_attack() -> void:
	if player != null and _player_in_range(attack_range * 1.3):
		if player.has_method("take_damage"):
			player.take_damage(attack_damage, self)
	state = State.COMBAT_CHASE
	windup_progress = 0.0


## 피격
func take_damage(amount: int = 1) -> void:
	current_hearts -= amount
	is_hit = true
	hit_flash_timer = 0.15
	# 피격 = 즉시 적대
	if not became_hostile:
		became_hostile = true
		state = State.COMBAT_CHASE
		CombatManager.start_combat(self)
	if current_hearts <= 0:
		_die()


func _handle_hit_flash(delta: float) -> void:
	if is_hit:
		hit_flash_timer -= delta
		if hit_flash_timer <= 0:
			is_hit = false


func _die() -> void:
	state = State.DEAD
	CombatManager.on_enemy_defeated(self)
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(queue_free)


## 유틸
func _find_player() -> void:
	if player != null:
		return
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]


func _player_in_range(dist: float) -> bool:
	if player == null:
		return false
	return global_position.distance_to(player.global_position) <= dist


func _pick_wander_direction() -> void:
	var angle := randf() * TAU
	wander_direction = Vector2(cos(angle), sin(angle))


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player = body
		player_in_range = true
		if not became_hostile and (state == State.IDLE or state == State.WANDER):
			state = State.TALK_RANGE
		queue_redraw()


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = false
		if state == State.TALK_RANGE:
			state = State.IDLE
		queue_redraw()


## 플레이스홀더 그리기
func _draw() -> void:
	if state == State.DEAD:
		return

	var body_color := Color(1, 1, 1) if is_hit else Color(0.6, 0.25, 0.25)
	if not became_hostile:
		body_color = Color(1, 1, 1) if is_hit else Color(0.55, 0.35, 0.35)

	draw_rect(Rect2(-24, -24, 48, 48), body_color)

	# 눈 2개 — 바라보는 방향에 따라 오프셋
	var eye_off := facing_direction * 4.0
	draw_circle(Vector2(-8 + eye_off.x, -8 + eye_off.y), 6.0, Color.WHITE)
	draw_circle(Vector2(8 + eye_off.x, -8 + eye_off.y), 6.0, Color.WHITE)
	draw_circle(Vector2(-8 + eye_off.x, -8 + eye_off.y), 3.0, Color(0.1, 0.1, 0.1))
	draw_circle(Vector2(8 + eye_off.x, -8 + eye_off.y), 3.0, Color(0.1, 0.1, 0.1))

	# 대화 가능 표시
	if player_in_range and not became_hostile and GameManager.is_state(GameManager.GameState.EXPLORE):
		draw_circle(Vector2(0, -48), 8.0, Color(1, 0.5, 0.3, 0.8))

	# 눈 게이지바
	if state == State.COMBAT_WINDUP:
		_draw_eye_gauge()


func _draw_eye_gauge() -> void:
	var gauge_y := -48.0
	var eye_width := 32.0
	var eye_height := 16.0
	var open_amount: float = windup_progress

	var points := PackedVector2Array()
	for i in range(20):
		var angle := float(i) / 19.0 * TAU
		var x := cos(angle) * eye_width * 0.5
		var y := sin(angle) * eye_height * 0.5 * open_amount
		points.append(Vector2(x, gauge_y + y))

	if points.size() >= 3:
		draw_colored_polygon(points, Color(0.15, 0.0, 0.0, 0.8))

	if open_amount > 0.3:
		draw_circle(Vector2(0, gauge_y), open_amount * 8.0, Color(1, 0.1, 0.1))

	if open_amount > 0.9:
		draw_circle(Vector2(0, gauge_y), 20.0, Color(1, 0.3, 0.1, 0.3))
