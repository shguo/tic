import SwiftUI

struct CalendarLunarCardView: View {
    let selectedDate: Date
    let showsYiJi: Bool
    let palette: CalendarPalette

    @State private var isYiJiDetailPresented = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text(ChineseCalendarSupport.lunarMonthDayLabel(for: selectedDate))
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(palette.accent)
                    .contentTransition(.numericText())

                Text(ChineseCalendarSupport.lunarDetailMeta(for: selectedDate))
                    .font(.system(size: 13))
                    .foregroundStyle(palette.secondaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }
            .frame(height: CalendarPopoverLayout.lunarCardHeight - 20)

            if showsYiJi {
                yiJiSection
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .frame(height: CalendarPopoverLayout.lunarCardHeight(showsYiJi: showsYiJi))
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(palette.cardBackground, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .shadow(color: palette.shadow, radius: 0, x: 0, y: 1)
        .onChange(of: selectedDate) {
            isYiJiDetailPresented = false
        }
    }

    /// 农历下方：宜 / 忌各一行，只放能完整显示的事项；点击弹出完整列表。
    private var yiJiSection: some View {
        let yiJi = ChineseCalendarSupport.dayYiJi(for: selectedDate)
        return VStack(alignment: .leading, spacing: 0) {
            palette.separator
                .frame(height: 1)
                .padding(.vertical, CalendarPopoverLayout.yiJiSeparatorSpacing)
            Button {
                isYiJiDetailPresented.toggle()
            } label: {
                VStack(alignment: .leading, spacing: CalendarPopoverLayout.yiJiRowSpacing) {
                    CalendarYiJiSummaryRow(label: "宜", items: yiJi.yi, tint: palette.solarTermText, palette: palette)
                    CalendarYiJiSummaryRow(label: "忌", items: yiJi.ji, tint: palette.festivalText, palette: palette)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("查看完整宜忌")
            .accessibilityLabel("宜：\(yiJi.yi.joined(separator: "、"))；忌：\(yiJi.ji.joined(separator: "、"))")
            .accessibilityHint("查看完整宜忌")
            .popover(isPresented: $isYiJiDetailPresented, arrowEdge: .bottom) {
                CalendarYiJiDetailView(date: selectedDate, yiJi: yiJi, palette: palette)
            }
        }
        .frame(height: CalendarPopoverLayout.yiJiHeight, alignment: .top)
    }
}

private struct CalendarYiJiBadge: View {
    let label: String
    let tint: Color
    var size: CGFloat = 13
    var weight: Font.Weight = .semibold

    var body: some View {
        Text(label)
            .font(.system(size: size, weight: weight))
            .foregroundStyle(tint)
    }
}

private struct CalendarYiJiSummaryRow: View {
    let label: String
    let items: [String]
    let tint: Color
    let palette: CalendarPalette

    var body: some View {
        HStack(spacing: 8) {
            CalendarYiJiBadge(label: label, tint: tint.opacity(0.8), size: 11, weight: .medium)
                .frame(width: CalendarPopoverLayout.yiJiRowHeight, alignment: .leading)
            // 按黄历原顺序能放几项放几项，始终只显示完整的词；完整列表点击查看
            ViewThatFits(in: .horizontal) {
                ForEach(Array(stride(from: items.count, through: 1, by: -1)), id: \.self) { count in
                    Text(items.prefix(count).joined(separator: "  "))
                        .font(.system(size: 11))
                        .foregroundStyle(palette.secondaryText)
                        .lineLimit(1)
                        .fixedSize()
                }
            }
        }
        .frame(height: CalendarPopoverLayout.yiJiRowHeight)
    }
}

/// 点击宜忌后弹出的完整列表，样式与年月选择弹层一致。
struct CalendarYiJiDetailView: View {
    let date: Date
    let yiJi: DayYiJi
    let palette: CalendarPalette

    @AppStorage(AppSettings.appThemeKey) private var appThemeRaw = AppTheme.system.rawValue

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text(ChineseCalendarSupport.lunarMonthDayLabel(for: date))
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(palette.primaryText)
                Spacer()
                Text("仅供参考")
                    .font(.system(size: 11))
                    .foregroundStyle(palette.secondaryText)
            }
            section(label: "宜", items: yiJi.yi, tint: palette.solarTermText)
            section(label: "忌", items: yiJi.ji, tint: palette.festivalText)
        }
        .padding(14)
        .frame(width: 280, alignment: .leading)
        .background(palette.cardBackground, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .preferredColorScheme(AppTheme(rawValue: appThemeRaw)?.colorScheme)
    }

    private func section(label: String, items: [String], tint: Color) -> some View {
        HStack(alignment: .top, spacing: 10) {
            CalendarYiJiBadge(label: label, tint: tint)
            CalendarFlowLayout(horizontalSpacing: 12, verticalSpacing: 8) {
                ForEach(items, id: \.self) { item in
                    Text(item)
                        .font(.system(size: 13))
                        .foregroundStyle(palette.primaryText)
                }
            }
        }
    }
}

/// 按行从左到右排列，放不下时换行。
private struct CalendarFlowLayout: Layout {
    let horizontalSpacing: CGFloat
    let verticalSpacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        let frames = arrange(subviews: subviews, maxWidth: maxWidth)
        let width = frames.map(\.maxX).max() ?? 0
        let height = frames.map(\.maxY).max() ?? 0
        return CGSize(width: proposal.width ?? width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let frames = arrange(subviews: subviews, maxWidth: bounds.width)
        for (subview, frame) in zip(subviews, frames) {
            subview.place(
                at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY),
                proposal: ProposedViewSize(frame.size)
            )
        }
    }

    private func arrange(subviews: Subviews, maxWidth: CGFloat) -> [CGRect] {
        var frames: [CGRect] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var lineHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0, x + size.width > maxWidth {
                x = 0
                y += lineHeight + verticalSpacing
                lineHeight = 0
            }
            frames.append(CGRect(origin: CGPoint(x: x, y: y), size: size))
            x += size.width + horizontalSpacing
            lineHeight = max(lineHeight, size.height)
        }
        return frames
    }
}
