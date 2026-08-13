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
            localized(
                "core.error.emptyName",
                fallback: "The name cannot be empty."
            )
        case .invalidName:
            localized(
                "core.error.invalidName",
                fallback: "The name cannot contain a slash or null character."
            )
        case .reservedName:
            localized(
                "core.error.reservedName",
                fallback: "“.” and “..” cannot be used as names."
            )
        case .targetIsNotDirectory:
            localized(
                "core.error.targetIsNotDirectory",
                fallback: "The destination is not a folder."
            )
        case let .itemAlreadyExists(name):
            String(
                format: localized(
                    "core.error.itemAlreadyExists",
                    fallback: "“%@” already exists."
                ),
                locale: .current,
                name
            )
        case .unableToCreate:
            localized(
                "core.error.unableToCreate",
                fallback: "The item could not be created. Check the folder permissions and try again."
            )
        }
    }

    private func localized(_ key: String, fallback: String) -> String {
        NSLocalizedString(
            key,
            tableName: nil,
            bundle: .main,
            value: fallback,
            comment: ""
        )
    }
}
