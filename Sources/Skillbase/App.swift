import AppKit
import SwiftUI

@main
struct SkillbaseApp: App {
    @State private var store = AppStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .preferredColorScheme(.light)
                .background(Theme.bg)
                .task { await store.scan() }
                .onAppear {
                    NSApp.appearance = NSAppearance(named: .aqua)
                }
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1380, height: 860)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("新建技能") {
                    store.select(.create)
                }
                .keyboardShortcut("n", modifiers: .command)
            }
            CommandGroup(after: .newItem) {
                Button("刷新扫描") {
                    Task { await store.scan() }
                }
                .keyboardShortcut("r", modifiers: .command)
                Button("搜索技能") {
                    store.wantsSearchFocus = true
                }
                .keyboardShortcut("s", modifiers: .command)
                Button("导入技能文件夹…") {
                    Task { await store.importFromPanel() }
                }
                .keyboardShortcut("o", modifiers: .command)
            }
        }
    }
}
