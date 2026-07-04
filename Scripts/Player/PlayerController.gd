# ============================================================
# PlayerController.gd - 第一人称玩家控制器
# 使用 CharacterBody3D 移动，Camera3D 作为第一人称相机
# 接收 InputManager 的信号驱动移动和视角
# ============================================================

class_name PlayerController
extends CharacterBody3D

# ==================== 导出参数 ====================
## 移动速度（米/秒）
@export var move_speed: float = 5.0:
	set(v): move_speed = max(v, 0.0)

## 重力加速度
@export var gravity: float = -24.8

## 相机节点引用（Inspector 中赋值）
@export var camera: Camera3D = null

# ==================== 视角参数 ====================
## 水平灵敏度
var _look_sensitivity_h: float = 0.15
## 垂直灵敏度
var _look_sensitivity_v: float = 0.12
## 垂直视角最小角度（向下看）
var _pitch_min: float = -89.0
## 垂直视角最大角度（向上看）
var _pitch_max: float = 89.0
## 当前俯仰角（度）
var _pitch: float = 0.0
## 当前偏航角（度）
var _yaw: float = 0.0

# ==================== 内部状态 ====================
var _move_vector: Vector2 = Vector2.ZERO   # 来自虚拟摇杆的输入向量
var _look_delta: Vector2  = Vector2.ZERO   # 来自触控视角输入的增量

# ==================== 生命周期 ====================
func _ready():
	# 隐藏鼠标（PC 测试用，手机端可忽略）
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	# 连接输入管理器信号
	if InputManager.instance:
		InputManager.instance.move_vector_changed.connect(_on_move_vector_changed)
	else:
		push_warning("InputManager 未找到，输入将不工作")

func _physics_process(delta: float):
	# —— 应用重力 ——
	if not is_on_floor():
		velocity.y += gravity * delta

	# —— 计算移动方向（基于相机朝向）——
	var input_dir: Vector2 = _move_vector
	var direction: Vector3 = Vector3.ZERO
	if camera:
		var camera_basis: Basis = camera.global_transform.basis
		direction = (camera_basis.x * input_dir.x) + (camera_basis.z * input_dir.y)
		direction.y = 0
		direction = direction.normalized()

	# —— 应用移动速度 ——
	var target_velocity_xy: Vector2 = Vector2(direction.x, direction.z) * move_speed
	velocity.x = target_velocity_xy.x
	velocity.z = target_velocity_xy.y

	# —— 执行移动 ——
	move_and_slide()

func _process(_delta: float):
	# —— 处理视角旋转（来自触控输入）——
	_process_look_input()

func _process_look_input():
	"""处理本帧的视角输入（来自 InputManager）"""
	if not camera:
		return

	# 从 InputManager 获取视角增量
	var look_delta: Vector2 = Vector2.ZERO
	if InputManager.instance:
		look_delta = InputManager.instance.consume_look_delta()

	# 灵敏度从设置读取
	var sens_h: float = _look_sensitivity_h
	var sens_v: float = _look_sensitivity_v
	if SettingsManager.instance:
		# 用 look_sensitivity 作为基准，映射到实际灵敏度
		sens_h = SettingsManager.instance.look_sensitivity * 0.15
		sens_v = SettingsManager.instance.look_sensitivity * 0.12

	# 应用旋转
	_yaw   -= look_delta.x * sens_h
	_pitch -= look_delta.y * sens_v
	_pitch = clamp(_pitch, _pitch_min, _pitch_max)

	# 更新相机旋转
	camera.rotation_degrees.x = _pitch
	# 更新玩家 Y 轴旋转
	rotation_degrees.y = _yaw

# ==================== 信号回调 ====================
func _on_move_vector_changed(vector: Vector2):
	"""接收来自 InputManager 的移动向量"""
	_move_vector = vector

# ==================== 公共接口 ====================
func set_move_vector(vector: Vector2):
	"""外部设置移动向量（供非信号方式调用）"""
	_move_vector = vector

func add_look_delta(delta: Vector2):
	"""外部注入视角增量"""
	_look_delta += delta

func reset_view():
	"""重置视角到初始状态"""
	_pitch = 0.0
	_yaw   = 0.0
	if camera:
		camera.rotation_degrees.x = 0.0
	rotation_degrees.y = 0.0
