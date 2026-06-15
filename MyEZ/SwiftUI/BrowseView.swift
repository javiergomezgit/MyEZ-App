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

    private static let shopifyCSS = """
        body { padding-left: 16px !important; padding-right: 16px !important; box-sizing: border-box !important; }
        footer, .site-footer, #shopify-section-footer, .footer { display: none !important; }
        .header__logo { display: none !important; }
        .mobile-menu__section--loose { display: none !important; }
        """

    // Runs at document start (before any widget scripts) — blocks known chat/accessibility widgets
    // by intercepting appendChild so their scripts and iframes are never added to the DOM.
    private static let widgetBlockerJS = """
        (function() {
            var blocked = [
                'tawk.to', 'tawk.min.js',
                'userway.org', 'cdn.userway',
                'accessibe.com', 'acsbapp.com',
                'equalweb.com',
                'tidio.com', 'tidio.co',
                'gorgias.io', 'gorgias.com',
                'zendesk.com', 'zopim.com',
                'intercom.io', 'intercom.com',
                'freshchat.com', 'freshworks.com',
                'livechatinc.com', 'livechat.com',
                'crisp.chat', 'smartsupp.com',
                'olark.com', 'drift.com'
            ];

            function isBlocked(src) {
                if (!src) return false;
                var s = src.toLowerCase();
                for (var i = 0; i < blocked.length; i++) {
                    if (s.indexOf(blocked[i]) !== -1) return true;
                }
                return false;
            }

            function patch(proto, method) {
                var orig = proto[method];
                proto[method] = function(child) {
                    if (child) {
                        var tag = (child.tagName || '').toLowerCase();
                        if (tag === 'script' || tag === 'iframe') {
                            var src = child.src || child.getAttribute('src') || '';
                            if (isBlocked(src)) return child;
                        }
                    }
                    return orig.apply(this, arguments);
                };
            }

            patch(Element.prototype, 'appendChild');
            patch(Element.prototype, 'insertBefore');
        })();
        """

    func makeUIViewController(context: Context) -> AuthenticatedBrowserViewController {
        let vc = AuthenticatedBrowserViewController()
        if let url = URL(string: "https://www.ezinflatables.com/collections/in-stock-app") {
            vc.configure(
                url: url,
                title: "Browse",
                earlyJS: Self.widgetBlockerJS,
                customCSS: Self.shopifyCSS,
                showNavButtons: false
            )
        }
        controller.viewController = vc
        return vc
    }

    func updateUIViewController(_ uiViewController: AuthenticatedBrowserViewController, context: Context) {
        controller.viewController = uiViewController
    }
}
