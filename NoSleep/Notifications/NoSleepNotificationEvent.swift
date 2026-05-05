import Foundation

enum NoSleepNotificationEvent: String, Equatable {
    case timerEnded
    case batteryLowDisabled
    case unpluggedWhileActive
    case autoDisabledWhenUnplugged

    var identifier: String {
        "nosleep.notification.\(rawValue)"
    }

    var title: String {
        switch self {
        case .timerEnded:
            "NoSleep timer ended"
        case .batteryLowDisabled:
            "NoSleep disabled"
        case .unpluggedWhileActive:
            "NoSleep is still active"
        case .autoDisabledWhenUnplugged:
            "NoSleep disabled"
        }
    }

    var body: String {
        switch self {
        case .timerEnded:
            "NoSleep timer ended. Your Mac can sleep normally again."
        case .batteryLowDisabled:
            "NoSleep disabled at the configured battery threshold."
        case .unpluggedWhileActive:
            "NoSleep is still active on battery."
        case .autoDisabledWhenUnplugged:
            "NoSleep disabled because your Mac was unplugged."
        }
    }
}
