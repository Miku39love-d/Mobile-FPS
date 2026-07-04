# ============================================================
# JoystickUI.gd - 虚拟摇杆 UI 绘制
# 作为 Control 节点，在左侧区域绘制摇杆背景和手柄
# ============================================================

class_name JoystickUI
extends Control

# ==================== 样式 ====================
## 摇杆背景颜色（半透明）
@export var bg_color: Color = Color(1, 1, 1, 0.15)
## 摇杆手柄颜色
@export var handle_color: Color = Color(1, 1, 1, 0.45)
## 摇杆背景半径
@export var bg_radius: float = 120.0
## 手柄半径
@export var handle_radius: float = 50.0

# ==================== 内部状态 ====================
var _active: bool = false
var _origin: Vector2 = Vector2.ZERO
var _current: Vector2 = Vector2.ZERO
var _vector: Vector2 = Vector2.ZERO

# ==================== 生命周期 ====================
func _ready():
	# 占满父容器
	anchor_right  = 1.0
	anchor_bottom = 1.0
	# 确保可以接收鼠标/触摸事件
	mouse_filter = MOUSE_FILTER_IGNORE

func _draw():
	"""绘制摇杆"""
	if not _active:
		return
	# 背景圆
	draw_circle(_origin, bg_radius, bg_color)
	# 手柄圆
	var handle_pos: Vector2 = _origin + _vector * bg_radius
	draw_circle(handle_pos, handle_radius, handle_color)
	# 中心点小圆（装饰）
	draw_circle(_origin, 10.0, Color(1, 1, 1, 0.2))

# ==================== 公共接口 ====================
func set_active(active: bool):
	_active = active
	queue_redraw()

func set_origin(pos: Vector2):
	_origin = pos
	queue_redraw()

func set_current(current: Vector2, vector: Vector2):
	_current = current
	_vector  = vector
	queue_redraw()

func reset():
	_active = false
	_vector = Vector2.ZERO
	queue_redraw()
