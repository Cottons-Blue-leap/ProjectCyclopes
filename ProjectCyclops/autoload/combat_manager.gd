extends Node

## 전투 흐름 관리 — 인카운터 시작/종료, 구경꾼 장벽, 카메라

signal combat_started
signal combat_ended

var is_in_combat: bool = false
var combat_center: Vector2 = Vector2.ZERO
var active_enemies: Array = []
var bystanders: Array = []
var player: CharacterBody2D = null

@export var bystander_gather_speed: float = 100.0
@export var max_joinable_bystanders: int = 5

## 전투 영역 — 카메라 뷰포트 기반
const VIEWPORT_HALF_W: float = 640.0  # 1280 / 2
const VIEWPORT_HALF_H: float = 360.0  # 720 / 2
const ARENA_PADDING: float = 40.0     # 엔티티 클램프 여유
const BYSTANDER_GATHER_RADIUS: float = 800.0  # 구경꾼 수집 범위


func start_combat(enemy: CharacterBody2D) -> void:
	if is_in_combat:
		if enemy not in active_enemies:
			active_enemies.append(enemy)
		return

	is_in_combat = true
	active_enemies = [enemy]
	_find_player()

	if player == null:
		return

	# 전투 중심 = 플레이어와 적의 중간
	combat_center = (player.global_position + enemy.global_position) / 2.0

	# 카메라 고정
	if player.has_method("lock_camera"):
		player.lock_camera(combat_center)

	GameManager.change_state(GameManager.GameState.COMBAT)
	_gather_bystanders()
	combat_started.emit()


func end_combat() -> void:
	if not is_in_combat:
		return

	is_in_combat = false
	active_enemies.clear()

	if player != null and player.has_method("unlock_camera"):
		player.unlock_camera()

	_dismiss_bystanders()
	GameManager.change_state(GameManager.GameState.EXPLORE)
	combat_ended.emit()


## 적 사망 시 호출
func on_enemy_defeated(enemy: CharacterBody2D) -> void:
	active_enemies.erase(enemy)
	if active_enemies.is_empty():
		await get_tree().create_timer(0.5).timeout
		end_combat()


## 구경꾼 수집 — 범위 내 NPC를 구경꾼으로
func _gather_bystanders() -> void:
	bystanders.clear()
	var npcs := get_tree().get_nodes_in_group("npc")
	var enemies := get_tree().get_nodes_in_group("enemy")

	for npc in npcs:
		if npc in active_enemies:
			continue
		if combat_center.distance_to(npc.global_position) <= BYSTANDER_GATHER_RADIUS:
			bystanders.append(npc)

	for e in enemies:
		if e not in active_enemies and combat_center.distance_to(e.global_position) <= BYSTANDER_GATHER_RADIUS:
			bystanders.append(e)


func _dismiss_bystanders() -> void:
	bystanders.clear()


## 구경꾼 목표 위치 — 카메라 뷰포트 가장자리 사각형 배치
func get_bystander_position(index: int) -> Vector2:
	if bystanders.is_empty():
		return combat_center

	var total := bystanders.size()
	# 사각형 둘레를 따라 균등 배치
	var perimeter := (VIEWPORT_HALF_W + VIEWPORT_HALF_H) * 4.0
	var t := float(index) / float(total) * perimeter
	var hw := VIEWPORT_HALF_W
	var hh := VIEWPORT_HALF_H

	var offset := Vector2.ZERO
	if t < hw * 2.0:
		# 상단 변 (좌→우)
		offset = Vector2(-hw + t, -hh)
	elif t < hw * 2.0 + hh * 2.0:
		# 우측 변 (상→하)
		var seg := t - hw * 2.0
		offset = Vector2(hw, -hh + seg)
	elif t < hw * 4.0 + hh * 2.0:
		# 하단 변 (우→좌)
		var seg := t - hw * 2.0 - hh * 2.0
		offset = Vector2(hw - seg, hh)
	else:
		# 좌측 변 (하→상)
		var seg := t - hw * 4.0 - hh * 2.0
		offset = Vector2(-hw, hh - seg)

	return combat_center + offset


## NPC 참전 — 평판 기반
func check_bystander_join(npc: Node2D, faction: String) -> bool:
	var rep := ReputationManager.get_reputation(faction)
	if rep <= -5:
		return true
	return false


func _find_player() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]


## 전투 영역 경계 계산
func _get_arena_rect() -> Rect2:
	var min_pos := combat_center - Vector2(VIEWPORT_HALF_W - ARENA_PADDING, VIEWPORT_HALF_H - ARENA_PADDING)
	var size := Vector2((VIEWPORT_HALF_W - ARENA_PADDING) * 2.0, (VIEWPORT_HALF_H - ARENA_PADDING) * 2.0)
	return Rect2(min_pos, size)


## 엔티티 위치를 전투 영역 안으로 클램프
func _clamp_to_arena(entity: Node2D) -> void:
	var arena := _get_arena_rect()
	entity.global_position.x = clampf(entity.global_position.x, arena.position.x, arena.position.x + arena.size.x)
	entity.global_position.y = clampf(entity.global_position.y, arena.position.y, arena.position.y + arena.size.y)


func _process(_delta: float) -> void:
	if not is_in_combat:
		return

	# 구경꾼을 뷰포트 가장자리로 이동
	for i in range(bystanders.size()):
		var bystander: Node2D = bystanders[i]
		if not is_instance_valid(bystander):
			continue
		var target := get_bystander_position(i)
		var dir := (target - bystander.global_position)
		if dir.length() > 4.0:
			bystander.global_position += dir.normalized() * bystander_gather_speed * _delta

	# 전투 중 플레이어와 적을 카메라 영역 안으로 클램프
	if player != null and is_instance_valid(player):
		_clamp_to_arena(player)
	for enemy in active_enemies:
		if is_instance_valid(enemy):
			_clamp_to_arena(enemy)
