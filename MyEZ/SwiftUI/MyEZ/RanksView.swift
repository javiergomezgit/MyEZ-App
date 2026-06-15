import SwiftUI

struct RanksView: View {
    let currentRank: String

    struct RankTier: Identifiable {
        let id = UUID()
        let key: String
        let name: String
        let threshold: String
    }

    private let tiers: [RankTier] = [
        RankTier(key: "minimumweight", name: "Minimumweight", threshold: "0 lbs"),
        RankTier(key: "flyweight",     name: "Flyweight",     threshold: "1,000 lbs"),
        RankTier(key: "bantamweight",  name: "Bantamweight",  threshold: "2,000 lbs"),
        RankTier(key: "featherweight", name: "Featherweight", threshold: "4,000 lbs"),
        RankTier(key: "lightweight",   name: "Lightweight",   threshold: "6,000 lbs"),
        RankTier(key: "middleweight",  name: "Middleweight",  threshold: "9,000 lbs"),
        RankTier(key: "heavyweight",   name: "Heavyweight",   threshold: "13,000+ lbs"),
    ]

    var body: some View {
        ZStack {
            SceneBackgroundView()

            VStack(spacing: 0) {
                Text("Ranks")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.top, 28)
                    .padding(.bottom, 20)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        ForEach(tiers) { tier in
                            RankRow(tier: tier, isCurrentRank: tier.key == currentRank)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
    }
}

private struct RankRow: View {
    let tier: RanksView.RankTier
    let isCurrentRank: Bool

    private var theme: RankTheme { RankTheme.forRank(tier.key) }

    var body: some View {
        HStack(spacing: 14) {
            Image(tier.key)
                .resizable()
                .scaledToFit()
                .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 3) {
                Text(tier.name.uppercased())
                    .font(.system(size: 15, weight: .heavy))
                    .foregroundColor(isCurrentRank ? .white : AppColors.textPrimary)
                    .tracking(0.4)

                Text(tier.threshold)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(isCurrentRank ? .white.opacity(0.75) : AppColors.textSecondary)
            }

            Spacer()

            if isCurrentRank {
                Text("YOUR RANK")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule().fill(.white.opacity(0.25))
                    )
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(isCurrentRank ? theme.accent : AppColors.surfacePrimary)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(
                            isCurrentRank ? theme.accent : AppColors.borderSubtle,
                            lineWidth: isCurrentRank ? 0 : 0.7
                        )
                )
                .shadow(
                    color: isCurrentRank ? theme.accent.opacity(0.35) : Color.black.opacity(0.05),
                    radius: isCurrentRank ? 12 : 4,
                    x: 0, y: isCurrentRank ? 6 : 2
                )
        )
    }
}
