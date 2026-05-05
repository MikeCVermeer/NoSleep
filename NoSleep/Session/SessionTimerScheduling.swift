import Foundation

@MainActor
protocol SessionTimerToken {
    func cancel()
}

@MainActor
protocol SessionTimerScheduling {
    func schedule(at date: Date, action: @escaping @MainActor () -> Void) -> SessionTimerToken
}

@MainActor
final class FoundationSessionTimerScheduler: SessionTimerScheduling {
    func schedule(at date: Date, action: @escaping @MainActor () -> Void) -> SessionTimerToken {
        let interval = max(0, date.timeIntervalSinceNow)
        let timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { _ in
            Task { @MainActor in
                action()
            }
        }

        return FoundationSessionTimerToken(timer: timer)
    }
}

@MainActor
private final class FoundationSessionTimerToken: SessionTimerToken {
    private weak var timer: Timer?

    init(timer: Timer) {
        self.timer = timer
    }

    func cancel() {
        timer?.invalidate()
    }
}

