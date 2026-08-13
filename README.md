# MacEase

MacEase 是一款原生 macOS 小工具，目标是补齐日常使用中那些“本该很顺手”的操作。

当前版本实现了第一个功能：在 Finder 右键菜单中创建文件或文件夹。

## 功能

- 在 Finder 窗口空白处右键，在当前目录创建
- 右键文件，在文件所在目录创建
- 右键文件夹，在该文件夹内创建
- 支持自定义文件名和扩展名
- 创建前校验名称，已有项目绝不覆盖
- 原生 SwiftUI 主应用与 Finder Sync 扩展

## 系统要求

- macOS 13 Ventura 或更高版本
- Xcode 15 或更高版本（从源码构建）

## 本地运行

1. 安装完整 Xcode，并在终端确认 `xcode-select -p` 指向 Xcode：

   ```bash
   sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
   ```

2. 打开 `MacEase.xcodeproj`，选择 `MacEase` scheme 后运行。
3. 在 MacEase 中点击“启用 Finder 扩展…”。
4. 在系统设置中启用“MacEase Finder 扩展”。
5. 打开 Finder，在空白处、文件或文件夹上右键使用。

如果修改了 `project.yml`，可使用 [XcodeGen](https://github.com/yonaskolb/XcodeGen) 重新生成工程：

```bash
brew install xcodegen
xcodegen generate
```

## 测试

核心文件操作被拆分为独立 Swift Package，可在没有 Finder UI 的情况下做真实文件系统测试：

```bash
./scripts/verify.sh
```

测试覆盖创建文件、创建文件夹、名称校验、防覆盖，以及三种 Finder 右键目标解析规则。

## 设计说明

MacEase 使用 Finder Sync 扩展提供上下文菜单。扩展监控本机文件系统根目录，使菜单可以出现在本地磁盘和 `/Volumes` 下的挂载卷中。扩展自身运行在 App Sandbox 中，只负责解析目标目录并把请求交给主应用；文件创建由主应用执行。受 macOS 权限保护的目录仍遵循系统访问控制。

Finder Sync 原本主要面向同步类应用，因此未来若 Apple 提供更合适的通用 Finder 扩展接口，项目会迁移到官方推荐方案。

## License

[MIT](LICENSE)
