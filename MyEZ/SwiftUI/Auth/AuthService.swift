import Foundation
import UIKit
import Firebase
import FirebaseAuth

final class AuthService {
    static let shared = AuthService()
    private init() {}
    
    private lazy var dbRef: DatabaseReference = Database.database().reference()
    
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
                        self?.downloadDataFirebase(signedUser: user, email: email, password: password) {
                            completion(.success(user))
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
    
    private func downloadDataFirebase(signedUser: OdooUser, email: String, password: String, completion: @escaping () -> Void) {
        dbRef.child("users").child(String(signedUser.partnerID)).observeSingleEvent(of: .value, with: { snapshot in
            let value = snapshot.value as? NSDictionary
            userInformation.userId = String(signedUser.partnerID)
            userInformation.website = value?["website"] as? String ?? ""
            userInformation.companyName = value?["companyName"] as? String ?? ""
            userInformation.zipCode = value?["zipCode"] as? String ?? ""
            userInformation.phone = value?["phone"] as? String ?? ""
            userInformation.typeUser = value?["typeUser"] as? String ?? ""
            userInformation.weight = value?["owned_weight"] as? Int ?? 0
            userInformation.subscribed = value?["subscribed"] as? Bool ?? false
            userInformation.profileImageUrl = value?["profile_image_url"] as? String ?? "https://firebasestorage.googleapis.com/v0/b/myezfirebase.appspot.com/o/myez-default-profile-image.png?alt=media&token=220f60c3-4cb2-480f-a365-f7852b229857"
            
            if let passwordData = password.data(using: .utf8) {
                KeychainHelper.shared.save(passwordData, service: "com.myez.app", account: email)
            }
            self.saveLocally(signedOdooUser: signedUser, email: email)
            completion()
        }) { error in
            print(error.localizedDescription)
            completion()
        }
    }
    
    private func saveLocally(signedOdooUser: OdooUser, email: String) {
        let localUser = AppUser(
            uid: signedOdooUser.uid,
            partnerID: signedOdooUser.partnerID,
            name: signedOdooUser.name,
            email: email,
            typeUser: userInformation.typeUser,
            ownwedWeight: userInformation.weight,
            companyID: 25,
            completedSigningUp: false,
            profileImageUrl: userInformation.profileImageUrl
        )
        UserSession.shared.save(user: localUser)
    }
    
    func registerUser(name: String, email: String, password: String, completion: @escaping (Result<Void, AuthError>) -> Void) {
        registerUserInOdoo(name: name, email: email, password: password, completion: completion)
    }
    
    private func registerUserInOdoo(name: String, email: String, password: String, completion: @escaping (Result<Void, AuthError>) -> Void) {
        let urlString = "\(OdooKeys.databaseURL)/jsonrpc"
        let database = OdooKeys.databaseName
        let botKey = OdooKeys.apiKey
        let templateID = 13
        
        guard let url = URL(string: urlString) else {
            completion(.failure(.message("Bad URL")))
            return
        }
        
        let newUserOverrides: [String: Any] = [
            "name": name,
            "login": email,
            "password": password,
            "active": true,
            "company_id": 25,
            "company_ids": [[6, 0, [25]]]
        ]
        
        let params: [String: Any] = [
            "service": "object",
            "method": "execute_kw",
            "args": [database, 2, botKey, "res.users", "copy", [templateID, newUserOverrides]]
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
                        self.fetchPartnerID(uid: validUID, botLogin: "admin", botKey: botKey, name: name, email: email, password: password, completion: completion)
                    } else {
                        completion(.failure(.message("Could not parse UID")))
                    }
                }
            } catch {
                completion(.failure(.parsing))
            }
        }.resume()
    }
    
    private func fetchPartnerID(uid: Int, botLogin: String, botKey: String, name: String, email: String, password: String, completion: @escaping (Result<Void, AuthError>) -> Void) {
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
                        self.didFinishRegistration(partnerID: finalPartnerID, odooUID: uid, email: email, name: name, password: password, completion: completion)
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
    
    private func didFinishRegistration(partnerID: Int, odooUID: Int, email: String, name: String, password: String, completion: @escaping (Result<Void, AuthError>) -> Void) {
        uploadProfileImage(partnerID: partnerID) { [weak self] imageURL in
            guard let self = self else { return }
            let finalImageURL = imageURL ?? "https://firebasestorage.googleapis.com/v0/b/myezfirebase.appspot.com/o/myez-default-profile-image.png?alt=media&token=220f60c3-4cb2-480f-a365-f7852b229857"
            let timestamp = Date().timeIntervalSince1970
            let firebaseData: [String: Any] = [
                "uid": odooUID,
                "partner_id": partnerID,
                "name": name,
                "email": email,
                "completedSigningUp": false,
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
