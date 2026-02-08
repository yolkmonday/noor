import SwiftUI
import Adhan

enum PanelTab: String, CaseIterable {
    case jadwal = "Jadwal"
    case solatku = "Solatku"
}

// Native macOS style segmented control
private struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: isSelected ? .medium : .regular))
                .foregroundStyle(isSelected ? .primary : .secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(tabBackground)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var tabBackground: some View {
        if isSelected {
            RoundedRectangle(cornerRadius: 5)
                .fill(.background)
                .shadow(color: .black.opacity(0.08), radius: 1, y: 1)
        }
    }
}

struct NoorPanelView: View {
    @EnvironmentObject var viewModel: PrayerTimeViewModel
    @State private var selectedTab: PanelTab = .jadwal

    private let hijriService = HijriCalendarService.shared

    var body: some View {
        Group {
            if viewModel.showCityPicker {
                CityPickerView()
                    .environmentObject(viewModel)
            } else if viewModel.showSettings {
                SettingsView()
                    .environmentObject(viewModel)
            } else if viewModel.showAzanPicker {
                AzanPickerView()
                    .environmentObject(viewModel)
            } else {
                mainView
            }
        }
    }

    private var mainView: some View {
        VStack(spacing: 0) {
            // Header
            headerView

            Divider()

            // Tab Selector - Apple style segmented control
            HStack(spacing: 2) {
                ForEach(PanelTab.allCases, id: \.self) { tab in
                    TabButton(
                        title: tab.rawValue,
                        isSelected: selectedTab == tab
                    ) {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            selectedTab = tab
                        }
                    }
                }
            }
            .padding(2)
            .background(Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 7))
            .padding(.horizontal)
            .padding(.vertical, 8)

            // Tab Content
            Group {
                switch selectedTab {
                case .jadwal:
                    JadwalTab()
                        .environmentObject(viewModel)
                case .solatku:
                    SolatkuTab()
                        .environmentObject(viewModel)
                }
            }

            Divider()

            // Footer
            footerView
        }
        .frame(width: 320, height: 480)
        .background(.ultraThinMaterial)
    }

    private var headerView: some View {
        HStack(alignment: .top) {
            // Left: Prayer name + countdown
            VStack(alignment: .leading, spacing: 2) {
                if let next = viewModel.nextPrayer {
                    Text(PrayerName(from: next).rawValue)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.primary)
                }

                if viewModel.nextPrayer != nil {
                    Text(humanisCountdown)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Right: Location + Date
            VStack(alignment: .trailing, spacing: 2) {
                Button {
                    viewModel.showCityPicker = true
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 8))
                        Text(viewModel.cityName)
                            .font(.system(size: 12))
                    }
                    .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)

                Text("\(shortDate) · \(hijriService.shortHijriDate(viewModel.currentDate))")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }

    private var humanisCountdown: String {
        guard let time = viewModel.nextPrayerTime else { return "" }
        let diff = time.timeIntervalSince(Date())
        let h = Int(diff) / 3600
        let m = (Int(diff) % 3600) / 60

        if h > 0 {
            return "\(h) jam \(m) menit lagi"
        } else if m > 1 {
            return "\(m) menit lagi"
        } else {
            return "Sebentar lagi"
        }
    }

    private static let shortDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "d MMM"
        f.locale = Locale(identifier: "id_ID")
        return f
    }()

    private var shortDate: String {
        Self.shortDateFormatter.string(from: viewModel.currentDate)
    }

    private var footerView: some View {
        HStack {
            Button {
                viewModel.showSettings = true
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)

            Spacer()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.plain)
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }

    private static let fullDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEEE, d MMMM yyyy"
        f.locale = Locale(identifier: "id_ID")
        return f
    }()

    private var formattedDate: String {
        Self.fullDateFormatter.string(from: viewModel.currentDate)
    }
}
