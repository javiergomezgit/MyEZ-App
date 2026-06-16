import SwiftUI

// MARK: - Data

struct FleetItem {
    let name: String
    let sku: String
    let bgColor: Color
    let iconColor: Color
    let icon: String
}

let walkthroughFleetItems: [FleetItem] = [
    FleetItem(name: "Bounce Houses", sku: "EZ-BH-001", bgColor: Color(hex: "FDEAEA"), iconColor: Color(hex: "C13A35"), icon: "house.fill"),
    FleetItem(name: "Water Slides",  sku: "EZ-WS-001", bgColor: Color(hex: "E0EAFD"), iconColor: Color(hex: "2F5EC4"), icon: "water.waves"),
    FleetItem(name: "Obstacles",     sku: "EZ-OB-001", bgColor: Color(hex: "FEF5D6"), iconColor: Color(hex: "C07E10"), icon: "chart.bar.fill"),
    FleetItem(name: "Games",         sku: "EZ-GM-001", bgColor: Color(hex: "D9F5E5"), iconColor: Color(hex: "1E8A4A"), icon: "gamecontroller"),
]

// MARK: - Sub-views

private struct FleetCardView: View {
    let item: FleetItem

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(item.bgColor)
                    .frame(height: 90)
                Image(systemName: item.icon)
                    .font(.system(size: 36, weight: .medium))
                    .foregroundColor(item.iconColor)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                Text(item.sku)
                    .font(.system(size: 11))
                    .foregroundColor(AppColors.textSecondary)
            }
            .padding(.top, 8)
            .padding(.horizontal, 4)
            .padding(.bottom, 10)
        }
        .background(AppColors.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(AppColors.borderSubtle, lineWidth: 0.7)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)
    }
}

// MARK: - Page View

struct WalkthroughPage1: View {
    @Binding var index: Int
    let totalPages: Int

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.clear

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(walkthroughFleetItems, id: \.name) { item in
                    FleetCardView(item: item)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 260)

            WalkthroughBottomPanel(
                index: $index,
                totalPages: totalPages,
                title: "Your Fleet, Always With You",
                subtitle: "Every inflatable you own, in one place. See your full inventory anytime with product images and SKU details."
            )
        }
    }
}
