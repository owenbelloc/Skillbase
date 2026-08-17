import SwiftUI

struct RootView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        ZStack(alignment: .top) {
            Theme.bg.ignoresSafeArea()

            HStack(alignment: .top, spacing: 0) {
                SidebarView()
                Rectangle().fill(Theme.border).frame(width: 1)
                VStack(alignment: .leading, spacing: 0) {
                    TitleBar()
                    HStack(alignment: .top, spacing: Space.lg) {
                        mainPane
                        if showsDetail, store.selectedGroup != nil {
                            SkillDetailView()
                                .frame(width: Theme.detailWidth)
                                .padding(.trailing, Space.lg)
                                .padding(.bottom, Space.lg)
                                .transition(.opacity)
                        }
                    }
                }
            }

            if store.route == .dashboard, let group = store.selectedGroup {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        SkillPeekCard(group: group)
                            .padding(Space.lg)
                    }
                }
                .transition(.opacity)
            }

            if let toast = store.toast {
                ToastBanner(toast: toast)
                    .padding(.top, Space.md)
                    .transition(.opacity)
                    .zIndex(10)
            }
        }
        .animation(.easeOut(duration: 0.18), value: store.toast)
        .animation(.easeOut(duration: 0.18), value: store.selectedSkillID)
        .sheet(isPresented: Binding(
            get: { store.showDeploySheet },
            set: { store.showDeploySheet = $0 }
        )) {
            DeploySheet()
        }
    }

    private var showsDetail: Bool {
        switch store.route {
        case .library, .platform: return true
        default: return false
        }
    }

    @ViewBuilder
    private var mainPane: some View {
        switch store.route {
        case .dashboard:
            DashboardView()
        case .library, .platform:
            LibraryView()
        case .create:
            CreateSkillView()
        case .settings:
            SettingsView()
        }
    }
}

struct TitleBar: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        HStack(alignment: .center, spacing: Space.md) {
            Spacer().frame(width: 62)
            VStack(alignment: .leading, spacing: Space.xs) {
                Text(title)
                    .font(TypeScale.displayLG)
                    .foregroundStyle(Theme.text)
                    .appleTight(-0.28)
                Text(subtitle)
                    .font(TypeScale.body)
                    .foregroundStyle(Theme.muted)
            }
            Spacer()
            HoverIconButton(symbol: "arrow.clockwise") {
                Task { await store.scan() }
            }
            .help("刷新扫描")
            .disabled(store.isScanning)
            Button("新建技能") {
                store.select(.create)
            }
            .buttonStyle(AccentButtonStyle())
        }
        .padding(.trailing, Space.lg)
        .padding(.top, Space.xl)
        .padding(.bottom, Space.md)
    }

    private var title: String {
        switch store.route {
        case .dashboard: return "Welcome back."
        case .library: return "技能库"
        case .platform(let platform): return platform.displayName
        case .create: return "新建技能"
        case .settings: return "设置"
        }
    }

    private var subtitle: String {
        switch store.route {
        case .dashboard:
            return "管理本机 Cursor、Claude、Codex 与 Kimi 的 Skills。"
        case .library:
            return "\(store.uniqueSkillCount) 个技能，可部署到任一桌面端。"
        case .platform(let platform):
            return platform.subtitle
        case .create:
            return "写入知识库，并应用到指定的 AI 桌面端。"
        case .settings:
            return "部署方式与本地扫描目录。"
        }
    }
}

struct HoverIconButton: View {
    var symbol: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(Theme.text)
                .frame(width: 44, height: 44)
                .background(Circle().fill(Color(hex: 0xD2D2D7).opacity(0.64)))
        }
        .buttonStyle(PressScaleButtonStyle())
        .pointingCursor()
    }
}

struct ToastBanner: View {
    var toast: Toast

    var body: some View {
        HStack(spacing: Space.xs) {
            Image(systemName: toast.isError ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                .foregroundStyle(Theme.accent)
            Text(toast.text)
                .font(TypeScale.caption)
                .foregroundStyle(Theme.text)
        }
        .padding(.horizontal, Space.md)
        .padding(.vertical, Space.sm)
        .background(Capsule().fill(Theme.card))
        .overlay(Capsule().stroke(Theme.border, lineWidth: 1))
    }
}

struct SkillPeekCard: View {
    @Environment(AppStore.self) private var store
    var group: SkillGroup

    var body: some View {
        VStack(alignment: .leading, spacing: Space.sm) {
            HStack {
                Text(group.name)
                    .font(TypeScale.bodyStrong)
                    .appleTight()
                Spacer()
                Button {
                    store.selectedSkillID = nil
                } label: {
                    Image(systemName: "xmark")
                        .foregroundStyle(Theme.muted)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(PressScaleButtonStyle())
                .pointingCursor()
            }
            Text(group.description.isEmpty ? "暂无描述" : group.description)
                .font(TypeScale.caption)
                .foregroundStyle(Theme.muted)
                .lineLimit(3)
            HStack(spacing: Space.xs) {
                ForEach(AIPlatform.managedTargets.filter(\.isDesktopTarget), id: \.self) { platform in
                    PlatformChip(platform: platform, installed: group.platforms.contains(platform))
                }
            }
            HStack(spacing: Space.xs) {
                Button("打开技能库") {
                    store.select(.library)
                    store.selectedSkillID = group.id
                }
                .buttonStyle(GhostButtonStyle())
                Button("部署到平台") {
                    store.openDeploy(for: group)
                }
                .buttonStyle(AccentButtonStyle())
            }
        }
        .padding(Space.lg)
        .frame(width: 340)
        .background(
            RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                .fill(Theme.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                .stroke(Theme.border, lineWidth: 1)
        )
    }
}
