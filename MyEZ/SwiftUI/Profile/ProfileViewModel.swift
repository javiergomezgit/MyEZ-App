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

    private var firebaseUID: String {
        UserDefaults.standard.string(forKey: "firebaseUID") ?? ""
    }

    func refresh() {
        user = UserSession.shared.load()
        isSubscribed = userInformation.subscribed
        loadSubscriptionState()
        loadCurrentWeight()
        loadMonthlyPlace()
    }

    func updateSubscription(isOn: Bool) {
        userInformation.subscribed = isOn
        isSubscribed = isOn
        guard !firebaseUID.isEmpty else { return }
        dbRef.child("users").child(firebaseUID).updateChildValues(["subscribed": isOn])
    }

    func updateProfile(name: String, phone: String, companyName: String, zipCode: String, onSuccess: (() -> Void)? = nil) {
        guard var user = UserSession.shared.load(), !firebaseUID.isEmpty else { return }

        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPhone = Self.normalizedPhoneNumber(from: phone)
        let trimmedCompany = companyName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedZip = zipCode.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedName = trimmedName.isEmpty ? user.name : trimmedName

        let payload: [String: Any] = [
            "name": resolvedName,
            "phone": trimmedPhone,
            "company_name": trimmedCompany,
            "zipCode": trimmedZip
        ]

        dbRef.child("users").child(firebaseUID).updateChildValues(payload) { [weak self] error, _ in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }
                userInformation.name = resolvedName
                userInformation.phone = trimmedPhone
                userInformation.companyName = trimmedCompany
                userInformation.zipCode = trimmedZip

                user = AppUser(
                    uid: user.uid,
                    partnerID: user.partnerID,
                    name: resolvedName,
                    email: user.email,
                    typeUser: user.typeUser,
                    ownwedWeight: user.ownwedWeight,
                    companyID: user.companyID,
                    completedSigningUp: user.completedSigningUp,
                    profileImageUrl: user.profileImageUrl
                )
                UserSession.shared.save(user: user)
                self.user = user
                onSuccess?()
            }
        }
    }

    func updateProfileImage(newImage: UIImage) {
        guard var user = UserSession.shared.load(), !firebaseUID.isEmpty else { return }
        let uid = firebaseUID
        let storageRef = Storage.storage().reference().child("users/\(uid)/profile/\(uid)-profileImage.jpg")
        guard let imageData = newImage.jpegData(compressionQuality: 0.7) else {
            errorMessage = "Couldn't convert image"
            return
        }
        storageRef.putData(imageData, metadata: nil) { [weak self] _, error in
            guard let self = self else { return }
            if let error = error {
                DispatchQueue.main.async { self.errorMessage = error.localizedDescription }
                return
            }
            storageRef.downloadURL { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let downloadURL):
                    let urlString = downloadURL.absoluteString
                    self.dbRef.child("users").child(uid).child("profile_image_url").setValue(urlString) { [weak self] dbError, _ in
                        guard let self = self else { return }
                        if let dbError = dbError {
                            DispatchQueue.main.async { self.errorMessage = dbError.localizedDescription }
                        } else {
                            user.profileImageUrl = urlString
                            UserSession.shared.save(user: user)
                            userInformation.profileImageUrl = urlString
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
        appState.logout()
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

    private func loadMonthlyPlace() {
        guard !firebaseUID.isEmpty else { return }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        let monthKey = formatter.string(from: Date())

        dbRef.child("leaderboards").child(monthKey).observeSingleEvent(of: .value) { [weak self] snapshot in
            guard let self = self else { return }
            guard let entries = snapshot.value as? [String: Any] else {
                DispatchQueue.main.async { self.currentUserRank = 0 }
                return
            }

            let scores: [(uid: String, score: Int)] = entries.compactMap { uid, value in
                guard let dict = value as? [String: Any],
                      let score = Self.intValue(dict["score"]) else { return nil }
                return (uid, score)
            }.sorted { $0.score > $1.score }

            let place = (scores.firstIndex { $0.uid == self.firebaseUID } ?? -1) + 1

            DispatchQueue.main.async {
                self.currentUserRank = place > 0 ? place : 0
            }
        }
    }

    private func loadCurrentWeight() {
        guard !firebaseUID.isEmpty else { return }
        dbRef.child("users").child(firebaseUID).observeSingleEvent(of: .value) { [weak self] snapshot in
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

    private func loadSubscriptionState() {
        guard !firebaseUID.isEmpty else { return }
        dbRef.child("users").child(firebaseUID).observeSingleEvent(of: .value) { [weak self] snapshot in
            guard let self = self else { return }
            let value = snapshot.value as? [String: Any]
            let subscribed = value?["subscribed"] as? Bool ?? false

            DispatchQueue.main.async {
                userInformation.subscribed = subscribed
                self.isSubscribed = subscribed
            }
        }
    }

    private static func intValue(_ value: Any?) -> Int? {
        if let intValue = value as? Int { return intValue }
        if let doubleValue = value as? Double { return Int(doubleValue) }
        if let stringValue = value as? String { return Int(stringValue) }
        return nil
    }

    private static func normalizedPhoneNumber(from value: String) -> String {
        value.unicodeScalars
            .filter { CharacterSet.decimalDigits.contains($0) }
            .map(String.init)
            .joined()
    }
}
