import SwiftUI
import Combine
import Adhan
import AppKit

@MainActor
final class PrayerTimeViewModel: ObservableObject {

    // MARK: - Published State
    @Published var prayerTimes: PrayerTimes?
    @Published var nextPrayer: Prayer?
    @Published var nextPrayerTime: Date?
    @Published var countdownText: String = "--:--:--"
    @Published var isApproaching: Bool = false  // true jika <= 15 menit sebelum waktu solat
    @Published var remainingInCurrentPrayer: String = ""  // sisa waktu dalam solat saat ini
    @Published var menuBarLabel: String = "Noor"
    @Published var menuBarIcon: String = "moon.stars"
    @Published var showMenuBarIcon: Bool = true
    @Published var currentDate: Date = Date()
    @Published var cityName: String = "Batam"
    @Published var showCityPicker: Bool = false
    @Published var showSettings: Bool = false
    @Published var showAzanPicker: Bool = false

    // MARK: - Services
    private let adhanService = AdhanService.shared
    let locationService = LocationService.shared
    private let notificationService = NotificationService.shared
    private let settings = AppSettings.shared

    nonisolated(unsafe) private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Lifecycle
    init() {
        setupBindings()
        setupTimer()
        setupWakeNotification()
        requestNotificationPermission()
    }

    deinit {
        timer?.invalidate()
    }

    private func setupBindings() {
        locationService.$latitude
            .combineLatest(locationService.$longitude)
            .debounce(for: .milliseconds(100), scheduler: RunLoop.main)
            .sink { [weak self] lat, lng in
                self?.recalculate(lat: lat, lng: lng)
            }
            .store(in: &cancellables)

        locationService.$cityName
            .assign(to: &$cityName)

        // Listen to settings changes (merged + debounced)
        Publishers.Merge5(
            settings.$showMenuBarIcon.map { _ in () },
            settings.$showMenuBarPrayerName.map { _ in () },
            settings.$showMenuBarCountdown.map { _ in () },
            settings.$countdownFormat.map { _ in () },
            settings.$prayerNameFormat.map { _ in () }
        )
        .debounce(for: .milliseconds(50), scheduler: RunLoop.main)
        .sink { [weak self] _ in
            self?.updateCountdown()
        }
        .store(in: &cancellables)
    }

    private func setupTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateCountdown()
            }
        }
    }

    private func setupWakeNotification() {
        NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.didWakeNotification)
            .sink { [weak self] _ in
                Task { @MainActor in
                    guard let self else { return }
                    self.recalculate(lat: self.locationService.latitude, lng: self.locationService.longitude)
                }
            }
            .store(in: &cancellables)
    }

    private func requestNotificationPermission() {
        Task {
            await notificationService.requestPermission()
        }
    }

    // MARK: - City Selection
    func selectCity(_ city: City) {
        locationService.selectCity(city)
        showCityPicker = false
    }

    func useCurrentLocation() {
        locationService.useCurrentLocation()
        showCityPicker = false
    }

    // MARK: - Calculations
    private func recalculate(lat: Double, lng: Double) {
        prayerTimes = adhanService.getPrayerTimes(latitude: lat, longitude: lng)
        updateCountdown()
        scheduleNotifications()
    }

    private func updateCountdown() {
        currentDate = Date()

        guard let prayers = prayerTimes else {
            menuBarLabel = "Noor"
            countdownText = "--:--:--"
            return
        }

        let next: Prayer
        let time: Date

        if let todayNext = prayers.nextPrayer() {
            // Ada solat berikutnya hari ini
            next = todayNext
            time = prayers.time(for: next)
        } else {
            // Setelah Isya, hitung Subuh besok
            next = .fajr
            let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
            let tomorrowPrayers = adhanService.getPrayerTimes(
                latitude: locationService.latitude,
                longitude: locationService.longitude,
                date: tomorrow
            )
            guard let tomorrowPrayers = tomorrowPrayers else {
                menuBarLabel = "Noor"
                countdownText = "--:--:--"
                return
            }
            time = tomorrowPrayers.fajr
        }

        nextPrayer = next
        nextPrayerTime = time

        let diff = time.timeIntervalSince(Date())

        if diff <= 0 {
            // Prayer time has arrived
            recalculate(lat: locationService.latitude, lng: locationService.longitude)
            return
        }

        let h = Int(diff) / 3600
        let m = (Int(diff) % 3600) / 60
        let s = Int(diff) % 60

        // Check if approaching (15 minutes or less)
        isApproaching = diff <= 15 * 60

        // Calculate remaining time in current prayer (time since last prayer started)
        remainingInCurrentPrayer = calculateRemainingInCurrentPrayer(prayers: prayers, nextPrayer: next)

        let prayerName = PrayerName(from: next)
        let name = prayerName.formatted(settings.prayerNameFormat)
        menuBarIcon = prayerName.icon

        // Format countdown based on selected format
        let countdown: String
        switch settings.countdownFormat {
        case .digital:
            if h > 0 {
                countdown = String(format: "%d:%02d:%02d", h, m, s)
            } else {
                countdown = String(format: "%02d:%02d", m, s)
            }
        case .hourMinute:
            if h > 0 {
                countdown = String(format: "%d:%02d", h, m)
            } else {
                countdown = String(format: "0:%02d", m)
            }
        case .humanis:
            countdown = formatHumanis(hours: h, minutes: m, seconds: s)
        case .compact:
            countdown = formatCompact(hours: h, minutes: m, seconds: s)
        case .compactShort:
            if h > 0 {
                countdown = "\(h)j"
            } else {
                countdown = "\(m)m"
            }
        }
        countdownText = countdown

        // Build menu bar label from individual toggles
        var parts: [String] = []
        if settings.showMenuBarPrayerName {
            parts.append(name)
        }
        if settings.showMenuBarCountdown {
            parts.append(countdown)
        }
        menuBarLabel = parts.joined(separator: " ")
        showMenuBarIcon = settings.showMenuBarIcon
    }

    private func formatHumanis(hours: Int, minutes: Int, seconds: Int) -> String {
        if hours > 0 {
            if minutes > 30 {
                return "\(hours + 1) jam lagi"
            } else if minutes > 0 {
                return "\(hours) jam \(minutes) mnt"
            } else {
                return "\(hours) jam lagi"
            }
        } else if minutes > 0 {
            if minutes == 1 {
                return "1 menit lagi"
            } else if minutes < 5 {
                return "\(minutes) menit lagi"
            } else {
                return "\(minutes) mnt lagi"
            }
        } else {
            return "\(seconds) detik"
        }
    }

    private func formatCompact(hours: Int, minutes: Int, seconds: Int) -> String {
        if hours > 0 {
            return "\(hours)j \(minutes)m"
        } else if minutes > 0 {
            return "\(minutes)m"
        } else {
            return "\(seconds)d"
        }
    }

    private func scheduleNotifications() {
        notificationService.removeAll()

        guard let prayers = prayerTimes else { return }

        let prayerList: [(Prayer, String)] = [
            (.fajr, "Subuh"),
            (.dhuhr, "Dzuhur"),
            (.asr, "Ashar"),
            (.maghrib, "Maghrib"),
            (.isha, "Isya")
        ]

        for (prayer, name) in prayerList {
            let time = prayers.time(for: prayer)
            notificationService.schedulePrayerNotification(prayer: name, time: time)
        }
    }

    // MARK: - Helpers
    func timeString(for prayer: Prayer) -> String {
        guard let prayers = prayerTimes else { return "--:--" }

        let time = prayers.time(for: prayer)
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: time)
    }

    func isPast(_ prayer: Prayer) -> Bool {
        guard let prayers = prayerTimes else { return false }
        let time = prayers.time(for: prayer)
        return time < Date()
    }

    func isNext(_ prayer: Prayer) -> Bool {
        return prayer == nextPrayer
    }

    private func calculateRemainingInCurrentPrayer(prayers: PrayerTimes, nextPrayer: Prayer) -> String {
        // Get current prayer (the one before next)
        let prayerOrder: [Prayer] = [.fajr, .sunrise, .dhuhr, .asr, .maghrib, .isha]

        guard let nextIndex = prayerOrder.firstIndex(of: nextPrayer) else {
            return ""
        }

        // Current prayer is the one before next
        let currentIndex = nextIndex > 0 ? nextIndex - 1 : prayerOrder.count - 1
        let currentPrayer = prayerOrder[currentIndex]

        // Skip sunrise as it's not a prayer time
        if currentPrayer == .sunrise {
            return ""
        }

        let currentPrayerTime = prayers.time(for: currentPrayer)
        let nextPrayerTime = prayers.time(for: nextPrayer)
        let now = Date()

        // Time elapsed since current prayer started
        let elapsed = now.timeIntervalSince(currentPrayerTime)
        // Total duration of current prayer window
        let totalDuration = nextPrayerTime.timeIntervalSince(currentPrayerTime)
        // Remaining time in current prayer window
        let remaining = totalDuration - elapsed

        if remaining <= 0 {
            return ""
        }

        let h = Int(remaining) / 3600
        let m = (Int(remaining) % 3600) / 60

        if h > 0 {
            return "\(h)j \(m)m tersisa"
        } else {
            return "\(m) menit tersisa"
        }
    }

    func currentPrayerName() -> String? {
        guard let prayers = prayerTimes,
              let next = nextPrayer else { return nil }

        let prayerOrder: [Prayer] = [.fajr, .sunrise, .dhuhr, .asr, .maghrib, .isha]
        guard let nextIndex = prayerOrder.firstIndex(of: next), nextIndex > 0 else {
            return nil
        }

        let currentPrayer = prayerOrder[nextIndex - 1]
        if currentPrayer == .sunrise {
            return nil
        }

        return PrayerName(from: currentPrayer).rawValue
    }
}
