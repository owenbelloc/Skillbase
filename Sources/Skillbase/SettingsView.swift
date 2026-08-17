import SwiftUI

struct SettingsView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Space.lg) {
                Text("Skillbase 是本地应用，技能文件都留在你的电脑上，不会上传。")
                    .font(TypeScale.body)
                    .foregroundStyle(Theme.muted)

                VStack(alignment: .leading, spacing: Space.sm) {
                    Text("默认部署方式")
                        .font(TypeScale.bodyStrong)
                        .appleTight()
                    Picker("模式", selection: Bindable(store).deployMode) {
                        ForEach(DeployMode.allCases, id: \.self) { mode in
                            Text(mode.label).tag(mode)
                        }
                    }
                    .pickerStyle(.radioGroup)
                    .labelsHidden()
                    .font(TypeScale.body)
                }
                .saasCard()

                VStack(alignment: .leading, spacing: Space.sm) {
                    Text("扫描目录")
                        .font(TypeScale.bodyStrong)
                        .appleTight()
                    ForEach(AIPlatform.allCases) { platform in
                        VStack(alignment: .leading, spacing: Space.xxs) {
                            Text(platform.displayName)
                                .font(TypeScale.captionStrong)
                                .foregroundStyle(Theme.text)
                            ForEach(SkillCatalog.platformRoots(platform), id: \.url) { root in
                                HStack {
                                    Text(root.url.path.replacingOccurrences(
                                        of: FileManager.default.homeDirectoryForCurrentUser.path,
                                        with: "~"
                                    ))
                                    .font(.system(size: 12, design: .monospaced))
                                    .foregroundStyle(Theme.muted)
                                    Spacer()
                                    Text(root.writable ? "可写" : "只读")
                                        .font(TypeScale.micro)
                                        .foregroundStyle(Theme.muted)
                                }
                            }
                        }
                        .padding(.bottom, Space.xs)
                    }
                }
                .saasCard()

                HStack {
                    Button("打开知识库文件夹") {
                        try? FileManager.default.createDirectory(
                            at: SkillCatalog.libraryRoot,
                            withIntermediateDirectories: true
                        )
                        store.reveal(SkillCatalog.libraryRoot)
                    }
                    .buttonStyle(GhostButtonStyle())
                    Button("重新扫描") {
                        Task { await store.scan() }
                    }
                    .buttonStyle(AccentButtonStyle())
                }
            }
            .padding(Space.xl)
            .frame(maxWidth: 820, alignment: .leading)
        }
        .background(Theme.bg)
    }
}
