import Combine
import Foundation
import ServiceManagement

@MainActor
final class LoginItemManager: ObservableObject {
    @Published private(set) var isEnabled: Bool
    @Published private(set) var lastErrorDescription: String?

    init() {
        isEnabled = Self.currentStatusIsEnabled()
    }

    @discardableResult
    func setEnabled(_ enabled: Bool) -> Bool {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }

            lastErrorDescription = nil
            refresh()
            return true
        } catch {
            lastErrorDescription = error.localizedDescription
            refresh()
            return false
        }
    }

    func refresh() {
        isEnabled = Self.currentStatusIsEnabled()
    }

    private static func currentStatusIsEnabled() -> Bool {
        SMAppService.mainApp.status == .enabled
    }
}
