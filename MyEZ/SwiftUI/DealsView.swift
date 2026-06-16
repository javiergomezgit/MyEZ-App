//
//  DealsView.swift
//  MyEZ
//
//  Created by Javier Gomez on 3/9/26.
//  Copyright © 2026 JDev. All rights reserved.
//

import SwiftUI
import FirebaseDatabase

struct DealsView: View {
    @StateObject private var viewModel = DealsViewModel()
    @EnvironmentObject private var appState: AppState

    var body: some View {
        content
            .background { SceneBackgroundView() }
            .toolbar(.hidden, for: .navigationBar)
            .task {
                viewModel.loadDeals()
            }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading {
            ProgressView("Loading deals...")
                .tint(.white)
                .foregroundColor(.white)
                .padding(.horizontal, 20)
        } else if let errorMessage = viewModel.errorMessage {
            DealsFeedbackView(
                title: "Unable to load deals",
                message: errorMessage,
                buttonTitle: "Try Again",
                action: viewModel.loadDeals
            )
            .padding(.horizontal, 28)
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header

                    if viewModel.deals.isEmpty {
                        DealsEmptyView(onRefresh: viewModel.loadDeals)
                    } else {
                        VStack(spacing: 16) {
                            ForEach(viewModel.deals) { deal in
                                DealCard(deal: deal) {
                                    handleAction(for: deal)
                                }
                            }
                        }
                    }
                }
                .padding(.top, 12)
                .padding(.bottom, 100)
            }
            .padding(.horizontal, 20)
            .refreshable {
                viewModel.loadDeals()
            }
        }
    }

    private var header: some View {
        Text("Deals")
            .font(.system(size: 30, weight: .bold))
            .foregroundColor(AppColors.textPrimary)
    }

    private func handleAction(for deal: DealsViewModel.DealItem) {
        switch deal.normalizedActionType {
        case "go_to_link", "add_to_cart":
            guard let url = URL(string: deal.actionValue) else { return }
            appState.pendingBrowseURL = url
            appState.selectedTab = .browse
        case "call_now":
            let digits = deal.actionValue.filter(\.isNumber)
            guard !digits.isEmpty, let url = URL(string: "tel://\(digits)") else { return }
            UIApplication.shared.open(url)
        case "email_now":
            guard let topVC = UIApplication.shared.topMostViewController() else { return }
            let sender = EmailSender()
            sender.presentEmailSender(
                from: topVC,
                to: [deal.actionValue],
                subject: "MyEZ – \(deal.name)",
                body: ""
            )
        case "text_now":
            let digits = deal.actionValue.filter(\.isNumber)
            guard !digits.isEmpty, let url = URL(string: "sms:\(digits)") else { return }
            UIApplication.shared.open(url)
        default:
            break
        }
    }
}

// MARK: - Deal Card

private struct DealCard: View {
    let deal: DealsViewModel.DealItem
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Image — ZStack owns the frame; AsyncImage fills it via overlay
            ZStack(alignment: .topTrailing) {
                Color(AppColors.surfaceSecondary)
                    .overlay(
                        AsyncImage(url: deal.imageURL) { phase in
                            switch phase {
                            case .success(let image):
                                image.resizable().scaledToFill()
                            case .failure:
                                fallbackImage
                            case .empty:
                                ZStack {
                                    AppColors.surfaceSecondary
                                    ProgressView().tint(AppColors.buttonRedStart)
                                }
                            @unknown default:
                                fallbackImage
                            }
                        }
                    )
                    .clipped()

                Text(deal.emoji)
                    .font(.system(size: 30))
                    .padding(8)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 190)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            // Row 1: title (left) | expiry pill (right)
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

            // Row 2: subtitle (left) | countdown (right)
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

            // CTA button — full width
            Button(action: action) {
                HStack(spacing: 6) {
                    Text(deal.buttonTitle)
                        .font(.system(size: 15, weight: .semibold))
                    Image(systemName: deal.buttonIcon)
                        .font(.system(size: 13, weight: .bold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 13)
                .frame(maxWidth: .infinity)
                .background(
                    LinearGradient(
                        colors: [AppColors.buttonRedStart, AppColors.buttonRedEnd],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .sceneCard(cornerRadius: 22, fillColor: .white)
    }

    private var fallbackImage: some View {
        ZStack {
            LinearGradient(
                colors: [AppColors.surfaceSecondary, AppColors.surfaceElevated],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Image(systemName: "tag.fill")
                .font(.system(size: 40, weight: .medium))
                .foregroundColor(AppColors.textMuted)
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
                Text("No Active Deals")
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

// MARK: - Error / Feedback View

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
        let emoji: String
        let imageURL: URL?
        let name: String
        let subtitle: String?
        let sort: Int
        let expiresAt: Date?

        var buttonTitle: String {
            switch normalizedActionType {
            case "go_to_link":  return "View Offer"
            case "call_now":    return "Call Now"
            case "email_now":   return "Email Us"
            case "text_now":    return "Text Us"
            case "add_to_cart": return "Add to Cart"
            default:            return "View Offer"
            }
        }

        var buttonIcon: String {
            switch normalizedActionType {
            case "go_to_link":  return "arrow.up.right"
            case "call_now":    return "phone.fill"
            case "email_now":   return "envelope.fill"
            case "text_now":    return "message.fill"
            case "add_to_cart": return "cart.badge.plus"
            default:            return "tag.fill"
            }
        }

        var normalizedActionType: String {
            actionType.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        }

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
            if days > 0 {
                return "\(days) day\(days == 1 ? "" : "s"), \(hours) hr\(hours == 1 ? "" : "s")"
            }
            let minutes = Int(seconds.truncatingRemainder(dividingBy: 3600) / 60)
            if hours > 0 {
                return "\(hours) hr\(hours == 1 ? "" : "s"), \(minutes) min"
            }
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
    private let dealsPath = "dealsLinks"

    func loadDeals() {
        isLoading = true
        errorMessage = nil
        print("[Deals] Starting Firebase fetch from node: \(dealsPath)")

        dbRef.child(dealsPath).observeSingleEvent(of: .value) { [weak self] snapshot in
            guard let self else { return }

            print("[Deals] Snapshot exists: \(snapshot.exists()), children: \(snapshot.childrenCount)")

            let items = Self.extractDealItems(from: snapshot)
                .sorted { lhs, rhs in
                    lhs.sort == rhs.sort
                        ? lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
                        : lhs.sort < rhs.sort
                }

            DispatchQueue.main.async {
                self.deals = Array(items.prefix(5))
                self.errorMessage = items.isEmpty
                    ? "No valid deals were parsed from `\(self.dealsPath)`. Check the Xcode console logs."
                    : nil
                self.isLoading = false
                print("[Deals] Rendered \(self.deals.count) deals: \(self.deals.map(\.name))")
            }
        } withCancel: { [weak self] error in
            DispatchQueue.main.async {
                self?.errorMessage = error.localizedDescription
                self?.deals = []
                self?.isLoading = false
            }
            print("[Deals] Firebase read cancelled: \(error.localizedDescription)")
        }
    }

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
        let emoji       = stringValue(in: value, keys: ["emoji"]) ?? "🎉"
        let imageURL    = stringValue(in: value, keys: ["imageURL", "imageUrl", "image_url"])
        let name        = stringValue(in: value, keys: ["name", "title"]) ?? "Deal"
        let subtitle    = stringValue(in: value, keys: ["subtitle", "description", "benefit"])
        let sort        = intValue(in: value, keys: ["sort"]) ?? Int.max
        let expiresAt   = dateValue(in: value, keys: ["expiresAt", "expires_at", "expiry", "expiration"])

        guard let actionType, let actionValue else { return nil }

        return DealItem(
            id: snapshot.key,
            actionType: actionType,
            actionValue: actionValue,
            emoji: emoji,
            imageURL: imageURL.flatMap(URL.init(string:)),
            name: name,
            subtitle: subtitle,
            sort: sort,
            expiresAt: expiresAt
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
            // Unix timestamp — values above 1e11 are milliseconds (Firebase JS default)
            if let ts = dict[key] as? Double {
                let seconds = ts > 1_000_000_000_00 ? ts / 1000.0 : ts
                return Date(timeIntervalSince1970: seconds)
            }
            if let ts = dict[key] as? NSNumber {
                let raw = ts.doubleValue
                let seconds = raw > 1_000_000_000_00 ? raw / 1000.0 : raw
                return Date(timeIntervalSince1970: seconds)
            }
            // ISO-8601 string
            if let str = dict[key] as? String {
                let formatter = ISO8601DateFormatter()
                if let date = formatter.date(from: str) { return date }
                // "yyyy-MM-dd" fallback
                let df = DateFormatter()
                df.dateFormat = "yyyy-MM-dd"
                if let date = df.date(from: str) { return date }
            }
        }
        return nil
    }
}
