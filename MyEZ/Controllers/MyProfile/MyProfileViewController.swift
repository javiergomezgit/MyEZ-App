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
import YPImagePicker
import FirebaseDatabase


class MyProfileViewController: UITableViewController, MFMailComposeViewControllerDelegate {

    @IBOutlet weak var userProfileButton: UIButton!
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
    
    
    @IBAction func userProfileButtonTapped(_ sender: UIButton) {
        showPhotoCamera()
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
    
        if let user = UserSession.shared.load() {
            print("Welcome, \(user.name)!")
            
            self.nameLabel.text = user.name
            self.typeUserLabel.text = user.typeUser
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
            
            userProfileButton.isEnabled = false
            
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

            userProfileButton.isEnabled = true

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
        
        userInformation = UserValues(
            name: "",
            userId: "",
            email: "",
            zipCode: "",
            website: "",
            companyName: "",
            phone: "",
            businessType: "",
            about: "",
            myProfileImage: NSData(),
            typeUser: "",
            weight: 0,
            subscribed: false,
            showWalk: true
        )
        
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
        sendEmail(email: "javier@ezinflatables.com", name: "Javier")
    }
        
    
    @IBAction func contactTechnial(_ sender: UIButton) {
        sendEmail(email: "javier@ezinflatables.com", name: "Javier")
    }
    
    
    private let supportEmail = EmailSender()
    func sendEmail(email: String, name: String){
        let body = """
            Hi \(name),
            
            I need help with:
            
            ---
            User: \(self.nameLabel.text ?? "No name")
            App Version: \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?")
            iOS: \(UIDevice.current.systemVersion)
            Device: \(UIDevice.current.model)
            ---
            """
        supportEmail.presentEmailSender(from: self, to: [email], subject: "MyEZ App Contact", body: body)
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


//MARK: Photo camera/album picker
extension MyProfileViewController {
    
    func showPhotoCamera() {
        var config = YPImagePickerConfiguration()
        config.isScrollToChangeModesEnabled = true
        config.onlySquareImagesFromCamera = true
        config.usesFrontCamera = false
        config.showsPhotoFilters = false
        config.showsVideoTrimmer = false
        config.shouldSaveNewPicturesToAlbum = true
        config.startOnScreen = YPPickerScreen.library
        config.screens = [.library, .photo]
        config.showsCrop = .none
        config.targetImageSize = YPImageSize.original
        config.overlayView = UIView()
        config.hidesStatusBar = true
        config.hidesBottomBar = false
        config.hidesCancelButton = false
        config.silentMode = true
        config.preferredStatusBarStyle = UIStatusBarStyle.default
        config.maxCameraZoomFactor = 1.0
        
        let picker = YPImagePicker(configuration: config)
        
        picker.didFinishPicking { [unowned picker] items, cancelled in
            if cancelled {
                print("Picker was cancelled")
            }
            
            if let photo = items.singlePhoto {
                print(photo.fromCamera) // Image source (camera or library)
                print(photo.image) // Final image selected by the user
                print(photo.originalImage) // original image selected by the user, unfiltered
                print(photo.modifiedImage) // Transformed image, can     be nil
                print(photo.exifMeta) // Print exif meta data of original image.
                self.userProfileImage.image = photo.image
            }
            picker.dismiss(animated: true, completion: nil)
        }
        present(picker, animated: true, completion: nil)
    }
}
