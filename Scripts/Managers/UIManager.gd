extends CanvasLayer

## UIManager - 管理所有 UI 面板切换
## 通过 project.godot 注册为 Autoload 单例

signal panel_opened(panel_name: String)
signal panel_closed(panel_name: String)

var _current_panel: String = "hud"

@onready var hud_panel: Control     = $HUD
@onready var settings_panel: Control = $SettingsPanel
@onready var key_edit_overlay: Control = $KeyEditOverlay

func _ready():
	_show_only("hud")

func _show_only(panel: String):
	_current_panel = panel
	if hud_panel:        hud_panel.visible        = (panel == "hud")
	if settings_panel:   settings_panel.visible   = (panel == "settings")
	if key_edit_overlay: key_edit_overlay.visible = (panel == "key_edit")

func open_settings():
	_show_only("settings")
	panel_opened.emit("settings")

func close_settings():
	_show_only("hud")
	panel_closed.emit("settings")

func open_key_editor():
	_show_only("key_edit")
	panel_opened.emit("key_edit")

func close_key_editor():
	_show_only("hud")
	panel_closed.emit("key_edit")

func _input(event: InputEvent):
	if event is InputEventKey and event.pressed and event.keycode == KEY_BACK:
		_on_back_pressed()

func _on_back_pressed():
	match _current_panel:
		"settings":    close_settings()
		"key_edit":    close_key_editor()
		_:             open_settings()
