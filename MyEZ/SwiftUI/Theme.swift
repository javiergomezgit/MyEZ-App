import SwiftUI

enum AppColors {
    static let primary = Color(hex: "ED1C24")
    static let secondary = Color(hex: "0167C1")
    static let accent = Color(hex: "DAE401")
    static let light = Color(hex: "F0F0F0")
    static let dark = Color.black
    static let sceneBackgroundTop = Color(hex: "0F0F0F")
    static let sceneBackgroundBottom = Color(hex: "141414")
    static let sceneCard = Color(hex: "1C1C1E")
    static let sceneCardBorder = Color(hex: "2C2C2E")
    static let sceneMuted = Color(hex: "8E8E93")
    static let sceneBlue = Color(hex: "1E3A5F")
    static let sceneBlueGlow = Color(hex: "4A90D9")
}

struct SceneBackgroundView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [AppColors.sceneBackgroundTop, AppColors.sceneBackgroundBottom],
                startPoint: .top,
                endPoint: .bottom
            )

            Circle()
                .fill(AppColors.sceneBlue.opacity(0.22))
                .frame(width: 280, height: 280)
                .blur(radius: 40)
                .offset(x: -120, y: -260)

            Circle()
                .fill(AppColors.primary.opacity(0.14))
                .frame(width: 220, height: 220)
                .blur(radius: 38)
                .offset(x: 140, y: -170)
        }
        .ignoresSafeArea()
    }
}

struct SceneCardModifier: ViewModifier {
    var cornerRadius: CGFloat = 20
    var fillColor: Color = AppColors.sceneCard

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(fillColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 0.7)
                    )
            )
            .shadow(color: .black.opacity(0.24), radius: 20, x: 0, y: 10)
    }
}

extension View {
    func sceneCard(cornerRadius: CGFloat = 20, fillColor: Color = AppColors.sceneCard) -> some View {
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
