//
//  PreviewTopUsersViewController.swift
//  MyEZ
//
//  Created by Javier Gomez on 1/29/19.
//  Copyright © 2019 JDev. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth

class TopUser {
    let idTop : String!
    let weight : Int!
    
    init(idTop: String, weight: Int) {
        self.idTop = idTop
        self.weight = weight
    }
}



class PreviewTopUsersViewController: UIViewController {

    var ref : DatabaseReference!
    var topUsers : [TopUser] = []
    var zipCode : [String] = []

    
    @IBOutlet weak var firstTopUserLabel: UILabel!
    @IBOutlet weak var secondTopUserLabel: UILabel!
    @IBOutlet weak var thirdTopUserLabel: UILabel!
    
    @IBOutlet weak var firstWeightLabel: UILabel!
    @IBOutlet weak var secondWeightLabel: UILabel!
    @IBOutlet weak var thirdWeightLabel: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ref = Database.database().reference()
        
        updateTopUsers()
    }
                                                
    func updateTopUsers() {
        
        ref.child("topUsers").observeSingleEvent(of: .value, with: { (snapshot) in
            
            var values = snapshot.value as! [String : Any]
            let myId = Auth.auth().currentUser!.uid
            
            values.updateValue(Int(userInformation.weight), forKey: myId)
            
            for value in values {
                self.topUsers.append(TopUser(idTop: value.key, weight: value.value as! Int))
            }
            
            //sorting bigger weight to smaller
            self.topUsers.sort(by: { $0.weight > $1.weight })

            let topFiveUsers = self.topUsers[0..<5]

            
            for topUser in self.topUsers {
                let id: String = topUser.idTop
                let weight: Int = topUser.weight
                
                self.ref.child("topUsers").updateChildValues([id : weight])
            }
            
            self.findZipCodes()
            
            
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    func findZipCodes() {
        
        ref.child("users").observeSingleEvent(of: .value) { (snapshot) in
            
            let values = snapshot.value as! [String: Any]
            
            for value in 0..<3 {
                let userValue = values[self.topUsers[value].idTop] as! [String: Any]
                let userZipCode = userValue["zipCode"] as! String
                self.zipCode.append(userZipCode)
            }
            
            print (self.zipCode)
            self.populateTopUsers()
        }
    }
    
    
    func populateTopUsers() {
        
        let topFiveUsers = self.topUsers[0..<3]
        
        for (index, topFiveUser) in topFiveUsers.enumerated() {
           
            switch index {
            case 0:
                self.firstTopUserLabel.textAlignment = .center
                self.firstTopUserLabel.numberOfLines = 0
                self.firstTopUserLabel.text = String(topFiveUser.weight) + " Lbs"
                self.firstWeightLabel.text = self.zipCode[0]
                //self.firstWeightLabel.text = String(checkTypeUser(weightUnits: topFiveUser.weight)).uppercased()
            case 1:
                self.secondTopUserLabel.text = String(topFiveUser.weight) + " Lbs"
                self.secondWeightLabel.text = self.zipCode[1]
                //self.secondWeightLabel.text = String(checkTypeUser(weightUnits: topFiveUser.weight)).uppercased()
            case 2:
                self.thirdTopUserLabel.text = String(topFiveUser.weight) + " Lbs"
                self.thirdWeightLabel.text = self.zipCode[2]
                //self.thirdWeightLabel.text = String(checkTypeUser(weightUnits: topFiveUser.weight)).uppercased()
            default:
                print ("nothing")
            }
        }
    }
    
}
