import AppKit
import SwiftUI

enum Theme {
    static let accent = Color(hex: 0x0066CC)
    static let accentFocus = Color(hex: 0x0071E3)
    static let accentOnDark = Color(hex: 0x2997FF)
    static let accentSoft = Color(hex: 0x0071E3)
    static let blue = Color(hex: 0x0066CC)
    static let yellow = Color(hex: 0x7A7A7A)
    static let teal = Color(hex: 0x0066CC)
    static let purple = Color(hex: 0x1D1D1F)
    static let orange = Color(hex: 0x0066CC)
    static let bg = Color(hex: 0xF5F5F7)
    static let canvas = Color(hex: 0xFFFFFF)
    static let sidebar = Color(hex: 0xF5F5F7)
    static let card = Color(hex: 0xFFFFFF)
    static let cardHover = Color(hex: 0xFAFAFC)
    static let elevated = Color(hex: 0xFAFAFC)
    static let input = Color(hex: 0xFFFFFF)
    static let border = Color(hex: 0xE0E0E0)
    static let borderStrong = Color(hex: 0xE0E0E0)
    static let text = Color(hex: 0x1D1D1F)
    static let muted = Color(hex: 0x7A7A7A)
    static let faint = Color(hex: 0x7A7A7A)
    static let inkMuted = Color(hex: 0x333333)
    static let success = Color(hex: 0x0066CC)
    static let warning = Color(hex: 0x7A7A7A)
    static let danger = Color(hex: 0x1D1D1F)
    static let shadow = Color.clear

    static let sidebarWidth: CGFloat = 248
    static let detailWidth: CGFloat = 380
    static let radius = Radius.lg
}

enum Radius {
    static let xs: CGFloat = 5
    static let sm: CGFloat = 8
    static let md: CGFloat = 11
    static let lg: CGFloat = 18
}

enum Space {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 17
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

enum TypeScale {
    static let displayLG = Font.system(size: 40, weight: .semibold)
    static let displayMD = Font.system(size: 34, weight: .semibold)
    static let lead = Font.system(size: 28, weight: .regular)
    static let tagline = Font.system(size: 21, weight: .semibold)
    static let body = Font.system(size: 17, weight: .regular)
    static let bodyStrong = Font.system(size: 17, weight: .semibold)
    static let caption = Font.system(size: 14, weight: .regular)
    static let captionStrong = Font.system(size: 14, weight: .semibold)
    static let fine = Font.system(size: 12, weight: .regular)
    static let micro = Font.system(size: 10, weight: .regular)
}

struct CardModifier: ViewModifier {
    var padding: CGFloat = Space.lg

    func body(content: Content) -> some View {
        content
            .padding(padding)
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

extension View {
    func saasCard(padding: CGFloat = Space.lg) -> some View {
        modifier(CardModifier(padding: padding))
    }

    func appleTight(_ px: CGFloat = -0.37) -> some View {
        tracking(px / 16)
    }

    func pointingCursor() -> some View {
        modifier(PointingCursorModifier())
    }
}

struct PointingCursorModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.onHover { inside in
            if inside {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}

struct AccentButtonStyle: ButtonStyle {
    var fill: Color = Theme.accent
    var foreground: Color = .white

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(TypeScale.body)
            .foregroundStyle(foreground)
            .padding(.horizontal, 22)
            .padding(.vertical, 11)
            .background(Capsule().fill(fill))
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
            .pointingCursor()
    }
}

struct GhostButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(TypeScale.body)
            .foregroundStyle(Theme.accent)
            .padding(.horizontal, 22)
            .padding(.vertical, 11)
            .background(Capsule().fill(Color.clear))
            .overlay(Capsule().stroke(Theme.accent, lineWidth: 1))
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
            .pointingCursor()
    }
}

struct PercentPill: View {
    var text: String
    var positive: Bool = true

    var body: some View {
        Text(text)
            .font(TypeScale.fine)
            .foregroundStyle(positive ? Theme.accent : Theme.muted)
            .padding(.horizontal, Space.xs)
            .padding(.vertical, Space.xxs)
            .background(Capsule().fill(positive ? Theme.accent.opacity(0.08) : Theme.elevated))
    }
}

struct StatusPill: View {
    var text: String
    var color: Color

    var body: some View {
        Text(text)
            .font(TypeScale.fine)
            .foregroundStyle(color)
            .padding(.horizontal, Space.xs)
            .padding(.vertical, Space.xxs)
            .background(Capsule().fill(color.opacity(0.08)))
    }
}

struct PlatformChip: View {
    var platform: AIPlatform
    var compact: Bool = false
    var installed: Bool = true

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(installed ? Theme.accent : Theme.border)
                .frame(width: 6, height: 6)
            if !compact {
                Text(platform.displayName)
                    .font(TypeScale.fine)
            }
        }
        .foregroundStyle(installed ? Theme.text : Theme.muted)
        .padding(.horizontal, compact ? 6 : Space.xs)
        .padding(.vertical, Space.xxs)
        .background(Capsule().stroke(installed ? Theme.accent.opacity(0.35) : Theme.border, lineWidth: 1))
        .help(installed ? "\(platform.displayName) 已安装" : "\(platform.displayName) 未安装")
    }
}

struct KindBadge: View {
    var kind: SkillKind

    var body: some View {
        Text(kind.label)
            .font(TypeScale.fine)
            .foregroundStyle(Theme.muted)
            .padding(.horizontal, Space.xs)
            .padding(.vertical, Space.xxs)
            .background(Capsule().stroke(Theme.border, lineWidth: 1))
    }
}

struct EmptyState: View {
    var symbol: String
    var title: String
    var message: String

    var body: some View {
        VStack(spacing: Space.sm) {
            Image(systemName: symbol)
                .font(.system(size: 28, weight: .light))
                .foregroundStyle(Theme.accent)
            Text(title)
                .font(TypeScale.tagline)
                .foregroundStyle(Theme.text)
                .appleTight(-0.23)
            Text(message)
                .font(TypeScale.caption)
                .foregroundStyle(Theme.muted)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 360)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct MiniSparkline: View {
    var values: [Int]
    var color: Color = Theme.accent

    var body: some View {
        let maxValue = max(values.max() ?? 1, 1)
        HStack(alignment: .bottom, spacing: 3) {
            ForEach(Array(values.enumerated()), id: \.offset) { index, value in
                Capsule()
                    .fill(color.opacity(index == values.count - 1 ? 1 : 0.22))
                    .frame(width: 3, height: max(4, CGFloat(value) / CGFloat(maxValue) * 22))
            }
        }
        .frame(height: 22)
    }
}
