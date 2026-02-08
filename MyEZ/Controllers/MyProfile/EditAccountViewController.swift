//
//  EditAcountViewController.swift
//  MyEZ
//
//  Created by Javier Gomez on 9/16/18.
//  Copyright © 2018 JDev. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth
import SCLAlertView


class EditAccountViewController: UIViewController {
    
    @IBOutlet weak var nameText: UITextField!
    @IBOutlet weak var phoneText: UITextField!
    @IBOutlet weak var zipcodeText: UITextField!
    @IBOutlet weak var companyText: UITextField!
    @IBOutlet weak var emailText: UITextField!
    @IBOutlet weak var currentPassword: UITextField!
    @IBOutlet weak var newPasswordText: UITextField!
    @IBOutlet weak var verifyPasswordText: UITextField!
    
    @IBOutlet weak var updateSecurityButton: UIButton!
    @IBOutlet weak var coveringPasswordsView: UIView!
    @IBOutlet weak var coveringEmailView: UIView!

    var ref : DatabaseReference!
    
    override func viewDidLoad() {
        
        navigationController?.navigationBar.isHidden = true

        ref = Database.database().reference()

    }
    
    override func viewWillAppear(_ animated: Bool) {
        loadInformation()
    }
    
    @IBAction func cancelUpdate(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
        self.dismiss(animated: true, completion: nil)
    }
    
    func loadInformation() {
       
        nameText.text = userInformation.name
        phoneText.text = userInformation.phone
        zipcodeText.text = userInformation.zipCode
        companyText.text = userInformation.companyName
        emailText.text = userInformation.email
    }
    
    
    @IBAction func updateInformation(_ sender: UIButton) {
        if nameText.text != "" {
            saveInformationInDB()
        } else {
            SCLAlertView().showError("Missing information!", subTitle:("Name can not be empty"))
        }
    }
    
    @IBAction func updateSecurity(_ sender: UIButton) {
        if emailText.text != userInformation.email {
            saveEmail()
        }
        
        if newPasswordText.text != "" {
            if newPasswordText.text == verifyPasswordText.text {
                savePassword()
            } else {
                SCLAlertView().showError("Not matching", subTitle:("Passwords not matching, try again."))
                newPasswordText.text = ""
                verifyPasswordText.text = ""
            }
        }
    }
    
    func saveInformationInDB() {
        
        ref.child("users").child(userInformation.userId).updateChildValues(
             ["name" : nameText.text!,
             "phone" : phoneText.text!,
             "zipCode" : zipcodeText.text!,
             "companyName" : companyText.text!]) { (error, reference) in
                if error == nil {
                    self.saveInfoIntormationInDevice()
                    SCLAlertView().showInfo("Changed", subTitle:"Successfully changed information")
                } else {
                    SCLAlertView().showError("Something wrong!", subTitle:(error!.localizedDescription))
                }
        }
       
    }
    
    func saveInfoIntormationInDevice() {
        userInformation.email = emailText.text!
        userInformation.name = nameText.text!
        userInformation.zipCode = zipcodeText.text!
        userInformation.companyName = companyText.text!
        userInformation.phone = phoneText.text!
        
        UserDefaults.standard.set([
            "emailUser": userInformation.email,
            "name": userInformation.name,
            "zipCode": userInformation.zipCode,
            "website": userInformation.website,
            "companyName": userInformation.companyName,
            "phone": userInformation.phone,
            ], forKey: "userInformationSession")
    }
    
    
    func saveEmail() {
        Auth.auth().currentUser?.updateEmail(to: emailText.text!, completion: { (error) in
            if error != nil {
                SCLAlertView().showError("Try Again!", subTitle:(error?.localizedDescription.description)!)
            } else {
                self.ref.child("users").child(userInformation.userId).updateChildValues(
                ["account" : ["email": self.emailText.text!]]) {
                    (error, reference) in
                    if error == nil {
                        self.saveInfoIntormationInDevice()
                        SCLAlertView().showInfo("Changed", subTitle:"Successfully changed email")
                    } else {
                        SCLAlertView().showError("Something wrong!", subTitle:(error!.localizedDescription))
                    }
                }
            }
        })
    }

    func savePassword() {
        Auth.auth().currentUser?.updatePassword(to: newPasswordText.text!, completion: { (error) in
            if error != nil {
                SCLAlertView().showError("Try Again!", subTitle:(error?.localizedDescription.description)!)
            } else {
                SCLAlertView().showInfo("Changed", subTitle:"Successfully changed password")
                self.newPasswordText.text = ""
                self.verifyPasswordText.text = ""
            }
        })
    }
    
    
    @IBAction func verifyCurrentPassword(_ sender: UITextField) {
        let credential = EmailAuthProvider.credential(withEmail: userInformation.email, password: currentPassword.text!)
        if let user = Auth.auth().currentUser {
            user.reauthenticate(with: credential) { result, error in
                if error != nil{
                    self.coveringEmailView.isHidden = false
                    self.coveringPasswordsView.isHidden = false
                    self.currentPassword.text = ""
                    self.updateSecurityButton.isEnabled = false
                    SCLAlertView().showError("Wrong password", subTitle:("Sorry, you typed a wrong password"))
                } else{
                    print ("activate fields")
                    self.currentPassword.text = ""
                    self.updateSecurityButton.isEnabled = true
                    self.coveringEmailView.isHidden = true
                    self.coveringPasswordsView.isHidden = true
                }
            }
        }
    }
}
