import Foundation

final class AppState: ObservableObject {
    @Published var isAuthenticated: Bool
    
    init() {
        Self.hydrateCachedUserInformation()
        isAuthenticated = UserSession.shared.getSessionID() != nil || UserSession.shared.load() != nil
    }
    
    func markAuthenticated() {
        isAuthenticated = true
    }
    
    func logout() {
        UserSession.shared.clear()
        UserDefaults.standard.removeObject(forKey: "odooSessionID")
        SessionManager.shared.currentSessionID = nil
        isAuthenticated = false
    }

    private static func hydrateCachedUserInformation() {
        guard let savedUser = UserSession.shared.load() else { return }
        userInformation.userId = String(savedUser.partnerID)
        userInformation.email = savedUser.email
        userInformation.name = savedUser.name
        userInformation.profileImageUrl = savedUser.profileImageUrl ?? ""
        userInformation.typeUser = savedUser.typeUser
        userInformation.weight = savedUser.ownwedWeight
    }
}
