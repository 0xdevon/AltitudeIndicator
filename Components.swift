import SwiftUI
import CoreLocation

private enum AdaptiveTheme {
    static func cardBackground(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color(.secondarySystemGroupedBackground).opacity(0.78)
            : Color(.secondarySystemGroupedBackground).opacity(0.96)
    }

    static func elevatedBackground(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color.white.opacity(0.08)
            : Color(.tertiarySystemGroupedBackground)
    }

    static func border(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color.white.opacity(0.12)
            : Color.black.opacity(0.06)
    }

    static func shadow(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color.black.opacity(0.28)
            : Color.black.opacity(0.06)
    }

    static func compassRing(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color.white.opacity(0.14)
            : Color.primary.opacity(0.08)
    }

    static func majorTick(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color.white.opacity(0.72)
            : Color.primary.opacity(0.68)
    }

    static func minorTick(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color.white.opacity(0.24)
            : Color.secondary.opacity(0.28)
    }
}

struct GlassCard<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme

    var cornerRadius: CGFloat = 28
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(20)
            .background(
                AdaptiveTheme.cardBackground(for: colorScheme),
                in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(AdaptiveTheme.border(for: colorScheme), lineWidth: 1)
            }
            .shadow(color: AdaptiveTheme.shadow(for: colorScheme), radius: 10, x: 0, y: 5)
    }
}

struct MetricTile: View {
    @Environment(\.colorScheme) private var colorScheme

    let title: String
    let value: String
    let subtitle: String
    let icon: String

    var body: some View {
        GlassCard(cornerRadius: 24) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .frame(width: 34, height: 34)
                        .background(AdaptiveTheme.elevatedBackground(for: colorScheme), in: Circle())
                    Spacer()
                }
                Text(title)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.system(size: 25, weight: .bold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.55)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
    }
}

struct StatusPill: View {
    @Environment(\.colorScheme) private var colorScheme

    let text: String
    let isActive: Bool

    var body: some View {
        HStack(spacing: 7) {
            Circle()
                .fill(isActive ? Color.green : Color.secondary)
                .frame(width: 8, height: 8)
            Text(text)
                .font(.caption.weight(.semibold))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(AdaptiveTheme.elevatedBackground(for: colorScheme), in: Capsule())
        .accessibilityLabel("定位状态：\(text)")
    }
}

struct CompassDial: View {
    @Environment(\.colorScheme) private var colorScheme

    let degrees: Double?

    private var rotation: Angle {
        .degrees(-(degrees ?? 0))
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(AdaptiveTheme.elevatedBackground(for: colorScheme))
            Circle()
                .strokeBorder(AdaptiveTheme.compassRing(for: colorScheme), lineWidth: 1)
            CompassTicks(
                majorColor: AdaptiveTheme.majorTick(for: colorScheme),
                minorColor: AdaptiveTheme.minorTick(for: colorScheme)
            )
            VStack(spacing: 68) {
                Text("N").font(.headline.weight(.bold))
                Text("S").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
            }
            HStack(spacing: 68) {
                Text("W").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                Text("E").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
            }
            .rotationEffect(rotation)

            Image(systemName: "location.north.fill")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(.primary)
                .rotationEffect(.degrees(degrees ?? 0))
        }
        .frame(width: 160, height: 160)
        .animation(.snappy(duration: 0.18), value: degrees)
        .accessibilityLabel("罗盘")
    }
}

private struct CompassTicks: View {
    let majorColor: Color
    let minorColor: Color

    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)

            for tick in 0..<60 {
                let isMajor = tick.isMultiple(of: 5)
                let tickSize = CGSize(width: isMajor ? 2.2 : 1, height: isMajor ? 12 : 6)
                let rect = CGRect(
                    x: center.x - tickSize.width / 2,
                    y: 10,
                    width: tickSize.width,
                    height: tickSize.height
                )
                let angle = CGFloat(tick) * .pi / 30
                let transform = CGAffineTransform(translationX: center.x, y: center.y)
                    .rotated(by: angle)
                    .translatedBy(x: -center.x, y: -center.y)
                let path = Path(roundedRect: rect, cornerRadius: tickSize.width / 2)
                    .applying(transform)

                context.fill(path, with: .color(isMajor ? majorColor : minorColor))
            }
        }
        .allowsHitTesting(false)
    }
}

struct BackgroundGradient: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        LinearGradient(
            colors: gradientColors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    private var gradientColors: [Color] {
        if colorScheme == .dark {
            return [
                Color(.systemBackground),
                Color(.secondarySystemBackground),
                Color(.systemTeal).opacity(0.16)
            ]
        }

        return [
            Color(.systemBackground),
            Color(.secondarySystemBackground),
            Color(.systemTeal).opacity(0.08)
        ]
    }
}

struct ActionButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.callout.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
        }
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.capsule)
    }
}
