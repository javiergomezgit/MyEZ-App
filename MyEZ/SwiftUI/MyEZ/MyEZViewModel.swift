import Foundation
import FirebaseDatabase
import UIKit

final class MyEZViewModel: ObservableObject {
    struct UnitDisplayItem: Identifiable {
        let id = UUID()
        let sku: String
        let qty: Int
        var imageURL: URL?
    }

    struct TopUserDisplay: Identifiable {
        let id = UUID()
        let place: Int
        let scoreText: String
        let displayText: String
        let medal: String
    }

    @Published var displayUnits: [UnitDisplayItem] = []
    @Published var isAuthenticated: Bool = false
    @Published var categoryName: String = userInformation.typeUser
    @Published var categoryImageName: String = userInformation.typeUser
    @Published var ownedUnitsText: String = "You own \(userInformation.weight) Pounds of inflatable"
    @Published var topUsers: [TopUserDisplay] = []
    @Published var monthlyPlace: Int = 0
    @Published var monthlyScore: Int = 0
    @Published var isLoadingLeaderboard: Bool = true
    @Published var ownedWeight: Int = 0
    @Published var manualLink: String = ""
    @Published var unitLink: String = ""
    @Published var selectedUnit: UnitDisplayItem?
    @Published var showingDownload = false

    private lazy var dbRef: DatabaseReference = Database.database().reference()

    private var firebaseUID: String {
        UserDefaults.standard.string(forKey: "firebaseUID") ?? ""
    }

    func load() {
        syncAuthenticationState()
        loadUnitsFromFirebase()
        loadInfoHeader()
        loadTopUsers()
    }

    func refreshAll() {
        syncAuthenticationState()
        loadUnitsFromFirebase()
        loadInfoHeader()
        loadTopUsers()
    }

    func select(unit: UnitDisplayItem) {
        selectedUnit = unit
        fetchLinks(for: unit)
    }

    private func loadUnitsFromFirebase() {
        guard isAuthenticated, !firebaseUID.isEmpty else {
            displayUnits = []
            print("⚠️ MyEZ units fetch skipped: user is not signed in")
            return
        }

        dbRef.child("users").child(firebaseUID).child("units").getData { [weak self] error, snapshot in
            guard let self = self else { return }
            if let error = error {
                DispatchQueue.main.async { self.displayUnits = [] }
                print("❌ Failed to fetch units: \(error.localizedDescription)")
                return
            }
            guard let snapshot = snapshot, snapshot.exists(),
                  let dict = snapshot.value as? [String: Any] else {
                DispatchQueue.main.async { self.displayUnits = [] }
                return
            }

            var units: [UnitDisplayItem] = dict.compactMap { sku, rawQty in
                guard sku != "SKU" else { return nil }
                let qty = Self.intFromAny(rawQty) ?? 1
                return UnitDisplayItem(sku: sku, qty: qty)
            }.sorted { $0.sku < $1.sku }

            DispatchQueue.main.async { self.displayUnits = units }

            self.dbRef.child("product_images").getData { [weak self] _, imgSnapshot in
                guard let self = self,
                      let imgDict = imgSnapshot?.value as? [String: Any] else { return }
                for i in units.indices {
                    if let urlString = imgDict[units[i].sku] as? String {
                        units[i].imageURL = URL(string: urlString)
                    }
                }
                DispatchQueue.main.async { self.displayUnits = units }
            }
        }
    }

    private func syncAuthenticationState() {
        let uid = firebaseUID
        isAuthenticated = UserSession.shared.load() != nil && !uid.isEmpty
    }

    private func loadInfoHeader() {
        guard !firebaseUID.isEmpty else { return }
        dbRef.child("users").child(firebaseUID).getData { [weak self] _, snapshot in
            guard let self = self,
                  let dict = snapshot?.value as? [String: Any] else { return }
            let weight = Self.intFromAny(dict["owned_weight"] as Any) ?? userInformation.weight
            userInformation.weight = weight
            userInformation.typeUser = checkTypeUser(weightUnits: weight)
            let resolvedType = userInformation.typeUser.isEmpty ? "minimumweight" : userInformation.typeUser
            DispatchQueue.main.async {
                self.categoryName = resolvedType.uppercased()
                self.categoryImageName = resolvedType
                self.ownedUnitsText = "You own \(weight) Pounds of inflatable"
                self.ownedWeight = weight
            }
        }
    }

    private func loadTopUsers() {
        isLoadingLeaderboard = true
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        let monthKey = formatter.string(from: Date())
        let uid = firebaseUID

        dbRef.child("leaderboards").child(monthKey).getData { [weak self] _, snapshot in
            guard let self = self else { return }
            guard let snapshot = snapshot,
                  let entries = snapshot.value as? [String: Any] else {
                DispatchQueue.main.async {
                    self.topUsers = []
                    self.monthlyPlace = 0
                    self.isLoadingLeaderboard = false
                }
                return
            }

            let scored: [(uid: String, score: Int, display: String)] = entries.compactMap { entryUID, value in
                guard let dict = value as? [String: Any],
                      let score = Self.intFromAny(dict["score"] as Any) else { return nil }
                let display = dict["display"] as? String ?? "—"
                return (entryUID, score, display)
            }.sorted { $0.score > $1.score }

            let numberFormatter = NumberFormatter()
            numberFormatter.numberStyle = .decimal

            let top5 = scored.prefix(5)
            let topDisplays: [TopUserDisplay] = top5.enumerated().map { index, entry in
                let formattedScore = numberFormatter.string(from: NSNumber(value: entry.score)) ?? "\(entry.score)"
                return TopUserDisplay(
                    place: index + 1,
                    scoreText: "\(formattedScore) pts",
                    displayText: entry.display,
                    medal: Self.medal(for: index)
                )
            }

            let currentIndex = scored.firstIndex { $0.uid == uid }
            let currentPlace = currentIndex.map { $0 + 1 } ?? 0
            let currentScore = currentIndex.map { scored[$0].score } ?? 0

            DispatchQueue.main.async {
                self.topUsers = topDisplays
                self.monthlyPlace = currentPlace
                self.monthlyScore = currentScore
                self.isLoadingLeaderboard = false
            }
        }
    }

    private static func medal(for index: Int) -> String {
        switch index {
        case 0: return "🥇"
        case 1: return "🥈"
        case 2: return "🥉"
        default: return "⭐️"
        }
    }

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

    private func fetchLinks(for unit: UnitDisplayItem) {
        manualLink = ""
        unitLink = ""
        dbRef.child("general_urls").getData { [weak self] _, snapshot in
            self?.manualLink = (snapshot?.value as? NSDictionary)?["manual_url"] as? String ?? ""
        }
        dbRef.child("unitsLink").getData { [weak self] _, snapshot in
            guard let self = self else { return }
            self.unitLink = (snapshot?.value as? NSDictionary)?[unit.sku] as? String ?? ""
            DispatchQueue.main.async { self.showingDownload = true }
        }
    }

    private static func intFromAny(_ value: Any) -> Int? {
        if let i = value as? Int { return i }
        if let d = value as? Double { return Int(d) }
        if let s = value as? String { return Int(s) }
        return nil
    }
}
