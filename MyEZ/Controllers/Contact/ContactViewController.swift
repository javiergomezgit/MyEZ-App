//
//  ContactViewController.swift
//  MyEZ
//
//  Created by Javier Gomez on 11/15/17.
//  Copyright © 2017 JDev. All rights reserved.
//

import UIKit
import MessageUI

class ContactViewController: UIViewController {
    
    @IBOutlet weak var ceoButton: UIButton!
    @IBOutlet weak var cooButton: UIButton!
    @IBOutlet weak var facebookButton: UIButton!
    @IBOutlet weak var instagramButton: UIButton!
    @IBOutlet weak var youtubeButton: UIButton!
    @IBOutlet weak var tiktokButton: UIButton!
    @IBOutlet weak var callUsButton: UIButton!
    
    @IBAction func goinToFacebook(_ sender: UIButton) {
        socialMediaAction(linkSocialMedia: "https://www.facebook.com/209605312428497", appSocialMedia: "fb://profile/209605312428497")
    }
    
    @IBAction func goinToInstagram(_ sender: UIButton) {
        socialMediaAction(linkSocialMedia: "http://instagram.com/ez_inflatables", appSocialMedia: "instagram://user?username=ez_inflatables")
    }
    
    @IBAction func goinToYoutube(_ sender: UIButton) {
        socialMediaAction(linkSocialMedia: "https://youtube.com/channel/UCYG_F4nyo3UCXv3cO-X6iAw", appSocialMedia: "youtube://www.youtube.com/channel/UCYG_F4nyo3UCXv3cO-X6iAw")
    }
    
    @IBAction func goinToTiktok(_ sender: UIButton) {
        socialMediaAction(linkSocialMedia: "https://tiktok.com/@ez_inflatables", appSocialMedia: "tiktok://user?screen_name=ez_inflatables")
    }
    
    func socialMediaAction(linkSocialMedia: String, appSocialMedia: String) {
        
        if UIApplication.shared.canOpenURL(URL(string: appSocialMedia)!) {
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(URL(string: appSocialMedia)!, options: [:])
            } else {
                //Fallback earlier versions
            }
        } else {
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(URL(string: linkSocialMedia)!, options: [:])
            } else {
                //Fallback earlier versions
            }
        }
    }
    
    private let supportEmail = EmailSender()
    func sendEmail(email: String, name: String){
        let body = """
            Hi \(name),
            
            I need help with:
            
            ---
            App Version: \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?")
            iOS: \(UIDevice.current.systemVersion)
            Device: \(UIDevice.current.model)
            ---
            """
        supportEmail.presentEmailSender(from: self, to: [email], subject: "MyEZ App Contact", body: body)
    }
    
    @IBAction func callUsAction(_ sender: UIButton) {
        if let url = URL(string: "tel://+18883445867"), UIApplication.shared.canOpenURL(url) {
            if #available(iOS 10, *) {
                UIApplication.shared.open(url)
            } else {
                UIApplication.shared.openURL(url)
            }
        }
    }
    
    @IBAction func goingToChat(_ sender: UIButton) {
        
        performSegue(withIdentifier: "goingToChat", sender: self)
    }
    
    override func viewDidLoad() {
        facebookButton.imageView?.contentMode = .scaleAspectFit
        instagramButton.imageView?.contentMode = .scaleAspectFit
        youtubeButton.imageView?.contentMode = .scaleAspectFit
        tiktokButton.imageView?.contentMode = .scaleAspectFit
    }
    
    @IBAction func contactCeoButton(_ sender: UIButton) {
        sendEmail(email: "eddie@ezinflatables.com", name: "Eddie")
    }
    
    @IBAction func contactCooButton(_ sender: UIButton) {
        sendEmail(email: "art@ezinflatables.com", name: "Art")
    }
    
    func alert(message: String, title: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let OKAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(OKAction)
        self.present(alertController, animated: true, completion: nil)
    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToUIApplicationOpenExternalURLOptionsKeyDictionary(_ input: [String: Any]) -> [UIApplication.OpenExternalURLOptionsKey: Any] {
    return Dictionary(uniqueKeysWithValues: input.map { key, value in (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value)})
}
