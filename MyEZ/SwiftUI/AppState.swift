import Foundation

final class AppState: ObservableObject {
    @Published var isAuthenticated: Bool
    
    init() {
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
}
