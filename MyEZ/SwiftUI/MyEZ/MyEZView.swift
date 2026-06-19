import SwiftUI
import Kingfisher
import FirebaseDatabase

struct MyEZView: View {
    @StateObject private var viewModel = MyEZViewModel()
    @State private var showingRanks = false
    @State private var showingMonthlyPrize = false

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
                    TopUsersCard(topUsers: viewModel.topUsers, monthlyPlace: viewModel.monthlyPlace, monthlyScore: viewModel.monthlyScore, isLoading: viewModel.isLoadingLeaderboard, headerColor: rankTheme.accent, title: monthTitle, onPrizeTap: { showingMonthlyPrize = true })

                    VStack(alignment: .leading, spacing: 14) {
                        Text("Your Products")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(AppColors.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        if viewModel.isAuthenticated {
                            if viewModel.displayUnits.isEmpty {
                                Text("If your units are not appearing here, please contact us.")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(AppColors.textSecondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            } else {
                                LazyVGrid(columns: columns, spacing: 14) {
                                    ForEach(viewModel.displayUnits) { unit in
                                        UnitCard(unit: unit)
                                            .onTapGesture { viewModel.select(unit: unit) }
                                    }
                                }
                                .padding(.horizontal, 4)
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
        .sheet(isPresented: $showingMonthlyPrize) {
            MonthlyPrizeSheet()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
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

            VStack(alignment: .trailing, spacing: 3) {
                Text("Owned")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(AppColors.textSecondary)

                Text("\(viewModel.ownedWeight.formatted()) lbs")
                    .font(.system(size: 17, weight: .heavy))
                    .foregroundColor(AppColors.textPrimary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .sceneCard(cornerRadius: 26, fillColor: AppColors.surfacePrimary)
        .onTapGesture { showingRanks = true }
        .sheet(isPresented: $showingRanks) {
            RanksView(currentRank: viewModel.categoryImageName)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
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
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AppColors.surfaceSecondary)
                .frame(height: 158)
                .overlay {
                    if let url = unit.imageURL {
                        KFImage(url)
                            .placeholder { ProgressView() }
                            .fade(duration: 0.3)
                            .resizable()
                            .scaledToFit()
                            .scaleEffect(1.1)
                    } else {
                        Image("logoLaunch")
                            .resizable()
                            .scaledToFit()
                            .padding(24)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            VStack(spacing: 2) {
                Text(unit.sku)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Qty: \(unit.qty)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppColors.textSecondary)
            }
            .frame(maxWidth: .infinity, minHeight: 52, alignment: .center)
            .padding(.horizontal, 8)
            .padding(.vertical, 12)
        }
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AppColors.surfacePrimary)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(AppColors.borderSubtle, lineWidth: 0.7)
                )
                .shadow(color: Color.black.opacity(0.07), radius: 6, x: 0, y: 3)
        )
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
    let monthlyScore: Int
    let isLoading: Bool
    let headerColor: Color
    let title: String
    let onPrizeTap: () -> Void

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
                HStack(spacing: 4) {
                    Image(systemName: "gift.fill")
                        .font(.system(size: 12))
                    Text("Prize")
                        .font(.system(size: 13, weight: .bold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Capsule().fill(.white.opacity(0.25)))
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
            .contentShape(Rectangle())
            .onTapGesture { onPrizeTap() }

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
            .foregroundColor(AppColors.textSecondary)
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
                    + Text(" for the month with ")
                        .foregroundColor(AppColors.textPrimary)
                    + Text("\(monthlyScore) pts")
                        .foregroundColor(AppColors.accentRed)
                    + Text(".")
                        .foregroundColor(AppColors.textPrimary)
                )
                .multilineTextAlignment(.center)
            } else if isLoading {
                Text("Loading your rank...")
                    .foregroundColor(AppColors.textPrimary)
                    .multilineTextAlignment(.center)
            } else {
                Text("No points yet this month — make a purchase to get on the board!")
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
                .fill(AppColors.surfaceSecondary)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(AppColors.borderSubtle, lineWidth: 1)
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
    @State private var showingManualPDF: Bool = false

    var body: some View {
        ZStack {
            SceneBackgroundView()

            VStack(spacing: 18) {
                Group {
                    if let url = unit.imageURL {
                        KFImage(url)
                            .placeholder {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 180)
                            }
                            .fade(duration: 0.3)
                            .resizable()
                            .scaledToFit()
                    } else {
                        Image("logoLaunch")
                            .resizable()
                            .scaledToFit()
                    }
                }
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
                } else if linkErrorMessage != nil {
                    Button("Contact Us") {
                        guard let topVC = UIApplication.shared.topMostViewController() else { return }
                        let sender = EmailSender()
                        sender.presentEmailSender(
                            from: topVC,
                            to: ["javier@ezinflatables.com"],
                            subject: "Download Request – \(unit.sku)",
                            body: "Hi, I need the download files for my unit: \(unit.sku)."
                        )
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(AppColors.buttonRedStart)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }

                Button("Download Manual") {
                    guard !manualLink.isEmpty else { return }
                    showingManualPDF = true
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(manualLink.isEmpty ? AppColors.buttonGhostFill.opacity(0.5) : AppColors.buttonGhostFill)
                .foregroundColor(manualLink.isEmpty ? AppColors.textMuted : AppColors.textPrimary)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .disabled(manualLink.isEmpty)
                .sheet(isPresented: $showingManualPDF) {
                    if let url = URL(string: manualLink) {
                        SafariView(url: url)
                            .ignoresSafeArea()
                    }
                }

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
                guard let url = URL(string: unitLink), !unitLink.isEmpty else { return }
                UIApplication.shared.open(url)
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

}


// MARK: - Monthly Prize Sheet

struct MonthlyPrizeSheet: View {
    @StateObject private var vm = MonthlyPrizeViewModel()

    private let gradientTop    = Color(hex: "FF6B6B")
    private let gradientBottom = Color(hex: "FF9F43")
    private var imageSide: CGFloat { UIScreen.main.bounds.width - 40 }

    var body: some View {
        ZStack {
            // Warm festive background
            LinearGradient(
                colors: [gradientTop, gradientBottom],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Group {
                if vm.isLoading {
                    VStack(spacing: 14) {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(1.4)
                        Text("Loading prize...")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white.opacity(0.85))
                    }
                } else if let prize = vm.prize {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {

                            // Hero header
                            VStack(spacing: 6) {
                                Text("🎁")
                                    .font(.system(size: 52))
                                Text("Monthly Prize")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.white.opacity(0.8))
                                    .kerning(2)
                                    .textCase(.uppercase)
                                Text("TOP BUYER WINS FREE!")
                                    .font(.system(size: 26, weight: .heavy))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.top, 32)
                            .padding(.bottom, 28)
                            .padding(.horizontal, 24)

                            // White card
                            VStack(alignment: .leading, spacing: 0) {

                                // Square image
                                ZStack {
                                    Color(AppColors.surfaceSecondary)
                                    if let url = prize.imageURL {
                                        AsyncImage(url: url) { image in
                                            image.resizable().scaledToFit()
                                        } placeholder: {
                                            Text(prize.emoji)
                                                .font(.system(size: imageSide * 0.45))
                                        }
                                    } else {
                                        Text(prize.emoji)
                                            .font(.system(size: imageSide * 0.45))
                                    }
                                }
                                .frame(width: imageSide, height: imageSide)
                                .clipShape(
                                        UnevenRoundedRectangle(
                                            topLeadingRadius: 24,
                                            bottomLeadingRadius: 0,
                                            bottomTrailingRadius: 0,
                                            topTrailingRadius: 24
                                        )
                                    )

                                // Info area
                                VStack(alignment: .leading, spacing: 12) {
                                    // "FREE" badge + name row
                                    HStack(alignment: .top, spacing: 10) {
                                        Text("FREE")
                                            .font(.system(size: 11, weight: .heavy))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(
                                                Capsule()
                                                    .fill(LinearGradient(
                                                        colors: [gradientTop, gradientBottom],
                                                        startPoint: .leading, endPoint: .trailing
                                                    ))
                                            )

                                        Text(prize.emoji + "  " + prize.name)
                                            .font(.system(size: 18, weight: .bold))
                                            .foregroundColor(AppColors.textPrimary)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }

                                    // Subtitle
                                    if let subtitle = prize.subtitle {
                                        Text(subtitle)
                                            .font(.system(size: 14))
                                            .foregroundColor(AppColors.textSecondary)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }

                                    // Expiry
                                    if let expiry = prize.expiryLabel {
                                        HStack(spacing: 5) {
                                            Image(systemName: "clock")
                                                .font(.system(size: 12))
                                            Text(expiry)
                                                .font(.system(size: 13, weight: .medium))
                                        }
                                        .foregroundColor(prize.isExpiringSoon ? AppColors.accentRed : AppColors.textMuted)
                                    }
                                }
                                .padding(20)
                            }
                            .background(AppColors.surfacePrimary)
                            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                            .shadow(color: Color.black.opacity(0.12), radius: 20, x: 0, y: 8)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 40)
                        }
                    }
                } else {
                    VStack(spacing: 14) {
                        Text("🎁")
                            .font(.system(size: 52))
                        Text("No prize announced yet.\nCheck back soon!")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white.opacity(0.85))
                            .multilineTextAlignment(.center)
                    }
                }
            }
        }
        .onAppear { vm.load() }
    }
}

private class MonthlyPrizeViewModel: ObservableObject {
    @Published var prize: PrizeItem?
    @Published var isLoading = true

    struct PrizeItem {
        let name: String
        let subtitle: String?
        let emoji: String
        let imageURL: URL?
        let expiresAt: Date?

        var expiryLabel: String? {
            guard let date = expiresAt else { return nil }
            let df = DateFormatter()
            df.dateStyle = .medium
            df.timeStyle = .none
            return "Ends \(df.string(from: date))"
        }

        var isExpiringSoon: Bool {
            guard let date = expiresAt else { return false }
            return date.timeIntervalSinceNow < 3 * 24 * 3600
        }
    }

    func load() {
        Database.database().reference().child("monthly_prize")
            .observeSingleEvent(of: .value) { [weak self] snapshot in
                let item = Self.parsePrize(from: snapshot)
                DispatchQueue.main.async {
                    self?.prize = item
                    self?.isLoading = false
                }
            }
    }

    private static func parsePrize(from snapshot: DataSnapshot) -> PrizeItem? {
        if let dict = snapshot.value as? [String: Any], dict["name"] != nil {
            return makePrizeItem(from: dict)
        }
        for case let child as DataSnapshot in snapshot.children {
            if let dict = child.value as? [String: Any] {
                return makePrizeItem(from: dict)
            }
        }
        return nil
    }

    private static func makePrizeItem(from dict: [String: Any]) -> PrizeItem? {
        let name = (dict["name"] as? String ?? dict["title"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return nil }
        let subtitle = dict["subtitle"] as? String ?? dict["description"] as? String
        let emoji = dict["emoji"] as? String ?? "🎁"
        let imageURLString = dict["imageURL"] as? String ?? dict["imageUrl"] as? String ?? dict["image_url"] as? String
        let imageURL = imageURLString.flatMap(URL.init(string:))
        let expiresAt = dateValue(in: dict, keys: ["expiresAt", "expires_at", "expiry", "expiration"])
        return PrizeItem(name: name, subtitle: subtitle, emoji: emoji, imageURL: imageURL, expiresAt: expiresAt)
    }

    private static func dateValue(in dict: [String: Any], keys: [String]) -> Date? {
        for key in keys {
            if let ts = dict[key] as? Double {
                let s = ts > 1_000_000_000_00 ? ts / 1000.0 : ts
                return Date(timeIntervalSince1970: s)
            }
            if let ts = dict[key] as? NSNumber {
                let s = ts.doubleValue > 1_000_000_000_00 ? ts.doubleValue / 1000.0 : ts.doubleValue
                return Date(timeIntervalSince1970: s)
            }
            if let str = dict[key] as? String {
                if let d = ISO8601DateFormatter().date(from: str) { return d }
                let df = DateFormatter(); df.dateFormat = "yyyy-MM-dd"
                if let d = df.date(from: str) { return d }
            }
        }
        return nil
    }
}
