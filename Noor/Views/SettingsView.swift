import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var viewModel: PrayerTimeViewModel
    @ObservedObject private var settings = AppSettings.shared
    @ObservedObject private var locationService = LocationService.shared

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button {
                    viewModel.showSettings = false
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

                Text("Pengaturan")
                    .font(.headline)

                Spacer()

                // Spacer for alignment
                Text("Kembali")
                    .font(.subheadline)
                    .opacity(0)
            }
            .padding()

            Divider()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {

                    // MARK: - Umum
                    SettingsSection(title: "Umum") {
                        VStack(spacing: 1) {
                            SettingsToggleRow(
                                icon: "power",
                                title: "Buka saat Login",
                                subtitle: "Jalankan otomatis saat Mac dinyalakan",
                                isOn: $settings.launchAtLogin
                            )
                        }
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
                    }

                    // MARK: - Lokasi
                    SettingsSection(title: "Lokasi") {
                        VStack(spacing: 1) {
                            // Current location display
                            HStack {
                                Image(systemName: locationService.isUsingGPS ? "location.fill" : "mappin")
                                    .font(.system(size: 14))
                                    .foregroundStyle(Color.noorTeal)
                                    .frame(width: 24)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(locationService.cityName)
                                        .font(.subheadline)
                                        .foregroundStyle(.primary)
                                    Text(locationService.isUsingGPS ? "Menggunakan GPS" : "Dipilih manual")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Button {
                                    viewModel.showSettings = false
                                    viewModel.showCityPicker = true
                                } label: {
                                    Text("Ubah")
                                        .font(.caption)
                                        .foregroundStyle(Color.noorTeal)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(10)

                            Divider().padding(.leading, 44)

                            // Use GPS button
                            Button {
                                locationService.useCurrentLocation()
                            } label: {
                                HStack {
                                    Image(systemName: "location.circle")
                                        .font(.system(size: 14))
                                        .foregroundStyle(locationService.isUsingGPS ? Color.noorTeal : .secondary)
                                        .frame(width: 24)

                                    Text("Gunakan Lokasi GPS")
                                        .font(.subheadline)
                                        .foregroundStyle(.primary)

                                    Spacer()

                                    if locationService.isUsingGPS {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundStyle(Color.noorTeal)
                                    }
                                }
                                .padding(10)
                            }
                            .buttonStyle(.plain)
                        }
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
                    }

                    // MARK: - Notifikasi
                    SettingsSection(title: "Notifikasi") {
                        VStack(spacing: 1) {
                            SettingsToggleRow(
                                icon: "bell.badge",
                                title: "Pengingat Sebelum Adzan",
                                subtitle: "\(settings.reminderMinutesBefore) menit sebelum waktu solat",
                                isOn: $settings.showNotificationBefore
                            )

                            if settings.showNotificationBefore {
                                Divider().padding(.leading, 44)

                                HStack {
                                    Image(systemName: "clock")
                                        .font(.system(size: 14))
                                        .foregroundStyle(.secondary)
                                        .frame(width: 24)

                                    Text("Waktu pengingat")
                                        .font(.subheadline)

                                    Spacer()

                                    Picker("", selection: $settings.reminderMinutesBefore) {
                                        Text("5 menit").tag(5)
                                        Text("10 menit").tag(10)
                                        Text("15 menit").tag(15)
                                        Text("30 menit").tag(30)
                                    }
                                    .pickerStyle(.menu)
                                    .frame(width: 100)
                                }
                                .padding(10)
                            }

                            Divider().padding(.leading, 44)

                            // Azan sound
                            Button {
                                viewModel.showSettings = false
                                viewModel.showAzanPicker = true
                            } label: {
                                HStack {
                                    Image(systemName: "speaker.wave.2")
                                        .font(.system(size: 14))
                                        .foregroundStyle(.secondary)
                                        .frame(width: 24)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Suara Azan")
                                            .font(.subheadline)
                                            .foregroundStyle(.primary)
                                        Text(AzanService.shared.selectedOption?.name ?? "Tanpa Suara")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 11))
                                        .foregroundStyle(.tertiary)
                                }
                                .padding(10)
                            }
                            .buttonStyle(.plain)
                        }
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
                    }

                    // MARK: - Menu Bar
                    SettingsSection(title: "Tampilan Menu Bar") {
                        VStack(spacing: 1) {
                            // Icon toggle
                            SettingsToggleRow(
                                icon: "star.square",
                                title: "Ikon",
                                subtitle: "Tampilkan ikon solat di menu bar",
                                isOn: $settings.showMenuBarIcon
                            )

                            Divider().padding(.leading, 44)

                            // Prayer name toggle
                            SettingsToggleRow(
                                icon: "textformat",
                                title: "Nama Solat",
                                subtitle: "Tampilkan nama solat berikutnya",
                                isOn: $settings.showMenuBarPrayerName
                            )

                            if settings.showMenuBarPrayerName {
                                Divider().padding(.leading, 44)

                                // Prayer name format
                                HStack {
                                    Image(systemName: "textformat.size")
                                        .font(.system(size: 14))
                                        .foregroundStyle(.secondary)
                                        .frame(width: 24)

                                    Text("Format nama")
                                        .font(.subheadline)

                                    Spacer()

                                    Picker("", selection: $settings.prayerNameFormat) {
                                        ForEach(PrayerNameFormat.allCases, id: \.self) { fmt in
                                            Text(fmt.example).tag(fmt)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    .frame(width: 100)
                                }
                                .padding(10)
                            }

                            Divider().padding(.leading, 44)

                            // Countdown toggle
                            SettingsToggleRow(
                                icon: "timer",
                                title: "Hitung Mundur",
                                subtitle: "Tampilkan waktu hitung mundur",
                                isOn: $settings.showMenuBarCountdown
                            )

                            if settings.showMenuBarCountdown {
                                Divider().padding(.leading, 44)

                                // Countdown format
                                HStack {
                                    Image(systemName: "clock.badge")
                                        .font(.system(size: 14))
                                        .foregroundStyle(.secondary)
                                        .frame(width: 24)

                                    Text("Format")
                                        .font(.subheadline)

                                    Spacer()

                                    Picker("", selection: $settings.countdownFormat) {
                                        ForEach(CountdownFormat.allCases, id: \.self) { fmt in
                                            Text(fmt.example).tag(fmt)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    .frame(width: 120)
                                }
                                .padding(10)
                            }
                        }
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))

                        // Preview
                        HStack {
                            if settings.showMenuBarIcon {
                                Image(systemName: viewModel.menuBarIcon)
                                    .font(.system(size: 12))
                            }
                            Text(viewModel.menuBarLabel.isEmpty && !settings.showMenuBarIcon ? "(ikon saja)" : viewModel.menuBarLabel.isEmpty ? "" : viewModel.menuBarLabel)
                                .font(.system(size: 12, design: .monospaced))
                        }
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 6))
                    }

                    // MARK: - Tentang
                    SettingsSection(title: "Tentang") {
                        VStack(spacing: 1) {
                            HStack {
                                Image(systemName: "info.circle")
                                    .font(.system(size: 14))
                                    .foregroundStyle(.secondary)
                                    .frame(width: 24)

                                Text("Versi")
                                    .font(.subheadline)

                                Spacer()

                                Text("1.0.0")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(10)
                        }
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
                    }
                }
                .padding()
            }
        }
        .frame(width: 320, height: 480)
        .background(.ultraThinMaterial)
    }
}

struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            content
        }
    }
}

struct SettingsRadioRow: View {
    let title: String
    let subtitle: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? Color.noorTeal : .secondary.opacity(0.3))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(isSelected ? Color.noorTeal.opacity(0.08) : Color.clear)
        }
        .buttonStyle(.plain)
    }
}

struct SettingsToggleRow: View {
    let icon: String
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .toggleStyle(.switch)
                .scaleEffect(0.8)
        }
        .padding(10)
    }
}
