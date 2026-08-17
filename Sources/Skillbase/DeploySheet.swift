import SwiftUI

struct DeploySheet: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: Space.md) {
            HStack {
                VStack(alignment: .leading, spacing: Space.xxs) {
                    Text("部署技能")
                        .font(TypeScale.tagline)
                        .appleTight(-0.23)
                    Text(store.selectedGroup?.name ?? "")
                        .font(TypeScale.body)
                        .foregroundStyle(Theme.muted)
                }
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .foregroundStyle(Theme.muted)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(PressScaleButtonStyle())
                .pointingCursor()
            }

            Text("部署后，对应桌面端在新对话里就能发现这个 skill。")
                .font(TypeScale.body)
                .foregroundStyle(Theme.muted)

            VStack(alignment: .leading, spacing: Space.xs) {
                ForEach(AIPlatform.managedTargets, id: \.self) { platform in
                    let installed = store.selectedGroup?.platforms.contains(platform) == true
                    Toggle(isOn: Binding(
                        get: { store.pendingDeployTargets.contains(platform) },
                        set: { on in
                            if on {
                                store.pendingDeployTargets.insert(platform)
                            } else {
                                store.pendingDeployTargets.remove(platform)
                            }
                        }
                    )) {
                        HStack {
                            PlatformChip(platform: platform, installed: true)
                            Text(installed ? "已存在，可覆盖" : "尚未安装")
                                .font(TypeScale.caption)
                                .foregroundStyle(Theme.muted)
                            Spacer()
                            if let info = store.platforms.first(where: { $0.platform == platform }) {
                                Text(info.detected ? "已识别" : "目录将自动创建")
                                    .font(TypeScale.fine)
                                    .foregroundStyle(Theme.muted)
                            }
                        }
                    }
                    .toggleStyle(.checkbox)
                    .font(TypeScale.body)
                }
            }
            .saasCard()

            Picker("写入方式", selection: Bindable(store).deployMode) {
                ForEach(DeployMode.allCases, id: \.self) { mode in
                    Text(mode.label).tag(mode)
                }
            }
            .pickerStyle(.radioGroup)
            .font(TypeScale.body)

            Toggle("若目标已存在则覆盖", isOn: Bindable(store).overwriteOnDeploy)
                .toggleStyle(.checkbox)
                .font(TypeScale.body)

            HStack {
                Spacer()
                Button("取消") { dismiss() }
                    .buttonStyle(GhostButtonStyle())
                Button("开始部署") {
                    Task { await store.deploySelected() }
                }
                .buttonStyle(AccentButtonStyle())
                .disabled(store.pendingDeployTargets.isEmpty)
            }
        }
        .padding(Space.lg)
        .frame(width: 560)
        .background(Theme.card)
    }
}
