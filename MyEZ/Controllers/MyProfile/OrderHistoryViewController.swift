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


class OrderHistoryViewController: UIViewController {

    @IBOutlet weak var emailText: UITextField!
    @IBOutlet weak var phoneText: UITextField!
    @IBOutlet weak var passwordText: UITextField!
    @IBOutlet weak var retypepassText: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        emailText.text = userInformation.email
        phoneText.text = userInformation.phone

    }
    
    @IBAction func saveInfo(_ sender: UIButton) {
        
        if userInformation.email != emailText.text {
            
            var ref : DatabaseReference!
            
            ref = Database.database().reference()
            
            let userID = userInformation.userId
            
            ref.child("users").child(userID).child("account").updateChildValues(["email": emailText.text])
            
            
            Auth.auth().currentUser?.updateEmail(to: emailText.text!, completion: { (error) in
                if error != nil {
                    SCLAlertView().showError("Try Again!", subTitle:(error?.localizedDescription.description)!)
                } else {
                    SCLAlertView().showInfo("Changed", subTitle:"Successfully changed email")
                }
            })

        }
        
        
            
        if passwordText.text != "" {
            if passwordText.text == retypepassText.text {
                
                Auth.auth().currentUser?.updatePassword(to: retypepassText.text!, completion: { (error) in
                    if error != nil {
                        SCLAlertView().showError("Try Again!", subTitle:(error?.localizedDescription.description)!)
                    } else {
                        SCLAlertView().showInfo("Changed", subTitle:"Successfully changed password")
                        self.passwordText.text = ""
                        self.retypepassText.text = ""
                    }
                    
                })
            } else {
                SCLAlertView().showError("Type again", subTitle: "Verify your password")
                passwordText.text = ""
                retypepassText.text = ""
            }
        }
        
        if phoneText.text != "" {
            var ref : DatabaseReference!
            
            ref = Database.database().reference()
            
            let userID = userInformation.userId

            userInformation.phone = phoneText.text!
            ref.child("users").child(userID).child("account").updateChildValues(["phone":phoneText.text!])
            
            SCLAlertView().showInfo("Changed", subTitle:"Successfully changed phone number")
            
        }
        
    }
    
    @IBAction func cancel(_ sender: UIButton) {
        
    }
    

}
