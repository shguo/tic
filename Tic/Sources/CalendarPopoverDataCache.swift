import Foundation

struct CalendarPopoverDataCache {
    private struct MonthSlotsKey: Hashable {
        let year: Int
        let month: Int
        let options: CalendarDisplayOptions

        init(month date: Date, options: CalendarDisplayOptions, calendar: Calendar) {
            let components = calendar.dateComponents([.year, .month], from: date)
            self.year = components.year ?? 0
            self.month = components.month ?? 0
            self.options = options
        }
    }

    private struct UpcomingEventsKey: Hashable {
        let year: Int
        let month: Int
        let day: Int
        let options: CalendarDisplayOptions
        let limit: Int

        init(date: Date, limit: Int, options: CalendarDisplayOptions, calendar: Calendar) {
            let components = calendar.dateComponents([.year, .month, .day], from: date)
            self.year = components.year ?? 0
            self.month = components.month ?? 0
            self.day = components.day ?? 0
            self.options = options
            self.limit = limit
        }
    }

    private var monthSlotsByKey: [MonthSlotsKey: [CalendarMonthSlot]] = [:]
    private var monthSlotsOrder: [MonthSlotsKey] = []
    private var upcomingEventsByKey: [UpcomingEventsKey: [CalendarUpcomingEvent]] = [:]
    private var upcomingEventsOrder: [UpcomingEventsKey] = []

    mutating func monthSlots(
        for month: Date,
        options: CalendarDisplayOptions,
        calendar: Calendar
    ) -> [CalendarMonthSlot] {
        let key = MonthSlotsKey(month: month, options: options, calendar: calendar)
        if let cached = monthSlotsByKey[key] {
            touch(key, in: &monthSlotsOrder)
            return cached
        }

        let slots = CalendarMonthBuilder.monthSlots(for: month, options: options)
        monthSlotsByKey[key] = slots
        remember(key, in: &monthSlotsOrder, cache: &monthSlotsByKey, limit: 18)
        return slots
    }

    mutating func upcomingEvents(
        from date: Date,
        limit: Int,
        options: CalendarDisplayOptions,
        calendar: Calendar
    ) -> [CalendarUpcomingEvent] {
        let key = UpcomingEventsKey(
            date: calendar.startOfDay(for: date),
            limit: limit,
            options: options,
            calendar: calendar
        )
        if let cached = upcomingEventsByKey[key] {
            touch(key, in: &upcomingEventsOrder)
            return cached
        }

        let events = CalendarMonthBuilder.upcomingEvents(from: date, limit: limit, options: options)
        upcomingEventsByKey[key] = events
        remember(key, in: &upcomingEventsOrder, cache: &upcomingEventsByKey, limit: 90)
        return events
    }

    private func touch<Key: Hashable>(_ key: Key, in order: inout [Key]) {
        order.removeAll { $0 == key }
        order.append(key)
    }

    private func remember<Key: Hashable, Value>(
        _ key: Key,
        in order: inout [Key],
        cache: inout [Key: Value],
        limit: Int
    ) {
        touch(key, in: &order)
        while order.count > limit, let staleKey = order.first {
            order.removeFirst()
            cache.removeValue(forKey: staleKey)
        }
    }
}
