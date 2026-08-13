# MacEase

[English](README.md)

MacEase 为 macOS 增加轻量、原生的便捷功能，并常驻菜单栏。

## 功能

- 在 Finder 右键菜单中创建空文件。
- 在 Finder 右键菜单中创建文件夹。
- 创建项目后直接在 Finder 中原地重命名。
- 关闭窗口后继续常驻菜单栏且不占用 Dock。
- 根据 macOS 语言设置使用英文或简体中文。

## 系统要求

- macOS 13 Ventura 或更高版本
- Apple Silicon Mac

## 安装

1. 从[最新版本](https://github.com/lkpsg/MacEase/releases/latest)下载 `MacEase-vX.Y.Z-arm64.dmg`。
2. 打开 DMG，将 `MacEase.app` 拖入“应用程序”。
3. 首次启动时按住 Control 点击 MacEase，然后选择“打开”。
4. 在 MacEase 中启用 Finder 扩展，并授予辅助功能权限以自动进入原地重命名。

当前下载版本使用临时签名，尚未经过 Apple 公证。

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

在本地构建可分发的 DMG：

```bash
./scripts/build-release.sh
```

## 版本管理

MacEase 遵循[语义化版本](https://semver.org/lang/zh-CN/)，当前版本号和构建号统一保存在 `Config/Version.xcconfig`。

```bash
./scripts/set-version.sh 0.2.0
./scripts/check-version.sh
```

标签必须使用 `v主版本.次版本.修订号`；推送匹配的标签后，GitHub Actions 会自动构建并发布 Release。

## 许可证

[MIT](LICENSE)
