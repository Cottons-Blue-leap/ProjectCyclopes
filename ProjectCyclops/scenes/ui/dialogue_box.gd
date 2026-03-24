extends CanvasLayer

## 하단 대화 텍스트박스 UI

@onready var panel: PanelContainer = $Panel
@onready var speaker_label: Label = $Panel/MarginContainer/VBoxContainer/SpeakerLabel
@onready var text_label: RichTextLabel = $Panel/MarginContainer/VBoxContainer/TextLabel
@onready var choice_container: VBoxContainer = $Panel/MarginContainer/VBoxContainer/ChoiceContainer
@onready var advance_indicator: Label = $Panel/MarginContainer/VBoxContainer/AdvanceIndicator

const CHAR_DELAY: float = 0.03  # 타이핑 효과 속도
const ADVANCE_COOLDOWN: float = 0.4  # 대사 표시 후 최소 대기 시간

var dialogue_data: Dictionary = {}
var current_lines: Array = []
var current_line_index: int = 0
var is_typing: bool = false
var is_waiting_for_input: bool = false
var is_showing_choices: bool = false
var typing_tween: Tween = null
var selected_choice: int = 0
var choice_buttons: Array = []
var advance_cooldown_timer: float = 0.0


func _ready() -> void:
	panel.visible = false
	advance_indicator.visible = false
	_clear_choices()
	add_to_group("dialogue_box")


func _process(delta: float) -> void:
	if advance_cooldown_timer > 0:
		advance_cooldown_timer -= delta


func _unhandled_input(event: InputEvent) -> void:
	if not panel.visible:
		return

	if is_showing_choices:
		_handle_choice_input(event)
		return

	var is_advance := event.is_action_pressed("dialogue_advance") or event.is_action_pressed("interact") or event.is_action_pressed("attack")

	if is_typing and is_advance:
		# 타이핑 중 스킵 → 전체 표시
		_skip_typing()
		get_viewport().set_input_as_handled()
	elif is_waiting_for_input and is_advance and advance_cooldown_timer <= 0:
		# 다음 대사로 (쿨다운 지난 후에만)
		_advance()
		get_viewport().set_input_as_handled()


## 대화 시작
func start(data: Dictionary) -> void:
	dialogue_data = data
	current_lines = data.get("lines", [])
	current_line_index = 0
	panel.visible = true
	GameManager.change_state(GameManager.GameState.DIALOGUE)
	_show_current_line()


## 현재 대사 표시
func _show_current_line() -> void:
	if current_line_index >= current_lines.size():
		_end_dialogue()
		return

	var line: Dictionary = current_lines[current_line_index]

	# 조건 체크 (플래그/평판 기반 필터링)
	if not _check_conditions(line):
		current_line_index += 1
		_show_current_line()
		return

	speaker_label.text = line.get("speaker", "")
	var full_text: String = line.get("text", "")

	# 타이핑 효과
	text_label.text = full_text
	text_label.visible_ratio = 0.0
	is_typing = true
	is_waiting_for_input = false
	advance_indicator.visible = false
	_clear_choices()

	if typing_tween:
		typing_tween.kill()
	typing_tween = create_tween()
	var duration := full_text.length() * CHAR_DELAY
	typing_tween.tween_property(text_label, "visible_ratio", 1.0, duration)
	typing_tween.tween_callback(_on_typing_finished.bind(line))


func _on_typing_finished(line: Dictionary) -> void:
	is_typing = false
	advance_cooldown_timer = ADVANCE_COOLDOWN

	# 다음이 선택지인지 확인
	var next_id: String = line.get("next", "")
	if next_id != "" and dialogue_data.has("choices") and dialogue_data["choices"].has(next_id):
		_show_choices(dialogue_data["choices"][next_id])
	else:
		is_waiting_for_input = true
		advance_indicator.visible = true


func _skip_typing() -> void:
	if typing_tween:
		typing_tween.kill()
	text_label.visible_ratio = 1.0
	is_typing = false
	advance_cooldown_timer = ADVANCE_COOLDOWN

	var line: Dictionary = current_lines[current_line_index]
	var next_id: String = line.get("next", "")
	if next_id != "" and dialogue_data.has("choices") and dialogue_data["choices"].has(next_id):
		_show_choices(dialogue_data["choices"][next_id])
	else:
		is_waiting_for_input = true
		advance_indicator.visible = true


## 다음 대사
func _advance() -> void:
	is_waiting_for_input = false
	advance_indicator.visible = false

	var line: Dictionary = current_lines[current_line_index]
	var next_id: String = line.get("next", "")

	# next가 다른 대사 라인을 가리키는 경우
	if next_id != "":
		var found := _find_line_by_id(next_id)
		if found >= 0:
			current_line_index = found
			_show_current_line()
			return

	# next가 명시적으로 ""이면 대화 종료
	if line.has("next"):
		_end_dialogue()
		return

	# next 키 자체가 없는 경우에만 순차 진행
	current_line_index += 1
	_show_current_line()


## 선택지 표시
func _show_choices(choice_data: Dictionary) -> void:
	is_showing_choices = true
	advance_indicator.visible = false
	_clear_choices()

	var options: Array = choice_data.get("options", [])
	selected_choice = 0

	for i in range(options.size()):
		var option: Dictionary = options[i]
		var label := Label.new()
		label.text = option.get("text", "")
		label.add_theme_font_size_override("font_size", 14)
		choice_container.add_child(label)
		choice_buttons.append(label)

	choice_container.visible = true
	_update_choice_highlight()


func _handle_choice_input(event: InputEvent) -> void:
	# 마우스 스크롤로 선택지 이동
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
			selected_choice = max(0, selected_choice - 1)
			_update_choice_highlight()
			get_viewport().set_input_as_handled()
			return
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			selected_choice = min(choice_buttons.size() - 1, selected_choice + 1)
			_update_choice_highlight()
			get_viewport().set_input_as_handled()
			return

	if event.is_action_pressed("move_up"):
		selected_choice = max(0, selected_choice - 1)
		_update_choice_highlight()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("move_down"):
		selected_choice = min(choice_buttons.size() - 1, selected_choice + 1)
		_update_choice_highlight()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("interact") or event.is_action_pressed("dialogue_advance") or event.is_action_pressed("attack"):
		_select_choice()
		get_viewport().set_input_as_handled()


func _update_choice_highlight() -> void:
	for i in range(choice_buttons.size()):
		var label: Label = choice_buttons[i]
		if i == selected_choice:
			label.text = "> " + label.text.lstrip("> ")
			label.modulate = Color(1, 1, 0.5)
		else:
			label.text = label.text.lstrip("> ")
			label.modulate = Color(0.7, 0.7, 0.7)


func _select_choice() -> void:
	is_showing_choices = false

	# 현재 대사의 next에서 선택지 데이터 가져오기
	var line: Dictionary = current_lines[current_line_index]
	var next_id: String = line.get("next", "")
	var choice_data: Dictionary = dialogue_data["choices"][next_id]
	var options: Array = choice_data.get("options", [])
	var chosen: Dictionary = options[selected_choice]

	# 플래그/평판 적용
	var flags: Dictionary = chosen.get("flags", {})
	for key in flags:
		if key.begins_with("reputation_"):
			var faction: String = key.replace("reputation_", "")
			ReputationManager.change_reputation(faction, int(flags[key]))
		else:
			EventFlags.set_flag(key, flags[key])

	DialogueManager.choice_made.emit(selected_choice)
	_clear_choices()

	# 선택지의 next로 이동
	var chosen_next: String = chosen.get("next", "")
	if chosen_next != "":
		var found := _find_line_by_id(chosen_next)
		if found >= 0:
			current_line_index = found
			_show_current_line()
			return

	# next가 없으면 대화 종료
	_end_dialogue()


func _clear_choices() -> void:
	for child in choice_container.get_children():
		child.queue_free()
	choice_buttons.clear()
	choice_container.visible = false


## 조건 체크
## 평판 조건: 양수 = 이상, 음수 = 이하 (예: -3 → 평판 -3 이하일 때 매치)
func _check_conditions(line: Dictionary) -> bool:
	var conditions: Dictionary = line.get("conditions", {})
	for key in conditions:
		if key.begins_with("reputation_"):
			var faction: String = key.replace("reputation_", "")
			var required: int = int(conditions[key])
			var current: int = ReputationManager.get_reputation(faction)
			if required >= 0 and current < required:
				return false
			elif required < 0 and current > required:
				return false
		elif key.begins_with("flag_"):
			if EventFlags.get_flag(key) != conditions[key]:
				return false
	return true


## ID로 라인 검색
func _find_line_by_id(line_id: String) -> int:
	for i in range(current_lines.size()):
		if current_lines[i].get("id", "") == line_id:
			return i
	return -1


## 대화 종료
func _end_dialogue() -> void:
	panel.visible = false
	_clear_choices()
	GameManager.change_state(GameManager.GameState.EXPLORE)
	DialogueManager.end_dialogue()
