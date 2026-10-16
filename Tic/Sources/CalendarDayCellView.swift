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
    let subtitle: String
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

                        Text(subtitle)
                            .font(.system(size: Self.subtitleFontSize))
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
                        .foregroundStyle(.white)
                        .frame(width: 17, height: 17)
                        .background(badge == .rest ? palette.restBadge : palette.workBadge, in: Circle())
                        .offset(x: 1, y: -1)
                }
            }
            .frame(maxWidth: .infinity)
            .opacity(isInDisplayedMonth ? 1 : Self.outsideMonthOpacity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private static let outsideMonthOpacity: CGFloat = 0.35

    // 格高固定为 `CalendarPopoverLayout.gridCellHeight`（46pt），以下尺寸按它排布。
    private static let dayNumberFontSize: CGFloat = 20
    private static let subtitleFontSize: CGFloat = 11
    private static let subtitleHeight: CGFloat = 12
    private static let dotBottomPadding: CGFloat = 3

    private var cellBackground: Color {
        if isToday { return palette.accent }
        switch badge {
        case .rest: return palette.holidayBackground
        case .work: return palette.workdayBackground
        case nil: return .clear
        }
    }

    private var dayTextColor: Color {
        if isToday { return .white }
        if isWeekend || badge == .rest { return palette.accent }
        return palette.primaryText
    }

    private var subtitleTextColor: Color {
        isToday ? Color.white.opacity(0.94) : palette.secondaryText
    }

    private var dotColor: Color {
        isToday ? Color.white.opacity(0.78) : palette.dot
    }

    private var accessibilityLabel: String {
        "\(monthNumber)月\(dayNumber)日，\(subtitle)"
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
            && lhs.showAnnotationDot == rhs.showAnnotationDot
            && lhs.subtitle == rhs.subtitle
            && lhs.badge == rhs.badge
            && lhs.isInDisplayedMonth == rhs.isInDisplayedMonth
    }
}
