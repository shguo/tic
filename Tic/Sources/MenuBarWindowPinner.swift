import AppKit
import ObjectiveC
import SwiftUI

/// 把日历弹窗所在的 `MenuBarExtra` 宿主窗口登记给 `MenuBarPopoverPin`。
struct MenuBarWindowPinner: NSViewRepresentable {
    func makeNSView(context: Context) -> HostView { HostView() }
    func updateNSView(_ nsView: HostView, context: Context) {}

    final class HostView: NSView {
        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            guard let window else { return }
            MenuBarPopoverPin.register(window)
        }
    }
}

/// 「钉住」日历弹窗：钉住时点击其他应用 / 桌面不收起弹窗。
///
/// `MenuBarExtra(.window)` 没有公开 API 控制收起行为。实测 SwiftUI 收起弹窗时（点击窗外、再次点状态栏图标）
/// 最终调用宿主窗口的 `orderWindow(.out, relativeTo:)`；单纯切到其他应用（不点击）并不会收起。
/// 因此在 SwiftUI 的 `MenuBarExtraWindow` 类上挂钩 `orderWindow:relativeTo:`：钉住时拦下这次收起，
/// 但点状态栏图标、按 Esc 仍照常关闭。
///
/// 注意：
/// - 不能把窗口实例的 isa 换成动态子类——该窗口已被 KVO 换成 `NSKVONotifying_` 子类，再换会崩溃；
///   所以挂钩在真实类（跳过 KVO 子类）上，并只对登记的弹窗窗口生效。
/// - 拦下收起后，SwiftUI 内部已认为弹窗关闭；此时再点状态栏图标，SwiftUI 会走「显示」。
///   这里在显示完成后再替用户点一次状态栏按钮，让 SwiftUI 正常收起，保证一次点击即可关闭。
@MainActor
enum MenuBarPopoverPin {
    private static weak var popoverWindow: NSWindow?
    private static var hookedClasses = Set<String>()
    /// 已拦下一次收起：窗口仍可见，但 SwiftUI 认为弹窗已关闭。
    private static var hasSuppressedDismissal = false
    /// 放行下一次收起（由本类主动触发的关闭）。
    private static var allowsNextDismissal = false

    static var isPinned: Bool {
        UserDefaults.standard.bool(forKey: AppSettings.popoverPinnedKey)
    }

    static func register(_ window: NSWindow) {
        popoverWindow = window
        hookOrderWindow(of: window)
    }

    /// 钉住状态切换后调用。取消钉住时，若之前拦过收起，让 SwiftUI 重新认为弹窗处于打开状态，
    /// 之后点击窗外即可照常收起。
    static func pinStateDidChange() {
        guard !isPinned, hasSuppressedDismissal, popoverWindow?.isVisible == true else { return }
        hasSuppressedDismissal = false
        statusItemButton()?.performClick(nil)
    }

    // MARK: - Hook

    private typealias OrderWindowIMP = @convention(c) (AnyObject, Selector, Int, Int) -> Void

    private static func hookOrderWindow(of window: NSWindow) {
        guard var cls: AnyClass = object_getClass(window) else { return }
        while NSStringFromClass(cls).hasPrefix("NSKVONotifying_"), let superclass = class_getSuperclass(cls) {
            cls = superclass
        }
        let className = NSStringFromClass(cls)
        guard !hookedClasses.contains(className) else { return }
        hookedClasses.insert(className)

        let selector = NSSelectorFromString("orderWindow:relativeTo:")
        guard let method = class_getInstanceMethod(cls, selector) else { return }
        let ownsMethod = classOwnsMethod(cls, selector)
        let originalIMP = method_getImplementation(method)
        let superclass: AnyClass? = class_getSuperclass(cls)

        let block: @convention(block) (AnyObject, Int, Int) -> Void = { object, place, otherWindow in
            let callOriginal = {
                // 类本身没有实现时，每次按父类当前实现转发，避免固化挂钩时刻的 IMP。
                let imp = ownsMethod ? originalIMP : superclass.flatMap { class_getMethodImplementation($0, selector) } ?? originalIMP
                unsafeBitCast(imp, to: OrderWindowIMP.self)(object, selector, place, otherWindow)
            }
            MainActor.assumeIsolated {
                handleOrderWindow(object, place: place, callOriginal: callOriginal)
            }
        }
        let newIMP = imp_implementationWithBlock(block)
        if ownsMethod {
            method_setImplementation(method, newIMP)
        } else {
            class_addMethod(cls, selector, newIMP, method_getTypeEncoding(method))
        }
    }

    private static func handleOrderWindow(_ object: AnyObject, place: Int, callOriginal: () -> Void) {
        guard let window = popoverWindow, object === window else {
            callOriginal()
            return
        }

        if place == NSWindow.OrderingMode.out.rawValue {
            if allowsNextDismissal || !isPinned || !window.isVisible || isUserCloseEvent(NSApp.currentEvent) {
                allowsNextDismissal = false
                hasSuppressedDismissal = false
                callOriginal()
            } else {
                hasSuppressedDismissal = true
            }
            return
        }

        // 显示弹窗。
        let wasSuppressed = hasSuppressedDismissal
        hasSuppressedDismissal = false
        callOriginal()
        if wasSuppressed, isStatusItemEvent(NSApp.currentEvent) {
            // 窗口一直钉在屏幕上，用户点状态栏图标的本意是关闭：等 SwiftUI 完成「显示」后再切换一次。
            DispatchQueue.main.async {
                allowsNextDismissal = true
                statusItemButton()?.performClick(nil)
                allowsNextDismissal = false
            }
        }
    }

    // MARK: - Helpers

    /// 点击状态栏图标或按 Esc：即使钉住也允许关闭。
    private static func isUserCloseEvent(_ event: NSEvent?) -> Bool {
        guard let event else { return false }
        if event.type == .keyDown, event.keyCode == 53 { return true }
        return isStatusItemEvent(event)
    }

    private static func isStatusItemEvent(_ event: NSEvent?) -> Bool {
        guard let event, let window = event.window else { return false }
        switch event.type {
        case .leftMouseDown, .leftMouseUp, .rightMouseDown, .rightMouseUp:
            return isStatusBarWindow(window)
        default:
            return false
        }
    }

    private static func isStatusBarWindow(_ window: NSWindow) -> Bool {
        NSStringFromClass(type(of: window)).contains("NSStatusBarWindow")
    }

    private static func statusItemButton() -> NSButton? {
        for window in NSApp.windows where isStatusBarWindow(window) {
            if let button = firstButton(in: window.contentView) {
                return button
            }
        }
        return nil
    }

    private static func firstButton(in view: NSView?) -> NSButton? {
        guard let view else { return nil }
        if let button = view as? NSButton { return button }
        for subview in view.subviews {
            if let button = firstButton(in: subview) { return button }
        }
        return nil
    }

    private static func classOwnsMethod(_ cls: AnyClass, _ selector: Selector) -> Bool {
        var count: UInt32 = 0
        guard let list = class_copyMethodList(cls, &count) else { return false }
        defer { free(list) }
        return (0..<Int(count)).contains { method_getName(list[$0]) == selector }
    }
}
