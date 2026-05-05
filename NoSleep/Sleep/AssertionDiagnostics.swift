import Foundation

struct AssertionDiagnostics: Equatable {
    let systemAssertionID: PowerAssertionID?
    let displayAssertionID: PowerAssertionID?
    let lastErrorDescription: String?

    var isSystemAssertionActive: Bool {
        systemAssertionID != nil
    }

    var isDisplayAssertionActive: Bool {
        displayAssertionID != nil
    }

    var hasActiveAssertions: Bool {
        isSystemAssertionActive || isDisplayAssertionActive
    }
}

