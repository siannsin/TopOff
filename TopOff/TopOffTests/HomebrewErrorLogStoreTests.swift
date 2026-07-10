import XCTest
@testable import TopOff

@MainActor
final class HomebrewErrorLogStoreTests: XCTestCase {
    private var directoryURL: URL!
    private var fileURL: URL!

    override func setUpWithError() throws {
        directoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("topoff-error-log-tests-\(UUID().uuidString)")
        fileURL = directoryURL.appendingPathComponent("homebrew-errors.json")
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directoryURL)
        directoryURL = nil
        fileURL = nil
    }

    func testRecordsOperationAndRawBrewOutput() throws {
        let now = Date(timeIntervalSince1970: 1_000_000)
        let store = HomebrewErrorLogStore(fileURL: fileURL, now: { now })

        store.record(
            operation: "updateAll.adminRetry",
            error: BrewError.commandFailed("Error: installer failed with status 1")
        )

        XCTAssertEqual(store.loadEntries(), [
            HomebrewErrorLogEntry(
                timestamp: now,
                operation: "updateAll.adminRetry",
                output: "Error: installer failed with status 1"
            )
        ])
    }

    func testPrunesEntriesOlderThanSevenDays() throws {
        let currentDate = Date(timeIntervalSince1970: 2_000_000)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let storedEntries = [
            HomebrewErrorLogEntry(
                timestamp: currentDate.addingTimeInterval(-HomebrewErrorLogStore.retentionInterval - 1),
                operation: "expired",
                output: "old"
            ),
            HomebrewErrorLogEntry(
                timestamp: currentDate.addingTimeInterval(-HomebrewErrorLogStore.retentionInterval),
                operation: "retained",
                output: "new"
            )
        ]
        try encoder.encode(storedEntries).write(to: fileURL)

        let store = HomebrewErrorLogStore(fileURL: fileURL, now: { currentDate })

        XCTAssertEqual(store.loadEntries().map(\.operation), ["retained"])
    }
}
