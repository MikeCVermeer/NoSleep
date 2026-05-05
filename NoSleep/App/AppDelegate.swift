import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let workspaceNotificationCenter = NSWorkspace.shared.notificationCenter

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        workspaceNotificationCenter.addObserver(
            self,
            selector: #selector(workspaceWillSleep),
            name: NSWorkspace.willSleepNotification,
            object: nil
        )
        workspaceNotificationCenter.addObserver(
            self,
            selector: #selector(workspaceDidWake),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )
    }

    func applicationWillTerminate(_ notification: Notification) {
        workspaceNotificationCenter.removeObserver(self)
        AppEnvironment.shared.sleepAssertionManager.releaseAllAssertions()
    }

    @objc private func workspaceWillSleep(_ notification: Notification) {
        AppEnvironment.shared.sessionController.handleSystemWillSleep()
    }

    @objc private func workspaceDidWake(_ notification: Notification) {
        AppEnvironment.shared.sessionController.handleSystemDidWake()
    }
}
