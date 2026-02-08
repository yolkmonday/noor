import SwiftUI

struct WeeklyCalendarView: View {
    @Binding var selectedDate: Date
    let weeklyData: [Date: [PrayerType: Bool]]

    private let calendar = Calendar.current
    private let dayNames = ["Sen", "Sel", "Rab", "Kam", "Jum", "Sab", "Min"]
    private let totalWeeks = 53 // ~1 year of scrollable weeks
    private let currentWeekIndex = 52 // index for "this week"

    var body: some View {
        VStack(spacing: 8) {
            // Week header
            HStack {
                Text(weekTitle)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(weekRangeText)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            // Scrollable weeks
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 0) {
                        ForEach(0..<totalWeeks, id: \.self) { weekOffset in
                            let offset = weekOffset - currentWeekIndex
                            WeekRow(
                                days: weekDays(offset: offset),
                                dayNames: dayNames,
                                selectedDate: $selectedDate,
                                weeklyData: weeklyData,
                                calendar: calendar
                            )
                            .frame(width: 280)
                            .id(weekOffset)
                        }
                    }
                }
                .onAppear {
                    proxy.scrollTo(currentWeekIndex, anchor: .center)
                }
                .onChange(of: selectedDate) { _ in
                    let weekIndex = weekIndexFor(date: selectedDate)
                    withAnimation(.easeInOut(duration: 0.2)) {
                        proxy.scrollTo(weekIndex, anchor: .center)
                    }
                }
            }
        }
        .padding(10)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
    }

    private var selectedWeekDays: [Date] {
        weekDays(offset: 0)
    }

    private func weekDays(offset: Int) -> [Date] {
        let referenceDate = calendar.date(byAdding: .weekOfYear, value: offset, to: Date()) ?? Date()
        var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: referenceDate)
        components.weekday = 2 // Monday
        let weekStart = calendar.date(from: components) ?? referenceDate

        return (0..<7).compactMap { day in
            calendar.date(byAdding: .day, value: day, to: weekStart)
        }
    }

    private func weekIndexFor(date: Date) -> Int {
        let today = Date()
        let todayWeekStart = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)
        let dateWeekStart = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)

        let todayMonday = calendar.date(from: todayWeekStart) ?? today
        let dateMonday = calendar.date(from: dateWeekStart) ?? date

        let weekDiff = calendar.dateComponents([.weekOfYear], from: todayMonday, to: dateMonday).weekOfYear ?? 0
        return currentWeekIndex + weekDiff
    }

    private var weekTitle: String {
        let days = weekDays(offset: weekOffsetForSelected)
        guard let first = days.first else { return "" }
        if calendar.isDate(first, equalTo: Date(), toGranularity: .weekOfYear) {
            return "Minggu Ini"
        }
        let diff = calendar.dateComponents([.weekOfYear], from: Date(), to: first).weekOfYear ?? 0
        if diff == -1 { return "Minggu Lalu" }
        if diff == 1 { return "Minggu Depan" }
        return "Minggu Ini"
    }

    private var weekOffsetForSelected: Int {
        let todayWeekStart = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())
        let selectedWeekStart = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: selectedDate)

        let todayMonday = calendar.date(from: todayWeekStart) ?? Date()
        let selectedMonday = calendar.date(from: selectedWeekStart) ?? selectedDate

        return calendar.dateComponents([.weekOfYear], from: todayMonday, to: selectedMonday).weekOfYear ?? 0
    }

    private static let rangeDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "d MMM"
        f.locale = Locale(identifier: "id_ID")
        return f
    }()

    private var weekRangeText: String {
        let days = weekDays(offset: weekOffsetForSelected)
        guard let first = days.first, let last = days.last else { return "" }
        return "\(Self.rangeDateFormatter.string(from: first)) - \(Self.rangeDateFormatter.string(from: last))"
    }
}

private struct WeekRow: View {
    let days: [Date]
    let dayNames: [String]
    @Binding var selectedDate: Date
    let weeklyData: [Date: [PrayerType: Bool]]
    let calendar: Calendar

    var body: some View {
        HStack(spacing: 4) {
            ForEach(Array(days.enumerated()), id: \.offset) { index, date in
                DayCell(
                    dayName: dayNames[index],
                    dayNumber: calendar.component(.day, from: date),
                    isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                    isToday: calendar.isDateInToday(date),
                    completedCount: completedCount(for: date)
                ) {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        selectedDate = date
                    }
                }
            }
        }
    }

    private func completedCount(for date: Date) -> Int {
        let dayStart = calendar.startOfDay(for: date)
        guard let prayers = weeklyData[dayStart] else { return 0 }
        return prayers.values.filter { $0 }.count
    }
}

struct DayCell: View {
    let dayName: String
    let dayNumber: Int
    let isSelected: Bool
    let isToday: Bool
    let completedCount: Int
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Text(dayName)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)

                ZStack {
                    Circle()
                        .fill(isSelected ? Color.noorTeal : Color.clear)
                        .frame(width: 26, height: 26)

                    if isToday && !isSelected {
                        Circle()
                            .strokeBorder(Color.noorTeal, lineWidth: 1)
                            .frame(width: 26, height: 26)
                    }

                    Text("\(dayNumber)")
                        .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                        .foregroundStyle(isSelected ? .white : .primary)
                }

                // Completion dots
                HStack(spacing: 2) {
                    ForEach(0..<5, id: \.self) { index in
                        Circle()
                            .fill(index < completedCount ? Color.noorTeal : Color.secondary.opacity(0.2))
                            .frame(width: 3, height: 3)
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}
