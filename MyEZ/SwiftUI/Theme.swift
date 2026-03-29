import SwiftUI

enum AppColors {
    static let backgroundTop = Color(hex: "F8F7F5")
    static let backgroundBottom = Color(hex: "F2F1EE")

    static let surfacePrimary = Color.white
    static let surfaceSecondary = Color(hex: "F7F7F4")
    static let surfaceElevated = Color(hex: "FCFBF9")

    static let borderSubtle = Color(hex: "E7E5E1")
    static let borderStrong = Color(hex: "D8D5CF")

    static let textPrimary = Color(hex: "2E3440")
    static let textSecondary = Color(hex: "7C8594")
    static let textMuted = Color(hex: "A0A8B4")

    static let accentBlue = Color(hex: "4F6FD9")
    static let buttonBlueStart = Color(hex: "536ED7")
    static let buttonBlueEnd = Color(hex: "3F56B3")

    static let accentRed = Color(hex: "DE4B43")
    static let buttonRedStart = Color(hex: "E24E45")
    static let buttonRedEnd = Color(hex: "D63B32")

    static let accentGreen = Color(hex: "58BB7B")
    static let accentYellow = Color(hex: "F2BF55")
    static let accentPurple = Color(hex: "A56BFF")
    static let accentSky = Color(hex: "70CDE7")

    static let buttonGhostFill = Color(hex: "F3F2EF")

    /// Legacy aliases kept to minimize churn while views migrate to the new names.
    static let primary = accentRed
    static let secondary = buttonBlueEnd
    static let accent = Color(hex: "DAE401")
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
