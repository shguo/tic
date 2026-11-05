import Foundation

enum DayBadge: String {
    case rest = "休"
    case work = "班"
}

struct DayAnnotation {
    var subtitle: String?
    var badge: DayBadge?
}

extension Notification.Name {
    /// 联网拉到新的调休数据并已生效；月历、倒计时据此重算。
    static let holidayDataDidUpdate = Notification.Name("me.nic.tic.holidayDataDidUpdate")
}

/// 法定节假日 / 调休（休/班）数据源。
///
/// 节气、农历、公历/农历节日都能本地推算；唯独「法定放假 / 调休」依赖国务院逐年公布，
/// 无法算法化。数据按年一份 JSON（holiday-cn 格式），来源优先级：
/// 联网缓存（`HolidayRemoteUpdater` 写入 Application Support）> App 内置 `holidays/{year}.json`。
/// 新年份 / 修订只需更新仓库里的 JSON，客户端联网自动拉取，无需发版。
///
/// 线程安全：所有可变状态由 `lock` 保护。
final class HolidayStore: @unchecked Sendable {
    static let shared = HolidayStore(loadCache: !AppRuntime.isRunningTests)

    private let lock = NSLock()
    private var daysByYear: [Int: [Day]] = [:]
    private var byKey: [String: DayAnnotation] = [:]
    private var dataRevision = 0

    init(loadCache: Bool) {
        lock.lock(); defer { lock.unlock() }
        loadBundled()
        if loadCache { loadCached() }
        rebuild()
    }

    /// 查询某日的调休标注；键为 `"yyyy-MM-dd"`（东八区当地日）。
    func annotation(forKey key: String) -> DayAnnotation? {
        lock.lock(); defer { lock.unlock() }
        return byKey[key]
    }

    /// 所有放假日（休）的键，升序。
    var restDayKeys: [String] {
        lock.lock(); defer { lock.unlock() }
        return byKey.filter { $0.value.badge == .rest }.keys.sorted()
    }

    /// 数据每次变化 +1，供依赖放假数据的缓存判断是否失效。
    var revision: Int {
        lock.lock(); defer { lock.unlock() }
        return dataRevision
    }

    /// 已有数据覆盖的最大年份；无任何数据时为 0。
    var maxCoveredYear: Int {
        lock.lock(); defer { lock.unlock() }
        return daysByYear.keys.max() ?? 0
    }

    /// 某年是否缺少调休数据（用于 UI 非阻断提示）；无任何数据时不提示，避免误报。
    func isYearUncovered(_ year: Int) -> Bool {
        lock.lock(); defer { lock.unlock() }
        return !daysByYear.isEmpty && daysByYear[year] == nil
    }

    /// 用联网拉到的某年数据替换现有数据。数据无效或与现有内容相同返回 false。
    @discardableResult
    func install(year: Int, data: Data) -> Bool {
        guard let days = Self.validatedDays(data, year: year) else { return false }
        lock.lock(); defer { lock.unlock() }
        guard daysByYear[year] != days else { return false }
        daysByYear[year] = days
        rebuild()
        return true
    }

    // MARK: - 解析与校验（holiday-cn 格式）

    struct Day: Decodable, Equatable {
        let name: String
        let date: String
        let isOffDay: Bool
    }

    private struct HolidayFile: Decodable {
        let year: Int
        let days: [Day]
    }

    static let maxJSONBytes = 2 * 1024 * 1024

    /// 解析并校验一年的数据：年份一致、日期合法且落在该年前后、放假天数在合理区间（防脏数据 / 格式悄悄变更）。
    static func validatedDays(_ data: Data, year: Int) -> [Day]? {
        guard data.count <= maxJSONBytes,
              let file = try? JSONDecoder().decode(HolidayFile.self, from: data),
              file.year == year,
              !file.days.isEmpty
        else { return nil }
        let offDays = file.days.filter(\.isOffDay).count
        guard (7...45).contains(offDays) else { return nil }
        for day in file.days {
            guard let date = BeijingCalendar.date(fromKey: day.date),
                  BeijingCalendar.dateKey(date) == day.date,
                  abs(BeijingCalendar.gregorian.component(.year, from: date) - year) <= 1,
                  !day.name.isEmpty, day.name.count <= 20
            else { return nil }
        }
        return file.days
    }

    // MARK: - 加载（调用方持有 lock）

    private func loadBundled() {
        // XcodeGen 将 `Tic/Resources/holidays/*.json` 复制到 bundle 根目录（非 holidays/ 子目录）。
        let urls = Bundle.main.urls(forResourcesWithExtension: "json", subdirectory: nil) ?? []
        load(urls)
    }

    private func loadCached() {
        guard let directory = HolidayCache.directory,
              let urls = try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
        else { return }
        load(urls.filter { $0.pathExtension == "json" })
    }

    private func load(_ urls: [URL]) {
        for url in urls {
            guard let year = Int(url.deletingPathExtension().lastPathComponent),
                  let data = try? Data(contentsOf: url),
                  let days = Self.validatedDays(data, year: year)
            else { continue }
            daysByYear[year] = days
        }
    }

    private func rebuild() {
        var table: [String: DayAnnotation] = [:]
        for days in daysByYear.values {
            for day in days {
                // 放假：节日名 + 休；补班：无副标题 + 班（与历史内置数据语义一致）
                table[day.date] = DayAnnotation(
                    subtitle: day.isOffDay ? day.name : nil,
                    badge: day.isOffDay ? .rest : .work
                )
            }
        }
        byKey = table
        dataRevision += 1
    }
}

/// 联网拉取的调休数据缓存目录：`~/Library/Application Support/Tic/holidays/{year}.json`。
enum HolidayCache {
    static var directory: URL? {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent("Tic/holidays", isDirectory: true)
    }

    static func write(_ data: Data, year: Int) {
        guard let directory else { return }
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try? data.write(to: directory.appendingPathComponent("\(year).json"), options: .atomic)
    }
}

enum AppRuntime {
    /// 单元测试宿主进程中运行（测试需要只用内置数据、不联网，保证结果确定）。
    static let isRunningTests = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
}
