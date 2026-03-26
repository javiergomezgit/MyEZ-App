import SwiftUI

struct AuthFlowView: View {
    @ObservedObject var appState: AppState
    
    var body: some View {
        NavigationStack {
            GetStartedView(appState: appState)
        }
    }
}

struct GetStartedView: View {
    @ObservedObject var appState: AppState
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#0D1B2A"), Color(hex: "#1A1A2E")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 26) {
                Spacer(minLength: 36)

                VStack(spacing: 18) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.95), Color(hex: "D7E3F5")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 118, height: 118)
                            .overlay(
                                RoundedRectangle(cornerRadius: 28, style: .continuous)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                            .shadow(color: AppColors.sceneBlueGlow.opacity(0.2), radius: 16, x: 0, y: 10)

                        Image("logoLaunch")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 88, height: 88)
                    }

                    VStack(spacing: 10) {
                        Text("Welcome to MyEZ")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)

                        Text("Sign in or create an account to continue with the new MyEZ experience.")
                            .font(.system(size: 17))
                            .foregroundColor(.white.opacity(0.64))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                    }
                }

                VStack(spacing: 16) {
                    NavigationLink { LoginView(appState: appState) } label: {
                        Text("Sign In")
                            .font(.system(size: 18, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 58)
                            .background(
                                LinearGradient(
                                    colors: [Color(hex: "#2D8CFF"), Color(hex: "#1E63E9")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .shadow(color: Color(hex: "#2D8CFF").opacity(0.28), radius: 12, x: 0, y: 6)
                    }

                    NavigationLink { SignupView(appState: appState) } label: {
                        Text("Create Account")
                            .font(.system(size: 17, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(
                                LinearGradient(
                                    colors: [Color(hex: "#E8272B"), Color(hex: "#C0181C")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(Color.white.opacity(0.10), lineWidth: 1)
                            )
                            .shadow(color: Color(hex: "#E8272B").opacity(0.28), radius: 12, x: 0, y: 6)
                    }
                }

                VStack(spacing: 10) {
                    Text("Guest access is available if you just want to look around.")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.42))
                        .multilineTextAlignment(.center)

                    // FIXME: "Skip" lets any user bypass authentication entirely and access all
                    // protected content without credentials. If the app has any user-specific or
                    // privileged content, this is a security hole. At minimum, gate sensitive
                    // tabs/actions on a separate `isGuest` flag and prompt sign-in when needed.
                    Button("Skip") {
                        appState.markAuthenticated()
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white.opacity(0.65))
                }
                .padding(.top, 4)

                Spacer()
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 28)
            .sceneCard(cornerRadius: 30, fillColor: Color.white.opacity(0.05))
            .padding(.horizontal, 24)
        }
    }
}

struct LoginView: View {
    @ObservedObject var appState: AppState
    @StateObject private var viewModel = AuthViewModel()
    @State private var showPassword = false

    private var isShowingError: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { _ in viewModel.errorMessage = nil }
        )
    }

    private var headerSection: some View {
        VStack(spacing: 8) {
            Image("logo")
                .resizable()
                .scaledToFit()
                .frame(width: 72, height: 72)
                .padding(.top, 60)
                .padding(.bottom, 8)

            Text("Sign In to MyEZ")
                .font(.system(size: 26, weight: .semibold))
                .foregroundColor(.white)
                .padding(.top, 16)
        }
        .padding(.bottom, 32)
    }

    private var emailField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Email")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white.opacity(0.85))

            HStack(spacing: 12) {
                Image(systemName: "envelope")
                    .foregroundColor(.white.opacity(0.4))
                TextField("your@email.com", text: $viewModel.email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 16)
            .frame(height: 56)
            .background(Color.white.opacity(0.07))
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
        }
    }

    private var passwordField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Password")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white.opacity(0.85))

            HStack(spacing: 12) {
                Image(systemName: "lock")
                    .foregroundColor(.white.opacity(0.4))
                Group {
                    if showPassword {
                        TextField("Password", text: $viewModel.password)
                    } else {
                        SecureField("••••••••", text: $viewModel.password)
                    }
                }
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .foregroundColor(.white)

                Button {
                    showPassword.toggle()
                } label: {
                    Image(systemName: showPassword ? "eye.slash" : "eye")
                        .foregroundColor(.white.opacity(0.4))
                }
            }
            .padding(.horizontal, 16)
            .frame(height: 56)
            .background(Color.white.opacity(0.07))
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
        }
    }

    private var signInButton: some View {
        Button {
            viewModel.login(appState: appState)
        } label: {
            Text(viewModel.isLoading ? "Signing In..." : "Sign In")
                .font(.system(size: 18, weight: .bold))
                .frame(maxWidth: .infinity)
                .frame(height: 58)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "#2D8CFF"), Color(hex: "#1E63E9")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: Color(hex: "#2D8CFF").opacity(0.28), radius: 12, x: 0, y: 6)
        }
        .disabled(viewModel.isLoading)
        .padding(.top, 8)
    }

    private var formCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            emailField
            passwordField
            signInButton
        }
        .padding(24)
        .background(Color.white.opacity(0.05))
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white.opacity(0.07), lineWidth: 1)
        )
        .padding(.horizontal, 4)
    }

    private var footerSection: some View {
        VStack(spacing: 16) {
            NavigationLink {
                SignupView(appState: appState)
            } label: {
                HStack(spacing: 4) {
                    Text("Don't have an account?")
                        .foregroundColor(.white.opacity(0.6))
                    Text("Sign Up")
                        .foregroundColor(Color(hex: "#E8272B"))
                        .fontWeight(.semibold)
                }
                .font(.system(size: 15))
            }

            Button("Skip") {
                appState.markAuthenticated()
            }
            .font(.system(size: 14))
            .foregroundColor(.white.opacity(0.4))
        }
        .padding(.top, 24)
        .padding(.bottom, 40)
    }

    var body: some View {
        ZStack {
            // Dark gradient background
            LinearGradient(
                colors: [Color(hex: "#0D1B2A"), Color(hex: "#1A1A2E")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    headerSection
                    formCard
                    footerSection
                }
                .padding(.horizontal, 24)
            }
        }
        .alert("", isPresented: isShowingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct SignupView: View {
    @ObservedObject var appState: AppState
    @StateObject private var viewModel = AuthViewModel()
    @State private var showPassword = false
    @State private var showVerify = false

    private var isShowingError: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { _ in viewModel.errorMessage = nil }
        )
    }

    private var headerSection: some View {
        VStack(spacing: 8) {
            Image("logo")
                .resizable()
                .scaledToFit()
                .frame(width: 72, height: 72)
                .padding(.top, 10)
                .padding(.bottom, 8)

            Text("Create Account")
                .font(.system(size: 26, weight: .semibold))
                .foregroundColor(.white)
                .padding(.top, 16)
        }
        .padding(.bottom, 32)
    }

    private var fullNameField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Full Name")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white.opacity(0.85))

            HStack(spacing: 12) {
                Image(systemName: "person")
                    .foregroundColor(.white.opacity(0.4))
                TextField("John Doe", text: $viewModel.name)
                    .textInputAutocapitalization(.words)
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 16)
            .frame(height: 56)
            .background(Color.white.opacity(0.07))
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
        }
    }

    private var emailField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Email")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white.opacity(0.85))

            HStack(spacing: 12) {
                Image(systemName: "envelope")
                    .foregroundColor(.white.opacity(0.4))
                TextField("your@email.com", text: $viewModel.email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 16)
            .frame(height: 56)
            .background(Color.white.opacity(0.07))
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
        }
    }

    private var passwordField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Password")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white.opacity(0.85))

            HStack(spacing: 12) {
                Image(systemName: "lock")
                    .foregroundColor(.white.opacity(0.4))
                Group {
                    if showPassword {
                        TextField("Password", text: $viewModel.password)
                    } else {
                        SecureField("••••••••", text: $viewModel.password)
                    }
                }
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .foregroundColor(.white)

                Button {
                    showPassword.toggle()
                } label: {
                    Image(systemName: showPassword ? "eye.slash" : "eye")
                        .foregroundColor(.white.opacity(0.4))
                }
            }
            .padding(.horizontal, 16)
            .frame(height: 56)
            .background(Color.white.opacity(0.07))
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
        }
    }

    private var verifyPasswordField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Verify Password")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white.opacity(0.85))

            HStack(spacing: 12) {
                Image(systemName: "lock")
                    .foregroundColor(.white.opacity(0.4))
                Group {
                    if showVerify {
                        TextField("Verify Password", text: $viewModel.verifyPassword)
                    } else {
                        SecureField("••••••••", text: $viewModel.verifyPassword)
                    }
                }
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .foregroundColor(.white)

                Button {
                    showVerify.toggle()
                } label: {
                    Image(systemName: showVerify ? "eye.slash" : "eye")
                        .foregroundColor(.white.opacity(0.4))
                }
            }
            .padding(.horizontal, 16)
            .frame(height: 56)
            .background(Color.white.opacity(0.07))
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
        }
    }

    private var createAccountButton: some View {
        Button {
            viewModel.signup(appState: appState)
        } label: {
            Text(viewModel.isLoading ? "Creating..." : "Create Account")
                .font(.system(size: 18, weight: .bold))
                .frame(maxWidth: .infinity)
                .frame(height: 58)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "#E8272B"), Color(hex: "#C0181C")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: Color(hex: "#E8272B").opacity(0.28), radius: 12, x: 0, y: 6)
        }
        .disabled(viewModel.isLoading)
        .padding(.top, 8)
    }

    private var formCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            fullNameField
            emailField
            passwordField
            verifyPasswordField
            createAccountButton
        }
        .padding(24)
        .background(Color.white.opacity(0.05))
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white.opacity(0.07), lineWidth: 1)
        )
        .padding(.horizontal, 4)
    }

    private var footerSection: some View {
        VStack(spacing: 16) {
            NavigationLink {
                LoginView(appState: appState)
            } label: {
                HStack(spacing: 4) {
                    Text("Already have an account?")
                        .foregroundColor(.white.opacity(0.6))
                    Text("Sign In")
                        .foregroundColor(Color(hex: "#E8272B"))
                        .fontWeight(.semibold)
                }
                .font(.system(size: 15))
            }

            if let url = URL(string: "https://www.ezinflatables.com/pages/terms-and-conditions") {
                Link("Terms and Conditions", destination: url)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.4))
            }

            Button("Skip") {
                appState.markAuthenticated()
            }
            .font(.system(size: 14))
            .foregroundColor(.white.opacity(0.4))
        }
        .padding(.top, 24)
        .padding(.bottom, 40)
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#0D1B2A"), Color(hex: "#1A1A2E")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    headerSection
                    formCard
                    footerSection
                }
                .padding(.horizontal, 24)
            }
        }
        .alert("", isPresented: isShowingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}
