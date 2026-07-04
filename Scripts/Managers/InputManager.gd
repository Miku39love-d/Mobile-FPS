# ============================================================
# InputManager.gd - 统一管理所有触摸输入
# 单例模式，处理虚拟摇杆 + 视角触控
# 信号驱动，解耦输入与逻辑
# ============================================================

class_name InputManager
extends Node

## 单例
static var instance: InputManager = null

func _init():
	if instance == null:
		instance = self
	else:
		queue_free()

signal move_vector_changed(vector: Vector2)   # 摇杆移动向量 (-1~1)
signal look_vector_changed(vector: Vector2)    # 视角转动向量 (delta)
signal tap_pressed(pos: Vector2)              # 屏幕点击
signal back_pressed()                          # 返回键（Android）

# ==================== 虚拟摇杆状态 ====================
var _joystick_active: bool = false
var _joystick_origin: Vector2 = Vector2.ZERO
var _joystick_current: Vector2 = Vector2.ZERO
var _joystick_radius: float = 120.0           # 摇杆活动半径（像素）
var _joystick_vector: Vector2 = Vector2.ZERO   # 归一化移动向量

## 摇杆输出向量（只读）
func get_move_vector() -> Vector2:
	return _joystick_vector

# ==================== 视角触控状态 ====================
var _look_active: bool = false
var _look_last_pos: Vector2 = Vector2.ZERO
var _look_delta: Vector2 = Vector2.ZERO

## 本帧视角增量（只读，每帧清零）
func consume_look_delta() -> Vector2:
	var ret: Vector2 = _look_delta
	_look_delta = Vector2.ZERO
	return ret

# ==================== 区域定义（由 UIManager 设置）========================
## 左侧摇杆区域（屏幕坐标）
var joystick_area: Rect2 = Rect2(0, 0, 540, 1080)   # 默认左半屏
## 右侧视角区域
var look_area: Rect2 = Rect2(540, 0, 540, 1080)       # 默认右半屏

func set_joystick_area(rect: Rect2):
	joystick_area = rect

func set_look_area(rect: Rect2):
	look_area = rect

# ==================== 输入处理 ====================
func _input(event: InputEvent):
	# 只处理触摸屏事件
	if event is InputEventScreenTouch:
		_handle_screen_touch(event)
	elif event is InputEventScreenDrag:
		_handle_screen_drag(event)

	# Android 返回键
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_BACK:
			back_pressed.emit()

func _handle_screen_touch(event: InputEventScreenTouch):
	var pos: Vector2 = event.position

	if event.pressed:
		# 按下
		if joystick_area.has_point(pos) and not _joystick_active:
			_joystick_active = true
			_joystick_origin = pos
			_joystick_current = pos
			_joystick_vector = Vector2.ZERO
			emit_signal("joystick_pressed", pos)
		elif look_area.has_point(pos) and not _look_active:
			_look_active = true
			_look_last_pos = pos
			emit_signal("look_pressed", pos)
		else:
			# 其他区域点击
			tap_pressed.emit(pos)

	else:
		# 松开
		if _joystick_active:
			_joystick_active = false
			_joystick_vector = Vector2.ZERO
			move_vector_changed.emit(Vector2.ZERO)
			emit_signal("joystick_released")
		if _look_active:
			_look_active = false
			emit_signal("look_released")

func _handle_screen_drag(event: InputEventScreenDrag):
	var pos: Vector2 = event.position
	var rel: Vector2 = event.relative

	if _joystick_active and joystick_area.has_point(pos):
		# 摇杆拖动
		_joystick_current = pos
		var offset: Vector2 = _joystick_current - _joystick_origin
		# 限制半径
		if offset.length() > _joystick_radius:
			offset = offset.normalized() * _joystick_radius
		_joystick_vector = offset / _joystick_radius
		_joystick_vector = _joystick_vector.limit_length(1.0)
		move_vector_changed.emit(_joystick_vector)
		emit_signal("joystick_moved", _joystick_origin, _joystick_current, _joystick_vector)

	if _look_active and _look_active:
		# 视角拖动（右侧）
		_look_delta += rel
		look_vector_changed.emit(rel)

# ==================== 摇杆 UI 查询 ====================
signal joystick_pressed(pos: Vector2)
signal joystick_released()
signal joystick_moved(origin: Vector2, current: Vector2, vector: Vector2)
signal look_pressed(pos: Vector2)
signal look_released()

## 获取摇杆视觉信息（供 UI 绘制用）
func get_joystick_visual() -> Dictionary:
	return {
		"active": _joystick_active,
		"origin": _joystick_origin,
		"current": _joystick_current,
		"vector": _joystick_vector,
		"radius": _joystick_radius
	}

# ==================== 陀螺仪（预留）========================
var _gyro_enabled: bool = false

func enable_gyro():
	Input.set_use_gyroscope(true)
	_gyro_enabled = true

func disable_gyro():
	Input.set_use_gyroscope(false)
	_gyro_enabled = false

func get_gyro_delta() -> Vector2:
	"""返回陀螺仪视角增量，需在 _process 中调用"""
	if not _gyro_enabled:
		return Vector2.ZERO
	var gyro: Vector3 = Input.get_gyroscope()
	# 灵敏度由 SettingsManager 控制
	var sens: float = SettingsManager.get_instance().gyro_sensitivity
	return Vector2(gyro.y, gyro.x) * sens
