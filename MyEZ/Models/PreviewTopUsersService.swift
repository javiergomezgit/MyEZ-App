//
//  PreviewTopUsersService.swift
//  MyEZ
//
//  Created by Javier on 3/6/26.
//

import Foundation
import FirebaseDatabase

final class PreviewTopUsersService {

    struct TopUserEntry {
        let userId: String
        let weight: Int
        var zipCode: String?
    }

    struct TopUsersSummary {
        let topUsers: [TopUserEntry]
        let currentUserRank: Int
        let currentUserWeight: Int
    }

    enum ServiceError: Error {
        case missingUserSession
        case malformedSnapshot
    }

    private let ref: DatabaseReference

    init(ref: DatabaseReference = Database.database().reference()) {
        self.ref = ref
    }

    // MARK: - Public API

    func updateAndGetTopUsers(completion: @escaping (Result<[TopUserEntry], Error>) -> Void) {
        guard let user = UserSession.shared.load() else {
            print("[TopUsers] Missing user session")
            DispatchQueue.main.async { completion(.failure(ServiceError.missingUserSession)) }
            return
        }

        let currentUserId = String(user.partnerID)
        let currentUserWeight = userInformation.weight

        print("[TopUsers] updateAndGetTopUsers currentUserId=\(currentUserId) weight=\(currentUserWeight)")
        updateAndGetTopUsers(currentUserId: currentUserId, currentUserWeight: currentUserWeight, completion: completion)
    }

    func updateAndGetTopUsers(currentUserId: String, currentUserWeight: Int, completion: @escaping (Result<[TopUserEntry], Error>) -> Void) {
        let topUsersRef = ref.child("topUsers")

        topUsersRef.observeSingleEvent(of: .value, with: { [weak self] snapshot in
            guard let self = self else { return }

            var values = snapshot.value as? [String: Any] ?? [:]
            values[currentUserId] = currentUserWeight
            print("[TopUsers] topUsers snapshot count=\(values.count)")

            topUsersRef.updateChildValues([currentUserId: currentUserWeight]) { error, _ in
                if let error = error {
                    print("[TopUsers] updateChildValues error: \(error.localizedDescription)")
                    DispatchQueue.main.async { completion(.failure(error)) }
                    return
                }

                let topUsers = self.populateTopUsers(from: values)
                print("[TopUsers] topUsers after sort: \(topUsers.map { "\($0.userId)=\($0.weight)" })")
                self.findZipCodes(for: topUsers, completion: completion)
            }
        }, withCancel: { error in
            print("[TopUsers] observeSingleEvent error: \(error.localizedDescription)")
            DispatchQueue.main.async { completion(.failure(error)) }
        })
    }

    func updateAndGetTopUsersSummary(completion: @escaping (Result<TopUsersSummary, Error>) -> Void) {
        guard let user = UserSession.shared.load() else {
            print("[TopUsers] Missing user session")
            DispatchQueue.main.async { completion(.failure(ServiceError.missingUserSession)) }
            return
        }

        let currentUserId = String(user.partnerID)
        fetchCurrentUserData(currentUserId: currentUserId) { [weak self] weight in
            guard let self = self else { return }
            let currentUserWeight = weight
            print("[TopUsers] updateAndGetTopUsersSummary currentUserId=\(currentUserId) weight=\(currentUserWeight)")
            self.updateAndGetTopUsersSummary(currentUserId: currentUserId, currentUserWeight: currentUserWeight, completion: completion)
        }
    }

    func updateAndGetTopUsersSummary(currentUserId: String, currentUserWeight: Int, completion: @escaping (Result<TopUsersSummary, Error>) -> Void) {
        let topUsersRef = ref.child("topUsers")

        topUsersRef.observeSingleEvent(of: .value, with: { [weak self] snapshot in
            guard let self = self else { return }

            var values = snapshot.value as? [String: Any] ?? [:]
            values[currentUserId] = currentUserWeight
            print("[TopUsers] summary snapshot count=\(values.count)")

            topUsersRef.updateChildValues([currentUserId: currentUserWeight]) { error, _ in
                if let error = error {
                    print("[TopUsers] summary updateChildValues error: \(error.localizedDescription)")
                    DispatchQueue.main.async { completion(.failure(error)) }
                    return
                }

                let sorted = self.populateAllUsers(from: values)
                let currentRank = (sorted.firstIndex { $0.userId == currentUserId } ?? 0) + 1
                let topUsers = Array(sorted.prefix(3))
                print("[TopUsers] summary currentRank=\(currentRank)")
                print("[TopUsers] summary topUsers: \(topUsers.map { "\($0.userId)=\($0.weight)" })")

                self.findZipCodes(for: topUsers) { result in
                    switch result {
                    case .success(let withZipCodes):
                        print("[TopUsers] summary zipCodes: \(withZipCodes.map { "\($0.userId)=\($0.zipCode ?? "nil")" })")
                        let summary = TopUsersSummary(
                            topUsers: withZipCodes,
                            currentUserRank: currentRank,
                            currentUserWeight: currentUserWeight
                        )
                        DispatchQueue.main.async { completion(.success(summary)) }
                    case .failure(let error):
                        DispatchQueue.main.async { completion(.failure(error)) }
                    }
                }
            }
        }, withCancel: { error in
            DispatchQueue.main.async { completion(.failure(error)) }
        })
    }

    func populateTopUsers(from values: [String: Any]) -> [TopUserEntry] {
        var users: [TopUserEntry] = []

        for (userId, rawWeight) in values {
            guard let weight = Self.intFromAny(rawWeight) else { continue }
            users.append(TopUserEntry(userId: userId, weight: weight, zipCode: nil))
        }

        users.sort { $0.weight > $1.weight }
        return Array(users.prefix(3))
    }

    func populateAllUsers(from values: [String: Any]) -> [TopUserEntry] {
        var users: [TopUserEntry] = []

        for (userId, rawWeight) in values {
            guard let weight = Self.intFromAny(rawWeight) else { continue }
            users.append(TopUserEntry(userId: userId, weight: weight, zipCode: nil))
        }

        users.sort { $0.weight > $1.weight }
        return users
    }

    func findZipCodes(for topUsers: [TopUserEntry], completion: @escaping (Result<[TopUserEntry], Error>) -> Void) {
        ref.child("users").observeSingleEvent(of: .value, with: { snapshot in
            guard let values = snapshot.value as? [String: Any] else {
                print("[TopUsers] users snapshot malformed")
                DispatchQueue.main.async { completion(.failure(ServiceError.malformedSnapshot)) }
                return
            }

            var updated: [TopUserEntry] = []
            updated.reserveCapacity(topUsers.count)

            for entry in topUsers {
                if let userValue = values[entry.userId] as? [String: Any] {
                    let zip = userValue["zipCode"] as? String
                    updated.append(TopUserEntry(userId: entry.userId, weight: entry.weight, zipCode: zip))
                    print("[TopUsers] zip for \(entry.userId)=\(zip ?? "nil")")
                } else {
                    print("[TopUsers] user not found for \(entry.userId)")
                    updated.append(entry)
                }
            }

            DispatchQueue.main.async { completion(.success(updated)) }
        }, withCancel: { error in
            print("[TopUsers] users observe error: \(error.localizedDescription)")
            DispatchQueue.main.async { completion(.failure(error)) }
        })
    }

    // MARK: - Helpers

    private static func intFromAny(_ value: Any) -> Int? {
        if let intValue = value as? Int { return intValue }
        if let doubleValue = value as? Double { return Int(doubleValue) }
        if let stringValue = value as? String { return Int(stringValue) }
        return nil
    }

    private func fetchCurrentUserData(currentUserId: String, completion: @escaping (Int) -> Void) {
        ref.child("users").child(currentUserId).observeSingleEvent(of: .value, with: { snapshot in
            let value = snapshot.value as? [String: Any]
            let weight = value?["owned_weight"] as? Int
                ?? value?["weightOwned"] as? Int
                ?? value?["weightOwned".lowercased()] as? Int
                ?? userInformation.weight
            let zip = value?["zipCode"] as? String
            userInformation.weight = weight
            if let zip = zip {
                userInformation.zipCode = zip
            }
            print("[TopUsers] fetched current user weight=\(weight) zip=\(zip ?? "nil")")
            DispatchQueue.main.async { completion(weight) }
        }, withCancel: { _ in
            print("[TopUsers] failed to fetch current user weight; using cached=\(userInformation.weight)")
            DispatchQueue.main.async { completion(userInformation.weight) }
        })
    }
}
