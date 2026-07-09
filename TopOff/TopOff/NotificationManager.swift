import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    static let updatesAvailableCategoryIdentifier = "updatesAvailable"
    static let updateAllActionIdentifier = "updateAll"

    private init() {}

    func configureNotificationCategories() {
        let updateAllAction = UNNotificationAction(
            identifier: Self.updateAllActionIdentifier,
            title: "Update All",
            options: [.foreground]
        )
        let updatesAvailableCategory = UNNotificationCategory(
            identifier: Self.updatesAvailableCategoryIdentifier,
            actions: [updateAllAction],
            intentIdentifiers: [],
            options: []
        )
        UNUserNotificationCenter.current().setNotificationCategories([updatesAvailableCategory])
    }

    func requestPermission() {
        configureNotificationCategories()
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }

    private func sendCompletionNotification(
        success: Bool,
        title: String,
        body: String,
        categoryIdentifier: String? = nil
    ) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = success ? .default : .defaultCritical
        if let categoryIdentifier {
            content.categoryIdentifier = categoryIdentifier
        }

        // Use custom notification icon if available
        if let imageURL = Bundle.main.url(forResource: "DancingStickFigure", withExtension: "png") {
            if let attachment = try? UNNotificationAttachment(identifier: "image", url: imageURL, options: nil) {
                content.attachments = [attachment]
            }
        }

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }

    func showCompletionNotification(success: Bool, message: String) {
        let title = "TopOff"
        let body: String
        if success {
            body = message.isEmpty ? "All packages updated! 🎉" : message
        } else {
            body = "Update failed: \(message)"
        }
        sendCompletionNotification(success: success, title: title, body: body)
    }

    func showCompletionNotification(success: Bool, title: String, body: String) {
        let resolvedBody: String
        if success {
            resolvedBody = body.isEmpty ? "All packages updated! 🎉" : body
        } else {
            resolvedBody = body
        }
        sendCompletionNotification(success: success, title: title, body: resolvedBody)
    }

    func showUpdatesAvailableNotification(count: Int) {
        guard let body = Self.updatesAvailableNotificationBody(count: count) else { return }
        sendCompletionNotification(
            success: true,
            title: "TopOff",
            body: body,
            categoryIdentifier: Self.updatesAvailableCategoryIdentifier
        )
    }

    static func updatesAvailableNotificationBody(count: Int) -> String? {
        guard count > 0 else { return nil }
        let noun = count == 1 ? "update" : "updates"
        return "\(count) Homebrew \(noun) available"
    }
}
