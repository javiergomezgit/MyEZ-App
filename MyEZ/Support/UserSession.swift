//
//  UserSession.swift
//  MyEZ
//
//  Created by Javier Gomez on 2/12/26.
//  Copyright © 2026 JDev. All rights reserved.
//

import Foundation

class UserSession {
    // Singleton instance so you can access it anywhere like 'UserSession.shared'
    static let shared = UserSession()
    private let defaults = UserDefaults.standard
    private let key = "savedUserSession"
    
    private init() {}
    
    // MARK: - Save User
    func save(user: AppUser) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(user)
            defaults.set(data, forKey: key)
            print("💾 User saved locally!")
        } catch {
            print("❌ Failed to save user locally: \(error)")
        }
    }
    
    // MARK: - Load User
    func load() -> AppUser? {
        guard let data = defaults.data(forKey: key) else { return nil }
        
        do {
            let decoder = JSONDecoder()
            let user = try decoder.decode(AppUser.self, from: data)
            return user
        } catch {
            print("❌ Failed to load user: \(error)")
            return nil
        }
    }
    
    // MARK: - Delete (Logout)
    func clear() {
        defaults.removeObject(forKey: key)
        print("🗑️ User session cleared.")
    }
}
