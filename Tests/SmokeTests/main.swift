import Foundation
import MacEaseCore

struct SmokeTestFailure: Error, CustomStringConvertible {
    let description: String
}

@main
@MainActor
enum SmokeTests {
    private static let service = FileCreationService()
    private static let resolver = TargetDirectoryResolver()
    private static var passed = 0

    static func main() throws {
        try run("创建空文件并保留扩展名", testCreateFile)
        try run("创建文件夹", testCreateFolder)
        try run("清理名称首尾空白", testTrimmedName)
        try run("不覆盖已有文件", { try testDuplicate(.file) })
        try run("不覆盖已有文件夹", { try testDuplicate(.folder) })
        try run("拒绝空名称", { try testInvalidName("") })
        try run("拒绝路径分隔符", { try testInvalidName("nested/file") })
        try run("拒绝保留名称", { try testInvalidName("..") })
        try run("拒绝将文件作为目标目录", testNonDirectoryTarget)
        try run("右键文件夹时定位到文件夹内", testSelectedFolderResolution)
        try run("右键文件时定位到父目录", testSelectedFileResolution)
        try run("右键空白处时定位到当前目录", testContainerResolution)
        try run("创建请求 URL 可无损往返", testCreationRequestRoundTrip)
        try run("默认名称自动避让已存在项目", testAvailableDefaultNames)
        try run("连续滚动事件识别为触摸板", testContinuousScrollInput)
        try run("离散滚动事件识别为鼠标滚轮", testDiscreteScrollInput)
        try run("自然滚动方向决策", testNaturalScrollDecision)
        try run("反向滚动方向决策", testReversedScrollDecision)
        try run("Dock 仅按顺序读取固定应用", testDockApplicationParsing)
        try run("Dock 支持可选 Finder 编号且不重复", testDockFinder)
        try run("Dock 支持中文、空格和旧式路径", testDockPaths)
        try run("Dock 忽略非法项目及重复应用", testInvalidDockTiles)
        try run("Dock 前十个应用映射到 1–9 和 0", testDockShortcutNumbers)
        try run("Dock 重排和移除更新快捷键", testDockReordering)

        print("\n✅ MacEaseCore 冒烟测试通过：\(passed)/\(passed)")
    }

    private static func run(_ name: String, _ test: () throws -> Void) throws {
        do {
            try test()
            passed += 1
            print("✓ \(name)")
        } catch {
            print("✗ \(name): \(error)")
            throw error
        }
    }

    private static func testCreateFile() throws {
        try withFixture { root, _, _ in
            let result = try service.create(kind: .file, named: "notes.md", in: root)
            try expect(FileManager.default.fileExists(atPath: result.path), "文件不存在")
            try expect(try Data(contentsOf: result).isEmpty, "新文件不是空文件")
            try expect(result.lastPathComponent == "notes.md", "扩展名发生变化")
        }
    }

    private static func testCreateFolder() throws {
        try withFixture { root, _, _ in
            let result = try service.create(kind: .folder, named: "资料", in: root)
            var isDirectory: ObjCBool = false
            try expect(
                FileManager.default.fileExists(atPath: result.path, isDirectory: &isDirectory),
                "文件夹不存在"
            )
            try expect(isDirectory.boolValue, "创建结果不是文件夹")
        }
    }

    private static func testTrimmedName() throws {
        try withFixture { root, _, _ in
            let result = try service.create(kind: .file, named: "  todo.txt\n", in: root)
            try expect(result.lastPathComponent == "todo.txt", "未清理首尾空白")
        }
    }

    private static func testDuplicate(_ kind: CreationKind) throws {
        try withFixture { root, _, _ in
            _ = try service.create(kind: kind, named: "Existing", in: root)
            do {
                _ = try service.create(kind: kind, named: "Existing", in: root)
                throw SmokeTestFailure(description: "重复项目被覆盖")
            } catch FileCreationError.itemAlreadyExists("Existing") {
                return
            }
        }
    }

    private static func testInvalidName(_ name: String) throws {
        try withFixture { root, _, _ in
            do {
                _ = try service.create(kind: .file, named: name, in: root)
                throw SmokeTestFailure(description: "非法名称被接受：\(name)")
            } catch is FileCreationError {
                return
            }
        }
    }

    private static func testNonDirectoryTarget() throws {
        try withFixture { _, _, file in
            do {
                _ = try service.create(kind: .file, named: "new", in: file)
                throw SmokeTestFailure(description: "文件被当作目录")
            } catch FileCreationError.targetIsNotDirectory {
                return
            }
        }
    }

    private static func testSelectedFolderResolution() throws {
        try withFixture { root, folder, _ in
            let result = resolver.resolve(
                menuLocation: .items,
                targetedURL: folder,
                selectedItemURLs: [folder]
            )
            try expect(result == folder.standardizedFileURL, "未定位到选中文件夹")
            try expect(result != root.standardizedFileURL, "错误定位到父目录")
        }
    }

    private static func testSelectedFileResolution() throws {
        try withFixture { root, _, file in
            let result = resolver.resolve(
                menuLocation: .items,
                targetedURL: file,
                selectedItemURLs: [file]
            )
            try expect(result == root.standardizedFileURL, "未定位到文件的父目录")
        }
    }

    private static func testContainerResolution() throws {
        try withFixture { root, _, _ in
            let result = resolver.resolve(
                menuLocation: .container,
                targetedURL: root,
                selectedItemURLs: []
            )
            try expect(result == root.standardizedFileURL, "未定位到当前目录")
        }
    }

    private static func testCreationRequestRoundTrip() throws {
        try withFixture { root, _, _ in
            let request = CreationRequest(kind: .file, directoryURL: root)
            let parsed = request.url.flatMap(CreationRequest.init(url:))
            try expect(parsed == request, "创建请求 URL 往返失败")
        }
    }

    private static func testAvailableDefaultNames() throws {
        try withFixture { root, _, _ in
            let firstFileName = service.availableDefaultName(for: .file, in: root)
            let firstFolderName = service.availableDefaultName(for: .folder, in: root)
            _ = try service.create(kind: .file, named: firstFileName, in: root)
            _ = try service.create(kind: .folder, named: firstFolderName, in: root)
            try expect(
                service.availableDefaultName(for: .file, in: root)
                    == firstFileName.replacingOccurrences(of: ".txt", with: " 2.txt"),
                "文件默认名称未避让"
            )
            try expect(
                service.availableDefaultName(for: .folder, in: root) == "\(firstFolderName) 2",
                "文件夹默认名称未避让"
            )
        }
    }

    private static func testContinuousScrollInput() throws {
        try expect(
            ScrollInputKind(usesContinuousDeltas: true) == .trackpad,
            "连续滚动事件未识别为触摸板"
        )
    }

    private static func testDiscreteScrollInput() throws {
        try expect(
            ScrollInputKind(usesContinuousDeltas: false) == .mouseWheel,
            "离散滚动事件未识别为鼠标滚轮"
        )
    }

    private static func testNaturalScrollDecision() throws {
        try expect(
            !ScrollDirectionDecision.shouldReverseEvent(
                systemUsesNaturalDirection: true,
                preferredDirection: .natural
            ),
            "系统已自然滚动时不应反转"
        )
        try expect(
            ScrollDirectionDecision.shouldReverseEvent(
                systemUsesNaturalDirection: false,
                preferredDirection: .natural
            ),
            "系统为传统滚动时应反转为自然滚动"
        )
    }

    private static func testReversedScrollDecision() throws {
        try expect(
            ScrollDirectionDecision.shouldReverseEvent(
                systemUsesNaturalDirection: true,
                preferredDirection: .reversed
            ),
            "系统为自然滚动时应执行反向滚动"
        )
        try expect(
            !ScrollDirectionDecision.shouldReverseEvent(
                systemUsesNaturalDirection: false,
                preferredDirection: .reversed
            ),
            "系统已是反向滚动时不应再次反转"
        )
    }

    private static func dockTile(_ path: String, name: String? = nil, type: String = "file-tile") -> [String: Any] {
        var data: [String: Any] = ["file-data": ["_CFURLString": path]]
        if let name { data["file-label"] = name }
        return ["tile-type": type, "tile-data": data]
    }

    private static func testDockApplicationParsing() throws {
        let apps = DockApplicationParser.applications(from: [
            dockTile("file:///Applications/Safari.app/", name: "Safari"),
            dockTile("file:///Applications/Spacer.app", type: "spacer-tile"),
            dockTile("file:///Users/test/Downloads/"),
            dockTile("file:///Applications/Mail.app/", name: "Mail"),
        ])
        try expect(apps.map(\.name) == ["Safari", "Mail"], "Dock 应用顺序或过滤不正确")
        try expect(apps[0].url.path == "/Applications/Safari.app", "应用路径不正确")
    }

    private static func testDockFinder() throws {
        let tiles = [
            dockTile("file:///System/Library/CoreServices/Finder.app/", name: "Finder"),
            dockTile("file:///Applications/Mail.app/", name: "Mail"),
        ]
        try expect(DockApplicationParser.applications(from: tiles).map(\.name) == ["Mail"], "默认应跳过 Finder")
        let apps = DockApplicationParser.applications(from: tiles, includesFinder: true)
        try expect(apps.map(\.name) == ["Finder", "Mail"], "Finder 应只在首位出现一次")
    }

    private static func testDockPaths() throws {
        let path = "/Applications/测试 App #1.app"
        let apps = DockApplicationParser.applications(from: [
            dockTile(URL(fileURLWithPath: path).absoluteString),
            dockTile("/Applications/Legacy App.app", name: "  "),
        ])
        try expect(apps.map(\.name) == ["测试 App #1", "Legacy App"], "缺少名称时未从路径读取名称")
        try expect(apps.first?.url.path == path, "编码后的 URL 解析失败")
    }

    private static func testInvalidDockTiles() throws {
        let apps = DockApplicationParser.applications(from: [
            [:], ["tile-type": "file-tile"],
            dockTile("https://example.com/Remote.app"),
            dockTile("file://remote/Applications/Remote.app"),
            dockTile("Relative.app"),
            dockTile(""),
            dockTile("file:///Applications/Mail.app/"),
            dockTile("file:///Applications/Mail.app"),
        ])
        try expect(apps.map(\.name) == ["Mail"], "非法或重复项目未被忽略")
    }

    private static func testDockShortcutNumbers() throws {
        let apps = (1...12).map {
            DockApplication(url: URL(fileURLWithPath: "/Applications/App\($0).app"), name: "App\($0)")
        }
        let shortcuts = DockShortcut.make(applications: apps)
        try expect(shortcuts.count == 10, "只能为前十个应用分配数字快捷键")
        try expect(shortcuts.map(\.digit) == [1, 2, 3, 4, 5, 6, 7, 8, 9, 0], "数字顺序错误")
        try expect(shortcuts.map(\.keyCode) == [18, 19, 20, 21, 23, 22, 26, 28, 25, 29], "物理按键映射错误")
        try expect(shortcuts.last?.application.name == "App10", "⌘0 应映射到第十个应用")
        try expect(DockShortcut.make(applications: []).isEmpty, "空 Dock 不应注册快捷键")
    }

    private static func testDockReordering() throws {
        let first = dockTile("file:///Applications/First.app")
        let second = dockTile("file:///Applications/Second.app")
        let before = DockShortcut.make(applications: DockApplicationParser.applications(from: [first, second]))
        let after = DockShortcut.make(applications: DockApplicationParser.applications(from: [second, first]))
        let removed = DockShortcut.make(applications: DockApplicationParser.applications(from: [second]))
        try expect(before[0].application.name == "First", "初始映射错误")
        try expect(after[0].application.name == "Second", "重排未生效")
        try expect(removed.count == 1 && removed[0].digit == 1, "移除应用后映射错误")
    }

    private static func expect(_ condition: @autoclosure () throws -> Bool, _ message: String) throws {
        if try !condition() {
            throw SmokeTestFailure(description: message)
        }
    }

    private static func withFixture(
        _ body: (URL, URL, URL) throws -> Void
    ) throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let folder = root.appendingPathComponent("folder", isDirectory: true)
        let file = root.appendingPathComponent("file.txt")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        try Data().write(to: file)
        defer { try? FileManager.default.removeItem(at: root) }
        try body(root, folder, file)
    }
}
