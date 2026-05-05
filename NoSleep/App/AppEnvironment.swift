import Foundation

@MainActor
final class AppEnvironment {
    static let shared = AppEnvironment()

    let settingsStore: SettingsStore
    let powerMonitor: PowerMonitor
    let notificationManager: NotificationManager
    let loginItemManager: LoginItemManager
    let sleepAssertionManager: SleepAssertionManager
    let sessionController: SessionController

    convenience init() {
        let settingsStore = SettingsStore()
        let powerMonitor = PowerMonitor()
        let notificationManager = NotificationManager()
        let loginItemManager = LoginItemManager()
        let sleepAssertionManager = SleepAssertionManager()
        let sessionController = SessionController(
            settings: settingsStore,
            powerMonitor: powerMonitor,
            notificationManager: notificationManager,
            assertionManager: sleepAssertionManager
        )

        self.init(
            settingsStore: settingsStore,
            powerMonitor: powerMonitor,
            notificationManager: notificationManager,
            loginItemManager: loginItemManager,
            sleepAssertionManager: sleepAssertionManager,
            sessionController: sessionController
        )
    }

    init(
        settingsStore: SettingsStore,
        powerMonitor: PowerMonitor,
        notificationManager: NotificationManager,
        loginItemManager: LoginItemManager,
        sleepAssertionManager: SleepAssertionManager,
        sessionController: SessionController
    ) {
        self.settingsStore = settingsStore
        self.powerMonitor = powerMonitor
        self.notificationManager = notificationManager
        self.loginItemManager = loginItemManager
        self.sleepAssertionManager = sleepAssertionManager
        self.sessionController = sessionController
    }
}
