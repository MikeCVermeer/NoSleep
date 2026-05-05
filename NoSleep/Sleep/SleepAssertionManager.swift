import Combine
import Foundation

@MainActor
final class SleepAssertionManager: ObservableObject {
    private let client: IOPowerAssertionClient

    @Published private(set) var systemAssertionID: PowerAssertionID?
    @Published private(set) var displayAssertionID: PowerAssertionID?
    @Published private(set) var lastError: SleepAssertionError?

    convenience init() {
        self.init(client: IOKitPowerAssertionClient())
    }

    init(client: IOPowerAssertionClient) {
        self.client = client
    }

    deinit {
        MainActor.assumeIsolated {
            releaseAllAssertions()
        }
    }

    var diagnostics: AssertionDiagnostics {
        AssertionDiagnostics(
            systemAssertionID: systemAssertionID,
            displayAssertionID: displayAssertionID,
            lastErrorDescription: lastError?.localizedDescription
        )
    }

    @discardableResult
    func activate(preventSystemSleep: Bool = true, preventDisplaySleep: Bool = false) -> Result<Void, SleepAssertionError> {
        lastError = nil

        if preventSystemSleep {
            switch ensureSystemAssertion() {
            case .success:
                break
            case let .failure(error):
                lastError = error
                releaseAllAssertions()
                return .failure(error)
            }
        } else {
            releaseSystemAssertion()
        }

        if preventDisplaySleep {
            switch ensureDisplayAssertion() {
            case .success:
                break
            case let .failure(error):
                lastError = error
                releaseAllAssertions()
                return .failure(error)
            }
        } else {
            releaseDisplayAssertion()
        }

        return .success(())
    }

    func releaseAllAssertions() {
        releaseDisplayAssertion()
        releaseSystemAssertion()
    }

    private func ensureSystemAssertion() -> Result<Void, SleepAssertionError> {
        guard systemAssertionID == nil else {
            return .success(())
        }

        switch client.createAssertion(kind: .systemSleep) {
        case let .success(id):
            systemAssertionID = id
            return .success(())
        case let .failure(error):
            return .failure(error)
        }
    }

    private func ensureDisplayAssertion() -> Result<Void, SleepAssertionError> {
        guard displayAssertionID == nil else {
            return .success(())
        }

        switch client.createAssertion(kind: .displaySleep) {
        case let .success(id):
            displayAssertionID = id
            return .success(())
        case let .failure(error):
            return .failure(error)
        }
    }

    private func releaseSystemAssertion() {
        guard let id = systemAssertionID else {
            return
        }

        systemAssertionID = nil

        if case let .failure(error) = client.releaseAssertion(id: id) {
            lastError = error
        }
    }

    private func releaseDisplayAssertion() {
        guard let id = displayAssertionID else {
            return
        }

        displayAssertionID = nil

        if case let .failure(error) = client.releaseAssertion(id: id) {
            lastError = error
        }
    }
}
