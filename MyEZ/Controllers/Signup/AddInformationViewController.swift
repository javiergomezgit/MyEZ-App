//
//  AddInformationViewController.swift
//  MyEZ
//
//  Created by Javier Gomez on 10/14/17.
//  Copyright © 2017 JDev. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth

class AddInformationViewController: UIViewController {
    
    @IBOutlet weak var nameText: UITextField!
    @IBOutlet weak var phoneText: UITextField!
    @IBOutlet weak var zipCode: UITextField!
    @IBOutlet weak var companyText: UITextField!
    @IBOutlet weak var websiteText: UITextField!

    
    @IBOutlet weak var backgroundView: UIImageView!
    
    @IBOutlet weak var signupButton: UIButton!
    
    var missingInfo = true
    
    override var prefersStatusBarHidden: Bool {
        return true
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    @IBAction func nameTextChanged(_ sender: UITextField) {
        OperationQueue.main.addOperation {
            if self.nameText.text != "" {
                userInformation.name = self.nameText.text!
            }
        }
    }
    @IBAction func phoneTextChanged(_ sender: UITextField) {
        if phoneText.text != "" {
            userInformation.phone = String(phoneText.text!)
        } else {
            userInformation.phone = "000 - 000 - 0000"
        }
    }
    @IBAction func zipcodeTextChanged(_ sender: UITextField) {
        if zipCode.text != "" {
            userInformation.zipCode = String(zipCode.text!)
        }
    }
    @IBAction func companyTextChanged(_ sender: UITextField) {
        if companyText.text != "" {
            userInformation.companyName = companyText.text!
        }
    }
    @IBAction func websiteTextChanged(_ sender: UITextField) {
        if websiteText.text != "" {
            userInformation.website = websiteText.text!
        } else {
            userInformation.website = "www.yourwebsite.com"
        }
    }
    
    @IBAction func signupAction(_ sender: UIButton) {
    
        saveInfo()
    }
    
    
    
    func saveInfo() {
        
        if !checkIfEmptyInfo() {
            
            var ref : DatabaseReference!
            
            ref = Database.database().reference()
            
            let userID = Auth.auth().currentUser?.uid
            userInformation.email = (Auth.auth().currentUser?.email)!
            
            ref.child("users").child(userID!).updateChildValues([
                "account": ["email": userInformation.email, "completedSigningUp": true],
                "name": userInformation.name,
                "phone": phoneText.text!,
                "zipCode": userInformation.zipCode,
                "companyName": userInformation.companyName,
                "website": userInformation.website,
                "typeUser": "minimumweight",
                "weightOwned": "0"]) {
                (error:Error?, ref:DatabaseReference) in
                
                    if let error = error {
                        print (error)
                    } else {
                        extraInfo.completedSigningUp = true
                        userInformation.typeUser = "minimumweight"
                        userInformation.weight = "0"
                        
                        let preferences = UserDefaults.standard
    //                    preferences.set(true, forKey: "newUser")
                        preferences.set(userID!, forKey: "session")
                        
                        self.saveInfoIntoUserDefaults()
                        
                        self.performSegue(withIdentifier: "addMain", sender: self)
                    }
                }
        } else {
           
            alert(message: "Your name, zip code, and company name are required", title: "Missing information")
            
            extraInfo.completedSigningUp = false
            let preferences = UserDefaults.standard
            preferences.set(extraInfo.completedSigningUp, forKey: "completedSigningUp")
        }
        
    }
    
    func checkIfEmptyInfo() -> Bool{
        var isEmpty = true
        
        if userInformation.name == "" ||
            userInformation.zipCode == "" ||
            userInformation.companyName == ""
        {
            isEmpty = true
        } else {
            isEmpty = false
        }
        
        return isEmpty
    }
    
    func saveInfoIntoUserDefaults() {
        
        UserDefaults.standard.set([
            "userId": userInformation.userId,
            "idShopify" : userInformation.idShopify,
            "emailUser": userInformation.email,
            "name": userInformation.name,
            "zipCode": userInformation.zipCode,
            "website": userInformation.website,
            "companyName": userInformation.companyName,
            "phone": userInformation.phone,
            "subscribed": userInformation.subscribed
            ], forKey: "userInformationSession")
    }
    
    func alert(message: String, title: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let OKAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(OKAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
}


//OLD FUNCTIONS
/*
 func loadInfo() {
 nameText?.text = userInformation.name
 websiteText?.text = userInformation.website
 companyText?.text = userInformation.companyName
 zipCode?.text = userInformation.zipCode
 companyText?.text = userInformation.companyName
 phoneText?.text = userInformation.phone
 }
 */
