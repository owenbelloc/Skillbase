import SwiftUI

struct CreateSkillView: View {
    @Environment(AppStore.self) private var store
    @State private var name = ""
    @State private var description = ""
    @State private var bodyText = """
    # 技能名称

    ## 适用场景
    说明什么时候应该使用这个 skill。

    ## 步骤
    1. 先做什么
    2. 再做什么
    """
    @State private var targets: Set<AIPlatform> = [.codex]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Space.lg) {
                Text("把新技能写进知识库，然后部署到桌面端。打开对应应用后新开一轮对话即可调用。")
                    .font(TypeScale.body)
                    .foregroundStyle(Theme.muted)

                field("标识", hint: "小写字母、数字和连字符，例如 seo-audit") {
                    TextField("my-skill", text: $name)
                        .textFieldStyle(.plain)
                }

                field("描述", hint: "给模型看的 description，说明做什么、何时用") {
                    TextField("当用户提到……时使用", text: $description, axis: .vertical)
                        .textFieldStyle(.plain)
                        .lineLimit(3...6)
                }

                field("SKILL.md 正文", hint: "给 Agent 的操作说明") {
                    TextEditor(text: $bodyText)
                        .font(.system(size: 14, design: .monospaced))
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 240)
                        .foregroundStyle(Theme.text)
                }

                VStack(alignment: .leading, spacing: Space.sm) {
                    Text("部署目标")
                        .font(TypeScale.captionStrong)
                        .foregroundStyle(Theme.muted)
                    Text("可以只保存到知识库，也可以立刻应用到桌面端。")
                        .font(TypeScale.caption)
                        .foregroundStyle(Theme.muted)
                    ForEach(AIPlatform.managedTargets, id: \.self) { platform in
                        Toggle(isOn: Binding(
                            get: { targets.contains(platform) },
                            set: { on in
                                if on { targets.insert(platform) } else { targets.remove(platform) }
                            }
                        )) {
                            HStack {
                                PlatformChip(platform: platform)
                                Text(platform.subtitle)
                                    .font(TypeScale.caption)
                                    .foregroundStyle(Theme.muted)
                            }
                        }
                        .toggleStyle(.checkbox)
                    }
                }
                .saasCard()

                HStack {
                    Button("导入现有文件夹…") {
                        Task { await store.importFromPanel() }
                    }
                    .buttonStyle(GhostButtonStyle())
                    Spacer()
                    Button("创建并部署") {
                        Task {
                            await store.createAndDeploy(
                                name: name,
                                description: description,
                                body: bodyText,
                                targets: AIPlatform.managedTargets.filter { targets.contains($0) }
                            )
                        }
                    }
                    .buttonStyle(AccentButtonStyle())
                    .disabled(SkillParser.sanitizeName(name).isEmpty)
                }
            }
            .padding(Space.xl)
            .frame(maxWidth: 760, alignment: .leading)
        }
        .background(Theme.bg)
    }

    private func field<Content: View>(_ title: String, hint: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: Space.xs) {
            Text(title)
                .font(TypeScale.captionStrong)
                .foregroundStyle(Theme.muted)
            content()
                .font(TypeScale.body)
                .foregroundStyle(Theme.text)
                .padding(Space.sm)
                .background(
                    RoundedRectangle(cornerRadius: Radius.sm, style: .continuous)
                        .fill(Theme.card)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.sm, style: .continuous)
                        .stroke(Color.black.opacity(0.08), lineWidth: 1)
                )
            Text(hint)
                .font(TypeScale.fine)
                .foregroundStyle(Theme.muted)
        }
    }
}
