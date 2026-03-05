import Foundation
import FirebaseDatabase
import UIKit

final class MyEZViewModel: ObservableObject {
    struct UnitDisplayItem: Identifiable {
        let id = UUID()
        let sku: String
        let imageName: String
    }
    
    @Published var displayUnits: [UnitDisplayItem] = []
    @Published var categoryName: String = userInformation.typeUser
    @Published var ownedUnitsText: String = "You own \(userInformation.weight) Pounds of inflatable"
    @Published var manualLink: String = ""
    @Published var unitLink: String = ""
    @Published var selectedUnit: UnitDisplayItem?
    @Published var showingDownload = false
    
    private lazy var dbRef: DatabaseReference = Database.database().reference()
    
    private let hardcodedUnits: [UnitDisplayItem] = [
        UnitDisplayItem(sku: "WS1020-IP", imageName: "WS"),
        UnitDisplayItem(sku: "SS3453", imageName: "SS"),
        UnitDisplayItem(sku: "S0234-DP", imageName: "S")
    ]
    
    func load() {
        loadUnitsFromFirebase()
        loadInfoHeader()
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
        let weight = Int(userInformation.weight)
        userInformation.typeUser = checkTypeUser(weightUnits: weight)
        categoryName = userInformation.typeUser.uppercased()
        ownedUnitsText = "You own \(userInformation.weight) Pounds of inflatable"
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
