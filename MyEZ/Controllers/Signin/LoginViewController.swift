//
//  LoginViewController.swift
//  MyEZ
//
//  Created by Javier Gomez on 9/1/17.
//  Copyright © 2017 JDev. All rights reserved.
//

import UIKit
import Firebase

extension UITextField{
    @IBInspectable var placeHolderColor: UIColor? {
        get {
            return self.placeHolderColor
        }
        set {
            self.attributedPlaceholder = NSAttributedString(string:self.placeholder != nil ? self.placeholder! : "", attributes:    [NSAttributedString.Key.foregroundColor: newValue!])
        }
    }
}


class LoginViewController: UIViewController, UITextFieldDelegate{
    
    @IBOutlet weak var emailText: UITextField!
    @IBOutlet weak var passText: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    
    // ERROR TYPES
    enum LoginError: Error {
        case badURL
        case networkError(Error)
        case invalidResponse
        case odooError(String)
        case parsingError
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.emailText.delegate = self
        self.passText.delegate = self
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    @IBAction func emailTextChanged(_ sender: UITextField) {
        if emailText.text != "" && passText.text != "" {
            loginButton.isEnabled = true
        } else {
            loginButton.isEnabled = false
        }
        
    }
    
    //Validate when textfield changes
    @IBAction func passwordTextChanged(_ sender: UITextField) {
        if emailText.text != "" && passText.text != "" {
            loginButton.isEnabled = true
        } else {
            loginButton.isEnabled = false
        }
    }
    
    @IBAction func loginAction(_ sender: UIButton) {
        //let key = OdooKeys.apiKey //Key is for signing as admin
        
        signInWithOdoo(email: emailText.text!, password: passText.text!) { [weak self] result in
            DispatchQueue.main.async(execute: {
                switch result {
                case .success(let user):
                    self?.handleLoginSuccess(user: user)
                    
                case .failure(let error):
                    let msg: String
                    switch error {
                    case .odooError(let m): msg = m
                    case .networkError(let e): msg = "Network error: \(e)"
                    default: msg = "Unknown error"
                    }
                    self?.alert(message: msg, title: "Error")
                }
            })
        }
        
    }
    
    func handleLoginSuccess(user: OdooUser) {
        print("✅ Logged in as: \(user.name)")
        print("🔑 Session ID: \(user.sessionID)")
        
        // TODO: Save to Keychain here
        
        // Navigate to Main App
        //             let mainVC = MainTabBarController()
        //             mainVC.modalPresentationStyle = .fullScreen
        //             self.present(mainVC, animated: true)
        
        self.performSegue(withIdentifier: "loginMain", sender: self)
        
        alert(message: "Welcome", title: "Hello, \(user.name)")
    }
    
    func signInWithOdoo(email: String, password: String, completion: @escaping (Result<OdooUser, LoginError>) -> Void) {
        
        let database = OdooKeys.databaseName
        let urlString = OdooKeys.databaseURL
        
        guard let url = URL(string: "\(urlString)/web/session/authenticate") else {
            completion(.failure(.badURL))
            return
        }
        
        // 2. Prepare the Parameters
        let params: [String: Any] = [
            "db": database,
            "login": email,
            "password": password
        ]
        
        // 3. Wrap in JSON-RPC format
        let body: [String: Any] = [
            "jsonrpc": "2.0",
            "method": "call",
            "params": params,
            "id": Int(Date().timeIntervalSince1970)
        ]
        
        // 4. Setup Request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Serialize body
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            completion(.failure(.parsingError))
            return
        }
        
        // 5. Execute
        URLSession.shared.dataTask(with: request) { data, response, error in
            
            // Handle Network Failures
            if let error = error {
                completion(.failure(.networkError(error)))
                return
            }
            
            guard let data = data else {
                completion(.failure(.invalidResponse))
                return
            }
            
            // 6. Parse Response
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    
                    // A. Check for Odoo Logic Errors (Wrong Password, etc.)
                    if let errorDict = json["error"] as? [String: Any] {
                        let message = errorDict["message"] as? String ?? "Unknown Odoo Error"
                        // Sometimes the detailed message is deeper
                        let dataDict = errorDict["data"] as? [String: Any]
                        let detailedMsg = dataDict?["message"] as? String ?? message
                        
                        completion(.failure(.odooError(detailedMsg)))
                        return
                    }
                    
                    // B. Parse Success Result
                    if let result = json["result"] as? [String: Any] {
                        
                        // Extract Session ID from fields or response
                        let sessionID = result["session_id"] as? String ?? ""
                        
                        let user = OdooUser(
                            uid: result["uid"] as? Int ?? 0,
                            name: result["name"] as? String ?? "Unknown",
                            username: result["username"] as? String ?? email,
                            partnerID: result["partner_id"] as? Int ?? 0,
                            sessionID: sessionID,
                            companyID: result["company_id"] as? Int ?? 0
                        )
                        
                        // C. SUCCESS!
                        completion(.success(user))
                    } else {
                        completion(.failure(.parsingError))
                    }
                }
            } catch {
                completion(.failure(.parsingError))
            }
        }.resume()
        
    }
    
    //TODO: Future function
    func signinInOdooAndGetData(email: String, password: String, apiKey: String) {
        
        // 1. ENDPOINT TO "AUTHENTICATE"
        // This specific URL returns the full user profile immediately
        let database = OdooKeys.databaseName
        let urlString = OdooKeys.databaseURLGetData
        
        guard let url = URL(string: urlString) else { return }
        
        // 2. SIMPLER PARAMETERS
        let params: [String: Any] = [
            "db": database,
            "login": email,
            "password": apiKey
        ]
        
        let body: [String: Any] = [
            "jsonrpc": "2.0",
            "method": "call", // This remains "call"
            "params": params,
            "id": Int(Date().timeIntervalSince1970)
        ]
        
        // 3. SETUP REQUEST
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch { return }
        
        // 4. SEND REQUEST
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else { return }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    
                    // CHECK FOR ERRORS
                    if let error = json["error"] as? [String: Any] {
                        print("❌ Login Failed: \(error["message"] ?? "")")
                        return
                    }
                    
                    // 5. PARSE THE RICH RESULT
                    if let result = json["result"] as? [String: Any] {
                        
                        print (result)
                        let uid = result["uid"] as? Int ?? 0
                        let name = result["name"] as? String ?? "No Name"
                        let username = result["username"] as? String ?? ""
                        let partnerID = result["partner_id"] as? Int ?? 0 // Useful for fetching address later
                        let sessionID = result["session_id"] as? String ?? "" // Keep this if you want to stay logged in!
                        let companyID = result["company_id"] as? Int ?? 0
                        
                        print("✅ Success!")
                        print("UID: \(uid)")
                        print("Name: \(name)")
                        print("User: \(username)")
                        print (partnerID)
                        print (sessionID)
                        
                        // 6. PROCEED TO FIREBASE IMMEDIATELY
                        DispatchQueue.main.async {
                            let odooUser = OdooUser(uid: uid, name: name, username: username, partnerID: partnerID, sessionID: sessionID, companyID: companyID)
                            self.downloadDataFirebase(signedUser: odooUser)
                        }
                    }
                }
            } catch {
                print("Parsing Error: \(error)")
            }
        }.resume()
    }
    
    
    func downloadDataFirebase(signedUser: OdooUser) {
        
        var databaseReference : DatabaseReference!
        databaseReference = Database.database().reference()
        
        databaseReference.child("users").child(userInformation.userId).observeSingleEvent(of: .value, with: { (snapshot) in
            // Get user value
            let value = snapshot.value as? NSDictionary
            
            if let units = value?["units"] as? NSDictionary {
                for unit in units {
                    userUnits[unit.key as! String] = UnitInfo(model: unit.value as! String, imageUnit: NSData())
                }
            }
            
            userInformation.website = value?["website"] as? String ?? ""
            userInformation.companyName = value?["companyName"] as? String ?? ""
            userInformation.zipCode = value?["zipCode"] as? String ?? ""
            userInformation.phone =  value?["phone"] as? String ?? ""
            userInformation.typeUser = value?["typeUser"] as? String ?? ""
            userInformation.weight = value?["owned_weight"] as? Int ?? 0
            userInformation.subscribed = value?["subscribed"] as? Bool ?? false
            userInformation.profileImageUrl = value?["profile_image_url"] as? String ?? "https://firebasestorage.googleapis.com/v0/b/myezfirebase.appspot.com/o/myez-default-profile-image.png?alt=media&token=220f60c3-4cb2-480f-a365-f7852b229857"
            
            OperationQueue.main.addOperation {
                self.saveLocally(signedOdooUser: signedUser)
                self.performSegue(withIdentifier: "loginMain", sender: self)
                
            }
        })
        {
            (error) in
            print(error.localizedDescription)
            
            
        }
    }
    
    func saveLocally(signedOdooUser: OdooUser) {
        
        let localUser = AppUser(
            uid: signedOdooUser.uid,
            partnerID: signedOdooUser.partnerID,
            name: signedOdooUser.name,
            email: self.emailText.text!,
            typeUser: userInformation.typeUser,
            ownwedWeight: userInformation.weight,
            companyID: 25,
            completedSigningUp: false,
            profileImageUrl: userInformation.profileImageUrl
        )
        UserSession.shared.save(user: localUser)
    }
    
    @IBAction func forgotPassButton(_ sender: UIButton) {
        if emailText.text == "" {
            self.alert(message: "Please fill in with your e-mail in the text field", title: "Missing email")
        } else {
            Auth.auth().sendPasswordReset(withEmail: emailText.text!) { (error) in
                if error == nil {
                    self.alert(message: "Check your email for more details", title: "Reset password")
                } else {
                    if let errCode = AuthErrorCode(rawValue: error!._code) {
                        switch errCode {
                        case .invalidEmail:
                            self.alert(message: "Please fill the information with a valid email", title: "Invalid email")
                        case .emailAlreadyInUse:
                            self.alert(message: "Email is already in use", title: "Email in use")
                        default:
                            self.alert(message: error!.localizedDescription, title: "System error")
                        }
                    }
                }
            }
        }
    }
    
    func alert(message: String, title: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let OKAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(OKAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
}

