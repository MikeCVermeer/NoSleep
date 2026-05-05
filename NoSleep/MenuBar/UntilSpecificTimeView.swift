import SwiftUI

struct UntilSpecificTimeView: View {
    static let windowID = "until-specific-time"

    @ObservedObject var sessionController: SessionController
    @ObservedObject var powerMonitor: PowerMonitor
    @ObservedObject var settings: SettingsStore

    @Environment(\.dismiss) private var dismiss
    @State private var selectedTime = Date(timeIntervalSinceNow: 60 * 60)
    @State private var pendingBatteryConfirmation = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Until Specific Time")
                .font(.headline)

            DatePicker(
                "Time",
                selection: $selectedTime,
                displayedComponents: [.hourAndMinute]
            )
            .datePickerStyle(.field)

            Text("NoSleep will keep your Mac awake until \(targetEndDate.formatted(date: .omitted, time: .shortened)).")
                .foregroundStyle(.secondary)

            if pendingBatteryConfirmation {
                batteryConfirmation
            }

            if let errorDescription = sessionController.lastStartError?.errorDescription {
                Text(errorDescription)
                    .foregroundStyle(.red)
            }

            HStack {
                Spacer()

                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Button(startButtonTitle) {
                    start()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .frame(width: 360)
    }

    private var targetEndDate: Date {
        UntilSpecificTimeCalculator.nextDate(matchingHourAndMinuteFrom: selectedTime)
    }

    private var startButtonTitle: String {
        pendingBatteryConfirmation ? "Start on Battery" : "Start"
    }

    private var batteryConfirmation: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label("Running on battery", systemImage: "exclamationmark.triangle")

            if settings.disableBelowBatteryThreshold {
                Text("Will disable at \(settings.batteryThresholdPercent)%")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func start() {
        if requiresBatteryConfirmation, !pendingBatteryConfirmation {
            pendingBatteryConfirmation = true
            return
        }

        let result = sessionController.start(
            until: targetEndDate,
            allowBatteryStart: pendingBatteryConfirmation
        )

        if case .success = result {
            dismiss()
        }
    }

    private var requiresBatteryConfirmation: Bool {
        if settings.disableBelowBatteryThreshold,
           powerMonitor.snapshot.isAtOrBelowBatteryThreshold(settings.batteryThresholdPercent) {
            return false
        }

        return settings.warnBeforeRunningOnBattery && powerMonitor.snapshot.isOnBattery
    }
}
