# ============================================================
# GraphicsSettings.gd - 画质设置面板逻辑
# 包含：渲染引擎切换 + 帧率 + 画质 + 阴影 + 抗锯齿 + 纹理 + 特效
# 切换渲染引擎后自动重启游戏（Android）
# ============================================================

class_name GraphicsSettings
extends Control

# ==================== 节点引用 ====================
@onready var option_render_engine: OptionButton = $VBox/RowRenderEngine/OptionRenderEngine
@onready var option_fps:            OptionButton = $VBox/RowFPS/OptionFPS
@onready var option_quality:        OptionButton = $VBox/RowQuality/OptionQuality
@onready var option_shadow:        OptionButton = $VBox/RowShadow/OptionShadow
@onready var option_aa:            OptionButton = $VBox/RowAA/OptionAA
@onready var option_texture:        OptionButton = $VBox/RowTexture/OptionTexture
@onready var option_effects:       OptionButton = $VBox/RowEffects/OptionEffects

# ==================== 选项数据 ====================
const RENDER_ENGINE_OPTIONS: Array = ["OpenGL ES 3.0", "Vulkan（标准）", "Vulkan（天玑）", "安卓通用（低画质）"]
const FPS_OPTIONS:           Array = ["30 FPS", "45 FPS", "60 FPS", "90 FPS", "120 FPS"]
const QUALITY_OPTIONS:       Array = ["流畅", "均衡", "高清", "HDR", "超高清"]
const SHADOW_OPTIONS:       Array = ["关闭", "低", "中", "高"]
const AA_OPTIONS:           Array = ["关闭", "FXAA", "MSAA 2x", "MSAA 4x", "MSAA 8x"]
const TEXTURE_OPTIONS:      Array = ["低", "中", "高"]
const EFFECT_OPTIONS:       Array = ["关闭", "低", "中", "高"]

# ==================== 生命周期 ====================
func _ready():
	_populate_options()
	_load_current_settings()
	_connect_signals()

func _populate_options():
	_add_items(option_render_engine, RENDER_ENGINE_OPTIONS)
	_add_items(option_fps,            FPS_OPTIONS)
	_add_items(option_quality,        QUALITY_OPTIONS)
	_add_items(option_shadow,         SHADOW_OPTIONS)
	_add_items(option_aa,             AA_OPTIONS)
	_add_items(option_texture,        TEXTURE_OPTIONS)
	_add_items(option_effects,        EFFECT_OPTIONS)

func _add_items(opt: OptionButton, items: Array):
	opt.clear()
	for item in items:
		opt.add_item(item)

func _load_current_settings():
	if not SettingsManager.instance:
		return
	var sm = SettingsManager.instance
	option_render_engine.select(_render_engine_to_index(sm.render_engine))
	option_fps.select(            _fps_to_index(sm.fps_target))
	option_quality.select(        sm.quality_mode)
	option_shadow.select(         sm.shadow_quality)
	option_aa.select(             _aa_to_index(sm.aa_mode))
	option_texture.select(         sm.texture_quality)
	option_effects.select(         sm.effect_quality)

func _connect_signals():
	option_render_engine.item_selected.connect(_on_render_engine_changed)
	option_fps.item_selected.connect(_on_fps_changed)
	option_quality.item_selected.connect(_on_quality_changed)
	option_shadow.item_selected.connect(_on_shadow_changed)
	option_aa.item_selected.connect(_on_aa_changed)
	option_texture.item_selected.connect(_on_texture_changed)
	option_effects.item_selected.connect(_on_effects_changed)

# ==================== 回调 ====================
func _on_render_engine_changed(idx: int):
	"""渲染引擎切换 → 保存并自动重启"""
	if SettingsManager.instance:
		SettingsManager.instance.render_engine = idx
		SettingsManager.instance._apply_render_engine()
		# 自动重启
		_restart_game()

func _on_fps_changed(idx: int):
	var fps_map: Array[int] = [30, 45, 60, 90, 120]
	if SettingsManager.instance:
		SettingsManager.instance.fps_target = fps_map[idx]
		SettingsManager.instance.apply_fps()

func _on_quality_changed(idx: int):
	if SettingsManager.instance:
		SettingsManager.instance.quality_mode = idx

func _on_shadow_changed(idx: int):
	if SettingsManager.instance:
		SettingsManager.instance.shadow_quality = idx

func _on_aa_changed(idx: int):
	if SettingsManager.instance:
		SettingsManager.instance.aa_mode = idx

func _on_texture_changed(idx: int):
	if SettingsManager.instance:
		SettingsManager.instance.texture_quality = idx

func _on_effects_changed(idx: int):
	if SettingsManager.instance:
		SettingsManager.instance.effect_quality = idx

# ==================== 自动重启 ====================
func _restart_game():
	"""切换渲染引擎后自动重启游戏"""
	# 先保存所有设置
	if SettingsManager.instance:
		SettingsManager.instance._save_all()
	# Android 平台：quit 后系统会自动重启游戏
	# PC 平台：提示用户手动重启
	if OS.get_name() == "Android":
		print("[GraphicsSettings] 渲染引擎已切换，正在重启...")
		get_tree().quit()
	else:
		print("[GraphicsSettings] 渲染引擎已切换，请手动重启游戏")

# ==================== 工具 ====================
func _fps_to_index(fps: int) -> int:
	match fps:
		30:  return 0
		45:  return 1
		60:  return 2
		90:  return 3
		120: return 4
		_:   return 2

func _aa_to_index(mode: int) -> int:
	return clamp(mode, 0, 4)

func _render_engine_to_index(engine: int) -> int:
	return clamp(engine, 0, 3)
