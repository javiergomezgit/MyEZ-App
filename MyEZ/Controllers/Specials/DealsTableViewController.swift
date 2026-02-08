//
//  DealsTableViewController.swift
//  MyEZ
//
//  Created by Javier Gomez on 7/25/19.
//  Copyright © 2019 JDev. All rights reserved.
//

import UIKit
import Firebase
import SCLAlertView
import MessageUI


class DealsTableViewController: UIViewController {
    
    var deals : [Deals] = []
    var refreshControl: UIRefreshControl!
    
    @IBOutlet var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    
        refreshControl = UIRefreshControl()
        refreshControl.backgroundColor = UIColor.white
        refreshControl.tintColor = UIColor.lightGray
        
        tableView.addSubview(refreshControl)
   
        tableView.delegate = self
        tableView.dataSource = self
        
        print (deals)
        
        createArrayDeals()
        
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if refreshControl.isRefreshing {
            deals.removeAll()
            createArrayDeals()
            
        }
    }

    
    func createArrayDeals() {
        
        var tempDeal: [Deals] = []
       
        Database.database().reference().child("dealsLinks").observeSingleEvent(of: .value) { (snapshot) in
            
            let valueDeals = snapshot.value as? [String: Any]
            
            print (valueDeals)
//            print (valueDeals.keys)
//            print (valueDeals["Bounce N Slide"])

            for (key, url) in valueDeals! {
                
                print (key)
                print (url)
                var image = UIImage()
            
                if let newUrl = url as? String {
                    
                    let session = URLSession.shared
                    let url = URL(string: newUrl)!
                    
                    let task = session.dataTask(with: url) { data, response, error in
                     
                        if error != nil || data == nil {
                            print("Client error!")
                            return
                        } else {
                            
                            image = UIImage(data: data!)!
                            
                            let deal = Deals(image: image, title: key, url: newUrl)
                            self.deals.append(deal)
                        }
                        DispatchQueue.main.async {
                            self.tableView.reloadData()
                        }
                    }
                    task.resume()
                }
                
            }
        }
        
    }
}


extension DealsTableViewController: UITableViewDataSource, UITableViewDelegate {
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return deals.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if refreshControl.isRefreshing {
            refreshControl.endRefreshing()
        }
        
        let deal = deals[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "DealsCell") as! DealsCustomCell
        
        cell.setDeals(deal: deal)
        
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return view.frame.height / 2.2
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {

        return view.frame.height / 2.2
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        sendEmail(dealSelected: deals[indexPath.row].dealTitle)
    }
    
}


extension DealsTableViewController: MFMailComposeViewControllerDelegate { // MFMessageComposeViewControllerDelegate,  {
   
    func sendEmail(dealSelected: String) {
        
        if MFMailComposeViewController.canSendMail() {
            let mail = MFMailComposeViewController()
            
            mail.mailComposeDelegate = self as! MFMailComposeViewControllerDelegate
            mail.setToRecipients(["info@ezinflatables.com"])
            mail.setSubject("Deals from the App")
            mail.setMessageBody("<h1>Code Deal: \(dealSelected)</h1> <h3>Name: \(userInformation.name) <br /> UserID: \(userInformation.userId)</h3>", isHTML: true)
            
            self.present(mail, animated: true, completion: nil)
        } else {
            //show failure alert
            SCLAlertView().showError("Email app not configured", subTitle:"Send us an email to info@ezinflatables.com and give us this name: \n\(dealSelected)")
        }
    }
    
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
      
        switch (result){
        case MFMailComposeResult.cancelled:
            print("Mail cancelled");
            break;
        case MFMailComposeResult.saved:
            print("Mail saved");
            break;
        case MFMailComposeResult.sent:
            print("Mail sent");
            break;
        case MFMailComposeResult.failed:
            print("Mail sent failure: %@", error?.localizedDescription);
            break;
        default:
            break;
        }
        controller.dismiss(animated: true)
    }
    
    
}
