import SwiftUI

struct SkillDetailView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        if let group = store.selectedGroup {
            ScrollView {
                VStack(alignment: .leading, spacing: Space.md) {
                    header(group)
                    coverage(group)
                    actions(group)
                    instances(group)
                    preview(group)
                }
                .padding(Space.lg)
            }
            .background(panel)
        } else {
            EmptyState(
                symbol: "doc.text.magnifyingglass",
                title: "选择一个技能",
                message: "查看描述、已安装平台，并一键部署到 Codex 等桌面端。"
            )
            .background(panel)
        }
    }

    private var panel: some View {
        RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
            .fill(Theme.card)
            .overlay(
                RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                    .stroke(Theme.border, lineWidth: 1)
            )
    }

    private func header(_ group: SkillGroup) -> some View {
        VStack(alignment: .leading, spacing: Space.xs) {
            Text(group.name)
                .font(TypeScale.tagline)
                .foregroundStyle(Theme.text)
                .appleTight(-0.23)
            Text(group.description.isEmpty ? "这个技能还没有 description。" : group.description)
                .font(TypeScale.body)
                .foregroundStyle(Theme.muted)
        }
    }

    private func coverage(_ group: SkillGroup) -> some View {
        VStack(alignment: .leading, spacing: Space.xs) {
            Text("安装覆盖")
                .font(TypeScale.captionStrong)
                .foregroundStyle(Theme.muted)
            VStack(spacing: Space.xs) {
                ForEach(AIPlatform.managedTargets, id: \.self) { platform in
                    HStack {
                        Circle()
                            .fill(group.platforms.contains(platform) ? Theme.accent : Theme.border)
                            .frame(width: 7, height: 7)
                        Text(platform.displayName)
                            .font(TypeScale.caption)
                            .foregroundStyle(Theme.text)
                        Spacer()
                        Text(group.platforms.contains(platform) ? "已安装" : "未安装")
                            .font(TypeScale.fine)
                            .foregroundStyle(group.platforms.contains(platform) ? Theme.accent : Theme.muted)
                    }
                }
            }
        }
    }

    private func actions(_ group: SkillGroup) -> some View {
        VStack(alignment: .leading, spacing: Space.xs) {
            Button {
                store.openDeploy(for: group)
            } label: {
                Text("部署到 AI 平台")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(AccentButtonStyle())

            if let file = group.primary?.skillFile {
                HStack(spacing: Space.xs) {
                    Button("打开 SKILL.md") { store.openInEditor(file) }
                        .buttonStyle(GhostButtonStyle())
                    Button("在 Finder 中显示") { store.reveal(group.primary?.folder ?? file) }
                        .buttonStyle(GhostButtonStyle())
                }
            }
        }
    }

    private func instances(_ group: SkillGroup) -> some View {
        VStack(alignment: .leading, spacing: Space.xs) {
            Text("本机副本")
                .font(TypeScale.captionStrong)
                .foregroundStyle(Theme.muted)
            VStack(spacing: Space.sm) {
                ForEach(group.instances) { instance in
                    VStack(alignment: .leading, spacing: Space.xs) {
                        HStack {
                            PlatformChip(platform: instance.platform)
                            KindBadge(kind: instance.kind)
                            if instance.isSymlink {
                                Text("链接")
                                    .font(TypeScale.micro)
                                    .foregroundStyle(Theme.accent)
                            }
                            Spacer()
                        }
                        Text(instance.folder.path.replacingOccurrences(
                            of: FileManager.default.homeDirectoryForCurrentUser.path,
                            with: "~"
                        ))
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(Theme.muted)
                        .textSelection(.enabled)
                        HStack {
                            Text("\(instance.fileCount) 个文件")
                            Text(instance.modifiedAt.formatted(date: .abbreviated, time: .shortened))
                            Spacer()
                            if instance.writable {
                                Button("移除此平台") {
                                    Task { await store.uninstall(instance) }
                                }
                                .font(TypeScale.fine)
                                .foregroundStyle(Theme.accent)
                                .buttonStyle(.plain)
                                .pointingCursor()
                            }
                        }
                        .font(TypeScale.fine)
                        .foregroundStyle(Theme.muted)
                    }
                    .padding(Space.sm)
                    .overlay(
                        RoundedRectangle(cornerRadius: Radius.sm, style: .continuous)
                            .stroke(Theme.border, lineWidth: 1)
                    )
                }
            }
        }
    }

    private func preview(_ group: SkillGroup) -> some View {
        VStack(alignment: .leading, spacing: Space.xs) {
            Text("内容预览")
                .font(TypeScale.captionStrong)
                .foregroundStyle(Theme.muted)
            Text(attributed(group.body))
                .font(TypeScale.caption)
                .foregroundStyle(Theme.text)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func attributed(_ markdown: String) -> AttributedString {
        (try? AttributedString(
            markdown: String(markdown.prefix(4000)),
            options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        )) ?? AttributedString(markdown)
    }
}
