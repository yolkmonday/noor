import SwiftUI

/// Scale-on-press feedback, matching noor-expo's PressableScale.
private struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

/// Full-screen dimmed backdrop with the azan card centered on top.
/// Hosted in a borderless, transparent, screen-sized window so the card
/// always lands dead center regardless of monitor layout.
struct AzanAlertOverlayView: View {
    let prayerName: String
    let onStop: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .contentShape(Rectangle())

            AzanAlertCard(prayerName: prayerName, onStop: onStop)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Mirrors noor-expo's onboarding AzanStep: soft green gradient, round
/// translucent icon badge, Outfit type, solid-primary pill button.
private struct AzanAlertCard: View {
    let prayerName: String
    let onStop: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            iconBadge

            VStack(spacing: 14) {
                Text("Waktu \(prayerName) Telah Tiba")
                    .font(.outfit(26, weight: .semibold))
                    .foregroundStyle(Color.noorTextStrong)
                    .multilineTextAlignment(.center)

                Text("Saatnya menunaikan solat \(prayerName)")
                    .font(.outfit(16))
                    .foregroundStyle(Color.noorTextBody)
                    .multilineTextAlignment(.center)
            }

            Button(action: onStop) {
                Text("Hentikan Azan")
                    .font(.outfit(16, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .foregroundStyle(.white)
                    .background(Color.noorTeal, in: RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(PressableButtonStyle())
        }
        .padding(40)
        .frame(width: 440, height: 420)
        .background(
            LinearGradient(colors: Color.noorGradient, startPoint: .top, endPoint: .bottom),
            in: RoundedRectangle(cornerRadius: 28)
        )
        .shadow(color: Color.noorTeal.opacity(0.35), radius: 40, y: 16)
    }

    private var iconBadge: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.55))
                .frame(width: 112, height: 112)

            Image(systemName: "bell.and.waves.left.and.right")
                .font(.system(size: 46, weight: .medium))
                .foregroundStyle(Color.noorTeal)
                .symbolEffect(.pulse, options: .repeating)
        }
    }
}
