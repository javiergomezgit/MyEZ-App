import SwiftUI

struct BrowseView: View {
    @StateObject private var browserController = BrowserController()

    var body: some View {
        AuthenticatedBrowserContainer(controller: browserController)
            .ignoresSafeArea()
            .background(AppColors.dark.ignoresSafeArea())
            .navigationBarHidden(true)
    }
}

final class BrowserController: ObservableObject {
    weak var viewController: AuthenticatedBrowserViewController?
}

struct AuthenticatedBrowserContainer: UIViewControllerRepresentable {
    @ObservedObject var controller: BrowserController

    func makeUIViewController(context: Context) -> AuthenticatedBrowserViewController {
        let vc = AuthenticatedBrowserViewController()
        if let url = URL(string: "https://ezinflatables.odoo.com/shop") {
            vc.configure(url: url, title: "Browse", injectShopCSS: true, showNavButtons: false)
        }
        controller.viewController = vc
        return vc
    }
    
    func updateUIViewController(_ uiViewController: AuthenticatedBrowserViewController, context: Context) {
        controller.viewController = uiViewController
    }
}
