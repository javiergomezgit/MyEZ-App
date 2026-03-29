import Foundation
import UIKit
import FirebaseDatabase
import FirebaseStorage

final class ProfileViewModel: ObservableObject {
    @Published var user: AppUser?
    @Published var isSubscribed: Bool = userInformation.subscribed
    @Published var profileImage: UIImage?
    @Published var errorMessage: String?
    @Published var showingTerms = false
    @Published var showingPrivacy = false
    @Published var currentUserWeight: Int = 0
    @Published var currentUserRank: Int = 0
    
    private lazy var dbRef: DatabaseReference = Database.database().reference()
    private let topUsersService = PreviewTopUsersService()
    
    func refresh() {
        user = UserSession.shared.load()
        isSubscribed = userInformation.subscribed
        loadCurrentWeight()
        loadRankSummary()
    }
    
    func updateSubscription(isOn: Bool) {
        userInformation.subscribed = isOn
        isSubscribed = isOn
        guard !userInformation.userId.isEmpty else { return }
        dbRef.child("users").child(userInformation.userId).updateChildValues(["subscribed": isOn])
    }
    
    func updateProfileImage(newImage: UIImage) {
        guard var user = UserSession.shared.load() else { return }
        let storageRef = Storage.storage().reference().child("users/\(user.partnerID)/profile/\(user.partnerID)-profileImage.jpg")
        guard let imageData = newImage.jpegData(compressionQuality: 0.7) else {
            errorMessage = "Couldn't convert image"
            return
        }
        // FIXME: Missing `[weak self]` capture in every nested closure here. Each closure
        // strongly captures `self` (ProfileViewModel), and the closures are passed to Firebase
        // Storage / Database callbacks that can outlive the view. This creates a retain cycle
        // that prevents the view model from being deallocated while the upload is in flight.
        // Add `[weak self] in` and guard-unwrap `self` at the start of each closure.
        storageRef.putData(imageData, metadata: nil) { _, error in
            if let error = error {
                DispatchQueue.main.async { self.errorMessage = error.localizedDescription }
                return
            }
            storageRef.downloadURL { result in
                switch result {
                case .success(let downloadURL):
                    let urlString = downloadURL.absoluteString
                    self.dbRef.child("users").child("\(user.partnerID)").child("profile_image_url").setValue(urlString) { dbError, _ in
                        if let dbError = dbError {
                            DispatchQueue.main.async { self.errorMessage = dbError.localizedDescription }
                        } else {
                            user.profileImageUrl = urlString
                            UserSession.shared.save(user: user)
                            DispatchQueue.main.async {
                                self.profileImage = newImage
                                self.user = user
                            }
                        }
                    }
                case .failure(let error):
                    DispatchQueue.main.async { self.errorMessage = error.localizedDescription }
                }
            }
        }
    }
    
    func logout(appState: AppState) {
        // Clear local data
        UserSession.shared.clear()
        UserDefaults.standard.removeObject(forKey: "savedUserSession")
        // Clear cookies
        let storage = HTTPCookieStorage.shared
        storage.cookies?.forEach { storage.deleteCookie($0) }
        // Odoo logout
        // FIXME: Hardcoded URL that differs from OdooKeys.databaseURL used everywhere else.
        // If the Odoo domain ever changes this will silently send the logout request to the
        // wrong host. Use `URL(string: "\(OdooKeys.databaseURL)/web/session/logout")` and
        // handle the optional gracefully instead of force-unwrapping.
        let odooLogoutURL = URL(string: "https://ezinflatables.odoo.com/web/session/logout")!
        var request = URLRequest(url: odooLogoutURL)
        request.httpMethod = "GET"
        URLSession.shared.dataTask(with: request) { _, _, _ in
            DispatchQueue.main.async { appState.logout() }
        }.resume()
    }
    
    func supportEmailBody() -> String {
        let name = user?.name ?? "No name"
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        return """
        Hi Javier,
        
        I need help with:
        
        ---
        User: \(name)
        App Version: \(version)
        iOS: \(UIDevice.current.systemVersion)
        Device: \(UIDevice.current.model)
        ---
        """
    }

    private func loadRankSummary() {
        topUsersService.updateAndGetTopUsersSummary { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let summary):
                DispatchQueue.main.async {
                    userInformation.weight = summary.currentUserWeight
                    self.currentUserWeight = summary.currentUserWeight
                    self.currentUserRank = summary.currentUserRank
                }
            case .failure:
                DispatchQueue.main.async {
                    self.currentUserWeight = self.user?.ownwedWeight ?? userInformation.weight
                    self.currentUserRank = 0
                }
            }
        }
    }

    private func loadCurrentWeight() {
        guard let user = UserSession.shared.load() else { return }
        dbRef.child("users").child(String(user.partnerID)).observeSingleEvent(of: .value) { [weak self] snapshot in
            guard let self = self else { return }
            let value = snapshot.value as? [String: Any]
            let weight = Self.intValue(value?["owned_weight"])
                ?? Self.intValue(value?["weightOwned"])
                ?? userInformation.weight

            DispatchQueue.main.async {
                userInformation.weight = weight
                self.currentUserWeight = weight
            }
        }
    }

    private static func intValue(_ value: Any?) -> Int? {
        if let intValue = value as? Int { return intValue }
        if let doubleValue = value as? Double { return Int(doubleValue) }
        if let stringValue = value as? String { return Int(stringValue) }
        return nil
    }
}
