extends Node

## 이벤트 플래그 시스템

var flags: Dictionary = {}

func set_flag(flag_name: String, value: bool = true) -> void:
	flags[flag_name] = value

func get_flag(flag_name: String) -> bool:
	return flags.get(flag_name, false)

func clear_all() -> void:
	flags.clear()

func get_save_data() -> Dictionary:
	return flags.duplicate()

func load_save_data(data: Dictionary) -> void:
	flags = data.duplicate()
