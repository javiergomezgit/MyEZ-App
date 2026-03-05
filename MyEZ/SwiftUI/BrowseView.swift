import SwiftUI

struct BrowseView: View {
    @StateObject private var browserController = BrowserController()

    var body: some View {
        AuthenticatedBrowserContainer(controller: browserController)
            .ignoresSafeArea()
            .overlay(alignment: .top) {
                HStack {
                    Button {
                        browserController.goBack()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(AppColors.light)
                            .frame(width: 38, height: 38)
                            .background(Circle().fill(AppColors.dark.opacity(0.6)))
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Button {
                        browserController.refresh()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(AppColors.light)
                            .frame(width: 38, height: 38)
                            .background(Circle().fill(AppColors.dark.opacity(0.6)))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 12)
                .padding(.top, 8)
            }
            .background(AppColors.dark.ignoresSafeArea())
            .navigationBarHidden(true)
    }
}

final class BrowserController: ObservableObject {
    weak var viewController: AuthenticatedBrowserViewController?

    func goBack() {
        viewController?.goBack()
    }

    func refresh() {
        viewController?.refresh()
    }
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
