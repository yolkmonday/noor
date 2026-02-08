import SwiftUI

struct PrayerHeroCard: View {
    let prayerName: String
    let prayerTime: String
    let countdown: String
    let icon: String
    let isApproaching: Bool
    let currentPrayerName: String?
    let remainingInCurrent: String

    var body: some View {
        if isApproaching {
            approachingView
        } else {
            normalView
        }
    }

    // Tampilan besar saat 15 menit sebelum waktu solat
    private var approachingView: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(Color.noorTeal)

            VStack(spacing: 4) {
                Text(prayerName)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)

                Text(prayerTime)
                    .font(.system(size: 20, weight: .medium, design: .monospaced))
                    .foregroundStyle(.secondary)
            }

            Text(countdown)
                .font(.system(size: 28, weight: .semibold, design: .monospaced))
                .foregroundStyle(Color.noorTeal)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .padding(.horizontal, 14)
        .background(Color.noorTeal.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.noorTeal.opacity(0.3), lineWidth: 1)
        )
    }

    // Tampilan normal - sisa waktu dalam solat saat ini
    private var normalView: some View {
        VStack(spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    if let current = currentPrayerName, !remainingInCurrent.isEmpty {
                        Text("Waktu \(current)")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text(remainingInCurrent)
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundStyle(.primary)
                    } else {
                        Text("Berikutnya")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text(prayerName)
                            .font(.system(size: 24, weight: .semibold, design: .rounded))
                            .foregroundStyle(.primary)
                    }
                }

                Spacer()

                Image(systemName: icon)
                    .font(.system(size: 32, weight: .light))
                    .foregroundStyle(Color.noorTeal)
            }

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(prayerName)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    Text(prayerTime)
                        .font(.system(size: 18, weight: .medium, design: .monospaced))
                        .foregroundStyle(.primary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("Dalam")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    Text(countdown)
                        .font(.system(size: 18, weight: .medium, design: .monospaced))
                        .foregroundStyle(Color.noorTeal)
                }
            }
        }
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(.quaternary, lineWidth: 0.5)
        )
    }
}
