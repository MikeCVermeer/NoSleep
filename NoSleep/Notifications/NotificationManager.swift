import Combine
import Foundation
import UserNotifications

@MainActor
final class NotificationManager: ObservableObject, NotificationManaging {
    @Published private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published private(set) var lastErrorDescription: String?

    private let center: UNUserNotificationCenter

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
        refreshAuthorizationStatus()
    }

    func requestAuthorizationIfNeeded() {
        Task {
            await requestAuthorizationIfNeededAsync()
        }
    }

    func send(_ event: NoSleepNotificationEvent) {
        Task {
            await requestAuthorizationIfNeededAsync()

            let content = UNMutableNotificationContent()
            content.title = event.title
            content.body = event.body
            content.sound = .default

            let request = UNNotificationRequest(
                identifier: event.identifier,
                content: content,
                trigger: nil
            )

            do {
                try await center.add(request)
                lastErrorDescription = nil
            } catch {
                lastErrorDescription = error.localizedDescription
            }
        }
    }

    private func refreshAuthorizationStatus() {
        Task {
            authorizationStatus = await center.notificationSettings().authorizationStatus
        }
    }

    private func requestAuthorizationIfNeededAsync() async {
        let settings = await center.notificationSettings()

        guard settings.authorizationStatus == .notDetermined else {
            authorizationStatus = settings.authorizationStatus
            return
        }

        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound])
            authorizationStatus = granted ? .authorized : .denied
            lastErrorDescription = nil
        } catch {
            authorizationStatus = .denied
            lastErrorDescription = error.localizedDescription
        }
    }
}
