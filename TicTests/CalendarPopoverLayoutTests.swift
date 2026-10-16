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

    func testGridPadsWithAdjacentMonthDates() {
        // 首尾用上月 / 下月日期补齐：42 格日期连续、首格为周一，当月天数与 isInDisplayedMonth 一致
        let calendar = Calendar.gregorianChineseLocale
        for year in 2026...2027 {
            for month in 1...12 {
                let date = calendar.date(from: DateComponents(year: year, month: month, day: 15))!
                let slots = ChineseCalendarSupport.monthSlots(for: date, showSolarTerms: true)
                let dates = slots.compactMap(\.date)
                XCTAssertEqual(dates.count, slots.count, "\(year)-\(month)")
                XCTAssertEqual(calendar.component(.weekday, from: dates[0]), 2, "首格应为周一 \(year)-\(month)")
                for (prev, next) in zip(dates, dates.dropFirst()) {
                    XCTAssertEqual(calendar.dateComponents([.day], from: prev, to: next).day, 1, "\(year)-\(month)")
                }
                let inMonth = slots.filter(\.isInDisplayedMonth)
                XCTAssertEqual(inMonth.count, calendar.range(of: .day, in: .month, for: date)!.count, "\(year)-\(month)")
                XCTAssertTrue(inMonth.allSatisfy { $0.monthNumber == month }, "\(year)-\(month)")
                XCTAssertTrue(slots.filter { !$0.isInDisplayedMonth }.allSatisfy { $0.monthNumber != month })
            }
        }
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

    func testHeaderFitsWidestContent() {
        // 两位数月份 + 年份 + 三位数相对天数标签 + 缺数据图标，不能超出标题行可用宽度（否则标签会被截断）
        let palette = CalendarPopoverTheme.palette(for: .light)
        for label in ["123天后", "999天后"] {
            let header = CalendarPopoverHeader(
                monthNumber: 12, year: 2027, relativeOffsetLabel: label, nextRestDayCountdownLabel: nil,
                dataCoverageNotice: "2027 年放假安排待更新", palette: palette,
                onShowMonthPicker: {}, onPreviousMonth: {}, onGoToToday: {}, onNextMonth: {}, onShowSettings: {}
            )
            let host = NSHostingView(rootView: header.fixedSize())
            host.layoutSubtreeIfNeeded()
            XCTAssertLessThanOrEqual(host.fittingSize.width, CalendarPopoverLayout.width - 40, label)
        }
    }

    func testBadgeWidthIsFixed() {
        // 天数标签一位到三位数、今天 / 明天 / 昨天，胶囊同宽：标题行总宽一致，后面的图标不挪动
        let palette = CalendarPopoverTheme.palette(for: .light)
        let widths = ["明天", "今天", "5天后", "36天前", "123天后", "999天后", "888天前"].map { label -> CGFloat in
            let header = CalendarPopoverHeader(
                monthNumber: 10, year: 2026, relativeOffsetLabel: label, nextRestDayCountdownLabel: nil,
                dataCoverageNotice: "2027 年放假安排待更新", palette: palette,
                onShowMonthPicker: {}, onPreviousMonth: {}, onGoToToday: {}, onNextMonth: {}, onShowSettings: {}
            )
            let host = NSHostingView(rootView: header.fixedSize())
            host.layoutSubtreeIfNeeded()
            return host.fittingSize.width
        }
        for width in widths {
            XCTAssertEqual(width, widths[0], accuracy: 0.5, "\(widths)")
        }
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
