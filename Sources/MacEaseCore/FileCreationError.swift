import Foundation

public enum FileCreationError: Error, Equatable, LocalizedError, Sendable {
    case emptyName
    case invalidName
    case reservedName
    case targetIsNotDirectory
    case itemAlreadyExists(String)
    case unableToCreate

    public var errorDescription: String? {
        switch self {
        case .emptyName:
            "名称不能为空。"
        case .invalidName:
            "名称不能包含斜杠或空字符。"
        case .reservedName:
            "“.” 和 “..” 不能用作名称。"
        case .targetIsNotDirectory:
            "目标位置不是文件夹。"
        case let .itemAlreadyExists(name):
            "“\(name)” 已经存在。"
        case .unableToCreate:
            "无法创建项目，请检查文件夹权限后重试。"
        }
    }
}
