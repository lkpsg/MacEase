import Foundation

public struct DockApplication: Equatable, Sendable {
    public let url: URL
    public let name: String

    public init(url: URL, name: String) {
        self.url = url
        self.name = name
    }
}

public struct DockShortcut: Equatable, Identifiable, Sendable {
    public let position: Int
    public let application: DockApplication

    public var id: Int { position }
    public var digit: Int { position % 10 }
    public var label: String { "⌘\(digit)" }

    // Virtual key codes for the number row, in Dock order: 1…9, 0.
    public var keyCode: UInt32 {
        [18, 19, 20, 21, 23, 22, 26, 28, 25, 29][position - 1]
    }

    public static func make(applications: [DockApplication]) -> [DockShortcut] {
        applications.prefix(10).enumerated().map {
            DockShortcut(position: $0.offset + 1, application: $0.element)
        }
    }
}

public enum DockApplicationParser {
    public static let finderURL = URL(fileURLWithPath: "/System/Library/CoreServices/Finder.app")

    /// Reads only pinned application tiles. Recent apps, folders, spacers and
    /// minimized windows must not shift the stable shortcut positions.
    public static func applications(
        from tiles: [[String: Any]],
        includesFinder: Bool = false
    ) -> [DockApplication] {
        var applications: [DockApplication] = includesFinder
            ? [DockApplication(url: finderURL, name: "Finder")]
            : []
        var seen: Set<URL> = [finderURL]

        for tile in tiles {
            guard tile["tile-type"] as? String == "file-tile",
                  let data = tile["tile-data"] as? [String: Any],
                  let fileData = data["file-data"] as? [String: Any],
                  let path = fileData["_CFURLString"] as? String else {
                continue
            }

            let url: URL?
            if path.hasPrefix("/") {
                url = URL(fileURLWithPath: path)
            } else {
                url = URL(string: path)
            }
            guard let url,
                  url.isFileURL,
                  url.host == nil || url.host == "" || url.host == "localhost",
                  url.pathExtension.lowercased() == "app" else {
                continue
            }
            let normalizedURL = URL(fileURLWithPath: url.path).standardizedFileURL
            guard seen.insert(normalizedURL).inserted else { continue }

            let label = (data["file-label"] as? String)?
                .trimmingCharacters(in: .whitespacesAndNewlines)
            applications.append(DockApplication(
                url: normalizedURL,
                name: label.flatMap { $0.isEmpty ? nil : $0 }
                    ?? url.deletingPathExtension().lastPathComponent
            ))
        }
        return applications
    }
}
