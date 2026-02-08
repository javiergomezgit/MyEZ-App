//
//  DownloadMyezViewController.swift
//  MyEZ
//
//  Created by Javier Gomez on 9/6/18.
//  Copyright © 2018 JDev. All rights reserved.
//

import UIKit
import SCLAlertView
import FirebaseDatabase


class DownloadMyezViewController: UIViewController {
    
    @IBOutlet weak var imageMyez: UIImageView!
    @IBOutlet weak var manualButton: UIButton!
    @IBOutlet weak var filesButton: UIButton!
    
    var imageSelected = UIImage()
    var unitModelSelected = String()
    var linkPNG = String()
    var manualLink = String()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        manualButton.imageView?.contentMode = .scaleAspectFit
        filesButton.imageView?.contentMode = .scaleAspectFit
        
        imageMyez.image = imageSelected
        
        self.view.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        self.showAnimate()
        
        print (getLinkPNG())
    }
    
    func getLinkPNG() {
        var ref : DatabaseReference!
        
        ref = Database.database().reference()
        
        ref.child("downloadLinks").observeSingleEvent(of: .value) { (snapshot) in
            let value = snapshot.value as? NSDictionary
            
            self.manualLink = (value!["generalManual"] as? String)!
            
            print (self.manualLink)
        }
        
        ref.child("unitsLink").observeSingleEvent(of: .value, with: { (snapshot) in
            let value = snapshot.value as? NSDictionary
            
            print (snapshot)
            
            self.linkPNG = value![self.unitModelSelected] as? String ?? ""
        })
    }
    
    
    func showAnimate()
    {
        self.view.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
        self.view.alpha = 0.0;
        UIView.animate(withDuration: 0.25, animations: {
            self.view.alpha = 1.0
            self.view.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
        });
    }
    
    @IBAction func closePopUp(_ sender: AnyObject) {
        self.removeAnimate()
    }
    
    func removeAnimate()
    {
        UIView.animate(withDuration: 0.25, animations: {
            self.view.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
            self.view.alpha = 0.0;
        }, completion:{(finished : Bool)  in
            if (finished)
            {
                self.view.removeFromSuperview()
            }
        });
    }
    
    @IBAction func downloadFiles(_ sender: UIButton) {
        
        sendEmailGmail(subject: "Download \(unitModelSelected) png images", additionalBody: linkPNG)
    }
    
    @IBAction func downloadManual(_ sender: UIButton) {
        
        sendEmailGmail(subject: "Manual for EZ Inflatables", additionalBody: manualLink) //"https://view.publitas.com/47750/451346/pdfs/26eed7a804397175d1b4a020c39eedd6e7370273.pdf")
    }
    
    
    //TODO: Send email with attachments
    func sendEmailGmail(subject: String, additionalBody: String) {
//        
//        let smtpSession = MCOSMTPSession()
//        smtpSession.hostname = "smtp.gmail.com"
//        smtpSession.username = "no-reply@ez-inflatables.com"
//        smtpSession.password = "*3%8bUW=1"
//        smtpSession.port = 465
//        smtpSession.authType = MCOAuthType.saslPlain
//        smtpSession.connectionType = MCOConnectionType.TLS
//        smtpSession.connectionLogger = {(connectionID, type, data) in
//            if data != nil {
//                if let string = NSString(data: data!, encoding: String.Encoding.utf8.rawValue){
//                    NSLog("Connectionlogger: \(string)")
//                }
//            }
//        }
//        let builder = MCOMessageBuilder()
//        builder.header.to = [MCOAddress(displayName: userInformation.name, mailbox: userInformation.email)]
//        builder.header.from = MCOAddress(displayName: "EZ Inflatables, Inc.", mailbox: "no-reply@ez-inflatables.com")
//        builder.header.replyTo = [MCOAddress(displayName: "EZ Inflatables, Inc.", mailbox: "info@ezinflatables.com")]
//        builder.header.subject = subject
//        builder.htmlBody = "<h2>Thank you for being part of EZ Inflatables</h2> <br /> <p>Desktop view prefered</p> <a href = '\(additionalBody)'>Cick here to download your files."
//        
//        let rfc822Data = builder.data()
//        let sendOperation = smtpSession.sendOperation(with: rfc822Data)
//        sendOperation?.start { (error) -> Void in
//            let alert = SCLAlertView()
//            
//            if (error != nil) {
//                
//                //NSLog("Error sending email: \(error)")
//                alert.showInfo("Error", subTitle: "There was an error, try again later \(error.debugDescription)")
//            } else {
//                NSLog("Successfully sent email!")
//                alert.showSuccess("Sent", subTitle: "You should be receiving an email shortly, please check your spam folder")
//            }
//        }
    }
}
