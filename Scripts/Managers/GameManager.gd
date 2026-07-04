# ============================================================
# GameManager.gd - 游戏主管理器
# 单例，控制游戏状态（菜单/游戏中/暂停）
# ============================================================

class_name GameManager
extends Node

static var instance: GameManager = null

## 游戏状态
enum GameState { MENU, PLAYING, PAUSED, SETTINGS }
var current_state: int = GameState.MENU:
	set(v):
		current_state = v
		state_changed.emit(v)

signal state_changed(new_state: int)

func _ready():
	instance = self
	# 确保持久化
	process_mode = Node.PROCESS_MODE_ALWAYS

func start_game():
	"""开始游戏，隐藏菜单，显示 HUD"""
	current_state = GameState.PLAYING
	get_tree().paused = false

func pause_game():
	current_state = GameState.PAUSED
	get_tree().paused = true

func resume_game():
	current_state = GameState.PLAYING
	get_tree().paused = false

func open_settings():
	current_state = GameState.SETTINGS

func quit_game():
	get_tree().quit()
