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
