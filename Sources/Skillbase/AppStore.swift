import AppKit
import Foundation
import SwiftUI

@MainActor
@Observable
final class AppStore {
    var route: Route = .dashboard
    var groups: [SkillGroup] = []
    var platforms: [PlatformInfo] = []
    var selectedSkillID: String?
    var search: String = ""
    var isScanning = false
    var lastScan: Date?
    var toast: Toast?
    var deployMode: DeployMode = .symlink
    var showDeploySheet = false
    var pendingDeployTargets: Set<AIPlatform> = []
    var overwriteOnDeploy = true
    var wantsSearchFocus = false

    var selectedGroup: SkillGroup? {
        groups.first(where: { $0.id == selectedSkillID })
    }

    var filteredGroups: [SkillGroup] {
        let base: [SkillGroup]
        switch route {
        case .platform(let platform):
            base = groups.filter { $0.platforms.contains(platform) }
        default:
            base = groups
        }
        let query = search.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return base }
        return base.filter {
            $0.name.lowercased().contains(query)
                || $0.description.lowercased().contains(query)
        }
    }

    var uniqueSkillCount: Int { groups.count }

    var desktopPlatforms: [PlatformInfo] {
        platforms.filter { $0.platform.isDesktopTarget }
    }

    var coverageGaps: Int {
        groups.filter { !$0.missingDesktopPlatforms.isEmpty }.count
    }

    func scan() async {
        isScanning = true
        defer { isScanning = false }
        let scanned = await Task.detached(priority: .userInitiated) {
            SkillCatalog.scan()
        }.value
        var detected = SkillCatalog.detectPlatforms()
        var counts: [AIPlatform: Int] = [:]
        for group in scanned {
            for platform in group.platforms {
                counts[platform, default: 0] += 1
            }
        }
        for index in detected.indices {
            detected[index].skillCount = counts[detected[index].platform] ?? 0
        }
        groups = scanned
        platforms = detected
        lastScan = Date()
        if let id = selectedSkillID, !groups.contains(where: { $0.id == id }) {
            selectedSkillID = nil
        }
    }

    func peek(_ group: SkillGroup) {
        selectedSkillID = group.id
    }

    func select(_ route: Route) {
        self.route = route
        if case .library = route { return }
        if case .platform = route { return }
        selectedSkillID = nil
    }

    func openDeploy(for group: SkillGroup? = nil) {
        if let group {
            selectedSkillID = group.id
            pendingDeployTargets = Set(
                AIPlatform.managedTargets.filter { !group.platforms.contains($0) && $0.isDesktopTarget }
            )
            if pendingDeployTargets.isEmpty {
                pendingDeployTargets = Set(AIPlatform.managedTargets.filter(\.isDesktopTarget))
            }
        } else if let selectedGroup {
            pendingDeployTargets = Set(selectedGroup.missingDesktopPlatforms)
        }
        showDeploySheet = true
    }

    func deploySelected() async {
        guard let group = selectedGroup else { return }
        let targets = AIPlatform.managedTargets.filter { pendingDeployTargets.contains($0) }
        guard !targets.isEmpty else { return }
        do {
            let deployed = try SkillCatalog.deploy(
                group: group,
                to: targets,
                mode: deployMode,
                overwrite: overwriteOnDeploy
            )
            await scan()
            selectedSkillID = group.id
            showDeploySheet = false
            presentToast("已部署到 \(deployed.map(\.displayName).joined(separator: "、"))。新开一轮对话即可使用。")
        } catch {
            presentToast(error.localizedDescription, error: true)
        }
    }

    func createAndDeploy(name: String, description: String, body: String, targets: [AIPlatform]) async {
        do {
            _ = try SkillCatalog.createSkill(name: name, description: description, body: body)
            await scan()
            selectedSkillID = SkillParser.sanitizeName(name)
            if !targets.isEmpty, let group = selectedGroup {
                _ = try SkillCatalog.deploy(
                    group: group,
                    to: targets,
                    mode: deployMode,
                    overwrite: overwriteOnDeploy
                )
                await scan()
                selectedSkillID = group.id
            }
            route = .library
            presentToast("技能已写入知识库\(targets.isEmpty ? "" : "并完成部署")。")
        } catch {
            presentToast(error.localizedDescription, error: true)
        }
    }

    func importFromPanel() async {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "选择包含 SKILL.md 的技能文件夹"
        panel.prompt = "导入"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            let dest = try SkillCatalog.importFolder(url)
            await scan()
            selectedSkillID = dest.lastPathComponent.lowercased()
            route = .library
            presentToast("已导入到知识库：\(dest.lastPathComponent)")
        } catch {
            presentToast(error.localizedDescription, error: true)
        }
    }

    func uninstall(_ instance: SkillInstance) async {
        do {
            try SkillCatalog.uninstall(instance: instance)
            await scan()
            presentToast("已从 \(instance.platform.displayName) 移除。")
        } catch {
            presentToast(error.localizedDescription, error: true)
        }
    }

    func reveal(_ url: URL) {
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    func openInEditor(_ url: URL) {
        NSWorkspace.shared.open(url)
    }

    func presentToast(_ text: String, error: Bool = false) {
        toast = Toast(text: text, isError: error)
        Task {
            try? await Task.sleep(for: .seconds(3.2))
            if toast?.text == text {
                toast = nil
            }
        }
    }
}
