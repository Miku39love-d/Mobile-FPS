# ============================================================
# Main.gd - 游戏入口脚本
# 挂载在 Main 场景根节点，负责初始化所有 Manager 并加载主场景
# ============================================================

extends Node3D

# ==================== 场景节点引用 ====================
@onready var player: CharacterBody3D = $Player          # 玩家节点
@onready var camera: Camera3D       = $Player/Camera3D # 相机
@onready var ground:  StaticBody3D  = $Ground           # 地面
@onready var ui_layer: CanvasLayer   = $UI               # UI 层

# ==================== 管理器引用 ====================
var settings_mgr: SettingsManager = null
var input_mgr:    InputManager    = null
var ui_mgr:       UIManager       = null
var game_mgr:      GameManager     = null

# ==================== 生命周期 ====================
func _ready():
	# 初始化显示设置（Android 全屏横屏）
	DisplayServer.screen_set_orientation(DisplayServer.SCREEN_LANDSCAPE)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

	# 初始化所有 Manager（自动单例化）
	_init_managers()

	# 连接玩家控制器
	_connect_player()

	# 应用设置
	if settings_mgr:
		settings_mgr.apply_fps()

	# 隐藏鼠标（PC 测试用）
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	print("[Main] 游戏初始化完成")

func _init_managers():
	# 确保所有 Manager 已加入场景树
	# 这些节点应该在场景文件中，或通过代码添加
	if not get_node_or_null("/root/SettingsManager"):
		settings_mgr = SettingsManager.new()
		settings_mgr.name = "SettingsManager"
		get_tree().root.add_child(settings_mgr)
	else:
		settings_mgr = get_node("/root/SettingsManager")

	if not get_node_or_null("/root/InputManager"):
		input_mgr = InputManager.new()
		input_mgr.name = "InputManager"
		get_tree().root.add_child(input_mgr)
	else:
		input_mgr = get_node("/root/InputManager")

	if not get_node_or_null("/root/UIManager"):
		ui_mgr = UIManager.new()
		ui_mgr.name = "UIManager"
		get_tree().root.add_child(ui_mgr)
	else:
		ui_mgr = get_node("/root/UIManager")

	if not get_node_or_null("/root/GameManager"):
		game_mgr = GameManager.new()
		game_mgr.name = "GameManager"
		get_tree().root.add_child(game_mgr)
	else:
		game_mgr = get_node("/root/GameManager")

func _connect_player():
	"""连接玩家控制器和输入管理器"""
	if player and player.has_method("set_camera"):
		pass  # 预留接口
	# 由 PlayerController.gd 自行连接 InputManager 信号

# ==================== 输入 ====================
func _input(event: InputEvent):
	# Android 返回键
	if event is InputEventKey and event.pressed and event.keycode == KEY_BACK:
		if ui_mgr:
			# 模拟返回键
			pass
