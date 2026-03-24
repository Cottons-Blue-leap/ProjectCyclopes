extends CanvasLayer

## 디버그 오버레이 — 평판/플래그 수치 표시 (개발용, 출시 시 제거)

@onready var label: Label = $Label

var visible_toggle: bool = true
var _f3_held: bool = false


func _ready() -> void:
	label.text = ""


func _process(_delta: float) -> void:
	if Input.is_key_pressed(KEY_QUOTELEFT) and not _f3_held:
		_f3_held = true
		visible_toggle = not visible_toggle
		label.visible = visible_toggle
	elif not Input.is_key_pressed(KEY_QUOTELEFT):
		_f3_held = false

	if not visible_toggle:
		return

	var text := "[DEBUG] ` 키로 토글\n"

	# 현재 입력 키
	text += "입력:\n"
	var actions := ["move_up", "move_down", "move_left", "move_right", "sprint", "dodge", "attack", "parry", "interact", "cancel"]
	var active: Array = []
	for action in actions:
		if Input.is_action_pressed(action):
			active.append(action)
	text += "  %s\n" % (", ".join(active) if not active.is_empty() else "없음")

	# 플레이어 상태
	var player := get_tree().get_first_node_in_group("player")
	if player:
		text += "위치: (%.0f, %.0f)  속도: %.0f\n" % [player.global_position.x, player.global_position.y, player.velocity.length()]
		text += "하트: %d/%d  스태미나: %.0f\n" % [player.current_hearts, player.max_hearts, player.stamina]

	text += "게임상태: %s\n" % GameManager.GameState.keys()[GameManager.current_state]

	text += "평판:\n"
	for faction in ReputationManager.reputation:
		var value: int = ReputationManager.reputation[faction]
		var level: String = ReputationManager.get_reputation_level(faction)
		text += "  %s: %d (%s)\n" % [faction, value, level]

	text += "플래그:\n"
	for flag in EventFlags.flags:
		text += "  %s: %s\n" % [flag, str(EventFlags.flags[flag])]

	label.text = text
