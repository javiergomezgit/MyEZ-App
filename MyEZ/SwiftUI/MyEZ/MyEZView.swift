import SwiftUI

struct MyEZView: View {
    @StateObject private var viewModel = MyEZViewModel()
    
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        ZStack {
            AppColors.dark.ignoresSafeArea()
            VStack(spacing: 16) {
                ScrollView {
                    VStack(spacing: 18) {
                        rankHeader
                        TopUsersCard(topUsers: viewModel.topUsers, summaryText: viewModel.topUsersSummaryText)
                        Text("My Inflatables")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(AppColors.light)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 8)
                            .padding(.horizontal, 13)
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(viewModel.displayUnits) { unit in
                                UnitCard(unit: unit)
                                    .onTapGesture { viewModel.select(unit: unit) }
                            }
                        }
                        .padding(.horizontal, 13)
                        .padding(.bottom, 24)
                    }
                    .padding(.top, 8)
                }
                .refreshable { viewModel.refreshAll() }
                addUnitButton
            }
        }
        .navigationTitle("MyEZ")
        .navigationBarTitleDisplayMode(.inline)
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
            Text(viewModel.categoryName.isEmpty ? "MINIMUMWEIGHT" : viewModel.categoryName)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(AppColors.light.opacity(0.6))
        }
    }
    
    private var addUnitButton: some View {
        Button("Add Unit") {
            viewModel.refreshUnits()
        }
        .frame(maxWidth: .infinity)
        .frame(height: 50)
        .background(AppColors.light.opacity(0.08))
        .foregroundColor(AppColors.light)
        .cornerRadius(12)
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
}

struct UnitCard: View {
    let unit: MyEZViewModel.UnitDisplayItem
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                AppColors.light
                Image(unit.imageName)
                    .resizable()
                    .scaledToFit()
                    .padding(10)
            }
            .frame(height: 140)
            
            ZStack {
                AppColors.dark
                Text(unit.sku)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppColors.light.opacity(0.65))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 12)
            }
            .frame(height: 46)
        }
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(AppColors.light.opacity(0.5), lineWidth: 1)
        )
        .shadow(color: AppColors.dark.opacity(0.4), radius: 6, x: 0, y: 4)
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
                    .foregroundColor(AppColors.light)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(AppColors.secondary.opacity(0.25))

            VStack(spacing: 12) {
                HStack {
                    Text("PLACE")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(AppColors.light.opacity(0.5))
                    Spacer()
                    Text("WEIGHT")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(AppColors.light.opacity(0.5))
                    Spacer()
                    Text("LOCATION")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(AppColors.light.opacity(0.5))
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
                            .stroke(AppColors.secondary.opacity(0.35), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 12)
            .padding(.bottom, 14)
        }
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(AppColors.dark.opacity(0.92))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(AppColors.light.opacity(0.18), lineWidth: 1)
                )
        )
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
                .foregroundColor(AppColors.light)
            Spacer()
            Text(weight)
                .foregroundColor(AppColors.secondary)
            Spacer()
            Text(location)
                .foregroundColor(AppColors.light.opacity(0.6))
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
            AppColors.dark.opacity(0.7).ignoresSafeArea()
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
                .background(AppColors.primary)
                .foregroundColor(.white)
                .cornerRadius(12)
                Button("Download Manual") {
                    openLink(manualLink)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(AppColors.light.opacity(0.1))
                .foregroundColor(.white)
                .cornerRadius(12)
                Spacer()
            }
            .padding(24)
        }
    }
    
    private func openLink(_ link: String) {
        guard let url = URL(string: link), !link.isEmpty else { return }
        UIApplication.shared.open(url)
    }
}
