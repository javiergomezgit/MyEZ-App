//
//  DealsView.swift
//  MyEZ
//
//  Created by Javier Gomez on 3/9/26.
//  Copyright © 2026 JDev. All rights reserved.
//

import SwiftUI
import FirebaseDatabase

// MARK: - Tab

private enum DealsTab: CaseIterable {
    case points, deals

    var label: String {
        switch self {
        case .points: return "🎯 Points"
        case .deals:  return "💰 Deals"
        }
    }
}

// MARK: - Main View

struct DealsView: View {
    @StateObject private var dealsVM  = DealsViewModel(path: "dealsLinks")
    @StateObject private var pointsVM = DealsViewModel(path: "pointsActivities")
    @EnvironmentObject private var appState: AppState
    @Environment(\.scenePhase) private var scenePhase

    @State private var selectedTab: DealsTab = .points
    @State private var blogItem: IdentifiableURL?
    @State private var showingPurchaseConfirm = false

    private var activeVM: DealsViewModel {
        selectedTab == .deals ? dealsVM : pointsVM
    }

    var body: some View {
        VStack(spacing: 0) {
            tabPicker
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 8)

            tabContent
        }
        .background { SceneBackgroundView() }
        .toolbar(.hidden, for: .navigationBar)
        .task { dealsVM.load(); pointsVM.load() }
        .onAppear { checkPendingPurchase() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { checkPendingPurchase() }
        }
        .alert("Purchase Complete?", isPresented: $showingPurchaseConfirm) {
            Button("Yes, I completed it") {
                if let dealID = appState.pendingPointsDealID,
                   let deal = pointsVM.deals.first(where: { $0.id == dealID }) {
                    recordActivity(for: deal)
                }
                appState.pendingPointsDealID = nil
            }
            Button("No", role: .cancel) {
                appState.pendingPointsDealID = nil
            }
        } message: {
            Text("Did you complete your purchase? Your points will be added if you did.")
        }
        .sheet(item: $blogItem) { item in
            SafariView(url: item.url).ignoresSafeArea()
        }
    }

    // MARK: Tab Picker

    private var tabPicker: some View {
        HStack(spacing: 0) {
            ForEach(DealsTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { selectedTab = tab }
                } label: {
                    Text(tab.label)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(selectedTab == tab ? .white : AppColors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(selectedTab == tab ? AppColors.buttonRedStart : Color.clear)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(AppColors.surfaceSecondary)
        )
    }

    // MARK: Tab Content

    @ViewBuilder
    private var tabContent: some View {
        if activeVM.isLoading {
            Spacer()
            ProgressView("Loading...")
                .tint(AppColors.textPrimary)
                .foregroundColor(AppColors.textPrimary)
            Spacer()
        } else if let errorMessage = activeVM.errorMessage {
            Spacer()
            DealsFeedbackView(
                title: "Unable to load \(selectedTab == .points ? "points" : "deals")",
                message: errorMessage,
                buttonTitle: "Try Again",
                action: activeVM.load
            )
            .padding(.horizontal, 28)
            Spacer()
        } else {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    Text(selectedTab.label)
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)

                    if activeVM.deals.isEmpty {
                        DealsEmptyView(tab: selectedTab == .points ? "Points" : "Deals", onRefresh: activeVM.load)
                    } else {
                        VStack(spacing: 16) {
                            ForEach(activeVM.deals) { deal in
                                DealCard(deal: deal) { handleAction(for: deal) }
                            }
                        }
                    }
                }
                .padding(.top, 12)
                .padding(.bottom, 100)
            }
            .padding(.horizontal, 20)
            .refreshable { activeVM.load() }
        }
    }

    private func handleAction(for deal: DealsViewModel.DealItem) {
        switch deal.normalizedActionType {
        case "go_to", "go_to_link":
            guard let url = URL(string: deal.actionValue) else { return }
            appState.pendingBrowseURL = url
            appState.selectedTab = .browse

        case "add_to_cart":
            openAddToCart(deal: deal)

        case "call_now":
            let digits = deal.actionValue.filter(\.isNumber)
            guard !digits.isEmpty, let url = URL(string: "tel://\(digits)") else { return }
            UIApplication.shared.open(url)

        case "email_now":
            guard let topVC = UIApplication.shared.topMostViewController() else { return }
            let sender = EmailSender()
            sender.presentEmailSender(from: topVC, to: [deal.actionValue],
                                      subject: "MyEZ – \(deal.name)", body: "")

        case "text_now":
            let digits = deal.actionValue.filter(\.isNumber)
            guard !digits.isEmpty, let url = URL(string: "sms:\(digits)") else { return }
            UIApplication.shared.open(url)

        case "blog_reading":
            let raw = deal.actionValue.trimmingCharacters(in: .whitespacesAndNewlines)
            let urlString = raw.hasPrefix("http") ? raw : "https://\(raw)"
            guard let url = URL(string: urlString) else { return }
            blogItem = IdentifiableURL(url: url)
            recordActivity(for: deal)

        case "buy_product":
            appState.pendingPointsDealID = deal.id
            openBuyProduct(deal: deal)

        case "post_sharing":
            sharePost(deal: deal)

        case "social_sharing":
            shareSocial(deal: deal)

        case "share_anything":
            shareAnything(deal: deal)

        default:
            break
        }
    }

    private func sharePost(deal: DealsViewModel.DealItem) {
        let message = "🔥 Just read this from EZ Inflatables — \(deal.name). Check it out!"
        let items: [Any] = [message, URL(string: deal.actionValue)].compactMap { $0 }
        presentShareSheet(items: items, deal: deal)
    }

    private func shareSocial(deal: DealsViewModel.DealItem) {
        let message = "🔥 Just read this from EZ Inflatables — \(deal.name). Check it out!"
        let items: [Any] = [message, URL(string: deal.actionValue)].compactMap { $0 }
        presentShareSheet(items: items, deal: deal)
    }

    private func shareAnything(deal: DealsViewModel.DealItem) {
        let message = "🎉 Sharing this with you from EZ Inflatables — \(deal.name). Don't miss it!"
        let items: [Any] = [message, URL(string: deal.actionValue)].compactMap { $0 }
        presentShareSheet(items: items, deal: deal)
    }

    private func presentShareSheet(items: [Any], deal: DealsViewModel.DealItem) {
        guard let topVC = UIApplication.shared.topMostViewController() else { return }
        let ac = UIActivityViewController(activityItems: items, applicationActivities: nil)
        if let popover = ac.popoverPresentationController {
            popover.sourceView = topVC.view
            popover.sourceRect = CGRect(x: topVC.view.bounds.midX, y: topVC.view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        ac.completionWithItemsHandler = { _, completed, _, _ in
            guard completed else { return }
            recordActivity(for: deal)
        }
        topVC.present(ac, animated: true)
    }

    // DEALS: navigates to the product page with ?autoAddToCart=1.
    // The JS injected in BrowseView reads the variant from the page form,
    // calls Shopify's AJAX cart API, and redirects to /cart.
    private func openAddToCart(deal: DealsViewModel.DealItem) {
        let raw = deal.actionValue.trimmingCharacters(in: .whitespacesAndNewlines)
        let urlString = raw.hasPrefix("http") ? raw : "https://\(raw)"
        guard var comps = URLComponents(string: urlString) else { return }
        var items = comps.queryItems ?? []
        items.append(URLQueryItem(name: "autoAddToCart", value: "1"))
        comps.queryItems = items
        guard let finalURL = comps.url else { return }
        DispatchQueue.main.async {
            appState.pendingBrowseURL = finalURL
            appState.selectedTab = .browse
        }
    }

    // POINTS: applies coupon then navigates to the product page with
    // ?autoAddToCart=1&autoCheckout=1. The JS auto-adds the item and
    // redirects to /checkout where the email is pre-filled.
    private func openBuyProduct(deal: DealsViewModel.DealItem) {
        let raw = deal.actionValue.trimmingCharacters(in: .whitespacesAndNewlines)
        let urlString = raw.hasPrefix("http") ? raw : "https://\(raw)"
        guard var productComps = URLComponents(string: urlString),
              let host = productComps.host else { return }

        var qItems = productComps.queryItems ?? []
        qItems.append(URLQueryItem(name: "autoAddToCart", value: "1"))
        qItems.append(URLQueryItem(name: "autoCheckout", value: "1"))
        productComps.queryItems = qItems
        guard let productURL = productComps.url else { return }
        let redirectPath = productURL.path + "?" + (productURL.query ?? "")

        let navigate: (String) -> Void = { code in
            var discountComps = URLComponents(string: "https://\(host)/discount/\(code)")
            discountComps?.queryItems = [URLQueryItem(name: "redirect", value: redirectPath)]
            guard let finalURL = discountComps?.url else { return }
            DispatchQueue.main.async {
                appState.pendingBrowseURL = finalURL
                appState.selectedTab = .browse
            }
        }

        if let code = deal.couponCode, !code.isEmpty {
            navigate(code)
        } else {
            Database.database().reference().child("coupon_code")
                .observeSingleEvent(of: .value) { snapshot in
                    let code = snapshot.value as? String ?? ""
                    navigate(code)
                }
        }
    }

    private func checkPendingPurchase() {
        guard appState.pendingPointsDealID != nil else { return }
        showingPurchaseConfirm = true
    }

    private func recordActivity(for deal: DealsViewModel.DealItem) {
        let uid = UserDefaults.standard.string(forKey: "firebaseUID") ?? ""
        guard !uid.isEmpty else { return }

        let db = Database.database().reference()
        let transactionRef = db.child("users").child(uid)
            .child("pointTransactions").child(deal.id)

        // Only record once — if the activity ID already exists, skip
        transactionRef.observeSingleEvent(of: .value) { snapshot in
            guard !snapshot.exists() else { return }

            let data: [String: Any] = [
                "doneDate": Date().timeIntervalSince1970,
                "score": deal.score,
                "type": deal.actionType
            ]
            transactionRef.setValue(data)

            guard deal.score > 0 else { return }

            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM"
            let monthKey = formatter.string(from: Date())

            db.child("leaderboards").child(monthKey).child(uid).child("score")
                .setValue(ServerValue.increment(NSNumber(value: deal.score)))
        }
    }
}

// MARK: - Deal Card

private struct DealCard: View {
    let deal: DealsViewModel.DealItem
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Color(AppColors.surfaceSecondary)
                .overlay(
                    AsyncImage(url: deal.imageURL) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().scaledToFill()
                        case .failure:
                            fallbackImageView
                        case .empty:
                            ZStack {
                                AppColors.surfaceSecondary
                                ProgressView().tint(AppColors.buttonRedStart)
                            }
                        @unknown default:
                            fallbackImageView
                        }
                    }
                )
                .clipped()
            .frame(maxWidth: .infinity)
            .frame(height: 190)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            HStack(alignment: .top, spacing: 8) {
                Text(deal.name)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if let expiryLabel = deal.expiryLabel {
                    ExpiryPill(label: expiryLabel, isSoon: deal.isExpiringSoon)
                }
            }

            HStack(alignment: .top, spacing: 8) {
                if let subtitle = deal.subtitle {
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(AppColors.textSecondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    Spacer()
                }

                if let countdown = deal.countdownLabel {
                    Text(countdown)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(deal.isExpiringSoon ? AppColors.buttonRedEnd : AppColors.textMuted)
                        .multilineTextAlignment(.trailing)
                }
            }

            HStack(spacing: 12) {
                Button(action: action) {
                    HStack(spacing: 6) {
                        Text(deal.buttonTitle)
                            .font(.system(size: 15, weight: .semibold))
                        if deal.normalizedActionType == "go_to", let emoji = deal.emoji {
                            Text(emoji)
                                .font(.system(size: 15))
                        } else {
                            Image(systemName: deal.buttonIcon)
                                .font(.system(size: 13, weight: .bold))
                        }
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 13)
                    .frame(maxWidth: .infinity)
                    .background(
                        LinearGradient(
                            colors: deal.isPointsActivity
                                ? [AppColors.buttonBlueStart, AppColors.buttonBlueEnd]
                                : [AppColors.buttonRedStart, AppColors.buttonRedEnd],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                    )
                }
                .buttonStyle(.plain)

            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .sceneCard(cornerRadius: 22, fillColor: AppColors.surfacePrimary)
    }

    private var fallbackImageView: some View {
        ZStack {
            LinearGradient(
                colors: [AppColors.surfaceSecondary, AppColors.surfaceElevated],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            if deal.normalizedActionType == "go_to" {
                Text(deal.emoji ?? "⭐")
                    .font(.system(size: 60))
            } else {
                Image(systemName: "tag.fill")
                    .font(.system(size: 40, weight: .medium))
                    .foregroundColor(AppColors.textMuted)
            }
        }
    }
}

// MARK: - Expiry Pill

private struct ExpiryPill: View {
    let label: String
    let isSoon: Bool

    var body: some View {
        Text(label)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(isSoon ? AppColors.buttonRedEnd : AppColors.textMuted)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill((isSoon ? AppColors.buttonRedStart : AppColors.textMuted).opacity(0.10))
            )
    }
}

// MARK: - Empty State

private struct DealsEmptyView: View {
    let tab: String
    let onRefresh: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(AppColors.buttonRedStart.opacity(0.08))
                    .frame(width: 88, height: 88)
                Image(systemName: "tag.slash.fill")
                    .font(.system(size: 36, weight: .medium))
                    .foregroundColor(AppColors.buttonRedStart)
            }

            VStack(spacing: 8) {
                Text("No Active \(tab)")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)

                Text("Check back soon — new offers are added regularly.")
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Button("Refresh", action: onRefresh)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 28)
                .padding(.vertical, 13)
                .background(
                    LinearGradient(
                        colors: [AppColors.buttonRedStart, AppColors.buttonRedEnd],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    in: Capsule()
                )
        }
        .padding(32)
        .frame(maxWidth: .infinity)
        .sceneCard()
        .padding(.top, 40)
    }
}

// MARK: - Feedback View

private struct DealsFeedbackView: View {
    let title: String
    let message: String
    let buttonTitle: String
    let action: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            Text(title)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(AppColors.textPrimary)

            Text(message)
                .font(.system(size: 15))
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)

            Button(buttonTitle, action: action)
                .font(.system(size: 15, weight: .semibold))
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [AppColors.buttonRedStart, AppColors.buttonRedEnd],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
                .foregroundColor(.white)
        }
        .padding(24)
        .sceneCard()
    }
}

// MARK: - ViewModel

final class DealsViewModel: ObservableObject {
    struct DealItem: Identifiable {
        let id: String
        let actionType: String
        let actionValue: String
        let emoji: String?
        let subtype: String?
        let imageURL: URL?
        let name: String
        let subtitle: String?
        let sort: Int
        let expiresAt: Date?
        let score: Int
        let couponCode: String?

        var buttonTitle: String {
            switch normalizedActionType {
            case "go_to":
                guard let sub = subtype, !sub.isEmpty else { return "Go To" }
                return sub.replacingOccurrences(of: "_", with: " ").capitalized
            case "go_to_link":      return "View Offer"
            case "call_now":        return "Call Now"
            case "email_now":       return "Email Us"
            case "text_now":        return "Text Us"
            case "add_to_cart":     return "Add to Cart"
            case "blog_reading":    return "Read More"
            case "post_sharing":    return "Share Post"
            case "social_sharing":  return "Share Social Media"
            case "buy_product":     return "Buy Now"
            case "share_anything":  return "Share"
            default:                return "View Offer"
            }
        }

        var buttonIcon: String {
            switch normalizedActionType {
            case "go_to":           return "arrow.up.right"
            case "go_to_link":      return "arrow.up.right"
            case "call_now":        return "phone.fill"
            case "email_now":       return "envelope.fill"
            case "text_now":        return "message.fill"
            case "add_to_cart":     return "cart.badge.plus"
            case "blog_reading":    return "book.fill"
            case "post_sharing":    return "square.and.arrow.up"
            case "social_sharing":  return "person.2.fill"
            case "buy_product":     return "bag.fill"
            case "share_anything":  return "square.and.arrow.up"
            default:                return "tag.fill"
            }
        }

        var normalizedActionType: String {
            actionType.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        }

        var isPointsActivity: Bool { score > 0 }

        var expiryLabel: String? {
            guard let date = expiresAt else { return nil }
            guard date > Date() else { return "Expired" }
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return "Ends \(formatter.string(from: date))"
        }

        var countdownLabel: String? {
            guard let date = expiresAt else { return nil }
            let seconds = date.timeIntervalSince(Date())
            guard seconds > 0 else { return nil }
            let days = Int(seconds / 86400)
            let hours = Int(seconds.truncatingRemainder(dividingBy: 86400) / 3600)
            if days > 0 { return "\(days) day\(days == 1 ? "" : "s"), \(hours) hr\(hours == 1 ? "" : "s")" }
            let minutes = Int(seconds.truncatingRemainder(dividingBy: 3600) / 60)
            if hours > 0 { return "\(hours) hr\(hours == 1 ? "" : "s"), \(minutes) min" }
            return "\(minutes) min"
        }

        var isExpiringSoon: Bool {
            guard let date = expiresAt else { return false }
            return date.timeIntervalSince(Date()) < 3 * 86400
        }
    }

    @Published var deals: [DealItem] = []
    @Published var isLoading = true
    @Published var errorMessage: String?

    private lazy var dbRef: DatabaseReference = Database.database().reference()
    private let path: String

    init(path: String) {
        self.path = path
    }

    func load() {
        isLoading = true
        errorMessage = nil

        dbRef.child(path).observeSingleEvent(of: .value) { [weak self] snapshot in
            guard let self else { return }
            let items = Self.extractDealItems(from: snapshot)
                .sorted { lhs, rhs in
                    lhs.sort == rhs.sort
                        ? lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
                        : lhs.sort < rhs.sort
                }
            DispatchQueue.main.async {
                self.deals = Array(items.prefix(5))
                self.errorMessage = items.isEmpty ? "No items found." : nil
                self.isLoading = false
            }
        } withCancel: { [weak self] error in
            DispatchQueue.main.async {
                self?.errorMessage = error.localizedDescription
                self?.deals = []
                self?.isLoading = false
            }
        }
    }

    // kept for backward compatibility with call sites that used loadDeals()
    func loadDeals() { load() }

    private static func extractDealItems(from snapshot: DataSnapshot) -> [DealItem] {
        let directItems = snapshot.children.allObjects
            .compactMap { $0 as? DataSnapshot }
            .compactMap(makeDealItem(from:))
        if !directItems.isEmpty { return directItems }
        return snapshot.children.allObjects
            .compactMap { $0 as? DataSnapshot }
            .flatMap { parent in
                parent.children.allObjects
                    .compactMap { $0 as? DataSnapshot }
                    .compactMap(makeDealItem(from:))
            }
    }

    private static func makeDealItem(from snapshot: DataSnapshot) -> DealItem? {
        guard let value = snapshot.value as? [String: Any] else { return nil }

        let actionType  = stringValue(in: value, keys: ["actionType", "action_type"])
        let actionValue = stringValue(in: value, keys: ["actionValue", "action_value"])
        let emoji       = stringValue(in: value, keys: ["emoji"])
        let subtype     = stringValue(in: value, keys: ["subtype"])
        let imageURL    = stringValue(in: value, keys: ["imageURL", "imageUrl", "image_url"])
        let name        = stringValue(in: value, keys: ["name", "title"]) ?? "Deal"
        let subtitle    = stringValue(in: value, keys: ["subtitle", "description", "benefit"])
        let sort        = intValue(in: value, keys: ["sort"]) ?? Int.max
        let expiresAt   = dateValue(in: value, keys: ["expiresAt", "expires_at", "expiry", "expiration"])
        let score       = intValue(in: value, keys: ["score", "points"]) ?? 0
        let couponCode  = stringValue(in: value, keys: ["coupon_code", "couponCode"])

        guard let actionType, let actionValue else { return nil }

        return DealItem(
            id: snapshot.key,
            actionType: actionType,
            actionValue: actionValue,
            emoji: emoji,
            subtype: subtype,
            imageURL: imageURL.flatMap(URL.init(string:)),
            name: name,
            subtitle: subtitle,
            sort: sort,
            expiresAt: expiresAt,
            score: score,
            couponCode: couponCode
        )
    }

    private static func stringValue(in dict: [String: Any], keys: [String]) -> String? {
        keys.lazy.compactMap { dict[$0] as? String }
            .first { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    private static func intValue(in dict: [String: Any], keys: [String]) -> Int? {
        for key in keys {
            if let v = dict[key] as? Int { return v }
            if let v = dict[key] as? NSNumber { return v.intValue }
            if let v = dict[key] as? String, let i = Int(v) { return i }
        }
        return nil
    }

    private static func dateValue(in dict: [String: Any], keys: [String]) -> Date? {
        for key in keys {
            if let ts = dict[key] as? Double {
                let s = ts > 1_000_000_000_00 ? ts / 1000.0 : ts
                return Date(timeIntervalSince1970: s)
            }
            if let ts = dict[key] as? NSNumber {
                let raw = ts.doubleValue
                let s = raw > 1_000_000_000_00 ? raw / 1000.0 : raw
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
