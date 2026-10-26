import AppKit

@MainActor
final class CalendarSettingsViewController: SettingsPaneViewController {
    private let dotsSwitch = NSSwitch()
    private let termsSwitch = NSSwitch()
    private let westernSwitch = NSSwitch()
    private let yiJiSwitch = NSSwitch()
    init() { super.init(title: "日历") }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func makeContent() -> [NSView] {
        dotsSwitch.state = AppSettings.bool(forKey: AppSettings.showAnnotationDotsKey, default: AppSettings.showAnnotationDotsDefault) ? .on : .off
        dotsSwitch.target = self
        dotsSwitch.action = #selector(dotsChanged)

        termsSwitch.state = AppSettings.bool(forKey: AppSettings.showSolarTermsKey, default: true) ? .on : .off
        termsSwitch.target = self
        termsSwitch.action = #selector(termsChanged)

        westernSwitch.state = AppSettings.bool(forKey: AppSettings.showWesternFestivalsKey, default: true) ? .on : .off
        westernSwitch.target = self
        westernSwitch.action = #selector(westernChanged)

        yiJiSwitch.state = AppSettings.bool(forKey: AppSettings.showYiJiKey, default: true) ? .on : .off
        yiJiSwitch.target = self
        yiJiSwitch.action = #selector(yiJiChanged)

        let dotsRow = makeSettingsRow(
            title: "显示标注圆点",
            subtitle: "节假日、节气等有标注的日期在月历格底部显示圆点",
            control: dotsSwitch
        )
        let termsRow = makeSettingsRow(
            title: "显示节气",
            subtitle: "月历副标题与详情中显示节气名称（如立夏）",
            control: termsSwitch
        )
        let westernRow = makeSettingsRow(
            title: "显示西方节日",
            subtitle: "情人节、母亲节、万圣节、感恩节、圣诞节等",
            control: westernSwitch
        )
        let yiJiRow = makeSettingsRow(
            title: "显示宜忌",
            subtitle: "农历详情下方显示当日宜 / 忌，点击查看完整列表",
            control: yiJiSwitch
        )
        return [makeSettingsGroupedCard([dotsRow, termsRow, westernRow, yiJiRow])]
    }

    override func makeFooter() -> NSView? {
        makeSettingsFootnote("法定节假日 / 调休数据已内置至 \(HolidayStore.shared.maxCoveredYear) 年，新年份随版本更新。")
    }

    @objc private func dotsChanged() {
        AppSettings.setBool(dotsSwitch.state == .on, forKey: AppSettings.showAnnotationDotsKey)
    }

    @objc private func termsChanged() {
        AppSettings.setBool(termsSwitch.state == .on, forKey: AppSettings.showSolarTermsKey)
    }

    @objc private func westernChanged() {
        AppSettings.setBool(westernSwitch.state == .on, forKey: AppSettings.showWesternFestivalsKey)
    }

    @objc private func yiJiChanged() {
        AppSettings.setBool(yiJiSwitch.state == .on, forKey: AppSettings.showYiJiKey)
    }

}
