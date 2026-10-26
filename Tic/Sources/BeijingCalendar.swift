import Foundation

/// 农历、节气、调休均以北京时间（东八区）为「当天」边界，与 LunarSwift / holiday-cn 一致。
enum BeijingCalendar {
    static let timeZone = TimeZone(identifier: "Asia/Shanghai") ?? .current

    static let gregorian: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "zh_CN")
        calendar.timeZone = timeZone
        // 与月历网格一致：周一为每周第一天（zh_CN 默认周日为首，此处显式对齐）。
        calendar.firstWeekday = 2
        return calendar
    }()

    static let chinese: Calendar = {
        var calendar = Calendar(identifier: .chinese)
        calendar.timeZone = timeZone
        return calendar
    }()

    /// `HolidayStore` 与月历格 id 使用的日期键，如「2026-10-01」。
    static func dateKey(_ date: Date) -> String {
        let components = gregorian.dateComponents([.year, .month, .day], from: date)
        let year = components.year ?? 0
        let month = components.month ?? 0
        let day = components.day ?? 0
        return "\(year)-\(twoDigit(month))-\(twoDigit(day))"
    }

    private static func twoDigit(_ value: Int) -> String {
        value < 10 ? "0\(value)" : "\(value)"
    }
}
