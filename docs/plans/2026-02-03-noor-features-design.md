# Noor macOS - Fitur Lengkap Design

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan task-by-task.

**Goal:** Menambahkan pencatatan ibadah, statistik, notifikasi/azan, dan kalender Hijriyah ke Noor macOS app.

**Architecture:** Tab-based UI dengan Core Data untuk persistensi. Download-on-demand untuk audio azan. Konversi Hijriyah menggunakan algoritma Islamic calendar.

**Tech Stack:** SwiftUI, Core Data, AVFoundation (audio), UNUserNotificationCenter

---

## Fitur yang Diimplementasi

### 1. Pencatatan Ibadah (Prayer Tracking)
- Toggle 5 waktu solat wajib (Subuh, Dzuhur, Ashar, Maghrib, Isya)
- Ibadah sunnah: Tahajud, Dhuha, Rawatib
- Tampilan mingguan dengan progress visual
- Data persisten dengan Core Data

### 2. Statistik Ibadah
- Total hari dengan pencatatan
- Hari lengkap (5/5 solat)
- Current streak & best streak
- Persentase mingguan/bulanan

### 3. Notifikasi & Azan
- Notifikasi pada waktu solat
- Reminder X menit sebelum
- Pilihan suara azan (download on-demand)
- Mode: silent, azan_makkah, azan_mishary, dll

### 4. Kalender Hijriyah
- Tampilkan tanggal Hijriyah di header panel utama

---

## Data Model

### Core Data Entities

```swift
// PrayerLog - Pencatatan solat harian
entity PrayerLog {
    id: UUID
    date: Date              // Tanggal (tanpa jam)
    prayerType: String      // fajr/dhuhr/asr/maghrib/isha/tahajud/dhuha/rawatib_*
    completed: Bool
    completedAt: Date?      // Timestamp saat selesai
}

// AzanAudio - Audio yang sudah didownload  
entity AzanAudio {
    id: String              // azan_makkah, azan_mishary, dll
    name: String            // Display name
    localPath: String       // Path file lokal
    downloadedAt: Date
}
```

### UserDefaults Settings
- `selectedAzanSound: String` - ID azan terpilih
- `azanEnabled: Bool` - Putar azan on/off
- `reminderEnabled: Bool` - Reminder on/off  
- `reminderMinutesBefore: Int` - Default 5

---

## File Structure

```
Noor/
├── Models/
│   ├── PrayerLog.swift          // Core Data entity
│   ├── AzanAudio.swift          // Core Data entity
│   ├── HijriDate.swift          // Struct tanggal Hijriyah
│   └── Noor.xcdatamodeld/       // Core Data model
├── Services/
│   ├── PrayerLogService.swift   // CRUD prayer logs
│   ├── StatsService.swift       // Kalkulasi statistik
│   ├── AzanService.swift        // Download & play azan
│   └── HijriCalendarService.swift
├── ViewModels/
│   └── SolatkuViewModel.swift   // State untuk tab Solatku
├── Views/
│   ├── NoorPanelView.swift      // Update: tab container
│   ├── Tabs/
│   │   ├── JadwalTab.swift      // Panel jadwal (existing)
│   │   └── SolatkuTab.swift     // Tab pencatatan
│   └── Components/
│       ├── PrayerCheckRow.swift // Row dengan toggle
│       ├── WeeklyCalendar.swift // Kalender mingguan
│       ├── StatsCard.swift      // Kartu statistik
│       └── AzanPickerView.swift // Pilih suara azan
```

---

## UI Flow

```
┌─────────────────────────────────┐
│  🌙 Noor          Batam ▼       │
│  Senin, 3 Feb 2026              │
│  5 Sya'ban 1447 H    ← Hijriyah │
├─────────────────────────────────┤
│  [Jadwal]  [Solatku]   ← Tabs   │
├─────────────────────────────────┤
│                                 │
│  Tab Jadwal:                    │
│  - Hero card (next prayer)      │
│  - List waktu solat             │
│                                 │
│  Tab Solatku:                   │
│  - Weekly calendar (Sen-Min)    │
│  - Today's checklist            │
│  - Quick stats                  │
│                                 │
├─────────────────────────────────┤
│  ⚙️                      Quit   │
└─────────────────────────────────┘
```

---

## Azan Audio Sources

Download dari URL publik:
- `azan_makkah` - Masjidil Haram
- `azan_mishary` - Mishary Rashid
- `azan_abdul_basit` - Abdul Basit

Storage: `~/Library/Application Support/Noor/azan/`

---

## Implementation Tasks

### Task 1: Core Data Setup
- Buat Noor.xcdatamodeld
- Entity: PrayerLog, AzanAudio
- Setup PersistenceController

### Task 2: Prayer Log Service
- CRUD operations untuk PrayerLog
- Query by date, date range
- Toggle completion

### Task 3: Stats Service  
- calculateStats(from:to:)
- streak calculation
- weekly/monthly percentage

### Task 4: Hijri Calendar Service
- Gregorian to Hijri conversion
- Format tanggal Hijriyah

### Task 5: Tab Navigation UI
- Update NoorPanelView dengan tabs
- Extract existing view ke JadwalTab
- Add Hijri date ke header

### Task 6: Solatku Tab - Weekly Calendar
- WeeklyCalendar component
- Visual dots untuk completion

### Task 7: Solatku Tab - Prayer Checklist
- PrayerCheckRow component
- Today's prayers dengan toggle

### Task 8: Solatku Tab - Stats Card
- StatsCard component
- Current streak, best streak, percentage

### Task 9: Azan Service
- Download manager
- Audio playback dengan AVFoundation
- Storage management

### Task 10: Azan Settings UI
- AzanPickerView
- Download progress
- Preview/test sound

### Task 11: Enhanced Notifications
- Schedule dengan azan sound
- Reminder sebelum waktu solat

### Task 12: Integration & Polish
- Connect all services
- Test full flow
- Fix edge cases
