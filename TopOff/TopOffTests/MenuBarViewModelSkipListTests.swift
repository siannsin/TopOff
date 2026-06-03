import XCTest
@testable import TopOff

@MainActor
final class MenuBarViewModelSkipListTests: XCTestCase {

    private var defaults: UserDefaults!
    private var suiteName: String!

    override func setUp() {
        super.setUp()
        suiteName = "TopOff.tests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
        // Also reset the real UserDefaults that MenuBarViewModel uses
        UserDefaults.standard.removeObject(forKey: "rememberSkippedPackages")
        UserDefaults.standard.removeObject(forKey: "rememberedSkipList")
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
        let vm = MenuBarViewModel(skipInitialChecks: true)
        vm.rememberSkippedPackages = true
        vm.outdatedPackages = [OutdatedPackage(name: "chrome", currentVersion: "1.0", latestVersion: "2.0")]

        vm.skipPackage(vm.outdatedPackages[0])

        XCTAssertFalse(vm.skippedPackages.contains("chrome"))
        XCTAssertTrue(vm.rememberedSkipList.contains("chrome"))
        XCTAssertTrue(vm.visibleOutdatedPackages.isEmpty)
    }

    func testSkipRoutesToSessionWhenToggleOff() {
        let vm = MenuBarViewModel(skipInitialChecks: true)
        vm.rememberSkippedPackages = false
        vm.outdatedPackages = [OutdatedPackage(name: "chrome", currentVersion: "1.0", latestVersion: "2.0")]

        vm.skipPackage(vm.outdatedPackages[0])

        XCTAssertTrue(vm.skippedPackages.contains("chrome"))
        XCTAssertFalse(vm.rememberedSkipList.contains("chrome"))
        XCTAssertTrue(vm.visibleOutdatedPackages.isEmpty)
    }

    func testVisibleOutdatedExcludesUnionOfBothSkipSets() {
        let vm = MenuBarViewModel(skipInitialChecks: true)
        vm.rememberedSkipList = ["chrome"]
        vm.skippedPackages = ["figma"]
        vm.outdatedPackages = [
            OutdatedPackage(name: "chrome", currentVersion: "1", latestVersion: "2"),
            OutdatedPackage(name: "figma",  currentVersion: "1", latestVersion: "2"),
            OutdatedPackage(name: "warp",   currentVersion: "1", latestVersion: "2"),
        ]

        XCTAssertEqual(vm.visibleOutdatedPackages.map(\.name), ["warp"])
    }
}
