import SwiftUI
import YPImagePicker

struct ProfileView: View {
    @ObservedObject var appState: AppState
    @StateObject private var viewModel = ProfileViewModel()
    @State private var showingImagePicker = false
    @State private var showingMail = false
    @State private var showingOrders = false
    @State private var showingSafariURL: IdentifiableURL?
    
    var body: some View {
        ZStack {
            AppColors.dark.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    header
                    
                    profileCard
                    
                    sectionHeader("Account")
                    ProfileRow(
                        icon: "clock",
                        title: "Order History",
                        action: { showingOrders = true },
                        isEnabled: viewModel.user != nil
                    )
                    ProfileRow(
                        icon: "mappin.and.ellipse",
                        title: "Addresses",
                        action: { },
                        isEnabled: viewModel.user != nil
                    )
                    
                    sectionHeader("Privacy and Security")
                    ProfileRow(
                        icon: "doc.text",
                        title: "Terms & Conditions",
                        action: {
                            if let url = URL(string: "https://www.ezinflatables.com/pages/terms-and-conditions") {
                                showingSafariURL = IdentifiableURL(url: url)
                            }
                        },
                        isEnabled: true
                    )
                    ProfileRow(
                        icon: "shield",
                        title: "Privacy",
                        action: {
                            if let url = URL(string: "https://www.ezinflatables.com/pages/privacy-policy") {
                                showingSafariURL = IdentifiableURL(url: url)
                            }
                        },
                        isEnabled: true
                    )
                    
                    sectionHeader("Notifications")
                    ProfileToggleRow(
                        icon: "bell",
                        title: "Deals in your email",
                        isOn: Binding(get: {
                            viewModel.isSubscribed
                        }, set: { newValue in
                            viewModel.updateSubscription(isOn: newValue)
                        }),
                        isEnabled: viewModel.user != nil
                    )
                    
                    sectionHeader("Support")
                    ProfileRow(
                        icon: "questionmark.circle",
                        title: "Help Center",
                        action: { showingMail = true },
                        isEnabled: true
                    )
                    
                    Spacer(minLength: 30)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 100)
            }
        }
        .onAppear { viewModel.refresh() }
        .sheet(isPresented: $showingOrders) {
            if let url = URL(string: "https://ezinflatables.odoo.com/my/orders") {
                NavigationStack {
                    AuthenticatedBrowserView(url: url, title: "Order History", injectShopCSS: true, showNavButtons: true)
                        .navigationTitle("Order History")
                        .navigationBarTitleDisplayMode(.inline)
                }
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ProfileImagePicker { image in
                viewModel.updateProfileImage(newImage: image)
            }
        }
        .sheet(item: $showingSafariURL) { item in
            SafariView(url: item.url)
        }
        .alert("", isPresented: Binding(get: { viewModel.errorMessage != nil }, set: { _ in viewModel.errorMessage = nil })) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .onChange(of: showingMail) { isShowing in
            guard isShowing else { return }
            presentingMail()
            showingMail = false
        }
    }
    
    private var profileImageView: some View {
        Group {
            if let image = viewModel.profileImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else if let urlString = viewModel.user?.profileImageUrl, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image.resizable().scaledToFill()
                    } else {
                        Image("defaultProfile").resizable().scaledToFill()
                    }
                }
            } else {
                Image("defaultProfile").resizable().scaledToFill()
            }
        }
    }
    
    private func presentingMail() {
        guard let topVC = UIApplication.shared.topMostViewController() else { return }
        let body = viewModel.supportEmailBody()
        let sender = EmailSender()
        sender.presentEmailSender(from: topVC, to: ["javier@ezinflatables.com"], subject: "MyEZ App Contact", body: body)
    }

    private var header: some View {
        HStack {
            Text("MyProfile")
                .font(.system(size: 30, weight: .bold))
                .foregroundColor(.white)
            
            Spacer()
            
            Button {
                if viewModel.user != nil {
                    viewModel.logout(appState: appState)
                } else {
                    appState.logout()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: viewModel.user == nil ? "arrow.right.to.line" : "rectangle.portrait.and.arrow.right")
                    Text(viewModel.user == nil ? "Login" : "Logout")
                        .fontWeight(.semibold)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Capsule().fill(AppColors.secondary))
                .foregroundColor(.white)
            }
            .buttonStyle(.plain)
        }
    }

    private var profileCard: some View {
        VStack(spacing: 14) {
            profileImageView
                .frame(width: 120, height: 120)
                .clipShape(Circle())
                .overlay(Circle().stroke(AppColors.light.opacity(0.18), lineWidth: 1))
                .background(
                    Circle()
                        .fill(AppColors.light.opacity(0.08))
                        .frame(width: 140, height: 140)
                )
                .shadow(color: AppColors.dark.opacity(0.7), radius: 18, x: 0, y: 10)
                .allowsHitTesting(viewModel.user != nil)
                .onTapGesture {
                    guard viewModel.user != nil else { return }
                    showingImagePicker = true
                }
            
            Text(viewModel.user?.name ?? "Sign in for more features")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(AppColors.primary)
            
            if let type = viewModel.user?.typeUser, !type.isEmpty {
                Text(type)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(AppColors.light.opacity(0.45))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 8)
    }
}

struct ProfileRow: View {
    let icon: String
    let title: String
    let action: () -> Void
    let isEnabled: Bool
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(AppColors.light.opacity(0.55))
                    .frame(width: 24)
                
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(AppColors.light)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppColors.light.opacity(0.35))
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(AppColors.dark.opacity(0.85))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(AppColors.light.opacity(0.12), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1.0 : 0.5)
    }
}

struct ProfileToggleRow: View {
    let icon: String
    let title: String
    @Binding var isOn: Bool
    let isEnabled: Bool
    
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .regular))
                .foregroundColor(AppColors.light.opacity(0.55))
                .frame(width: 24)
            
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(AppColors.light)
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(AppColors.primary)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(AppColors.dark.opacity(0.85))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(AppColors.light.opacity(0.12), lineWidth: 1)
                )
        )
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1.0 : 0.5)
    }
}

struct ProfileImagePicker: UIViewControllerRepresentable {
    let onImagePicked: (UIImage) -> Void
    
    func makeUIViewController(context: Context) -> YPImagePicker {
        var config = YPImagePickerConfiguration()
        config.isScrollToChangeModesEnabled = true
        config.onlySquareImagesFromCamera = true
        config.usesFrontCamera = false
        config.showsPhotoFilters = false
        config.showsVideoTrimmer = false
        config.shouldSaveNewPicturesToAlbum = true
        config.startOnScreen = .library
        config.screens = [.library, .photo]
        config.showsCrop = .none
        config.targetImageSize = .original
        config.overlayView = UIView()
        config.hidesStatusBar = true
        config.hidesBottomBar = false
        config.hidesCancelButton = false
        config.silentMode = true
        config.preferredStatusBarStyle = .default
        config.maxCameraZoomFactor = 1.0
        config.wordings.done = "Save"
        
        let picker = YPImagePicker(configuration: config)
        picker.didFinishPicking { items, _ in
            if let photo = items.singlePhoto {
                onImagePicked(photo.image)
            }
            picker.dismiss(animated: true)
        }
        return picker
    }
    
    func updateUIViewController(_ uiViewController: YPImagePicker, context: Context) {
    }
}

struct IdentifiableURL: Identifiable {
    let id = UUID()
    let url: URL
}
