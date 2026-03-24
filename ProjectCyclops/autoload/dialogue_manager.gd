extends Node

## 대화 시스템 매니저

signal dialogue_started
signal dialogue_ended
@warning_ignore("unused_signal")
signal choice_made(choice_index: int)

var current_dialogue: Dictionary = {}
var is_active: bool = false

func start_dialogue(dialogue_data: Dictionary) -> void:
	current_dialogue = dialogue_data
	is_active = true
	dialogue_started.emit()

func end_dialogue() -> void:
	current_dialogue = {}
	is_active = false
	dialogue_ended.emit()

## JSON 파일에서 대화 데이터 로드
func load_dialogue_file(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Failed to load dialogue: " + path)
		return {}
	var json := JSON.new()
	var result := json.parse(file.get_as_text())
	if result != OK:
		push_error("Failed to parse dialogue JSON: " + path)
		return {}
	return json.data
