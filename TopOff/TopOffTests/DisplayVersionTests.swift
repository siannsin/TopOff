import XCTest
@testable import TopOff

final class DisplayVersionTests: XCTestCase {

    func testAbbreviatesLongHexWithAlphaCharacters() {
        let input = "1.9255.0,a22af1fabbbc85af5502e695ed8fbea9f74276fc"
        XCTAssertEqual(DisplayVersion.abbreviate(input), "1.9255.0,a22af1f")
    }

    func testLeavesShortBuildSuffixUnchanged() {
        // Six digits — too short to be a SHA
        XCTAssertEqual(DisplayVersion.abbreviate("4.75.0,227598"), "4.75.0,227598")
    }

    func testLeavesPureNumericLongSuffixUnchanged() {
        // 8 digits but no alpha — not a SHA
        XCTAssertEqual(DisplayVersion.abbreviate("1.0,12345678"), "1.0,12345678")
    }

    func testLeavesVersionWithoutCommaUnchanged() {
        XCTAssertEqual(DisplayVersion.abbreviate("126.3.12"), "126.3.12")
    }

    func testPassesPlaceholderThrough() {
        XCTAssertEqual(DisplayVersion.abbreviate("?"), "?")
    }

    func testLeavesDateStampVersionUnchanged() {
        // Warp-style: no comma → no abbreviation
        let input = "0.2026.05.20.09.21.stable_03"
        XCTAssertEqual(DisplayVersion.abbreviate(input), input)
    }

    func testShortensOnlyQualifyingSegmentWhenMultipleCommas() {
        // Hypothetical: marketing,sha,extra — only the SHA-shaped piece shortens
        let input = "1.0,a22af1fabbbc85af5502e695ed8fbea9,extra"
        XCTAssertEqual(DisplayVersion.abbreviate(input), "1.0,a22af1f,extra")
    }

    func testIdempotent() {
        let once = DisplayVersion.abbreviate("1.9255.0,a22af1fabbbc85af5502e695ed8fbea9f74276fc")
        let twice = DisplayVersion.abbreviate(once)
        XCTAssertEqual(once, twice)
    }
}
