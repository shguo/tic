import AppKit
import SwiftUI
import XCTest
@testable import Tic

/// 定制版弹窗各区块尺寸固定：月历 6 行、「后续提醒」3 行、总高恒定。
/// 用 SwiftUI 实际排版校验，防止改了字号 / 间距却没同步 `CalendarPopoverLayout` 常量。
@MainActor
final class CalendarPopoverLayoutTests: XCTestCase {
    private func fittingHeight<V: View>(_ view: V) -> CGFloat {
        let host = NSHostingView(rootView: view)
        host.layoutSubtreeIfNeeded()
        return host.fittingSize.height
    }

    func testEveryMonthUsesSixRowGrid() {
        let calendar = Calendar.gregorianChineseLocale
        for year in 2026...2027 {
            for month in 1...12 {
                let date = calendar.date(from: DateComponents(year: year, month: month, day: 15))!
                let slots = ChineseCalendarSupport.monthSlots(for: date, showSolarTerms: true)
                XCTAssertEqual(slots.count, ChineseCalendarSupport.monthGridSlotCount, "\(year)-\(month)")
                XCTAssertEqual(Set(slots.map(\.id)).count, slots.count, "格子 id 需唯一 \(year)-\(month)")
            }
        }
        XCTAssertEqual(CalendarPopoverLayout.gridRows, 6)
    }

    func testPopoverHeightIsConstantAndMatchesLayout() {
        // 覆盖 4 / 5 / 6 行自然行数的月份，以及缺调休数据的年份（2027）
        let calendar = Calendar.gregorianChineseLocale
        for year in 2026...2027 {
            for month in 1...12 {
                let date = calendar.date(from: DateComponents(year: year, month: month, day: 15))!
                let actual = fittingHeight(CalendarPopoverView(initialDate: date).fixedSize())
                XCTAssertEqual(actual, CalendarPopoverLayout.popoverHeight, accuracy: 0.5, "\(year)-\(month)")
            }
        }
        XCTAssertEqual(CalendarPopoverLayout.popoverHeight, 735)
    }

    func testUpcomingListHeightIsFixed() {
        let palette = CalendarPopoverTheme.palette(for: .light)
        let date = Calendar.gregorianChineseLocale.date(from: DateComponents(year: 2026, month: 10, day: 16))!
        let events = ChineseCalendarSupport.upcomingEvents(from: date, limit: 3, includeSolarTerms: true)
        XCTAssertEqual(events.count, 3)
        for count in 0...3 {
            let list = CalendarUpcomingListView(events: Array(events.prefix(count)), palette: palette)
                .frame(width: CalendarPopoverLayout.width)
            XCTAssertEqual(fittingHeight(list), CalendarPopoverLayout.upcomingListHeight, accuracy: 0.5, "events=\(count)")
        }
    }
}
