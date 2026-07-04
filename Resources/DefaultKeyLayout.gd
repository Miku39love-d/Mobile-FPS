# ============================================================
# DefaultKeyLayout.gd - 默认键位布局数据
# 定义所有默认按钮的位置和大小
# 作为 Resource 加载，便于设计和调试
# ============================================================

class_name DefaultKeyLayout
extends Resource

@export var layout_data: Dictionary = {
	# 射击按钮（右下角）
	"btn_fire":    {"pos_x": 900, "pos_y": 420, "size_x": 120, "size_y": 120},
	# 瞄准按钮
	"btn_aim":     {"pos_x": 760, "pos_y": 480, "size_x": 90,  "size_y": 90},
	# 换弹按钮
	"btn_reload":  {"pos_x": 900, "pos_y": 280, "size_x": 80,  "size_y": 60},
	# 跳跃按钮
	"btn_jump":    {"pos_x": 1000,"pos_y": 480, "size_x": 80,  "size_y": 60},
	# 蹲下按钮
	"btn_crouch":  {"pos_x": 1000,"pos_y": 380, "size_x": 80,  "size_y": 60},
	# 趴下按钮
	"btn_prone":   {"pos_x": 1000,"pos_y": 300, "size_x": 80,  "size_y": 60},
	# 设置按钮（左上角）
	"btn_settings": {"pos_x": 20,  "pos_y": 20,  "size_x": 60,  "size_y": 60},
}

## 获取默认布局（返回深拷贝）
func get_default_layout() -> Dictionary:
	return layout_data.duplicate()

## 重置键位为默认（需要在游戏运行时调用，此时 SettingsManager 已加载）
func reset_to_default():
	if Engine.is_editor_hint():
		return
	if not has_node("/root/SettingsManager"):
		return
	var sm = get_node("/root/SettingsManager") as SettingsManager
	if sm:
		var dfl = DefaultKeyLayout.new()
		sm.key_layout = dfl.get_default_layout()
		sm.save_key_layout()
		print("[DefaultKeyLayout] 已重置为默认键位")
