import Foundation

struct CalendarMonthSlot: Identifiable {
    let id: String
    let date: Date?
    let monthNumber: Int
    let dayNumber: Int
    let isWeekend: Bool
    let subtitles: [String]
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
        subtitles: [String],
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

    func subtitle(rotationIndex: Int) -> String {
        guard !subtitles.isEmpty else { return "" }
        return subtitles[rotationIndex % subtitles.count]
    }
}
