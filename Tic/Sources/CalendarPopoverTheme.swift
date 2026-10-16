import SwiftUI

enum CalendarPopoverLayout {
    static let width: CGFloat = 397

    static let fiveRowCellHeight: CGFloat = 55
    static let fiveRowSpacing: CGFloat = 17
    static let sixRowCellHeight: CGFloat = 46
    static let sixRowSpacing: CGFloat = 10

    static func gridHeight(rowCount: Int) -> CGFloat {
        guard rowCount > 0 else { return 0 }
        if rowCount > 5 {
            return CGFloat(rowCount) * sixRowCellHeight + CGFloat(rowCount - 1) * sixRowSpacing
        }
        return CGFloat(rowCount) * fiveRowCellHeight + CGFloat(rowCount - 1) * fiveRowSpacing
    }

    static let maxGridHeight = max(gridHeight(rowCount: 5), gridHeight(rowCount: 6))

    static func gridRowCount(slotCount: Int) -> Int {
        Int(ceil(Double(slotCount) / 7.0))
    }

    // MARK: - 弹窗各区块高度
    //
    // 弹窗总高由下列常量直接算出（`popoverHeight`），视图按同一组常量显式定高，
    // 窗口尺寸与内容在同一次更新里一起变化（见 `PopoverWindowSizer`），不再等系统事后推算。
    // 改动任何区块的字号 / 间距时，同步改这里；`testPopoverHeightMatchesLayout` 会校验二者一致。

    static let headerTopPadding: CGFloat = 8
    static let headerHeight: CGFloat = 40
    static let headerBottomPadding: CGFloat = 16

    static let dataCoverageBannerHeight: CGFloat = 26
    static let dataCoverageBannerBottomPadding: CGFloat = 12

    static let weekdayRowHeight: CGFloat = 18
    static let weekdayRowBottomPadding: CGFloat = 12

    static let detailsTopSpacing: CGFloat = 14
    static let detailsVerticalPadding: CGFloat = 10
    static let detailsCardSpacing: CGFloat = 12
    static let lunarCardHeight: CGFloat = 72

    static let upcomingRowHeight: CGFloat = 65
    static let upcomingDividerHeight: CGFloat = 1

    /// 「后续提醒」卡片高度；无条目时显示一行占位文案。
    static func upcomingListHeight(eventCount: Int) -> CGFloat {
        let rows = max(eventCount, 1)
        return CGFloat(rows) * upcomingRowHeight + CGFloat(rows - 1) * upcomingDividerHeight
    }

    static func popoverHeight(gridRowCount: Int, showsDataCoverageBanner: Bool, upcomingEventCount: Int) -> CGFloat {
        let header = headerTopPadding + headerHeight + headerBottomPadding
        let banner = showsDataCoverageBanner ? dataCoverageBannerHeight + dataCoverageBannerBottomPadding : 0
        let weekday = weekdayRowHeight + weekdayRowBottomPadding
        let details = detailsTopSpacing + detailsVerticalPadding * 2 + lunarCardHeight + detailsCardSpacing
            + upcomingListHeight(eventCount: upcomingEventCount)
        return header + banner + weekday + gridHeight(rowCount: gridRowCount) + details
    }
}

enum CalendarPopoverTheme {
    static func palette(for scheme: ColorScheme) -> CalendarPalette {
        switch scheme {
        case .dark:
            CalendarPalette(
                appearance: .dark,
                background: Color(red: 0.07, green: 0.07, blue: 0.08),
                detailsBackground: Color(red: 0.11, green: 0.11, blue: 0.12),
                cardBackground: Color(red: 0.15, green: 0.15, blue: 0.17),
                controlBackground: Color.white.opacity(0.10),
                controlBorder: Color.white.opacity(0.14),
                holidayBackground: Color.accentColor.opacity(0.20),
                workdayBackground: Color.white.opacity(0.08),
                accent: Color.accentColor,
                primaryText: Color(red: 0.96, green: 0.96, blue: 0.97),
                secondaryText: Color(red: 0.65, green: 0.65, blue: 0.68),
                mutedText: Color.white.opacity(0.30),
                restBadge: Color.accentColor,
                workBadge: Color(red: 1.0, green: 0.48, blue: 0.10),
                dot: Color(red: 0.42, green: 0.42, blue: 0.45),
                separator: Color.white.opacity(0.10),
                shadow: Color.black.opacity(0.20)
            )
        default:
            CalendarPalette(
                appearance: .light,
                background: .white,
                detailsBackground: Color(red: 0.96, green: 0.96, blue: 0.96),
                cardBackground: .white,
                controlBackground: Color.black.opacity(0.04),
                controlBorder: Color.black.opacity(0.08),
                holidayBackground: Color.accentColor.opacity(0.10),
                workdayBackground: Color.black.opacity(0.04),
                accent: Color.accentColor,
                primaryText: Color(red: 0.02, green: 0.02, blue: 0.02),
                secondaryText: Color(red: 0.38, green: 0.38, blue: 0.40),
                mutedText: Color.black.opacity(0.28),
                restBadge: Color.accentColor,
                workBadge: Color(red: 1.0, green: 0.48, blue: 0.10),
                dot: Color(red: 0.73, green: 0.73, blue: 0.74),
                separator: Color.black.opacity(0.08),
                shadow: Color.black.opacity(0.05)
            )
        }
    }
}
