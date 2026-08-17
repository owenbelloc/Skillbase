import Foundation
import SwiftUI

enum SkillKind: String, Codable, Hashable {
    case user
    case builtin
    case plugin
    case library

    var label: String {
        switch self {
        case .user: return "用户"
        case .builtin: return "内置"
        case .plugin: return "插件"
        case .library: return "知识库"
        }
    }
}

enum AIPlatform: String, CaseIterable, Identifiable, Codable, Hashable {
    case cursor
    case claude
    case codex
    case kimi
    case agents
    case skillbase

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .cursor: return "Cursor"
        case .claude: return "Claude"
        case .codex: return "Codex"
        case .kimi: return "Kimi"
        case .agents: return "Open Skills"
        case .skillbase: return "Skillbase"
        }
    }

    var subtitle: String {
        switch self {
        case .cursor: return "Cursor 桌面端 / CLI"
        case .claude: return "Claude 桌面端 / Claude Code"
        case .codex: return "Codex 桌面端 / CLI"
        case .kimi: return "Kimi 桌面端 / Kimi Code"
        case .agents: return "跨平台共享目录"
        case .skillbase: return "本地知识库"
        }
    }

    var symbol: String {
        switch self {
        case .cursor: return "cursorarrow.rays"
        case .claude: return "sparkle"
        case .codex: return "terminal"
        case .kimi: return "moon.stars"
        case .agents: return "square.stack.3d.up"
        case .skillbase: return "books.vertical"
        }
    }

    var tint: Color {
        switch self {
        case .cursor: return Color(hex: 0x374151)
        case .claude: return Color(hex: 0xD97757)
        case .codex: return Color(hex: 0x16A34A)
        case .kimi: return Color(hex: 0x3B82F6)
        case .agents: return Color(hex: 0x8B5CF6)
        case .skillbase: return Theme.accent
        }
    }

    var isDesktopTarget: Bool {
        switch self {
        case .cursor, .claude, .codex, .kimi: return true
        case .agents, .skillbase: return false
        }
    }

    static var managedTargets: [AIPlatform] {
        [.cursor, .claude, .codex, .kimi, .agents]
    }
}

struct PlatformRoot: Hashable {
    var url: URL
    var kind: SkillKind
    var writable: Bool
    var immediateOnly: Bool
}

struct PlatformInfo: Identifiable, Hashable {
    var platform: AIPlatform
    var appInstalled: Bool
    var configPresent: Bool
    var appPath: URL?
    var skillCount: Int
    var writable: Bool
    var roots: [PlatformRoot]

    var id: AIPlatform { platform }
    var detected: Bool { appInstalled || configPresent }
}

struct SkillInstance: Identifiable, Hashable {
    var platform: AIPlatform
    var folder: URL
    var skillFile: URL
    var kind: SkillKind
    var writable: Bool
    var isSymlink: Bool
    var modifiedAt: Date
    var fileCount: Int

    var id: String { folder.path }
}

struct SkillGroup: Identifiable, Hashable {
    var name: String
    var description: String
    var body: String
    var instances: [SkillInstance]

    var id: String { name.lowercased() }

    var platforms: Set<AIPlatform> {
        Set(instances.map(\.platform))
    }

    var latestModified: Date {
        instances.map(\.modifiedAt).max() ?? .distantPast
    }

    var primary: SkillInstance? {
        instances.first(where: { $0.platform == .skillbase })
            ?? instances.first(where: { $0.kind == .library })
            ?? instances.first(where: { $0.writable && $0.kind == .user })
            ?? instances.first
    }

    func instance(on platform: AIPlatform) -> SkillInstance? {
        instances.first(where: { $0.platform == platform })
    }

    var missingDesktopPlatforms: [AIPlatform] {
        AIPlatform.managedTargets.filter { $0.isDesktopTarget && !platforms.contains($0) }
    }
}

enum Route: Hashable {
    case dashboard
    case library
    case platform(AIPlatform)
    case create
    case settings
}

enum DeployMode: String, Codable, CaseIterable {
    case symlink
    case copy

    var label: String {
        switch self {
        case .symlink: return "符号链接（推荐，改一处全同步）"
        case .copy: return "复制文件（独立副本）"
        }
    }
}

struct Toast: Equatable {
    var text: String
    var isError: Bool
}

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}
