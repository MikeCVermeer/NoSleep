import XCTest
@testable import NoSleep

final class DurationPresetTests: XCTestCase {
    func testPresetMinutesMatchSpec() {
        XCTAssertEqual(DurationPreset.allCases.map(\.minutes), [15, 30, 60, 120, 240])
    }

    func testPresetLabelsMatchMenuCopy() {
        XCTAssertEqual(DurationPreset.fifteenMinutes.label, "15 minutes")
        XCTAssertEqual(DurationPreset.thirtyMinutes.label, "30 minutes")
        XCTAssertEqual(DurationPreset.oneHour.label, "1 hour")
        XCTAssertEqual(DurationPreset.twoHours.label, "2 hours")
        XCTAssertEqual(DurationPreset.fourHours.label, "4 hours")
    }

    func testEndDateCalculation() {
        let startDate = Date(timeIntervalSince1970: 1_000)

        XCTAssertEqual(DurationPreset.fifteenMinutes.endDate(startingAt: startDate), Date(timeIntervalSince1970: 1_900))
        XCTAssertEqual(DurationPreset.fourHours.endDate(startingAt: startDate), Date(timeIntervalSince1970: 15_400))
    }
}

