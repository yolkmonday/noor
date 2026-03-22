# ☪ NOOR — نور

**Aplikasi Pengingat & Jadwal Solat untuk macOS Menu Bar**

*Technical Documentation & Project Blueprint*\
*Swift + SwiftUI + Adhan · macOS 14+*

| Detail | Keterangan |
|--------|-----------|
| Dokumen | Initial Project Document (PRD + Architecture + Code) |
| Versi | 1.0.0 |
| Tanggal | 3 Februari 2026 |
| Platform | macOS 14+ (Sonoma) |
| Tech Stack | Swift 5.10 / SwiftUI / Adhan Swift |
| Status | Draft — Siap Development |

---

## Daftar Isi

1. [Overview Proyek](#1-overview-proyek)
2. [Spesifikasi Fitur](#2-spesifikasi-fitur)
3. [Tech Stack & Dependencies](#3-tech-stack--dependencies)
4. [Arsitektur Aplikasi](#4-arsitektur-aplikasi)
5. [Struktur Proyek](#5-struktur-proyek)
6. [Core Implementation](#6-core-implementation)
7. [Notification System](#7-notification-system)
8. [Konfigurasi Metode Kalkulasi](#8-konfigurasi-metode-kalkulasi)
9. [Development Roadmap](#9-development-roadmap)
10. [Referensi & Resources](#10-referensi--resources)

---

## 1. Overview Proyek

Noor adalah aplikasi menu bar macOS untuk menampilkan jadwal solat, countdown waktu solat berikutnya, arah kiblat, dan notifikasi pengingat adzan. Aplikasi ini dirancang untuk selalu aktif di background dengan footprint resource yang minimal.

> **💡 Kenapa Menu Bar App?**
>
> - Selalu visible di menu bar tanpa perlu buka app terpisah.
> - Resource usage sangat rendah (~15-30 MB RAM).
> - Integrasi native macOS: notifikasi, lokasi, kalender.
> - Quick-glance: countdown waktu solat terlihat sekilas.

### 1.1 Target User

- Muslim yang menggunakan Mac sebagai daily driver
- Pekerja remote / WFH yang butuh pengingat waktu solat
- User yang menginginkan app ringan dan non-intrusive

### 1.2 Key Metrics

| Metrik | Target |
|--------|--------|
| Bundle size | < 10 MB |
| RAM usage (idle) | < 30 MB |
| Startup time | < 0.5 detik |
| Akurasi waktu solat | ±1 menit dari Kemenag RI |
| Battery impact | Negligible (no polling, timer-based) |

---

## 2. Spesifikasi Fitur

### 2.1 Menu Bar Item

Menampilkan icon bulan sabit, nama solat berikutnya, dan countdown real-time di menu bar macOS. Contoh tampilan:

```
  ☪  Maghrib  -2:39
```

- Update countdown setiap detik menggunakan Timer
- Icon berubah sesuai waktu: bulan (malam), matahari (siang)
- Klik untuk buka dropdown panel

### 2.2 Dropdown Panel

Panel popup yang muncul saat menu bar item diklik. Menampilkan informasi lengkap:

- **Header:** Salam, tanggal Hijriyah & Masehi, lokasi
- **Hero Card:** Nama solat berikutnya, waktu, progress bar countdown
- **Jadwal Lengkap:** 6 waktu (Subuh, Syuruq, Dzuhur, Ashar, Maghrib, Isya) dengan status
- **Week Strip:** Navigasi per hari dalam seminggu
- **Footer:** Arah kiblat, tombol kalender, tombol settings

### 2.3 Notifikasi Solat

Push notification lokal menggunakan UNUserNotificationCenter:

- Notifikasi 15 menit sebelum waktu solat (default, configurable)
- Notifikasi saat waktu solat tiba
- Opsi suara adzan (custom sound, max 30 detik)
- Action button: "Buka Noor" dan "Dismiss"

### 2.4 Fitur Tambahan

| Fitur | Deskripsi | Prioritas |
|-------|-----------|-----------|
| Auto Location | CoreLocation untuk deteksi kota otomatis | P0 |
| Multi Metode | Kemenag, MWL, ISNA, Karachi, dll | P0 |
| Dark/Light Mode | Mengikuti system appearance | P0 |
| Arah Kiblat | Kompas kiblat berdasarkan koordinat GPS | P1 |
| Kalender Hijriyah | Tampilkan tanggal Islam di header | P1 |
| Launch at Login | Otomatis jalan saat Mac startup | P1 |
| Suara Adzan | Audio adzan opsional saat waktu tiba | P2 |
| macOS Widget | Widget untuk Notification Center | P2 |

---

## 3. Tech Stack & Dependencies

### 3.1 Core Stack

| Layer | Teknologi | Keterangan |
|-------|-----------|-----------|
| Language | Swift 5.10 | Versi terbaru, full concurrency |
| UI Framework | SwiftUI | MenuBarExtra + declarative UI |
| Menu Bar | MenuBarExtra (.window) | Built-in SwiftUI scene, macOS 13+ |
| Prayer Calc | Adhan Swift 1.4 | MIT license, SPM, presisi tinggi |
| Notifications | UNUserNotificationCenter | Local notification scheduling |
| Location | CoreLocation | CLLocationManager, auto-detect |
| Calendar | Calendar(.islamic) | Foundation, built-in iOS/macOS |
| Storage | UserDefaults / SwiftData | Preference & cached data |
| Audio | AVFoundation | Playback suara adzan |
| Build Tool | Xcode 16+ | Target macOS 14+ (Sonoma) |

### 3.2 Adhan Swift Library

Adhan Swift adalah library open-source dari Batoul Apps untuk kalkulasi waktu solat dengan presisi tinggi. Library ini menggunakan persamaan astronomi langsung dari buku "Astronomical Algorithms" oleh Jean Meeus.

> **Fitur Adhan Swift:**
>
> - Kalkulasi 5 waktu solat + sunrise + Sunnah times
> - Support 8+ metode kalkulasi (Kemenag, MWL, ISNA, dll)
> - Perhitungan arah Kiblat dari koordinat GPS
> - Madhab Syafi'i dan Hanafi
> - High latitude rules untuk daerah kutub
> - MIT License, zero dependencies

**Instalasi via Swift Package Manager:**

```swift
// Package.swift
dependencies: [
    .package(
        url: "https://github.com/batoulapps/adhan-swift",
        .branch("main")
    )
]
```

### 3.3 Entitlements & Permissions

| Permission | Key | Alasan |
|-----------|-----|--------|
| Location | NSLocationWhenInUseUsageDescription | Auto-detect koordinat untuk kalkulasi |
| Notification | UNUserNotificationCenter | Pengingat waktu solat |
| Network | com.apple.security.network.client | Opsional: update data online |
| Launch at Login | ServiceManagement | Login item registration |

---

## 4. Arsitektur Aplikasi

### 4.1 High-Level Architecture

Noor menggunakan arsitektur MVVM (Model-View-ViewModel) yang clean dan modular:

```
┌───────────────────────────────────────────┐
│           NoorApp.swift (@main)           │
│     MenuBarExtra → NoorPanelView          │
└───────────────────┬───────────────────────┘
                    │
    ┌───────────────┴──────────────────┐
    │           ViewModels             │
    ├──────────────────────────────────┤
    │  PrayerTimeVM    NotificationVM  │
    │  LocationVM      SettingsVM      │
    └───────────────┬──────────────────┘
                    │
    ┌───────────────┴──────────────────┐
    │           Services               │
    ├──────────────────────────────────┤
    │  AdhanService     LocationService│
    │  NotifService     StorageService │
    └──────────────────────────────────┘
```

### 4.2 Data Flow

1. **LocationService** mendeteksi koordinat user via CoreLocation
2. **AdhanService** menghitung waktu solat menggunakan Adhan Swift
3. **PrayerTimeVM** meng-observe perubahan dan update UI setiap detik
4. **NotifService** menjadwalkan notifikasi lokal untuk setiap waktu solat
5. **MenuBarExtra** label di-update dengan nama solat + countdown

---

## 5. Struktur Proyek

```
Noor/
├── NoorApp.swift                    # @main entry point
├── Info.plist                       # LSUIElement = YES
├── Noor.entitlements                # Permissions
│
├── Models/
│   ├── PrayerTime.swift             # Prayer time model
│   ├── PrayerName.swift             # Enum: fajr, sunrise, dhuhr...
│   ├── CalculationConfig.swift      # Method, madhab, adjustments
│   └── AppSettings.swift            # User preferences model
│
├── Services/
│   ├── AdhanService.swift           # Wrapper around Adhan library
│   ├── LocationService.swift        # CoreLocation manager
│   ├── NotificationService.swift    # UNUserNotificationCenter
│   └── HijriDateService.swift       # Islamic calendar conversion
│
├── ViewModels/
│   ├── PrayerTimeViewModel.swift    # Main prayer time logic
│   └── SettingsViewModel.swift      # Settings state
│
├── Views/
│   ├── NoorPanelView.swift          # Main dropdown panel
│   ├── PrayerHeroCard.swift         # Next prayer hero section
│   ├── PrayerRowView.swift          # Individual prayer row
│   ├── WeekStripView.swift          # Day-of-week navigation
│   ├── QiblaView.swift              # Qibla compass
│   └── SettingsView.swift           # Settings panel
│
├── Resources/
│   ├── Assets.xcassets/             # App icon, menu bar icon
│   └── Sounds/                      # Adzan audio files
│       └── adzan.caf               # Max 30s for notification
│
└── Package.swift                    # SPM: Adhan dependency
```

---

## 6. Core Implementation

### 6.1 NoorApp.swift — Entry Point

File utama yang mendefinisikan menu bar app menggunakan `MenuBarExtra` scene dari SwiftUI. Perhatikan penggunaan `.menuBarExtraStyle(.window)` untuk popup panel, bukan menu dropdown biasa.

```swift
import SwiftUI

@main
struct NoorApp: App {
    @StateObject private var prayerVM = PrayerTimeViewModel()
    
    var body: some Scene {
        MenuBarExtra {
            NoorPanelView()
                .environmentObject(prayerVM)
                .frame(width: 360, height: 520)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: prayerVM.menuBarIcon)
                Text(prayerVM.menuBarLabel)
                    .monospacedDigit()
            }
        }
        .menuBarExtraStyle(.window)
    }
}
```

> **⚠️ Penting: Info.plist**
>
> Set `LSUIElement` (Application is agent) = `YES`.\
> Ini menyembunyikan icon app dari Dock, menjadikan Noor murni menu bar app.

### 6.2 AdhanService.swift — Prayer Calculation

Service layer yang membungkus Adhan Swift library. Menghitung waktu solat berdasarkan koordinat dan metode yang dipilih user.

```swift
import Foundation
import Adhan

final class AdhanService {
    
    /// Hitung waktu solat untuk tanggal & koordinat tertentu
    func getPrayerTimes(
        latitude: Double,
        longitude: Double,
        date: Date = Date(),
        method: CalculationMethod = .other
    ) -> PrayerTimes? {
        let coordinates = Coordinates(
            latitude: latitude,
            longitude: longitude
        )
        
        let cal = Calendar(identifier: .gregorian)
        let dateComponents = cal.dateComponents(
            [.year, .month, .day], from: date
        )
        
        // Kemenag RI parameters
        var params = method.params
        params.fajrAngle = 20.0
        params.ishaAngle = 18.0
        params.madhab = .shafi
        
        return PrayerTimes(
            coordinates: coordinates,
            date: dateComponents,
            calculationParameters: params
        )
    }
    
    /// Hitung arah kiblat dari koordinat
    func getQiblaDirection(
        latitude: Double,
        longitude: Double
    ) -> Double {
        let coordinates = Coordinates(
            latitude: latitude,
            longitude: longitude
        )
        return Qibla(coordinates: coordinates).direction
    }
}
```

### 6.3 PrayerTimeViewModel.swift

ViewModel utama yang mengelola state waktu solat, countdown, dan update timer. Menggunakan `@Observable` macro (macOS 14+) untuk reactive updates.

```swift
import SwiftUI
import Adhan
import Combine

@Observable
final class PrayerTimeViewModel: ObservableObject {
    
    // MARK: - Published State
    var prayerTimes: PrayerTimes?
    var nextPrayer: Prayer?
    var nextPrayerTime: Date?
    var countdownText: String = "--:--"
    var menuBarLabel: String = "☪ Solat"
    var menuBarIcon: String = "moon.stars"
    var qiblaDirection: Double = 0.0
    var hijriDate: String = ""
    
    // MARK: - Services
    private let adhanService = AdhanService()
    private let locationService = LocationService()
    private var timer: Timer?
    
    // MARK: - Lifecycle
    init() {
        setupLocation()
        startTimer()
    }
    
    private func setupLocation() {
        locationService.onLocationUpdate = {
            [weak self] lat, lng in
            self?.recalculate(lat: lat, lng: lng)
        }
        locationService.requestLocation()
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(
            withTimeInterval: 1.0,
            repeats: true
        ) { [weak self] _ in
            self?.updateCountdown()
        }
    }
    
    private func recalculate(
        lat: Double, lng: Double
    ) {
        prayerTimes = adhanService.getPrayerTimes(
            latitude: lat, longitude: lng
        )
        qiblaDirection = adhanService.getQiblaDirection(
            latitude: lat, longitude: lng
        )
        updateHijriDate()
        updateCountdown()
        scheduleNotifications()
    }
    
    private func updateCountdown() {
        guard let prayers = prayerTimes,
              let next = prayers.nextPrayer(),
              let time = prayers.time(for: next)
        else { return }
        
        self.nextPrayer = next
        self.nextPrayerTime = time
        
        let diff = time.timeIntervalSince(Date())
        let h = Int(diff) / 3600
        let m = Int(diff) % 3600 / 60
        let s = Int(diff) % 60
        
        let name = prayerName(for: next)
        countdownText = String(
            format: "-%d:%02d:%02d", h, m, s
        )
        menuBarLabel = "\(name) \(countdownText)"
        menuBarIcon = iconName(for: next)
    }
    
    func prayerName(for prayer: Prayer) -> String {
        switch prayer {
        case .fajr:    return "Subuh"
        case .sunrise: return "Syuruq"
        case .dhuhr:   return "Dzuhur"
        case .asr:     return "Ashar"
        case .maghrib: return "Maghrib"
        case .isha:    return "Isya"
        }
    }
}
```

---

## 7. Notification System

Noor menggunakan UNUserNotificationCenter untuk menjadwalkan notifikasi lokal. Setiap kali waktu solat dihitung ulang, semua pending notification dihapus dan dijadwalkan ulang.

### 7.1 NotificationService.swift

```swift
import UserNotifications

final class NotificationService {
    
    private let center = UNUserNotificationCenter.current()
    
    /// Request notification permission
    func requestPermission() async -> Bool {
        do {
            return try await center.requestAuthorization(
                options: [.alert, .sound, .badge]
            )
        } catch {
            return false
        }
    }
    
    /// Schedule prayer notification
    func schedulePrayerNotification(
        prayer: String,
        time: Date,
        minutesBefore: Int = 15
    ) {
        // Notification saat waktu tiba
        scheduleAt(
            id: "noor-\(prayer)-exact",
            title: "Waktu \(prayer) telah tiba",
            body: "Waktu solat \(prayer)",
            date: time,
            sound: "adzan.caf"
        )
        
        // Reminder sebelum waktu
        let reminderDate = time.addingTimeInterval(
            TimeInterval(-minutesBefore * 60)
        )
        scheduleAt(
            id: "noor-\(prayer)-reminder",
            title: "\(prayer) dalam \(minutesBefore) menit",
            body: "Persiapkan diri untuk solat \(prayer)",
            date: reminderDate
        )
    }
    
    private func scheduleAt(
        id: String,
        title: String,
        body: String,
        date: Date,
        sound: String? = nil
    ) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        
        if let sound {
            content.sound = UNNotificationSound(
                named: UNNotificationSoundName(sound)
            )
        } else {
            content.sound = .default
        }
        
        let components = Calendar.current
            .dateComponents(
                [.hour, .minute, .second],
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
        center.add(request)
    }
    
    /// Remove all pending notifications
    func removeAll() {
        center.removeAllPendingNotificationRequests()
    }
}
```

---

## 8. Konfigurasi Metode Kalkulasi

Noor mendukung berbagai metode kalkulasi waktu solat. Default menggunakan parameter Kemenag RI yang umum dipakai di Indonesia.

### 8.1 Parameter Metode

| Metode | Fajr Angle | Isha Angle | Region |
|--------|-----------|-----------|--------|
| **Kemenag RI (default)** | 20.0° | 18.0° | Indonesia |
| MWL | 18.0° | 17.0° | Eropa, Asia Timur |
| ISNA | 15.0° | 15.0° | Amerika Utara |
| Egypt | 19.5° | 17.5° | Afrika, Timur Tengah |
| Karachi | 18.0° | 18.0° | Pakistan, Asia Selatan |
| Umm Al-Qura | 18.5° | 90 min | Arab Saudi |
| Tehran | 17.7° | 14.0° | Iran |
| Moonsighting | 18.0° | 18.0° | Global (Shafaq) |

### 8.2 Koordinat Default Batam

```swift
// Batam, Kepulauan Riau
let defaultCoordinates = Coordinates(
    latitude: 1.0456,     // 1° 2' 44" N
    longitude: 104.0305   // 104° 1' 50" E
)

// Arah Kiblat dari Batam
let qibla = Qibla(coordinates: defaultCoordinates)
// qibla.direction ≈ 292.5° (Barat Laut)

// Timezone: WIB (UTC+7)
let timezone = TimeZone(identifier: "Asia/Jakarta")
```

---

## 9. Development Roadmap

### Phase 1 — MVP (2-3 Minggu)

Core functionality yang harus selesai sebelum testing:

- Menu bar item dengan icon + nama solat + countdown
- Dropdown panel: jadwal 6 waktu, hero card, status
- Kalkulasi Adhan dengan metode Kemenag RI
- Auto-detect lokasi menggunakan CoreLocation
- Notifikasi lokal sebelum dan saat waktu solat
- Info.plist: LSUIElement = YES (hide from Dock)

### Phase 2 — Enhancement (2 Minggu)

Fitur pelengkap untuk pengalaman yang lebih baik:

- Arah kiblat dengan kompas visual
- Kalender Hijriyah di header panel
- Pilihan metode kalkulasi di Settings
- Suara adzan opsional (custom .caf audio)
- Launch at Login via ServiceManagement
- Week/day navigation untuk lihat jadwal hari lain

### Phase 3 — Polish & Distribution (1-2 Minggu)

Final touches dan persiapan distribusi:

- Settings panel lengkap (appearance, notification, method)
- macOS Widget untuk Notification Center
- Light/dark mode theming mengikuti system
- Onboarding flow saat pertama kali buka
- App Store metadata, screenshots, review submission
- DMG alternative untuk distribusi langsung

### 9.1 Timeline Summary

| Phase | Durasi | Deliverable |
|-------|--------|-------------|
| Phase 1 - MVP | 2-3 minggu | Functional menu bar app |
| Phase 2 - Enhancement | 2 minggu | Full-featured app |
| Phase 3 - Polish | 1-2 minggu | App Store ready |
| **Total** | **5-7 minggu** | **v1.0.0 Release** |

---

## 10. Referensi & Resources

### 10.1 Documentation

- Apple MenuBarExtra: [developer.apple.com/documentation/swiftui/menubarextra](https://developer.apple.com/documentation/swiftui/menubarextra)
- Adhan Swift: [github.com/batoulapps/adhan-swift](https://github.com/batoulapps/adhan-swift)
- UNUserNotificationCenter: [developer.apple.com/documentation/usernotifications](https://developer.apple.com/documentation/usernotifications)
- CoreLocation: [developer.apple.com/documentation/corelocation](https://developer.apple.com/documentation/corelocation)
- ServiceManagement (Login Items): [developer.apple.com/documentation/servicemanagement](https://developer.apple.com/documentation/servicemanagement)

### 10.2 Tutorial & Guides

- Build a macOS menu bar utility in SwiftUI — nilcoalescing.com
- Create a mac menu bar app with MenuBarExtra — sarunw.com
- SwiftUI MenuBarExtra hands-on — cindori.com

### 10.3 Design Reference

- Prototype UI: `noor-prototype.html` (included)
- Design system: dark theme, gold accent (`#C8963E`), SF Mono typography
- Islamic-inspired geometric patterns with atmospheric depth

---

*☪ Noor v1.0.0 — Dokumen dibuat 3 Februari 2026*
