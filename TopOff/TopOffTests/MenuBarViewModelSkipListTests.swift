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
}
