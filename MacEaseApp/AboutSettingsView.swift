import AppKit
import SwiftUI

struct AboutSettingsView: View {
    var body: some View {
        VStack(spacing: 14) {
            Image(nsImage: NSApplication.shared.applicationIconImage)
                .resizable()
                .frame(width: 72, height: 72)
                .accessibilityHidden(true)
            Text("MacEase")
                .font(.system(size: 26, weight: .semibold, design: .rounded))
            Text(AppVersion.description)
                .foregroundStyle(.secondary)
            Text(AppLocalization.string("settings.tagline", fallback: "Make everyday macOS tasks easier"))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Link(
                AppLocalization.string("settings.sourceCode", fallback: "Source code"),
                destination: URL(string: "https://github.com/lkpsg/MacEase")!
            )
            .padding(.top, 6)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 56)
    }
}
