import Foundation
import ServiceManagement
import Adhan

enum PrayerNotificationMode: String, CaseIterable, Codable {
    case off = "off"           // Tidak ada notifikasi
    case silent = "silent"     // Notifikasi tanpa suara
    case azan = "azan"         // Notifikasi dengan azan

    var icon: String {
        switch self {
        case .off: return "bell.slash"
        case .silent: return "bell"
        case .azan: return "bell.and.waves.left.and.right"
        }
    }

    func next() -> PrayerNotificationMode {
        switch self {
        case .off: return .silent
        case .silent: return .azan
        case .azan: return .off
        }
    }
}

enum MenuBarDisplayMode: String, CaseIterable, Codable {
    case prayerAndCountdown = "prayer_countdown"
    case countdownOnly = "countdown"
    case prayerAndTime = "prayer_time"
    case prayerOnly = "prayer"
    case iconOnly = "icon"
}

enum CountdownFormat: String, CaseIterable, Codable {
    case digital = "digital"           // 1:23:45
    case hourMinute = "hour_minute"    // 1:23
    case compact = "compact"           // 2j 10m
    case compactShort = "compact_short" // 2j
    case humanis = "humanis"           // 1 jam lagi

    var example: String {
        switch self {
        case .digital: return "1:23:45"
        case .hourMinute: return "1:23"
        case .compact: return "2j 10m"
        case .compactShort: return "2j"
        case .humanis: return "1 jam lagi"
        }
    }
}

enum PrayerNameFormat: String, CaseIterable, Codable {
    case full = "full"           // Maghrib
    case short3 = "short3"       // Mag
    case short1 = "short1"       // M

    var label: String {
        switch self {
        case .full: return "Lengkap"
        case .short3: return "3 Huruf"
        case .short1: return "1 Huruf"
        }
    }

    var example: String {
        switch self {
        case .full: return "Maghrib"
        case .short3: return "Mag"
        case .short1: return "M"
        }
    }
}

final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    @Published var menuBarDisplayMode: MenuBarDisplayMode {
        didSet { save() }
    }

    @Published var showMenuBarIcon: Bool {
        didSet { save() }
    }

    @Published var showMenuBarPrayerName: Bool {
        didSet { save() }
    }

    @Published var showMenuBarCountdown: Bool {
        didSet { save() }
    }

    @Published var countdownFormat: CountdownFormat {
        didSet { save() }
    }

    @Published var prayerNameFormat: PrayerNameFormat {
        didSet { save() }
    }

    @Published var notificationMinutesBefore: Int {
        didSet { save() }
    }

    @Published var enableAdhanSound: Bool {
        didSet { save() }
    }

    @Published var launchAtLogin: Bool {
        didSet {
            save()
            updateLaunchAtLogin()
        }
    }

    @Published var showNotificationBefore: Bool {
        didSet { save() }
    }

    @Published var reminderMinutesBefore: Int {
        didSet { save() }
    }

    // Per-prayer notification settings
    @Published var prayerNotifications: [String: PrayerNotificationMode] {
        didSet { save() }
    }

    private let defaults = UserDefaults.standard

    private init() {
        // Load from UserDefaults
        if let modeRaw = defaults.string(forKey: "menuBarDisplayMode"),
           let mode = MenuBarDisplayMode(rawValue: modeRaw) {
            self.menuBarDisplayMode = mode
        } else {
            self.menuBarDisplayMode = .prayerAndCountdown
        }

        self.showMenuBarIcon = defaults.object(forKey: "showMenuBarIcon") as? Bool ?? true
        self.showMenuBarPrayerName = defaults.object(forKey: "showMenuBarPrayerName") as? Bool ?? true
        self.showMenuBarCountdown = defaults.object(forKey: "showMenuBarCountdown") as? Bool ?? true

        if let formatRaw = defaults.string(forKey: "countdownFormat"),
           let format = CountdownFormat(rawValue: formatRaw) {
            self.countdownFormat = format
        } else {
            self.countdownFormat = .digital
        }

        if let nameFormatRaw = defaults.string(forKey: "prayerNameFormat"),
           let nameFormat = PrayerNameFormat(rawValue: nameFormatRaw) {
            self.prayerNameFormat = nameFormat
        } else {
            self.prayerNameFormat = .full
        }

        let savedMinutes = defaults.integer(forKey: "notificationMinutesBefore")
        self.notificationMinutesBefore = savedMinutes == 0 ? 15 : savedMinutes

        self.enableAdhanSound = defaults.bool(forKey: "enableAdhanSound")

        self.launchAtLogin = defaults.bool(forKey: "launchAtLogin")

        self.showNotificationBefore = defaults.object(forKey: "showNotificationBefore") as? Bool ?? true

        let savedReminder = defaults.integer(forKey: "reminderMinutesBefore")
        self.reminderMinutesBefore = savedReminder == 0 ? 10 : savedReminder

        // Load per-prayer notifications
        if let data = defaults.data(forKey: "prayerNotifications"),
           let decoded = try? JSONDecoder().decode([String: PrayerNotificationMode].self, from: data) {
            self.prayerNotifications = decoded
        } else {
            // Default: all prayers with azan
            self.prayerNotifications = [
                "fajr": .azan,
                "dhuhr": .azan,
                "asr": .azan,
                "maghrib": .azan,
                "isha": .azan
            ]
        }
    }

    private func save() {
        defaults.set(menuBarDisplayMode.rawValue, forKey: "menuBarDisplayMode")
        defaults.set(showMenuBarIcon, forKey: "showMenuBarIcon")
        defaults.set(showMenuBarPrayerName, forKey: "showMenuBarPrayerName")
        defaults.set(showMenuBarCountdown, forKey: "showMenuBarCountdown")
        defaults.set(countdownFormat.rawValue, forKey: "countdownFormat")
        defaults.set(prayerNameFormat.rawValue, forKey: "prayerNameFormat")
        defaults.set(notificationMinutesBefore, forKey: "notificationMinutesBefore")
        defaults.set(enableAdhanSound, forKey: "enableAdhanSound")
        defaults.set(launchAtLogin, forKey: "launchAtLogin")
        defaults.set(showNotificationBefore, forKey: "showNotificationBefore")
        defaults.set(reminderMinutesBefore, forKey: "reminderMinutesBefore")

        // Save per-prayer notifications
        if let encoded = try? JSONEncoder().encode(prayerNotifications) {
            defaults.set(encoded, forKey: "prayerNotifications")
        }
    }

    // Helper to get/set notification mode for a prayer
    func notificationMode(for prayer: Prayer) -> PrayerNotificationMode {
        let key = prayerKey(for: prayer)
        return prayerNotifications[key] ?? .azan
    }

    func setNotificationMode(_ mode: PrayerNotificationMode, for prayer: Prayer) {
        let key = prayerKey(for: prayer)
        prayerNotifications[key] = mode
    }

    func toggleNotificationMode(for prayer: Prayer) {
        let current = notificationMode(for: prayer)
        setNotificationMode(current.next(), for: prayer)
    }

    private func prayerKey(for prayer: Prayer) -> String {
        switch prayer {
        case .fajr: return "fajr"
        case .dhuhr: return "dhuhr"
        case .asr: return "asr"
        case .maghrib: return "maghrib"
        case .isha: return "isha"
        default: return "unknown"
        }
    }

    private func updateLaunchAtLogin() {
        if #available(macOS 13.0, *) {
            do {
                if launchAtLogin {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("Failed to update launch at login: \(error)")
            }
        }
    }
}
