import Foundation
import FirebaseAuth

final class AppState: ObservableObject {
    @Published var isAuthenticated: Bool
    @Published var selectedTab: RootTab = .browse
    @Published var pendingBrowseURL: URL?
    /// Set before navigating to buy_product checkout; cleared after points are recorded.
    var pendingPointsDealID: String?

    init() {
        // Use locally cached session for initial state — no Firebase call needed at init time.
        // Firebase Auth may not be ready yet; logout() and markAuthenticated() keep this in sync.
        isAuthenticated = UserSession.shared.load() != nil
        Self.hydrateCachedUserInformation()
    }

    func markAuthenticated() {
        isAuthenticated = true
    }

    func logout() {
        // Remove this device's FCM token before signing out so it won't receive push notifications
        let uid = UserDefaults.standard.string(forKey: "firebaseUID") ?? ""
        AuthService.shared.removeFCMToken(firebaseUID: uid)

        try? Auth.auth().signOut()
        UserSession.shared.clear()
        UserDefaults.standard.removeObject(forKey: "firebaseUID")
        userInformation = UserValues(name: "", userId: "", email: "", zipCode: "", website: "", companyName: "", phone: "", businessType: "", about: "", profileImageUrl: "", typeUser: "", weight: 0, subscribed: false, showWalk: true)
        isAuthenticated = false
    }

    private static func hydrateCachedUserInformation() {
        let firebaseUID = UserDefaults.standard.string(forKey: "firebaseUID") ?? ""
        guard let savedUser = UserSession.shared.load() else { return }
        userInformation.userId = firebaseUID.isEmpty ? savedUser.email : firebaseUID
        userInformation.email = savedUser.email
        userInformation.name = savedUser.name
        userInformation.profileImageUrl = savedUser.profileImageUrl ?? ""
        userInformation.typeUser = savedUser.typeUser
        userInformation.weight = savedUser.ownwedWeight
    }
}
