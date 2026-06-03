import XCTest
@testable import TopOff

final class HistoryGroupingTests: XCTestCase {

    private let calendar = Calendar(identifier: .gregorian)
    private let referenceDate: Date = {
        var components = DateComponents(year: 2026, month: 6, day: 3, hour: 14, minute: 0)
        return Calendar(identifier: .gregorian).date(from: components)!
    }()

    private func result(daysAgo: Int, hour: Int, packages: Int = 1) -> UpdateResult {
        let date = calendar.date(byAdding: .day, value: -daysAgo, to: referenceDate)!
        let withHour = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: date)!
        let pkgs = (0..<packages).map { i in
            UpgradedPackage(name: "pkg-\(daysAgo)-\(i)", oldVersion: "1.0", newVersion: "1.1")
        }
        return UpdateResult(packages: pkgs, timestamp: withHour)
    }

    func testSingleDayMakesOneGroup() {
        let history = [result(daysAgo: 0, hour: 10)]
        let groups = HistoryGrouping.groupHistory(history, calendar: calendar, referenceDate: referenceDate)
        XCTAssertEqual(groups.count, 1)
        XCTAssertEqual(groups[0].title, "Today")
    }

    func testTodayYesterdayDayNameMonthDayBranches() {
        // Today, Yesterday, 3 days ago (this week), 60 days ago (this year)
        let history = [
            result(daysAgo: 0,  hour: 14),
            result(daysAgo: 1,  hour: 10),
            result(daysAgo: 3,  hour: 11),
            result(daysAgo: 60, hour: 9),
        ]
        let groups = HistoryGrouping.groupHistory(history, calendar: calendar, referenceDate: referenceDate)
        XCTAssertEqual(groups.count, 4)
        XCTAssertEqual(groups[0].title, "Today")
        XCTAssertEqual(groups[1].title, "Yesterday")
        // 2026-06-03 minus 3 days = 2026-05-31 (Sunday) — day name within current week branch
        XCTAssertTrue(groups[2].title.contains("Sunday") || groups[2].title.contains("May 31"))
        // 2026-06-03 minus 60 days = 2026-04-04 — month-day form
        XCTAssertTrue(groups[3].title.contains("April") || groups[3].title.contains("Apr"))
    }

    func testCrossYearGroupAppendsYear() {
        let oldDate = calendar.date(from: DateComponents(year: 2025, month: 11, day: 1, hour: 10, minute: 0))!
        let history = [
            UpdateResult(
                packages: [UpgradedPackage(name: "x", oldVersion: "1", newVersion: "2")],
                timestamp: oldDate
            )
        ]
        let groups = HistoryGrouping.groupHistory(history, calendar: calendar, referenceDate: referenceDate)
        XCTAssertEqual(groups.count, 1)
        XCTAssertTrue(groups[0].title.contains("2025"))
    }

    func testMultipleEventsOnSameDayShareSection() {
        let history = [
            result(daysAgo: 0, hour: 15),
            result(daysAgo: 0, hour: 10),
        ]
        let groups = HistoryGrouping.groupHistory(history, calendar: calendar, referenceDate: referenceDate)
        XCTAssertEqual(groups.count, 1)
        XCTAssertEqual(groups[0].events.count, 2)
    }
}
