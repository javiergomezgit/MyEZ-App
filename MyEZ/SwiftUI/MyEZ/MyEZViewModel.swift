import Foundation
import FirebaseDatabase
import UIKit

final class MyEZViewModel: ObservableObject {
    struct UnitDisplayItem: Identifiable {
        let id = UUID()
        let sku: String
        let imageName: String
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
    
    private let hardcodedUnits: [UnitDisplayItem] = [
        UnitDisplayItem(sku: "WS1020-IP", imageName: "WS"),
        UnitDisplayItem(sku: "SS3453", imageName: "SS"),
        UnitDisplayItem(sku: "S0234-DP", imageName: "S")
    ]
    
    func load() {
        loadUnitsFromFirebase()
        loadInfoHeader()
        loadTopUsers()
    }

    func refreshAll() {
        loadInfoHeader()
        loadTopUsers()
    }
    
    func refreshUnits() {
        loadUnitsFromFirebase()
    }
    
    func select(unit: UnitDisplayItem) {
        selectedUnit = unit
        fetchLinks(for: unit)
    }
    
    private func loadUnitsFromFirebase() {
        displayUnits = hardcodedUnits
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
}
