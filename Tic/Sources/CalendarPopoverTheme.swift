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
    /// 当前用户选择的配色（`UserDefaults` 未设置时为经典）。
    static var currentColorTheme: AppColorTheme {
        UserDefaults.standard.string(forKey: AppSettings.appColorThemeKey)
            .flatMap(AppColorTheme.init(rawValue:)) ?? .classic
    }

    static func palette(for scheme: ColorScheme, colorTheme: AppColorTheme = .classic) -> CalendarPalette {
        guard let spec = ThemeSpec.spec(for: colorTheme) else {
            return classicPalette(for: scheme)
        }
        return tintedPalette(spec, scheme: scheme)
    }

    // MARK: - 经典：系统强调色 + 中性灰

    private static func classicPalette(for scheme: ColorScheme) -> CalendarPalette {
        switch scheme {
        case .dark:
            CalendarPalette(
                appearance: .dark,
                colorTheme: .classic,
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
                workBadge: defaultWorkBadge,
                dot: Color(red: 0.42, green: 0.42, blue: 0.45),
                festivalText: Color(red: 1.0, green: 0.45, blue: 0.42),
                solarTermText: Color(red: 0.38, green: 0.80, blue: 0.52),
                separator: Color.white.opacity(0.10),
                shadow: Color.black.opacity(0.20)
            )
        default:
            CalendarPalette(
                appearance: .light,
                colorTheme: .classic,
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
                workBadge: defaultWorkBadge,
                dot: Color(red: 0.73, green: 0.73, blue: 0.74),
                festivalText: Color(red: 0.86, green: 0.20, blue: 0.18),
                solarTermText: Color(red: 0.10, green: 0.56, blue: 0.30),
                separator: Color.black.opacity(0.08),
                shadow: Color.black.opacity(0.05)
            )
        }
    }

    private static let defaultWorkBadge = Color(red: 1.0, green: 0.48, blue: 0.10)
    /// 强调色本身偏红 / 橙时，「班」改用石板蓝，避免与「休」撞色。
    private static let slateWorkBadge = Color(red: 0.36, green: 0.44, blue: 0.56)

    // MARK: - 彩色配色：整套界面（背景、卡片、控件、分隔线、文字）按主题色染色

    private static func tintedPalette(_ spec: ThemeSpec, scheme: ColorScheme) -> CalendarPalette {
        let workBadge = spec.slateWorkBadge ? slateWorkBadge : defaultWorkBadge
        switch scheme {
        case .dark:
            let hue = spec.dark
            let accent = hue.color
            return CalendarPalette(
                appearance: .dark,
                colorTheme: spec.theme,
                background: RGB(0.06, 0.06, 0.07).mixed(with: hue, 0.16).color,
                detailsBackground: RGB(0.09, 0.09, 0.10).mixed(with: hue, 0.20).color,
                cardBackground: RGB(0.13, 0.13, 0.14).mixed(with: hue, 0.24).color,
                controlBackground: accent.opacity(0.20),
                controlBorder: accent.opacity(0.32),
                holidayBackground: accent.opacity(0.26),
                workdayBackground: Color.white.opacity(0.08),
                accent: accent,
                primaryText: RGB(0.96, 0.96, 0.97).mixed(with: hue, 0.03).color,
                secondaryText: RGB(0.68, 0.68, 0.70).mixed(with: hue, 0.10).color,
                mutedText: RGB(0.40, 0.40, 0.42).mixed(with: hue, 0.30).color,
                restBadge: accent,
                workBadge: workBadge,
                dot: RGB(0.40, 0.40, 0.42).mixed(with: hue, 0.35).color,
                festivalText: Color(red: 1.0, green: 0.50, blue: 0.46),
                solarTermText: Color(red: 0.42, green: 0.84, blue: 0.56),
                separator: RGB(1, 1, 1).mixed(with: hue, 0.25).color.opacity(0.08),
                shadow: Color.black.opacity(0.30)
            )
        default:
            let hue = spec.light
            let accent = hue.color
            return CalendarPalette(
                appearance: .light,
                colorTheme: spec.theme,
                background: RGB(1, 1, 1).mixed(with: hue, 0.09).color,
                detailsBackground: RGB(1, 1, 1).mixed(with: hue, 0.17).color,
                cardBackground: RGB(1, 1, 1).mixed(with: hue, 0.04).color,
                controlBackground: accent.opacity(0.12),
                controlBorder: accent.opacity(0.24),
                holidayBackground: accent.opacity(0.16),
                workdayBackground: Color.black.opacity(0.05),
                accent: accent,
                primaryText: RGB(0.02, 0.02, 0.02).mixed(with: hue, 0.05).color,
                secondaryText: RGB(0.36, 0.36, 0.38).mixed(with: hue, 0.10).color,
                mutedText: RGB(0.70, 0.70, 0.72).mixed(with: hue, 0.30).color,
                restBadge: accent,
                workBadge: workBadge,
                dot: RGB(0.72, 0.72, 0.74).mixed(with: hue, 0.35).color,
                festivalText: Color(red: 0.84, green: 0.18, blue: 0.16),
                solarTermText: Color(red: 0.08, green: 0.52, blue: 0.28),
                separator: accent.opacity(0.18),
                shadow: hue.mixed(with: RGB(0, 0, 0), 0.5).color.opacity(0.12)
            )
        }
    }
}

private struct RGB {
    let r: Double
    let g: Double
    let b: Double

    init(_ r: Double, _ g: Double, _ b: Double) {
        self.r = r
        self.g = g
        self.b = b
    }

    func mixed(with other: RGB, _ amount: Double) -> RGB {
        RGB(r + (other.r - r) * amount, g + (other.g - g) * amount, b + (other.b - b) * amount)
    }

    var color: Color { Color(red: r, green: g, blue: b) }
}

/// 每套彩色配色的强调色（浅 / 深两版）。「今天」格是白字压强调色，强调色需足够深。
private struct ThemeSpec {
    let theme: AppColorTheme
    let light: RGB
    let dark: RGB
    var slateWorkBadge = false

    static func spec(for theme: AppColorTheme) -> ThemeSpec? {
        switch theme {
        case .classic: nil
        case .vermilion: ThemeSpec(theme: .vermilion, light: RGB(0.80, 0.20, 0.16), dark: RGB(0.90, 0.32, 0.27), slateWorkBadge: true)
        case .jade: ThemeSpec(theme: .jade, light: RGB(0.04, 0.53, 0.48), dark: RGB(0.12, 0.64, 0.57))
        case .indigo: ThemeSpec(theme: .indigo, light: RGB(0.16, 0.31, 0.62), dark: RGB(0.33, 0.50, 0.86))
        case .amber: ThemeSpec(theme: .amber, light: RGB(0.78, 0.45, 0.04), dark: RGB(0.86, 0.55, 0.12), slateWorkBadge: true)
        case .sakura: ThemeSpec(theme: .sakura, light: RGB(0.84, 0.30, 0.48), dark: RGB(0.88, 0.42, 0.58))
        case .wisteria: ThemeSpec(theme: .wisteria, light: RGB(0.46, 0.33, 0.74), dark: RGB(0.58, 0.46, 0.88))
        }
    }
}
