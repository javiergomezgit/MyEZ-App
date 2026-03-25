import SwiftUI

struct MyEZView: View {
    @StateObject private var viewModel = MyEZViewModel()
    
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        ZStack {
            SceneBackgroundView()
            VStack(spacing: 16) {
                ScrollView {
                    VStack(spacing: 18) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("MyEZ")
                                .font(.system(size: 30, weight: .bold))
                                .foregroundColor(.white)
                            Text("Your rank, owned inflatables, and downloads in the same visual system as MyProfile.")
                                .font(.system(size: 15))
                                .foregroundColor(.white.opacity(0.55))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 13)

                        rankHeader
                        TopUsersCard(topUsers: viewModel.topUsers, summaryText: viewModel.topUsersSummaryText)

                        VStack(alignment: .leading, spacing: 14) {
                            Text("My Inflatables")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            Text(viewModel.ownedUnitsText)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.white.opacity(0.55))

                            LazyVGrid(columns: columns, spacing: 12) {
                                ForEach(viewModel.displayUnits) { unit in
                                    UnitCard(unit: unit)
                                        .onTapGesture { viewModel.select(unit: unit) }
                                }
                            }
                        }
                        .padding(18)
                        .sceneCard()
                        .padding(.horizontal, 13)
                        .padding(.bottom, 24)
                    }
                    .padding(.top, 8)
                }
                .padding(.horizontal, 5)
                .refreshable { viewModel.refreshAll() }
            }
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
        VStack(spacing: 6) {
            Image(viewModel.categoryImageName.isEmpty ? "minimumweight" : viewModel.categoryImageName)
                .resizable()
                .scaledToFit()
                .frame(width: 90, height: 90)
                .shadow(color: AppColors.sceneBlueGlow.opacity(0.25), radius: 18, x: 0, y: 8)
            Text(viewModel.categoryName.isEmpty ? "MINIMUMWEIGHT" : viewModel.categoryName)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white.opacity(0.6))
            Text(viewModel.ownedUnitsText)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .padding(.horizontal, 18)
        .sceneCard()
        .padding(.horizontal, 13)
    }
    
}

struct UnitCard: View {
    let unit: MyEZViewModel.UnitDisplayItem
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                LinearGradient(
                    colors: [Color.white.opacity(0.96), Color(hex: "D9E7F5")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                Image(unit.imageName)
                    .resizable()
                    .scaledToFit()
                    .padding(10)
            }
            .frame(height: 140)
            
            ZStack {
                AppColors.sceneCard
                Text(unit.sku)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 12)
            }
            .frame(height: 46)
        }
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.35), radius: 10, x: 0, y: 8)
    }
}

struct TopUsersCard: View {
    let topUsers: [MyEZViewModel.TopUserDisplay]
    let summaryText: String

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Text("🏆")
                Text("TOP USERS")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(AppColors.sceneBlue.opacity(0.28))

            VStack(spacing: 12) {
                HStack {
                    Text("PLACE")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white.opacity(0.45))
                    Spacer()
                    Text("WEIGHT")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white.opacity(0.45))
                    Spacer()
                    Text("LOCATION")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white.opacity(0.45))
                }

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
                        if user.id != topUsers.last?.id {
                            Divider().background(AppColors.light.opacity(0.08))
                        }
                    }
                }
            }
            .padding(16)

            HStack {
                Text(summaryText.isEmpty ? "Loading your rank..." : summaryText)
                    .foregroundColor(AppColors.light.opacity(0.85))
                Spacer()
            }
            .font(.system(size: 15, weight: .semibold))
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(AppColors.secondary.opacity(0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 12)
            .padding(.bottom, 14)
        }
        .sceneCard()
        .padding(.horizontal, 13)
    }
}

struct TopUserRow: View {
    let place: String
    let weight: String
    let location: String
    let medal: String

    var body: some View {
        HStack {
            Text("\(medal) \(place)")
                .foregroundColor(.white)
            Spacer()
            Text(weight)
                .foregroundColor(AppColors.sceneBlueGlow)
            Spacer()
            Text(location)
                .foregroundColor(.white.opacity(0.6))
        }
        .font(.system(size: 16, weight: .semibold))
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
                .background(AppColors.sceneBlue)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                Button("Download Manual") {
                    openLink(manualLink)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(Color.white.opacity(0.08))
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
