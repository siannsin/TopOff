import Foundation

struct HomebrewErrorLogEntry: Codable, Equatable {
    let timestamp: Date
    let operation: String
    let output: String
}

@MainActor
final class HomebrewErrorLogStore {
    static let retentionInterval: TimeInterval = 7 * 24 * 60 * 60
    static let shared = HomebrewErrorLogStore()

    let fileURL: URL

    private let fileManager: FileManager
    private let now: () -> Date

    init(
        fileURL: URL? = nil,
        fileManager: FileManager = .default,
        now: @escaping () -> Date = Date.init
    ) {
        self.fileManager = fileManager
        self.now = now

        if let fileURL {
            self.fileURL = fileURL
        } else {
            let applicationSupport = fileManager.urls(
                for: .applicationSupportDirectory,
                in: .userDomainMask
            ).first ?? fileManager.temporaryDirectory
            self.fileURL = applicationSupport
                .appendingPathComponent("TopOff", isDirectory: true)
                .appendingPathComponent("homebrew-errors.json")
        }

        pruneExpiredEntries()
    }

    func record(operation: String, error: Error) {
        let output: String
        if let brewError = error as? BrewError {
            output = brewError.diagnosticOutput
        } else {
            output = error.localizedDescription
        }
        record(operation: operation, output: output)
    }

    func record(operation: String, output: String) {
        let timestamp = now()
        var entries = retainedEntries(asOf: timestamp)
        entries.append(HomebrewErrorLogEntry(
            timestamp: timestamp,
            operation: operation,
            output: output
        ))
        write(entries)
    }

    func loadEntries() -> [HomebrewErrorLogEntry] {
        loadStoredEntries()
    }

    func pruneExpiredEntries() {
        guard fileManager.fileExists(atPath: fileURL.path) else { return }
        write(retainedEntries(asOf: now()))
    }

    private func retainedEntries(asOf date: Date) -> [HomebrewErrorLogEntry] {
        let cutoff = date.addingTimeInterval(-Self.retentionInterval)
        return loadStoredEntries().filter { $0.timestamp >= cutoff }
    }

    private func loadStoredEntries() -> [HomebrewErrorLogEntry] {
        guard let data = try? Data(contentsOf: fileURL) else { return [] }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode([HomebrewErrorLogEntry].self, from: data)) ?? []
    }

    private func write(_ entries: [HomebrewErrorLogEntry]) {
        do {
            try fileManager.createDirectory(
                at: fileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )

            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            try encoder.encode(entries).write(to: fileURL, options: .atomic)
        } catch {
            print("Failed to write Homebrew error log: \(error)")
        }
    }
}
