//
//  EmailLoginViewController.swift
//  MyEZ
//
//  Created by EZ Inflatables on 9/1/17.
//  Copyright © 2017 JDev. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth

class EmailLoginViewController: UIViewController {

    @IBOutlet weak var emailText: UITextField!
    @IBOutlet weak var passText: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    
    @IBOutlet weak var resultLabel: UILabel!
    
    @IBAction func forgotPassButton(_ sender: UIButton) {
        Auth.auth().sendPasswordReset(withEmail: emailText.text!) { (error) in
            print (error)
            
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
       
        loginButton.setImage(UIImage(named: "circles.png")?.withRenderingMode(.alwaysOriginal), for: .normal)
        loginButton.setImage(UIImage(named: "circles1.png")?.withRenderingMode(.alwaysOriginal), for: .highlighted)

        

    }

    @IBAction func loginAction(_ sender: UIButton) {
        //resultLabel.text = String(emailText.text! + passText.text!)
        
        Auth.auth().signIn(withEmail: emailText.text!, password: passText.text!) { (user, error) in
            if user != nil {
                self.resultLabel.text = "Welcome " + (user?.email)! + "\nThis is your ID: " + (user?.uid)!
                print ("Welcome " + (user?.email)! + "\nThis is your ID: " + (user?.uid)!)
            } else {
                self.resultLabel.text = "Sorry wrong credentials"
            }
        }
    }
    
}
