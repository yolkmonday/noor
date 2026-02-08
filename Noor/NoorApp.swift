import SwiftUI
import UserNotifications

@main
struct NoorApp: App {
    @StateObject private var prayerVM = PrayerTimeViewModel()

    init() {
        // Set notification delegate for azan playback
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
    }

    var body: some Scene {
        MenuBarExtra {
            NoorPanelView()
                .environmentObject(prayerVM)
        } label: {
            HStack(spacing: 4) {
                if prayerVM.showMenuBarIcon {
                    Image(systemName: prayerVM.menuBarIcon)
                }
                if !prayerVM.menuBarLabel.isEmpty {
                    Text(prayerVM.menuBarLabel)
                        .monospacedDigit()
                }
            }
        }
        .menuBarExtraStyle(.window)
    }
}
