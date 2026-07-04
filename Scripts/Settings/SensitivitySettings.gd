# ============================================================
# SensitivitySettings.gd - 操作灵敏度设置面板
# 使用 HSlider 控制各灵敏度（0.1 ~ 5.0）
# ============================================================

class_name SensitivitySettings
extends Control

# ==================== 节点引用 ====================
@onready var slider_look:   HSlider = $VBox/RowLook/HSliderLook
@onready var label_look:    Label  = $VBox/RowLook/LabelValue
@onready var slider_ads:    HSlider = $VBox/RowADS/HSliderADS
@onready var label_ads:     Label  = $VBox/RowADS/LabelValue
@onready var slider_scope:   HSlider = $VBox/RowScope/HSliderScope
@onready var label_scope:   Label  = $VBox/RowScope/LabelValue
@onready var slider_gyro:   HSlider = $VBox/RowGyro/HSliderGyro
@onready var label_gyro:    Label  = $VBox/RowGyro/LabelValue

# ==================== 常量 ====================
const MIN_VAL: float = 0.1
const MAX_VAL: float = 5.0

# ==================== 生命周期 ====================
func _ready():
	# 设置 Slider 范围
	_set_slider_range(slider_look)
	_set_slider_range(slider_ads)
	_set_slider_range(slider_scope)
	_set_slider_range(slider_gyro)
	# 加载当前设置
	_load_settings()
	# 连接信号
	_connect_signals()

func _set_slider_range(slider: HSlider):
	slider.min_value = MIN_VAL
	slider.max_value = MAX_VAL
	slider.step       = 0.1

func _load_settings():
	if not SettingsManager.instance:
		return
	var sm = SettingsManager.instance
	slider_look.value  = sm.look_sensitivity
	slider_ads.value   = sm.ads_sensitivity
	slider_scope.value  = sm.scope_sensitivity
	slider_gyro.value  = sm.gyro_sensitivity
	_update_labels()

func _connect_signals():
	slider_look.value_changed.connect(_on_look_changed)
	slider_ads.value_changed.connect(_on_ads_changed)
	slider_scope.value_changed.connect(_on_scope_changed)
	slider_gyro.value_changed.connect(_on_gyro_changed)

# ==================== 回调 ====================
func _on_look_changed(val: float):
	if SettingsManager.instance:
		SettingsManager.instance.look_sensitivity = val
	_update_label(label_look, val)

func _on_ads_changed(val: float):
	if SettingsManager.instance:
		SettingsManager.instance.ads_sensitivity = val
	_update_label(label_ads, val)

func _on_scope_changed(val: float):
	if SettingsManager.instance:
		SettingsManager.instance.scope_sensitivity = val
	_update_label(label_scope, val)

func _on_gyro_changed(val: float):
	if SettingsManager.instance:
		SettingsManager.instance.gyro_sensitivity = val
		_update_label(label_gyro, val)

# ==================== UI 更新 ====================
func _update_labels():
	_update_label(label_look,  slider_look.value)
	_update_label(label_ads,   slider_ads.value)
	_update_label(label_scope, slider_scope.value)
	_update_label(label_gyro, slider_gyro.value)

func _update_label(label: Label, val: float):
	label.text = "%.1f" % val
