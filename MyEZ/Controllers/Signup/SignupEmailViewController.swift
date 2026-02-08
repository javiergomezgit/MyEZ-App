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
//import SwiftyJSON

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
    
    // MAIN FUNCTION
    func registerUserInOdoo(name: String, email: String, password: String) {
        
        let urlString = "\(OdooKeys.databaseURL)/jsonrpc"
        let database = OdooKeys.databaseName
        let botKey = OdooKeys.apiKey
        
        // ✅ HARDCODED ID FROM YOUR SCREENSHOT
        let portalGroupID = 10
        
        guard let url = URL(string: urlString) else { return }
        
        // STEP 1: CREATE USER (Naked - No groups yet)
        let newUserValues: [String: Any] = [
            "name": name,
            "login": email,
            "password": password,
            "active": true
        ]
        
        let params: [String: Any] = [
            "service": "object",
            "method": "execute_kw",
            "args": [
                database,
                2,       // Admin UID
                botKey,
                "res.users",
                "create",
                [newUserValues]
            ]
        ]
        
        let body: [String: Any] = ["jsonrpc": "2.0", "method": "call", "params": params, "id": 1]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        print("⏳ Step 1: Creating User...")
        
        URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            guard let self = self, let data = data else { return }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    
                    // CHECK FOR ERRORS
                    if let errorDict = json["error"] as? [String: Any] {
                        let msg = errorDict["message"] as? String ?? "Error"
                        print("🐞 Step 1 Failed: \(msg)")
                        DispatchQueue.main.async { self.alert(message: msg, title: "Odoo Error") }
                        return
                    }
                    
                    // SUCCESS -> MOVE TO STEP 2
                    if let newUID = json["result"] as? Int {
                        print("✅ Step 1 Success! New UID: \(newUID)")
                        
                        // CALL STEP 2 IMMEDIATELY
                        self.assignPortalGroup(uid: newUID, portalID: portalGroupID, botKey: botKey)
                        
                        // FETCH INFO FOR FIREBASE
                        self.fetchPartnerID(uid: newUID, botLogin: "admin", botKey: botKey, name: name, email: email)
                    }
                }
            } catch {
                print("Parsing Error: \(error)")
            }
        }.resume()
    }

    // STEP 2: FORCE PORTAL GROUP
    func assignPortalGroup(uid: Int, portalID: Int, botKey: String) {
        
        print("⏳ Step 2: Forcing User \(uid) into Group \(portalID)...")
        
        let urlString = "\(OdooKeys.databaseURL)/jsonrpc"
        let database = OdooKeys.databaseName
        
        // MAGIC COMMAND: (6, 0, [ID])
        // This tells Odoo: "REMOVE all other groups (including Internal) and KEEP ONLY Group 10"
        let writeValues: [String: Any] = [
            "groups_id": [[6, 0, [portalID]]]
        ]
        
        let params: [String: Any] = [
            "service": "object",
            "method": "execute_kw",
            "args": [
                database,
                2,       // Admin UID
                botKey,
                "res.users",
                "write",
                [[uid], writeValues]
            ]
        ]
        
        let body: [String: Any] = ["jsonrpc": "2.0", "method": "call", "params": params, "id": 2]
        
        guard let url = URL(string: urlString) else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, _, _ in
            guard let data = data else { return }
            
            // 🔍 DEBUGGING: PRINT THE RESULT
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📨 Step 2 Response: \(jsonString)")
                
                // Look for "result": true in the console log
                if jsonString.contains("\"result\":true") {
                    print("✨ SUCCESS: User is now Portal!")
                } else {
                    print("⚠️ WARNING: Failed to switch to Portal. User is still Internal.")
                }
            }
        }.resume()
    }
    
    
    // Helper to get the Partner ID after creation
    func fetchPartnerID(uid: Int, botLogin: String, botKey: String, name: String, email: String) {
        
        let urlString = "\(OdooKeys.databaseURL)/jsonrpc"
        let database = OdooKeys.databaseName
        
        // We search for the user we just created (by UID) and ask for their partner_id
        let params: [String: Any] = [
            "service": "object",
            "method": "execute_kw",
            "args": [
                database,
                1,          // Admin (Doorman) UID
                botKey,     // Admin API Key
                "res.users",
                "read",
                [uid],      // The UID of the new user
                ["fields": ["partner_id"]] // We only need this field
            ]
        ]
        
        let body: [String: Any] = [
            "jsonrpc": "2.0", "method": "call", "params": params, "id": 1
        ]
        
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
                   let firstUser = result.first {
                    
                    // CRITICAL ODOO PARSING:
                    // 'partner_id' comes back as an Array: [123, "Javier Gomez"]
                    // We need the first item (123)
                    var finalPartnerID = ""
                    
                    if let partnerArray = firstUser["partner_id"] as? [Any],
                       let id = partnerArray.first as? Int {
                        finalPartnerID = "\(id)"
                    }
                    
                    print("✅ Found Partner ID: \(finalPartnerID)")
                    
                    // ---------------------------------------------------------
                    // 🎯 THE FINAL STEP: SAVE TO FIREBASE
                    // ---------------------------------------------------------
                    DispatchQueue.main.async {
                        self.saveExtraInfoUser(
                            partnerID: finalPartnerID,
                            odooUID: "\(uid)",
                            email: email,
                            name: name
                        )
                        
                        // Optional: Navigate to Home Screen now
                        // self.performSegue(withIdentifier: "goToHome", sender: self)
                    }
                }
            } catch {
                print("Parsing Error in fetchPartnerID: \(error)")
            }
        }.resume()
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        // Simple validation
        return email.contains("@") && email.contains(".") && email.count >= 6
    }
    
    func saveExtraInfoUser(partnerID: String, odooUID: String, email: String, name: String) {
                
        let initialInformation = [
            "email": email,
            "uid": odooUID,
            "completedSigningUp" : false,
            "typeuser" : "minimumweight",
            "weightowned" : 1
        ] as [String : Any]
        
        //store in database firebase, odoo UID, name, username, maybe partner id, not sure if needed in future
        dbRef.child("users").child(partnerID).setValue(initialInformation) {
            (error:Error?, ref:DatabaseReference) in
            if let error = error {
                print (error)
            }
        }
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
