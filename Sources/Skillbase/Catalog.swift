import Foundation

enum SkillParser {
    static func parse(file: URL, folderName: String) -> (name: String, description: String, body: String) {
        let raw = (try? String(contentsOf: file, encoding: .utf8)) ?? ""
        return parse(text: raw, fallbackName: folderName)
    }

    static func parse(text: String, fallbackName: String) -> (name: String, description: String, body: String) {
        let normalized = text.replacingOccurrences(of: "\r\n", with: "\n")
        guard normalized.hasPrefix("---") else {
            return (fallbackName, "", normalized.trimmingCharacters(in: .whitespacesAndNewlines))
        }

        let rest = String(normalized.dropFirst(3)).trimmingCharacters(in: .newlines)
        guard let end = rest.range(of: "\n---") else {
            return (fallbackName, "", normalized)
        }

        let yaml = String(rest[..<end.lowerBound])
        var body = String(rest[end.upperBound...])
        if body.hasPrefix("\n") { body.removeFirst() }

        let meta = parseYAML(yaml)
        let name = sanitizeName(meta["name"] ?? fallbackName)
        let description = (meta["description"] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return (name.isEmpty ? fallbackName : name, description, body)
    }

    static func sanitizeName(_ raw: String) -> String {
        let lowered = raw.lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .replacingOccurrences(of: "_", with: "-")
        let allowed = lowered.unicodeScalars.map { scalar -> Character in
            CharacterSet.alphanumerics.contains(scalar) || scalar == "-" ? Character(scalar) : "-"
        }
        let collapsed = String(allowed)
            .replacingOccurrences(of: "--+", with: "-", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
        return String(collapsed.prefix(64))
    }

    static func render(name: String, description: String, body: String) -> String {
        let trimmedBody = body.trimmingCharacters(in: .whitespacesAndNewlines)
        return """
        ---
        name: \(name)
        description: \(yamlEscape(description))
        ---

        \(trimmedBody.isEmpty ? "# \(name)\n" : trimmedBody)

        """
    }

    private static func yamlEscape(_ value: String) -> String {
        if value.contains("\n") || value.contains(":") || value.contains("#") || value.count > 80 {
            let indented = value.split(separator: "\n", omittingEmptySubsequences: false)
                .map { "  \($0)" }
                .joined(separator: "\n")
            return ">-\n\(indented)"
        }
        return value
    }

    private static func parseYAML(_ yaml: String) -> [String: String] {
        var result: [String: String] = [:]
        let lines = yaml.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        var index = 0
        while index < lines.count {
            let line = lines[index]
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty || trimmed.hasPrefix("#") {
                index += 1
                continue
            }
            guard let colon = line.firstIndex(of: ":") else {
                index += 1
                continue
            }
            let key = String(line[..<colon]).trimmingCharacters(in: .whitespaces)
            var value = String(line[line.index(after: colon)...]).trimmingCharacters(in: .whitespaces)
            if value == ">" || value == ">|" || value == ">-" || value == "|" || value == "|-" || value == "|+" {
                var collected: [String] = []
                index += 1
                while index < lines.count {
                    let next = lines[index]
                    if next.isEmpty {
                        collected.append("")
                        index += 1
                        continue
                    }
                    let indent = next.prefix { $0 == " " }.count
                    if indent >= 2 {
                        collected.append(String(next.dropFirst(min(2, indent))))
                        index += 1
                    } else {
                        break
                    }
                }
                result[key] = collected.joined(separator: " ").replacingOccurrences(of: "  +", with: " ", options: .regularExpression)
                continue
            }
            if (value.hasPrefix("\"") && value.hasSuffix("\"") && value.count >= 2)
                || (value.hasPrefix("'") && value.hasSuffix("'") && value.count >= 2) {
                value = String(value.dropFirst().dropLast())
            }
            result[key] = value
            index += 1
        }
        return result
    }
}

enum SkillCatalog {
    static var home: URL {
        FileManager.default.homeDirectoryForCurrentUser
    }

    static var libraryRoot: URL {
        home
            .appendingPathComponent("Library/Application Support/Skillbase/Library")
    }

    static func platformRoots(_ platform: AIPlatform) -> [PlatformRoot] {
        switch platform {
        case .cursor:
            return [
                root(".cursor/skills", kind: .user, writable: true, immediate: true),
                root(".cursor/skills-cursor", kind: .builtin, writable: false, immediate: true),
                root(".cursor/plugins", kind: .plugin, writable: false, immediate: false)
            ]
        case .claude:
            return [
                root(".claude/skills", kind: .user, writable: true, immediate: true),
                root(".claude/plugins", kind: .plugin, writable: false, immediate: false)
            ]
        case .codex:
            return [
                root(".codex/skills", kind: .user, writable: true, immediate: true),
                root(".codex/skills/.system", kind: .builtin, writable: false, immediate: true)
            ]
        case .kimi:
            var items: [PlatformRoot] = [
                root(".kimi/skills", kind: .user, writable: true, immediate: true),
                root(".kimi-code/skills", kind: .user, writable: true, immediate: true)
            ]
            let daimon = home.appendingPathComponent(
                "Library/Application Support/kimi-desktop/daimon-share/daimon/runtime/kimi-code/home/plugins"
            )
            items.append(PlatformRoot(url: daimon, kind: .plugin, writable: false, immediateOnly: false))
            return items
        case .agents:
            return [
                root(".agents/skills", kind: .user, writable: true, immediate: true)
            ]
        case .skillbase:
            return [
                PlatformRoot(url: libraryRoot, kind: .library, writable: true, immediateOnly: true)
            ]
        }
    }

    static func writableRoots(for platform: AIPlatform) -> [URL] {
        platformRoots(platform).filter(\.writable).map(\.url)
    }

    static func writableRoot(for platform: AIPlatform) -> URL? {
        writableRoots(for: platform).first
    }

    static func appPath(for platform: AIPlatform) -> URL? {
        let fm = FileManager.default
        let candidates: [String]
        switch platform {
        case .cursor: candidates = ["Cursor.app"]
        case .claude: candidates = ["Claude.app"]
        case .codex: candidates = ["ChatGPT.app", "ChatGPT Atlas.app", "Codex.app"]
        case .kimi: candidates = ["Kimi.app"]
        case .agents, .skillbase: return nil
        }
        let bases = [
            URL(fileURLWithPath: "/Applications"),
            home.appendingPathComponent("Applications")
        ]
        for base in bases {
            for name in candidates {
                let url = base.appendingPathComponent(name)
                if fm.fileExists(atPath: url.path) { return url }
            }
        }
        return nil
    }

    static func configPresent(for platform: AIPlatform) -> Bool {
        let fm = FileManager.default
        switch platform {
        case .cursor:
            return fm.fileExists(atPath: home.appendingPathComponent(".cursor").path)
        case .claude:
            return fm.fileExists(atPath: home.appendingPathComponent(".claude").path)
        case .codex:
            return fm.fileExists(atPath: home.appendingPathComponent(".codex").path)
        case .kimi:
            return fm.fileExists(atPath: home.appendingPathComponent(".kimi-code").path)
                || fm.fileExists(atPath: home.appendingPathComponent(".kimi").path)
                || fm.fileExists(atPath: home.appendingPathComponent("Library/Application Support/kimi-desktop").path)
        case .agents:
            return fm.fileExists(atPath: home.appendingPathComponent(".agents").path)
        case .skillbase:
            return true
        }
    }

    static func detectPlatforms() -> [PlatformInfo] {
        AIPlatform.allCases.map { platform in
            let roots = platformRoots(platform).filter { FileManager.default.fileExists(atPath: $0.url.path) }
            let app = appPath(for: platform)
            return PlatformInfo(
                platform: platform,
                appInstalled: app != nil,
                configPresent: configPresent(for: platform),
                appPath: app,
                skillCount: 0,
                writable: platformRoots(platform).contains(where: \.writable),
                roots: roots
            )
        }
    }

    static func scan() -> [SkillGroup] {
        var buckets: [String: SkillGroup] = [:]
        for platform in AIPlatform.allCases {
            for root in platformRoots(platform) {
                let folders = findSkillFolders(root: root)
                for folder in folders {
                    let skillFile = folder.appendingPathComponent("SKILL.md")
                    guard FileManager.default.fileExists(atPath: skillFile.path) else { continue }
                    let parsed = SkillParser.parse(file: skillFile, folderName: folder.lastPathComponent)
                    let instance = makeInstance(
                        platform: platform,
                        folder: folder,
                        skillFile: skillFile,
                        kind: root.kind,
                        writable: root.writable
                    )
                    let key = parsed.name.lowercased()
                    if var existing = buckets[key] {
                        if existing.description.isEmpty { existing.description = parsed.description }
                        if existing.body.isEmpty { existing.body = parsed.body }
                        if !existing.instances.contains(where: { $0.folder.path == instance.folder.path }) {
                            existing.instances.append(instance)
                        }
                        buckets[key] = existing
                    } else {
                        buckets[key] = SkillGroup(
                            name: parsed.name,
                            description: parsed.description,
                            body: parsed.body,
                            instances: [instance]
                        )
                    }
                }
            }
        }
        return buckets.values.sorted { lhs, rhs in
            if lhs.latestModified != rhs.latestModified {
                return lhs.latestModified > rhs.latestModified
            }
            return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }
    }

    static func deploy(
        group: SkillGroup,
        to platforms: [AIPlatform],
        mode: DeployMode,
        overwrite: Bool
    ) throws -> [AIPlatform] {
        guard let source = canonicalFolder(for: group) else {
            throw CatalogError.missingSource
        }
        var deployed: [AIPlatform] = []
        for platform in platforms {
            guard platform != .skillbase else { continue }
            let destRoots = writableRoots(for: platform)
            guard !destRoots.isEmpty else { continue }
            var wrote = false
            for destRoot in destRoots {
                try FileManager.default.createDirectory(at: destRoot, withIntermediateDirectories: true)
                let dest = destRoot.appendingPathComponent(group.name)
                if FileManager.default.fileExists(atPath: dest.path) {
                    let resolvedDest = dest.resolvingSymlinksInPath().standardizedFileURL
                    let resolvedSource = source.resolvingSymlinksInPath().standardizedFileURL
                    if resolvedDest.path == resolvedSource.path {
                        wrote = true
                        continue
                    }
                    if overwrite {
                        try FileManager.default.removeItem(at: dest)
                    } else {
                        throw CatalogError.alreadyExists(platform, dest.path)
                    }
                }
                switch mode {
                case .symlink:
                    try FileManager.default.createSymbolicLink(at: dest, withDestinationURL: source)
                case .copy:
                    try FileManager.default.copyItem(at: source, to: dest)
                }
                wrote = true
            }
            if wrote { deployed.append(platform) }
        }
        return deployed
    }

    static func importFolder(_ url: URL) throws -> URL {
        let skillFile = skillFileURL(in: url)
        guard FileManager.default.fileExists(atPath: skillFile.path) else {
            throw CatalogError.notASkill
        }
        let parsed = SkillParser.parse(file: skillFile, folderName: url.lastPathComponent)
        try FileManager.default.createDirectory(at: libraryRoot, withIntermediateDirectories: true)
        let dest = libraryRoot.appendingPathComponent(parsed.name)
        if FileManager.default.fileExists(atPath: dest.path) {
            try FileManager.default.removeItem(at: dest)
        }
        try FileManager.default.copyItem(at: url.resolvingSymlinksInPath(), to: dest)
        return dest
    }

    static func createSkill(name: String, description: String, body: String) throws -> URL {
        let clean = SkillParser.sanitizeName(name)
        guard !clean.isEmpty else { throw CatalogError.invalidName }
        try FileManager.default.createDirectory(at: libraryRoot, withIntermediateDirectories: true)
        let folder = libraryRoot.appendingPathComponent(clean)
        if FileManager.default.fileExists(atPath: folder.path) {
            throw CatalogError.alreadyExists(.skillbase, folder.path)
        }
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let markdown = SkillParser.render(name: clean, description: description, body: body)
        try markdown.write(to: folder.appendingPathComponent("SKILL.md"), atomically: true, encoding: .utf8)
        return folder
    }

    static func uninstall(instance: SkillInstance) throws {
        guard instance.writable, instance.kind != .builtin, instance.kind != .plugin else {
            throw CatalogError.readOnly
        }
        try FileManager.default.removeItem(at: instance.folder)
    }

    static func canonicalFolder(for group: SkillGroup) -> URL? {
        if let library = group.instance(on: .skillbase) {
            return library.folder.resolvingSymlinksInPath()
        }
        if let user = group.instances.first(where: { $0.writable && $0.kind == .user }) {
            return user.folder.resolvingSymlinksInPath()
        }
        return group.primary?.folder.resolvingSymlinksInPath()
    }

    private static func root(_ relative: String, kind: SkillKind, writable: Bool, immediate: Bool) -> PlatformRoot {
        PlatformRoot(
            url: home.appendingPathComponent(relative),
            kind: kind,
            writable: writable,
            immediateOnly: immediate
        )
    }

    private static func makeInstance(
        platform: AIPlatform,
        folder: URL,
        skillFile: URL,
        kind: SkillKind,
        writable: Bool
    ) -> SkillInstance {
        let fm = FileManager.default
        let values = try? folder.resourceValues(forKeys: [.isSymbolicLinkKey, .contentModificationDateKey])
        let fileCount = (try? fm.contentsOfDirectory(atPath: folder.path).count) ?? 1
        return SkillInstance(
            platform: platform,
            folder: folder,
            skillFile: skillFile,
            kind: kind,
            writable: writable && kind != .builtin && kind != .plugin,
            isSymlink: values?.isSymbolicLink == true,
            modifiedAt: values?.contentModificationDate ?? Date.distantPast,
            fileCount: fileCount
        )
    }

    private static func findSkillFolders(root: PlatformRoot) -> [URL] {
        let fm = FileManager.default
        guard fm.fileExists(atPath: root.url.path) else { return [] }
        if root.immediateOnly {
            return immediateSkills(at: root.url)
        }
        return deepSkills(at: root.url)
    }

    private static func immediateSkills(at url: URL) -> [URL] {
        let fm = FileManager.default
        let items = (try? fm.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        )) ?? []
        return items.filter { folder in
            fm.fileExists(atPath: folder.appendingPathComponent("SKILL.md").path)
        }
    }

    private static func deepSkills(at url: URL) -> [URL] {
        let fm = FileManager.default
        guard let enumerator = fm.enumerator(
            at: url,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else { return [] }

        var folders: [URL] = []
        let skip = Set(["node_modules", ".git", ".build", "Cache", "Code Cache", "GPUCache"])
        while let item = enumerator.nextObject() as? URL {
            if skip.contains(item.lastPathComponent) {
                enumerator.skipDescendants()
                continue
            }
            if enumerator.level > 8 { continue }
            if item.lastPathComponent.lowercased() == "skill.md" {
                folders.append(item.deletingLastPathComponent())
            }
        }
        return folders
    }

    private static func skillFileURL(in folder: URL) -> URL {
        let direct = folder.appendingPathComponent("SKILL.md")
        if FileManager.default.fileExists(atPath: direct.path) { return direct }
        return folder.appendingPathComponent("skill.md")
    }
}

enum CatalogError: LocalizedError {
    case missingSource
    case notASkill
    case invalidName
    case alreadyExists(AIPlatform, String)
    case readOnly

    var errorDescription: String? {
        switch self {
        case .missingSource:
            return "找不到可部署的源文件。"
        case .notASkill:
            return "这个文件夹里没有 SKILL.md。"
        case .invalidName:
            return "技能名称只能包含小写字母、数字和连字符。"
        case .alreadyExists(let platform, let path):
            return "\(platform.displayName) 上已存在该技能：\(path)"
        case .readOnly:
            return "内置或插件技能不能删除。"
        }
    }
}
