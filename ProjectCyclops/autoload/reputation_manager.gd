extends Node

## 평판 시스템 — 지역/세력별 int 값

var reputation: Dictionary = {
	"oneeye": 0,
	"twoeye": 0,
	"trade": 0,
}

func change_reputation(faction: String, amount: int) -> void:
	if faction in reputation:
		reputation[faction] += amount

func get_reputation(faction: String) -> int:
	return reputation.get(faction, 0)

## 평판 단계 반환
func get_reputation_level(faction: String) -> String:
	var value := get_reputation(faction)
	if value <= -10:
		return "hostile"
	elif value <= -3:
		return "wary"
	elif value <= 3:
		return "neutral"
	elif value <= 10:
		return "friendly"
	else:
		return "trusted"

func get_save_data() -> Dictionary:
	return reputation.duplicate()

func load_save_data(data: Dictionary) -> void:
	reputation = data.duplicate()
