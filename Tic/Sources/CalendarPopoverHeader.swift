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
    let isPinned: Bool
    let onShowMonthPicker: () -> Void
    let onPreviousMonth: () -> Void
    let onGoToToday: () -> Void
    let onNextMonth: () -> Void
    let onTogglePin: () -> Void
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
        HStack(alignment: .center, spacing: 8) {
            HStack(alignment: .lastTextBaseline, spacing: 6) {
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

            HStack(spacing: 8) {
                monthNavigationControl
                toolControl
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
                    .frame(width: 26, height: 24)
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
                .frame(width: 24, height: 24)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
        .help(accessibilityLabel)
    }

    /// 钉住 + 设置，与月份切换同款胶囊：标题行宽度有限，合并后比两个独立圆形按钮更省空间。
    private var toolControl: some View {
        HStack(spacing: 0) {
            pinButton

            divider

            toolButton(
                systemName: "gearshape.fill",
                accessibilityLabel: "打开设置",
                action: onShowSettings
            )
        }
        .foregroundStyle(palette.primaryText)
        .background(palette.controlBackground, in: Capsule())
        .overlay {
            Capsule().strokeBorder(palette.controlBorder)
        }
    }

    /// 通用约定：图钉 45° 倾斜 = 未钉住，竖直插下 = 已钉住。
    /// SF Symbols 的 `pin` 本身竖直（针尖朝下）：钉住时原样，未钉住时顺时针转 45°（针尖朝左下）。
    private var pinButton: some View {
        let label = isPinned ? "取消钉住" : "钉住：点击其他应用时不收起"
        return Button(action: onTogglePin) {
            Image(systemName: isPinned ? "pin.fill" : "pin")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(isPinned ? palette.accent : palette.primaryText)
                .rotationEffect(.degrees(isPinned ? 0 : 45))
                // 图钉字形上重下轻、旋转后重心再偏移：按截图实测的视觉重心（像素墨量加权）
                // 对到按钮中心，并与齿轮重心同高。改字号 / 字重后需重新测量。
                .offset(x: isPinned ? 0.5 : -0.75, y: isPinned ? 1.15 : 1.1)
                .animation(.easeOut(duration: 0.15), value: isPinned)
                .frame(width: 24, height: 24)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .help(label)
    }

    private func toolButton(
        systemName: String,
        accessibilityLabel: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(palette.primaryText)
                .frame(width: 24, height: 24)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
        .help(accessibilityLabel)
    }
}
