import Foundation
import Adhan

enum PrayerName: String, CaseIterable, Identifiable {
    case fajr = "Subuh"
    case sunrise = "Syuruq"
    case dhuhr = "Dzuhur"
    case asr = "Ashar"
    case maghrib = "Maghrib"
    case isha = "Isya"

    var id: String { rawValue }

    init(from prayer: Prayer) {
        switch prayer {
        case .fajr: self = .fajr
        case .sunrise: self = .sunrise
        case .dhuhr: self = .dhuhr
        case .asr: self = .asr
        case .maghrib: self = .maghrib
        case .isha: self = .isha
        }
    }

    var icon: String {
        switch self {
        case .fajr: return "sunrise"
        case .sunrise: return "sun.horizon"
        case .dhuhr: return "sun.max"
        case .asr: return "sun.min"
        case .maghrib: return "sunset"
        case .isha: return "moon.stars"
        }
    }

    var short3: String {
        switch self {
        case .fajr: return "Sub"
        case .sunrise: return "Syu"
        case .dhuhr: return "Dzu"
        case .asr: return "Asr"
        case .maghrib: return "Mag"
        case .isha: return "Isy"
        }
    }

    var short1: String {
        switch self {
        case .fajr: return "S"
        case .sunrise: return "Y"
        case .dhuhr: return "D"
        case .asr: return "A"
        case .maghrib: return "M"
        case .isha: return "I"
        }
    }

    func formatted(_ format: PrayerNameFormat) -> String {
        switch format {
        case .full: return rawValue
        case .short3: return short3
        case .short1: return short1
        }
    }
}
