import AppKit
import MacEaseCore
import OSLog

@MainActor
final class CreationRequestHandler {
    private let creationService = FileCreationService()
    private let finderRenameController = FinderRenameController()
    private let logger = Logger(subsystem: "com.lkpsg.MacEase", category: "creation")

    func handle(_ url: URL) {
        guard let request = CreationRequest(url: url) else { return }

        do {
            let defaultName = creationService.availableDefaultName(
                for: request.kind,
                in: request.directoryURL
            )
            let createdURL = try creationService.create(
                kind: request.kind,
                named: defaultName,
                in: request.directoryURL
            )
            finderRenameController.selectAndBeginRenaming(createdURL)
        } catch {
            let message = (error as? LocalizedError)?.errorDescription
                ?? FileCreationError.unableToCreate.localizedDescription
            let logMessage = String(
                format: AppLocalization.string(
                    "creation.error.log",
                    fallback: "Unable to create %@: %@"
                ),
                locale: .current,
                request.kind.localizedName,
                message
            )
            logger.error("\(logMessage, privacy: .public)")
        }
    }
}
