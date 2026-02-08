import SwiftUI
import Adhan

struct PrayerChecklistView: View {
    let date: Date
    let completionStatus: [PrayerType: Bool]
    let onToggle: (PrayerType) -> Void

    private let adhanService = AdhanService.shared
    @EnvironmentObject var viewModel: PrayerTimeViewModel

    var body: some View {
        VStack(spacing: 2) {
            // Header
            HStack {
                Text(headerText)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(completedCount)/5")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(completedCount == 5 ? .green : Color.noorTeal)
            }
            .padding(.horizontal, 6)
            .padding(.bottom, 6)

            // Prayer rows
            ForEach(PrayerType.wajibPrayers, id: \.rawValue) { prayer in
                PrayerCheckRow(
                    prayerType: prayer,
                    isCompleted: completionStatus[prayer] ?? false,
                    isEnabled: isPrayerTimeReached(prayer),
                    onToggle: { onToggle(prayer) }
                )
            }
        }
    }

    private func isPrayerTimeReached(_ prayerType: PrayerType) -> Bool {
        let calendar = Calendar.current

        // Jika bukan hari ini, semua enabled
        if !calendar.isDateInToday(date) {
            return true
        }

        // Cek waktu solat hari ini
        guard let prayerTimes = viewModel.prayerTimes else { return true }

        let adhanPrayer: Prayer
        switch prayerType {
        case .fajr: adhanPrayer = .fajr
        case .dhuhr: adhanPrayer = .dhuhr
        case .asr: adhanPrayer = .asr
        case .maghrib: adhanPrayer = .maghrib
        case .isha: adhanPrayer = .isha
        default: return true
        }

        let prayerTime = prayerTimes.time(for: adhanPrayer)
        return Date() >= prayerTime
    }

    private static let headerDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEEE, d MMM"
        f.locale = Locale(identifier: "id_ID")
        return f
    }()

    private var headerText: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Hari Ini"
        } else if calendar.isDateInYesterday(date) {
            return "Kemarin"
        } else {
            return Self.headerDateFormatter.string(from: date)
        }
    }

    private var completedCount: Int {
        completionStatus.values.filter { $0 }.count
    }
}

struct PrayerCheckRow: View {
    let prayerType: PrayerType
    let isCompleted: Bool
    let isEnabled: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 10) {
                Image(systemName: prayerIcon)
                    .font(.system(size: 12))
                    .foregroundStyle(iconColor)
                    .frame(width: 18)

                Text(prayerType.displayName)
                    .font(.subheadline)
                    .foregroundStyle(textColor)

                Spacer()

                Image(systemName: checkmarkIcon)
                    .font(.system(size: 18))
                    .foregroundStyle(checkmarkColor)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 10)
            .background(backgroundColor, in: RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }

    private var iconColor: Color {
        if !isEnabled {
            return .secondary.opacity(0.3)
        }
        return isCompleted ? Color.noorTeal : .secondary
    }

    private var textColor: Color {
        if !isEnabled {
            return .secondary.opacity(0.4)
        }
        return isCompleted ? .primary : .secondary
    }

    private var checkmarkIcon: String {
        if !isEnabled {
            return "clock"
        }
        return isCompleted ? "checkmark.circle.fill" : "circle"
    }

    private var checkmarkColor: Color {
        if !isEnabled {
            return .secondary.opacity(0.3)
        }
        return isCompleted ? .green : .secondary.opacity(0.3)
    }

    private var backgroundColor: Color {
        if !isEnabled {
            return Color.clear
        }
        return isCompleted ? Color.green.opacity(0.08) : Color.clear
    }

    private var prayerIcon: String {
        switch prayerType {
        case .fajr: return "sunrise"
        case .dhuhr: return "sun.max"
        case .asr: return "sun.min"
        case .maghrib: return "sunset"
        case .isha: return "moon.stars"
        default: return "circle"
        }
    }
}
