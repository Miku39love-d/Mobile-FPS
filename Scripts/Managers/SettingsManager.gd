extends Node

## SettingsManager - 统一管理所有游戏设置
## 通过 project.godot 注册为 Autoload 单例
## 所有配置通过 ConfigFile 持久化保存到 user://settings.cfg

signal setting_changed(section: String, key: String, value: Variant)
signal graphics_changed()
signal control_changed()
signal ui_changed()

const CONFIG_PATH: String = "user://settings.cfg"
var _config: ConfigFile = ConfigFile.new()

# ==================== 画质设置 ====================
enum FPSMode { FPS_30, FPS_45, FPS_60, FPS_90, FPS_120 }
var fps_target: int = 60

enum QualityMode { SMOOTH, BALANCED, HD, HDR, ULTRA }
var quality_mode: int = QualityMode.BALANCED

enum ShadowQuality { OFF, LOW, MEDIUM, HIGH }
var shadow_quality: int = ShadowQuality.MEDIUM

enum AAMode { OFF, FXAA, MSAA_2X, MSAA_4X, MSAA_8X }
var aa_mode: int = AAMode.FXAA

enum TextureQuality { LOW, MEDIUM, HIGH }
var texture_quality: int = TextureQuality.MEDIUM

enum EffectQuality { OFF, LOW, MEDIUM, HIGH }
var effect_quality: int = EffectQuality.MEDIUM

# ==================== 渲染引擎 ====================
enum RenderEngine { OPENGL, VULKAN, VULKAN_DIMENSITY, ANDROID_GENERIC }
var render_engine: int = RenderEngine.VULKAN_DIMENSITY

# ==================== 操作设置 ====================
var look_sensitivity: float = 1.0
var ads_sensitivity: float = 0.8
var scope_sensitivity: float = 0.7
var gyro_sensitivity: float = 0.0

# ==================== UI 设置 ====================
var ui_scale: float = 1.0

# ==================== 键位数据 ====================
var key_layout: Dictionary = {}

# ==================== 生命周期 ====================
func _ready():
	_load_all_settings()
	if render_engine == RenderEngine.VULKAN_DIMENSITY:
		apply_fps()

func apply_fps():
	Engine.max_fps = fps_target
	print("[SettingsManager] FPS target: ", fps_target)

func _load_all_settings():
	var err: int = _config.load(CONFIG_PATH)
	if err != OK:
		_reset_to_default()
		return
	fps_target     = _config.get_value("Graphics", "fps_target", 60)
	quality_mode   = _config.get_value("Graphics", "quality_mode", QualityMode.BALANCED)
	shadow_quality = _config.get_value("Graphics", "shadow_quality", ShadowQuality.MEDIUM)
	aa_mode        = _config.get_value("Graphics", "aa_mode", AAMode.FXAA)
	texture_quality= _config.get_value("Graphics", "texture_quality", TextureQuality.MEDIUM)
	effect_quality = _config.get_value("Graphics", "effect_quality", EffectQuality.MEDIUM)
	render_engine   = _config.get_value("Graphics", "render_engine", RenderEngine.VULKAN_DIMENSITY)
	look_sensitivity  = _config.get_value("Controls", "look_sensitivity", 1.0)
	ads_sensitivity   = _config.get_value("Controls", "ads_sensitivity", 0.8)
	scope_sensitivity = _config.get_value("Controls", "scope_sensitivity", 0.7)
	gyro_sensitivity  = _config.get_value("Controls", "gyro_sensitivity", 0.0)
	ui_scale = _config.get_value("UI", "ui_scale", 1.0)
	var raw = _config.get_value("KeyLayout", "layout", {})
	if raw != null:
		key_layout = raw
	print("[SettingsManager] Settings loaded")

func save_all():
	_config.set_value("Graphics", "fps_target", fps_target)
	_config.set_value("Graphics", "quality_mode", quality_mode)
	_config.set_value("Graphics", "shadow_quality", shadow_quality)
	_config.set_value("Graphics", "aa_mode", aa_mode)
	_config.set_value("Graphics", "texture_quality", texture_quality)
	_config.set_value("Graphics", "effect_quality", effect_quality)
	_config.set_value("Graphics", "render_engine", render_engine)
	_config.set_value("Controls", "look_sensitivity", look_sensitivity)
	_config.set_value("Controls", "ads_sensitivity", ads_sensitivity)
	_config.set_value("Controls", "scope_sensitivity", scope_sensitivity)
	_config.set_value("Controls", "gyro_sensitivity", gyro_sensitivity)
	_config.set_value("UI", "ui_scale", ui_scale)
	_config.set_value("KeyLayout", "layout", key_layout)
	_config.save(CONFIG_PATH)

func _reset_to_default():
	fps_target = 60
	quality_mode = QualityMode.BALANCED
	shadow_quality = ShadowQuality.MEDIUM
	aa_mode = AAMode.FXAA
	texture_quality = TextureQuality.MEDIUM
	effect_quality = EffectQuality.MEDIUM
	render_engine = RenderEngine.VULKAN_DIMENSITY
	look_sensitivity = 1.0
	ads_sensitivity = 0.8
	scope_sensitivity = 0.7
	gyro_sensitivity = 0.0
	ui_scale = 1.0
	key_layout.clear()
	save_all()

func get_render_engine_string() -> String:
	match render_engine:
		RenderEngine.OPENGL:         return "OpenGL ES 3.0"
		RenderEngine.VULKAN:         return "Vulkan (Standard)"
		RenderEngine.VULKAN_DIMENSITY: return "Vulkan (Dimensity)"
		RenderEngine.ANDROID_GENERIC: return "Android Generic (Low Quality)"
		_:                          return "Unknown"
