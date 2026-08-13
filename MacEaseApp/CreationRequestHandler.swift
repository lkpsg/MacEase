import AppKit
import MacEaseCore

@MainActor
final class CreationRequestHandler {
    private let creationService = FileCreationService()

    func handle(_ url: URL) {
        guard let request = CreationRequest(url: url) else {
            presentError("收到的创建请求无效。")
            return
        }

        NSApplication.shared.activate(ignoringOtherApps: true)
        var proposedName = request.kind == .file ? "未命名文件.txt" : "未命名文件夹"

        while let name = requestName(
            for: request.kind,
            in: request.directoryURL,
            initialValue: proposedName
        ) {
            do {
                let createdURL = try creationService.create(
                    kind: request.kind,
                    named: name,
                    in: request.directoryURL
                )
                NSWorkspace.shared.activateFileViewerSelecting([createdURL])
                return
            } catch {
                presentError(
                    (error as? LocalizedError)?.errorDescription
                        ?? FileCreationError.unableToCreate.localizedDescription
                )
                proposedName = name
            }
        }
    }

    private func requestName(
        for kind: CreationKind,
        in directory: URL,
        initialValue: String
    ) -> String? {
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = "创建新\(kind.localizedName)"
        alert.informativeText = "位置：\(directory.path)"
        alert.addButton(withTitle: "创建")
        alert.addButton(withTitle: "取消")

        let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 360, height: 24))
        textField.stringValue = initialValue
        textField.placeholderString = kind == .file ? "例如：笔记.md" : "例如：新项目"
        alert.accessoryView = textField
        alert.window.initialFirstResponder = textField

        guard alert.runModal() == .alertFirstButtonReturn else { return nil }
        return textField.stringValue
    }

    private func presentError(_ message: String) {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "无法创建"
        alert.informativeText = message
        alert.addButton(withTitle: "好")
        alert.runModal()
    }
}
