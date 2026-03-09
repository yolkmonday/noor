import SwiftUI
import Adhan

struct PrayerRowView: View {
    let prayer: Prayer
    let name: String
    let time: String
    let isPast: Bool
    let isNext: Bool

    @ObservedObject private var settings = AppSettings.shared

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: PrayerName(from: prayer).icon)
                .font(.system(size: 16))
                .foregroundStyle(iconColor)
                .frame(width: 24)

            Text(name)
                .font(.system(size: 16, weight: isNext ? .semibold : .regular))
                .foregroundStyle(textColor)

            Spacer()

            Text(time)
                .font(.system(size: 16, weight: .medium, design: .monospaced))
                .foregroundStyle(timeColor)

            // Notification toggle button (skip for sunrise)
            if prayer != .sunrise {
                Button {
                    settings.toggleNotificationMode(for: prayer)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: notificationIcon)
                            .font(.system(size: 12))
                        Text(notificationLabel)
                            .font(.system(size: 10))
                    }
                    .foregroundStyle(notificationColor)
                    .frame(width: 60)
                }
                .buttonStyle(.plain)
            } else {
                Color.clear.frame(width: 60)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(isNext ? Color.noorTeal.opacity(0.08) : Color.clear, in: RoundedRectangle(cornerRadius: 8))
    }

    private var iconColor: Color {
        if isNext { return .noorTeal }
        if isPast { return .secondary.opacity(0.35) }
        return .primary
    }

    private var timeColor: Color {
        if isNext { return .noorTeal }
        if isPast { return .secondary.opacity(0.35) }
        return .primary
    }

    private var textColor: Color {
        if isPast { return .secondary.opacity(0.35) }
        return .primary
    }

    private var notificationIcon: String {
        settings.notificationMode(for: prayer).icon
    }

    private var notificationLabel: String {
        settings.notificationMode(for: prayer).label
    }

    private var notificationColor: Color {
        switch settings.notificationMode(for: prayer) {
        case .off: return .secondary.opacity(0.3)
        case .silent: return .secondary
        case .azan: return Color.noorTeal
        }
    }
}
