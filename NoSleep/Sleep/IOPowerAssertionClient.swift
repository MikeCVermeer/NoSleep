import Foundation
import IOKit.pwr_mgt

typealias PowerAssertionID = IOPMAssertionID

enum PowerAssertionKind: Equatable {
    case systemSleep
    case displaySleep

    nonisolated static func == (lhs: PowerAssertionKind, rhs: PowerAssertionKind) -> Bool {
        switch (lhs, rhs) {
        case (.systemSleep, .systemSleep), (.displaySleep, .displaySleep):
            true
        case (.systemSleep, .displaySleep), (.displaySleep, .systemSleep):
            false
        }
    }

    var assertionName: String {
        switch self {
        case .systemSleep:
            "NoSleep system sleep prevention"
        case .displaySleep:
            "NoSleep display sleep prevention"
        }
    }

    fileprivate var iokitAssertionType: CFString {
        switch self {
        case .systemSleep:
            kIOPMAssertionTypeNoIdleSleep as CFString
        case .displaySleep:
            kIOPMAssertionTypeNoDisplaySleep as CFString
        }
    }
}

@MainActor
protocol IOPowerAssertionClient {
    func createAssertion(kind: PowerAssertionKind) -> Result<PowerAssertionID, SleepAssertionError>
    func releaseAssertion(id: PowerAssertionID) -> Result<Void, SleepAssertionError>
}

struct IOKitPowerAssertionClient: IOPowerAssertionClient {
    func createAssertion(kind: PowerAssertionKind) -> Result<PowerAssertionID, SleepAssertionError> {
        var assertionID = PowerAssertionID(0)
        let result = IOPMAssertionCreateWithName(
            kind.iokitAssertionType,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            kind.assertionName as CFString,
            &assertionID
        )

        guard result == kIOReturnSuccess else {
            return .failure(.createFailed(kind: kind, code: result))
        }

        return .success(assertionID)
    }

    func releaseAssertion(id: PowerAssertionID) -> Result<Void, SleepAssertionError> {
        let result = IOPMAssertionRelease(id)

        guard result == kIOReturnSuccess else {
            return .failure(.releaseFailed(id: id, code: result))
        }

        return .success(())
    }
}
