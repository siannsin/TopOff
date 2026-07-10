import Foundation

struct HistoryDayGroup: Identifiable {
    let id: Date                  // start-of-day
    let title: String             // localized date label
    let events: [UpdateResult]
}

enum HistoryGrouping {

    static func timeTitle(
        for date: Date,
        calendar: Calendar = .current,
        locale: Locale = .current
    ) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = locale
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    static func groupHistory(
        _ history: [UpdateResult],
        calendar: Calendar = .current,
        referenceDate: Date = Date(),
        locale: Locale = .current
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
                title: dateTitle(for: day, calendar: calendar, locale: locale),
                events: events
            )
        }
    }

    private static func dateTitle(for day: Date, calendar: Calendar, locale: Locale) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = locale
        formatter.setLocalizedDateFormatFromTemplate("d MMMM y")
        return formatter.string(from: day)
    }
}
