//
//  SupportEmailSender.swift
//  MyEZ
//
//  Created by Javier Gomez on 2/6/26.
//  Copyright © 2026 JDev. All rights reserved.
//

import MessageUI

final class EmailSender: NSObject, MFMailComposeViewControllerDelegate {
    
    func presentEmailSender(
        from vc: UIViewController,
        to recipients: [String],
        subject: String,
        body: String) {
            
            guard MFMailComposeViewController.canSendMail() else {
                vc.presentMailFallbackAlert()
                return
            }
            
            let mail = MFMailComposeViewController()
            mail.mailComposeDelegate = self
            mail.setToRecipients(recipients)
            mail.setSubject(subject)
            mail.setMessageBody(body, isHTML: false)
            
            vc.present(mail, animated: true)
        }
    
    func mailComposeController(_ controller: MFMailComposeViewController,
                               didFinishWith result: MFMailComposeResult,
                               error: Error?) {
        controller.dismiss(animated: true)
    }
}

private extension UIViewController {
    func presentMailFallbackAlert() {
        let alert = UIAlertController(
            title: "Mail Not Configured",
            message: "Please add a Mail account on this device, or contact us at javier@ezinflatables.com",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
