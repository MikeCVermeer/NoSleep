import Foundation

enum DiagnosticsTextFormatter {
    static func string(from snapshot: DiagnosticsSnapshot) -> String {
        [
            "NoSleep Diagnostics",
            "",
            "Session",
            "State: \(sessionDescription(snapshot.sessionState))",
            "Active timer end: \(dateDescription(snapshot.activeTimerEndDate))",
            "",
            "Assertions",
            "System assertion ID: \(idDescription(snapshot.assertionDiagnostics.systemAssertionID))",
            "Display assertion ID: \(idDescription(snapshot.assertionDiagnostics.displayAssertionID))",
            "Last assertion error: \(snapshot.assertionDiagnostics.lastErrorDescription ?? "None")",
            "",
            "Power",
            "Source: \(snapshot.powerSourceDescription ?? "Unknown")",
            "Battery: \(batteryDescription(snapshot.batteryPercentage))",
            "",
            "Settings",
            "Prevent system sleep: \(boolDescription(snapshot.settings.preventSystemSleep))",
            "Prevent display sleep: \(boolDescription(snapshot.settings.preventDisplaySleep))",
            "Warn before running on battery: \(boolDescription(snapshot.settings.warnBeforeRunningOnBattery))",
            "Only allow indefinite while plugged in: \(boolDescription(snapshot.settings.onlyAllowIndefiniteWhilePluggedIn))",
            "Auto-disable when unplugged: \(boolDescription(snapshot.settings.autoDisableWhenUnplugged))",
            "Disable below battery threshold: \(boolDescription(snapshot.settings.disableBelowBatteryThreshold))",
            "Battery threshold: \(snapshot.settings.batteryThresholdPercent)%",
            "Start at login: \(boolDescription(snapshot.settings.startAtLogin))",
            "Show timer in menu bar: \(boolDescription(snapshot.settings.showTimerInMenuBar))",
            "Show active state in icon: \(boolDescription(snapshot.settings.showActiveStateInIcon))",
            "When Mac sleeps: \(snapshot.settings.sleepWakeBehavior.label)",
            "Default duration: \(snapshot.settings.defaultDuration.label)",
            "Notify timer ended: \(boolDescription(snapshot.settings.notifyTimerEnded))",
            "Notify Mac can sleep again: \(boolDescription(snapshot.settings.notifyMacCanSleepAgain))",
            "Notify battery low: \(boolDescription(snapshot.settings.notifyBatteryLow))",
            "Notify unplugged while active: \(boolDescription(snapshot.settings.notifyUnpluggedWhileActive))",
            "Notify auto-disabled when unplugged: \(boolDescription(snapshot.settings.notifyAutoDisabledWhenUnplugged))",
        ].joined(separator: "\n")
    }

    private static func sessionDescription(_ state: AwakeSessionState) -> String {
        switch state {
        case .inactive:
            "Inactive"
        case .activeIndefinitely:
            "Keeping Mac Awake until turned off"
        case let .activeUntilDate(_, endsAt):
            "Keeping Mac Awake until \(dateDescription(endsAt))"
        case .disabledDueToBattery:
            "Disabled at the configured battery threshold"
        case .disabledDueToUnplugged:
            "Disabled because the Mac was unplugged"
        }
    }

    private static func dateDescription(_ date: Date?) -> String {
        guard let date else {
            return "None"
        }

        return date.formatted(date: .abbreviated, time: .standard)
    }

    private static func idDescription(_ id: PowerAssertionID?) -> String {
        guard let id else {
            return "None"
        }

        return "\(id)"
    }

    private static func batteryDescription(_ percentage: Int?) -> String {
        guard let percentage else {
            return "Unavailable"
        }

        return "\(percentage)%"
    }

    private static func boolDescription(_ value: Bool) -> String {
        value ? "On" : "Off"
    }
}
