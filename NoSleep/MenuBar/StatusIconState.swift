import Foundation

enum StatusIconState {
    case inactive
    case activeIndefinitely
    case activeTimed
    case warning

    init(sessionState: AwakeSessionState) {
        switch sessionState {
        case .inactive:
            self = .inactive
        case .disabledDueToBattery, .disabledDueToUnplugged:
            self = .warning
        case .activeIndefinitely:
            self = .activeIndefinitely
        case .activeUntilDate:
            self = .activeTimed
        }
    }

    var systemImageName: String {
        switch self {
        case .inactive:
            "power.circle"
        case .activeIndefinitely:
            "power.circle.fill"
        case .activeTimed:
            "timer.circle.fill"
        case .warning:
            "exclamationmark.triangle.fill"
        }
    }
}
