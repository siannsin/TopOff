import XCTest
@testable import TopOff

final class BrewErrorClassificationTests: XCTestCase {

    func testClassifiesNetworkTimeout() {
        let output = "Error: Failed to fetch: Operation timed out after 30 seconds"
        if case .networkUnavailable = BrewError.classify(output: output) {
            // pass
        } else {
            XCTFail("Expected .networkUnavailable")
        }
    }

    func testClassifiesGetaddrinfoAsNetwork() {
        let output = "curl: (6) Could not resolve host: github.com — getaddrinfo failed"
        if case .networkUnavailable = BrewError.classify(output: output) {} else {
            XCTFail("Expected .networkUnavailable")
        }
    }

    func testClassifiesDiskFull() {
        let output = "Error: No space left on device @ io_write"
        if case .diskFull = BrewError.classify(output: output) {} else {
            XCTFail("Expected .diskFull")
        }
    }

    func testClassifiesCommandLineTools() {
        let output = "xcrun: error: invalid active developer path (/Library/Developer/CommandLineTools)"
        if case .commandLineToolsRequired = BrewError.classify(output: output) {} else {
            XCTFail("Expected .commandLineToolsRequired")
        }
    }

    func testClassifiesBrewBusy() {
        let output = "Error: Another active Homebrew update process is already in progress."
        if case .brewBusy = BrewError.classify(output: output) {} else {
            XCTFail("Expected .brewBusy")
        }
    }

    func testClassifiesPermission() {
        let output = "sudo: a terminal is required to read the password"
        if case .permissionDenied = BrewError.classify(output: output) {} else {
            XCTFail("Expected .permissionDenied")
        }
    }

    func testClassifiesCaskUnavailable() {
        let output = "Error: foo-bar has been disabled because it no longer ships..."
        if case .caskUnavailable = BrewError.classify(output: output) {} else {
            XCTFail("Expected .caskUnavailable")
        }
    }

    func testClassifiesExistingAppArtifactConflict() {
        let output = """
        Warning: Reverting upgrade for Cask stats
        Error: stats: It seems there is already an App at '/Applications/Stats.app'.
        """

        if case .caskArtifactConflict(let path, _) = BrewError.classify(output: output) {
            XCTAssertEqual(path, "/Applications/Stats.app")
        } else {
            XCTFail("Expected .caskArtifactConflict")
        }
    }

    func testFallsBackToCommandFailed() {
        let output = "Something genuinely novel that we have no pattern for."
        if case .commandFailed = BrewError.classify(output: output) {} else {
            XCTFail("Expected .commandFailed fallback")
        }
    }

    func testSpecificPrecedenceNetworkOverPermission() {
        // Both patterns present — network is more specific
        let output = """
        Operation timed out
        Permission denied: /some/path
        """
        if case .networkUnavailable = BrewError.classify(output: output) {} else {
            XCTFail("Expected network to win precedence over permission")
        }
    }

    func testEveryCaseHasFriendlyDescription() {
        let cases: [BrewError] = [
            .brewNotFound,
            .permissionDenied(""),
            .commandFailed(""),
            .networkUnavailable(""),
            .diskFull(""),
            .commandLineToolsRequired(""),
            .brewBusy(""),
            .caskUnavailable(packageName: nil, output: ""),
            .caskArtifactConflict(path: "/Applications/Stats.app", output: ""),
        ]
        for err in cases {
            XCTAssertNotNil(err.errorDescription, "Missing errorDescription for \(err)")
            XCTAssertFalse(err.errorDescription!.isEmpty)
        }
    }
}
