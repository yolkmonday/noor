import SwiftUI
import Combine

@MainActor
final class SolatkuViewModel: ObservableObject {
    @Published var selectedDate: Date = Date()
    @Published var weeklyData: [Date: [PrayerType: Bool]] = [:]
    @Published var todayStatus: [PrayerType: Bool] = [:]
    @Published var todayCompleted: Int = 0
    @Published var currentStreak: Int = 0
    @Published var weeklyPercentage: Double = 0

    private let logService = PrayerLogService.shared
    private let statsService = StatsService.shared

    init() {
        refresh()
    }

    func refresh() {
        loadWeeklyData()
        loadTodayStatus()
        loadStats()
    }

    private func loadWeeklyData() {
        weeklyData = logService.weeklyData(for: selectedDate)
    }

    private func loadTodayStatus() {
        var status: [PrayerType: Bool] = [:]
        for prayer in PrayerType.wajibPrayers {
            status[prayer] = logService.isCompleted(for: selectedDate, prayerType: prayer)
        }
        todayStatus = status
        todayCompleted = status.values.filter { $0 }.count
    }

    private func loadStats() {
        let (current, _) = statsService.calculateStreaks(upTo: Date())
        currentStreak = current

        let calendar = Calendar.current
        var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())
        components.weekday = 2
        let weekStart = calendar.date(from: components) ?? Date()
        weeklyPercentage = statsService.calculatePercentage(from: weekStart, to: Date())
    }

    func togglePrayer(_ prayerType: PrayerType) {
        let newStatus = logService.toggleCompletion(for: selectedDate, prayerType: prayerType)
        todayStatus[prayerType] = newStatus
        todayCompleted = todayStatus.values.filter { $0 }.count

        // Refresh weekly data and stats
        loadWeeklyData()
        loadStats()
    }

    func selectDate(_ date: Date) {
        selectedDate = date
        loadTodayStatus()
    }
}
