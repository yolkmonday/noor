import Foundation
import Adhan

final class AdhanService {

    static let shared = AdhanService()

    private init() {}

    /// Kemenag Indonesia ihtiyath adjustments (in minutes)
    private let kemenagAdjustments = PrayerAdjustments(
        fajr: 2,
        sunrise: -3,
        dhuhr: 2,
        asr: 2,
        maghrib: 3,
        isha: 2
    )

    /// Calculate prayer times for given coordinates and date
    func getPrayerTimes(
        latitude: Double,
        longitude: Double,
        date: Date = Date()
    ) -> PrayerTimes? {
        let coordinates = Coordinates(
            latitude: latitude,
            longitude: longitude
        )

        let cal = Calendar(identifier: .gregorian)
        let dateComponents = cal.dateComponents(
            [.year, .month, .day],
            from: date
        )

        // Use Singapore method as base (Fajr 20°, Isha 18°)
        // Same as Kemenag Indonesia
        var params = CalculationMethod.singapore.params
        params.madhab = .shafi

        // Apply Kemenag ihtiyath adjustments
        params.adjustments = kemenagAdjustments

        return PrayerTimes(
            coordinates: coordinates,
            date: dateComponents,
            calculationParameters: params
        )
    }
}
