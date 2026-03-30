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

    var body: some View {
        ZStack {
            SceneBackgroundView()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    rankHeader
                    TopUsersCard(topUsers: viewModel.topUsers, summaryText: viewModel.topUsersSummaryText, headerColor: rankTheme.accent)

                    VStack(alignment: .leading, spacing: 14) {
                        Text("Your Products")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(AppColors.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        LazyVGrid(columns: columns, spacing: 14) {
                            ForEach(viewModel.displayUnits) { unit in
                                UnitCard(unit: unit)
                                    .onTapGesture { viewModel.select(unit: unit) }
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
        VStack(spacing: 6) {
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
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .sceneCard(cornerRadius: 26, fillColor: AppColors.surfacePrimary)
    }
}

struct UnitCard: View {
    let unit: MyEZViewModel.UnitDisplayItem

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(AppColors.surfaceSecondary)

                VStack {
                    Spacer(minLength: 0)

                    if let imageURL = unit.imageURL {
                        AsyncImage(url: imageURL) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFit()
                            default:
                                Image("logoLaunch")
                                    .resizable()
                                    .scaledToFit()
                            }
                        }
                        .padding(14)
                    } else {
                        Image("logoLaunch")
                            .resizable()
                            .scaledToFit()
                            .padding(14)
                    }
                }

            }
            .frame(height: 158)

            Text(unit.sku)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(AppColors.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
        }
        .sceneCard(cornerRadius: 18, fillColor: AppColors.surfacePrimary)
    }
}

struct TopUsersCard: View {
    let topUsers: [MyEZViewModel.TopUserDisplay]
    let summaryText: String
    let headerColor: Color

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Top Users")
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
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("WEIGHT")
                        .frame(maxWidth: .infinity, alignment: .center)
                    Text("LOCATION")
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(AppColors.textSecondary)
                .padding(.horizontal, 6)

                if topUsers.isEmpty {
                    TopUserRow(place: "1", weight: "15,420 lbs", location: "90210", medal: "🥇")
                    TopUserRow(place: "2", weight: "12,850 lbs", location: "10001", medal: "🥈")
                    TopUserRow(place: "3", weight: "9,340 lbs", location: "60601", medal: "🥉")
                } else {
                    ForEach(topUsers) { user in
                        TopUserRow(
                            place: "\(user.place)",
                            weight: user.weightText,
                            location: user.locationText,
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
        VStack(spacing: 4) {
            if let parsed = SummaryParts(summaryText: summaryText) {
                (
                    Text("Owning ")
                        .foregroundColor(AppColors.textPrimary)
                    + Text(parsed.weight)
                        .foregroundColor(AppColors.accentGreen)
                    + Text(" of inflatables,")
                        .foregroundColor(AppColors.textPrimary)
                )
                .multilineTextAlignment(.center)

                (
                    Text("I'm in ")
                        .foregroundColor(AppColors.textPrimary)
                    + Text(parsed.place)
                        .foregroundColor(AppColors.accentRed)
                    + Text(".")
                        .foregroundColor(AppColors.textPrimary)
                )
                .multilineTextAlignment(.center)
            } else {
                Text(summaryText.isEmpty ? "Loading your rank..." : summaryText)
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
    let weight: String
    let location: String
    let medal: String

    var body: some View {
        HStack {
            Text("\(medal)  \(place)")
                .foregroundColor(AppColors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(weight)
                .foregroundColor(AppColors.accentGreen)
                .frame(maxWidth: .infinity, alignment: .center)

            Text(location)
                .foregroundColor(AppColors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .font(.system(size: 16, weight: .bold))
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(AppColors.surfaceSecondary)
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
    
    @State private var unitLink: String = ""
    @State private var isLoadingLink: Bool = true
    @State private var showingLinkAlert: Bool = false
    @State private var linkErrorMessage: String?
    
    var body: some View {
        ZStack {
            SceneBackgroundView()
            
            VStack(spacing: 18) {
                if let imageURL = unit.imageURL {
                    AsyncImage(url: imageURL) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                        default:
                            Image("logoLaunch")
                                .resizable()
                                .scaledToFit()
                        }
                    }
                    .frame(height: 180)
                } else {
                    Image("logoLaunch")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 180)
                }
                
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
                UIPasteboard.general.string = downloadLink            }
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
            print("❌ Bad URL: \(PrivateKeys.baseURLDropbox)\(unit.sku)")
            linkErrorMessage = "Try later or contact the EZ team for more information."
            isLoadingLink = false
            return
        }
        print("🔍 Fetching: \(url)")
        guard let (data, _) = try? await URLSession.shared.data(from: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            print("❌ Network or parsing failed")
            linkErrorMessage = "Try later or contact the EZ team for more information."
            isLoadingLink = false
            return
        }
        print("📦 Response: \(json)")
        guard let urlString = json["url"] as? String else {
            print("❌ No url key in response: \(json)")
            let apiError = json["error"] as? String
            if let apiError, !apiError.isEmpty {
                print("❌ Dropbox API error: \(apiError)")
            }
            linkErrorMessage = "Try later or contact the EZ team for more information."
            isLoadingLink = false
            return
        }
        unitLink = urlString
        linkErrorMessage = nil
        print("✅ unitLink set: \(unitLink)")
        isLoadingLink = false
    }
    
    private func openLink(_ link: String) {
        guard let url = URL(string: link), !link.isEmpty else { return }
        UIApplication.shared.open(url)
    }
}
