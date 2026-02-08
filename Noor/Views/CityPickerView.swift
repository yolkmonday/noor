import SwiftUI

struct CityPickerView: View {
    @EnvironmentObject var viewModel: PrayerTimeViewModel
    @State private var searchText: String = ""

    private let cityData = CityData.shared

    var filteredCities: [City] {
        cityData.search(searchText)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button {
                    viewModel.showCityPicker = false
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 12, weight: .semibold))
                        Text("Kembali")
                    }
                    .font(.subheadline)
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color.noorTeal)

                Spacer()

                Text("Pilih Kota")
                    .font(.headline)

                Spacer()

                Text("Kembali")
                    .font(.subheadline)
                    .opacity(0)
            }
            .padding()

            Divider()

            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.tertiary)
                TextField("Cari kota...", text: $searchText)
                    .textFieldStyle(.plain)
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.tertiary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
            .padding(.horizontal)
            .padding(.vertical, 8)

            // City List
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 1) {
                    // GPS Option
                    GPSRowView(
                        isSelected: viewModel.locationService.isUsingGPS
                    ) {
                        viewModel.useCurrentLocation()
                    }

                    // Section header
                    HStack {
                        Text(searchText.isEmpty ? "Semua Kota" : "Hasil Pencarian")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal, 10)
                    .padding(.top, 12)
                    .padding(.bottom, 4)

                    ForEach(filteredCities) { city in
                        CityRowView(
                            city: city,
                            isSelected: !viewModel.locationService.isUsingGPS &&
                                       viewModel.locationService.selectedCity?.id == city.id
                        ) {
                            viewModel.selectCity(city)
                        }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 16)
            }
        }
        .frame(width: 320, height: 480)
        .background(.ultraThinMaterial)
    }
}

struct GPSRowView: View {
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                Image(systemName: "location.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(isSelected ? Color.noorTeal : .secondary)
                    .frame(width: 20)

                VStack(alignment: .leading, spacing: 1) {
                    Text("Gunakan GPS")
                        .font(.subheadline)
                        .fontWeight(isSelected ? .medium : .regular)
                    Text("Deteksi lokasi otomatis")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.noorTeal)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 10)
            .background(isSelected ? Color.noorTeal.opacity(0.08) : Color.clear, in: RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
    }
}

struct CityRowView: View {
    let city: City
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 1) {
                    Text(city.name)
                        .font(.subheadline)
                        .fontWeight(isSelected ? .medium : .regular)
                    Text(city.provinceName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.noorTeal)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 10)
            .background(isSelected ? Color.noorTeal.opacity(0.08) : Color.clear, in: RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
    }
}
