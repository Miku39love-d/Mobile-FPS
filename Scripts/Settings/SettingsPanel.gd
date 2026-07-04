# ============================================================
# SettingsPanel.gd - 设置主面板（操作/画质/灵敏度标签页）
# 现代深色风格，半透明面板，标签页切换
# ============================================================

class_name SettingsPanel
extends Panel

# ==================== 节点引用（Inspector 中赋值）========================
@onready var tab_container: TabContainer = $TabContainer
@onready var btn_close: Button         = $BtnClose

# ==================== 子面板 ====================
@onready var graphics_panel: Control   = $TabContainer/Graphics
@onready var controls_panel: Control   = $TabContainer/Controls
@onready var key_edit_btn: Button     = $TabContainer/Controls/BtnKeyEdit

# ==================== 生命周期 ====================
func _ready():
	# 关闭按钮
	btn_close.pressed.connect(_on_close)
	# 自定义键位按钮
	key_edit_btn.pressed.connect(_on_key_edit)
	# 初始化各子面板
	_init_graphics_panel()
	_init_controls_panel()
	# 半透明背景
	self_modulate = Color(1, 1, 1, 0.95)

func _on_close():
	"""关闭设置面板"""
	visible = false
	if UIManager.instance:
		UIManager.instance.close_settings()

func _on_key_edit():
	"""打开键位编辑"""
	if UIManager.instance:
		UIManager.instance.open_key_editor()

# ==================== 画质面板初始化 ====================
func _init_graphics_panel():
	"""动态创建画质设置控件（如果场景里没有的话）"""
	# 由 GraphicsSettings.gd 负责具体逻辑
	pass

# ==================== 操作面板初始化 ====================
func _init_controls_panel():
	"""动态创建操作设置控件"""
	# 由 ControlsSettings.gd 负责具体逻辑
	pass

# ==================== 应用主题 ====================
func apply_dark_theme():
	"""应用深色玻璃拟态主题"""
	var bg_style: StyleBoxFlat = StyleBoxFlat.new()
	bg_style.bg_color       = Color(0.08, 0.08, 0.12, 0.92)
	bg_style.corner_radius_top_left    = 18
	bg_style.corner_radius_top_right   = 18
	bg_style.corner_radius_bottom_left  = 18
	bg_style.corner_radius_bottom_right = 18
	bg_style.set_border_width_all(1)
	bg_style.border_color = Color(1, 1, 1, 0.08)
	add_theme_stylebox_override("panel", bg_style)
