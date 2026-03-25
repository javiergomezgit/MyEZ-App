import SwiftUI

struct ContactView: View {
    @State private var showingMail = false
    @State private var showingChat = false
    
    var body: some View {
        ZStack {
            SceneBackgroundView()
            
            ScrollView {
                VStack(spacing: 22) {
                    VStack(spacing: 10) {
                        Text("Reach the team")
                            .font(.system(size: 30, weight: .bold))
                            .foregroundColor(AppColors.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Text("Same MyProfile energy, now applied to the people and channels that keep customers moving.")
                            .font(.system(size: 15))
                            .foregroundColor(AppColors.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    HStack(spacing: 24) {
                        ContactAvatar(
                            imageName: "ceo",
                            name: "Eddie",
                            title: "CEO",
                            action: { sendEmail(email: "eddie@ezinflatables.com", name: "Eddie") }
                        )
                        ContactAvatar(
                            imageName: "coo",
                            name: "Art",
                            title: "COO",
                            action: { sendEmail(email: "art@ezinflatables.com", name: "Art") }
                        )
                    }
                    .padding(.top, 6)
                    .padding(.vertical, 24)
                    .frame(maxWidth: .infinity)
                    .sceneCard()
                    
                    VStack(spacing: 10) {
                        Text("Click on them to contact them.")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(AppColors.textPrimary)
                        
                        Text("Look for us in any of our social media, we love to hear from you.")
                            .font(.system(size: 16))
                            .foregroundColor(AppColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 12)
                    }
                    .padding(.horizontal, 14)
                    
                    VStack(spacing: 14) {
                        SocialRow(
                            icon: "facebookContact",
                            title: "Facebook",
                            subtitle: "@ezinflatablesinc",
                            action: { openSocial(link: "https://www.facebook.com/209605312428497", app: "fb://profile/209605312428497") }
                        )
                        SocialRow(
                            icon: "instaContact",
                            title: "Instagram",
                            subtitle: "@ez_Inflatables",
                            action: { openSocial(link: "http://instagram.com/ez_inflatables", app: "instagram://user?username=ez_inflatables") }
                        )
                        SocialRow(
                            icon: "youtubeContact",
                            title: "YouTube",
                            subtitle: "ezinflatables",
                            action: { openSocial(link: "https://youtube.com/channel/UCYG_F4nyo3UCXv3cO-X6iAw", app: "youtube://www.youtube.com/channel/UCYG_F4nyo3UCXv3cO-X6iAw") }
                        )
                        SocialRow(
                            icon: "tiktokContact",
                            title: "TikTok",
                            subtitle: "@ez_inflatables",
                            action: { openSocial(link: "https://tiktok.com/@ez_inflatables", app: "tiktok://user?screen_name=ez_inflatables") }
                        )
                    }
                    .padding(.top, 6)
                    
                    HStack(spacing: 12) {
                        Button {
                            showingChat = true
                        } label: {
                            Text("Live Chat")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal, 22)
                                .padding(.vertical, 12)
                                .background(
                                    Capsule()
                                        .fill(
                                            LinearGradient(
                                                colors: [AppColors.buttonBlueStart, AppColors.buttonBlueEnd],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                )
                        }
                        .buttonStyle(.plain)
                        
                        Button {
                            callUs()
                        } label: {
                            Text("Call")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal, 22)
                                .padding(.vertical, 12)
                                .background(Capsule().fill(AppColors.buttonGhostFill))
                                .overlay(
                                    Capsule()
                                        .stroke(AppColors.borderSubtle, lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 10)
                }
                .padding(.top, 12)
                .padding(.bottom, 100)
            }
            .padding(.horizontal, 20)
        }
        .sheet(isPresented: $showingChat) {
            NavigationStack {
                ChatWebView()
                    .navigationTitle("Chat")
                    .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
    
    private func sendEmail(email: String, name: String) {
        guard let topVC = UIApplication.shared.topMostViewController() else { return }
        let body = """
        Hi \(name),
        
        I need help with:
        
        ---
        App Version: \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?")
        iOS: \(UIDevice.current.systemVersion)
        Device: \(UIDevice.current.model)
        ---
        """
        let sender = EmailSender()
        sender.presentEmailSender(from: topVC, to: [email], subject: "MyEZ App Contact", body: body)
    }
    
    private func callUs() {
        if let url = URL(string: "tel://+18883445867"), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
    
    private func openSocial(link: String, app: String) {
        if let appURL = URL(string: app), UIApplication.shared.canOpenURL(appURL) {
            UIApplication.shared.open(appURL)
        } else if let linkURL = URL(string: link) {
            UIApplication.shared.open(linkURL)
        }
    }
}

struct ChatWebView: View {
    var body: some View {
        AuthenticatedBrowserView(url: URL(string: "https://tawk.to/chat/5e0120b527773e0d832a7141/default")!, title: "Chat", injectShopCSS: false, showNavButtons: false)
            .ignoresSafeArea()
    }
}

struct ContactAvatar: View {
    let imageName: String
    let name: String
    let title: String
    let action: () -> Void
    private let circleSize: CGFloat = 50
    private let imageSize: CGFloat = 68

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [AppColors.buttonRedStart, AppColors.buttonBlueStart, AppColors.accentBlue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 4
                        )
                        .frame(width: circleSize, height: circleSize)
                        .background(
                            Circle()
                                .fill(AppColors.buttonGhostFill)
                        )
                        .shadow(color: AppColors.buttonBlueStart.opacity(0.18), radius: 12, x: 0, y: 8)

                    Image(imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: imageSize, height: imageSize)
                }

                Text(name)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)

                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        .buttonStyle(.plain)
    }
}

struct SocialRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void
    private let circleSize: CGFloat = 20
    private let iconSize: CGFloat = 23

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(AppColors.buttonGhostFill)
                        .frame(width: circleSize, height: circleSize)
                        .overlay(
                            Circle()
                                .stroke(AppColors.borderSubtle, lineWidth: 1)
                        )
                    Image(icon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: iconSize, height: iconSize)
                        .foregroundColor(AppColors.light)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)
                    Text(subtitle)
                        .font(.system(size: 15))
                        .foregroundColor(AppColors.textSecondary)
                }

                Spacer()
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .sceneCard(fillColor: AppColors.surfaceSecondary)
        }
        .buttonStyle(.plain)
    }
}
