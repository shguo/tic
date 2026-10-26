import XCTest
@testable import Tic

/// 设备时区不是东八区时，弹窗看到的日期应与东八区用户一致（按「墙上日期」对齐）。
/// 模拟界面实际调用路径：`CalendarPopoverSelection.today` 取今天 → 月历 / 农历卡片 / 选中高亮。
@MainActor
final class TimeZoneTests: XCTestCase {
    private func instant(_ iso: String) -> Date {
        ISO8601DateFormatter().date(from: iso)!
    }

    /// 与 `CalendarMonthGridView` 相同：界面用该 key 判断选中 / 今天。
    private func uiDayID(_ date: Date) -> String {
        BeijingCalendar.dateKey(date)
    }

    private func checkPopover(
        timeZone identifier: String,
        now iso: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let savedTimeZone = NSTimeZone.default
        NSTimeZone.default = TimeZone(identifier: identifier)!
        defer { NSTimeZone.default = savedTimeZone }
        XCTAssertEqual(Calendar(identifier: .gregorian).timeZone.identifier, identifier, file: file, line: line)

        // 各时区传入的时刻在当地都是 2026-10-01
        let now = instant(iso)
        let today = CalendarPopoverSelection.today(now: now)
        let slots = CalendarMonthBuilder.monthSlots(for: today.displayedMonth)
        let monthsShown = Set(slots.filter(\.isInDisplayedMonth).map(\.monthNumber))
        XCTAssertEqual(monthsShown, [10], "\(identifier) 月历应显示 10 月", file: file, line: line)
        XCTAssertEqual(uiDayID(today.selectedDate), "2026-10-01", "\(identifier) 今天", file: file, line: line)
        XCTAssertTrue(slots.contains { $0.id == uiDayID(today.selectedDate) }, "\(identifier) 今天的格子应能高亮", file: file, line: line)
        XCTAssertEqual(
            ChineseCalendarSupport.lunarMonthDayLabel(for: today.selectedDate), "八月廿一",
            "\(identifier) 农历卡片", file: file, line: line
        )
        XCTAssertEqual(
            ChineseCalendarSupport.relativeDayLabel(for: today.selectedDate, relativeTo: now), "今天",
            "\(identifier) 头部相对日期", file: file, line: line
        )
        XCTAssertEqual(
            MenuBarDisplayComposer.compose(
                date: now, order: [.date, .lunar], enabled: [.date, .lunar], showSeconds: false, use24Hour: true
            ),
            "10月1日 八月廿一",
            "\(identifier) 菜单栏日期与农历", file: file, line: line
        )

        // 点击 10/18 格子：选中高亮应落在 10/18，农历卡片为九月初九
        let oct18 = slots.first { $0.id == "2026-10-18" }!
        XCTAssertEqual(uiDayID(oct18.date), "2026-10-18", "\(identifier) 点击 10/18 后的选中高亮", file: file, line: line)
        XCTAssertEqual(
            ChineseCalendarSupport.lunarMonthDayLabel(for: oct18.date), "九月初九",
            "\(identifier) 点击 10/18 后的农历卡片", file: file, line: line
        )
    }

    func testTokyo() {
        // 东京 00:30 = 北京前一天 23:30
        checkPopover(timeZone: "Asia/Tokyo", now: "2026-10-01T00:30:00+09:00")
        checkPopover(timeZone: "Asia/Tokyo", now: "2026-10-01T23:30:00+09:00")
    }

    func testLosAngeles() {
        // 洛杉矶 17:00 = 北京次日 08:00
        checkPopover(timeZone: "America/Los_Angeles", now: "2026-10-01T00:30:00-07:00")
        checkPopover(timeZone: "America/Los_Angeles", now: "2026-10-01T17:00:00-07:00")
    }

    func testShanghai() {
        checkPopover(timeZone: "Asia/Shanghai", now: "2026-10-01T09:00:00+08:00")
    }
}
