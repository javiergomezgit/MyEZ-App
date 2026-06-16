import SwiftUI
import FirebaseDatabase

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

    @State private var discounts: [String: Int] = [:]

    var body: some View {
        ZStack {
            SceneBackgroundView()

            VStack(spacing: 0) {
                Text("Ranks")
                    .font(.system(size: 22, weight: .bold)).privacySensitive()
                    .foregroundColor(AppColors.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.top, 28)
                    .padding(.bottom, 20)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        ForEach(tiers) { tier in
                            RankRow(
                                tier: tier,
                                isCurrentRank: tier.key == currentRank,
                                discount: discounts[tier.key]
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .onAppear { fetchDiscounts() }
    }

    private func fetchDiscounts() {
        Database.database().reference().child("rank_discounts")
            .observeSingleEvent(of: .value) { snapshot in
                var fetched: [String: Int] = [:]
                for case let child as DataSnapshot in snapshot.children {
                    let val: Int?
                    if let v = child.value as? Int { val = v }
                    else if let v = child.value as? NSNumber { val = v.intValue }
                    else if let v = child.value as? String { val = Int(v) }
                    else { val = nil }
                    if let v = val { fetched[child.key] = v }
                }
                DispatchQueue.main.async { discounts = fetched }
            }
    }
}

private struct RankRow: View {
    let tier: RanksView.RankTier
    let isCurrentRank: Bool
    let discount: Int?

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

            if let pct = discount {
                VStack(spacing: 1) {
                    Text("\(pct)% off")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(isCurrentRank ? .white : theme.accent)
                    Text("discount")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(isCurrentRank ? .white.opacity(0.7) : AppColors.textSecondary)
                }
            }

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
