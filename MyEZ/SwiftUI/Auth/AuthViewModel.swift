import Foundation
import FirebaseAuth

final class AuthViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var name = ""
    @Published var verifyPassword = ""
    @Published var isLoading = false
    @Published var errorMessage: String?

    func login(appState: AppState) {
        let emailTrimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !emailTrimmed.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter email and password."
            return
        }
        isLoading = true
        AuthService.shared.signIn(email: emailTrimmed, password: password) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success:
                    appState.markAuthenticated()
                    let token = AppDelegate.deviceIDToken
                    if !token.isEmpty, let uid = Auth.auth().currentUser?.uid {
                        AuthService.shared.updateFCMToken(firebaseUID: uid, token: token)
                        self?.registerFCMToken(firebaseUID: uid, token: token)
                    }
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }

    func sendPasswordReset() {
        let emailTrimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !emailTrimmed.isEmpty else {
            errorMessage = "Please enter your email."
            return
        }
        AuthService.shared.sendPasswordReset(email: emailTrimmed) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self?.errorMessage = "Check your email for more details"
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }

    func signup(appState: AppState) {
        let emailTrimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, !emailTrimmed.isEmpty, !password.isEmpty, !verifyPassword.isEmpty else {
            errorMessage = "Please fill in all fields."
            return
        }
        guard password == verifyPassword else {
            errorMessage = "Passwords not matching, try again."
            return
        }
        guard isValidEmail(emailTrimmed) else {
            errorMessage = "Please enter a valid email address."
            return
        }
        isLoading = true
        AuthService.shared.registerUser(name: name, email: emailTrimmed, password: password) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success:
                    appState.markAuthenticated()
                    let token = AppDelegate.deviceIDToken
                    if !token.isEmpty, let uid = Auth.auth().currentUser?.uid {
                        AuthService.shared.updateFCMToken(firebaseUID: uid, token: token)
                        self?.registerFCMToken(firebaseUID: uid, token: token)
                    }
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func registerFCMToken(firebaseUID: String, token: String) {
        let urlString = "https://myez-odooapi-production.up.railway.app/register-token?firebase_uid=\(firebaseUID)&token=\(token)"
        guard let url = URL(string: urlString) else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        URLSession.shared.dataTask(with: request) { _, _, error in
            if let error = error {
                print("❌ FCM token registration failed: \(error)")
                return
            }
            print("✅ FCM token registered for \(firebaseUID)")
        }.resume()
    }

    private func isValidEmail(_ email: String) -> Bool {
        return email.contains("@") && email.contains(".") && email.count >= 6
    }
}
