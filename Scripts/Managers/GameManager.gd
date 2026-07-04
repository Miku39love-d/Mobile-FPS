extends Node

## GameManager - 游戏状态管理
## 通过 project.godot 注册为 Autoload 单例

enum GameState { MENU, PLAYING, PAUSED, SETTINGS }
var current_state: int = GameState.MENU

signal state_changed(new_state: int)

func start_game():
	current_state = GameState.PLAYING
	get_tree().paused = false
	state_changed.emit(current_state)

func pause_game():
	current_state = GameState.PAUSED
	get_tree().paused = true
	state_changed.emit(current_state)

func resume_game():
	current_state = GameState.PLAYING
	get_tree().paused = false
	state_changed.emit(current_state)

func open_settings():
	current_state = GameState.SETTINGS
	state_changed.emit(current_state)

func quit_game():
	get_tree().quit()
