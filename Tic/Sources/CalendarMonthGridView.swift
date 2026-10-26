import SwiftUI

struct CalendarMonthGridView: View {
    let slots: [CalendarMonthSlot]
    let selectedDate: Date
    let palette: CalendarPalette
    let showAnnotationDots: Bool
    let subtitleRotationIndex: Int
    let onSelectDate: (Date) -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

    var body: some View {
        let selectedDayID = BeijingCalendar.dateKey(selectedDate)
        let todayID = BeijingCalendar.dateKey(BeijingCalendar.day(containing: .now))

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
}
