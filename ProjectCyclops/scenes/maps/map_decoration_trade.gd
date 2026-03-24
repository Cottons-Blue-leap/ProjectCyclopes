extends Node2D

## 교역도시 맵 장식 — 중세 유럽 교역도시 분위기 (탑뷰)

func _ready() -> void:
	z_index = -1
	queue_redraw()


func _draw() -> void:
	# === 성벽 (외곽) ===
	_draw_city_wall()

	# === 대로 ===
	# 메인 대로 (남북 — 정문에서 중앙 광장)
	_draw_paved_road(Vector2(2560, 200), Vector2(2560, 2880), 140)
	# 동서 대로
	_draw_paved_road(Vector2(200, 1200), Vector2(4920, 1200), 120)
	# 보조 도로
	_draw_paved_road(Vector2(1200, 200), Vector2(1200, 2700), 70)
	_draw_paved_road(Vector2(3800, 200), Vector2(3800, 2700), 70)
	_draw_paved_road(Vector2(200, 600), Vector2(4920, 600), 60)
	_draw_paved_road(Vector2(200, 2000), Vector2(4920, 2000), 60)

	# === 중앙 광장 / 시장 ===
	# 광장 바닥
	draw_rect(Rect2(2200, 900, 720, 600), Color(0.32, 0.28, 0.22))
	draw_rect(Rect2(2220, 920, 680, 560), Color(0.35, 0.31, 0.25))
	# 바닥 타일 패턴
	for tx in range(8):
		for ty in range(6):
			var tile_x := 2230 + tx * 82
			var tile_y := 930 + ty * 88
			var shade := 0.33 + fmod(float(tx + ty), 2.0) * 0.04
			draw_rect(Rect2(tile_x, tile_y, 78, 84), Color(shade, shade * 0.9, shade * 0.75))
	# 분수대
	draw_circle(Vector2(2560, 1200), 40, Color(0.25, 0.23, 0.18))
	draw_circle(Vector2(2560, 1200), 32, Color(0.2, 0.32, 0.4))
	draw_circle(Vector2(2560, 1200), 24, Color(0.25, 0.38, 0.5))
	draw_circle(Vector2(2560, 1200), 10, Color(0.3, 0.26, 0.2))

	# === 시장 노점 ===
	_draw_stall(Vector2(2250, 940), Color(0.7, 0.2, 0.15))   # 빨간 천막
	_draw_stall(Vector2(2500, 940), Color(0.2, 0.5, 0.15))   # 초록 천막
	_draw_stall(Vector2(2750, 940), Color(0.15, 0.25, 0.6))  # 파란 천막
	_draw_stall(Vector2(2250, 1400), Color(0.6, 0.5, 0.1))   # 노란 천막
	_draw_stall(Vector2(2500, 1400), Color(0.5, 0.15, 0.4))  # 보라 천막
	_draw_stall(Vector2(2750, 1400), Color(0.6, 0.35, 0.1))  # 주황 천막

	# === 건물 (석조) ===
	# 좌상단 — 주거구역
	_draw_stone_building(Vector2(200, 100), Vector2(280, 200))
	_draw_stone_building(Vector2(550, 80), Vector2(240, 180))
	_draw_stone_building(Vector2(200, 380), Vector2(260, 160))

	# 우상단 — 상인 구역
	_draw_stone_building(Vector2(4000, 100), Vector2(320, 220))
	_draw_stone_building(Vector2(4400, 120), Vector2(280, 200))
	_draw_stone_building(Vector2(4100, 380), Vector2(240, 160))

	# 좌하단 — 항구/창고 구역
	_draw_warehouse(Vector2(200, 1500), Vector2(300, 200))
	_draw_warehouse(Vector2(200, 1780), Vector2(280, 180))
	_draw_stone_building(Vector2(550, 1550), Vector2(220, 160))

	# 우하단
	_draw_stone_building(Vector2(4200, 1500), Vector2(300, 220))
	_draw_stone_building(Vector2(4100, 1800), Vector2(260, 180))
	_draw_warehouse(Vector2(4500, 1750), Vector2(240, 200))

	# 하단 — 남문 근처
	_draw_stone_building(Vector2(1600, 2200), Vector2(280, 200))
	_draw_stone_building(Vector2(2000, 2300), Vector2(200, 180))
	_draw_stone_building(Vector2(3200, 2200), Vector2(260, 200))
	_draw_stone_building(Vector2(3600, 2300), Vector2(220, 180))

	# === 나무 (가로수) ===
	# 대로변 가로수
	for i in range(12):
		_draw_tree(Vector2(2420, 300 + i * 200))
		_draw_tree(Vector2(2700, 300 + i * 200))
	for i in range(10):
		_draw_tree(Vector2(400 + i * 450, 1080))
		_draw_tree(Vector2(400 + i * 450, 1320))

	# 공원/녹지
	_draw_tree(Vector2(1500, 700))
	_draw_tree(Vector2(1650, 750))
	_draw_tree(Vector2(1550, 850))
	_draw_tree(Vector2(3500, 700))
	_draw_tree(Vector2(3650, 780))
	_draw_tree(Vector2(3550, 860))


func _draw_city_wall() -> void:
	var wall_color := Color(0.35, 0.32, 0.25)
	var wall_dark := Color(0.28, 0.25, 0.2)
	var thickness := 32.0

	# 외벽
	draw_rect(Rect2(0, 0, 5120, thickness), wall_color)      # 상
	draw_rect(Rect2(0, 2848, 5120, thickness), wall_color)    # 하
	draw_rect(Rect2(0, 0, thickness, 2880), wall_color)       # 좌
	draw_rect(Rect2(5088, 0, thickness, 2880), wall_color)    # 우

	# 내벽 (약간 어두운 줄)
	draw_rect(Rect2(32, 32, 5056, 8), wall_dark)
	draw_rect(Rect2(32, 2840, 5056, 8), wall_dark)
	draw_rect(Rect2(32, 32, 8, 2816), wall_dark)
	draw_rect(Rect2(5080, 32, 8, 2816), wall_dark)

	# 탑 (모서리)
	for corner in [Vector2(0, 0), Vector2(5080, 0), Vector2(0, 2840), Vector2(5080, 2840)]:
		draw_rect(Rect2(corner, Vector2(40, 40)), wall_dark)
		draw_circle(corner + Vector2(20, 20), 16, wall_color)

	# 남문 (출입구)
	draw_rect(Rect2(2510, 2848, 100, 32), Color(0.18, 0.15, 0.12))


func _draw_paved_road(from: Vector2, to: Vector2, width: float) -> void:
	var road_color := Color(0.3, 0.28, 0.22)
	var edge_color := Color(0.26, 0.24, 0.18)
	var curb_color := Color(0.35, 0.32, 0.26)
	draw_line(from, to, edge_color, width + 12)
	draw_line(from, to, curb_color, width + 4)
	draw_line(from, to, road_color, width)


func _draw_stone_building(pos: Vector2, bld_size: Vector2) -> void:
	var wall := Color(0.4, 0.38, 0.32)
	var roof := Color(0.3, 0.22, 0.18)
	# 그림자
	draw_rect(Rect2(pos + Vector2(8, 8), bld_size), Color(0, 0, 0, 0.12))
	# 벽
	draw_rect(Rect2(pos, bld_size), wall)
	# 지붕선
	draw_rect(Rect2(pos.x - 6, pos.y - 6, bld_size.x + 12, 18), roof)
	# 창문
	var win_count := int(bld_size.x / 60)
	for i in range(win_count):
		var wx := pos.x + 20 + i * 60
		draw_rect(Rect2(wx, pos.y + 30, 14, 18), Color(0.5, 0.55, 0.6, 0.6))
	# 문
	draw_rect(Rect2(pos.x + bld_size.x / 2 - 10, pos.y + bld_size.y - 24, 20, 24), Color(0.3, 0.2, 0.12))


func _draw_warehouse(pos: Vector2, wh_size: Vector2) -> void:
	var wall := Color(0.38, 0.34, 0.26)
	var roof := Color(0.28, 0.25, 0.2)
	draw_rect(Rect2(pos + Vector2(6, 6), wh_size), Color(0, 0, 0, 0.1))
	draw_rect(Rect2(pos, wh_size), wall)
	draw_rect(Rect2(pos.x - 4, pos.y - 4, wh_size.x + 8, 14), roof)
	# 대문 (넓은)
	draw_rect(Rect2(pos.x + wh_size.x / 2 - 20, pos.y + wh_size.y - 30, 40, 30), Color(0.32, 0.22, 0.12))


func _draw_stall(pos: Vector2, canopy_color: Color) -> void:
	# 노점 테이블
	draw_rect(Rect2(pos, Vector2(100, 60)), Color(0.4, 0.3, 0.2))
	# 천막
	draw_rect(Rect2(pos.x - 8, pos.y - 12, 116, 16), canopy_color)
	draw_rect(Rect2(pos.x - 8, pos.y - 12, 116, 4), Color(canopy_color.r * 0.7, canopy_color.g * 0.7, canopy_color.b * 0.7))
	# 물건들 (작은 사각형)
	for i in range(3):
		var item_color := Color(randf_range(0.4, 0.7), randf_range(0.3, 0.6), randf_range(0.2, 0.5))
		draw_rect(Rect2(pos.x + 10 + i * 28, pos.y + 15, 20, 14), item_color)


func _draw_tree(pos: Vector2) -> void:
	draw_circle(pos + Vector2(4, 5), 16, Color(0, 0, 0, 0.08))
	draw_circle(pos, 16, Color(0.15, 0.28, 0.12))
	draw_circle(pos, 12, Color(0.22, 0.36, 0.16))
	draw_circle(pos + Vector2(-3, -2), 8, Color(0.26, 0.4, 0.2))
	draw_circle(pos, 3, Color(0.35, 0.25, 0.15))
