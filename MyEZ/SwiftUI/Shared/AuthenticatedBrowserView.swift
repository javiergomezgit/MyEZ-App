import SwiftUI

struct AuthenticatedBrowserView: UIViewControllerRepresentable {
    let url: URL
    let title: String
    let injectShopCSS: Bool
    let showNavButtons: Bool
    
    init(url: URL, title: String, injectShopCSS: Bool = true, showNavButtons: Bool = true) {
        self.url = url
        self.title = title
        self.injectShopCSS = injectShopCSS
        self.showNavButtons = showNavButtons
    }
    
    func makeUIViewController(context: Context) -> AuthenticatedBrowserViewController {
        let vc = AuthenticatedBrowserViewController()
        vc.configure(url: url, title: title, injectShopCSS: injectShopCSS, showNavButtons: showNavButtons)
        return vc
    }
    
    func updateUIViewController(_ uiViewController: AuthenticatedBrowserViewController, context: Context) {
    }
}
