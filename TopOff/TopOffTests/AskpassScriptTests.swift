import XCTest
@testable import TopOff

@MainActor
final class AskpassScriptTests: XCTestCase {

    private var scratchDir: URL!

    override func setUp() {
        super.setUp()
        scratchDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("topoff-tests-\(UUID().uuidString)")
        try! FileManager.default.createDirectory(at: scratchDir, withIntermediateDirectories: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: scratchDir)
        super.tearDown()
    }

    func testScriptPrintsPasswordWhenFifoYieldsPassword() throws {
        let fifoPath = scratchDir.appendingPathComponent("pw.fifo").path
        try BrewService.makeFIFO(at: fifoPath)

        let scriptPath = scratchDir.appendingPathComponent("askpass.sh").path
        try BrewService.writeAskpassScript(toPath: scriptPath, fifoPath: fifoPath)

        // Run the script asynchronously
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        process.arguments = [scriptPath]
        process.standardOutput = pipe
        try process.run()

        // Write the password to the FIFO
        let fileHandle = FileHandle(forWritingAtPath: fifoPath)!
        fileHandle.write("hunter2\n".data(using: .utf8)!)
        fileHandle.closeFile()

        process.waitUntilExit()
        let output = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        XCTAssertEqual(process.terminationStatus, 0)
        XCTAssertEqual(output, "hunter2\n")
    }

    func testScriptExitsNonZeroOnCancelSentinel() throws {
        let fifoPath = scratchDir.appendingPathComponent("pw.fifo").path
        try BrewService.makeFIFO(at: fifoPath)

        let scriptPath = scratchDir.appendingPathComponent("askpass.sh").path
        try BrewService.writeAskpassScript(toPath: scriptPath, fifoPath: fifoPath)

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        process.arguments = [scriptPath]
        try process.run()

        let fileHandle = FileHandle(forWritingAtPath: fifoPath)!
        fileHandle.write("__TOPOFF_CANCEL__\n".data(using: .utf8)!)
        fileHandle.closeFile()

        process.waitUntilExit()
        XCTAssertEqual(process.terminationStatus, 1)
    }
}
