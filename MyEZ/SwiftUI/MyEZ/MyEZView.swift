import SwiftUI

struct MyEZView: View {
    @StateObject private var viewModel = MyEZViewModel()

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    private var rankTheme: RankTheme {
        RankTheme.forRank(viewModel.categoryImageName.isEmpty ? "minimumweight" : viewModel.categoryImageName)
    }

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return "\(formatter.string(from: Date())) Top Users"
    }

    var body: some View {
        ZStack {
            SceneBackgroundView()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    rankHeader
                    TopUsersCard(topUsers: viewModel.topUsers, monthlyPlace: viewModel.monthlyPlace, headerColor: rankTheme.accent, title: monthTitle)

                    VStack(alignment: .leading, spacing: 14) {
                        Text("Your Products")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(AppColors.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        if viewModel.isAuthenticated {
                            LazyVGrid(columns: columns, spacing: 14) {
                                ForEach(viewModel.displayUnits) { unit in
                                    UnitCard(unit: unit)
                                        .onTapGesture { viewModel.select(unit: unit) }
                                }
                            }
                        } else {
                            SignedOutProductsMessage()

                            LazyVGrid(columns: columns, spacing: 14) {
                                ForEach(0..<3, id: \.self) { _ in
                                    PlaceholderUnitCard()
                                }
                            }
                        }
                    }
                    .padding(.bottom, 100)
                }
                .padding(.top, 12)
            }
            .padding(.horizontal, 20)
            .refreshable { viewModel.refreshAll() }
        }
        .onAppear { viewModel.load() }
        .sheet(isPresented: $viewModel.showingDownload) {
            if let unit = viewModel.selectedUnit {
                DownloadUnitSheet(unit: unit, manualLink: viewModel.manualLink)
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
        }
    }

    private var rankHeader: some View {
        HStack(spacing: 10) {
            Image(viewModel.categoryImageName.isEmpty ? "minimumweight" : viewModel.categoryImageName)
                .resizable()
                .scaledToFit()
                .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 3) {
                Text("Your Rank")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(AppColors.textSecondary)

                Text(viewModel.categoryName.isEmpty ? "MINIMUMWEIGHT" : viewModel.categoryName)
                    .font(.system(size: 17, weight: .heavy))
                    .foregroundColor(AppColors.textPrimary)
                    .tracking(0.5)
            }

            Spacer()

            if viewModel.ownedWeight > 0 {
                VStack(alignment: .trailing, spacing: 3) {
                    Text("Owned")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(AppColors.textSecondary)

                    Text("\(viewModel.ownedWeight.formatted()) lbs")
                        .font(.system(size: 17, weight: .heavy))
                        .foregroundColor(AppColors.textPrimary)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .sceneCard(cornerRadius: 26, fillColor: AppColors.surfacePrimary)
    }
}

struct SignedOutProductsMessage: View {
    var body: some View {
        Text("Sign in to download your inflatables photos.")
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(AppColors.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct UnitCard: View {
    let unit: MyEZViewModel.UnitDisplayItem

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(AppColors.surfaceSecondary)

                Image("logoLaunch")
                    .resizable()
                    .scaledToFit()
                    .padding(14)
            }
            .frame(height: 158)

            VStack(spacing: 2) {
                Text(unit.sku)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)

                if unit.qty > 1 {
                    Text("Qty: \(unit.qty)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 8)
            .padding(.vertical, 12)
        }
        .sceneCard(cornerRadius: 18, fillColor: AppColors.surfacePrimary)
    }
}

struct PlaceholderUnitCard: View {
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(AppColors.surfaceSecondary)

                Image("logoLaunch")
                    .resizable()
                    .scaledToFit()
                    .padding(20)
            }
            .frame(height: 158)

            Text("Sign In To View")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(AppColors.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
        }
        .sceneCard(cornerRadius: 18, fillColor: AppColors.surfacePrimary)
    }
}

struct TopUsersCard: View {
    let topUsers: [MyEZViewModel.TopUserDisplay]
    let monthlyPlace: Int
    let headerColor: Color
    let title: String

    private static func ordinalString(_ value: Int) -> String {
        let tens = (value / 10) % 10
        let ones = value % 10
        if tens == 1 { return "\(value)th" }
        switch ones {
        case 1: return "\(value)st"
        case 2: return "\(value)nd"
        case 3: return "\(value)rd"
        default: return "\(value)th"
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(headerColor)
                    .clipShape(
                        .rect(
                            topLeadingRadius: 22,
                            bottomLeadingRadius: 0,
                            bottomTrailingRadius: 0,
                            topTrailingRadius: 22
                        )
                    )
            )

            VStack(spacing: 12) {
                HStack {
                    Text("PLACE")
                        .frame(width: 72, alignment: .leading)
                    Text("SCORE")
                        .frame(width: 80, alignment: .leading)
                    Text("NAME")
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(AppColors.textSecondary)
                .padding(.horizontal, 6)

                if topUsers.isEmpty {
                    Text("No leaderboard data yet.")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppColors.textMuted)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 8)
                } else {
                    ForEach(topUsers) { user in
                        TopUserRow(
                            place: "\(user.place)",
                            score: user.scoreText,
                            display: user.displayText,
                            medal: user.medal
                        )
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 14)

            summaryBanner
                .padding(.horizontal, 18)
                .padding(.top, 14)

            HStack(spacing: 8) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 14, weight: .medium))
                Text("Pull to refresh")
                    .font(.system(size: 15, weight: .medium))
            }
            .foregroundColor(AppColors.textMuted)
            .padding(.vertical, 14)
        }
        .sceneCard(cornerRadius: 22, fillColor: AppColors.surfacePrimary)
    }

    private var summaryBanner: some View {
        Group {
            if monthlyPlace > 0 {
                (
                    Text("I'm in ")
                        .foregroundColor(AppColors.textPrimary)
                    + Text(Self.ordinalString(monthlyPlace) + " place")
                        .foregroundColor(AppColors.accentRed)
                    + Text(" for the month.")
                        .foregroundColor(AppColors.textPrimary)
                )
                .multilineTextAlignment(.center)
            } else {
                Text("Loading your rank...")
                    .foregroundColor(AppColors.textPrimary)
                    .multilineTextAlignment(.center)
            }
        }
        .font(.system(size: 15, weight: .bold))
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(hex: "F5F9FF"))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color(hex: "CFE0FF"), lineWidth: 1)
                )
        )
    }
}

struct TopUserRow: View {
    let place: String
    let score: String
    let display: String
    let medal: String

    var body: some View {
        HStack(spacing: 0) {
            Text("\(medal)  \(place)")
                .foregroundColor(AppColors.textPrimary)
                .frame(width: 72, alignment: .leading)

            Text(score.replacingOccurrences(of: "lbs", with: "pts"))
                .foregroundColor(AppColors.accentGreen)
                .frame(width: 80, alignment: .leading)

            Text(display)
                .foregroundColor(AppColors.textPrimary)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .font(.system(size: 15, weight: .bold))
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(AppColors.surfaceSecondary)
        )
    }
}


struct DownloadUnitSheet: View {
    let unit: MyEZViewModel.UnitDisplayItem
    let manualLink: String

    @State private var unitLink: String = ""
    @State private var isLoadingLink: Bool = true
    @State private var showingLinkAlert: Bool = false
    @State private var linkErrorMessage: String?

    var body: some View {
        ZStack {
            SceneBackgroundView()

            VStack(spacing: 18) {
                Image("logoLaunch")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 180)

                Text(unit.sku)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)

                if isLoadingLink {
                    ProgressView("Generating download link...")
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                } else if !unitLink.isEmpty {
                    Button("Download Files") {
                        showingLinkAlert = true
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(AppColors.buttonBlueStart)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                } else if let linkErrorMessage = linkErrorMessage {
                    Text(linkErrorMessage)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(AppColors.accentRed)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 14)
                        .background(AppColors.buttonGhostFill)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }

                Button("Download Manual") {
                    openLink(manualLink)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(AppColors.buttonGhostFill)
                .foregroundColor(AppColors.textPrimary)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                Spacer()
            }
            .padding(24)
            .sceneCard(cornerRadius: 24, fillColor: AppColors.surfacePrimary)
            .padding(20)
        }
        .task {
            await fetchUnitLink()
        }
        .alert("Download Files", isPresented: $showingLinkAlert) {
            Button("Copy Link") {
                let downloadLink = unitLink.replacingOccurrences(of: "dl=0", with: "dl=1")
                UIPasteboard.general.string = downloadLink
            }
            Button("Go to Website") {
                openLink(unitLink)
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Choose how to access the files for \(unit.sku).")
        }
    }

    private func fetchUnitLink() async {
        guard let url = URL(string: "\(PrivateKeys.baseURLDropbox)\(unit.sku)") else {
            linkErrorMessage = "Try later or contact the EZ team for more information."
            isLoadingLink = false
            return
        }
        guard let (data, _) = try? await URLSession.shared.data(from: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let urlString = json["url"] as? String else {
            linkErrorMessage = "Try later or contact the EZ team for more information."
            isLoadingLink = false
            return
        }
        unitLink = urlString
        linkErrorMessage = nil
        isLoadingLink = false
    }

    private func openLink(_ link: String) {
        guard let url = URL(string: link), !link.isEmpty else { return }
        UIApplication.shared.open(url)
    }
}
