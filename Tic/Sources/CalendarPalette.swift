import SwiftUI

enum CalendarPaletteAppearance: Equatable {
    case light
    case dark
}

struct CalendarPalette {
    let appearance: CalendarPaletteAppearance
    /// 所属配色。日期格按 `.equatable()` 跳过重绘，需与 `appearance` 一起参与比较，否则切换配色后格子不刷新。
    let colorTheme: AppColorTheme
    let background: Color
    let detailsBackground: Color
    let cardBackground: Color
    let controlBackground: Color
    let controlBorder: Color
    let holidayBackground: Color
    let workdayBackground: Color
    let accent: Color
    let primaryText: Color
    let secondaryText: Color
    let mutedText: Color
    let restBadge: Color
    let workBadge: Color
    let dot: Color
    /// 日期格中节日 / 法定假日名
    let festivalText: Color
    /// 日期格中节气名
    let solarTermText: Color
    let separator: Color
    let shadow: Color
}
