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

    // users/{uid}/gameScores/{gameKey}/{autoId} = { score, level, playedAt }
    private func recordGame(score: Int, level: Int) {
        guard isSignedIn else {
            print("⚠️ Game finished as a guest; score not saved")
            return
        }
        let entry: [String: Any] = [
            "score": score,
            "level": level,
            "playedAt": Int(Date().timeIntervalSince1970)
        ]
        let gameRef = dbRef.child("users").child(firebaseUID).child("gameScores").child(Self.gameKey)
            .childByAutoId()
        gameRef.setValue(entry) { [weak self] error, _ in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Failed to save game score: \(error.localizedDescription)")
                    self?.errorMessage = "Couldn't save your score."
                    return
                }
                print("✅ Saved game score \(score) (level \(level))")
                self?.awardPoints(score: score, gameID: gameRef.key ?? UUID().uuidString)
            }
        }
    }

    // Converts the game score into EZ Points: a pointTransactions entry plus the monthly
    // leaderboard, the same records DealsView writes for a points deal. Leftover game points
    // (score % 10) are dropped.
    private func awardPoints(score: Int, gameID: String) {
        let ezPoints = score / Self.gamePointsPerEZPoint
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
