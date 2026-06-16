import SwiftUI

// MARK: - Data

private struct LeaderEntry {
    let place: Int
    let medal: String
    let company: String
    let zip: String
    let points: Int
}

private let leaderEntries: [LeaderEntry] = [
    LeaderEntry(place: 1, medal: "🥇", company: "Bounce Kings Co",   zip: "90210", points: 2340),
    LeaderEntry(place: 2, medal: "🥈", company: "Lone Star Rentals", zip: "75201", points: 1890),
    LeaderEntry(place: 3, medal: "🥉", company: "Sunshine Inflate",  zip: "33101", points: 1420),
]

private struct PointAction {
    let icon: String
    let label: String
    let pts: Int
}

private let pointActions: [PointAction] = [
    PointAction(icon: "cart",          label: "Purchase", pts: 100),
    PointAction(icon: "play.rectangle",label: "Video",    pts: 20),
    PointAction(icon: "link",          label: "Share",    pts: 15),
    PointAction(icon: "book",          label: "Article",  pts: 10),
]

// MARK: - Sub-views

private struct LeaderRowView: View {
    let entry: LeaderEntry

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Text(entry.medal)
                .font(.system(size: 24))
                .frame(width: 32)
            Text("#\(entry.place)")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(AppColors.textPrimary)
            Text(entry.company)
                .font(.system(size: 15))
                .foregroundColor(AppColors.textPrimary)
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(entry.points.formatted()) pts")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                Text("ZIP \(entry.zip)")
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

private struct YouRowView: View {
    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("You — 47th place")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                Text("660 pts behind #1")
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.textSecondary)
            }
            Spacer()
            Text("310 pts")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(AppColors.accentRed)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(AppColors.accentRed.opacity(0.07))
        )
        .padding(.horizontal, 8)
        .padding(.bottom, 8)
    }
}

// MARK: - Page View

struct WalkthroughPage3: View {
    @Binding var index: Int
    let totalPages: Int

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.clear

            VStack(spacing: 0) {
                Spacer()

                // Leaderboard card
                VStack(spacing: 0) {
                    // Red header
                    HStack(spacing: 8) {
                        Image(systemName: "trophy.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 14, weight: .bold))
                        Text("FLYWEIGHT LEAGUE — MAY 2026")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                            .tracking(0.5)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(AppColors.accentRed)

                    // Top 3 rows
                    ForEach(leaderEntries, id: \.place) { entry in
                        LeaderRowView(entry: entry)
                        if entry.place < 3 {
                            Divider()
                                .padding(.horizontal, 16)
                        }
                    }

                    // You row
                    YouRowView()
                }
                .background(AppColors.surfacePrimary)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(AppColors.borderSubtle, lineWidth: 0.7)
                )
                .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
                .padding(.horizontal, 20)

                // Action pills (horizontal scroll)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(pointActions, id: \.label) { action in
                            HStack(spacing: 6) {
                                Image(systemName: action.icon)
                                    .font(.system(size: 13))
                                Text("\(action.label) +\(action.pts)")
                                    .font(.system(size: 13, weight: .medium))
                            }
                            .foregroundColor(AppColors.textPrimary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 9)
                            .background(
                                Capsule()
                                    .stroke(AppColors.borderStrong, lineWidth: 1)
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.top, 16)

                Spacer()
            }
            .padding(.bottom, 200)

            WalkthroughBottomPanel(
                index: $index,
                totalPages: totalPages,
                title: "Compete Every Month",
                subtitle: "Every month your league resets. Earn points by buying, watching, sharing, and showing up. The top earner wins a prize."
            )
        }
    }
}
