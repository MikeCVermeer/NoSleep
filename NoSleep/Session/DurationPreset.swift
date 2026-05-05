import Foundation

enum DurationPreset: Int, CaseIterable, Identifiable {
    case fifteenMinutes = 15
    case thirtyMinutes = 30
    case oneHour = 60
    case twoHours = 120
    case fourHours = 240

    var id: Int { rawValue }

    var minutes: Int { rawValue }

    var timeInterval: TimeInterval {
        TimeInterval(minutes * 60)
    }

    var label: String {
        switch self {
        case .fifteenMinutes:
            "15 minutes"
        case .thirtyMinutes:
            "30 minutes"
        case .oneHour:
            "1 hour"
        case .twoHours:
            "2 hours"
        case .fourHours:
            "4 hours"
        }
    }

    func endDate(startingAt startDate: Date) -> Date {
        startDate.addingTimeInterval(timeInterval)
    }
}

