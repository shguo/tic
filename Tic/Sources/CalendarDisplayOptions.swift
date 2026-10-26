import Foundation

/// 月历 / 后续提醒的显示选项（对应设置 → 日历中的开关），同时用作弹出层数据缓存的键。
struct CalendarDisplayOptions: Hashable, Sendable {
    var showSolarTerms = true
    var showWesternFestivals = true

    static let `default` = CalendarDisplayOptions()

    static func fromUserDefaults() -> CalendarDisplayOptions {
        CalendarDisplayOptions(
            showSolarTerms: AppSettings.bool(forKey: AppSettings.showSolarTermsKey, default: true),
            showWesternFestivals: AppSettings.bool(forKey: AppSettings.showWesternFestivalsKey, default: true)
        )
    }
}
