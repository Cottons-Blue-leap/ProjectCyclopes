extends Node2D

## 마을 맵 장식 — 중세 유럽 마을 분위기 (탑뷰)

func _ready() -> void:
	z_index = -1
	queue_redraw()


func _draw() -> void:
	# === 도로 ===
	# 메인 도로 (남북)
	_draw_road(Vector2(2560, 0), Vector2(2560, 2880), 120)
	# 메인 도로 (동서)
	_draw_road(Vector2(0, 1440), Vector2(5120, 1440), 100)
	# 보조 도로
	_draw_road(Vector2(800, 0), Vector2(800, 2880), 60)
	_draw_road(Vector2(4200, 0), Vector2(4200, 2880), 60)
	_draw_road(Vector2(0, 600), Vector2(5120, 600), 50)
	_draw_road(Vector2(0, 2200), Vector2(5120, 2200), 50)

	# === 건물 (집) ===
	# 좌상단 구역
	_draw_house(Vector2(200, 100), Vector2(180, 140), Color(0.45, 0.32, 0.2))
	_draw_house(Vector2(400, 250), Vector2(140, 120), Color(0.5, 0.35, 0.22))
	_draw_house(Vector2(150, 350), Vector2(160, 100), Color(0.42, 0.3, 0.18))

	# 우상단 구역
	_draw_house(Vector2(3200, 100), Vector2(200, 160), Color(0.48, 0.33, 0.2))
	_draw_house(Vector2(3600, 200), Vector2(160, 130), Color(0.44, 0.31, 0.19))
	_draw_house(Vector2(4500, 80), Vector2(180, 150), Color(0.5, 0.36, 0.24))

	# 중앙 좌측
	_draw_house(Vector2(100, 800), Vector2(220, 180), Color(0.46, 0.32, 0.2))
	_draw_house(Vector2(100, 1100), Vector2(200, 160), Color(0.43, 0.3, 0.18))

	# 중앙 우측
	_draw_house(Vector2(4400, 900), Vector2(200, 200), Color(0.5, 0.35, 0.22))
	_draw_house(Vector2(4600, 1200), Vector2(180, 160), Color(0.44, 0.32, 0.2))

	# 하단
	_draw_house(Vector2(300, 2400), Vector2(160, 140), Color(0.47, 0.33, 0.21))
	_draw_house(Vector2(600, 2500), Vector2(140, 120), Color(0.42, 0.3, 0.18))
	_draw_house(Vector2(3800, 2300), Vector2(200, 180), Color(0.48, 0.34, 0.22))
	_draw_house(Vector2(4300, 2500), Vector2(160, 140), Color(0.45, 0.32, 0.2))

	# === 광장 (중앙 교차로) ===
	draw_rect(Rect2(2460, 1340, 200, 200), Color(0.35, 0.3, 0.22))  # 바닥
	# 우물
	draw_circle(Vector2(2560, 1440), 30, Color(0.3, 0.28, 0.2))
	draw_circle(Vector2(2560, 1440), 22, Color(0.2, 0.35, 0.45))
	draw_circle(Vector2(2560, 1440), 16, Color(0.15, 0.25, 0.35))

	# === 나무 ===
	var tree_positions := [
		Vector2(1400, 300), Vector2(1600, 500), Vector2(1100, 700),
		Vector2(3000, 500), Vector2(3400, 800), Vector2(2800, 1000),
		Vector2(1200, 1600), Vector2(1500, 1900), Vector2(1800, 1700),
		Vector2(3500, 1700), Vector2(3800, 1500), Vector2(4000, 1800),
		Vector2(1000, 2600), Vector2(1400, 2700), Vector2(2000, 2500),
		Vector2(3200, 2600), Vector2(3600, 2700), Vector2(4600, 1800),
	]
	for pos in tree_positions:
		_draw_tree(pos)

	# === 울타리 ===
	# 메인 도로 양쪽
	_draw_fence(Vector2(2490, 200), Vector2(2490, 1300))
	_draw_fence(Vector2(2630, 200), Vector2(2630, 1300))
	_draw_fence(Vector2(2490, 1580), Vector2(2490, 2700))
	_draw_fence(Vector2(2630, 1580), Vector2(2630, 2700))


func _draw_road(from: Vector2, to: Vector2, width: float) -> void:
	var road_color := Color(0.28, 0.25, 0.18)
	var edge_color := Color(0.22, 0.2, 0.14)
	# 가장자리
	draw_line(from, to, edge_color, width + 8)
	# 도로 본체
	draw_line(from, to, road_color, width)


func _draw_house(pos: Vector2, house_size: Vector2, wall_color: Color) -> void:
	var roof_color := Color(wall_color.r * 0.6, wall_color.g * 0.5, wall_color.b * 0.4)
	# 그림자
	draw_rect(Rect2(pos + Vector2(6, 6), house_size), Color(0, 0, 0, 0.15))
	# 벽
	draw_rect(Rect2(pos, house_size), wall_color)
	# 지붕 (상단 약간 어두운 줄)
	draw_rect(Rect2(pos.x - 4, pos.y - 4, house_size.x + 8, 16), roof_color)
	# 문 (하단 중앙)
	var door_x := pos.x + house_size.x / 2 - 8
	draw_rect(Rect2(door_x, pos.y + house_size.y - 20, 16, 20), Color(0.3, 0.2, 0.1))


func _draw_tree(pos: Vector2) -> void:
	# 그림자
	draw_circle(pos + Vector2(4, 6), 20, Color(0, 0, 0, 0.1))
	# 나무 그림자 (진한 초록)
	draw_circle(pos, 22, Color(0.12, 0.2, 0.08))
	# 수관
	draw_circle(pos, 18, Color(0.2, 0.35, 0.15))
	draw_circle(pos + Vector2(-5, -3), 12, Color(0.25, 0.4, 0.18))
	draw_circle(pos + Vector2(6, -2), 10, Color(0.22, 0.38, 0.16))
	# 줄기
	draw_circle(pos, 4, Color(0.35, 0.25, 0.15))


func _draw_fence(from: Vector2, to: Vector2) -> void:
	draw_line(from, to, Color(0.4, 0.3, 0.18), 3.0)
	# 기둥
	var dir := (to - from).normalized()
	var dist := from.distance_to(to)
	var spacing := 40.0
	var count := int(dist / spacing)
	for i in range(count + 1):
		var pos := from + dir * (i * spacing)
		draw_rect(Rect2(pos.x - 2, pos.y - 2, 4, 4), Color(0.35, 0.25, 0.15))
