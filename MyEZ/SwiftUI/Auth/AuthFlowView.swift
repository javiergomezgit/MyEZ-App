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
            AppColors.dark.ignoresSafeArea()
            VStack(spacing: 24) {
                Spacer()
                Image("logoLaunch")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 96, height: 96)
                    .padding(12)
                    .background(AppColors.light)
                    .cornerRadius(12)
                Text("Welcome to MyEZ")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                Text("Sign in or create an account to continue")
                    .font(.system(size: 17))
                    .foregroundColor(AppColors.light.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                NavigationLink { LoginView(appState: appState) } label: {
                    Text("Sign In")
                        .font(.system(size: 18, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(AppColors.primary)
                        .foregroundColor(.white)
                        .cornerRadius(18)
                }
                NavigationLink { SignupView(appState: appState) } label: {
                    Text("Create Account")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(AppColors.light.opacity(0.08))
                        .foregroundColor(.white)
                        .cornerRadius(16)
                }
                // FIXME: "Skip" lets any user bypass authentication entirely and access all
                // protected content without credentials. If the app has any user-specific or
                // privileged content, this is a security hole. At minimum, gate sensitive
                // tabs/actions on a separate `isGuest` flag and prompt sign-in when needed.
                Button("Skip") {
                    appState.markAuthenticated()
                }
                .foregroundColor(AppColors.light.opacity(0.6))
                Spacer()
            }
            .padding(.horizontal, 28)
        }
    }
}

struct LoginView: View {
    @ObservedObject var appState: AppState
    @StateObject private var viewModel = AuthViewModel()
    @State private var showPassword = false
    
    var body: some View {
        ZStack {
            AppColors.dark.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 14) {
                    Image("logoLaunch")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 96, height: 96)
                        .padding(12)
                        .background(AppColors.light)
                        .cornerRadius(12)
                        .padding(.top, 20)
                    Text("Welcome Back")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(.white)
                    Text("Sign in to your MyEZ account")
                        .font(.system(size: 17))
                        .foregroundColor(AppColors.light.opacity(0.7))
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Email")
                            .font(.system(size: 15))
                            .foregroundColor(AppColors.light.opacity(0.6))
                        TextField("name@email.com", text: $viewModel.email)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .padding(.horizontal, 16)
                            .frame(height: 56)
                            .background(AppColors.light.opacity(0.08))
                            .cornerRadius(18)
                            .foregroundColor(.white)
                        Text("Password")
                            .font(.system(size: 15))
                            .foregroundColor(AppColors.light.opacity(0.6))
                        HStack {
                            Group {
                                if showPassword {
                                    TextField("Password", text: $viewModel.password)
                                } else {
                                    SecureField("Password", text: $viewModel.password)
                                        .foregroundColor(.white)
                                }
                            }
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            Button {
                                showPassword.toggle()
                            } label: {
                                Image(systemName: showPassword ? "eye.slash" : "eye")
                                    .foregroundColor(AppColors.light.opacity(0.7))
                            }
                        }
                        .padding(.horizontal, 16)
                        .frame(height: 56)
                        .background(AppColors.light.opacity(0.08))
                        .cornerRadius(18)
                    }
                    .padding(.top, 12)
                    Button {
                        viewModel.login(appState: appState)
                    } label: {
                        Text(viewModel.isLoading ? "Signing In..." : "Sign In")
                            .font(.system(size: 18, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 60)
                            .background(AppColors.primary)
                            .foregroundColor(.white)
                            .cornerRadius(20)
                    }
                    .disabled(viewModel.isLoading)
                    Button("Forgot Password?") {
                        viewModel.sendPasswordReset()
                    }
                    .foregroundColor(AppColors.light.opacity(0.7))
                    NavigationLink {
                        SignupView(appState: appState)
                    } label: {
                        HStack(spacing: 6) {
                            Text("Don't have an account?")
                                .foregroundColor(AppColors.light.opacity(0.65))
                            Text("Sign Up")
                                .foregroundColor(AppColors.primary)
                                .fontWeight(.semibold)
                        }
                        .font(.system(size: 15))
                    }
                    Spacer()
                    // FIXME: Same auth-bypass issue as in GetStartedView — see comment there.
                    Button("Skip") {
                        appState.markAuthenticated()
                    }
                    .foregroundColor(AppColors.light.opacity(0.6))
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 40)
            }
        }
        .alert("", isPresented: Binding(get: { viewModel.errorMessage != nil }, set: { _ in viewModel.errorMessage = nil })) {
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
    
    var body: some View {
        ZStack {
            AppColors.dark.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 14) {
                    Text("Create Account")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.top, 20)
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Name")
                            .font(.system(size: 15))
                            .foregroundColor(AppColors.light.opacity(0.6))
                        TextField("Your name", text: $viewModel.name)
                            .textInputAutocapitalization(.words)
                            .padding(.horizontal, 16)
                            .frame(height: 56)
                            .background(AppColors.light.opacity(0.08))
                            .cornerRadius(18)
                            .foregroundColor(.white)
                        Text("Email")
                            .font(.system(size: 15))
                            .foregroundColor(AppColors.light.opacity(0.6))
                        TextField("name@email.com", text: $viewModel.email)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .padding(.horizontal, 16)
                            .frame(height: 56)
                            .background(AppColors.light.opacity(0.08))
                            .cornerRadius(18)
                            .foregroundColor(.white)
                        Text("Password")
                            .font(.system(size: 15))
                            .foregroundColor(AppColors.light.opacity(0.6))
                        HStack {
                            Group {
                                if showPassword {
                                    TextField("Password", text: $viewModel.password)
                                } else {
                                    SecureField("Password", text: $viewModel.password)
                                        .foregroundColor(.white)
                                }
                            }
                            Button {
                                showPassword.toggle()
                            } label: {
                                Image(systemName: showPassword ? "eye.slash" : "eye")
                                    .foregroundColor(AppColors.light.opacity(0.7))
                            }
                        }
                        .padding(.horizontal, 16)
                        .frame(height: 56)
                        .background(AppColors.light.opacity(0.08))
                        .cornerRadius(18)
                        Text("Verify Password")
                            .font(.system(size: 15))
                            .foregroundColor(AppColors.light.opacity(0.6))
                        HStack {
                            Group {
                                if showVerify {
                                    TextField("Verify Password", text: $viewModel.verifyPassword)
                                } else {
                                    SecureField("Verify Password", text: $viewModel.verifyPassword)
                                        .foregroundColor(.white)
                                }
                            }
                            Button {
                                showVerify.toggle()
                            } label: {
                                Image(systemName: showVerify ? "eye.slash" : "eye")
                                    .foregroundColor(AppColors.light.opacity(0.7))
                            }
                        }
                        .padding(.horizontal, 16)
                        .frame(height: 56)
                        .background(AppColors.light.opacity(0.08))
                        .cornerRadius(18)
                    }
                    .padding(.top, 12)
                    Button {
                        viewModel.signup(appState: appState)
                    } label: {
                        Text(viewModel.isLoading ? "Creating..." : "Create Account")
                            .font(.system(size: 18, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 60)
                            .background(AppColors.primary)
                            .foregroundColor(.white)
                            .cornerRadius(20)
                    }
                    .disabled(viewModel.isLoading)
                    // FIXME: Force-unwrapping a URL literal. While this particular string is
                    // currently valid, a typo or domain change will crash at runtime. Use
                    // `if let url = URL(string: ...)` or a static constant instead.
                    Link("Terms and Conditions", destination: URL(string: "https://www.ezinflatables.com/pages/terms-and-conditions")!)
                        .foregroundColor(AppColors.light.opacity(0.7))
                    Spacer()
                    // FIXME: Same auth-bypass issue as in GetStartedView — see comment there.
                    Button("Skip") {
                        appState.markAuthenticated()
                    }
                    .foregroundColor(AppColors.light.opacity(0.6))
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 40)
            }
        }
        .alert("", isPresented: Binding(get: { viewModel.errorMessage != nil }, set: { _ in viewModel.errorMessage = nil })) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}
