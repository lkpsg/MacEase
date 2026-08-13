# MacEase

MacEase 是一款原生 macOS 小工具，目标是补齐日常使用中那些“本该很顺手”的操作。

当前版本实现了第一个功能：在 Finder 右键菜单中创建文件或文件夹。

## 功能

- 在 Finder 窗口空白处右键，在当前目录创建
- 右键文件，在文件所在目录创建
- 右键文件夹，在该文件夹内创建
- 创建后直接在 Finder 中原地命名
- 创建前校验名称，已有项目绝不覆盖
- 常驻菜单栏，不因创建操作弹出软件窗口
- 跟随 macOS 系统或单独应用语言，支持简体中文和英文
- 通用品牌图标，不与当前某一项功能绑定
- 原生 SwiftUI 主应用与 Finder Sync 扩展

## 系统要求

- macOS 13 Ventura 或更高版本
- Apple Silicon Mac（当前命令行构建脚本生成 `arm64` 应用）
- 完整 Xcode 15 或更高版本；仅在本机调试时也可使用 Xcode Command Line Tools
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)，用于生成 Xcode 工程和执行完整验证

## 编译与安装

### 方式一：使用完整 Xcode（推荐）

1. 从 App Store 安装 Xcode，并让命令行工具指向完整 Xcode：

   ```bash
   sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
   xcodebuild -version
   ```

2. 安装 XcodeGen、获取源码并生成工程：

   ```bash
   brew install xcodegen
   git clone https://github.com/lkpsg/MacEase.git
   cd MacEase
   xcodegen generate
   open MacEase.xcodeproj
   ```

3. 在 Xcode 中依次选择 `MacEase` 主应用和 `MacEaseFinderExtension` 扩展，在 **Signing & Capabilities** 中选择自己的 Apple Developer Team。若 Bundle Identifier 与现有应用冲突，请同时修改 `project.yml` 中主应用和扩展的标识符，再执行一次 `xcodegen generate`。
4. 选择 `MacEase` scheme 和 `My Mac`，使用 **Product > Run** 编译并运行。需要长期安装时，在 Xcode 的 Products 中找到 `MacEase.app`，复制到 `/Applications`。

### 方式二：使用命令行脚本（本机 Debug）

这套流程使用临时签名，适合在当前 Mac 上开发和调试，不适合分发给其他用户。首次准备环境：

```bash
xcode-select --install
brew install xcodegen
git clone https://github.com/lkpsg/MacEase.git
cd MacEase
```

执行完整检查、编译并安装：

```bash
./scripts/verify.sh
./scripts/install-debug-app.sh
```

安装脚本会完成以下操作：

- 编译到仓库同级的 `outputs/MacEase-Debug.app`
- 验证主应用和 Finder 扩展的代码签名
- 安装为 `/Applications/MacEase.app`
- 启动 MacEase 以便系统注册内嵌 Finder 扩展，然后重启 Finder
- 若 `/Applications/MacEase.app` 已存在，使用 `ditto` 原位更新应用内容

只编译、不安装时运行：

```bash
./scripts/build-debug-app.sh "$PWD/build"
open "$PWD/build/MacEase-Debug.app"
```

如需使用自定义输出目录，可把目录作为安装脚本的第一个参数：

```bash
./scripts/install-debug-app.sh "$PWD/build"
```

## 首次启动设置

1. 在菜单栏中点击 MacEase 图标，确认 Finder 扩展状态；如果系统尚未启用，选择“启用 Finder 扩展…”，在系统设置中打开 `MacEase Finder 扩展`。
2. 从菜单栏选择“允许 Finder 原地命名…”，按系统提示为 MacEase 授予辅助功能权限。未授权时仍会创建并选中项目，但无法自动进入改名状态。
3. 打开 Finder，在窗口空白处、文件或文件夹上右键，使用“新建文件”或“新建文件夹”。

## 语言

MacEase 支持简体中文和英文，跟随 macOS 的语言顺序。在 **系统设置 > 通用 > 语言与地区** 中调整首选语言并重新登录后，主应用、菜单栏、Finder 右键菜单和新建项目的默认名称会统一切换。

### 卸载

退出 MacEase 后执行：

```bash
pkill -x MacEase || true
pluginkit -e ignore -i com.lkpsg.MacEase.FinderExtension
osascript -e 'tell application "Finder" to delete POSIX file "/Applications/MacEase.app"'
killall Finder
```

应用会被移入废纸篓，需要时可以恢复。

## 测试

核心文件操作被拆分为独立 Swift Package，可在没有 Finder UI 的情况下做真实文件系统测试：

```bash
./scripts/verify.sh
```

测试覆盖创建文件、创建文件夹、名称校验、防覆盖，以及三种 Finder 右键目标解析规则。

## 重新生成图标资源

仓库已包含构建所需的全部图标。只有修改 `Design/MacEase-AppIcon-Master.png` 后才需要重新生成；脚本需要 Python 3 和 Pillow：

```bash
python3 -m pip install Pillow
./scripts/generate-icon-assets.sh
```

脚本会生成 Xcode Asset Catalog 的全部 App Icon 尺寸、运行时 `.icns`，以及与品牌轮廓一致的单色菜单栏模板图标。

## 设计说明

MacEase 使用 Finder Sync 扩展提供上下文菜单。扩展监控本机文件系统根目录，使菜单可以出现在本地磁盘和 `/Volumes` 下的挂载卷中。扩展自身运行在 App Sandbox 中，只负责解析目标目录并把请求交给主应用；文件创建由主应用执行。受 macOS 权限保护的目录仍遵循系统访问控制。

Finder Sync 不提供右键点击的像素坐标。MacEase 会立即在目标目录创建项目并进入原地命名，但项目在窗口或桌面上的具体图标位置由 Finder 当前的排序与布局决定。自动进入原地命名需要用户主动授予辅助功能权限；未授权时仍会正常创建并选中项目。

Finder Sync 原本主要面向同步类应用，因此未来若 Apple 提供更合适的通用 Finder 扩展接口，项目会迁移到官方推荐方案。

## License

[MIT](LICENSE)
