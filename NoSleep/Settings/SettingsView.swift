import AppKit
import SwiftUI
import UserNotifications

struct SettingsView: View {
    @ObservedObject var settings: SettingsStore
    @ObservedObject var sessionController: SessionController
    @ObservedObject var assertionManager: SleepAssertionManager
    @ObservedObject var powerMonitor: PowerMonitor
    @ObservedObject var notificationManager: NotificationManager
    @ObservedObject var loginItemManager: LoginItemManager

    @State private var diagnosticsCopied = false

    var body: some View {
        TabView {
            generalSettings
                .tabItem { Label("General", systemImage: "gearshape") }

            sleepBehaviorSettings
                .tabItem { Label("Sleep Behavior", systemImage: "bed.double") }

            batterySettings
                .tabItem { Label("Battery", systemImage: "battery.75percent") }

            notificationSettings
                .tabItem { Label("Notifications", systemImage: "bell") }

            advancedSettings
                .tabItem { Label("Advanced", systemImage: "wrench.and.screwdriver") }
        }
        .padding()
        .frame(width: 620, height: 480)
        .onAppear {
            loginItemManager.refresh()
            settings.startAtLogin = loginItemManager.isEnabled
        }
    }

    private var generalSettings: some View {
        Form {
            Toggle("Start NoSleep at login", isOn: startAtLoginBinding)
            Toggle("Show timer in menu bar", isOn: $settings.showTimerInMenuBar)
            Toggle("Show active state in menu bar icon", isOn: $settings.showActiveStateInIcon)

            Picker("Default duration", selection: $settings.defaultDuration) {
                ForEach(DefaultDurationOption.allCases) { option in
                    Text(option.label).tag(option)
                }
            }
            .pickerStyle(.menu)
        }
        .formStyle(.grouped)
    }

    private var sleepBehaviorSettings: some View {
        Form {
            Toggle("Prevent system sleep", isOn: $settings.preventSystemSleep)
            Toggle("Also prevent display sleep", isOn: $settings.preventDisplaySleep)

            Picker("When Mac sleeps", selection: $settings.sleepWakeBehavior) {
                ForEach(SleepWakeBehavior.allCases) { behavior in
                    Text(behavior.label).tag(behavior)
                }
            }
            .pickerStyle(.radioGroup)
        }
        .formStyle(.grouped)
    }

    private var batterySettings: some View {
        Form {
            Toggle("Warn before running on battery", isOn: $settings.warnBeforeRunningOnBattery)
            Toggle("Only allow indefinite sessions while plugged in", isOn: $settings.onlyAllowIndefiniteWhilePluggedIn)
            Toggle("Auto-disable when unplugged", isOn: $settings.autoDisableWhenUnplugged)
            Toggle("Disable below battery percentage", isOn: $settings.disableBelowBatteryThreshold)

            Stepper(
                "Battery threshold: \(settings.batteryThresholdPercent)%",
                value: $settings.batteryThresholdPercent,
                in: 1...100,
                step: 1
            )
            .disabled(!settings.disableBelowBatteryThreshold)
        }
        .formStyle(.grouped)
    }

    private var notificationSettings: some View {
        Form {
            Toggle("Timer ended", isOn: $settings.notifyTimerEnded)
            Toggle("Mac can sleep again", isOn: $settings.notifyMacCanSleepAgain)
            Toggle("Battery low", isOn: $settings.notifyBatteryLow)
            Toggle("Unplugged while active", isOn: $settings.notifyUnpluggedWhileActive)
            Toggle("Auto-disabled when unplugged", isOn: $settings.notifyAutoDisabledWhenUnplugged)
        }
        .formStyle(.grouped)
    }

    private var advancedSettings: some View {
        VStack(alignment: .leading, spacing: 16) {
            Form {
                LabeledContent("Current session", value: sessionSummary)
                LabeledContent("System assertion", value: assertionIDText(assertionManager.systemAssertionID))
                LabeledContent("Display assertion", value: assertionIDText(assertionManager.displayAssertionID))
                LabeledContent("Power source", value: powerMonitor.snapshot.source.description)
                LabeledContent("Battery", value: batteryText)
                LabeledContent("Active timer end", value: activeTimerEndText)
                LabeledContent("Notifications", value: notificationAuthorizationText)
                LabeledContent("Launch at login", value: loginItemManager.isEnabled ? "Enabled" : "Disabled")
                LabeledContent("Notification error", value: notificationManager.lastErrorDescription ?? "None")
                LabeledContent("Login item error", value: loginItemManager.lastErrorDescription ?? "None")
            }
            .formStyle(.grouped)

            Text(diagnosticsText)
                .font(.system(.caption, design: .monospaced))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(8)
                .background(Color(nsColor: .textBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 6))

            HStack {
                Button("Export Diagnostics") {
                    copyDiagnosticsToPasteboard()
                }

                if diagnosticsCopied {
                    Text("Copied")
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button("Reset All Settings") {
                    settings.reset()
                }
            }
        }
    }

    private var diagnosticsSnapshot: DiagnosticsSnapshot {
        DiagnosticsSnapshot(
            sessionController: sessionController,
            assertionManager: assertionManager,
            powerSnapshot: powerMonitor.snapshot,
            settingsStore: settings
        )
    }

    private var diagnosticsText: String {
        DiagnosticsTextFormatter.string(from: diagnosticsSnapshot)
    }

    private var startAtLoginBinding: Binding<Bool> {
        Binding {
            settings.startAtLogin
        } set: { isEnabled in
            if loginItemManager.setEnabled(isEnabled) {
                settings.startAtLogin = isEnabled
            } else {
                settings.startAtLogin = loginItemManager.isEnabled
            }
        }
    }

    private var sessionSummary: String {
        switch sessionController.state {
        case .inactive:
            "Inactive"
        case .activeIndefinitely:
            "Keeping Mac Awake until turned off"
        case let .activeUntilDate(_, endsAt):
            "Keeping Mac Awake until \(endsAt.formatted(date: .omitted, time: .shortened))"
        case .disabledDueToBattery:
            "Disabled at the configured battery threshold"
        case .disabledDueToUnplugged:
            "Disabled because the Mac was unplugged"
        }
    }

    private var batteryText: String {
        guard let batteryPercentage = powerMonitor.snapshot.batteryPercentage else {
            return powerMonitor.snapshot.hasBattery ? "Unavailable" : "No battery detected"
        }

        return "\(batteryPercentage)%"
    }

    private var activeTimerEndText: String {
        guard let endDate = sessionController.activeTimerEndDate else {
            return "None"
        }

        return endDate.formatted(date: .abbreviated, time: .shortened)
    }

    private var notificationAuthorizationText: String {
        switch notificationManager.authorizationStatus {
        case .notDetermined:
            "Not requested"
        case .denied:
            "Denied"
        case .authorized:
            "Authorized"
        case .provisional:
            "Provisional"
        @unknown default:
            "Unknown"
        }
    }

    private func assertionIDText(_ id: PowerAssertionID?) -> String {
        guard let id else {
            return "Inactive"
        }

        return "\(id)"
    }

    private func copyDiagnosticsToPasteboard() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(diagnosticsText, forType: .string)
        diagnosticsCopied = true
    }
}
