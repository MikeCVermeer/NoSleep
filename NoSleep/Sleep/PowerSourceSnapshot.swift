import Foundation

enum PowerSourceState: Equatable {
    case pluggedIn
    case onBattery
    case unknown

    var description: String {
        switch self {
        case .pluggedIn:
            "Plugged in"
        case .onBattery:
            "On battery"
        case .unknown:
            "Power source unknown"
        }
    }
}

struct PowerSourceSnapshot: Equatable {
    let source: PowerSourceState
    let batteryPercentage: Int?
    let hasBattery: Bool

    static let unknown = PowerSourceSnapshot(source: .unknown, batteryPercentage: nil, hasBattery: false)

    var isPluggedIn: Bool {
        source == .pluggedIn
    }

    var isOnBattery: Bool {
        source == .onBattery
    }

    func isAtOrBelowBatteryThreshold(_ threshold: Int) -> Bool {
        guard isOnBattery, let batteryPercentage else {
            return false
        }

        return batteryPercentage <= threshold
    }
}
