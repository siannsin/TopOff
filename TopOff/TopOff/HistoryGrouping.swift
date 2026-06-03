import Foundation

struct HistoryDayGroup: Identifiable {
    let id: Date                  // start-of-day
    let title: String             // relative label
    let events: [UpdateResult]
}

enum HistoryGrouping {

    static func groupHistory(
        _ history: [UpdateResult],
        calendar: Calendar = .current,
        referenceDate: Date = Date()
    ) -> [HistoryDayGroup] {
        var ordered: [(Date, [UpdateResult])] = []
        var keyOrder: [Date] = []
        var byDay: [Date: [UpdateResult]] = [:]

        for event in history {
            let day = calendar.startOfDay(for: event.timestamp)
            if byDay[day] == nil {
                keyOrder.append(day)
            }
            byDay[day, default: []].append(event)
        }

        for key in keyOrder {
            ordered.append((key, byDay[key] ?? []))
        }

        return ordered.map { day, events in
            HistoryDayGroup(
                id: day,
                title: relativeTitle(for: day, calendar: calendar, reference: referenceDate),
                events: events
            )
        }
    }

    private static func relativeTitle(for day: Date,
                                      calendar: Calendar,
                                      reference: Date) -> String {
        let referenceDay = calendar.startOfDay(for: reference)
        if calendar.isDate(day, inSameDayAs: referenceDay) {
            return "Today"
        }
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: referenceDay),
           calendar.isDate(day, inSameDayAs: yesterday) {
            return "Yesterday"
        }

        // Within the past week → day name (Wednesday, etc.)
        if let weekAgo = calendar.date(byAdding: .day, value: -6, to: referenceDay),
           day >= weekAgo {
            let formatter = DateFormatter()
            formatter.calendar = calendar
            formatter.dateFormat = "EEEE"
            return formatter.string(from: day)
        }

        // Same year → "May 27"
        if calendar.component(.year, from: day) == calendar.component(.year, from: reference) {
            let formatter = DateFormatter()
            formatter.calendar = calendar
            formatter.dateFormat = "MMMM d"
            return formatter.string(from: day)
        }

        // Older → "May 27, 2025"
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: day)
    }
}
