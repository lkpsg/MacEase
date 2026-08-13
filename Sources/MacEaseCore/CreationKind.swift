import Foundation

public enum CreationKind: String, CaseIterable, Sendable {
    case file
    case folder

    public var localizedName: String {
        switch self {
        case .file:
            NSLocalizedString(
                "core.kind.file",
                bundle: .main,
                value: "file",
                comment: "A file"
            )
        case .folder:
            NSLocalizedString(
                "core.kind.folder",
                bundle: .main,
                value: "folder",
                comment: "A folder"
            )
        }
    }
}
