import SwiftUI

struct CalendarDayCellView: View {
    let date: Date
    let monthNumber: Int
    let dayNumber: Int
    let isToday: Bool
    let isWeekend: Bool
    let isSelected: Bool
    let palette: CalendarPalette
    let showAnnotationDot: Bool
    let subtitle: DaySubtitle
    let badge: DayBadge?
    /// 为 false 时是首尾补齐的上月 / 下月日期：整格淡化显示，点击会跳到该月。
    let isInDisplayedMonth: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            ZStack(alignment: .topTrailing) {
                ZStack(alignment: .bottom) {
                    VStack(spacing: 0) {
                        Text(String(dayNumber))
                            .font(.system(size: Self.dayNumberFontSize, weight: .semibold))
                            .foregroundStyle(dayTextColor)
                            .monospacedDigit()
                            .contentTransition(.numericText())

                        Text(subtitle.text)
                            .font(.system(size: Self.subtitleFontSize, weight: subtitleWeight))
                            .foregroundStyle(subtitleTextColor)
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)
                            .frame(height: Self.subtitleHeight)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(maxHeight: .infinity, alignment: .top)

                    if showAnnotationDot {
                        Circle()
                            .fill(dotColor)
                            .frame(width: 4, height: 4)
                            .padding(.bottom, Self.dotBottomPadding)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: CalendarPopoverLayout.gridCellHeight)
                .background(cellBackground, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(isSelected && !isToday ? palette.accent : Color.clear, lineWidth: 2)
                }

                if let badge {
                    Text(badge.rawValue)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(badgeForeground(badge))
                        .frame(width: 17, height: 17)
                        .background(badgeBackground(badge), in: Circle())
                        .offset(x: 1, y: -1)
                }
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    /// 首尾补齐的上月 / 下月日期：淡化以区分本月，但仍需看得清。
    /// 淡化只作用在颜色上，不用视图级 `.opacity`：后者会把整格先画进离屏图层再合成，文字抗锯齿变差、显得发虚。
    private static let outsideMonthOpacity: CGFloat = 0.55

    private var fade: CGFloat { isInDisplayedMonth ? 1 : Self.outsideMonthOpacity }

    /// 「休 / 班」角标：本月为实心色圆 + 白字；上月 / 下月改为浅色圆底 + 彩色字，
    /// 跨月放假安排仍清楚可读，又与本月角标一眼可分。
    private func badgeTint(_ badge: DayBadge) -> Color {
        badge == .rest ? palette.restBadge : palette.workBadge
    }

    private func badgeForeground(_ badge: DayBadge) -> Color {
        isInDisplayedMonth ? .white : badgeTint(badge).opacity(0.9)
    }

    private func badgeBackground(_ badge: DayBadge) -> Color {
        isInDisplayedMonth ? badgeTint(badge) : badgeTint(badge).opacity(palette.appearance == .dark ? 0.24 : 0.16)
    }

    // 格高固定为 `CalendarPopoverLayout.gridCellHeight`（46pt），以下尺寸按它排布。
    private static let dayNumberFontSize: CGFloat = 20
    private static let subtitleFontSize: CGFloat = 11
    private static let subtitleHeight: CGFloat = 12
    private static let dotBottomPadding: CGFloat = 3

    private var cellBackground: Color {
        if isToday { return palette.accent }
        switch badge {
        case .rest: return palette.holidayBackground.opacity(fade)
        case .work: return palette.workdayBackground.opacity(fade)
        case nil: return .clear
        }
    }

    private var dayTextColor: Color {
        if isToday { return .white }
        if isWeekend || badge == .rest { return palette.accent.opacity(fade) }
        return palette.primaryText.opacity(fade)
    }

    private var subtitleTextColor: Color {
        if isToday { return Color.white.opacity(0.94) }
        // 节日红、节气绿、农历灰：扫一眼即可区分，不必再靠底部圆点
        switch subtitle.kind {
        case .festival: return palette.festivalText.opacity(fade)
        case .solarTerm: return palette.solarTermText.opacity(fade)
        case .lunarDay, .lunarMonthStart: return palette.secondaryText.opacity(fade)
        }
    }

    private var subtitleWeight: Font.Weight {
        switch subtitle.kind {
        case .festival, .solarTerm, .lunarMonthStart: return .medium
        case .lunarDay: return .regular
        }
    }

    private var dotColor: Color {
        isToday ? Color.white.opacity(0.78) : palette.dot.opacity(fade)
    }

    private var accessibilityLabel: String {
        "\(monthNumber)月\(dayNumber)日，\(subtitle.text)"
    }
}

extension CalendarDayCellView: Equatable {
    nonisolated static func == (lhs: CalendarDayCellView, rhs: CalendarDayCellView) -> Bool {
        lhs.date == rhs.date
            && lhs.monthNumber == rhs.monthNumber
            && lhs.dayNumber == rhs.dayNumber
            && lhs.isToday == rhs.isToday
            && lhs.isWeekend == rhs.isWeekend
            && lhs.isSelected == rhs.isSelected
            && lhs.palette.appearance == rhs.palette.appearance
            && lhs.palette.colorTheme == rhs.palette.colorTheme
            && lhs.showAnnotationDot == rhs.showAnnotationDot
            && lhs.subtitle == rhs.subtitle
            && lhs.badge == rhs.badge
            && lhs.isInDisplayedMonth == rhs.isInDisplayedMonth
    }
}
