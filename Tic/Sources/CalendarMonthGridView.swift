import SwiftUI

struct CalendarMonthGridView: View {
    let slots: [CalendarMonthSlot]
    let selectedDate: Date
    let palette: CalendarPalette
    let showAnnotationDots: Bool
    let subtitleRotationIndex: Int
    let onSelectDate: (Date) -> Void

    private let calendar = Calendar(identifier: .gregorian)
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

    var body: some View {
        let selectedDayID = dayID(for: selectedDate)
        let todayID = dayID(for: .now)

        LazyVGrid(columns: columns, spacing: CalendarPopoverLayout.gridRowSpacing) {
            ForEach(slots) { slot in
                CalendarDayCellView(
                    date: slot.date,
                    monthNumber: slot.monthNumber,
                    dayNumber: slot.dayNumber,
                    isToday: slot.id == todayID,
                    isWeekend: slot.isWeekend,
                    isSelected: slot.id == selectedDayID,
                    palette: palette,
                    showAnnotationDot: showAnnotationDots && slot.hasAnnotation,
                    subtitle: slot.subtitle(rotationIndex: subtitleRotationIndex),
                    badge: slot.badge,
                    isInDisplayedMonth: slot.isInDisplayedMonth,
                    onSelect: { onSelectDate(slot.date) }
                )
                .equatable()
            }
        }
    }

    private func dayID(for date: Date) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        let year = components.year ?? 0
        let month = components.month ?? 0
        let day = components.day ?? 0
        return "\(year)-\(Self.twoDigit(month))-\(Self.twoDigit(day))"
    }

    private static func twoDigit(_ value: Int) -> String {
        value < 10 ? "0\(value)" : "\(value)"
    }
}
