import Foundation

enum AwakeSessionState: Equatable {
    case inactive
    case activeIndefinitely(startedAt: Date)
    case activeUntilDate(startedAt: Date, endsAt: Date)
    case disabledDueToBattery
    case disabledDueToUnplugged

    var isActive: Bool {
        switch self {
        case .activeIndefinitely, .activeUntilDate:
            true
        case .inactive, .disabledDueToBattery, .disabledDueToUnplugged:
            false
        }
    }

    var startedAt: Date? {
        switch self {
        case let .activeIndefinitely(startedAt), let .activeUntilDate(startedAt, _):
            startedAt
        case .inactive, .disabledDueToBattery, .disabledDueToUnplugged:
            nil
        }
    }

    var endsAt: Date? {
        switch self {
        case let .activeUntilDate(_, endsAt):
            endsAt
        case .inactive, .activeIndefinitely, .disabledDueToBattery, .disabledDueToUnplugged:
            nil
        }
    }
}

