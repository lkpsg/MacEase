import FinderSync
import SwiftUI

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var extensionIsEnabled = FIFinderSyncController.isExtensionEnabled
    private let creationRequestHandler = CreationRequestHandler()

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack(spacing: 16) {
                Image(systemName: "cursorarrow.click.2")
                    .font(.system(size: 34, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 64, height: 64)
                    .background(
                        LinearGradient(
                            colors: [.indigo, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                    )

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

                Text("在 Finder 的空白处、文件或文件夹上右键，即可创建新文件或新文件夹。")
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

            Text("首次使用时，请在打开的系统设置中启用“MacEase Finder 扩展”。")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(32)
        .frame(width: 500)
        .onChange(of: scenePhase) { phase in
            if phase == .active {
                extensionIsEnabled = FIFinderSyncController.isExtensionEnabled
            }
        }
        .onOpenURL { url in
            creationRequestHandler.handle(url)
        }
    }
}
