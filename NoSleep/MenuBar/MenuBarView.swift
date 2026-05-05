import AppKit
import SwiftUI

struct MenuBarView: View {
    @ObservedObject var sessionController: SessionController
    @ObservedObject var powerMonitor: PowerMonitor
    @ObservedObject var settings: SettingsStore

    @Environment(\.openSettings) private var openSettings
    @Environment(\.openWindow) private var openWindow
    @State private var pendingBatteryStart: PendingBatteryStart?

    var body: some View {
        VStack(alignment: .leading) {
            Text("NoSleep")
                .font(.headline)

            Divider()

            if let pendingBatteryStart {
                batteryConfirmationMenu(for: pendingBatteryStart)
            } else {
                switch sessionController.state {
                case .inactive:
                    inactiveMenu
                case let .activeIndefinitely(startedAt):
                    activeIndefiniteMenu(startedAt: startedAt)
                case let .activeUntilDate(_, endsAt):
                    activeTimedMenu(endsAt: endsAt)
                case .disabledDueToBattery:
                    disabledMenu(message: "NoSleep disabled at the configured battery threshold.")
                case .disabledDueToUnplugged:
                    disabledMenu(message: "NoSleep disabled because your Mac was unplugged.")
                }
            }

            Divider()

            powerSection

            Divider()

            Button("Open Settings...") {
                openSettings()
            }

            Button("Quit NoSleep") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
    }

    private var inactiveMenu: some View {
        Group {
            if indefiniteUnavailableOnBattery {
                Label("Indefinite session unavailable on battery", systemImage: "exclamationmark.triangle")
                Text("Plug in your Mac or choose a timer.")
                    .foregroundStyle(.secondary)
            } else {
                Button("Keep Mac Awake") {
                    beginStart(.indefinite)
                }
            }

            Divider()

            Text("Duration")
                .font(.caption)
                .foregroundStyle(.secondary)

            if !indefiniteUnavailableOnBattery {
                Button("Until I turn it off") {
                    beginStart(.indefinite)
                }
            }

            ForEach(DurationPreset.allCases) { preset in
                Button(preset.label) {
                    beginStart(.preset(preset))
                }
            }

            Button("Until specific time...") {
                openWindow(id: UntilSpecificTimeView.windowID)
            }
        }
    }

    private func activeIndefiniteMenu(startedAt: Date) -> some View {
        Group {
            Label("Keeping Mac Awake", systemImage: "checkmark")

            Text("Until I turn it off")
                .foregroundStyle(.secondary)

            Text("Started \(startedAt.formatted(date: .omitted, time: .shortened))")
                .foregroundStyle(.secondary)

            Divider()

            Button("Stop Keeping Awake") {
                sessionController.stop()
            }
        }
    }

    private func activeTimedMenu(endsAt: Date) -> some View {
        Group {
            Label("Keeping Mac Awake", systemImage: "checkmark")

            Text("Until \(endsAt.formatted(date: .omitted, time: .shortened))")
                .foregroundStyle(.secondary)

            Text("Mac can sleep again in \(TimeRemainingFormatter.string(until: endsAt))")
                .foregroundStyle(.secondary)

            Divider()

            Button("Stop Keeping Awake") {
                sessionController.stop()
            }
        }
    }

    private func disabledMenu(message: String) -> some View {
        Group {
            Text(message)
                .foregroundStyle(.secondary)

            Divider()

            inactiveMenu
        }
    }

    private func batteryConfirmationMenu(for pendingStart: PendingBatteryStart) -> some View {
        Group {
            Label("Running on battery", systemImage: "exclamationmark.triangle")

            if settings.disableBelowBatteryThreshold {
                Text("Will disable at \(settings.batteryThresholdPercent)%")
                    .foregroundStyle(.secondary)
            }

            Button("Start on Battery") {
                performStart(pendingStart, allowBatteryStart: true)
                pendingBatteryStart = nil
            }

            Button("Cancel") {
                pendingBatteryStart = nil
            }
        }
    }

    private var powerSection: some View {
        Group {
            Text("Power")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(powerMonitor.snapshot.source.description)
                .foregroundStyle(.secondary)

            if let batteryPercentage = powerMonitor.snapshot.batteryPercentage {
                Text("Battery: \(batteryPercentage)%")
                    .foregroundStyle(.secondary)
            } else if powerMonitor.snapshot.hasBattery {
                Text("Battery percentage unavailable")
                    .foregroundStyle(.secondary)
            }

            if powerMonitor.snapshot.isOnBattery, sessionController.state.isActive {
                Text("Running on battery")
                    .foregroundStyle(.secondary)

                if settings.disableBelowBatteryThreshold {
                    Text("Will disable at \(settings.batteryThresholdPercent)%")
                        .foregroundStyle(.secondary)
                }
            } else if indefiniteUnavailableOnBattery {
                Text("Until I turn it off unavailable on battery")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var indefiniteUnavailableOnBattery: Bool {
        settings.onlyAllowIndefiniteWhilePluggedIn && powerMonitor.snapshot.isOnBattery
    }

    private func beginStart(_ pendingStart: PendingBatteryStart) {
        if requiresBatteryConfirmation(for: pendingStart) {
            pendingBatteryStart = pendingStart
            return
        }

        performStart(pendingStart, allowBatteryStart: false)
    }

    private func requiresBatteryConfirmation(for pendingStart: PendingBatteryStart) -> Bool {
        if case .indefinite = pendingStart, indefiniteUnavailableOnBattery {
            return false
        }

        if settings.disableBelowBatteryThreshold,
           powerMonitor.snapshot.isAtOrBelowBatteryThreshold(settings.batteryThresholdPercent) {
            return false
        }

        return settings.warnBeforeRunningOnBattery && powerMonitor.snapshot.isOnBattery
    }

    private func performStart(_ pendingStart: PendingBatteryStart, allowBatteryStart: Bool) {
        switch pendingStart {
        case .indefinite:
            sessionController.startIndefinite(allowBatteryStart: allowBatteryStart)
        case let .preset(preset):
            sessionController.start(durationPreset: preset, allowBatteryStart: allowBatteryStart)
        case let .until(endDate):
            sessionController.start(until: endDate, allowBatteryStart: allowBatteryStart)
        }
    }
}

private enum PendingBatteryStart: Equatable {
    case indefinite
    case preset(DurationPreset)
    case until(Date)
}
