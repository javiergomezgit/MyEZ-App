import Foundation
import FirebaseDatabase
import UIKit

final class MyEZViewModel: ObservableObject {
    struct UnitDisplayItem: Identifiable {
        let id = UUID()
        let sku: String
        let productID: String
        let imageURL: URL?
    }
    
    struct TopUserDisplay: Identifiable {
        let id = UUID()
        let place: Int
        let weightText: String
        let locationText: String
        let medal: String
    }

    @Published var displayUnits: [UnitDisplayItem] = []
    @Published var categoryName: String = userInformation.typeUser
    @Published var categoryImageName: String = userInformation.typeUser
    @Published var ownedUnitsText: String = "You own \(userInformation.weight) Pounds of inflatable"
    @Published var topUsers: [TopUserDisplay] = []
    @Published var topUsersSummaryText: String = ""
    @Published var manualLink: String = ""
    @Published var unitLink: String = ""
    @Published var selectedUnit: UnitDisplayItem?
    @Published var showingDownload = false
    
    private lazy var dbRef: DatabaseReference = Database.database().reference()
    private let topUsersService = PreviewTopUsersService()
    
    func load() {
        loadUnitsFromFirebase()
        loadInfoHeader()
        loadTopUsers()
    }

    func refreshAll() {
        loadUnitsFromFirebase()
        loadInfoHeader()
        loadTopUsers()
    }
    
    func select(unit: UnitDisplayItem) {
        selectedUnit = unit
        fetchLinks(for: unit)
    }
    
    private func loadUnitsFromFirebase() {
        guard !userInformation.userId.isEmpty else {
            displayUnits = []
            print("⚠️ MyEZ units fetch skipped: missing user ID")
            return
        }

        dbRef.child("users").child(userInformation.userId).child("units").observeSingleEvent(of: .value) { [weak self] snapshot in
            guard let self = self else { return }

            guard snapshot.exists() else {
                DispatchQueue.main.async {
                    self.displayUnits = []
                }
                print("⚠️ No units found for user \(userInformation.userId).")
                return
            }

            let childSnapshots = snapshot.children.allObjects.compactMap { $0 as? DataSnapshot }
            let units = childSnapshots.compactMap(Self.extractUnitDisplayItem(from:))

            if units.isEmpty {
                DispatchQueue.main.async {
                    self.displayUnits = []
                }
                print("⚠️ Units found but no valid SKU/product_id values were available.")
                return
            }

            DispatchQueue.main.async {
                self.displayUnits = units
            }
        } withCancel: { error in
            DispatchQueue.main.async {
                self.displayUnits = []
            }
            print("❌ Failed to fetch units from Firebase: \(error.localizedDescription)")
        }
    }
    
    private func loadInfoHeader() {
        let weight = userInformation.weight
        userInformation.typeUser = checkTypeUser(weightUnits: weight)
        let resolvedType = userInformation.typeUser.isEmpty ? "minimumweight" : userInformation.typeUser
        categoryName = resolvedType.uppercased()
        categoryImageName = resolvedType
        ownedUnitsText = "You own \(userInformation.weight) Pounds of inflatable"
    }

    private func loadTopUsers() {
        topUsersService.updateAndGetTopUsersSummary { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let summary):
                let formatter = NumberFormatter()
                formatter.numberStyle = .decimal

                let topDisplays = summary.topUsers.enumerated().map { index, entry in
                    let medal = Self.medal(for: index)
                    let formattedWeight = formatter.string(from: NSNumber(value: entry.weight)) ?? String(entry.weight)
                    let weightText = "\(formattedWeight) lbs"
                    let locationText = entry.zipCode ?? "—"
                    return TopUserDisplay(place: index + 1, weightText: weightText, locationText: locationText, medal: medal)
                }

                let weightText = formatter.string(from: NSNumber(value: summary.currentUserWeight)) ?? "\(summary.currentUserWeight)"
                let placeText = Self.ordinalString(summary.currentUserRank)
                let summaryText = "Owning \(weightText) lbs of inflatables, I'm in \(placeText) place."

                DispatchQueue.main.async {
                    self.topUsers = topDisplays
                    self.topUsersSummaryText = summaryText
                }
            case .failure:
                break
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
        dbRef.child("downloadLinks").observeSingleEvent(of: .value) { snapshot in
            let value = snapshot.value as? NSDictionary
            self.manualLink = value?["generalManual"] as? String ?? ""
        }
        dbRef.child("unitsLink").observeSingleEvent(of: .value) { snapshot in
            let value = snapshot.value as? NSDictionary
            self.unitLink = value?[unit.sku] as? String ?? ""
            DispatchQueue.main.async { self.showingDownload = true }
        }
    }

    private static func extractUnitDisplayItem(from snapshot: DataSnapshot) -> UnitDisplayItem? {
        let rawValue = snapshot.value
        print("📦 unit snapshot [\(snapshot.key)]: \(String(describing: rawValue))")

        guard let dictionary = rawValue as? [String: Any] else {
            return nil
        }

        guard let productID = firstNonEmptyValue(
            in: dictionary,
            keys: ["product_id", "productId", "productID"]
        ) else {
            return nil
        }

        let nestedUnit = dictionary["unit"] as? [String: Any]
        let nestedProduct = dictionary["product"] as? [String: Any]

        let sku = firstNonEmptyValue(
            in: dictionary,
            keys: [
                "sku",
                "SKU",
                "sku_unit",
                "skuUnit",
                "unit_sku",
                "default_code",
                "defaultCode",
                "model",
                "serial",
                "serial_number",
                "serialNumber"
            ]
        )
        ?? nestedUnit.flatMap { firstNonEmptyValue(in: $0, keys: ["sku", "default_code", "model", "serial"]) }
        ?? nestedProduct.flatMap { firstNonEmptyValue(in: $0, keys: ["sku", "default_code", "model"]) }
        ?? snapshot.key

        print("📦 product_id: \(productID)")
        print("🏷️ sku text: \(sku)")

        return UnitDisplayItem(
            sku: sku,
            productID: productID,
            imageURL: URL(string: "https://ezinflatables.odoo.com/web/image/product.product/\(productID)/image_1024")
        )
    }

    private static func stringify(_ value: Any) -> String? {
        if let stringValue = value as? String, !stringValue.isEmpty {
            return stringValue
        }

        if let numberValue = value as? NSNumber {
            return numberValue.stringValue
        }

        return nil
    }

    private static func firstNonEmptyValue(in dictionary: [String: Any], keys: [String]) -> String? {
        for key in keys {
            if let value = dictionary[key].flatMap(stringify), !value.isEmpty {
                return value
            }
        }
        return nil
    }
}
