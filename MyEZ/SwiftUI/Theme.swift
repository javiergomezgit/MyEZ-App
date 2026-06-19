import SwiftUI

enum AppColors {
    static let backgroundTop = Color("backgroundTop")
    static let backgroundBottom = Color("backgroundBottom")

    static let surfacePrimary = Color("surfacePrimary")
    static let surfaceSecondary = Color("surfaceSecondary")
    static let surfaceElevated = Color("surfaceElevated")

    static let borderSubtle = Color("borderSubtle")
    static let borderStrong = Color("borderStrong")

    static let textPrimary = Color("textPrimary")
    static let textSecondary = Color("textSecondary")
    static let textMuted = Color("textMuted")

    static let accentBlue = Color("accentBlue")
    static let buttonBlueStart = Color("buttonBlueStart")
    static let buttonBlueEnd = Color("buttonBlueEnd")

    static let accentRed = Color("accentRed")
    static let buttonRedStart = Color("buttonRedStart")
    static let buttonRedEnd = Color("buttonRedEnd")

    static let accentGreen = Color("accentGreen")
    static let accentYellow = Color("accentYellow")
    static let accentPurple = Color("accentPurple")
    static let accentSky = Color("accentSky")

    static let buttonGhostFill = Color("buttonGhostFill")

    /// Legacy aliases kept to minimize churn while views migrate to the new names.
    static let primary = accentRed
    static let secondary = buttonBlueEnd
    static let accent = Color("accentLegacy")
    static let light = textPrimary
    static let dark = textPrimary
    static let sceneBackgroundTop = backgroundTop
    static let sceneBackgroundBottom = backgroundBottom
    static let sceneCard = surfacePrimary
    static let sceneCardBorder = borderSubtle
    static let sceneMuted = textMuted
    static let sceneBlue = buttonBlueEnd
    static let sceneBlueGlow = accentBlue
}

struct RankTheme {
    let base: Color
    let accent: Color

    static let all: [String: RankTheme] = [
        "minimumweight": RankTheme(base: Color("rankMinimumweightBase"), accent: Color("rankMinimumweightAccent")),
        "flyweight":     RankTheme(base: Color("rankFlyweightBase"),     accent: Color("rankFlyweightAccent")),
        "bantamweight":  RankTheme(base: Color("rankBantamweightBase"),  accent: Color("rankBantamweightAccent")),
        "featherweight": RankTheme(base: Color("rankFeatherweightBase"), accent: Color("rankFeatherweightAccent")),
        "lightweight":   RankTheme(base: Color("rankLightweightBase"),   accent: Color("rankLightweightAccent")),
        "middleweight":  RankTheme(base: Color("rankMiddleweightBase"),  accent: Color("rankMiddleweightAccent")),
        "heavyweight":   RankTheme(base: Color("rankHeavyweightBase"),   accent: Color("rankHeavyweightAccent")),
    ]

    static let fallback = RankTheme(base: Color("rankFallbackBase"), accent: Color("rankFallbackAccent"))

    static func forRank(_ rank: String) -> RankTheme {
        all[rank.lowercased()] ?? fallback
    }
}

struct SceneBackgroundView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [AppColors.backgroundTop, AppColors.backgroundBottom],
                startPoint: .top,
                endPoint: .bottom
            )

            Circle()
                .fill(AppColors.buttonBlueStart.opacity(0.05))
                .frame(width: 280, height: 280)
                .blur(radius: 56)
                .offset(x: -140, y: -240)

            Circle()
                .fill(AppColors.buttonRedStart.opacity(0.05))
                .frame(width: 220, height: 220)
                .blur(radius: 48)
                .offset(x: 150, y: -150)
        }
        .ignoresSafeArea()
    }
}

struct SceneCardModifier: ViewModifier {
    var cornerRadius: CGFloat = 20
    var fillColor: Color = AppColors.surfacePrimary

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(fillColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(AppColors.borderSubtle, lineWidth: 0.7)
                    )
            )
            .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: 6)
    }
}

extension View {
    func sceneCard(cornerRadius: CGFloat = 20, fillColor: Color = AppColors.surfacePrimary) -> some View {
        modifier(SceneCardModifier(cornerRadius: cornerRadius, fillColor: fillColor))
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 6:
            (r, g, b) = (int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: 1
        )
    }
}
