import XCTest
@testable import NoSleep

final class TimeRemainingFormatterTests: XCTestCase {
    func testFormatsMinutes() {
        XCTAssertEqual(TimeRemainingFormatter.string(from: 60), "1m")
        XCTAssertEqual(TimeRemainingFormatter.string(from: 29 * 60), "29m")
    }

    func testRoundsPartialMinutesUp() {
        XCTAssertEqual(TimeRemainingFormatter.string(from: 61), "2m")
    }

    func testFormatsHoursAndMinutes() {
        XCTAssertEqual(TimeRemainingFormatter.string(from: 60 * 60), "1h")
        XCTAssertEqual(TimeRemainingFormatter.string(from: 84 * 60), "1h 24m")
    }

    func testFormatsExpiredTimeAsZeroMinutes() {
        XCTAssertEqual(TimeRemainingFormatter.string(from: -10), "0m")
    }

    func testFormatsUntilDate() {
        let now = Date(timeIntervalSince1970: 1_000)
        let endDate = Date(timeIntervalSince1970: 1_000 + 90 * 60)

        XCTAssertEqual(TimeRemainingFormatter.string(until: endDate, now: now), "1h 30m")
    }
}

