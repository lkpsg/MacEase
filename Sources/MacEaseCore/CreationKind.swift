import Foundation

public enum CreationKind: String, CaseIterable, Sendable {
    case file
    case folder

    public var localizedName: String {
        switch self {
        case .file: "文件"
        case .folder: "文件夹"
        }
    }
}
