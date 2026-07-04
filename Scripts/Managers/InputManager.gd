extends Node

## InputManager - 统一管理所有触摸输入
## 通过 project.godot 注册为 Autoload 单例

signal move_vector_changed(vector: Vector2)
signal look_vector_changed(vector: Vector2)
signal tap_pressed(pos: Vector2)

var _joystick_active: bool = false
var _joystick_origin: Vector2 = Vector2.ZERO
var _joystick_current: Vector2 = Vector2.ZERO
var _joystick_radius: float = 120.0
var _joystick_vector: Vector2 = Vector2.ZERO
var _look_active: bool = false
var _look_last_pos: Vector2 = Vector2.ZERO
var _look_delta: Vector2 = Vector2.ZERO

var joystick_area: Rect2 = Rect2(0, 0, 540, 1080)
var look_area: Rect2 = Rect2(540, 0, 540, 1080)

func _input(event: InputEvent):
	if event is InputEventScreenTouch:
		_handle_touch(event)
	elif event is InputEventScreenDrag:
		_handle_drag(event)

func _handle_touch(event: InputEventScreenTouch):
	var pos: Vector2 = event.position
	if event.pressed:
		if joystick_area.has_point(pos) and not _joystick_active:
			_joystick_active = true
			_joystick_origin = pos
			_joystick_current = pos
		elif look_area.has_point(pos) and not _look_active:
			_look_active = true
			_look_last_pos = pos
	else:
		if _joystick_active:
			_joystick_active = false
			_joystick_vector = Vector2.ZERO
			move_vector_changed.emit(Vector2.ZERO)
		if _look_active:
			_look_active = false

func _handle_drag(event: InputEventScreenDrag):
	var pos: Vector2 = event.position
	if _joystick_active and joystick_area.has_point(pos):
		_joystick_current = pos
		var offset: Vector2 = _joystick_current - _joystick_origin
		if offset.length() > _joystick_radius:
			offset = offset.normalized() * _joystick_radius
		_joystick_vector = offset / _joystick_radius
		_joystick_vector = _joystick_vector.limit_length(1.0)
		move_vector_changed.emit(_joystick_vector)
	if _look_active:
		_look_delta += event.relative
		look_vector_changed.emit(event.relative)

func consume_look_delta() -> Vector2:
	var ret: Vector2 = _look_delta
	_look_delta = Vector2.ZERO
	return ret

func get_joystick_vector() -> Vector2:
	return _joystick_vector

func get_joystick_visual() -> Dictionary:
	return {
		"active": _joystick_active,
		"origin": _joystick_origin,
		"current": _joystick_current,
		"vector": _joystick_vector,
		"radius": _joystick_radius
	}
