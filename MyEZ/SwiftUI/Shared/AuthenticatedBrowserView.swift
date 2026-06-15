import SwiftUI

struct AuthenticatedBrowserView: UIViewControllerRepresentable {
    let url: URL
    let title: String
    let earlyJS: String?
    let customCSS: String?
    let customJS: String?
    let showNavButtons: Bool

    init(
        url: URL,
        title: String,
        earlyJS: String? = nil,
        customCSS: String? = nil,
        customJS: String? = nil,
        showNavButtons: Bool = true
    ) {
        self.url = url
        self.title = title
        self.earlyJS = earlyJS
        self.customCSS = customCSS
        self.customJS = customJS
        self.showNavButtons = showNavButtons
    }

    func makeUIViewController(context: Context) -> AuthenticatedBrowserViewController {
        let vc = AuthenticatedBrowserViewController()
        vc.configure(url: url, title: title, earlyJS: earlyJS, customCSS: customCSS, customJS: customJS, showNavButtons: showNavButtons)
        return vc
    }

    func updateUIViewController(_ uiViewController: AuthenticatedBrowserViewController, context: Context) {}
}
