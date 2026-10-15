import AppKit
import SwiftUI

/// 菜单栏日历图标：造型取自 App 图标（页眉 + 两个装订环 + 当天日期）。
///
/// 只用黑色绘制、透明底，由调用方导出为模板图（见 docs/menu-bar-label.md「模板图着色」）。
/// 装订环在页眉上「挖空」一圈，避免与实心页眉糊成一块。
struct MenuBarCalendarIcon: View {
    let day: Int

    private static let size = MenuBarDisplayComposer.menuBarIconSize
    private static let cornerRadius: CGFloat = 3.5
    private static let strokeWidth: CGFloat = 1.4
    /// 页身顶边距画布顶部的距离，留给装订环露出。
    private static let bodyTop: CGFloat = 2.5
    private static let headerHeight: CGFloat = 4.5
    private static let ringSize = CGSize(width: 1.8, height: 5)
    private static let ringGap: CGFloat = 1
    /// 两个装订环中心距左右边缘的距离。
    private static let ringInset: CGFloat = 5

    var body: some View {
        ZStack(alignment: .top) {
            page
            rings
        }
        .frame(width: Self.size.width, height: Self.size.height)
        .compositingGroup()
    }

    private var page: some View {
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
        .frame(height: Self.size.height - Self.bodyTop)
        .padding(.top, Self.bodyTop)
    }

    private var rings: some View {
        ZStack(alignment: .top) {
            ringRow(width: Self.ringSize.width + Self.ringGap * 2, height: Self.ringSize.height + Self.ringGap)
                .blendMode(.destinationOut)
            ringRow(width: Self.ringSize.width, height: Self.ringSize.height)
                .padding(.top, 0.5)
        }
        .frame(maxWidth: .infinity, alignment: .top)
    }

    private func ringRow(width: CGFloat, height: CGFloat) -> some View {
        HStack(spacing: 0) {
            Capsule().fill(Color.black).frame(width: width, height: height)
            Spacer(minLength: 0)
            Capsule().fill(Color.black).frame(width: width, height: height)
        }
        .padding(.horizontal, Self.ringInset - width / 2)
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
