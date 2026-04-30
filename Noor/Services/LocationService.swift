import Foundation
import CoreLocation
import os.log

final class LocationService: NSObject, ObservableObject {

    static let shared = LocationService()
    private static let logger = Logger(subsystem: "com.noor.app", category: "LocationService")

    @Published var selectedCity: City?
    @Published var latitude: Double
    @Published var longitude: Double
    @Published var cityName: String
    @Published var isUsingGPS: Bool = true

    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private let userDefaultsKey = "selectedCityId"
    private let useGPSKey = "useGPS"

    override init() {
        // Check if user has selected a city manually before
        let savedCityId = UserDefaults.standard.string(forKey: userDefaultsKey)
        let useGPS = UserDefaults.standard.object(forKey: useGPSKey) as? Bool ?? true

        if let cityId = savedCityId, !useGPS, let city = CityData.shared.popularCities.first(where: { $0.id == cityId }) {
            self.selectedCity = city
            self.latitude = city.latitude
            self.longitude = city.longitude
            self.cityName = city.name
            self.isUsingGPS = false
        } else {
            // Default to Batam until GPS updates
            self.selectedCity = nil
            self.latitude = CityData.shared.defaultCity.latitude
            self.longitude = CityData.shared.defaultCity.longitude
            self.cityName = "Mencari lokasi..."
            self.isUsingGPS = true
        }

        super.init()

        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer

        Self.logger.info("LocationService init - isUsingGPS: \(self.isUsingGPS)")
        Self.logger.info("Current auth status: \(CLLocationManager.authorizationStatus().rawValue)")

        if isUsingGPS {
            requestLocation()
        }
    }

    func requestLocation() {
        locationManager.requestWhenInUseAuthorization()
    }

    func selectCity(_ city: City) {
        selectedCity = city
        latitude = city.latitude
        longitude = city.longitude
        cityName = city.name
        isUsingGPS = false

        // Save to UserDefaults
        UserDefaults.standard.set(city.id, forKey: userDefaultsKey)
        UserDefaults.standard.set(false, forKey: useGPSKey)
    }

    func useCurrentLocation() {
        isUsingGPS = true
        selectedCity = nil
        UserDefaults.standard.set(true, forKey: useGPSKey)
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
        requestLocation()
    }

    private func updateFromGPS(_ location: CLLocation) {
        latitude = location.coordinate.latitude
        longitude = location.coordinate.longitude

        // Cancel any in-flight geocoding before starting new one
        geocoder.cancelGeocode()
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, _ in
            DispatchQueue.main.async {
                if let city = placemarks?.first?.locality {
                    self?.cityName = city
                } else if let area = placemarks?.first?.administrativeArea {
                    self?.cityName = area
                } else {
                    self?.cityName = "Lokasi Saat Ini"
                }
            }
        }
    }
}

extension LocationService: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Self.logger.info("Authorization status: \(manager.authorizationStatus.rawValue)")
        guard isUsingGPS else { return }

        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            Self.logger.info("Location authorized, requesting location")
            manager.requestLocation()
        case .denied, .restricted:
            Self.logger.warning("Location denied/restricted")
            cityName = CityData.shared.defaultCity.name
            latitude = CityData.shared.defaultCity.latitude
            longitude = CityData.shared.defaultCity.longitude
        case .notDetermined:
            Self.logger.info("Location not determined, requesting authorization")
            manager.requestWhenInUseAuthorization()
        @unknown default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard isUsingGPS, let location = locations.last else { return }
        updateFromGPS(location)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Self.logger.error("Location error: \(error.localizedDescription) (code: \((error as NSError).code))")
        if isUsingGPS {
            cityName = CityData.shared.defaultCity.name
            latitude = CityData.shared.defaultCity.latitude
            longitude = CityData.shared.defaultCity.longitude
        }
    }
}
