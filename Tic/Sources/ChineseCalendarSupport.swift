import Foundation
import LunarSwift

/// 黄历当日宜 / 忌（传统择日，仅供参考）。
struct DayYiJi: Equatable {
    let yi: [String]
    let ji: [String]
}

/// 农历文字、干支、宜忌与日期标签。节日见 `FestivalCalendar`，月历合并见 `CalendarMonthBuilder`。
enum ChineseCalendarSupport {
    private static let gregorian = BeijingCalendar.gregorian
    private static let chinese = BeijingCalendar.chinese

    private static let heavenlyStems = ["甲", "乙", "丙", "丁", "戊", "己", "庚", "辛", "壬", "癸"]
    private static let earthlyBranches = ["子", "丑", "寅", "卯", "辰", "巳", "午", "未", "申", "酉", "戌", "亥"]
    private static let zodiacAnimals = ["鼠", "牛", "虎", "兔", "龙", "蛇", "马", "羊", "猴", "鸡", "狗", "猪"]
    private static let lunarMonthNames = [
        "正月", "二月", "三月", "四月", "五月", "六月",
        "七月", "八月", "九月", "十月", "冬月", "腊月",
    ]
    private static let digitNames = ["一", "二", "三", "四", "五", "六", "七", "八", "九", "十"]

    static func lunarMonthDayLabel(for date: Date) -> String {
        let month = chinese.component(.month, from: date)
        let day = chinese.component(.day, from: date)
        let monthName = lunarMonthNames[safe: month - 1] ?? "\(month)月"
        let leapPrefix = chinese.dateComponents([.month], from: date).isLeapMonth == true ? "闰" : ""
        return leapPrefix + monthName + lunarDayName(day)
    }

    static func lunarYearLabel(for date: Date) -> String {
        let yearInCycle = chinese.component(.year, from: date)
        let index = positiveModulo(yearInCycle - 1, 60)
        let stem = heavenlyStems[index % 10]
        let branch = earthlyBranches[index % 12]
        let animal = zodiacAnimals[index % 12]
        return "\(stem)\(branch)\(animal)年"
    }

    static func lunarDetailMeta(for date: Date) -> String {
        "\(lunarYearLabel(for: date)) \(sexagenaryMonthLabel(for: date))月 \(sexagenaryDayLabel(for: date))日"
    }

    /// 宜忌由 LunarSwift 按「月干支 × 日干支」查《协纪辨方书》预编码表得出；无条目时为 ["无"]。
    @MainActor
    static func dayYiJi(for date: Date) -> DayYiJi {
        let key = BeijingCalendar.dateKey(date)
        if let cached = yiJiCache[key] {
            return cached
        }
        let lunar = lunarDay(for: date)
        let result = DayYiJi(yi: lunar.dayYi, ji: lunar.dayJi)
        if yiJiCache.count >= 400 {
            yiJiCache.removeAll()
        }
        yiJiCache[key] = result
        return result
    }

    /// 查表要对整张宜忌表跑正则；弹窗每 3 秒轮播副标题会重算视图，按日缓存避免重复计算。
    @MainActor private static var yiJiCache: [String: DayYiJi] = [:]

    static func weekOfYear(for date: Date) -> Int {
        gregorian.component(.weekOfYear, from: date)
    }

    /// 相对今天：今天 / 昨天 / 明天 / N天前 / N天后
    static func relativeDayLabel(
        for date: Date,
        relativeTo reference: Date = .now
    ) -> String {
        let target = gregorian.startOfDay(for: date)
        let anchor = BeijingCalendar.day(containing: reference)
        let days = gregorian.dateComponents([.day], from: anchor, to: target).day ?? 0
        switch days {
        case 0: return "今天"
        case 1: return "明天"
        case -1: return "昨天"
        case let offset where offset > 0: return "\(offset)天后"
        default: return "\(-days)天前"
        }
    }

    /// 无节日 / 节气时的农历文字：月首显示月名（「九月」「闰六月」），其余显示农历日。
    static func lunarCellSubtitle(for date: Date) -> DaySubtitle {
        let components = chinese.dateComponents([.month, .day], from: date)
        guard components.day == 1, let month = components.month else {
            return DaySubtitle(text: lunarDayLabel(for: date), kind: .lunarDay)
        }
        let leapPrefix = components.isLeapMonth == true ? "闰" : ""
        return DaySubtitle(text: leapPrefix + (lunarMonthNames[safe: month - 1] ?? "\(month)月"), kind: .lunarMonthStart)
    }

    private static func lunarDayLabel(for date: Date) -> String {
        lunarDayName(chinese.component(.day, from: date))
    }

    private static func lunarDayName(_ day: Int) -> String {
        switch day {
        case 1...10:
            return "初" + digitNames[day - 1]
        case 11...19:
            return "十" + digitNames[day - 11]
        case 20:
            return "二十"
        case 21...29:
            return "廿" + digitNames[day - 21]
        case 30:
            return "三十"
        default:
            return ""
        }
    }

    private static func sexagenaryMonthLabel(for date: Date) -> String {
        let year = gregorian.component(.year, from: date)
        let lichun = dateOfSolarTerm("立春", in: year) ?? gregorian.date(from: DateComponents(year: year, month: 2, day: 4))!
        let solarYear = date < lichun ? year - 1 : year
        let branchIndex = solarMonthBranchIndex(for: date, in: year)
        let yinStemIndex = yinMonthStemIndex(forYearStem: positiveModulo(solarYear - 4, 10))
        let monthOffset = positiveModulo(branchIndex - 2, 12)
        let stemIndex = positiveModulo(yinStemIndex + monthOffset, 10)
        return heavenlyStems[stemIndex] + earthlyBranches[branchIndex]
    }

    private static func sexagenaryDayLabel(for date: Date) -> String {
        lunarDay(for: date).dayInGanZhi
    }

    /// 北京时间当日对应的 LunarSwift 农历日。
    private static func lunarDay(for date: Date) -> Lunar {
        let components = gregorian.dateComponents([.year, .month, .day], from: date)
        return Solar.fromYmdHms(
            year: components.year ?? 0,
            month: components.month ?? 1,
            day: components.day ?? 1
        ).lunar
    }

    private static func solarMonthBranchIndex(for date: Date, in year: Int) -> Int {
        let boundaries: [(term: String, branchIndex: Int)] = [
            ("小寒", 1),
            ("立春", 2),
            ("惊蛰", 3),
            ("清明", 4),
            ("立夏", 5),
            ("芒种", 6),
            ("小暑", 7),
            ("立秋", 8),
            ("白露", 9),
            ("寒露", 10),
            ("立冬", 11),
            ("大雪", 0),
        ]

        return boundaries.reduce(0) { current, boundary in
            guard let boundaryDate = dateOfSolarTerm(boundary.term, in: year), date >= boundaryDate else {
                return current
            }
            return boundary.branchIndex
        }
    }

    private static func yinMonthStemIndex(forYearStem yearStem: Int) -> Int {
        switch yearStem {
        case 0, 5: return 2
        case 1, 6: return 4
        case 2, 7: return 6
        case 3, 8: return 8
        default: return 0
        }
    }

    private static func dateOfSolarTerm(_ term: String, in year: Int) -> Date? {
        SolarTermSupport.date(of: term, in: year)
    }

    /// 「后续提醒」日期：所有类型统一为「公历 | 农历 | 星期」，如「10月18日 | 九月初九 | 周日」。
    static func upcomingDateLabel(for date: Date) -> String {
        let gregorianLabel = "\(gregorian.component(.month, from: date))月\(gregorian.component(.day, from: date))日"
        return "\(gregorianLabel) | \(lunarMonthDayLabel(for: date)) | \(weekdayLabel(for: date))"
    }

    private static func weekdayLabel(for date: Date) -> String {
        let labels = ["周日", "周一", "周二", "周三", "周四", "周五", "周六"]
        let index = gregorian.component(.weekday, from: date) - 1
        return labels[safe: index] ?? ""
    }

    private static func positiveModulo(_ value: Int, _ divisor: Int) -> Int {
        let remainder = value % divisor
        return remainder >= 0 ? remainder : remainder + divisor
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
