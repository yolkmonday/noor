import Foundation

struct PrayerStats {
    let totalDays: Int
    let completedDays: Int          // Days with all 5 prayers
    let totalPrayers: Int
    let completedPrayers: Int
    let currentStreak: Int
    let bestStreak: Int
    let weeklyPercentage: Double
    let monthlyPercentage: Double
    let perPrayerStats: [PrayerType: (completed: Int, total: Int)]
}

final class StatsService {
    static let shared = StatsService()

    private let logService = PrayerLogService.shared

    private init() {}

    // MARK: - Main Stats Calculation

    func calculateStats(from startDate: Date, to endDate: Date) -> PrayerStats {
        let calendar = Calendar.current
        let logs = logService.fetchLogs(from: startDate, to: endDate)

        // Group logs by date
        var logsByDate: [Date: [PrayerLog]] = [:]
        for log in logs {
            let dayStart = calendar.startOfDay(for: log.date)
            if logsByDate[dayStart] == nil {
                logsByDate[dayStart] = []
            }
            logsByDate[dayStart]?.append(log)
        }

        // Calculate days in range
        let dayCount = calendar.dateComponents([.day], from: startDate, to: endDate).day! + 1

        // Count completed days (all 5 wajib prayers)
        var completedDays = 0
        var completedPrayers = 0
        var perPrayer: [PrayerType: (completed: Int, total: Int)] = [:]

        // Initialize per-prayer stats
        for prayer in PrayerType.wajibPrayers {
            perPrayer[prayer] = (0, dayCount)
        }

        // Process each day
        var currentDate = startDate
        while currentDate <= endDate {
            let dayStart = calendar.startOfDay(for: currentDate)
            let dayLogs = logsByDate[dayStart] ?? []

            var dayCompleted = 0
            for prayer in PrayerType.wajibPrayers {
                let isCompleted = dayLogs.first { $0.prayerType == prayer.rawValue && $0.completed } != nil
                if isCompleted {
                    dayCompleted += 1
                    completedPrayers += 1
                    perPrayer[prayer]?.completed += 1
                }
            }

            if dayCompleted == 5 {
                completedDays += 1
            }

            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }

        // Calculate streaks
        let (currentStreak, bestStreak) = calculateStreaks(upTo: endDate)

        // Weekly percentage (last 7 days)
        let weekAgo = calendar.date(byAdding: .day, value: -6, to: endDate)!
        let weeklyStats = calculatePercentage(from: weekAgo, to: endDate)

        // Monthly percentage (last 30 days)
        let monthAgo = calendar.date(byAdding: .day, value: -29, to: endDate)!
        let monthlyStats = calculatePercentage(from: monthAgo, to: endDate)

        return PrayerStats(
            totalDays: dayCount,
            completedDays: completedDays,
            totalPrayers: dayCount * 5,
            completedPrayers: completedPrayers,
            currentStreak: currentStreak,
            bestStreak: bestStreak,
            weeklyPercentage: weeklyStats,
            monthlyPercentage: monthlyStats,
            perPrayerStats: perPrayer
        )
    }

    // MARK: - Streak Calculation

    func calculateStreaks(upTo endDate: Date) -> (current: Int, best: Int) {
        let calendar = Calendar.current

        // Go back up to 365 days to find streaks
        let startDate = calendar.date(byAdding: .day, value: -365, to: endDate)!
        let logs = logService.fetchLogs(from: startDate, to: endDate)

        // Group completed wajib prayers by date
        var completedByDate: [Date: Set<String>] = [:]
        for log in logs where log.completed {
            let dayStart = calendar.startOfDay(for: log.date)
            if completedByDate[dayStart] == nil {
                completedByDate[dayStart] = []
            }
            if PrayerType.wajibPrayers.contains(where: { $0.rawValue == log.prayerType }) {
                completedByDate[dayStart]?.insert(log.prayerType)
            }
        }

        // Find days with all 5 completed
        var fullyCompletedDays = Set<Date>()
        for (date, prayers) in completedByDate {
            if prayers.count == 5 {
                fullyCompletedDays.insert(date)
            }
        }

        // Calculate current streak (consecutive days ending today/yesterday)
        var currentStreak = 0
        var checkDate = calendar.startOfDay(for: endDate)

        // Check if today is completed, if not start from yesterday
        if !fullyCompletedDays.contains(checkDate) {
            checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
        }

        while fullyCompletedDays.contains(checkDate) {
            currentStreak += 1
            checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
        }

        // Calculate best streak
        var bestStreak = 0
        var tempStreak = 0
        var sortedDates = fullyCompletedDays.sorted()

        for (index, date) in sortedDates.enumerated() {
            if index == 0 {
                tempStreak = 1
            } else {
                let prevDate = sortedDates[index - 1]
                let dayDiff = calendar.dateComponents([.day], from: prevDate, to: date).day!

                if dayDiff == 1 {
                    tempStreak += 1
                } else {
                    bestStreak = max(bestStreak, tempStreak)
                    tempStreak = 1
                }
            }
        }
        bestStreak = max(bestStreak, tempStreak)

        return (currentStreak, bestStreak)
    }

    // MARK: - Percentage Calculation

    func calculatePercentage(from startDate: Date, to endDate: Date) -> Double {
        let calendar = Calendar.current
        let dayCount = calendar.dateComponents([.day], from: startDate, to: endDate).day! + 1
        let totalPossible = dayCount * 5

        if totalPossible == 0 { return 0 }

        let logs = logService.fetchLogs(from: startDate, to: endDate)
        let completed = logs.filter { log in
            log.completed && PrayerType.wajibPrayers.contains { $0.rawValue == log.prayerType }
        }.count

        return Double(completed) / Double(totalPossible) * 100
    }

    // MARK: - Quick Stats for Today

    func todayStats() -> (completed: Int, total: Int) {
        let completed = logService.completedCount(for: Date())
        return (completed, 5)
    }

    func thisWeekStats() -> (completed: Int, total: Int) {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())
        components.weekday = 2 // Monday
        let weekStart = calendar.date(from: components) ?? Date()
        let today = Date()

        let daysPassed = calendar.dateComponents([.day], from: weekStart, to: today).day! + 1
        let totalPossible = daysPassed * 5

        let logs = logService.fetchLogs(from: weekStart, to: today)
        let completed = logs.filter { log in
            log.completed && PrayerType.wajibPrayers.contains { $0.rawValue == log.prayerType }
        }.count

        return (completed, totalPossible)
    }
}
