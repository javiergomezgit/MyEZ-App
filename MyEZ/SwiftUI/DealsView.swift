//
//  DealsView.swift
//  MyEZ
//
//  Created by Javier Gomez on 3/9/26.
//  Copyright © 2026 JDev. All rights reserved.
//

//Temporal code for API calls
import SwiftUI

struct DealsView: View {
    
    @State private var clients: [Client] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        ZStack {
            AppColors.secondary.ignoresSafeArea()
            
            if isLoading {
                ProgressView("Loading...")
            } else if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .padding()
            } else {
                List(clients) { client in
                    VStack(alignment: .leading) {
                        Text(client.name)
                            .font(.headline)
                        Text(client.rank_weight)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                .scrollContentBackground(.hidden)
                .refreshable {
                    do {
                        clients = try await OdooService.shared.fetchRanking()
                    } catch {
                        errorMessage = "Failed to load clients. Please try again."
                    }
                }
            }
        }
        .navigationTitle("Deals")
        .task {
            do {
                clients = try await OdooService.shared.fetchRanking()
                isLoading = false
            } catch {
                errorMessage = "Failed to load clients. Please try again."
                isLoading = false
            }
        }
    }
}
