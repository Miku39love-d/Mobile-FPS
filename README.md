# Mobile FPS - Godot 4.4 手机端 3D FPS 游戏
# 项目使用说明

## 环境配置

### 渲染后端（已配置，适合天玑 900）
- 渲染方式：`Mobile`（Vulkan 移动版）
- 适配：Mali-G68 MC4（Honor 50 SE）
- 修改方式：Project Settings → Rendering → Renderer → Mobile

### 项目设置已包含
- ✅ 横屏锁定（`display/handheld/orientation=0`）
- ✅ 全屏（`window/size/fullscreen=true`）
- ✅ Vulkan 驱动（`rendering_method.mobile/rendering_driver="vulkan"`）
- ✅ 前向渲染（`Mobile` 后端）

---

## 如何导入项目

1. 下载 `FPSProject.zip`
2. 解压到任意目录
3. 打开 **Godot 4.4**
4. 点击「导入」（Import）
5. 选择解压后的 `project.godot`
6. 点击「编辑」（Edit）

---

## 如何导出 Android APK

### 第一步：安装 Android 构建模板
在 Godot 中：
1. `项目(Project)` → `安装 Android 构建模板(Install Android Build Template)`
2. 等待下载完成

### 第二步：配置 Android SDK
1. `编辑器设置(Editor Settings)` → `导出(Export)` → `Android`
2. 设置以下路径（如未安装，可用 Godot 自带的 `Android SDK`）：
   - `android_sdk_path`
   - `jarsigner_path`
   - `adb_path`

### 第三步：一键导出
1. `项目(Project)` → `导出(Export)`
2. 点击「添加(Add)」→ 选择 `Android`
3. 填写：
   - `Package Name`：`com.fps.mobile`
   - `Version Code`：`1`
   - `Version String`：`1.0`
   - `Icon`：选择 `icon.svg`
4. 点击「导出(Export)」→ 选择输出 APK 路径

---

## 场景结构（Main.tscn）

```
World (Node3D)                  ← 主场景根节点
├── DirectionalLight3D         ← 方向光
├── Ground (StaticBody3D)      ← 地面（碰撞 + 网格）
│   ├── CollisionShape3D
│   └── MeshInstance3D
├── Player (CharacterBody3D)    ← 玩家控制器
│   ├── CollisionShape3D       ← 碰撞胶囊
│   └── Camera3D              ← 第一人称相机（FOV 75）
└── UI (CanvasLayer)            ← UI 层
    ├── HUD (Control)          ← 游戏 HUD
    │   ├── JoystickArea       ← 左侧摇杆区域
    │   ├── LookArea          ← 右侧视角区域
    │   └── SettingsButton    ← 设置按钮
    ├── KeyEditOverlay          ← 键位编辑遮罩层
    │   ├── Overlay           ← 半透明黑色遮罩
    │   ├── InfoLabel         ← 键位信息显示
    │   ├── BtnSave          ← 保存按钮
    │   ├── BtnReset         ← 重置按钮
    │   └── BtnCancel        ← 取消按钮
    └── SettingsPanel          ← 设置面板
        ├── TabContainer      ← 标签页
        │   ├── Graphics     ← 画质设置
        │   └── Controls     ← 操作设置
        └── BtnClose         ← 关闭按钮
```

---

## 脚本功能清单

| 脚本 | 功能 |
|------|------|
| `Scripts/Managers/SettingsManager.gd` | 统一管理所有设置，ConfigFile 持久化 |
| `Scripts/Managers/InputManager.gd`   | 处理触摸输入，摇杆 + 视角 |
| `Scripts/Managers/UIManager.gd`       | UI 面板切换管理 |
| `Scripts/Managers/GameManager.gd`     | 游戏状态管理 |
| `Scripts/Player/PlayerController.gd`  | 第一人称移动 + 视角控制 |
| `Scripts/UI/JoystickUI.gd`           | 虚拟摇杆 UI 绘制 |
| `Scripts/Settings/SettingsPanel.gd`   | 设置面板逻辑 |
| `Scripts/Settings/KeyEditor.gd`       | 键位编辑器核心 |
| `Scripts/Settings/GraphicsSettings.gd`| 画质设置 UI |
| `Scripts/Settings/SensitivitySettings.gd` | 灵敏度设置 UI |
| `Resources/DefaultKeyLayout.gd`       | 默认键位数据 |

---

## 下一步扩展建议

1. **射击功能**：在 `PlayerController.gd` 中添加 `fire()` 方法
2. **武器系统**：新增 `Weapon.gd`，挂载在 `Player` 下
3. **敌人 AI**：新增 `Enemy.gd`，使用 `NavigationAgent3D`
4. **背包系统**：在 `UI` 下新增 `InventoryPanel`
5. **联网**：使用 `MultiplayerSynchronizer` 节点

---

## 已知问题

- [ ] 场景文件中部分 `ExtResource` 的 UID 是占位符，需在 Godot 中重新关联脚本
- [ ] `CollisionShape3D` 的 `shape` 属性为 `null`，需在编辑器中分配 `CapsuleShape3D` / `BoxShape3D`
- [ ] Android 导出需本地配置 SDK，无法在服务器完成

---

## 联系人

- 开发者：WorkBuddy AI
- 项目类型：Godot 4.4 手机端 3D FPS
- 目标设备：Honor 50 SE（天玑 900 / Mali-G68 MC4）
