extends CanvasLayer

## 미니맵 — 우상단, NPC/적/문/플레이어 표시

@onready var minimap_control: Control = $MinimapControl


class MinimapDraw extends Control:
	const MINIMAP_W: float = 200.0
	const MINIMAP_H: float = 112.0
	const MARGIN: float = 12.0
	var map_size: Vector2 = Vector2(5120, 2880)

	func _ready() -> void:
		# 우상단 배치
		var vp_size := get_viewport_rect().size
		position = Vector2(vp_size.x - MINIMAP_W - MARGIN, MARGIN)
		size = Vector2(MINIMAP_W, MINIMAP_H)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _process(_delta: float) -> void:
		queue_redraw()

	func _draw() -> void:
		# 배경
		draw_rect(Rect2(Vector2.ZERO, Vector2(MINIMAP_W, MINIMAP_H)), Color(0.05, 0.05, 0.05, 0.7))
		draw_rect(Rect2(Vector2.ZERO, Vector2(MINIMAP_W, MINIMAP_H)), Color(0.4, 0.4, 0.4, 0.6), false, 1.0)

		# 맵 사이즈 자동 감지
		var bg := get_tree().get_first_node_in_group("map_background")
		if bg and bg.has_method("get_map_size"):
			map_size = bg.get_map_size()

		# 플레이어
		var player := get_tree().get_first_node_in_group("player")
		if player:
			_draw_dot(player.global_position, Color(0.3, 0.9, 1.0), 4.0)
			# 카메라 시야 표시
			_draw_camera_rect(player)

		# 문
		for door in get_tree().get_nodes_in_group("door"):
			_draw_dot(door.global_position, Color(1.0, 0.85, 0.2), 3.0)

		# NPC (적이 아닌)
		for npc in get_tree().get_nodes_in_group("npc"):
			if npc.is_in_group("enemy"):
				continue  # 적대 NPC는 enemy 색으로 표시
			_draw_dot(npc.global_position, Color(0.3, 0.9, 0.3), 2.5)

		# 적
		for enemy in get_tree().get_nodes_in_group("enemy"):
			_draw_dot(enemy.global_position, Color(0.9, 0.2, 0.2), 2.5)

	func _world_to_minimap(world_pos: Vector2) -> Vector2:
		return Vector2(
			clampf(world_pos.x / map_size.x * MINIMAP_W, 0, MINIMAP_W),
			clampf(world_pos.y / map_size.y * MINIMAP_H, 0, MINIMAP_H)
		)

	func _draw_dot(world_pos: Vector2, color: Color, radius: float) -> void:
		var pos := _world_to_minimap(world_pos)
		draw_circle(pos, radius, color)

	func _draw_camera_rect(player: Node2D) -> void:
		var cam_pos := player.global_position
		var half := Vector2(640, 360)  # viewport half
		var tl := _world_to_minimap(cam_pos - half)
		var br := _world_to_minimap(cam_pos + half)
		var rect := Rect2(tl, br - tl)
		draw_rect(rect, Color(1, 1, 1, 0.2), false, 1.0)


func _ready() -> void:
	var control := MinimapDraw.new()
	control.name = "MinimapControl"
	add_child(control)
