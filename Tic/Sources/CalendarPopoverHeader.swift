import AppKit
import SwiftUI

struct CalendarPopoverHeader: View {
    let monthNumber: Int
    let year: Int
    let relativeOffsetLabel: String?
    let nextRestDayCountdownLabel: String?
    /// 当前查看年份缺少内置调休数据时的提示；以小图标 + 悬停提示显示在标题行末尾，不占额外行高、不推动其他元素。
    let dataCoverageNotice: String?
    let palette: CalendarPalette
    let onShowMonthPicker: () -> Void
    let onPreviousMonth: () -> Void
    let onGoToToday: () -> Void
    let onNextMonth: () -> Void
    let onShowSettings: () -> Void

    private static let monthFontSize: CGFloat = 34

    /// 两位数月份在等宽数字下的宽度（所有两位数宽度相同，以「88月」量取）。
    static let monthLabelWidth: CGFloat = {
        let font = NSFont.monospacedDigitSystemFont(ofSize: monthFontSize, weight: .medium)
        return ceil(("88月" as NSString).size(withAttributes: [.font: font]).width)
    }()

    private static let badgeFontSize: CGFloat = 10
    private static let badgeHorizontalPadding: CGFloat = 7

    /// 天数标签按三位数（「999天后」）等宽数字预留宽度：「5天后」与「123天后」胶囊一样宽，后面的图标不再左右挪动。
    /// 超过三位数时按实际内容撑开。
    static let badgeTextWidth: CGFloat = {
        let font = NSFont.monospacedDigitSystemFont(ofSize: badgeFontSize, weight: .medium)
        return ceil(("999天后" as NSString).size(withAttributes: [.font: font]).width)
    }()

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            HStack(alignment: .lastTextBaseline, spacing: 8) {
                Button(action: onShowMonthPicker) {
                    Text("\(monthNumber)月")
                        .font(.system(size: Self.monthFontSize, weight: .medium))
                        .monospacedDigit()
                        .foregroundStyle(palette.primaryText)
                        .contentTransition(.numericText())
                        // 等宽数字 + 按两位数预留宽度、靠右对齐：「月」字与后面的年份、标签位置固定，
                        // 一位数月份左侧空出一个数字宽度。
                        .frame(width: Self.monthLabelWidth, alignment: .trailing)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("选择月份")

                Button(action: onShowMonthPicker) {
                    Text(String(year))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(palette.secondaryText)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                        .fixedSize()
                }
                .buttonStyle(.plain)
                .accessibilityLabel("选择年份")

                if let relativeOffsetLabel {
                    badge(relativeOffsetLabel)
                        .accessibilityLabel("相对今天\(relativeOffsetLabel)")
                } else if let nextRestDayCountdownLabel {
                    badge(nextRestDayCountdownLabel)
                        .accessibilityLabel("距离\(nextRestDayCountdownLabel)")
                }

                if let dataCoverageNotice {
                    Image(systemName: "exclamationmark.circle")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(palette.secondaryText)
                        .help(dataCoverageNotice)
                        .accessibilityLabel(dataCoverageNotice)
                }
            }
            .layoutPriority(1)

            Spacer(minLength: 0)

            HStack(spacing: 10) {
                monthNavigationControl

                headerIconButton(
                    systemName: "gearshape.fill",
                    accessibilityLabel: "打开设置",
                    action: onShowSettings
                )
            }
        }
    }

    private func badge(_ text: String) -> some View {
        Text(text)
            .font(.system(size: Self.badgeFontSize, weight: .medium))
            .monospacedDigit()
            .foregroundStyle(palette.accent)
            .fixedSize()
            .frame(minWidth: Self.badgeTextWidth)
            .padding(.horizontal, Self.badgeHorizontalPadding)
            .frame(height: 16)
            .background(palette.accent.opacity(0.10), in: Capsule())
            .overlay {
                Capsule().strokeBorder(palette.accent.opacity(0.18))
            }
    }

    private var monthNavigationControl: some View {
        HStack(spacing: 0) {
            monthNavigationButton(
                systemName: "chevron.left",
                accessibilityLabel: "上个月",
                action: onPreviousMonth
            )

            divider

            Button(action: onGoToToday) {
                Text("今")
                    .font(.system(size: 11, weight: .semibold))
                    .frame(width: 30, height: 24)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("回到今天")
            .help("回到今天")

            divider

            monthNavigationButton(
                systemName: "chevron.right",
                accessibilityLabel: "下个月",
                action: onNextMonth
            )
        }
        .foregroundStyle(palette.primaryText)
        .background(palette.controlBackground, in: Capsule())
        .overlay {
            Capsule().strokeBorder(palette.controlBorder)
        }
    }

    private var divider: some View {
        Rectangle()
            .fill(palette.controlBorder)
            .frame(width: 1, height: 14)
            .accessibilityHidden(true)
    }

    private func monthNavigationButton(
        systemName: String,
        accessibilityLabel: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 10, weight: .bold))
                .frame(width: 27, height: 24)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
        .help(accessibilityLabel)
    }

    private func headerIconButton(
        systemName: String,
        accessibilityLabel: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(palette.primaryText)
                .frame(width: 24, height: 24)
                .background(palette.controlBackground, in: Circle())
                .overlay {
                    Circle().strokeBorder(palette.controlBorder)
                }
        }
        .buttonStyle(.plain)
        .contentShape(Circle())
        .accessibilityLabel(accessibilityLabel)
        .help(accessibilityLabel)
    }
}
