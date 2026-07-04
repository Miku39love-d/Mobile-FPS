# ============================================================
# KeyEditor.gd - 键位编辑器核心类
# 统一管理所有可编辑按键：拖动、缩放、保存、恢复默认
# 进入编辑模式后，半透明黑色遮罩 + 所有按键高亮边框
# ============================================================

class_name KeyEditor
extends Control

# ==================== 信号 ====================
signal layout_saved(layout: Dictionary)
signal layout_reset()
signal edit_cancelled()

# ==================== 编辑状态 ====================
var _edit_mode: bool = false
var _editing_button: Button = null       # 当前正在拖动的按钮
var _edit_start_pos: Vector2 = Vector2.ZERO
var _drag_offset: Vector2 = Vector2.ZERO

## 所有可编辑按钮的列表（由外部注册）
var _registered_buttons: Array[Button] = []

## 按键数据：{ "btn_id": {"pos_x": float, "pos_y": float, "size_x": float, "size_y": float} }
var _working_layout: Dictionary = {}

# ==================== 缩放状态 ====================
var _pinch_active: bool = false
var _pinch_start_dist: float = 0.0
var _pinch_start_size: Vector2 = Vector2.ZERO

# ==================== UI 节点 ====================
@onready var overlay: ColorRect = $Overlay          # 半透明黑色遮罩
@onready var info_label: Label   = $InfoLabel       # 显示当前选中按钮信息
@onready var btn_save: Button     = $BtnSave
@onready var btn_reset: Button    = $BtnReset
@onready var btn_cancel: Button   = $BtnCancel

# ==================== 常量 ====================
const MIN_SIZE: Vector2 = Vector2(48, 48)
const MAX_SIZE: Vector2 = Vector2(300, 150)
const SNAP_DIST: float  = 15.0   # 吸附距离（像素）
const SNAP_LINES: Array = [0.5]   # 吸附比例（屏幕中心）

# ==================== 生命周期 ====================
func _ready():
	# 初始隐藏
	visible = false
	overlay.color = Color(0, 0, 0, 0.55)
	# 按钮信号
	btn_save.pressed.connect(_on_save)
	btn_reset.pressed.connect(_on_reset)
	btn_cancel.pressed.connect(_on_cancel)

# ==================== 公共接口 ====================
func register_button(btn: Button, btn_id: String):
	"""注册一个可编辑按钮"""
	if btn not in _registered_buttons:
		_registered_buttons.append(btn)
	# 从配置加载初始位置
	_load_button_from_layout(btn, btn_id)

func unregister_button(btn: Button):
	_registered_buttons.erase(btn)

func enter_edit_mode():
	"""进入键位编辑模式"""
	_edit_mode = true
	visible = true
	_working_layout.clear()
	# 复制当前布局到工作区
	if SettingsManager.instance:
		_working_layout = SettingsManager.instance.key_layout.duplicate()
	# 高亮所有已注册按钮
	for btn in _registered_buttons:
		_add_highlight(btn)
	# 遮罩淡入动画（简化版直接显示）
	overlay.modulate = Color(1, 1, 1, 0)
	var tween: Tween = create_tween()
	tween.tween_property(overlay, "modulate:a", 1.0, 0.25)
	print("[KeyEditor] 进入键位编辑模式，共 ", _registered_buttons.size(), " 个按钮")

func exit_edit_mode():
	"""退出编辑模式"""
	_edit_mode = false
	# 移除所有高亮
	for btn in _registered_buttons:
		_remove_highlight(btn)
	# 隐藏
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	tween.tween_callback(func(): visible = false; modulate.a = 1.0)

# ==================== 输入处理 ====================
func _input(event: InputEvent):
	if not _edit_mode:
		return

	# 单指拖动
	if event is InputEventScreenTouch:
		_handle_touch(event)

	# 拖动更新
	if event is InputEventScreenDrag and _editing_button:
		_handle_drag(event)

	# 双指缩放（Pinch）
	if event is InputEventMagnifyGesture and _editing_button:
		_handle_pinch(event)

func _handle_touch(event: InputEventScreenTouch):
	var pos: Vector2 = event.position

	if event.pressed:
		# 检测点击了哪个按钮
		_editing_button = _find_button_at(pos)
		if _editing_button:
			_drag_offset    = pos - _editing_button.global_position
			_show_button_info(_editing_button)
	else:
		# 松开，应用吸附
		if _editing_button:
			_apply_snap(_editing_button)
			_editing_button = null

func _handle_drag(event: InputEventScreenDrag):
	if not _editing_button:
		return
	var new_pos: Vector2 = event.position - _drag_offset
	# 限制不拖出屏幕
	new_pos = _clamp_to_screen(_editing_button, new_pos)
	_editing_button.global_position = new_pos
	_update_working_layout(_editing_button)
	_show_button_info(_editing_button)

func _handle_pinch(event: InputEventMagnifyGesture):
	"""双指缩放按钮大小"""
	if not _editing_button:
		return
	var scale_factor: float = event.factor
	var new_size: Vector2 = _editing_button.custom_minimum_size * scale_factor
	new_size = new_size.clamp(MIN_SIZE, MAX_SIZE)
	_editing_button.custom_minimum_size = new_size
	_update_working_layout(_editing_button)
	_show_button_info(_editing_button)

# ==================== 按钮管理 ====================
func _find_button_at(pos: Vector2) -> Button:
	"""查找点击位置所在的按钮"""
	for btn in _registered_buttons:
		var rect: Rect2 = Rect2(btn.global_position, btn.size)
		if rect.has_point(pos):
			return btn
	return null

func _add_highlight(btn: Button):
	"""给按钮加编辑高亮边框"""
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.set_border_width_all(2)
	style.border_color = Color(0.2, 0.8, 1.0, 0.9)  # 蓝色高亮边框
	style.bg_color = Color(1, 1, 1, 0.08)
	btn.add_theme_stylebox_override("normal", style)
	btn.mouse_filter = MOUSE_FILTER_IGNORE  # 让触摸事件穿透到 KeyEditor

func _remove_highlight(btn: Button):
	"""移除高亮"""
	btn.remove_theme_stylebox_override("normal")
	btn.mouse_filter = MOUSE_FILTER_STOP

func _show_button_info(btn: Button):
	"""在 info_label 显示当前按钮信息"""
	if not info_label:
		return
	var pos: Vector2   = btn.global_position
	var size: Vector2   = btn.size
	info_label.text = "按键: %s | 位置: (%.0f, %.0f) | 大小: (%.0f x %.0f)" % [
		btn.name, pos.x, pos.y, size.x, size.y
	]

func _clamp_to_screen(btn: Button, pos: Vector2) -> Vector2:
	"""限制按钮不超出屏幕"""
	var screen_size: Vector2 = get_viewport_rect().size
	pos.x = clamp(pos.x, 0, screen_size.x - btn.size.x)
	pos.y = clamp(pos.y, 0, screen_size.y - btn.size.y)
	return pos

func _apply_snap(btn: Button):
	"""应用位置吸附（靠近屏幕中心/边缘时自动对齐）"""
	var screen_size: Vector2 = get_viewport_rect().size
	var btn_center: Vector2 = btn.global_position + btn.size * 0.5
	var snapped: bool = false

	# 吸附到屏幕中心
	for ratio in SNAP_LINES:
		var target_x: float = screen_size.x * ratio
		var target_y: float = screen_size.y * ratio
		if abs(btn_center.x - target_x) < SNAP_DIST:
			btn.global_position.x = target_x - btn.size.x * 0.5
			snapped = true
		if abs(btn_center.y - target_y) < SNAP_DIST:
			btn.global_position.y = target_y - btn.size.y * 0.5
			snapped = true

	if snapped:
		print("[KeyEditor] 吸附生效：", btn.name)

# ==================== 布局数据 ====================
func _update_working_layout(btn: Button):
	"""更新工作区布局数据"""
	if not SettingsManager.instance:
		return
	var btn_id: String = btn.get_meta("key_id", btn.name)
	_working_layout[btn_id] = {
		"pos_x": btn.global_position.x,
		"pos_y": btn.global_position.y,
		"size_x": btn.custom_minimum_size.x,
		"size_y": btn.custom_minimum_size.y,
	}

func _load_button_from_layout(btn: Button, btn_id: String):
	"""从配置加载按钮位置和大小"""
	if not SettingsManager.instance:
		return
	var layout: Dictionary = SettingsManager.instance.key_layout
	if layout.has(btn_id):
		var data: Dictionary = layout[btn_id]
		btn.global_position = Vector2(data.get("pos_x", 0), data.get("pos_y", 0))
		btn.custom_minimum_size = Vector2(data.get("size_x", 80), data.get("size_y", 48))

func save_layout():
	"""保存当前布局到 SettingsManager"""
	if not SettingsManager.instance:
		return
	SettingsManager.instance.key_layout = _working_layout.duplicate()
	SettingsManager.instance.save_key_layout()
	layout_saved.emit(_working_layout)
	print("[KeyEditor] 布局已保存")

func reset_layout():
	"""恢复默认布局"""
	_working_layout.clear()
	for btn in _registered_buttons:
		# 重置到默认位置（平均分布在右下角）
		btn.global_position = Vector2(100, 100)
		btn.custom_minimum_size = Vector2(100, 48)
	_update_working_layout(btn)
	layout_reset.emit()
	print("[KeyEditor] 布局已重置为默认")

# ==================== 按钮回调 ====================
func _on_save():
	save_layout()
	exit_edit_mode()

func _on_reset():
	reset_layout()

func _on_cancel():
	_exit_no_save()

func _exit_no_save():
	"""不保存退出"""
	# 恢复为进入编辑前的位置
	_working_layout.clear()
	exit_edit_mode()
	edit_cancelled.emit()
