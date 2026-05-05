import Foundation

@MainActor
protocol NotificationManaging: AnyObject {
    func requestAuthorizationIfNeeded()
    func send(_ event: NoSleepNotificationEvent)
}

@MainActor
final class NullNotificationManager: NotificationManaging {
    func requestAuthorizationIfNeeded() {}
    func send(_ event: NoSleepNotificationEvent) {}
}
