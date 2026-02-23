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
//        var logged = false
//        let user = UserSession.shared.load()
//        if user != nil {
//            logged = true
//        }
//        return logged
        
        
        //*-- Fancier way --*//
        return UserSession.shared.load() != nil
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
                
        if let userInformationSession = UserSession.shared.load() {
            userInformation.userId = String(userInformationSession.partnerID)
            userInformation.email = userInformationSession.email
            userInformation.name = userInformationSession.name
            userInformation.profileImageUrl = userInformationSession.profileImageUrl ?? "https://firebasestorage.googleapis.com/v0/b/myezfirebase.appspot.com/o/myez-default-profile-image.png?alt=media&token=220f60c3-4cb2-480f-a365-f7852b229857"
            userInformation.typeUser = userInformationSession.typeUser
            userInformation.weight = userInformationSession.ownwedWeight
            
            OperationQueue.main.addOperation {
                self.performSegue(withIdentifier: "getstartedMain", sender: self)
                print("User already signed in: \(userInformation.name) (ID: \(userInformation.userId))")
            }
        }
    }
}

