import Foundation

/// 合并节日（`FestivalCalendar`）、节气（`SolarTermSupport`）、法定放假（`HolidayStore`）与农历文字，
/// 生成月历格子、后续提醒与下个假期倒计时。
enum CalendarMonthBuilder {
    private struct CalendarEventCandidate {
        let date: Date
        let title: String
        let dateLabel: String
        let priority: Int
        let kind: DaySubtitleKind
    }

    private static let gregorian = BeijingCalendar.gregorian

    /// 月历固定 6 行 × 7 列；首尾按常见日历惯例用上月 / 下月日期补齐，切换月份时网格高度不变。
    static let monthGridSlotCount = 42

    static func monthSlots(for month: Date, options: CalendarDisplayOptions = .default) -> [CalendarMonthSlot] {
        let firstOfMonth = gregorian.date(from: gregorian.dateComponents([.year, .month], from: month))!
        let leading = mondayBasedLeadingBlankCount(
            weekdayOfFirst: gregorian.component(.weekday, from: firstOfMonth)
        )
        let gridStart = gregorian.date(byAdding: .day, value: -leading, to: firstOfMonth)!

        return (0..<monthGridSlotCount).map { offset in
            let date = gregorian.date(byAdding: .day, value: offset, to: gridStart)!
            let components = gregorian.dateComponents([.month, .day, .weekday], from: date)
            let weekday = components.weekday ?? 0
            let metadata = dayCellMetadata(for: date, options: options)
            return .day(
                date,
                key: BeijingCalendar.dateKey(date),
                monthNumber: components.month ?? 0,
                dayNumber: components.day ?? 0,
                isWeekend: weekday == 1 || weekday == 7,
                subtitles: metadata.subtitles,
                hasAnnotation: metadata.hasAnnotation,
                badge: metadata.badge,
                isInDisplayedMonth: gregorian.isDate(date, equalTo: firstOfMonth, toGranularity: .month)
            )
        }
    }

    static func cellSubtitle(for date: Date, options: CalendarDisplayOptions = .default) -> String {
        cellSubtitles(for: date, options: options).first ?? ""
    }

    static func cellSubtitles(for date: Date, options: CalendarDisplayOptions = .default) -> [String] {
        dayCellMetadata(for: date, options: options).subtitles.map(\.text)
    }

    static func badge(for date: Date) -> DayBadge? {
        storedAnnotation(for: date)?.badge
    }

    private static func dayCellMetadata(
        for date: Date,
        options: CalendarDisplayOptions
    ) -> (subtitles: [DaySubtitle], hasAnnotation: Bool, badge: DayBadge?) {
        var subtitles: [DaySubtitle] = []
        let ann = storedAnnotation(for: date)
        let solarTerm = options.showSolarTerms ? SolarTermSupport.name(for: date) : nil
        let festivals = FestivalCalendar.festivals(on: date, includeWestern: options.showWesternFestivals)

        if let term = solarTerm {
            subtitles.append(DaySubtitle(text: term, kind: .solarTerm))
        }
        for festival in festivals {
            subtitles.append(DaySubtitle(text: festival.cellTitle, kind: .festival))
        }
        // 放假数据用全名（「中秋节」「清明节」），合并假期写作「国庆节、中秋节」；
        // 其中任一节日已由同日节日 / 节气显示时不再追加。
        if let subtitle = ann?.subtitle,
           !subtitle.split(separator: "、").contains(where: { name in
               subtitles.contains { $0.text == name || $0.text + "节" == name }
           }),
           ann?.badge != .rest || isFirstAnnotatedHoliday(date, subtitle: subtitle) {
            subtitles.append(DaySubtitle(text: subtitle, kind: .festival))
        }

        let unique = subtitles.reduce(into: [DaySubtitle]()) { result, subtitle in
            if !result.contains(where: { $0.text == subtitle.text }) {
                result.append(subtitle)
            }
        }
        let hasAnnotation = ann?.badge != nil
            || solarTerm != nil
            || !festivals.isEmpty

        return (
            subtitles: unique.isEmpty ? [ChineseCalendarSupport.lunarCellSubtitle(for: date)] : unique,
            hasAnnotation: hasAnnotation,
            badge: ann?.badge
        )
    }

    static func upcomingEvents(
        from date: Date,
        limit: Int = 3,
        options: CalendarDisplayOptions = .default
    ) -> [CalendarUpcomingEvent] {
        let start = gregorian.startOfDay(for: date)
        let end = gregorian.date(byAdding: .day, value: 370, to: start) ?? start
        var candidates: [CalendarEventCandidate] = []
        candidates.reserveCapacity(options.showSolarTerms ? 96 : 48)

        appendFestivalEvents(
            from: start,
            through: end,
            includeWestern: options.showWesternFestivals,
            into: &candidates
        )
        if options.showSolarTerms {
            appendSolarTermEvents(from: start, through: end, into: &candidates)
        }

        let unique = candidates
            .filter { $0.date >= start && $0.date <= end }
            .sorted {
                if !gregorian.isDate($0.date, inSameDayAs: $1.date) {
                    return $0.date < $1.date
                }
                return $0.priority < $1.priority
            }
            .reduce(into: [CalendarEventCandidate]()) { result, candidate in
                let alreadyIncluded = result.contains {
                    $0.title == candidate.title && gregorian.isDate($0.date, inSameDayAs: candidate.date)
                }
                if !alreadyIncluded {
                    result.append(candidate)
                }
            }
            .prefix(limit)

        return unique.map { item in
            let days = gregorian.dateComponents([.day], from: start, to: item.date).day ?? 0
            return CalendarUpcomingEvent(
                id: "\(BeijingCalendar.dateKey(item.date))-\(item.title)",
                title: item.title,
                date: item.date,
                daysUntil: days,
                dateLabel: item.dateLabel,
                kind: item.kind
            )
        }
    }

    /// 距下一法定休首日（HolidayStore 中 badge 为「休」的首日）的天数；今天已是休假日则跳过当前连休。
    static func nextRestDayCountdown(from date: Date) -> (name: String, days: Int)? {
        let start = gregorian.startOfDay(for: date)
        for offset in 0..<370 {
            guard let candidate = gregorian.date(byAdding: .day, value: offset, to: start),
                  let stored = storedAnnotation(for: candidate),
                  stored.badge == .rest,
                  let name = stored.subtitle,
                  isFirstAnnotatedHoliday(candidate, subtitle: name)
            else { continue }
            if offset > 0 {
                return (name, offset)
            }
        }
        return nil
    }

    static func nextRestDayCountdownLabel(from date: Date) -> String? {
        guard let next = nextRestDayCountdown(from: date) else { return nil }
        return "\(next.name) \(countdownLabel(days: next.days))"
    }

    private static func countdownLabel(days: Int) -> String {
        switch days {
        case 0: return "今天"
        case 1: return "明天"
        default: return "\(days)天后"
        }
    }

    private static func appendFestivalEvents(
        from start: Date,
        through end: Date,
        includeWestern: Bool,
        into candidates: inout [CalendarEventCandidate]
    ) {
        let startYear = gregorian.component(.year, from: start)
        let endYear = gregorian.component(.year, from: end)

        for year in startYear...endYear {
            for item in FestivalCalendar.festivals(in: year)
            where item.date >= start && item.date <= end && (includeWestern || item.festival.tier != .western) {
                candidates.append(CalendarEventCandidate(
                    date: item.date,
                    title: item.festival.eventTitle,
                    dateLabel: ChineseCalendarSupport.upcomingDateLabel(for: item.date),
                    priority: 1,
                    kind: .festival
                ))
            }
        }
    }

    private static func appendSolarTermEvents(
        from start: Date,
        through end: Date,
        into candidates: inout [CalendarEventCandidate]
    ) {
        let startYear = gregorian.component(.year, from: start)
        let endYear = gregorian.component(.year, from: end)

        for year in startYear...endYear {
            for term in SolarTermSupport.terms(in: year) where term.date >= start && term.date <= end {
                candidates.append(CalendarEventCandidate(
                    date: term.date,
                    title: term.name,
                    dateLabel: ChineseCalendarSupport.upcomingDateLabel(for: term.date),
                    priority: 2,
                    kind: .solarTerm
                ))
            }
        }
    }

    /// 法定连休仅首日显示节日名；向前最多 14 天跳过数据缺口，避免缺前一天条目时重复显示。
    private static func isFirstAnnotatedHoliday(_ date: Date, subtitle: String) -> Bool {
        var cursor = date
        for _ in 0..<14 {
            guard let previousDate = gregorian.date(byAdding: .day, value: -1, to: cursor) else {
                return true
            }
            cursor = previousDate
            guard let previous = storedAnnotation(for: previousDate) else {
                continue
            }
            if previous.badge == .rest && previous.subtitle == subtitle {
                return false
            }
            return true
        }
        return true
    }

    private static func storedAnnotation(for date: Date) -> DayAnnotation? {
        HolidayStore.shared.annotation(forKey: BeijingCalendar.dateKey(date))
    }

    /// 月历网格周一为首列：`weekday` 为 `Calendar` 标准（1=周日 … 7=周六）。
    private static func mondayBasedLeadingBlankCount(weekdayOfFirst: Int) -> Int {
        (weekdayOfFirst + 5) % 7
    }
}
