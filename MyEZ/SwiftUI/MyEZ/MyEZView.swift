import SwiftUI

struct MyEZView: View {
    @StateObject private var viewModel = MyEZViewModel()
    
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    private var rankTheme: RankTheme {
        RankTheme.forRank(viewModel.categoryImageName.isEmpty ? "minimumweight" : viewModel.categoryImageName)
    }
    
    var body: some View {
        ZStack {
            SceneBackgroundView()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    rankHeader
                    TopUsersCard(topUsers: viewModel.topUsers, summaryText: viewModel.topUsersSummaryText)

                    VStack(alignment: .leading, spacing: 14) {
                        Text("Your Products")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(AppColors.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(viewModel.displayUnits) { unit in
                                UnitCard(unit: unit)
                                    .onTapGesture { viewModel.select(unit: unit) }
                            }
                        }
                    }
                    .padding(.bottom, 100)
                }
                .padding(.top, 8)
            }
            .padding(.horizontal, 20)
            .refreshable { viewModel.refreshAll() }
        }
        .onAppear { viewModel.load() }
        .sheet(isPresented: $viewModel.showingDownload) {
            if let unit = viewModel.selectedUnit {
                DownloadUnitSheet(unit: unit, manualLink: viewModel.manualLink, unitLink: viewModel.unitLink)
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
        }
    }
    
    private var rankHeader: some View {
        VStack(spacing: 14) {
            Image(viewModel.categoryImageName.isEmpty ? "minimumweight" : viewModel.categoryImageName)
                .resizable()
                .scaledToFit()
                .frame(width: 78, height: 78)
                .shadow(color: AppColors.sceneBlueGlow.opacity(0.25), radius: 18, x: 0, y: 8)
            Text(viewModel.categoryName.isEmpty ? "MINIMUMWEIGHT" : viewModel.categoryName)
                .font(.system(size: 24, weight: .heavy, design: .rounded))
                .tracking(1)
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .padding(.horizontal, 24)
        .background(
            LinearGradient(
                colors: [rankTheme.base, rankTheme.accent],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .stroke(AppColors.borderSubtle, lineWidth: 1)
        )
    }
    
}

struct UnitCard: View {
    let unit: MyEZViewModel.UnitDisplayItem
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            LinearGradient(
                colors: [AppColors.surfaceElevated, AppColors.surfaceSecondary],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack {
                Spacer(minLength: 0)
                Image(unit.imageName)
                    .resizable()
                    .scaledToFit()
                    .padding(14)
            }

            LinearGradient(
                colors: [Color.black.opacity(0.18), Color.clear],
                startPoint: .top,
                endPoint: .center
            )
            
            VStack(alignment: .leading, spacing: 0) {
                Text(unit.sku)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.top, 12)
                    .padding(.leading, 12)
                Spacer()
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 192)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(AppColors.borderStrong, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.35), radius: 10, x: 0, y: 8)
    }
}

struct TopUsersCard: View {
    let topUsers: [MyEZViewModel.TopUserDisplay]
    let summaryText: String

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("TOP USERS")
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 14)
            .background(
                LinearGradient(
                    colors: [AppColors.buttonBlueStart, AppColors.buttonBlueEnd],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(
                .rect(
                    topLeadingRadius: 24,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: 24
                )
            )

            VStack(spacing: 14) {
                HStack {
                    Text("PLACE")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(AppColors.textSecondary)
                    Spacer()
                    Text("WEIGHT")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(AppColors.textSecondary)
                    Spacer()
                    Text("LOCATION")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(AppColors.textSecondary)
                }
                .padding(.horizontal, 6)

                if topUsers.isEmpty {
                    TopUserRow(place: "—", weight: "—", location: "—", medal: "🏅")
                } else {
                    ForEach(topUsers) { user in
                        TopUserRow(
                            place: "#\(user.place)",
                            weight: user.weightText,
                            location: user.locationText,
                            medal: user.medal
                        )
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 18)

            summaryBanner
                .padding(.horizontal, 18)
                .padding(.top, 18)
                .padding(.bottom, 18)

            HStack(spacing: 8) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 14, weight: .medium))
                Text("Pull down to update your EZ's")
                    .font(.system(size: 15, weight: .medium))
            }
            .foregroundColor(AppColors.textMuted)
            .padding(.bottom, 18)
        }
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(AppColors.surfacePrimary)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(AppColors.borderSubtle, lineWidth: 1)
                )
        )
    }

    private var summaryBanner: some View {
        VStack(spacing: 4) {
            if let parsed = SummaryParts(summaryText: summaryText) {
                (
                    Text("Owning ")
                        .foregroundColor(.white.opacity(0.9))
                    + Text(parsed.weight)
                        .foregroundColor(AppColors.accentBlue)
                    + Text(" of inflatables,")
                        .foregroundColor(.white.opacity(0.9))
                )
                .multilineTextAlignment(.center)

                (
                    Text("I'm in ")
                        .foregroundColor(.white.opacity(0.9))
                    + Text(parsed.place)
                        .foregroundColor(AppColors.accentRed)
                    + Text(".")
                        .foregroundColor(.white.opacity(0.9))
                )
                .multilineTextAlignment(.center)
            } else {
                Text(summaryText.isEmpty ? "Loading your rank..." : summaryText)
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
            }
        }
        .font(.system(size: 15, weight: .bold, design: .rounded))
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppColors.surfaceSecondary)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(AppColors.borderStrong, lineWidth: 1)
                )
        )
    }
}

struct TopUserRow: View {
    let place: String
    let weight: String
    let location: String
    let medal: String

    var body: some View {
        HStack {
            Text("\(medal)  \(place)")
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            Spacer()
            Text(weight)
                .foregroundColor(AppColors.accentBlue)
                .frame(maxWidth: .infinity, alignment: .center)
            Spacer()
            Text(location)
                .foregroundColor(.white.opacity(0.88))
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .font(.system(size: 16, weight: .bold, design: .rounded))
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppColors.surfaceElevated)
        )
    }
}

private struct SummaryParts {
    let weight: String
    let place: String

    init?(summaryText: String) {
        guard
            let weightRange = summaryText.range(of: "Owning "),
            let inflatablesRange = summaryText.range(of: " of inflatables"),
            let placeIntroRange = summaryText.range(of: "I'm in "),
            let placeEndRange = summaryText.range(of: " place")
        else {
            return nil
        }

        let weightStart = weightRange.upperBound
        let weight = String(summaryText[weightStart..<inflatablesRange.lowerBound])
        let placeStart = placeIntroRange.upperBound
        let place = String(summaryText[placeStart..<placeEndRange.lowerBound])

        guard !weight.isEmpty, !place.isEmpty else { return nil }
        self.weight = weight
        self.place = place + " Place"
    }
}

struct DownloadUnitSheet: View {
    let unit: MyEZViewModel.UnitDisplayItem
    let manualLink: String
    let unitLink: String
    
    var body: some View {
        ZStack {
            SceneBackgroundView()
            VStack(spacing: 16) {
                Image(unit.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 180)
                Text(unit.sku)
                    .font(.headline)
                    .foregroundColor(.white)
                Button("Download Files") {
                    openLink(unitLink)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(
                    LinearGradient(
                        colors: [AppColors.buttonBlueStart, AppColors.buttonBlueEnd],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                Button("Download Manual") {
                    openLink(manualLink)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(AppColors.buttonGhostFill)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                Spacer()
            }
            .padding(24)
            .sceneCard()
            .padding(20)
        }
    }
    
    private func openLink(_ link: String) {
        guard let url = URL(string: link), !link.isEmpty else { return }
        UIApplication.shared.open(url)
    }
}
