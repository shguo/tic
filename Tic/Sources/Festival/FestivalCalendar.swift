import Foundation

struct DatedFestival: Sendable {
    let date: Date
    let festival: Festival
}

/// 按公历年计算并缓存 `FestivalCatalog` 的全年日期；月历单日查询与后续提醒区间枚举共用同一份结果。
enum FestivalCalendar {
    private static let gregorian = BeijingCalendar.gregorian
    private static let chinese = BeijingCalendar.chinese

    private struct YearFestivals: Sendable {
        /// 按日期升序；同日按 `FestivalCatalog` 顺序
        let sorted: [DatedFestival]
        let byDay: [Date: [Festival]]
    }

    private final class YearCache: @unchecked Sendable {
        private let lock = NSLock()
        private var storage: [Int: YearFestivals] = [:]

        func festivals(forYear year: Int, compute: (Int) -> YearFestivals) -> YearFestivals {
            lock.lock()
            if let cached = storage[year] {
                lock.unlock()
                return cached
            }
            lock.unlock()

            let computed = compute(year)

            lock.lock()
            defer { lock.unlock() }
            if let cached = storage[year] { return cached }
            storage[year] = computed
            return computed
        }
    }

    private static let cache = YearCache()

    static func festivals(in year: Int) -> [DatedFestival] {
        cache.festivals(forYear: year, compute: computeYear).sorted
    }

    static func festivals(on date: Date, includeWestern: Bool) -> [Festival] {
        let year = gregorian.component(.year, from: date)
        let festivals = cache.festivals(forYear: year, compute: computeYear)
            .byDay[gregorian.startOfDay(for: date)] ?? []
        return includeWestern ? festivals : festivals.filter { $0.tier != .western }
    }

    private static func computeYear(_ year: Int) -> YearFestivals {
        var dated: [(date: Date, order: Int, festival: Festival)] = []

        for (order, festival) in FestivalCatalog.all.enumerated() {
            switch festival.rule {
            case let .solar(month, day):
                if let date = gregorian.date(from: DateComponents(year: year, month: month, day: day)) {
                    dated.append((date, order, festival))
                }
            case let .nthWeekday(month, weekday, ordinal):
                if let date = nthWeekdayDate(year: year, month: month, weekday: weekday, ordinal: ordinal) {
                    dated.append((date, order, festival))
                }
            case .lunar, .lunarNewYearEve:
                break
            }
        }

        // 农历节日逐日换算一次全年（含次年 1 月 1 日，用于判定 12 月 31 日是否为除夕）。
        guard var day = gregorian.date(from: DateComponents(year: year, month: 1, day: 1)) else {
            return YearFestivals(sorted: [], byDay: [:])
        }
        var current = chinese.dateComponents([.month, .day], from: day)
        while gregorian.component(.year, from: day) == year,
              let next = gregorian.date(byAdding: .day, value: 1, to: day) {
            let following = chinese.dateComponents([.month, .day], from: next)
            for (order, festival) in FestivalCatalog.all.enumerated() {
                switch festival.rule {
                case let .lunar(month, dayOfMonth):
                    if current.isLeapMonth != true, current.month == month, current.day == dayOfMonth {
                        dated.append((day, order, festival))
                    }
                case .lunarNewYearEve:
                    if following.isLeapMonth != true, following.month == 1, following.day == 1 {
                        dated.append((day, order, festival))
                    }
                case .solar, .nthWeekday:
                    break
                }
            }
            day = next
            current = following
        }

        let sorted = dated
            .sorted { ($0.date, $0.order) < ($1.date, $1.order) }
            .map { DatedFestival(date: $0.date, festival: $0.festival) }
        let byDay = Dictionary(grouping: sorted) { gregorian.startOfDay(for: $0.date) }
            .mapValues { $0.map(\.festival) }
        return YearFestivals(sorted: sorted, byDay: byDay)
    }

    private static func nthWeekdayDate(year: Int, month: Int, weekday: Int, ordinal: Int) -> Date? {
        guard let firstOfMonth = gregorian.date(from: DateComponents(year: year, month: month, day: 1)) else {
            return nil
        }
        let firstWeekday = gregorian.component(.weekday, from: firstOfMonth)
        let offset = ((weekday - firstWeekday) % 7 + 7) % 7 + (ordinal - 1) * 7
        return gregorian.date(byAdding: .day, value: offset, to: firstOfMonth)
    }
}
