//
//  UserValues.swift
//  MyEZ
//
//  Created by Javier Gomez on 10/15/17.
//  Copyright © 2017 JDev. All rights reserved.
//

import Foundation
import Firebase


struct UserValues {
    
    var name: String
    var userId: String
    var email: String
    var zipCode: String
    var website: String
    var companyName: String
    var phone: String
    var businessType: String
    var about: String
    var myProfileImage: NSData
    var typeUser: String
    var weight: String
    var subscribed: Bool
    var showWalk: Bool
    var idShopify: String
    
    //    var token: String
    //    var username: String
    //    var userTokenAmount: Int
    //    var usercountry: String
    //    var userstate: String
    //    var userAvatarId: String
    //    var userActiveTripsJSON = [Any]()
    //    var userActiveTrips: Int
    //    var userInactiveTrip: Int
    //    var usersRanks = [String:Any]()
    //    var usersRanksInactive = [String:Any]()
    //    var userInactiveTrips = [String:[String:UIImage]]()
    //    var imageTrips = [String:UIImage]()
    //    var imageTripsResized = [String:[String:UIImage]]()
    //    var totalGames: Int
    //    var currentTripId: String
    //    var finalScore: Int
    //    var bestScore: Int
    //    var practiceOrNot: Bool
    
}

struct OdooUser {
    let uid: Int //Save this to keep session alive
    let name: String
    let username: String // This is the email/login
    let partnerID: Int //Save thiss to fetch orders and other information
    let sessionID: String // The session cookie value
    let companyID: Int
}

var userInformation = UserValues(name: "", userId: "", email: "", zipCode: "", website: "", companyName: "", phone: "", businessType: "", about: "", myProfileImage: NSData(), typeUser: "", weight: "", subscribed: false, showWalk: true, idShopify: "")


struct UnitInfo {
    var model: String
    var imageUnit: NSData
    
    init(model: String, imageUnit: NSData) {
        self.model = model
        self.imageUnit = imageUnit
    }
}

var userUnits = [String:UnitInfo]()


struct UserExtraInfo {
    var completedSigningUp: Bool
    var myez = [String]()
}

var extraInfo = UserExtraInfo(completedSigningUp: false, myez : [""])

//
//struct TopUsers {
//
//    var weightUser = Int?
//    var zipCodeUser = String?
//
//    init(weightUser: Int?, zipCodeUser: String?) {
//        self.weightUser = weightUser
//        self.zipCodeUser = zipCodeUser
//    }
//}

var topUsers = [Int:String]()


func checkTypeUser(weightUnits: Int) -> String {
    
    var typeUser = ""
    
    switch weightUnits {
        case 0..<2500:
            typeUser = "minimumweight"
        case 2500..<5000:
            typeUser = "flyweight"
        case 5000..<7500:
            typeUser = "bantamweight"
        case 7500..<10000:
            typeUser = "featherweight"
        case 10000..<12500:
            typeUser = "lightweight"
        case 12500..<15001:
            typeUser = "welterweight"
        case 15001..<17500:
            typeUser = "middleweight"
        case 17500..<20000:
            typeUser = "cruiserweight"
        default:
            typeUser = "heavyweight"
    }
    
    return typeUser
}
