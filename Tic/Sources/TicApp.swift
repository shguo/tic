import SwiftUI

@main
struct TicApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra {
            // 宽高由 CalendarPopoverView 按布局常量显式给出，窗口尺寸见 PopoverWindowSizer。
            CalendarPopoverView()
                .fixedSize()
        } label: {
            MenuBarDateLabel()
        }
        .menuBarExtraStyle(.window)
        .commands {
            CommandGroup(replacing: .appSettings) {
                Button("设置…") {
                    SettingsWindowManager.show()
                }
                .keyboardShortcut(",", modifiers: .command)

                Button("检查更新…") {
                    NotificationCenter.default.post(name: .checkForUpdates, object: nil)
                }
            }
        }
    }
}
