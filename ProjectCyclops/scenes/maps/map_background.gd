extends Node2D

## 청크 기반 배경 — 카메라에 보이는 영역만 렌더링

@export var map_width: int = 5120
@export var map_height: int = 2880
@export var chunk_size: int = 640
@export var bg_color: Color = Color(0.18, 0.22, 0.15, 1)

var chunks: Dictionary = {}
var last_camera_chunk: Vector2i = Vector2i(-999, -999)


func _ready() -> void:
	add_to_group("map_background")
	_update_visible_chunks()


func get_map_size() -> Vector2:
	return Vector2(map_width, map_height)


func _process(_delta: float) -> void:
	_update_visible_chunks()


func _update_visible_chunks() -> void:
	var viewport := get_viewport()
	if viewport == null:
		return
	var camera := viewport.get_camera_2d()
	if camera == null:
		return

	var cam_pos := camera.global_position
	var cam_chunk := Vector2i(int(cam_pos.x) / chunk_size, int(cam_pos.y) / chunk_size)

	if cam_chunk == last_camera_chunk:
		return
	last_camera_chunk = cam_chunk

	# 화면 범위 + 1청크 여유
	var margin := 2
	var visible_set: Dictionary = {}
	for cx in range(cam_chunk.x - margin, cam_chunk.x + margin + 1):
		for cy in range(cam_chunk.y - margin, cam_chunk.y + margin + 1):
			var key := Vector2i(cx, cy)
			if cx * chunk_size < map_width and cy * chunk_size < map_height and cx * chunk_size + chunk_size > 0 and cy * chunk_size + chunk_size > 0:
				visible_set[key] = true
				if key not in chunks:
					_create_chunk(key)

	# 보이지 않는 청크 제거
	var to_remove: Array = []
	for key in chunks:
		if key not in visible_set:
			to_remove.append(key)
	for key in to_remove:
		chunks[key].queue_free()
		chunks.erase(key)


func _create_chunk(key: Vector2i) -> void:
	var rect := ColorRect.new()
	rect.position = Vector2(key.x * chunk_size, key.y * chunk_size)
	rect.size = Vector2(chunk_size, chunk_size)
	rect.color = bg_color
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(rect)
	chunks[key] = rect
