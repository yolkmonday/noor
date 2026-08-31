import Foundation
import UserNotifications
import os.log

final class NotificationService {

    static let shared = NotificationService()
    private static let logger = Logger(subsystem: "com.noor.app", category: "NotificationService")

    private let center = UNUserNotificationCenter.current()

    @Published var reminderEnabled: Bool {
        didSet {
            UserDefaults.standard.set(reminderEnabled, forKey: "reminderEnabled")
        }
    }

    @Published var reminderMinutesBefore: Int {
        didSet {
            UserDefaults.standard.set(reminderMinutesBefore, forKey: "reminderMinutesBefore")
        }
    }

    private init() {
        reminderEnabled = UserDefaults.standard.object(forKey: "reminderEnabled") as? Bool ?? true
        let savedMinutes = UserDefaults.standard.integer(forKey: "reminderMinutesBefore")
        reminderMinutesBefore = savedMinutes > 0 ? savedMinutes : 5
    }

    /// Request notification permission
    func requestPermission() async -> Bool {
        do {
            return try await center.requestAuthorization(
                options: [.alert, .sound, .badge]
            )
        } catch {
            Self.logger.error("Notification permission error: \(error.localizedDescription)")
            return false
        }
    }

    /// Schedule prayer notification with optional azan
    @MainActor
    func schedulePrayerNotification(
        prayer: String,
        time: Date,
        playAzan: Bool = false
    ) {
        // Skip if time is in the past
        guard time > Date() else { return }

        // Check if azan file is available when playAzan requested
        let shouldPlayAzan: Bool
        if playAzan {
            let azanService = AzanService.shared
            shouldPlayAzan = azanService.selectedAzanId != "silent" && azanService.isAvailable(azanService.selectedAzanId)
        } else {
            shouldPlayAzan = false
        }

        // Notification at exact time
        scheduleAt(
            id: "noor-\(prayer)-exact",
            title: "Waktu \(prayer) Telah Tiba",
            body: "Saatnya menunaikan solat \(prayer)",
            date: time,
            playAzan: shouldPlayAzan,
            prayer: prayer
        )

        // Reminder before prayer time (if enabled)
        if reminderEnabled {
            let reminderDate = time.addingTimeInterval(TimeInterval(-reminderMinutesBefore * 60))
            if reminderDate > Date() {
                scheduleAt(
                    id: "noor-\(prayer)-reminder",
                    title: "\(prayer) dalam \(reminderMinutesBefore) menit",
                    body: "Persiapkan diri untuk solat \(prayer)",
                    date: reminderDate,
                    playAzan: false  // No azan for reminder, just notification
                )
            }
        }
    }

    private func scheduleAt(
        id: String,
        title: String,
        body: String,
        date: Date,
        playAzan: Bool = false,
        prayer: String = ""
    ) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        // Store whether to play azan (and which prayer, for the popup) in userInfo
        content.userInfo = ["playAzan": playAzan, "prayer": prayer]

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: date
        )
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: components,
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: id,
            content: content,
            trigger: trigger
        )

        center.add(request) { error in
            if let error {
                Self.logger.error("Failed to schedule notification: \(error.localizedDescription)")
            }
        }
    }

    /// Play azan sound and show the azan popup (called when notification is received)
    @MainActor
    func playAzanIfNeeded(prayer: String) {
        AzanService.shared.play()
        AzanAlertWindowController.shared.show(prayerName: prayer)
    }

    /// Remove all pending notifications
    func removeAll() {
        center.removeAllPendingNotificationRequests()
    }

    /// Get pending notifications count
    func getPendingCount() async -> Int {
        let requests = await center.pendingNotificationRequests()
        return requests.count
    }
}

// MARK: - Notification Delegate for playing azan
class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show banner even when app is in foreground
        completionHandler([.banner, .sound])

        // Play azan if needed
        if let playAzan = notification.request.content.userInfo["playAzan"] as? Bool, playAzan {
            let prayer = notification.request.content.userInfo["prayer"] as? String ?? ""
            Task { @MainActor in
                NotificationService.shared.playAzanIfNeeded(prayer: prayer)
            }
        }
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        completionHandler()
    }
}
