import SwiftUI

// MARK: - Data

private struct DealItem {
    let emoji: String
    let title: String
    let description: String
    let badge: String
    let expiry: String
    let progress: Double  // 0–1, represents time elapsed
    let badgeColor: Color
}

private let dealItems: [DealItem] = [
    DealItem(emoji: "🏖️", title: "Summer Blowout Sale",  description: "Save up to 40% on water slides",      badge: "40% OFF", expiry: "Expires in 2d 14h", progress: 0.40, badgeColor: AppColors.accentBlue),
    DealItem(emoji: "🎯", title: "Weekend Warrior Deal",  description: "BOGO on combo units this weekend",     badge: "BOGO",    expiry: "Expires in 1d 8h",  progress: 0.22, badgeColor: AppColors.accentBlue),
    DealItem(emoji: "🎉", title: "New Customer Bundle",   description: "15% off your first 3 inflatables",    badge: "15% OFF", expiry: "Expires in 5d",      progress: 0.10, badgeColor: AppColors.accentBlue),
]

// MARK: - Sub-views

private struct DealCardView: View {
    let deal: DealItem

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header row
            HStack(alignment: .top) {
                Text(deal.emoji)
                    .font(.system(size: 28))
                Text(deal.title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
                Text(deal.expiry)
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.trailing)
            }

            // Description
            Text(deal.description)
                .font(.system(size: 14))
                .foregroundColor(AppColors.textSecondary)

            // Badge + progress bar
            HStack(spacing: 12) {
                Text(deal.badge)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(Capsule().fill(deal.badgeColor))

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(AppColors.borderSubtle)
                            .frame(height: 6)
                        Capsule()
                            .fill(deal.badgeColor)
                            .frame(width: geo.size.width * deal.progress, height: 6)
                    }
                }
                .frame(height: 6)
            }
        }
        .padding(18)
        .background(AppColors.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 3)
    }
}

// MARK: - Page View

struct WalkthroughPage4: View {
    @Binding var index: Int
    let totalPages: Int
    let onFinish: () -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.clear

            VStack(spacing: 12) {
                ForEach(dealItems, id: \.title) { deal in
                    DealCardView(deal: deal)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 100)
            .padding(.bottom, 260)

            WalkthroughBottomPanel(
                index: $index,
                totalPages: totalPages,
                title: "Deals Built for You",
                subtitle: "Exclusive time-limited offers pushed directly to your phone. They expire automatically — so you never miss a window.",
                onDone: onFinish
            )
        }
    }
}
