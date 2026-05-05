import Foundation

enum DefaultDurationOption: String, CaseIterable, Identifiable {
    case untilTurnedOff
    case fifteenMinutes
    case thirtyMinutes
    case oneHour
    case twoHours
    case fourHours

    var id: String { rawValue }

    var label: String {
        switch self {
        case .untilTurnedOff:
            "Until I turn it off"
        case .fifteenMinutes:
            DurationPreset.fifteenMinutes.label
        case .thirtyMinutes:
            DurationPreset.thirtyMinutes.label
        case .oneHour:
            DurationPreset.oneHour.label
        case .twoHours:
            DurationPreset.twoHours.label
        case .fourHours:
            DurationPreset.fourHours.label
        }
    }

    var durationPreset: DurationPreset? {
        switch self {
        case .untilTurnedOff:
            nil
        case .fifteenMinutes:
            .fifteenMinutes
        case .thirtyMinutes:
            .thirtyMinutes
        case .oneHour:
            .oneHour
        case .twoHours:
            .twoHours
        case .fourHours:
            .fourHours
        }
    }
}
