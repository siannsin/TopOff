import Foundation

/// Helper for shortening Homebrew cask version strings that include long
/// SHA-style suffixes (e.g. `1.9255.0,a22af1fabbbc85af5502e695ed8fbea9f74276fc`).
/// Used at the menu render layer so a single wide row can't blow out the
/// entire menu width.
enum DisplayVersion {

    /// Returns `version` with any SHA-like segment shortened to 7 characters.
    /// A segment after a comma is treated as SHA-like if it is at least 8
    /// characters long AND contains at least one lowercase hex letter
    /// (`a`–`f`). Numeric-only build numbers are left untouched.
    static func abbreviate(_ version: String) -> String {
        guard version.contains(",") else { return version }

        let segments = version.split(separator: ",", omittingEmptySubsequences: false)
        let abbreviated = segments.map { segment -> Substring in
            guard isSHALike(segment) else { return segment }
            return segment.prefix(7)
        }
        return abbreviated.joined(separator: ",")
    }

    private static func isSHALike(_ segment: Substring) -> Bool {
        guard segment.count >= 8 else { return false }
        var seenAlphaHex = false
        for ch in segment {
            if ch.isHexDigit {
                if ch.isLetter { seenAlphaHex = true }
            } else {
                return false
            }
        }
        return seenAlphaHex
    }
}
