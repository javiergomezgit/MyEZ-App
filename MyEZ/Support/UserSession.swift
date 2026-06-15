//
//  UserSession.swift
//  MyEZ
//
//  Created by Javier Gomez on 2/12/26.
//  Copyright © 2026 JDev. All rights reserved.
//

import Foundation

class UserSession {
    static let shared = UserSession()
    private let defaults = UserDefaults.standard
    private let key = "savedUserSession"

    private init() {}

    func save(user: AppUser) {
        do {
            let data = try JSONEncoder().encode(user)
            defaults.set(data, forKey: key)
        } catch {
            print("❌ Failed to save user locally: \(error)")
        }
    }

    func load() -> AppUser? {
        guard let data = defaults.data(forKey: key) else { return nil }
        do {
            return try JSONDecoder().decode(AppUser.self, from: data)
        } catch {
            print("❌ Failed to load user: \(error)")
            return nil
        }
    }

    func clear() {
        defaults.removeObject(forKey: key)
    }
}
