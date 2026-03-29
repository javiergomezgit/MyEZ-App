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
            SceneBackgroundView()

            VStack(spacing: 28) {
                Spacer(minLength: 40)

                ZStack {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(AppColors.surfacePrimary)
                        .frame(width: 92, height: 92)
                        .shadow(color: Color.black.opacity(0.05), radius: 12, x: 0, y: 6)

                    Image("logoLaunch")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 64, height: 64)
                }

                VStack(spacing: 10) {
                    Text("Welcome to MyEZ")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)

                    Text("Join the EZ family")
                        .font(.system(size: 19, weight: .medium))
                        .foregroundColor(AppColors.textSecondary)
                }

                VStack(spacing: 14) {
                    NavigationLink { LoginView(appState: appState) } label: {
                        authPrimaryButton(title: "Sign In", fill: AppColors.buttonBlueStart)
                    }

                    NavigationLink { SignupView(appState: appState) } label: {
                        authPrimaryButton(title: "Create Account", fill: AppColors.buttonRedStart)
                    }
                }

                Button("Skip") {
                    appState.markAuthenticated()
                }
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(AppColors.textMuted)

                Spacer()
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 24)
        }
    }

    private func authPrimaryButton(title: String, fill: Color) -> some View {
        Text(title)
            .font(.system(size: 18, weight: .bold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(fill)
            )
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

    var body: some View {
        authScaffold(
            title: "Sign In",
            subtitle: "Welcome back",
            footer: AnyView(
                VStack(spacing: 16) {
                    NavigationLink {
                        SignupView(appState: appState)
                    } label: {
                        HStack(spacing: 4) {
                            Text("Don't have an account?")
                                .foregroundColor(AppColors.textSecondary)
                            Text("Sign Up")
                                .foregroundColor(AppColors.accentRed)
                                .fontWeight(.semibold)
                        }
                        .font(.system(size: 15))
                    }

                    Button("Skip") {
                        appState.markAuthenticated()
                    }
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.textMuted)
                }
            )
        ) {
            VStack(alignment: .leading, spacing: 16) {
                authField(label: "Email", placeholder: "you@company.com", systemImage: "envelope", text: $viewModel.email, autocapitalization: .never, isSecure: false)
                authField(label: "Password", placeholder: "••••••••", systemImage: "lock", text: $viewModel.password, autocapitalization: .never, isSecure: !showPassword, toggle: {
                    showPassword.toggle()
                })

                Button {
                    viewModel.login(appState: appState)
                } label: {
                    Text(viewModel.isLoading ? "Signing In..." : "Sign In")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(AppColors.buttonBlueStart)
                        )
                }
                .disabled(viewModel.isLoading)
                .padding(.top, 6)
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

    var body: some View {
        authScaffold(
            title: "Create Account",
            subtitle: "Join the EZ family",
            footer: AnyView(
                VStack(spacing: 16) {
                    NavigationLink {
                        LoginView(appState: appState)
                    } label: {
                        HStack(spacing: 4) {
                            Text("Already have an account?")
                                .foregroundColor(AppColors.textSecondary)
                            Text("Sign In")
                                .foregroundColor(AppColors.accentRed)
                                .fontWeight(.semibold)
                        }
                        .font(.system(size: 15))
                    }

                    Button("Skip") {
                        appState.markAuthenticated()
                    }
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.textMuted)
                }
            )
        ) {
            VStack(alignment: .leading, spacing: 16) {
                authField(label: "Full Name", placeholder: "John Doe", systemImage: "person", text: $viewModel.name, autocapitalization: .words, isSecure: false)
                authField(label: "Email", placeholder: "you@company.com", systemImage: "envelope", text: $viewModel.email, autocapitalization: .never, isSecure: false)
                authField(label: "Password", placeholder: "••••••••", systemImage: "lock", text: $viewModel.password, autocapitalization: .never, isSecure: !showPassword, toggle: {
                    showPassword.toggle()
                })
                authField(label: "Verify Password", placeholder: "••••••••", systemImage: "lock", text: $viewModel.verifyPassword, autocapitalization: .never, isSecure: !showVerify, toggle: {
                    showVerify.toggle()
                })

                Button {
                    viewModel.signup(appState: appState)
                } label: {
                    Text(viewModel.isLoading ? "Creating..." : "Create Account")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(AppColors.buttonRedStart)
                        )
                }
                .disabled(viewModel.isLoading)
                .padding(.top, 6)
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

private func authScaffold<Content: View>(title: String, subtitle: String, footer: AnyView, @ViewBuilder content: () -> Content) -> some View {
    ZStack {
        SceneBackgroundView()

        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                Image("logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 72, height: 72)
                    .padding(.top, 18)

                VStack(spacing: 8) {
                    Text(title)
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)

                    Text(subtitle)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(AppColors.textSecondary)
                }

                VStack(alignment: .leading, spacing: 16) {
                    content()
                }

                footer
                    .padding(.top, 6)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
    }
}

private func authField(label: String, placeholder: String, systemImage: String, text: Binding<String>, autocapitalization: TextInputAutocapitalization, isSecure: Bool, toggle: (() -> Void)? = nil) -> some View {
    VStack(alignment: .leading, spacing: 8) {
        Text(label)
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(AppColors.textPrimary)

        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .foregroundColor(AppColors.textMuted)

            Group {
                if isSecure {
                    SecureField(placeholder, text: text)
                } else {
                    TextField(placeholder, text: text)
                }
            }
            .textInputAutocapitalization(autocapitalization)
            .autocorrectionDisabled()
            .foregroundColor(AppColors.textPrimary)

            if let toggle {
                Button(action: toggle) {
                    Image(systemName: isSecure ? "eye" : "eye.slash")
                        .foregroundColor(AppColors.textMuted)
                }
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 56)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppColors.surfacePrimary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(AppColors.borderSubtle, lineWidth: 1)
        )
    }
}
