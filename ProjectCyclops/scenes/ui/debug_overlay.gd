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
	text += "평판:\n"
	for faction in ReputationManager.reputation:
		var value: int = ReputationManager.reputation[faction]
		var level: String = ReputationManager.get_reputation_level(faction)
		text += "  %s: %d (%s)\n" % [faction, value, level]

	text += "플래그:\n"
	for flag in EventFlags.flags:
		text += "  %s: %s\n" % [flag, str(EventFlags.flags[flag])]

	label.text = text
