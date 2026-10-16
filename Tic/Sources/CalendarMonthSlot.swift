import Foundation

/// 日期格第二行文字的类别，决定显示样式。
enum DaySubtitleKind: Sendable {
    /// 农历日（初二…三十）
    case lunarDay
    /// 农历月首，显示月名（如「九月」「闰六月」）
    case lunarMonthStart
    case solarTerm
    /// 公历 / 农历节日与法定假日名
    case festival
}

struct DaySubtitle: Hashable, Sendable {
    let text: String
    let kind: DaySubtitleKind
}

struct CalendarMonthSlot: Identifiable {
    let id: String
    let date: Date
    let monthNumber: Int
    let dayNumber: Int
    let isWeekend: Bool
    let subtitles: [DaySubtitle]
    let hasAnnotation: Bool
    let badge: DayBadge?
    /// 是否属于当前查看的月份；为 false 时是补齐首尾的上月 / 下月日期，淡色显示。
    var isInDisplayedMonth: Bool = true

    static func day(
        _ date: Date,
        key: String,
        monthNumber: Int,
        dayNumber: Int,
        isWeekend: Bool,
        subtitles: [DaySubtitle],
        hasAnnotation: Bool,
        badge: DayBadge?,
        isInDisplayedMonth: Bool = true
    ) -> CalendarMonthSlot {
        CalendarMonthSlot(
            id: key,
            date: date,
            monthNumber: monthNumber,
            dayNumber: dayNumber,
            isWeekend: isWeekend,
            subtitles: subtitles,
            hasAnnotation: hasAnnotation,
            badge: badge,
            isInDisplayedMonth: isInDisplayedMonth
        )
    }

    func subtitle(rotationIndex: Int) -> DaySubtitle {
        guard !subtitles.isEmpty else { return DaySubtitle(text: "", kind: .lunarDay) }
        return subtitles[rotationIndex % subtitles.count]
    }
}
