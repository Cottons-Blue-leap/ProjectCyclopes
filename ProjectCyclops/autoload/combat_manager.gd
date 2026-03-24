extends Node

## 전투 흐름 관리 — 인카운터 시작/종료, 구경꾼, 카메라

signal combat_started
signal combat_ended

var is_in_combat: bool = false
var combat_center: Vector2 = Vector2.ZERO
var active_enemies: Array = []
var bystanders: Array = []
var player: CharacterBody2D = null

@export var bystander_gather_speed: float = 100.0
@export var bystander_circle_radius: float = 200.0
@export var max_joinable_bystanders: int = 5


func start_combat(enemy: CharacterBody2D) -> void:
	if is_in_combat:
		# 이미 전투 중이면 적 추가만
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

	# 게임 상태 전환
	GameManager.change_state(GameManager.GameState.COMBAT)

	# 구경꾼 수집
	_gather_bystanders()

	combat_started.emit()


func end_combat() -> void:
	if not is_in_combat:
		return

	is_in_combat = false
	active_enemies.clear()

	# 카메라 해제
	if player != null and player.has_method("unlock_camera"):
		player.unlock_camera()

	# 구경꾼 해산
	_dismiss_bystanders()

	# 게임 상태 복원
	GameManager.change_state(GameManager.GameState.EXPLORE)

	combat_ended.emit()


## 적 사망 시 호출
func on_enemy_defeated(enemy: CharacterBody2D) -> void:
	active_enemies.erase(enemy)
	if active_enemies.is_empty():
		# 짧은 딜레이 후 전투 종료 (연출용)
		await get_tree().create_timer(0.5).timeout
		end_combat()


## 구경꾼 수집 — 범위 내 NPC를 구경꾼으로
func _gather_bystanders() -> void:
	bystanders.clear()
	var npcs := get_tree().get_nodes_in_group("npc")
	var enemies := get_tree().get_nodes_in_group("enemy")

	# NPC 구경꾼 (전투 참여 중인 적은 제외)
	for npc in npcs:
		if npc in active_enemies:
			continue
		if combat_center.distance_to(npc.global_position) <= bystander_circle_radius * 2.0:
			bystanders.append(npc)

	# 적 중 현재 전투에 참여하지 않은 적도 구경꾼 후보
	for e in enemies:
		if e not in active_enemies and combat_center.distance_to(e.global_position) <= bystander_circle_radius * 2.0:
			bystanders.append(e)


## 구경꾼 해산
func _dismiss_bystanders() -> void:
	bystanders.clear()


## 구경꾼 목표 위치 계산 (원형 배치)
func get_bystander_position(index: int) -> Vector2:
	if bystanders.is_empty():
		return combat_center
	var angle := (float(index) / float(bystanders.size())) * TAU
	return combat_center + Vector2(cos(angle), sin(angle)) * bystander_circle_radius


## NPC 참전 — 평판 기반
func check_bystander_join(npc: Node2D, faction: String) -> bool:
	var rep := ReputationManager.get_reputation(faction)
	# 적대 평판 → 적으로 참전 가능
	if rep <= -5:
		return true
	return false


func _find_player() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]


func _process(_delta: float) -> void:
	if not is_in_combat:
		return

	# 구경꾼을 원형 위치로 이동
	for i in range(bystanders.size()):
		var bystander: Node2D = bystanders[i]
		if not is_instance_valid(bystander):
			continue
		var target := get_bystander_position(i)
		var dir := (target - bystander.global_position)
		if dir.length() > 4.0:
			bystander.global_position += dir.normalized() * bystander_gather_speed * _delta
