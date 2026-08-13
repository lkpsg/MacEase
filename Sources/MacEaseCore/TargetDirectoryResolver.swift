import Foundation

public enum FinderMenuLocation: Sendable {
    case container
    case items
    case sidebar
    case toolbar
}

public struct TargetDirectoryResolver {
    private let fileManager: FileManager

    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    public func resolve(
        menuLocation: FinderMenuLocation,
        targetedURL: URL?,
        selectedItemURLs: [URL]
    ) -> URL? {
        switch menuLocation {
        case .container, .toolbar:
            return directoryRepresented(by: targetedURL)
                ?? directoryRepresented(by: selectedItemURLs.first)
        case .items, .sidebar:
            return directoryRepresented(by: selectedItemURLs.first ?? targetedURL)
        }
    }

    private func directoryRepresented(by url: URL?) -> URL? {
        guard let url else { return nil }

        let standardizedURL = url.standardizedFileURL
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(
            atPath: standardizedURL.path,
            isDirectory: &isDirectory
        ) else {
            return nil
        }

        return isDirectory.boolValue
            ? standardizedURL
            : standardizedURL.deletingLastPathComponent()
    }
}
