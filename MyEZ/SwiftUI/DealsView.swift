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
            SceneBackgroundView()
            
            if isLoading {
                ProgressView("Loading deals...")
                    .tint(.white)
                    .foregroundColor(.white)
            } else if let error = errorMessage {
                VStack(spacing: 14) {
                    Text("Unable to load deals")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                    Text(error)
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                    Button("Try Again") {
                        Task { await loadDeals() }
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background(Capsule().fill(AppColors.sceneBlue))
                    .foregroundColor(.white)
                }
                .padding(24)
                .sceneCard()
                .padding(.horizontal, 20)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Deals")
                                .font(.system(size: 30, weight: .bold))
                                .foregroundColor(.white)
                            Text("A profile-style leaderboard view for current client rankings.")
                                .font(.system(size: 15))
                                .foregroundColor(.white.opacity(0.55))
                        }

                        VStack(spacing: 12) {
                            ForEach(Array(clients.enumerated()), id: \.element.id) { index, client in
                                DealRow(client: client, rank: index + 1)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 100)
                }
                .refreshable {
                    await loadDeals()
                }
            }
        }
        .navigationTitle("Deals")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadDeals()
        }
    }

    private func loadDeals() async {
        do {
            clients = try await OdooService.shared.fetchRanking()
            errorMessage = nil
            isLoading = false
        } catch {
            errorMessage = "Failed to load clients. Please try again."
            isLoading = false
        }
    }
}

private struct DealRow: View {
    let client: Client
    let rank: Int

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [AppColors.sceneBlue.opacity(0.95), AppColors.primary.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 52, height: 52)
                Text("\(rank)")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(client.name)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                Text(client.rank_weight)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(AppColors.sceneBlueGlow)
            }

            Spacer()
        }
        .padding(18)
        .sceneCard()
    }
}
