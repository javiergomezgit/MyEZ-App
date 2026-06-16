import SwiftUI
import YPImagePicker

struct ProfileView: View {
    @ObservedObject var appState: AppState
    @StateObject private var viewModel = ProfileViewModel()
    @State private var showingImagePicker = false
    @State private var showingMail = false
    @State private var showingMyInformation = false
    @State private var showingSafariURL: IdentifiableURL?

    var body: some View {
        ZStack {
            SceneBackgroundView()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    header
                    profileCard

                    profileSection("Account", rows: [
                        ProfileRow(icon: "person.text.rectangle", title: "My Information", tint: AppColors.accentRed,
                            action: { showingMyInformation = true },
                            isEnabled: viewModel.user != nil)
                    ])

                    profileToggleSection("Notifications", rows: [
                        ProfileToggleRow(icon: "bell", title: "Deals in your email", tint: AppColors.accentPurple,
                            isOn: Binding(
                                get: { viewModel.isSubscribed },
                                set: { newValue in viewModel.updateSubscription(isOn: newValue) }
                            ), isEnabled: viewModel.user != nil)
                    ])

                    profileSection("Support", rows: [
                        ProfileRow(icon: "questionmark.circle", title: "Help Center", tint: AppColors.accentYellow,
                            action: { showingMail = true },
                            isEnabled: true),
                        ProfileRow(icon: "doc.text", title: "Terms & Privacy", tint: AppColors.accentSky,
                            action: {
                                if let url = URL(string: "https://www.ezinflatables.com/policies/privacy-policy") {
                                    showingSafariURL = IdentifiableURL(url: url)
                                }
                            },
                            isEnabled: true)
                    ])

                    Text("MyEZ Version 1.0.0")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(AppColors.textMuted)
                        .padding(.top, 4)
                        .padding(.bottom, 96)
                }
                .padding(.top, 12)
            }
            .padding(.horizontal, 20)
        }
        .onAppear { viewModel.refresh() }
        .sheet(isPresented: $showingMyInformation) {
            MyInformationView(viewModel: viewModel) {
                showingMyInformation = false
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
        .alert("", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { _ in viewModel.errorMessage = nil }
        )) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .onChange(of: showingMail, initial: false) { _, newValue in
            guard newValue else { return }
            presentingMail()
            showingMail = false
        }
    }

    private var header: some View {
        HStack {
            Text("My Profile")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(AppColors.textPrimary)

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
                        .font(.system(size: 13, weight: .semibold))
                    Text(viewModel.user == nil ? "Login" : "Logout")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundColor(AppColors.accentRed)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Capsule().fill(Color.white.opacity(0.92)))
                .overlay(
                    Capsule()
                        .stroke(AppColors.accentRed.opacity(0.12), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var profileCard: some View {
        VStack(spacing: 20) {
            HStack(spacing: 16) {
                profileImageView
                    .frame(width: 82, height: 82)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(AppColors.borderSubtle, lineWidth: 1))
                    .background(
                        Circle()
                            .fill(Color(hex: "EEF3FF"))
                            .frame(width: 82, height: 82)
                    )
                    .allowsHitTesting(viewModel.user != nil)
                    .onTapGesture {
                        guard viewModel.user != nil else { return }
                        showingImagePicker = true
                    }

                VStack(alignment: .leading, spacing: 6) {
                    Text(viewModel.user?.name ?? "Guest User")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)
                        .lineLimit(2)

                    Text(displayRankTitle)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(AppColors.buttonBlueEnd)
                        .textCase(.uppercase)
                }

                Spacer(minLength: 0)
            }

            Divider()
                .overlay(AppColors.borderSubtle)

            HStack(spacing: 12) {
                statCard(value: totalWeightText, label: "Total Weight (lbs)")
                statCard(value: rankText, label: "Monthly Place")
            }
        }
        .padding(20)
        .sceneCard(cornerRadius: 22, fillColor: AppColors.surfacePrimary)
    }

    private func statCard(value: String, label: String) -> some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(AppColors.textPrimary)

            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppColors.surfaceSecondary)
        )
    }

    private func profileSection(_ title: String, rows: [ProfileRow]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(.system(size: 12, weight: .bold))
                .tracking(1.1)
                .foregroundColor(AppColors.textSecondary)
                .padding(.leading, 6)

            VStack(spacing: 0) {
                ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                    row

                    if index < rows.count - 1 {
                        Divider()
                            .overlay(AppColors.borderSubtle)
                            .padding(.leading, 72)
                    }
                }
            }
            .sceneCard(cornerRadius: 20, fillColor: AppColors.surfacePrimary)
        }
    }

    private func profileToggleSection(_ title: String, rows: [ProfileToggleRow]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(.system(size: 12, weight: .bold))
                .tracking(1.1)
                .foregroundColor(AppColors.textSecondary)
                .padding(.leading, 6)

            VStack(spacing: 0) {
                ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                    row

                    if index < rows.count - 1 {
                        Divider()
                            .overlay(AppColors.borderSubtle)
                            .padding(.leading, 72)
                    }
                }
            }
            .sceneCard(cornerRadius: 20, fillColor: AppColors.surfacePrimary)
        }
    }

    private var totalWeightText: String {
        let weight = userInformation.weight > 0
            ? userInformation.weight
            : (viewModel.currentUserWeight > 0 ? viewModel.currentUserWeight : (viewModel.user?.ownwedWeight ?? 0))
        if weight > 0 {
            return weight.formatted()
        }
        return "—"
    }

    private var rankText: String {
        viewModel.currentUserRank > 0 ? "#\(viewModel.currentUserRank)" : "—"
    }

    private var displayRankTitle: String {
        guard let user = viewModel.user else { return "MINIMUMWEIGHT" }
        return user.typeUser.isEmpty ? "MINIMUMWEIGHT" : user.typeUser
    }

    private var profileImageView: some View {
        Group {
            if let image = viewModel.profileImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else if let urlString = viewModel.user?.profileImageUrl,
                      let url = URL(string: urlString) {
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
        sender.presentEmailSender(from: topVC, to: ["javier@ezinflatables.com"],
            subject: "MyEZ App Contact", body: body)
    }
}

// MARK: - My Information Sheet

struct MyInformationView: View {
    @ObservedObject var viewModel: ProfileViewModel
    let onDismiss: () -> Void

    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            ZStack {
                SceneBackgroundView()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        infoField(label: "Full Name", placeholder: "John Doe", text: $viewModel.editName, keyboard: .default)
                        infoField(label: "Phone", placeholder: "1234567890", text: $viewModel.editPhone, keyboard: .phonePad)
                        infoField(label: "Company Name", placeholder: "EZ Inflatables", text: $viewModel.editCompanyName, keyboard: .default)
                        infoField(label: "Zip Code", placeholder: "33101", text: $viewModel.editZipCode, keyboard: .numbersAndPunctuation)

                        Button {
                            isSaving = true
                            viewModel.updateProfile(
                                name: viewModel.editName,
                                phone: viewModel.editPhone,
                                companyName: viewModel.editCompanyName,
                                zipCode: viewModel.editZipCode
                            ) {
                                isSaving = false
                                onDismiss()
                            }
                        } label: {
                            Text(isSaving ? "Saving..." : "Save Changes")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .fill(AppColors.buttonBlueStart)
                                )
                        }
                        .disabled(isSaving)
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("My Information")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onDismiss() }
                        .foregroundColor(AppColors.accentRed)
                }
            }
        }
    }

    private func infoField(label: String, placeholder: String, text: Binding<String>, keyboard: UIKeyboardType) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(AppColors.textPrimary)

            TextField(placeholder, text: text)
                .keyboardType(keyboard)
                .autocorrectionDisabled()
                .textInputAutocapitalization(keyboard == .default ? .words : .never)
                .foregroundColor(AppColors.textPrimary)
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
}

// MARK: - Supporting Views

struct ProfileRow: View {
    let icon: String
    let title: String
    let tint: Color
    let action: () -> Void
    let isEnabled: Bool

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(tint.opacity(0.14))
                        .frame(width: 40, height: 40)

                    Image(systemName: icon)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(tint)
                }

                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppColors.textMuted)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 15)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.5)
    }
}

struct ProfileToggleRow: View {
    let icon: String
    let title: String
    let tint: Color
    @Binding var isOn: Bool
    let isEnabled: Bool

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(tint.opacity(0.14))
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(tint)
            }

            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(AppColors.textPrimary)

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(AppColors.buttonBlueStart)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 15)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.5)
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
