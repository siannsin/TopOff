import SwiftUI
import AppKit

/// Result of presenting the admin prompt. Either the user submitted a password
/// or they cancelled (window closed via Cancel, ⎋, or window-close button).
enum AdminPasswordPromptResult {
    case submitted(String)
    case cancelled
}

@MainActor
final class AdminPasswordPromptWindowController: NSWindowController {

    /// Present the prompt and asynchronously return the user's choice.
    /// Caller is responsible for shuttling the password to sudo (or its
    /// equivalent) — this window does not touch sudo itself.
    static func present(forPackage packageName: String?,
                        errorMessage: String?) async -> AdminPasswordPromptResult {
        await withCheckedContinuation { continuation in
            let controller = AdminPasswordPromptWindowController(
                packageName: packageName,
                errorMessage: errorMessage,
                continuation: continuation
            )
            controller.show()
        }
    }

    private var continuation: CheckedContinuation<AdminPasswordPromptResult, Never>?

    private init(packageName: String?,
                 errorMessage: String?,
                 continuation: CheckedContinuation<AdminPasswordPromptResult, Never>) {
        self.continuation = continuation

        let viewModel = AdminPasswordPromptViewModel(
            packageName: packageName,
            errorMessage: errorMessage
        )

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 230),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.level = .modalPanel
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.center()

        super.init(window: window)
        viewModel.onSubmit = { [weak self] password in
            self?.finish(with: .submitted(password))
        }
        viewModel.onCancel = { [weak self] in
            self?.finish(with: .cancelled)
        }
        window.delegate = self

        let view = AdminPasswordPromptView(viewModel: viewModel)
        window.contentView = NSHostingView(rootView: view)
    }

    required init?(coder: NSCoder) {
        fatalError("not supported")
    }

    private func show() {
        NSApp.activate(ignoringOtherApps: true)
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
    }

    private func finish(with result: AdminPasswordPromptResult) {
        guard let continuation else { return }
        self.continuation = nil
        continuation.resume(returning: result)
        close()
    }
}

extension AdminPasswordPromptWindowController: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        finish(with: .cancelled)
    }
}

@MainActor
final class AdminPasswordPromptViewModel: ObservableObject {
    @Published var password: String = ""
    let packageName: String?
    let errorMessage: String?

    var onSubmit: ((String) -> Void)?
    var onCancel: (() -> Void)?

    init(packageName: String?, errorMessage: String?) {
        self.packageName = packageName
        self.errorMessage = errorMessage
    }

    func submit() {
        onSubmit?(password)
    }

    func cancel() {
        onCancel?()
    }
}

struct AdminPasswordPromptView: View {
    @ObservedObject var viewModel: AdminPasswordPromptViewModel
    @FocusState private var passwordFocused: Bool

    var body: some View {
        VStack(spacing: 14) {
            if let icon = NSImage(named: NSImage.applicationIconName) {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: 64, height: 64)
                    .padding(.top, 6)
            }

            VStack(spacing: 4) {
                Text("TopOff needs administrator access")
                    .font(.title3)
                    .fontWeight(.medium)

                Text(subtitleText)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.callout)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .center)
            }

            SecureField("Password", text: $viewModel.password)
                .textFieldStyle(.roundedBorder)
                .focused($passwordFocused)
                .onSubmit { viewModel.submit() }

            HStack(spacing: 10) {
                Button("Cancel") { viewModel.cancel() }
                    .keyboardShortcut(.cancelAction)
                Button("Update") { viewModel.submit() }
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(20)
        .frame(width: 360)
        .onAppear { passwordFocused = true }
    }

    private var subtitleText: String {
        let target = viewModel.packageName ?? "some packages"
        return "to update \(target). Enter your Mac password to continue."
    }
}
