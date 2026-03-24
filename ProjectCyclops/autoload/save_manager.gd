extends Node

## 세이브/로드 시스템 (1슬롯)

const SAVE_PATH := "user://save_slot_1.json"

func save_game(player_data: Dictionary) -> void:
	var save_data := {
		"player": player_data,
		"event_flags": EventFlags.get_save_data(),
		"reputation": ReputationManager.get_save_data(),
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Failed to save game")
		return
	file.store_string(JSON.stringify(save_data, "\t"))

func load_game() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return {}
	var json := JSON.new()
	var result := json.parse(file.get_as_text())
	if result != OK:
		push_error("Failed to parse save file")
		return {}
	var data: Dictionary = json.data
	if data.has("event_flags"):
		EventFlags.load_save_data(data["event_flags"])
	if data.has("reputation"):
		ReputationManager.load_save_data(data["reputation"])
	return data.get("player", {})

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)
