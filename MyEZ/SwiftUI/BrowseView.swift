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
        .header__action-item--account { display: none !important; }
        .rfq-btn, .rfq-collection-btn, .rfq-btn-cart,
        [class*="rfq-btn"], [class*="grfq"], [id*="grfq"],
        .g-rfq-button, .globo-rfq-btn { display: none !important; }
        .template-cart [name="checkout"],
        .template-cart .cart__checkout-button,
        .template-cart .cart-checkout-button,
        .template-cart .cart__checkout,
        .template-cart a[href="/checkout"],
        .template-cart a[href*="/checkout"],
        .template-cart shopify-accelerated-checkout-cart,
        .template-cart .shopify-payment-button,
        .template-cart [data-shopify="payment-button"],
        .template-cart .dynamic-checkout-cart,
        .template-cart [name="goto_pp"],
        .template-cart [name="goto_gc"] { display: none !important; }
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

    // Runs at document end — on /cart, hides checkout buttons and injects
    // a "Request a Quote" button that opens a modal form.
    private static let cartPageJS = """
        (function() {
            if (window.location.pathname !== '/cart') return;

            function getCartItems() {
                return fetch('/cart.js')
                    .then(function(r) { return r.json(); })
                    .then(function(cart) {
                        return (cart.items || []).map(function(item) {
                            var price = '$' + (item.price / 100).toFixed(2);
                            var linePrice = '$' + (item.line_price / 100).toFixed(2);
                            var url = 'https://www.ezinflatables.com' + item.url;
                            var line = item.quantity + 'x ' + item.title;
                            if (item.variant_title) line += ' (' + item.variant_title + ')';
                            line += ' — ' + price + ' each, total ' + linePrice;
                            line += '\\nLink: ' + url;
                            return line;
                        }).join('\\n\\n');
                    })
                    .catch(function() { return 'items unavailable'; });
            }

            function clearCart() {
                return fetch('/cart/clear.js', { method: 'POST' });
            }

            function showModal() {
                if (document.getElementById('myez-overlay')) return;
                var overlay = document.createElement('div');
                overlay.id = 'myez-overlay';
                overlay.style.cssText = 'position:fixed;inset:0;background:rgba(0,0,0,0.6);z-index:99999;display:flex;align-items:center;justify-content:center;';
                overlay.innerHTML = '<div id="myez-modal" style="background:#fff;border-radius:14px;padding:28px 24px 22px;width:88%;max-width:380px;box-shadow:0 10px 40px rgba(0,0,0,0.25);font-family:-apple-system,sans-serif;">'
                    + '<h2 style="margin:0 0 4px;font-size:19px;font-weight:700;color:#111;">Request a Quote</h2>'
                    + '<p style="margin:0 0 18px;font-size:13px;color:#666;">We will contact you with pricing and availability.</p>'
                    + '<label style="display:block;font-size:13px;font-weight:600;color:#333;margin-bottom:5px;">Name *</label>'
                    + '<input id="myez-name" type="text" placeholder="Your name" autocomplete="name" style="width:100%;padding:12px;border:1.5px solid #ddd;border-radius:8px;font-size:15px;margin-bottom:13px;box-sizing:border-box;outline:none;-webkit-appearance:none;">'
                    + '<label style="display:block;font-size:13px;font-weight:600;color:#333;margin-bottom:5px;">Email *</label>'
                    + '<input id="myez-email" type="email" placeholder="your@email.com" autocomplete="email" style="width:100%;padding:12px;border:1.5px solid #ddd;border-radius:8px;font-size:15px;margin-bottom:13px;box-sizing:border-box;outline:none;-webkit-appearance:none;">'
                    + '<label style="display:block;font-size:13px;font-weight:600;color:#333;margin-bottom:5px;">Phone</label>'
                    + '<input id="myez-phone" type="tel" placeholder="(555) 000-0000" autocomplete="tel" style="width:100%;padding:12px;border:1.5px solid #ddd;border-radius:8px;font-size:15px;margin-bottom:13px;box-sizing:border-box;outline:none;-webkit-appearance:none;">'
                    + '<button id="myez-btn-send" type="button" style="width:100%;padding:15px;background:#e22;color:#fff;border:none;border-radius:8px;font-size:16px;font-weight:700;cursor:pointer;">Send Request</button>'
                    + '<button id="myez-btn-cancel" type="button" style="width:100%;padding:10px;background:none;border:none;color:#999;font-size:14px;cursor:pointer;margin-top:6px;">Cancel</button>'
                    + '<div id="myez-status" style="margin-top:12px;font-size:14px;text-align:center;"></div>'
                    + '</div>';
                document.body.appendChild(overlay);

                document.getElementById('myez-btn-cancel').onclick = function() { overlay.remove(); };
                overlay.onclick = function(e) { if (e.target === overlay) overlay.remove(); };

                document.getElementById('myez-btn-send').onclick = function() {
                    var name = document.getElementById('myez-name').value.trim();
                    var email = document.getElementById('myez-email').value.trim();
                    var phone = document.getElementById('myez-phone').value.trim();
                    var status = document.getElementById('myez-status');
                    var sendBtn = document.getElementById('myez-btn-send');
                    var cancelBtn = document.getElementById('myez-btn-cancel');
                    if (!name || !email) {
                        status.style.color = '#c00';
                        status.textContent = 'Please enter your name and email.';
                        return;
                    }
                    sendBtn.disabled = true;
                    cancelBtn.disabled = true;
                    status.style.color = '#555';
                    status.textContent = 'Sending\\u2026';
                    getCartItems().then(function(items) {
                        return fetch('https://formspree.io/f/mojzrbeq', {
                            method: 'POST',
                            headers: { 'Content-Type': 'application/json', 'Accept': 'application/json' },
                            body: JSON.stringify({ name: name, email: email, phone: phone || 'not provided', message: 'Items:\\n' + items })
                        });
                    }).then(function(r) {
                        if (!r.ok) throw new Error('failed');
                        return clearCart();
                    }).then(function() {
                        status.style.color = '#080';
                        status.textContent = '\\u2713 Request sent! We will contact you soon.';
                        sendBtn.style.display = 'none';
                        cancelBtn.textContent = 'Close';
                        cancelBtn.disabled = false;
                        setTimeout(function() { overlay.remove(); window.location.reload(); }, 2000);
                    }).catch(function() {
                        status.style.color = '#c00';
                        status.textContent = 'Something went wrong. Please try again.';
                        sendBtn.disabled = false;
                        cancelBtn.disabled = false;
                    });
                };
            }

            // Expose for native nav-block fallback
            window.myezShowModal = showModal;

            function hideCheckoutButtons() {
                var sels = [
                    '[name="checkout"]', 'button[name="checkout"]', 'input[name="checkout"]',
                    '.cart__checkout-button', '.cart-checkout-button', '.cart__checkout',
                    'a[href="/checkout"]', 'a[href*="/checkout"]',
                    'shopify-accelerated-checkout-cart', '.shopify-payment-button',
                    '[data-shopify="payment-button"]', '.dynamic-checkout-cart',
                    '[name="goto_pp"]', '[name="goto_gc"]'
                ];
                sels.forEach(function(sel) {
                    try { document.querySelectorAll(sel).forEach(function(el) {
                        el.style.setProperty('display', 'none', 'important');
                    }); } catch(e) {}
                });
            }

            function injectButton() {
                if (document.getElementById('myez-quote-btn')) return;
                var anchor = document.querySelector(
                    '.cart__footer, .cart-footer, .cart__totals, form[action*="checkout"], form[action="/cart"]'
                );
                if (!anchor) return;
                var btn = document.createElement('button');
                btn.id = 'myez-quote-btn';
                btn.type = 'button';
                btn.textContent = 'Request a Quote';
                btn.style.cssText = 'display:block;width:100%;padding:15px;background:#e22;color:#fff;border:none;border-radius:8px;font-size:16px;font-weight:700;cursor:pointer;margin-top:14px;letter-spacing:0.3px;font-family:-apple-system,sans-serif;box-sizing:border-box;';
                btn.onclick = showModal;
                anchor.appendChild(btn);
            }

            function run() {
                hideCheckoutButtons();
                injectButton();
            }

            if (document.readyState === 'loading') {
                document.addEventListener('DOMContentLoaded', run);
            } else {
                run();
            }
            [400, 1000, 2500].forEach(function(ms) { setTimeout(run, ms); });

            // Keep hiding if Shopify re-renders buttons
            new MutationObserver(hideCheckoutButtons).observe(document.body, { childList: true, subtree: true });
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
                customJS: Self.cartPageJS,
                showNavButtons: false,
                blockCheckoutNavigation: true
            )
        }
        controller.viewController = vc
        return vc
    }

    func updateUIViewController(_ uiViewController: AuthenticatedBrowserViewController, context: Context) {
        controller.viewController = uiViewController
    }
}
