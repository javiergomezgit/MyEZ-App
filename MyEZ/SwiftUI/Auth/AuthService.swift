import Foundation
import UIKit
import Firebase
import FirebaseAuth

final class AuthService {
    static let shared = AuthService()
    private init() {}

    private lazy var dbRef: DatabaseReference = Database.database().reference()
    private let zipCodeProvider = ZipCodeProvider()

    private static let defaultProfileImageURL = "https://firebasestorage.googleapis.com/v0/b/myezfirebase.appspot.com/o/myez-default-profile-image.png?alt=media&token=220f60c3-4cb2-480f-a365-f7852b229857"

    enum AuthError: LocalizedError {
        case message(String)
        case network(Error)
        case invalidResponse
        case parsing
        case unknown

        var errorDescription: String? {
            switch self {
            case .message(let msg): return msg
            case .network(let err): return "Network error: \(err.localizedDescription)"
            case .invalidResponse: return "Invalid response"
            case .parsing: return "Parsing error"
            case .unknown: return "Unknown error"
            }
        }
    }

    // MARK: - Sign In

    func signIn(email: String, password: String, completion: @escaping (Result<OdooUser, AuthError>) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            if let error = error {
                completion(.failure(.message(error.localizedDescription)))
                return
            }
            guard let firebaseUser = result?.user else {
                completion(.failure(.unknown))
                return
            }
            let authName = firebaseUser.displayName ?? ""
            self?.loadOrCreateFirebaseProfile(firebaseUID: firebaseUser.uid, email: email, name: authName) {
                let placeholder = OdooUser(uid: 0, name: authName, username: email, partnerID: 0, sessionID: "", companyID: 0)
                completion(.success(placeholder))
            }
        }
    }

    // MARK: - Password Reset

    func sendPasswordReset(email: String, completion: @escaping (Result<Void, AuthError>) -> Void) {
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            if let error = error {
                completion(.failure(.network(error)))
            } else {
                completion(.success(()))
            }
        }
    }

    // MARK: - Register

    func registerUser(name: String, email: String, password: String, completion: @escaping (Result<Void, AuthError>) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            if let error = error {
                completion(.failure(.message(error.localizedDescription)))
                return
            }
            guard let firebaseUser = result?.user else {
                completion(.failure(.unknown))
                return
            }
            let changeRequest = firebaseUser.createProfileChangeRequest()
            changeRequest.displayName = name
            changeRequest.commitChanges(completion: nil)

            self?.zipCodeProvider.requestZipCode { zip in
                let safeZip = (zip?.isEmpty == false) ? zip! : "00000"
                self?.createFirebaseProfile(firebaseUID: firebaseUser.uid, name: name, email: email, zipCode: safeZip) { imageURL in
                    self?.saveLocally(firebaseUID: firebaseUser.uid, name: name, email: email, profileImageURL: imageURL)
                    completion(.success(()))
                }
            }
        }
    }

    // MARK: - FCM Token (multi-device)

    /// A stable key for this device. Stored in UserDefaults so it survives
    /// app restarts but is unique per device/install.
    static var deviceKey: String {
        if let existing = UserDefaults.standard.string(forKey: "deviceKey") { return existing }
        let new = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        UserDefaults.standard.set(new, forKey: "deviceKey")
        return new
    }

    /// Adds or updates this device's FCM token under users/{uid}/fcmTokens/{deviceKey}.
    func updateFCMToken(firebaseUID: String, token: String) {
        guard !firebaseUID.isEmpty, !token.isEmpty else { return }
        dbRef.child("users").child(firebaseUID).child("fcmTokens").child(Self.deviceKey).setValue(token) { error, _ in
            if let error = error {
                print("❌ FCM token save failed: \(error.localizedDescription)")
            } else {
                print("✅ FCM token saved for device \(Self.deviceKey)")
            }
        }
    }

    /// Removes this device's FCM token on sign-out so it won't receive push notifications.
    func removeFCMToken(firebaseUID: String) {
        guard !firebaseUID.isEmpty else { return }
        dbRef.child("users").child(firebaseUID).child("fcmTokens").child(Self.deviceKey).removeValue { error, _ in
            if let error = error {
                print("❌ FCM token removal failed: \(error.localizedDescription)")
            } else {
                print("✅ FCM token removed for device \(Self.deviceKey)")
            }
        }
    }

    // MARK: - Firebase Profile Helpers

    private func loadOrCreateFirebaseProfile(firebaseUID: String, email: String, name: String, completion: @escaping () -> Void) {
        dbRef.child("users").child(firebaseUID).observeSingleEvent(of: .value, with: { [weak self] snapshot in
            guard let self = self else { completion(); return }

            if snapshot.exists(), let value = snapshot.value as? [String: Any] {
                // Update activeAt every time the user connects
                self.dbRef.child("users").child(firebaseUID).child("activeAt").setValue(Int(Date().timeIntervalSince1970))
                self.applySnapshot(firebaseUID: firebaseUID, email: email, value: value)
                completion()
            } else {
                // No DB record — resolve name and fetch zip before creating
                let resolvedName = name.isEmpty ? (email.components(separatedBy: "@").first ?? "") : name
                self.zipCodeProvider.requestZipCode { zip in
                    let safeZip = (zip?.isEmpty == false) ? zip! : "00000"
                    self.createFirebaseProfile(firebaseUID: firebaseUID, name: resolvedName, email: email, zipCode: safeZip) { imageURL in
                        self.saveLocally(firebaseUID: firebaseUID, name: resolvedName, email: email, profileImageURL: imageURL)
                        completion()
                    }
                }
            }
        }) { error in
            print("❌ Firebase load error: \(error.localizedDescription)")
            completion()
        }
    }

    private func createFirebaseProfile(firebaseUID: String, name: String, email: String, zipCode: String, completion: @escaping (String) -> Void) {
        uploadProfileImage(firebaseUID: firebaseUID) { [weak self] imageURL in
            guard let self = self else { completion(AuthService.defaultProfileImageURL); return }
            let finalImageURL = imageURL ?? AuthService.defaultProfileImageURL
            let now = Int(Date().timeIntervalSince1970)
            let fcmToken = AppDelegate.deviceIDToken
            var fcmTokens: [String: String] = [:]
            if !fcmToken.isEmpty { fcmTokens[AuthService.deviceKey] = fcmToken }
            let data: [String: Any] = [
                "name": name,
                "email": email,
                "signedIn": "myez_app",
                "zipCode": zipCode,
                "activeAt": now,
                "typeUser": "minimumweight",
                "owned_weight": 0,
                "units": ["SKU": 1],
                "company_name": "",
                "createdAt": now,
                "phone": "",
                "fcmTokens": fcmTokens,
                "profile_image_url": finalImageURL,
                "subscribed": false
            ]
            self.dbRef.child("users").child(firebaseUID).setValue(data) { error, _ in
                if let error = error {
                    print("❌ Firebase profile create error: \(error.localizedDescription)")
                } else {
                    print("✅ Firebase profile created: \(firebaseUID)")
                }
                completion(finalImageURL)
            }
        }
    }

    private func applySnapshot(firebaseUID: String, email: String, value: [String: Any]) {
        let name = value["name"] as? String ?? ""
        let profileImageURL = value["profile_image_url"] as? String ?? AuthService.defaultProfileImageURL

        userInformation.userId = firebaseUID
        userInformation.name = name
        userInformation.email = email
        userInformation.website = value["website"] as? String ?? ""
        userInformation.companyName = value["company_name"] as? String ?? ""
        userInformation.zipCode = value["zipCode"] as? String ?? ""
        userInformation.phone = value["phone"] as? String ?? ""
        userInformation.typeUser = value["typeUser"] as? String ?? value["typeuser"] as? String ?? "minimumweight"
        userInformation.weight = value["owned_weight"] as? Int ?? 0
        userInformation.subscribed = value["subscribed"] as? Bool ?? false
        userInformation.profileImageUrl = profileImageURL

        saveLocally(firebaseUID: firebaseUID, name: name, email: email, profileImageURL: profileImageURL)
    }

    private func saveLocally(firebaseUID: String, name: String, email: String, profileImageURL: String) {
        UserDefaults.standard.set(firebaseUID, forKey: "firebaseUID")
        userInformation.userId = firebaseUID
        userInformation.name = name
        userInformation.email = email
        if userInformation.profileImageUrl.isEmpty {
            userInformation.profileImageUrl = profileImageURL
        }

        let localUser = AppUser(
            uid: 0,
            partnerID: 0,
            name: name,
            email: email,
            typeUser: userInformation.typeUser.isEmpty ? "minimumweight" : userInformation.typeUser,
            ownwedWeight: userInformation.weight,
            companyID: 0,
            completedSigningUp: false,
            profileImageUrl: profileImageURL
        )
        UserSession.shared.save(user: localUser)
    }

    // MARK: - Profile Image Upload

    private func uploadProfileImage(firebaseUID: String, completion: @escaping (String?) -> Void) {
        let storageRef = Storage.storage().reference().child("users/\(firebaseUID)/profile/\(firebaseUID)_profileImage.jpg")
        guard let defaultImage = UIImage(named: "defaultProfile"),
              let imageData = defaultImage.jpegData(compressionQuality: 0.7) else {
            completion(nil)
            return
        }
        storageRef.putData(imageData, metadata: nil) { _, error in
            if let error = error {
                print("Storage error: \(error.localizedDescription)")
                completion(nil)
                return
            }
            storageRef.downloadURL { url, _ in
                completion(url?.absoluteString)
            }
        }
    }
}
