import AppKit
import SwiftUI

struct SidebarView: View {
    @Environment(AppStore.self) private var store
    @FocusState private var searchFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: Space.xs) {
                Text("Skillbase")
                    .font(TypeScale.tagline)
                    .foregroundStyle(Theme.text)
                    .appleTight(-0.23)
            }
            .padding(.horizontal, Space.md)
            .padding(.top, Space.lg)
            .padding(.bottom, Space.sm)

            HStack(spacing: Space.xs) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(Theme.muted)
                TextField("Search", text: Bindable(store).search)
                    .font(TypeScale.body)
                    .textFieldStyle(.plain)
                    .focused($searchFocused)
                Text("⌘S")
                    .font(TypeScale.fine)
                    .foregroundStyle(Theme.muted)
            }
            .padding(.horizontal, 20)
            .frame(height: 44)
            .background(Capsule().fill(Theme.card))
            .overlay(Capsule().stroke(Color.black.opacity(0.08), lineWidth: 1))
            .padding(.horizontal, Space.md)
            .onChange(of: store.wantsSearchFocus) { _, on in
                if on {
                    searchFocused = true
                    store.wantsSearchFocus = false
                }
            }

            HStack(spacing: Space.xs) {
                Text("本机用户")
                    .font(TypeScale.captionStrong)
                    .foregroundStyle(Theme.text)
                StatusPill(text: "Admin", color: Theme.accent)
                Spacer()
            }
            .padding(.horizontal, Space.md)
            .padding(.top, Space.md)

            VStack(spacing: Space.xxs) {
                navRow("Dashboard", symbol: "square.grid.2x2", route: .dashboard)
                navRow("技能库", symbol: "square.stack.3d.up", route: .library)
                navRow("新建技能", symbol: "plus", route: .create)
                ForEach(store.desktopPlatforms) { info in
                    platformRow(info)
                }
            }
            .padding(.top, Space.lg)
            .padding(.horizontal, Space.xs)

            Spacer()

            VStack(spacing: Space.xxs) {
                navRow("设置", symbol: "gearshape", route: .settings)
                HoverNavButton(title: "Support", symbol: "questionmark.circle", active: false) {
                    if let url = URL(string: "https://skills.sh") {
                        NSWorkspace.shared.open(url)
                    }
                }
            }
            .padding(.horizontal, Space.xs)
            .padding(.bottom, Space.lg)
        }
        .frame(width: Theme.sidebarWidth)
        .background(Theme.sidebar)
    }

    private func navRow(_ title: String, symbol: String, route: Route) -> some View {
        HoverNavButton(title: title, symbol: symbol, active: store.route == route) {
            store.select(route)
        }
    }

    private func platformRow(_ info: PlatformInfo) -> some View {
        let active: Bool = {
            if case .platform(let platform) = store.route { return platform == info.platform }
            return false
        }()
        return HoverNavButton(
            title: info.platform.displayName,
            symbol: info.platform.symbol,
            active: active,
            badge: "\(info.skillCount)"
        ) {
            store.select(.platform(info.platform))
        }
        .help(info.detected ? "\(info.platform.displayName) 已识别，\(info.skillCount) 个技能" : "尚未检测到 \(info.platform.displayName)")
    }
}

struct HoverNavButton: View {
    var title: String
    var symbol: String
    var active: Bool
    var badge: String? = nil
    var action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: Space.xs) {
                Image(systemName: symbol)
                    .font(.system(size: 14, weight: .regular))
                    .frame(width: 18)
                Text(title)
                    .font(active ? TypeScale.captionStrong : TypeScale.caption)
                Spacer()
                if let badge {
                    Text(badge)
                        .font(TypeScale.fine)
                        .foregroundStyle(active ? Theme.accent : Theme.muted)
                }
            }
            .foregroundStyle(active ? Theme.accent : Theme.text)
            .padding(.horizontal, Space.sm)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: Radius.sm, style: .continuous)
                    .fill(active || hovering ? Theme.card : Color.clear)
            )
            .scaleEffect(1)
        }
        .buttonStyle(PressScaleButtonStyle())
        .onHover { hovering = $0 }
        .pointingCursor()
    }
}

struct PressScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
