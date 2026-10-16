import AppKit
import SwiftUI

/// 由应用主动设置菜单栏弹窗的窗口高度，上边缘（靠菜单栏一侧）保持不动。
///
/// `MenuBarExtra` 默认在内容更新之后才按内容固有高度推算并改窗口尺寸，两者相差一两帧：
/// 这期间内容在新旧尺寸的窗口里居中摆放，肉眼看到整个弹窗先下移再弹回。
/// 现在由 `CalendarPopoverLayout.popoverHeight(showsYiJi:)` 直接算出目标高度，内容显式定高，
/// 并在 SwiftUI 用新状态更新视图的同一次更新（`updateNSView`）里同步设置窗口尺寸。
/// 系统随后按内容推算出的尺寸与之相同，不会再改动窗口。
struct PopoverWindowSizer: NSViewRepresentable {
    let height: CGFloat

    func makeNSView(context: Context) -> SizerView {
        let view = SizerView()
        view.targetHeight = height
        return view
    }

    func updateNSView(_ nsView: SizerView, context: Context) {
        nsView.targetHeight = height
        nsView.applyTargetHeight()
    }

    final class SizerView: NSView {
        var targetHeight: CGFloat = 0

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            applyTargetHeight()
        }

        func applyTargetHeight() {
            guard let window, targetHeight > 0 else { return }
            let current = window.frame
            // 系统尚未摆放窗口（frame 为 .zero 或不在任何屏幕上）时不处理，避免把窗口挪出屏幕。
            guard Self.isPlacedOnScreen(current) else { return }
            let contentRect = window.contentRect(forFrameRect: current)
            let target = window.frameRect(forContentRect: NSRect(
                x: contentRect.minX,
                y: contentRect.minY,
                width: contentRect.width,
                height: targetHeight
            ))
            guard abs(target.height - current.height) > 0.5 else { return }

            // 以上边缘为锚点：只改高度与 y，不改 x / 宽度。
            let frame = NSRect(
                x: current.minX,
                y: current.maxY - target.height,
                width: current.width,
                height: target.height
            )
            window.setFrame(frame, display: true, animate: false)
        }

        static func isPlacedOnScreen(_ frame: NSRect) -> Bool {
            !frame.isEmpty && NSScreen.screens.contains { $0.frame.intersects(frame) }
        }
    }
}
