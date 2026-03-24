extends Node

## 게임 전역 상태 관리

enum GameState { EXPLORE, DIALOGUE, COMBAT, TRANSITION }

var current_state: GameState = GameState.EXPLORE

func change_state(new_state: GameState) -> void:
	current_state = new_state

func is_state(state: GameState) -> bool:
	return current_state == state
