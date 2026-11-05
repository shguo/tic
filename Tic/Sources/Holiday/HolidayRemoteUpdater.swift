import Foundation
import os

/// 联网更新法定节假日 / 调休数据：从发布仓库拉取当年与次年的 `holidays/{year}.json`，
/// 校验通过后写入缓存并替换 `HolidayStore` 中的数据，无需发版。
///
/// - 数据源：发布仓库（`TrustedDownloadPolicy.repoOwner/repoName`）`custom` 分支下的
///   `Tic/Resources/holidays/{year}.json`，与内置资源同一份文件；维护者提交 JSON 即生效。
/// - 节点冗余：GitHub raw → jsDelivr，逐个尝试。
/// - 频率：启动后检查一次，此后每 6 小时检查；距上次成功拉取不足 24 小时则跳过。
/// - 任何失败都静默忽略，继续使用缓存 / 内置数据。
@MainActor
final class HolidayRemoteUpdater {
    static let shared = HolidayRemoteUpdater()

    private nonisolated static let branch = "custom"
    private nonisolated static let path = "Tic/Resources/holidays"
    private static let refreshInterval: TimeInterval = 24 * 60 * 60
    private static let timerInterval: TimeInterval = 6 * 60 * 60
    private static let launchDelay: Duration = .seconds(5)
    private let lastFetchKey = "me.nic.tic.lastHolidayFetchTime"

    private let logger = Logger(subsystem: "me.nic.tic", category: "HolidayRemoteUpdater")
    private var timer: Timer?
    private var isFetching = false

    private let session: URLSession = {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 10
        config.timeoutIntervalForResource = 20
        config.waitsForConnectivity = false
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        return URLSession(configuration: config)
    }()

    private init() {}

    func start() {
        guard !AppRuntime.isRunningTests, timer == nil else { return }
        Task {
            try? await Task.sleep(for: Self.launchDelay)
            await refreshIfNeeded()
        }
        let timer = Timer(timeInterval: Self.timerInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in await self?.refreshIfNeeded() }
        }
        timer.tolerance = 10 * 60
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    private func refreshIfNeeded() async {
        let last = UserDefaults.standard.double(forKey: lastFetchKey)
        guard Date().timeIntervalSince1970 - last >= Self.refreshInterval else { return }
        await refresh()
    }

    /// 拉取当年与次年（东八区年份）。至少一年拉取成功才记录时间，全部失败下次再试。
    func refresh() async {
        guard !isFetching else { return }
        isFetching = true
        defer { isFetching = false }

        let year = BeijingCalendar.gregorian.component(.year, from: Date())
        var anySucceeded = false
        var changed = false
        for target in [year, year + 1] {
            guard let data = await fetch(year: target) else { continue }
            anySucceeded = true
            if HolidayStore.shared.install(year: target, data: data) {
                HolidayCache.write(data, year: target)
                changed = true
                logger.info("已更新 \(target) 年调休数据")
            }
        }
        if anySucceeded {
            UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: lastFetchKey)
        }
        if changed {
            NotificationCenter.default.post(name: .holidayDataDidUpdate, object: nil)
        }
    }

    /// 依次尝试各节点，返回第一份通过校验的数据；该年尚未发布（404 / 空 days）返回 nil。
    private func fetch(year: Int) async -> Data? {
        for url in Self.urls(year: year) {
            do {
                let (data, response) = try await session.data(from: url)
                guard let http = response as? HTTPURLResponse, http.statusCode == 200,
                      HolidayStore.validatedDays(data, year: year) != nil
                else { continue }
                return data
            } catch {
                logger.debug("拉取调休数据失败 \(url.absoluteString, privacy: .public): \(error.localizedDescription, privacy: .public)")
            }
        }
        return nil
    }

    nonisolated static func urls(year: Int) -> [URL] {
        let owner = TrustedDownloadPolicy.repoOwner
        let repo = TrustedDownloadPolicy.repoName
        let file = "\(path)/\(year).json"
        return [
            "https://raw.githubusercontent.com/\(owner)/\(repo)/\(branch)/\(file)",
            "https://cdn.jsdelivr.net/gh/\(owner)/\(repo)@\(branch)/\(file)",
        ].compactMap(URL.init(string:))
    }
}
