//
//  SettingsViewController.swift
//  MyEZ
//
//  Created by Javier Gomez on 12/13/17.
//  Copyright © 2017 JDev. All rights reserved.
//

import UIKit
import SCLAlertView
import MessageUI
import YPImagePicker
import FirebaseDatabase
import Kingfisher

class MyProfileViewController: UITableViewController, MFMailComposeViewControllerDelegate {
    
    @IBOutlet weak var userProfileButton: UIButton!
    @IBOutlet weak var userProfileImage: UIImageView!
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var typeUserLabel: UILabel!
    
    @IBOutlet weak var accountButton: UIButton!
    @IBOutlet weak var ordersButton: UIButton!
    @IBOutlet weak var addressesButton: UIButton!
    @IBOutlet weak var dealsSwitch: UISwitch!
        
    override func viewWillAppear(_ animated: Bool) {
        
        navigationController?.navigationBar.isHidden = false
        
        if let currentUser = UserSession.shared.load() {
            print (currentUser.email)
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
        
        //TODO: verify if there is no information save locally if nothing after cleaning then show the pop up
        if UserSession.shared.load() == nil {
            
            // Use the main thread to show the UI popup
            DispatchQueue.main.async {
                // Show the success alert
                SCLAlertView().showSuccess(
                    "Logged Out",
                    subTitle: "Successfully signed out. Hope to see you soon!"
                )
                
                // Return to the login or welcome screen
                self.gotoFirstScreen()
            }
        } else {
            print("⚠️ Local data was not fully cleared.")
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
            
            let profileURL = URL(string: user.profileImageUrl ?? "https://firebasestorage.googleapis.com/v0/b/myezfirebase.appspot.com/o/myez-default-profile-image.png?alt=media&token=220f60c3-4cb2-480f-a365-f7852b229857")
            if let finalURL = profileURL {
                userProfileImage.kf.setImage(with: finalURL)
                print("Loading image from: \(finalURL)")
            }
        }
    }
    
    func hideOrDisableControls(hideOrDisable: Bool) {
        
        if hideOrDisable {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Login", style: .done, target: self, action: #selector(signinAction))
            
            userProfileButton.isEnabled = false
            userProfileImage.image = UIImage(named: "defaultProfile")
            
            nameLabel.isHidden = false
            nameLabel.text = "Signin for more features"
            typeUserLabel.isHidden = true

            heightForSignupSection = 50
            
            accountButton.isEnabled = false
            ordersButton.isEnabled = false
            addressesButton.isEnabled = false
            dealsSwitch.isEnabled = false
            
        } else {
            
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Logout", style: .done, target: self, action: #selector(signout(sender:)))
            
            userProfileButton.isEnabled = true
            //TODO: When user is signed in, should load the image from firebase and get the url from local
            
            nameLabel.isHidden = false
            typeUserLabel.isHidden = false
            
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
        
        // 1. DELETE LOCAL INFORMATION (UserDefaults)
        UserDefaults.standard.removeObject(forKey: "savedUserSession")
        print("💾 Local user data deleted.")
        
        // 2. DELETE STORED COOKIES
        let storage = HTTPCookieStorage.shared
        if let cookies = storage.cookies {
            for cookie in cookies {
                storage.deleteCookie(cookie)
            }
        }
        print("🍪 Cookies cleared.")
        
        // 3. SIGNOUT FROM ODOO (Network Call)
        let odooLogoutURL = URL(string: "https://ezinflatables.odoo.com/web/session/logout")!
        var request = URLRequest(url: odooLogoutURL)
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) { _, _, _ in
            print("🔌 Signed out from Odoo Server.")
            
            // 4. NAVIGATE TO LOGIN SCREEN
            DispatchQueue.main.async {
                // Add your code here to switch the root view back to Login
            }
        }.resume()
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
