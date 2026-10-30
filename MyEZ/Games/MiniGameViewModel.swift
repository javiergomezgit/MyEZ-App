import Foundation
import FirebaseDatabase

// Records finished games for the signed-in user. Guests (who skipped sign-in) can play,
// but nothing is saved for them.
final class MiniGameViewModel: ObservableObject {
    // PLACEHOLDER: the game's name isn't decided yet. Also used as the Firebase key.
    static let gameTitle = "To Be Decided"
    static let gameKey = "minigame"

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
        default:
            break
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
        dbRef.child("users").child(firebaseUID).child("gameScores").child(Self.gameKey)
            .childByAutoId()
            .setValue(entry) { [weak self] error, _ in
                DispatchQueue.main.async {
                    if let error = error {
                        print("❌ Failed to save game score: \(error.localizedDescription)")
                        self?.errorMessage = "Couldn't save your score."
                        return
                    }
                    print("✅ Saved game score \(score) (level \(level))")
                    self?.awardPoints(score: score)
                }
            }
    }

    // PLACEHOLDER: points strategy not decided. When it is, convert the score into EZ Points
    // here and write pointTransactions + the monthly leaderboard the way DealsView does.
    private func awardPoints(score: Int) {}

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
