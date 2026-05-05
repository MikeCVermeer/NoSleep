import XCTest
@testable import NoSleep

final class UntilSpecificTimeCalculatorTests: XCTestCase {
    func testUsesTodayWhenSelectedTimeIsInTheFuture() throws {
        let calendar = calendar
        let now = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 5, day: 4, hour: 10, minute: 30)))
        let selectedTime = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 1, day: 1, hour: 18, minute: 45)))

        let result = UntilSpecificTimeCalculator.nextDate(
            matchingHourAndMinuteFrom: selectedTime,
            now: now,
            calendar: calendar
        )

        XCTAssertEqual(
            result,
            try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 5, day: 4, hour: 18, minute: 45)))
        )
    }

    func testUsesTomorrowWhenSelectedTimeHasPassedToday() throws {
        let calendar = calendar
        let now = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 5, day: 4, hour: 18, minute: 30)))
        let selectedTime = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 1, day: 1, hour: 10, minute: 15)))

        let result = UntilSpecificTimeCalculator.nextDate(
            matchingHourAndMinuteFrom: selectedTime,
            now: now,
            calendar: calendar
        )

        XCTAssertEqual(
            result,
            try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 5, day: 5, hour: 10, minute: 15)))
        )
    }

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }
}
