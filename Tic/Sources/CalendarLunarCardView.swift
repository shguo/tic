import SwiftUI

struct CalendarLunarCardView: View {
    let selectedDate: Date
    let showsYiJi: Bool
    let palette: CalendarPalette

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
    }

    /// 农历下方：宜 / 忌各一行；放不下的部分可左右滚动查看，不再弹出浮层。
    private var yiJiSection: some View {
        let yiJi = ChineseCalendarSupport.dayYiJi(for: selectedDate)
        return VStack(alignment: .leading, spacing: 0) {
            palette.separator
                .frame(height: 1)
                .padding(.vertical, CalendarPopoverLayout.yiJiSeparatorSpacing)
            CalendarYiJiScrollRows(yi: yiJi.yi, ji: yiJi.ji, palette: palette)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("宜：\(yiJi.yi.joined(separator: "、"))；忌：\(yiJi.ji.joined(separator: "、"))")
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

/// 宜 / 忌两行共用一个横向滚动区，一起滚动；标签固定在左侧。
/// 放不下时可横向滚动（触控板左右滑 / Shift + 滚轮），两端用卡片底色渐变遮住，提示还有内容。
private struct CalendarYiJiScrollRows: View {
    let yi: [String]
    let ji: [String]
    let palette: CalendarPalette

    /// 内容在可视区坐标系中的位置，与可视区宽度一起算出左右各溢出多少。
    @State private var contentFrame: CGRect = .zero
    @State private var viewportWidth: CGFloat = 0

    private var leadingOverflow: CGFloat { max(0, -contentFrame.minX) }
    private var trailingOverflow: CGFloat {
        viewportWidth > 0 ? max(0, contentFrame.maxX - viewportWidth) : 0
    }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: CalendarPopoverLayout.yiJiRowSpacing) {
                badge("宜", tint: palette.solarTermText)
                badge("忌", tint: palette.festivalText)
            }
            .frame(width: CalendarPopoverLayout.yiJiRowHeight, alignment: .leading)

            ScrollView(.horizontal, showsIndicators: false) {
                VStack(alignment: .leading, spacing: CalendarPopoverLayout.yiJiRowSpacing) {
                    itemsText(yi)
                    itemsText(ji)
                }
                .onGeometryChange(for: CGRect.self) { proxy in
                    proxy.frame(in: .named(Self.space))
                } action: { contentFrame = $0 }
            }
            .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
            .coordinateSpace(.named(Self.space))
            .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { viewportWidth = $0 }
            .overlay(alignment: .leading) { fade(edge: .leading, distance: leadingOverflow) }
            .overlay(alignment: .trailing) { fade(edge: .trailing, distance: trailingOverflow) }
            // 换一天时回到行首
            .id(yi + ji)
        }
    }

    private static let fadeWidth: CGFloat = 36
    private static let space = "yiJiScroll"

    private func badge(_ label: String, tint: Color) -> some View {
        CalendarYiJiBadge(label: label, tint: tint.opacity(0.8), size: 11, weight: .medium)
            .frame(height: CalendarPopoverLayout.yiJiRowHeight)
    }

    private func itemsText(_ items: [String]) -> some View {
        Text(items.joined(separator: "  "))
            .font(.system(size: 11))
            .foregroundStyle(palette.secondaryText)
            .lineLimit(1)
            .fixedSize()
            .frame(height: CalendarPopoverLayout.yiJiRowHeight)
    }

    /// 溢出越少渐变越淡，滚到尽头时平滑消失。
    private func fade(edge: HorizontalEdge, distance: CGFloat) -> some View {
        let solid = palette.cardBackground
        let clear = palette.cardBackground.opacity(0)
        return LinearGradient(
            colors: edge == .leading ? [solid, clear] : [clear, solid],
            startPoint: .leading,
            endPoint: .trailing
        )
        .frame(width: Self.fadeWidth)
        .opacity(min(1, distance / Self.fadeWidth))
        .allowsHitTesting(false)
    }

}
