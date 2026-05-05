import XCTest
@testable import NoSleep

@MainActor
final class SettingsStoreTests: XCTestCase {
    func testDefaultsMatchSpecs() {
        let store = SettingsStore(defaults: makeDefaults())

        XCTAssertTrue(store.preventSystemSleep)
        XCTAssertFalse(store.preventDisplaySleep)
        XCTAssertTrue(store.warnBeforeRunningOnBattery)
        XCTAssertTrue(store.onlyAllowIndefiniteWhilePluggedIn)
        XCTAssertFalse(store.autoDisableWhenUnplugged)
        XCTAssertTrue(store.disableBelowBatteryThreshold)
        XCTAssertEqual(store.batteryThresholdPercent, 20)
        XCTAssertFalse(store.startAtLogin)
        XCTAssertFalse(store.showTimerInMenuBar)
        XCTAssertTrue(store.showActiveStateInIcon)
        XCTAssertEqual(store.sleepWakeBehavior, .turnOffOnSleep)
        XCTAssertEqual(store.defaultDuration, .untilTurnedOff)
    }

    func testSettingsPersistToUserDefaults() {
        let defaults = makeDefaults()
        let store = SettingsStore(defaults: defaults)

        store.preventDisplaySleep = true
        store.batteryThresholdPercent = 35
        store.sleepWakeBehavior = .resumeAfterWake
        store.defaultDuration = .oneHour

        let reloadedStore = SettingsStore(defaults: defaults)

        XCTAssertTrue(reloadedStore.preventDisplaySleep)
        XCTAssertEqual(reloadedStore.batteryThresholdPercent, 35)
        XCTAssertEqual(reloadedStore.sleepWakeBehavior, .resumeAfterWake)
        XCTAssertEqual(reloadedStore.defaultDuration, .oneHour)
    }

    func testResetRestoresDefaults() {
        let store = SettingsStore(defaults: makeDefaults())

        store.preventDisplaySleep = true
        store.autoDisableWhenUnplugged = true
        store.batteryThresholdPercent = 50
        store.sleepWakeBehavior = .keepPreviousState

        store.reset()

        XCTAssertFalse(store.preventDisplaySleep)
        XCTAssertFalse(store.autoDisableWhenUnplugged)
        XCTAssertEqual(store.batteryThresholdPercent, 20)
        XCTAssertEqual(store.sleepWakeBehavior, .turnOffOnSleep)
    }

    func testBatteryThresholdIsClamped() {
        let store = SettingsStore(defaults: makeDefaults())

        store.batteryThresholdPercent = -5
        XCTAssertEqual(store.batteryThresholdPercent, 1)

        store.batteryThresholdPercent = 140
        XCTAssertEqual(store.batteryThresholdPercent, 100)
    }

    func testSettingsLabelsMatchUserFacingCopy() {
        XCTAssertEqual(DefaultDurationOption.untilTurnedOff.label, "Until I turn it off")
        XCTAssertEqual(DefaultDurationOption.oneHour.label, "1 hour")
        XCTAssertEqual(SleepWakeBehavior.turnOffOnSleep.label, "Turn NoSleep off")
        XCTAssertEqual(SleepWakeBehavior.resumeAfterWake.label, "Resume NoSleep after wake")
        XCTAssertEqual(SleepWakeBehavior.keepPreviousState.label, "Keep previous state")
    }

    func testDiagnosticsTextIncludesSessionAssertionsPowerAndSettings() {
        let settings = SettingsStore(defaults: makeDefaults())
        let snapshot = DiagnosticsSnapshot(
            sessionState: .activeUntilDate(
                startedAt: Date(timeIntervalSince1970: 1_000),
                endsAt: Date(timeIntervalSince1970: 2_000)
            ),
            assertionDiagnostics: AssertionDiagnostics(
                systemAssertionID: PowerAssertionID(101),
                displayAssertionID: nil,
                lastErrorDescription: nil
            ),
            powerSourceDescription: "On battery",
            batteryPercentage: 84,
            activeTimerEndDate: Date(timeIntervalSince1970: 2_000),
            settings: SettingsDiagnostics(settings: settings)
        )

        let text = DiagnosticsTextFormatter.string(from: snapshot)

        XCTAssertTrue(text.contains("NoSleep Diagnostics"))
        XCTAssertTrue(text.contains("System assertion ID: 101"))
        XCTAssertTrue(text.contains("Source: On battery"))
        XCTAssertTrue(text.contains("Battery: 84%"))
        XCTAssertTrue(text.contains("Default duration: Until I turn it off"))
        XCTAssertTrue(text.contains("Battery threshold: 20%"))
    }

    private func makeDefaults() -> UserDefaults {
        let suiteName = "NoSleepTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}
