# ============================================================
# UIManager.gd - 管理所有 UI 面板切换和 HUD
# 单例模式，负责 HUD / 设置面板 / 键位编辑的显示控制
# ============================================================

class_name UIManager
extends CanvasLayer

static var instance: UIManager = null

## UI 面板类型
signal panel_opened(panel_name: String)
signal panel_closed(panel_name: String)

# ==================== 节点引用 ====================
@onready var hud_panel: Control   = $HUD       # 主游戏 HUD
@onready var settings_panel: Control = $Settings   # 设置面板
@onready var key_edit_overlay: Control = $KeyEditOverlay  # 键位编辑遮罩层

# ==================== 当前状态 ====================
var _current_panel: String = "hud"  # "hud" | "settings" | "key_edit"

func _ready():
	instance = self
	# 初始只显示 HUD
	_show_only("hud")
	# 连接设置管理器信号（如果存在）
	if SettingsManager.instance:
		SettingsManager.instance.ui_changed.connect(_on_ui_changed)

func _show_only(panel: String):
	"""只显示指定面板"""
	_current_panel = panel
	hud_panel.visible        = (panel == "hud")
	settings_panel.visible   = (panel == "settings")
	key_edit_overlay.visible = (panel == "key_edit")

# ==================== 公共接口 ====================
func open_settings():
	"""打开设置面板"""
	_show_only("settings")
	panel_opened.emit("settings")

func close_settings():
	"""关闭设置面板，返回 HUD"""
	_show_only("hud")
	panel_closed.emit("settings")

func open_key_editor():
	"""打开键位编辑界面"""
	_show_only("key_edit")
	panel_opened.emit("key_edit")

func close_key_editor():
	_close_key_editor_internal()
	panel_closed.emit("key_edit")

func _close_key_editor_internal():
	_show_only("hud")
	if key_edit_overlay.has_method("exit_edit_mode"):
		key_edit_overlay.exit_edit_mode()

# ==================== 信号响应 ====================
func _on_ui_changed():
	"""设置变更时刷新 UI"""
	_apply_ui_scale()

func _apply_ui_scale():
	"""应用 UI 缩放"""
	var scale_val: float = SettingsManager.instance.ui_scale if SettingsManager.instance else 1.0
	self.scale = Vector2(scale_val, scale_val)

# ==================== Android 返回键 ====================
func _input(event: InputEvent):
	if event is InputEventKey and event.pressed and event.keycode == KEY_BACK:
		_on_back_pressed()

func _on_back_pressed():
	match _current_panel:
		"settings":
			close_settings()
		"key_edit":
			close_key_editor()
		_:
			# 游戏中按返回 → 打开设置
			open_settings()
