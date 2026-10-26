import Foundation

/// 菜单栏标签中只依赖设置的部分（占位宽度需测量文字，较重），设置变化时才重算。
struct MenuBarLabelLayout: Equatable {
    let order: [MenuBarBlock]
    let enabled: Set<MenuBarBlock>
    let showSeconds: Bool
    let use24Hour: Bool
    let textSlotWidth: CGFloat
    let labelWidth: CGFloat
    let showsIcon: Bool

    /// 显示秒时每秒刷新，否则每分钟。
    var updateInterval: TimeInterval {
        enabled.contains(.time) && showSeconds ? 1 : 60
    }

    static func current() -> MenuBarLabelLayout {
        let order = AppSettings.loadBlockOrder()
        let enabled = AppSettings.loadEnabledBlocks()
        let showSeconds = UserDefaults.standard.object(forKey: AppSettings.showSecondsKey) as? Bool ?? true
        let use24Hour = UserDefaults.standard.object(forKey: AppSettings.use24HourKey) as? Bool ?? true

        let sizingText = MenuBarDisplayComposer.sizingText(
            order: order,
            enabled: enabled,
            showSeconds: showSeconds,
            use24Hour: use24Hour
        )
        let showsIcon = MenuBarDisplayComposer.showsIcon(order: order, enabled: enabled)
        let textSlotWidth = sizingText.isEmpty ? 0 : MenuBarDisplayComposer.reservedTextWidth(for: sizingText)

        var labelWidth = textSlotWidth
        if showsIcon {
            labelWidth += MenuBarDisplayComposer.menuBarIconWidth
            if textSlotWidth > 0 {
                labelWidth += MenuBarDisplayComposer.iconTextSpacing
            }
        }
        labelWidth += MenuBarDisplayComposer.labelHorizontalInset * 2

        return MenuBarLabelLayout(
            order: order,
            enabled: enabled,
            showSeconds: showSeconds,
            use24Hour: use24Hour,
            textSlotWidth: textSlotWidth,
            labelWidth: labelWidth,
            showsIcon: showsIcon
        )
    }
}

struct MenuBarLabelMetrics: Equatable {
    let displayText: String
    let textSlotWidth: CGFloat
    let labelWidth: CGFloat
    let showsIcon: Bool
    /// 图标内显示的当天日期。
    let iconDay: Int
    let updateInterval: TimeInterval

    static func current(date: Date = .now) -> MenuBarLabelMetrics {
        make(date: date, layout: .current())
    }

    static func make(date: Date, layout: MenuBarLabelLayout) -> MenuBarLabelMetrics {
        let composed = MenuBarDisplayComposer.compose(
            date: date,
            order: layout.order,
            enabled: layout.enabled,
            showSeconds: layout.showSeconds,
            use24Hour: layout.use24Hour
        )

        return MenuBarLabelMetrics(
            displayText: composed.isEmpty && !layout.showsIcon ? MenuBarDisplayComposer.fallbackText : composed,
            textSlotWidth: layout.textSlotWidth,
            labelWidth: layout.labelWidth,
            showsIcon: layout.showsIcon,
            iconDay: Calendar.current.component(.day, from: date),
            updateInterval: layout.updateInterval
        )
    }
}
