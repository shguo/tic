import Foundation

/// 节日分档：传统、官方节日始终显示；西方 / 流行节日受设置「显示西方节日」控制。
enum FestivalTier: Sendable {
    case traditional
    case official
    case western
}

/// 节日日期规则。
enum FestivalRule: Sendable {
    case solar(month: Int, day: Int)
    /// 公历某月第 `ordinal` 个星期几；`weekday` 为 `Calendar` 标准（1=周日 … 7=周六）。
    case nthWeekday(month: Int, weekday: Int, ordinal: Int)
    /// 农历月日，闰月不计。
    case lunar(month: Int, day: Int)
    /// 除夕：次日为正月初一（腊月廿九或三十均可）。
    case lunarNewYearEve
}

struct Festival: Sendable {
    /// 月历格与后续提醒共用的名称，统一用正式全名（「元宵节」而非「元宵」）。
    let name: String
    let tier: FestivalTier
    let rule: FestivalRule

    init(_ name: String, tier: FestivalTier, rule: FestivalRule) {
        self.name = name
        self.tier = tier
        self.rule = rule
    }
}

/// 节日唯一来源。官方节日对齐《全国年节及纪念日放假办法》与 Apple「中国大陆节假日」订阅，
/// 传统节日参考 tyme4j / LunarSwift；纪念日、国际日不收录。
/// 法定放假 / 调休不在此表，见 `HolidayStore`；节气见 `SolarTermSupport`。
/// 同一天有多个节日时按本表顺序显示（公历在前、农历在后）。
enum FestivalCatalog {
    static let all: [Festival] = [
        Festival("元旦", tier: .official, rule: .solar(month: 1, day: 1)),
        Festival("情人节", tier: .western, rule: .solar(month: 2, day: 14)),
        Festival("妇女节", tier: .official, rule: .solar(month: 3, day: 8)),
        Festival("植树节", tier: .official, rule: .solar(month: 3, day: 12)),
        Festival("愚人节", tier: .western, rule: .solar(month: 4, day: 1)),
        Festival("劳动节", tier: .official, rule: .solar(month: 5, day: 1)),
        Festival("青年节", tier: .official, rule: .solar(month: 5, day: 4)),
        Festival("儿童节", tier: .official, rule: .solar(month: 6, day: 1)),
        Festival("建党节", tier: .official, rule: .solar(month: 7, day: 1)),
        Festival("建军节", tier: .official, rule: .solar(month: 8, day: 1)),
        Festival("教师节", tier: .official, rule: .solar(month: 9, day: 10)),
        Festival("国庆节", tier: .official, rule: .solar(month: 10, day: 1)),
        // 严格说 10/31 是万圣夜，国内日历习惯标「万圣节」。
        Festival("万圣节", tier: .western, rule: .solar(month: 10, day: 31)),
        Festival("平安夜", tier: .western, rule: .solar(month: 12, day: 24)),
        Festival("圣诞节", tier: .western, rule: .solar(month: 12, day: 25)),

        Festival("母亲节", tier: .western, rule: .nthWeekday(month: 5, weekday: 1, ordinal: 2)),
        Festival("父亲节", tier: .western, rule: .nthWeekday(month: 6, weekday: 1, ordinal: 3)),
        Festival("感恩节", tier: .western, rule: .nthWeekday(month: 11, weekday: 5, ordinal: 4)),

        Festival("春节", tier: .traditional, rule: .lunar(month: 1, day: 1)),
        Festival("元宵节", tier: .traditional, rule: .lunar(month: 1, day: 15)),
        Festival("龙抬头", tier: .traditional, rule: .lunar(month: 2, day: 2)),
        Festival("上巳节", tier: .traditional, rule: .lunar(month: 3, day: 3)),
        Festival("端午节", tier: .traditional, rule: .lunar(month: 5, day: 5)),
        Festival("七夕节", tier: .traditional, rule: .lunar(month: 7, day: 7)),
        Festival("中元节", tier: .traditional, rule: .lunar(month: 7, day: 15)),
        Festival("中秋节", tier: .traditional, rule: .lunar(month: 8, day: 15)),
        Festival("重阳节", tier: .traditional, rule: .lunar(month: 9, day: 9)),
        Festival("腊八节", tier: .traditional, rule: .lunar(month: 12, day: 8)),
        Festival("小年", tier: .traditional, rule: .lunar(month: 12, day: 23)),
        Festival("除夕", tier: .traditional, rule: .lunarNewYearEve),
    ]
}
