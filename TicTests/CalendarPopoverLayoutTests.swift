import AppKit
import SwiftUI
import XCTest
@testable import Tic

/// 弹窗高度由 `CalendarPopoverLayout.popoverHeight` 直接算出，窗口按它定高；
/// 这里用 SwiftUI 实际排版校验公式，防止改了字号 / 间距却没同步常量。
@MainActor
final class CalendarPopoverLayoutTests: XCTestCase {
    private func fittingHeight<V: View>(_ view: V) -> CGFloat {
        let host = NSHostingView(rootView: view)
        host.layoutSubtreeIfNeeded()
        return host.fittingSize.height
    }

    func testPopoverHeightMatchesLayout() {
        let calendar = Calendar.gregorianChineseLocale
        let showSolarTerms = UserDefaults.standard.object(forKey: AppSettings.showSolarTermsKey) as? Bool ?? true
        var seenRowCounts = Set<Int>()
        var seenBanner = Set<Bool>()

        for year in 2026...2027 {
            for month in 1...12 {
                let date = calendar.date(from: DateComponents(year: year, month: month, day: 15))!
                let slots = ChineseCalendarSupport.monthSlots(for: date, showSolarTerms: showSolarTerms)
                let rows = CalendarPopoverLayout.gridRowCount(slotCount: slots.count)
                let banner = HolidayStore.shared.isYearUncovered(year)
                let events = ChineseCalendarSupport.upcomingEvents(from: date, limit: 3, includeSolarTerms: showSolarTerms)
                let expected = CalendarPopoverLayout.popoverHeight(
                    gridRowCount: rows,
                    showsDataCoverageBanner: banner,
                    upcomingEventCount: events.count
                )
                let actual = fittingHeight(CalendarPopoverView(initialDate: date).fixedSize())
                XCTAssertEqual(actual, expected, accuracy: 0.5, "\(year)-\(month) rows=\(rows) banner=\(banner)")
                seenRowCounts.insert(rows)
                seenBanner.insert(banner)
            }
        }
        // 覆盖 4 / 5 / 6 行与有无横幅
        XCTAssertEqual(seenRowCounts, [4, 5, 6])
        XCTAssertEqual(seenBanner, [true, false])
    }

    func testUpcomingListHeightMatchesLayout() {
        let palette = CalendarPopoverTheme.palette(for: .light)
        let date = Calendar.gregorianChineseLocale.date(from: DateComponents(year: 2026, month: 10, day: 16))!
        let events = ChineseCalendarSupport.upcomingEvents(from: date, limit: 3, includeSolarTerms: true)
        XCTAssertEqual(events.count, 3)
        for count in 0...3 {
            let list = CalendarUpcomingListView(events: Array(events.prefix(count)), palette: palette)
                .frame(width: CalendarPopoverLayout.width)
            XCTAssertEqual(
                fittingHeight(list),
                CalendarPopoverLayout.upcomingListHeight(eventCount: count),
                accuracy: 0.5,
                "events=\(count)"
            )
        }
    }

    func testKnownPopoverHeights() {
        // 与实测录屏一致：5 行 752、6 行 735；有缺数据横幅时 4 行 718、5 行 790、6 行 773
        func h(_ rows: Int, _ banner: Bool) -> CGFloat {
            CalendarPopoverLayout.popoverHeight(gridRowCount: rows, showsDataCoverageBanner: banner, upcomingEventCount: 3)
        }
        XCTAssertEqual(h(5, false), 752)
        XCTAssertEqual(h(6, false), 735)
        XCTAssertEqual(h(4, true), 718)
        XCTAssertEqual(h(5, true), 790)
        XCTAssertEqual(h(6, true), 773)
    }
}
