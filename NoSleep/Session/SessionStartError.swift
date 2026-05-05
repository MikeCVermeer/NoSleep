import Foundation

enum SessionStartError: Error, Equatable, LocalizedError {
    case invalidEndDate
    case indefiniteUnavailableOnBattery
    case batteryThresholdReached
    case batteryConfirmationRequired
    case assertionFailed(SleepAssertionError)

    var errorDescription: String? {
        switch self {
        case .invalidEndDate:
            "Choose a future time for the awake session."
        case .indefiniteUnavailableOnBattery:
            "Indefinite sessions are unavailable while your Mac is on battery."
        case .batteryThresholdReached:
            "NoSleep disabled at the configured battery threshold."
        case .batteryConfirmationRequired:
            "Confirm before running NoSleep on battery."
        case let .assertionFailed(error):
            error.localizedDescription
        }
    }
}
