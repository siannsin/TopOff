import AppKit

/// Result of presenting the admin prompt. Either the user submitted a password
/// or they cancelled (window closed via Cancel, ⎋, or window-close button).
enum AdminPasswordPromptResult {
    case submitted(String)
    case cancelled
}

@MainActor
enum AdminPasswordPromptWindowController {

    /// Present the prompt and asynchronously return the user's choice.
    /// Caller is responsible for shuttling the password to sudo (or its
    /// equivalent) — this prompt does not touch sudo itself.
    ///
    /// Implemented with `NSAlert` + a secure-text-field accessory view. This
    /// is the canonical macOS pattern for password modals and avoids the
    /// SwiftUI/NSHostingView constraint-update death-spiral that bit an
    /// earlier SwiftUI-window implementation.
    static func present(forPackage packageName: String?,
                        errorMessage: String?) async -> AdminPasswordPromptResult {
        await withCheckedContinuation { continuation in
            let result = presentAlert(
                packageName: packageName,
                errorMessage: errorMessage
            )
            continuation.resume(returning: result)
        }
    }

    private static func presentAlert(packageName: String?,
                                     errorMessage: String?) -> AdminPasswordPromptResult {
        let alert = NSAlert()
        alert.messageText = "TopOff needs administrator access"
        alert.informativeText = informativeText(
            packageName: packageName,
            errorMessage: errorMessage
        )
        alert.alertStyle = .informational
        if let icon = NSImage(named: NSImage.applicationIconName) {
            alert.icon = icon
        }

        // Buttons appear right-to-left in NSAlert: first added is the
        // rightmost (default) button.
        alert.addButton(withTitle: "Update")
        alert.addButton(withTitle: "Cancel")

        let secureField = NSSecureTextField(frame: NSRect(x: 0, y: 0, width: 260, height: 24))
        secureField.placeholderString = "Password"
        alert.accessoryView = secureField

        // Make the alert come to front and land focus in the password field.
        NSApp.activate(ignoringOtherApps: true)
        alert.window.initialFirstResponder = secureField

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            return .submitted(secureField.stringValue)
        }
        return .cancelled
    }

    private static func informativeText(packageName: String?,
                                        errorMessage: String?) -> String {
        let target = packageName ?? "some packages"
        let base = "Enter your Mac password to update \(target)."
        if let errorMessage {
            return "\(errorMessage)\n\n\(base)"
        }
        return base
    }
}
