import SwiftUI

struct StatsCardView: View {
    let todayCompleted: Int
    let currentStreak: Int
    let weeklyPercentage: Double

    var body: some View {
        HStack(spacing: 0) {
            StatItem(
                value: "\(todayCompleted)/5",
                label: "Hari Ini",
                icon: "checkmark.circle",
                color: todayCompleted == 5 ? .green : Color.noorTeal
            )

            Divider()
                .frame(height: 36)

            StatItem(
                value: "\(currentStreak)",
                label: "Streak",
                icon: "flame",
                color: currentStreak > 0 ? .orange : .secondary
            )

            Divider()
                .frame(height: 36)

            StatItem(
                value: String(format: "%.0f%%", weeklyPercentage),
                label: "Minggu",
                icon: "chart.bar",
                color: weeklyPercentage >= 80 ? .green : (weeklyPercentage >= 50 ? Color.noorTeal : .secondary)
            )
        }
        .padding(.vertical, 10)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
    }
}

struct StatItem: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 3) {
            HStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                Text(value)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(color)

            Text(label)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
    }
}
