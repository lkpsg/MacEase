import Foundation

public struct FileCreationService {
    private let fileManager: FileManager

    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    @discardableResult
    public func create(
        kind: CreationKind,
        named rawName: String,
        in directoryURL: URL
    ) throws -> URL {
        let name = try validatedName(rawName)
        let directory = directoryURL.standardizedFileURL

        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: directory.path, isDirectory: &isDirectory),
              isDirectory.boolValue else {
            throw FileCreationError.targetIsNotDirectory
        }

        let destination = directory
            .appendingPathComponent(name, isDirectory: kind == .folder)
            .standardizedFileURL

        guard destination.deletingLastPathComponent() == directory else {
            throw FileCreationError.invalidName
        }

        if fileManager.fileExists(atPath: destination.path) {
            throw FileCreationError.itemAlreadyExists(name)
        }

        do {
            switch kind {
            case .file:
                try Data().write(to: destination, options: .withoutOverwriting)
            case .folder:
                try fileManager.createDirectory(
                    at: destination,
                    withIntermediateDirectories: false
                )
            }
        } catch CocoaError.fileWriteFileExists {
            throw FileCreationError.itemAlreadyExists(name)
        } catch {
            throw FileCreationError.unableToCreate
        }

        return destination
    }

    public func validatedName(_ rawName: String) throws -> String {
        let name = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            throw FileCreationError.emptyName
        }
        guard name != ".", name != ".." else {
            throw FileCreationError.reservedName
        }
        guard !name.contains("/"), !name.contains("\0") else {
            throw FileCreationError.invalidName
        }
        return name
    }
}
