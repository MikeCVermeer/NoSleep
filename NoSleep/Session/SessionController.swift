import Combine
import Foundation

@MainActor
final class SessionController: ObservableObject {
    private let settings: SettingsStore
    private let powerMonitor: PowerMonitoring
    private let notificationManager: NotificationManaging
    private let assertionManager: SleepAssertionManager
    private let timerScheduler: SessionTimerScheduling
    private let now: () -> Date

    private var timerToken: SessionTimerToken?
    private var powerMonitorCancellable: AnyCancellable?
    private var previousPowerSnapshot: PowerSourceSnapshot
    private var batteryLowNotificationSent = false
    private var pendingWakeSessionState: AwakeSessionState?

    @Published private(set) var state: AwakeSessionState = .inactive
    @Published private(set) var lastStartError: SessionStartError?

    convenience init(
        settings: SettingsStore,
        powerMonitor: PowerMonitoring,
        notificationManager: NotificationManaging,
        assertionManager: SleepAssertionManager,
        now: @escaping () -> Date = Date.init
    ) {
        self.init(
            settings: settings,
            powerMonitor: powerMonitor,
            notificationManager: notificationManager,
            assertionManager: assertionManager,
            timerScheduler: FoundationSessionTimerScheduler(),
            now: now
        )
    }

    init(
        settings: SettingsStore,
        powerMonitor: PowerMonitoring,
        notificationManager: NotificationManaging,
        assertionManager: SleepAssertionManager,
        timerScheduler: SessionTimerScheduling,
        now: @escaping () -> Date = Date.init
    ) {
        self.settings = settings
        self.powerMonitor = powerMonitor
        self.notificationManager = notificationManager
        self.assertionManager = assertionManager
        self.timerScheduler = timerScheduler
        self.now = now
        previousPowerSnapshot = powerMonitor.snapshot

        powerMonitorCancellable = powerMonitor.snapshotPublisher
            .sink { [weak self] snapshot in
                MainActor.assumeIsolated {
                    self?.handlePowerSnapshotChange(snapshot)
                }
            }
    }

    deinit {
        MainActor.assumeIsolated {
            stop()
        }
    }

    var activeTimerEndDate: Date? {
        state.endsAt
    }

    func handleSystemWillSleep() {
        switch settings.sleepWakeBehavior {
        case .turnOffOnSleep:
            pendingWakeSessionState = nil
            stop()
        case .resumeAfterWake, .keepPreviousState:
            pendingWakeSessionState = state.isActive ? state : nil
            cancelTimer()
            assertionManager.releaseAllAssertions()
            state = .inactive
        }
    }

    func handleSystemDidWake() {
        guard let pendingWakeSessionState else {
            return
        }

        self.pendingWakeSessionState = nil

        switch pendingWakeSessionState {
        case .activeIndefinitely:
            startIndefinite()
        case let .activeUntilDate(_, endsAt):
            guard endsAt > now() else {
                stop()
                sendTimerEndedNotificationIfEnabled()
                return
            }

            start(until: endsAt)
        case .inactive, .disabledDueToBattery, .disabledDueToUnplugged:
            break
        }
    }

    @discardableResult
    func startIndefinite(allowBatteryStart: Bool = false) -> Result<Void, SessionStartError> {
        let startedAt = now()

        if let error = startSafetyError(for: .indefinite, allowBatteryStart: allowBatteryStart) {
            lastStartError = error
            return .failure(error)
        }

        switch activateAssertionsForNewSession() {
        case .success:
            state = .activeIndefinitely(startedAt: startedAt)
            return .success(())
        case let .failure(error):
            return .failure(error)
        }
    }

    @discardableResult
    func start(durationPreset: DurationPreset, allowBatteryStart: Bool = false) -> Result<Void, SessionStartError> {
        let startedAt = now()
        let endsAt = durationPreset.endDate(startingAt: startedAt)
        return startTimedSession(startedAt: startedAt, endsAt: endsAt, allowBatteryStart: allowBatteryStart)
    }

    @discardableResult
    func start(until endDate: Date, allowBatteryStart: Bool = false) -> Result<Void, SessionStartError> {
        let startedAt = now()

        guard endDate > startedAt else {
            let error = SessionStartError.invalidEndDate
            lastStartError = error
            return .failure(error)
        }

        return startTimedSession(startedAt: startedAt, endsAt: endDate, allowBatteryStart: allowBatteryStart)
    }

    func stop() {
        cancelTimer()
        assertionManager.releaseAllAssertions()
        state = .inactive
    }

    private func startTimedSession(
        startedAt: Date,
        endsAt: Date,
        allowBatteryStart: Bool
    ) -> Result<Void, SessionStartError> {
        if let error = startSafetyError(for: .timed, allowBatteryStart: allowBatteryStart) {
            lastStartError = error
            return .failure(error)
        }

        switch activateAssertionsForNewSession() {
        case .success:
            state = .activeUntilDate(startedAt: startedAt, endsAt: endsAt)
            timerToken = timerScheduler.schedule(at: endsAt) { [weak self] in
                self?.expireTimedSession()
            }
            return .success(())
        case let .failure(error):
            return .failure(error)
        }
    }

    private func startSafetyError(
        for sessionKind: SessionKind,
        allowBatteryStart: Bool
    ) -> SessionStartError? {
        powerMonitor.refresh()
        let snapshot = powerMonitor.snapshot

        let isAtOrBelowBatteryThreshold = snapshot.isAtOrBelowBatteryThreshold(settings.batteryThresholdPercent)

        if settings.disableBelowBatteryThreshold,
           isAtOrBelowBatteryThreshold {
            transitionToDisabledDueToBattery()
            sendBatteryLowNotificationIfEnabled()
            return .batteryThresholdReached
        }

        if !isAtOrBelowBatteryThreshold {
            batteryLowNotificationSent = false
        }

        if sessionKind == .indefinite,
           settings.onlyAllowIndefiniteWhilePluggedIn,
           snapshot.isOnBattery {
            state = .disabledDueToBattery
            return .indefiniteUnavailableOnBattery
        }

        if settings.warnBeforeRunningOnBattery,
           snapshot.isOnBattery,
           !allowBatteryStart {
            return .batteryConfirmationRequired
        }

        return nil
    }

    private func activateAssertionsForNewSession() -> Result<Void, SessionStartError> {
        cancelTimer()
        assertionManager.releaseAllAssertions()
        lastStartError = nil

        let assertionResult = assertionManager.activate(
            preventSystemSleep: settings.preventSystemSleep,
            preventDisplaySleep: settings.preventDisplaySleep
        )

        switch assertionResult {
        case .success:
            return .success(())
        case let .failure(error):
            state = .inactive
            assertionManager.releaseAllAssertions()
            let startError = SessionStartError.assertionFailed(error)
            lastStartError = startError
            return .failure(startError)
        }
    }

    private func expireTimedSession() {
        guard case .activeUntilDate = state else {
            return
        }

        timerToken = nil
        assertionManager.releaseAllAssertions()
        state = .inactive
        sendTimerEndedNotificationIfEnabled()
    }

    private func handlePowerSnapshotChange(_ snapshot: PowerSourceSnapshot) {
        defer { previousPowerSnapshot = snapshot }

        guard state.isActive else {
            return
        }

        let isAtOrBelowBatteryThreshold = snapshot.isAtOrBelowBatteryThreshold(settings.batteryThresholdPercent)

        if settings.disableBelowBatteryThreshold,
           isAtOrBelowBatteryThreshold {
            transitionToDisabledDueToBattery()
            sendBatteryLowNotificationIfEnabled()
            return
        }

        if !isAtOrBelowBatteryThreshold {
            batteryLowNotificationSent = false
        }

        let didUnplug = !previousPowerSnapshot.isOnBattery && snapshot.isOnBattery
        guard didUnplug else {
            return
        }

        if case .activeIndefinitely = state {
            if settings.autoDisableWhenUnplugged {
                transitionToDisabledDueToUnplugged()
                sendAutoDisabledWhenUnpluggedNotificationIfEnabled()
            } else {
                sendUnpluggedWhileActiveNotificationIfEnabled()
            }
        }
    }

    private func transitionToDisabledDueToBattery() {
        cancelTimer()
        assertionManager.releaseAllAssertions()
        state = .disabledDueToBattery
    }

    private func transitionToDisabledDueToUnplugged() {
        cancelTimer()
        assertionManager.releaseAllAssertions()
        state = .disabledDueToUnplugged
    }

    private func cancelTimer() {
        timerToken?.cancel()
        timerToken = nil
    }

    private func sendTimerEndedNotificationIfEnabled() {
        guard settings.notifyTimerEnded || settings.notifyMacCanSleepAgain else {
            return
        }

        notificationManager.send(.timerEnded)
    }

    private func sendBatteryLowNotificationIfEnabled() {
        guard settings.notifyBatteryLow, !batteryLowNotificationSent else {
            return
        }

        batteryLowNotificationSent = true
        notificationManager.send(.batteryLowDisabled)
    }

    private func sendUnpluggedWhileActiveNotificationIfEnabled() {
        guard settings.notifyUnpluggedWhileActive else {
            return
        }

        notificationManager.send(.unpluggedWhileActive)
    }

    private func sendAutoDisabledWhenUnpluggedNotificationIfEnabled() {
        guard settings.notifyAutoDisabledWhenUnplugged else {
            return
        }

        notificationManager.send(.autoDisabledWhenUnplugged)
    }
}

private enum SessionKind {
    case indefinite
    case timed
}
