import SwiftUI

struct CalendarUpcomingRowView: View {
    let event: CalendarUpcomingEvent
    let palette: CalendarPalette

    private let calendar = Calendar(identifier: .gregorian)

    /// 左侧色条颜色，与月历日期格同色：节日红、节气绿。
    private var kindColor: Color? {
        switch event.kind {
        case .festival: palette.festivalText
        case .solarTerm: palette.solarTermText
        case .lunarDay, .lunarMonthStart: nil
        }
    }

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            if let kindColor {
                RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                    .fill(kindColor)
                    .frame(width: 3, height: 34)
                    .padding(.trailing, -6)
                    .accessibilityHidden(true)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(palette.primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)

                Text(event.dateLabel)
                    .font(.system(size: 12))
                    .foregroundStyle(palette.secondaryText)
            }

            Spacer(minLength: 12)

            if showsTodayLabel {
                Text("今天")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(palette.accent)
                    .accessibilityLabel("今天")
            } else if event.daysUntil > 0 {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(String(event.daysUntil))
                        .font(.system(size: 28, weight: .medium))
                        .foregroundStyle(palette.primaryText)
                        .monospacedDigit()
                    Text("天")
                        .font(.system(size: 14))
                        .foregroundStyle(palette.primaryText)
                }
                .accessibilityLabel("还有\(event.daysUntil)天")
            }
        }
        .frame(height: CalendarPopoverLayout.upcomingRowHeight)
        .padding(.horizontal, 18)
        .accessibilityElement(children: .combine)
    }

    private var showsTodayLabel: Bool {
        event.daysUntil == 0 && calendar.isDateInToday(event.date)
    }
}
