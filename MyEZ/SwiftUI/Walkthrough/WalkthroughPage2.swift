import SwiftUI

// MARK: - Sub-views

private struct RankCircleView: View {
    let rankName: String

    var body: some View {
        ZStack {
            Circle()
                .stroke(AppColors.accentRed, lineWidth: 3)
                .frame(width: 160, height: 160)
            VStack(spacing: 4) {
                Text("RANK")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppColors.textSecondary)
                    .tracking(2)
                Text(rankName.uppercased())
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
            }
        }
    }
}

private struct RankProgressView: View {
    let ownedLbs: Int
    let nextLbs: Int
    let nextRankName: String

    private var progress: Double {
        min(Double(ownedLbs) / Double(nextLbs), 1.0)
    }

    var body: some View {
        VStack(spacing: 6) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(AppColors.borderSubtle)
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(AppColors.accentRed)
                        .frame(width: geo.size.width * progress, height: 8)
                }
            }
            .frame(height: 8)

            HStack {
                Text("\(ownedLbs.formatted()) lb owned")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
                Text("Next: \(nextRankName) at \(nextLbs.formatted()) lb")
                    .font(.system(size: 13))
                    .foregroundColor(AppColors.textSecondary)
            }
        }
    }
}

private struct RankBarChartView: View {
    // Bar heights relative to max
    private let bars: [(label: String, shortName: String, threshold: String, isCurrent: Bool)] = [
        ("Minimumweight", "Minweight", "0 lb",     false),
        ("Flyweight",     "Flyweight", "1,000 lb", true),
        ("Bantamweight",  "Bantam",    "2,000 lb", false),
    ]
    private let maxHeight: CGFloat = 140
    private let barHeights: [CGFloat] = [60, 110, 140]

    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack(spacing: 6) {
                Image(systemName: "arrow.up")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(AppColors.accentRed)
                Text("Heavier = higher rank")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(AppColors.accentRed)
            }

            // Bar chart
            HStack(alignment: .bottom, spacing: 16) {
                ForEach(Array(zip(bars, barHeights)), id: \.0.label) { bar, height in
                    VStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(bar.isCurrent ? AppColors.accentRed : Color(UIColor.systemGray5))
                            .frame(width: 72, height: height)

                        Text(bar.threshold)
                            .font(.system(size: 13, weight: bar.isCurrent ? .bold : .regular))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .foregroundColor(bar.isCurrent ? AppColors.accentRed : AppColors.textSecondary)

                        Text(bar.shortName)
                            .font(.system(size: 12, weight: bar.isCurrent ? .semibold : .regular))
                            .foregroundColor(bar.isCurrent ? AppColors.textPrimary : AppColors.textSecondary)
                    }
                }
            }
        }
    }
}

// MARK: - Page View

struct WalkthroughPage2: View {
    @Binding var index: Int
    let totalPages: Int

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.clear

            VStack(spacing: 20) {
                Spacer()

                RankCircleView(rankName: "Flyweight")

                RankProgressView(ownedLbs: 1340, nextLbs: 2000, nextRankName: "Bantamweight")
                    .padding(.horizontal, 32)

                // Current rank badge
                Text("RANK 2 OF 7 — FLYWEIGHT")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(AppColors.accentRed)
                    .tracking(0.4)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 9)
                    .background(
                        Capsule()
                            .fill(AppColors.accentRed.opacity(0.10))
                    )

                RankBarChartView()

                Spacer()
            }
            .padding(.bottom, 200)

            WalkthroughBottomPanel(
                index: $index,
                totalPages: totalPages,
                title: "Own More. Rank Higher.",
                subtitle: "The more you own, the higher your rank. Every purchase moves you closer to the next tier."
            )
        }
    }
}
