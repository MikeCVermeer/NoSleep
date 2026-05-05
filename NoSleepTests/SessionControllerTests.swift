import Combine
import XCTest
@testable import NoSleep

@MainActor
final class SessionControllerTests: XCTestCase {
    func testStartIndefiniteActivatesAssertionsAndState() {
        let context = makeContext()

        let result = context.controller.startIndefinite()

        XCTAssertSuccess(result)
        XCTAssertEqual(context.assertionClient.createdKinds, [.systemSleep])
        XCTAssertEqual(context.controller.state, .activeIndefinitely(startedAt: context.now))
        XCTAssertNil(context.controller.activeTimerEndDate)
    }

    func testStartTimedPresetActivatesAssertionsAndSchedulesExpiry() {
        let context = makeContext()

        let result = context.controller.start(durationPreset: .thirtyMinutes)

        XCTAssertSuccess(result)
        XCTAssertEqual(context.assertionClient.createdKinds, [.systemSleep])
        XCTAssertEqual(
            context.controller.state,
            .activeUntilDate(
                startedAt: context.now,
                endsAt: Date(timeInterval: DurationPreset.thirtyMinutes.timeInterval, since: context.now)
            )
        )
        XCTAssertEqual(context.scheduler.scheduledDates, [Date(timeInterval: 30 * 60, since: context.now)])
    }

    func testStartUntilDateUsesProvidedEndDate() {
        let context = makeContext()
        let endDate = Date(timeInterval: 45 * 60, since: context.now)

        let result = context.controller.start(until: endDate)

        XCTAssertSuccess(result)
        XCTAssertEqual(context.controller.state, .activeUntilDate(startedAt: context.now, endsAt: endDate))
        XCTAssertEqual(context.controller.activeTimerEndDate, endDate)
    }

    func testStartUntilDateRejectsPastDateWithoutCreatingAssertion() {
        let context = makeContext()
        let endDate = Date(timeInterval: -60, since: context.now)

        let result = context.controller.start(until: endDate)

        XCTAssertFailure(result, equals: .invalidEndDate)
        XCTAssertEqual(context.controller.state, .inactive)
        XCTAssertTrue(context.assertionClient.createdKinds.isEmpty)
        XCTAssertEqual(context.controller.lastStartError, .invalidEndDate)
    }

    func testStopReleasesAssertionsAndCancelsTimer() {
        let context = makeContext()

        _ = context.controller.start(durationPreset: .oneHour)
        context.controller.stop()

        XCTAssertEqual(context.controller.state, .inactive)
        XCTAssertEqual(context.assertionClient.releasedIDs, [100])
        XCTAssertEqual(context.scheduler.tokens.map(\.isCancelled), [true])
    }

    func testSystemWillSleepTurnsOffByDefaultAndReleasesAssertions() {
        let context = makeContext()

        _ = context.controller.start(durationPreset: .oneHour)
        context.controller.handleSystemWillSleep()

        XCTAssertEqual(context.controller.state, .inactive)
        XCTAssertEqual(context.assertionClient.releasedIDs, [100])
        XCTAssertEqual(context.scheduler.tokens.map(\.isCancelled), [true])
    }

    func testSystemDidWakeDoesNotResumeByDefault() {
        let context = makeContext()

        _ = context.controller.startIndefinite()
        context.controller.handleSystemWillSleep()
        context.controller.handleSystemDidWake()

        XCTAssertEqual(context.controller.state, .inactive)
        XCTAssertEqual(context.assertionClient.createdKinds, [.systemSleep])
    }

    func testResumeAfterWakeRestartsIndefiniteSession() {
        let context = makeContext()
        context.settings.sleepWakeBehavior = .resumeAfterWake

        _ = context.controller.startIndefinite()
        context.controller.handleSystemWillSleep()
        context.controller.handleSystemDidWake()

        XCTAssertEqual(context.controller.state, .activeIndefinitely(startedAt: context.now))
        XCTAssertEqual(context.assertionClient.createdKinds, [.systemSleep, .systemSleep])
        XCTAssertEqual(context.assertionClient.releasedIDs, [100])
    }

    func testResumeAfterWakeRestartsFutureTimedSession() {
        let context = makeContext()
        context.settings.sleepWakeBehavior = .resumeAfterWake
        let endDate = Date(timeInterval: 45 * 60, since: context.now)

        _ = context.controller.start(until: endDate)
        context.controller.handleSystemWillSleep()
        context.controller.handleSystemDidWake()

        XCTAssertEqual(context.controller.state, .activeUntilDate(startedAt: context.now, endsAt: endDate))
        XCTAssertEqual(context.assertionClient.createdKinds, [.systemSleep, .systemSleep])
        XCTAssertEqual(context.scheduler.scheduledDates, [endDate, endDate])
    }

    func testTimerExpiryReleasesAssertionsAndMarksInactive() {
        let context = makeContext()

        _ = context.controller.start(durationPreset: .fifteenMinutes)
        context.scheduler.fireLast()

        XCTAssertEqual(context.controller.state, .inactive)
        XCTAssertEqual(context.assertionClient.releasedIDs, [100])
    }

    func testTimerExpirySendsNotificationWhenEnabled() {
        let context = makeContext()

        _ = context.controller.start(durationPreset: .fifteenMinutes)
        context.scheduler.fireLast()

        XCTAssertEqual(context.notificationManager.sentEvents, [.timerEnded])
    }

    func testTimerExpiryDoesNotSendNotificationWhenDisabled() {
        let context = makeContext()
        context.settings.notifyTimerEnded = false
        context.settings.notifyMacCanSleepAgain = false

        _ = context.controller.start(durationPreset: .fifteenMinutes)
        context.scheduler.fireLast()

        XCTAssertTrue(context.notificationManager.sentEvents.isEmpty)
    }

    func testStartingNewSessionReleasesPreviousAssertionsAndCancelsPreviousTimer() {
        let context = makeContext()

        _ = context.controller.start(durationPreset: .fifteenMinutes)
        _ = context.controller.startIndefinite()

        XCTAssertEqual(context.assertionClient.createdKinds, [.systemSleep, .systemSleep])
        XCTAssertEqual(context.assertionClient.releasedIDs, [100])
        XCTAssertEqual(context.scheduler.tokens.map(\.isCancelled), [true])
        XCTAssertEqual(context.controller.state, .activeIndefinitely(startedAt: context.now))
    }

    func testAssertionFailureDoesNotLeaveActiveState() {
        let error = SleepAssertionError.createFailed(kind: .systemSleep, code: -1)
        let context = makeContext(createResults: [.failure(error)])

        let result = context.controller.startIndefinite()

        XCTAssertFailure(result, equals: .assertionFailed(error))
        XCTAssertEqual(context.controller.state, .inactive)
        XCTAssertEqual(context.controller.lastStartError, .assertionFailed(error))
        XCTAssertFalse(context.assertionManager.diagnostics.hasActiveAssertions)
    }

    func testDisplaySleepSettingCreatesDisplayAssertionToo() {
        let context = makeContext()
        context.settings.preventDisplaySleep = true

        let result = context.controller.startIndefinite()

        XCTAssertSuccess(result)
        XCTAssertEqual(context.assertionClient.createdKinds, [.systemSleep, .displaySleep])
    }

    func testIndefiniteSessionIsBlockedOnBatteryByDefault() {
        let context = makeContext(
            initialPowerSnapshot: PowerSourceSnapshot(source: .onBattery, batteryPercentage: 80, hasBattery: true)
        )

        let result = context.controller.startIndefinite()

        XCTAssertFailure(result, equals: .indefiniteUnavailableOnBattery)
        XCTAssertEqual(context.controller.state, .disabledDueToBattery)
        XCTAssertTrue(context.assertionClient.createdKinds.isEmpty)
    }

    func testTimedSessionOnBatteryRequiresConfirmationByDefault() {
        let context = makeContext(
            initialPowerSnapshot: PowerSourceSnapshot(source: .onBattery, batteryPercentage: 80, hasBattery: true)
        )

        let result = context.controller.start(durationPreset: .fifteenMinutes)

        XCTAssertFailure(result, equals: .batteryConfirmationRequired)
        XCTAssertEqual(context.controller.state, .inactive)
        XCTAssertTrue(context.assertionClient.createdKinds.isEmpty)
    }

    func testTimedSessionOnBatteryStartsAfterConfirmation() {
        let context = makeContext(
            initialPowerSnapshot: PowerSourceSnapshot(source: .onBattery, batteryPercentage: 80, hasBattery: true)
        )

        let result = context.controller.start(durationPreset: .fifteenMinutes, allowBatteryStart: true)

        XCTAssertSuccess(result)
        XCTAssertEqual(context.assertionClient.createdKinds, [.systemSleep])
        XCTAssertEqual(
            context.controller.state,
            .activeUntilDate(
                startedAt: context.now,
                endsAt: Date(timeInterval: DurationPreset.fifteenMinutes.timeInterval, since: context.now)
            )
        )
    }

    func testStartAtBatteryThresholdDisablesWithoutCreatingAssertion() {
        let context = makeContext(
            initialPowerSnapshot: PowerSourceSnapshot(source: .onBattery, batteryPercentage: 20, hasBattery: true)
        )

        let result = context.controller.start(durationPreset: .fifteenMinutes, allowBatteryStart: true)

        XCTAssertFailure(result, equals: .batteryThresholdReached)
        XCTAssertEqual(context.controller.state, .disabledDueToBattery)
        XCTAssertTrue(context.assertionClient.createdKinds.isEmpty)
        XCTAssertEqual(context.notificationManager.sentEvents, [.batteryLowDisabled])
    }

    func testActiveSessionDisablesWhenBatteryThresholdIsReached() {
        let context = makeContext(
            initialPowerSnapshot: PowerSourceSnapshot(source: .onBattery, batteryPercentage: 80, hasBattery: true)
        )

        _ = context.controller.start(durationPreset: .fifteenMinutes, allowBatteryStart: true)
        context.powerMonitor.update(PowerSourceSnapshot(source: .onBattery, batteryPercentage: 20, hasBattery: true))

        XCTAssertEqual(context.controller.state, .disabledDueToBattery)
        XCTAssertEqual(context.assertionClient.releasedIDs, [100])
        XCTAssertEqual(context.scheduler.tokens.map(\.isCancelled), [true])
        XCTAssertEqual(context.notificationManager.sentEvents, [.batteryLowDisabled])
    }

    func testBatteryLowNotificationDoesNotRepeatUntilConditionClears() {
        let context = makeContext(
            initialPowerSnapshot: PowerSourceSnapshot(source: .onBattery, batteryPercentage: 20, hasBattery: true)
        )

        _ = context.controller.start(durationPreset: .fifteenMinutes, allowBatteryStart: true)
        _ = context.controller.start(durationPreset: .fifteenMinutes, allowBatteryStart: true)

        XCTAssertEqual(context.notificationManager.sentEvents, [.batteryLowDisabled])

        context.powerMonitor.update(PowerSourceSnapshot(source: .onBattery, batteryPercentage: 80, hasBattery: true))
        _ = context.controller.start(durationPreset: .fifteenMinutes, allowBatteryStart: true)
        context.powerMonitor.update(PowerSourceSnapshot(source: .onBattery, batteryPercentage: 20, hasBattery: true))

        XCTAssertEqual(context.notificationManager.sentEvents, [.batteryLowDisabled, .batteryLowDisabled])
    }

    func testIndefiniteSessionAutoDisablesWhenUnpluggedSettingIsEnabled() {
        let context = makeContext(
            initialPowerSnapshot: PowerSourceSnapshot(source: .pluggedIn, batteryPercentage: 80, hasBattery: true)
        )
        context.settings.autoDisableWhenUnplugged = true

        _ = context.controller.startIndefinite()
        context.powerMonitor.update(PowerSourceSnapshot(source: .onBattery, batteryPercentage: 80, hasBattery: true))

        XCTAssertEqual(context.controller.state, .disabledDueToUnplugged)
        XCTAssertEqual(context.assertionClient.releasedIDs, [100])
        XCTAssertEqual(context.notificationManager.sentEvents, [.autoDisabledWhenUnplugged])
    }

    func testIndefiniteSessionRemainsActiveWhenUnpluggedByDefault() {
        let context = makeContext(
            initialPowerSnapshot: PowerSourceSnapshot(source: .pluggedIn, batteryPercentage: 80, hasBattery: true)
        )

        _ = context.controller.startIndefinite()
        context.powerMonitor.update(PowerSourceSnapshot(source: .onBattery, batteryPercentage: 80, hasBattery: true))

        XCTAssertEqual(context.controller.state, .activeIndefinitely(startedAt: context.now))
        XCTAssertTrue(context.assertionClient.releasedIDs.isEmpty)
        XCTAssertEqual(context.notificationManager.sentEvents, [.unpluggedWhileActive])
    }

    func testUnpluggedNotificationRespectsSetting() {
        let context = makeContext(
            initialPowerSnapshot: PowerSourceSnapshot(source: .pluggedIn, batteryPercentage: 80, hasBattery: true)
        )
        context.settings.notifyUnpluggedWhileActive = false

        _ = context.controller.startIndefinite()
        context.powerMonitor.update(PowerSourceSnapshot(source: .onBattery, batteryPercentage: 80, hasBattery: true))

        XCTAssertTrue(context.notificationManager.sentEvents.isEmpty)
    }

    private func makeContext(
        createResults: [Result<PowerAssertionID, SleepAssertionError>] = [],
        initialPowerSnapshot: PowerSourceSnapshot = PowerSourceSnapshot(source: .pluggedIn, batteryPercentage: 80, hasBattery: true)
    ) -> SessionControllerTestContext {
        let now = Date(timeIntervalSince1970: 1_000)
        let defaults = UserDefaults(suiteName: "NoSleepSessionControllerTests.\(UUID().uuidString)")!
        let settings = SettingsStore(defaults: defaults)
        let powerMonitor = MockPowerMonitor(snapshot: initialPowerSnapshot)
        let notificationManager = MockNotificationManager()
        let assertionClient = MockPowerAssertionClient(createResults: createResults)
        let assertionManager = SleepAssertionManager(client: assertionClient)
        let scheduler = ManualSessionTimerScheduler()
        let controller = SessionController(
            settings: settings,
            powerMonitor: powerMonitor,
            notificationManager: notificationManager,
            assertionManager: assertionManager,
            timerScheduler: scheduler,
            now: { now }
        )

        return SessionControllerTestContext(
            now: now,
            settings: settings,
            powerMonitor: powerMonitor,
            notificationManager: notificationManager,
            assertionClient: assertionClient,
            assertionManager: assertionManager,
            scheduler: scheduler,
            controller: controller
        )
    }
}

@MainActor
private struct SessionControllerTestContext {
    let now: Date
    let settings: SettingsStore
    let powerMonitor: MockPowerMonitor
    let notificationManager: MockNotificationManager
    let assertionClient: MockPowerAssertionClient
    let assertionManager: SleepAssertionManager
    let scheduler: ManualSessionTimerScheduler
    let controller: SessionController
}

@MainActor
private final class MockNotificationManager: NotificationManaging {
    private(set) var requestAuthorizationCallCount = 0
    private(set) var sentEvents: [NoSleepNotificationEvent] = []

    func requestAuthorizationIfNeeded() {
        requestAuthorizationCallCount += 1
    }

    func send(_ event: NoSleepNotificationEvent) {
        sentEvents.append(event)
    }
}

@MainActor
private final class MockPowerMonitor: PowerMonitoring {
    private let subject = PassthroughSubject<PowerSourceSnapshot, Never>()

    private(set) var refreshCallCount = 0
    private(set) var snapshot: PowerSourceSnapshot

    var snapshotPublisher: AnyPublisher<PowerSourceSnapshot, Never> {
        subject.eraseToAnyPublisher()
    }

    init(snapshot: PowerSourceSnapshot) {
        self.snapshot = snapshot
    }

    func refresh() {
        refreshCallCount += 1
    }

    func update(_ snapshot: PowerSourceSnapshot) {
        self.snapshot = snapshot
        subject.send(snapshot)
    }
}

@MainActor
private final class ManualSessionTimerScheduler: SessionTimerScheduling {
    private(set) var scheduledDates: [Date] = []
    private(set) var tokens: [ManualSessionTimerToken] = []

    func schedule(at date: Date, action: @escaping @MainActor () -> Void) -> SessionTimerToken {
        scheduledDates.append(date)
        let token = ManualSessionTimerToken(action: action)
        tokens.append(token)
        return token
    }

    func fireLast() {
        tokens.last?.fire()
    }
}

@MainActor
private final class ManualSessionTimerToken: SessionTimerToken {
    private let action: @MainActor () -> Void
    private(set) var isCancelled = false

    init(action: @escaping @MainActor () -> Void) {
        self.action = action
    }

    func cancel() {
        isCancelled = true
    }

    func fire() {
        guard !isCancelled else {
            return
        }

        action()
    }
}

@MainActor
private final class MockPowerAssertionClient: IOPowerAssertionClient {
    private var nextID: PowerAssertionID = 100
    private var createResults: [Result<PowerAssertionID, SleepAssertionError>]

    private(set) var createdKinds: [PowerAssertionKind] = []
    private(set) var releasedIDs: [PowerAssertionID] = []

    init(createResults: [Result<PowerAssertionID, SleepAssertionError>] = []) {
        self.createResults = createResults
    }

    func createAssertion(kind: PowerAssertionKind) -> Result<PowerAssertionID, SleepAssertionError> {
        createdKinds.append(kind)

        if !createResults.isEmpty {
            return createResults.removeFirst()
        }

        defer { nextID += 1 }
        return .success(nextID)
    }

    func releaseAssertion(id: PowerAssertionID) -> Result<Void, SleepAssertionError> {
        releasedIDs.append(id)
        return .success(())
    }
}

private func XCTAssertSuccess(
    _ result: Result<Void, SessionStartError>,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    if case let .failure(error) = result {
        XCTFail("Expected success, got failure: \(error)", file: file, line: line)
    }
}

private func XCTAssertFailure(
    _ result: Result<Void, SessionStartError>,
    equals expectedError: SessionStartError,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    switch result {
    case .success:
        XCTFail("Expected failure, got success.", file: file, line: line)
    case let .failure(error):
        XCTAssertEqual(error, expectedError, file: file, line: line)
    }
}
