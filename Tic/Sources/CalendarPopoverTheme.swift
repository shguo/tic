import SwiftUI

enum CalendarPopoverLayout {
    static let width: CGFloat = 397

    // MARK: - 弹窗各区块尺寸（全部固定）
    //
    // 定制版：月历固定 6 行、「后续提醒」固定 3 行、缺数据提示放在标题行，
    // 弹窗总高 `popoverHeight` 只取决于「显示宜忌」开关，切换月份时窗口与各区块都不改变尺寸。
    // 改动任何区块的字号 / 间距时同步改这里；`CalendarPopoverLayoutTests` 会校验与实际排版一致。

    static let gridRows = CalendarMonthBuilder.monthGridSlotCount / 7
    static let gridCellHeight: CGFloat = 46
    static let gridRowSpacing: CGFloat = 10
    static let gridHeight = CGFloat(gridRows) * gridCellHeight + CGFloat(gridRows - 1) * gridRowSpacing

    static let headerTopPadding: CGFloat = 8
    static let headerHeight: CGFloat = 40
    static let headerBottomPadding: CGFloat = 16

    static let weekdayRowHeight: CGFloat = 18
    static let weekdayRowBottomPadding: CGFloat = 12

    static let detailsTopSpacing: CGFloat = 14
    static let detailsVerticalPadding: CGFloat = 10
    static let detailsCardSpacing: CGFloat = 12
    static let lunarCardHeight: CGFloat = 72
    /// 农历卡片下方「宜 / 忌」两行：分隔线（上下各留 4）+ 两行 + 行距。
    static let yiJiSeparatorSpacing: CGFloat = 4
    static let yiJiRowHeight: CGFloat = 18
    static let yiJiRowSpacing: CGFloat = 4
    static let yiJiHeight = yiJiSeparatorSpacing * 2 + 1 + yiJiRowHeight * 2 + yiJiRowSpacing

    static func lunarCardHeight(showsYiJi: Bool) -> CGFloat {
        lunarCardHeight + (showsYiJi ? yiJiHeight : 0)
    }

    static let upcomingRowHeight: CGFloat = 65
    static let upcomingDividerHeight: CGFloat = 1
    static let upcomingVisibleRows = 3
    /// 「后续提醒」卡片固定按 3 行（含分隔线）占高，条目不足时不收缩。
    static let upcomingListHeight = CGFloat(upcomingVisibleRows) * upcomingRowHeight
        + CGFloat(upcomingVisibleRows - 1) * upcomingDividerHeight

    /// 弹窗总高（只随「显示宜忌」开关变化，切换月份 / 日期时不变）。
    static func popoverHeight(showsYiJi: Bool) -> CGFloat {
        let header = headerTopPadding + headerHeight + headerBottomPadding
        let weekday = weekdayRowHeight + weekdayRowBottomPadding
        let details = detailsTopSpacing + detailsVerticalPadding * 2 + lunarCardHeight(showsYiJi: showsYiJi)
            + detailsCardSpacing + upcomingListHeight
        return header + weekday + gridHeight + details
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
                festivalText: Color(red: 1.0, green: 0.45, blue: 0.42),
                solarTermText: Color(red: 0.38, green: 0.80, blue: 0.52),
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
                festivalText: Color(red: 0.86, green: 0.20, blue: 0.18),
                solarTermText: Color(red: 0.10, green: 0.56, blue: 0.30),
                separator: Color.black.opacity(0.08),
                shadow: Color.black.opacity(0.05)
            )
        }
    }
}
