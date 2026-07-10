import XCTest
@testable import TopOff

final class SpyLaunchAtLoginManager: LaunchAtLoginManaging {
    private(set) var calls: [Bool] = []
    func setEnabled(_ enabled: Bool) {
        calls.append(enabled)
    }
}

@MainActor
final class MenuBarViewModelSkipListTests: XCTestCase {

    private var defaults: UserDefaults!
    private var suiteName: String!

    override func setUp() {
        super.setUp()
        suiteName = "TopOff.tests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        super.tearDown()
    }

    func testRememberToggleDefaultsOff() {
        XCTAssertFalse(defaults.bool(forKey: "rememberSkippedPackages"))
    }

    func testRememberedSkipListPersistsAcrossDecode() {
        let set: Set<String> = ["google-chrome", "duckduckgo"]
        let encoded = try! JSONEncoder().encode(set.sorted())
        defaults.set(encoded, forKey: "rememberedSkipList")

        let raw = defaults.data(forKey: "rememberedSkipList")!
        let decoded = try! JSONDecoder().decode([String].self, from: raw)
        XCTAssertEqual(Set(decoded), set)
    }

    func testSkipRoutesToRememberedWhenToggleOn() {
        let vm = MenuBarViewModel(skipInitialChecks: true, defaults: defaults)
        vm.rememberSkippedPackages = true
        vm.outdatedPackages = [OutdatedPackage(name: "chrome", currentVersion: "1.0", latestVersion: "2.0")]

        vm.skipPackage(vm.outdatedPackages[0])

        XCTAssertFalse(vm.skippedPackages.contains("chrome"))
        XCTAssertTrue(vm.rememberedSkipList.contains("chrome"))
        XCTAssertTrue(vm.visibleOutdatedPackages.isEmpty)
    }

    func testSkipRoutesToSessionWhenToggleOff() {
        let vm = MenuBarViewModel(skipInitialChecks: true, defaults: defaults)
        vm.rememberSkippedPackages = false
        vm.outdatedPackages = [OutdatedPackage(name: "chrome", currentVersion: "1.0", latestVersion: "2.0")]

        vm.skipPackage(vm.outdatedPackages[0])

        XCTAssertTrue(vm.skippedPackages.contains("chrome"))
        XCTAssertFalse(vm.rememberedSkipList.contains("chrome"))
        XCTAssertTrue(vm.visibleOutdatedPackages.isEmpty)
    }

    func testVisibleOutdatedExcludesUnionOfBothSkipSets() {
        let vm = MenuBarViewModel(skipInitialChecks: true, defaults: defaults)
        vm.rememberedSkipList = ["chrome"]
        vm.skippedPackages = ["figma"]
        vm.outdatedPackages = [
            OutdatedPackage(name: "chrome", currentVersion: "1", latestVersion: "2"),
            OutdatedPackage(name: "figma",  currentVersion: "1", latestVersion: "2"),
            OutdatedPackage(name: "warp",   currentVersion: "1", latestVersion: "2"),
        ]

        XCTAssertEqual(vm.visibleOutdatedPackages.map(\.name), ["warp"])
    }

    func testMutationsWriteToInjectedDefaultsNotStandard() {
        // Snapshot the real domain so this test never leaves residue there,
        // even while it is red.
        let rememberBefore = UserDefaults.standard.object(forKey: "rememberSkippedPackages")
        let skipListBefore = UserDefaults.standard.object(forKey: "rememberedSkipList")
        defer {
            restoreStandard("rememberSkippedPackages", rememberBefore)
            restoreStandard("rememberedSkipList", skipListBefore)
        }

        let vm = MenuBarViewModel(skipInitialChecks: true, defaults: defaults)
        vm.rememberSkippedPackages = true
        vm.outdatedPackages = [OutdatedPackage(name: "ripgrep", currentVersion: "1", latestVersion: "2")]
        vm.skipPackage(vm.outdatedPackages[0])

        XCTAssertTrue(defaults.bool(forKey: "rememberSkippedPackages"),
                      "toggle should persist to the injected defaults")
        let savedData = defaults.data(forKey: "rememberedSkipList")
        let saved = savedData.flatMap { try? JSONDecoder().decode([String].self, from: $0) } ?? []
        XCTAssertEqual(saved, ["ripgrep"], "skip list should persist to the injected defaults")
    }

    func testLaunchAtLoginTogglesThroughInjectedManager() {
        let launchBefore = UserDefaults.standard.object(forKey: "launchAtLogin")
        defer { restoreStandard("launchAtLogin", launchBefore) }

        let spy = SpyLaunchAtLoginManager()
        let vm = MenuBarViewModel(skipInitialChecks: true, defaults: defaults, loginItemManager: spy)

        vm.launchAtLogin = true
        vm.launchAtLogin = false

        XCTAssertEqual(spy.calls, [true, false],
                       "launch-at-login changes should route through the injected manager, not SMAppService")
    }

    func testShouldRunHomebrewCheckWhenNoPreviousCheckExists() {
        let vm = MenuBarViewModel(skipInitialChecks: true, defaults: defaults)

        XCTAssertTrue(vm.shouldRunHomebrewCheck(now: Date(timeIntervalSince1970: 10_000)))
    }

    func testShouldNotRunHomebrewCheckInsideMinimumInterval() {
        let now = Date(timeIntervalSince1970: 20_000)
        let vm = MenuBarViewModel(skipInitialChecks: true, defaults: defaults)
        vm.lastHomebrewCheckDate = now.addingTimeInterval(-MenuBarViewModel.minimumHomebrewCheckInterval + 1)

        XCTAssertFalse(vm.shouldRunHomebrewCheck(now: now))
    }

    func testShouldRunHomebrewCheckAtMinimumIntervalBoundary() {
        let now = Date(timeIntervalSince1970: 20_000)
        let vm = MenuBarViewModel(skipInitialChecks: true, defaults: defaults)
        vm.lastHomebrewCheckDate = now.addingTimeInterval(-MenuBarViewModel.minimumHomebrewCheckInterval)

        XCTAssertTrue(vm.shouldRunHomebrewCheck(now: now))
    }

    func testGreedyModeSettingPersistsAsSingleSourceOfTruth() {
        let vm = MenuBarViewModel(skipInitialChecks: true, defaults: defaults)
        vm.greedyModeEnabled = true

        XCTAssertTrue(defaults.bool(forKey: "greedyModeEnabled"))
        XCTAssertTrue(vm.greedyModeEnabled)
    }

    func testGreedyModeDefaultsOffForNewUsers() {
        let vm = MenuBarViewModel(skipInitialChecks: true, defaults: defaults)

        XCTAssertFalse(MenuBarViewModel.defaultGreedyModeEnabled)
        XCTAssertFalse(vm.greedyModeEnabled)
    }

    func testChangingGreedyModeClearsStalePackageState() {
        let vm = MenuBarViewModel(skipInitialChecks: true, defaults: defaults)
        vm.outdatedPackages = [
            OutdatedPackage(name: "chrome", currentVersion: "1", latestVersion: "2")
        ]
        vm.skippedPackages = ["chrome"]
        vm.rememberedSkipList = ["persisted-package"]

        vm.greedyModeEnabled = true

        XCTAssertTrue(vm.outdatedPackages.isEmpty)
        XCTAssertTrue(vm.skippedPackages.isEmpty)
        XCTAssertEqual(vm.rememberedSkipList, ["persisted-package"])
    }

    func testSelectingUnlockModeStopsPeriodicChecks() {
        defaults.set(AutomaticCheckMode.periodic.rawValue, forKey: AutomaticCheckMode.userDefaultsKey)
        defaults.set(3600.0, forKey: "checkInterval")
        let vm = MenuBarViewModel(skipInitialChecks: true, defaults: defaults)

        vm.startPeriodicChecks()
        XCTAssertTrue(vm.hasActivePeriodicCheckTimer)

        vm.automaticCheckMode = .afterUnlock

        XCTAssertFalse(vm.hasActivePeriodicCheckTimer)
    }

    func testSelectingPeriodicModeCancelsPendingUnlockCheck() {
        let now = Date(timeIntervalSince1970: 20_000)
        let vm = MenuBarViewModel(skipInitialChecks: true, defaults: defaults)
        vm.automaticCheckMode = .afterUnlock
        vm.lastHomebrewCheckDate = now.addingTimeInterval(-MenuBarViewModel.minimumHomebrewCheckInterval)

        vm.scheduleCheckAfterUnlock(now: now)
        XCTAssertTrue(vm.hasPendingUnlockCheck)

        vm.automaticCheckMode = .periodic

        XCTAssertFalse(vm.hasPendingUnlockCheck)
    }

    func testUnlockCheckDoesNotScheduleInsideMinimumInterval() {
        let now = Date(timeIntervalSince1970: 20_000)
        let vm = MenuBarViewModel(skipInitialChecks: true, defaults: defaults)
        vm.automaticCheckMode = .afterUnlock
        vm.lastHomebrewCheckDate = now.addingTimeInterval(-MenuBarViewModel.minimumHomebrewCheckInterval + 1)

        vm.scheduleCheckAfterUnlock(now: now)

        XCTAssertFalse(vm.hasPendingUnlockCheck)
    }

    func testUpdatesAvailableNotificationBodySkipsZeroCount() {
        XCTAssertNil(NotificationManager.updatesAvailableNotificationBody(count: 0))
        XCTAssertEqual(
            NotificationManager.updatesAvailableNotificationBody(count: 1),
            "1 Homebrew update available"
        )
        XCTAssertEqual(
            NotificationManager.updatesAvailableNotificationBody(count: 7),
            "7 Homebrew updates available"
        )
    }

    func testLoadUpdateHistoryHealsReportedCorruptedRecordOnLaunch() throws {
        // Simulate launching the app with hunter-nl's corrupted history already
        // persisted, then drive the REAL init -> loadUpdateHistory path and show
        // what the menu + History window would render.
        let corrupted = UpdateResult(
            packages: [
                UpgradedPackage(name: "uv  0.11.23", oldVersion: "", newVersion: "0.11.24"),
                UpgradedPackage(name: "vim", oldVersion: "9.2.0650", newVersion: "9.2.0700"),
                UpgradedPackage(name: "uv", oldVersion: "?", newVersion: "?"),
                UpgradedPackage(name: "vim", oldVersion: "?", newVersion: "?")
            ],
            timestamp: Date()
        )
        defaults.set(try JSONEncoder().encode([corrupted]), forKey: "updateHistory")

        // Launching the app runs loadUpdateHistory() inside init.
        let vm = MenuBarViewModel(skipInitialChecks: true, defaults: defaults)

        // What the menu's "Last Update" section now renders.
        let last = try XCTUnwrap(vm.lastUpdateResult)
        XCTAssertEqual(last.packages.map(\.name), ["uv", "vim"])
        XCTAssertEqual(last.packages.map(\.newVersion), ["0.11.24", "9.2.0700"])
        XCTAssertFalse(last.packages.contains { $0.newVersion == "?" })

        // What the History window now renders (count + recovered old versions).
        let historyEntry = try XCTUnwrap(vm.updateHistory.first)
        XCTAssertEqual(historyEntry.packages.count, 2)
        XCTAssertEqual(historyEntry.packages.map(\.oldVersion), ["0.11.23", "9.2.0650"])

        // The healed record is re-persisted, so it stays fixed on the next launch.
        let reSaved = try XCTUnwrap(defaults.data(forKey: "updateHistory"))
        let decoded = try JSONDecoder().decode([UpdateResult].self, from: reSaved)
        XCTAssertEqual(decoded.first?.packages.count, 2)
    }

    private func restoreStandard(_ key: String, _ value: Any?) {
        if let value {
            UserDefaults.standard.set(value, forKey: key)
        } else {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }
}
