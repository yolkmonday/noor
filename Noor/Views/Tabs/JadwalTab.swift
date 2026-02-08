import SwiftUI
import Adhan

struct JadwalTab: View {
    @EnvironmentObject var viewModel: PrayerTimeViewModel

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 4) {
                // Prayer Times List
                ForEach(prayerList, id: \.1) { prayer, name in
                    PrayerRowView(
                        prayer: prayer,
                        name: name,
                        time: viewModel.timeString(for: prayer),
                        isPast: viewModel.isPast(prayer),
                        isNext: viewModel.isNext(prayer)
                    )
                }
            }
            .padding(.horizontal, 8)
            .padding(.top, 8)
            .padding(.bottom, 16)
        }
    }

    private var prayerList: [(Prayer, String)] {
        [
            (.fajr, "Subuh"),
            (.sunrise, "Syuruq"),
            (.dhuhr, "Dzuhur"),
            (.asr, "Ashar"),
            (.maghrib, "Maghrib"),
            (.isha, "Isya")
        ]
    }
}
