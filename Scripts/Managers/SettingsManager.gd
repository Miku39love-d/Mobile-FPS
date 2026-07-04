# ============================================================
# SettingsManager.gd - 统一管理所有游戏设置
# 单例模式，全局访问：SettingsManager
# 所有配置通过 ConfigFile 持久化保存到 user://settings.cfg
# ============================================================

class_name SettingsManager
extends Node

## 单例自检，防止重复加载
func _ready():
	if not get_tree().root.has_node("SettingsManager"):
		get_tree().root.call_deferred("add_child", self)
	set_process(false)

## 单例获取
static var instance: SettingsManager = null

func _init():
	if instance == null:
		instance = self
	else:
		queue_free()

static func get_instance() -> SettingsManager:
	if instance == null:
		instance = SettingsManager.new()
	return instance

# ==================== 设置信号 ====================
signal setting_changed(section: String, key: String, value: Variant)  # 任意设置变更
signal graphics_changed()   # 画质相关变更
signal control_changed()    # 操作相关变更
signal ui_changed()         # UI 相关变更

# ==================== 配置文件 ====================
const CONFIG_PATH: String = "user://settings.cfg"
var _config: ConfigFile = ConfigFile.new()

# ==================== 画质设置 ====================
## 帧率选项 (FPS)
enum FPSMode { FPS_30, FPS_45, FPS_60, FPS_90, FPS_120 }
var fps_target: int = 60:
	set(v): fps_target = v; _save_setting("Graphics", "fps_target", v); graphics_changed.emit()

## 画质等级
enum QualityMode { SMOOTH, BALANCED, HD, HDR, ULTRA }
var quality_mode: int = QualityMode.BALANCED:
	set(v): quality_mode = v; _apply_quality(); graphics_changed.emit()

## 阴影质量
enum ShadowQuality { OFF, LOW, MEDIUM, HIGH }
var shadow_quality: int = ShadowQuality.MEDIUM:
	set(v): shadow_quality = v; _apply_shadow(); graphics_changed.emit()

## 抗锯齿模式
enum AAMode { OFF, FXAA, MSAA_2X, MSAA_4X, MSAA_8X }
var aa_mode: int = AAMode.FXAA:
	set(v): aa_mode = v; _apply_aa(); graphics_changed.emit()

## 渲染引擎模式（影响 Godot 渲染后端选择）
enum RenderEngine { OPENGL, VULKAN, VULKAN_DIMENSITY, ANDROID_GENERIC }
var render_engine: int = RenderEngine.VULKAN_DIMENSITY:
	set(v): render_engine = v; _apply_render_engine(); graphics_changed.emit()

## 纹理质量
enum TextureQuality { LOW, MEDIUM, HIGH }
var texture_quality: int = TextureQuality.MEDIUM:
	set(v): texture_quality = v; _apply_texture(); graphics_changed.emit()

## 特效质量
enum EffectQuality { OFF, LOW, MEDIUM, HIGH }
var effect_quality: int = EffectQuality.MEDIUM:
	set(v): effect_quality = v; _apply_effects(); graphics_changed.emit()

# ==================== 操作设置 ====================
## 镜头灵敏度 (0.1 ~ 5.0)
var look_sensitivity: float = 1.0:
	set(v): look_sensitivity = clamp(v, 0.1, 5.0); _save_setting("Controls", "look_sensitivity", v); control_changed.emit()

## ADS 灵敏度
var ads_sensitivity: float = 0.8:
	set(v): ads_sensitivity = clamp(v, 0.1, 5.0); _save_setting("Controls", "ads_sensitivity", v); control_changed.emit()

## 开镜灵敏度
var scope_sensitivity: float = 0.7:
	set(v): scope_sensitivity = clamp(v, 0.1, 5.0); _save_setting("Controls", "scope_sensitivity", v); control_changed.emit()

## 陀螺仪灵敏度 (0 = 关闭)
var gyro_sensitivity: float = 0.0:
	set(v): gyro_sensitivity = clamp(v, 0.0, 5.0); _save_setting("Controls", "gyro_sensitivity", v); control_changed.emit()

# ==================== UI 设置 ====================
## UI 缩放 (0.8 ~ 1.5)
var ui_scale: float = 1.0:
	set(v): ui_scale = clamp(v, 0.8, 1.5); _save_setting("UI", "ui_scale", v); ui_changed.emit()

# ==================== 键位数据 ====================
## 键位布局数据: { "button_id": {"pos_x": float, "pos_y": float, "size_x": float, "size_y": float} }
var key_layout: Dictionary = {}

# ==================== 生命周期 ====================
func _ready():
	_load_all_settings()
	_apply_all_graphics()
	# 确保为单例，移除场景树自动卸载
	if not get_tree().root.is_a_parent_of(self):
		get_tree().root.add_child.call_deferred(self)

## 游戏启动时调用，应用帧率
func apply_fps():
	var fps_map: Dictionary = {30: 30, 45: 45, 60: 60, 90: 90, 120: 120}
	var target: int = fps_target
	if target > 0:
		Engine.max_fps = target
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if target <= 60 else DisplayServer.VSYNC_DISABLED)
	print("[SettingsManager] FPS 目标: ", target)

# ==================== 保存 / 加载 ====================
func _save_setting(section: String, key: String, value: Variant):
	_config.set_value(section, key, value)
	_config.save(CONFIG_PATH)

func _load_all_settings():
	var err: int = _config.load(CONFIG_PATH)
	if err != OK:
		print("[SettingsManager] 未找到配置文件，使用默认设置")
		_reset_to_default()
		return

	# 画质
	fps_target     = _config.get_value("Graphics", "fps_target", 60)
	quality_mode   = _config.get_value("Graphics", "quality_mode", QualityMode.BALANCED)
	shadow_quality = _config.get_value("Graphics", "shadow_quality", ShadowQuality.MEDIUM)
	aa_mode        = _config.get_value("Graphics", "aa_mode", AAMode.FXAA)
	texture_quality= _config.get_value("Graphics", "texture_quality", TextureQuality.MEDIUM)
	effect_quality = _config.get_value("Graphics", "effect_quality", EffectQuality.MEDIUM)

	# 操作
	look_sensitivity  = _config.get_value("Controls", "look_sensitivity", 1.0)
	ads_sensitivity   = _config.get_value("Controls", "ads_sensitivity", 0.8)
	scope_sensitivity = _config.get_value("Controls", "scope_sensitivity", 0.7)
	gyro_sensitivity  = _config.get_value("Controls", "gyro_sensitivity", 0.0)

	# UI
	ui_scale = _config.get_value("UI", "ui_scale", 1.0)
	# 渲染引擎
	render_engine = _config.get_value("Graphics", "render_engine", RenderEngine.VULKAN_DIMENSITY)

	# 键位
	var raw_layout: Dictionary = _config.get_value("KeyLayout", "layout", {})
	key_layout = raw_layout if raw_layout != null else {}

	print("[SettingsManager] 设置加载完成")

func save_key_layout():
	"""保存键位数据到配置文件"""
	_config.set_value("KeyLayout", "layout", key_layout)
	_config.save(CONFIG_PATH)
	print("[SettingsManager] 键位布局已保存")

func _reset_to_default():
	"""恢复默认设置并保存"""
	fps_target = 60
	quality_mode = QualityMode.BALANCED
	shadow_quality = ShadowQuality.MEDIUM
	aa_mode = AAMode.FXAA
	texture_quality = TextureQuality.MEDIUM
	effect_quality = EffectQuality.MEDIUM
	look_sensitivity = 1.0
	ads_sensitivity = 0.8
	scope_sensitivity = 0.7
	gyro_sensitivity = 0.0
	ui_scale = 1.0
	key_layout.clear()
	_save_all()

func _save_all():
	"""保存所有当前设置"""
	_config.set_value("Graphics", "fps_target", fps_target)
	_config.set_value("Graphics", "quality_mode", quality_mode)
	_config.set_value("Graphics", "shadow_quality", shadow_quality)
	_config.set_value("Graphics", "aa_mode", aa_mode)
	_config.set_value("Graphics", "texture_quality", texture_quality)
	_config.set_value("Graphics", "effect_quality", effect_quality)
	_config.set_value("Controls", "look_sensitivity", look_sensitivity)
	_config.set_value("Controls", "ads_sensitivity", ads_sensitivity)
	_config.set_value("Controls", "scope_sensitivity", scope_sensitivity)
	_config.set_value("Controls", "gyro_sensitivity", gyro_sensitivity)
	_config.set_value("UI", "ui_scale", ui_scale)
	_config.set_value("Graphics", "render_engine", render_engine)
	_config.set_value("KeyLayout", "layout", key_layout)
	_config.save(CONFIG_PATH)

# ==================== 图形应用 ====================
func _apply_all_graphics():
	_apply_quality()
	_apply_shadow()
	_apply_aa()
	_apply_texture()
	_apply_effects()
	apply_fps()

func _apply_quality():
	"""应用整体画质等级"""
	match quality_mode:
		QualityMode.SMOOTH:
			RenderingServer.viewport_set_render_info(null, RenderingServer.VIEWPORT_RENDER_INFO_TYPE_VISIBLE, RenderingServer.VIEWPORT_RENDER_INFO_SHADOW_ATLAS_SIZE, 1024)
			ProjectSettings.set_setting("rendering/anti_aliasing/quality/msaa_2d", 0)
			ProjectSettings.set_setting("rendering/anti_aliasing/quality/msaa_3d", 0)
		QualityMode.BALANCED:
			pass  # 默认
		QualityMode.HD, QualityMode.HDR, QualityMode.ULTRA:
			pass  # 高画质，交由子项控制

func _apply_shadow():
	match shadow_quality:
		ShadowQuality.OFF:
			RenderingServer.positional_soft_shadow_filter_set(false)
		ShadowQuality.LOW:
			RenderingServer.positional_soft_shadow_filter_set(true)
			# 低阴影质量设置
		ShadowQuality.MEDIUM, ShadowQuality.HIGH:
			RenderingServer.positional_soft_shadow_filter_set(true)

func _apply_aa():
	match aa_mode:
		AAMode.OFF:
			get_viewport().screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
		AAMode.FXAA:
			get_viewport().screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
		_:
			get_viewport().screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
			# MSAA 通过 ProjectSettings 控制

func _apply_texture():
	match texture_quality:
		TextureQuality.LOW:
			ProjectSettings.set_setting("rendering/textures/default_filters/anisotropic_filtering_level", 1)
		TextureQuality.MEDIUM:
			ProjectSettings.set_setting("rendering/textures/default_filters/anisotropic_filtering_level", 4)
		TextureQuality.HIGH:
			ProjectSettings.set_setting("rendering/textures/default_filters/anisotropic_filtering_level", 16)

func _apply_effects():
	pass  # 特效质量通过 Shader 全局参数控制，预留接口

# ==================== 工具方法 ====================
func get_fps_string() -> String:
	"""返回当前帧率设置的可读字符串"""
	match fps_target:
		30:  return "30 FPS"
		45:  return "45 FPS"
		60:  return "60 FPS"
		90:  return "90 FPS"
		120: return "120 FPS"
		_:   return str(fps_target) + " FPS"

func _apply_render_engine():
	"""应用渲染引擎设置：修改 project.godot 文件，下次启动时生效"""
	var cfg: Dictionary = get_rendering_method_config()
	var proj_path: String = "res://project.godot"
	var proj_text: String = FileAccess.get_file_as_string(proj_path)
	if proj_text == "":
		push_error("[SettingsManager] 无法读取 project.godot")
		return
	# 替换渲染配置行
	var lines: PackedStringArray = proj_text.split("\n")
	for i in range(lines.size()):
		if lines[i].begins_with("renderer/rendering_method="):
			lines[i] = "renderer/rendering_method=\"" + cfg["method"] + "\""
		if lines[i].begins_with("renderer/rendering_method.mobile/rendering_driver="):
			lines[i] = "renderer/rendering_method.mobile/rendering_driver=\"" + cfg["driver"] + "\""
	var new_text: String = ""
	for line in lines:
		new_text += line + "\n"
	var file = FileAccess.open(proj_path, FileAccess.WRITE)
	if file:
		file.store_string(new_text)
		file.close()
		print("[SettingsManager] project.godot 已更新：method=%s driver=%s" % [cfg["method"], cfg["driver"]])
	else:
		push_error("[SettingsManager] 无法写入 project.godot")

func get_render_engine_string() -> String:
	"""返回当前渲染引擎的可读字符串"""
	match render_engine:
		RenderEngine.OPENGL:         return "OpenGL ES 3.0"
		RenderEngine.VULKAN:         return "Vulkan（标准）"
		RenderEngine.VULKAN_DIMENSITY: return "Vulkan（天玑优化）"
		RenderEngine.ANDROID_GENERIC: return "安卓通用（低画质）"
		_:                          return "未知"

## 获取当前渲染后端对应的 project.godot 配置值
func get_rendering_method_config() -> Dictionary:
	"""返回 (rendering_method, rendering_driver) 元组"""
	match render_engine:
		RenderEngine.OPENGL:
			return {"method": "forward_plus", "driver": "opengl3"}
		RenderEngine.VULKAN:
			return {"method": "mobile", "driver": "vulkan"}
		RenderEngine.VULKAN_DIMENSITY:
			# 天玑优化：Vulkan + 降低部分特效
			return {"method": "mobile", "driver": "vulkan"}
		RenderEngine.ANDROID_GENERIC:
			# 安卓通用：Compatibility 后端（OpenGL ES）
			return {"method": "compatibility", "driver": "opengl3"}
		_:
			return {"method": "mobile", "driver": "vulkan"}
