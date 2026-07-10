import AppKit
import SwiftUI
import UserNotifications

@main
struct TopOffApp: App {
    @NSApplicationDelegateAdaptor(TopOffAppDelegate.self) private var appDelegate
    @StateObject private var viewModel: MenuBarViewModel
    @Environment(\.openWindow) private var openWindow

    init() {
        let viewModel = MenuBarViewModel()
        _viewModel = StateObject(wrappedValue: viewModel)
        NotificationActionRouter.shared.updateAllHandler = { [weak viewModel] in
            viewModel?.updateAll()
        }
    }

    var body: some Scene {
        MenuBarExtra {
            // Active status line
            if let progress = viewModel.updateProgress {
                Menu(progress.title) {
                    ForEach(progress.items) { item in
                        Text(progressLabel(for: item))
                            .font(.system(.body, design: .monospaced))
                    }
                }
                .help("Shows which Homebrew items are queued and which one is updating now.")

                if let status = viewModel.statusMessage, status != progress.title {
                    Text(status)
                        .foregroundStyle(.secondary)
                }
                Divider()
            } else if let status = viewModel.statusMessage {
                Text(status)
                    .foregroundStyle(.secondary)
                Divider()
            }

            // Outdated packages with version details
            if !viewModel.visibleOutdatedPackages.isEmpty {
                ForEach(viewModel.visibleOutdatedPackages) { package in
                    Menu(package.name) {
                        Button("Update") {
                            viewModel.upgradePackage(package)
                        }
                        Button("Skip") {
                            viewModel.skipPackage(package)
                        }
                    }
                }

                Divider()
            }

            // Primary actions
            Button(viewModel.greedyModeEnabled ? "Update All (Greedy)" : "Update All") {
                viewModel.updateAll()
            }
            .disabled(viewModel.isRunning)

            Button(viewModel.greedyModeEnabled ? "Check Updates (Greedy)" : "Check Updates") {
                Task {
                    await viewModel.checkForUpdates()
                }
            }
            .disabled(viewModel.isRunning)

            Divider()

            // Up-to-date confirmation
            if viewModel.showsUpToDateConfirmation {
                Label("All packages up to date", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.secondary)
                Divider()
            }

            // Last Update Results
            if let result = viewModel.lastUpdateResult {
                if result.isEmpty {
                    Text("Last Update: No changes")
                        .foregroundStyle(.secondary)
                } else {
                    let displayPackages = Array(result.packages.prefix(5))
                    let overflow = result.packages.count - displayPackages.count

                    Text("Last Update (\(result.count) package\(result.count == 1 ? "" : "s")):")
                        .foregroundStyle(.secondary)
                    ForEach(displayPackages) { package in
                        Text(package.name).fontWeight(.medium)
                            + Text(" \(DisplayVersion.abbreviate(package.newVersion))")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                    }

                    if overflow > 0 {
                        Button("...and \(overflow) more") {
                            openWindow(id: "history")
                            NSApp.activate(ignoringOtherApps: true)
                        }
                    }
                }

                if let cleanup = viewModel.lastCleanupResult, !cleanup.freedSpace.isEmpty {
                    Text("Cleanup: Freed \(cleanup.freedSpace)")
                        .foregroundStyle(.secondary)
                        .padding(.leading, 12)
                }

                Divider()
            }

            // Options submenu
            Menu("Options") {
                Toggle("Launch at Login", isOn: $viewModel.launchAtLogin)
                Toggle("Auto Cleanup", isOn: $viewModel.autoCleanupEnabled)
                    .help("Runs cleanup after successful updates. Cleanup style can be changed under Cleanup.")

                Menu("Cleanup") {
                    Button("Run Standard Cleanup") {
                        viewModel.runCleanup()
                    }
                    .disabled(viewModel.isRunning)
                    .help("Runs brew cleanup now.")

                    Button("Deep Cache Prune…") {
                        viewModel.runDeepCachePrune()
                    }
                    .disabled(viewModel.isRunning)
                    .help("Asks before running brew cleanup --prune=all.")

                    Divider()

                    Menu("Auto Cleanup Style") {
                        Button("\(viewModel.autoCleanupStyle == .standard ? "✓ " : "")Standard Cleanup") {
                            viewModel.setAutoCleanupStyle(.standard)
                        }
                        .help("Auto Cleanup runs brew cleanup after successful updates.")

                        Button("\(viewModel.autoCleanupStyle == .deepPruneAll ? "✓ " : "")Deep Cache Prune") {
                            viewModel.setAutoCleanupStyle(.deepPruneAll)
                        }
                        .help("Auto Cleanup runs brew cleanup --prune=all after successful updates.")
                    }
                }

                Divider()

                Toggle("Greedy Mode", isOn: $viewModel.greedyModeEnabled)
                    .disabled(viewModel.isRunning)
                    .help("Includes apps with built-in auto-update in both checks and upgrades, such as Chrome, Slack, and VS Code.")

                Divider()

                Toggle("Remember Skipped Packages", isOn: $viewModel.rememberSkippedPackages)
                    .help("When on, Skip persists across checks and app restarts.")

                if viewModel.rememberSkippedPackages || !viewModel.rememberedSkipList.isEmpty {
                    Button("Manage Skipped Packages…") {
                        openWindow(id: "skipped")
                        NSApp.activate(ignoringOtherApps: true)
                    }
                }

                Divider()

                Picker("Check Mode", selection: $viewModel.automaticCheckMode) {
                    ForEach(AutomaticCheckMode.allCases) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }

                if viewModel.automaticCheckMode == .periodic {
                    Picker("Check Interval", selection: $viewModel.checkInterval) {
                        Text("Every Hour").tag(3600.0 as TimeInterval)
                        Text("Every 4 Hours").tag(14400.0 as TimeInterval)
                        Text("Every 12 Hours").tag(43200.0 as TimeInterval)
                        Text("Every 24 Hours").tag(86400.0 as TimeInterval)
                    }
                }

                Divider()

                Button("View Update History") {
                    openWindow(id: "history")
                    NSApp.activate(ignoringOtherApps: true)
                }
            }

            Divider()

            Button(viewModel.appUpdateInfo != nil ? "About TopOff (Update Available)" : "About TopOff") {
                openWindow(id: "about")
                NSApp.activate(ignoringOtherApps: true)
            }

            Button("Quit TopOff") {
                NSApplication.shared.terminate(nil)
            }
        } label: {
            if viewModel.iconState == .checking || viewModel.iconState == .updating {
                SpinningArrowsLabel()
            } else if viewModel.iconState.isCustomImage {
                Image(viewModel.iconState.imageName)
            } else {
                Image(systemName: viewModel.iconState.imageName)
            }
        }

        Window("About TopOff", id: "about") {
            AboutView()
                .environmentObject(viewModel)
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)

        Window("Update History", id: "history") {
            HistoryView()
                .environmentObject(viewModel)
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)

        Window("Skipped Packages", id: "skipped") {
            SkippedPackagesView()
                .environmentObject(viewModel)
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)
    }

    private func progressLabel(for item: UpdateProgressItem) -> String {
        let marker: String
        switch item.state {
        case .queued:
            marker = "○"
        case .updating:
            marker = "●"
        case .repairing:
            marker = "*"
        case .attempted:
            marker = "…"
        case .finished:
            marker = "✓"
        }

        return "\(marker) \(item.name) \(DisplayVersion.abbreviate(item.currentVersion)) → \(DisplayVersion.abbreviate(item.latestVersion))"
    }

}

@MainActor
final class NotificationActionRouter {
    static let shared = NotificationActionRouter()

    var updateAllHandler: (() -> Void)?

    private init() {}

    func updateAllFromNotification() {
        updateAllHandler?()
    }
}

final class TopOffAppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    func applicationWillFinishLaunching(_ notification: Notification) {
        NotificationManager.shared.configureNotificationCategories()
        UNUserNotificationCenter.current().delegate = self
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        terminateIfAnotherTopOffInstanceIsRunning()
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        if response.actionIdentifier == NotificationManager.updateAllActionIdentifier {
            Task { @MainActor in
                NotificationActionRouter.shared.updateAllFromNotification()
                completionHandler()
            }
            return
        }

        completionHandler()
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    private func terminateIfAnotherTopOffInstanceIsRunning() {
        guard !ProcessInfo.processInfo.environment.keys.contains("XCTestConfigurationFilePath") else {
            return
        }
        guard let bundleIdentifier = Bundle.main.bundleIdentifier else { return }

        let currentProcessIdentifier = ProcessInfo.processInfo.processIdentifier
        let alreadyRunning = NSRunningApplication
            .runningApplications(withBundleIdentifier: bundleIdentifier)
            .contains { application in
                application.processIdentifier != currentProcessIdentifier
                    && !application.isTerminated
            }

        if alreadyRunning {
            NSApplication.shared.terminate(nil)
        }
    }
}

/// Menu-bar icon shown while a check or update is in flight.
///
/// Rotation is driven by a `CABasicAnimation` applied directly to the
/// underlying `NSStatusItem.button`'s `CALayer`. This sidesteps two
/// constraints we ran into earlier:
///
/// 1. `MenuBarExtra` labels are rendered through an AppKit bridge that
///    does NOT honor SwiftUI's animation system. `withAnimation` rotation
///    is silently no-op'd; `TimelineView` renders blank.
/// 2. Any spinner driven by `@Published` on the view model fires
///    `objectWillChange` ~10x per second, which forces the entire
///    `MenuBarExtra` menu content closure to reconcile and breaks NSMenu's
///    hover-to-open-submenu delay on the outdated package rows.
///
/// Core Animation runs the rotation on the render server - zero SwiftUI
/// state changes, zero menu invalidations - so the icon spins continuously
/// while the menu's submenu hover behavior remains intact.
private struct SpinningArrowsLabel: View {
    var body: some View {
        Image(systemName: "arrow.triangle.2.circlepath")
            .onAppear { MenuBarSpinController.shared.start() }
            .onDisappear { MenuBarSpinController.shared.stop() }
    }
}

/// Finds the `NSStatusBarButton` created by the app's single `MenuBarExtra`
/// and runs a Core Animation rotation on its layer. Safe to call
/// `start()` / `stop()` repeatedly - adding an animation with the same key
/// replaces the existing one, and removing a non-existent animation is a
/// no-op.
@MainActor
final class MenuBarSpinController {
    static let shared = MenuBarSpinController()

    private weak var cachedButton: NSStatusBarButton?

    /// Walks `NSApp.windows` for the persistent menu-bar status item
    /// button. `NSStatusBar.statusItems` is not public API on macOS, so
    /// we discover the button by type instead. `NSStatusBarButton` is a
    /// dedicated AppKit class used only for menu-bar status items, so any
    /// match is the right one.
    private func findButton() -> NSStatusBarButton? {
        if let cached = cachedButton { return cached }
        for window in NSApp.windows {
            if let button = firstStatusBarButton(in: window.contentView) {
                cachedButton = button
                return button
            }
        }
        return nil
    }

    private func firstStatusBarButton(in root: NSView?) -> NSStatusBarButton? {
        guard let root else { return nil }
        var stack: [NSView] = [root]
        while let view = stack.popLast() {
            if let button = view as? NSStatusBarButton {
                return button
            }
            stack.append(contentsOf: view.subviews)
        }
        return nil
    }

    func start() {
        // Defer to the next runloop turn. `.onAppear` fires inside
        // SwiftUI's layout pass; mutating the host button's layer in that
        // window causes `NSHostingView` to invalidate, re-push the image,
        // re-run `-[NSStatusItem _adjustLength]`, and bounce SwiftUI into
        // another layout pass - a runaway loop that makes the menu-bar
        // slot collapse to zero width and become unclickable.
        DispatchQueue.main.async { [weak self] in
            self?.applyAnimation(attemptsRemaining: 3)
        }
    }

    func stop() {
        cachedButton?.layer?.removeAnimation(forKey: "topoff.spin")
    }

    private func applyAnimation(attemptsRemaining: Int) {
        guard let button = findButton() else { return }
        button.wantsLayer = true
        guard let layer = button.layer else { return }

        let bounds = layer.bounds
        guard bounds.width > 0, bounds.height > 0 else {
            // Layer hasn't been laid out yet. Try again on the next
            // runloop turn (a few times only, then give up - better to
            // render a static icon than to spin retrying forever).
            if attemptsRemaining > 0 {
                DispatchQueue.main.async { [weak self] in
                    self?.applyAnimation(attemptsRemaining: attemptsRemaining - 1)
                }
            }
            return
        }

        // Build a keyframe animation that rotates the layer's content
        // around its visual center WITHOUT modifying `anchorPoint` or
        // `position`. The model-layer geometry stays identical to its
        // resting state, so SwiftUI's `NSHostingView` sees no change and
        // doesn't re-push the image. Each keyframe is a composite:
        //     T(+halfW, +halfH) . R(theta) . T(-halfW, -halfH)
        // which is equivalent to "rotate around (halfW, halfH)" - the
        // standard pivot-around-arbitrary-point trick for matrices.
        let halfW = bounds.width / 2.0
        let halfH = bounds.height / 2.0
        let steps = 60
        let values: [NSValue] = (0...steps).map { i in
            let theta = -Double.pi * 2.0 * Double(i) / Double(steps)
            var t = CATransform3DIdentity
            t = CATransform3DTranslate(t, halfW, halfH, 0)
            t = CATransform3DRotate(t, theta, 0, 0, 1)
            t = CATransform3DTranslate(t, -halfW, -halfH, 0)
            return NSValue(caTransform3D: t)
        }

        let spin = CAKeyframeAnimation(keyPath: "transform")
        spin.values = values
        spin.duration = 1.2
        spin.repeatCount = .infinity
        spin.calculationMode = .linear
        layer.add(spin, forKey: "topoff.spin")
    }
}
