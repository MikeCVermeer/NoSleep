import Foundation

struct DiagnosticsSnapshot: Equatable {
    let sessionState: AwakeSessionState
    let assertionDiagnostics: AssertionDiagnostics
    let powerSourceDescription: String?
    let batteryPercentage: Int?
    let activeTimerEndDate: Date?
    let settings: SettingsDiagnostics

    init(
        sessionState: AwakeSessionState,
        assertionDiagnostics: AssertionDiagnostics,
        powerSourceDescription: String?,
        batteryPercentage: Int?,
        activeTimerEndDate: Date?,
        settings: SettingsDiagnostics
    ) {
        self.sessionState = sessionState
        self.assertionDiagnostics = assertionDiagnostics
        self.powerSourceDescription = powerSourceDescription
        self.batteryPercentage = batteryPercentage
        self.activeTimerEndDate = activeTimerEndDate
        self.settings = settings
    }

    init(
        sessionController: SessionController,
        assertionManager: SleepAssertionManager,
        powerSnapshot: PowerSourceSnapshot,
        settingsStore: SettingsStore
    ) {
        self.init(
            sessionState: sessionController.state,
            assertionDiagnostics: assertionManager.diagnostics,
            powerSourceDescription: powerSnapshot.source.description,
            batteryPercentage: powerSnapshot.batteryPercentage,
            activeTimerEndDate: sessionController.activeTimerEndDate,
            settings: SettingsDiagnostics(settings: settingsStore)
        )
    }
}

struct SettingsDiagnostics: Equatable {
    let preventSystemSleep: Bool
    let preventDisplaySleep: Bool
    let warnBeforeRunningOnBattery: Bool
    let onlyAllowIndefiniteWhilePluggedIn: Bool
    let autoDisableWhenUnplugged: Bool
    let disableBelowBatteryThreshold: Bool
    let batteryThresholdPercent: Int
    let startAtLogin: Bool
    let showTimerInMenuBar: Bool
    let showActiveStateInIcon: Bool
    let sleepWakeBehavior: SleepWakeBehavior
    let defaultDuration: DefaultDurationOption
    let notifyTimerEnded: Bool
    let notifyMacCanSleepAgain: Bool
    let notifyBatteryLow: Bool
    let notifyUnpluggedWhileActive: Bool
    let notifyAutoDisabledWhenUnplugged: Bool

    init(settings: SettingsStore) {
        preventSystemSleep = settings.preventSystemSleep
        preventDisplaySleep = settings.preventDisplaySleep
        warnBeforeRunningOnBattery = settings.warnBeforeRunningOnBattery
        onlyAllowIndefiniteWhilePluggedIn = settings.onlyAllowIndefiniteWhilePluggedIn
        autoDisableWhenUnplugged = settings.autoDisableWhenUnplugged
        disableBelowBatteryThreshold = settings.disableBelowBatteryThreshold
        batteryThresholdPercent = settings.batteryThresholdPercent
        startAtLogin = settings.startAtLogin
        showTimerInMenuBar = settings.showTimerInMenuBar
        showActiveStateInIcon = settings.showActiveStateInIcon
        sleepWakeBehavior = settings.sleepWakeBehavior
        defaultDuration = settings.defaultDuration
        notifyTimerEnded = settings.notifyTimerEnded
        notifyMacCanSleepAgain = settings.notifyMacCanSleepAgain
        notifyBatteryLow = settings.notifyBatteryLow
        notifyUnpluggedWhileActive = settings.notifyUnpluggedWhileActive
        notifyAutoDisabledWhenUnplugged = settings.notifyAutoDisabledWhenUnplugged
    }
}
