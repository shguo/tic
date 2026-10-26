import AppKit
import SwiftUI

extension Notification.Name {
    static let menuBarSettingsDidChange = Notification.Name("menuBarSettingsDidChange")
}

private extension Font {
    static var menuBarLabel: Font {
        Font(MenuBarDisplayComposer.labelFont())
    }
}

/// `MenuBarExtra` 只可靠地显示 `Image` / `Text`；用 `ImageRenderer` 生成固定宽度位图避免抖动。
struct MenuBarDateLabel: View {
    @AppStorage(AppSettings.showSecondsKey) private var showSeconds = true
    @AppStorage(AppSettings.use24HourKey) private var use24Hour = true
    @State private var settingsRevision = 0
    /// 宽度等只依赖设置的部分，设置变化时才重算（测量文字较重，不放进每秒刷新）。
    @State private var layout = MenuBarLabelLayout.current()
    /// 当前位图对应的文案；文案未变时跳过重绘。
    @State private var renderedMetrics: MenuBarLabelMetrics?
    @State private var labelImage: NSImage?

    var body: some View {
        let metrics = renderedMetrics ?? MenuBarLabelMetrics.make(date: .now, layout: layout)
        Group {
            if let labelImage {
                Image(nsImage: labelImage)
                    .renderingMode(.template)
                    .accessibilityLabel(metrics.displayText.isEmpty ? "Tic 日历" : metrics.displayText)
            } else {
                Text(metrics.displayText.isEmpty ? MenuBarDisplayComposer.fallbackText : metrics.displayText)
                    .font(.menuBarLabel)
                    .monospacedDigit()
            }
        }
        .frame(width: metrics.labelWidth, height: 22)
        .fixedSize(horizontal: true, vertical: true)
        .onAppear { refresh(force: true) }
        .onChange(of: settingsRevision) { _, _ in reloadLayout() }
        .onChange(of: showSeconds) { _, _ in reloadLayout() }
        .onChange(of: use24Hour) { _, _ in reloadLayout() }
        .task(id: layout.updateInterval) {
            let interval = layout.updateInterval
            while !Task.isCancelled {
                refresh()
                try? await Task.sleep(for: .seconds(Self.delayUntilNextTick(interval: interval)))
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .menuBarSettingsDidChange)) { _ in
            settingsRevision += 1
        }
        .onReceive(
            DistributedNotificationCenter.default().publisher(
                for: Notification.Name("AppleInterfaceThemeChangedNotification")
            )
        ) { _ in
            refresh(force: true)
        }
        // 位图按主屏缩放比渲染；文案不变时不会重绘，切换 / 插拔显示器时需主动刷新清晰度。
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didChangeScreenParametersNotification)) { _ in
            refresh(force: true)
        }
    }

    /// 对齐到下一个整秒 / 整分钟，分钟数准点跳变（时区偏移均为整分钟，按参考时间取整即可）。
    nonisolated static func delayUntilNextTick(interval: TimeInterval, now: Date = .now) -> TimeInterval {
        let seconds = now.timeIntervalSinceReferenceDate
        let next = (floor(seconds / interval) + 1) * interval
        return next - seconds + 0.05
    }

    @MainActor
    private func reloadLayout() {
        layout = MenuBarLabelLayout.current()
        refresh(force: true)
    }

    @MainActor
    private func refresh(force: Bool = false) {
        let snapshot = MenuBarLabelMetrics.make(date: .now, layout: layout)
        guard force || snapshot != renderedMetrics else { return }

        let renderer = ImageRenderer(
            content: MenuBarRenderedLabel(metrics: snapshot)
        )
        renderer.proposedSize = ProposedViewSize(width: snapshot.labelWidth, height: 22)
        renderer.scale = NSScreen.main?.backingScaleFactor ?? 2
        renderer.isOpaque = false

        guard let image = renderer.nsImage else { return }
        image.isTemplate = true
        renderedMetrics = snapshot
        labelImage = image
    }
}

/// 模板图须为黑字 + 透明底，由系统按菜单栏/壁纸着色。
private enum MenuBarTemplateStyle {
    static let foreground = Color.black
}

private struct MenuBarRenderedLabel: View {
    let metrics: MenuBarLabelMetrics

    var body: some View {
        HStack(spacing: MenuBarDisplayComposer.iconTextSpacing) {
            if metrics.showsIcon {
                MenuBarCalendarIcon(day: metrics.iconDay)
            }
            if !metrics.displayText.isEmpty {
                Text(metrics.displayText)
                    .font(.menuBarLabel)
                    .monospacedDigit()
                    .foregroundStyle(MenuBarTemplateStyle.foreground)
                    .lineLimit(1)
                    .frame(width: metrics.textSlotWidth, alignment: .center)
            }
        }
        .frame(width: metrics.labelWidth, height: 22)
    }
}
