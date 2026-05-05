import Foundation

enum TimeRemainingFormatter {
    static func string(from remainingTime: TimeInterval) -> String {
        let totalMinutes = max(0, Int(ceil(remainingTime / 60)))

        if totalMinutes < 60 {
            return "\(totalMinutes)m"
        }

        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        if hours < 24 {
            return minutes == 0 ? "\(hours)h" : "\(hours)h \(minutes)m"
        }

        let days = hours / 24
        let remainingHours = hours % 24

        return remainingHours == 0 ? "\(days)d" : "\(days)d \(remainingHours)h"
    }

    static func string(until endDate: Date, now: Date = Date()) -> String {
        string(from: endDate.timeIntervalSince(now))
    }
}

