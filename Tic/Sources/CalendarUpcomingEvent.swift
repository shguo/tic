import Foundation

struct CalendarUpcomingEvent: Identifiable {
    let id: String
    let title: String
    let date: Date
    let daysUntil: Int
    let dateLabel: String
    /// `.festival` 或 `.solarTerm`，决定标题旁小标记的文字与颜色。
    let kind: DaySubtitleKind
}

