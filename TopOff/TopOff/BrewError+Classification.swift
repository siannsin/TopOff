import Foundation

extension BrewError {

    /// Map raw brew (or sudo) error output into a typed `BrewError` case.
    /// Specific patterns take precedence over generic ones.
    static func classify(output: String) -> BrewError {
        let lower = output.lowercased()

        // Specific patterns first
        if matchesAny(lower, [
            "operation timed out",
            "could not connect",
            "could not resolve host",
            "failed to fetch",
            "getaddrinfo",
            "network is unreachable",
        ]) {
            return .networkUnavailable(output)
        }

        if matchesAny(lower, [
            "no space left on device",
            "disk is full",
        ]) {
            return .diskFull(output)
        }

        if matchesAny(lower, [
            "xcrun: error: invalid active developer path",
            "command line tools for xcode",
        ]) {
            return .commandLineToolsRequired(output)
        }

        if matchesAny(lower, [
            "another active homebrew",
            "resource temporarily unavailable",
        ]) {
            return .brewBusy(output)
        }

        if matchesAny(lower, [
            "has been disabled",
            "no longer available",
            "removed for moderation",
        ]) {
            return .caskUnavailable(packageName: extractCaskName(from: output), output: output)
        }

        // Permission patterns last (current isPermissionError, folded in)
        if matchesAny(lower, [
            "permission denied",
            "operation not permitted",
            "failure while executing",
            "password is required",
            "requires root",
            "sudo",
            "insufficient permissions",
        ]) {
            return .permissionDenied(output)
        }

        return .commandFailed(output)
    }

    private static func matchesAny(_ haystack: String, _ needles: [String]) -> Bool {
        for needle in needles where haystack.contains(needle) {
            return true
        }
        return false
    }

    /// Best-effort cask name extraction from a "no longer available" message.
    /// Returns nil if no clear match — the recovery copy falls back to "A package".
    private static func extractCaskName(from output: String) -> String? {
        let lines = output.components(separatedBy: .newlines)
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("Error: ") {
                let after = trimmed.dropFirst("Error: ".count)
                let firstWord = after.split(separator: " ").first.map(String.init)
                if let firstWord, !firstWord.isEmpty, firstWord != "Cask" {
                    return firstWord
                }
            }
        }
        return nil
    }
}
