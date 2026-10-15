import AppKit
import SwiftUI

/// 菜单栏日历图标：日历页轮廓 + 实心页眉 + 当天日期数字。
///
/// 只用黑色绘制、透明底，由调用方导出为模板图（见 docs/menu-bar-label.md「模板图着色」）。
struct MenuBarCalendarIcon: View {
    let day: Int

    private static let size = MenuBarDisplayComposer.menuBarIconSize
    private static let cornerRadius: CGFloat = 3.5
    private static let strokeWidth: CGFloat = 1.4
    private static let headerHeight: CGFloat = 4.5

    var body: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: Self.cornerRadius, style: .continuous)
                .strokeBorder(Color.black, lineWidth: Self.strokeWidth)

            UnevenRoundedRectangle(
                topLeadingRadius: Self.cornerRadius,
                topTrailingRadius: Self.cornerRadius,
                style: .continuous
            )
            .fill(Color.black)
            .frame(height: Self.headerHeight)

            Text(String(day))
                .font(.system(size: 9.5, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(Color.black)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.top, Self.headerHeight - 0.5)
        }
        .frame(width: Self.size.width, height: Self.size.height)
    }

    /// 设置页预览用：渲染为模板 `NSImage`。
    @MainActor
    static func templateImage(day: Int, scale: CGFloat = NSScreen.main?.backingScaleFactor ?? 2) -> NSImage? {
        let renderer = ImageRenderer(content: MenuBarCalendarIcon(day: day))
        renderer.scale = scale
        renderer.isOpaque = false
        guard let image = renderer.nsImage else { return nil }
        image.isTemplate = true
        return image
    }
}
