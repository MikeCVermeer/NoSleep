import Combine
import Foundation

@MainActor
final class SettingsStore: ObservableObject {
    private enum Keys {
        static let preventSystemSleep = "preventSystemSleep"
        static let preventDisplaySleep = "preventDisplaySleep"
        static let warnBeforeRunningOnBattery = "warnBeforeRunningOnBattery"
        static let onlyAllowIndefiniteWhilePluggedIn = "onlyAllowIndefiniteWhilePluggedIn"
        static let autoDisableWhenUnplugged = "autoDisableWhenUnplugged"
        static let disableBelowBatteryThreshold = "disableBelowBatteryThreshold"
        static let batteryThresholdPercent = "batteryThresholdPercent"
        static let startAtLogin = "startAtLogin"
        static let showTimerInMenuBar = "showTimerInMenuBar"
        static let showActiveStateInIcon = "showActiveStateInIcon"
        static let sleepWakeBehavior = "sleepWakeBehavior"
        static let defaultDuration = "defaultDuration"
        static let notifyTimerEnded = "notifyTimerEnded"
        static let notifyMacCanSleepAgain = "notifyMacCanSleepAgain"
        static let notifyBatteryLow = "notifyBatteryLow"
        static let notifyUnpluggedWhileActive = "notifyUnpluggedWhileActive"
        static let notifyAutoDisabledWhenUnplugged = "notifyAutoDisabledWhenUnplugged"
    }

    private let defaults: UserDefaults

    @Published var preventSystemSleep: Bool {
        didSet { defaults.set(preventSystemSleep, forKey: Keys.preventSystemSleep) }
    }

    @Published var preventDisplaySleep: Bool {
        didSet { defaults.set(preventDisplaySleep, forKey: Keys.preventDisplaySleep) }
    }

    @Published var warnBeforeRunningOnBattery: Bool {
        didSet { defaults.set(warnBeforeRunningOnBattery, forKey: Keys.warnBeforeRunningOnBattery) }
    }

    @Published var onlyAllowIndefiniteWhilePluggedIn: Bool {
        didSet { defaults.set(onlyAllowIndefiniteWhilePluggedIn, forKey: Keys.onlyAllowIndefiniteWhilePluggedIn) }
    }

    @Published var autoDisableWhenUnplugged: Bool {
        didSet { defaults.set(autoDisableWhenUnplugged, forKey: Keys.autoDisableWhenUnplugged) }
    }

    @Published var disableBelowBatteryThreshold: Bool {
        didSet { defaults.set(disableBelowBatteryThreshold, forKey: Keys.disableBelowBatteryThreshold) }
    }

    @Published var batteryThresholdPercent: Int {
        didSet {
            let clamped = Self.clampedBatteryThreshold(batteryThresholdPercent)
            if batteryThresholdPercent != clamped {
                batteryThresholdPercent = clamped
                return
            }
            defaults.set(batteryThresholdPercent, forKey: Keys.batteryThresholdPercent)
        }
    }

    @Published var startAtLogin: Bool {
        didSet { defaults.set(startAtLogin, forKey: Keys.startAtLogin) }
    }

    @Published var showTimerInMenuBar: Bool {
        didSet { defaults.set(showTimerInMenuBar, forKey: Keys.showTimerInMenuBar) }
    }

    @Published var showActiveStateInIcon: Bool {
        didSet { defaults.set(showActiveStateInIcon, forKey: Keys.showActiveStateInIcon) }
    }

    @Published var sleepWakeBehavior: SleepWakeBehavior {
        didSet { defaults.set(sleepWakeBehavior.rawValue, forKey: Keys.sleepWakeBehavior) }
    }

    @Published var defaultDuration: DefaultDurationOption {
        didSet { defaults.set(defaultDuration.rawValue, forKey: Keys.defaultDuration) }
    }

    @Published var notifyTimerEnded: Bool {
        didSet { defaults.set(notifyTimerEnded, forKey: Keys.notifyTimerEnded) }
    }

    @Published var notifyMacCanSleepAgain: Bool {
        didSet { defaults.set(notifyMacCanSleepAgain, forKey: Keys.notifyMacCanSleepAgain) }
    }

    @Published var notifyBatteryLow: Bool {
        didSet { defaults.set(notifyBatteryLow, forKey: Keys.notifyBatteryLow) }
    }

    @Published var notifyUnpluggedWhileActive: Bool {
        didSet { defaults.set(notifyUnpluggedWhileActive, forKey: Keys.notifyUnpluggedWhileActive) }
    }

    @Published var notifyAutoDisabledWhenUnplugged: Bool {
        didSet { defaults.set(notifyAutoDisabledWhenUnplugged, forKey: Keys.notifyAutoDisabledWhenUnplugged) }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        preventSystemSleep = Self.bool(forKey: Keys.preventSystemSleep, defaultValue: true, defaults: defaults)
        preventDisplaySleep = Self.bool(forKey: Keys.preventDisplaySleep, defaultValue: false, defaults: defaults)
        warnBeforeRunningOnBattery = Self.bool(forKey: Keys.warnBeforeRunningOnBattery, defaultValue: true, defaults: defaults)
        onlyAllowIndefiniteWhilePluggedIn = Self.bool(forKey: Keys.onlyAllowIndefiniteWhilePluggedIn, defaultValue: true, defaults: defaults)
        autoDisableWhenUnplugged = Self.bool(forKey: Keys.autoDisableWhenUnplugged, defaultValue: false, defaults: defaults)
        disableBelowBatteryThreshold = Self.bool(forKey: Keys.disableBelowBatteryThreshold, defaultValue: true, defaults: defaults)
        batteryThresholdPercent = Self.clampedBatteryThreshold(defaults.object(forKey: Keys.batteryThresholdPercent) as? Int ?? 20)
        startAtLogin = Self.bool(forKey: Keys.startAtLogin, defaultValue: false, defaults: defaults)
        showTimerInMenuBar = Self.bool(forKey: Keys.showTimerInMenuBar, defaultValue: false, defaults: defaults)
        showActiveStateInIcon = Self.bool(forKey: Keys.showActiveStateInIcon, defaultValue: true, defaults: defaults)
        sleepWakeBehavior = Self.enumValue(forKey: Keys.sleepWakeBehavior, defaultValue: .turnOffOnSleep, defaults: defaults)
        defaultDuration = Self.enumValue(forKey: Keys.defaultDuration, defaultValue: .untilTurnedOff, defaults: defaults)
        notifyTimerEnded = Self.bool(forKey: Keys.notifyTimerEnded, defaultValue: true, defaults: defaults)
        notifyMacCanSleepAgain = Self.bool(forKey: Keys.notifyMacCanSleepAgain, defaultValue: true, defaults: defaults)
        notifyBatteryLow = Self.bool(forKey: Keys.notifyBatteryLow, defaultValue: true, defaults: defaults)
        notifyUnpluggedWhileActive = Self.bool(forKey: Keys.notifyUnpluggedWhileActive, defaultValue: true, defaults: defaults)
        notifyAutoDisabledWhenUnplugged = Self.bool(forKey: Keys.notifyAutoDisabledWhenUnplugged, defaultValue: true, defaults: defaults)
    }

    func reset() {
        allKeys.forEach { defaults.removeObject(forKey: $0) }

        preventSystemSleep = true
        preventDisplaySleep = false
        warnBeforeRunningOnBattery = true
        onlyAllowIndefiniteWhilePluggedIn = true
        autoDisableWhenUnplugged = false
        disableBelowBatteryThreshold = true
        batteryThresholdPercent = 20
        startAtLogin = false
        showTimerInMenuBar = false
        showActiveStateInIcon = true
        sleepWakeBehavior = .turnOffOnSleep
        defaultDuration = .untilTurnedOff
        notifyTimerEnded = true
        notifyMacCanSleepAgain = true
        notifyBatteryLow = true
        notifyUnpluggedWhileActive = true
        notifyAutoDisabledWhenUnplugged = true
    }

    private var allKeys: [String] {
        [
            Keys.preventSystemSleep,
            Keys.preventDisplaySleep,
            Keys.warnBeforeRunningOnBattery,
            Keys.onlyAllowIndefiniteWhilePluggedIn,
            Keys.autoDisableWhenUnplugged,
            Keys.disableBelowBatteryThreshold,
            Keys.batteryThresholdPercent,
            Keys.startAtLogin,
            Keys.showTimerInMenuBar,
            Keys.showActiveStateInIcon,
            Keys.sleepWakeBehavior,
            Keys.defaultDuration,
            Keys.notifyTimerEnded,
            Keys.notifyMacCanSleepAgain,
            Keys.notifyBatteryLow,
            Keys.notifyUnpluggedWhileActive,
            Keys.notifyAutoDisabledWhenUnplugged,
        ]
    }

    private static func bool(forKey key: String, defaultValue: Bool, defaults: UserDefaults) -> Bool {
        defaults.object(forKey: key) as? Bool ?? defaultValue
    }

    private static func enumValue<T: RawRepresentable>(
        forKey key: String,
        defaultValue: T,
        defaults: UserDefaults
    ) -> T where T.RawValue == String {
        guard let rawValue = defaults.string(forKey: key),
              let value = T(rawValue: rawValue)
        else {
            return defaultValue
        }

        return value
    }

    private static func clampedBatteryThreshold(_ value: Int) -> Int {
        min(max(value, 1), 100)
    }
}
