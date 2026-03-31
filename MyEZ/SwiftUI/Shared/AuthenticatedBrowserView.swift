import SwiftUI

struct AuthenticatedBrowserView: UIViewControllerRepresentable {
    let url: URL
    let title: String
    let injectShopCSS: Bool
    let showNavButtons: Bool
    let onAccountProfileSaved: ((AccountProfileInfo) -> Void)?
    let portalSavePathPrefix: String?
    let onPortalSave: (() -> Void)?
    
    init(
        url: URL,
        title: String,
        injectShopCSS: Bool = true,
        showNavButtons: Bool = true,
        onAccountProfileSaved: ((AccountProfileInfo) -> Void)? = nil,
        portalSavePathPrefix: String? = nil,
        onPortalSave: (() -> Void)? = nil
    ) {
        self.url = url
        self.title = title
        self.injectShopCSS = injectShopCSS
        self.showNavButtons = showNavButtons
        self.onAccountProfileSaved = onAccountProfileSaved
        self.portalSavePathPrefix = portalSavePathPrefix
        self.onPortalSave = onPortalSave
    }
    
    func makeUIViewController(context: Context) -> AuthenticatedBrowserViewController {
        let vc = AuthenticatedBrowserViewController()
        vc.configure(
            url: url,
            title: title,
            injectShopCSS: injectShopCSS,
            showNavButtons: showNavButtons,
            onAccountProfileSaved: onAccountProfileSaved,
            portalSavePathPrefix: portalSavePathPrefix,
            onPortalSave: onPortalSave
        )
        return vc
    }
    
    func updateUIViewController(_ uiViewController: AuthenticatedBrowserViewController, context: Context) {
    }
}
