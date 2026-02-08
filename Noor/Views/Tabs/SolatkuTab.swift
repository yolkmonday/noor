import SwiftUI

struct SolatkuTab: View {
    @EnvironmentObject var viewModel: PrayerTimeViewModel
    @StateObject private var solatkuVM = SolatkuViewModel()

    private let accentGold = Color(red: 0.78, green: 0.59, blue: 0.24)

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                // Stats Bar
                StatsBarView(
                    todayCompleted: solatkuVM.todayCompleted,
                    todayTotal: 5,
                    streak: solatkuVM.currentStreak,
                    weeklyPercentage: Int(solatkuVM.weeklyPercentage)
                )
                .padding(.horizontal)
                .padding(.top, 12)

                // Weekly Calendar
                WeeklyCalendarView(
                    selectedDate: $solatkuVM.selectedDate,
                    weeklyData: solatkuVM.weeklyData
                )
                .padding(.horizontal)

                // Today's Prayers Checklist
                PrayerChecklistView(
                    date: solatkuVM.selectedDate,
                    completionStatus: solatkuVM.todayStatus,
                    onToggle: { prayerType in
                        solatkuVM.togglePrayer(prayerType)
                    }
                )
                .padding(.horizontal, 8)
            }
            .padding(.bottom, 16)
        }
        .onAppear {
            solatkuVM.refresh()
        }
    }
}
