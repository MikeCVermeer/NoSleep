import SwiftUI

@main
struct NoSleepApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var sessionController = AppEnvironment.shared.sessionController
    @StateObject private var powerMonitor = AppEnvironment.shared.powerMonitor
    @StateObject private var settings = AppEnvironment.shared.settingsStore
    @StateObject private var notificationManager = AppEnvironment.shared.notificationManager
    @StateObject private var loginItemManager = AppEnvironment.shared.loginItemManager

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(
                sessionController: sessionController,
                powerMonitor: powerMonitor,
                settings: settings
            )
        } label: {
            if settings.showTimerInMenuBar, let endDate = sessionController.activeTimerEndDate {
                Label(
                    TimeRemainingFormatter.string(until: endDate),
                    systemImage: statusIconName
                )
            } else {
                Image(systemName: statusIconName)
            }
        }
        .menuBarExtraStyle(.menu)

        Settings {
            SettingsView(
                settings: settings,
                sessionController: sessionController,
                assertionManager: AppEnvironment.shared.sleepAssertionManager,
                powerMonitor: powerMonitor,
                notificationManager: notificationManager,
                loginItemManager: loginItemManager
            )
        }

        Window("Until Specific Time", id: UntilSpecificTimeView.windowID) {
            UntilSpecificTimeView(
                sessionController: sessionController,
                powerMonitor: powerMonitor,
                settings: settings
            )
        }
        .windowResizability(.contentSize)
    }

    private var statusIconName: String {
        guard settings.showActiveStateInIcon else {
            return "power.circle"
        }

        return StatusIconState(sessionState: sessionController.state).systemImageName
    }
}
