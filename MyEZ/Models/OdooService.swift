//
//  OdooService.swift
//  MyEZ
//
//  Created by Javier Gomez on 3/9/26.
//  Copyright © 2026 JDev. All rights reserved.
//

import Foundation

struct Client: Codable, Identifiable {
    let id: Int
    let name: String
    let rank_weight: String
}

struct ClientResponse: Codable {
    let clients: [Client]
}

class OdooService {
    static let shared = OdooService()
    private let baseURL = "https://myez-odoo-api-production-87b0.up.railway.app"
    
    func fetchRanking() async throws -> [Client] {
        let url = URL(string: "\(baseURL)/odoo/clients/ranking")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(ClientResponse.self, from: data)
        return response.clients.sorted {
                $0.rank_weight != "No Rank Yet" && $1.rank_weight == "No Rank Yet"
            }
    }
}
