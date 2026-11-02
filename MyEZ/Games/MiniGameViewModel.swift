import Foundation
import FirebaseDatabase
import UIKit

// Records finished games for the signed-in user. Guests (who skipped sign-in) can play,
// but nothing is saved for them.
final class MiniGameViewModel: ObservableObject {
    // PLACEHOLDER: the game's name isn't decided yet. Also used as the Firebase key.
    static let gameTitle = "To Be Decided"
    static let gameKey = "minigame"
    // Every 10 game points earn 1 EZ Point. Keep in sync with GAME_POINTS_PER_EZ_POINT in minigame.html.
    static let gamePointsPerEZPoint = 10

    @Published var errorMessage: String?
    // EZ Points for the last finished game, sent back to the results card. A new id per game.
    @Published var award: GameAward?

    struct GameAward: Equatable {
        let id = UUID()
        let ezPoints: Int
        let signedIn: Bool
    }

    private lazy var dbRef: DatabaseReference = Database.database().reference()

    private var firebaseUID: String {
        UserDefaults.standard.string(forKey: "firebaseUID") ?? ""
    }

    private var isSignedIn: Bool {
        UserSession.shared.load() != nil && !firebaseUID.isEmpty
    }

    // MARK: - Messages from the game

    func handle(message: [String: Any]) {
        guard let type = message["type"] as? String else { return }
        switch type {
        case "gameOver":
            let score = intFromAny(message["score"])
            let level = intFromAny(message["level"])
            recordGame(score: score, level: level)
        case "haptic":
            playHaptic(message["style"] as? String ?? "light")
        default:
            break
        }
    }

    // MARK: - Haptics

    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
    private let notification = UINotificationFeedbackGenerator()

    private func playHaptic(_ style: String) {
        switch style {
        case "medium": mediumImpact.impactOccurred()
        case "heavy": heavyImpact.impactOccurred()
        case "success": notification.notificationOccurred(.success)
        case "error": notification.notificationOccurred(.error)
        default:
            lightImpact.impactOccurred()
            lightImpact.prepare()
        }
    }

    // MARK: - Firebase

    // Only the part of a score above this month's best on the level earns EZ Points, so replaying
    // can't farm them: a level's EZ Points for the month add up to floor(best / 10).
    // Keep in sync with ezPointsFor in minigame.html.
    static func ezPoints(for score: Int, previousBest: Int) -> Int {
        max(0, score / gamePointsPerEZPoint - previousBest / gamePointsPerEZPoint)
    }

    // users/{uid}/gameScores/{gameKey}/{autoId} = { score, level, playedAt }
    private func recordGame(score: Int, level: Int) {
        guard isSignedIn else {
            print("⚠️ Game finished as a guest; score not saved")
            award = GameAward(ezPoints: 0, signedIn: false)
            return
        }
        let scoresRef = dbRef.child("users").child(firebaseUID).child("gameScores").child(Self.gameKey)

        // Read this month's best for the level before saving, so the new game isn't compared with itself
        scoresRef.observeSingleEvent(of: .value, with: { [weak self] snapshot in
            guard let self = self else { return }
            let previousBest = self.monthBest(in: snapshot.value as? [String: Any] ?? [:], level: level)
            let entry: [String: Any] = [
                "score": score,
                "level": level,
                "playedAt": Int(Date().timeIntervalSince1970)
            ]
            let gameRef = scoresRef.childByAutoId()
            gameRef.setValue(entry) { [weak self] error, _ in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    if let error = error {
                        print("❌ Failed to save game score: \(error.localizedDescription)")
                        self.errorMessage = "Couldn't save your score."
                        self.award = GameAward(ezPoints: 0, signedIn: true)
                        return
                    }
                    print("✅ Saved game score \(score) (level \(level), month best was \(previousBest))")
                    let ezPoints = Self.ezPoints(for: score, previousBest: previousBest)
                    self.award = GameAward(ezPoints: ezPoints, signedIn: true)
                    self.awardPoints(ezPoints, score: score, gameID: gameRef.key ?? UUID().uuidString)
                }
            }
        }) { [weak self] error in
            print("❌ Failed to read game scores: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self?.errorMessage = "Couldn't save your score."
                self?.award = GameAward(ezPoints: 0, signedIn: true)
            }
        }
    }

    // Best score on the level among games played this calendar month (device time, like the leaderboard key)
    private func monthBest(in games: [String: Any], level: Int) -> Int {
        guard let monthStart = Calendar.current.dateInterval(of: .month, for: Date())?.start else { return 0 }
        let since = Int(monthStart.timeIntervalSince1970)
        return games.values.compactMap { value -> Int? in
            guard let dict = value as? [String: Any],
                  intFromAny(dict["level"]) == level,
                  intFromAny(dict["playedAt"]) >= since else { return nil }
            return intFromAny(dict["score"])
        }.max() ?? 0
    }

    // Records the EZ Points: a pointTransactions entry plus the monthly leaderboard, the same
    // records DealsView writes for a points deal.
    private func awardPoints(_ ezPoints: Int, score: Int, gameID: String) {
        guard ezPoints > 0 else { return }

        let transaction: [String: Any] = [
            "doneDate": Date().timeIntervalSince1970,
            "score": ezPoints,
            "type": Self.gameKey
        ]
        dbRef.child("users").child(firebaseUID).child("pointTransactions").child("game_\(gameID)")
            .setValue(transaction) { [weak self] error, _ in
                guard let self = self else { return }
                if let error = error {
                    print("❌ Failed to award game points: \(error.localizedDescription)")
                    DispatchQueue.main.async { self.errorMessage = "Couldn't add your EZ Points." }
                    return
                }

                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM"
                let monthKey = formatter.string(from: Date())
                self.dbRef.child("leaderboards").child(monthKey).child(self.firebaseUID).child("score")
                    .setValue(ServerValue.increment(NSNumber(value: ezPoints)))
                print("✅ Awarded \(ezPoints) EZ Points for game score \(score)")
            }
    }

    private func intFromAny(_ value: Any?) -> Int {
        switch value {
        case let int as Int: return int
        case let double as Double: return Int(double)
        case let number as NSNumber: return number.intValue
        case let string as String: return Int(string) ?? 0
        default: return 0
        }
    }
}
