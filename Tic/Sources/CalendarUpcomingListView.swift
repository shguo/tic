import SwiftUI

struct CalendarUpcomingListView: View {
    let events: [CalendarUpcomingEvent]
    let palette: CalendarPalette

    var body: some View {
        Group {
            if events.isEmpty {
                Text("暂无后续节日或节气")
                    .font(.system(size: 14))
                    .foregroundStyle(palette.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(height: CalendarPopoverLayout.upcomingRowHeight)
                    .padding(.horizontal, 18)
                    .frame(maxHeight: .infinity, alignment: .top)
            } else {
                // 可见区域固定 3 行，其余滚动查看（不显示滚动条）；换选中日期时（首条变化）回到顶部
                ScrollView(.vertical) {
                    LazyVStack(spacing: 0) {
                        ForEach(events) { event in
                            CalendarUpcomingRowView(event: event, palette: palette)
                            if event.id != events.last?.id {
                                Divider()
                                    .overlay(palette.separator)
                                    .frame(height: CalendarPopoverLayout.upcomingDividerHeight)
                                    .padding(.leading, 20)
                            }
                        }
                    }
                }
                .scrollIndicators(.never)
                .id(events.first?.id)
            }
        }
        .frame(height: CalendarPopoverLayout.upcomingListHeight, alignment: .top)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .background(palette.cardBackground, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .shadow(color: palette.shadow, radius: 0, x: 0, y: 1)
    }
}
