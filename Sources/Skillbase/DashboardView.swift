import SwiftUI

struct DashboardView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Space.lg) {
                metrics
                HStack(alignment: .top, spacing: Space.lg) {
                    heatmap
                    assetsGrid
                    departmentGauge
                }
                HStack(alignment: .top, spacing: Space.lg) {
                    onboarding
                    expirations
                }
            }
            .padding(.leading, Space.xs)
            .padding(.trailing, Space.lg)
            .padding(.bottom, Space.xxl)
        }
        .background(Theme.bg)
    }

    private var metrics: some View {
        HStack(spacing: Space.sm) {
            kpi("技能总数", value: "\(store.uniqueSkillCount)", values: weekdayTotals, pill: "已索引") {
                store.select(.library)
            }
            kpi("已连接平台", value: "\(store.desktopPlatforms.filter(\.detected).count)", values: store.desktopPlatforms.map(\.skillCount), pill: percent(store.desktopPlatforms.filter(\.detected).count, of: max(store.desktopPlatforms.count, 1))) {}
            kpi("覆盖完整", value: "\(max(store.uniqueSkillCount - store.coverageGaps, 0))", values: weekdayUser, pill: percent(max(store.uniqueSkillCount - store.coverageGaps, 0), of: max(store.uniqueSkillCount, 1))) {}
            kpi("待部署", value: "\(store.coverageGaps)", values: weekdayGaps, pill: store.coverageGaps == 0 ? "已齐" : "需补齐") {}
        }
    }

    private func kpi(_ title: String, value: String, values: [Int], pill: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: Space.xs) {
                Text(title)
                    .font(TypeScale.caption)
                    .foregroundStyle(Theme.muted)
                HStack(alignment: .bottom) {
                    Text(value)
                        .font(TypeScale.displayMD)
                        .foregroundStyle(Theme.text)
                        .appleTight()
                    Spacer()
                    MiniSparkline(values: values.isEmpty ? [2, 3, 4, 6, 5, 8, 7] : values)
                }
                PercentPill(text: pill)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(PressScaleButtonStyle())
        .help("\(title)：\(value)")
        .modifier(UtilityCard())
        .pointingCursor()
    }

    private var heatmap: some View {
        VStack(alignment: .leading, spacing: Space.sm) {
            Text("技能活跃分布")
                .font(TypeScale.bodyStrong)
                .appleTight()
            Text("按最近更新时间点亮")
                .font(TypeScale.caption)
                .foregroundStyle(Theme.muted)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 12), spacing: 6) {
                ForEach(heatDots) { dot in
                    Circle()
                        .fill(Theme.accent.opacity(dot.opacity))
                        .frame(width: dot.size, height: dot.size)
                        .frame(maxWidth: .infinity, minHeight: 16)
                        .help("\(dot.label)：\(dot.value) 个技能")
                        .pointingCursor()
                }
            }
            .padding(.top, Space.xxs)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(UtilityCard())
    }

    private var assetsGrid: some View {
        VStack(alignment: .leading, spacing: Space.sm) {
            Text("平台概览")
                .font(TypeScale.bodyStrong)
                .appleTight()
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Space.sm) {
                ForEach(store.desktopPlatforms) { info in
                    Button {
                        store.select(.platform(info.platform))
                    } label: {
                        VStack(alignment: .leading, spacing: Space.xxs) {
                            Text("\(info.skillCount)")
                                .font(TypeScale.displayMD)
                                .foregroundStyle(Theme.text)
                                .appleTight()
                            Text(info.platform.displayName)
                                .font(TypeScale.caption)
                                .foregroundStyle(Theme.muted)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(Space.sm)
                        .background(
                            RoundedRectangle(cornerRadius: Radius.sm, style: .continuous)
                                .fill(Theme.bg)
                        )
                    }
                    .buttonStyle(PressScaleButtonStyle())
                    .pointingCursor()
                    .help("查看 \(info.platform.displayName) 的技能")
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(UtilityCard())
    }

    private var departmentGauge: some View {
        VStack(alignment: .leading, spacing: Space.sm) {
            Text("技能类型")
                .font(TypeScale.bodyStrong)
                .appleTight()
            SemiGauge(slices: kindSlices, total: store.uniqueSkillCount)
                .frame(height: 150)
            HStack {
                ForEach(kindSlices.prefix(4)) { slice in
                    HStack(spacing: 5) {
                        Circle().fill(slice.color).frame(width: 8, height: 8)
                        Text(slice.label)
                            .font(TypeScale.fine)
                            .foregroundStyle(Theme.muted)
                    }
                    .help("\(slice.label) \(slice.value)")
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(UtilityCard())
    }

    private var onboarding: some View {
        VStack(alignment: .leading, spacing: Space.md) {
            Text("平台接入")
                .font(TypeScale.bodyStrong)
                .appleTight()
            ForEach(store.desktopPlatforms) { info in
                Button {
                    store.select(.platform(info.platform))
                } label: {
                    HStack(spacing: Space.sm) {
                        Image(systemName: info.detected ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(info.detected ? Theme.accent : Theme.border)
                            .font(.system(size: 18, weight: .regular))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(info.platform.displayName)
                                .font(TypeScale.bodyStrong)
                            Text(info.detected ? "\(info.skillCount) 个技能已扫描" : "尚未检测到桌面端")
                                .font(TypeScale.caption)
                                .foregroundStyle(Theme.muted)
                        }
                        Spacer()
                        if info.detected {
                            StatusPill(text: "Completed", color: Theme.accent)
                        } else {
                            Text("0/1")
                                .font(TypeScale.caption)
                                .foregroundStyle(Theme.muted)
                        }
                    }
                    .padding(.vertical, Space.xxs)
                }
                .buttonStyle(PressScaleButtonStyle())
                .pointingCursor()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(UtilityCard())
    }

    private var expirations: some View {
        VStack(alignment: .leading, spacing: Space.md) {
            Text("待补齐覆盖")
                .font(TypeScale.bodyStrong)
                .appleTight()
            if gapRows.isEmpty {
                Text("所有技能都已覆盖已识别的桌面端。")
                    .font(TypeScale.body)
                    .foregroundStyle(Theme.muted)
                    .frame(maxWidth: .infinity, minHeight: 120, alignment: .leading)
            } else {
                ForEach(gapRows) { group in
                    Button {
                        store.peek(group)
                    } label: {
                        VStack(alignment: .leading, spacing: Space.xs) {
                            HStack {
                                Text(group.name)
                                    .font(TypeScale.bodyStrong)
                                    .lineLimit(1)
                                Spacer()
                                Text("\(group.missingDesktopPlatforms.count) 个平台未装")
                                    .font(TypeScale.fine)
                                    .foregroundStyle(Theme.muted)
                            }
                            GeometryReader { geo in
                                let ratio = CGFloat(group.platforms.filter(\.isDesktopTarget).count) / 4
                                ZStack(alignment: .leading) {
                                    Capsule().fill(Theme.border)
                                    Capsule().fill(Theme.accent)
                                        .frame(width: max(8, geo.size.width * ratio))
                                }
                            }
                            .frame(height: 4)
                        }
                        .padding(.vertical, Space.xxs)
                    }
                    .buttonStyle(PressScaleButtonStyle())
                    .pointingCursor()
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(UtilityCard())
    }

    private func percent(_ value: Int, of total: Int) -> String {
        "\(Int((Double(value) / Double(max(total, 1))) * 100))%"
    }

    private var gapRows: [SkillGroup] {
        Array(store.groups.filter { !$0.missingDesktopPlatforms.isEmpty }.prefix(5))
    }

    private var weekdayTotals: [Int] { weekdaySeries.map { $0.user + $0.plugin } }
    private var weekdayUser: [Int] { weekdaySeries.map(\.user) }
    private var weekdayGaps: [Int] { weekdaySeries.map(\.plugin) }

    private var weekdaySeries: [(user: Int, plugin: Int)] {
        var user = Array(repeating: 0, count: 7)
        var plugin = Array(repeating: 0, count: 7)
        let cal = Calendar.current
        for group in store.groups {
            let index = (cal.component(.weekday, from: group.latestModified) + 5) % 7
            if group.instances.contains(where: { $0.kind == .user || $0.kind == .library }) {
                user[index] += 1
            } else {
                plugin[index] += 1
            }
        }
        return zip(user, plugin).map { (user: $0, plugin: $1) }
    }

    private var heatDots: [HeatDot] {
        var buckets = Array(repeating: 0, count: 84)
        let cal = Calendar.current
        for group in store.groups {
            let month = max(cal.component(.month, from: group.latestModified) - 1, 0)
            let weekday = (cal.component(.weekday, from: group.latestModified) + 5) % 7
            let index = min(month, 11) + weekday * 12
            if buckets.indices.contains(index) {
                buckets[index] += 1
            }
        }
        let maxValue = max(buckets.max() ?? 1, 1)
        return buckets.enumerated().map { index, value in
            let t = CGFloat(value) / CGFloat(maxValue)
            return HeatDot(
                id: "\(index)",
                label: "单元 \(index + 1)",
                value: value,
                size: 8 + t * 10,
                opacity: value == 0 ? 0.12 : 0.28 + t * 0.72
            )
        }
    }

    private var kindSlices: [GaugeSlice] {
        var counts: [SkillKind: Int] = [:]
        for group in store.groups {
            counts[group.primary?.kind ?? .user, default: 0] += 1
        }
        let mapping: [(SkillKind, String, Double)] = [
            (.user, "用户", 1),
            (.plugin, "插件", 0.72),
            (.builtin, "内置", 0.44),
            (.library, "知识库", 0.22)
        ]
        return mapping.compactMap { kind, label, opacity in
            let value = counts[kind] ?? 0
            guard value > 0 else { return nil }
            return GaugeSlice(id: kind.rawValue, label: label, value: value, color: Theme.accent.opacity(opacity))
        }
    }
}

private struct HeatDot: Identifiable {
    var id: String
    var label: String
    var value: Int
    var size: CGFloat
    var opacity: CGFloat
}

private struct GaugeSlice: Identifiable {
    var id: String
    var label: String
    var value: Int
    var color: Color
}

private struct UtilityCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(Space.lg)
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

private struct SemiGauge: View {
    var slices: [GaugeSlice]
    var total: Int

    var body: some View {
        ZStack {
            Canvas { context, size in
                let center = CGPoint(x: size.width / 2, y: size.height - 8)
                let radius = min(size.width, size.height * 2) / 2 - 14
                let totalValue = max(slices.map(\.value).reduce(0, +), 1)
                var start = Angle.degrees(180)
                for slice in slices {
                    let fraction = Double(slice.value) / Double(totalValue)
                    let end = start + .degrees(180 * fraction)
                    var path = Path()
                    path.addArc(center: center, radius: radius, startAngle: start, endAngle: end, clockwise: false)
                    context.stroke(
                        path,
                        with: .color(slice.color),
                        style: StrokeStyle(lineWidth: 16, lineCap: .round)
                    )
                    start = end
                }
            }
            VStack(spacing: 2) {
                Text("\(total)")
                    .font(TypeScale.displayMD)
                    .appleTight()
                Text("Skills")
                    .font(TypeScale.caption)
                    .foregroundStyle(Theme.muted)
            }
            .offset(y: 18)
        }
        .help("按类型查看技能数量")
    }
}
