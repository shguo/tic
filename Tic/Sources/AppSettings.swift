import Foundation
import SwiftUI

enum AppTheme: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: "跟随系统"
        case .light: "浅色"
        case .dark: "深色"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

/// 弹窗配色：与「主题」（浅色 / 深色）正交组合，每套配色都有浅、深两版。
enum AppColorTheme: String, CaseIterable, Identifiable {
    case classic
    case vermilion
    case jade
    case indigo
    case amber
    case sakura
    case wisteria

    var id: String { rawValue }

    var title: String {
        switch self {
        case .classic: "经典（系统强调色）"
        case .vermilion: "朱砂红"
        case .jade: "青碧"
        case .indigo: "黛蓝"
        case .amber: "琥珀"
        case .sakura: "樱粉"
        case .wisteria: "紫藤"
        }
    }
}

enum MenuBarBlock: String, CaseIterable, Identifiable, Codable {
    case icon
    case date
    case weekday
    case weekNumber
    case lunar
    case time

    var id: String { rawValue }

    var title: String {
        switch self {
        case .icon: "图标"
        case .date: "日期"
        case .weekday: "星期"
        case .weekNumber: "周数"
        case .lunar: "农历"
        case .time: "时间"
        }
    }

    var previewSample: String {
        switch self {
        case .icon: "📅"
        case .date: "5月27日"
        case .weekday: "周三"
        case .weekNumber: "(21)"
        case .lunar: "四月十一"
        case .time: "11:09:40"
        }
    }

    static let defaultOrder: [MenuBarBlock] = [.icon, .date, .weekday, .weekNumber, .lunar, .time]
    static let defaultEnabled: Set<MenuBarBlock> = [.date, .time]
}

enum AppSettings {
    static let appThemeKey = "appTheme"
    static let appColorThemeKey = "appColorTheme"
    static let showSecondsKey = "showSeconds"
    static let use24HourKey = "use24Hour"
    static let menuBarBlockOrderKey = "menuBarBlockOrder"
    static let menuBarEnabledBlocksKey = "menuBarEnabledBlocks"
    static let showAnnotationDotsKey = "showAnnotationDots"
    /// 节日 / 节气已按颜色区分，标注圆点默认关闭（仍可在设置中打开）。
    static let showAnnotationDotsDefault = false
    static let showSolarTermsKey = "showSolarTerms"
    static let showWesternFestivalsKey = "showWesternFestivals"
    static let showYiJiKey = "showYiJi"
    static let launchAtLoginKey = "launchAtLogin"
    static let legacyDateFormatStyleKey = "dateFormatStyle"

    static func migrateLegacyFormatIfNeeded() {
        guard UserDefaults.standard.string(forKey: menuBarBlockOrderKey) == nil else { return }

        let legacy = UserDefaults.standard.string(forKey: legacyDateFormatStyleKey) ?? "compact"
        let enabled: Set<MenuBarBlock>
        let order: [MenuBarBlock]

        switch legacy {
        case "timeOnly":
            enabled = [.time]
            order = [.time]
        case "dateOnly":
            enabled = [.date]
            order = [.date]
        default:
            enabled = [.date, .time]
            order = [.date, .time]
        }

        saveBlockOrder(order)
        saveEnabledBlocks(enabled)
    }

    /// 读取排序并补全缺失的块（旧版迁移只写入 `date,time`），与设置页展示的顺序保持一致。
    static func loadBlockOrder() -> [MenuBarBlock] {
        guard let raw = UserDefaults.standard.string(forKey: menuBarBlockOrderKey) else {
            return MenuBarBlock.defaultOrder
        }
        let blocks = raw.split(separator: ",").compactMap { MenuBarBlock(rawValue: String($0)) }
        return blocks.isEmpty ? MenuBarBlock.defaultOrder : normalizedBlockOrder(blocks)
    }

    static func normalizedBlockOrder(_ order: [MenuBarBlock]) -> [MenuBarBlock] {
        var result: [MenuBarBlock] = []
        for block in order + MenuBarBlock.allCases where !result.contains(block) {
            result.append(block)
        }
        return result
    }

    static func saveBlockOrder(_ blocks: [MenuBarBlock]) {
        UserDefaults.standard.set(blocks.map(\.rawValue).joined(separator: ","), forKey: menuBarBlockOrderKey)
    }

    static func loadEnabledBlocks() -> Set<MenuBarBlock> {
        guard let raw = UserDefaults.standard.string(forKey: menuBarEnabledBlocksKey) else {
            return MenuBarBlock.defaultEnabled
        }
        let blocks = Set(raw.split(separator: ",").compactMap { MenuBarBlock(rawValue: String($0)) })
        return blocks.isEmpty ? MenuBarBlock.defaultEnabled : blocks
    }

    static func saveEnabledBlocks(_ blocks: Set<MenuBarBlock>) {
        UserDefaults.standard.set(blocks.map(\.rawValue).sorted().joined(separator: ","), forKey: menuBarEnabledBlocksKey)
    }

    static func resetMenuBarLayout() {
        saveBlockOrder(MenuBarBlock.defaultOrder)
        saveEnabledBlocks(MenuBarBlock.defaultEnabled)
    }

    /// 读取布尔设置；键不存在时返回 `defaultValue`（对齐 `@AppStorage` 的默认值语义）。
    static func bool(forKey key: String, default defaultValue: Bool) -> Bool {
        UserDefaults.standard.object(forKey: key) == nil
            ? defaultValue
            : UserDefaults.standard.bool(forKey: key)
    }

    static func setBool(_ value: Bool, forKey key: String) {
        UserDefaults.standard.set(value, forKey: key)
    }
}
