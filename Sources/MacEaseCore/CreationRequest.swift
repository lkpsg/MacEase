import Foundation

public struct CreationRequest: Equatable, Sendable {
    public static let urlScheme = "macease"

    public let kind: CreationKind
    public let directoryURL: URL

    public init(kind: CreationKind, directoryURL: URL) {
        self.kind = kind
        self.directoryURL = directoryURL.standardizedFileURL
    }

    public init?(url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              components.scheme?.lowercased() == Self.urlScheme,
              components.host?.lowercased() == "create",
              let kindValue = components.queryItems?.first(where: { $0.name == "kind" })?.value,
              let kind = CreationKind(rawValue: kindValue),
              let directoryPath = components.queryItems?.first(where: { $0.name == "directory" })?.value,
              directoryPath.hasPrefix("/") else {
            return nil
        }

        self.init(
            kind: kind,
            directoryURL: URL(fileURLWithPath: directoryPath, isDirectory: true)
        )
    }

    public var url: URL? {
        var components = URLComponents()
        components.scheme = Self.urlScheme
        components.host = "create"
        components.queryItems = [
            URLQueryItem(name: "kind", value: kind.rawValue),
            URLQueryItem(name: "directory", value: directoryURL.path)
        ]
        return components.url
    }
}
