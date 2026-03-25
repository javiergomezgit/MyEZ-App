import SwiftUI

enum AppColors {
    /// App-wide page background gradient start. Use on all main scenes so auth, profile,
    /// contact, deals, and MyEZ share the same deep navy base.
    static let backgroundTop = Color(hex: "0D1B2A")

    /// App-wide page background gradient end. Pairs with `backgroundTop` for the primary
    /// full-screen canvas.
    static let backgroundBottom = Color(hex: "1A1A2E")

    /// Default card/container fill for panels that hold a whole section of content.
    static let surfacePrimary = Color(hex: "162133")

    /// Secondary card fill for grouped rows, inner modules, and darker subsections.
    static let surfaceSecondary = Color(hex: "1D2940")

    /// Elevated fill for individual rows, tiles, and highlighted content inside cards.
    static let surfaceElevated = Color(hex: "273652")

    /// Subtle stroke used on cards, row outlines, and control borders.
    static let borderSubtle = Color.white.opacity(0.08)

    /// Slightly stronger stroke used when a control needs more separation.
    static let borderStrong = Color.white.opacity(0.12)

    /// Primary text color for titles and important labels.
    static let textPrimary = Color(hex: "F0F4FA")

    /// Secondary text color for descriptions and supporting copy.
    static let textSecondary = Color(hex: "A8B4C6")

    /// Muted icon/text color for tertiary UI like hints and inactive affordances.
    static let textMuted = Color(hex: "7E8A9D")

    /// Main blue accent pulled from the auth/welcome views. Use for primary buttons,
    /// informative highlights, and emphasized secondary accents.
    static let accentBlue = Color(hex: "4A90D9")

    /// Blue primary CTA gradient start. Use for Sign In, chat, refresh, and primary actions.
    static let buttonBlueStart = Color(hex: "2D8CFF")

    /// Blue primary CTA gradient end. Pairs with `buttonBlueStart`.
    static let buttonBlueEnd = Color(hex: "1E63E9")

    /// Main red brand accent. Use for branded emphasis and rank/place callouts.
    static let accentRed = Color(hex: "E8272B")

    /// Red branded CTA gradient start. Use for Create Account and other brand-forward actions.
    static let buttonRedStart = Color(hex: "E8272B")

    /// Red branded CTA gradient end. Pairs with `buttonRedStart`.
    static let buttonRedEnd = Color(hex: "C0181C")

    /// Soft ghost fill used for secondary buttons on dark surfaces.
    static let buttonGhostFill = Color.white.opacity(0.06)

    /// Legacy aliases kept to minimize churn while views migrate to the new names.
    static let primary = accentRed
    static let secondary = buttonBlueEnd
    static let accent = Color(hex: "DAE401")
    static let light = textPrimary
    static let dark = Color.black
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
        "minimumweight": RankTheme(base: Color(hex: "191A31"), accent: Color(hex: "F4C430")),
        "flyweight": RankTheme(base: Color(hex: "1A1D36"), accent: Color(hex: "FFD24A")),
        "bantamweight": RankTheme(base: Color(hex: "211B32"), accent: Color(hex: "FF9F1C")),
        "featherweight": RankTheme(base: Color(hex: "162A2A"), accent: Color(hex: "43C463")),
        "lightweight": RankTheme(base: Color(hex: "112A3D"), accent: Color(hex: "35C6F4")),
        "welterweight": RankTheme(base: Color(hex: "251A3A"), accent: Color(hex: "8F5BFF")),
        "middleweight": RankTheme(base: Color(hex: "2B1D25"), accent: Color(hex: "D28A2D")),
        "cruiserweight": RankTheme(base: Color(hex: "2C1720"), accent: Color(hex: "F04E3E")),
        "heavyweight": RankTheme(base: Color(hex: "16181D"), accent: Color(hex: "6E7784"))
    ]

    static let fallback = RankTheme(base: Color(hex: "11152D"), accent: Color(hex: "26357B"))

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
                .fill(AppColors.buttonBlueStart.opacity(0.18))
                .frame(width: 300, height: 300)
                .blur(radius: 52)
                .offset(x: -130, y: -250)

            Circle()
                .fill(AppColors.buttonRedStart.opacity(0.12))
                .frame(width: 240, height: 240)
                .blur(radius: 42)
                .offset(x: 145, y: -165)
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
            .shadow(color: .black.opacity(0.24), radius: 20, x: 0, y: 10)
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
