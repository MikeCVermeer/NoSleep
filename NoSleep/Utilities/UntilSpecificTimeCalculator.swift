import Foundation

enum UntilSpecificTimeCalculator {
    static func nextDate(
        matchingHourAndMinuteFrom selectedTime: Date,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> Date {
        let selectedComponents = calendar.dateComponents([.hour, .minute], from: selectedTime)
        let nowComponents = calendar.dateComponents([.year, .month, .day], from: now)

        var targetComponents = DateComponents()
        targetComponents.year = nowComponents.year
        targetComponents.month = nowComponents.month
        targetComponents.day = nowComponents.day
        targetComponents.hour = selectedComponents.hour
        targetComponents.minute = selectedComponents.minute

        let todayTarget = calendar.date(from: targetComponents) ?? selectedTime

        if todayTarget > now {
            return todayTarget
        }

        return calendar.date(byAdding: .day, value: 1, to: todayTarget) ?? todayTarget
    }
}
