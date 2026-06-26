import SwiftUI
import FirebaseDatabase

struct BrowseView: View {
    @StateObject private var browserController = BrowserController()
    @EnvironmentObject private var appState: AppState

    private func drainPendingURL() {
        guard let url = appState.pendingBrowseURL else { return }
        browserController.navigate(to: url)
        appState.pendingBrowseURL = nil
    }

    private func loadBrowseURL() {
        Database.database().reference().child("general_urls").child("browse_url")
            .observeSingleEvent(of: .value) { snapshot in
                guard let urlString = snapshot.value as? String,
                      let url = URL(string: urlString) else { return }
                DispatchQueue.main.async {
                    browserController.navigate(to: url)
                }
            }
    }

    var body: some View {
        AuthenticatedBrowserContainer(controller: browserController)
            .ignoresSafeArea()
            .background(AppColors.dark.ignoresSafeArea())
            .navigationBarHidden(true)
            .onAppear {
                loadBrowseURL()
                drainPendingURL()
            }
            .onChange(of: appState.pendingBrowseURL) { _, url in
                guard url != nil else { return }
                drainPendingURL()
            }
    }
}

final class BrowserController: ObservableObject {
    weak var viewController: AuthenticatedBrowserViewController?
    private(set) var queuedURL: URL?

    func navigate(to url: URL) {
        if let vc = viewController {
            vc.navigate(to: url)
            queuedURL = nil
        } else {
            queuedURL = url
        }
    }

    func drainQueue() {
        guard let url = queuedURL, let vc = viewController else { return }
        vc.navigate(to: url)
        queuedURL = nil
    }
}

struct AuthenticatedBrowserContainer: UIViewControllerRepresentable {
    @ObservedObject var controller: BrowserController

    private static let shopifyCSS = """
        body { padding-left: 16px !important; padding-right: 16px !important; box-sizing: border-box !important; }
        footer, .site-footer, #shopify-section-footer, .footer { display: none !important; }
        .header__logo { display: none !important; }
        .mobile-menu__section--loose { display: none !important; }
        .header__action-item--account { display: none !important; }
        .rfq-btn, .rfq-collection-btn, .rfq-btn-cart,
        [class*="rfq-btn"], [class*="grfq"], [id*="rfq-btn"], [id*="grfq"],
        .g-rfq-button, .globo-rfq-btn { display: none !important; }
        """

    // Runs at document start — blocks chat/accessibility widget scripts before they execute.
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
                'olark.com', 'drift.com',
                'accessibilityassistant.com', 'cdn.accessibilityassistant'
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

    // Runs at document end — removes third-party RFQ widgets and auto-fills the checkout email.
    private static func cartPageJS(email: String) -> String {
        // Escape the email so it's safe inside a JS string literal
        let safeEmail = email.replacingOccurrences(of: "\\", with: "\\\\")
                             .replacingOccurrences(of: "\"", with: "\\\"")
        return """
        (function() {
            var userEmail = "\(safeEmail)";

            // Remove third-party RFQ widgets
            var rfqText = 'request a quote';
            function removeRFQWidgets() {
                document.querySelectorAll('.rfq-btn, .rfq-collection-btn, .rfq-btn-cart, .g-rfq-button, .globo-rfq-btn').forEach(function(el) { el.remove(); });
                document.querySelectorAll('button, a, [role="button"]').forEach(function(el) {
                    if ((el.textContent || '').trim().toLowerCase() === rfqText) el.remove();
                });
            }
            removeRFQWidgets();
            [400, 1000, 2500].forEach(function(ms) { setTimeout(removeRFQWidgets, ms); });
            new MutationObserver(removeRFQWidgets).observe(document.body, { childList: true, subtree: true });

            // Auto add to cart when URL contains ?autoAddToCart=1
            (function() {
                var params = new URLSearchParams(window.location.search);
                if (params.get('autoAddToCart') !== '1') return;
                var shouldCheckout = params.get('autoCheckout') === '1';
                var attempted = false;
                function tryAdd() {
                    if (attempted) return;
                    var form = document.querySelector('form[action*="/cart/add"]');
                    if (!form) return;
                    var idInput = form.querySelector('input[name="id"], select[name="id"]');
                    if (!idInput || !idInput.value) return;
                    attempted = true;
                    fetch('/cart/add.js', {
                        method: 'POST',
                        headers: { 'Content-Type': 'application/json' },
                        body: JSON.stringify({ items: [{ id: parseInt(idInput.value), quantity: 1 }] })
                    })
                    .then(function() {
                        window.location.href = shouldCheckout ? '/checkout' : '/cart';
                    })
                    .catch(function() {
                        var btn = form.querySelector('[type="submit"], [name="add"]');
                        if (btn) btn.click();
                    });
                }
                [300, 800, 1500, 3000].forEach(function(ms) { setTimeout(tryAdd, ms); });
            })();

            // Auto-fill email on cart and checkout pages
            if (!userEmail) return;
            function fillEmail() {
                var selectors = [
                    '#email', 'input[name="email"]', 'input[type="email"]',
                    '#checkout_email', '#checkout_email_or_phone',
                    '[data-email]', 'input[autocomplete="email"]'
                ];
                selectors.forEach(function(sel) {
                    document.querySelectorAll(sel).forEach(function(input) {
                        if (!input.value) {
                            input.value = userEmail;
                            input.dispatchEvent(new Event('input', { bubbles: true }));
                            input.dispatchEvent(new Event('change', { bubbles: true }));
                        }
                    });
                });
            }
            fillEmail();
            [500, 1500, 3000].forEach(function(ms) { setTimeout(fillEmail, ms); });
            new MutationObserver(fillEmail).observe(document.body, { childList: true, subtree: true });
        })();
        """
    }

    func makeUIViewController(context: Context) -> AuthenticatedBrowserViewController {
        let vc = AuthenticatedBrowserViewController()
        vc.configure(
            url: nil,
            title: "Browse",
            earlyJS: Self.widgetBlockerJS,
            customCSS: Self.shopifyCSS,
            customJS: Self.cartPageJS(email: userInformation.email),
            showNavButtons: false,
            blockCheckoutNavigation: false
        )
        controller.viewController = vc
        return vc
    }

    func updateUIViewController(_ uiViewController: AuthenticatedBrowserViewController, context: Context) {
        controller.viewController = uiViewController
        controller.drainQueue()
    }
}
