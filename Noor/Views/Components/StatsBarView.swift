import SwiftUI

struct StatsBarView: View {
    let todayCompleted: Int
    let todayTotal: Int
    let streak: Int
    let weeklyPercentage: Int

    var body: some View {
        HStack(spacing: 0) {
            statsItem(
                icon: "checkmark.circle",
                value: "\(todayCompleted)/\(todayTotal)",
                label: "Hari Ini",
                color: Color.noorTeal
            )

            Divider()
                .frame(height: 24)

            statsItem(
                icon: "flame.fill",
                value: "\(streak)",
                label: "Streak",
                color: .orange
            )

            Divider()
                .frame(height: 24)

            statsItem(
                icon: "chart.bar.fill",
                value: "\(weeklyPercentage)%",
                label: "Minggu",
                color: Color.noorTeal
            )
        }
        .padding(.vertical, 8)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
    }

    private func statsItem(icon: String, value: String, label: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundStyle(color)
            Text(value)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
    }
}
