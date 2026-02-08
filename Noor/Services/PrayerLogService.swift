import Foundation
import CoreData

final class PrayerLogService {
    static let shared = PrayerLogService()

    private let persistence = PersistenceController.shared
    private var context: NSManagedObjectContext { persistence.viewContext }

    private init() {}

    // MARK: - Date Helpers

    private func startOfDay(_ date: Date) -> Date {
        Calendar.current.startOfDay(for: date)
    }

    private func dateRange(for date: Date) -> (start: Date, end: Date) {
        let start = startOfDay(date)
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start)!
        return (start, end)
    }

    // MARK: - Fetch

    func fetchLogs(for date: Date) -> [PrayerLog] {
        let range = dateRange(for: date)
        let request = NSFetchRequest<PrayerLog>(entityName: "PrayerLog")
        request.predicate = NSPredicate(format: "date >= %@ AND date < %@", range.start as NSDate, range.end as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \PrayerLog.prayerType, ascending: true)]

        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch prayer logs: \(error)")
            return []
        }
    }

    func fetchLogs(from startDate: Date, to endDate: Date) -> [PrayerLog] {
        let start = startOfDay(startDate)
        let end = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay(endDate))!

        let request = NSFetchRequest<PrayerLog>(entityName: "PrayerLog")
        request.predicate = NSPredicate(format: "date >= %@ AND date < %@", start as NSDate, end as NSDate)
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \PrayerLog.date, ascending: true),
            NSSortDescriptor(keyPath: \PrayerLog.prayerType, ascending: true)
        ]

        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch prayer logs: \(error)")
            return []
        }
    }

    func getLog(for date: Date, prayerType: PrayerType) -> PrayerLog? {
        let range = dateRange(for: date)
        let request = NSFetchRequest<PrayerLog>(entityName: "PrayerLog")
        request.predicate = NSPredicate(
            format: "date >= %@ AND date < %@ AND prayerType == %@",
            range.start as NSDate, range.end as NSDate, prayerType.rawValue
        )
        request.fetchLimit = 1

        do {
            return try context.fetch(request).first
        } catch {
            print("Failed to fetch prayer log: \(error)")
            return nil
        }
    }

    // MARK: - Toggle Completion

    @discardableResult
    func toggleCompletion(for date: Date, prayerType: PrayerType) -> Bool {
        if let existing = getLog(for: date, prayerType: prayerType) {
            // Toggle existing
            existing.completed.toggle()
            existing.completedAt = existing.completed ? Date() : nil
            persistence.save()
            return existing.completed
        } else {
            // Create new as completed
            let log = PrayerLog(context: context)
            log.id = UUID()
            log.date = startOfDay(date)
            log.prayerType = prayerType.rawValue
            log.completed = true
            log.completedAt = Date()
            persistence.save()
            return true
        }
    }

    func setCompletion(for date: Date, prayerType: PrayerType, completed: Bool) {
        if let existing = getLog(for: date, prayerType: prayerType) {
            existing.completed = completed
            existing.completedAt = completed ? Date() : nil
        } else if completed {
            let log = PrayerLog(context: context)
            log.id = UUID()
            log.date = startOfDay(date)
            log.prayerType = prayerType.rawValue
            log.completed = true
            log.completedAt = Date()
        }
        persistence.save()
    }

    // MARK: - Completion Status

    func isCompleted(for date: Date, prayerType: PrayerType) -> Bool {
        getLog(for: date, prayerType: prayerType)?.completed ?? false
    }

    func completedCount(for date: Date, prayerTypes: [PrayerType] = PrayerType.wajibPrayers) -> Int {
        let logs = fetchLogs(for: date)
        return logs.filter { log in
            log.completed && prayerTypes.contains { $0.rawValue == log.prayerType }
        }.count
    }

    func isFullyCompleted(for date: Date) -> Bool {
        completedCount(for: date) == PrayerType.wajibPrayers.count
    }

    // MARK: - Weekly Data

    func weeklyData(for date: Date) -> [Date: [PrayerType: Bool]] {
        let calendar = Calendar.current

        // Get start of week (Monday)
        var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        components.weekday = 2 // Monday
        let weekStart = calendar.date(from: components) ?? date
        let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart)!

        let logs = fetchLogs(from: weekStart, to: weekEnd)

        var result: [Date: [PrayerType: Bool]] = [:]

        // Initialize all days
        for i in 0..<7 {
            let day = calendar.date(byAdding: .day, value: i, to: weekStart)!
            let dayStart = startOfDay(day)
            result[dayStart] = [:]
            for prayer in PrayerType.wajibPrayers {
                result[dayStart]?[prayer] = false
            }
        }

        // Fill in completed
        for log in logs where log.completed {
            let dayStart = startOfDay(log.date)
            if let prayerType = PrayerType(rawValue: log.prayerType) {
                result[dayStart]?[prayerType] = true
            }
        }

        return result
    }
}
