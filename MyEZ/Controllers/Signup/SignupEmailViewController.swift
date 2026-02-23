//
//  SignupEmailViewController.swift
//  MyEZ
//
//  Created by Javier Gomez on 9/8/17.
//  Copyright © 2017 JDev. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth

class SignupEmailViewController: UIViewController {
    
    @IBOutlet weak var nameText: UITextField!
    @IBOutlet weak var emailText: UITextField!
    @IBOutlet weak var passwordText: UITextField!
    @IBOutlet weak var verifyPasswordText: UITextField!
    @IBOutlet weak var nextButton: UIButton!
    
    var isEmpty = true
    private lazy var dbRef: DatabaseReference = Database.database().reference()
    
    override var prefersStatusBarHidden: Bool { return true }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupKeyboardDismiss()
    }
    
    private func setupKeyboardDismiss() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false // keeps buttons/taps working
        view.addGestureRecognizer(tap)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    
    @IBAction func nameChange(_ sender: UITextField) {
        if nameText.text == "" {
            self.isEmpty = true
        }
    }
    
    @IBAction func emailChanged(_ sender: UITextField){
        if emailText.text == "" {
            self.isEmpty = true
        }
    }
    
    @IBAction func passwordChanged(_ sender: UITextField) {
        if passwordText.text == "" {
            self.isEmpty = true
        }
    }
    
    @IBAction func verifyMatchingPass(_ sender: Any) {
        let pass = passwordText.text ?? ""
        let verify = verifyPasswordText.text ?? ""
        
        guard !pass.isEmpty, !verify.isEmpty else { return }
        guard pass == verify else {
            alert(message: "Passwords not matching, try again.", title: "Not matching")
            passwordText.text = ""
            verifyPasswordText.text = ""
            return
        }
    }
    
    @IBAction func verifyPasswordChanged(_ sender: UITextField) {
        if verifyPasswordText.text == "" {
            self.isEmpty = true
        } else {
            self.isEmpty = false
            nextButton.isEnabled = true
        }
    }
    
    @IBAction func nextButtonAction(_ sender: UIButton) {
        let email = (emailText.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let pass  = passwordText.text ?? ""
        let verify = verifyPasswordText.text ?? ""
        
        guard !email.isEmpty, !pass.isEmpty, !verify.isEmpty else {
            alert(message: "Please type your email and password.", title: "Missing Email/Password")
            return
        }
        
        guard pass == verify else {
            alert(message: "Passwords not matching, try again.", title: "Not matching")
            return
        }
        
        guard isValidEmail(email) else {
            alert(message: "Please enter a valid email address.", title: "Invalid Email")
            return
        }
        
        registerUserInOdoo(name: nameText.text!, email: email, password: pass)
        
    }
    
    
    func registerUserInOdoo(name: String, email: String, password: String) {
        
        let urlString = "\(OdooKeys.databaseURL)/jsonrpc"
        let database = OdooKeys.databaseName
        let botKey = OdooKeys.apiKey
        let templateID = 13 // Keep using 13 if that is your Portal Template ID
        
        guard let url = URL(string: urlString) else { return }
        
        // CLONE COMMAND
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
        
        print("⏳ Cloning Portal Template (ID: \(templateID))...")
        
        URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            guard let self = self else { return }
            
            // 1. CHECK FOR NETWORK ERRORS
            if let error = error {
                print("❌ Network Error: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else { print("❌ No Data Received"); return }
            
            // 2. PRINT THE RAW RESPONSE (This will tell us why it hung!)
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📨 Odoo Response: \(jsonString)")
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    
                    // ERROR HANDLING
                    if let errorDict = json["error"] as? [String: Any] {
                        let msg = errorDict["message"] as? String ?? "Error"
                        print("🐞 ODOO ERROR: \(errorDict)")
                        DispatchQueue.main.async { self.alert(message: msg, title: "Odoo Error") }
                        return
                    }
                    
                    // SUCCESS PARSING
                    var newUID: Int?
                    
                    if let id = json["result"] as? Int {
                        newUID = id
                    } else if let ids = json["result"] as? [Int], let first = ids.first {
                        newUID = first
                    }
                    
                    if let validUID = newUID {
                        print("✅ User Cloned! New UID: \(validUID)")
                        print("🚀 Moving to Fetch Partner ID...")
                        
                        self.fetchPartnerID(uid: validUID, botLogin: "admin", botKey: botKey, name: name, email: email)
                    } else {
                        print("⚠️ Could not parse UID from result: \(json["result"] ?? "nil")")
                    }
                }
            } catch {
                print("❌ JSON Parsing Error: \(error)")
            }
        }.resume()
    }
    
    
    // Helper to get the Partner ID after creation
    func fetchPartnerID(uid: Int, botLogin: String, botKey: String, name: String, email: String) {
        
        print("⏳ Fetching Partner ID for User \(uid)...")
        
        let urlString = "\(OdooKeys.databaseURL)/jsonrpc"
        let database = OdooKeys.databaseName
        
        // Command: READ the 'partner_id' field for this User ID
        let params: [String: Any] = [
            "service": "object",
            "method": "execute_kw",
            "args": [
                database, 2, botKey,
                "res.users", "read",
                [[uid], ["partner_id"]] // We only ask for this one field
            ]
        ]
        
        let body: [String: Any] = ["jsonrpc": "2.0", "method": "call", "params": params, "id": 2]
        
        guard let url = URL(string: urlString) else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            guard let self = self, let data = data else { return }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let result = json["result"] as? [[String: Any]],
                   let firstRecord = result.first {
                    
                    // ⚠️ CRITICAL PART:
                    // Odoo returns partner_id as: [123, "Name"]
                    
                    var partnerID: Int?
                    
                    if let partnerArray = firstRecord["partner_id"] as? [Any],
                       let id = partnerArray.first as? Int {
                        partnerID = id
                    } else {
                        print("⚠️ Could not parse partner_id array: \(firstRecord["partner_id"] ?? "nil")")
                    }
                    
                    if let finalPartnerID = partnerID {
                        print("✅ Found Partner ID: \(finalPartnerID)")
                        
                        //  Go to Home Screen
                        DispatchQueue.main.async {
                            // self.saveToFirebase(...)
                            print("🎉 REGISTRATION COMPLETE! Navigating to Home...")
                            
                            self.didFinishRegistration(partnerID: partnerID!, odooUID: uid, email: email, name: name)
                        }
                    }
                } else {
                    print("❌ Failed to read Partner ID from response: \(String(data: data, encoding: .utf8) ?? "")")
                }
            } catch {
                print("❌ Parsing Error in fetchPartnerID: \(error)")
            }
        }.resume()
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        // Simple validation
        return email.contains("@") && email.contains(".") && email.count >= 6
    }
    
    func didFinishRegistration(partnerID: Int, odooUID: Int, email: String, name: String) {
        
        uploadProfileImage(partnerID: partnerID) { [weak self] imageURL in
            guard let self = self else { return }
            
            let finalImageURL = imageURL ?? "https://firebasestorage.googleapis.com/v0/b/myezfirebase.appspot.com/o/myez-default-profile-image.png?alt=media&token=220f60c3-4cb2-480f-a365-f7852b229857"
            
            // Get the current date for analytics (e.g. "When did this user join?")
            let timestamp = Date().timeIntervalSince1970
            
            let firebaseData: [String: Any] = [
                "uid": odooUID,              // The Odoo User ID (for JSON-RPC calls)
                "partner_id": partnerID,     // The Odoo Partner ID (for Invoices/Orders)
                "name": name,                // Display name for the Home Screen
                "email": email,              // Contact email
                "completedSigningUp": false,
                "typeuser": "minimumweight",
                "owned_weight": 1,
                "units": ["SKU": 1], //Going to store the skus of all the units that user owns and the owned quantity of each sku
                "company_id": 25,            // We know they belong to Company 25
                "company_name": "",
                "createdAt": timestamp,      // Good for sorting users by "Newest"
                "phone": "",                 // Placeholder for profile updates
                "fcmToken": "",               // Placeholder for Push Notifications
                "profile_image_url": finalImageURL
            ]
            
            // Save to Firebase
            dbRef.child("users").child("\(partnerID)").setValue(firebaseData) { (error, ref) in
                if let error = error {
                    print("❌ Firebase Save Error: \(error.localizedDescription)")
                } else {
                    print("✅ User Saved to Firebase! Partner ID: \(partnerID)")
                    
                    //SAVE LOCALLY
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
                    
                    self.loginAndSaveCookie(password: self.passwordText.text!, login: email) {
                        print("🚀 Performing Segue 'loginMain'...")
                        self.performSegue(withIdentifier: "signupMain", sender: self)
                    }
                }
            }
        }
    }
    
    func uploadProfileImage(partnerID: Int, completion: @escaping (String?) -> Void) {
        
        let storageRef = Storage.storage().reference().child("users/\(partnerID)/profile/\(partnerID)_profile_image.jpg")
        
        //Get Image from Assets (Ensure "default_profile_asset" exists in your Assets.xcassets)
        guard let defaultImage = UIImage(named: "defaultProfile"),
              let imageData = defaultImage.jpegData(compressionQuality: 0.7) else {
            print("❌ Image Asset not found")
            completion(nil)
            return
        }
        
        //Upload
        storageRef.putData(imageData, metadata: nil) { (metadata, error) in
            if let error = error {
                print("❌ Storage Error: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            //Retrieve URL
            storageRef.downloadURL { (url, error) in
                completion(url?.absoluteString)
            }
        }
    }
    
    // Add 'completion: @escaping () -> Void' to the parameters
    func loginAndSaveCookie(password: String, login: String, completion: @escaping () -> Void) {
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
        
        print("🔐 Attempting Login to Capture Cookie...")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            
            if let httpResponse = response as? HTTPURLResponse,
               let fields = httpResponse.allHeaderFields as? [String: String],
               let url = response?.url {
                
                let cookies = HTTPCookie.cookies(withResponseHeaderFields: fields, for: url)
                
                for cookie in cookies {
                    if cookie.name == "session_id" {
                        print("🍪 CAPTURED SESSION: \(cookie.value)")
                        
                        //Save to memory (instant process)
                        SessionManager.shared.currentSessionID = cookie.value
                        
                        //Save to disk (backup for future use in the app)
                        UserDefaults.standard.set(cookie.value, forKey: "odooSessionID")
                    }
                }
            }
            
            // Force the save to happen right now
            UserDefaults.standard.synchronize()
            
            // 🛑 CRITICAL: Tell the main thread we are done!
            DispatchQueue.main.async {
                completion()
            }
            
        }.resume()
    }
    
    @IBAction func openTermsOnline(_ sender: UIButton) {
        
        if let url = URL(string: "https://www.ezinflatables.com/pages/terms-and-conditions") {
            UIApplication.shared.open(url, options: [:])
        }
    }
    
    func alert(message: String, title: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let OKAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(OKAction)
        self.present(alertController, animated: true, completion: nil)
    }
}
