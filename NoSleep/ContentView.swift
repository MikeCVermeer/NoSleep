import SwiftUI

struct ContentView: View {
    @StateObject private var settings = AppEnvironment.shared.settingsStore
    @StateObject private var sessionController = AppEnvironment.shared.sessionController
    @StateObject private var assertionManager = AppEnvironment.shared.sleepAssertionManager
    @StateObject private var powerMonitor = AppEnvironment.shared.powerMonitor
    @StateObject private var notificationManager = AppEnvironment.shared.notificationManager
    @StateObject private var loginItemManager = AppEnvironment.shared.loginItemManager

    var body: some View {
        SettingsView(
            settings: settings,
            sessionController: sessionController,
            assertionManager: assertionManager,
            powerMonitor: powerMonitor,
            notificationManager: notificationManager,
            loginItemManager: loginItemManager
        )
    }
}

#Preview {
    ContentView()
}
