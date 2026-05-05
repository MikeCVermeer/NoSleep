import XCTest
@testable import NoSleep

@MainActor
final class SleepAssertionManagerTests: XCTestCase {
    func testActivatingSystemSleepCreatesSystemAssertionOnlyByDefault() {
        let client = MockPowerAssertionClient()
        let manager = SleepAssertionManager(client: client)

        let result = manager.activate()

        XCTAssertSuccess(result)
        XCTAssertEqual(client.createdKinds, [.systemSleep])
        XCTAssertEqual(manager.systemAssertionID, 100)
        XCTAssertNil(manager.displayAssertionID)
        XCTAssertTrue(manager.diagnostics.isSystemAssertionActive)
        XCTAssertFalse(manager.diagnostics.isDisplayAssertionActive)
    }

    func testActivatingDisplaySleepCreatesSeparateDisplayAssertion() {
        let client = MockPowerAssertionClient()
        let manager = SleepAssertionManager(client: client)

        let result = manager.activate(preventSystemSleep: true, preventDisplaySleep: true)

        XCTAssertSuccess(result)
        XCTAssertEqual(client.createdKinds, [.systemSleep, .displaySleep])
        XCTAssertEqual(manager.systemAssertionID, 100)
        XCTAssertEqual(manager.displayAssertionID, 101)
    }

    func testChangingDisplaySleepOffReleasesOnlyDisplayAssertion() {
        let client = MockPowerAssertionClient()
        let manager = SleepAssertionManager(client: client)

        _ = manager.activate(preventSystemSleep: true, preventDisplaySleep: true)
        _ = manager.activate(preventSystemSleep: true, preventDisplaySleep: false)

        XCTAssertEqual(manager.systemAssertionID, 100)
        XCTAssertNil(manager.displayAssertionID)
        XCTAssertEqual(client.releasedIDs, [101])
    }

    func testReleaseAllAssertionsReleasesDisplayBeforeSystem() {
        let client = MockPowerAssertionClient()
        let manager = SleepAssertionManager(client: client)

        _ = manager.activate(preventSystemSleep: true, preventDisplaySleep: true)
        manager.releaseAllAssertions()

        XCTAssertNil(manager.systemAssertionID)
        XCTAssertNil(manager.displayAssertionID)
        XCTAssertEqual(client.releasedIDs, [101, 100])
        XCTAssertFalse(manager.diagnostics.hasActiveAssertions)
    }

    func testSystemAssertionCreationFailureDoesNotLeaveActiveState() {
        let error = SleepAssertionError.createFailed(kind: .systemSleep, code: -1)
        let client = MockPowerAssertionClient(createResults: [.failure(error)])
        let manager = SleepAssertionManager(client: client)

        let result = manager.activate(preventSystemSleep: true, preventDisplaySleep: false)

        XCTAssertFailure(result, equals: error)
        XCTAssertNil(manager.systemAssertionID)
        XCTAssertNil(manager.displayAssertionID)
        XCTAssertEqual(manager.lastError, error)
        XCTAssertFalse(manager.diagnostics.hasActiveAssertions)
    }

    func testDisplayAssertionCreationFailureReleasesSystemAssertion() {
        let error = SleepAssertionError.createFailed(kind: .displaySleep, code: -2)
        let client = MockPowerAssertionClient(createResults: [.success(200), .failure(error)])
        let manager = SleepAssertionManager(client: client)

        let result = manager.activate(preventSystemSleep: true, preventDisplaySleep: true)

        XCTAssertFailure(result, equals: error)
        XCTAssertNil(manager.systemAssertionID)
        XCTAssertNil(manager.displayAssertionID)
        XCTAssertEqual(client.releasedIDs, [200])
        XCTAssertEqual(manager.lastError, error)
    }

    func testRepeatedActivateDoesNotCreateDuplicateAssertions() {
        let client = MockPowerAssertionClient()
        let manager = SleepAssertionManager(client: client)

        _ = manager.activate(preventSystemSleep: true, preventDisplaySleep: true)
        _ = manager.activate(preventSystemSleep: true, preventDisplaySleep: true)

        XCTAssertEqual(client.createdKinds, [.systemSleep, .displaySleep])
        XCTAssertEqual(manager.systemAssertionID, 100)
        XCTAssertEqual(manager.displayAssertionID, 101)
    }
}

private func XCTAssertSuccess(
    _ result: Result<Void, SleepAssertionError>,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    if case let .failure(error) = result {
        XCTFail("Expected success, got failure: \(error)", file: file, line: line)
    }
}

private func XCTAssertFailure(
    _ result: Result<Void, SleepAssertionError>,
    equals expectedError: SleepAssertionError,
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
