import SwiftUI

struct ContactView: View {
    @State private var showingChat = false

    private let socialLinks: [SocialTileItem] = [
        .init(icon: "facebookContact", title: "Facebook", subtitle: "@EZInflatables", tint: AppColors.accentBlue,
              link: "https://www.facebook.com/209605312428497", app: "fb://profile/209605312428497"),
        .init(icon: "instaContact", title: "Instagram", subtitle: "@ez_inflatables", tint: AppColors.accentRed,
              link: "http://instagram.com/ez_inflatables", app: "instagram://user?username=ez_inflatables"),
        .init(icon: "youtubeContact", title: "YouTube", subtitle: "EZ Inflatables", tint: AppColors.accentSky,
              link: "https://youtube.com/channel/UCYG_F4nyo3UCXv3cO-X6iAw", app: "youtube://www.youtube.com/channel/UCYG_F4nyo3UCXv3cO-X6iAw"),
        .init(icon: "tiktokContact", title: "TikTok", subtitle: "@ezinflatables", tint: AppColors.accentPurple,
              link: "https://tiktok.com/@ez_inflatables", app: "tiktok://user?screen_name=ez_inflatables")
    ]

    private let socialColumns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    var body: some View {
        ZStack {
            SceneBackgroundView()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    contactMethodsCard

                    VStack(spacing: 8) {
                        Text("Follow us on social media")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(AppColors.textPrimary)
                    }

                    LazyVGrid(columns: socialColumns, spacing: 14) {
                        ForEach(socialLinks) { item in
                            SocialTile(item: item) {
                                openSocial(link: item.link, app: item.app)
                            }
                        }
                    }
                    .padding(.bottom, 96)
                }
                .padding(.top, 18)
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

    private var contactMethodsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Contact Methods")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(AppColors.textPrimary)

            ContactMethodRow(
                iconName: "phone",
                iconTint: AppColors.accentGreen,
                title: "Phone",
                subtitle: "(123) 456-7890",
                action: callUs
            )

            ContactMethodRow(
                iconName: "envelope",
                iconTint: AppColors.accentBlue,
                title: "Email",
                subtitle: "info@ezinflatables.com",
                action: { sendEmail(email: "info@ezinflatables.com", name: "EZ Inflatables") }
            )

            ContactMethodRow(
                iconName: "message",
                iconTint: AppColors.accentPurple,
                title: "Live Chat",
                subtitle: "Start a conversation",
                action: { showingChat = true }
            )
        }
        .padding(20)
        .sceneCard(cornerRadius: 24, fillColor: AppColors.surfacePrimary)
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

private struct ContactMethodRow: View {
    let iconName: String
    let iconTint: Color
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(iconTint.opacity(0.14))
                        .frame(width: 44, height: 44)

                    Image(systemName: iconName)
                        .font(.system(size: 19, weight: .medium))
                        .foregroundColor(iconTint)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(AppColors.textSecondary)

                    Text(subtitle)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)
                }

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(AppColors.surfaceSecondary)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct SocialTileItem: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let subtitle: String
    let tint: Color
    let link: String
    let app: String
}

private struct SocialTile: View {
    let item: SocialTileItem
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(item.tint.opacity(0.10))
                        .frame(width: 54, height: 54)

                    Image(item.icon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                }

                Text(item.title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)

                Text(item.subtitle)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, minHeight: 148)
            .padding(.horizontal, 12)
            .sceneCard(cornerRadius: 20, fillColor: AppColors.surfacePrimary)
        }
        .buttonStyle(.plain)
    }
}
