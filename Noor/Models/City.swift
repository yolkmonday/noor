import Foundation

struct City: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let latitude: Double
    let longitude: Double
    let provinceName: String

    var displayName: String {
        "\(name), \(provinceName)"
    }
}

// MARK: - City Data Manager
final class CityData {
    static let shared = CityData()

    private let popularCityIds = [
        "jakarta-pusat", "surabaya", "bandung", "medan", "semarang",
        "makassar", "palembang", "tangerang", "depok", "bekasi",
        "yogyakarta", "denpasar", "batam", "pekanbaru", "malang",
        "balikpapan", "pontianak", "banjarmasin", "manado", "padang"
    ]

    /// Full city list - loaded lazily on first access (search)
    lazy var allCities: [City] = {
        if let url = Bundle.main.url(forResource: "cities", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let cities = try? JSONDecoder().decode([City].self, from: data) {
            return cities
        }
        return fallbackCities
    }()

    /// Cached at init - only the 20 popular cities
    let popularCities: [City]

    /// Cached at init
    let defaultCity: City

    private let fallbackCities = [
        City(id: "jakarta-pusat", name: "Jakarta Pusat", latitude: -6.1862, longitude: 106.8341, provinceName: "DKI Jakarta"),
        City(id: "surabaya", name: "Surabaya", latitude: -7.2504, longitude: 112.7688, provinceName: "Jawa Timur"),
        City(id: "bandung", name: "Bandung", latitude: -6.9175, longitude: 107.6191, provinceName: "Jawa Barat"),
        City(id: "medan", name: "Medan", latitude: 3.5952, longitude: 98.6722, provinceName: "Sumatera Utara"),
        City(id: "semarang", name: "Semarang", latitude: -6.9666, longitude: 110.4196, provinceName: "Jawa Tengah"),
        City(id: "makassar", name: "Makassar", latitude: -5.1477, longitude: 119.4327, provinceName: "Sulawesi Selatan"),
        City(id: "palembang", name: "Palembang", latitude: -2.9761, longitude: 104.7754, provinceName: "Sumatera Selatan"),
        City(id: "tangerang", name: "Tangerang", latitude: -6.1783, longitude: 106.63, provinceName: "Banten"),
        City(id: "depok", name: "Depok", latitude: -6.4025, longitude: 106.7942, provinceName: "Jawa Barat"),
        City(id: "bekasi", name: "Bekasi", latitude: -6.2349, longitude: 106.9896, provinceName: "Jawa Barat"),
        City(id: "yogyakarta", name: "Yogyakarta", latitude: -7.7956, longitude: 110.3695, provinceName: "DI Yogyakarta"),
        City(id: "denpasar", name: "Denpasar", latitude: -8.6705, longitude: 115.2126, provinceName: "Bali"),
        City(id: "batam", name: "Batam", latitude: 1.0456, longitude: 104.0305, provinceName: "Kepulauan Riau"),
        City(id: "pekanbaru", name: "Pekanbaru", latitude: 0.5071, longitude: 101.4478, provinceName: "Riau"),
        City(id: "malang", name: "Malang", latitude: -7.9666, longitude: 112.6326, provinceName: "Jawa Timur"),
    ]

    private init() {
        // Build popular cities from fallback (no need to load full JSON yet)
        var popular: [City] = []
        for id in popularCityIds {
            if let city = fallbackCities.first(where: { $0.id == id }) {
                popular.append(city)
            }
        }
        // For IDs not in fallback, we skip - they'll be available via search
        self.popularCities = popular
        self.defaultCity = fallbackCities.first { $0.id == "batam" } ?? fallbackCities[0]
    }

    func search(_ query: String) -> [City] {
        guard !query.isEmpty else { return popularCities }

        let lowercased = query.lowercased()
        return allCities.filter { city in
            city.name.lowercased().contains(lowercased) ||
            city.provinceName.lowercased().contains(lowercased)
        }
    }

    func findById(_ id: String) -> City? {
        allCities.first { $0.id == id }
    }
}
