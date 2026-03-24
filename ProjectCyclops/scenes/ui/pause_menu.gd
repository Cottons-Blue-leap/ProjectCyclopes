extends CanvasLayer

## 일시정지 메뉴 — ESC로 열기/닫기, 저장하기

@onready var panel: PanelContainer = $Panel
@onready var resume_btn: Button = $Panel/VBoxContainer/ResumeButton
@onready var save_btn: Button = $Panel/VBoxContainer/SaveButton
@onready var load_btn: Button = $Panel/VBoxContainer/LoadButton
@onready var save_label: Label = $Panel/VBoxContainer/SaveLabel

var is_open: bool = false


func _ready() -> void:
	panel.visible = false
	save_label.visible = false
	resume_btn.pressed.connect(_on_resume)
	save_btn.pressed.connect(_on_save)
	load_btn.pressed.connect(_on_load)
	load_btn.disabled = not SaveManager.has_save()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("cancel"):
		if is_open:
			_close()
		elif GameManager.is_state(GameManager.GameState.EXPLORE) or GameManager.is_state(GameManager.GameState.COMBAT):
			_open()
		get_viewport().set_input_as_handled()


func _open() -> void:
	is_open = true
	panel.visible = true
	save_label.visible = false
	load_btn.disabled = not SaveManager.has_save()
	get_tree().paused = true


func _close() -> void:
	is_open = false
	panel.visible = false
	get_tree().paused = false


func _on_resume() -> void:
	_close()


func _on_save() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		save_label.text = "저장 실패: 플레이어를 찾을 수 없음"
		save_label.visible = true
		return

	var player_data := {
		"position_x": player.global_position.x,
		"position_y": player.global_position.y,
		"current_hearts": player.current_hearts,
		"scene": get_tree().current_scene.scene_file_path,
	}
	SaveManager.save_game(player_data)
	save_label.text = "저장 완료!"
	save_label.visible = true
	load_btn.disabled = false


func _on_load() -> void:
	if not SaveManager.has_save():
		save_label.text = "저장 데이터 없음"
		save_label.visible = true
		return

	var player_data := SaveManager.load_game()
	if player_data.is_empty():
		save_label.text = "불러오기 실패"
		save_label.visible = true
		return

	# 일시정지 해제 후 씬 전환
	get_tree().paused = false
	is_open = false
	panel.visible = false

	var target_scene: String = player_data.get("scene", "")
	if target_scene != "":
		get_tree().change_scene_to_file(target_scene)
		# 씬 로드 후 플레이어 위치/체력 복원
		await get_tree().tree_changed
		var player := get_tree().get_first_node_in_group("player")
		if player:
			player.global_position = Vector2(
				player_data.get("position_x", 640),
				player_data.get("position_y", 360)
			)
			player.current_hearts = int(player_data.get("current_hearts", player.max_hearts))
