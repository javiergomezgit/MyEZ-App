//
//  GetStartedUIViewController.swift
//  MyEZ
//
//  Created by Javier Gomez on 9/21/17.
//  Copyright © 2017 JDev. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth
import Firebase

class GetStartedUIViewController: UIViewController {

    @IBOutlet weak var signupButton: UIButton!
    @IBOutlet weak var signinButton: UIButton!
    @IBOutlet weak var backLaunch: UIView!
    @IBOutlet weak var skipButton: UIButton!
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let registeredUser = UserDefaults.standard.bool(forKey: "registeredUser")
        
        if !registeredUser {
            UserDefaults.standard.set(true, forKey: "registeredUser")
            OperationQueue.main.addOperation {
                self.performSegue(withIdentifier: "showWalk", sender: self)
            }
        }
        
        signinButton.imageView?.contentMode = .scaleAspectFit
        signinButton.setImage(UIImage(named: "signinDown")?.withRenderingMode(.alwaysOriginal), for: .highlighted)
        
        signupButton.imageView?.contentMode = .scaleAspectFit
        signupButton.setImage(UIImage(named: "signUpDown")?.withRenderingMode(.alwaysOriginal), for: .highlighted)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if self.isLogged() {
            self.retrieveInfoFromUserDefaults()
            
        } else {
            backLaunch.isHidden = true
        }
    }
    
    @IBAction func skipGetStarted(_ sender: UIButton) {
        self.performSegue(withIdentifier: "getstartedMain", sender: self)

    }
    
    func isLogged() -> Bool{
    
        let preferences = UserDefaults.standard
        var logged = false

        if preferences.object(forKey: "session") != nil && preferences.object(forKey: "session") as? String != "LoggedOut" {
            logged = true
        } else if preferences.object(forKey: "session") as? String == "LoggedOut" {
            preferences.removeObject(forKey: "session")
            preferences.synchronize()
        } else {
            logged = false
        }
        
        print (preferences.object(forKey: "session"))

        return logged
    }

    func isUpdated() -> Bool {
        let preferences = UserDefaults.standard
        var updated = false

        if preferences.object(forKey: "completedSigningUp") as? Bool == true {
            updated = true
        } else {
            updated = false
        }
        return updated
    }

    func retrieveInfoFromUserDefaults() {
        let userInformationSession = UserDefaults.standard.value(forKey: "userInformationSession") as? [String: String] ?? [:]
        
        userInformation.userId = userInformationSession["userId"] as? String ?? ""
        userInformation.email = userInformationSession["emailUser"] as? String ?? ""
        userInformation.name = userInformationSession["name"] as? String ?? ""
        userInformation.zipCode = userInformationSession["zipCode"] as? String ?? ""
        userInformation.website = userInformationSession["website"] as? String ?? ""
        userInformation.companyName = userInformationSession["companyName"] as? String ?? ""
        userInformation.phone = userInformationSession["phone"] as? String ?? ""
        print (userInformation.zipCode)
        
        OperationQueue.main.addOperation {
            self.performSegue(withIdentifier: "getstartedMain", sender: self)
        }
    }
}


//OLD FUNCTIONS
/*
 func retrivePassword(for account: String) -> String? {
 let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
 kSecAttrAccount as String: account,
 kSecMatchLimit as String: kSecMatchLimitOne,
 kSecReturnData as String: kCFBooleanTrue]
 
 var retrivedData: AnyObject? = nil
 let _ = SecItemCopyMatching(query as CFDictionary, &retrivedData)
 
 guard let data = retrivedData as? Data else {return nil}
 return String(data: data, encoding: String.Encoding.utf8)
 }
 
 
 func saveInfoInLocalVariables() {
 
 var ref : DatabaseReference!
 
 ref = Database.database().reference()
 
 userInformation.userId = (Auth.auth().currentUser?.uid)!
 userInformation.email = (Auth.auth().currentUser?.email)!
 
 ref.child("users").child(userInformation.userId).observeSingleEvent(of: .value, with: {
 (snapshot) in
 // Get user value
 let value = snapshot.value as? NSDictionary
 
 if snapshot.exists() {
 let account = value?["account"] as! [String:String]
 
 if let units = value?["units"] as? NSDictionary {
 for unit in units {
 userUnits[unit.key as! String] = UnitInfo(model: unit.value as! String, imageUnit: NSData())
 }
 }
 userInformation.name = value?["name"] as? String ?? ""
 userInformation.website = value?["website"] as? String ?? ""
 userInformation.businessType = value?["businessType"] as? String ?? ""
 userInformation.companyName = value?["companyName"] as? String ?? ""
 userInformation.zipCode = value?["zipCode"] as? String ?? ""
 userInformation.about = value?["about"] as? String ?? ""
 userInformation.phone =  account["phone"] ?? ""
 userInformation.typeUser = value?["typeUser"] as? String ?? ""
 userInformation.weight = String(value?["weightOwned"] as? Int ?? 0)
 userInformation.subscribed = value?["subscribed"] as? Bool ?? false
 
 OperationQueue.main.addOperation {
 self.performSegue(withIdentifier: "getstartedMain", sender: self)
 }
 }
 })
 {
 (error) in
 print(error.localizedDescription)
 }
 }
 
 func newSignin(password: String) {
 Auth.auth().signIn(withEmail: userInformation.email, password: password) { (user, error) in
 if user != nil {
 print ("Welcome " + (user?.user.email)! + "\nThis is your ID: " + (user?.user.uid)!)
 self.performSegue(withIdentifier: "getstartedMain", sender: self)
 } else {
 print("Sorry wrong credentials")
 }
 }
 }
*/

