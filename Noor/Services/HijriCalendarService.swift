import Foundation

struct HijriDate {
    let day: Int
    let month: Int
    let year: Int

    var monthName: String {
        HijriCalendarService.monthNames[month - 1]
    }

    var formatted: String {
        "\(day) \(monthName) \(year) H"
    }

    var shortFormatted: String {
        "\(day) \(monthName) \(year)"
    }
}

final class HijriCalendarService {
    static let shared = HijriCalendarService()

    static let monthNames = [
        "Muharram",
        "Safar",
        "Rabiul Awal",
        "Rabiul Akhir",
        "Jumadil Awal",
        "Jumadil Akhir",
        "Rajab",
        "Sya'ban",
        "Ramadhan",
        "Syawal",
        "Dzulqa'dah",
        "Dzulhijjah"
    ]

    private let islamicCalendar: Calendar

    private init() {
        var calendar = Calendar(identifier: .islamicUmmAlQura)
        calendar.locale = Locale(identifier: "id_ID")
        islamicCalendar = calendar
    }

    // MARK: - Conversion

    func toHijri(_ date: Date) -> HijriDate {
        let components = islamicCalendar.dateComponents([.day, .month, .year], from: date)
        return HijriDate(
            day: components.day ?? 1,
            month: components.month ?? 1,
            year: components.year ?? 1445
        )
    }

    func toGregorian(hijriDay: Int, hijriMonth: Int, hijriYear: Int) -> Date? {
        var components = DateComponents()
        components.day = hijriDay
        components.month = hijriMonth
        components.year = hijriYear
        return islamicCalendar.date(from: components)
    }

    // MARK: - Formatted Strings

    func formattedHijriDate(_ date: Date) -> String {
        toHijri(date).formatted
    }

    func shortHijriDate(_ date: Date) -> String {
        toHijri(date).shortFormatted
    }

    // MARK: - Special Days Detection

    func isRamadan(_ date: Date) -> Bool {
        toHijri(date).month == 9
    }

    func isDhulHijjah(_ date: Date) -> Bool {
        toHijri(date).month == 12
    }

    func specialDayName(_ date: Date) -> String? {
        let hijri = toHijri(date)

        // Check for special Islamic days
        switch (hijri.month, hijri.day) {
        case (1, 1): return "Tahun Baru Hijriyah"
        case (1, 10): return "Hari Asyura"
        case (3, 12): return "Maulid Nabi"
        case (7, 27): return "Isra Mi'raj"
        case (8, 15): return "Nisfu Sya'ban"
        case (9, 1): return "Awal Ramadhan"
        case (9, 17): return "Nuzulul Quran"
        case (10, 1): return "Idul Fitri"
        case (12, 10): return "Idul Adha"
        default: return nil
        }
    }
}
