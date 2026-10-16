import SwiftUI

struct CalendarDetailsSection: View {
    let selectedDate: Date
    let upcomingEvents: [CalendarUpcomingEvent]
    let palette: CalendarPalette

    var body: some View {
        VStack(spacing: CalendarPopoverLayout.detailsCardSpacing) {
            CalendarLunarCardView(selectedDate: selectedDate, palette: palette)
            CalendarUpcomingListView(events: upcomingEvents, palette: palette)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, CalendarPopoverLayout.detailsVerticalPadding)
        .frame(maxWidth: .infinity, alignment: .top)
        .background(palette.detailsBackground)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("农历详情和后续提醒")
    }
}
