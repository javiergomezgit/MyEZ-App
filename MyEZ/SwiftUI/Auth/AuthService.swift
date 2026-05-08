import Foundation
import UIKit
import Firebase
import FirebaseAuth

final class AuthService {
    static let shared = AuthService()
    private init() {}
    
    private lazy var dbRef: DatabaseReference = Database.database().reference()
    private let zipCodeProvider = ZipCodeProvider()
    
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
    
    func signIn(email: String, password: String, completion: @escaping (Result<OdooUser, AuthError>) -> Void) {
        let database = OdooKeys.databaseName
        let urlString = OdooKeys.databaseURL
        guard let url = URL(string: "\(urlString)/web/session/authenticate") else {
            completion(.failure(.message("Bad URL")))
            return
        }
        
        let params: [String: Any] = [
            "db": database,
            "login": email,
            "password": password
        ]
        
        let body: [String: Any] = [
            "jsonrpc": "2.0",
            "method": "call",
            "params": params,
            "id": Int(Date().timeIntervalSince1970)
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            completion(.failure(.parsing))
            return
        }
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                completion(.failure(.network(error)))
                return
            }
            guard let data = data else {
                completion(.failure(.invalidResponse))
                return
            }
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    if let errorDict = json["error"] as? [String: Any] {
                        let message = errorDict["message"] as? String ?? "Unknown Odoo Error"
                        let dataDict = errorDict["data"] as? [String: Any]
                        let detailedMsg = dataDict?["message"] as? String ?? message
                        completion(.failure(.message(detailedMsg)))
                        return
                    }
                    if let result = json["result"] as? [String: Any] {
                        var sessionID = result["session_id"] as? String ?? ""
                        if sessionID.isEmpty,
                           let httpResponse = response as? HTTPURLResponse,
                           let fields = httpResponse.allHeaderFields as? [String: String],
                           let url = httpResponse.url {
                            let cookies = HTTPCookie.cookies(withResponseHeaderFields: fields, for: url)
                            if let cookie = cookies.first(where: { $0.name == "session_id" }) {
                                sessionID = cookie.value
                            }
                        }
                        if !sessionID.isEmpty {
                            SessionManager.shared.currentSessionID = sessionID
                            UserDefaults.standard.set(sessionID, forKey: "odooSessionID")
                            UserDefaults.standard.set(sessionID, forKey: "sessionID")
                        }
                        let user = OdooUser(
                            uid: result["uid"] as? Int ?? 0,
                            name: result["name"] as? String ?? "Unknown",
                            username: result["username"] as? String ?? email,
                            partnerID: result["partner_id"] as? Int ?? 0,
                            sessionID: sessionID,
                            companyID: result["company_id"] as? Int ?? 0
                        )
                        self?.fetchPartnerOwnedWeight(signedUser: user, password: password) { result in
                            switch result {
                            case .success(let ownedWeight):
                                self?.downloadDataFirebase(signedUser: user, email: email, password: password, ownedWeight: ownedWeight) {
                                    completion(.success(user))
                                }
                            case .failure(let error):
                                completion(.failure(error))
                            }
                        }
                    } else {
                        completion(.failure(.parsing))
                    }
                }
            } catch {
                completion(.failure(.parsing))
            }
        }.resume()
    }
    
    func sendPasswordReset(email: String, completion: @escaping (Result<Void, AuthError>) -> Void) {
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            if let error = error {
                completion(.failure(.network(error)))
            } else {
                completion(.success(()))
            }
        }
    }
    
    private func downloadDataFirebase(signedUser: OdooUser, email: String, password: String, ownedWeight: Int, completion: @escaping () -> Void) {
        let userId = String(signedUser.partnerID)
        dbRef.child("users").child(userId).observeSingleEvent(of: .value, with: { [weak self] snapshot in
            guard let self = self else { return }

            if !snapshot.exists() {
                let timestamp = Date().timeIntervalSince1970
                let firebaseData: [String: Any] = [
                    "uid": signedUser.uid,
                    "partner_id": signedUser.partnerID,
                    "name": signedUser.name,
                    "email": email,
                    "zipCode": "00000",
                    "completedSigningUp": false,
                    // FIXME: Key is "typeuser" (all lowercase) here but `applyFirebaseSnapshot`
                    // reads "typeUser" first and falls back to "typeuser". Inconsistent casing
                    // means a freshly-created user will never match the primary key lookup.
                    // Pick one canonical name (prefer "typeUser" to match the Swift property).
                    "typeuser": "minimumweight",
                    "owned_weight": ownedWeight,
                    "units": ["SKU": 1],
                    "company_id": signedUser.companyID,
                    "company_name": "",
                    "createdAt": timestamp,
                    "phone": "",
                    "fcmToken": "",
                    "profile_image_url": "https://firebasestorage.googleapis.com/v0/b/myezfirebase.appspot.com/o/myez-default-profile-image.png?alt=media&token=220f60c3-4cb2-480f-a365-f7852b229857",
                    "subscribed": false
                ]

                self.dbRef.child("users").child(userId).setValue(firebaseData) { error, _ in
                    if let error = error {
                        print("❌ Firebase Create Error: \(error.localizedDescription)")
                    } else {
                        print("✅ Firebase User Created on Sign-In: \(userId)")
                    }
                    self.applyFirebaseSnapshot(userId: userId, value: firebaseData as NSDictionary, email: email, password: password, signedUser: signedUser)
                    completion()
                }
                return
            }

            self.dbRef.child("users").child(userId).updateChildValues(["owned_weight": ownedWeight]) { error, _ in
                if let error = error {
                    print("❌ Firebase Weight Update Error: \(error.localizedDescription)")
                }

                var value = snapshot.value as? [String: Any] ?? [:]
                value["owned_weight"] = ownedWeight
                self.applyFirebaseSnapshot(userId: userId, value: value as NSDictionary, email: email, password: password, signedUser: signedUser)
                completion()
            }
        }) { error in
            print(error.localizedDescription)
            completion()
        }
    }

    private func fetchPartnerOwnedWeight(signedUser: OdooUser, password: String, completion: @escaping (Result<Int, AuthError>) -> Void) {
        let urlString = "\(OdooKeys.databaseURL)/jsonrpc"
        guard let url = URL(string: urlString) else {
            completion(.failure(.message("Bad URL")))
            return
        }

        let params: [String: Any] = [
            "service": "object",
            "method": "execute_kw",
            "args": [
                OdooKeys.databaseName,
                signedUser.uid,
                password,
                "res.partner",
                "read",
                [[signedUser.partnerID]],
                ["fields": ["x_studio_owned_weight"]]
            ]
        ]
        let body: [String: Any] = [
            "jsonrpc": "2.0",
            "method": "call",
            "params": params,
            "id": Int(Date().timeIntervalSince1970)
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            completion(.failure(.parsing))
            return
        }

        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                completion(.failure(.network(error)))
                return
            }

            guard let data = data else {
                completion(.failure(.invalidResponse))
                return
            }

            do {
                guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    completion(.failure(.parsing))
                    return
                }

                if let errorDict = json["error"] as? [String: Any] {
                    let message = errorDict["message"] as? String ?? "Failed to fetch owned weight"
                    completion(.failure(.message(message)))
                    return
                }

                guard
                    let result = json["result"] as? [[String: Any]],
                    let firstRecord = result.first
                else {
                    completion(.failure(.invalidResponse))
                    return
                }

                let ownedWeight = Self.intValue(firstRecord["x_studio_owned_weight"]) ?? 0
                completion(.success(ownedWeight))
            } catch {
                completion(.failure(.parsing))
            }
        }.resume()
    }

    private func applyFirebaseSnapshot(userId: String, value: NSDictionary?, email: String, password: String, signedUser: OdooUser) {
        userInformation.userId = userId
        userInformation.website = value?["website"] as? String ?? ""
        userInformation.companyName = value?["company_name"] as? String ?? ""
        userInformation.zipCode = value?["zipCode"] as? String ?? ""
        userInformation.phone = value?["phone"] as? String ?? ""
        userInformation.typeUser = value?["typeUser"] as? String ?? value?["typeuser"] as? String ?? ""
        userInformation.weight = value?["owned_weight"] as? Int ?? value?["weightOwned"] as? Int ?? 0
        userInformation.subscribed = value?["subscribed"] as? Bool ?? false
        userInformation.profileImageUrl = value?["profile_image_url"] as? String ?? "https://firebasestorage.googleapis.com/v0/b/myezfirebase.appspot.com/o/myez-default-profile-image.png?alt=media&token=220f60c3-4cb2-480f-a365-f7852b229857"

        if let passwordData = password.data(using: .utf8) {
            KeychainHelper.shared.save(passwordData, service: "com.myez.app", account: email)
        }
        saveLocally(signedOdooUser: signedUser, email: email)
    }
    
    private func saveLocally(signedOdooUser: OdooUser, email: String) {
        let localUser = AppUser(
            uid: signedOdooUser.uid,
            partnerID: signedOdooUser.partnerID,
            name: signedOdooUser.name,
            email: email,
            typeUser: userInformation.typeUser,
            // FIXME: Using the misspelled `ownwedWeight` label — consequence of the typo in
            // `AppUser`. When the typo is fixed in AppUser, update this label to `ownedWeight`.
            ownwedWeight: userInformation.weight,
            companyID: 25,
            completedSigningUp: false,
            profileImageUrl: userInformation.profileImageUrl
        )
        UserSession.shared.save(user: localUser)
    }

    private static func intValue(_ value: Any?) -> Int? {
        if let intValue = value as? Int { return intValue }
        if let doubleValue = value as? Double { return Int(doubleValue) }
        if let stringValue = value as? String { return Int(stringValue) }
        return nil
    }
    
    func registerUser(name: String, email: String, password: String, completion: @escaping (Result<Void, AuthError>) -> Void) {
        zipCodeProvider.requestZipCode { [weak self] zip in
            let safeZip = (zip?.isEmpty == false) ? zip! : "00000"
            self?.registerUserInOdoo(name: name, email: email, password: password, zipCode: safeZip, completion: completion)
        }
    }
    
    private func registerUserInOdoo(name: String, email: String, password: String, zipCode: String, completion: @escaping (Result<Void, AuthError>) -> Void) {
        let urlString = "\(OdooKeys.databaseURL)/jsonrpc"
        let database = OdooKeys.databaseName
        let botKey = OdooKeys.apiKey
        
        guard let url = URL(string: urlString) else {
            completion(.failure(.message("Bad URL")))
            return
        }
        
        let newUserOverrides: [String: Any] = [
            "name": name,
            "login": email,
            "email": email,
            "password": password,
            "zip": zipCode,
            "active": true,
            "company_id": 25,
            "company_ids": [[6, 0, [25]]],
            "group_ids": [[6, 0, [10]]]
        ]
        
        let params: [String: Any] = [
            "service": "object",
            "method": "execute_kw",
            "args": [database, 2, botKey, "res.users", "create", [newUserOverrides]]
        ]
        
        let body: [String: Any] = ["jsonrpc": "2.0", "method": "call", "params": params, "id": 1]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            guard let self = self else { return }
            if let error = error {
                completion(.failure(.network(error)))
                return
            }
            if let data = data, let raw = String(data: data, encoding: .utf8) {
                print("🔴 Odoo raw response: \(raw)") //For debugging
            }
            guard let data = data else {
                completion(.failure(.invalidResponse))
                return
            }
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    if let errorDict = json["error"] as? [String: Any] {
                        let msg = errorDict["message"] as? String ?? "Error"
                        completion(.failure(.message(msg)))
                        return
                    }
                    var newUID: Int?
                    if let id = json["result"] as? Int {
                        newUID = id
                    } else if let ids = json["result"] as? [Int], let first = ids.first {
                        newUID = first
                    }
                    if let validUID = newUID {
                        self.fetchPartnerID(uid: validUID, botLogin: "admin", botKey: botKey, name: name, email: email, password: password, zipCode: zipCode, completion: completion)
                    } else {
                        completion(.failure(.message("Could not parse UID")))
                    }
                }
            } catch {
                completion(.failure(.parsing))
            }
        }.resume()
    }
    
    private func fetchPartnerID(uid: Int, botLogin: String, botKey: String, name: String, email: String, password: String, zipCode: String, completion: @escaping (Result<Void, AuthError>) -> Void) {
        let urlString = "\(OdooKeys.databaseURL)/jsonrpc"
        let database = OdooKeys.databaseName
        let params: [String: Any] = [
            "service": "object",
            "method": "execute_kw",
            "args": [
                database, 2, botKey,
                "res.users", "read",
                [[uid], ["partner_id"]]
            ]
        ]
        let body: [String: Any] = ["jsonrpc": "2.0", "method": "call", "params": params, "id": 2]
        guard let url = URL(string: urlString) else {
            completion(.failure(.message("Bad URL")))
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            // FIXME: The guard checks `data` before checking `error`. URLSession can deliver
            // a non-nil error alongside non-nil data in some edge cases. More importantly, the
            // guard merges two distinct failure conditions (nil self vs nil data) into one
            // `.invalidResponse`, making it impossible to distinguish a retain-cycle release
            // from a genuine empty-body response. Check `error` first, then guard `data`.
            guard let self = self, let data = data else {
                completion(.failure(.invalidResponse))
                return
            }
            if let error = error {
                completion(.failure(.network(error)))
                return
            }
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let result = json["result"] as? [[String: Any]],
                   let firstRecord = result.first {
                    var partnerID: Int?
                    if let partnerArray = firstRecord["partner_id"] as? [Any],
                       let id = partnerArray.first as? Int {
                        partnerID = id
                    }
                    if let finalPartnerID = partnerID {
                        self.didFinishRegistration(partnerID: finalPartnerID, odooUID: uid, email: email, name: name, password: password, zipCode: zipCode, completion: completion)
                    } else {
                        completion(.failure(.message("Could not parse partner_id")))
                    }
                } else {
                    completion(.failure(.invalidResponse))
                }
            } catch {
                completion(.failure(.parsing))
            }
        }.resume()
    }
    
    private func didFinishRegistration(partnerID: Int, odooUID: Int, email: String, name: String, password: String, zipCode: String, completion: @escaping (Result<Void, AuthError>) -> Void) {
        uploadProfileImage(partnerID: partnerID) { [weak self] imageURL in
            guard let self = self else { return }
            let finalImageURL = imageURL ?? "https://firebasestorage.googleapis.com/v0/b/myezfirebase.appspot.com/o/myez-default-profile-image.png?alt=media&token=220f60c3-4cb2-480f-a365-f7852b229857"
            let timestamp = Date().timeIntervalSince1970
            let firebaseData: [String: Any] = [
                "uid": odooUID,
                "partner_id": partnerID,
                "name": name,
                "email": email,
                "zipCode": zipCode,
                "completedSigningUp": false,
                // FIXME: Same "typeuser" / "typeUser" inconsistency as in `downloadDataFirebase`.
                "typeuser": "minimumweight",
                "owned_weight": 1,
                "units": ["SKU": 1],
                "company_id": 25,
                "company_name": "",
                "createdAt": timestamp,
                "phone": "",
                "fcmToken": "",
                "profile_image_url": finalImageURL,
                "subscribed": false
            ]
            
            self.dbRef.child("users").child("\(partnerID)").setValue(firebaseData) { error, _ in
                if let error = error {
                    completion(.failure(.network(error)))
                    return
                }
                let localUser = AppUser(
                    uid: odooUID,
                    partnerID: partnerID,
                    name: name,
                    email: email,
                    typeUser: "minimumweight",
                    // FIXME: Using the misspelled `ownwedWeight` label — same issue as in
                    // `saveLocally`. Update when the typo in AppUser is corrected.
                    ownwedWeight: 0,
                    companyID: 25,
                    completedSigningUp: false,
                    profileImageUrl: finalImageURL
                )
                UserSession.shared.save(user: localUser)
                if let passwordData = password.data(using: .utf8) {
                    KeychainHelper.shared.save(passwordData, service: "com.myez.app", account: email)
                }
                self.loginAndSaveCookie(password: password, login: email) {
                    completion(.success(()))
                }
            }
        }
    }
    
    private func uploadProfileImage(partnerID: Int, completion: @escaping (String?) -> Void) {
        let storageRef = Storage.storage().reference().child("users/\(partnerID)/profile/\(partnerID)_profileImage.jpg")
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
    
    private func loginAndSaveCookie(password: String, login: String, completion: @escaping () -> Void) {
        let url = URL(string: "\(OdooKeys.databaseURL)/web/session/authenticate")!
        let params: [String: Any] = [
            "db": OdooKeys.databaseName,
            "login": login,
            "password": password
        ]
        let body: [String: Any] = [
            "jsonrpc": "2.0",
            "method": "call",
            "params": params,
            "id": Int(Date().timeIntervalSince1970)
        ]
        var request = URLRequest(url: url)
        let userAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148"
        request.addValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, _ in
            if let httpResponse = response as? HTTPURLResponse,
               let fields = httpResponse.allHeaderFields as? [String: String],
               let url = response?.url {
                let cookies = HTTPCookie.cookies(withResponseHeaderFields: fields, for: url)
                for cookie in cookies where cookie.name == "session_id" {
                    SessionManager.shared.currentSessionID = cookie.value
                    UserDefaults.standard.set(cookie.value, forKey: "odooSessionID")
                }
            }
            UserDefaults.standard.synchronize()
            DispatchQueue.main.async { completion() }
        }.resume()
    }
}
