import SwiftUI

struct LibraryView: View {
    @Environment(AppStore.self) private var store

    private let columns = [
        GridItem(.adaptive(minimum: 280, maximum: 360), spacing: Space.lg)
    ]

    var body: some View {
        VStack(spacing: 0) {
            if store.isScanning && store.groups.isEmpty {
                ProgressView("正在扫描本机 Skills…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .foregroundStyle(Theme.muted)
            } else if store.filteredGroups.isEmpty {
                EmptyState(
                    symbol: "tray",
                    title: "没有匹配的技能",
                    message: store.search.isEmpty
                        ? "还没有发现技能。可以新建一个，或导入包含 SKILL.md 的文件夹。"
                        : "换个关键词试试。"
                )
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: Space.lg) {
                        ForEach(store.filteredGroups) { group in
                            SkillCard(
                                group: group,
                                selected: store.selectedSkillID == group.id
                            )
                            .onTapGesture {
                                store.selectedSkillID = group.id
                            }
                            .pointingCursor()
                        }
                    }
                    .padding(.leading, Space.xs)
                    .padding(.trailing, Space.lg)
                    .padding(.bottom, Space.lg)
                }
            }
        }
        .background(Theme.bg)
    }
}

struct SkillCard: View {
    var group: SkillGroup
    var selected: Bool
    @State private var hovering = false

    var body: some View {
        VStack(alignment: .leading, spacing: Space.sm) {
            HStack(alignment: .top) {
                Text(group.name)
                    .font(TypeScale.bodyStrong)
                    .foregroundStyle(Theme.text)
                    .appleTight()
                    .lineLimit(1)
                Spacer()
                if let kind = group.primary?.kind {
                    KindBadge(kind: kind)
                }
            }
            Text(group.description.isEmpty ? "暂无描述" : group.description)
                .font(TypeScale.caption)
                .foregroundStyle(Theme.muted)
                .lineLimit(3)
                .frame(minHeight: 48, alignment: .topLeading)
            Spacer(minLength: 0)
            HStack(spacing: Space.xs) {
                ForEach(AIPlatform.managedTargets.filter(\.isDesktopTarget), id: \.self) { platform in
                    PlatformChip(
                        platform: platform,
                        compact: false,
                        installed: group.platforms.contains(platform)
                    )
                }
            }
        }
        .padding(Space.lg)
        .frame(height: 176)
        .background(
            RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                .fill(hovering ? Theme.cardHover : Theme.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                .stroke(selected ? Theme.accentFocus : Theme.border, lineWidth: selected ? 2 : 1)
        )
        .onHover { hovering = $0 }
        .help(group.description.isEmpty ? group.name : group.description)
    }
}
