# MacEase

[English](README.md)

MacEase 为 macOS 增加轻量、原生的便捷功能，并常驻菜单栏。

## 功能

- 在 Finder 右键菜单中创建空文件。
- 在 Finder 右键菜单中创建文件夹。
- 创建项目后直接在 Finder 中原地重命名。
- 关闭窗口后继续常驻菜单栏且不占用 Dock。
- 分别为触摸板和鼠标滚轮设置自然滚动或反向滚动。
- 使用 Command + 数字打开或切换到 Dock 中对应的固定应用。
- 将 Command + I/J/K/L 映射为上、左、下、右方向键。
- 根据 macOS 语言设置使用英文或简体中文。
- 按功能分组的侧边栏设置界面，可调整窗口大小并记住上次访问的页面。

## 系统要求

- macOS 13 Ventura 或更高版本
- Apple Silicon Mac

## 安装

1. 从[最新版本](https://github.com/lkpsg/MacEase/releases/latest)下载 `MacEase-vX.Y.Z-arm64.dmg`。
2. 打开 DMG，将 `MacEase.app` 拖入“应用程序”。
3. 首次启动时按住 Control 点击 MacEase，然后选择“打开”。
4. 在 MacEase 的“权限与扩展”中启用 Finder 扩展，并授予辅助功能权限以使用原地重命名、滚动方向控制和键盘映射。

当前下载版本使用临时签名，尚未经过 Apple 公证。

## 设置

在左侧选择 Finder、滚动方向、Dock 应用快捷键或键盘映射，右侧显示对应功能的设置。详细说明默认折叠，缺少权限或快捷键冲突时才会显示提示。“权限与扩展”集中管理系统授权，“关于 MacEase”显示版本信息。

窗口会记住上次访问的页面、大小和位置。菜单栏提供滚动方向、Dock 快捷键和键盘映射的快速开关，以及打开设置和退出入口。

## Dock 应用快捷键

在设置或菜单栏中开启“Dock 应用快捷键”，即可使用 `⌘1`–`⌘9` 打开或切换到 Dock 中前九个固定应用，`⌘0` 对应第十个应用。默认从 Finder 后的第一个固定应用开始编号，也可在设置中勾选“将 Finder 计为第一个应用”。设置中会显示当前快捷键与应用的对应关系。

拖动、添加或移除 Dock 中的固定应用后，映射会自动更新；最近使用的应用、文件夹和分隔符不参与编号。功能无需辅助功能权限，默认关闭。开启后，这些快捷键会优先于当前应用的同名快捷键；没有对应应用的数字不占用，关闭功能即释放快捷键。

如果设置显示快捷键不可用，请退出 Snap 等占用相同快捷键的应用，MacEase 会自动重试。

## 键盘映射

在设置或菜单栏中开启“键盘映射”，即可在各应用中使用 `⌘I` → `↑`、`⌘J` → `←`、`⌘K` → `↓`、`⌘L` → `→`。映射输出普通方向键，不保留 Command 修饰键，长按可连续移动。

功能需要辅助功能权限，默认关闭。按键对应键盘上 I/J/K/L 的物理位置，不受输入法切换影响。仅搭配 Command 时映射，同时按下 Shift、Option、Control 或 Fn 的组合保留原有行为。开启后会替代当前应用的这四个同名快捷键，关闭后恢复。安全输入框可能阻止 macOS 向 MacEase 提供键盘事件。

## 从源码构建

安装 Xcode Command Line Tools 和 XcodeGen，然后运行：

```bash
xcode-select --install
brew install xcodegen
git clone https://github.com/lkpsg/MacEase.git
cd MacEase
./scripts/verify.sh
./scripts/install-debug-app.sh
```

`verify.sh` 已包含键盘映射测试，覆盖按下/松开、修饰键、长按重复、中途关闭和原生文本光标移动。也可单独运行 `./scripts/test-keyboard-mapping.sh`；测试无需辅助功能权限，不会向其他应用发送按键。

若要进一步验证 macOS 系统事件流，请先退出 MacEase 和其他键盘映射工具，再在已登录且具备辅助功能和事件投递权限的桌面环境中运行以下命令。测试由独立进程发送带标记的事件，并在送达应用前截获；测试偏好设置与现有 MacEase 设置隔离。

```bash
./scripts/test-keyboard-mapping.sh --post-key-events
```

在已登录的 macOS 桌面上退出 MacEase、Snap 等快捷键工具后，可运行系统快捷键集成测试：

```bash
./scripts/test-dock-shortcuts.sh
# 同时测试真实键盘事件投递，需要终端具备事件投递权限：
./scripts/test-dock-shortcuts.sh --post-key-events
```

在本地构建可分发的 DMG：

```bash
./scripts/build-release.sh
```

## 版本管理

MacEase 遵循[语义化版本](https://semver.org/lang/zh-CN/)，当前版本号和构建号统一保存在 `Config/Version.xcconfig`。

```bash
./scripts/set-version.sh 0.3.1
./scripts/check-version.sh
```

标签必须使用 `v主版本.次版本.修订号`；推送匹配的标签后，GitHub Actions 会自动构建并发布 Release。

## 许可证

[MIT](LICENSE)
