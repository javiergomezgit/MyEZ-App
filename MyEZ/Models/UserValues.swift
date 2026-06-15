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
    var profileImageUrl: String
    var typeUser: String
    var weight: Int
    var subscribed: Bool
    var showWalk: Bool
}

struct OdooUser {
    let uid: Int //Save this to keep session alive
    let name: String
    let username: String // This is the email/login
    let partnerID: Int //Save thiss to fetch orders and other information
    let sessionID: String // The session cookie value
    let companyID: Int
}

struct AppUser: Codable {
    let uid: Int
    let partnerID: Int
    let name: String
    let email: String
    let typeUser: String
    // FIXME: Typo — should be `ownedWeight`. Rename here and everywhere it is used
    // (AuthService.saveLocally, AuthService.didFinishRegistration, UserSession encode/decode).
    let ownwedWeight: Int
    let companyID: Int
    var completedSigningUp: Bool
    var profileImageUrl: String?
}

// FIXME: Global mutable state shared across AuthService, ProfileViewModel, and view controllers.
// This makes thread safety, testability, and state tracking unpredictable.
// Should be owned by a single source of truth (e.g. a UserSession / AppState object) and
// injected where needed rather than mutated as a global variable.
var userInformation = UserValues(name: "", userId: "", email: "", zipCode: "", website: "", companyName: "", phone: "", businessType: "", about: "", profileImageUrl: "", typeUser: "", weight: 0, subscribed: false, showWalk: true)

struct UnitInfo {
    var skuUnit: String
    var imageUnit: NSData
    
    init(model: String, imageUnit: NSData) {
        self.skuUnit = model
        self.imageUnit = imageUnit
    }
}

// FIXME: Global mutable state — same problem as `userInformation` above.
var userUnits = [String:UnitInfo]()


struct UserExtraInfo {
    var completedSigningUp: Bool
    var myez = [String]()
}

// FIXME: Global mutable state — same problem as `userInformation` above.
var extraInfo = UserExtraInfo(completedSigningUp: false, myez : [""])


func checkTypeUser(weightUnits: Int) -> String {
    switch weightUnits {
    case 0..<1000:
        return "minimumweight"
    case 1000..<2000:
        return "flyweight"
    case 2000..<4000:
        return "bantamweight"
    case 4000..<6000:
        return "featherweight"
    case 6000..<9000:
        return "lightweight"
    case 9000..<13000:
        return "middleweight"
    default:
        return "heavyweight"
    }
}
