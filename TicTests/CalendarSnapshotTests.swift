import XCTest
@testable import Tic

/// 节假日 / 节日输出快照：2024–2030 每天的月历副标题、休班、标注，以及每月 1 日的后续提醒与下个假期。
/// 重构节日逻辑时用来保证输出逐字不变。fixture 缺失时会自动生成并让本次测试失败；
/// 有意改变输出时删除 fixture 重新生成，并在 diff 中确认变化。
@MainActor
final class CalendarSnapshotTests: XCTestCase {
    private static let fixtureURL = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .appendingPathComponent("Fixtures/calendar-snapshot.txt")

    private static let options: [(label: String, value: CalendarDisplayOptions)] = [
        ("default", .default),
        ("noTerms", CalendarDisplayOptions(showSolarTerms: false)),
        ("noWestern", CalendarDisplayOptions(showWesternFestivals: false)),
    ]

    func testCalendarOutputMatchesSnapshot() throws {
        let actual = Self.renderSnapshot()
        let fileManager = FileManager.default

        guard let expected = try? String(contentsOf: Self.fixtureURL, encoding: .utf8) else {
            try fileManager.createDirectory(
                at: Self.fixtureURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try actual.write(to: Self.fixtureURL, atomically: true, encoding: .utf8)
            XCTFail("已生成快照 \(Self.fixtureURL.path)，确认内容后重新运行")
            return
        }

        guard actual != expected else { return }
        let actualURL = Self.fixtureURL.appendingPathExtension("actual")
        try actual.write(to: actualURL, atomically: true, encoding: .utf8)
        let expectedLines = expected.components(separatedBy: "\n")
        let actualLines = actual.components(separatedBy: "\n")
        let index = zip(expectedLines, actualLines).enumerated().first { $0.element.0 != $0.element.1 }?.offset
            ?? min(expectedLines.count, actualLines.count)
        XCTFail("""
        快照不一致（第 \(index + 1) 行），实际输出已写入 \(actualURL.path)
        期望：\(index < expectedLines.count ? expectedLines[index] : "<EOF>")
        实际：\(index < actualLines.count ? actualLines[index] : "<EOF>")
        """)
    }

    private static func renderSnapshot() -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Shanghai") ?? .current
        var lines: [String] = []

        for year in 2024...2030 {
            for month in 1...12 {
                let firstOfMonth = calendar.date(from: DateComponents(year: year, month: month, day: 1))!
                let rendered = options.map { option in
                    CalendarMonthBuilder.monthSlots(for: firstOfMonth, options: option.value)
                    .filter(\.isInDisplayedMonth)
                    .map(render)
                }
                for (dayIndex, defaultLine) in rendered[0].enumerated() {
                    lines.append("D \(defaultLine)")
                    for (optionIndex, option) in options.enumerated().dropFirst()
                    where rendered[optionIndex][dayIndex] != defaultLine {
                        lines.append("  \(option.label) \(rendered[optionIndex][dayIndex])")
                    }
                }

                for option in options {
                    let events = CalendarPopoverView.upcomingListEvents(CalendarMonthBuilder.upcomingEvents(
                        from: firstOfMonth,
                        limit: .max,
                        options: option.value
                    ))
                    let rendered = events.map { "\($0.title)(\($0.kind),+\($0.daysUntil),\($0.dateLabel))" }
                    lines.append("U \(year)-\(month) \(option.label): \(rendered.joined(separator: " "))")
                }
                let rest = CalendarMonthBuilder.nextRestDayCountdownLabel(from: firstOfMonth) ?? "-"
                lines.append("R \(year)-\(month): \(rest)")
            }
        }
        return lines.joined(separator: "\n") + "\n"
    }

    private nonisolated static func render(_ slot: CalendarMonthSlot) -> String {
        let subtitles = slot.subtitles.map { "\($0.text):\($0.kind)" }.joined(separator: ",")
        let badge = slot.badge?.rawValue ?? "-"
        return "\(slot.id) \(subtitles) badge=\(badge) mark=\(slot.hasAnnotation ? 1 : 0)"
    }
}
