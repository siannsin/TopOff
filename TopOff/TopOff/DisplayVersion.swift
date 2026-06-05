import Foundation

/// Helper for collapsing Homebrew cask version strings down to the
/// recognizable semver-like core. Cask versions are wildly inconsistent —
/// some are plain (`126.4.12`), some include git SHAs
/// (`1.9255.0,a22af1fabbbc85af5502e695ed8fbea9f74276fc`), some bundle
/// release codes and build numbers (`2506-8.16.0-16536825094,CART26FQ2_MAC_2506`).
/// Showing the raw string makes menu rows enormous and unreadable, so this
/// extracts the most version-shaped substring and discards the rest.
enum DisplayVersion {

    /// Returns the most semver-shaped run of digits-and-dots inside
    /// `version`. "Most version-shaped" means the most dots; ties broken
    /// by string length. Falls back to the segment before the first comma
    /// when nothing matches.
    ///
    /// Examples:
    /// - `"1.9255.0,a22af1fabbbc..."` → `"1.9255.0"`
    /// - `"2506-8.16.0-16536825094,CART26FQ2_MAC_2506"` → `"8.16.0"`
    /// - `"1.10628.2,deee0a7"` → `"1.10628.2"`
    /// - `"126.4.12"` → `"126.4.12"`
    static func abbreviate(_ version: String) -> String {
        let nsString = version as NSString
        let range = NSRange(location: 0, length: nsString.length)
        let matches = Self.dottedNumberRegex?.matches(in: version, range: range) ?? []

        var best: (text: String, dots: Int)?
        for match in matches {
            let text = nsString.substring(with: match.range)
            let dots = text.reduce(0) { $1 == "." ? $0 + 1 : $0 }
            if let current = best {
                if dots > current.dots || (dots == current.dots && text.count > current.text.count) {
                    best = (text, dots)
                }
            } else {
                best = (text, dots)
            }
        }

        if let best { return best.text }

        // No dotted version anywhere. Fall back to the segment before the
        // first comma, which trims off any trailing build-metadata blob.
        if let comma = version.firstIndex(of: ",") {
            return String(version[..<comma])
        }
        return version
    }

    /// One or more digits, then one-or-more `.<digits>` groups. Matches the
    /// classic `X.Y`, `X.Y.Z`, `X.Y.Z.W`, etc.
    private static let dottedNumberRegex: NSRegularExpression? = {
        try? NSRegularExpression(pattern: #"\d+(?:\.\d+)+"#)
    }()
}
