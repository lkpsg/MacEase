import FinderSync
import SwiftUI

struct ContentView: View {
    @State private var extensionIsEnabled = FIFinderSyncController.isExtensionEnabled
    @State private var accessibilityIsGranted = FinderRenameController().isAccessibilityGranted

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack(spacing: 16) {
                Image(nsImage: NSApplication.shared.applicationIconImage)
                    .resizable()
                    .frame(width: 72, height: 72)

                VStack(alignment: .leading, spacing: 5) {
                    Text("MacEase")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                    Text("让 macOS 的日常操作更顺手")
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 14) {
                Label("Finder 右键创建", systemImage: "folder.badge.plus")
                    .font(.headline)

                Text("右键后立即创建项目，并直接在 Finder 中进入原地命名。不会打开 MacEase 窗口。")
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 8) {
                    Circle()
                        .fill(extensionIsEnabled ? Color.green : Color.orange)
                        .frame(width: 9, height: 9)
                    Text(extensionIsEnabled ? "Finder 扩展已启用" : "需要启用 Finder 扩展")
                        .fontWeight(.medium)
                }
            }

            Button(extensionIsEnabled ? "管理 Finder 扩展…" : "启用 Finder 扩展…") {
                FIFinderSyncController.showExtensionManagementInterface()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            HStack(spacing: 12) {
                Label(
                    accessibilityIsGranted ? "Finder 原地命名已启用" : "需要辅助功能权限以自动进入命名",
                    systemImage: accessibilityIsGranted ? "checkmark.circle.fill" : "exclamationmark.circle"
                )
                .foregroundStyle(accessibilityIsGranted ? .green : .secondary)

                Spacer()

                if !accessibilityIsGranted {
                    Button("允许…") {
                        accessibilityIsGranted = FinderRenameController()
                            .requestAccessibilityPermission()
                    }
                }
            }

            Text("首次使用时，请在打开的系统设置中启用“MacEase Finder 扩展”。")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(32)
        .frame(width: 500)
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            extensionIsEnabled = FIFinderSyncController.isExtensionEnabled
            accessibilityIsGranted = FinderRenameController().isAccessibilityGranted
        }
    }
}
