import Foundation

enum SleepAssertionError: Error, Equatable, LocalizedError {
    case createFailed(kind: PowerAssertionKind, code: Int32)
    case releaseFailed(id: PowerAssertionID, code: Int32)

    var errorDescription: String? {
        switch self {
        case let .createFailed(kind, code):
            "Failed to create \(kind.assertionName) assertion. IOKit code: \(code)."
        case let .releaseFailed(id, code):
            "Failed to release power assertion \(id). IOKit code: \(code)."
        }
    }
}

