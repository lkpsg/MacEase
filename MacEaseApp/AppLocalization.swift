import Foundation

enum AppLocalization {
    static func string(_ key: String, fallback: String) -> String {
        NSLocalizedString(
            key,
            tableName: nil,
            bundle: .main,
            value: fallback,
            comment: ""
        )
    }
}
