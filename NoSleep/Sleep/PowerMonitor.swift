import Combine
import Foundation
import IOKit.ps

@MainActor
final class PowerMonitor: ObservableObject, PowerMonitoring {
    @Published private(set) var snapshot: PowerSourceSnapshot

    private var timer: Timer?
    private let pollInterval: TimeInterval

    var snapshotPublisher: AnyPublisher<PowerSourceSnapshot, Never> {
        $snapshot.eraseToAnyPublisher()
    }

    init(pollInterval: TimeInterval = 30, startAutomatically: Bool = true) {
        self.pollInterval = pollInterval
        snapshot = Self.readSnapshot()

        if startAutomatically {
            start()
        }
    }

    deinit {
        timer?.invalidate()
    }

    func refresh() {
        snapshot = Self.readSnapshot()
    }

    private func start() {
        timer = Timer.scheduledTimer(withTimeInterval: pollInterval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.refresh()
            }
        }
    }

    private static func readSnapshot() -> PowerSourceSnapshot {
        guard let info = IOPSCopyPowerSourcesInfo()?.takeRetainedValue() else {
            return .unknown
        }

        let source = readPowerSourceState(from: info)
        let battery = readBattery(from: info)

        return PowerSourceSnapshot(
            source: source,
            batteryPercentage: battery.percentage,
            hasBattery: battery.hasBattery
        )
    }

    private static func readPowerSourceState(from info: CFTypeRef) -> PowerSourceState {
        guard let sourceType = IOPSGetProvidingPowerSourceType(info)?.takeUnretainedValue() as String? else {
            return .unknown
        }

        switch sourceType {
        case kIOPSACPowerValue:
            return .pluggedIn
        case kIOPSBatteryPowerValue:
            return .onBattery
        default:
            return .unknown
        }
    }

    private static func readBattery(from info: CFTypeRef) -> (percentage: Int?, hasBattery: Bool) {
        guard let sources = IOPSCopyPowerSourcesList(info)?.takeRetainedValue() as? [CFTypeRef] else {
            return (nil, false)
        }

        for source in sources {
            guard let description = IOPSGetPowerSourceDescription(info, source)?
                .takeUnretainedValue() as? [String: Any]
            else {
                continue
            }

            let isPresent = description[kIOPSIsPresentKey as String] as? Bool ?? true
            guard isPresent else {
                continue
            }

            let currentCapacity = description[kIOPSCurrentCapacityKey as String] as? Int
            let maxCapacity = description[kIOPSMaxCapacityKey as String] as? Int

            guard let currentCapacity, let maxCapacity, maxCapacity > 0 else {
                return (nil, true)
            }

            let percentage = Int((Double(currentCapacity) / Double(maxCapacity) * 100).rounded())
            return (min(max(percentage, 0), 100), true)
        }

        return (nil, false)
    }
}
