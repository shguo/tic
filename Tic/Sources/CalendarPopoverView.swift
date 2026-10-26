import SwiftUI

struct CalendarPopoverView: View {
    @State private var selectedDate: Date
    @State private var displayedMonth: Date
    @State private var isMonthPickerPresented = false
    @State private var pickerYear: Int
    @State private var subtitleRotationIndex = 0
    @State private var monthSlots: [CalendarMonthSlot]
    @State private var upcomingEvents: [CalendarUpcomingEvent]
    @State private var dataCache = CalendarPopoverDataCache()

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var systemColorScheme

    @AppStorage(AppSettings.appThemeKey) private var appThemeRaw = AppTheme.system.rawValue
    @AppStorage(AppSettings.showAnnotationDotsKey) private var showAnnotationDots = AppSettings.showAnnotationDotsDefault
    @AppStorage(AppSettings.showSolarTermsKey) private var showSolarTerms = true
    @AppStorage(AppSettings.showWesternFestivalsKey) private var showWesternFestivals = true
    @AppStorage(AppSettings.showYiJiKey) private var showYiJi = true

    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "zh_CN")
        return calendar
    }()

    init(initialDate: Date = .now) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "zh_CN")
        let initialDay = calendar.startOfDay(for: initialDate)
        let year = calendar.component(.year, from: initialDay)
        let options = CalendarDisplayOptions.fromUserDefaults()
        _selectedDate = State(initialValue: initialDay)
        _displayedMonth = State(initialValue: initialDay)
        _pickerYear = State(initialValue: year)
        _monthSlots = State(initialValue: CalendarMonthBuilder.monthSlots(for: initialDay, options: options))
        _upcomingEvents = State(initialValue: Self.upcomingListEvents(CalendarMonthBuilder.upcomingEvents(
            from: initialDay,
            limit: .max,
            options: options
        )))
    }

    private var displayOptions: CalendarDisplayOptions {
        CalendarDisplayOptions(showSolarTerms: showSolarTerms, showWesternFestivals: showWesternFestivals)
    }

    private var resolvedColorScheme: ColorScheme {
        switch AppTheme(rawValue: appThemeRaw) ?? .system {
        case .system: systemColorScheme
        case .light: .light
        case .dark: .dark
        }
    }

    private var palette: CalendarPalette {
        CalendarPopoverTheme.palette(for: resolvedColorScheme)
    }

    private var displayedMonthNumber: Int {
        calendar.component(.month, from: displayedMonth)
    }

    private var displayedYear: Int {
        calendar.component(.year, from: displayedMonth)
    }

    /// 网格当前展示的年份。与 `displayedYear` 不同，它随 `monthSlots` 一步到位更新，不参与数字滚动动画。
    private var gridYear: Int {
        monthSlots.first(where: \.isInDisplayedMonth).map { calendar.component(.year, from: $0.date) } ?? displayedYear
    }

    /// 当前查看年份缺少内置法定调休数据时的非阻断提示（随翻年自动更新）。
    private var dataCoverageNotice: String? {
        HolidayStore.shared.isYearUncovered(gridYear)
            ? "\(gridYear) 年放假安排待更新"
            : nil
    }

    /// 弹窗总高（定制版固定，仅随「显示宜忌」开关变化）；内容与窗口都按它定高。
    private var popoverHeight: CGFloat { CalendarPopoverLayout.popoverHeight(showsYiJi: showYiJi) }

    private var relativeOffsetLabel: String? {
        let label = ChineseCalendarSupport.relativeDayLabel(for: selectedDate)
        return label == "今天" ? nil : label
    }

    private var nextRestDayCountdownLabel: String? {
        guard relativeOffsetLabel == nil else { return nil }
        return CalendarMonthBuilder.nextRestDayCountdownLabel(from: selectedDate)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            CalendarPopoverHeader(
                monthNumber: displayedMonthNumber,
                year: displayedYear,
                relativeOffsetLabel: relativeOffsetLabel,
                nextRestDayCountdownLabel: nextRestDayCountdownLabel,
                dataCoverageNotice: dataCoverageNotice,
                palette: palette,
                onShowMonthPicker: showMonthPicker,
                onPreviousMonth: { shiftMonth(by: -1) },
                onGoToToday: goToToday,
                onNextMonth: { shiftMonth(by: 1) },
                onShowSettings: showSettings
            )
            .frame(height: CalendarPopoverLayout.headerHeight)
            .popover(isPresented: $isMonthPickerPresented, arrowEdge: .top) {
                monthYearPicker
            }
            .padding(.horizontal, 20)
            .padding(.top, CalendarPopoverLayout.headerTopPadding)
            .padding(.bottom, CalendarPopoverLayout.headerBottomPadding)

            CalendarWeekdayRow(palette: palette)
                .padding(.horizontal, 20)
                .padding(.bottom, CalendarPopoverLayout.weekdayRowBottomPadding)

            CalendarMonthGridView(
                slots: monthSlots,
                selectedDate: selectedDate,
                palette: palette,
                showAnnotationDots: showAnnotationDots,
                subtitleRotationIndex: subtitleRotationIndex,
                onSelectDate: selectDate
            )
            .padding(.horizontal, 8)

            CalendarDetailsSection(
                selectedDate: selectedDate,
                upcomingEvents: upcomingEvents,
                showsYiJi: showYiJi,
                palette: palette
            )
            .padding(.top, CalendarPopoverLayout.detailsTopSpacing)
        }
        // 显式定高并贴顶：窗口尺寸由 PopoverWindowSizer 在同一次更新里设成同一高度，内容不会在窗口里居中错位。
        .frame(width: CalendarPopoverLayout.width, height: popoverHeight, alignment: .top)
        .background(palette.background)
        .background { PopoverWindowSizer(height: popoverHeight) }
        .preferredColorScheme(AppTheme(rawValue: appThemeRaw)?.colorScheme)
        .focusable()
        .focusEffectDisabled()
        .onKeyPress(.leftArrow) {
            shiftSelectedDate(by: -1)
            return .handled
        }
        .onKeyPress(.rightArrow) {
            shiftSelectedDate(by: 1)
            return .handled
        }
        .onKeyPress(.upArrow) {
            shiftSelectedDate(by: -7)
            return .handled
        }
        .onKeyPress(.downArrow) {
            shiftSelectedDate(by: 7)
            return .handled
        }
        .onReceive(Timer.publish(every: 3, on: .main, in: .common).autoconnect()) { _ in
            rotateSubtitles()
        }
        .onAppear {
            refreshCalendarData(displayedMonth: displayedMonth, selectedDate: selectedDate)
        }
        .background {
            MenuBarWindowVisibilityObserver(
                // MenuBarExtra 会保留 @State；收起时就回到今天，下次打开时窗口直接是今天这个月的尺寸，
                // 不会先闪出上次的高度（Issue #2）。打开时再检查一次，覆盖跨零点等情况。
                onBecomeVisible: { resetSelectionToToday() },
                onBecomeHidden: { resetSelectionToToday() }
            )
        }
        .onChange(of: displayOptions) {
            refreshCalendarData(displayedMonth: displayedMonth, selectedDate: selectedDate)
        }
        .background { monthKeyboardShortcuts }
    }

    private var monthKeyboardShortcuts: some View {
        Group {
            Button("") { shiftMonth(by: -1) }
                .keyboardShortcut(.leftArrow, modifiers: [.option])
            Button("") { shiftMonth(by: 1) }
                .keyboardShortcut(.rightArrow, modifiers: [.option])
        }
        .frame(width: 0, height: 0)
        .opacity(0)
        .accessibilityHidden(true)
    }

    private func showMonthPicker() {
        pickerYear = displayedYear
        isMonthPickerPresented = true
    }

    private func selectDate(_ date: Date) {
        let nextDate = startOfDay(date)
        guard !calendar.isDate(nextDate, inSameDayAs: selectedDate) else {
            return
        }
        // 点到首尾补齐的上月 / 下月日期：跳到该月并选中这一天
        guard calendar.isDate(nextDate, equalTo: displayedMonth, toGranularity: .month) else {
            setDisplayedMonth(startOfMonth(nextDate), selecting: nextDate)
            return
        }
        let nextUpcomingEvents = upcomingEvents(from: nextDate)
        selectedDate = nextDate
        upcomingEvents = nextUpcomingEvents
    }

    private func shiftMonth(by value: Int) {
        guard let newMonth = calendar.date(byAdding: .month, value: value, to: startOfMonth(displayedMonth)) else {
            return
        }
        setDisplayedMonth(newMonth, preservingSelectedDay: true)
    }

    private func shiftSelectedDate(by days: Int) {
        guard let newDate = calendar.date(byAdding: .day, value: days, to: selectedDate) else {
            return
        }

        let changesMonth = !calendar.isDate(newDate, equalTo: displayedMonth, toGranularity: .month)
        let nextMonthSlots = changesMonth ? monthSlots(for: newDate) : nil
        let nextUpcomingEvents = upcomingEvents(from: newDate)

        guard changesMonth, let nextMonthSlots else {
            selectedDate = newDate
            upcomingEvents = nextUpcomingEvents
            return
        }

        withoutAnimation {
            monthSlots = nextMonthSlots
            upcomingEvents = nextUpcomingEvents
        }
        withOptionalAnimation(.easeOut(duration: 0.10)) {
            selectedDate = newDate
            displayedMonth = newDate
            pickerYear = calendar.component(.year, from: newDate)
        }
    }

    private func goToToday() {
        applyTodaySelection(animated: true)
    }

    /// 重新打开弹窗时回到今天（Issue #2）；无动画，避免闪一下。
    private func resetSelectionToToday() {
        applyTodaySelection(animated: false)
    }

    private func applyTodaySelection(animated: Bool) {
        let today = CalendarPopoverSelection.today(now: .now, calendar: calendar)
        let nextMonthSlots = monthSlots(for: today.displayedMonth)
        let nextUpcomingEvents = upcomingEvents(from: today.selectedDate)
        withoutAnimation {
            monthSlots = nextMonthSlots
            upcomingEvents = nextUpcomingEvents
            isMonthPickerPresented = false
        }
        let updates = {
            selectedDate = today.selectedDate
            displayedMonth = today.displayedMonth
            pickerYear = calendar.component(.year, from: today.selectedDate)
        }
        if animated {
            withOptionalAnimation(.easeInOut(duration: 0.18), updates)
        } else {
            withoutAnimation(updates)
        }
    }

    private func showSettings() {
        SettingsWindowManager.show()
    }

    private func setDisplayed(month: Int, year: Int) {
        let components = DateComponents(year: year, month: month, day: 1)
        guard let newMonth = calendar.date(from: components) else { return }
        setDisplayedMonth(newMonth, preservingSelectedDay: true)
    }

    private func setDisplayedMonth(_ newMonth: Date, preservingSelectedDay: Bool) {
        let nextSelectedDate = preservingSelectedDay ? dateInMonth(newMonth, matchingDayOf: selectedDate) : newMonth
        setDisplayedMonth(newMonth, selecting: nextSelectedDate)
    }

    private func setDisplayedMonth(_ newMonth: Date, selecting nextSelectedDate: Date) {
        let nextMonthSlots = monthSlots(for: newMonth)
        let nextUpcomingEvents = upcomingEvents(from: nextSelectedDate)
        withoutAnimation {
            monthSlots = nextMonthSlots
            upcomingEvents = nextUpcomingEvents
        }
        withOptionalAnimation(.easeInOut(duration: 0.18)) {
            displayedMonth = newMonth
            selectedDate = nextSelectedDate
            pickerYear = calendar.component(.year, from: newMonth)
        }
    }

    private func refreshCalendarData(displayedMonth: Date, selectedDate: Date) {
        monthSlots = monthSlots(for: displayedMonth)
        upcomingEvents = upcomingEvents(from: selectedDate)
    }

    private func monthSlots(for month: Date) -> [CalendarMonthSlot] {
        dataCache.monthSlots(for: month, options: displayOptions, calendar: calendar)
    }

    /// 「后续提醒」可滚动（可见区域 3 行）：至少列出最近 3 条，另含 90 天内的全部节日 / 节气。
    static let upcomingMinimumCount = 3
    static let upcomingWindowDays = 90

    static func upcomingListEvents(_ events: [CalendarUpcomingEvent]) -> [CalendarUpcomingEvent] {
        // events 已按日期升序
        events.enumerated()
            .prefix { $0.offset < upcomingMinimumCount || $0.element.daysUntil <= upcomingWindowDays }
            .map(\.element)
    }

    private func upcomingEvents(from date: Date) -> [CalendarUpcomingEvent] {
        Self.upcomingListEvents(dataCache.upcomingEvents(
            from: date,
            limit: .max,
            options: displayOptions,
            calendar: calendar
        ))
    }

    private func dateInMonth(_ month: Date, matchingDayOf date: Date) -> Date {
        let targetDay = calendar.component(.day, from: date)
        let firstOfMonth = startOfMonth(month)
        let daysInMonth = calendar.range(of: .day, in: .month, for: firstOfMonth)?.count ?? targetDay
        let clampedDay = min(targetDay, daysInMonth)
        return calendar.date(byAdding: .day, value: clampedDay - 1, to: firstOfMonth) ?? firstOfMonth
    }

    private func startOfMonth(_ date: Date) -> Date {
        calendar.date(from: calendar.dateComponents([.year, .month], from: date)) ?? date
    }

    private func startOfDay(_ date: Date) -> Date {
        calendar.startOfDay(for: date)
    }

    private func rotateSubtitles() {
        if reduceMotion {
            subtitleRotationIndex += 1
        } else {
            withAnimation(.easeInOut(duration: 0.18)) {
                subtitleRotationIndex += 1
            }
        }
    }

    private func withOptionalAnimation<Result>(
        _ animation: Animation,
        _ updates: () throws -> Result
    ) rethrows -> Result {
        if reduceMotion {
            return try updates()
        }
        return try withAnimation(animation, updates)
    }

    /// 切换月份时，网格与「后续提醒」等决定弹窗高度的内容一步换到位，与窗口尺寸同帧完成；
    /// 若随动画过渡，窗口已跳到新高度而内容仍在滑动、新旧两月叠影，看起来像抖动。
    /// 月份 / 年份 / 农历等数字仍在带动画的事务里更新，保留滚动效果。
    private func withoutAnimation(_ updates: () -> Void) {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction, updates)
    }
}

private extension CalendarPopoverView {
    var monthYearPicker: some View {
        MonthYearPickerPopover(
            pickerYear: $pickerYear,
            selectedMonth: displayedMonthNumber,
            onSelectMonth: { month in
                setDisplayed(month: month, year: pickerYear)
                isMonthPickerPresented = false
            },
            onGoToCurrentYear: {
                pickerYear = calendar.component(.year, from: .now)
            }
        )
        .preferredColorScheme(AppTheme(rawValue: appThemeRaw)?.colorScheme)
    }
}
