import Foundation

enum SleepWakeBehavior: String, CaseIterable, Identifiable {
    case turnOffOnSleep
    case resumeAfterWake
    case keepPreviousState

    var id: String { rawValue }

    var label: String {
        switch self {
        case .turnOffOnSleep:
            "Turn NoSleep off"
        case .resumeAfterWake:
            "Resume NoSleep after wake"
        case .keepPreviousState:
            "Keep previous state"
        }
    }
}
