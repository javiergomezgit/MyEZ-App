//
//  SettingsViewController.swift
//  MyEZ
//
//  Created by Javier Gomez on 12/13/17.
//  Copyright © 2017 JDev. All rights reserved.
//

import UIKit
import FirebaseAuth
import SCLAlertView
import MessageUI
import FirebaseDatabase


class MyProfileViewController: UITableViewController, MFMailComposeViewControllerDelegate {

    @IBOutlet weak var updateImageProfile: UIButton!
    
    @IBOutlet weak var userProfileImage: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var typeUserLabel: UILabel!
    @IBOutlet weak var websiteLabel: UILabel!
    
    @IBOutlet weak var signupButton: UIButton!
    @IBOutlet weak var signinButton: UIButton!
    
    @IBOutlet weak var accountButton: UIButton!
    @IBOutlet weak var ordersButton: UIButton!
    @IBOutlet weak var addressesButton: UIButton!
    @IBOutlet weak var dealsSwitch: UISwitch!
    
    @IBOutlet weak var signinupTableCell: UITableViewCell!

    override func viewWillAppear(_ animated: Bool) {
        
        navigationController?.navigationBar.isHidden = false

        
        if Auth.auth().currentUser?.uid != "" {
            print (Auth.auth().currentUser?.uid)
            loadInformationInScreen()
            hideOrDisableControls(hideOrDisable: false)
        } else {
            hideOrDisableControls(hideOrDisable: true)
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
       // self.modalPresentationStyle = .overFullScreen
        
        //For back button in navigation bar
        
        dealsSwitch.isOn = userInformation.subscribed
        
    }
    
    
    @objc func signout(sender: UIBarButtonItem) {
        
        cleanData()
        
        if Auth.auth().currentUser == nil {
            OperationQueue.main.addOperation {
                SCLAlertView().showSuccess("Logged Out", subTitle: "Successfully signed out. Hope to see you soon!")
            }
            
            self.gotoFirstScreen()
        }
    }
    
    func gotoFirstScreen() {
        let storyboard = UIStoryboard(name: "GetStarted", bundle: nil)
        
        let vc = storyboard.instantiateViewController(withIdentifier: "getStarted") as! GetStartedUIViewController
        vc.modalPresentationStyle = .overFullScreen
        self.present(vc, animated: false, completion: nil)
        
    }
    
    
    @IBAction func signupAction(_ sender: UIButton) {
        self.gotoFirstScreen()
    }
    
    @IBAction func signinAction(_ sender: UIButton) {
        self.gotoFirstScreen()
    }
    
    func loadInformationInScreen() {
    
        if let information = UserDefaults.standard.object(forKey: "userInformationSession") as? [String: String] {
            self.nameLabel.text = information["name"]
            self.websiteLabel.text = information["website"]
            self.typeUserLabel.text = information["typeUser"]
        }
        
        getImage()
        
        
        
        //load image from document files in device
        //first download from dabase if existe then
        
        
        
        
        
//        UserDefaults.standard.set([
//            "userId": userInformation.userId,
//            "emailUser": userInformation.email,
//            "name": userInformation.name,
//            "zipCode": userInformation.zipCode,
//            "website": userInformation.website,
//            "companyName": userInformation.companyName,
//            "phone": userInformation.phone,
//            ], forKey: "userInformationSession")
        
        
    
    }
    
    func getImage(){
        let fileManager = FileManager.default
        let imagePAth = (self.getDirectoryPath() as NSString).appendingPathComponent("MyEZProfileImage.png")
        
        print (imagePAth)
        if fileManager.fileExists(atPath: imagePAth){
            self.userProfileImage.image = UIImage(contentsOfFile: imagePAth)
        }else{
            print("No Image")
        }
    }
    
    func getDirectoryPath() -> String {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
    
    
    func hideOrDisableControls(hideOrDisable: Bool) {
        
        if hideOrDisable {
            
            updateImageProfile.isEnabled = false
            
            nameLabel.isHidden = false
            nameLabel.text = "Signin for more features"
            typeUserLabel.isHidden = true
            websiteLabel.isHidden = true
            
            signinButton.isHidden = false
            signupButton.isHidden = false
            heightForSignupSection = 50

            accountButton.isEnabled = false
            ordersButton.isEnabled = false
            addressesButton.isEnabled = false
            dealsSwitch.isEnabled = false
            
        } else {
            
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Logout", style: .done, target: self, action: #selector(signout(sender:)))

            updateImageProfile.isEnabled = true

            nameLabel.isHidden = false
            typeUserLabel.isHidden = false
            websiteLabel.isHidden = false
            
            signinButton.isHidden = true
            signupButton.isHidden = true
            heightForSignupSection = 0
            
            accountButton.isEnabled = true
            ordersButton.isEnabled = true
            addressesButton.isEnabled = true
            dealsSwitch.isEnabled = true
        }
    }
    
    var heightForSignupSection = 0
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 2 && indexPath.row == 0 {
            return CGFloat(heightForSignupSection)
        } else if indexPath.section == 0 && indexPath.row == 0 {
            let screenSize = UIScreen.main.bounds.height
            return CGFloat(screenSize * 0.2)
        } else {
            return UITableView.automaticDimension
        }
    }
    
    func cleanData() {
        
        let preferences = UserDefaults.standard
        
        preferences.removeObject(forKey: "userEmail")
        preferences.removeObject(forKey: "session")
        preferences.removeObject(forKey: "newUser")
        preferences.removeObject(forKey: "userInformationSession")
        preferences.synchronize()
        
        userInformation = UserValues(name: "", userId: "", email: "", zipCode: "", website: "", companyName: "", phone: "", businessType: "", about: "", myProfileImage: NSData(), typeUser: "", weight: "", subscribed: false, showWalk: true, idShopify: "")
        userUnits.removeAll()
        
        print (preferences)
        print (userInformation)
        print (userUnits)
        
        try! Auth.auth().signOut()
    }
    
    
    
    
    
    
    
    
    
    
    
    
    @IBAction func isSubscribed(_ sender: UISwitch) {
        
        if dealsSwitch.isOn {
            userInformation.subscribed = true
        }else {
            userInformation.subscribed = false
        }
        
        var ref : DatabaseReference!
        
        ref = Database.database().reference()
        
        ref.child("users").child(userInformation.userId).updateChildValues(["subscribed": userInformation.subscribed])
        
    }
    
    
    @IBAction func reportProblem(_ sender: UIButton) {

        if MFMailComposeViewController.canSendMail() {

            var alert = SCLAlertView()
            
            let apparance = SCLAlertView.SCLAppearance(kWindowWidth: UIScreen.main.bounds.width * 0.9)
            
            alert = SCLAlertView(appearance: apparance)
            
            let message = alert.addTextField("Message")
            message.autocorrectionType = .no
            message.autocapitalizationType = .none
            message.spellCheckingType = .no
            message.keyboardType = UIKeyboardType.alphabet
            message.layer.borderColor = UIColor.blue.cgColor
            
            alert.addButton("Send") {
                self.sendEmail(subjectText: "Report Problem", bodyText: message.text!)
            }
            alert.showEdit("Contact Us",
                           subTitle: "Type your message",
                           closeButtonTitle: "Cancel",
                           colorStyle: 0x60A2BF,
                           colorTextButton: 0xFFFFFF)
        } else {
            SCLAlertView().showError("Your email app is not configured", subTitle:"Send us an email to javier@ezinflatables.com")

        }
    }
        
    
    @IBAction func contactTechnial(_ sender: UIButton) {
      
        if MFMailComposeViewController.canSendMail() {

            var alert = SCLAlertView()
      //      let aparance = SCLAlertView.SCLAppearance(kDefaultShadowOpacity: T##CGFloat, kCircleTopPosition: T##CGFloat, kCircleBackgroundTopPosition: T##CGFloat, kCircleHeight: T##CGFloat, kCircleIconHeight: T##CGFloat, kTitleTop: T##CGFloat, kTitleHeight: T##CGFloat, kWindowWidth: T##CGFloat, kWindowHeight: T##CGFloat, kTextHeight: T##CGFloat, kTextFieldHeight: T##CGFloat, kTextViewdHeight: T##CGFloat, kButtonHeight: T##CGFloat, kTitleFont: T##UIFont, kTitleMinimumScaleFactor: T##CGFloat, kTextFont: T##UIFont, kButtonFont: T##UIFont, showCloseButton: T##Bool, showCircularIcon: T##Bool, shouldAutoDismiss: T##Bool, contentViewCornerRadius: T##CGFloat, fieldCornerRadius: T##CGFloat, buttonCornerRadius: T##CGFloat, hideWhenBackgroundViewIsTapped: T##Bool, circleBackgroundColor: T##UIColor, contentViewColor: T##UIColor, contentViewBorderColor: T##UIColor, titleColor: T##UIColor, dynamicAnimatorActive: T##Bool, disableTapGesture: T##Bool, buttonsLayout: T##SCLAlertButtonLayout, activityIndicatorStyle: T##UIActivityIndicatorView.Style)
            
            let apparance = SCLAlertView.SCLAppearance(kWindowWidth: UIScreen.main.bounds.width * 0.9)
            
            alert = SCLAlertView(appearance: apparance)
            
            let message = alert.addTextField("Message")
            message.autocorrectionType = .no
            message.autocapitalizationType = .none
            message.spellCheckingType = .no
            message.keyboardType = UIKeyboardType.alphabet
            message.layer.borderColor = UIColor.blue.cgColor
            //message.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.1)
            
            alert.addButton("Send") {
                self.sendEmail(subjectText: "Technical Problem", bodyText: message.text!)
            }
            alert.showEdit("Contact Us",
                           subTitle: "Type your message",
                           closeButtonTitle: "Cancel",
                           colorStyle: 0x60A2BF,
                           colorTextButton: 0xFFFFFF)
        } else {
            SCLAlertView().showError("Your email app is not configured", subTitle:"Send us an email to javier@ezinflatables.com")
        }
    }
    
    
    func sendEmail(subjectText: String, bodyText: String) {
        
        if MFMailComposeViewController.canSendMail() {
            let mail = MFMailComposeViewController()
            
            mail.mailComposeDelegate = self
            mail.setToRecipients(["javier@ezinflatables.com"])
            mail.setSubject(subjectText)
            mail.setMessageBody("<h1>\(subjectText):</h1> <br /> <h3>\(bodyText):</h3 > <br /> <h3>Name: \(userInformation.name) <br /> Email: \(userInformation.email)</h3>", isHTML: true)
            
            self.present(mail, animated: true, completion: nil)
        } else {
            SCLAlertView().showError("Your email app is not configured", subTitle:"Send us an email to javier@ezinflatables.com")
        }
    }
    
    
    @IBAction func openTermsOnline(_ sender: UIButton) {
        if let url = URL(string: "https://www.ezinflatables.com/pages/terms-and-conditions") {
            UIApplication.shared.open(url, options: [:])
        }
    }
    
    @IBAction func openPrivacyOnline(_ sender: UIButton) {
        if let url = URL(string: "https://www.ezinflatables.com/pages/privacy-policy") {
            UIApplication.shared.open(url, options: [:])
        }
    }
    
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
    }
}
