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
    @Environment(\.openURL) private var openURL

    var body: some View {
        ZStack {
            SceneBackgroundView()

            content
        }
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
                        DealsFeedbackView(
                            title: "No deals yet",
                            message: "Connect the Firebase `deals` node and this screen will show the first 5 offers automatically.",
                            buttonTitle: "Refresh",
                            action: viewModel.loadDeals
                        )
                    } else {
                        LazyVStack(spacing: 31) {
                            ForEach(viewModel.deals) { deal in
                                DealCard(deal: deal) {
                                    handleAction(for: deal)
                                }
                            }
                        }
                    }
                }
                .frame(maxWidth: 340)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 12)
                .padding(.bottom, 100)
            }
            .safeAreaPadding(.horizontal, 24)
            .refreshable {
                viewModel.loadDeals()
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Deals")
                .font(.system(size: 30, weight: .bold))
                .foregroundColor(AppColors.textPrimary)
        }
    }

    private func handleAction(for deal: DealsViewModel.DealItem) {
        guard let url = deal.actionURL else { return }
        openURL(url)
    }
}

private struct DealCard: View {
    let deal: DealsViewModel.DealItem
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ZStack(alignment: .topLeading) {
                AsyncImage(url: deal.imageURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                    case .failure:
                        fallbackImage
                    case .empty:
                        ZStack {
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [AppColors.surfaceSecondary, AppColors.surfaceElevated],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            ProgressView()
                                .tint(AppColors.buttonBlueEnd)
                        }
                    @unknown default:
                        fallbackImage
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 104)
                .background(AppColors.surfaceSecondary)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            }
            .frame(maxWidth: .infinity)

            VStack(alignment: .leading, spacing: 8) {
                Text(deal.name)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.trailing, 52)
            }

            Button(action: action) {
                HStack {
                    Text(deal.buttonTitle)
                        .font(.system(size: 15, weight: .semibold))
                    Spacer()
                    Image(systemName: deal.buttonIcon)
                        .font(.system(size: 15, weight: .bold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [AppColors.buttonBlueStart, AppColors.buttonBlueEnd],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .clipped()
        .sceneCard(cornerRadius: 26, fillColor: AppColors.surfacePrimary)
        .overlay(alignment: .topTrailing) {
            Text(deal.emoji)
                .font(.system(size: 34))
                .offset(x: 7, y: -7)
        }
    }

    private var fallbackImage: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [AppColors.surfaceSecondary, AppColors.surfaceElevated],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Image(systemName: "photo")
                .font(.system(size: 32, weight: .medium))
                .foregroundColor(AppColors.textMuted)
        }
        .frame(maxWidth: .infinity)
    }
}

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
                                colors: [AppColors.buttonBlueStart, AppColors.buttonBlueEnd],
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

final class DealsViewModel: ObservableObject {
    struct DealItem: Identifiable {
        let id: String
        let actionType: String
        let actionValue: String
        let emoji: String
        let imageURL: URL?
        let name: String
        let sort: Int

        var buttonTitle: String {
            switch normalizedActionType {
            case "call_now":
                return "Call Now"
            case "open_url":
                return "Open Deal"
            default:
                return "View Offer"
            }
        }

        var buttonIcon: String {
            switch normalizedActionType {
            case "call_now":
                return "phone.fill"
            case "open_url":
                return "arrow.up.right"
            default:
                return "tag.fill"
            }
        }

        var actionURL: URL? {
            switch normalizedActionType {
            case "call_now":
                let digits = actionValue.filter(\.isNumber)
                return URL(string: "tel://\(digits)")
            case "open_url":
                return URL(string: actionValue)
            default:
                if actionValue.contains("://") {
                    return URL(string: actionValue)
                }
                let digits = actionValue.filter(\.isNumber)
                guard !digits.isEmpty else { return nil }
                return URL(string: "tel://\(digits)")
            }
        }

        private var normalizedActionType: String {
            actionType.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        }

        private var formattedActionValue: String {
            let digits = actionValue.filter(\.isNumber)
            guard digits.count == 10 else { return actionValue }

            let areaCode = digits.prefix(3)
            let prefix = digits.dropFirst(3).prefix(3)
            let lineNumber = digits.suffix(4)
            return "(\(areaCode)) \(prefix)-\(lineNumber)"
        }
    }

    @Published var deals: [DealItem] = []
    @Published var isLoading = true
    @Published var errorMessage: String?
    @Published var sourceLabel: String = "Firebase ready"

    private lazy var dbRef: DatabaseReference = Database.database().reference()
    private let dealsPath = "dealsLinks"

    func loadDeals() {
        isLoading = true
        errorMessage = nil
        sourceLabel = dealsPath
        print("[Deals] Starting Firebase fetch from node: \(dealsPath)")

        dbRef.child(dealsPath).observeSingleEvent(of: .value) { [weak self] snapshot in
            guard let self else { return }

            print("[Deals] Snapshot exists: \(snapshot.exists())")
            print("[Deals] Snapshot children count: \(snapshot.childrenCount)")
            print("[Deals] Snapshot key: \(snapshot.key)")
            print("[Deals] Snapshot raw value type: \(type(of: snapshot.value as Any))")
            if let rawValue = snapshot.value {
                print("[Deals] Snapshot raw value: \(rawValue)")
            } else {
                print("[Deals] Snapshot raw value is nil")
            }

            let items = Self.extractDealItems(from: snapshot)
                .sorted { lhs, rhs in
                    if lhs.sort == rhs.sort {
                        return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
                    }
                    return lhs.sort < rhs.sort
                }

            DispatchQueue.main.async {
                self.deals = Array(items.prefix(5))
                self.errorMessage = items.isEmpty ? "No valid deals were parsed from `\(self.dealsPath)`. Check the Xcode console logs for the snapshot structure." : nil
                self.isLoading = false
                print("[Deals] Final rendered deals count: \(self.deals.count)")
                print("[Deals] Final deal names: \(self.deals.map(\.name))")
            }
        } withCancel: { [weak self] error in
            DispatchQueue.main.async {
                self?.errorMessage = error.localizedDescription
                self?.deals = []
                self?.isLoading = false
            }
            print("[Deals] Firebase read cancelled with error: \(error.localizedDescription)")
        }
    }

    private static func extractDealItems(from snapshot: DataSnapshot) -> [DealItem] {
        print("[Deals] Attempting direct child parsing")
        let directItems = snapshot.children.allObjects
            .compactMap { $0 as? DataSnapshot }
            .compactMap(makeDealItem(from:))

        if !directItems.isEmpty {
            print("[Deals] Parsed \(directItems.count) direct child deals")
            return directItems
        }

        print("[Deals] No direct child deals found, attempting nested parsing")
        let nestedItems = snapshot.children.allObjects
            .compactMap { $0 as? DataSnapshot }
            .flatMap { parent in
                print("[Deals] Inspecting nested parent: \(parent.key), child count: \(parent.childrenCount)")
                return parent.children.allObjects
                    .compactMap { $0 as? DataSnapshot }
                    .compactMap(makeDealItem(from:))
            }

        print("[Deals] Parsed \(nestedItems.count) nested deals")
        return nestedItems
    }

    private static func makeDealItem(from snapshot: DataSnapshot) -> DealItem? {
        guard let value = snapshot.value as? [String: Any] else {
            print("[Deals] Skipping snapshot \(snapshot.key): value is not a [String: Any]. Actual value: \(String(describing: snapshot.value))")
            return nil
        }

        print("[Deals] Inspecting deal snapshot \(snapshot.key): \(value)")

        let actionType = stringValue(in: value, keys: ["actionType", "action_type"])
        let actionValue = stringValue(in: value, keys: ["actionValue", "action_value"])
        let emoji = stringValue(in: value, keys: ["emoji"]) ?? "🎉"
        let imageURLString = stringValue(in: value, keys: ["imageURL", "imageUrl", "image_url"])
        let name = stringValue(in: value, keys: ["name", "title"]) ?? "Deal"
        let sort = intValue(in: value, keys: ["sort"]) ?? Int.max

        guard let actionType, let actionValue else {
            print("[Deals] Skipping snapshot \(snapshot.key): missing actionType or actionValue")
            return nil
        }

        print("[Deals] Parsed deal -> id: \(snapshot.key), name: \(name), actionType: \(actionType), actionValue: \(actionValue), emoji: \(emoji), sort: \(sort), imageURL: \(imageURLString ?? "nil")")

        return DealItem(
            id: snapshot.key,
            actionType: actionType,
            actionValue: actionValue,
            emoji: emoji,
            imageURL: imageURLString.flatMap(URL.init(string:)),
            name: name,
            sort: sort
        )
    }

    private static func stringValue(in dictionary: [String: Any], keys: [String]) -> String? {
        for key in keys {
            if let value = dictionary[key] as? String, !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return value
            }
        }
        return nil
    }

    private static func intValue(in dictionary: [String: Any], keys: [String]) -> Int? {
        for key in keys {
            if let value = dictionary[key] as? Int {
                return value
            }
            if let value = dictionary[key] as? NSNumber {
                return value.intValue
            }
            if let value = dictionary[key] as? String, let intValue = Int(value) {
                return intValue
            }
        }
        return nil
    }
}
