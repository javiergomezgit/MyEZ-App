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
        // FIXME: Incomplete sort comparator. The closure returns true only when $0 is ranked
        // and $1 is not, but never establishes ordering between two ranked entries or between
        // two unranked entries. Swift's sort requires a strict weak ordering; this comparator
        // violates that contract (e.g. compare(A,B) and compare(B,A) can both be false for two
        // ranked items, making the order undefined/unstable). Ranked items need to be sorted by
        // their weight value and unranked items should be grouped consistently.
        return response.clients.sorted {
                $0.rank_weight != "No Rank Yet" && $1.rank_weight == "No Rank Yet"
            }
    }
}
